# 项目级配置（相当于 VSCode 的 workspace settings）

「这个项目用 tab、那个用 2 空格」「这个项目的语言服务器要多认一个全局
变量」「只在这个仓库里加一组映射」—— Neovim 不装插件就能做到，一共五层
机制。

选择原则：**能不执行代码就不执行代码**。下面第 1、2 层跨编辑器通用、
没有安全问题，能覆盖绝大多数需求；`.nvim.lua` 是最后手段。

| 需求 | 用哪一层 |
| --- | --- |
| 格式化 / lint / 类型检查的规则 | 那个工具自己的配置文件 |
| 缩进、编码、行尾、去尾空格、行宽 | `.editorconfig` |
| 项目专属的语言服务器设置 | `.nvim/lsp/*.lua` + `exrc` |
| 项目专属的映射、autocmd、插件开关 | `.nvim.lua` + `exrc` |
| 只有某一个文件特殊 | modeline |

---

## 1. 工具自己的配置文件（不需要碰 Neovim）

`stylua.toml`、`.prettierrc`、`.markdownlint.jsonc`、`.luarc.json`、
`pyrightconfig.json`、`tsconfig.json`、`ruff.toml`……

conform 和 nvim-lint 只是把文件交给外部命令，命令自己会从文件所在目录
往上找这些配置。语言服务器也一样：`.luarc.json` 是 lua_ls 读的，不经过
Neovim。

所以「不同项目不同规则」这件事，很多时候一行 Neovim 配置都不用写。
本仓库根目录的 `stylua.toml` 就已经是一份项目级配置。

## 2. `.editorconfig`

Neovim 内置支持，**默认开着**，不需要任何配置。打开文件时从文件所在
目录一路往上找 `.editorconfig`，把匹配的属性应用到这个缓冲区。

```ini
root = true

[*]
indent_style = space
indent_size = 4
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
max_line_length = 100

[*.md]
indent_size = 2
trim_trailing_whitespace = false
```

几个要点：

- `root = true` 停止继续往上找，必须写在最顶上（不能在 `[...]` 段里）。
- 多个段会**合并**：上面那份配置作用在 `x.md` 上时，
  `indent_size` 取 2（后面的段赢），`charset` 仍然是 `[*]` 段里的 utf-8。
- 生效时机是 **ftplugin 和 `FileType` 自动命令之后**，所以它盖得住
  `lua/config/options.lua` 里的全局值，也盖得住语言自带的 ftplugin。
- 生效结果存在缓冲区变量里，`:lua =vim.b.editorconfig` 可以查到这个
  文件最终吃到了哪些属性。
- 整体关掉是 `vim.g.editorconfig = false`，单个缓冲区关掉是
  `vim.b.editorconfig = false`。

支持的属性只有这十个（其他的写了不报错，但没人管）：

| 属性 | 对应的 Neovim 选项 |
| --- | --- |
| `charset` | `fileencoding`、`bomb` |
| `end_of_line` | `fileformat`（lf/crlf/cr → unix/dos/mac） |
| `indent_size` | `shiftwidth`、`softtabstop`，顺带 `tabstop` |
| `indent_style` | `expandtab` |
| `insert_final_newline` | `fixendofline`、`endofline` |
| `max_line_length` | `textwidth` |
| `root` | 停止向上查找 |
| `spelling_language` | `spelllang` |
| `tab_width` | `tabstop` |
| `trim_trailing_whitespace` | 保存时删掉行尾空格 |

`indent_size` 和 `tab_width` 的分工：前者是「一级缩进算几列」，后者是
「一个 tab 字符显示几列」。只写 `indent_size` 时两个一起设。

## 3. `.nvim.lua` + `'exrc'`

这一层才是真正对应 VSCode workspace settings 的东西：一个能跑任意 Lua
的项目级配置文件。

### 打开开关

```lua
vim.o.exrc = true
```

开了之后，从当前工作目录一路往上，每一层目录里的 `.nvim.lua`、
`.nvimrc`、`.exrc` 都会执行 —— 前提是在信任列表里。

### 信任流程

第一次进那个目录，屏幕上出现：

```text
exrc: Found untrusted code. To enable it, choose (v)iew then run `:trust`:
/path/to/project/.nvim.lua
```

三个选项：`ignore` / `view` / `deny`。**没有「直接 allow」这一项** ——
对文件只能选 `(v)iew` 把它打开看，看完在那个缓冲区里执行 `:trust`，
然后重启 Neovim 才生效。设计上就是逼你先读一遍再放行。

（只有对**目录**授信时才有 `allow` 选项，因为目录是按名字判断的，
没有内容可看。）

- 信任按**文件内容的 hash** 记，所以 `.nvim.lua` 改一个字就要重新
  `:trust` 一次。
- 信任库在 `~/.local/state/nvim/trust`（`stdpath("state")`），
  纯文本，每行 `<sha256> <绝对路径>`，可以直接 `cat` 看。
- `:trust ++deny` 拉黑（以后再也不问、也不执行），
  `:trust ++remove` 移出列表（下次重新问）。
- `:trust <文件>` 带参数的形式有 TOCTOU 风险（你检查的和它读的可能不是
  同一份内容），所以官方建议：先打开文件看，然后不带参数执行 `:trust`。

### 执行时机

实测的位置：**`init.lua` 跑完之后、`VimEnter` 之前、命令行上指定的文件
被读入之前**。这时候：

- `lua/config/options.lua` 的值已经生效，`.nvim.lua` 能盖掉它们。
- lazy.nvim 的非懒加载插件已经载入（配色已经应用）。
- **懒加载插件的 `setup()` 还没跑**，所以直接改它们的 opts 是无效的 ——
  要么挂一个 autocmd，要么设一个 `vim.g.` 开关让插件那边读。
- `runtimepath` 还能改，下一层的 LSP 配方就是靠这个。

### 坑一：`vim.opt_local` 在这里几乎没用

执行 `.nvim.lua` 时已经有一个缓冲区（编号 1，名字就是命令行上的第一个
文件），但内容还没读进来。所以：

```lua
vim.opt_local.shiftwidth = 3   -- 只对第一个文件生效，打开第二个就没了
```

实测 `nvim a.lua` 之后 `a.lua` 的 `shiftwidth` 是 3，`:e b.lua` 之后
是全局默认值。要做「这个项目里所有文件都怎样」，用全局的
`vim.o` / `vim.opt`，或者挂 autocmd：

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  callback = function()
    vim.opt_local.shiftwidth = 3
  end,
})
```

### 坑二：多层目录是由内向外执行的，所以外层会赢

`project/.nvim.lua` 和 `project/sub/.nvim.lua` 都设 `shiftwidth`，
在 `sub` 里启动 Neovim，最终生效的是**外层 `project/` 那个值** ——
执行顺序是内 → 外，后执行的盖掉先执行的。

想让内层说了算，在内层文件的最后截断向上查找：

```lua
vim.o.exrc = false
```

和 `.editorconfig` 的 `root = true` 是一个意思。

### 坑三：三种文件名不是「取一个」

同一个目录里 `.nvim.lua`、`.nvimrc`、`.exrc` 都存在时，**三个都会执行**，
顺序就是这个顺序。实践上只用 `.nvim.lua`，另外两个是 Vimscript 的，
没有理由再碰。

### 要不要进 git

进 —— 项目级配置本来就该团队共享。但要知道两件事：

- **队友那边各自还要 `:trust` 一次**，而且文件一改，所有人都要重新信任。
  所以别把频繁变动的东西放进去。
- 别在里面写任何秘密（token、内网地址），它会跟着仓库走。

## 4. 项目专属的语言服务器设置

`:help 'exrc'` 里给了明确配方，两个文件：

```lua
-- .nvim.lua
vim.cmd([[set runtimepath+=.nvim]])
```

```lua
-- .nvim/lsp/lua_ls.lua
return {
  settings = {
    Lua = {
      diagnostics = { globals = { "PROJECT_ONLY_GLOBAL" } },
    },
  },
}
```

实测在本配置上生效：启动后 `:lua =vim.lsp.config.lua_ls` 里能看到
这份 settings 已经合进去了。

⚠ 注意优先级方向。见 [lua-api.md](./lua-api.md#四层配置的合并顺序)：
`.nvim/lsp/*.lua` 走的是「`runtimepath` 里的 `lsp/<名字>.lua`」这条路，
和 nvim-lspconfig 同属**第 2 层**；而本仓库的覆盖写在 `vim.lsp.config()`
里，是**第 4 层**。所以同一个键两边都设时，**是全局配置盖掉项目配置**，
不是反过来。

实测：项目里给 `basedpyright` 设 `disableOrganizeImports = false`，
最终生效的仍是 `lua/plugins/lsp.lua` 里的 `true`；而同一份项目配置里
另一个全局没设过的键，则原样保留下来了。所以项目级 LSP 配置只适合设
「全局没管过」的键。

顺带一提，很多语言服务器有自己的项目配置文件（`.luarc.json`、
`pyrightconfig.json`），能用那个就别用这一层 —— 回到第 1 层，不用开
`exrc`。

## 5. modeline（单个文件级）

写在文件的头或尾（默认查前后各 5 行，`modelines` 选项控制）：

```lua
-- vim: sw=2 ts=2 et
```

默认是开着的。只支持 `set`，不能执行命令；一部分选项被禁止在 modeline
里设（`exrc` 就是其中之一），这是防止别人的文件里藏东西。

适用场景很窄：一个仓库里只有某几个文件特殊，且不值得为它们写一段
`.editorconfig` 的 glob。跨编辑器不通用。

---

## 本仓库当前的状态

- **第 1 层在用**：`stylua.toml`。
- **第 2 层随时可用**：`.editorconfig` 是 Neovim 内置默认开的，
  往任意项目里丢一个就生效，本仓库自己没有这个文件。
- **`exrc` 没有开**：`lua/config/options.lua` 里没设它，保持默认的 off。
  需要项目级 Lua 配置时，在 options.lua 里加一行 `vim.o.exrc = true`，
  然后按上面的信任流程走。

## 自己验证的办法

```vim
:set exrc?                    " 开关状态
:lua =vim.b.editorconfig      " 当前文件吃到了哪些 editorconfig 属性
:lua =vim.g.editorconfig      " nil 或 true 表示开着
:verbose set shiftwidth?      " 当前值是被哪一层设的（会指出文件和行号）
:lua =vim.lsp.config.lua_ls   " 语言服务器最终生效的配置
:trust                        " 信任当前缓冲区这个文件
```

```bash
cat ~/.local/state/nvim/trust   # 信任库，纯文本
```

`:verbose set <选项>?` 是这一套里最有用的一条 —— 它会直接告诉你这个值
是 `options.lua` 设的、`.editorconfig` 设的，还是 modeline 设的。

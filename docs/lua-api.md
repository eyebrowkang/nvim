# Neovim Lua 配置 API 与机制

写配置时会反复用到的 API 区别、加载顺序等「机制层」知识。
纯操作技巧归到 [cheatsheet.md](./cheatsheet.md)。

---

## 设置项的四组入口：vim.opt / vim.o / vim.g / vim.b·w·bo·wo

Vimscript 里的 `:set`、`let g:` 在 Lua 里被拆成了几个不同的表，选错会踩坑。

### `vim.opt` —— 首选，等价于 `:set`

```lua
vim.opt.number = true
vim.opt.shiftwidth = 4
```

它返回的不是普通值，而是一个包装对象（Option 对象），因此对**列表型/字典型选项**
特别好用，可以增量修改而不是整体覆盖：

```lua
vim.opt.shortmess:append("I")           -- 追加，而不是把整个 shortmess 覆盖掉
vim.opt.wildignore:remove("*.o")        -- 移除单项
vim.opt.listchars = { tab = "» ", trail = "·" }  -- 用 Lua 表来写，比拼字符串清晰
```

读取时要用 `:get()`：`vim.opt.shiftwidth:get()` 才拿到数字 `4`，
直接 `vim.opt.shiftwidth` 拿到的是那个包装对象。

### `vim.o` —— 底层直接映射

```lua
vim.o.number = true
print(vim.o.shiftwidth)  -- 直接就是 4
```

只接受基础值（字符串/数字/布尔），**没有 `:append()` / `:remove()` 这些方法**。
好处是读写都是原始值，写脚本、做判断时更直接。

**选择标准：** 写配置用 `vim.opt`（尤其涉及列表型选项）；
在代码里读某个选项当前值用 `vim.o`。

### `vim.g` —— 全局变量，等价于 `let g:`

```lua
vim.g.mapleader = " "
vim.g.loaded_ruby_provider = 0
```

它不是「选项」，而是全局变量。典型用途：设置 leader 键、
关闭内置功能的开关、给插件传全局配置。

### `vim.bo` / `vim.wo` —— 缓冲区局部 / 窗口局部选项

有些选项本身就是「每个缓冲区/每个窗口各一份」的，改它们要指名道姓：

```lua
vim.bo.filetype              -- 当前缓冲区的 filetype
vim.bo[bufnr].buflisted = false   -- 指定缓冲区
vim.wo.wrap = false          -- 只改当前窗口的折行
```

本仓库 `lua/config/autocmds.lua` 里就用到了 `vim.bo[args.buf].buflisted = false`：
在 FileType 事件里必须操作**触发事件的那个缓冲区**，不能想当然用「当前缓冲区」。

> 对照表：`vim.g` 全局变量 · `vim.b` 缓冲区变量 · `vim.w` 窗口变量 · `vim.t` 标签页变量 ·
> `vim.v` Vim 预定义变量（如 `vim.v.event`）· `vim.env` 环境变量。

---

## 配置的生命线顺序

### 规则：`vim.g.mapleader` 必须早于所有按键映射和插件加载

```lua
-- init.lua 最顶部
vim.g.mapleader = " "
vim.g.maplocalleader = " "
```

**为什么**：`<leader>` 不是运行时才解析的占位符。定义映射的**那一刻**，
Neovim 就把 `<leader>` 替换成当时 `mapleader` 的实际值并写死进映射表。
之后再修改 `mapleader`，已经定义好的映射不会跟着变。

**顺序搞反的后果**：所有 `<leader>xxx` 映射都会绑到默认值反斜杠 `\` 上，
表现为「按空格没反应，按 `\` 却能触发」。插件尤其容易中招——
插件在加载时就会注册自己的 `<leader>` 映射。

**推论**：整个配置里 `mapleader` 只应该在一个地方设置一次，本仓库放在 `init.lua` 顶部。
散落在多个文件里会让人误以为改哪一处都生效。

### 本仓库的加载顺序

```
init.lua
  ├── vim.loader.enable()      -- 开 Lua 字节码缓存（必须在所有 require 之前）
  ├── vim.g.mapleader          -- 定 leader（必须在所有映射之前）
  └── require(...)
        ├── config.options     -- 选项：后面的映射/自动命令可能依赖它
        ├── config.keymaps     -- 按键映射
        └── config.autocmds    -- 自动命令
```

---

## `require` 是怎么找到文件的

```lua
require("config.options")   -- → lua/config/options.lua
```

Neovim 会在 `runtimepath` 里每个目录的 `lua/` 子目录下查找，点号翻译成路径分隔符。
`~/.config/nvim` 在 `runtimepath` 里，所以 `~/.config/nvim/lua/config/options.lua` 被命中。

两个要点：

- **有缓存**：同一个模块在一次会话里只会真正执行一次，第二次 `require` 直接返回缓存结果。
  改完配置想生效，`:source $MYVIMRC` 往往不够，可靠做法是重启 Neovim
  （或先 `package.loaded["config.options"] = nil` 再 require）。
- **`vim.loader.enable()`** 额外加了一层磁盘上的字节码缓存，按文件修改时间自动失效，
  改配置不需要手动清理。

---

## `vim.keymap.set` 的模式名

| 写法 | 含义 |
| --- | --- |
| `"n"` | Normal |
| `"i"` | Insert |
| `"x"` | Visual（真正的可视选区） |
| `"s"` | Select（选中后打字直接替换，代码片段占位符用的就是它） |
| `"v"` | **等于 `x` + `s` 两个** |
| `"o"` | Operator-pending（`d`、`y` 等待动作时） |
| `"t"` | Terminal |
| `""` | 等于 `n` + `v` + `o` |

**坑**：处理选区的映射（移动选中行、缩进保持选中等）要用 `"x"` 而不是 `"v"`。
用 `"v"` 会连 Select 模式一起改掉，将来用 snippet 在占位符之间跳转时，
按 `J`/`K`/`<`/`>` 本该替换掉占位符内容，却会去执行你的映射。

其他常用参数：

- `desc` —— 描述文字，会显示在 `:map` 输出和 which-key 之类的插件里，值得每条都写。
- `silent` —— 不在命令行回显被执行的命令。
- `buffer = bufnr` —— 只对某个缓冲区生效的局部映射。
- `expr = true` —— 把 rhs 当表达式求值，用返回值作为实际按键。
- **`noremap` 默认就是 `true`**，不用手写（这点和 Vimscript 的 `:map` 相反）。

### 查映射时会看到「和写的时候不一样」的字符串

`:map` 和 `vim.api.nvim_get_keymap()` 显示的是**存进映射表之后**的形式，
和源码里写的字面量对不上，按源码去搜会搜不到：

| 源码里写的 | 映射表里存的 | 原因 |
| --- | --- | --- |
| `<leader>y` | `" y"`（一个真实空格） | leader 在定义映射的那一刻就被替换成实际值了 |
| `<` | `<lt>` | `<` 是特殊记法的起始字符，必须转义才能表示自己 |
| `<C-l>` | `<C-L>` | 控制键组合统一规范化成大写 |

想确认「我到底改了什么、有没有盖掉内建默认」，最可靠的办法是和 `nvim --clean`
的映射表做差集，而不是肉眼比对：

```bash
nvim --clean --headless -c 'redir! > /tmp/clean.txt | map | redir END' -c 'qa!'
nvim          --headless -c 'redir! > /tmp/mine.txt  | map | redir END' -c 'qa!'
diff /tmp/clean.txt /tmp/mine.txt
```

### 用 `rhs` 时要记得默认不递归

映射默认 `noremap = true`，rhs 里的按键走的是**内建行为**，不会再经过其他映射。
所以 rhs 写 `Y` 拿到的是内建的 `Y`（整行），而不是 Neovim 默认映射里的 `Y`（= `y$`）。
想表达哪个意思就把它直接写出来，别依赖「按下去会怎样」的直觉。

---

## 已改名的 API 对照表

网上搜到的资料里常见左列的写法，本仓库统一用右列。

| 曾用名 | 现用名 | 变更版本 |
| --- | --- | --- |
| `vim.highlight` | `vim.hl` | 0.11 |
| `vim.loop` | `vim.uv` | 0.10 |
| `vim.lsp.buf_get_clients()` | `vim.lsp.get_clients()` | 0.10 |

曾用名通常还留着一个废弃别名，能跑，但会被 `:checkhealth vim.deprecated` 标出来，
并且计划在未来版本移除。

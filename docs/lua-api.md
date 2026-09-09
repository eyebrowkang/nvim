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

## lazy.nvim 写 spec 时的五个坑

### 1. 懒加载用哪个事件，取决于插件靠哪个事件工作

打开一个文件时，事件顺序是 **`FileType` 在前，`BufReadPost` 在后**。

很多插件是靠自己注册的 `FileType` 自动命令挂到缓冲区上的。
如果用 `event = "BufReadPost"` 懒加载这种插件，它被加载出来时 `FileType`
已经放过去了，它的自动命令就永远错过当前这个缓冲区，表现为
「开第一个文件没效果，手动 `:e` 一下或切个文件类型才出现」。

改用 `event = "FileType"` 就好：lazy.nvim 把插件加载完之后，
会把刚才触发的那个事件原样重新广播一次，插件自己的处理函数就接上了。

确认事件顺序的办法：

```bash
nvim --headless -c 'edit some.lua' -c 'qa!' -V15/tmp/ev.log
grep -n "Executing FileType\|Executing BufReadPost" /tmp/ev.log
```

### 2. 模块名和仓库名对不上时要写 `main`

lazy.nvim 从仓库名推断该在哪个模块上调 `setup()`。推断规则大致是去掉
`nvim-` 前缀和 `.nvim` / `.lua` 后缀，所以 `nvim-colorizer.lua` → `colorizer` 能猜中，
但 `indent-blankline.nvim` 的模块其实叫 `ibl`，猜不中，必须显式写 `main = "ibl"`。

### 3. 不是每个插件都有 `setup()`

「装插件先调 `setup()`」只是社区惯例，不是规矩。
例如 rainbow-delimiters 读的是全局变量 `vim.g.rainbow_delimiters`，根本没有 `setup()`；
给它写 `opts` 会让 lazy.nvim 去调用一个不存在的函数。装之前翻一眼 README。

反过来，光有 `setup()` 也不一定够 —— 配色插件还得再执行一次 `:colorscheme` 才真正生效，
所以 `colorscheme.lua` 用的是 `config` 而不是 `opts`。

### 4. 有的插件自己就会调 `setup()`，写了 `opts` 就跑两遍

少数插件（barbar 是一个）在被加载时会自动调一次 `setup()`。
这时再写 `opts`，lazy.nvim 又会调一次，等于初始化跑了两遍。
这类插件通常留了一个全局开关来关掉自动调用，要用 `init` 设置 ——
`init` 在插件加载**之前**执行，用 `config` 就来不及了：

```lua
init = function() vim.g.barbar_auto_setup = false end,
opts = { ... },
```

### 5. `opts` 里要用插件自己的函数时，必须写成函数

`opts` 通常写成一张表。但如果表里的值需要调用插件自己的函数才能算出来，
写成表就会出错 —— 表里的表达式在**读配置文件时**就求值了，那时插件还没加载：

```lua
-- ✗ 报错：模块 mini.ai 不存在
opts = {
  custom_textobjects = { m = require("mini.ai").gen_spec.treesitter({ ... }) },
}

-- ✓ lazy.nvim 认函数形式，会等插件加载完再调用它拿返回值
opts = function()
  local ai = require("mini.ai")
  return {
    custom_textobjects = { m = ai.gen_spec.treesitter({ ... }) },
  }
end,
```

判断标准很简单：`opts` 里出现了 `require("这个插件")`，就得写成函数。

### 附：`keys` 和 `lazy = false` 可以同时写

`keys` 字段有两个作用：**注册按键映射**，以及**让这些键触发懒加载**。
写了 `lazy = false` 只是取消了第二个作用，映射照常注册。
所以插件即使不懒加载，按键也应该写在它自己的 spec 里，
这样插件和它占用的按键是一份东西，删文件就一起没了，不会留下死键。

---

## 插件自己绑了按键怎么办

不是所有插件都像 flash 那样「你不绑它就不占键」。
有一类插件在 `setup()` 里、或者在自己的 `plugin/` 目录里，直接就把键绑上了。
这时想改键、想让位给别的插件，有四种手段，按「可控程度」从高到低：

### 1. 用插件给的开关关掉，然后自己绑

最干净，因为结果和加载顺序无关。开关长什么样各家不同：

```lua
-- mini 系列：把映射名设成空字符串
opts = { mappings = { toggle = "" } }        -- mini.splitjoin 的 gS

-- nvim-surround：整组模式开关，而且必须在 init 里设
-- （它的键定义在插件的 plugin/ 目录，比 config 更早执行）
init = function() vim.g.nvim_surround_no_visual_mappings = true end,
```

`splitjoin.lua` 用的就是第一种：插件默认把 `gS` 同时绑在普通和可视两个模式上，
可视模式那个和 nvim-surround 撞车，而它没法只关一半，于是整个关掉、
再用 `keys` 补回普通模式那一个。

### 2. 重绑到插件的 `<Plug>` 映射

插件如果暴露了 `<Plug>(xxx)` 形式的入口，直接在 `keys` 里指过去。
好处是能顺便写上中文 `desc`，which-key 里看到的就是中文：

```lua
keys = {
  { "ys", "<Plug>(nvim-surround-normal)", desc = "给一段文本加环绕符号" },
}
```

### 3. 只写按键、不写动作（纯触发）

`keys` 条目里省掉动作那一项，lazy.nvim 的行为是：按下时先加载插件，
让插件在 `setup()` 里绑好自己的键，然后把这个键**重新发一遍**，交给插件的映射处理。

```lua
keys = {
  { "ga", mode = { "n", "x" }, desc = "按分隔符对齐" },
}
```

适合插件的按键实现依赖内部私有状态、外面复刻不出来的情况（`align.lua` 就是）。
代价是加载之后 `desc` 会被插件自己的英文说明覆盖掉。

### 4. 什么都不做，靠加载顺序 —— 不要这样

两个插件抢同一个键时，后加载的赢。这能「碰巧」跑通，
但加载时机会随懒加载触发条件变化，哪天按键就换主人了，还很难查。

### 另外：缓冲区局部映射永远赢过全局映射

这条和插件无关，是 Vim 的规则，但排查「为什么只有这种文件里不好使」时必用。
Neovim 自带的 ftplugin 会给特定文件类型绑缓冲区局部的键，例如
`ftplugin/python.vim` 绑了 `]m` / `[m`，`ftplugin/markdown.vim` 绑了 `[[` / `]]`。
全局绑同样的键，在这些文件里不会生效。

```vim
" 哪些内置 ftplugin 绑了键（这些都认 no_plugin_maps 开关）。
" 要在 Neovim 里执行 —— $VIMRUNTIME 是 Neovim 自己设的环境变量，
" 普通终端里没有这个值。
:!grep -rl no_plugin_maps $VIMRUNTIME/ftplugin/

" 想知道某个键在当前文件里归谁管，这条最直接（会打印定义它的文件和行号）
:verbose map ]m
```

想整体关掉：`vim.g.no_plugin_maps = true`；想只关一种：`vim.g.no_python_maps = true`。

⚠ 这两个开关是用 `exists()` 判断的，只看变量**存不存在**，不看值。
写 `vim.g.no_python_maps = false` 一样会把映射关掉。不想关就别设这个变量
（要撤销得写 `vim.g.no_python_maps = nil`）。

本配置两个都没设 —— `ts-textobjects.lua` 里的 `]m` 在 Python 文件中会让位给内置那份，
但两者做的是同一件事，感觉不出差别，不值得为它把一整套 ftplugin 映射关掉。

---

## nvim-treesitter 在 0.12 上的两个陷阱

### 1. 有两条完全不兼容的分支

| 分支 | 面向 | API |
| --- | --- | --- |
| `main` | Neovim 0.12+ | `require("nvim-treesitter").install{...}`，`setup()` 可选 |
| `master` | 0.11 及更早，已冻结 | `setup{ ensure_installed = ..., highlight = { enable = true } }` |

网上大量教程写的是 `master` 那一套。照抄到 `main` 上不会报错，**会静默无效** ——
`setup()` 收下那张表然后忽略掉不认识的字段。
所以 spec 里必须显式写 `branch = "main"`，看到 `ensure_installed` 就知道那是旧分支的写法。

### 2. 装了解析器 ≠ 高亮就开了

Neovim 0.12 **没有**「装了解析器就自动用」的通用机制。
整个运行时里只有四个 ftplugin 文件主动调了 `vim.treesitter.start()`：

```bash
grep -rl "treesitter.start" "$VIMRUNTIME/ftplugin/"
# lua.lua  markdown.lua  query.lua  help.lua
```

其余语言要自己写一条 `FileType` 自动命令。判断解析器在不在的写法：

```lua
local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
if lang and vim.treesitter.language.add(lang) then
  vim.treesitter.start(buf, lang)
end
```

两个 API 的行为值得记住：

- `language.get_lang(ft)` 把**文件类型**翻译成**解析器名**（`sh` → `bash`，`jsonc` → `json`）。
  没有登记过映射时原样返回文件类型名。
- `language.add(lang)` 加载成功返回 `true`，找不到返回 `nil` —— **不抛错**，
  所以可以直接当 `if` 的条件用，不需要包 `pcall`。

确认某个缓冲区到底有没有用上 treesitter：

```vim
:Inspect
```

把光标停在有颜色的字符上执行，列出的高亮组里出现 `@` 开头的（`@keyword.lua` 之类）
就说明是 treesitter 在高亮；只有 `Identifier`、`Statement` 这种没有 `@` 的老组名，
说明还在用正则高亮。

想要一个 true/false 的答案：

```vim
:lua =vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil
```

⚠ 这张表的键是**真实缓冲区号**，不接受 `0` 这个「当前缓冲区」的简写 ——
很多 Neovim API 认 `0`，但它只是一张普通 Lua 表，写 `active[0]` 永远得到 `false`。

---

## 验证插件效果时，别用脚本驱动光标

很多插件（缩进参考线的作用域高亮、彩虹括号等）是在**真实重绘和真实光标移动**时
才更新的。在 `vim.defer_fn` 里用 `vim.cmd("normal! 10G")` 挪光标，
产生的事件流和真人按键不一样，插件可能完全不刷新，看起来像「功能坏了」。

可靠的做法是让另一个 Neovim 通过 RPC 把**真实按键**送进去：

```bash
# 终端 A：在真实终端里启动，开一个 socket
nvim --listen /tmp/nvim.sock file.lua

# 终端 B：送真实按键进去，再让它把结果写到文件
nvim --server /tmp/nvim.sock --remote-send 'jjjj'
nvim --server /tmp/nvim.sock --remote-send ':luafile /tmp/dump.lua<CR>'
```

看「屏幕上到底画了什么」用 `vim.fn.screenstring(行, 列)`，
它读的是渲染完成后的屏幕内容，比猜插件内部状态可靠。

查高亮时注意：extmark 的 `hl_group` **可能是一组高亮组而不是一个字符串**，
虚拟文本还挂在 `virt_text` 里而不是 `hl_group` 上；只取第一个会漏掉真正想找的那个。
另外 `nvim_get_namespaces()` 列不出匿名命名空间（`nvim_create_namespace("")`），
统计缓冲区里全部高亮要用 `nvim_buf_get_extmarks(buf, -1, ...)`，`-1` 表示所有命名空间。

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

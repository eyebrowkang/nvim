# Neovim 配置

一份从零手写、逐步长大的 Neovim 配置。插件管理器：**lazy.nvim**。

目标是每一行配置都能说清楚「为什么这么写」，所以所有配置项都带中文注释。

核心原生配置（`lua/config/options|keymaps|autocmds.lua`）不依赖任何插件，
即使插件全部出问题也照常生效。

## 环境

| 项 | 值 |
| --- | --- |
| Neovim | 0.12.4（最低 0.11：`vim.hl`、`winborder`、`vim.lsp.config`、`gr*` 内置映射） |
| 目标平台 | **macOS 与 Linux 通用**，不写平台专属配置 |
| 当前主力环境 | macOS + Ghostty，Neovim 由 MacPorts 安装（`/opt/local`） |
| 字体 | **需要 Nerd Font**，否则图标显示成豆腐块。终端里指定即可，Neovim 不管字体 |
| 配置路径 | `~/.config/nvim`（即 `$XDG_CONFIG_HOME/nvim`） |
| 状态数据 | `~/.local/state/nvim/`（undo 历史等，两个平台一致） |

## 外部命令依赖

有几个插件是在调用命令行工具，Neovim 本身不带这些，得单独装。
**没装的话 Neovim 照常启动、其他功能不受影响**，只是对应那个插件一用就报「找不到命令」。

| 命令 | 谁要用 | 缺了会怎样 |
| --- | --- | --- |
| `ripgrep` | fzf-lua、grug-far、todo-comments | 搜不了内容，只影响搜索类功能 |
| `fzf` | fzf-lua | 所有 `<leader>f` 快捷键都不出界面 |
| C 编译器 | nvim-treesitter | 装不了新解析器，已装的照常用 |
| `tree-sitter` | nvim-treesitter | 同上 |
| `git` `curl` | blink.cmp（下载补全用的预编译二进制） | 补全菜单出不来 |
| `node` `npm` | mason 装的大部分语言服务器 | 那几个服务器装不上，其余照常 |
| `python3` + venv | mason 装 basedpyright 时要建虚拟环境 | Python 的类型检查装不上 |
| `lazygit` | `<leader>gg` 的 git 操作界面 | 按 `<leader>gg` 弹一条提示，别的不受影响 |

「按语法」的那些功能都建立在解析器之上：某个语言没装解析器时，
它的文件里 `am` / `ic` / `i=` / `]m` / `S` 会不生效，其余按键照常。

语言服务器不需要手动装：换台机器后第一次用 Neovim 打开任意文件时，
mason 会把 [lua/plugins/lsp.lua](lua/plugins/lsp.lua) 里 `ensure_installed` 那张表
缺的一次性装齐（这一次会等上几分钟，之后就不再有了；进度看 `:Mason`）。

但**格式化器和 linter 不是语言服务器，`ensure_installed` 管不着**，要手动装一次：

```vim
:MasonInstall stylua prettierd markdownlint-cli2
```

```bash
# macOS
brew install ripgrep fzf tree-sitter node lazygit
xcode-select --install                      # C 编译器

# Debian / Ubuntu
sudo apt install ripgrep fzf build-essential python3-venv python3-pip
# lazygit 不在 apt 源里，从 github.com/jesseduffield/lazygit 的 release
# 下对应架构的 tar.gz，解出来的 lazygit 放进 PATH 即可。
# Node.js 用 nvm 装（apt 源里的版本通常过旧），装完 nvm 再 nvm install --lts：
#   github.com/nvm-sh/nvm 的 README 里有安装命令
# tree-sitter CLI 要求 >= 0.26.1，apt 源里的版本通常过旧，
# 从 github.com/tree-sitter/tree-sitter 的 release 下二进制放进 PATH。
# 官方明确说不要用 npm 装。
```

装完用 `tree-sitter --version` 等命令自查，或在 Neovim 里：

```vim
:checkhealth fzf_lua           " 注意是下划线；要先按一次 <leader>ff 让插件载入
:checkhealth nvim-treesitter
:checkhealth mason             " 语言服务器安装器要的外部命令齐不齐
:checkhealth vim.lsp           " 当前挂了哪些语言服务器、各自的日志在哪
:checkhealth blink.cmp         " 补全用的二进制下下来没有
```

## 目录结构

```
.
├── init.lua                    # 入口：开缓存 → 定 leader → 按顺序 require
├── lazy-lock.json              # 插件版本锁文件，由 lazy.nvim 生成，必须进 git
├── stylua.toml                 # Lua 格式化规则（<leader>cf 调 stylua 时读它）
├── lua/
│   ├── config/                 # 核心原生配置（不依赖任何插件）
│   │   ├── options.lua         # 选项：行号、缩进、搜索、剪贴板、持久化、折叠、消息界面…
│   │   ├── keymaps.lua         # 全局按键映射
│   │   ├── autocmds.lua        # 自动命令：复制高亮、恢复光标、q 关辅助窗口
│   │   └── lazy.lua            # 引导并启动插件管理器 lazy.nvim
│   └── plugins/                # 插件声明，每个文件返回一张 spec 表，自动全部导入
│       ├── colorscheme.lua     # 配色：tokyonight（storm 风格）
│       ├── icons.lua           # 图标库：mini.icons，供其他插件调用
│       ├── lualine.lua         # 状态栏：lualine
│       ├── barbar.lua          # 顶部 buffer 栏：barbar
│       ├── indent.lua          # 缩进参考线：indent-blankline
│       ├── rainbow.lua         # 彩虹括号：rainbow-delimiters
│       ├── colorizer.lua       # 颜色代码高亮：nvim-colorizer
│       ├── alpha.lua           # 起始页：alpha-nvim
│       ├── treesitter.lua      # 语法解析：nvim-treesitter（高亮的底座）
│       ├── ts-context.lua      # 上下文粘顶：nvim-treesitter-context
│       ├── lsp.lua             # 语言服务器：mason + mason-lspconfig + nvim-lspconfig
│       ├── lazydev.lua         # 让 lua_ls 认识 vim.* 这些 Neovim API：lazydev
│       ├── cmp.lua             # 自动补全 + Snippet：blink.cmp + friendly-snippets
│       ├── conform.lua         # 格式化：conform.nvim
│       ├── lint.lua            # 独立 linter（补语言服务器不管的）：nvim-lint
│       ├── neotree.lua         # 文件树：neo-tree
│       ├── fzf.lua             # 模糊查找：fzf-lua
│       ├── grug-far.lua        # 全项目搜索替换：grug-far
│       ├── todo.lua            # 待办注释高亮：todo-comments
│       ├── flash.lua           # 光标快速跳转：flash
│       ├── autopairs.lua       # 括号引号自动配对：nvim-autopairs
│       ├── surround.lua        # 环绕符号的增删改：nvim-surround
│       ├── mini-ai.lua         # 文本对象增强：mini.ai
│       ├── ts-textobjects.lua  # 按语法跳转 / 交换参数：nvim-treesitter-textobjects
│       ├── autotag.lua         # HTML 标签自动闭合与联动改名：nvim-ts-autotag
│       ├── splitjoin.lua       # 参数列表拆行 / 合行：mini.splitjoin
│       ├── align.lua           # 按分隔符对齐：mini.align
│       ├── gitsigns.lua        # Git 改动标记与 hunk 操作：gitsigns
│       ├── toggleterm.lua      # 终端 + lazygit 浮窗：toggleterm
│       ├── trouble.lua         # 诊断与列表面板：trouble
│       ├── persisted.lua       # 会话恢复：persisted
│       ├── render-markdown.lua # Markdown 就地渲染：render-markdown
│       └── whichkey.lua        # 按键提示：which-key
├── docs/
│   ├── notes.md                # 收件箱：随手记，定期清空归档到下面两个文件
│   ├── cheatsheet.md           # 操作技巧速查（怎么用 Vim）
│   ├── lua-api.md              # 配置机制与 Lua API（怎么写配置）
│   └── project-config.md       # 专题：给单个项目做专属配置
└── logs/                       # 临时调试日志，不进 git
```

插件本体装在 `~/.local/share/nvim/lazy/`，是下载来的产物，不进这个仓库。

`docs/` 下除了两份速查，成体系的话题另开一篇：
[project-config.md](docs/project-config.md) 讲怎么给单个项目做专属配置 ——
不同项目不同缩进、项目专属的语言服务器设置、项目专属的映射，
相当于 VSCode 的 workspace settings。

## 加载顺序

```
init.lua
  ├── vim.loader.enable()   # Lua 字节码缓存，必须在所有 require 之前
  ├── vim.g.mapleader = " " # leader 必须在所有映射之前，全仓库只设这一次
  ├── require config.options → config.keymaps → config.autocmds
  └── require config.lazy   # 必须最后：它会接管启动流程并开始加载插件
```

为什么顺序不能乱，见 [docs/lua-api.md](docs/lua-api.md#配置的生命线顺序)。

## 按键总览

leader 键是**空格**。按下空格停顿一下，which-key 会把下一层选项列出来，
所以这张表不用背 —— 记住分组字母就够了。

| 前缀 | 用途 |
| --- | --- |
| `<leader>e` `<leader>E` | 文件树：切换 / 定位当前文件 |
| `<leader>f…` | **f**ind，查找：文件、内容、buffer、帮助、按键、待办 |
| `<leader>s…` | **s**earch & replace，全项目搜索替换 |
| `<leader>b…` | **b**uffer 标签栏操作 |
| `<leader>c…` | **c**ode，代码相关：格式化、内嵌提示开关、上下文粘顶开关 |
| `<leader>g…` | **g**it：改动的暂存 / 回滚 / 预览 / blame，以及 lazygit |
| `<leader>t…` | **t**erminal，终端：浮窗 / 底部 / 侧边 |
| `<leader>x…` | 诊断列表面板：诊断 / 大纲 / 引用 / quickfix（trouble） |
| `<leader>q…` | 会话：恢复上次开着的那些文件和窗口布局（persisted） |
| `<leader>a` `<leader>A` | **a**rgument，当前参数和后一个 / 前一个对调位置 |
| `<leader>y` `<leader>p` | 系统剪贴板复制 / 粘贴（普通寄存器保持独立） |
| `<leader>?` | 列出当前缓冲区里所有可用按键 |

移动与窗口：

| 按键 | 用途 |
| --- | --- |
| `s` | 跳到屏幕上任意位置（flash，覆盖了原生 `s`，等价写法 `cl`） |
| `S` | 按语法结构选中（flash；只在普通和算子模式，覆盖了原生 `S`，等价写法 `cc`） |
| `]m` `[m` | 跳到下 / 上一个函数定义的开头 |
| `]M` `[M` | 跳到下 / 上一个函数定义的结尾 |
| `<C-w>` + 方向 | 窗口间移动（Neovim 内置） |
| `<C-方向键>` | 调整窗口大小 |
| `<C-l>` | 清掉搜索高亮（Neovim 内置） |
| `za` `zR` `zM` | 折叠：切换当前 / 全展开 / 全折起（Neovim 内置，按语法树分块） |
| `g<` | 调出最近的消息全文（Neovim 内置） |
| `[b` `]b` | 上一个 / 下一个 buffer（Neovim 内置） |
| `[q` `]q` | quickfix 列表前后跳（Neovim 内置） |
| `gc` | 切换注释（Neovim 内置，接动作或在可视模式用） |

编辑与文本对象：

| 按键 | 用途 |
| --- | --- |
| `a` / `i` + 代号 | 文本对象，跟在 `d` `c` `y` `v` 后面用；代号见下 |
| `aN` `iN` / `aL` `iL` | 同上，但取光标之后 / 之前的那一个，如 `ciNq` 改后面那对引号里的内容 |
| `g[` `g]` | 跳到当前文本对象的左 / 右边界，如 `g]f` 跳到函数调用的右括号 |
| `an` `in`（可视模式） | 按语法逐层扩大 / 缩小选区（Neovim 内置） |
| `ys` + 动作 + 符号 | 给一段文本加环绕符号，如 `ysiw"`；`yss` 是整行 |
| `ds` + 符号 | 删掉环绕符号，如 `ds"` |
| `cs` + 旧 + 新 | 替换环绕符号，如 `cs"'` |
| `yS` `ySS` `cS` | 同上三个，但让符号各占一行 |
| `S`（可视模式） | 把选中内容包起来；`gS` 是包起来并各占一行 |
| `<C-g>s`（插入模式） | 在光标处插入一对环绕符号 |
| `gS` | 参数列表拆成多行 / 合成一行（普通模式） |
| `ga` `gA` | 按分隔符对齐 / 带预览地对齐（覆盖了原生 `ga`，等价写法 `:ascii`） |
| `<M-e>`（插入模式） | 把光标后面的内容用一对括号包住 |

文本对象代号（`a` = 含边界，`i` = 不含边界）：

| 代号 | 范围 |
| --- | --- |
| `w` `W` `s` `p` | 词 / 句 / 段（Neovim 内置） |
| `(` `[` `{` `<` | 各种括号；用左半边如 `i(` 会顺带去掉内侧空格，用右半边 `i)` 不会 |
| `"` `'` `` ` `` | 各种引号 |
| `b` `q` | `b` = 任意一种括号，`q` = 任意一种引号（懒得挑的时候用） |
| `a` | 一个函数参数：`aa` 含逗号，`ia` 只要参数本身 |
| `f` | 一次函数调用 `foo(x, y)` |
| `t` | 一对 HTML 标签 |
| `?` | 现场输入左右边界，用来对付上面没覆盖的怪符号 |
| `m` `c` `=` | 函数定义 / 类 / 赋值语句，靠 treesitter 认语法；`ci=` 就是「换掉这个变量的值」 |

代码智能。**这一组全部是 Neovim 0.12 内置的，配置里一个都没映射**，
文件挂上语言服务器就能用（`:help lsp-defaults`）：

| 按键 | 用途 |
| --- | --- |
| `K` | 悬浮显示光标处符号的文档；再按一次进浮窗，`q` 关掉 |
| `<C-]>` | 跳到定义（`<C-t>` 跳回来） |
| `grn` | **r**e**n**ame，重命名符号：改一处，全项目的引用一起改 |
| `gra` | code **a**ction，代码操作：自动导入、快速修复……普通和可视模式都能用 |
| `grr` | **r**eferences，列出所有引用 |
| `gri` | **i**mplementation，跳到实现 |
| `grt` | **t**ype，跳到类型定义 |
| `gO` | **o**utline，列出本文件的符号大纲 |
| `<C-s>`（插入模式） | 显示当前函数的参数签名 |
| `gq` + 动作 | 按语言服务器的规则格式化一段范围 |

自己映射的三个：

| 按键 | 用途 |
| --- | --- |
| `<leader>cf` | 格式化整个文件；可视模式下只格式化选区（conform.nvim） |
| `<leader>ch` | 开关内嵌提示（Neovim 内置，见下） |
| `<leader>ct` | 开关上下文粘顶（nvim-treesitter-context） |

两样不用按键、自动生效的显示：

- **内嵌提示（inlay hints）**：语言服务器把推断出来的类型、参数名以浅色小字
  画进代码行里（`local x: number = f()`、`setTimeout(callback: fn, delay: 1000)`）。
  纯虚拟文本，源文件没有变化，复制粘贴带不走。默认开着，在
  `lua/config/options.lua` 第 9 节；碍事时按 `<leader>ch` 临时关掉。
- **同名符号高亮**：光标在一个变量上停 250ms，它在本文件里的其他出现位置
  一起亮起来，读和写用不同的高亮组区分。走的是语言服务器的
  `textDocument/documentHighlight`，同名但不同作用域的变量不会被算进来。
  Neovim 自带这个能力但默认不接线，胶水在 `lua/config/autocmds.lua` 第 4 节，
  没有装插件。

上下文粘顶是第三样：函数写长了往下滚，外层的函数签名、`if`、`for` 会钉在
窗口最上面，最多 3 行。同样靠 treesitter 的语法树，不是按缩进猜的。

诊断（就是代码里的错误和警告，显示样式在 `lua/config/options.lua` 第 9 节）：

| 按键 | 用途 |
| --- | --- |
| `]d` `[d` | 下一条 / 上一条诊断（Neovim 内置） |
| `]D` `[D` | 本文件最后一条 / 第一条诊断（Neovim 内置） |
| `<C-w>d` | 浮窗显示光标所在行的诊断全文，消息太长被截断时用（Neovim 内置） |
| `<leader>xx` `<leader>xX` | 面板列出全项目 / 当前文件的诊断（trouble） |
| `<leader>xs` | 当前文件的符号大纲，会跟着光标走（trouble） |
| `<leader>xl` | 光标下这个符号的定义 / 引用 / 实现（trouble） |
| `<leader>xq` `<leader>xL` | quickfix / location list 改用同一个面板显示（trouble） |

上面三种诊断入口的分工：`]d` `[d` 逐条改最快，`<leader>xx` 适合先看总量，
`gO` 是不会自己刷新的一次性快照。面板里按 `?` 列出它自己的全部按键。

会话（persisted，把「当时开着哪些文件、窗口怎么分」存下来，一个目录一份）：

| 按键 | 用途 |
| --- | --- |
| `<leader>qs` | 恢复当前目录的会话 |
| `<leader>ql` | 恢复最近保存的那一个（不限目录） |
| `<leader>qS` | 列出所有会话挑一个；选别的目录会连 cwd 一起切过去 |
| `<leader>qd` | 本次退出不保存 |

保存是自动的（退出时写盘），恢复要手动按键 —— 启动照常停在起始页。
**带文件名启动（`nvim a.lua`）时不记录会话**，这是插件的设计，
要记就手动 `:Persisted start`。

补全菜单（blink.cmp，用的是它的 `default` 预设 —— 全部是 `Ctrl` 组合键，
不占用 `<CR>` 和 `<Tab>`，所以打字节奏完全不受影响）：

| 按键 | 用途 |
| --- | --- |
| `<C-n>` `<C-p>` | 选下一个 / 上一个候选（`<Down>` `<Up>` 同义） |
| `<C-y>` | **y**es，确认选中的候选 |
| `<C-e>` | 关掉菜单，保留已经打出来的字 |
| `<C-space>` | 手动唤出菜单；菜单已开时切换右侧文档面板 |
| `<C-b>` `<C-f>` | 文档面板内容太长时上下翻页 |
| `<Tab>` `<S-Tab>` | **仅在代码片段展开后**：跳到下一个 / 上一个待填空位 |

函数签名不归它管，用上面内置的 `<C-s>`。

Git（gitsigns，**只在 git 仓库里的文件上生效**）。
「hunk / 块」是连续的一段改动，也是 git 能单独暂存的最小单位：

| 按键 | 用途 |
| --- | --- |
| `]h` `[h` | 下一处 / 上一处改动 |
| `]H` `[H` | 本文件最后一处 / 第一处改动 |
| `<leader>gs` | 暂存这一块；停在已暂存的块上再按一次就撤销暂存。支持 `.` 重复 |
| `<leader>gr` | 回滚这一块（改的是缓冲区，按错了 `u` 就回来）。支持 `.` 重复 |
| `<leader>gs` `<leader>gr`（可视模式） | 只处理选中的那几行，一块里也能只挑一部分 |
| `<leader>gS` `<leader>gR` | 暂存 / 回滚整个文件 |
| `<leader>gp` | 浮窗预览这一块的完整 diff（删掉的行只能在这看到） |
| `<leader>gb` | 光标这一行是谁、什么时候、哪个提交改的 |
| `<leader>gB` | 侧边开窗，整个文件逐行 blame |
| `<leader>gd` | 和上次提交并排对比（进内置 diff 模式，`]c` `do` `dp` 都能用） |
| `<leader>gq` | 全仓库未提交的改动进 quickfix，然后 `]q` `[q` 逐个过 |
| `<leader>gt` | 开关「每行行尾显示 blame」 |
| `ih` | 文本对象：这一块改动。`vih` 选中，`dih` 删掉 |

先按 `<leader>gp` 打开预览浮窗，再按 `]h`，浮窗会跟着跳到下一块 ——
相当于一路翻着看这次都改了什么。

终端（toggleterm）。同一个键按第二次收回去，**进程继续在后台跑，输出不会丢**：

| 按键 | 用途 |
| --- | --- |
| `<leader>gg` | lazygit 浮窗：提交、切分支、rebase、看历史，完整的 git 操作都在这 |
| `<leader>tf` | 浮窗终端（1 号） |
| `<leader>th` | 底部终端（2 号，15 行高） |
| `<leader>tv` | 侧边终端（3 号，占 40% 宽） |
| `<leader>ts` | 在多个终端之间选一个跳过去 |
| `<C-\><C-n>` | 从终端里退回普通模式，之后可以滚动、复制、切窗口（Neovim 内置） |
| `[[` `]]` | 终端里在 shell 提示符之间跳（Neovim 内置，需要 shell 发 OSC 133） |

三个键是三个各自独立的 shell，可以一个跑测试、一个跑服务器、一个随手敲。
还想要更多直接敲 `:4ToggleTerm`，编号任意。

终端里没有把 `<Esc>` 映射成退出 —— lazygit、less、htop 这些程序自己要用 Esc。

内置映射的完整清单：`:help default-mappings`。
想查某个键现在归谁管，用 `<leader>fk` 或 `:verbose map <键>`。

> `<M-e>` 是 Alt/Option 组合。macOS 的终端默认把 Option 当成「打特殊字符」的键，
> 发不出 Alt 组合。Ghostty 在 `~/.config/ghostty/config` 里加一行
> `macos-option-as-alt = true` 即可。

## 插件常用命令

```vim
:Lazy            " 打开管理面板（I 装 / U 更新 / X 清理 / 大写 S 查看启动耗时）
:Lazy sync       " 一次搞定：装缺的、删多的、更新到锁文件之外的最新版
:Lazy restore    " 按 lazy-lock.json 把所有插件回滚到锁定的版本
:Lazy health     " 等价于 :checkhealth lazy
```

语言服务器与格式化：

```vim
:Mason                    " 安装器面板（i 装 / X 卸 / u 更新 / U 全部更新；g? 看完整按键）
:MasonInstall stylua      " 直接装某个工具，格式化器和 linter 都靠它
:MasonLog                 " 装不上时看这里，报错原因全在日志里
:checkhealth vim.lsp      " 当前挂了哪些服务器、根目录认到哪、日志文件在哪
:lua =vim.lsp.config.lua_ls   " 查某个服务器最终生效的配置（合并过所有层之后的）
:lsp restart              " 改完配置或服务器卡住时重启它（还有 enable/disable/stop）
:ConformInfo              " 当前文件会用哪个格式化器、它装了没有
:LazyDev                  " 查 lua_ls 当前加载了哪些库（补全不出 vim.* 时看这个）
```

Git 与终端：

```vim
:Gitsigns                 " 所有 gitsigns 操作都能当子命令用，带补全
:Gitsigns change_base ~1  " 换个对比基准：不跟上次提交比，跟再往前一个比
:Gitsigns show ~1         " 打开某个版本的这个文件（只读）
:4ToggleTerm              " 开第 4 个终端；direction=float/horizontal/vertical 指定形态
:TermExec cmd="make test" " 把命令送进终端里执行
```

面板、会话与 Markdown：

```vim
:Trouble diagnostics toggle   " 写法是 :Trouble {模式} {动作} {选项=值}，带补全
:Trouble symbols toggle win.position=right   " 临时改这一次的面板位置
:Persisted save 名字        " 存一份带名字的会话（不带名字就按当前目录存）
:Persisted delete           " 列出会话，挑一个删掉
:Persisted clean            " 清掉那些目录已经不存在了的会话文件
:RenderMarkdown toggle      " 临时关掉 Markdown 渲染，看原始文本
:checkhealth render-markdown " 解析器和可选的 LaTeX 转换命令齐不齐
```

## 约定

- **所有配置项必须有注释**，写清楚它做什么、以及为什么选这个值。
  被刻意「不设置」的选项，也用注释说明为什么不设（例如 `options.lua` 里的 `smartindent`、`clipboard`）。
- **注释只描述当前配置**：讲含义和取舍，不记录「以前是什么样、改了什么」——那是 git 的职责。
- **跨平台**：macOS 和 Linux 上都要能直接用，不引入平台专属写法。
  确实需要区分时用 `vim.fn.has("mac")` 之类判断，并在注释里说明原因。
- **保持克制**：想要的行为如果 Neovim 内置默认映射已经提供（`:help default-mappings`），
  就不要再映射一遍。已有的内置能力清单见 [docs/cheatsheet.md](docs/cheatsheet.md)。
- **`docs/notes.md` 是收件箱**，随手往里丢。定期分类归档：
  操作技巧 → `cheatsheet.md`，配置写法/API/机制 → `lua-api.md`，归档后清空 notes。
  攒够一个成体系的话题（塞进上面两份会喧宾夺主的），在 `docs/` 下单开一个文件。
- **Lua 代码风格交给 stylua**，规则写在根目录的 `stylua.toml` 里（2 空格、双引号、120 列）。
  排版上不要和它较劲：手工对齐的行尾注释会被它拆掉，多个短项挤在一行也会被拆成每行一个。
  想让注释管住一组项，把注释写在这组的**上面**，别写在行尾——
  拆行之后行尾注释只会跟着最后一项，读起来就变成假的了。
  改完按 `<leader>cf` 或跑 `stylua .` 统一一遍。
- **`logs/` 不进 git**，只保留 `.gitkeep` 占位，用来放临时调试输出。
- **`lazy-lock.json` 要进 git**：它记录每个插件锁定的 commit，
  是换机器复现出同一套环境的依据。插件装完/更新完记得连它一起提交。
- **一个插件一个文件**，放在 `lua/plugins/` 下，文件名说清楚它是干什么的。
  不想要某个插件时删掉对应文件即可，`:Lazy` 下次会把它清理掉。
  例外是几个必须一起用、单独留下任何一个都没意义的：`lsp.lua` 里的
  mason + mason-lspconfig + nvim-lspconfig 就是这种，拆开反而看不出它们的分工。

## 调试常用命令

```vim
:checkhealth                  " 整体体检
:checkhealth vim.deprecated   " 查有没有用到已废弃的 API
:messages                     " 回看刷过去的消息
:verbose set shiftwidth?      " 查某个选项当前值，以及是被哪个文件设的
:verbose map <leader>w        " 查某个映射是被哪个文件定义的
:Inspect                      " 查光标处字符的高亮组来源
:lua =vim.o.timeoutlen        " 打印任意 Lua 表达式（= 是 print 的简写）
```

启动过程排查：

```bash
# 把详细的启动日志写到 logs/（-V 后面的数字是啰嗦程度，15 已经很细了）
nvim -V15logs/debug.log

# 启动耗时分析
nvim --startuptime logs/startup.log

# 不加载任何配置，用来确认「问题是不是我的配置引起的」
nvim --clean
```

# Neovim 配置

一份从零手写、逐步长大的 Neovim 配置。插件管理器：**lazy.nvim**。

目标是每一行配置都能说清楚「为什么这么写」，所以所有配置项都带中文注释。

核心原生配置（`lua/config/options|keymaps|autocmds.lua`）不依赖任何插件，
即使插件全部出问题也照常生效。

## 环境

| 项 | 值 |
| --- | --- |
| Neovim | 0.12.4（`vim.hl`、`winborder` 需要 0.11+，`vim.uv` 需要 0.10+） |
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

```bash
# macOS
brew install ripgrep fzf tree-sitter
xcode-select --install                      # C 编译器

# Debian / Ubuntu
sudo apt install ripgrep fzf build-essential
# tree-sitter CLI 要求 >= 0.26.1，apt 源里的版本通常过旧，
# 从 github.com/tree-sitter/tree-sitter 的 release 下二进制放进 PATH。
# 官方明确说不要用 npm 装。
```

装完用 `tree-sitter --version` 等命令自查，或在 Neovim 里：

```vim
:checkhealth fzf_lua           " 注意是下划线；要先按一次 <leader>ff 让插件载入
:checkhealth nvim-treesitter
```

## 目录结构

```
.
├── init.lua                 # 入口：开缓存 → 定 leader → 按顺序 require
├── lazy-lock.json           # 插件版本锁文件，由 lazy.nvim 生成，必须进 git
├── lua/
│   ├── config/              # 核心原生配置（不依赖任何插件）
│   │   ├── options.lua      # 选项：行号、缩进、搜索、剪贴板、持久化…
│   │   ├── keymaps.lua      # 全局按键映射
│   │   ├── autocmds.lua     # 自动命令：复制高亮、恢复光标、q 关辅助窗口
│   │   └── lazy.lua         # 引导并启动插件管理器 lazy.nvim
│   └── plugins/             # 插件声明，每个文件返回一张 spec 表，自动全部导入
│       ├── colorscheme.lua  # 配色：tokyonight（storm 风格）
│       ├── icons.lua        # 图标库：mini.icons，供其他插件调用
│       ├── lualine.lua      # 状态栏：lualine
│       ├── barbar.lua       # 顶部 buffer 栏：barbar
│       ├── indent.lua       # 缩进参考线：indent-blankline
│       ├── rainbow.lua      # 彩虹括号：rainbow-delimiters
│       ├── colorizer.lua    # 颜色代码高亮：nvim-colorizer
│       ├── alpha.lua        # 起始页：alpha-nvim
│       ├── treesitter.lua   # 语法解析：nvim-treesitter（高亮的底座）
│       ├── neotree.lua      # 文件树：neo-tree
│       ├── fzf.lua          # 模糊查找：fzf-lua
│       ├── grug-far.lua     # 全项目搜索替换：grug-far
│       ├── todo.lua         # 待办注释高亮：todo-comments
│       ├── flash.lua        # 光标快速跳转：flash
│       └── whichkey.lua     # 按键提示：which-key
├── docs/
│   ├── notes.md             # 收件箱：随手记，定期清空归档到下面两个文件
│   ├── cheatsheet.md        # 操作技巧速查（怎么用 Vim）
│   └── lua-api.md           # 配置机制与 Lua API（怎么写配置）
└── logs/                    # 临时调试日志，不进 git
```

插件本体装在 `~/.local/share/nvim/lazy/`，是下载来的产物，不进这个仓库。

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
| `<leader>y` `<leader>p` | 系统剪贴板复制 / 粘贴（普通寄存器保持独立） |
| `<leader>?` | 列出当前缓冲区里所有可用按键 |

不带 leader 的：

| 按键 | 用途 |
| --- | --- |
| `s` | 跳到屏幕上任意位置（flash，覆盖了原生 `s`，等价写法 `cl`） |
| `S` | 按语法结构选中（flash，覆盖了原生 `S`，等价写法 `cc`） |
| `<C-w>` + 方向 | 窗口间移动（Neovim 内置） |
| `<C-方向键>` | 调整窗口大小 |
| `<C-l>` | 清掉搜索高亮（Neovim 内置） |
| `[b` `]b` | 上一个 / 下一个 buffer（Neovim 内置） |
| `[d` `]d` | 上一个 / 下一个诊断（Neovim 内置） |
| `[q` `]q` | quickfix 列表前后跳（Neovim 内置） |
| `gc` | 切换注释（Neovim 内置，接动作或在可视模式用） |

内置映射的完整清单：`:help default-mappings`。
想查某个键现在归谁管，用 `<leader>fk` 或 `:verbose map <键>`。

## 插件常用命令

```vim
:Lazy            " 打开管理面板（I 装 / U 更新 / X 清理 / 大写 S 查看启动耗时）
:Lazy sync       " 一次搞定：装缺的、删多的、更新到锁文件之外的最新版
:Lazy restore    " 按 lazy-lock.json 把所有插件回滚到锁定的版本
:Lazy health     " 等价于 :checkhealth lazy
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
- **`logs/` 不进 git**，只保留 `.gitkeep` 占位，用来放临时调试输出。
- **`lazy-lock.json` 要进 git**：它记录每个插件锁定的 commit，
  是换机器复现出同一套环境的依据。插件装完/更新完记得连它一起提交。
- **一个插件一个文件**，放在 `lua/plugins/` 下，文件名说清楚它是干什么的。
  不想要某个插件时删掉对应文件即可，`:Lazy` 下次会把它清理掉。

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

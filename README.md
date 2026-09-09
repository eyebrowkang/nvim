# Neovim 配置

一份从零手写、逐步长大的 Neovim 配置。当前阶段：**0 插件，纯原生**。

目标是每一行配置都能说清楚「为什么这么写」，所以所有配置项都带中文注释。

## 环境

| 项 | 值 |
| --- | --- |
| Neovim | 0.12.4（`vim.hl`、`winborder` 需要 0.11+，`vim.pack` 需要 0.12） |
| 目标平台 | **macOS 与 Linux 通用**，不写平台专属配置 |
| 当前主力环境 | macOS + Ghostty，Neovim 由 MacPorts 安装（`/opt/local`） |
| 配置路径 | `~/.config/nvim`（即 `$XDG_CONFIG_HOME/nvim`） |
| 状态数据 | `~/.local/state/nvim/`（undo 历史等，两个平台一致） |

## 目录结构

```
.
├── init.lua               # 入口：开缓存 → 定 leader → 按顺序 require
├── lua/
│   ├── config/            # 核心原生配置（不依赖任何插件）
│   │   ├── options.lua    # 选项：行号、缩进、搜索、剪贴板、持久化…
│   │   ├── keymaps.lua    # 全局按键映射
│   │   └── autocmds.lua   # 自动命令：复制高亮、恢复光标、q 关辅助窗口
│   └── plugins/           # 插件声明（暂时是空的）
├── docs/
│   ├── notes.md           # 收件箱：随手记，定期清空归档到下面两个文件
│   ├── cheatsheet.md      # 操作技巧速查（怎么用 Vim）
│   └── lua-api.md         # 配置机制与 Lua API（怎么写配置）
└── logs/                  # 临时调试日志，不进 git
```

## 加载顺序

```
init.lua
  ├── vim.loader.enable()   # Lua 字节码缓存，必须在所有 require 之前
  ├── vim.g.mapleader = " " # leader 必须在所有映射之前，全仓库只设这一次
  └── require config.options → config.keymaps → config.autocmds
```

为什么顺序不能乱，见 [docs/lua-api.md](docs/lua-api.md#配置的生命线顺序)。

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
- **锁文件要进 git**：以后装插件产生的 `nvim-pack-lock.json`（或 `lazy-lock.json`）
  必须提交，它是换机器复现环境的依据。

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

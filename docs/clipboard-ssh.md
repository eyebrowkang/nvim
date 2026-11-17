# SSH、tmux 与系统剪贴板

从 Mac A 通过 SSH 登录远端 B，在 B 的 tmux 内用 Neovim 按 `<leader>y`，
可以直接把文字复制到 A 的系统剪贴板。关键是让 Neovim 使用 tmux 后端，
再由 tmux 通过 OSC 52 通知 A 的终端写入剪贴板。

以下配置面向 Neovim 0.12.x；复制链路的实现核对于 Neovim 0.12.6、
tmux 3.5a。B 可以是 Linux，也可以是另一台 Mac。

## 1. 从快捷键到 Mac 剪贴板

[keymaps.lua](../lua/config/keymaps.lua) 把 `<leader>y` 映射成 `"+y`：
leader 是空格，先按空格再按 `y`；可视模式复制选区，普通模式后接动作。
复制整行用 `<leader>yy`。

`+` 是剪贴板寄存器，但它最终连接哪个剪贴板，取决于 Neovim 选择的
provider（后端）。使用 tmux 后端时，复制经过以下路径：

```text
B：Neovim 的 "+y
  → tmux load-buffer -w -
  → tmux 存入缓冲区，并发出 OSC 52 控制序列
  → SSH 将终端输出传回 A
A：终端识别 OSC 52，写入 macOS 系统剪贴板
```

`tmux load-buffer` 末尾的 `-` 表示从标准输入读取文字；`-w` 表示同时尝试
把缓冲区发送到客户端的剪贴板。Neovim 对 tmux 3.2 及以上版本使用此参数。

OSC 52 和终端显示颜色、移动光标的转义序列类似，只是用途为访问剪贴板。
写入时，序列携带 Base64 编码的文字，由终端解码并交给本地系统。
SSH 负责传输这些字节，真正操作 A 剪贴板的是 A 的终端程序。
因此不需要 X11 转发，也不需要在 B 安装 A 的剪贴板命令。

## 2. 为什么远端 Linux 能用，远端 Mac 却可能复制到自己

Neovim 自动探测剪贴板后端时，相关优先级如下，省略其他平台的工具：

```text
显式设置的 g:clipboard
  → macOS 的 pbcopy / pbpaste
  → Wayland / X11 等剪贴板工具
  → tmux（存在 $TMUX 且能执行 tmux）
  → OSC 52（终端支持，且满足自动探测条件）
```

在没有桌面剪贴板工具的远端 Linux 上，tmux 往往会被自动选中。
而在 Mac B 上，`pbcopy` 优先于 tmux：即使通过 SSH 登录并进入 tmux，
Neovim 仍会调用 B 的 `pbcopy`，写入 B 的系统剪贴板。

SSH 登录不会自动让 Neovim 改选后端。要把内容传回 A，需要显式覆盖选择。

## 3. tmux 内统一使用 tmux 后端

本仓库默认保留自动探测。需要上述行为时，在
[options.lua](../lua/config/options.lua) 第 5 节加入：

```lua
-- tmux 内通过客户端终端交换剪贴板，避免远端 macOS 优先调用 pbcopy。
-- 本地 tmux 也使用此路径；tmux 外保留系统默认探测。
if vim.env.TMUX then
  vim.g.clipboard = "tmux"
end
```

这条规则同时适用于 macOS 和 Linux，不依赖 SSH 环境变量：本地使用 tmux
也会通过连接它的终端设置剪贴板。代价是 tmux 内的复制依赖外层终端的
OSC 52 支持；它不会同时更新远端 Mac 的系统剪贴板。

`vim.g.clipboard` 指定的是后端，`vim.opt.clipboard` 决定普通寄存器是否
联动剪贴板，两者不同。本仓库不设置 `unnamedplus`，普通 `y/d/p` 保持内部
寄存器行为，显式使用 `"+` 的映射才访问剪贴板后端。

必须在后端初始化前设置 `vim.g.clipboard`。放在 `config.options` 中可以
早于插件加载；修改后重启 Neovim，避免当前进程继续使用已初始化的后端。

不改配置也可以先在 B 的 tmux 内验证：

```sh
nvim --cmd "let g:clipboard = 'tmux'"
```

## 4. tmux 和终端需要什么

B 的 `~/.tmux.conf` 使用：

```tmux
# 允许程序通过 OSC 52 设置 tmux 缓冲区，并向外层终端同步剪贴板。
set -g set-clipboard on
```

`on` 同时允许 tmux 向外写剪贴板，以及接收内部程序发出的 OSC 52。
`external` 允许 tmux 向外写，但禁止内部程序通过 OSC 52 创建缓冲区。
这里的 Neovim tmux 后端调用 tmux 命令；直接发送 OSC 52 是另一条路径。

tmux 还需要外层终端的 `Ms` 能力；A 的终端也必须支持并允许 OSC 52
写剪贴板。可在 B 的 tmux 内检查：

```sh
tmux show-options -s set-clipboard
tmux list-clients -F '#{client_termname} #{client_termfeatures}'
tmux info | rg 'Ms:'
```

客户端特性中的 `clipboard` 和非缺失的 `Ms` 是有效线索。
`Ms` 通常形如 `\033]52;%p1%s;%p2%s\a`，表示 tmux 如何生成剪贴板序列。
能力声明不等于终端实际允许写入，最后仍需复制并在 A 的其他程序中粘贴验证。

这条路径由 tmux 自己处理剪贴板序列，不需要开启 `allow-passthrough`。

## 5. 没有 tmux，以及反向粘贴

B 没有运行 tmux 时，可以让 Neovim 直接发送 OSC 52，仍由 A 的终端处理：

```lua
-- 远程会话直接请求客户端终端访问剪贴板，跳过 pbcopy 等自动探测。
vim.g.clipboard = "osc52"
```

此设置也会把粘贴后端切到 OSC 52。终端允许写入剪贴板，不代表允许读取，
所以 `<leader>y` 成功不保证 `<leader>p` 能读到 A 的最新剪贴板。
tmux 后端的读取也依赖其版本和终端响应，不能视为双向实时同步。
从 A 向远端粘贴时，通常直接用 A 终端的 `⌘V` 即可。

## 6. 排查顺序与参考

先在有问题的那个 Neovim 进程中确认实际后端：

```vim
:echo provider#clipboard#Executable()
:set clipboard?
:checkhealth vim.provider
```

第一条若输出 `pbcopy`，说明仍在使用当前 Mac 的系统剪贴板；输出 `tmux`
才是本文的 tmux 链路。第二条在本仓库默认应显示 `clipboard=`；它为空不代表
剪贴板不可用，只表示普通寄存器没有自动联动系统剪贴板。

确认后端后，再检查 tmux 的 `set-clipboard`、客户端能力和 A 的终端设置。
有多层 tmux 时，每一层都需要正确处理剪贴板序列；不能只检查最里面一层。

- 本地帮助：`:help clipboard-tool`、`:help g:clipboard`、`:help clipboard-osc52`。
- [Neovim 剪贴板后端说明](https://neovim.io/doc/user/provider/#clipboard-tool)。
- [tmux 剪贴板原理与终端配置](https://github.com/tmux/tmux/wiki/Clipboard)。
- [tmux 3.5a 手册源码](https://github.com/tmux/tmux/blob/3.5a/tmux.1)：
  查找 `load-buffer` 的 `-w` 参数。

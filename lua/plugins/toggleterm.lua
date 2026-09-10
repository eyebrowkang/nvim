-- lua/plugins/toggleterm.lua
-- 终端：toggleterm.nvim
--
-- Neovim 本来就有终端（:terminal），而且 0.12 把它做得相当完整了：
-- 打开时自动关掉行号、标记列和折行，回滚缓冲区提到一万行，
-- [[ 和 ]] 能在 shell 提示符之间跳（见 :help terminal-osc133）。
-- 进程退出后缓冲区会留着，末尾标一行 [Process exited 0]；
-- 本插件的 close_on_exit 默认为 true，会把这个缓冲区直接关掉。
--
-- 那这个插件补的是什么？三件事：
--   1. 浮窗形态 —— :terminal 只能开在一个普通窗口里，会挤掉正在看的代码
--   2. 一键开关 —— 同一个键按一下弹出来、再按一下收回去，进程一直活着
--   3. 把外部 TUI 程序包成一个专用浮窗，比如下面的 lazygit
--
-- ⚠ 从终端里逃出来用 <C-\><C-n>（回到 Normal 模式，可以滚动、复制、切窗口）。
--   按 i 或 a 回到交互。这里没有把它映射成更好按的 <Esc>，因为终端里跑的
--   lazygit、less、htop 这类程序自己要用 Esc，映射掉它们就没法退出子菜单了。

-- lazygit 的浮窗。声明在这里（模块作用域）而不是 keys 里面，
-- 是为了让这个终端对象只建一次 —— 建两次就是两个 lazygit 进程。
local lazygit

local function toggle_lazygit()
  -- lazygit 是外部命令，装没装是运行时才知道的事。
  -- 不检查的话会开出一个只写着 "command not found" 的浮窗，看不出是缺什么。
  if vim.fn.executable("lazygit") == 0 then
    vim.notify(
      "没有找到 lazygit 命令。安装：brew install lazygit / apt install lazygit",
      vim.log.levels.WARN
    )
    return
  end

  -- 第一次按才真正创建。require 写在函数里，
  -- 是因为这个文件在 lazy.nvim 读配置阶段就会被执行，那时插件还没加载。
  lazygit = lazygit
    or require("toggleterm.terminal").Terminal:new({
      cmd = "lazygit",
      direction = "float",

      -- 每个终端有一个编号，<leader>tf 这类普通终端从 1 开始顺着排。
      -- 不指定编号的话 lazygit 会抢到 1 号，之后按 <leader>tf 弹出来的
      -- 就是 lazygit 而不是 shell（实测过，确实会撞）。
      -- 给它一个远离 1、2、3 的固定编号就躲开了。
      count = 99,

      -- 不出现在 :TermSelect 的列表里 —— 它有自己的 <leader>gg，
      -- 混在「第几个终端」里只会碍事。
      hidden = true,

      on_open = function()
        -- lazygit 整个界面靠单键操作，必须停在插入模式（按键才会转发给它）。
        vim.cmd("startinsert!")
      end,
    })

  lazygit:toggle()
end

return {
  {
    "akinsho/toggleterm.nvim",

    -- 锁在 tag 上而不是跟 main 分支。这个插件维护节奏很慢（功能已经完备），
    -- 跟 main 拿不到什么新东西，反而可能碰上没发版的中间状态。
    version = "*",

    -- 没有设 open_mapping：那个选项会注册一个全局按键，插件文档里的例子用
    -- <C-\>，正好把上面说的 <C-\><C-n> 逃生口挡掉半秒（Neovim 要等着看
    -- 你是不是想按第二个键）。按键统一在下面的 keys 里显式写。
    opts = {
      -- 每个终端多大。这个函数在每次打开时调用，参数是那个终端对象，
      -- 所以横着开和竖着开可以给不同的尺寸。浮窗不走这里（见 float_opts）。
      size = function(term)
        if term.direction == "horizontal" then
          -- 底部开 15 行高，够看清一屏输出，又不至于把代码挤没。
          return 15
        elseif term.direction == "vertical" then
          -- 侧边开屏幕宽度的 40%。用比例而不是固定列数，
          -- 换一块屏幕（或者笔记本外接显示器）时不用改配置。
          return vim.o.columns * 0.4
        end
      end,

      float_opts = {
        -- 浮窗占屏幕的 85%。留一圈边能看见底下是什么文件，
        -- 不至于产生「我现在到底在哪」的错觉。
        width = function()
          return math.floor(vim.o.columns * 0.85)
        end,
        height = function()
          return math.floor(vim.o.lines * 0.85)
        end,

        -- 边框要单独设。这个插件不看全局的 winborder（options.lua 里设的
        -- "rounded"），它总是自己往 nvim_open_win 里塞一个 border 值，
        -- 不写就用它自己的默认值 "single"（直角）。
        -- 它管圆角叫 "curved"，效果和 winborder = "rounded" 一样。
        border = "curved",
      },

      -- 关掉「把终端窗口整体调暗」的效果（默认是开的）。
      -- 它靠改 Normal 这类高亮组的背景色实现，
      -- 在 tokyonight 这种本来就暗的主题上会让终端文字糊成一片。
      shade_terminals = false,
    },

    -- 没配 start_in_insert：默认就是 true，打开终端直接进插入模式，
    --   不用再按一次 i，正是想要的。
    --
    -- 没配 persist_mode：默认 true，记住你离开这个终端时是插入还是普通模式，
    --   下次切回来还原成那个模式。滚上去看输出、切走、再切回来，
    --   光标还停在原处而不是被丢回插入模式。
    --
    -- 没配 close_on_exit / hide_numbers：默认都是想要的行为
    --   （进程退出就把窗口关掉、缓冲区一并删掉；终端里不显示行号）。

    -- 下面这些键或命令第一次用到时才加载插件，之前它完全不占资源。
    --
    -- cmd 这一串是必须的：命令是插件加载时才注册的，
    -- 不在这里报备的话，手敲 :TermExec 会得到 E492 找不到命令 ——
    -- 得先按一次 <leader>tf 把插件唤起来才行。列在这里，lazy.nvim 会先放一个
    -- 同名的占位命令，敲到它时先加载插件再把命令转交过去。
    cmd = {
      "ToggleTerm", -- 开 / 关第 n 个终端，也是 <leader>t 那几个键背后的命令
      "TermExec", -- 把一条命令送进终端里执行，如 :TermExec cmd="make test"
      "TermSelect", -- 列出所有终端，选一个跳过去
      "ToggleTermToggleAll", -- 一次开 / 关全部终端
      "ToggleTermSendCurrentLine", -- 把光标这一行发到终端里跑
      "ToggleTermSendVisualLines", -- 把选中的整行发过去
      "ToggleTermSendVisualSelection", -- 只把选中的那一段字符发过去
    },

    keys = {
      -- 三种形态各给一个键，<leader>t = terminal。
      -- 同一个键按第二次会把它收回去（进程还在后台跑着，输出不会丢）。
      --
      -- 命令前面那个数字是终端编号，1 / 2 / 3 是三个各自独立的 shell ——
      -- 可以一个跑测试、一个跑服务器、一个随手敲命令，互不干扰。
      --
      -- ⚠ 编号必须写。不写（编号 0）时插件走的是另一套「智能」逻辑：
      --   只要屏幕上有任何一个终端窗口开着，它就去操作那一个。
      --   结果是 lazygit 开着的时候按 <leader>tf 会作用到 lazygit 身上。
      --   写死编号就绕开了那套启发式，每个键永远只管自己那一个终端。
      { "<leader>tf", "<cmd>1ToggleTerm direction=float<cr>", desc = "浮窗终端" },
      { "<leader>th", "<cmd>2ToggleTerm direction=horizontal<cr>", desc = "底部终端" },
      { "<leader>tv", "<cmd>3ToggleTerm direction=vertical<cr>", desc = "侧边终端" },

      -- 列出当前所有终端，选一个跳过去。
      -- 还想要更多就直接敲 :4ToggleTerm，编号任意。
      { "<leader>ts", "<cmd>TermSelect<cr>", desc = "在多个终端之间选" },

      -- lazygit 归到 <leader>g（git）组里而不是 <leader>t（终端）组，
      -- 因为用它的时候想的是「我要提交」，不是「我要开个终端」。
      { "<leader>gg", toggle_lazygit, desc = "lazygit" },
    },
  },
}

-- lua/plugins/barbar.lua
-- 顶部 buffer 栏：barbar
--
-- 把打开着的缓冲区（buffer）画成一排标签，显示在屏幕最上面一行。
--
-- 先分清两个容易混的概念，否则配置里的选项名会看不懂：
--   buffer  一份「被载入内存的文件内容」。打开十个文件就有十个 buffer，
--           哪怕屏幕上只显示一个。这一栏画的就是它们。
--   tab     Vim 的标签页，装的是一整套窗口布局，和「打开了哪些文件」无关。
--           Vim 原生的 :tabnew 才是它。
-- 也就是说这一栏借用了 tabline 这个位置（屏幕最上面一行），
-- 但画的是 buffer 而不是 tab —— 更接近 VS Code 那种标签栏的直觉。

return {
  {
    "romgrk/barbar.nvim",

    -- 文件类型图标走 mini.icons（它把自己伪装成了 nvim-web-devicons，见 icons.lua）。
    -- 写成 dependencies 是为了保证 mini.icons 先加载完，伪装已经就位。
    dependencies = { "nvim-mini/mini.icons" },

    -- 顶栏一启动就要显示，没有更晚的时机可等，所以不懒加载。
    -- 和 lualine、alpha 是同一个理由。
    lazy = false,

    -- 只跟随 1.x 大版本。
    -- 和 lazy-lock.json 的分工：锁文件钉死的是「现在用的是哪个 commit」，
    -- 这一行管的是「执行 :Lazy update 时允许更新到哪」——
    -- 将来作者发 2.0 带破坏性改动，也不会在某次例行更新里悄悄卷进来。
    version = "^1.0.0",

    -- 这行必须写。barbar 默认会在自己加载时调一次 setup()，
    -- 而下面写了 opts，lazy.nvim 也会替我们调一次，不关掉就是白跑两遍。
    -- 用 init 而不是 config：init 在插件加载「之前」执行，这个开关才来得及生效。
    init = function()
      vim.g.barbar_auto_setup = false
    end,

    opts = {
      icons = {
        -- 分隔符预设。powerline 用的箭头（  ）和 lualine 状态栏是同一套，
        -- 上下两条栏看起来是一整套而不是两个插件拼的。
        -- 这些字符需要 Nerd Font；没装字体就删掉这一行，会回到默认的竖线 ▎。
        preset = "powerline",
      },

      -- 新打开的文件排到最右边，而不是插在当前标签的后面。
      --
      -- 为什么改这个默认值：Neovim 0.12 内建的 [b / ]b 是按「缓冲区编号」
      -- 前后跳的，而编号是按打开顺序递增的。让标签也按打开顺序排，
      -- 内建映射走一遍就正好是这一栏从左到右的顺序，两者不会打架。
      -- （用下面的 <leader>b< / <leader>b> 手动挪过标签之后就又不一致了，
      --   在意的话可以再把 [b / ]b 映射到 BufferPrevious / BufferNext。）
      insert_at_end = true,

      -- 侧边栏让位。
      -- 顶栏默认是整行通铺的，左边开了文件树之后，标签会压在树的上方，
      -- 看起来像树顶上顶了半截标签。在这里登记「哪些文件类型算侧边栏」，
      -- barbar 就会把这一栏起始位置右移，空出侧边栏的宽度。
      -- event 指的是「什么时候认为这个侧边栏关掉了、可以把宽度收回来」，
      -- BufWipeout 是 neo-tree 关闭时真正会触发的那个事件。
      sidebar_filetypes = {
        ["neo-tree"] = { event = "BufWipeout" },
      },

      -- 这里刻意保持默认的「顶栏常驻」（auto_hide 默认是 -1，即从不隐藏）。
      -- 已知的小代价：起始页上缓冲区列表是空的，顶端会留一条纯背景色的空条；
      -- 只开一个文件时也会有一个只写着当前文件名的标签，信息和状态栏重复。
      -- 想让它在「buffer 数 ≤ 1 时自动收起来」，在这里加一行 auto_hide = 1。
      -- 不设成默认是因为那样顶栏会来回出现消失，整个界面跟着上下跳一行，
      -- 常驻虽然浪费一行，但位置是稳的。
    },

    -- 按键映射写在这里而不是 lua/config/keymaps.lua：
    -- 那个文件的定位是「不依赖任何插件的核心映射」，删掉插件也不该留下死键。
    -- 放在 spec 的 keys 字段里，插件和它的按键是一份东西，删文件就一起没了，
    -- 而且能在 :Lazy 面板里看到这个插件占用了哪些键。
    --
    -- 这里刻意「不」映射切换上一个/下一个 buffer：
    -- Neovim 0.12 内建就有 [b ]b（前后切）和 [B ]B（跳到第一个/最后一个），
    -- 见 :help [b。内建有的不重复造。
    keys = {
      -- barbar 的招牌功能：按下之后每个标签上会浮出一个字母，
      -- 再按那个字母就直接跳过去。标签一多的时候比连按 ]b 快得多。
      { "<leader>bb", "<cmd>BufferPick<CR>", desc = "按字母挑一个 buffer 跳过去" },

      -- 关掉当前 buffer 但保留窗口布局（原生 :bdelete 在某些情况下会连窗口一起收掉）。
      { "<leader>bd", "<cmd>BufferClose<CR>", desc = "关闭当前 buffer" },
      { "<leader>bo", "<cmd>BufferCloseAllButCurrent<CR>", desc = "关闭其他所有 buffer" },

      -- 固定住的标签会排到最左边，并且不会被上面那条「关闭其他」清掉。
      -- 适合钉住正在参照的文件。
      { "<leader>bp", "<cmd>BufferPin<CR>", desc = "固定/取消固定当前 buffer" },

      -- 手动调整标签在这一栏里的左右位置。
      -- 用 < 和 > 是沿用可视模式里 < / > 做左右缩进的那个方向直觉。
      { "<leader>b<", "<cmd>BufferMovePrevious<CR>", desc = "当前标签左移" },
      { "<leader>b>", "<cmd>BufferMoveNext<CR>", desc = "当前标签右移" },
    },
  },
}

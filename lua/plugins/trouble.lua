-- lua/plugins/trouble.lua
-- 诊断与列表面板：trouble.nvim
--
-- 把「一堆位置」按文件分组，画成一棵可折叠的树，放在一个固定的窗口里。
-- 光标停在某一项上时，对应的文件会在旁边预览，回车跳过去。
-- 喂给它的数据可以是几种不同的来源，本配置绑了这几种（统一放在 <leader>x 下）：
--   <leader>xx   全项目诊断（LSP 和 linter 报的所有错误、警告）
--   <leader>xX   只看当前文件的诊断
--   <leader>xs   当前文件的符号大纲（函数、类、变量的树）
--   <leader>xl   光标下这个符号的定义 / 引用 / 实现 / 类型定义
--   <leader>xq   quickfix 列表
--   <leader>xL   location list（窗口局部的那份列表）
--
-- 和已有功能的分工，三个都能列诊断，别记混：
--   ]d / [d        内置的逐个跳，不开窗口，看一条改一条时最快
--   <leader>xx     开一个常驻面板，适合「先看看总共有多少问题」
--   :lopen（gO）   内置的大纲，一次性快照，不跟着光标动
--
-- 面板里的常用键（打开后按 ? 可以看全部）：
--   <CR>  跳到该位置，面板留着      o     跳过去并关掉面板
--   j / k 上下移动，旁边同步预览    q     关闭面板
--   za    折叠 / 展开一个文件分组   r     手动刷新
--   P     关掉 / 打开自动预览       ?     列出面板里的所有按键
--
-- ⚠ 维护状态：这个仓库最后一次提交是 2025-10-31，此后没再动过。
--   仓库里还挂着一个 2025-09 提出、至今未修的 issue，说 0.12 上打开诊断视图会报
--   `trouble.treesitter: attempt to call a nil value`（它伸手用了 treesitter
--   高亮器的私有方法 _on_win / _on_range，那几个方法在 0.12 改过）。
--   在 0.12.5 上实测没有复现，诊断、大纲、quickfix 三种视图都正常。
--   万一将来升级后真的报这个错，退路是内置的诊断列表，不需要任何插件：
--     :lua vim.diagnostic.setqflist()   把全项目诊断丢进 quickfix，然后 :copen
--     :lua vim.diagnostic.setloclist()  只要当前文件的，然后 :lopen
--   这一类里没有第二个成熟的同类插件，所以没有「换一个活跃的」这个选项。

return {
  {
    "folke/trouble.nvim",

    -- 面板里的文件图标走 mini.icons 的伪装（见 icons.lua）。
    dependencies = { "nvim-mini/mini.icons" },

    -- 命令要报备，否则手敲 :Trouble 会是 E492（见 docs/lua-api.md 第 6 个坑）。
    cmd = "Trouble",

    keys = {
      -- 命令的写法是 :Trouble {模式} {动作} {选项=值}...
      -- toggle 的意思是「开着就关、关着就开」，同一个键来回按。
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "诊断列表（全项目）" },

      -- filter.buf=0 里的 0 是 Neovim 里「当前缓冲区」的惯用写法。
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "诊断列表（当前文件）" },

      -- 和内置的 gO 的区别：gO 是一次性快照，丢进 location list 就不再更新；
      -- 这个面板会跟着光标高亮你正处在哪个函数里，改了代码也会自己刷新。
      { "<leader>xs", "<cmd>Trouble symbols toggle<CR>", desc = "符号大纲" },

      -- win.position=right 把这个模式的面板改成右边竖着开。
      -- 它列的是「和光标下这个符号有关的所有位置」，条目通常不多但路径长，
      -- 竖版比默认的底部横版好读。其他模式不受影响。
      { "<leader>xl", "<cmd>Trouble lsp toggle win.position=right<CR>", desc = "定义 / 引用 / 实现" },

      { "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "quickfix 列表" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<CR>", desc = "location list" },
    },

    -- opts 留空 = 全用默认。默认值里值得知道的四个：
    --   focus = false         打开面板时光标不进去，还留在代码里
    --   follow = true         面板里的高亮跟着代码里的光标走
    --   auto_refresh = true   诊断变了、文件改了，面板自己更新
    --   auto_preview = true   光标停在某一项上，旁边就预览那个位置
    -- 也就是说「开着它继续写代码」是设计好的用法，不需要额外配置。
    --
    -- 几个改起来最有感觉的（要用时再往里加）：
    --   auto_close = true            列表空了就自动关掉面板
    --   focus = true                 打开时光标直接进面板
    --   win = { position = "right" } 所有模式都改成右侧竖版
    opts = {},
  },
}

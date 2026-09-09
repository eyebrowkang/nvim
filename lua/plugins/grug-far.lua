-- lua/plugins/grug-far.lua
-- 全项目搜索替换：grug-far
--
-- 它的思路和别的插件不一样：不弹对话框，而是开一个普通的可编辑 buffer。
-- 上半部分是几个输入格（搜什么、替换成什么、限定哪些文件、额外的 rg 参数），
-- 你就用平时写代码的方式在里面打字；下半部分实时列出所有命中和替换后的样子。
-- 确认无误后按 <localleader>r 一次性落盘。
--
-- 因为它就是个 buffer，所以原生的一切都还能用：u 撤销输入、
-- <leader>p 粘贴系统剪贴板里的关键词、:w 之外的窗口操作等等。
--
-- ⚠ 需要外部命令 ripgrep（版本 >= 14）：
--     macOS: brew install ripgrep      Linux: apt install ripgrep
--   用 rg --version 确认；插件的报错信息也会直接把 rg 的原话透出来。
--   :checkhealth grug-far 会额外提醒缺 ast-grep，那是可选的「按语法结构替换」
--   引擎，只做文本替换不需要它。

return {
  {
    "MagicDuck/grug-far.nvim",

    -- 懒加载。插件文档说它内部所有 require 都是延迟的，
    -- 所以不需要额外的 event，用到命令或按键时才载入就够。
    cmd = "GrugFar",

    keys = {
      -- ---- 搜索替换：统一放在 <leader>s 下（s = search & replace）----

      -- 空手开一个面板，搜什么替换什么进去再填。
      {
        "<leader>sr",
        function()
          require("grug-far").open()
        end,
        desc = "搜索替换（全项目）",
      },

      -- 把光标下的词直接填进搜索框，最常用的入口。
      -- <cword> 是 Vim 的特殊记法，展开成「光标所在的那个单词」。
      {
        "<leader>sw",
        function()
          require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
        end,
        desc = "替换光标下的词（全项目）",
      },

      -- 只在当前文件里替换。
      -- paths 这一格接受的就是 rg 的路径参数，填 % 展开出来的当前文件路径即可。
      {
        "<leader>sf",
        function()
          require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } })
        end,
        desc = "搜索替换（只在当前文件）",
      },

      -- 可视模式：把选中的那段文字当搜索词。
      -- 用 with_visual_selection 而不是自己取选区，是因为它会正确处理
      -- 多行选择和需要转义的特殊字符。
      {
        "<leader>sr",
        function()
          require("grug-far").with_visual_selection()
        end,
        mode = "x",
        desc = "用选中内容做搜索替换",
      },
    },

    -- opts 留空是有效写法：插件文档写明「目前没有必填选项」，
    -- 但 lazy.nvim 需要看到 opts 才会去调 setup()，所以这里保留一个空表。
    -- 面板内部的按键（落盘、切换输入格、翻页等）按 g? 可以随时查。
    opts = {},
  },
}

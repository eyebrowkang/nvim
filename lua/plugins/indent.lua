-- lua/plugins/indent.lua
-- 缩进参考线：indent-blankline（简称 ibl）
--
-- 在每一级缩进的位置画一条竖线，并把光标当前所在的那一级作用域高亮出来。

return {
  {
    "lukas-reineke/indent-blankline.nvim",

    -- main 指定「setup 应该在哪个模块上调」。
    -- lazy.nvim 默认从仓库名猜模块名，这个插件仓库叫 indent-blankline.nvim
    -- 但模块实际叫 ibl，猜不中，必须显式写出来。
    main = "ibl",

    -- 事件懒加载：等到真正打开文件时才加载，空启动（比如只是看起始页）不必付这份开销。
    --   BufReadPost  打开一个已存在的文件、读完内容之后
    --   BufNewFile   新建一个还不存在的文件
    -- 两个加起来 = 「手上有一个真实文件缓冲区」的时刻。
    event = { "BufReadPost", "BufNewFile" },

    opts = {
      indent = {
        -- 画线用的字符。"│" 是普通的 Box Drawing 字符，不需要 Nerd Font。
        char = "│",
      },

      scope = {
        -- 把光标当前所在的作用域（函数体、if 块…）那条线高亮成另一种颜色。
        enabled = true,

        -- 不在作用域的首行/末行画下划线。开着会在 function 那一行拉一条横线，
        -- 和光标行高亮叠在一起容易糊成一片。
        show_start = false,
        show_end = false,
      },

      exclude = {
        -- 这些缓冲区里不画线：它们不是代码，画了只是噪音。
        filetypes = {
          "help",        -- :help 文档
          "lazy",        -- :Lazy 面板
          "checkhealth", -- :checkhealth 报告
          "alpha",       -- 起始页
          "man",         -- man 手册
          "qf",          -- quickfix / location 列表
        },
      },
    },
  },
}

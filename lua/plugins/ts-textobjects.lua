-- lua/plugins/ts-textobjects.lua
-- 语法感知的跳转与交换：nvim-treesitter-textobjects
--
-- 这个插件在本配置里担两个角色：
--
--   1. 「语法查询文件」的提供方。它带了 50 多种语言的 queries/<语言>/textobjects.scm，
--      内容是「在这门语言里，什么算一个函数、什么算一个类、什么算一个参数」。
--      mini.ai 的 m / c / = 三个文本对象读的就是这些文件（见 mini-ai.lua）。
--      所以哪怕下面的按键一个都不用，这个插件也不能删。
--
--   2. 提供「在函数之间跳」和「交换两个参数」这两个动作 —— 那是文本对象做不到的。
--
-- 它自己也能配一套 am / im 之类的文本对象，这里没用，
-- 因为那会和 mini.ai 的 a / i 前缀抢同一个按键序列，
-- 结果是每次按 a 都要等一次超时。文本对象统一交给 mini.ai。

return {
  {
    "nvim-treesitter/nvim-treesitter-textobjects",

    -- 和 nvim-treesitter 一样必须指明 main 分支。
    -- 这个仓库同样有 main / master 两套互不兼容的 API，
    -- master 是留给 Neovim 0.11 及更早的冻结版本。两个插件的分支必须一致。
    branch = "main",

    -- 查询文件要能被找到，靠的是 nvim-treesitter 装好的解析器先把文件解析出来。
    dependencies = { "nvim-treesitter/nvim-treesitter" },

    opts = {
      move = {
        -- 跳转前把当前位置记进跳转表，这样按 <C-o> 能原路退回来。
        set_jumps = true,
      },
    },

    keys = {
      -- ---- 在函数之间跳 ----
      -- ]m / [m / ]M / [M 是 Vim 原本就有的键，语义完全一致：
      --   ]m 下一个函数的开头   [m 上一个函数的开头
      --   ]M 下一个函数的结尾   [M 上一个函数的结尾
      -- 区别在实现：原生靠数花括号，只对 C / Java 那类语言准；
      -- 这里换成按语法树找，Python、Lua 这种没花括号的语言也准。
      -- 三种模式都映射：普通模式跳光标，可视模式扩选区，算子模式当动作用（d]m）。
      --
      -- 一个例外：Neovim 自带的 Python ftplugin 会给 python 缓冲区
      -- 单独绑一份 ]m / [m（缓冲区局部映射优先级高于全局），所以 .py 文件里
      -- 生效的是它那份。好在两者做的是同一件事（跳到下一个 def），感觉不出差别。
      {
        "]m",
        function()
          require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects")
        end,
        mode = { "n", "x", "o" },
        desc = "下一个函数开头",
      },
      {
        "[m",
        function()
          require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects")
        end,
        mode = { "n", "x", "o" },
        desc = "上一个函数开头",
      },
      {
        "]M",
        function()
          require("nvim-treesitter-textobjects.move").goto_next_end("@function.outer", "textobjects")
        end,
        mode = { "n", "x", "o" },
        desc = "下一个函数结尾",
      },
      {
        "[M",
        function()
          require("nvim-treesitter-textobjects.move").goto_previous_end("@function.outer", "textobjects")
        end,
        mode = { "n", "x", "o" },
        desc = "上一个函数结尾",
      },

      -- ---- 调换参数顺序 ----
      -- 光标停在某个参数上，按 <leader>a 把它和右边那个参数对调，<leader>A 和左边对调。
      -- 逗号和空格会一起处理好，不会留下 (b, , a) 这种残骸。
      -- 手工做的话要剪切、找位置、粘贴、再修逗号，这个键一步到位。
      {
        "<leader>a",
        function()
          require("nvim-treesitter-textobjects.swap").swap_next("@parameter.inner")
        end,
        desc = "和后一个参数对调",
      },
      {
        "<leader>A",
        function()
          require("nvim-treesitter-textobjects.swap").swap_previous("@parameter.inner")
        end,
        desc = "和前一个参数对调",
      },

      -- 这里没有映射 ]] / [[（在类之间跳）。
      -- 那两个键被 Neovim 自带的 20 多个 ftplugin 抢着当「跳章节」用了
      -- （markdown 跳标题、python 跳顶层定义……），缓冲区局部映射会赢，
      -- 全局绑上去只会得到「在有些文件里生效、有些不生效」的迷惑行为。
      -- 要选中一个类用 mini.ai 的 ac / ic。
      --
      -- 插件自带的 repeatable_move（用 ; 和 , 重复上一次跳转）也没启用：
      -- 那两个键归 flash 管（见 flash.lua）。
    },
  },
}

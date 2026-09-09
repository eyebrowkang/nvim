-- lua/plugins/mini-ai.lua
-- 文本对象增强：mini.ai
--
-- 「文本对象」是 Vim 里跟在 d / c / y / v 后面的那个「操作范围」。
-- 原生只有 iw（词）、ip（段）、i"（引号内）、i( 这么几种，
-- 而且原生的只认「光标正好在里面」，光标在括号左边一点点就找不到了。
--
-- 这个插件做两件事：
--   1. 补上原生没有的对象，比如 a（函数参数）、f（函数调用）、t（HTML 标签）
--   2. 让所有对象都能「往后找」—— 光标在这一行开头，按 ci( 照样能进到
--      本行后面那个括号里去，不用先把光标挪进去
--
-- 常用代号（a = 含边界，i = 不含边界）：
--   ai( ai[ ai{ ai<     各种括号；用左半边如 i( 会顺带去掉内侧空格，用右半边 i) 不会
--   ai" ai' ai`         各种引号
--   aib aiq             b = 任意一种括号，q = 任意一种引号（懒得挑的时候用）
--   aia                 argument，函数参数：a 含逗号，i 只要参数本身
--   aif                 function call，整个函数调用 foo(x, y)
--   ait                 tag，一对 HTML 标签
--   ai?                 现场输入左右边界，用来对付上面没覆盖的怪符号
--   aim aic ai=         下面 custom_textobjects 里加的，靠 treesitter 认语法

return {
  {
    "nvim-mini/mini.ai",

    -- 依赖 nvim-treesitter-textobjects：下面的 m / c / = 三个对象是靠
    -- 「语法查询文件」实现的，那些 .scm 查询文件由那个插件提供（见 ts-textobjects.lua）。
    -- 写在这里的作用是让 lazy.nvim 保证它先加载 —— 查询文件只有在插件被加载、
    -- 目录进了 runtimepath 之后才找得到。
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },

    -- 它映射的是 a / i 这两个前缀，没法用某一个具体按键当懒加载触发点，
    -- 所以用 VeryLazy：启动画面出来之后再加载，不拖慢启动。
    event = "VeryLazy",

    -- opts 写成函数而不是表，是因为里面要用 require("mini.ai") 上的 gen_spec。
    -- 写成表的话这个 require 会在读配置文件时就执行，那时插件还没加载，会报模块不存在。
    -- 写成函数，lazy.nvim 会等插件加载完再调用它拿返回值。
    opts = function()
      local ai = require("mini.ai")

      -- gen_spec.treesitter 把「语法查询里的某个捕获组」包装成一个文本对象。
      -- @xxx.outer 是含外壳的整体（函数含 function 关键字和整个函数体），
      -- @xxx.inner 是里面的内容（只有函数体）。
      -- 哪些语言支持哪些捕获，取决于 nvim-treesitter-textobjects 里有没有写对应的查询，
      -- 没写的语言上按下去会提示找不到，不影响别的对象。
      local ts = ai.gen_spec.treesitter

      return {
        custom_textobjects = {
          -- m = method，函数「定义」。
          -- 注意和内置的 f 区分：f 是函数「调用」foo(1, 2)，m 是函数「定义」那一整块。
          -- 用 m 而不是 f，也是为了和内置的 ]m / [m（在函数间跳）对上。
          m = ts({ a = "@function.outer", i = "@function.inner" }),

          -- c = class，类 / 结构体。
          c = ts({ a = "@class.outer", i = "@class.inner" }),

          -- = 号：一条赋值语句。
          -- a= 是整条 foo = bar + 1，i= 是等号右边的值 bar + 1，
          -- 所以「把这个变量的值整个换掉」就是 ci=。
          --
          -- 这里 i 用的是 @assignment.rhs 而不是名字更顺的 @assignment.inner：
          -- 查询文件里 @assignment.inner 同时标了等号左边和右边两处
          -- （为了让没有右边的写法也能选中），结果 i= 会优先选中更小的左边，
          -- 变成「改变量名」而不是「改值」。rhs 明确只指右边。
          ["="] = ts({ a = "@assignment.outer", i = "@assignment.rhs" }),
        },

        mappings = {
          -- 「往后找 / 往前找」的四个变体，插件默认占的是 an / in / al / il。
          -- 这里挪成大写，是为了让出 Neovim 0.12 内置的可视模式 an / in ——
          -- 那两个键是内置的「按语法结构逐层扩大 / 缩小选区」（:help v_an）。
          -- 插件文档里也给了这个改法，见 :help MiniAi-default-an-in。
          --
          -- 用法：aNq 选「光标后面下一对」引号，aLq 选「光标前面上一对」引号。
          -- 不加 N / L 时是默认的搜索策略：先看光标在不在里面，不在就往后找最近的。
          around_next = "aN",
          inside_next = "iN",
          around_last = "aL",
          inside_last = "iL",

          -- g[ / g] 跳到「当前对象的左边界 / 右边界」，例如 g]f 跳到函数调用的右括号。
          -- g] 盖住了内置命令（对光标处的 tag 执行 :tselect）。
          -- 本配置没有配 ctags，用不到那条；真要用的话直接敲 :tselect 关键词。
          -- g[ 内置没有占用。
          goto_left = "g[",
          goto_right = "g]",
        },
      }
    end,
  },
}

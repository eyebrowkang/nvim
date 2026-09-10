-- lua/plugins/ts-context.lua
-- 上下文粘顶：nvim-treesitter-context
--
-- 函数写长了、循环嵌套深了，往下滚几屏之后就看不见「我现在在哪个函数、
-- 哪个 if 分支里」了。这个插件把外层结构那几行钉在窗口最上面，
-- 滚到哪儿都跟着，等于给代码加了一个面包屑。
--
-- 靠 treesitter 的语法树判断「外层是什么」，所以是真的按语言文法算的，
-- 不是按缩进猜。每种语言由插件仓库里的 queries/<语言>/context.scm 定义
-- 「哪些节点算上下文」，支持的语言列表见它的 README。
--
-- ⚠ 需要对应语言的解析器。没装解析器的语言就是没有效果，不报错。
--   本配置的解析器在 lua/plugins/treesitter.lua 里管，那边加一种语言，
--   这边自动就有了。注意它**不依赖 nvim-treesitter 这个插件本身**，
--   只依赖解析器，所以这里不用写 dependencies。
--
-- 命令：
--   :TSContext toggle     临时开 / 关（也绑了 <leader>ct）
--   :TSContext enable     开
--   :TSContext disable    关

return {
  {
    "nvim-treesitter/nvim-treesitter-context",

    -- 打开文件时才需要。它自己在 enable() 里会遍历一遍已经加载的缓冲区，
    -- 所以即使加载得比第一个文件晚，当前这个文件照样立刻生效。
    event = { "BufReadPost", "BufNewFile" },

    -- 命令要单独报备，否则手敲 :TSContext 是 E492（见 docs/lua-api.md 第 6 个坑）。
    cmd = "TSContext",

    keys = {
      { "<leader>ct", "<cmd>TSContext toggle<CR>", desc = "开关上下文粘顶" },
    },

    -- ⚠ 这个插件的 plugin/ 目录里有一句无参数的 setup()，
    --   也就是 docs/lua-api.md 第 4 个坑说的「插件自己会调 setup()」。
    --   这里写 opts 之后 setup 会跑两遍：先是插件自己用默认值跑一次，
    --   然后 lazy.nvim 带着下面这张表再跑一次。
    --   它的 setup 明确写了「可能被调用多次」，第二次会先 disable 再 enable，
    --   结果是对的，所以照常写 opts 就行 —— 但知道有这回事，
    --   排查「为什么默认值先生效了一下」时才不会懵。
    opts = {
      -- 最多钉几行。默认 0 = 不限，嵌套深的地方能占掉半屏。
      -- 3 行的意思是「最外面那层、中间一层、最里面那层」，
      -- 再深就按下面 trim_scope 的规则丢掉一些。
      max_lines = 3,

      -- 没设 trim_scope：默认 "outer"，即超出 max_lines 时丢最外层的。
      --   留下的是离光标最近的几层，也就是当前最相关的那部分。
      --   反过来设成 "inner" 会保住文件级的那层（比如 class 名），
      --   代价是看不见紧贴着自己的 if / for。
      --
      -- 没设 mode：默认 "cursor"，即按**光标所在行**算上下文。
      --   另一个值 "topline" 按窗口最上面那一行算。
      --   两者的差别只在「光标不动、只滚屏」时看得出来：
      --   cursor 模式下钉的还是光标那一层，topline 模式下跟着滚。
      --
      -- 没关 line_numbers：默认 true，钉住的行会带上它自己的行号，
      --   和左边的行号列对齐。这样一眼能看出「外层那个 if 在第几行」。
      --
      -- 没设 multiline_threshold：默认 20，即单独一层最多展开 20 行。
      --   参数列表拆成很多行的函数签名会被完整钉住，占地方但信息全。
      --   只想看第一行就设成 1。
      --
      -- 没设 separator：默认没有分隔线。
      --   设成 "─" 之类会在钉住区和正文之间画一条线，但它附带一个条件：
      --   光标上方至少有 2 行时才显示上下文。宁可不要这个副作用。
      --
      -- 没开 multiwindow：默认 false，只有当前窗口显示上下文。
      --   开了之后分屏里每个窗口都各钉各的，屏幕会变得很挤。
    },

    -- 顺带一提，它和会话插件是自动配合好的：它监听 User SessionSavePre
    -- 事件关掉自己那个浮窗，而 lua/plugins/persisted.lua 的 before_save
    -- 正好会发这个事件。所以存会话时不会把这个浮窗一起存进去。
  },
}

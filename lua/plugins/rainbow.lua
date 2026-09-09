-- lua/plugins/rainbow.lua
-- 彩虹括号：rainbow-delimiters
--
-- 把嵌套的括号按层级染成不同颜色，一眼看出哪个 ) 对应哪个 (。
--
-- 依赖 treesitter：它靠语法树判断「这一对括号是第几层」，不是数字符。
-- 所以只在装了对应语言解析器的文件里生效。Neovim 0.12 自带这几个解析器：
--   c · lua · markdown · markdown_inline · query · vim · vimdoc
-- 也就是说现在写这份配置（Lua）已经能看到效果，
-- 其他语言要等以后装 nvim-treesitter 并下载对应解析器。

return {
  {
    "HiPhish/rainbow-delimiters.nvim",

    -- 必须用 FileType，不能用 indent.lua 那组 BufReadPost/BufNewFile。
    -- 这个插件是靠自己注册的 FileType 自动命令来挂上缓冲区的，
    -- 而打开文件的事件顺序是 FileType 先、BufReadPost 后 ——
    -- 等到 BufReadPost 才加载它，它的自动命令就永远错过当前这个缓冲区，
    -- 表现为「开第一个文件没有彩虹括号，切一次文件类型才出现」。
    --
    -- 用 FileType 触发就没这个问题：lazy.nvim 把插件加载完之后，
    -- 会把刚才那个事件原样重新广播一次，插件自己的处理函数就接上了。
    -- 判断标准：插件靠哪个事件工作，就用哪个事件懒加载它。
    event = "FileType",

    -- 这里既没有 opts 也没有 config，是刻意的，两个原因：
    --
    -- 1. 这个插件没有 setup() 函数。它的配置读的是全局变量 vim.g.rainbow_delimiters，
    --    加载时自己去读。写 opts 会让 lazy.nvim 去调用不存在的 setup()。
    --    ——「装插件先调 setup()」只是社区惯例，不是规矩，装之前值得翻一眼它的 README。
    --
    -- 2. 默认行为（七色循环、对所有语言生效）就是想要的，没什么可改。
    --
    -- 想换配色的话，在这里加一个 init 函数设置 vim.g.rainbow_delimiters，
    -- 其中 highlight 是一个高亮组名的列表，按层级从外到内循环使用：
    --   RainbowDelimiterRed / Yellow / Blue / Orange / Green / Violet / Cyan
    -- tokyonight 已经帮这七个组配好了色，和主题是一套。
  },
}

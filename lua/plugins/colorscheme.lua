-- lua/plugins/colorscheme.lua
-- 配色方案：tokyonight
--
-- 本文件返回一张「插件 spec 列表」，lazy.nvim 会把 lua/plugins/ 下所有文件
-- 返回的列表合并起来。spec 常用字段：
--   [1]（第一个字符串）  插件仓库，"user/repo" 是 GitHub 的简写
--   lazy                 是否懒加载。true = 等到被需要时才加载
--   priority             加载优先级，数字大的先加载。只对非懒加载的插件有意义
--   opts                 一张表，lazy.nvim 会自动帮你调用 require("插件").setup(opts)
--   config               加载后要执行的函数。一旦写了 config，就不会再自动调 setup，
--                        得自己调；函数签名是 function(plugin_spec, opts)
--   dependencies         依赖的其他插件，会先于它加载

return {
  {
    "folke/tokyonight.nvim",

    -- 主题不能懒加载。它必须在屏幕第一次绘制之前就位，
    -- 否则启动瞬间会先闪一下 Neovim 默认配色再跳成 tokyonight。
    lazy = false,

    -- 1000 是社区约定的「主题专用」优先级，确保它排在其他插件前面加载。
    -- 因为别的插件在加载时会去读当前的高亮组来给自己配色，主题得先定下来。
    priority = 1000,

    opts = {
      -- 四个风格，改这一个词就能换：
      --   "storm" 深蓝灰底，对比适中，最经典的一款
      --   "moon"  比 storm 略深一点、偏紫，插件默认值
      --   "night" 最深，接近纯黑底
      --   "day"   浅色主题
      style = "storm",

      -- 系统切到浅色模式时（vim.o.background = "light"）自动用哪个风格。
      light_style = "day",

      -- 是否让编辑区背景透明（透出终端自己的背景/毛玻璃效果）。
      -- 关掉，用主题自己的背景色，颜色对比才是主题作者调好的样子。
      transparent = false,

      -- 把主题的调色板同步给 :terminal 里开的终端，
      -- 这样内嵌终端的配色和编辑区是一套，不会突兀。
      terminal_colors = true,

      styles = {
        -- 注释和关键字用斜体。终端字体不支持斜体时会退化成别的样式（通常是反色），
        -- 觉得难看就把这两行改成 {}。
        comments = { italic = true },
        keywords = { italic = true },
        functions = {},
        variables = {},

        -- 侧边栏（如文件树）和浮动窗口的背景：
        -- "dark" 比主背景更深一档，让它们和编辑区有层次区分；
        -- 另外两个可选值是 "transparent" 和 "normal"（与主背景一致）。
        sidebars = "dark",
        floats = "dark",
      },

      -- 是否把「非当前窗口」调暗。分屏多的时候能一眼看出焦点在哪，
      -- 但也会让另一半代码变得难读。先关掉，需要再开。
      dim_inactive = false,
    },

    -- 这里必须用 config 而不是只写 opts：
    -- 光 setup() 只是把配置存下来并生成高亮定义，真正生效还要执行 :colorscheme。
    config = function(_, opts)
      require("tokyonight").setup(opts)
      -- vim.cmd.colorscheme("x") 等价于 :colorscheme x，
      -- 比 vim.cmd("colorscheme x") 少一层字符串拼接，参数也不用担心转义。
      vim.cmd.colorscheme("tokyonight")
    end,
  },
}

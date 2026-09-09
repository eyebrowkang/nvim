-- lua/plugins/lualine.lua
-- 状态栏：lualine
--
-- 接管了原生的 statusline（屏幕底部那一条）。
-- 因为它已经显示模式，options.lua 里把 showmode 关掉了，避免重复。

return {
  {
    "nvim-lualine/lualine.nvim",

    -- 依赖图标库。dependencies 的作用是保证加载顺序：
    -- mini.icons 会先加载并完成 mock，lualine 之后 require("nvim-web-devicons")
    -- 才拿得到东西。顺序反了图标会全部消失。
    dependencies = { "nvim-mini/mini.icons" },

    -- 状态栏一直可见，没有「等到某个时机再加载」的说法，直接跟着启动加载。
    lazy = false,

    opts = {
      options = {
        -- 用 tokyonight 官方提供的 lualine 配色，状态栏和编辑区是同一套色板。
        -- 写 "auto" 也能用，但那是让 lualine 去猜当前主题的高亮组，效果不如专门适配的。
        theme = "tokyonight",

        -- 分隔符。component 是同一段内各组件之间的分隔，section 是段与段之间的分隔。
        -- 这两个是 Nerd Font 的「powerline 箭头」字符，字体没配好会显示成豆腐块，
        -- 那就把两个都改成 { left = "", right = "" }（空字符串 = 不画分隔符）。
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },

        -- 只画一条全局状态栏，而不是每个分屏底部各画一条。
        -- 分屏多的时候能省下好几行屏幕空间，代价是看不出「每个窗口各自的」文件名。
        globalstatus = true,
      },

      -- 六个区段，从左到右依次排布：a b c ...(中间留白)... x y z。
      -- 每个区段是一个组件列表，删掉某项就是不显示它。
      sections = {
        lualine_a = { "mode" },                       -- 当前模式：NORMAL / INSERT / VISUAL…
        lualine_b = { "branch", "diff", "diagnostics" }, -- git 分支、增删改统计、LSP 诊断计数
        lualine_c = { "filename" },                   -- 文件名（相对路径 + 修改/只读标记）
        lualine_x = { "encoding", "fileformat", "filetype" }, -- 编码、换行符风格、文件类型
        lualine_y = { "progress" },                   -- 在文件中的百分比位置
        lualine_z = { "location" },                   -- 行:列
      },

      -- 非当前窗口用的状态栏。globalstatus = true 时用不上，
      -- 但留着它，将来把 globalstatus 改回 false 就直接生效。
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { "filename" },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },
    },
  },
}

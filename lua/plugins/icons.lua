-- lua/plugins/icons.lua
-- 图标库：mini.icons
--
-- 它本身不显示任何东西，只是一张「名字 → 图标 + 颜色」的查询表，
-- 供别的插件调用（状态栏、文件树、补全菜单…）。所以单独装它看不出效果。
--
-- 图标字符本身来自 Nerd Font：一批把图标塞进 Unicode 私有区的补丁字体。
-- 终端必须用 Nerd Font，否则这些码点渲染成方框「豆腐块」。
-- macOS: brew install --cask font-jetbrains-mono-nerd-font
--        然后在 ~/.config/ghostty/config 写 font-family = "JetBrainsMono Nerd Font"
-- Linux: 从 nerdfonts.com 下 ttf 放进 ~/.local/share/fonts/，再执行 fc-cache -fv

return {
  {
    "nvim-mini/mini.icons",

    -- mini.nvim 是一套「一个模块一个功能」的插件集合，
    -- 每个模块都有独立的镜像仓库，装单个模块就用这种 mini.xxx 的仓库名。

    -- 懒加载：没人调用它就不加载。
    -- 真正触发加载的是 dependencies —— lualine 和 alpha 在自己的 spec 里
    -- 把它列为依赖，lazy.nvim 会保证它先于那两个插件加载完。
    lazy = true,

    opts = {
      -- "glyph" 用 Nerd Font 图标；字体没配好想临时应急，可以改成 "ascii"，
      -- 它会退化成纯 ASCII 字母，虽然丑但至少不会满屏豆腐块。
      style = "glyph",
    },

    -- 这里必须用 config 而不是只写 opts，因为除了 setup 还要多做一步 mock。
    config = function(_, opts)
      require("mini.icons").setup(opts)

      -- 生态里的绝大多数插件写死了 require("nvim-web-devicons")，
      -- 那是另一个图标库。mock 会伪造一个同名模块塞进 Lua 的模块缓存，
      -- 把调用转发给 mini.icons —— 于是那些插件照常工作，
      -- 但图标实际由 mini.icons 提供，全局只有一套图标风格。
      --
      -- 时机很重要：必须赶在任何插件 require("nvim-web-devicons") 之前执行。
      -- 靠 dependencies 保证顺序，见 lualine.lua / alpha.lua。
      require("mini.icons").mock_nvim_web_devicons()
    end,
  },
}

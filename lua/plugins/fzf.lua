-- lua/plugins/fzf.lua
-- 模糊查找器：fzf-lua
--
-- 弹出一个输入框，边打字边过滤候选项，用来找文件、找内容、找帮助文档等等。
-- 底层是命令行工具 fzf，插件负责把候选项喂给它、把选中结果接回来。
--
-- ⚠ 需要两个外部命令，两个平台都要装：
--     fzf       模糊匹配引擎，必需     macOS: brew install fzf
--     ripgrep   全文搜索用（下面的     Linux: apt install fzf ripgrep
--               <leader>fg 靠它）
--   没装 fzf 的话插件加载不会报错，但一按快捷键就会提示找不到命令。
--
--   查缺了哪个，用 :checkhealth fzf_lua —— 注意是下划线，不是插件名里的连字符
--   （健康检查的名字取自插件里的文件名 autoload/health/fzf_lua.vim）。
--   另外这个插件是懒加载的，得先按一次下面的快捷键让它载入，
--   否则 :checkhealth 会说「找不到该插件的健康检查」。
--   媒体预览那三项（viu / chafa / ueberzugpp）报警告是正常的，
--   它们只影响在终端里预览图片，不装不影响任何上面的功能。

return {
  {
    "ibhagwan/fzf-lua",

    -- 文件类型图标走 mini.icons 的伪装（见 icons.lua）。
    dependencies = { "nvim-mini/mini.icons" },

    -- 懒加载：用到才载入。两条触发路径都要写。
    cmd = "FzfLua",

    keys = {
      -- ---- 找东西：统一放在 <leader>f 下（f = find）----

      -- 最常用的两个：按文件名找文件、按内容搜整个项目。
      { "<leader>ff", "<cmd>FzfLua files<CR>", desc = "找文件" },
      { "<leader>fg", "<cmd>FzfLua live_grep<CR>", desc = "全项目搜内容" },

      -- 搜光标下的那个词，省去手打。
      { "<leader>fw", "<cmd>FzfLua grep_cword<CR>", desc = "搜光标下的词" },

      -- 在已打开的 buffer 之间找。
      -- 和 <leader>bb（barbar 的按字母跳）的分工：
      --   <leader>bb  标签少的时候更快，一眼看到就按字母
      --   <leader>fb  标签多、或者只记得路径不记得位置时用，能看到完整路径
      { "<leader>fb", "<cmd>FzfLua buffers<CR>", desc = "找已打开的 buffer" },

      { "<leader>fr", "<cmd>FzfLua oldfiles<CR>", desc = "最近打开过的文件" },

      -- 在当前文件内按行找，比 / 搜索更适合「大概记得写过但不记得关键词」的情况。
      { "<leader>fl", "<cmd>FzfLua blines<CR>", desc = "在当前文件内按行找" },

      -- ---- 查文档和配置本身 ----

      -- 搜 :help 全文。比 :help 加 Tab 补全好用，因为它搜的是内容不只是标题。
      { "<leader>fh", "<cmd>FzfLua helptags<CR>", desc = "搜帮助文档" },

      -- 列出当前所有按键映射，带 desc 描述。
      -- 学配置阶段特别有用：能直接看到某个键是被谁占了、内建的默认映射有哪些。
      { "<leader>fk", "<cmd>FzfLua keymaps<CR>", desc = "查所有按键映射" },

      -- 上一次的查找结果重新打开，不用重新输入条件。
      { "<leader>f<CR>", "<cmd>FzfLua resume<CR>", desc = "恢复上次查找" },
    },

    opts = {
      -- 数组的第一项是「预设方案」，fzf-lua 用它一次性设好一整套外观。
      -- border-fused：查找框和预览窗共用一个外框，看起来是一个整体面板。
      -- 其他可选：default（分离的两个框）、ivy（贴在屏幕底部）、telescope（模仿 telescope 布局）。
      -- 换着试一下就知道喜欢哪个：:lua require("fzf-lua").setup({"ivy"})
      "border-fused",

      winopts = {
        -- 和 lazy.nvim 面板（lua/config/lazy.lua 里设的 border = "rounded"）保持一致。
        border = "rounded",
        preview = {
          -- 预览窗放右边，占 55% 宽度。
          -- 窗口太窄时自动改成上下排布，不用手动切。
          layout = "flex",
          horizontal = "right:55%",
        },
      },

      -- 这里没有配色相关设置：fzf-lua 会自动读取当前 colorscheme 的高亮组，
      -- tokyonight 换风格时它跟着变，不需要额外同步。
    },
  },
}

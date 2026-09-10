-- lua/plugins/colorizer.lua
-- 颜色代码高亮：nvim-colorizer
--
-- 把源码里的颜色值直接用该颜色显示出来，#24283b 会以那个深蓝灰作背景画出来。
-- 调主题配色、写 CSS 时省掉「改一下、切出去看一眼」的来回。

return {
  {
    -- 注意作者：原作者 norcalli 的仓库已经停更多年，
    -- catgoose 这个是社区接手维护的活跃分支，功能是原来的超集。
    "catgoose/nvim-colorizer.lua",

    -- 只在打开文件时加载，理由同 indent.lua。
    event = { "BufReadPost", "BufNewFile" },

    opts = {
      -- 对哪些文件类型生效。"*" 是通配，表示所有类型。
      -- 想收窄成只在样式文件里生效，把它换成 { "css", "scss", "html", "lua" }。
      filetypes = { "*" },

      user_default_options = {
        -- 识别哪些写法。关掉用不上的可以少一点误判和开销。
        names = false, -- 关掉英文颜色名。开着的话 lua 里的变量 red、代码里的 tan 都会被染色，很吵
        RGB = true, -- #RGB      三位十六进制简写
        RRGGBB = true, -- #RRGGBB   六位十六进制
        RRGGBBAA = true, -- #RRGGBBAA 带 alpha 通道的八位
        rgb_fn = true, -- rgb() / rgba() 函数写法
        hsl_fn = true, -- hsl() / hsla() 函数写法
        css = false, -- 一次性打开上面所有 CSS 相关识别（含 names），这里逐项控制，不用它
        css_fn = false, -- 一次性打开所有函数写法，同上

        -- 怎么显示：
        --   "background" 用该颜色作背景，文字自动取黑或白保证可读 —— 最直观
        --   "foreground" 只把文字染成该颜色
        --   "virtualtext" 在行尾追加一个小色块，不动原文
        mode = "background",
      },
    },
  },
}

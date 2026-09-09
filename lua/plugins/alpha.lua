-- lua/plugins/alpha.lua
-- 起始页：alpha-nvim
--
-- 不带文件名直接敲 nvim 时显示的欢迎界面，代替空白缓冲区。
-- 带文件名启动（nvim foo.lua）或从管道读入内容时，alpha 会自动让路，不会挡路。

return {
  {
    "goolord/alpha-nvim",

    -- 图标库要先加载完，下面的按钮文字里用了 Nerd Font 图标。
    dependencies = { "nvim-mini/mini.icons" },

    -- 起始页要在启动时立刻显示，没有更晚的时机可等，所以不懒加载。
    lazy = false,

    config = function()
      -- alpha 只提供框架，具体长什么样由「主题」决定。
      -- dashboard 是内置主题之一：居中的 logo + 一列快捷按钮 + 页脚。
      local dashboard = require("alpha.themes.dashboard")

      -- 每个字符串是一行，alpha 会整体水平居中。
      -- 用的是制表符和方块字符，不需要 Nerd Font。
      dashboard.section.header.val = {
        [[                                                     ]],
        [[  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ]],
        [[  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ]],
        [[  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ]],
        [[  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ]],
        [[  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ]],
        [[  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ]],
        [[                                                     ]],
      }

      -- dashboard.button(按键, 显示文字, 按下后执行的按键序列)
      -- 第三个参数是当成按键喂给 Neovim 的，所以命令要以 <CR> 结尾表示回车。
      -- 第一个参数同时也是快捷键：在起始页上直接按那个字母就能触发。
      dashboard.section.buttons.val = {
        dashboard.button("e", "  新建文件", "<cmd>ene<CR>"),
        dashboard.button("r", "  最近打开", "<cmd>browse oldfiles<CR>"),
        dashboard.button("c", "  编辑配置", "<cmd>edit $MYVIMRC<CR>"),
        dashboard.button("l", "󰒲  插件管理", "<cmd>Lazy<CR>"),
        dashboard.button("h", "󰗶  健康检查", "<cmd>checkhealth<CR>"),
        dashboard.button("q", "  退出", "<cmd>qa<CR>"),
      }

      -- 先给页脚一个占位值，下面的自动命令再把真实数据填进去。
      dashboard.section.footer.val = { "" }

      require("alpha").setup(dashboard.config)

      -- 页脚显示插件数量和启动耗时。
      -- 为什么要放进自动命令而不是直接写在上面：这两个数字要等启动流程走完才有意义。
      -- lazy.nvim 在界面就绪后（UIEnter）会广播一个 User 事件 VeryLazy，
      -- 那时统计数据才填好，所以挂在它上面，算完再让 alpha 重画一次。
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true, -- 只需要算一次
        callback = function()
          local stats = require("lazy").stats()
          -- startuptime 单位是毫秒的浮点数，这里四舍五入到两位小数。
          local ms = math.floor(stats.startuptime * 100 + 0.5) / 100
          dashboard.section.footer.val = {
            ("󱐋 %d/%d 个插件已加载，启动耗时 %sms"):format(stats.loaded, stats.count, ms),
          }
          -- 用 pcall 包一层：如果此刻当前窗口不是起始页（比如你是带着文件名启动的），
          -- AlphaRedraw 会报错。这只是个页脚，不值得因此打断启动。
          pcall(vim.cmd.AlphaRedraw)
        end,
      })
    end,
  },
}

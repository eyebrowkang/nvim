-- lua/plugins/neotree.lua
-- 文件树：neo-tree
--
-- 屏幕左侧的树状文件浏览器。除了文件系统，它还能用同一个面板展示
-- 「当前打开的 buffer」和「git 改动状态」，三种视图用 < > 切换。
--
-- :checkhealth neo-tree 会提醒缺 gio，那是 Linux 上「删除到回收站」用的可选命令，
-- 不装的话删除就是直接删，其余功能不受影响。

return {
  {
    "nvim-neo-tree/neo-tree.nvim",

    -- 官方 README 指定用 v3.x 这条稳定分支；仓库默认分支 main 是开发线。
    -- 两条都在维护，但发给用户的是 v3.x。
    branch = "v3.x",

    dependencies = {
      -- plenary：一堆 Lua 工具函数（异步、路径处理、任务），
      --   Neovim 生态里的通用底座，很多插件都依赖它。
      "nvim-lua/plenary.nvim",
      -- nui：浮窗、输入框、弹出菜单等 UI 组件库，neo-tree 的界面由它画。
      "MunifTanjim/nui.nvim",
      -- 文件图标，走 mini.icons 的伪装（见 icons.lua）。
      "nvim-mini/mini.icons",
    },

    -- 懒加载：只有真正要用文件树时才载入。
    -- cmd 让 :Neotree 能触发加载，keys 让下面那个快捷键能触发加载。
    -- 两个都写是因为触发路径有两条，少写一个就会出现「敲命令能用、按键不能用」。
    cmd = "Neotree",

    keys = {
      { "<leader>e", "<cmd>Neotree toggle<CR>", desc = "切换文件树" },
      { "<leader>E", "<cmd>Neotree reveal<CR>", desc = "在文件树中定位当前文件" },
    },

    opts = {
      -- 文件树是最后一个窗口时自动关掉 Neovim，
      -- 免得出现「只剩一棵树，退不掉也编辑不了」的尴尬状态。
      close_if_last_window = true,

      -- 展开/折叠、以及各种状态图标。这些字符需要 Nerd Font。
      default_component_configs = {
        indent = {
          with_expanders = true, -- 目录前面显示可点的展开箭头
          expander_collapsed = "",
          expander_expanded = "",
        },
        git_status = {
          -- git 状态用符号而不是文字，占的宽度更稳定。
          symbols = {
            added = "", -- 这三个留空是因为 neo-tree 会用颜色区分，
            modified = "", -- 再加符号反而挤，颜色已经够。
            deleted = "✖",
            renamed = "󰁕",
            untracked = "",
            ignored = "",
            staged = "",
            unstaged = "",
            conflict = "",
          },
        },
      },

      window = {
        width = 32, -- 默认 40 偏宽，会挤掉正文
        mappings = {
          -- neo-tree 自带一整套树内按键（见 ?）。这里只调整两处：
          -- 空格默认是 toggle_node，但空格是我们的 leader 键，
          -- 留着会让树里所有 <leader>xxx 映射都慢半拍（要等 timeoutlen 判断）。
          ["<space>"] = "none",
          -- 回车展开目录/打开文件，和 o 一样，符合直觉。
          ["<cr>"] = "open",
        },
      },

      filesystem = {
        -- 在树里删除/重命名文件后，同步更新已经打开的 buffer 名字，
        -- 否则会留下指向旧路径的僵尸 buffer。
        use_libuv_file_watcher = true,

        filtered_items = {
          -- 默认隐藏点文件和 .gitignore 里的东西，
          -- 在树里按 H 可以临时显示出来。
          visible = false,
          hide_dotfiles = true,
          hide_gitignored = true,
          -- 但这几个点文件是要经常改的，单独放出来。
          never_show = { ".DS_Store" },
          always_show = { ".gitignore", ".github", ".config" },
        },

        -- 切换 buffer 时，树里的高亮跟着跳到对应文件。
        -- leave_dirs_open = false：跟随时收起之前展开的无关目录，避免树越来越长。
        follow_current_file = {
          enabled = true,
          leave_dirs_open = false,
        },
      },
    },
  },
}

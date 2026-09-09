-- lua/plugins/whichkey.lua
-- 按键提示：which-key
--
-- 按下 <leader> 之后停顿一下，屏幕下方弹出一张表，
-- 告诉你接着按什么、分别是什么功能。表里的说明文字直接取自各处映射的 desc，
-- 所以不需要在这里重复维护一份按键清单 —— 加新映射时写好 desc 就自动出现。
--
-- 维护状态说明：这个插件最后一次提交是 2025-10，v3.17.0 之后没再动。
-- 它挂的是 vim.on_key 和映射表查询这两个很稳定的接口，实测在 0.12 上正常。
-- 如果将来它真的坏了，同类替代是 nvim-mini/mini.clue（和已有的 mini 系列同家）。

return {
  {
    "folke/which-key.nvim",

    -- VeryLazy 是 lazy.nvim 在界面就绪后广播的事件。
    -- 这个插件不参与启动流程，也不需要在第一个文件打开前就位，
    -- 挂在这里可以让它完全不占启动时间。
    event = "VeryLazy",

    opts = {
      -- 弹窗样式：
      --   classic  贴在屏幕底部的经典样式
      --   modern   带圆角边框的浮窗
      --   helix    仿 Helix 编辑器，靠底部、分栏更紧凑
      preset = "modern",

      -- 只声明「前缀分组的名字」。具体每个键的说明文字由各插件自己的 desc 提供，
      -- 不在这里重复写一遍 —— 否则删掉某个插件后这里会留下指向不存在按键的死条目。
      spec = {
        { "<leader>b", group = "buffer 标签" },
        { "<leader>f", group = "查找" },
        { "<leader>s", group = "搜索替换" },
        -- <leader>y / <leader>p 这类单键映射不需要分组，它们本身就是完整映射。
      },

      -- 弹窗延迟：按下前缀键之后等多久才弹。
      -- 设 0 是故意的 —— 学习阶段希望它立刻出来。
      -- 熟练之后如果觉得晃眼，改成 300（毫秒）左右会安静很多。
      delay = 0,
    },

    keys = {
      -- 查当前缓冲区里所有可用的按键（包括插件临时注册的局部映射）。
      -- 在 neo-tree、grug-far 这类有自己一套按键的窗口里特别有用。
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "显示当前缓冲区的所有按键",
      },
    },
  },
}

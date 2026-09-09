-- lua/plugins/todo.lua
-- 待办注释高亮：todo-comments
--
-- 把代码注释里的 TODO / FIXME / HACK / NOTE / WARN / PERF / TEST
-- 这几个关键词高亮成带图标的色块，并且能一键把全项目的待办列出来。
--
-- 关键词后面必须紧跟冒号才会被识别，也就是要写成 `-- TODO: 待办内容`，
-- 只写 `-- TODO 待办内容` 不会高亮。这是插件的默认规则，为的是避免把
-- 正常英文里出现的 todo 一词也染色。
--
-- ⚠ 列出全项目待办的功能依赖 ripgrep（和 fzf.lua、grug-far.lua 是同一个）。
--   只做高亮的话不需要外部命令。

return {
  {
    "folke/todo-comments.nvim",

    -- plenary 提供它内部用的异步和路径工具。
    -- 这个依赖和 neo-tree 声明的是同一个插件，lazy.nvim 只会装一份。
    dependencies = { "nvim-lua/plenary.nvim" },

    -- 它靠自己注册的一批事件给缓冲区上色，打开文件时才需要它。
    -- 这里能用 BufReadPost（而不是像 rainbow.lua 那样必须用 FileType），
    -- 是因为它不依赖文件类型，纯按文本内容匹配关键词。
    event = { "BufReadPost", "BufNewFile" },

    keys = {
      -- 列出全项目的待办，走 fzf-lua 的界面（和 <leader>f 系列一套操作方式）。
      -- 这个命令是 todo-comments 检测到装了 fzf-lua 之后才注册的。
      { "<leader>ft", "<cmd>TodoFzfLua<CR>", desc = "找全项目的待办注释" },

      -- 这里刻意没有映射「跳到下一个/上一个待办」。
      -- 插件 README 推荐的是 ]t 和 [t，但这两个键在 Neovim 0.12 是内建的，
      -- 对应 :tnext / :tprevious（在 tag 匹配列表里前后跳，见 :help ]t）。
      -- 内建已经占用的键不去覆盖。真的常用的话，上面那个列表配合 fzf 也够。
    },

    -- opts 留空表示全用默认：默认关键词、默认配色、默认图标。
    -- 想加自己的关键词（比如 REVIEW），在这里写：
    --   keywords = { REVIEW = { icon = " ", color = "info" } }
    opts = {},
  },
}

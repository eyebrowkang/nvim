-- lua/plugins/conform.lua
-- 代码格式化：conform.nvim
--
-- 「格式化」是按统一规则重排缩进、空格、换行、引号，不改变代码含义。
-- 语言服务器有些自带格式化能力（LSP 内置的 gq 就是用它），但质量参差，
-- 而且社区公认的格式化器（stylua、prettier）大多是独立的命令行工具，不走 LSP。
-- conform 做的事就是：按文件类型把内容喂给对应的命令行工具，把结果写回缓冲区。
--
-- 按键：
--   <leader>cf   格式化。普通模式格式化整个文件，可视模式只格式化选中的部分。
--
-- 保存时不自动格式化。开了当然省事，但代价是「保存」这个动作会改动你没打算改的行 ——
-- 在别人的项目里尤其麻烦，一次保存可能顺手重排几百行，git diff 全是噪音。
-- 想开的话，在下面 opts 里加：
--   format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
--
-- ⚠ 格式化器是外部命令，conform 只负责调用，不负责安装。用 mason 装：
--     :MasonInstall stylua prettierd
--   （ruff 和 taplo 已经作为语言服务器装过了，同一个二进制两用，不用重复装）
--   自查哪个文件类型用了什么、装没装：把光标放在文件里执行 :ConformInfo

return {
  {
    "stevearc/conform.nvim",

    -- 两个触发点：手动敲 :ConformInfo 时，或者按下面 keys 里的按键时。
    -- 平时不加载，因为不格式化就完全用不到它。
    cmd = "ConformInfo",

    keys = {
      {
        "<leader>cf",
        function()
          -- async = true：格式化在后台跑，编辑器不会卡住等外部命令返回。
          -- 可视模式下不用告诉它范围，conform 自己会去读当前选区。
          require("conform").format({ async = true })
        end,
        mode = { "n", "x" },
        desc = "格式化（整个文件或选区）",
      },
    },

    opts = {
      -- 每次格式化的公共选项。
      -- lsp_format = "fallback"：某个文件类型在下面表里没写，就退回用语言服务器的
      -- 格式化能力。默认是 "never"，即没配就什么都不做。有了这行，
      -- 装了语言服务器的语言至少有个能用的格式化，不用每种都在下面列一遍。
      default_format_opts = { lsp_format = "fallback" },

      -- 哪种文件用哪个格式化器。值是一个列表，默认「全部依次跑一遍」，
      -- 前一个的输出是后一个的输入 —— 所以 python 那行是先修 import 再排版。
      formatters_by_ft = {
        -- Lua：stylua 是 Lua 社区事实上的标准格式化器。
        -- 项目根目录放一个 stylua.toml 就能调缩进宽度、列宽等，没有就用它的默认值。
        lua = { "stylua" },

        python = {
          -- ruff 的两个子命令，分别对应 ruff format 和 ruff 的整理 import 规则。
          -- 顺序有讲究：先整理 import（会增删行），再整体排版。
          "ruff_organize_imports",
          "ruff_format",
        },

        -- TOML：taplo 既是语言服务器也是格式化器，同一个二进制。
        toml = { "taplo" },

        -- 下面这些都归 prettier 管。它是前端圈的通用格式化器，一个工具吃很多种格式。
        -- 两个名字的区别：
        --   prettierd   常驻后台的守护进程版，第二次之后几乎瞬间返回
        --   prettier    原版，每次都要启动一次 Node，慢得能感觉到
        -- stop_after_first = true 让它「第一个能跑的成功了就收工」，
        -- 所以实际效果是：装了 prettierd 用它，没装就退回 prettier。
        javascript = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        javascriptreact = { "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "prettierd", "prettier", stop_after_first = true },
        json = { "prettierd", "prettier", stop_after_first = true },
        jsonc = { "prettierd", "prettier", stop_after_first = true },
        yaml = { "prettierd", "prettier", stop_after_first = true },
        html = { "prettierd", "prettier", stop_after_first = true },
        css = { "prettierd", "prettier", stop_after_first = true },
        scss = { "prettierd", "prettier", stop_after_first = true },
        markdown = { "prettierd", "prettier", stop_after_first = true },

        -- 没有 sh / bash 这一项：bash-language-server 自己就会调用 shfmt 格式化，
        -- 上面 default_format_opts 的 fallback 会把 shell 脚本交给它。
        -- 在这里再配一个 shfmt 就成了两套规则来回打架。
        -- 前提是 shfmt 命令得存在：:MasonInstall shfmt
      },
    },
  },
}

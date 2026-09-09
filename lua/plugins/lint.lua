-- lua/plugins/lint.lua
-- 补充检查：nvim-lint
--
-- 「linter」是检查代码问题的命令行工具，报的是语言服务器不管的那一类：
-- 拼写、风格约定、容易出错的写法。结果同样以「诊断」的形式显示
-- （显示样式和跳转按键见 lua/config/options.lua 第 9 节）。
--
-- 这个插件本身只做一件事：在合适的时机运行 linter 命令，
-- 把它的输出解析成 Neovim 的诊断。它不带任何 linter，也不装。
--
-- 大部分语言不需要它 —— 语言服务器已经在做检查了。只在语言服务器覆盖不到的地方补：
--   markdown   marksman 只管链接和标题跳转，不管排版规范，所以补一个 markdownlint
--
-- 刻意没有加的（加了就是重复报同一个问题，同一行出现两条一模一样的警告）：
--   shellcheck   bash-language-server 已经在内部调用它了（见 lsp.lua）
--   ruff         它本身就是 Python 的语言服务器，检查一直在跑（见 lsp.lua）
--   selene       Lua 的 linter，但它要求项目根目录有 selene.toml 才能工作，
--                没有配置文件时只会报错，不适合当默认
--
-- ⚠ linter 是外部命令，用 mason 装：
--     :MasonInstall markdownlint-cli2
--   没装的话，每次触发会弹一条 "Error running ..." 的通知，不影响编辑。

return {
  {
    "mfussenegger/nvim-lint",

    -- 打开文件时才需要，和语言服务器同一个时机。
    event = { "BufReadPre", "BufNewFile" },

    config = function()
      local lint = require("lint")

      -- 哪种文件跑哪些 linter。
      -- 名字是插件内置的 linter 定义名，全部可选项在插件仓库的
      -- lua/lint/linters/ 目录下，一个文件一个。
      lint.linters_by_ft = {
        -- markdownlint-cli2 是 markdownlint 的命令行版本，
        -- 检查标题层级跳跃、列表缩进不一致、行尾多余空格这类问题。
        -- 规则可以在项目根目录放 .markdownlint.jsonc 调整，
        -- 比如本仓库的文档里如果嫌某条规则烦，在那里关掉它就行。
        markdown = { "markdownlint-cli2" },
      }

      -- 这个插件没有「自动运行」的机制，什么时候跑得自己决定。
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
        desc = "保存和打开文件时运行 linter",
        group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
        callback = function()
          -- 不传参数时，它按当前文件类型去上面那张表里查该跑什么。
          -- 表里没有这个文件类型就什么都不做，所以这个自动命令对所有文件生效也无妨。
          lint.try_lint()
        end,
      })

      -- 没有挂在 InsertLeave 或 TextChanged 上：那样每敲几个字就起一次外部进程，
      -- 而且会在一句话写到一半时报错。保存和打开这两个时机已经够用。
    end,
  },
}

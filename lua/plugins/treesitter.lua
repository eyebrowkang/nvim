-- lua/plugins/treesitter.lua
-- 语法解析器：nvim-treesitter
--
-- treesitter 把源码解析成一棵语法树，Neovim 用这棵树来做语法高亮、
-- 判断「光标现在在哪个函数里」等等。它比传统的正则高亮准得多：
-- 传统方式是按字符模式猜，treesitter 是真的按语言文法解析。
--
-- Neovim 0.12 自带解析引擎，但只随包发了 7 个解析器
-- （c · lua · markdown · markdown_inline · query · vim · vimdoc），
-- 这个插件负责下载和编译其余语言的解析器。
--
-- ⚠ 需要两个外部工具，两个平台都要装：
--     C 编译器      macOS: xcode-select --install
--                   Linux: apt install build-essential
--     tree-sitter   要求 0.26.1 以上
--                   macOS: brew install tree-sitter
--                   Linux: 从 github.com/tree-sitter/tree-sitter 的 release 下二进制
--                          （apt 源里的版本通常太旧）
--   注意 CLI 不要用 npm 装，插件官方明确要求用包管理器装的版本。
--   缺任何一个，装解析器会失败，但不影响其他插件，也不影响已装好的解析器。
--   自查：:checkhealth nvim-treesitter

return {
  {
    "nvim-treesitter/nvim-treesitter",

    -- 必须指明 main。这个仓库有两条并存的分支，而且是「完全不兼容的重写」：
    --   main    当前版本，要求 Neovim 0.12+。就是这里用的。
    --   master  旧版本，已冻结，只为 Neovim 0.11 及更早保留。
    -- 网上大量教程写的还是 master 那套 API
    -- （setup { ensure_installed = ..., highlight = { enable = true } }），
    -- 在 main 上完全不存在，照抄会静默无效。判断办法见下面 config 里的写法。
    branch = "main",

    -- 插件官方文档明确写了「不支持懒加载」，所以不能给它加 event / cmd。
    lazy = false,

    -- 每次插件更新后自动重新编译解析器。
    -- 解析器的版本必须和插件里记录的版本对得上，只更新插件不更新解析器会出错。
    build = ":TSUpdate",

    config = function()
      -- 想要哪些语言就写在这里。改完这张表后执行 :TSUpdate 补装新增的。
      -- 已经装过的会被跳过，不会重复编译。
      -- 完整可选列表见插件仓库的 SUPPORTED_LANGUAGES.md，或用 :TSInstall <Tab> 补全。
      require("nvim-treesitter").install({
        -- 配置和脚本
        "bash",
        "lua",
        "luadoc",
        "vim",
        "vimdoc",
        "query",

        -- 标记与数据格式
        -- 没有 jsonc：带注释的 json 用的就是 json 解析器（可以自己验证：
        -- :lua =vim.treesitter.language.get_lang("jsonc") 会打印 json）。
        -- 写上去的话 :TSUpdate 每次都会警告 "skipping unsupported language"。
        "markdown",
        "markdown_inline",
        "json",
        "yaml",
        "toml",

        -- 网页
        "html",
        "css",
        "javascript",
        "typescript",
        "tsx",

        -- 其他常用
        "c",
        "python",
        "regex",
        "diff",

        -- git 相关文件
        "git_config",
        "gitcommit",
        "gitignore",
      })

      -- 装了解析器 ≠ 高亮就开了，这两件事在 main 分支上是分开的。
      --
      -- Neovim 0.12 只在四个内置的 ftplugin 文件里主动调用 vim.treesitter.start()
      -- （lua / markdown / query / help），除此之外没有任何通用机制。
      -- 也就是说上面装的 python、yaml 等等，不写这段就一直用老的正则高亮。
      -- 确认办法：打开一个 .py 文件，把光标停在有颜色的字上执行 :Inspect，
      -- 列出的高亮组里有 @ 开头的（@function.python 之类）就是 treesitter 在管。
      vim.api.nvim_create_autocmd("FileType", {
        desc = "为装了解析器的文件类型开启 treesitter 高亮",
        callback = function(args)
          -- 文件类型名和解析器名不总是一样（比如 ft=sh 对应解析器 bash），
          -- get_lang 负责这层翻译；没有对应关系时它原样返回文件类型名。
          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)

          -- language.add 会去 runtimepath 里找这个解析器：
          -- 找到并加载成功返回 true，找不到返回 nil（不会报错，可以直接当条件用）。
          -- 有了这层判断，没装解析器的语言就静静地退回原来的高亮，不会满屏报错。
          if lang and vim.treesitter.language.add(lang) then
            vim.treesitter.start(args.buf, lang)
          end
        end,
      })

      -- 折叠不在这里配。foldexpr 是全局选项，和这个插件没有依赖关系 ——
      -- lua/config/options.lua 第 10 节把它设成了 vim.treesitter.foldexpr()。
      -- 上面这段 autocmd 让解析器挂上，折叠自然就有了；没装解析器的文件不折叠也不报错。
      --
      -- 这里没开 treesitter 缩进：插件文档自己标注为 experimental，不适合当默认。
    end,
  },
}

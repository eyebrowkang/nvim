-- lua/plugins/lsp.lua
-- 语言服务器：mason + mason-lspconfig + nvim-lspconfig
--
-- LSP（Language Server Protocol）是编辑器和「语言服务器」之间的一套通用协议。
-- 语言服务器是一个独立进程，真正读懂你的项目，编辑器把「光标在第 12 行第 3 列」发过去，
-- 它回答「这是个函数，签名是这样，定义在那个文件」。
-- 和 treesitter 的区别：treesitter 只看单个文件的语法结构（这是不是一个函数？），
-- LSP 看整个项目的语义（这个函数是谁？在哪定义的？调用参数对不对？）。
--
-- Neovim 0.12 自带完整的 LSP 客户端，不需要插件。这里三个插件只解决三件周边的事：
--   mason.nvim          装服务器。语言服务器是一堆五花八门的可执行文件，
--                       这个插件统一下载到 ~/.local/share/nvim/mason/ 并把它的
--                       bin 目录加进 PATH，省得每种语言都去研究一遍怎么装。
--   nvim-lspconfig      提供每个服务器的默认配置（启动命令、管哪些文件类型、
--                       靠什么文件判断项目根目录）。它就是一堆 lsp/<名字>.lua 文件。
--   mason-lspconfig     把上面两个接起来：确保 ensure_installed 里的服务器装好，
--                       并自动对装好的调用 vim.lsp.enable()。
--
-- ⚠ 外部依赖：下面大部分服务器是 npm 包，需要先装 Node.js。
--     macOS: brew install node    Linux: 用 nvm 或发行版的包
--   不需要 Node 的：lua_ls（独立二进制）、taplo、marksman、ruff。
--   自查：:checkhealth mason      看装了什么：:Mason
--
-- 按键：本文件不映射任何按键。Neovim 0.12 已经内置了一整套（:help lsp-defaults），
-- 文件一旦挂上语言服务器就自动可用：
--   K              悬浮显示文档
--   grn            重命名符号（改一处，全项目的引用一起改）
--   gra            代码操作（自动导入、快速修复……普通和可视模式都能用）
--   grr            列出所有引用
--   gri            跳到实现
--   grt            跳到类型定义
--   gO             列出本文件的符号大纲
--   <C-]>          跳到定义（靠 tagfunc；<C-t> 跳回来）
--   <C-s>          插入模式下显示函数签名
--   gq             按语言服务器的规则格式化选中范围（靠 formatexpr）
-- 诊断相关的按键和显示样式在 lua/config/options.lua 第 9 节。

return {
  -- ==================================================================
  -- 1. mason.nvim —— 安装器
  -- ==================================================================
  {
    "mason-org/mason.nvim",

    -- 只有手动敲这些命令时才需要它自己加载。
    -- 但下面的 mason-lspconfig 把它写进了 dependencies，所以实际上开文件时就会被带起来，
    -- cmd 在这里的作用是「万一 mason-lspconfig 没被触发，敲 :Mason 也能用」。
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },

    opts = {
      ui = {
        -- :Mason 界面里每个包前面的状态标记，默认三种状态都是同一个圆点，只靠颜色区分。
        -- 换成三个不同的符号，扫一眼就知道哪些装好了。
        -- 这三个是普通 Unicode 字符，不需要 Nerd Font。
        icons = { package_installed = "✓", package_pending = "➤", package_uninstalled = "✗" },
      },
    },

    -- mason v2 没有 ensure_installed 这个设置项 —— 只有下面 mason-lspconfig 有，
    -- 而且它只认语言服务器。格式化器、linter 这类不是服务器的工具得手动装：
    --   :MasonInstall stylua prettierd markdownlint-cli2
    -- （见 conform.lua 和 lint.lua 的头部说明）
  },

  -- ==================================================================
  -- 2. nvim-lspconfig —— 每个服务器的默认配置
  -- ==================================================================
  {
    "neovim/nvim-lspconfig",

    -- 这个插件不需要 setup()，也不需要任何配置。
    -- 它的全部内容就是仓库里的 lsp/ 目录，被 lazy.nvim 加载后进入 runtimepath，
    -- Neovim 从此就能在里面找到 lsp/lua_ls.lua 这些文件。
    --
    -- 查找和合并的顺序（后面的覆盖前面的，:help lsp-config）：
    --   1. vim.lsp.config("*", {...})        对所有服务器生效的公共设置
    --   2. runtimepath 里所有 lsp/<名字>.lua      ← 这个插件提供的就是这一层
    --   3. runtimepath 里所有 after/lsp/<名字>.lua
    --   4. vim.lsp.config("<名字>", {...})    ← 下面第 3 块里的覆盖写在这一层
    --
    -- 想改某个服务器的配置有两条路：写 vim.lsp.config()（少量改动，就地可见），
    -- 或者在自己配置目录下建 after/lsp/<名字>.lua（改动多时更清爽）。
    -- 本配置用前者，改动都集中在下面一个地方。
    --
    -- 看某个服务器最终用的是什么配置：:lua =vim.lsp.config.lua_ls
    lazy = true,
  },

  -- ==================================================================
  -- 3. mason-lspconfig —— 把两者接起来
  -- ==================================================================
  {
    "mason-org/mason-lspconfig.nvim",

    -- 顺序不能反：mason 要先把 bin 目录加进 PATH，
    -- nvim-lspconfig 要先进 runtimepath，然后才轮到这个插件去 enable。
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },

    -- 打开一个文件时才需要语言服务器，启动画面上不需要，所以懒加载到这两个时机。
    -- 这样安全，是因为 vim.lsp.enable() 会对「已经打开的和之后打开的」缓冲区都生效：
    -- 它内部注册一个 FileType 自动命令，同时对已存在的缓冲区补发一次 FileType。
    -- 所以哪怕 enable 得比文件打开还晚，服务器照样挂得上。
    event = { "BufReadPre", "BufNewFile" },

    -- opts 写成函数，是因为下面同一张列表要用在两个地方，写成表就得抄两遍。
    opts = function()
      -- 这里写的是「nvim-lspconfig 里的服务器名」，不是 mason 的包名
      -- （比如 lua_ls 的 mason 包名叫 lua-language-server），中间的翻译由这个插件负责。
      -- 缺哪个它在启动时自动下载，已装的跳过。
      -- 可选的全部名字：https://github.com/mason-org/mason-lspconfig.nvim 的 README
      local servers = {
        -- Lua：本配置自己就是 Lua 写的，配合 lazydev.nvim（见 lazydev.lua）
        -- 能对 vim.* 这些 Neovim API 做补全和跳转
        "lua_ls",

        -- Shell：bash-language-server。
        -- 它会自动调用 shellcheck 做检查、shfmt 做格式化（前提是这两个命令在 PATH 里），
        -- 所以 shell 脚本不需要再单独配 linter 和格式化器。
        "bashls",

        -- 配置与文档类
        "jsonls", -- JSON，带注释的 jsonc 也归它管
        "yamlls", -- YAML
        "taplo", -- TOML
        "marksman", -- Markdown，管的是链接和标题的跳转补全，不管排版

        -- 前端
        "html",
        "cssls",
        "ts_ls", -- JavaScript / TypeScript（名字里的 ts 指 TypeScript）

        -- Ansible：ansible-language-server。
        -- 它只认 yaml.ansible 这个文件类型，由 lua/config/filetype.lua 产生 ——
        -- Neovim 内置的识别规则里一条 Ansible 都没有，没那个文件它永远挂不上。
        -- 补全模块名和参数、悬浮显示模块文档（K），检查由它调用 ansible-lint 完成。
        "ansiblels",

        -- Python：两个服务器分工，见下面的说明
        "basedpyright",
        "ruff",
      }

      return {
        ensure_installed = servers,

        -- automatic_enable 决定「自动对哪些服务器调用 vim.lsp.enable()」。
        -- 默认值 true 的含义是「凡是 mason 装过、且在 nvim-lspconfig 里有同名配置的，
        -- 一律开启」—— 这个默认值有坑：mason 里装的不只是语言服务器，
        -- 而有些工具恰好两栖。比如格式化器 stylua 带一个 --lsp 模式，
        -- nvim-lspconfig 里也就有一份 lsp/stylua.lua，于是只要为了格式化装了 stylua
        -- （见 conform.lua），每打开一个 Lua 文件就会白白多起一个 stylua 进程。
        --
        -- 所以这里传的不是 true 而是同一张 servers 列表，意思变成
        -- 「只开这些，而且只开其中确实装好了的」。装什么、开什么就是同一张表，
        -- 以后再装别的工具也不会莫名其妙多出服务器来。
        --
        -- 另外，不是 mason 装的服务器（比如系统包管理器装的 gopls）它一概管不着，
        -- 那种要自己写一行：vim.lsp.enable("gopls")
        automatic_enable = servers,
      }
    end,

    -- 用 config 而不是直接给 opts，是因为有些服务器的默认配置需要改，
    -- 而这些 vim.lsp.config() 必须在 setup() 触发 enable 之前调用完 —— 否则服务器
    -- 已经按旧配置启动了。opts 那个参数就是上面那张表，lazy.nvim 会原样传进来。
    config = function(_, opts)
      -- Python 用了两个服务器，得划清界限，否则同一个问题会被报两遍、
      -- 悬浮文档会弹两个窗口。分工是：
      --   basedpyright  类型检查、补全、跳转、悬浮文档
      --   ruff          检查代码风格、格式化、整理 import（Rust 写的，非常快）
      vim.lsp.config("basedpyright", {
        settings = {
          basedpyright = {
            -- 整理 import 交给 ruff，让 basedpyright 别插手。
            disableOrganizeImports = true,

            analysis = {
              -- 两个服务器有一批规则是重合的，不管的话同一行会并排出现两条
              -- 意思一样只是措辞不同的警告（"os imported but unused" 和
              -- "Import os is not accessed"）。这里把重合的那几条从
              -- basedpyright 这边关掉，统一由 ruff 报 —— 它的消息更短，
              -- 而且带规则编号，想临时忽略某条时能直接写 # noqa: F401。
              -- 关掉的只是这几条具体规则，类型检查本身一点没动。
              diagnosticSeverityOverrides = {
                reportUnusedImport = "none", -- 对应 ruff 的 F401
                reportUnusedVariable = "none", -- 对应 ruff 的 F841
                reportUndefinedVariable = "none", -- 对应 ruff 的 F821
                reportRedeclaration = "none", -- 对应 ruff 的 F811
              },
            },
          },
        },
      })

      vim.lsp.config("ruff", {
        -- 服务器挂上缓冲区时执行。这里关掉 ruff 的悬浮文档能力，
        -- 让 K 只由 basedpyright 回答 —— ruff 的悬浮内容只有规则编号，没什么用。
        -- 能力开关关掉之后，Neovim 就不会再向它发这类请求了。
        on_attach = function(client)
          client.server_capabilities.hoverProvider = false
        end,
      })

      -- Ansible。nvim-lspconfig 给的默认 root_markers 只有两项：
      -- ansible.cfg 和 .ansible-lint。问题是这两个文件在很多仓库里都不存在 ——
      -- 独立的 role 仓库、collection 仓库经常一个都没有，于是项目根目录判不出来，
      -- 服务器只能按单个文件工作，跨文件的角色和变量就找不到了。
      -- 这里把常见的仓库标志补上，从具体到宽泛排：galaxy.yml 是 collection
      -- 和 role 的元数据文件，.git 兜底。
      -- root_markers 匹配的是**文件名**，不能写 meta/main.yml 这种带斜杠的路径。
      vim.lsp.config("ansiblels", {
        root_markers = { "ansible.cfg", ".ansible-lint", "galaxy.yml", ".git" },
      })
      -- 没有动它的 settings：nvim-lspconfig 那份默认值已经把
      -- validation.lint.enabled 打开了，检查由服务器自己调 ansible-lint 完成。
      -- 所以 lua/plugins/lint.lua 里刻意没有再配一个 ansible_lint，
      -- 否则同一条规则会被报两遍（和那边 shellcheck、ruff 的处理原则一致）。
      --
      -- ⚠ 它依赖两个外部命令，都不是 mason 自动带的：
      --     ansible        本体，pip install ansible 或系统包管理器
      --     ansible-lint   :MasonInstall ansible-lint（也可以 pip 装）
      --   缺 ansible 时服务器起得来但查不到模块文档；缺 ansible-lint 时没有诊断。

      -- 没有为 lua_ls 写覆盖配置：它需要的 runtime.version、workspace.library
      -- 这些全部由 lazydev.nvim 在运行时动态注入（见 lazydev.lua），
      -- 在这里写死反而会和它打架。
      --
      -- 也没给 jsonls / yamlls 配 schema（那样能对 package.json、GitHub Actions
      -- 这类文件做字段级补全和校验）。要的话得再加一个插件 b0o/SchemaStore.nvim。

      require("mason-lspconfig").setup(opts)
    end,
  },
}

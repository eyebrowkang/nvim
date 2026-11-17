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
-- 保存时默认不自动格式化。开了当然省事，但代价是「保存」这个动作会改动你没打算改的行 ——
-- 在别人的项目里尤其麻烦，一次保存可能顺手重排几百行，git diff 全是噪音。
-- 唯一的例外是 Terraform：terraform fmt 只有一套官方风格、没有任何可调选项，
-- 社区项目几乎都在 CI 里跑 terraform fmt -check，不存在「别人的规矩和我不一样」，
-- 所以保存即格式化只有好处。白名单见下面的 format_on_save。
--
-- ⚠ 格式化器是外部命令，conform 只负责调用，不负责安装。用 mason 装：
--     :MasonInstall stylua prettierd
--   （ruff 和 taplo 已经作为语言服务器装过了，同一个二进制两用，不用重复装）
--   自查哪个文件类型用了什么、装没装：把光标放在文件里执行 :ConformInfo

return {
  {
    "stevearc/conform.nvim",

    -- 三个触发点：手动敲 :ConformInfo、按下面 keys 里的按键，或者第一次保存文件。
    -- 最后一个是给 format_on_save 用的：conform 靠自己注册的 BufWritePre 自动命令
    -- 在写盘前格式化，插件没加载就没有这条自动命令。lazy.nvim 拦下第一次
    -- BufWritePre、加载插件后会把这个事件重放一遍，所以第一次保存也能格式化上。
    -- 代价是任何文件第一次保存时都会加载 conform，它很轻，可以忽略。
    cmd = "ConformInfo",
    event = "BufWritePre",

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

      -- 保存时格式化的白名单。写成函数是因为 conform 对每个缓冲区都会问一次：
      -- 返回选项表就格式化，返回 nil 就跳过。只有下面列出的文件类型返回选项表。
      -- timeout_ms：保存时的格式化是同步的（必须等结果出来才能写盘），
      -- terraform fmt 通常几十毫秒就返回，给 1 秒是留余量；超时就放弃格式化、照常保存。
      format_on_save = function(bufnr)
        local enabled = { terraform = true, ["terraform-vars"] = true }
        if enabled[vim.bo[bufnr].filetype] then
          return { timeout_ms = 1000 }
        end
      end,

      -- 哪种文件用哪个格式化器。值是一个列表，默认「全部依次跑一遍」，
      -- 前一个的输出是后一个的输入 —— 所以 python 那行是先修 import 再排版。
      formatters_by_ft = {
        -- Lua：stylua 是 Lua 社区事实上的标准格式化器。
        -- 缩进宽度、列宽这些规则读自项目根目录的 stylua.toml ——
        -- 本仓库根目录就有一份，逐项写了注释。
        -- ⚠ 没有那个文件时 stylua 用自己的默认值：tab 缩进、宽度 4。
        --   在别人的项目里按 <leader>cf 之前，先确认那边有没有配置文件，
        --   否则一次格式化就会把人家整个文件的缩进换掉。
        lua = { "stylua" },

        python = {
          -- ruff 的两个子命令，分别对应 ruff format 和 ruff 的整理 import 规则。
          -- 顺序有讲究：先整理 import（会增删行），再整体排版。
          "ruff_organize_imports",
          "ruff_format",
        },

        -- TOML：taplo 既是语言服务器也是格式化器，同一个二进制。
        toml = { "taplo" },

        -- Terraform：terraform fmt，从标准输入读、往标准输出写，不碰磁盘上的文件。
        -- 用的是 mason 装的 terraform 二进制（mason 的 bin 目录在 PATH 上）。
        -- .tfvars 也是 HCL 语法，同一个命令照样能排。
        -- 不用 terraform-ls 的格式化：它内部也是调 terraform fmt，多绕一层而已。
        terraform = { "terraform_fmt" },
        ["terraform-vars"] = { "terraform_fmt" },

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

        -- Ansible 的 YAML 不交给 prettier。
        -- 排版归 ansible-lint 管 —— 它内部带一套 yamllint 规则（缩进、行长、
        -- 引号、注释间距都在管），而且它的判断才是 CI 里会拦你的那一个。
        -- prettier 按自己的一套重排，两边规矩不一样，很容易出现
        -- 「格式化完反而多了几条警告」。
        --
        -- ⚠ 写法上有个讲究：这里的键是完整的复合类型 yaml.ansible。
        --   conform 查表时会先拿完整类型试一次，再拆点号从后往前试
        --   （yaml.ansible → ansible → yaml → _），第一个命中的就定了。
        --   所以这一条能精确拦在 yaml 那条前面，普通 YAML 不受影响。
        --   但值不能写成空表 {} —— conform 明确把空表当作「没配」而跳过，
        --   会继续往下落到 yaml 那条。写成返回空表的函数才算数。
        ["yaml.ansible"] = function()
          return {}
        end,

        -- Jinja 模板同理，而且理由更硬：模板里的 {% for %} / {{ 变量 }}
        -- 对底层语言来说就是语法错误，prettier 连解析都过不去。
        -- lua/config/filetype.lua 把这类文件识别成 `底层.jinja`（yaml.jinja、
        -- nginx.jinja……），而 conform 拆点号时是**从后往前**找的，
        -- 所以这一条 jinja 总能抢在 yaml / html 那些前面命中。
        jinja = function()
          return {}
        end,

        -- 没有 sh / bash 这一项：bash-language-server 自己就会调用 shfmt 格式化，
        -- 上面 default_format_opts 的 fallback 会把 shell 脚本交给它。
        -- 在这里再配一个 shfmt 就成了两套规则来回打架。
        -- 前提是 shfmt 命令得存在：:MasonInstall shfmt
      },
    },
  },
}

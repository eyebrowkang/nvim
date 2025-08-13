return {

  -- manage external editor tooling
  -- such as LSP servers, DAP servers, linters, and formatters
  -- through a single interface.
  {
    "mason-org/mason.nvim",
    opts = {
      ui = {
        border = "rounded",
        icons = {
          package_installed = "",
          package_pending = "",
          package_uninstalled = "",
        },
      },
    },
  },

  -- lspconfig
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason-org/mason.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      vim.diagnostic.config({
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = require("config.icons").diagnostics.Error,
            [vim.diagnostic.severity.WARN] = require("config.icons").diagnostics.Warn,
            [vim.diagnostic.severity.HINT] = require("config.icons").diagnostics.Hint,
            [vim.diagnostic.severity.INFO] = require("config.icons").diagnostics.Info,
          },
        },
        float = { border = "double" },
        severity_sort = true,
      })

      vim.lsp.enable({
        "lua_ls",
        "vimls",
        "marksman",
        "jsonls",
        "yamlls",
        "html",
        "cssls",
        "eslint",
        "pyright",
        "terraformls",
        "ansiblels",
      })

      -- for all clients
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("my.lsp", {}),
        callback = function(args)
          local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
          local default_opts = { noremap = true, silent = true, buffer = args.buf }
          local function map(mode, l, r, opts)
            opts = opts or {}
            vim.keymap.set(mode, l, r, vim.tbl_extend("force", {}, default_opts, opts))
          end

          -- 跳转到定义
          if client:supports_method("textDocument/definition") then
            map("n", "gd", require("telescope.builtin").lsp_definitions, { desc = "Goto Definition" })
          end
          -- 跳转到声明
          if client:supports_method("textDocument/declaration") then
            map("n", "gD", vim.lsp.buf.declaration, { desc = "Goto Declaration" })
          end

          -- 查找引用
          if client:supports_method("textDocument/references") then
            map("n", "grr", require("telescope.builtin").lsp_references, { desc = "Goto References" })
          end
          -- 跳转到实现
          if client:supports_method("textDocument/implementation") then
            map("n", "gri", require("telescope.builtin").lsp_implementations, { desc = "Goto Implementation" })
          end
          -- 跳转到类型定义
          if client:supports_method("textDocument/typeDefinition") then
            map("n", "grt", require("telescope.builtin").lsp_type_definitions, { desc = "Goto TypeDefinition" })
          end
          -- 文档符号搜索
          if client:supports_method("textDocument/documentSymbol") then
            map("n", "gO", require("telescope.builtin").lsp_document_symbols, { desc = "Search Document Symbol" })
          end

          -- 签名帮助
          if client:supports_method("textDocument/signatureHelp") then
            map("n", "<C-k>", vim.lsp.buf.signature_help, { desc = "Show SignatureHelp" })
          end

          -- 工作区符号搜索
          if client:supports_method("workspace/symbol") then
            map("n", "<leader>ws", require("telescope.builtin").lsp_workspace_symbols, { desc = "Workspace Symbol" })
          end
        end,
      })
    end,
  },

  -- NOTE: this plugin can be removed later
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = {
        "lua_ls",
        "vimls",
      },
      automatic_enable = false,
    },
  },

  -- with jsonls and yamlls
  {
    "b0o/schemastore.nvim",
    event = "VeryLazy",
  },

  -- with LuaLS
  {
    "folke/lazydev.nvim",
    ft = "lua", -- 仅在打开 lua 文件时加载此插件
    opts = {
      library = {
        -- 当代码里出现 "vim.uv" 这个词时，自动加载 luvit 的类型
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },

        -- 无条件加载 lazy.nvim 的类型
        "lazy.nvim",
      },
      -- disable when a .luarc.json file is found
      enabled = function(root_dir)
        return not vim.uv.fs_stat(root_dir .. "/.luarc.json")
      end,
    },
  },
}

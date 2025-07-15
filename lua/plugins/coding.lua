return {

  -- Use treesitter to autoclose and autorename html tag
  {
    "windwp/nvim-ts-autotag",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    event = "InsertEnter",
    config = true,
  },

  -- autopair (), {}, etc
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
  },

  -- LSP renaming
  {
    "smjonas/inc-rename.nvim",
    enabled = false, -- NOTE: disable this plugin to test vim.lsp.buf.rename()
    cmd = "IncRename",
    keys = {
      {
        "<leader>rn",
        function()
          return ":IncRename " .. vim.fn.expand("<cword>")
        end,
        expr = true,
        desc = "Rename LSP identifier",
      },
    },
    config = true,
  },

  -- comment plugin
  {
    "numToStr/Comment.nvim",
    event = "VeryLazy",
    config = true,
  },

  -- 据当前的语法上下文（依赖Tree-sitter）动态切换注释符号，搭配注释插件使用
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    dependencies = {
      "numToStr/Comment.nvim",
    },
    event = "VeryLazy",
    config = function()
      require("ts_context_commentstring").setup({
        enable_autocmd = false,
      })

      ---@diagnostic disable: missing-fields
      require("Comment").setup({
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      })
    end,
  },

  -- highlight and search for todo comments
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "VeryLazy",
    opts = {},
    keys = {
      {
        "]t",
        function()
          require("todo-comments").jump_next()
        end,
        desc = "Next todo comment",
      },
      {
        "[t",
        function()
          require("todo-comments").jump_prev()
        end,
        desc = "Previous todo comment",
      },
      {
        "<leader>ft",
        function()
          vim.cmd("TodoTelescope")
        end,
        desc = "Open Todo List in Telescope",
      },
    },
    config = true,
  },

  -- code snippets
  {
    "L3MON4D3/LuaSnip",
    build = "make install_jsregexp", -- optional
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },

  -- Completion
  {
    "saghen/blink.cmp",
    -- optional: provides snippets for the snippet source
    dependencies = {
      "L3MON4D3/LuaSnip",
      "nvim-tree/nvim-web-devicons",
      "echasnovski/mini.icons",
    },
    version = "1.*",

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
      -- 'super-tab' for mappings similar to vscode (tab to accept)
      -- 'enter' for enter to accept
      -- 'none' for no mappings
      --
      -- All presets have the following mappings:
      -- C-space: Open menu or open docs if already open
      -- C-n/C-p or Up/Down: Select next/previous item
      -- C-e: Hide menu
      -- C-k: Toggle signature help (if signature.enabled = true)
      --
      -- See :h blink-cmp-config-keymap for defining your own keymap
      keymap = {
        preset = "default",
        ["<C-e>"] = false,
        ["<C-space>"] = false,
        ["<C-c>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-b>"] = { "cancel" },
      },

      appearance = {
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = "mono",
      },

      -- (Default) Only show the documentation popup when manually triggered
      completion = {
        documentation = {
          auto_show = false,
        },
        menu = {
          draw = {
            components = {
              kind_icon = {
                text = function(ctx)
                  local kind_icon, _, _ = require("mini.icons").get("lsp", ctx.kind)
                  return kind_icon
                end,
                -- (optional) use highlights from mini.icons
                highlight = function(ctx)
                  local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
                  return hl
                end,
              },
              kind = {
                -- (optional) use highlights from mini.icons
                highlight = function(ctx)
                  local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
                  return hl
                end,
              },
            },
          },
        },
      },

      snippets = { preset = "luasnip" },

      -- Default list of enabled providers defined so that you can extend it
      -- elsewhere in your config, without redefining it, due to `opts_extend`
      sources = {
        default = { "lazydev", "lsp", "path", "snippets", "buffer" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            -- make lazydev completions top priority (see `:h blink.cmp`)
            score_offset = 100,
          },
        },
      },

      -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
      -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
      -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
      --
      -- See the fuzzy documentation for more information
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },
  },

  {
    "folke/trouble.nvim",
    ---@module 'trouble'
    ---@type trouble.Config
    opts = {
      modes = {
        test = {
          mode = "diagnostics",
          preview = {
            type = "split",
            relative = "win",
            position = "right",
            size = 0.3,
          },
        },
      },
    },
    cmd = "Trouble",
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
      {
        "<leader>xt",
        "<cmd>Trouble todo toggle<cr>",
        desc = "Todo List in Trouble",
      },
    },
  },

  -- Terminal
  {
    "akinsho/toggleterm.nvim",
    cmd = "Toggleterm",
    opts = {
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.5
        end
      end,
      float_opts = {
        border = "curved",
      },
    },
    keys = {
      {
        "<leader>tt",
        function()
          require("toggleterm").toggle()
        end,
        desc = "Open Terminal (Toggleterm)",
      },
      {
        "<leader>tf",
        function()
          require("toggleterm").toggle(nil, nil, nil, "float", nil)
        end,
        desc = "Open Float Terminal (Toggleterm)",
      },
      {
        "<leader>tg",
        function()
          local lazygit = require("toggleterm.terminal").Terminal:new({
            cmd = "lazygit",
            dir = "git_dir",
            direction = "float",
            -- function to run on opening the terminal
            on_open = function(term)
              vim.cmd("startinsert!")
              vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<Cmd>close<CR>", { noremap = true, silent = true })
            end,
            -- function to run on closing the terminal
            on_close = function()
              vim.cmd("startinsert!")
            end,
          })

          lazygit:toggle()
        end,
        desc = "Lazygit (Toggleterm)",
        noremap = true,
        silent = true,
      },
      { "<leader>gg", "<leader>tg", desc = "Lazygit (Toggleterm)", remap = true },
    },
  },

  -- automatically highlighting other uses of the word under the cursor
  -- using either LSP, Tree-sitter, or regex matching.
  {
    "RRethy/vim-illuminate",
    event = "VeryLazy",
    config = function()
      require("illuminate").configure({
        filetypes_denylist = {
          "dirbuf",
          "dirvish",
          "fugitive",
          "mason",
          "neo-tree",
          "checkhealth",
          "notify",
        },
      })
    end,
  },

  -- code formatter
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = { "n", "v" },
        desc = "Format buffer (Conform)",
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
        python = { "isort", "black" },
        -- >>> frontend ⬇️
        html = { "prettier" },
        css = { "prettier" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        ["javascript.jsx"] = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        ["typescript.tsx"] = { "prettier" },
        vue = { "prettier" },
        svelte = { "prettier" },
        astro = { "prettier" },
        htmlangular = { "prettier" },
        -- >>> frontend ⬆️
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        go = { "gofmt", "goimports" },
        rust = { "rustfmt" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        terraform = { "terraform" },
        hcl = { "terraform" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    },
  },
}

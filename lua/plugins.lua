local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local servers = {
  "cssls",
  "golangci_lint_ls",
  "gopls",
  "html",
  "jsonls",
  "lua_ls",
  "prismals",
  "rust_analyzer",
  "tsserver",
  "volar",
}
require("lazy").setup({
  {
    "ibhagwan/fzf-lua",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      local builtin = require('fzf-lua')
      builtin.setup({
        winopts = {
          height = 0.68,
          width = 0.86,
        },
        keymap = {
          builtin = {
            ["<C-y>"] = "preview-page-up",
            ["<C-e>"] = "preview-page-down",
          },
        },
      })
      vim.keymap.set('n', '<LEADER>ff', builtin.files, {})
      vim.keymap.set('n', '<LEADER>fg', builtin.live_grep, {})
      vim.keymap.set('n', '<LEADER>fb', builtin.buffers, {})
      vim.keymap.set('n', '<LEADER>fh', builtin.help_tags, {})
      vim.keymap.set('n', '<LEADER>fl', function() vim.cmd("FzfLua") end)
    end,
  },
  "williamboman/mason.nvim",
  "williamboman/mason-lspconfig.nvim",
  "hrsh7th/nvim-cmp",
  "hrsh7th/cmp-nvim-lsp",
  {
    "L3MON4D3/LuaSnip",
    -- follow latest release.
    version = "1.2.*",
    -- install jsregexp (optional!).
    build = "make install_jsregexp",
    config = function(_, opts)
      if opts then require("luasnip").config.setup(opts) end
      vim.tbl_map(function(type) require("luasnip.loaders.from_" .. type).lazy_load() end,
        { "vscode", "snipmate", "lua" })
    end
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          }
        }
      })
      require("mason-lspconfig").setup({
        ensure_installed = servers,
      })
      -- See `:help vim.diagnostic.*` for documentation on any of the below functions
      local opts = { noremap = true, silent = true }
      vim.keymap.set('n', '<LEADER>le', vim.diagnostic.open_float, opts)
      vim.keymap.set('n', '<LEADER>lp', vim.diagnostic.goto_prev, opts)
      vim.keymap.set('n', '<LEADER>ln', vim.diagnostic.goto_next, opts)
      vim.keymap.set('n', '<LEADER>ll', vim.diagnostic.setloclist, opts)
      -- Use an on_attach function to only map the following keys
      -- after the language server attaches to the current buffer
      local on_attach = function(client, bufnr)
        -- Enable completion triggered by <c-x><c-o>
        vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

        -- Mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local bufopts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
        vim.keymap.set('n', 'gh', vim.lsp.buf.hover, bufopts)

        vim.keymap.set('n', '<LEADER>lh', vim.lsp.buf.signature_help, bufopts)
        vim.keymap.set('n', '<LEADER>la', vim.lsp.buf.add_workspace_folder, bufopts)
        vim.keymap.set('n', '<LEADER>ld', vim.lsp.buf.remove_workspace_folder, bufopts)
        vim.keymap.set('n', '<LEADER>lw', function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, bufopts)
        vim.keymap.set('n', '<LEADER>lt', vim.lsp.buf.type_definition, bufopts)
        vim.keymap.set('n', '<LEADER>lr', vim.lsp.buf.rename, bufopts)
        vim.keymap.set('n', '<LEADER>lc', vim.lsp.buf.code_action, bufopts)
        vim.keymap.set('n', '<LEADER>lf', function() vim.lsp.buf.format { async = true } end, bufopts)
      end

      local lsp_config = require('lspconfig')
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      for _, lsp in ipairs(servers) do
        local opt = {
          on_attach = on_attach,
          capabilities = capabilities,
        }

        if (lsp == "volar")
        then
          opt["filetypes"] = {
            'vue',
            'json',
          }
        end

        if (lsp == "rust_analyzer")
        then
          opt["settings"] = {
            ["rust_analyzer"] = {}
          }
        end

        lsp_config[lsp].setup(opt)
      end

      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      local luasnip = require('luasnip')
      local cmp = require('cmp')
      cmp.setup({
        window = {
          completion = cmp.config.window.bordered({
            col_offset = -5,
          }),
          documentation = cmp.config.window.bordered(),
        },
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          -- C-b (back) C-f (forward) for snippet placeholder navigation.
          ['<C-\\>'] = cmp.mapping.complete(),
          ['<C-u>'] = cmp.mapping.scroll_docs(-4), -- Up
          ['<C-d>'] = cmp.mapping.scroll_docs(4),  -- Down
          ['<CR>'] = cmp.mapping.confirm {
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          },
          ['<C-n>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            elseif has_words_before() then
              cmp.complete()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<C-p>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<C-e>'] = cmp.mapping.abort(),
        }),
        sources = {
          { name = 'nvim_lsp' },
          { name = 'luasnip', option = { show_autosnippets = true } },
        },
        view = {
          entries = "custom", -- can be "custom", "wildmenu" or "native"
          selection_order = "near_cursor",
        },
        formatting = {
          format = function(entry, vim_item)
            -- Source
            vim_item.menu = ({
              buffer = "[Buffer]",
              nvim_lsp = "[LSP]",
              luasnip = "[LuaSnip]",
              nvim_lua = "[Lua]",
              latex_symbols = "[LaTeX]",
            })[entry.source.name]
            return vim_item
          end
        },
      })
    end,
  },
  "saadparwaiz1/cmp_luasnip",
  {
    "jose-elias-alvarez/null-ls.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local null_ls = require("null-ls")
      local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

      null_ls.setup({
        sources = {
          null_ls.builtins.formatting.stylua,
          null_ls.builtins.diagnostics.eslint,
          null_ls.builtins.code_actions.eslint,
          null_ls.builtins.completion.spell,
        },
        on_attach = function(client, bufnr)
          if client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = augroup,
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format({ bufnr = bufnr })
              end,
            })
          end
          vim.keymap.set('n', '<LEADER>lq', function() vim.lsp.buf.format { async = true } end, bufopts)
        end,
      })
    end
  },
  {
    "windwp/nvim-autopairs",
    config = function()
      require('nvim-autopairs').setup({
        disable_filetype = { "TelescopePrompt", "vim" },
      })
      -- If you want insert `(` after select function or method item
      local cmp_autopairs = require('nvim-autopairs.completion.cmp')
      local cmp = require('cmp')
      cmp.event:on(
        'confirm_done',
        cmp_autopairs.on_confirm_done()
      )
    end
  },
  {
    "kdheepak/lazygit.nvim",
    config = function()
      vim.keymap.set('n', '<C-g>', function() vim.cmd("LazyGit") end, { noremap = true, silent = true })
      vim.g.lazygit_floating_window_winblend = 0                          -- transparency of floating window
      vim.g.lazygit_floating_window_scaling_factor = 0.86                 -- scaling factor for floating window
      vim.g.lazygit_floating_window_corner_chars = { '╭', '╮', '╰', '╯' } -- customize lazygit popup window corner characters
      vim.g.lazygit_use_neovim_remote = 1                                 -- for neovim-remote support
    end
  },
  {
    "numToStr/Comment.nvim",
    config = function()
      require('Comment').setup({
        ---Add a space b/w comment and the line
        padding = true,
        ---Whether the cursor should stay at its position
        sticky = true,
        ---Lines to be ignored while (un)comment
        ignore = nil,
        ---LHS of toggle mappings in NORMAL mode
        toggler = {
          ---Line-comment toggle keymap
          line = '<LEADER>cc',
          ---Block-comment toggle keymap
          block = '<LEADER>bc',
        },
        ---LHS of operator-pending mappings in NORMAL and VISUAL mode
        opleader = {
          ---Line-comment keymap
          line = '<LEADER>c',
          ---Block-comment keymap
          block = '<LEADER>b',
        },
        ---LHS of extra mappings
        extra = {
          ---Add comment on the line above
          above = '<LEADER>cO',
          ---Add comment on the line below
          below = '<LEADER>co',
          ---Add comment at the end of line
          eol = '<LEADER>cA',
        },
        ---Enable keybindings
        ---NOTE: If given `false` then the plugin won't create any mappings
        mappings = {
          ---Operator-pending mapping; `gcc` `gbc` `gc[count]{motion}` `gb[count]{motion}`
          basic = true,
          ---Extra mapping; `gco`, `gcO`, `gcA`
          extra = true,
        },
        ---Function to call before (un)comment
        pre_hook = nil,
        ---Function to call after (un)comment
        post_hook = nil,
      })
    end
  },
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1

      -- set termguicolors to enable highlight groups
      vim.opt.termguicolors = true

      -- OR setup with some options
      require("nvim-tree").setup({
        sort_by = "case_sensitive",
        view = {
          width = 30,
          mappings = {
            list = {
              { key = "u",     action = "" },
              { key = "e",     action = "" },
              { key = "n",     action = "" },
              { key = "i",     action = "" },
              { key = "U",     action = "" },
              { key = "E",     action = "" },
              { key = "<C-y>", action = "collapse_all" },
              { key = "<C-e>", action = "expand_all" },
            },
          },
        },
        renderer = {
          group_empty = true,
        },
        filters = {
          dotfiles = true,
        },
      })

      vim.keymap.set('n', 'tc', function() vim.cmd("NvimTreeCollapse") end)
      vim.keymap.set('n', 'tf', function() vim.cmd("NvimTreeFindFileToggle") end)
      vim.keymap.set('n', 'to', function() vim.cmd("NvimTreeFocus") end)
      vim.keymap.set('n', 'tt', function() vim.cmd("NvimTreeToggle") end)
      vim.keymap.set('n', 'tr', function() vim.cmd("NvimTreeRefresh") end)
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      local gitsigns = require('gitsigns')

      local on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map('n', ']c', function()
          if vim.wo.diff then return ']c' end
          vim.schedule(function() gs.next_hunk() end)
          return '<Ignore>'
        end, { expr = true })

        map('n', '[c', function()
          if vim.wo.diff then return '[c' end
          vim.schedule(function() gs.prev_hunk() end)
          return '<Ignore>'
        end, { expr = true })

        -- Actions
        map('n', '<leader>hd', gs.diffthis)
        map('n', '<leader>hD', function() gs.diffthis('~') end)
        map({ 'n', 'v' }, '<leader>hb', gs.toggle_current_line_blame)
        map('n', '<leader>hp', gs.preview_hunk)
      end

      gitsigns.setup({
        signs                        = {
          add          = { text = '│' },
          change       = { text = '│' },
          delete       = { text = '_' },
          topdelete    = { text = '‾' },
          changedelete = { text = '~' },
          untracked    = { text = '┆' },
        },
        signcolumn                   = true,  -- Toggle with `:Gitsigns toggle_signs`
        numhl                        = false, -- Toggle with `:Gitsigns toggle_numhl`
        linehl                       = false, -- Toggle with `:Gitsigns toggle_linehl`
        word_diff                    = false, -- Toggle with `:Gitsigns toggle_word_diff`
        watch_gitdir                 = {
          interval = 1000,
          follow_files = true
        },
        attach_to_untracked          = true,
        current_line_blame           = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
        current_line_blame_opts      = {
          virt_text = true,
          virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
          delay = 500,
          ignore_whitespace = false,
        },
        current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
        sign_priority                = 6,
        update_debounce              = 100,
        status_formatter             = nil,   -- Use default
        max_file_length              = 40000, -- Disable if file is longer than this (in lines)
        preview_config               = {
          -- Options passed to nvim_open_win
          border = 'single',
          style = 'minimal',
          relative = 'cursor',
          row = 0,
          col = 1
        },
        yadm                         = {
          enable = false
        },
        on_attach                    = on_attach,
      })
    end
  },
  {
    "folke/tokyonight.nvim",
    lazy = false,    -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      -- load the colorscheme here
      vim.cmd([[colorscheme tokyonight]])
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require('nvim-treesitter.configs').setup({
        -- A list of parser names, or "all" (the four listed parsers should always be installed)
        ensure_installed = { "bash", "c", "css", "dockerfile", "gitignore", "help", "html", "javascript", "json", "lua",
          "rust", "sql", "toml", "tsx", "typescript", "vim", "vue", "yaml" },
        -- Install parsers synchronously (only applied to `ensure_installed`)
        sync_install = false,
        -- Automatically install missing parsers when entering buffer
        -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
        auto_install = true,
        -- List of parsers to ignore installing (for "all")
        -- ignore_install = { "" },

        ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
        -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

        highlight = {
          enable = true,
          -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
          -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
          -- the name of the parser)
          -- list of language that will be disabled
          -- disable = { "c", "rust" },
          -- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files
          disable = function(lang, buf)
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
              return true
            end
          end,
          -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
          -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
          -- Using this option may slow down your editor, and you may see some duplicate highlights.
          -- Instead of true it can also be a list of languages
          additional_vim_regex_highlighting = false,
        },
        autotag = {
          enable = true,
          filetypes = { "html", "xml" },
        }
      })
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      require('lualine').setup({
        options = {
          icons_enabled = true,
          theme = 'auto',
          section_separators = { left = '', right = '' },
          component_separators = { left = '', right = '' },
          disabled_filetypes = {
            statusline = {},
            winbar = {},
          },
          ignore_focus = {},
          always_divide_middle = true,
          globalstatus = false,
          refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
          }
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { 'filename' },
          lualine_x = { 'encoding', 'fileformat', 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' }
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { 'filename' },
          lualine_x = { 'location' },
          lualine_y = {},
          lualine_z = {}
        },
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = {}
      })
    end,
  },
  {
    "stevearc/aerial.nvim",
    config = function()
      require('aerial').setup({
        -- You probably also want to set a keymap to toggle aerial
        -- optionally use on_attach to set keymaps when aerial has attached to a buffer
        on_attach = function(bufnr)
          -- Jump forwards/backwards with '{' and '}'
          vim.keymap.set('n', '{', '<cmd>AerialPrev<CR>', { buffer = bufnr })
          vim.keymap.set('n', '}', '<cmd>AerialNext<CR>', { buffer = bufnr })
        end
      })
      vim.keymap.set('n', 'ta', '<cmd>AerialToggle!<CR>')
    end,
  },
})

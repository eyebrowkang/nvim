return {
  -- auto completion and snippets
  "hrsh7th/nvim-cmp",
  "hrsh7th/cmp-nvim-lsp",
  "saadparwaiz1/cmp_luasnip",
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

      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      local lsp_config = require('lspconfig')
      local servers = require("../lsp-servers")

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
}

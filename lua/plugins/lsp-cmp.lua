return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Use LspAttach autocommand to only map the following keys
      -- after the language server attaches to the current buffer
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('UserLspConfig', {}),
        callback = function(ev)
          -- Buffer local mappings.
          -- See `:help vim.lsp.*` for documentation on any of the below functions
          local opts = { buffer = ev.buf }
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
          -- vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', '<C-k>', vim.lsp.buf.hover, opts)
          -- vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
          -- vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
          vim.keymap.set('n', '<LEADER>wa', vim.lsp.buf.add_workspace_folder, opts)
          vim.keymap.set('n', '<LEADER>wr', vim.lsp.buf.remove_workspace_folder, opts)
          vim.keymap.set('n', '<LEADER>wl', function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end, opts)
          -- vim.keymap.set('n', '<LEADER>qD', vim.lsp.buf.type_definition, opts)
          -- vim.keymap.set('n', '<LEADER>rn', vim.lsp.buf.rename, opts)
          -- vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)

          vim.keymap.set({ 'n', 'v' }, '<LEADER>qa', vim.lsp.buf.code_action, opts)
          vim.keymap.set('n', '<LEADER>qm', function()
            vim.lsp.buf.format()
          end, opts)
        end,
      })
    end
  },
  "hrsh7th/cmp-nvim-lsp",
  'hrsh7th/cmp-buffer',
  'hrsh7th/cmp-path',
  'hrsh7th/cmp-cmdline',
  {
    "L3MON4D3/LuaSnip",
    version = "1.2.*",
    build = "make install_jsregexp",
    config = function(_, opts)
      if opts then require("luasnip").config.setup(opts) end
      vim.tbl_map(function(type) require("luasnip.loaders.from_" .. type).lazy_load() end,
        { "vscode", "snipmate", "lua" })
    end
  },
  "saadparwaiz1/cmp_luasnip",
  {
    "hrsh7th/nvim-cmp",
    config = function()
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
          ['<C-\\>'] = cmp.mapping.complete(),
          ['<C-u>'] = cmp.mapping.scroll_docs(-4),
          ['<C-d>'] = cmp.mapping.scroll_docs(4),
          ['<CR>'] = cmp.mapping.confirm {
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          },
          ['<C-n>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
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
          {
            name = 'luasnip',
            option = {
              show_autosnippets = false,
              use_show_condition = false
            }
          },
          { name = 'buffer' },
          { name = 'path' },
        },
        view = {
          entries = "custom",
          selection_order = "near_cursor",
        },
        formatting = {
          format = function(entry, vim_item)
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

      cmp.setup.cmdline('/', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'buffer' }
        }
      })

      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'path' }
        }, {
          {
            name = 'cmdline',
            option = {
              ignore_cmds = { 'Man', '!' }
            }
          }
        })
      })

      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      local lsp_config = require('lspconfig')
      local servers = require("../lsp-servers")

      local auto_format = function(client, bufnr)
        if client.supports_method("textDocument/formatting") then
          vim.api.nvim_clear_autocmds({ group = "LspFormatting", buffer = bufnr })
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({ bufnr = bufnr })
            end,
          })
        end
      end

      for _, lsp in ipairs(servers) do
        local opt = {
          capabilities = capabilities,
        }

        if (lsp == "volar")
        then
          opt["filetypes"] = {
            'vue',
          }
          opt["init_options"] = {
            typescript = {
              tsdk = os.getenv("HOME") .. "/.volta/tools/shared/typescript/lib",
            },
          }
        end

        if (lsp == "rust_analyzer")
        then
          opt["settings"] = {
            ["rust_analyzer"] = {}
          }
        end

        if (lsp == "eslint")
        then
          opt["on_attach"] = function(client, bufnr)
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = bufnr,
              command = "EslintFixAll",
            })
          end
        end

        if (lsp == "lua_ls")
        then
          opt["settings"] = {
            Lua = {
              format = {
                enable = true,
                -- Put format options here
                -- NOTE: the value should be STRING!!
                defaultConfig = {
                  indent_style = "space",
                  indent_size = "2",
                }
              },
            }
          }
          opt["on_attach"] = function(client, bufnr)
            auto_format(client, bufnr)
          end
        end

        if (lsp == "taplo")
        then
          opt["on_attach"] = function(client, bufnr)
            auto_format(client, bufnr)
          end
        end

        lsp_config[lsp].setup(opt)
      end
    end,
  },
}

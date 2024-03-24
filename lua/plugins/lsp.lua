return {

    -- load before lspconfig
    -- cmdline tools and lsp servers
    {

        "williamboman/mason.nvim",
        cmd = "Mason",
        build = ":MasonUpdate",
        opts = {
            max_concurrent_installers = 8,
            log_level = vim.log.levels.WARN,
            ui = {
                check_outdated_packages_on_open = false,
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
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "folke/neodev.nvim",
            "stevearc/conform.nvim",
        },
        opts = {
            -- options for vim.diagnostic.config()
            diagnostics = {
                underline = true,
                update_in_insert = false,
                severity_sort = true,
                float = { border = 'double' },
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = require("config.icons").diagnostics.Error,
                        [vim.diagnostic.severity.WARN] = require("config.icons").diagnostics.Warn,
                        [vim.diagnostic.severity.HINT] = require("config.icons").diagnostics.Hint,
                        [vim.diagnostic.severity.INFO] = require("config.icons").diagnostics.Info,
                    },
                },
            },

            -- lsp servers
            servers = {
                lua_ls = {
                    settings = {
                        Lua = {
                            format = {
                                enable = false,
                            },
                            hint = {
                                enable = true,
                                arrayIndex = "Disable", -- "Enable", "Auto", "Disable"
                                await = true,
                                paramName = "All", -- "All", "Literal", "Disable"
                                paramType = true,
                                semicolon = "Disable", -- "All", "SameLine", "Disable"
                                setType = true,
                            },
                            workspace = {
                                checkThirdParty = false,
                            },
                            codeLens = {
                                enable = true,
                            },
                            completion = {
                                callSnippet = "Replace",
                            },
                        },
                    },
                },
                jsonls = {
                    settings = {
                        json = {
                            validate = { enable = true },
                        },
                    },
                },
                marksman = {},
                html = {},
                cssls = {},
                tsserver = {},
                eslint = {
                    on_attach = function(_, bufnr)
                        vim.api.nvim_create_autocmd("BufWritePre", {
                            buffer = bufnr,
                            command = "EslintFixAll",
                        })
                    end,
                },
                volar = {},
                tailwindcss = {},
                gopls = {},
                rust_analyzer = {},
            },
        },
        config = function(_, opts)
            -- require("config.debug").simpleLog("lspconfig load")
            -- :h nvim_create_autocmd
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup('UserLspConfig', {}),
                callback = function(args)
                    local buffer = args.buf
                    local client = vim.lsp.get_client_by_id(args.data.client_id)

                    -- Enable completion triggered by <c-x><c-o>
                    vim.bo[buffer].omnifunc = 'v:lua.vim.lsp.omnifunc'
                    vim.keymap.set('n', 'U', vim.lsp.buf.hover, { noremap = true, desc = "Hover", buffer = buffer })
                    vim.keymap.set('n', 'gd', function() require("telescope.builtin").lsp_definitions({ reuse_win = true }) end, { desc = "Goto Definition", buffer = buffer })
                    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { desc = "Goto Declaration", buffer = buffer })
                    vim.keymap.set('n', '<leader>ch', vim.lsp.buf.signature_help, { desc = "Signature Help", buffer = buffer })
                    vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, { desc = "Code Action", buffer = buffer })
                    -- vim.keymap.set('n', '<leader>cf', function() vim.lsp.buf.format { async = true } end, { desc = "Code Format", buffer = buffer })
                    vim.keymap.set('n', '<leader>cf', function() require("conform").format({ bufnr = buffer }) end, { desc = "Code Format", buffer = buffer })

                end,
            })

            -- diagnostics
            for name, icon in pairs(require("config.icons").diagnostics) do
                name = "DiagnosticSign" .. name
                vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
            end

            vim.diagnostic.config(opts.diagnostics)

            -- mason-lspconfig
            require("mason-lspconfig").setup {
                ensure_installed = {
                    "lua_ls",
                    "jsonls",
                    "marksman",
                    "html",
                    "cssls",
                    "tsserver",
                    "eslint"
                },
            }


            -- for nvim development
            require("neodev").setup({
                library = { plugins = { "nvim-dap-ui" }, types = true },
            })

            local capabilities = require('cmp_nvim_lsp').default_capabilities()

            -- lspconfig servers
            local lspconfig = require('lspconfig')
            for key, value in pairs(opts.servers) do
                value.capabilities = capabilities
                lspconfig[key].setup(value)
            end
        end,
    },

    -- rename
    {
        "smjonas/inc-rename.nvim",
        dependencies = "neovim/nvim-lspconfig",
        cmd = "IncRename",
        keys = {
            { "<leader>rn", function() return ":IncRename " .. vim.fn.expand("<cword>") end, expr = true, desc = "Rename variable" },
        },
        config = true,
    },

    -- lsp server related
    {
        "b0o/schemastore.nvim",
        dependencies = {
            "neovim/nvim-lspconfig",
            opts = function(_, opts)
                table.insert(opts.servers.jsonls.settings.json, { schemas = require('schemastore').json.schemas() })
            end,
        },
        event = "VeryLazy",
    }
}

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
        -- event = "LazyFile",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            { "folke/neodev.nvim", opts = {} },
            -- lsp related
            -- jsonls
            "b0o/schemastore.nvim",
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
        },
        config = function(_, opts)
            -- diagnostics
            for name, icon in pairs(require("config.icons").diagnostics) do
                name = "DiagnosticSign" .. name
                vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
            end

            vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

            -- mason-lspconfig
            require("mason-lspconfig").setup {
                ensure_installed = {
                    "lua_ls",
                    "html",
                    "cssls",
                    "tsserver",
                    "jsonls",
                },
            }

            -- lspconfig servers
            local lspconfig = require('lspconfig')
            require("neodev").setup {}
            lspconfig.lua_ls.setup {
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
                    },
                },
            }
            lspconfig.html.setup {}
            lspconfig.cssls.setup {}
            lspconfig.tsserver.setup {}
            lspconfig.jsonls.setup {
                settings = {
                    json = {
                        schemas = require('schemastore').json.schemas(),
                        validate = { enable = true },
                    },
                },
            }
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
}

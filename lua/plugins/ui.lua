local icons = {
    diagnostics = {
        Error = " ",
        Warn  = " ",
        Hint  = " ",
        Info  = " ",
    },
    git = {
        added    = " ",
        modified = " ",
        removed  = " ",
    },
}

local function nofile()
    return #vim.fn.argv() ~= 0 or #vim.fn.getbufinfo({buflisted = 1}) ~= 1
end

return {
    {
        'akinsho/bufferline.nvim',
        version = "*",
        dependencies = 'nvim-tree/nvim-web-devicons',
        event = "VeryLazy",
        enabled = nofile(),
        opts = {
            options = {
                diagnostics = "nvim_lsp",
                mode = "tabs",
                separator_style = "slant",
            }
        },
        config = function(_, opts)
            require("bufferline").setup(opts)
        end
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = {
            'folke/tokyonight.nvim',
            'nvim-tree/nvim-web-devicons'
        },
        event = "VeryLazy",
        enabled = function()
            return nofile()
        end,
        opts = function()

            vim.o.laststatus = vim.g.lualine_laststatus

            return {
                options = {
                    theme = 'tokyonight',
                    globalstatus = true,
                    disabled_filetypes = {
                        statusline = { "lazy", "mason", "neo-tree" },
                    },
                },
                sections = {
                    lualine_a = {
                        { 'branch', separator = { left = '' } },
                    },
                    lualine_b = {},
                    lualine_z = {
                        { 'location', separator = { right = '' } },
                    },
                },
                extensions = { "lazy" },
            }
        end,
    }
}

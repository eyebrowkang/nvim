local function nofile()
    return #vim.fn.argv() ~= 0 or #vim.fn.getbufinfo({buflisted = 1}) ~= 1
end

return {
    {
        'akinsho/bufferline.nvim',
        version = "*",
        dependencies = 'nvim-tree/nvim-web-devicons',
        event = "VeryLazy",
        cond = nofile(),
        opts = {
            options = {
                mode = "tabs",
                separator_style = "slant",
                always_show_bufferline = false,
                diagnostics = "nvim_lsp",
                diagnostics_indicator = function(_, _, diag)
                    local icons = require("config.icons").diagnostics
                    local ret = (diag.error and icons.Error .. diag.error .. " " or "")
                    .. (diag.warning and icons.Warn .. diag.warning or "")
                    return vim.trim(ret)
                end,
                --[[ offsets = {
                    {
                        filetype = "neo-tree",
                        text = "Neo-tree",
                        highlight = "Directory",
                        text_align = "left",
                    },
                }, ]]
            },
        },
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = {
            'folke/tokyonight.nvim',
            'nvim-tree/nvim-web-devicons'
        },
        event = "VeryLazy",
        cond = function()
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
                        { 'mode', separator = { left = '' } }
                    },
                    lualine_b = { 'branch' },
                    lualine_z = {
                        { 'location', separator = { right = '' } },
                    },
                },
                extensions = { "lazy" },
            }
        end,
    }
}

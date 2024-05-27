local function nofile()
    return #vim.fn.argv() ~= 0 or #vim.fn.getbufinfo({buflisted = 1}) ~= 1
end

return {
    {
        'akinsho/bufferline.nvim',
        -- version = "*",
        dependencies = 'nvim-tree/nvim-web-devicons',
        event = "VeryLazy",
        cond = nofile(),
        keys = {
            { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle pin" },
            { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete non-pinned buffers" },
            { "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>", desc = "Delete other buffers" },
            { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete buffers to the right" },
            { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete buffers to the left" },
            { "[b", "<Cmd>BufferLineCyclePrev<CR>", desc = "Prev buffer" },
            { "]b", "<Cmd>BufferLineCycleNext<CR>", desc = "Next buffer" },
        },
        opts = {
            options = {
                -- mode = "tabs",
                separator_style = "slant",
                -- always_show_bufferline = false,
                diagnostics = "nvim_lsp",
                diagnostics_indicator = function(_, _, diagnostics_dict)
                    local icons = require("config.icons").diagnostics
                    local ret = (diagnostics_dict.error and icons.Error .. diagnostics_dict.error .. " " or "")
                    .. (diagnostics_dict.warning and icons.Warn .. diagnostics_dict.warning or "")
                    return vim.trim(ret)
                end,
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
        init = function()
            vim.g.lualine_laststatus = vim.o.laststatus
            if vim.fn.argc(-1) > 0 then
                -- set an empty statusline till lualine loads
                vim.o.statusline = " "
            else
                -- hide the statusline on the starter page
                vim.o.laststatus = 0
            end
        end,
        opts = function()
            vim.o.laststatus = vim.g.lualine_laststatus

            local icons = require("config.icons")

            return {
                options = {
                    theme = 'tokyonight',
                    globalstatus = true,
                    disabled_filetypes = {
                        statusline = { "lazy", "mason", "neo-tree" },
                    },
                },
                sections = {
                    lualine_a = { 'mode' },
                    lualine_b = {
                        'branch',
                        'filename',
                    },
                    lualine_c = {
                        {
                            "diagnostics",
                            symbols = {
                                error = icons.diagnostics.Error,
                                warn = icons.diagnostics.Warn,
                                info = icons.diagnostics.Info,
                                hint = icons.diagnostics.Hint,
                            },
                        },
                    },
                    lualine_x = {
                        {
                            "diff",
                            symbols = {
                                added = icons.git.added,
                                modified = icons.git.modified,
                                removed = icons.git.removed,
                            },
                            source = function()
                                local gitsigns = vim.b.gitsigns_status_dict
                                if gitsigns then
                                    return {
                                        added = gitsigns.added,
                                        modified = gitsigns.changed,
                                        removed = gitsigns.removed,
                                    }
                                end
                            end,
                        },
                        'filetype',
                    },
                    lualine_y = { 'progress' },
                    lualine_z = { 'location' },
                },
                extensions = { "neo-tree", "lazy" },
            }
        end,
    },
}

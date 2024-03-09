return {

    -- measure startuptime
    {
        "dstein64/vim-startuptime",
        cmd = "StartupTime",
        config = function()
            vim.g.startuptime_tries = 10
        end,
    },

    -- which-key helps you remember key bindings by showing a popup
    -- with the active keybindings of the command you started typing.
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            plugins = { spelling = true },
            defaults = {
                mode = { "n", "v" },
                ["g"] = { name = "+goto" },
                -- ["gs"] = { name = "+surround" },
                ["]"] = { name = "+next" },
                ["["] = { name = "+prev" },
                -- ["<leader><tab>"] = { name = "+tabs" },
                ["<leader>b"] = { name = "+buffer" },
                -- ["<leader>c"] = { name = "+code" },
                ["<leader>e"] = { name = "+explorer" },
                ["<leader>f"] = { name = "+find/search" },
                ["<leader>g"] = { name = "+git" },
                ["<leader>gh"] = { name = "+hunks" },
                ["<leader>p"] = { name = "+paste" },
                -- ["<leader>q"] = { name = "+quit/session" },
                -- ["<leader>s"] = { name = "+search" },
                ["<leader>t"] = { name = "+terminal" },
                -- ["<leader>u"] = { name = "+ui" },
                -- ["<leader>w"] = { name = "+windows" },
                -- ["<leader>x"] = { name = "+diagnostics/quickfix" },
            },
        },
        config = function(_, opts)
            local wk = require("which-key")
            wk.setup(opts)
            wk.register(opts.defaults)
        end,
    },
}

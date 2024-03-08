return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        dependencies = { 'windwp/nvim-ts-autotag' },
        cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
        opts = {
            ensure_installed = { "c", "lua", "vim", "vimdoc", "javascript", "html", "css" },
            sync_install = false,
            autotag = { enable = true },
            highlight = { enable = true },
            indent = { enable = true },
        },
        config = function (_, opts)
            require("nvim-treesitter.configs").setup(opts)
        end
    },
}


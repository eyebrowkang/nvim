return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        dependencies = {
            "windwp/nvim-ts-autotag",
            {
                "nvim-treesitter/nvim-treesitter-textobjects",
            },
        },
        cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
        opts = {
            ensure_installed = { "c", "lua", "vim", "vimdoc", "javascript", "html", "css" },
            sync_install = false,
            autotag = { enable = true },
            highlight = {
                enable = true,
                disable = function(_, buf)
                    local max_filesize = 10 * 1024 * 1024 -- 10 MB
                    local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
                    if ok and stats and stats.size > max_filesize then
                        return true
                    end
                end,
            },
            indent = { enable = true },
        },
        config = function (_, opts)
            require("nvim-treesitter.configs").setup(opts)
        end
    },
}


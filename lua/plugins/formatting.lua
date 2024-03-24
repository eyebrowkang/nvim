return {
    {
        --[[ auto format on save
        vim.api.nvim_create_autocmd("BufWritePre", {
            pattern = "*",
            callback = function(args)
                require("conform").format({ bufnr = args.buf })
            end,
        })]]
        "stevearc/conform.nvim",
        dependencies = { "mason.nvim" },
        lazy = true,
        cmd = "ConformInfo",
        keys = {
            {
                "<leader>cF",
                function()
                    require("conform").format({ formatters = { "injected" } })
                end,
                mode = { "n", "v" },
                desc = "Format Injected Langs",
            },
        },
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
                sh = { "shfmt" },
                markdown = { "markdownlint" },
                -- >> prettier <<
                json = { "prettier" },
                javascript = { "prettier" },
                javascriptreact = { "prettier" },
                ['javascript.jsx'] = { "prettier" },
                typescript = { "prettier" },
                typescriptreact = { "prettier" },
                ['typescript.tsx'] = { "prettier" },
                vue = { "prettier" },
                svelte = { "prettier" },
                astro = { "prettier" },
                -- >> end <<
                go = { "gofmt" },
                rust = { "rustfmt" },
                -- Use the "*" filetype to run formatters on all filetypes.
                ["*"] = { "codespell" },
            },
            format = {
                timeout_ms = 3000,
                async = false, -- not recommended to change
                quiet = false, -- not recommended to change
                lsp_fallback = true, -- not recommended to change
            },
        },
    },
}

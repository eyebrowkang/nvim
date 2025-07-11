return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    lazy = false,
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "lua", "vim", "vimdoc", "markdown", "markdown_inline" },
      sync_install = false,
      auto_install = true,

      highlight = {
        enable = true,

        -- 针对大于10MB的文件，禁用treesitter
        disable = function(_, buf)
          local max_filesize = 10 * 1024 * 1024 -- 10 MB
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            return true
          end
        end,
      },

      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "gnn", -- set to `false` to disable one of the mappings
          node_incremental = "grn",
          scope_incremental = "grc",
          node_decremental = "grm",
        },
      },

      indent = { enable = true },
    },
    config = function(_, opts)
      -- 加速nvim-ts-context-commentstring插件的加载
      vim.g.skip_ts_context_commentstring_module = true
      -- Tree-sitter based folding
      vim.wo.foldmethod = "expr"
      vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

      require("nvim-treesitter.configs").setup(opts)
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
  },
}

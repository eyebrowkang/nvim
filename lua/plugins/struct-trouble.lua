return {
  'folke/trouble.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    require("trouble").setup({})
    vim.keymap.set("n", "<leader>qt", "<cmd>TroubleToggle<cr>",
      { silent = true, noremap = true }
    )
    vim.keymap.set("n", "<leader>qw", "<cmd>TroubleToggle workspace_diagnostics<cr>",
      { silent = true, noremap = true }
    )
    vim.keymap.set("n", "<leader>qd", "<cmd>TroubleToggle document_diagnostics<cr>",
      { silent = true, noremap = true }
    )
    vim.keymap.set("n", "<leader>ql", "<cmd>TroubleToggle loclist<cr>",
      { silent = true, noremap = true }
    )
    vim.keymap.set("n", "<leader>qf", "<cmd>TroubleToggle quickfix<cr>",
      { silent = true, noremap = true }
    )
    vim.keymap.set("n", "<leader>qr", "<cmd>TroubleToggle lsp_references<cr>",
      { silent = true, noremap = true }
    )
    vim.keymap.set("n", "<leader>qD", "<cmd>TroubleToggle lsp_type_definitions<cr>",
      { silent = true, noremap = true }
    )
    vim.keymap.set("n", "<leader>qi", "<cmd>TroubleToggle lsp_implementations<cr>",
      { silent = true, noremap = true }
    )
    vim.keymap.set("n", "<leader>qo", "<cmd>TroubleToggle todo<cr>",
      { silent = true, noremap = true }
    )
    vim.keymap.set("n", "gd", "<cmd>TroubleToggle lsp_definitions<cr>",
      { silent = true, noremap = true }
    )
  end,
}

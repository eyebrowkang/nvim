return {
  'folke/trouble.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    require("trouble").setup({})
    vim.keymap.set("n", "<leader>xx", "<cmd>TroubleToggle<cr>",
      { silent = true, noremap = true }
    )
    vim.keymap.set("n", "<leader>xd", "<cmd>TroubleToggle workspace_diagnostics<cr>",
      { silent = true, noremap = true }
    )
    vim.keymap.set("n", "<leader>xc", "<cmd>TroubleToggle document_diagnostics<cr>",
      { silent = true, noremap = true }
    )
    vim.keymap.set("n", "<leader>xl", "<cmd>TroubleToggle loclist<cr>",
      { silent = true, noremap = true }
    )
    vim.keymap.set("n", "<leader>xf", "<cmd>TroubleToggle quickfix<cr>",
      { silent = true, noremap = true }
    )
    vim.keymap.set("n", "gR", "<cmd>TroubleToggle lsp_references<cr>",
      { silent = true, noremap = true }
    )
  end,
}

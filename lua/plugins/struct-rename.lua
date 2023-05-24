return {
  "smjonas/inc-rename.nvim",
  config = function()
    vim.keymap.set("n", "<leader>rn", ":IncRename ")
    require("inc_rename").setup()
  end,
}

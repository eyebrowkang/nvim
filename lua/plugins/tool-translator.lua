return {
  "voldikss/vim-translator",
  config = function()
    vim.keymap.set('', 'tr', function() vim.cmd("Translate") end)
    vim.keymap.set('', 'tw', function() vim.cmd("TranslateW") end)
  end
}

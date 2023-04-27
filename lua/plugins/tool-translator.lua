return {
  "voldikss/vim-translator",
  config = function()
    vim.keymap.set('', 'ts', function() vim.cmd("Translate") end)
    vim.keymap.set('', 'tw', function() vim.cmd("TranslateW") end)
  end
}

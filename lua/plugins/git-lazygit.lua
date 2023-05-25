return {
  "kdheepak/lazygit.nvim",
  config = function()
    vim.keymap.set('n', '<C-g>', function() vim.cmd("LazyGit") end, { noremap = true, silent = true })

    vim.g.lazygit_floating_window_winblend = 0                          -- transparency of floating window
    vim.g.lazygit_floating_window_scaling_factor = 0.86                 -- scaling factor for floating window
    vim.g.lazygit_floating_window_corner_chars = { '╭', '╮', '╰', '╯' } -- customize lazygit popup window corner characters
    vim.g.lazygit_use_neovim_remote = 1                                 -- for neovim-remote support
  end
}

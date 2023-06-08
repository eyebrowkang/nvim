return {
  "ibhagwan/fzf-lua",
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local builtin = require('fzf-lua')
    builtin.setup({
      winopts = {
        height = 0.68,
        width = 0.86,
      },
      keymap = {
        builtin = {
          ["<C-y>"] = "preview-page-up",
          ["<C-e>"] = "preview-page-down",
        },
      },
    })
    vim.keymap.set('n', '<LEADER>fl', function() vim.cmd("FzfLua") end)
    vim.keymap.set('n', '<LEADER>ff', builtin.files, {})
    vim.keymap.set('n', '<LEADER>fg', builtin.live_grep_glob, {})
    vim.keymap.set('n', '<LEADER>fb', builtin.buffers, {})
    vim.keymap.set('n', '<LEADER>fh', builtin.help_tags, {})
    vim.keymap.set('n', '<LEADER>fp', builtin.lsp_finder, {})
    vim.keymap.set('n', '<LEADER>fs', builtin.git_status, {})
  end,
}

vim.cmd("filetype on")
vim.cmd("filetype indent on")
vim.cmd("filetype plugin on")
vim.cmd("filetype plugin indent on")

vim.o.number = true
vim.o.relativenumber = true
vim.o.numberwidth = 4
vim.o.ruler = true
vim.o.cursorline = true
vim.o.cursorcolumn = true
vim.o.wrap = true

vim.o.shiftwidth = 2
vim.o.shiftround = true
vim.o.expandtab = true
vim.o.tabstop = 2
vim.o.softtabstop = 2
vim.o.list = true
vim.o.scrolloff = 5

vim.o.backspace = 'indent,eol,start'
vim.o.foldmethod = 'indent'
vim.o.foldlevel = 99

vim.o.splitbelow = true
vim.o.splitright = true

vim.o.showmatch = true
vim.o.matchtime = 2

vim.cmd("syntax enable")

vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.laststatus = 2
vim.o.statusline = "%f %m%r %y - %l/%L %p%%"

vim.o.wildignore = "log/**,node_modules/**,target/**,tmp/**,*.rbc"
vim.o.listchars = "tab:▸ ,trail:▫"

-- vim.g.colors_name = "slate"

-- basic keymaps
local nv_mode = { 'n', 'v' };
local nvo_mode = { 'n', 'v', 'o' };
local ns_opts = { noremap = true, silent = true };

vim.keymap.set(nvo_mode, 'n', 'h', ns_opts)
vim.keymap.set(nvo_mode, 'u', 'k', ns_opts)
vim.keymap.set(nvo_mode, 'e', 'j', ns_opts)
vim.keymap.set(nvo_mode, 'i', 'l', ns_opts)
vim.keymap.set(nvo_mode, 'N', '^', ns_opts)
vim.keymap.set(nvo_mode, 'I', 'g_', ns_opts)
vim.keymap.set(nvo_mode, 'h', 'nzz', ns_opts)
vim.keymap.set(nvo_mode, 'j', 'e', ns_opts)
vim.keymap.set(nvo_mode, 'k', 'i', ns_opts)
vim.keymap.set(nvo_mode, 'l', 'u', ns_opts)
vim.keymap.set(nvo_mode, 'K', 'I', ns_opts)
vim.keymap.set(nvo_mode, 'H', 'Nzz', ns_opts)
vim.keymap.set(nvo_mode, 'U', '5k', ns_opts)
vim.keymap.set(nvo_mode, 'E', '5j', ns_opts)
vim.keymap.set(nvo_mode, 'S', ':w<cr>', ns_opts)
vim.keymap.set(nvo_mode, 'Q', ':q<cr>', ns_opts)
vim.keymap.set('v', 'Y', '"+y', ns_opts)
vim.keymap.set('i', '<C-a>', '<esc>A', ns_opts)
vim.keymap.set('i', '<C-j>', '<esc>viw~ea', ns_opts)
vim.keymap.set('n', '<C-j>', '<esc>viw~e', ns_opts)

vim.g.mapleader = " "

-- neovim config file management
vim.keymap.set('', '<LEADER>ve', function() vim.cmd("vsplit $MYVIMRC") end)
vim.keymap.set('', '<LEADER>vs', function() vim.cmd("source $MYVIMRC") end)

-- window management
vim.keymap.set('', '<LEADER>u', '<C-w>k')
vim.keymap.set('', '<LEADER>e', '<C-w>j')
vim.keymap.set('', '<LEADER>n', '<C-w>h')
vim.keymap.set('', '<LEADER>i', '<C-w>l')
vim.keymap.set(nv_mode, 's', '<nop>')
vim.keymap.set(nv_mode, 'su', function()
  vim.o.splitbelow = false
  vim.cmd("split")
  vim.o.splitbelow = true
end)
vim.keymap.set(nv_mode, 'se', function()
  vim.o.splitbelow = true
  vim.cmd("split")
end)
vim.keymap.set(nv_mode, 'sn', function()
  vim.o.splitright = false
  vim.cmd("vsplit")
  vim.o.splitright = ture
end)
vim.keymap.set(nv_mode, 'si', function()
  vim.o.splitright = ture
  vim.cmd("vsplit")
end)
vim.keymap.set('n', 'sh', '<C-w>t<C-w>K', ns_opts)
vim.keymap.set('n', 'sv', '<C-w>t<C-w>H', ns_opts)
vim.keymap.set('n', 'srh', '<C-w>b<C-w>K', ns_opts)
vim.keymap.set('n', 'srv', '<C-w>b<C-w>H', ns_opts)
vim.keymap.set('', '<up>', function() vim.cmd("res +5") end)
vim.keymap.set('', '<down>', function() vim.cmd("res -5") end)
vim.keymap.set('', '<left>', function() vim.cmd("vertical resize-5") end)
vim.keymap.set('', '<right>', function() vim.cmd("vertical resize+5") end)

-- tab management
vim.keymap.set(nv_mode, 'tu', function() vim.cmd("tabe") end)
vim.keymap.set(nv_mode, 'te', '<C-w>T')
vim.keymap.set(nv_mode, 'tn', function() vim.cmd("-tabnext") end)
vim.keymap.set(nv_mode, 'ti', function() vim.cmd("+tabnext") end)
vim.keymap.set(nv_mode, 'tmn', function() vim.cmd("-tabmove") end)
vim.keymap.set(nv_mode, 'tmi', function() vim.cmd("+tabmove") end)

-- terminal management
-- just use :te, it is easy enough
-- vim.keymap.set('', '<LEADER>t', function() vim.cmd("terminal") end)
-- vim.keymap.set('t', '<esc>', '<C-\\><C-n>')

vim.api.nvim_create_autocmd({ "BufReadPost" }, {
  pattern = "*",
  callback = function()
    local last_cursor_pos, last_line = vim.fn.line([['"]]), vim.fn.line("$")

    if last_cursor_pos > 1 and last_cursor_pos <= last_line then
      vim.fn.cursor(last_cursor_pos, 1)
    end
  end,
})

-- plugins
require('plugins')

" Options: {{{
" <<< Indentation >>>
set autoindent
set expandtab
set smarttab
set shiftround
set shiftwidth=4
set tabstop=4
set softtabstop=4
" <<< Display >>>
set background=dark
set termguicolors
set cursorcolumn
set cursorline
set display=lastline,uhex
set number
set relativenumber
set scrolloff=5
set sidescroll=1
set sidescrolloff=5
" set smoothscroll
set list
set listchars=tab:▸\ ,trail:▫,nbsp:␣,precedes:«,extends:» " eol:⏎
set showcmd
set noshowmode
set showmatch
set matchtime=1
set nowrap
set wildmenu
set wildignore=*.o,*.obj,*.swp,*/node_modules/*
" set laststatus=2
" <<< Search >>>
set hlsearch
set ignorecase
set incsearch
set smartcase
" <<< Others >>>
set autoread
set backspace=indent,eol,start
set encoding=utf-8
set foldlevel=99
set foldmethod=indent
set history=200
set langnoremap
set nolangremap
set mouse=nvi
set ruler
set nostartofline
set ttimeoutlen=100
set exrc
" }}}
" Syntax: {{{
syntax enable
" colorscheme tokyonight
" }}}
" Filetype: {{{
filetype plugin indent on
" }}}
" Keymap: {{{
" Copy to system clipboard
vnoremap Y "+y

" noremap <CR> ciw
inoremap <C-A> <Esc>I
inoremap <C-E> <Esc>A
nnoremap <C-L> :nohlsearch<CR><C-L>

" leave terminal mode quickly
tnoremap <Esc> <C-\><C-N>

let g:mapleader=" "
let g:maplocalleader="\\"

" }}}
" Miscellaneous: {{{
" let &t_ut=''
" <<< Abbreviations >>>
cabbrev hb botright help
cabbrev hr vertical botright help
cabbrev ht tab help

augroup vimStartup
  autocmd!

  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid, when inside an event handler
  " (happens when dropping a file on gvim), for a commit or rebase message
  " (likely a different one than last time), and when using xxd(1) to filter
  " and edit binary files (it transforms input files back and forth, causing
  " them to have dual nature, so to speak)
  autocmd BufReadPost *
    \ let line = line("'\"")
    \ | if line >= 1 && line <= line("$") && &filetype !~# 'commit'
    \      && index(['xxd', 'gitrebase'], &filetype) == -1
    \ |   execute "normal! g`\""
    \ | endif

augroup END
"}}}

let g:loaded_node_provider = 0
let g:loaded_perl_provider = 0
let g:loaded_python3_provider = 0
let g:loaded_ruby_provider = 0

augroup ansible_filetype
  autocmd!
  autocmd BufRead,BufNewFile *.yml,*.yaml call s:set_ansible_filetype()
augroup END

function! s:set_ansible_filetype()
  let filepath = expand('%:p')
  let filename = expand('%:t')
  
  if filepath =~ 'inventory\|playbook\|roles'
    set filetype=yaml.ansible
  endif
endfunction

" 加载插件系统(lazy.nvim)
lua require("config.lazy")


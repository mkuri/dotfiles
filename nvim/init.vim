" Plugins will be downloaded under the specified directory.
call plug#begin('~/.config/nvim/plugged')

Plug 'jacoborus/tender.vim'
Plug '/usr/bin/fzf'
Plug 'junegunn/fzf.vim'
if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif
Plug 'autozimu/LanguageClient-neovim', {
    \ 'branch': 'next',
    \ 'do': 'bash install.sh',
    \ }
Plug 'w0rp/ale'
Plug 'tyru/caw.vim'
" List ends here. Plugins become visible to Vim after this call.
call plug#end()

" General settings
set number
set nobackup
set noswapfile
set clipboard=unnamedplus
let mapleader="\<Space>"

" Color
if (has("termguicolors"))
  set termguicolors
endif
syntax enable
colorscheme tender

" Indent
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab
set smartindent

" Search
set incsearch
nnoremap <ESC><ESC> :nohlsearch<CR>
set ignorecase
set smartcase
set wrapscan

" Keybind
nnoremap <Leader>f :Files<CR>
nnoremap <Leader>b :Buffers<CR>
nnoremap <Leader>; :Commands<CR>

" deoplete
let g:deoplete#enable_at_startup = 1

" language server protocol
let g:LanguageClient_serverCommands = {
  \ 'python': ['pyls'],
  \ }

" python
let g:python_host_prog = '/usr/bin/python2'
let g:python3_host_prog = '/usr/bin/python3'
if exists("$VIRTUAL_ENV")
  if !empty(glob("$VIRTUAL_ENV/bin/python3"))
    let g:python3_host_prog = substitute(system("which python"), '\n', '', 'g')
  else
    let g:python_host_prog = substitute(system("which python"), '\n', '', 'g')
  endif
endif

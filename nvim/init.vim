" Plugins will be downloaded under the specified directory.
call plug#begin('~/.config/nvim/plugged')

Plug 'zacanger/angr.vim'
Plug 'jacoborus/tender.vim'

" List ends here. Plugins become visible to Vim after this call.
call plug#end()

" General settings
set number
set nobackup
set noswapfile
set clipboard=unnamed

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

" Plugins will be downloaded under the specified directory.
call plug#begin('~/.config/nvim/plugged')

Plug 'arcticicestudio/nord-vim'
Plug '/usr/bin/fzf'
Plug 'junegunn/fzf.vim'
Plug 'tyru/caw.vim'
" Plug 'SirVer/ultisnips'
" Plug 'honza/vim-snippets'
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" List ends here. Plugins become visible to Vim after this call.
call plug#end()

" General settings
set hidden
set nobackup
set nowritebackup
set noswapfile
set clipboard=unnamedplus

" Display
set number
" set cmdheight=2
set signcolumn=yes
au VimEnter * highlight clear SignColumn

" Color
if (has("termguicolors"))
  set termguicolors
endif
syntax enable
colorscheme nord

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
let mapleader="\<Space>"
nnoremap <Leader>f :Files<CR>
nnoremap <Leader>b :Buffers<CR>
nnoremap <Leader>h :History<CR>
nnoremap <Leader>; :Commands<CR>

noremap j gj
noremap k gk
noremap gj j
noremap gk k

nmap <silent> [c <Plug>(coc-diagnostic-prev)
nmap <silent> ]c <Plug>(coc-diagnostic-next)
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

nmap <leader>rn <Plug>(coc-rename)

" templates
autocmd BufNewFile requirements.in 0r $HOME/.config/nvim/templates/requirements.in.template

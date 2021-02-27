" Plugins will be downloaded under the specified directory.
call plug#begin('~/.config/nvim/plugged')

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'tyru/caw.vim'
" Plug 'SirVer/ultisnips'
" Plug 'honza/vim-snippets'
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
Plug 'cocopon/iceberg.vim'
Plug 'tpope/vim-fugitive'

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
" if (has("termguicolors"))
"   set termguicolors
" endif
syntax enable
" colorscheme iceberg
" highlight Normal guibg=none
" highlight Nontext guibg=none

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

nnoremap <Leader>gs :Git<CR>
nnoremap <Leader>ga :Gwrite<CR>
nnoremap <Leader>gc :Git commit<CR>
nnoremap <Leader>gb :Gblame<CR>
nnoremap <Leader>gd :Gdiffsplit<CR>

nmap <silent> gd <Plug>(lsp-definition)
nmap <silent> gr <Plug>(lsp-references)
nmap <silent> gi <Plug>(lsp-implementation)
nmap <silent> gt <Plug>(lsp-type-definition)
nmap <silent> gs <Plug>(lsp-document-symbol-search)
nmap <silent> gS <Plug>(lsp-workspace-symbol-search)
nmap <leader>rn <Plug>(lsp-rename)
nmap <silent> [d <Plug>(lsp-previous-diagnostic)
nmap <silent> ]d <Plug>(lsp-next-diagnostic)
nmap <silent> gh <Plug>(lsp-hover)

" templates
autocmd BufNewFile requirements.in 0r $HOME/.config/nvim/templates/requirements.in.template

" fzf
let g:fzf_layout = { 'down': '40%' }

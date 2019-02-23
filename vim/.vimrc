" Plugins will be downloaded under the specified directory.
call plug#begin('~/.config/nvim/plugged')

Plug 'jacoborus/tender.vim'
Plug '/usr/bin/fzf'
Plug 'junegunn/fzf.vim'
Plug 'tyru/caw.vim'
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

" List ends here. Plugins become visible to Vim after this call.
call plug#end()

" General settings
set number
set nobackup
set noswapfile
set viminfo+=n~/.local/share/vim/.viminfo
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

noremap j gj
noremap k gk
noremap gj j
noremap gk k

" templates
autocmd BufNewFile requirements.in 0r $HOME/.config/nvim/templates/requirements.in.template

" lsp
if executable('clangd')
  augroup LspCpp
    au!
    autocmd User lsp_setup call lsp#register_server({
        \ 'name': 'clangd',
        \ 'cmd': {server_info->['clangd']},
        \ 'whitelist': ['c', 'cpp', 'objc', 'objcpp'],
        \ })
    autocmd FileType c,cpp setlocal omnifunc=lsp#complete
  augroup END
endif
let g:lsp_log_verbose = 1
let g:lsp_log_file = expand('~/.local/share/vim/vim-lsp.log')

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

---------- plugins --------------------
require('packer').startup(function()
  use 'wbthomason/packer.nvim'
  use 'neovim/nvim-lspconfig'
  use 'williamboman/mason.nvim'
  use 'williamboman/mason-lspconfig.nvim'
  use 'mfussenegger/nvim-dap'
  use 'jose-elias-alvarez/null-ls.nvim'
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  use {
    'lewis6991/gitsigns.nvim',
    tag = 'release'
  }
  use 'ibhagwan/fzf-lua'
  use {
    'kyazdani42/nvim-tree.lua',
    requires = {
      'kyazdani42/nvim-web-devicons',
    },
  }
  use 'numToStr/Comment.nvim'
  use 'ntpeters/vim-better-whitespace'
  use 'cocopon/iceberg.vim'
end)

---------- options --------------------
vim.opt.number = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.clipboard = "unnamedplus"

---------- color --------------------
vim.cmd 'colorscheme iceberg'

---------- keymaps --------------------
vim.keymap.set('n', '<space>f', '<cmd>FzfLua files<CR>')
vim.keymap.set('n', '<space>b', '<cmd>FzfLua buffers<CR>')
vim.keymap.set('n', '<space>g', '<cmd>FzfLua live_grep<CR>')
vim.keymap.set('n', '<space><space>', '<cmd>FzfLua builtin<CR>')
vim.keymap.set('n', '<space>ss', '<cmd>FzfLua lsp_document_symbols<CR>')
vim.keymap.set('n', '<space>sd', '<cmd>FzfLua diagnostics_document<CR>')
vim.keymap.set('n', '<space>sc', '<cmd>FzfLua git_bcommits<CR>')
vim.keymap.set('n', '<space>sC', '<cmd>FzfLua git_commits<CR>')
vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>')
vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>')
vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
vim.keymap.set('n', 'gt', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
vim.keymap.set('n', 'rn', '<cmd>lua vim.lsp.buf.rename()<CR>')
vim.keymap.set('n', 'ca', '<cmd>lua vim.lsp.buf.code_action()<CR>')
vim.keymap.set('n', '<space>tt', '<cmd>NvimTreeToggle<CR>')
vim.keymap.set('n', '<space>to', '<cmd>NvimTreeFocus<CR>')
vim.keymap.set('n', '<space>tf', '<cmd>NvimTreeFindFile<CR>')
vim.keymap.set('n', '<esc><esc>', '<cmd>nohlsearch<CR>')

---------- lsp --------------------
require('mason').setup()
require('mason-lspconfig').setup_handlers({
  function(server)
    local opt = {
      on_attach = function(client, bufnr)
        print("LSP started.")
      end
    }
    require('lspconfig')[server].setup(opt)
  end
})

---------- completion --------------------
require('cmp').setup({
  sources = {
    {name = 'nvim_lsp'},
    {name = 'buffer'},
    {name = 'path'},
  }
})

---------- gitsigns --------------------
require('gitsigns').setup({
  current_line_blame = true,
})

---------- nvim-tree --------------------
require('nvim-tree').setup()

---------- comment --------------------
require('Comment').setup()

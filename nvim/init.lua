---------- plugins --------------------
vim.cmd [[packadd packer.nvim]]
require('packer').startup(function()
  use 'wbthomason/packer.nvim'
  use 'neovim/nvim-lspconfig'
  use 'hrsh7th/nvim-compe'
  use {
    'nvim-telescope/telescope.nvim',
    requires = {{'nvim-lua/popup.nvim'}, {'nvim-lua/plenary.nvim'}}
  }
  use 'b3nj5m1n/kommentary'
  use 'cocopon/iceberg.vim'
  use 'ntpeters/vim-better-whitespace'
  use {
    'lewis6991/gitsigns.nvim',
    requires = {'nvim-lua/plenary.nvim'}
  }
  use {
    'lambdalisue/fern.vim',
    requires = {'antoinemadec/FixCursorHold.nvim'}
  }
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

---------- lsp --------------------
local lsp = require('lspconfig')
local on_attach = function(client, bufnr)
  print("LSP started.")
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  local opts = {noremap = true, silent = true}
  buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<cr>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<cr>', opts)
  buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
  buf_set_keymap('n', '<space>a', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
  buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<cr>', opts)
end

lsp.clangd.setup{
  on_attach = on_attach,
  cmd = {"clangd-12", "--background-index"},
}
lsp.pyright.setup{
  on_attach = on_attach
}

---------- completion --------------------
vim.opt.completeopt = 'menuone,noselect'
require'compe'.setup{
  enabled = true,
  autocomplete = true,
  source = {
    path = true,
    buffer = true,
    spell = true,
    nvim_lsp = true,
  },
}

---------- telescope --------------------
local actions = require('telescope.actions')
require('telescope').setup{
  defaults = {
    file_ignore_patterns = {
      '%.png', '%.jpg',
      '%.mp4', '%.mp3',
      '%.tgz', '%.tar.gz', '%.zst', '%.zip',
      'install', 'build', 'log',
    },
    mappings = {
      i = {
        ["<esc>"] = actions.close
      },
    },
    layout_config = {
      prompt_position = 'bottom',
    },
    path_display = {
      'shorten',
    },
  }
}

---------- gitsigns --------------------
require('gitsigns').setup()

---------- mappings --------------------
local function map(mode, lhs, rhs, opts)
  local options = {noremap = true}
  if opts then options = vim.tbl_extend('force', options, opts) end
  vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end
map('n', '<space>f', '<cmd>Telescope find_files<cr>')
map('n', '<space>g', '<cmd>Telescope live_grep<cr>')
map('n', '<space>b', '<cmd>Telescope buffers<cr>')
map('n', '<esc><esc>', '<cmd>nohlsearch<cr>')
map('n', '<space>t', '<cmd>Fern . -drawer -width=60 -toggle<cr>')

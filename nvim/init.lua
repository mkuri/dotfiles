---------- plugins --------------------
require('packer').startup(function()
  use 'wbthomason/packer.nvim'
  use 'neovim/nvim-lspconfig'
  use 'williamboman/mason.nvim'
  use 'williamboman/mason-lspconfig.nvim'
  use 'mfussenegger/nvim-dap'
  use 'rcarriga/nvim-dap-ui'
  use {
    'folke/trouble.nvim',
    requires = {
      'kyazdani42/nvim-web-devicons',
    },
  }
  use 'j-hui/fidget.nvim'
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  use 'lewis6991/gitsigns.nvim'
  use 'ibhagwan/fzf-lua'
  use {
    'kyazdani42/nvim-tree.lua',
    requires = {
      'kyazdani42/nvim-web-devicons',
    },
  }
  use 'numToStr/Comment.nvim'
  use 'ntpeters/vim-better-whitespace'
  use 'hoshinotsuyoshi/vim-to-github'
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
vim.keymap.set('n', '<space><space>', '<cmd>FzfLua builtin<CR>')
vim.keymap.set('n', '<space>sg', '<cmd>FzfLua live_grep<CR>')
vim.keymap.set('n', '<space>ss', '<cmd>FzfLua lsp_document_symbols<CR>')
vim.keymap.set('n', '<space>sd', '<cmd>FzfLua diagnostics_document<CR>')
vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>')
vim.keymap.set('n', 'gr', '<cmd>TroubleToggle lsp_references<CR>')
vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
vim.keymap.set('n', 'gt', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
vim.keymap.set('n', 'rn', '<cmd>lua vim.lsp.buf.rename()<CR>')
vim.keymap.set('n', 'ca', '<cmd>lua vim.lsp.buf.code_action()<CR>')
vim.keymap.set('n', '<F5>', '<cmd>DapContinue<CR>')
vim.keymap.set('n', '<F10>', '<cmd>DapStepOver<CR>')
vim.keymap.set('n', '<F11>', '<cmd>DapStepInto<CR>')
vim.keymap.set('n', '<F12>', '<cmd>DapStepOut<CR>')
vim.keymap.set('n', '<space>db', '<cmd>DapToggleBreakpoint<CR>')
vim.keymap.set('n', '<space>dd', '<cmd>lua require"dapui".toggle()<CR>')
vim.keymap.set('n', '<space>tt', '<cmd>NvimTreeToggle<CR>')
vim.keymap.set('n', '<space>to', '<cmd>NvimTreeFocus<CR>')
vim.keymap.set('n', '<space>tf', '<cmd>NvimTreeFindFile<CR>')
vim.keymap.set('n', '<space>gc', '<cmd>FzfLua git_bcommits<CR>')
vim.keymap.set('n', '<space>gb', '<cmd>ToGithub<CR>')
vim.keymap.set('n', '<space>xx', '<cmd>TroubleToggle document_diagnostics<CR>')
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
require('fidget').setup()

---------- dap --------------------
require('dapui').setup()

---------- completion --------------------
local cmp = require('cmp')
cmp.setup({
  sources = cmp.config.sources({
    {name = 'nvim_lsp'},
    {name = 'buffer'},
    {name = 'path'},
  }),
  mapping = {
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
  },
})

---------- gitsigns --------------------
require('gitsigns').setup({
  current_line_blame = true,
})

---------- nvim-tree --------------------
require('nvim-tree').setup({
  view = {
    adaptive_size = true,
  },
  renderer = {
    symlink_destination = false,
  },
})

---------- comment --------------------
require('Comment').setup()

-- init.lua for Neovim
-- Debug helper function
local function debug_print(message)
  vim.api.nvim_echo({{message, "WarningMsg"}}, true, {})
  print(message)
end

debug_print("Loading init.lua...")

-- Install and configure package manager (packer)
local install_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
local packer_bootstrap = false

if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  debug_print("Installing packer...")
  packer_bootstrap = vim.fn.system({
    'git',
    'clone',
    '--depth',
    '1',
    'https://github.com/wbthomason/packer.nvim',
    install_path
  })
  vim.cmd [[packadd packer.nvim]]
  debug_print("Packer installed")
end

-- Basic options
vim.o.number = true
-- vim.o.relativenumber = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.termguicolors = true
vim.o.updatetime = 300
vim.o.timeoutlen = 500
vim.o.signcolumn = "yes"
vim.o.wrap = false

-- Plugin setup with Packer
require('packer').startup({function(use)
  debug_print("Configuring plugins...")
  
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'
  
  -- CodeCompanion
  use {
    'jellydn/CopilotChat.nvim',
    config = function()
      debug_print("Loading CodeCompanion...")
      require("CopilotChat").setup({
        -- Your CodeCompanion configuration
      })
      debug_print("CodeCompanion loaded")
    end,
    requires = {
      "nvim-lua/plenary.nvim",
      "zbirenbaum/copilot.lua", -- Ensure this is installed
    }
  }
  
  -- Copilot Chat
  use {
    'CopilotC-Nvim/CopilotChat.nvim',
    config = function()
      debug_print("Loading CopilotChat...")
      require("copilot_chat").setup({
        -- Your CopilotChat configuration
      })
      debug_print("CopilotChat loaded")
    end,
    requires = {
      "nvim-lua/plenary.nvim",
    }
  }
  
  -- bhop (Bunny hop - for easy motion)
  use {
    'phaazon/hop.nvim',
    config = function()
      debug_print("Loading hop.nvim...")
      require('hop').setup()
      debug_print("hop.nvim loaded")
    end
  }
  
  -- Copilot.nvim
  use {
    'zbirenbaum/copilot.lua',
    config = function()
      debug_print("Loading copilot.lua...")
      require('copilot').setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
      })
      debug_print("copilot.lua loaded")
    end
  }
  
  -- Add essential plugins for dev experience
  use {
    'nvim-treesitter/nvim-treesitter',
    run = function()
      debug_print("Running Treesitter setup...")
      local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
      ts_update()
    end,
    config = function()
      debug_print("Configuring Treesitter...")
      require('nvim-treesitter.configs').setup({
        ensure_installed = { "lua", "vim", "javascript", "typescript", "python" },
        highlight = { enable = true },
      })
      debug_print("Treesitter configured")
    end
  }
  
  -- Telescope for fuzzy finding
  use {
    'nvim-telescope/telescope.nvim',
    requires = { {'nvim-lua/plenary.nvim'} },
    config = function()
      debug_print("Loading telescope...")
      require('telescope').setup()
      debug_print("Telescope loaded")
    end
  }
  
  -- LSP Configuration
  use {
    'neovim/nvim-lspconfig',
    config = function()
      debug_print("Setting up LSP...")
      -- Basic LSP setup
      local lspconfig = require('lspconfig')
      lspconfig.tsserver.setup {}
      lspconfig.pyright.setup {}
      debug_print("LSP configured")
    end
  }
  
  -- Colorscheme
  use {
    'folke/tokyonight.nvim',
    config = function()
      debug_print("Setting colorscheme...")
      vim.cmd[[colorscheme tokyonight]]
      debug_print("Colorscheme set")
    end
  }
  
  -- Automatically set up configuration after cloning packer.nvim
  if packer_bootstrap then
    debug_print("Running PackerSync due to first-time install...")
    require('packer').sync()
  end
end,
config = {
  display = {
    open_fn = function()
      return require('packer.util').float({ border = 'rounded' })
    end
  }
}})

-- Add keymappings
debug_print("Setting up keymappings...")

-- Leader key
-- vim.g.mapleader = ' '

-- Copilot Chat
vim.api.nvim_set_keymap('n', '<leader>cc', ':CopilotChat<CR>', {noremap = true, silent = true})

-- Hop (bhop)
vim.api.nvim_set_keymap('n', '<leader>hw', ':HopWord<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>hl', ':HopLine<CR>', {noremap = true, silent = true})

-- Telescope
vim.api.nvim_set_keymap('n', '<leader>ff', ':Telescope find_files<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>fg', ':Telescope live_grep<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>fb', ':Telescope buffers<CR>', {noremap = true, silent = true})

-- Common operations
vim.api.nvim_set_keymap('n', '<leader>w', ':w<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>q', ':q<CR>', {noremap = true, silent = true})

debug_print("Keymappings set")
debug_print("Neovim configuration loaded successfully!")

-- Add an autocmd group for debugging
local augroup = vim.api.nvim_create_augroup("ConfigDebug", { clear = true })

-- Log when entering a buffer
-- vim.api.nvim_create_autocmd("BufEnter", {
--   group = augroup,
--   callback = function(ev)
--     debug_print("Entered buffer: " .. ev.file)
--   end,
-- })

-- Create a command to check plugin status
vim.api.nvim_create_user_command("CheckPlugins", function()
  debug_print("Checking plugin status:")
  local plugins = {
    "CopilotChat",
    "copilot",
    "hop",
    "nvim-treesitter",
    "telescope",
    "lspconfig"
  }
  
  for _, plugin in ipairs(plugins) do
    local loaded = pcall(require, plugin:gsub("%.nvim$", ""))
    debug_print(plugin .. ": " .. (loaded and "Loaded" or "Not loaded"))
  end
end, {})

-- Print final confirmation
debug_print("Init.lua fully loaded. Type :CheckPlugins to verify plugin status.")

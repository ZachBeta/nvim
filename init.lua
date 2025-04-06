-- # Step 1
-- init.lua - Minimal base configuration
-- Clear all mappings and set leader key at the very beginning
vim.cmd('mapclear')
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Prevent space from doing anything by default
vim.api.nvim_set_keymap('n', ' ', '<Nop>', {noremap = true})

-- Basic settings vim.o.number = true
vim.o.relativenumber = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.smartindent = true

-- Test mapping to verify leader key works
vim.api.nvim_set_keymap('n', '<Leader>test', ':echo "Leader key works!"<CR>', {noremap = true})

-- # Step 2

-- Add to init.lua
-- Debug helper function
local function debug_print(message)
  vim.api.nvim_echo({{message, "WarningMsg"}}, true, {})
  print(message)
end

--
-- Install packer if not installed
local install_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
local packer_bootstrap = false

if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  debug_print("Installing packer...")
  packer_bootstrap = vim.fn.system({
    'git', 'clone', '--depth', '1',
    'https://github.com/wbthomason/packer.nvim', install_path
  })
  vim.cmd [[packadd packer.nvim]]
  debug_print("Packer installed")
end

-- Correct way to add hop.nvim
require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  -- Inside your packer setup function
  use {
    'phaazon/hop.nvim',
    branch = 'v2', -- important: use v2 branch
    config = function()
      require('hop').setup()
    end
  }

  use {
    'nvim-telescope/telescope.nvim',
    requires = { {'nvim-lua/plenary.nvim'} },
    config = function()
      require('telescope').setup()
    end
  }

--  use {
--    'zbirenbaum/copilot.lua',
--    config = function()
--      require('copilot').setup({
--        suggestion = { enabled = false },
--        panel = { enabled = false },
--      })
--    end
--  }
--
--  use {
--    'CopilotC-Nvim/CopilotChat.nvim',
--    config = function()
--      -- The module might be named differently than expected
--      -- Let's try different possible names
--      local status_ok, copilot_chat = pcall(require, "CopilotChat")
--      if not status_ok then
--        -- Try alternative module name
--        status_ok, copilot_chat = pcall(require, "copilotchat")
--        if not status_ok then
--          print("Failed to load CopilotChat plugin")
--          return
--        end
--      end
--
--      copilot_chat.setup()
--    end,
--    requires = {
--      {"nvim-lua/plenary.nvim"},
--      {"zbirenbaum/copilot.lua"} -- This dependency might be needed
--    }
--  }

  use {
    'nvim-lualine/lualine.nvim',
    config = function()
      require('lualine').setup()
    end
  }

  -- Or for packer.nvim
  use {
    '~/.config/nvim/lua/llm_agent_new',  -- Absolute path with ~
    as = 'llm_agent_new',
    config = function()
      require("llm_agent_new").setup()
    end,
  }
  
  -- Other plugins would go here

  -- Automatically set up configuration after cloning packer.nvim
  if packer_bootstrap then
    require('packer').sync()
  end
end)

require('hop').setup()

-- Add keymaps after plugin setup
vim.api.nvim_set_keymap('n', '<Leader>hw', ':HopWord<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<Leader>hl', ':HopLine<CR>', {noremap = true})

vim.api.nvim_set_keymap('n', '<Leader>ff', ':Telescope find_files<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<Leader>fg', ':Telescope live_grep<CR>', {noremap = true})

-- vim.api.nvim_set_keymap('n', '<Leader>cc', ':CopilotChat<CR>', {noremap = true})

vim.o.termguicolors = true
vim.o.updatetime = 300
vim.o.timeoutlen = 500
vim.o.signcolumn = "yes"
vim.o.wrap = false

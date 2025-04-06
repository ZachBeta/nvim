-- # Step 1
-- init.lua - Minimal base configuration
-- Clear all mappings and set leader key at the very beginning
vim.cmd('mapclear')
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Prevent space from doing anything by default
vim.api.nvim_set_keymap('n', ' ', '<Nop>', {noremap = true})

-- Basic settings
vim.o.number = true
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

-- Create verification command
vim.api.nvim_create_user_command("CheckLeader", function()
  debug_print("Leader key is: '" .. vim.inspect(vim.g.mapleader) .. "'")
  debug_print("Try <space>test to verify functionality")
end, {})

-- # Step 3
--
-- Add to init.lua
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
  

-- tests/minimal_init.lua
-- Minimal configuration for running tests

-- Add packer and plenary to the runtime path
local packer_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
local plenary_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/plenary.nvim'

-- Add necessary directories to runtimepath
-- We need the path containing the 'llm_agent_new' directory itself.
local config_lua_path = vim.fn.expand("$HOME/.config/nvim/lua")

local paths_to_add = {
  packer_path,
  plenary_path,
  config_lua_path -- Add the directory containing our plugin's folder
}

-- Clear runtimepath first to avoid interference from user config
vim.opt.runtimepath = ''

for _, path in ipairs(paths_to_add) do
  if vim.fn.isdirectory(path) > 0 then
    vim.opt.runtimepath:append(path) -- Use append or prepend consistently
  else
    -- print('Warning: Test setup could not find directory: ' .. path)
  end
end

-- Append Neovim's own runtime dir last
vim.opt.runtimepath:append(vim.env.VIMRUNTIME)


-- Minimal settings
vim.o.compatible = false
vim.o.termguicolors = true

-- Ensure Plenary's plugin scripts are loaded from the modified runtimepath
vim.cmd [[runtime! plugin/plenary.vim]]

-- Now require Plenary
local plenary_ok, plenary = pcall(require, 'plenary')
if not plenary_ok then
  error("Failed to require plenary.nvim. Ensure it is installed correctly at: " .. plenary_path .. "\nRuntime path: " .. vim.o.runtimepath)
end 
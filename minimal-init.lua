-- minimal-init.lua - Save this as a separate file to test leader key functionality
-- This is a minimal config to test ONLY leader key functionality

-- Clear any existing mappings and settings
vim.cmd('mapclear')

-- Helper function to display messages
local function echo(msg)
  vim.api.nvim_echo({{msg, "WarningMsg"}}, true, {})
end

echo("Starting minimal test configuration...")

-- Set leader key using multiple approaches for maximum compatibility
vim.g.mapleader = ","
vim.g.maplocalleader = "," -- Also set local leader
vim.api.nvim_set_var("mapleader", ",") -- Alternative approach
-- Try comma as leader

-- Or try backslash (Vim's default leader)
-- vim.g.mapleader = "\\"

-- Create several test mappings using different methods
vim.api.nvim_set_keymap('n', '<Leader>t1', ':echo "Test 1 works!"<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<Space>t2', ':echo "Test 2 works!"<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', ' t3', ':echo "Test 3 works!"<CR>', {noremap = true})

-- Also try a Vim command style mapping
vim.cmd([[nnoremap <Leader>t4 :echo "Test 4 works!"<CR>]])
vim.cmd([[nnoremap <Space>t5 :echo "Test 5 works!"<CR>]])

-- Set up an autocmd to verify leader key at startup
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    echo("Verification steps:")
    echo("1. Leader key is currently set to: '" .. vim.inspect(vim.g.mapleader) .. "'")
    echo("2. Try these test mappings:")
    echo("   - <Leader>t1 (API mapping with <Leader>)")
    echo("   - <Space>t2 (API mapping with <Space>)")
    echo("   - space+t3 (API mapping with literal space)")
    echo("   - <Leader>t4 (Vim command with <Leader>)")
    echo("   - <Space>t5 (Vim command with <Space>)")
    echo("3. Run :map <Leader> to see all leader mappings")
    echo("4. Run :map <Space> to see all space mappings")
  end,
})

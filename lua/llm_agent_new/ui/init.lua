-- lua/llm_agent_new/ui/init.lua

local api = vim.api
local M = {}

-- Store the buffer number of the chat window
local chat_bufnr = nil

-- Function to open the chat buffer in a right-side vertical split
function M.open_chat_window(config)
  -- Configuration for the split
  local width = config.width or 80
  -- Height is determined by the editor layout, not fixed
  -- Border is not applicable to standard splits

  -- Check if the buffer already exists and is loaded
  if chat_bufnr and api.nvim_buf_is_loaded(chat_bufnr) then
    -- Find the window displaying the buffer
    local win_id = vim.fn.bufwinid(chat_bufnr)
    if win_id ~= -1 then
      -- Window exists, just focus it
      api.nvim_set_current_win(win_id)
      vim.notify("Switched to existing chat window.", vim.log.levels.INFO)
      return
    end
    -- Buffer exists but window doesn't, proceed to create split
  else
    -- Create a new buffer for the chat window
    chat_bufnr = api.nvim_create_buf(false, true) -- Args: listed, scratch
    api.nvim_buf_set_option(chat_bufnr, 'bufhidden', 'wipe') -- Close buffer when window closes
    api.nvim_buf_set_option(chat_bufnr, 'filetype', 'markdown') -- Set filetype
    api.nvim_buf_set_lines(chat_bufnr, 0, -1, false, {"LLM Agent Chat Buffer - Placeholder"}) -- Initial content
    
    -- Basic keymap to close the buffer (e.g., with 'q')
    -- Use :Bdelete to remove the buffer entirely when closed
    api.nvim_buf_set_keymap(chat_bufnr, 'n', 'q', ':Bdelete!<CR>', { noremap = true, silent = true })
  end

  -- Execute commands to open the split
  vim.cmd(string.format('rightbelow vsplit | buffer %d', chat_bufnr))
  
  -- Resize the new vertical split
  vim.cmd(string.format('vertical resize %d', width))

  vim.notify(string.format("Opened chat buffer %d in a vertical split. Press 'q' to close.", chat_bufnr), vim.log.levels.INFO)
end

-- No need for explicit close_chat_window for splits, standard commands work.

return M 
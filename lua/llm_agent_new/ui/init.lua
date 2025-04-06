-- lua/llm_agent_new/ui/init.lua

local api = vim.api
local M = {}

-- Store the buffer number and the callback for sending messages
local chat_bufnr = nil
local send_message_callback = nil

-- Helper to append messages, managing modifiable state
local function append_message(bufnr_arg, role, message)
    -- Use the module-level chat_bufnr if no specific bufnr is passed
    local bufnr = bufnr_arg or chat_bufnr
    if not bufnr or type(bufnr) ~= "number" then
        vim.notify("UI Error: append_message called without a valid buffer number. Got: " .. vim.inspect(bufnr), vim.log.levels.ERROR)
        return
    end
    
    -- Ensure buffer is still valid before proceeding
    if not api.nvim_buf_is_valid(bufnr) then
        vim.notify("UI Error: append_message called with an invalid buffer number: " .. bufnr, vim.log.levels.ERROR)
        chat_bufnr = nil -- Clear the stored buffer number if invalid
        return
    end

    local is_modifiable = api.nvim_buf_get_option(bufnr, 'modifiable')
    api.nvim_buf_set_option(bufnr, 'modifiable', true)
    
    -- Find the last line (where the prompt is)
    local last_line = api.nvim_buf_line_count(bufnr)
    
    -- Format the message
    local formatted_lines = {}
    table.insert(formatted_lines, string.format("**%s:**", role))
    -- Split message by newlines and add each line
    for _, line in ipairs(vim.split(message, "\n")) do
        table.insert(formatted_lines, line)
    end
    table.insert(formatted_lines, "") -- Add empty line for spacing
    
    -- Insert message before the prompt line
    api.nvim_buf_set_lines(bufnr, last_line - 1, last_line - 1, false, formatted_lines)
    
    api.nvim_buf_set_option(bufnr, 'modifiable', is_modifiable) 
end

M.append_message = append_message -- Expose helper if needed externally

-- Function called when Enter is pressed on the prompt line
local function on_prompt_submit(input)
  if not input or input == "" then
    vim.notify("Input cannot be empty.", vim.log.levels.WARN)
    return
  end

  -- Append user message immediately
  append_message(chat_bufnr, "User", input)
  
  -- Clear the prompt area (optional, handled by buftype=prompt?)
  -- api.nvim_buf_set_lines(chat_bufnr, -1, -1, false, { "> " })

  -- Call the actual send function provided during setup
  if send_message_callback then
    vim.notify("UI: Sending message to API module...", vim.log.levels.DEBUG)
    send_message_callback({input}) -- Send as array for now, matching API expectation
  else
    vim.notify("UI Error: send_message_callback not set!", vim.log.levels.ERROR)
  end
end

-- Function to open and set up the chat buffer
function M.setup_chat_window(config, send_cb)
  send_message_callback = send_cb -- Store the callback
  local width = config.width or 80

  if chat_bufnr and api.nvim_buf_is_loaded(chat_bufnr) then
    local win_id = vim.fn.bufwinid(chat_bufnr)
    if win_id ~= -1 then
      api.nvim_set_current_win(win_id)
      vim.notify("Switched to existing chat window.", vim.log.levels.INFO)
      return
    end
  else
    -- Create buffer
    chat_bufnr = api.nvim_create_buf(false, true) 
    api.nvim_buf_set_option(chat_bufnr, 'bufhidden', 'wipe')
    api.nvim_buf_set_option(chat_bufnr, 'filetype', 'markdown')
    
    -- Set buffer type to prompt and other options
    api.nvim_buf_set_option(chat_bufnr, 'buftype', 'prompt')
    api.nvim_buf_set_option(chat_bufnr, 'modifiable', true) -- Prompt needs modifiable
    
    -- Initial content - maybe just the prompt?
    api.nvim_buf_set_lines(chat_bufnr, 0, -1, false, {"LLM Agent Chat", ""}) 
    
    -- Set the prompt text (appears on the last line)
    vim.fn.prompt_setprompt(chat_bufnr, "> ")
    
    -- Set the callback for when Enter is pressed in the prompt buffer
    vim.fn.prompt_setcallback(chat_bufnr, on_prompt_submit)
    
    -- Keymap to close buffer
    api.nvim_buf_set_keymap(chat_bufnr, 'n', 'q', ':Bdelete!<CR>', { noremap = true, silent = true })
    api.nvim_buf_set_keymap(chat_bufnr, 'i', '<Esc>', '<Nop>', { noremap = true, silent = true }) -- Optional: prevent Esc exiting prompt mode?
  end

  -- Open split
  vim.cmd(string.format('rightbelow vsplit | buffer %d', chat_bufnr))
  vim.cmd(string.format('vertical resize %d', width))
  
  -- Move cursor to the end for prompt
  api.nvim_win_set_cursor(0, {api.nvim_buf_line_count(chat_bufnr), 0})
  vim.cmd('startinsert') -- Enter insert mode on the prompt line

  vim.notify(string.format("Opened chat buffer %d. Type your message and press Enter.", chat_bufnr), vim.log.levels.INFO)
end

return M 
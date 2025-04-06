-- lua/llm_agent_new/ui/init.lua

local api = vim.api
local M = {}

-- Store the buffer number, window ID, and the callback for sending messages
local chat_state = {
  bufnr = nil,
  winid = nil,
  send_message_callback = nil,
  config = nil -- Store config for reopening
}

-- Helper to append messages
local function append_message(role, message)
    local bufnr = chat_state.bufnr
    if not bufnr or not api.nvim_buf_is_valid(bufnr) then
        vim.notify("UI Error: Cannot append message, chat buffer is invalid or missing.", vim.log.levels.ERROR)
        return
    end

    local is_modifiable = api.nvim_buf_get_option(bufnr, 'modifiable')
    api.nvim_buf_set_option(bufnr, 'modifiable', true)
    
    local last_line = api.nvim_buf_line_count(bufnr)
    local formatted_lines = {}
    table.insert(formatted_lines, string.format("**%s:**", role))
    for _, line in ipairs(vim.split(message, "\n")) do
        table.insert(formatted_lines, line)
    end
    table.insert(formatted_lines, "")
    api.nvim_buf_set_lines(bufnr, last_line - 1, last_line - 1, false, formatted_lines)
    
    -- Keep buffer modifiable while chat is active
    -- api.nvim_buf_set_option(bufnr, 'modifiable', is_modifiable) 
end
M.append_message = function(...) append_message(...) end -- Expose helper

-- Function called when Enter is pressed on the prompt line
local function on_prompt_submit(input)
  if not input or input == "" then
    vim.notify("Input cannot be empty.", vim.log.levels.WARN)
    return
  end
  append_message("User", input)
  if chat_state.send_message_callback then
    vim.notify("UI: Sending message to API module...", vim.log.levels.DEBUG)
    chat_state.send_message_callback({input})
  else
    vim.notify("UI Error: send_message_callback not set!", vim.log.levels.ERROR)
  end
end

-- Function to create and open the chat window if needed
local function ensure_window_open()
    local bufnr = chat_state.bufnr
    local config = chat_state.config
    if not bufnr or not api.nvim_buf_is_loaded(bufnr) then
        -- Create buffer if it doesn't exist
        bufnr = api.nvim_create_buf(false, true) 
        chat_state.bufnr = bufnr
        api.nvim_buf_set_option(bufnr, 'bufhidden', 'hide') -- Hide buffer, don't wipe
        api.nvim_buf_set_option(bufnr, 'filetype', 'markdown')
        api.nvim_buf_set_option(bufnr, 'buftype', 'prompt')
        api.nvim_buf_set_option(bufnr, 'modifiable', true)
        api.nvim_buf_set_lines(bufnr, 0, -1, false, {"LLM Agent Chat", ""}) 
        vim.fn.prompt_setprompt(bufnr, "> ")
        vim.fn.prompt_setcallback(bufnr, on_prompt_submit)
        -- Add other keymaps if needed, e.g., for normal mode actions
        -- api.nvim_buf_set_keymap(bufnr, 'n', 'q', ':echo "Use toggle command to hide"<CR>', { noremap = true, silent = true })
    end

    -- Open split if window doesn't exist or is invalid
    if not chat_state.winid or not api.nvim_win_is_valid(chat_state.winid) then
        vim.cmd(string.format('keepalt rightbelow vsplit | buffer %d', bufnr))
        chat_state.winid = api.nvim_get_current_win() -- Get the new window ID
        vim.cmd(string.format('vertical resize %d', config.width or 80))
        vim.notify(string.format("Opened chat window %d.", chat_state.winid), vim.log.levels.INFO)
    end
    
    return chat_state.winid
end

-- Main function to toggle chat window visibility
function M.toggle_chat_window(config, send_cb)
  -- Store config and callback if provided (usually only on first call)
  if config then chat_state.config = config end
  if send_cb then chat_state.send_message_callback = send_cb end
  
  local winid = chat_state.winid
  
  -- Check if window exists and is valid
  if winid and api.nvim_win_is_valid(winid) then
    -- Window is valid, check if it's the current window
    if api.nvim_get_current_win() == winid then
      -- Current window, hide it
      api.nvim_win_hide(winid)
      vim.notify("Chat window hidden.", vim.log.levels.INFO)
      -- Don't clear winid from state, so we know it's hidden
    else
      -- Not current window, focus it
      api.nvim_set_current_win(winid)
      vim.notify("Switched to chat window.", vim.log.levels.INFO)
    end
  else
    -- Window doesn't exist or is invalid, ensure it's opened
    winid = ensure_window_open()
    if winid then
       api.nvim_set_current_win(winid) -- Focus the newly opened window
       -- Move cursor to the end for prompt
       api.nvim_win_set_cursor(winid, {api.nvim_buf_line_count(chat_state.bufnr), 0})
       vim.cmd('startinsert') -- Enter insert mode
    else 
       vim.notify("Failed to open or find chat window.", vim.log.levels.ERROR)
    end
  end
end

-- Setup function (kept for potential future use, but toggle is main entry now)
function M.setup_chat_window(config, send_cb)
    M.toggle_chat_window(config, send_cb)
end

return M 
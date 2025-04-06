-- llm-agent/ui/init.lua
-- UI module for chat interface

local utils = require("llm-agent.utils")
local config = require("llm-agent.config").defaults
local api = require("llm-agent.api")

local M = {}

-- Internal state
M._state = {
  chat_buf = nil,     -- Current chat buffer
  chat_win = nil,     -- Current chat window
  input_win = nil,    -- Input window
  input_buf = nil,    -- Input buffer
  context_win = nil,  -- Context summary window
  context_buf = nil,  -- Context summary buffer
  is_visible = false, -- Whether chat is currently visible
  messages = {},      -- Message history
  input_history = {}, -- Input history
  input_index = 0,    -- Current position in input history
  current_request = nil, -- Current active request
  streaming = false,  -- Whether we're currently streaming a response
  last_response = "", -- Last accumulated response text
}

-- Local helper functions
local function create_window(buf, opts)
  local default_opts = {
    relative = 'editor',
    width = 80,
    height = 24,
    row = 2,
    col = 2,
    style = 'minimal',
    border = 'rounded',
  }
  
  opts = vim.tbl_deep_extend('force', default_opts, opts or {})
  return vim.api.nvim_open_win(buf, true, opts)
end

-- Create a new chat buffer
function M.create_chat_buffer()
  local global_config = require("llm-agent")._config or config
  local ui_config = global_config.ui
  
  -- Create the main chat buffer if it doesn't exist or is invalid
  if not M._state.chat_buf or not vim.api.nvim_buf_is_valid(M._state.chat_buf) then
    M._state.chat_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(M._state.chat_buf, 'filetype', 'llm-chat')
    vim.api.nvim_buf_set_option(M._state.chat_buf, 'bufhidden', 'hide')
    vim.api.nvim_buf_set_option(M._state.chat_buf, 'modifiable', false)
    vim.api.nvim_buf_set_option(M._state.chat_buf, 'swapfile', false)
    
    -- Set buffer-local keymaps
    local keymaps = global_config.keymaps.chat or {}
    
    if keymaps.close then
      vim.api.nvim_buf_set_keymap(M._state.chat_buf, 'n', keymaps.close, 
        "<cmd>lua require('llm-agent.ui').close_chat()<CR>", 
        {noremap = true, silent = true})
    end
    
    if keymaps.scroll_down then
      vim.api.nvim_buf_set_keymap(M._state.chat_buf, 'n', keymaps.scroll_down, 
        "<C-d>", {noremap = false})
    end
    
    if keymaps.scroll_up then
      vim.api.nvim_buf_set_keymap(M._state.chat_buf, 'n', keymaps.scroll_up, 
        "<C-u>", {noremap = false})
    end
    
    -- Set up autocommands
    local chat_augroup = vim.api.nvim_create_augroup("LLMChatBuffer", {clear = true})
    
    vim.api.nvim_create_autocmd("BufWipeout", {
      group = chat_augroup,
      buffer = M._state.chat_buf,
      callback = function()
        M._state.chat_buf = nil
        M._state.is_visible = false
      end
    })
  end
  
  -- Create the input buffer if it doesn't exist or is invalid
  if not M._state.input_buf or not vim.api.nvim_buf_is_valid(M._state.input_buf) then
    M._state.input_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(M._state.input_buf, 'filetype', 'llm-chat-input')
    vim.api.nvim_buf_set_option(M._state.input_buf, 'bufhidden', 'hide')
    vim.api.nvim_buf_set_option(M._state.input_buf, 'swapfile', false)
    
    -- Set buffer-local keymaps
    if keymaps.submit then
      vim.api.nvim_buf_set_keymap(M._state.input_buf, 'i', keymaps.submit, 
        "<cmd>lua require('llm-agent.ui').submit_message()<CR>", 
        {noremap = true, silent = true})
    end
    
    if keymaps.cancel then
      vim.api.nvim_buf_set_keymap(M._state.input_buf, 'i', keymaps.cancel, 
        "<cmd>lua require('llm-agent.ui').cancel_request()<CR>", 
        {noremap = true, silent = true})
    end
    
    if keymaps.next_history then
      vim.api.nvim_buf_set_keymap(M._state.input_buf, 'i', keymaps.next_history, 
        "<cmd>lua require('llm-agent.ui').next_history()<CR>", 
        {noremap = true, silent = true})
    end
    
    if keymaps.prev_history then
      vim.api.nvim_buf_set_keymap(M._state.input_buf, 'i', keymaps.prev_history, 
        "<cmd>lua require('llm-agent.ui').prev_history()<CR>", 
        {noremap = true, silent = true})
    end
  end
  
  return M._state.chat_buf
end

-- Calculate window dimensions based on orientation
local function get_window_dimensions()
  local global_config = require("llm-agent")._config or config
  local ui_config = global_config.ui
  
  local orientation = ui_config.orientation or "vertical"
  local position = ui_config.position or "right"
  
  local width, height
  local editor_width = vim.o.columns
  local editor_height = vim.o.lines - vim.o.cmdheight - 2 -- Account for status line and cmd area
  
  if orientation == "vertical" then
    local size = ui_config.size.vertical or "30%"
    if type(size) == "string" and size:match("%%$") then
      local percent = tonumber(size:match("(%d+)%%"))
      width = math.floor(editor_width * percent / 100)
    else
      width = tonumber(size) or math.floor(editor_width * 0.3)
    end
    height = editor_height
    
    -- Adjust based on position
    local col = position == "left" and 0 or (editor_width - width)
    
    return {
      width = width,
      height = height,
      col = col,
      row = 0,
      input_height = 3, -- Input area height
      orientation = orientation,
      position = position
    }
  else -- horizontal
    local size = ui_config.size.horizontal or "20%"
    if type(size) == "string" and size:match("%%$") then
      local percent = tonumber(size:match("(%d+)%%"))
      height = math.floor(editor_height * percent / 100)
    else
      height = tonumber(size) or math.floor(editor_height * 0.2)
    end
    width = editor_width
    
    -- Adjust based on position
    local row = position == "top" and 0 or (editor_height - height)
    
    return {
      width = width,
      height = height,
      col = 0,
      row = row,
      input_height = 3, -- Input area height
      orientation = orientation,
      position = position
    }
  end
end

-- Create chat window layout
function M.create_chat_windows()
  -- Calculate dimensions
  local dims = get_window_dimensions()
  
  -- Create main chat window
  if not M._state.chat_win or not vim.api.nvim_win_is_valid(M._state.chat_win) then
    -- Create chat window with slightly reduced height to make room for input
    local chat_height = dims.height - dims.input_height
    M._state.chat_win = vim.api.nvim_open_win(M._state.chat_buf, true, {
      relative = 'editor',
      width = dims.width,
      height = chat_height,
      col = dims.col,
      row = dims.row,
      style = 'minimal',
      border = 'none',
    })
    
    -- Set window options
    vim.api.nvim_win_set_option(M._state.chat_win, 'wrap', true)
    vim.api.nvim_win_set_option(M._state.chat_win, 'linebreak', true)
    vim.api.nvim_win_set_option(M._state.chat_win, 'number', false)
    vim.api.nvim_win_set_option(M._state.chat_win, 'cursorline', false)
    vim.api.nvim_win_set_option(M._state.chat_win, 'signcolumn', 'no')
    vim.api.nvim_win_set_option(M._state.chat_win, 'foldcolumn', '0')
    
    -- Add window-local autocommands
    local win_augroup = vim.api.nvim_create_augroup("LLMChatWindow", {clear = true})
    
    vim.api.nvim_create_autocmd("WinClosed", {
      group = win_augroup,
      pattern = tostring(M._state.chat_win),
      callback = function()
        M.close_chat()
      end
    })
  end
  
  -- Create input window below chat window
  if not M._state.input_win or not vim.api.nvim_win_is_valid(M._state.input_win) then
    M._state.input_win = vim.api.nvim_open_win(M._state.input_buf, false, {
      relative = 'editor',
      width = dims.width,
      height = dims.input_height,
      col = dims.col,
      row = dims.row + dims.height - dims.input_height,
      style = 'minimal',
      border = 'none',
    })
    
    -- Set window options
    vim.api.nvim_win_set_option(M._state.input_win, 'wrap', true)
    vim.api.nvim_win_set_option(M._state.input_win, 'linebreak', true)
    vim.api.nvim_win_set_option(M._state.input_win, 'number', false)
    vim.api.nvim_win_set_option(M._state.input_win, 'cursorline', false)
    vim.api.nvim_win_set_option(M._state.input_win, 'signcolumn', 'no')
    vim.api.nvim_win_set_option(M._state.input_win, 'foldcolumn', '0')
    
    -- Clear input buffer and set focus
    vim.api.nvim_buf_set_lines(M._state.input_buf, 0, -1, false, {""})
  end
  
  -- Focus chat window initially
  vim.api.nvim_set_current_win(M._state.chat_win)
  
  -- Mark as visible
  M._state.is_visible = true
  
  -- Render initial content if needed
  M.render_messages()
end

-- Open chat interface
function M.open_chat()
  -- Create buffer if needed
  M.create_chat_buffer()
  
  -- Create windows
  M.create_chat_windows()
  
  -- Focus input window and enter insert mode
  vim.api.nvim_set_current_win(M._state.input_win)
  vim.cmd("startinsert")
  
  -- Initialize API if needed
  if not api._state.active_provider then
    api.setup()
  end
end

-- Close chat interface
function M.close_chat()
  -- Cancel any active request
  if M._state.current_request then
    M.cancel_request()
  end
  
  -- Close windows if they exist
  if M._state.chat_win and vim.api.nvim_win_is_valid(M._state.chat_win) then
    vim.api.nvim_win_close(M._state.chat_win, true)
    M._state.chat_win = nil
  end
  
  if M._state.input_win and vim.api.nvim_win_is_valid(M._state.input_win) then
    vim.api.nvim_win_close(M._state.input_win, true)
    M._state.input_win = nil
  end
  
  if M._state.context_win and vim.api.nvim_win_is_valid(M._state.context_win) then
    vim.api.nvim_win_close(M._state.context_win, true)
    M._state.context_win = nil
  end
  
  -- Mark as not visible
  M._state.is_visible = false
end

-- Toggle chat visibility
function M.toggle_chat()
  if M._state.is_visible then
    M.close_chat()
  else
    M.open_chat()
  end
end

-- Add a message to chat
function M.add_message(role, content)
  table.insert(M._state.messages, {
    role = role,
    content = content,
    timestamp = os.time()
  })
  
  -- Re-render messages
  M.render_messages()
end

-- Submit user message from input
function M.submit_message()
  -- Get input content
  local lines = vim.api.nvim_buf_get_lines(M._state.input_buf, 0, -1, false)
  local content = table.concat(lines, "\n")
  
  -- Skip if empty
  if content:match("^%s*$") then
    return
  end
  
  -- Check for special commands
  if content:match("^/") then
    M.handle_command(content)
    return
  end
  
  -- Skip if request already in progress
  if M._state.current_request then
    utils.log.warn("Request already in progress")
    return
  end
  
  -- Add to history
  table.insert(M._state.input_history, content)
  M._state.input_index = #M._state.input_history + 1
  
  -- Add user message
  M.add_message("user", content)
  
  -- Clear input
  vim.api.nvim_buf_set_lines(M._state.input_buf, 0, -1, false, {""})
  
  -- Start "thinking" message
  M.add_message("assistant", "_Thinking..._")
  M._state.streaming = true
  M._state.last_response = ""
  
  -- Prepare messages for API
  local api_messages = {}
  local prompt_messages = {}
  
  -- Add conversation history (limited to last 10 messages)
  local start_idx = math.max(1, #M._state.messages - 11)
  for i = start_idx, #M._state.messages - 2 do -- Skip the "thinking" message
    local msg = M._state.messages[i]
    table.insert(api_messages, {
      role = msg.role,
      content = msg.content
    })
  end
  
  -- Get last user message
  local user_msg = M._state.messages[#M._state.messages - 1] -- Last real message before "thinking"
  table.insert(api_messages, {
    role = user_msg.role,
    content = user_msg.content
  })
  
  -- Set up options
  local options = {
    include_context = true,  -- Include context files
    stream = true,           -- Stream the response
  }
  
  -- Set the current request (will be updated by the API)
  M._state.current_request = {}
  
  -- Send to API
  api.send_message(api_messages, options, function(response)
    if response.error then
      -- Handle error
      M._state.streaming = false
      M._state.current_request = nil
      
      -- Update last message
      M._state.messages[#M._state.messages] = {
        role = "system",
        content = "Error: " .. response.message,
        timestamp = os.time()
      }
      
      -- Re-render
      M.render_messages()
      return
    end
    
    -- Update message content for streaming
    if M._state.streaming then
      -- Replace "thinking" message with actual content
      M._state.messages[#M._state.messages] = {
        role = "assistant",
        content = response.response,
        timestamp = os.time()
      }
      
      -- Store last response
      M._state.last_response = response.response
      
      -- Re-render
      M.render_messages()
      
      -- Check if done
      if response.done then
        M._state.streaming = false
        M._state.current_request = nil
      end
    end
  end)
end

-- Handle chat commands
function M.handle_command(cmd)
  -- Extract command and arguments
  local command, args = cmd:match("^/(%w+)%s*(.*)")
  
  if command == "context" then
    M.handle_context_command(args)
  elseif command == "clear" then
    M._state.messages = {}
    M.render_messages()
  elseif command == "help" then
    M.show_help()
  elseif command == "status" then
    M.show_status()
  else
    M.add_message("system", "Unknown command: " .. command)
  end
  
  -- Clear input
  vim.api.nvim_buf_set_lines(M._state.input_buf, 0, -1, false, {""})
end

-- Show API status
function M.show_status()
  local status = api.get_status()
  local status_text = "# LLM Agent Status\n\n"
  
  -- OpenRouter status
  status_text = status_text .. "## OpenRouter\n"
  status_text = status_text .. "Status: " .. status.openrouter.status .. "\n"
  if status.openrouter.error then
    status_text = status_text .. "Error: " .. status.openrouter.error .. "\n"
  end
  status_text = status_text .. "\n"
  
  -- Ollama status
  status_text = status_text .. "## Ollama\n"
  status_text = status_text .. "Status: " .. status.ollama.status .. "\n"
  if status.ollama.error then
    status_text = status_text .. "Error: " .. status.ollama.error .. "\n"
  end
  status_text = status_text .. "\n"
  
  -- Active provider
  status_text = status_text .. "Active provider: " .. (status.active_provider or "none") .. "\n"
  status_text = status_text .. "Current request: " .. (status.current_request and "in progress" or "none") .. "\n"
  
  M.add_message("system", status_text)
end

-- Handle context commands
function M.handle_context_command(args)
  local context = require("llm-agent.context")
  local subcmd, rest = args:match("^(%w+)%s*(.*)")
  
  if not subcmd then
    -- Just show context
    context.list()
    return
  end
  
  if subcmd == "add" then
    local pattern = rest ~= "" and rest or vim.fn.expand("%:p")
    local success = context.add(pattern)
    if success then
      M.add_message("system", "Added to context: " .. pattern)
    else
      M.add_message("system", "Failed to add to context: " .. pattern)
    end
  elseif subcmd == "remove" then
    local pattern = rest
    if pattern and pattern ~= "" then
      local success = context.remove(pattern)
      if success then
        M.add_message("system", "Removed from context: " .. pattern)
      else
        M.add_message("system", "Failed to remove from context: " .. pattern)
      end
    else
      M.add_message("system", "Please specify a pattern to remove")
    end
  elseif subcmd == "list" then
    context.list()
  elseif subcmd == "clear" then
    context.clear()
    M.add_message("system", "Context cleared")
  elseif subcmd == "save" then
    local name = rest
    if name and name ~= "" then
      context.save_preset(name)
      M.add_message("system", "Context saved as preset: " .. name)
    else
      M.add_message("system", "Please specify a name for the preset")
    end
  elseif subcmd == "load" then
    local name = rest
    if name and name ~= "" then
      local success = context.load_preset(name)
      if success then
        M.add_message("system", "Loaded context preset: " .. name)
      else
        M.add_message("system", "Failed to load context preset: " .. name)
      end
    else
      M.add_message("system", "Please specify a preset name to load")
    end
  else
    M.add_message("system", "Unknown context subcommand: " .. subcmd)
  end
end

-- Show help information
function M.show_help()
  local help_text = [[
LLM Agent Commands:

/context add <pattern>  - Add file(s) to context
/context remove <pattern> - Remove file(s) from context
/context list           - List files in context
/context clear          - Clear context
/context save <name>    - Save context as preset
/context load <name>    - Load context preset
/clear                  - Clear chat history
/status                 - Show API connection status
/help                   - Show this help
]]

  M.add_message("system", help_text)
end

-- Navigate input history
function M.next_history()
  if #M._state.input_history == 0 then
    return
  end
  
  -- Get current input and save it if we're at the end
  if M._state.input_index > #M._state.input_history then
    local lines = vim.api.nvim_buf_get_lines(M._state.input_buf, 0, -1, false)
    local current = table.concat(lines, "\n")
    if not current:match("^%s*$") then
      M._state.current_input = current
    end
  end
  
  -- Move to next item
  M._state.input_index = math.min(M._state.input_index + 1, #M._state.input_history + 1)
  
  -- Set input text
  if M._state.input_index <= #M._state.input_history then
    local history_item = M._state.input_history[M._state.input_index]
    local lines = vim.split(history_item, "\n")
    vim.api.nvim_buf_set_lines(M._state.input_buf, 0, -1, false, lines)
    
    -- Move cursor to end
    local last_line = #lines
    local last_col = #lines[last_line]
    vim.api.nvim_win_set_cursor(M._state.input_win, {last_line, last_col})
  else
    -- At the end, restore current input or clear
    local lines = M._state.current_input and vim.split(M._state.current_input, "\n") or {""}
    vim.api.nvim_buf_set_lines(M._state.input_buf, 0, -1, false, lines)
    
    -- Move cursor to end
    local last_line = #lines
    local last_col = #lines[last_line]
    vim.api.nvim_win_set_cursor(M._state.input_win, {last_line, last_col})
  end
end

-- Navigate input history backwards
function M.prev_history()
  if #M._state.input_history == 0 then
    return
  end
  
  -- Get current input and save it if we're at the end
  if M._state.input_index > #M._state.input_history then
    local lines = vim.api.nvim_buf_get_lines(M._state.input_buf, 0, -1, false)
    local current = table.concat(lines, "\n")
    if not current:match("^%s*$") then
      M._state.current_input = current
    end
  end
  
  -- Move to previous item
  M._state.input_index = math.max(M._state.input_index - 1, 1)
  
  -- Set input text
  local history_item = M._state.input_history[M._state.input_index]
  local lines = vim.split(history_item, "\n")
  vim.api.nvim_buf_set_lines(M._state.input_buf, 0, -1, false, lines)
  
  -- Move cursor to end
  local last_line = #lines
  local last_col = #lines[last_line]
  vim.api.nvim_win_set_cursor(M._state.input_win, {last_line, last_col})
end

-- Cancel current request
function M.cancel_request()
  if M._state.current_request then
    -- Cancel API request
    api.cancel_request()
    
    -- Update last message if we were streaming
    if M._state.streaming then
      -- Replace "thinking" or partial message with cancellation notice
      if M._state.last_response ~= "" then
        -- Append cancellation notice to partial response
        M._state.messages[#M._state.messages] = {
          role = "assistant",
          content = M._state.last_response .. "\n\n_Request cancelled_",
          timestamp = os.time()
        }
      else
        -- Replace "thinking" message with cancellation notice
        M._state.messages[#M._state.messages] = {
          role = "system",
          content = "Request cancelled",
          timestamp = os.time()
        }
      }
    else
      -- Add cancellation message
      M.add_message("system", "Request cancelled")
    end
    
    -- Reset state
    M._state.streaming = false
    M._state.current_request = nil
    M._state.last_response = ""
    
    -- Re-render
    M.render_messages()
  end
end

-- Render message history
function M.render_messages()
  -- Skip if chat buffer is not valid
  if not M._state.chat_buf or not vim.api.nvim_buf_is_valid(M._state.chat_buf) then
    return
  end
  
  local lines = {}
  
  -- Add welcome message if no messages
  if #M._state.messages == 0 then
    table.insert(lines, "# LLM Agent Chat")
    table.insert(lines, "")
    table.insert(lines, "Type your message below or use a / command.")
    table.insert(lines, "Type /help for available commands.")
    table.insert(lines, "")
  else
    -- Render each message
    for i, msg in ipairs(M._state.messages) do
      -- Add separator
      if i > 1 then
        table.insert(lines, string.rep("-", 80))
      end
      
      -- Add header with role
      local role_display = msg.role:sub(1, 1):upper() .. msg.role:sub(2)
      table.insert(lines, role_display .. ":")
      table.insert(lines, "")
      
      -- Add content
      local content_lines = vim.split(msg.content, "\n")
      for _, line in ipairs(content_lines) do
        table.insert(lines, line)
      end
      
      table.insert(lines, "")
    end
  end
  
  -- Add API status indicator if applicable
  local status = api.get_status()
  if status.active_provider then
    local status_line = "Provider: " .. status.active_provider
    if status.current_request then
      status_line = status_line .. " (request in progress)"
    end
    table.insert(lines, status_line)
  end
  
  -- Update buffer
  vim.api.nvim_buf_set_option(M._state.chat_buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(M._state.chat_buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(M._state.chat_buf, 'modifiable', false)
  
  -- Auto-scroll to bottom if configured
  local global_config = require("llm-agent")._config or config
  if global_config.ui.auto_scroll then
    vim.api.nvim_win_set_cursor(M._state.chat_win, {#lines, 0})
  end
end

return M 
-- ~/.config/nvim/lua/llm_agent_new/init.lua
local M = {}

-- Plugin version
M._VERSION = "0.1.0"

-- Default configuration
M.default_config = {
  debug = false,
  ui = {
    width = 80,
    height = 20,
    position = "right", -- Note: Position not used by current basic UI
    border = 'single'
  },
  api = {
    provider = "ollama",
    openrouter = {
      api_key = "",
      model = "gpt-3.5-turbo"
    },
    ollama = {
      enabled = true,
      host = "localhost:11434",
      model = "gemma3:4b"
    }
  }
}

-- Plugin state
M._config = {}
local ui_module = nil
local api_module = nil

-- Function to handle sending message and receiving response
local function handle_send_message(messages)
  if not api_module then
    vim.notify("LLM Agent Error: API module not loaded.", vim.log.levels.ERROR)
    return
  end

  api_module.send_request(messages, function(response)
    if response.success then
      if ui_module and ui_module.append_message then
          ui_module.append_message("Assistant", response.content) -- Pass only role/content
      else
          vim.notify("LLM Agent Error: UI module or append_message not available.", vim.log.levels.ERROR)
      end
    else
      vim.notify("LLM Agent Error: API request failed: " .. (response.error or "Unknown error"), vim.log.levels.ERROR)
      if ui_module and ui_module.append_message then
          ui_module.append_message("Error", "API request failed: " .. (response.error or "Unknown error"))
      end
    end
  end)
end

-- Setup function
function M.setup(opts)
  M._config = vim.tbl_deep_extend("force", M.default_config, opts or {})
  
  -- Load UI module
  local ui_ok, ui = pcall(require, 'llm_agent_new.ui')
  if not ui_ok then
    vim.notify("LLM Agent: Failed to load UI module: " .. tostring(ui), vim.log.levels.ERROR)
  else
    ui_module = ui
  end
  
  -- Load API module
  local api_ok, api = pcall(require, 'llm_agent_new.api')
  if not api_ok then
    vim.notify("LLM Agent: Failed to load API module: " .. tostring(api), vim.log.levels.ERROR)
  else
    -- Pass the *entire* config table to API setup, which now includes the debug flag
    local api_setup_ok = pcall(api.setup, M._config.api)
    if not api_setup_ok then
      vim.notify("LLM Agent: Failed to setup API module.", vim.log.levels.ERROR)
    else
      api_module = api
    end
  end

  -- Remove commands, add keymap
  -- Ensure keymap is set only after modules are loaded
  if ui_module and ui_module.toggle_chat_window then
      vim.api.nvim_set_keymap('n', '<Leader>ac', ':lua require("llm_agent_new").toggle_chat()<CR>', 
          { noremap = true, silent = true, desc = "Toggle LLM Agent Chat" })
  else
      vim.notify("LLM Agent: Failed to set up toggle keymap, UI module not ready.", vim.log.levels.WARN)
  end

  -- Keep API test command for debugging
  vim.api.nvim_create_user_command("LLMAgentTestAPI", function()
    if api_module then
      api_module.send_request({"Test message from TestAPI"}, function(response)
        if response.success then
          vim.notify("API Test Success: " .. response.content)
        else
           vim.notify("API Test Error: " .. response.error, vim.log.levels.ERROR)
        end
      end)
    else
      vim.notify("LLM Agent: API module not loaded.", vim.log.levels.WARN)
    end
  end, {})
  
  return M
end

-- Global function accessible by the keymap
function M.toggle_chat()
    if ui_module and ui_module.toggle_chat_window then
        -- Pass config and callback only if needed (e.g., on first open)
        -- The UI module now stores these internally
        ui_module.toggle_chat_window(M._config.ui, handle_send_message)
    else
        vim.notify("LLM Agent Error: UI module not loaded or toggle function missing.", vim.log.levels.ERROR)
    end
end

return M
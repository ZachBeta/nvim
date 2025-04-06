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
      vim.notify("Received API response, appending to UI...", vim.log.levels.DEBUG)
      if ui_module and ui_module.append_message then
          -- Need the buffer number; ideally UI module manages its own state
          -- For now, let's assume append_message knows the buffer
          ui_module.append_message(nil, "Assistant", response.content) -- Pass nil bufnr, let UI handle it
      else
          vim.notify("LLM Agent Error: UI module or append_message not available.", vim.log.levels.ERROR)
      end
    else
      vim.notify("LLM Agent Error: API request failed: " .. (response.error or "Unknown error"), vim.log.levels.ERROR)
      -- Optionally display error in chat window too
      if ui_module and ui_module.append_message then
          ui_module.append_message(nil, "Error", "API request failed: " .. (response.error or "Unknown error"))
      end
    end
  end)
end

-- Setup function
function M.setup(opts)
  -- Merge user config with defaults
  M._config = vim.tbl_deep_extend("force", M.default_config, opts or {})
  
  -- Load UI module
  local ui_ok, ui = pcall(require, 'llm_agent_new.ui')
  if not ui_ok then
    vim.notify("LLM Agent: Failed to load UI module: " .. tostring(ui), vim.log.levels.ERROR)
    -- Decide if we should continue without UI or return
  else
    ui_module = ui
  end
  
  -- Load API module
  local api_ok, api = pcall(require, 'llm_agent_new.api')
  if not api_ok then
    vim.notify("LLM Agent: Failed to load API module: " .. tostring(api), vim.log.levels.ERROR)
    -- Decide if we should continue without API or return
  else
    -- Initialize API module with its specific config section
    local api_setup_ok = pcall(api.setup, M._config.api)
    if not api_setup_ok then
      vim.notify("LLM Agent: Failed to setup API module.", vim.log.levels.ERROR)
      -- Decide if we should continue
    else
      api_module = api
    end
  end

  -- Load commands
  local cmd_success, cmd_err = pcall(function()
    vim.api.nvim_create_user_command("LLMAgentChat", function()
      if ui_module and ui_module.setup_chat_window then
        -- Pass the handle_send_message function as the callback
        ui_module.setup_chat_window(M._config.ui, handle_send_message)
      else
        vim.notify("LLM Agent Error: UI module or setup_chat_window not available.", vim.log.levels.ERROR)
      end
    end, {})
    
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
  end)
  
  if not cmd_success then
    vim.notify("LLM Agent: Error setting up commands: " .. tostring(cmd_err), vim.log.levels.ERROR)
  end
  
  return M
end

return M
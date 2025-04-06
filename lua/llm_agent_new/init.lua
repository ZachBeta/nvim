-- ~/.config/nvim/lua/llm_agent_new/init.lua
local M = {}

-- Plugin version
M._VERSION = "0.1.0"

-- Default configuration
M.default_config = {
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
      if ui_module then
        ui_module.open_chat_window(M._config.ui)
      else
        vim.notify("LLM Agent: UI module not loaded.", vim.log.levels.WARN)
      end
    end, {})
    
    -- Example command to test API (placeholder)
    vim.api.nvim_create_user_command("LLMAgentTestAPI", function()
      if api_module then
        api_module.send_request({"Test message"}, function(response)
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
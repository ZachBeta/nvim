-- ~/.config/nvim/lua/llm_agent_new/init.lua
local M = {}

-- Plugin version
M._VERSION = "0.1.0"

-- Default configuration
M.default_config = {
  ui = {
    width = 80,
    height = 20,
    position = "right"
  },
  api = {
    provider = "openrouter",
    openrouter = {
      api_key = "",
      model = "gpt-3.5-turbo"
    },
    ollama = {
      enabled = true,
      host = "localhost:11434",
      model = "llama2"
    }
  }
}

-- Plugin state
M._config = {}

-- Setup function
function M.setup(opts)
  -- Merge user config with defaults
  M._config = vim.tbl_deep_extend("force", M.default_config, opts or {})
  
  -- Load commands (simplified)
  local success, err = pcall(function()
    -- Register basic command
    vim.api.nvim_create_user_command("LLMAgentChat", function()
      print("Chat command executed - UI not yet implemented")
    end, {})
  end)
  
  if not success then
    vim.notify("LLM Agent: Error setting up commands: " .. tostring(err), vim.log.levels.ERROR)
  end
  
  return M
end

return M
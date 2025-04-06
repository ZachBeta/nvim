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
local ui_module = nil

-- Setup function
function M.setup(opts)
  -- Merge user config with defaults
  M._config = vim.tbl_deep_extend("force", M.default_config, opts or {})
  
  -- Load modules lazily (or require directly if simple)
  local ui_ok, ui = pcall(require, 'llm_agent_new.ui')
  if not ui_ok then
    vim.notify("LLM Agent: Failed to load UI module: " .. tostring(ui), vim.log.levels.ERROR)
    return M -- Return early if UI can't load
  else
    ui_module = ui
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
  end)
  
  if not cmd_success then
    vim.notify("LLM Agent: Error setting up commands: " .. tostring(cmd_err), vim.log.levels.ERROR)
  end
  
  return M
end

return M
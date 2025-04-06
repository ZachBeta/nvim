-- llm-agent/init.lua
-- Neovim LLM Agent: A context-aware AI assistant for Neovim

local M = {}

-- Plugin version
M.version = "0.1.0"

-- Default configuration (will be overridden by user config)
local default_config = require("llm-agent.config").defaults

-- Internal state
M._initialized = false
M._config = {}

-- Setup function (called by user)
function M.setup(opts)
  -- Don't initialize twice
  if M._initialized then
    return
  end

  -- Merge user config with defaults
  M._config = vim.tbl_deep_extend("force", default_config, opts or {})
  
  -- Initialize components
  require("llm-agent.commands").setup(M._config)
  
  -- Mark as initialized
  M._initialized = true
  
  -- Log initialization
  if M._config.debug then
    require("llm-agent.utils").log.info("LLM Agent initialized with config:", M._config)
  end
end

-- Public API
M.open_chat = function()
  require("llm-agent.ui").open_chat()
end

M.toggle_chat = function()
  require("llm-agent.ui").toggle_chat()
end

M.add_to_context = function(file_pattern)
  require("llm-agent.context").add(file_pattern)
end

M.remove_from_context = function(file_pattern)
  require("llm-agent.context").remove(file_pattern)
end

M.list_context = function()
  require("llm-agent.context").list()
end

M.clear_context = function()
  require("llm-agent.context").clear()
end

return M 
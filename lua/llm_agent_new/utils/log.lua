-- ~/.config/nvim/lua/llm_agent_new/utils/log.lua

local M = {}

local config = {
  level = vim.log.levels.INFO, -- Default log level
  prefix = "[LLMAgent] ",
}

-- Function to configure the logger
function M.setup(opts)
  if opts then
    config.level = opts.level or config.level
    config.prefix = opts.prefix or config.prefix
  end
end

-- Internal log function
local function log(level, ...)
  if level >= config.level then
    local args = {...}
    local message = ""
    for i, v in ipairs(args) do
      message = message .. tostring(v)
      if i < #args then
        message = message .. " "
      end
    end
    vim.notify(config.prefix .. message, level)
  end
end

-- Public log functions
function M.debug(...)
  log(vim.log.levels.DEBUG, ...)
end

function M.info(...)
  log(vim.log.levels.INFO, ...)
end

function M.warn(...)
  log(vim.log.levels.WARN, ...)
end

function M.error(...)
  log(vim.log.levels.ERROR, ...)
end

return M
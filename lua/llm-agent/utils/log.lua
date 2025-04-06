-- llm-agent/utils/log.lua
-- Logging utilities for the plugin

local M = {}

-- Log levels
M.levels = {
  DEBUG = 1,
  INFO = 2,
  WARN = 3,
  ERROR = 4,
}

-- Current log level
M.level = M.levels.INFO

-- Log title prefix
M.prefix = "[LLM Agent]"

-- Enable/disable file logging
M.file_logging = false
M.log_path = vim.fn.stdpath("cache") .. "/llm-agent.log"

-- Format objects for logging
local function format_value(item)
  if type(item) == "table" then
    local result = "{"
    for k, v in pairs(item) do
      if type(k) == "string" then
        result = result .. k .. "="
      end
      result = result .. format_value(v) .. ", "
    end
    result = result .. "}"
    return result
  elseif type(item) == "string" then
    return '"' .. item .. '"'
  else
    return tostring(item)
  end
end

-- Convert all arguments to a string
local function format_message(...)
  local args = {...}
  local parts = {}
  
  for i, v in ipairs(args) do
    table.insert(parts, format_value(v))
  end
  
  return table.concat(parts, " ")
end

-- Write to log file
local function write_to_file(level_name, message)
  if not M.file_logging then
    return
  end
  
  local file = io.open(M.log_path, "a")
  if file then
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    file:write(string.format("[%s] [%s] %s %s\n", timestamp, level_name, M.prefix, message))
    file:close()
  end
end

-- Output a log message at the specified level
local function log(level, level_name, ...)
  if level < M.level then
    return
  end
  
  local message = format_message(...)
  
  -- Log to Neovim
  local hl = "Normal"
  if level == M.levels.ERROR then
    hl = "ErrorMsg"
  elseif level == M.levels.WARN then
    hl = "WarningMsg"
  elseif level == M.levels.DEBUG then
    hl = "Comment"
  end
  
  vim.api.nvim_echo({{M.prefix .. " ", hl}, {message, "Normal"}}, true, {})
  
  -- Log to file
  write_to_file(level_name, message)
end

-- Public logging functions
function M.debug(...)
  log(M.levels.DEBUG, "DEBUG", ...)
end

function M.info(...)
  log(M.levels.INFO, "INFO", ...)
end

function M.warn(...)
  log(M.levels.WARN, "WARN", ...)
end

function M.error(...)
  log(M.levels.ERROR, "ERROR", ...)
end

-- Set log level
function M.set_level(level)
  M.level = level
end

-- Enable file logging
function M.enable_file_logging(path)
  M.file_logging = true
  if path then
    M.log_path = path
  end
  
  -- Create log file and directory if they don't exist
  local dir = vim.fn.fnamemodify(M.log_path, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
  
  local file = io.open(M.log_path, "a")
  if file then
    file:write("\n" .. string.rep("-", 80) .. "\n")
    file:write(string.format("[%s] [INFO] %s Logging session started\n", os.date("%Y-%m-%d %H:%M:%S"), M.prefix))
    file:close()
  end
end

return M 
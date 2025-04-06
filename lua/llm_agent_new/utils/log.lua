-- ~/.config/nvim/lua/llm_agent_new/utils/log.lua
local M = {}

M.levels = {
  DEBUG = 1,
  INFO = 2,
  WARN = 3,
  ERROR = 4,
}

M.current_level = M.levels.INFO

function M.set_level(level)
  if type(level) == "string" then
    level = M.levels[level:upper()] or M.levels.INFO
  end
  M.current_level = level
end

function M.log(level, msg, ...)
  if type(level) == "string" then
    level = M.levels[level:upper()] or M.levels.INFO
  end
  
  if level < M.current_level then
    return
  end
  
  local level_str = "INFO"
  for k, v in pairs(M.levels) do
    if v == level then
      level_str = k
      break
    end
  end
  
  local formatted = string.format("[LLM-Agent] [%s] %s", level_str, msg)
  if select("#", ...) > 0 then
    formatted = string.format(formatted, ...)
  end
  
  vim.notify(formatted, level == M.levels.ERROR and vim.log.levels.ERROR or 
                       level == M.levels.WARN and vim.log.levels.WARN or 
                       vim.log.levels.INFO)
end

function M.debug(msg, ...) M.log(M.levels.DEBUG, msg, ...) end
function M.info(msg, ...) M.log(M.levels.INFO, msg, ...) end
function M.warn(msg, ...) M.log(M.levels.WARN, msg, ...) end
function M.error(msg, ...) M.log(M.levels.ERROR, msg, ...) end

return M
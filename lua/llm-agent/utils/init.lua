-- llm-agent/utils/init.lua
-- Utility functions for the plugin

local M = {}

-- Logging module
M.log = require("llm-agent.utils.log")

-- File handling utilities
M.file = require("llm-agent.utils.file")

-- Async utilities
M.async = require("llm-agent.utils.async")

-- General utility functions
function M.is_empty(item)
  if item == nil then
    return true
  elseif type(item) == "string" then
    return item:match("^%s*$") ~= nil
  elseif type(item) == "table" then
    return vim.tbl_isempty(item)
  end
  return false
end

-- Simple token counter (very approximate)
function M.count_tokens(text)
  if type(text) ~= "string" then
    return 0
  end
  
  -- Very rough approximation: average 4 chars per token
  -- This is not accurate but gives a ballpark figure
  return math.ceil(#text / 4)
end

-- Print a table for debugging
function M.dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '['..k..'] = ' .. M.dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

-- Escape special characters for pattern matching
function M.escape_pattern(text)
  return text:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
end

-- Get current buffer text
function M.get_current_buffer_text()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return table.concat(lines, "\n")
end

-- Get visual selection text
function M.get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)
  
  if #lines == 0 then
    return ""
  end
  
  -- Handle single line selection
  if #lines == 1 then
    return string.sub(lines[1], start_pos[3], end_pos[3])
  end
  
  -- Handle multi-line selection
  lines[1] = string.sub(lines[1], start_pos[3])
  lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
  
  return table.concat(lines, "\n")
end

return M 
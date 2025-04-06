-- llm-agent/utils/file.lua
-- File handling utilities for the plugin

local M = {}

-- Check if file exists
function M.exists(file_path)
  local stat = vim.loop.fs_stat(file_path)
  return stat and stat.type == "file"
end

-- Check if directory exists
function M.dir_exists(dir_path)
  local stat = vim.loop.fs_stat(dir_path)
  return stat and stat.type == "directory"
end

-- Create directory if it doesn't exist
function M.ensure_dir(dir_path)
  if not M.dir_exists(dir_path) then
    vim.fn.mkdir(dir_path, "p")
  end
end

-- Read file content
function M.read_file(file_path)
  if not M.exists(file_path) then
    return nil, "File does not exist: " .. file_path
  end
  
  local file = io.open(file_path, "r")
  if not file then
    return nil, "Failed to open file: " .. file_path
  end
  
  local content = file:read("*a")
  file:close()
  
  return content
end

-- Write content to file
function M.write_file(file_path, content)
  -- Create directory if it doesn't exist
  local dir = vim.fn.fnamemodify(file_path, ":h")
  M.ensure_dir(dir)
  
  local file = io.open(file_path, "w")
  if not file then
    return false, "Failed to open file for writing: " .. file_path
  end
  
  file:write(content)
  file:close()
  
  return true
end

-- Append content to file
function M.append_file(file_path, content)
  -- Create directory if it doesn't exist
  local dir = vim.fn.fnamemodify(file_path, ":h")
  M.ensure_dir(dir)
  
  local file = io.open(file_path, "a")
  if not file then
    return false, "Failed to open file for appending: " .. file_path
  end
  
  file:write(content)
  file:close()
  
  return true
end

-- Get file size in bytes
function M.get_file_size(file_path)
  local stat = vim.loop.fs_stat(file_path)
  return stat and stat.size or 0
end

-- Get file modification time
function M.get_file_mtime(file_path)
  local stat = vim.loop.fs_stat(file_path)
  return stat and stat.mtime or 0
end

-- List files in directory (non-recursive)
function M.list_files(dir_path, pattern)
  if not M.dir_exists(dir_path) then
    return {}
  end
  
  pattern = pattern or "*"
  local files = {}
  
  -- Use vim.fn.glob() to list files matching pattern
  local glob_pattern = dir_path:gsub("/$", "") .. "/" .. pattern
  local matches = vim.fn.glob(glob_pattern, true, true)
  
  for _, file in ipairs(matches) do
    if M.exists(file) then
      table.insert(files, file)
    end
  end
  
  return files
end

-- List files in directory recursively
function M.list_files_recursive(dir_path, pattern)
  if not M.dir_exists(dir_path) then
    return {}
  end
  
  pattern = pattern or "*"
  local files = {}
  
  -- Use vim.fn.globpath() to recursively list files matching pattern
  local glob_pattern = dir_path:gsub("/$", "") .. "/**/" .. pattern
  local matches = vim.fn.globpath(dir_path, "**/" .. pattern, true, true)
  
  for _, file in ipairs(matches) do
    if M.exists(file) then
      table.insert(files, file)
    end
  end
  
  return files
end

-- Check if file matches pattern
function M.matches_pattern(file_path, pattern)
  return vim.fn.match(file_path, pattern) >= 0
end

-- Check if file matches any pattern in a list
function M.matches_any_pattern(file_path, patterns)
  for _, pattern in ipairs(patterns) do
    if M.matches_pattern(file_path, pattern) then
      return true
    end
  end
  return false
end

-- Get relative path
function M.get_relative_path(file_path, base_dir)
  base_dir = base_dir or vim.fn.getcwd()
  base_dir = base_dir:gsub("/$", "") .. "/"
  
  if vim.startswith(file_path, base_dir) then
    return file_path:sub(#base_dir + 1)
  end
  
  return file_path
end

-- Serialize data to JSON and write to file
function M.write_json(file_path, data)
  local json_str = vim.fn.json_encode(data)
  return M.write_file(file_path, json_str)
end

-- Read JSON file and parse content
function M.read_json(file_path)
  local content, err = M.read_file(file_path)
  if not content then
    return nil, err
  end
  
  local ok, data = pcall(vim.fn.json_decode, content)
  if not ok then
    return nil, "Failed to parse JSON: " .. data
  end
  
  return data
end

return M 
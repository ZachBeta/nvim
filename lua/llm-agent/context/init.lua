-- llm-agent/context/init.lua
-- Context management for LLM Agent

local utils = require("llm-agent.utils")
local config = require("llm-agent.config").defaults

local M = {}

-- Internal state
M._context = {
  files = {},      -- List of file paths in context
  content = {},    -- Map of file path to content
  metadata = {},   -- Map of file path to metadata
  token_count = 0, -- Approximate token count
  presets = {},    -- Named context presets
}

-- Add a file to the context
function M.add(file_pattern)
  -- Get config from global settings
  local global_config = require("llm-agent")._config or config
  local max_files = global_config.context.max_files
  local max_tokens = global_config.context.max_tokens
  local exclude_patterns = global_config.context.exclude_patterns
  
  -- Expand the pattern to get matching files
  local matches = vim.fn.glob(file_pattern, false, true)
  
  if #matches == 0 then
    utils.log.warn("No files match pattern: " .. file_pattern)
    return false
  end
  
  local added_count = 0
  for _, file_path in ipairs(matches) do
    -- Skip if excluded by pattern
    if utils.file.matches_any_pattern(file_path, exclude_patterns) then
      utils.log.debug("Skipping excluded file: " .. file_path)
      goto continue
    end
    
    -- Skip if already in context
    if M._context.content[file_path] then
      utils.log.info("File already in context: " .. file_path)
      goto continue
    end
    
    -- Check if we've reached the max file limit
    if #M._context.files >= max_files then
      utils.log.warn("Maximum file limit reached (" .. max_files .. "). Remove files first.")
      break
    end
    
    -- Read file content
    local content, err = utils.file.read_file(file_path)
    if not content then
      utils.log.error("Failed to read file: " .. err)
      goto continue
    end
    
    -- Calculate token count
    local token_count = utils.count_tokens(content)
    
    -- Check if adding this would exceed token budget
    if M._context.token_count + token_count > max_tokens then
      utils.log.warn("Adding file would exceed token budget: " .. file_path)
      goto continue
    end
    
    -- Add file to context
    table.insert(M._context.files, file_path)
    M._context.content[file_path] = content
    M._context.metadata[file_path] = {
      size = #content,
      tokens = token_count,
      mtime = utils.file.get_file_mtime(file_path),
      added_at = os.time(),
      reason = "Manually added",
    }
    M._context.token_count = M._context.token_count + token_count
    
    utils.log.info("Added to context: " .. file_path .. " (" .. token_count .. " tokens)")
    added_count = added_count + 1
    
    ::continue::
  end
  
  -- Save context if persistence is enabled
  if global_config.context.persist then
    M._save_context()
  end
  
  return added_count > 0
end

-- Remove a file from context
function M.remove(file_pattern)
  local removed = false
  local pattern_files = {}
  
  -- Expand pattern and find matching files in context
  for i, file_path in ipairs(M._context.files) do
    if file_path:match(file_pattern) then
      table.insert(pattern_files, file_path)
    end
  end
  
  -- Remove matched files
  for _, file_path in ipairs(pattern_files) do
    for i, ctx_file in ipairs(M._context.files) do
      if ctx_file == file_path then
        table.remove(M._context.files, i)
        break
      end
    end
    
    -- Update token count
    local token_count = M._context.metadata[file_path] and M._context.metadata[file_path].tokens or 0
    M._context.token_count = M._context.token_count - token_count
    
    -- Remove from maps
    M._context.content[file_path] = nil
    M._context.metadata[file_path] = nil
    
    utils.log.info("Removed from context: " .. file_path)
    removed = true
  end
  
  -- Save context if persistence is enabled
  if config.context.persist then
    M._save_context()
  end
  
  if not removed then
    utils.log.warn("No matching files found in context: " .. file_pattern)
  end
  
  return removed
end

-- Clear all context
function M.clear()
  M._context.files = {}
  M._context.content = {}
  M._context.metadata = {}
  M._context.token_count = 0
  
  utils.log.info("Context cleared")
  
  -- Save context if persistence is enabled
  if config.context.persist then
    M._save_context()
  end
  
  return true
end

-- List files in context
function M.list()
  local lines = {
    "LLM Context Files (" .. M._context.token_count .. " tokens total):",
    string.rep("-", 80)
  }
  
  for i, file_path in ipairs(M._context.files) do
    local metadata = M._context.metadata[file_path] or {}
    local tokens = metadata.tokens or 0
    local reason = metadata.reason or ""
    
    table.insert(lines, string.format("%2d. %s (%d tokens) - %s", 
      i, file_path, tokens, reason))
  end
  
  if #M._context.files == 0 then
    table.insert(lines, "No files in context")
  end
  
  -- Display in a floating window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  
  local width = 80
  local height = #lines
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
  })
  
  -- Close on any key press
  vim.api.nvim_buf_set_keymap(buf, "n", "q", 
    ":lua vim.api.nvim_win_close(" .. win .. ", true)<CR>", 
    { noremap = true, silent = true })
  
  -- Also close on buffer leave
  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
    once = true,
  })
  
  return buf
end

-- Save context as a named preset
function M.save_preset(name)
  M._context.presets[name] = {
    files = vim.deepcopy(M._context.files),
    metadata = vim.deepcopy(M._context.metadata),
    created_at = os.time(),
  }
  
  utils.log.info("Saved context preset: " .. name)
  
  -- Save presets to disk
  local global_config = require("llm-agent")._config or config
  if global_config.context.persist then
    local presets_path = global_config.context.storage_path .. "/presets.json"
    utils.file.ensure_dir(global_config.context.storage_path)
    utils.file.write_json(presets_path, M._context.presets)
  end
  
  return true
end

-- Load a saved preset
function M.load_preset(name)
  local preset = M._context.presets[name]
  if not preset then
    utils.log.error("Preset not found: " .. name)
    return false
  end
  
  -- Clear current context
  M.clear()
  
  -- Load files from preset
  for _, file_path in ipairs(preset.files) do
    M.add(file_path)
  end
  
  utils.log.info("Loaded context preset: " .. name)
  return true
end

-- Get list of current files in context
function M.get_current_files()
  return vim.deepcopy(M._context.files)
end

-- Get list of preset names
function M.get_preset_names()
  local names = {}
  for name, _ in pairs(M._context.presets) do
    table.insert(names, name)
  end
  return names
end

-- Get a formatted context string for LLM prompts
function M.get_formatted_context()
  local lines = {}
  
  -- Add header
  table.insert(lines, "# CONTEXT\n")
  
  -- Add each file with content
  for i, file_path in ipairs(M._context.files) do
    local content = M._context.content[file_path] or ""
    local rel_path = utils.file.get_relative_path(file_path)
    
    table.insert(lines, "## FILE: " .. rel_path .. "\n")
    table.insert(lines, "```")
    table.insert(lines, content)
    table.insert(lines, "```\n")
  end
  
  return table.concat(lines, "\n")
end

-- Save context to disk
function M._save_context()
  local global_config = require("llm-agent")._config or config
  if not global_config.context.persist then
    return
  end
  
  -- Ensure directory exists
  local storage_path = global_config.context.storage_path
  utils.file.ensure_dir(storage_path)
  
  -- Save context files list
  local context_path = storage_path .. "/context.json"
  local context_data = {
    files = M._context.files,
    metadata = M._context.metadata,
    token_count = M._context.token_count,
    updated_at = os.time(),
  }
  utils.file.write_json(context_path, context_data)
  
  -- Save presets
  local presets_path = storage_path .. "/presets.json"
  utils.file.write_json(presets_path, M._context.presets)
  
  utils.log.debug("Context saved to disk")
end

-- Load context from disk
function M._load_context()
  local global_config = require("llm-agent")._config or config
  if not global_config.context.persist then
    return
  end
  
  local storage_path = global_config.context.storage_path
  if not utils.file.dir_exists(storage_path) then
    return
  end
  
  -- Load context files list
  local context_path = storage_path .. "/context.json"
  if utils.file.exists(context_path) then
    local context_data = utils.file.read_json(context_path)
    if context_data then
      -- We load files and metadata but reload actual content
      M._context.files = context_data.files or {}
      M._context.metadata = context_data.metadata or {}
      M._context.token_count = context_data.token_count or 0
      
      -- Reload file contents
      for _, file_path in ipairs(M._context.files) do
        local content, err = utils.file.read_file(file_path)
        if content then
          M._context.content[file_path] = content
        else
          utils.log.warn("Failed to load content for " .. file_path .. ": " .. (err or "unknown error"))
        end
      end
      
      utils.log.info("Loaded context from disk: " .. #M._context.files .. " files")
    end
  end
  
  -- Load presets
  local presets_path = storage_path .. "/presets.json"
  if utils.file.exists(presets_path) then
    local presets_data = utils.file.read_json(presets_path)
    if presets_data then
      M._context.presets = presets_data
      utils.log.info("Loaded " .. vim.tbl_count(M._context.presets) .. " context presets")
    end
  end
end

-- Initialize module
function M.setup()
  -- Load saved context if persistence is enabled
  M._load_context()
end

return M 
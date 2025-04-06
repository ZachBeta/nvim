-- llm-agent/commands.lua
-- Plugin commands and keymappings

local M = {}

-- Initialize command completion for context commands
local function context_cmd_complete(arg_lead, cmd_line, cursor_pos)
  local parts = vim.split(cmd_line, "%s+")
  local subcmd = parts[2]
  
  if #parts <= 2 or (#parts == 3 and cursor_pos <= #cmd_line) then
    -- Complete subcommand
    local subcmds = {"add", "remove", "list", "clear", "save", "load"}
    return vim.tbl_filter(function(item)
      return item:match("^" .. arg_lead)
    end, subcmds)
  elseif subcmd == "remove" then
    -- Complete file to remove
    local context = require("llm-agent.context").get_current_files()
    return vim.tbl_filter(function(item)
      return item:match("^" .. arg_lead)
    end, context)
  elseif subcmd == "load" or subcmd == "save" then
    -- Complete preset name
    local presets = require("llm-agent.context").get_preset_names()
    return vim.tbl_filter(function(item)
      return item:match("^" .. arg_lead)
    end, presets)
  end
  
  return {}
end

-- Register plugin commands
local function register_commands()
  -- Main chat command
  vim.api.nvim_create_user_command("LLMChat", function(opts)
    require("llm-agent.ui").open_chat()
  end, {
    desc = "Open LLM Agent chat window",
    nargs = 0,
  })
  
  -- Toggle chat command
  vim.api.nvim_create_user_command("LLMToggleChat", function(opts)
    require("llm-agent.ui").toggle_chat()
  end, {
    desc = "Toggle LLM Agent chat window",
    nargs = 0,
  })
  
  -- Context management commands
  vim.api.nvim_create_user_command("LLMContext", function(opts)
    local args = opts.fargs
    local subcmd = args[1]
    
    if subcmd == "add" then
      local pattern = args[2] or vim.fn.expand("%:p")
      require("llm-agent.context").add(pattern)
    elseif subcmd == "remove" then
      local pattern = args[2]
      if pattern then
        require("llm-agent.context").remove(pattern)
      else
        require("llm-agent.utils").log.error("Pattern required for remove command")
      end
    elseif subcmd == "list" then
      require("llm-agent.context").list()
    elseif subcmd == "clear" then
      require("llm-agent.context").clear()
    elseif subcmd == "save" then
      local name = args[2]
      if name then
        require("llm-agent.context").save_preset(name)
      else
        require("llm-agent.utils").log.error("Name required for save command")
      end
    elseif subcmd == "load" then
      local name = args[2]
      if name then
        require("llm-agent.context").load_preset(name)
      else
        require("llm-agent.utils").log.error("Name required for load command")
      end
    else
      require("llm-agent.utils").log.error("Unknown context subcommand: " .. (subcmd or ""))
    end
  end, {
    desc = "Manage LLM Agent context",
    nargs = "*",
    complete = context_cmd_complete,
  })
end

-- Set up global keymappings
local function setup_keymaps(config)
  local keymaps = config.keymaps or {}
  
  -- Global keymaps
  if keymaps.global then
    if keymaps.global.toggle_chat then
      vim.keymap.set("n", keymaps.global.toggle_chat, function()
        require("llm-agent.ui").toggle_chat()
      end, { desc = "Toggle LLM Agent chat" })
    end
  end
  
  -- Context keymaps
  if keymaps.context then
    if keymaps.context.add_file then
      vim.keymap.set("n", keymaps.context.add_file, function()
        require("llm-agent.context").add(vim.fn.expand("%:p"))
      end, { desc = "Add current file to LLM context" })
    end
    
    if keymaps.context.remove_file then
      vim.keymap.set("n", keymaps.context.remove_file, function()
        require("llm-agent.context").remove(vim.fn.expand("%:p"))
      end, { desc = "Remove current file from LLM context" })
    end
    
    if keymaps.context.clear then
      vim.keymap.set("n", keymaps.context.clear, function()
        require("llm-agent.context").clear()
      end, { desc = "Clear LLM context" })
    end
    
    if keymaps.context.list then
      vim.keymap.set("n", keymaps.context.list, function()
        require("llm-agent.context").list()
      end, { desc = "List LLM context files" })
    end
  end
end

-- Setup function
function M.setup(config)
  register_commands()
  setup_keymaps(config)
end

return M 
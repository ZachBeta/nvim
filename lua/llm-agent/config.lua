-- llm-agent/config.lua
-- Default configuration options

local M = {}

-- Default configuration
M.defaults = {
  -- Debug mode (enables detailed logging)
  debug = false,

  -- UI Configuration
  ui = {
    -- Chat window orientation: 'vertical' or 'horizontal'
    orientation = "vertical",
    
    -- Window size (percentage of screen or fixed size)
    size = {
      vertical = "30%",   -- width when vertical
      horizontal = "20%", -- height when horizontal
    },
    
    -- Window location: 'left', 'right', 'top', 'bottom'
    position = "right",
    
    -- Show line numbers in chat buffer
    show_line_numbers = false,
    
    -- Enable fancy UI elements
    fancy = true,
    
    -- Auto-scroll to bottom on new message
    auto_scroll = true,
    
    -- Highlight code blocks with treesitter
    highlight_code = true,
  },

  -- API Configuration
  api = {
    -- Primary provider (OpenRouter)
    openrouter = {
      base_url = "https://openrouter.ai/api/v1",
      api_key = vim.env.OPENROUTER_API_KEY or "", -- Use environment variable if available
      
      -- Default models to use
      models = {
        default = "anthropic/claude-3-opus-20240229",
        fallback = "anthropic/claude-3-sonnet-20240229",
        code = "openai/gpt-4-turbo",
      },
      
      -- Request parameters
      parameters = {
        temperature = 0.3,
        top_p = 0.9,
        timeout = 30, -- seconds
        stream = true, -- Stream responses
      },
    },
    
    -- Fallback provider (Ollama)
    ollama = {
      base_url = "http://localhost:11434/api",
      enabled = true, -- Enable fallback to Ollama
      
      -- Default models to use
      models = {
        default = "llama3",
        code = "codellama:latest",
      },
      
      -- Request parameters
      parameters = {
        temperature = 0.2,
        top_p = 0.9,
        timeout = 60, -- seconds
        stream = true, -- Stream responses
      },
    },
  },
  
  -- Context Management
  context = {
    -- Maximum number of files to include in context
    max_files = 10,
    
    -- Maximum token budget for context (approximated)
    max_tokens = 28000,
    
    -- Default file patterns to exclude
    exclude_patterns = {
      "node_modules/**",
      ".git/**",
      "*.min.js",
      "*.lock",
    },
    
    -- Persist context between sessions
    persist = true,
    
    -- Store context data in this location
    storage_path = vim.fn.stdpath("data") .. "/llm-agent/context",
  },
  
  -- Keybindings
  keymaps = {
    -- Global keymaps
    global = {
      toggle_chat = "<leader>lc", -- Toggle chat window
    },
    
    -- Buffer-local keymaps (for chat buffer)
    chat = {
      submit = "<CR>",        -- Submit current input
      cancel = "<C-c>",       -- Cancel current request
      scroll_down = "<C-d>",  -- Scroll down in chat history
      scroll_up = "<C-u>",    -- Scroll up in chat history
      next_history = "<C-n>", -- Next in input history
      prev_history = "<C-p>", -- Previous in input history
      close = "q",            -- Close chat window
    },
    
    -- Context management
    context = {
      add_file = "<leader>lca",    -- Add current file to context
      remove_file = "<leader>lcr", -- Remove current file from context
      clear = "<leader>lcc",       -- Clear context
      list = "<leader>lcl",        -- List context files
    },
  },
}

return M 
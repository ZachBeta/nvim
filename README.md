# LLM Agent for Neovim

A context-aware AI assistant for Neovim with sophisticated context management similar to Cursor or Windsurf.

⚠️ **Note:** This plugin is under active development and is not yet ready for production use.

## Features

- Chat interface within Neovim
- Powerful context management
- OpenRouter API integration with Ollama fallback
- Code completion and assistance

## Requirements

- Neovim 0.7.0+
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (for async operations)
- OpenRouter API key (optional, for OpenAI/Claude models)
- Ollama (optional, for local models)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "ZachBeta/llm-agent.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("llm-agent").setup({
      -- Configuration options
      api = {
        openrouter = {
          api_key = "your_openrouter_api_key", -- or set OPENROUTER_API_KEY env var
        }
      }
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "ZachBeta/llm-agent.nvim",
  requires = { "nvim-lua/plenary.nvim" },
  config = function()
    require("llm-agent").setup({
      -- Configuration options
    })
  end
}
```

## Usage

### Basic Commands

- `:LLMChat` - Open the chat interface
- `:LLMToggleChat` - Toggle the chat interface
- `:LLMContext add [pattern]` - Add file(s) to context
- `:LLMContext remove [pattern]` - Remove file(s) from context
- `:LLMContext list` - List files in context
- `:LLMContext clear` - Clear context
- `:LLMContext save [name]` - Save context as preset
- `:LLMContext load [name]` - Load context preset

### Default Keybindings

- `<leader>lc` - Toggle chat interface
- `<leader>lca` - Add current file to context
- `<leader>lcr` - Remove current file from context
- `<leader>lcl` - List context files
- `<leader>lcc` - Clear context

### Chat Interface

- Type your queries in the input area at the bottom
- Use `/context` commands to manage context directly from chat
- Code blocks in responses are syntax highlighted
- Press `q` to close the chat window

## Configuration

Here's a configuration example with all available options:

```lua
require("llm-agent").setup({
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
      api_key = "your_openrouter_api_key", -- or use env var OPENROUTER_API_KEY
      
      -- Default models to use
      models = {
        default = "anthropic/claude-3-opus-20240229",
        fallback = "anthropic/claude-3-sonnet-20240229",
        code = "openai/gpt-4-turbo",
      },
    },
    
    -- Fallback provider (Ollama)
    ollama = {
      enabled = true, -- Enable fallback to Ollama
      
      -- Default models to use
      models = {
        default = "llama3",
        code = "codellama:latest",
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
  },
  
  -- Keybindings (all are optional)
  keymaps = {
    -- Global keymaps
    global = {
      toggle_chat = "<leader>lc", -- Toggle chat window
    },
    
    -- Context management
    context = {
      add_file = "<leader>lca",    -- Add current file to context
      remove_file = "<leader>lcr", -- Remove current file from context
      clear = "<leader>lcc",       -- Clear context
      list = "<leader>lcl",        -- List context files
    },
  },
})
```

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

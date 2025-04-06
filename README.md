# LLM Agent for Neovim (Work In Progress - MVP)

A context-aware AI assistant for Neovim.

⚠️ **Note:** This plugin is under active development as a **Minimum Viable Product (MVP)** focusing on local Ollama interaction. It is primarily intended for local development and testing. Many features described historically may not be present in the current local development version.

## Features (Current MVP)

- Basic chat interface within Neovim (right-side vertical split).
- Asynchronous communication with Ollama using `curl` via Neovim's `jobstart()`.
- Toggle keymap to show/hide/focus the chat window.

## Requirements

- Neovim 0.7.0+
- `curl` command-line tool installed.
- Ollama running locally (e.g., `ollama serve` or `ollama run <model>`)

## Installation (Local Development Setup)

This plugin is currently developed and used locally.

1.  **Clone the repository:** Clone this repository directly into your Neovim configuration's Lua path. For a standard setup, this would be:
    ```bash
    git clone <repository_url> ~/.config/nvim/lua/llm_agent_new
    ```
    *(Replace `<repository_url>` with the actual URL of your development repository. If you are already working within the cloned repo located at `~/.config/nvim`, you can skip this step.)*

2.  **Add to Packer:** Use the local path in your `packer.nvim` configuration (`init.lua` or equivalent):

    ```lua
    use {
      '~/.config/nvim/lua/llm_agent_new', -- Path to the locally cloned plugin
      as = 'llm_agent_new',
      config = function()
        require("llm_agent_new").setup()
      end,
    }
    ```

3.  **Sync Packer:** Run `:PackerSync` in Neovim.

## Usage (MVP)

- Press `<Leader>ac` (default: Space + a + c) to toggle the chat window:
    - If closed, it opens and focuses.
    - If open and focused, it hides.
    - If open and unfocused, it focuses.
- In the chat window, type your message at the `> ` prompt and press `Enter`.
- The user message and the assistant's response will appear in the buffer.
- Press `<Esc>` while in insert mode in the chat window to enter Normal mode.
- Use standard Neovim window commands (e.g., `Ctrl-W h/l/j/k`) to navigate away from the chat window when in Normal mode.

## Configuration (MVP Options)

The plugin can be configured via the `setup()` function. Only the following options are currently used by the MVP:

```lua
require("llm_agent_new").setup({
  -- Debug mode (enables detailed logging in :messages)
  debug = false, 

  -- UI Configuration
  ui = {
    width = 80, -- Width of the chat split window
  },

  -- API Configuration
  api = {
    -- Only 'ollama' provider is currently implemented
    provider = "ollama", 
    ollama = {
      enabled = true, -- Must be true to use Ollama
      host = "localhost:11434", -- Ollama API endpoint
      model = "gemma3:4b"      -- Default Ollama model to use
    }
    -- Other settings like openrouter are ignored in the MVP
  }
})
```

Ensure your Ollama server is running before use.

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

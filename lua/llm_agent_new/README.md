# LLM Agent New (MVP)

## Purpose

A minimal Neovim plugin providing a basic chat interface with an LLM, primarily designed to interact with a local Ollama instance.

## Current Status

This is a functional **Minimum Viable Product (MVP)** built following the "Hybrid Approach" outlined in `llm_agent_project_options.md`. 

Core features implemented:
- Opens a chat window as a vertical split on the right.
- Uses Neovim's native `jobstart()` to interact asynchronously with Ollama via `curl`.
- Basic conversation flow (User input -> Assistant response).
- Toggle keymap to show/hide/focus the chat window.

## Installation

This plugin is intended for local development and is loaded via Packer using a local path.

Add the following to your `init.lua` (or relevant Packer setup file):

```lua
use {
  '~/.config/nvim/lua/llm_agent_new',  -- Adjust path if your config is elsewhere
  as = 'llm_agent_new',
  config = function()
    require("llm_agent_new").setup()
  end,
}
```

Then run `:PackerSync`.

## Configuration

The plugin can be configured via the `setup()` function. Defaults are set for Ollama:

```lua
require("llm_agent_new").setup({
  debug = false, -- Set to true for verbose debug logs
  ui = {
    width = 80, -- Width of the chat split
  },
  api = {
    provider = "ollama",
    ollama = {
      enabled = true,
      host = "localhost:11434", -- Ollama API endpoint
      model = "gemma3:4b"      -- Default Ollama model
    }
    -- openrouter config is present but not implemented
  }
})
```

Ensure your Ollama server is running (`ollama serve` or `ollama run <model>`) before use.

## Usage

- Press `<Leader>ac` (default: Space + a + c) to toggle the chat window.
    - If closed, it opens and focuses.
    - If open and focused, it hides.
    - If open and unfocused, it focuses.
- In the chat window, type your message at the `> ` prompt and press `Enter`.
- The user message and the assistant's response will appear in the buffer.
- Press `<Esc>` while in insert mode in the chat window to enter Normal mode.
- Use standard Neovim window commands (e.g., `Ctrl-W h/l/j/k`) to navigate away from the chat window when in Normal mode. 
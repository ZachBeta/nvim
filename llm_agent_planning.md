# Neovim LLM Agent Planning

## Overview
An nvim-centric LLM agent for agentic code generation with sophisticated context management similar to Cursor or Windsurf.

## Core Components

### 1. Context Management System

#### Project Indexing
- Create metadata index of all project files (paths, file types, sizes)
- Perform semantic indexing using embeddings for code similarity/relevance
- Build dependency graph of codebase to understand relationships

#### Local Embedding System
- Use larger embedding models for better semantic understanding
- Implement disk-based vector database (FAISS or Chroma)
- Chunking strategies at function/class level with overlapping to preserve context
- Run indexing as async background job with incremental updates

#### Hybrid Context Selection
- **Automatic**: Include current file, semantically related files, dependencies
- **Manual**: Allow user to override via chat commands
- **Suggestions**: Agent suggests relevant files based on context

### 2. User Interface

#### Split Buffer Chat UI
- Dedicated Neovim buffer with custom filetype `llm-chat`
- Vertical or horizontal split (configurable)
- Buffer-local commands for context management
- Message formatting with markdown syntax highlighting
- Input area at bottom for user queries

#### Context Visualization
- Context summary block at top of chat (collapsible)
- Inline commands for context management
- Visual indicators for files in context
- Agent suggestions with reasoning

#### Command Interface
- `/context add <file pattern>` - Add files to context
- `/context remove <file>` - Remove file from context
- `/context clear` - Reset context to defaults
- `/context save <name>` - Save current context as preset
- `/context load <name>` - Load saved context preset
- `/context list` - Show current context files

### 3. LLM Integration

#### Provider Configuration
```lua
-- Primary: OpenRouter
local openrouter = {
  base_url = "https://openrouter.ai/api/v1",
  models = {
    default = "anthropic/claude-3-opus-20240229",
    fallback = "anthropic/claude-3-sonnet-20240229",
    code = "openai/gpt-4-turbo"
  },
  timeout = 30
}

-- Fallback: Ollama local
local ollama = {
  base_url = "http://localhost:11434/api",
  models = {
    default = "llama3",
    code = "codellama:latest"
  }
}
```

#### Context Management Implementation
```lua
local context_manager = {
  current = {}, -- currently included files
  suggested = {}, -- agent-suggested files
  history = {}, -- recently used files
  presets = {} -- saved context configurations
}

-- Function to add file to context with reason
function context_manager:add(file_path, reason)
  -- Add file content to context
  -- Update UI
end

-- Function to suggest relevant files
function context_manager:suggest()
  -- Use embeddings to find relevant files
  -- Return list with relevance scores and reasons
end
```

### 4. Implementation Phases

1. **Phase 1: Basic Chat Interface**
   - Buffer UI setup
   - OpenRouter API integration
   - Ollama fallback mechanism
   - Simple context commands

2. **Phase 2: Context Management**
   - File indexing system
   - Embedding storage and retrieval
   - Relevance ranking algorithms
   - Context visualization

3. **Phase 3: Advanced Features**
   - Code completion integration
   - Multiple conversation sessions
   - Agent memory/history
   - Context presets and templates

## Next Steps

1. Set up basic plugin structure
2. Implement chat buffer UI
3. Establish API connections to LLM providers
4. Build simple context management
5. Develop embedding and indexing system 
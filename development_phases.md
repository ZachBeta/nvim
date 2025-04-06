# Neovim LLM Agent - Phased Development Plan

## Phase 1: Basic Chat Interface

### Goals
- Establish plugin architecture 
- Create functional UI for chat interaction
- Set up API connections to LLM providers
- Implement basic context awareness

### Tasks

#### 1.1 Plugin Structure Setup
- Create plugin directory structure following Neovim conventions
- Set up configuration module with default options
- Implement lazy loading for performance
- Define public API and command interface

```lua
-- Plugin structure
/lua
  /llm-agent
    /init.lua         -- Main entry point
    /config.lua       -- Configuration options
    /ui.lua           -- UI components
    /api.lua          -- LLM API integrations
    /context.lua      -- Basic context management
    /commands.lua     -- Command definitions
    /utils.lua        -- Utility functions
```

#### 1.2 Chat Buffer UI Implementation
- Create buffer creation and management functions
- Implement syntax highlighting for chat messages
- Design input area with command parsing
- Set up keybindings for navigation and actions
- Add buffer-local commands

```lua
function create_chat_buffer()
  -- Create a new buffer with custom filetype
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'llm-chat')
  
  -- Set up buffer-local keymaps
  vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>', '<cmd>lua require("llm-agent.ui").send_message()<CR>', {})
  
  return buf
end
```

#### 1.3 OpenRouter API Integration
- Implement HTTP client for API requests
- Set up authentication and API key management
- Create request/response handling
- Implement model selection logic
- Add streaming response support

```lua
function send_to_openrouter(prompt, options)
  local headers = {
    ["Content-Type"] = "application/json",
    ["Authorization"] = "Bearer " .. config.api_key
  }
  
  local body = {
    model = options.model or config.models.default,
    messages = prompt,
    stream = options.stream or true
  }
  
  -- Make async HTTP request
  return make_request("POST", openrouter.base_url .. "/chat/completions", headers, body)
end
```

#### 1.4 Ollama Fallback Mechanism
- Set up local API connection
- Implement fallback logic and error handling
- Create model compatibility layer
- Add health check for local service

```lua
function check_ollama_available()
  -- Check if Ollama is running locally
  local result = vim.fn.system("curl -s http://localhost:11434/api/version")
  return result:match("version") ~= nil
end

function fallback_to_ollama(prompt, options)
  -- Log fallback reason
  -- Translate prompt to Ollama format
  -- Send request to local Ollama
end
```

#### 1.5 Basic Context Commands
- Implement manual file inclusion/exclusion
- Create context display command
- Add content formatting for context
- Set up persistence of context between sessions

```lua
function add_to_context(file_pattern)
  -- Find matching files
  local files = vim.fn.glob(file_pattern, false, true)
  
  -- Add each file to context
  for _, file in ipairs(files) do
    context_manager:add(file, "Manually added")
  end
  
  -- Update UI
  update_context_display()
end
```

### Deliverables
- Functional chat interface with split-window layout
- Working API connection to OpenRouter with fallback to Ollama
- Basic context commands for adding/removing files
- Configuration options for API keys, model selection, and UI preferences

## Phase 2: Context Management

### Goals
- Build sophisticated context capture system
- Implement embedding-based relevance ranking
- Create visualization for context management
- Enhance prompt construction with selective context

### Tasks

#### 2.1 File Indexing System
- Create project scanner to find all files
- Build metadata store for file information
- Implement file type detection and filtering
- Add incremental indexing on file changes
- Set up persistence for index data

```lua
function scan_project()
  local files = {}
  local ignored_patterns = config.ignored_patterns or {".git", "node_modules"}
  
  -- Use plenary.scandir or similar to recursively scan
  -- Filter files based on size, type, ignored patterns
  -- Store metadata about each file
  
  return files
end
```

#### 2.2 Embedding System Implementation
- Integrate with local embedding model
- Implement chunking strategies for code
- Set up vector storage and retrieval
- Create background embedding process
- Add cache mechanism for performance

```lua
function embed_file(file_path)
  -- Read file content
  local content = read_file(file_path)
  
  -- Split into chunks
  local chunks = split_into_chunks(content, config.chunk_size, config.chunk_overlap)
  
  -- Generate embeddings for each chunk
  for i, chunk in ipairs(chunks) do
    local embedding = generate_embedding(chunk)
    store_embedding(file_path, i, chunk, embedding)
  end
end
```

#### 2.3 Relevance Ranking Algorithms
- Implement semantic similarity search
- Create ranking system based on multiple factors
- Add recency and frequency weighting
- Build dependency-aware relevance boost
- Implement filtering and sorting algorithms

```lua
function find_relevant_files(query, current_file, limit)
  -- Generate embedding for query
  local query_embedding = generate_embedding(query)
  
  -- Search for similar chunks
  local results = vector_db:search(query_embedding, limit * 3)
  
  -- Apply additional ranking factors
  results = apply_ranking_factors(results, {
    current_file = current_file,
    recency = get_recently_used_files(),
    dependencies = get_dependencies(current_file)
  })
  
  -- Return top results
  return table.slice(results, 1, limit)
end
```

#### 2.4 Context Visualization
- Design collapsible context summary
- Implement file status indicators
- Create interactive context management UI
- Add tooltips with relevance explanations
- Support drag-and-drop reordering of context

```lua
function render_context_summary()
  local lines = {"# Context"}
  
  -- Add header
  table.insert(lines, string.format("- %d files included (%d tokens)", 
    #context_manager.current, count_tokens(context_manager.current)))
  
  -- Add current files with indicators
  for i, file in ipairs(context_manager.current) do
    local indicator = get_indicator_for_file(file)
    table.insert(lines, string.format("%s %s [%.2f relevance]", indicator, file.path, file.relevance))
  end
  
  -- Render to buffer
  render_markdown_to_region(lines, context_region)
end
```

#### 2.5 Advanced Context Commands
- Implement pattern-based file selection
- Add context presets saving/loading
- Create automatic context suggestions
- Implement context size management
- Add token counting and optimization

```lua
function suggest_context_additions(query)
  -- Find relevant files not in context
  local relevant = find_relevant_files(query, vim.fn.expand("%:p"), 5)
  
  -- Filter to files not already in context
  local suggestions = {}
  for _, file in ipairs(relevant) do
    if not is_in_context(file.path) then
      table.insert(suggestions, {
        path = file.path,
        reason = file.match_reason,
        relevance = file.relevance
      })
    end
  end
  
  return suggestions
end
```

### Deliverables
- Complete file indexing and embedding system
- Relevance-based context suggestions
- Visual context management in chat interface
- Preset management for different tasks
- Token optimization for context

## Phase 3: Advanced Features

### Goals
- Integrate with code completion
- Support multiple conversation sessions
- Implement agent memory/history
- Create templates and specialized agents

### Tasks

#### 3.1 Code Completion Integration
- Implement omnifunc for completion
- Create context-aware completion provider
- Add inline code suggestions
- Build completion acceptance mechanisms
- Implement post-completion formatting

```lua
function setup_completion()
  -- Set omnifunc for supported filetypes
  for _, ft in ipairs(config.completion_filetypes) do
    vim.api.nvim_create_autocmd("FileType", {
      pattern = ft,
      callback = function()
        vim.bo.omnifunc = "v:lua.require'llm-agent.completion'.omnifunc"
      end
    })
  end
end

function omnifunc(findstart, base)
  if findstart == 1 then
    -- Find start of completion
    return find_completion_start()
  else
    -- Generate completions
    return generate_completions(base)
  end
end
```

#### 3.2 Multiple Conversation Sessions
- Implement session management
- Create session switching UI
- Add session naming and organization
- Implement session-specific context
- Add export/import functionality

```lua
function create_new_session(name)
  local session = {
    id = generate_id(),
    name = name or "Session " .. #sessions + 1,
    messages = {},
    context = table.deepcopy(context_manager.current),
    created_at = os.time(),
    buffer = nil
  }
  
  table.insert(sessions, session)
  return session
end

function switch_to_session(session_id)
  -- Save current session state
  save_current_session()
  
  -- Load target session
  current_session = get_session_by_id(session_id)
  
  -- Create buffer if needed or switch to existing
  if not current_session.buffer or not vim.api.nvim_buf_is_valid(current_session.buffer) then
    current_session.buffer = create_chat_buffer()
  end
  
  -- Load session content
  load_session_content(current_session)
  
  -- Restore session context
  context_manager.current = table.deepcopy(current_session.context)
end
```

#### 3.3 Agent Memory and History
- Implement long-term memory storage
- Create summarization for history
- Add cross-session knowledge base
- Implement memory search/retrieval
- Create forgetting mechanisms

```lua
function add_to_memory(entry)
  -- Generate embedding for memory entry
  local embedding = generate_embedding(entry.content)
  
  -- Store in memory database
  memory_db:add({
    content = entry.content,
    embedding = embedding,
    type = entry.type,
    timestamp = os.time(),
    session_id = entry.session_id,
    metadata = entry.metadata
  })
end

function retrieve_relevant_memories(query, limit)
  -- Generate embedding for query
  local query_embedding = generate_embedding(query)
  
  -- Search memory for relevant entries
  return memory_db:search(query_embedding, limit)
end
```

#### 3.4 Context Templates and Specialized Agents
- Create template system for common tasks
- Implement specialized agents (debug, refactor, doc)
- Add domain-specific prompt engineering
- Create workflows for common development tasks
- Implement agent personality configuration

```lua
function load_template(template_name)
  local template = config.templates[template_name]
  if not template then
    error("Template not found: " .. template_name)
  end
  
  -- Create new session with template
  local session = create_new_session(template.name)
  
  -- Set up context based on template
  if template.context_patterns then
    for _, pattern in ipairs(template.context_patterns) do
      add_to_context(pattern)
    end
  end
  
  -- Add system message
  add_message(session.id, {
    role = "system",
    content = template.system_message
  })
  
  -- Switch to the new session
  switch_to_session(session.id)
  
  return session
end
```

### Deliverables
- Code completion integration with context awareness
- Multiple session support with session management UI
- Long-term memory with relevance-based retrieval
- Template system for specialized agents
- Workflow automation for common tasks

## Phase 4: Polish and Optimization

### Goals
- Optimize performance for large codebases
- Enhance UI/UX for seamless workflow integration
- Add extensive customization options
- Implement comprehensive error handling
- Create thorough documentation

### Tasks

#### 4.1 Performance Optimization
- Implement lazy loading of components
- Add caching strategies for embeddings and API calls
- Optimize context selection algorithms
- Implement background processing for indexing
- Add resource usage monitoring

#### 4.2 UI/UX Enhancements
- Implement smooth animations and transitions
- Add keyboard shortcuts for all operations
- Create status line integration
- Implement floating UI components
- Add accessibility features

#### 4.3 Customization Options
- Create comprehensive configuration system
- Add theming support
- Implement plugin extension API
- Create custom prompt templates
- Add user-defined commands and shortcuts

#### 4.4 Error Handling and Resilience
- Implement comprehensive error handling
- Add retry mechanisms for API failures
- Create fallback strategies for all operations
- Implement logging and diagnostics
- Add self-healing mechanisms

#### 4.5 Documentation and Examples
- Create comprehensive user documentation
- Add developer documentation for extension
- Create example configurations and templates
- Add tutorials for common workflows
- Implement help system within the plugin

### Deliverables
- Optimized performance for large codebases
- Polished UI/UX with smooth workflow integration
- Comprehensive customization options
- Resilient error handling and recovery
- Complete documentation and examples

## Implementation Timeline

### Phase 1: Basic Chat Interface
- Duration: 2-3 weeks
- Dependencies: None
- Key milestone: Functional chat with basic API integration

### Phase 2: Context Management
- Duration: 3-4 weeks
- Dependencies: Phase 1
- Key milestone: Embedding-based context suggestions working

### Phase 3: Advanced Features
- Duration: 4-6 weeks
- Dependencies: Phase 2
- Key milestone: Multiple sessions with specialized agents

### Phase 4: Polish and Optimization
- Duration: 2-3 weeks
- Dependencies: Phase 3
- Key milestone: Production-ready plugin with documentation

## Testing Strategy

### Unit Testing
- Test all utility functions
- Test API integration with mocks
- Test context management algorithms
- Test UI rendering functions

### Integration Testing
- Test full workflow scenarios
- Test fallback mechanisms
- Test session management
- Test embedding and indexing system

### Performance Testing
- Test with large codebases (>100k LOC)
- Test embedding generation performance
- Test API response handling
- Test UI rendering performance

### User Testing
- Get feedback on UI/UX
- Test with different workflow styles
- Test with different programming languages
- Test with different project structures 
# LLM Agent Test Plan

This document outlines the test scenarios for verifying the functionality of the LLM Agent plugin for Neovim.

## Summary and Test Priorities

This test plan covers all major aspects of the LLM Agent plugin. Testing should prioritize these key areas:

1. **Critical Path**: Basic chat functionality, API connectivity, and context management
2. **Core Features**: Message sending/receiving, context commands, and command interface
3. **Edge Cases**: Error handling, large contexts, and performance under load
4. **Integration**: Workflows with real coding tasks and Neovim integration

### Priority Matrix

| Priority | Feature Area | Impact | Complexity |
|----------|--------------|--------|------------|
| P0 | Chat & API Connectivity | High | Medium |
| P0 | Context Management | High | Medium |
| P1 | Command Interface | Medium | Low |
| P1 | UI Responsiveness | Medium | Medium |
| P2 | Edge Cases | Medium | High |
| P2 | Integration Workflows | High | High |
| P3 | CI/CD Pipeline | Low | High |

## 1. Installation and Setup

### 1.1 Plugin Installation

- [ ] Install plugin using lazy.nvim
  - Add configuration to lazy.nvim config
  - Run `:Lazy sync` to install
  - Verify no errors during installation

- [ ] Install plugin using packer.nvim
  - Add configuration to packer.nvim config
  - Run `:PackerSync` to install
  - Verify no errors during installation

### 1.2 Configuration Verification

- [ ] Set up with default configuration
  - Run plugin with minimal configuration
  - Verify defaults are applied correctly

- [ ] Set up with custom configuration
  - Configure custom API keys
  - Set custom UI options
  - Verify custom settings are applied

### 1.3 API Connectivity

- [ ] Test OpenRouter connectivity
  - Set valid OpenRouter API key
  - Open chat interface
  - Verify connection status shows "ready"

- [ ] Test Ollama connectivity
  - Install and run Ollama locally
  - Verify connection to local Ollama instance
  - Check fallback functionality when OpenRouter is unavailable

## 2. Chat Interface

### 2.1 Opening/Closing Chat

- [ ] Command-based opening
  - Run `:LLMChat` command
  - Verify chat window opens with correct dimensions and position

- [ ] Keybinding-based opening
  - Press `<leader>lc` (default keybinding)
  - Verify chat window opens correctly

- [ ] Closing chat interface
  - Press `q` in chat window
  - Verify chat window closes
  - Re-open and close using `:q` command

- [ ] Toggle functionality
  - Run `:LLMToggleChat` command
  - Verify window opens
  - Run command again and verify window closes

### 2.2 Chat Window Layout

- [ ] Verify vertical layout
  - Set `orientation = "vertical"` in config
  - Open chat and verify layout position
  - Test different width settings

- [ ] Verify horizontal layout
  - Set `orientation = "horizontal"` in config
  - Open chat and verify layout position
  - Test different height settings

- [ ] Verify window positions
  - Test with `position = "right"` (default)
  - Test with `position = "left"`
  - Test with `position = "top"` (horizontal mode)
  - Test with `position = "bottom"` (horizontal mode)

### 2.3 Basic Conversation

- [ ] Send simple message
  - Type text in input area
  - Press Enter to send
  - Verify message appears in chat
  - Verify assistant responds
  
- [ ] Message history navigation
  - Send multiple messages
  - Use Ctrl-n/Ctrl-p to navigate history
  - Verify correct history entries are displayed
  
- [ ] Cancel request
  - Send a message
  - Press Ctrl-c during response generation
  - Verify request is cancelled and indicated in UI

## 3. Context Management

### 3.1 Adding Files to Context

- [ ] Add current file
  - Open a file in Neovim
  - Use `/context add` in chat
  - Verify file is added to context
  
- [ ] Add file with pattern
  - Use `/context add *.lua` in chat
  - Verify matching files are added to context
  
- [ ] Add file with keybinding
  - Open a file
  - Press `<leader>lca`
  - Verify file is added to context

### 3.2 Managing Context

- [ ] List context
  - Add several files to context
  - Run `/context list` in chat
  - Verify all files are displayed with token counts
  
- [ ] Remove file from context
  - Use `/context remove <file>` command
  - Verify file is removed from context list
  
- [ ] Clear context
  - Add several files to context
  - Run `/context clear` command
  - Verify all files are removed from context

### 3.3 Context Presets

- [ ] Save context preset
  - Add files to context
  - Use `/context save mypreset` command
  - Verify success message
  
- [ ] Load context preset
  - Clear context
  - Use `/context load mypreset` command
  - Verify files from preset are loaded into context

## 4. API Functionality

### 4.1 OpenRouter Integration

- [ ] Send message using OpenRouter
  - Configure valid OpenRouter API key
  - Send a message in chat
  - Verify response is received from specified model
  
- [ ] Model switching
  - Test different model configurations
  - Verify model changes are applied

### 4.2 Ollama Integration

- [ ] Send message using Ollama
  - Disable OpenRouter or set invalid API key
  - Verify fallback to Ollama
  - Send a message and verify response
  
- [ ] Test with different Ollama models
  - Configure different models in settings
  - Verify correct model is used

### 4.3 Response Streaming

- [ ] Test streaming with OpenRouter
  - Send a message
  - Verify response appears incrementally
  - Check final response is complete
  
- [ ] Test streaming with Ollama
  - Switch to Ollama
  - Send a message
  - Verify response appears incrementally

## 5. Command Interface

### 5.1 Command Execution

- [ ] Test `:LLMChat` command
  - Run command in Neovim
  - Verify chat window opens
  
- [ ] Test `:LLMContext` commands
  - Run `:LLMContext add %` to add current file
  - Run `:LLMContext list` to show context
  - Run `:LLMContext remove %` to remove current file
  - Run `:LLMContext clear` to clear context

### 5.2 Command Completion

- [ ] Test tab completion for commands
  - Type `:LLMContext` and press Tab
  - Verify subcommands are shown
  - Type partial subcommand and verify completion

### 5.3 Chat Commands

- [ ] Test help command
  - Type `/help` in chat
  - Verify help information is displayed
  
- [ ] Test status command
  - Type `/status` in chat
  - Verify API status information is displayed

## 6. Edge Cases and Error Handling

### 6.1 Connection Issues

- [ ] Test behavior with invalid API keys
  - Set invalid OpenRouter API key
  - Verify appropriate error message
  - Check fallback to Ollama if configured

- [ ] Test with no internet connection
  - Disconnect from internet
  - Verify appropriate error handling

### 6.2 Large Context Handling

- [ ] Test with large files
  - Add very large files to context
  - Verify token limiting works correctly
  - Verify context management remains responsive

### 6.3 Long Conversations

- [ ] Test with many messages
  - Send many messages back and forth
  - Verify UI remains responsive
  - Check history navigation works with many messages

## 7. Performance Testing

### 7.1 Startup Time

- [ ] Measure plugin load time
  - Start Neovim with and without plugin
  - Compare startup time difference
  - Verify lazy loading works as expected

### 7.2 Memory Usage

- [ ] Monitor memory usage
  - Run Neovim with plugin active
  - Monitor memory usage during extended use
  - Check for memory leaks with extensive use

### 7.3 UI Responsiveness

- [ ] Test UI smoothness
  - Interact with chat interface rapidly
  - Verify no lag or freezing
  - Test with large responses and context

## 8. Neovim Integration Workflows

### 8.1 Coding Assistance

- [ ] Get code suggestions
  - Open a code file with incomplete function
  - Ask for completion suggestions in chat
  - Verify relevant code is generated
  - Test copying code from chat to buffer

- [ ] Debug existing code
  - Open file with buggy code
  - Add file to context
  - Ask about fixing the bug
  - Verify helpful debugging advice is provided

### 8.2 Documentation Generation

- [ ] Generate function documentation
  - Open file with undocumented functions
  - Add to context
  - Ask to generate documentation for functions
  - Verify documentation follows codebase style

- [ ] Create README or project documentation
  - Add multiple project files to context
  - Ask to generate or improve project documentation
  - Verify documentation is comprehensive and accurate

### 8.3 Refactoring Assistance

- [ ] Request refactoring suggestions
  - Add complex or messy code file to context
  - Ask for refactoring suggestions
  - Verify suggestions improve code quality
  - Test implementing suggested changes

### 8.4 Project Navigation Assistance

- [ ] Get codebase understanding help
  - Add multiple files from a project
  - Ask about project structure and organization
  - Verify response provides useful overview

- [ ] Find relevant code locations
  - Add project files to context
  - Ask where specific functionality is implemented
  - Verify response correctly identifies relevant files/functions

### 8.5 Learning Assistance

- [ ] Learn Neovim features
  - Ask about specific Neovim features
  - Verify explanation and examples are helpful
  - Try implementing suggested commands

- [ ] Learn programming concepts
  - Ask about programming concepts relevant to open file
  - Verify explanations are clear and accurate
  - Test examples provided in response

## 9. Continuous Integration and Automation

### 9.1 Unit Tests

- [ ] Set up test framework
  - Create test directory structure
  - Set up test runner with busted or similar
  - Implement basic test utilities

- [ ] Core functionality tests
  - Write tests for utility functions
  - Create tests for context management
  - Test configuration handling
  - Implement mocks for API calls

### 9.2 Integration Tests

- [ ] Create headless Neovim testing
  - Set up headless Neovim instance for testing
  - Create test scripts for simulating user actions
  - Implement assertion helpers

- [ ] API mock testing
  - Create mocks for OpenRouter and Ollama
  - Test API interaction without real services
  - Verify error handling with mock failures

### 9.3 CI Pipeline

- [ ] Set up GitHub Actions workflow
  - Create workflow definition
  - Configure test runs on PRs and pushes
  - Set up linting with luacheck

- [ ] Implement code coverage
  - Add code coverage tracking
  - Set minimum coverage thresholds
  - Generate coverage reports

### 9.4 Automated Performance Testing

- [ ] Create performance benchmarks
  - Implement startup time measurement
  - Create memory usage tests
  - Add response time benchmarks

- [ ] Regression testing
  - Compare performance metrics against baseline
  - Alert on significant regressions
  - Track performance trends over time

## Test Results Tracking

| Test ID | Description | Expected Result | Actual Result | Status | Notes |
|---------|-------------|-----------------|---------------|--------|-------|
| 1.1.1   | Install with lazy.nvim | Successful installation | | | |
| 1.2.1   | Default config test | Default settings applied | | | |
| 2.1.1   | Open chat with command | Chat window opens | | | |
| ... | ... | ... | ... | ... | ... | 
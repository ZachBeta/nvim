# Context Management Implementation Plan

## 1. Goal

Integrate context management features into the `llm-agent-new` plugin. This allows users to add files or code selections to the conversation context, which will then be included in requests sent to the LLM.

**Core Features:**
- Add current file or specific file path to context.
- Add visual selection to context.
- List items currently in context (including estimated token count).
- Remove items from context.
- Clear the entire context.
- Automatically include context in API requests.

## 2. Architecture Changes

- **Introduce `lua/llm_agent_new/context.lua`:** This new module will encapsulate all logic related to managing the context (storing items, calculating tokens, formatting for API).
- **Update `init.lua`:**
    - Load and initialize the `context.lua` module during `setup`.
    - Pass relevant configuration (e.g., token limits) to `context.setup`.
    - Make the context module accessible to the UI and API modules (potentially by passing it during their setup or storing it in the main `M` table).
    - Potentially register new top-level commands (e.g., `:LLMContextAddFile`) or keymaps that call functions in `context.lua`.
- **Update `ui.lua`:**
    - Add handling for chat commands (e.g., `/context add`, `/context list`, `/context clear`). These commands will call functions in the `context.lua` module.
    - Implement UI elements to display context information (e.g., a collapsible section or updates on `/context list`).
    - Update the `handle_send_message` callback mechanism (or similar) to ensure context is retrieved before sending.
- **Update `api.lua`:**
    - Modify `send_request` (or create a wrapper) to accept the current context string.
    - Prepend the formatted context string to the actual user prompt/messages before sending to the LLM API.

## 3. `context.lua` Module Details

- **Data Structure:** Likely a table storing context items. Each item could be a table containing `{ type = "file"|"selection", path = "...", content = "...", tokens = N }`.
- **Core Functions:**
    - `setup(config)`: Initializes the module, sets token limits.
    - `add_file(filepath)`: Reads file content, calculates tokens, adds to context if within limits.
    - `add_selection(lines)`: Adds selected text, calculates tokens, adds to context.
    - `remove_item(identifier)`: Removes an item (e.g., by index or filepath).
    - `clear()`: Empties the context.
    - `get_context_items()`: Returns the list of context items.
    - `get_formatted_context(max_tokens)`: Generates a single string representation of the context suitable for the LLM, potentially pruning based on `max_tokens`.
    - `get_token_count()`: Returns the current total token count.
- **Token Counting:** Needs a basic token counting utility (can be approximate initially).
- **Persistence:** (Future) Consider saving/loading context presets or across sessions.

## 4. UI Changes (`ui.lua`)

- **Command Parser:** Enhance the input handler to recognize `/context ...` commands.
- **Context Display:**
    - Option 1: Add a small, always-visible indicator of context size (e.g., "Context: 3 items / 1500 tokens").
    - Option 2: Implement `/context list` to print the detailed context into the chat buffer.
    - Option 3: (More complex) Add a dedicated, potentially collapsible, section in the UI.
- **Interaction:** Ensure context commands provide user feedback (e.g., "Added file.lua to context.").

## 5. API Changes (`api.lua`)

- **Context Injection:** Before sending the request in `send_request`, call `context.get_formatted_context()` and prepend the result to the message list/prompt being sent. Ensure this respects the overall token limit of the model.

## 6. `init.lua` Changes

- Require `llm_agent_new.context`.
- Call `context.setup(M._config)` within `M.setup`.
- Decide how `ui` and `api` modules will access the `context` module instance (e.g., pass `context` instance to `ui.setup` and `api.setup`).
- Update `handle_send_message` to orchestrate getting context and passing it to `api.send_request`.

## 7. Configuration (`config.lua`)

- Add a `context` section to `M.default_config`:
  ```lua
  context = {
    max_tokens = 4096 -- Example limit
  }
  ```

## 8. Implementation Steps

1.  Create basic `context.lua` with an empty context table and placeholder functions (`add_file`, `clear`, `get_formatted_context`).
2.  Update `init.lua` to load and setup `context.lua`.
3.  Update `api.lua`'s `send_request` to accept and prepend context (initially empty string).
4.  Implement basic `/context add <filepath>` command handling in `ui.lua` calling `context.add_file`.
5.  Implement file reading and basic storage in `context.add_file`.
6.  Implement `context.get_formatted_context` to combine stored content.
7.  Implement `/context list` and display logic in `ui.lua`.
8.  Implement `/context clear`.
9.  Add visual selection support (`/context add_selection` or similar command/keymap).
10. Implement token counting and limit enforcement.
11. Add `:LLMContext...` commands/keymaps in `init.lua` if desired.
12. Refine UI display and feedback.
13. Add configuration options (`max_tokens`). 
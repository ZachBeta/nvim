# Tutorial: Adding Context Management to the LLM Agent

Welcome! This tutorial will guide you through adding context management to our Neovim LLM Agent plugin. This feature allows users to add files or code snippets to the chat, giving the LLM more information to provide better answers. We'll follow the steps outlined in `context_management_plan.md`.

## 1. Understanding the Goal

Right now, our agent only sends the current conversation history to the LLM. We want to allow the user to add relevant code (like the file they are editing or a specific function) to this conversation. This "context" helps the LLM understand the user's specific situation better.

**What we'll build:**
- Commands like `/context add <file>` to add files.
- A way to see what's currently in the context (`/context list`).
- A way to clear the context (`/context clear`).
- The ability for the agent to automatically include this context when talking to the LLM.

## 2. The Heart of Context: `context.lua`

We need a central place to manage everything related to context. That's why we're creating a new file: `lua/llm_agent_new/context.lua`.

**Purpose:** This module will be responsible for:
- Storing the pieces of context (files, selections).
- Adding new items to the context.
- Removing items.
- Clearing all context.
- Formatting the context into a single piece of text that the LLM can understand.
- (Eventually) Keeping track of how much context we're adding (token counting).

**Getting Started:**
1.  Create the file `lua/llm_agent_new/context.lua`.
2.  Inside, define a basic Lua module structure:
    ```lua
    -- lua/llm_agent_new/context.lua
    local Context = {}
    Context._VERSION = "0.1.0"

    local context_items = {} -- Our main storage!
    local config = {}

    function Context.setup(opts)
      config = opts or {}
      context_items = {} -- Reset on setup
      print("Context module setup!") -- Debug message
    end

    -- Placeholder for adding a file
    function Context.add_file(filepath)
      print("TODO: Implement add_file for: " .. filepath)
      -- Later: Read file, check limits, add to context_items
    end

    -- Placeholder for clearing context
    function Context.clear()
      print("TODO: Implement clear")
      context_items = {}
      print("Context cleared (basic).")
    end

    -- Placeholder for formatting context for the LLM
    function Context.get_formatted_context()
      print("TODO: Implement get_formatted_context")
      -- Later: Combine items in context_items into a string
      return "-- CONTEXT WILL GO HERE --\n" -- Basic placeholder
    end

    -- Placeholder for listing items
    function Context.get_context_items()
        print("TODO: Implement get_context_items")
        return context_items
    end

    return Context
    ```
3.  **Data Structure:** Think about how to store items in the `context_items` table. The plan suggests something like: `{ type = "file", path = "...", content = "...", tokens = 0 }`. This helps us know what each piece of context is.

## 3. Connecting the Pieces: `init.lua`

Our main `init.lua` file needs to know about the new `context` module and make it available to other parts of the plugin (`ui.lua`, `api.lua`).

**Changes needed:**
1.  **Require:** At the top, add `local context_module = nil`.
2.  **Setup:** Inside the `M.setup` function:
    - Add configuration defaults for context (see step 7 below).
    - Just like you load `ui` and `api`, load the `context` module:
      ```lua
      -- Inside M.setup, after loading ui and api
      local context_ok, context = pcall(require, 'llm_agent_new.context')
      if not context_ok then
        vim.notify("LLM Agent: Failed to load Context module: " .. tostring(context), vim.log.levels.ERROR)
      else
        -- Pass the context part of the config
        local context_setup_ok = pcall(context.setup, M._config.context)
        if not context_setup_ok then
             vim.notify("LLM Agent: Failed to setup Context module.", vim.log.levels.ERROR)
        else
            context_module = context -- Store the loaded module instance
        end
      end
      ```
    - **Sharing:** We need `ui` and `api` to talk to the `context` module. A simple way is to pass the `context_module` instance to their `setup` functions:
      ```lua
      -- Modify ui.setup call (example)
      -- ui_module = ui.setup(M._config.ui, context_module) -- Assuming ui.setup accepts context
      -- Modify api.setup call (example)
      -- api.setup(M._config.api, context_module) -- Assuming api.setup accepts context
      ```
      *(You'll need to modify the `setup` functions in `ui.lua` and `api.lua` slightly to accept this new argument and store it for later use.)*
3.  **Sending Messages:** The `handle_send_message` function needs updating. Before it calls `api_module.send_request`, it needs to get the formatted context string from our new module:
    ```lua
    -- Inside handle_send_message(messages)
    if not api_module or not context_module then -- Check context_module too
      vim.notify("LLM Agent Error: API or Context module not loaded.", vim.log.levels.ERROR)
      return
    end

    local current_context = context_module.get_formatted_context() -- Get context!

    -- Pass context to send_request (requires modifying api.send_request)
    api_module.send_request(current_context, messages, function(response)
      -- ... existing callback logic ...
    end)
    ```

## 4. Teaching the API Module: `api.lua`

The `api.lua` module needs to know how to *use* the context string we give it.

**Changes needed:**
1.  **Modify `setup`:** Accept the `context_module` instance passed from `init.lua` and store it if needed (though maybe not strictly necessary if context is passed directly to `send_request`).
2.  **Modify `send_request`:** Change its signature to accept the `current_context` string (as shown in the `init.lua` example above).
3.  **Prepend Context:** Inside `send_request`, before you construct the final payload for `curl` (or whatever API call you make), prepend the `current_context` string to the user's prompt or message list. A common way is to add it as a system message or just put it at the beginning of the user's first message in the list.
    ```lua
    -- Inside api.send_request(current_context, messages, callback)

    -- Example: Add context before the main messages
    local messages_with_context = vim.deep_copy(messages) -- Don't modify original messages table
    -- Option A: Prepend to the content of the first user message (if structure allows)
    -- if #messages_with_context > 0 and messages_with_context[1].role == "user" then
    --    messages_with_context[1].content = current_context .. "\n" .. messages_with_context[1].content
    -- end
    -- Option B: Add a system message at the start (often better)
    table.insert(messages_with_context, 1, { role = "system", content = current_context })

    -- Now use messages_with_context when building the API request body...
    -- ... rest of the API call logic ...
    ```

## 5. User Interface Interaction: `ui.lua`

The user needs a way to *tell* the agent to add/list/clear context. This happens in the chat window (`ui.lua`).

**Changes needed:**
1.  **Modify `setup`:** Accept the `context_module` instance passed from `init.lua` and store it (e.g., `self.context_module = passed_context_module`).
2.  **Command Parsing:** In the function that handles user input (when Enter is pressed), add logic to check if the input starts with `/context`.
    - If it's `/context add <filepath>`, extract the filepath and call `self.context_module.add_file(filepath)`.
    - If it's `/context list`, call `self.context_module.get_context_items()` and display the results in the chat window (using `append_message` or similar).
    - If it's `/context clear`, call `self.context_module.clear()`.
    - Remember to provide feedback to the user (e.g., `append_message("System", "Added file X to context.")`).
3.  **Displaying Context:** For `/context list`, format the output nicely. Show the type and path/name of each item. Eventually, add token counts.

## 6. Configuration: `config.lua` (via `init.lua`)

We need a place to potentially configure context behavior, like the maximum number of tokens allowed.

**Changes needed:**
1.  **Defaults:** In `init.lua`, add a `context` section to `M.default_config`:
    ```lua
    -- In M.default_config
    context = {
      max_tokens = 4096 -- Example limit
    },
    -- other sections like ui, api...
    ```
2.  **Passing Config:** Ensure `M._config.context` is passed to `context.setup` (as shown in Step 3).
3.  **Using Config:** Inside `context.lua`, use `config.max_tokens` when implementing token limits later.

## 7. Implementation Steps (Putting it Together)

Follow the numbered steps in `context_management_plan.md` Section 8. Here's a summary:

1.  **Create `context.lua`** with placeholder functions.
2.  **Update `init.lua`** to load `context.lua` and pass it to `ui`/`api` setups.
3.  **Update `api.lua`** (`send_request`) to accept and prepend context (start with the placeholder string).
4.  **Implement `/context add <filepath>`** command parsing in `ui.lua`. Make it call the placeholder `context.add_file`.
5.  **Implement actual file reading** in `context.add_file`. Store the content in `context_items`.
6.  **Implement `context.get_formatted_context`** to create the string from `context_items`.
7.  **Implement `/context list`** in `ui.lua` to display items.
8.  **Implement `/context clear`** in `ui.lua` and `context.lua`.
9.  **Add visual selection support** (more advanced, maybe later).
10. **Implement token counting** (can be tricky, start simple like counting words/lines).
11. Add Neovim commands (`:LLMContextAddFile`) if desired (in `init.lua`).
12. Improve UI feedback.
13. Use the `max_tokens` config.

**Key Advice:**
- **Implement step-by-step.** Get one piece working before moving to the next.
- **Use `print()` or `vim.notify()` extensively** for debugging.
- **Test frequently.** After each small change, reload Neovim and see if it works as expected.
- **Start simple.** Don't worry about perfect token counting or complex UI at first. Get the basic flow working.

Good luck! Adding context is a big step in making the LLM agent much more useful. 
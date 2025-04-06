-- lua/llm_agent_new/api/init.lua

-- local Job = require('plenary.job') -- Use native jobstart

local M = {}

local api_config = {}

-- Function to initialize the API module with configuration
function M.setup(config)
  if not config then
    vim.notify("LLM Agent API: Configuration is missing.", vim.log.levels.ERROR)
    return false
  end
  api_config = config
  vim.notify("LLM Agent API: Initialized with provider: " .. (api_config.provider or "none"), vim.log.levels.INFO)
  return true
end

-- Function to send a request to the configured LLM provider using native jobstart and curl
function M.send_request(messages, final_callback)
  if not api_config or not api_config.provider then
    vim.notify("LLM Agent API: Provider not configured.", vim.log.levels.ERROR)
    if final_callback then final_callback({ success = false, error = "API provider not configured." }) end
    return
  end

  if api_config.provider == "ollama" then
    local ollama_config = api_config.ollama
    if not ollama_config or not ollama_config.enabled then
      vim.notify("LLM Agent API: Ollama provider is not enabled in config.", vim.log.levels.WARN)
      if final_callback then final_callback({ success = false, error = "Ollama provider not enabled." }) end
      return
    end

    local url = "http://" .. (ollama_config.host or "localhost:11434") .. "/api/chat"
    local model = ollama_config.model or "gemma3:4b"

    -- Format messages
    local formatted_messages = {}
    for _, msg_content in ipairs(messages) do
      table.insert(formatted_messages, { role = "user", content = msg_content })
    end

    local request_body_tbl = {
      model = model,
      messages = formatted_messages,
      stream = false
    }
    local request_body_json = vim.fn.json_encode(request_body_tbl)
    -- No need to shellescape when passing args directly to jobstart

    -- Construct the command arguments for jobstart
    local cmd_args = {
        'curl',
        '-X', 'POST',
        url,
        '-H', "Content-Type: application/json",
        '-d', request_body_json -- Pass raw JSON string directly
    }

    vim.notify(string.format("LLM Agent API: Starting jobstart for Ollama (%s) at %s", model, url), vim.log.levels.INFO)
    vim.notify("API: Using command args: " .. vim.inspect(cmd_args), vim.log.levels.DEBUG)

    local stdout_chunks = {}
    local stderr_chunks = {}

    local job_id = vim.fn.jobstart(cmd_args, {
        clear_env = false,
        on_stdout = function(job_id, data, event)
            vim.schedule(function()
                vim.notify("Job Callback: on_stdout received data chunk.", vim.log.levels.DEBUG)
                if data then table.insert(stdout_chunks, table.concat(data, "")) end
            end)
        end,
        on_stderr = function(job_id, data, event)
             vim.schedule(function()
                vim.notify("Job Callback: on_stderr received data chunk.", vim.log.levels.DEBUG)
                if data then table.insert(stderr_chunks, table.concat(data, "")) end
            end)
        end,
        on_exit = function(job_id, exit_code, event)
            vim.schedule(function()
                vim.notify("Job Callback: on_exit received, code: " .. tostring(exit_code), vim.log.levels.DEBUG)
                local response_body = table.concat(stdout_chunks, "")
                local stderr_output = table.concat(stderr_chunks, "")

                if exit_code ~= 0 then
                    local err_msg = stderr_output
                    if err_msg == "" then err_msg = "curl command failed with exit code " .. exit_code end
                    vim.notify("Job Callback Error: curl command failed: " .. err_msg, vim.log.levels.ERROR)
                    if final_callback then final_callback({ success = false, error = "curl command failed: " .. err_msg }) end
                    return
                end

                vim.notify("Job Callback: curl success (exit 0). Raw stdout: " .. response_body, vim.log.levels.DEBUG)

                -- Decode JSON
                local success, decoded_body = pcall(vim.fn.json_decode, response_body)
                if not success or not decoded_body then
                   local decode_err_msg = decoded_body or "Unknown decode error"
                   vim.notify("Job Callback Error: Failed to decode Ollama JSON: " .. decode_err_msg, vim.log.levels.ERROR)
                   if final_callback then final_callback({ success = false, error = "Failed to decode Ollama JSON response." }) end
                   return
                end
                vim.notify("Job Callback: JSON decoded successfully.", vim.log.levels.DEBUG)

                -- Check for application-level error
                if decoded_body.error then
                   vim.notify("Job Callback Error: Ollama returned an error: " .. decoded_body.error, vim.log.levels.ERROR)
                   if final_callback then final_callback({ success = false, error = "Ollama API error: " .. decoded_body.error }) end
                   return
                end

                -- Extract content
                local content = "(Error extracting content)"
                if decoded_body.message and decoded_body.message.content then
                     content = decoded_body.message.content
                     vim.notify("Job Callback: Content extracted successfully.", vim.log.levels.DEBUG)
                else
                     vim.notify("Job Callback Warning: Could not find message.content in response.", vim.log.levels.WARN)
                end

                -- Execute final success callback
                vim.notify("Job Callback: Preparing final success notification.", vim.log.levels.DEBUG)
                if final_callback then
                    vim.notify("Job Callback: Executing final callback.", vim.log.levels.DEBUG)
                    final_callback({ success = true, content = content })
                end
            end) -- end vim.schedule
        end -- end on_exit
    })
    
    if job_id == 0 or job_id == -1 then
        vim.notify("LLM Agent API Error: Failed to start job with jobstart(). Job ID: " .. tostring(job_id), vim.log.levels.ERROR)
        if final_callback then final_callback({ success = false, error = "Failed to start curl job." }) end
    else
        vim.notify("LLM Agent API: Job started successfully with ID: " .. job_id, vim.log.levels.INFO)
    end

  elseif api_config.provider == "openrouter" then
     vim.notify("LLM Agent API: OpenRouter provider not implemented yet.", vim.log.levels.WARN)
     if final_callback then final_callback({ success = false, error = "OpenRouter provider not implemented." }) end
  else
    vim.notify("LLM Agent API: Unsupported provider: " .. api_config.provider, vim.log.levels.ERROR)
    if final_callback then final_callback({ success = false, error = "Unsupported API provider." }) end
  end
end

return M 
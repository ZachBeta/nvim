-- llm-agent/api/init.lua
-- API module for LLM provider integration

local utils = require("llm-agent.utils")
local config = require("llm-agent.config").defaults

local M = {}

-- Internal state
M._state = {
  openrouter = {
    status = "idle", -- idle, connecting, ready, error
    error = nil,     -- Last error message
    client = nil,    -- HTTP client instance
  },
  ollama = {
    status = "idle", -- idle, connecting, ready, error
    error = nil,     -- Last error message
    client = nil,    -- HTTP client instance
  },
  active_provider = nil, -- Current active provider
  current_request = nil, -- Current request in progress
  request_id = 0,        -- Request counter
}

-- Initialize API module
function M.setup()
  -- Get global config
  local global_config = require("llm-agent")._config or config
  
  -- Initialize OpenRouter client
  M.init_openrouter(global_config.api.openrouter)
  
  -- Initialize Ollama client if enabled
  if global_config.api.ollama.enabled then
    M.init_ollama(global_config.api.ollama)
  end
end

-- Initialize OpenRouter client
function M.init_openrouter(config)
  -- Skip if no API key
  if not config.api_key or config.api_key == "" then
    M._state.openrouter.status = "error"
    M._state.openrouter.error = "API key not configured"
    utils.log.warn("OpenRouter API key not configured")
    return false
  end
  
  M._state.openrouter.status = "connecting"
  
  -- Test API connection
  local success, result = pcall(function()
    local curl_cmd = string.format(
      'curl -s -X GET -H "Authorization: Bearer %s" %s/models',
      config.api_key,
      config.base_url
    )
    
    local deferred = utils.async.exec_command(curl_cmd)
    
    deferred:then_fn(function(response)
      -- Parse JSON response
      local ok, data = pcall(vim.fn.json_decode, response)
      
      if not ok then
        M._state.openrouter.status = "error"
        M._state.openrouter.error = "Failed to parse API response"
        utils.log.error("OpenRouter API test failed: " .. data)
        return false
      end
      
      if data.error then
        M._state.openrouter.status = "error"
        M._state.openrouter.error = data.error.message or "API error"
        utils.log.error("OpenRouter API test failed: " .. M._state.openrouter.error)
        return false
      end
      
      -- Connection successful
      M._state.openrouter.status = "ready"
      M._state.active_provider = "openrouter"
      utils.log.info("OpenRouter API connection established")
      return true
    end):catch(function(err)
      M._state.openrouter.status = "error"
      M._state.openrouter.error = err.stderr or tostring(err)
      utils.log.error("OpenRouter API test failed: " .. M._state.openrouter.error)
      return false
    end)
  end)
  
  if not success then
    M._state.openrouter.status = "error"
    M._state.openrouter.error = result
    utils.log.error("OpenRouter API test failed: " .. result)
    return false
  end
  
  return true
end

-- Initialize Ollama client
function M.init_ollama(config)
  M._state.ollama.status = "connecting"
  
  -- Test API connection
  local success, result = pcall(function()
    local curl_cmd = string.format(
      'curl -s %s/api/tags',
      config.base_url
    )
    
    local deferred = utils.async.exec_command(curl_cmd)
    
    deferred:then_fn(function(response)
      -- Parse JSON response
      local ok, data = pcall(vim.fn.json_decode, response)
      
      if not ok then
        M._state.ollama.status = "error"
        M._state.ollama.error = "Failed to parse API response"
        utils.log.error("Ollama API test failed: " .. data)
        return false
      end
      
      if data.error then
        M._state.ollama.status = "error"
        M._state.ollama.error = data.error or "API error"
        utils.log.error("Ollama API test failed: " .. M._state.ollama.error)
        return false
      end
      
      -- Connection successful
      M._state.ollama.status = "ready"
      if not M._state.active_provider then
        M._state.active_provider = "ollama"
      end
      utils.log.info("Ollama API connection established")
      return true
    end):catch(function(err)
      M._state.ollama.status = "error"
      M._state.ollama.error = err.stderr or tostring(err)
      utils.log.error("Ollama API test failed: " .. M._state.ollama.error)
      return false
    end)
  end)
  
  if not success then
    M._state.ollama.status = "error"
    M._state.ollama.error = result
    utils.log.error("Ollama API test failed: " .. result)
    return false
  end
  
  return true
end

-- Check if Ollama is available
function M.check_ollama_available()
  local global_config = require("llm-agent")._config or config
  if not global_config.api.ollama.enabled then
    return false
  end
  
  -- Check status
  if M._state.ollama.status == "ready" then
    return true
  end
  
  -- Try to initialize
  return M.init_ollama(global_config.api.ollama)
end

-- Send message to LLM
function M.send_message(messages, options, callback)
  options = options or {}
  local global_config = require("llm-agent")._config or config
  
  -- Get provider to use
  local provider = options.provider or M._state.active_provider
  
  -- Check provider status
  if not provider or M._state[provider].status ~= "ready" then
    -- Try fallback if active provider is unavailable
    if provider == "openrouter" and M.check_ollama_available() then
      provider = "ollama"
      utils.log.warn("Falling back to Ollama")
    else
      callback({
        error = true,
        message = "No LLM provider available",
        details = M._state[provider] and M._state[provider].error or "Provider not initialized"
      })
      return
    end
  end
  
  -- Increment request ID
  M._state.request_id = M._state.request_id + 1
  local request_id = M._state.request_id
  
  -- Create request object
  M._state.current_request = {
    id = request_id,
    provider = provider,
    messages = messages,
    options = options,
    callback = callback,
    start_time = vim.loop.now(),
    stream_data = {},
  }
  
  -- Format context if needed
  if options.include_context then
    local context_module = require("llm-agent.context")
    local context_text = context_module.get_formatted_context()
    
    -- Add context as a system message at the beginning
    if #context_text > 0 then
      table.insert(messages, 1, {
        role = "system",
        content = context_text
      })
    end
  end
  
  -- Send to provider
  if provider == "openrouter" then
    M.send_to_openrouter(messages, options, callback)
  elseif provider == "ollama" then
    M.send_to_ollama(messages, options, callback)
  else
    callback({
      error = true,
      message = "Unknown provider: " .. provider
    })
  end
end

-- Send message to OpenRouter
function M.send_to_openrouter(messages, options, callback)
  local global_config = require("llm-agent")._config or config
  local provider_config = global_config.api.openrouter
  
  -- Get model to use
  local model = options.model or provider_config.models.default
  
  -- Create request body
  local body = {
    model = model,
    messages = messages,
    stream = options.stream or provider_config.parameters.stream,
    temperature = options.temperature or provider_config.parameters.temperature,
    top_p = options.top_p or provider_config.parameters.top_p,
    max_tokens = options.max_tokens or 4000,
  }
  
  -- Create curl command
  local curl_cmd = string.format(
    'curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer %s" -d \'%s\' %s/chat/completions',
    provider_config.api_key,
    vim.fn.json_encode(body),
    provider_config.base_url
  )
  
  -- Add streaming parameters if needed
  if body.stream then
    -- Use a different approach for streaming responses
    return M.stream_from_openrouter(curl_cmd, messages, options, callback)
  end
  
  -- Execute request
  local deferred = utils.async.exec_command(curl_cmd)
  
  deferred:then_fn(function(response)
    -- Parse JSON response
    local ok, data = pcall(vim.fn.json_decode, response)
    
    if not ok then
      callback({
        error = true,
        message = "Failed to parse API response",
        details = data
      })
      return
    end
    
    if data.error then
      callback({
        error = true,
        message = data.error.message or "API error",
        details = data.error
      })
      return
    end
    
    -- Process successful response
    callback({
      error = false,
      provider = "openrouter",
      model = model,
      response = data.choices[0].message.content,
      metadata = {
        id = data.id,
        created = data.created,
        prompt_tokens = data.usage.prompt_tokens,
        completion_tokens = data.usage.completion_tokens,
        total_tokens = data.usage.total_tokens,
      }
    })
  end):catch(function(err)
    callback({
      error = true,
      message = "API request failed",
      details = err.stderr or tostring(err)
    })
  end)
end

-- Stream response from OpenRouter
function M.stream_from_openrouter(curl_cmd, messages, options, callback)
  local global_config = require("llm-agent")._config or config
  local request_id = M._state.current_request.id
  local accumulated_text = ""
  
  -- Execute command with line-by-line processing
  local handle = io.popen(curl_cmd, "r")
  if not handle then
    callback({
      error = true,
      message = "Failed to execute curl command",
      details = "IO error"
    })
    return
  end
  
  -- Process stream data
  local timer = utils.async.set_interval(function()
    -- Check if request has been cancelled
    if not M._state.current_request or (M._state.current_request.id ~= request_id) then
      -- Clean up
      if handle then
        handle:close()
        handle = nil
      end
      utils.async.clear_interval(timer)
      return
    end
    
    if not handle then return end
    
    local line = handle:read("*line")
    if not line then
      -- End of stream
      handle:close()
      handle = nil
      utils.async.clear_interval(timer)
      
      -- Process final message
      callback({
        error = false,
        provider = "openrouter",
        response = accumulated_text,
        done = true
      })
      return
    end
    
    -- Skip empty lines
    if line:match("^%s*$") then
      return
    end
    
    -- Check for data prefix
    if line:match("^data: ") then
      line = line:sub(7) -- Remove "data: " prefix
      
      -- Handle [DONE] marker
      if line == "[DONE]" then
        handle:close()
        handle = nil
        utils.async.clear_interval(timer)
        
        -- Process final message
        callback({
          error = false,
          provider = "openrouter",
          response = accumulated_text,
          done = true
        })
        return
      end
      
      -- Parse JSON data
      local ok, data = pcall(vim.fn.json_decode, line)
      if not ok then
        utils.log.debug("Failed to parse stream data: " .. line)
        return
      end
      
      -- Process response chunk
      if data.choices and data.choices[1] and data.choices[1].delta and data.choices[1].delta.content then
        local content = data.choices[1].delta.content
        accumulated_text = accumulated_text .. content
        
        -- Send chunk to callback
        callback({
          error = false,
          provider = "openrouter",
          response = accumulated_text,
          chunk = content,
          done = false
        })
      end
    end
  end, 10) -- Check every 10ms
end

-- Send message to Ollama
function M.send_to_ollama(messages, options, callback)
  local global_config = require("llm-agent")._config or config
  local provider_config = global_config.api.ollama
  
  -- Get model to use
  local model = options.model or provider_config.models.default
  
  -- Convert messages to Ollama format
  local prompt = M.messages_to_ollama_prompt(messages)
  
  -- Create request body
  local body = {
    model = model,
    prompt = prompt,
    stream = options.stream or provider_config.parameters.stream,
    temperature = options.temperature or provider_config.parameters.temperature,
    top_p = options.top_p or provider_config.parameters.top_p,
    num_predict = options.max_tokens or 4000,
  }
  
  -- Create curl command
  local curl_cmd = string.format(
    'curl -s -X POST -H "Content-Type: application/json" -d \'%s\' %s/api/generate',
    vim.fn.json_encode(body),
    provider_config.base_url
  )
  
  -- Add streaming parameters if needed
  if body.stream then
    -- Use a different approach for streaming responses
    return M.stream_from_ollama(curl_cmd, messages, options, callback)
  end
  
  -- Execute request
  local deferred = utils.async.exec_command(curl_cmd)
  
  deferred:then_fn(function(response)
    -- Parse JSON response
    local ok, data = pcall(vim.fn.json_decode, response)
    
    if not ok then
      callback({
        error = true,
        message = "Failed to parse API response",
        details = data
      })
      return
    end
    
    if data.error then
      callback({
        error = true,
        message = data.error or "API error",
        details = data
      })
      return
    end
    
    -- Process successful response
    callback({
      error = false,
      provider = "ollama",
      model = model,
      response = data.response,
      metadata = {
        eval_count = data.eval_count,
        eval_duration = data.eval_duration,
      }
    })
  end):catch(function(err)
    callback({
      error = true,
      message = "API request failed",
      details = err.stderr or tostring(err)
    })
  end)
end

-- Stream response from Ollama
function M.stream_from_ollama(curl_cmd, messages, options, callback)
  local global_config = require("llm-agent")._config or config
  local request_id = M._state.current_request.id
  local accumulated_text = ""
  
  -- Execute command with line-by-line processing
  local handle = io.popen(curl_cmd, "r")
  if not handle then
    callback({
      error = true,
      message = "Failed to execute curl command",
      details = "IO error"
    })
    return
  end
  
  -- Process stream data
  local timer = utils.async.set_interval(function()
    -- Check if request has been cancelled
    if not M._state.current_request or (M._state.current_request.id ~= request_id) then
      -- Clean up
      if handle then
        handle:close()
        handle = nil
      end
      utils.async.clear_interval(timer)
      return
    end
    
    if not handle then return end
    
    local line = handle:read("*line")
    if not line then
      -- End of stream
      handle:close()
      handle = nil
      utils.async.clear_interval(timer)
      
      -- Process final message
      callback({
        error = false,
        provider = "ollama",
        response = accumulated_text,
        done = true
      })
      return
    end
    
    -- Skip empty lines
    if line:match("^%s*$") then
      return
    end
    
    -- Parse JSON data
    local ok, data = pcall(vim.fn.json_decode, line)
    if not ok then
      utils.log.debug("Failed to parse stream data: " .. line)
      return
    end
    
    -- Process response chunk
    if data.response then
      local content = data.response
      accumulated_text = accumulated_text .. content
      
      -- Send chunk to callback
      callback({
        error = false,
        provider = "ollama",
        response = accumulated_text,
        chunk = content,
        done = data.done or false
      })
      
      -- Check if done
      if data.done then
        handle:close()
        handle = nil
        utils.async.clear_interval(timer)
      end
    end
  end, 10) -- Check every 10ms
end

-- Convert messages array to Ollama prompt format
function M.messages_to_ollama_prompt(messages)
  local prompt = ""
  
  for _, msg in ipairs(messages) do
    local role = msg.role
    local content = msg.content
    
    if role == "system" then
      prompt = prompt .. "[SYSTEM] " .. content .. "\n\n"
    elseif role == "user" then
      prompt = prompt .. "[USER] " .. content .. "\n\n"
    elseif role == "assistant" then
      prompt = prompt .. "[ASSISTANT] " .. content .. "\n\n"
    end
  end
  
  -- Add final assistant prompt
  prompt = prompt .. "[ASSISTANT] "
  
  return prompt
end

-- Cancel current request
function M.cancel_request()
  if not M._state.current_request then
    return false
  end
  
  -- Set a flag to indicate the request was cancelled
  M._state.current_request.cancelled = true
  
  -- TODO: In a future version, implement proper cancellation of in-flight HTTP requests
  -- For now, we'll just mark the request as cancelled and ignore future responses
  
  -- Reset current request
  local cancelled_request = M._state.current_request
  M._state.current_request = nil
  
  -- Log cancellation
  utils.log.info("Cancelled request " .. tostring(cancelled_request.id))
  
  return true
end

-- Get API status
function M.get_status()
  return {
    openrouter = {
      status = M._state.openrouter.status,
      error = M._state.openrouter.error,
    },
    ollama = {
      status = M._state.ollama.status,
      error = M._state.ollama.error,
    },
    active_provider = M._state.active_provider,
    current_request = M._state.current_request ~= nil,
  }
end

return M 
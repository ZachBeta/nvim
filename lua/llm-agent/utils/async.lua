-- llm-agent/utils/async.lua
-- Async operation utilities for the plugin

local M = {}

-- Store scheduled timer callbacks
M._scheduled = {}

-- Schedule a function to run in the future (milliseconds)
function M.schedule(fn, timeout)
  timeout = timeout or 0
  local timer = vim.loop.new_timer()
  
  local callback = function()
    -- Remove from scheduled list
    for i, v in ipairs(M._scheduled) do
      if v.timer == timer then
        table.remove(M._scheduled, i)
        break
      end
    end
    
    -- Execute in the main loop
    vim.schedule(fn)
  end
  
  -- Start the timer
  timer:start(timeout, 0, callback)
  
  -- Store in scheduled list
  table.insert(M._scheduled, { timer = timer, callback = fn })
  
  return timer
end

-- Cancel a scheduled timer
function M.cancel_schedule(timer)
  if not timer then
    return
  end
  
  timer:stop()
  timer:close()
  
  -- Remove from scheduled list
  for i, v in ipairs(M._scheduled) do
    if v.timer == timer then
      table.remove(M._scheduled, i)
      break
    end
  end
end

-- Set up an interval timer
function M.set_interval(fn, interval)
  local timer = vim.loop.new_timer()
  
  local callback = function()
    vim.schedule(fn)
  end
  
  -- Start the timer
  timer:start(interval, interval, callback)
  
  -- Store in scheduled list
  table.insert(M._scheduled, { timer = timer, callback = fn })
  
  return timer
end

-- Clear an interval timer
function M.clear_interval(timer)
  return M.cancel_schedule(timer)
end

-- Simple debounce function
function M.debounce(fn, ms)
  local timer = nil
  
  return function(...)
    local args = {...}
    
    -- Cancel previous timer
    if timer then
      M.cancel_schedule(timer)
    end
    
    -- Create new timer
    timer = M.schedule(function()
      fn(unpack(args))
      timer = nil
    end, ms)
  end
end

-- Simple throttle function
function M.throttle(fn, ms)
  local timer = nil
  local last_exec = 0
  
  return function(...)
    local args = {...}
    local now = vim.loop.now()
    
    -- Check if enough time has passed
    if now - last_exec >= ms then
      last_exec = now
      fn(unpack(args))
    else
      -- Schedule for later if not already scheduled
      if not timer then
        timer = M.schedule(function()
          last_exec = vim.loop.now()
          fn(unpack(args))
          timer = nil
        end, ms - (now - last_exec))
      end
    end
  end
end

-- Create a new Deferred object (Promise-like)
function M.deferred()
  local d = {
    _state = "pending", 
    _value = nil,
    _resolvers = {},
    _rejectors = {},
  }
  
  -- Resolve the deferred
  d.resolve = function(value)
    if d._state ~= "pending" then
      return
    end
    
    d._state = "fulfilled"
    d._value = value
    
    -- Call all resolvers
    for _, resolver in ipairs(d._resolvers) do
      vim.schedule(function()
        resolver(value)
      end)
    end
    
    d._resolvers = {}
    d._rejectors = {}
  end
  
  -- Reject the deferred
  d.reject = function(err)
    if d._state ~= "pending" then
      return
    end
    
    d._state = "rejected"
    d._value = err
    
    -- Call all rejectors
    for _, rejector in ipairs(d._rejectors) do
      vim.schedule(function()
        rejector(err)
      end)
    end
    
    d._resolvers = {}
    d._rejectors = {}
  end
  
  -- Add then callback
  d.then_fn = function(on_fulfilled, on_rejected)
    local new_deferred = M.deferred()
    
    local resolve_handler = function(value)
      if type(on_fulfilled) ~= "function" then
        new_deferred.resolve(value)
        return
      end
      
      local success, result = pcall(on_fulfilled, value)
      if not success then
        new_deferred.reject(result)
        return
      end
      
      new_deferred.resolve(result)
    end
    
    local reject_handler = function(err)
      if type(on_rejected) ~= "function" then
        new_deferred.reject(err)
        return
      end
      
      local success, result = pcall(on_rejected, err)
      if not success then
        new_deferred.reject(result)
        return
      end
      
      new_deferred.resolve(result)
    end
    
    if d._state == "fulfilled" then
      vim.schedule(function()
        resolve_handler(d._value)
      end)
    elseif d._state == "rejected" then
      vim.schedule(function()
        reject_handler(d._value)
      end)
    else
      table.insert(d._resolvers, resolve_handler)
      table.insert(d._rejectors, reject_handler)
    end
    
    return new_deferred
  end
  
  -- Add catch callback
  d.catch = function(on_rejected)
    return d.then_fn(nil, on_rejected)
  end
  
  -- Add finally callback
  d.finally = function(on_settled)
    local on_settled_fn = function()
      on_settled()
    end
    
    return d.then_fn(on_settled_fn, on_settled_fn)
  end
  
  return d
end

-- Execute function asynchronously and return a deferred
function M.async(fn)
  local deferred = M.deferred()
  
  vim.schedule(function()
    local success, result = pcall(fn)
    if success then
      deferred.resolve(result)
    else
      deferred.reject(result)
    end
  end)
  
  return deferred
end

-- Execute a shell command asynchronously
function M.exec_command(cmd)
  local deferred = M.deferred()
  
  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)
  local stdout_data = {}
  local stderr_data = {}
  
  local handle, pid = vim.loop.spawn("sh", {
    args = {"-c", cmd},
    stdio = {nil, stdout, stderr}
  }, function(code, signal)
    stdout:close()
    stderr:close()
    
    if code ~= 0 then
      deferred.reject({
        code = code,
        signal = signal,
        stderr = table.concat(stderr_data, ""),
        stdout = table.concat(stdout_data, "")
      })
    else
      deferred.resolve(table.concat(stdout_data, ""))
    end
  end)
  
  if not handle then
    stderr:close()
    stdout:close()
    deferred.reject("Failed to spawn process")
    return deferred
  end
  
  vim.loop.read_start(stdout, function(err, data)
    if err then
      deferred.reject("stdout read error: " .. err)
      return
    end
    
    if data then
      table.insert(stdout_data, data)
    end
  end)
  
  vim.loop.read_start(stderr, function(err, data)
    if err then
      deferred.reject("stderr read error: " .. err)
      return
    end
    
    if data then
      table.insert(stderr_data, data)
    end
  end)
  
  return deferred
end

return M 
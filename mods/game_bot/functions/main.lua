local context = G.botContext

-- MAIN BOT FUNCTION
-- macro(timeout, callback)
-- macro(timeout, name, callback)
-- macro(timeout, name, callback, parent)
-- macro(timeout, name, hotkey, callback)
-- macro(timeout, name, hotkey, callback, parent)
context.macro = function(timeout, name, hotkey, callback, parent)
  if type(timeout) ~= 'number' or timeout < 1 then
    error("Invalid timeout for macro: " .. tostring(timeout))
  end
  if type(name) == 'function' then
    callback = name
    name = ""
    hotkey = ""
  elseif type(hotkey) == 'function' then
    parent = callback
    callback = hotkey
    hotkey = ""    
  elseif type(callback) ~= 'function' then
    error("Invalid callback for macro: " .. tostring(callback))
  end
  if hotkey == nil then
    hotkey = ""
  end
  if type(name) ~= 'string' or type(hotkey) ~= 'string' then
    error("Invalid name or hotkey for macro")
  end
  if not parent then
    parent = context.panel
  end  
  if hotkey:len() > 0 then
    hotkey = retranslateKeyComboDesc(hotkey)
  end
  
  -- min timeout is 50, to avoid lags
  if timeout < 50 then
    timeout = 50
  end
  
  table.insert(context._macros, {
    enabled = false,
    name = name,
    timeout = timeout,
    lastExecution = context.now + math.random(0, 100),
    hotkey = hotkey,    
  })
  local macro = context._macros[#context._macros]

  macro.isOn = function()
    return macro.enabled
  end
  macro.isOff = function()
    return not macro.enabled
  end
  macro.toggle = function(widget)
    if macro.isOn() then
      macro.setOff()
    else
      macro.setOn()
    end
  end
  macro.setOn = function(val)
    if val == false then
      return macro.setOff()
    end
    macro.enabled = true
    context.storage._macros[name] = true
    if macro.switch then
      macro.switch:setOn(true)
    end
    if macro.icon then
      macro.icon.setOn(true)
    end
  end
  macro.setOff = function(val)
    if val == false then
      return macro.setOn()
    end
    macro.enabled = false
    context.storage._macros[name] = false
    if macro.switch then
      macro.switch:setOn(false)
    end
    if macro.icon then
      macro.icon.setOn(false)
    end
  end
    
  if name:len() > 0 then
    -- creature switch
    local text = name
    if hotkey:len() > 0 then
      text = name .. " [" .. hotkey .. "]"
    end
    macro.switch = context.addSwitch("macro_" .. (#context._macros + 1), text, macro.toggle, parent)

    -- load state
    if context.storage._macros[name] == true then
      macro.setOn()
    end
  else
    macro.enabled = true -- unnamed macros are enabled by default
  end
      
  local desc = "lua"
  local info = debug.getinfo(2, "Sl")
  if info then
    desc = info.short_src .. ":" .. info.currentline
  end
  
  macro.callback = function(macro)
    if not macro.delay or macro.delay < context.now then
      context._currentExecution = macro
      local start = g_clock.realMillis()
      callback(macro)
      local executionTime = g_clock.realMillis() - start
      if executionTime > 100 then
        context.warning("Slow macro (" .. executionTime .. "ms): " .. macro.name .. " - " .. desc)
      end
      context._currentExecution = nil    
      return true
    end
  end
  return macro
end

-- hotkey(keys, callback)
-- hotkey(keys, name, callback)
-- hotkey(keys, name, callback, parent)
context.hotkey = function(keys, name, callback, parent, single)
  if type(name) == 'function' then
    callback = name
    name = ""
  end
  if not parent then
    parent = context.panel
  end
  keys = retranslateKeyComboDesc(keys)
  if not keys or #keys == 0 then
    return context.error("Invalid hotkey keys " .. tostring(name))
  end
  if context._hotkeys[keys] then
    return context.error("Duplicated hotkey: " .. keys)
  end

  local switch = nil
  if name:len() > 0 then
    switch = context._addHotkeySwitch(name, keys, parent)
  end

  context._hotkeys[keys] = {
    name = name,
    lastExecution = context.now,
    switch = switch,
    single = single
  }
  
  local desc = "lua"
  local info = debug.getinfo(2, "Sl")
  if info then
    desc = info.short_src .. ":" .. info.currentline
  end

  local hotkeyData = context._hotkeys[keys]
  hotkeyData.callback = function()
    if not hotkeyData.delay or hotkeyData.delay < context.now then
      context._currentExecution = hotkeyData       
      local start = g_clock.realMillis()
      callback()
      local executionTime = g_clock.realMillis() - start
      if executionTime > 100 then
        context.warning("Slow hotkey (" .. executionTime .. "ms): " .. hotkeyData.name .. " - " .. desc)
      end
      context._currentExecution = nil
      return true
    end
  end

  return hotkeyData
end

-- singlehotkey(keys, callback)
-- singlehotkey(keys, name, callback)
-- singlehotkey(keys, name, callback, parent)
context.singlehotkey = function(keys, name, callback, parent)
  if type(name) == 'function' then
    callback = name
    name = ""
  end
  return context.hotkey(keys, name, callback, parent, true) 
end  

-- schedule(timeout, callback)
context.schedule = function(timeout, callback)
  local extecute_time = g_clock.millis() + timeout
  table.insert(context._scheduler, {
    execution = extecute_time,
    callback = callback
  })
  table.sort(context._scheduler, function(a, b) return a.execution < b.execution end)
end

-- delay(duration) -- block execution of current macro/hotkey/callback for x milliseconds
context.delay = function(duration)
  if not context._currentExecution then
    return context.error("Invalid usage of delay function, it should be used inside callbacks")
  end
  context._currentExecution.delay = context.now + duration
end
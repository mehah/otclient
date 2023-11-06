local cavebotMacro = nil
local config = nil

-- ui
local configWidget = UI.Config()
local ui = UI.createWidget("CaveBotPanel")

ui.list = ui.listPanel.list -- shortcut
CaveBot.actionList = ui.list

if CaveBot.Editor then
  CaveBot.Editor.setup()
end
if CaveBot.Config then
  CaveBot.Config.setup()
end
for extension, callbacks in pairs(CaveBot.Extensions) do
  if callbacks.setup then
    callbacks.setup()
  end
end

-- main loop, controlled by config
local actionRetries = 0
local prevActionResult = true
cavebotMacro = macro(20, function()
  if TargetBot and TargetBot.isActive() and not TargetBot.isCaveBotActionAllowed() then
    CaveBot.resetWalking()
    return -- target bot or looting is working, wait
  end
  
  if CaveBot.doWalking() then
    return -- executing walking
  end
  
  local actions = ui.list:getChildCount()
  if actions == 0 then return end
  local currentAction = ui.list:getFocusedChild()
  if not currentAction then
    currentAction = ui.list:getFirstChild()
  end
  local action = CaveBot.Actions[currentAction.action]  
  local value = currentAction.value
  local retry = false
  if action then
    local status, result = pcall(function()
      CaveBot.resetWalking()
      return action.callback(value, actionRetries, prevActionResult)
    end)
    if status then
      if result == "retry" then
        actionRetries = actionRetries + 1
        retry = true
      elseif type(result) == 'boolean' then
        actionRetries = 0
        prevActionResult = result
      else
        error("Invalid return from cavebot action (" .. currentAction.action .. "), should be \"retry\", false or true, is: " .. tostring(result))
      end
    else
      error("Error while executing cavebot action (" .. currentAction.action .. "):\n" .. result)
    end    
  else
    error("Invalid cavebot action: " .. currentAction.action)
  end
  
  if retry then
    return
  end
  
  if currentAction ~= ui.list:getFocusedChild() then
    -- focused child can change durring action, get it again and reset state
    currentAction = ui.list:getFocusedChild() or ui.list:getFirstChild()
    actionRetries = 0
    prevActionResult = true
  end
  local nextAction = ui.list:getChildIndex(currentAction) + 1
  if nextAction > actions then
    nextAction = 1
  end
  ui.list:focusChild(ui.list:getChildByIndex(nextAction))
end)

-- config, its callback is called immediately, data can be nil
local lastConfig = ""
config = Config.setup("cavebot_configs", configWidget, "cfg", function(name, enabled, data)
  if enabled and CaveBot.Recorder.isOn() then
    CaveBot.Recorder.disable()
    CaveBot.setOff()
    return    
  end

  local currentActionIndex = ui.list:getChildIndex(ui.list:getFocusedChild())
  ui.list:destroyChildren()
  if not data then return cavebotMacro.setOff() end
  
  local cavebotConfig = nil
  for k,v in ipairs(data) do
    if type(v) == "table" and #v == 2 then
      if v[1] == "config" then
        local status, result = pcall(function()
          return json.decode(v[2])
        end)
        if not status then
          error("Error while parsing CaveBot extensions from config:\n" .. result)
        else
          cavebotConfig = result
        end
      elseif v[1] == "extensions" then
        local status, result = pcall(function()
          return json.decode(v[2])
        end)
        if not status then
          error("Error while parsing CaveBot extensions from config:\n" .. result)
        else
          for extension, callbacks in pairs(CaveBot.Extensions) do
            if callbacks.onConfigChange then
              callbacks.onConfigChange(name, enabled, result[extension])
            end
          end
        end
      else
        CaveBot.addAction(v[1], v[2])
      end
    end
  end

  CaveBot.Config.onConfigChange(name, enabled, cavebotConfig)
  
  actionRetries = 0
  CaveBot.resetWalking()
  prevActionResult = true
  cavebotMacro.setOn(enabled)
  cavebotMacro.delay = nil
  if lastConfig == name then 
    -- restore focused child on the action list
    ui.list:focusChild(ui.list:getChildByIndex(currentActionIndex))
  end
  lastConfig = name  
end)

-- ui callbacks
ui.showEditor.onClick = function()
  if not CaveBot.Editor then return end
  if ui.showEditor:isOn() then
    CaveBot.Editor.hide()
    ui.showEditor:setOn(false)
  else
    CaveBot.Editor.show()
    ui.showEditor:setOn(true)
  end
end

ui.showConfig.onClick = function()
  if not CaveBot.Config then return end
  if ui.showConfig:isOn() then
    CaveBot.Config.hide()
    ui.showConfig:setOn(false)
  else
    CaveBot.Config.show()
    ui.showConfig:setOn(true)
  end
end

-- public function, you can use them in your scripts
CaveBot.isOn = function()
  return config.isOn()
end

CaveBot.isOff = function()
  return config.isOff()
end

CaveBot.setOn = function(val)
  if val == false then  
    return CaveBot.setOff(true)
  end
  config.setOn()
end

CaveBot.setOff = function(val)
  if val == false then  
    return CaveBot.setOn(true)
  end
  config.setOff()
end

CaveBot.delay = function(value)
  cavebotMacro.delay = math.max(cavebotMacro.delay or 0, now + value)
end

CaveBot.gotoLabel = function(label)
  label = label:lower()
  for index, child in ipairs(ui.list:getChildren()) do
    if child.action == "label" and child.value:lower() == label then    
      ui.list:focusChild(child)
      return true
    end
  end
  return false
end

CaveBot.save = function()
  local data = {}
  for index, child in ipairs(ui.list:getChildren()) do
    table.insert(data, {child.action, child.value})
  end
  
  if CaveBot.Config then
    table.insert(data, {"config", json.encode(CaveBot.Config.save())})
  end
  
  local extension_data = {}
  for extension, callbacks in pairs(CaveBot.Extensions) do
    if callbacks.onSave then
      local ext_data = callbacks.onSave()
      if type(ext_data) == "table" then
        extension_data[extension] = ext_data
      end
    end
  end
  table.insert(data, {"extensions", json.encode(extension_data, 2)})
  config.save(data)
end

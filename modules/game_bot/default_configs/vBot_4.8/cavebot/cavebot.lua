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
    return -- executing walking3
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
        warn("Invalid return from cavebot action (" .. currentAction.action .. "), should be \"retry\", false or true, is: " .. tostring(result))
      end
    else
      warn("warn while executing cavebot action (" .. currentAction.action .. "):\n" .. result)
    end    
  else
    warn("Invalid cavebot action: " .. currentAction.action)
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
          warn("warn while parsing CaveBot extensions from config:\n" .. result)
        else
          cavebotConfig = result
        end
      elseif v[1] == "extensions" then
        local status, result = pcall(function()
          return json.decode(v[2])
        end)
        if not status then
          warn("warn while parsing CaveBot extensions from config:\n" .. result)
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

CaveBot.getCurrentProfile = function()
  return storage._configs.cavebot_configs.selected
end

CaveBot.lastReachedLabel = function()
  return vBot.lastLabel
end

CaveBot.gotoNextWaypointInRange = function()
  local currentAction = ui.list:getFocusedChild()
  local index = ui.list:getChildIndex(currentAction)
  local actions = ui.list:getChildren()

  -- start searching from current index
  for i, child in ipairs(actions) do
    if i > index then
      local text = child:getText()
      if string.starts(text, "goto:") then
        local re = regexMatch(text, [[(?:goto:)([^,]+),([^,]+),([^,]+)]])
        local pos = {x = tonumber(re[1][2]), y = tonumber(re[1][3]), z = tonumber(re[1][4])}
        
        if posz() == pos.z then
          local maxDist = storage.extras.gotoMaxDistance
          if distanceFromPlayer(pos) <= maxDist then
            if findPath(player:getPosition(), pos, maxDist, { ignoreNonPathable = true }) then
              ui.list:focusChild(ui.list:getChildByIndex(i-1))
              return true
            end
          end
        end
      end
    end
  end

  -- if not found then damn go from start
  for i, child in ipairs(actions) do
    if i <= index then
      local text = child:getText()
      if string.starts(text, "goto:") then
        local re = regexMatch(text, [[(?:goto:)([^,]+),([^,]+),([^,]+)]])
        local pos = {x = tonumber(re[1][2]), y = tonumber(re[1][3]), z = tonumber(re[1][4])}

        if posz() == pos.z then
          local maxDist = storage.extras.gotoMaxDistance
          if distanceFromPlayer(pos) <= maxDist then
            if findPath(player:getPosition(), pos, maxDist, { ignoreNonPathable = true }) then
              ui.list:focusChild(ui.list:getChildByIndex(i-1))
              return true
            end
          end
        end
      end
    end
  end

  -- not found
  return false
end

local function reverseTable(t, max)
  local reversedTable = {}
  local itemCount = max or #t
  for i, v in ipairs(t) do
      reversedTable[itemCount + 1 - i] = v
  end
  return reversedTable
end

function rpairs(t)
  test()
	return function(t, i)
		i = i - 1
		if i ~= 0 then
			return i, t[i]
		end
	end, t, #t + 1
end

CaveBot.gotoFirstPreviousReachableWaypoint = function()
  local currentAction = ui.list:getFocusedChild()
  local currentIndex = ui.list:getChildIndex(currentAction)
  local index = ui.list:getChildIndex(currentAction)

  -- check up to 100 childs
  for i=0,100 do
    index = index - i
    if index <= 0 or index > currentIndex or math.abs(index-currentIndex) > 100 then
      break
    end

    local child = ui.list:getChildByIndex(index)

    if child then
      local text = child:getText()
      if string.starts(text, "goto:") then
        local re = regexMatch(text, [[(?:goto:)([^,]+),([^,]+),([^,]+)]])
        local pos = {x = tonumber(re[1][2]), y = tonumber(re[1][3]), z = tonumber(re[1][4])}

        if posz() == pos.z then
          if distanceFromPlayer(pos) <= storage.extras.gotoMaxDistance/2 then
            print("found pos, going back "..currentIndex-index.. " waypoints.")
            return ui.list:focusChild(child)
          end
        end
      end
    end
  end

  -- not found
  print("previous pos not found, proceeding")
  return false
end

CaveBot.getFirstWaypointBeforeLabel = function(label)
  label = "label:"..label
  label = label:lower()
  local actions = ui.list:getChildren()
  local index

  -- find index of label
  for i, child in pairs(actions) do
    local name = child:getText():lower()
    if name == label then
      index = i
      break
    end
  end

  -- if there's no index then label was not found
  if not index then return false end

  for i=1,#actions do
    if index - 1 < 1 then
      -- did not found any waypoint in range before label 
      return false
    end

    local child = ui.list:getChildByIndex(index-i)
    if child then
      local text = child:getText()
      if string.starts(text, "goto:") then
        local re = regexMatch(text, [[(?:goto:)([^,]+),([^,]+),([^,]+)]])
        local pos = {x = tonumber(re[1][2]), y = tonumber(re[1][3]), z = tonumber(re[1][4])}

        if posz() == pos.z then
          if distanceFromPlayer(pos) <= storage.extras.gotoMaxDistance/2 then
            return ui.list:focusChild(child)
          end
        end
      end
    end
  end
end

CaveBot.getPreviousLabel = function()
  local actions = ui.list:getChildren()
  -- check if config is empty
  if #actions == 0 then return false end

  local currentAction = ui.list:getFocusedChild()
  --check we made any progress in waypoints, if no focused or first then no point checking
  if not currentAction or currentAction == ui.list:getFirstChild() then return false end

  local index = ui.list:getChildIndex(currentAction)

  -- if not index then something went wrong and there's no selected child
  if not index then return false end

  for i=1,#actions do
    if index - i < 1 then
      -- did not found any waypoint in range before label 
      return false
    end

    local child = ui.list:getChildByIndex(index-i)
    if child then
      if child.action == "label" then
        return child.value
      end
    end
  end
end

CaveBot.getNextLabel = function()
  local actions = ui.list:getChildren()
  -- check if config is empty
  if #actions == 0 then return false end

  local currentAction = ui.list:getFocusedChild() or ui.list:getFirstChild()
  local index = ui.list:getChildIndex(currentAction)

  -- if not index then something went wrong
  if not index then return false end

  for i=1,#actions do
    if index + i > #actions then
      -- did not found any waypoint in range before label 
      return false
    end

    local child = ui.list:getChildByIndex(index+i)
    if child then
      if child.action == "label" then
        return child.value
      end
    end
  end
end

local botConfigName = modules.game_bot.contentsPanel.config:getCurrentOption().text
CaveBot.setCurrentProfile = function(name)
  if not g_resources.fileExists("/bot/"..botConfigName.."/cavebot_configs/"..name..".cfg") then
    return warn("there is no cavebot profile with that name!")
  end
  CaveBot.setOff()
  storage._configs.cavebot_configs.selected = name
  CaveBot.setOn()
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

CaveBotList = function()
  return ui.list
end
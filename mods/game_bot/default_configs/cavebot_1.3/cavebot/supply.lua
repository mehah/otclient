CaveBot.Extensions.Supply = {}

local ui

-- first function called, here you should setup your UI
CaveBot.Extensions.Supply.setup = function()
  --ui = UI.createWidget('SupplyItemList')
  --local widget = UI.createWidget('SupplyItem', ui.list)
  --widget.item.onItemChange = function(newItem)
  --widget.fields.min.onTextChange = function(newText)
  -- make it similar to UI.Container, so if there are no free slots, add another one, keep min 4 slots, check if value min/max is number after edit
end

-- called when cavebot config changes, configData is a table but it can be nil
CaveBot.Extensions.Supply.onConfigChange = function(configName, isEnabled, configData)
  if not configData then return end
  
end

-- called when cavebot is saving config, should return table or nil
CaveBot.Extensions.Supply.onSave = function()
  return {}
end

-- bellow add you custom functions
-- this function can be used in cavebot function waypoint as: return Supply.run(retries, prev)
-- there are 2 useful parameters - retries (number) and prev (true/false), check actions.lua to learn more
CaveBot.Extensions.Supply.run = function(retries, prev)
  return true
end

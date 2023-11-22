CaveBot.Extensions.Depositer = {}

local ui

-- first function called, here you should setup your UI
CaveBot.Extensions.Depositer.setup = function()
  --ui = UI.createWidget('Label')
  --ui:setText("Depositer UI")
end

-- called when cavebot config changes, configData is a table but it can be nil
CaveBot.Extensions.Depositer.onConfigChange = function(configName, isEnabled, configData)
  if not configData then return end
  
end

-- called when cavebot is saving config, should return table or nil
CaveBot.Extensions.Depositer.onSave = function()
  return {}
end

-- bellow add you custom functions
-- this function can be used in cavebot function waypoint as: return Depositer.run(retries, prev)
-- there are 2 useful parameters - retries (number) and prev (true/false), check actions.lua to learn more
CaveBot.Extensions.Depositer.run = function(retries, prev)
  return true
end

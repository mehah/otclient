-- example cavebot extension (remember to add this file to ../cavebot.lua)
CaveBot.Extensions.Example = {}

local ui

-- setup is called automaticly when cavebot is ready
CaveBot.Extensions.Example.setup = function()
  ui = UI.createWidget('BotTextEdit')
  ui:setText("Hello")
  ui.onTextChange = function()
    CaveBot.save() -- save new config when you change something
  end

  -- add custom cavebot action (check out actions.lua)
  CaveBot.registerAction("sayhello", "orange", function(value, retries, prev)
    local how_many_times = tonumber(value)
    if retries >= how_many_times then
      return true
    end
    say("hello " .. (retries + 1))
    delay(250)
    return "retry"
  end)

  -- add this custom action to editor (check out editor.lua)
  CaveBot.Editor.registerAction("sayhello", "say hello", {
    value="5",
    title="Say hello",
    description="Says hello x times",
    validation="[0-9]{1,5}" -- regex, optional
  })  
end

-- called when cavebot config changes, configData is a table but it can also be nil
CaveBot.Extensions.Example.onConfigChange = function(configName, isEnabled, configData)
  if not configData then return end
  if configData["text"] then
    ui:setText(configData["text"])
  end
end

-- called when cavebot is saving config (so when CaveBot.save() is called), should return table or nil
CaveBot.Extensions.Example.onSave = function()
  return {text=ui:getText()}
end

-- bellow add you custom functions to be used in cavebot function action
-- an example: return Example.run(retries, prev)
-- there are 2 useful parameters - retries (number) and prev (true/false), check actions.lua and example_functions.lua to learn more
CaveBot.Extensions.Example.run = function(retries, prev)
  -- it will say text 10 times with some delay and then continue
  if retries > 10 then
    return true
  end
  say(ui:getText() .. " x" .. retries)
  delay(100 + retries * 100)
  return "retry"
end

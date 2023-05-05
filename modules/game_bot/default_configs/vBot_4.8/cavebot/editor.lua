CaveBot.Editor = {}
CaveBot.Editor.Actions = {}

-- also works as registerAction(action, params), then text == action
-- params are options for text editor or function to be executed when clicked
-- you have many examples how to use it bellow
CaveBot.Editor.registerAction = function(action, text, params)
  if type(text) ~= 'string' then
    params = text
    text = action
  end

  local color = nil
  if type(params) ~= 'function' then
    local raction = CaveBot.Actions[action]
    if not raction then
      return warn("CaveBot editor warn: action " .. action .. " doesn't exist")
    end
    CaveBot.Editor.Actions[action] = params
    color = raction.color
  end
  
  local button = UI.createWidget('CaveBotEditorButton', CaveBot.Editor.ui.buttons)
  button:setText(text)
  if color then
    button:setColor(color)
  end
  button.onClick = function()    
    if type(params) == 'function' then
      params()
      return
    end
    CaveBot.Editor.edit(action, nil, function(action, value)
      local focusedAction = CaveBot.actionList:getFocusedChild()
      local index = CaveBot.actionList:getChildCount()
      if focusedAction then
        index = CaveBot.actionList:getChildIndex(focusedAction)
      end
      local widget = CaveBot.addAction(action, value)
      CaveBot.actionList:moveChildToIndex(widget, index + 1)
      CaveBot.actionList:focusChild(widget)
      CaveBot.save()
    end)
  end
  return button
end

CaveBot.Editor.setup = function()
  CaveBot.Editor.ui = UI.createWidget("CaveBotEditorPanel")
  local ui = CaveBot.Editor.ui
  local registerAction = CaveBot.Editor.registerAction

  registerAction("move up", function()
    local action = CaveBot.actionList:getFocusedChild()
    if not action then return end
    local index = CaveBot.actionList:getChildIndex(action)
    if index < 2 then return end
    CaveBot.actionList:moveChildToIndex(action, index - 1)
    CaveBot.actionList:ensureChildVisible(action)
    CaveBot.save()
  end)
  registerAction("edit", function()
    local action = CaveBot.actionList:getFocusedChild()
    if not action or not action.onDoubleClick then return end
    action.onDoubleClick(action)
  end)
  registerAction("move down", function()
    local action = CaveBot.actionList:getFocusedChild()
    if not action then return end
    local index = CaveBot.actionList:getChildIndex(action)
    if index >= CaveBot.actionList:getChildCount() then return end
    CaveBot.actionList:moveChildToIndex(action, index + 1)
    CaveBot.actionList:ensureChildVisible(action)
    CaveBot.save()
  end)
  registerAction("remove", function()
    local action = CaveBot.actionList:getFocusedChild()
    if not action then return end
    action:destroy()
    CaveBot.save()
  end)
    
  registerAction("label", {
    value="labelName",
    title="Label",
    description="Add label",
    multiline=false   
  })
  registerAction("delay", {
    value="500",
    title="Delay",
    description="Delay next action (in milliseconds),randomness (in percent-optional)",
    multiline=false,
    validation="^[0-9]{1,10}$|^[0-9]{1,10},[0-9]{1,4}$"
  })
  registerAction("gotolabel", "go to label", {
    value="labelName",
    title="Go to label",
    description="Go to label",
    multiline=false   
  })
  registerAction("goto", "go to", {
    value=function() return posx() .. "," .. posy() .. "," .. posz() end,
    title="Go to position",
    description="Go to position (x,y,z)",
    multiline=false,
    validation="^\\s*([0-9]+)\\s*,\\s*([0-9]+)\\s*,\\s*([0-9]+),?\\s*([0-9]?)$"
  })
  registerAction("use", {
    value=function() return posx() .. "," .. posy() .. "," .. posz() end,
    title="Use",
    description="Use item from position (x,y,z) or from inventory (itemId)",
    multiline=false   
  }) 
  registerAction("usewith", "use with", {
    value=function() return "itemId," .. posx() .. "," .. posy() .. "," .. posz() end,
    title="Use with",
    description="Use item at position (itemid,x,y,z)",
    multiline=false,
    validation="^\\s*([0-9]+)\\s*,\\s*([0-9]+)\\s*,\\s*([0-9]+)\\s*,\\s*([0-9]+)$"
  })
  registerAction("say", {
    value="text",
    title="Say",
    description="Enter text to say",
    multiline=false   
  }) 
  registerAction("follow", {
    value="NPC name",
    title="Follow Creature",
    description="insert creature name to follow",
    multiline=false   
  })
  registerAction("npcsay", {
    value="text",
    title="NPC Say",
    description="Enter text to NPC say",
    multiline=false   
  }) 
  registerAction("function", {
    title="Edit bot function",
    multiline=true,
    value=CaveBot.Editor.ExampleFunctions[1][2],
    examples=CaveBot.Editor.ExampleFunctions,
    width=650
  })
  
  ui.autoRecording.onClick = function()
    if ui.autoRecording:isOn() then
      CaveBot.Recorder.disable()
    else
      CaveBot.Recorder.enable()
    end
  end
  
  -- callbacks
  onPlayerPositionChange(function(pos)
    ui.pos:setText("Position: " .. pos.x .. ", " .. pos.y .. ", " .. pos.z) 
  end)
  ui.pos:setText("Position: " .. posx() .. ", " .. posy() .. ", " .. posz()) 
end

CaveBot.Editor.show = function()
  CaveBot.Editor.ui:show()
end


CaveBot.Editor.hide = function()
  CaveBot.Editor.ui:hide()
end

CaveBot.Editor.edit = function(action, value, callback) -- callback = function(action, value)
  local params = CaveBot.Editor.Actions[action]
  if not params then return end
  if not value then
    if type(params.value) == 'function' then
      value = params.value()
    elseif type(params.value) == 'string' then
      value = params.value
    end
  end

  UI.EditorWindow(value, params, function(newText)
    callback(action, newText)
  end)   
end

local context = G.botContext
if type(context.UI) ~= "table" then
  context.UI = {}
end
local UI = context.UI

UI.createWidget = function(name, parent)
  if parent == nil then      
    parent = context.panel
  end
  local widget = g_ui.createWidget(name, parent)
  widget.botWidget = true
  return widget
end

UI.createMiniWindow = function(name, parent)
  if parent == nil then      
    parent = modules.game_interface.getRightPanel()
  end
  local widget = g_ui.createWidget(name, parent)
  widget:setup()
  widget.botWidget = true
  return widget
end

UI.createWindow = function(name)
  local widget = g_ui.createWidget(name, g_ui.getRootWidget())
  widget.botWidget = true  
  widget:show()
  widget:raise()
  widget:focus()
  return widget
end
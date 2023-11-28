local context = G.botContext

context.encode = function(data, indent) return json.encode(data, indent or 2) end
context.decode = function(text) local status, result = pcall(function() return json.decode(text) end) if status then return result end return {} end

context.displayGeneralBox = function(title, message, buttons, onEnterCallback, onEscapeCallback)
  local box = displayGeneralBox(title, message, buttons, onEnterCallback, onEscapeCallback)
  box.botWidget = true
  return box
end

context.doScreenshot = function(filename)
  g_app.doScreenshot(filename)
end
context.screenshot = context.doScreenshot

context.getVersion = function()
  return g_app.getVersion()
end
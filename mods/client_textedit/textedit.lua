local activeWindow

function init()
  g_ui.importStyle('textedit')

  connect(g_game, { onGameEnd = destroyWindow })
end

function terminate()
  disconnect(g_game, { onGameEnd = destroyWindow })

  destroyWindow()
end

function destroyWindow()
  if activeWindow then
    activeWindow:destroy()
    activeWindow = nil
  end
end

-- also works as show(text, callback)
function show(text, options, callback) -- callback = function(newText)
  --[[
    Available options:
      title = text
      description = text
      multiline = true / false
      width = number
      validation = text (regex)
      range = {number, number}
      examples = {{name, text}, {name, text}}
  ]]
     --
  if type(text) == 'userdata' then
    local widget = text
    callback = function(newText)
      widget:setText(newText)
    end
    text = widget:getText()
  elseif type(text) == 'number' then
    text = tostring(text)
  elseif type(text) == 'nil' then
    text = ''
  elseif type(text) ~= 'string' then
    return error("Invalid text type for client_textedit: " .. type(text))
  end
  if type(options) == 'function' then
    local tmp = callback
    callback = options
    options = callback
  end
  options = options or {}

  if activeWindow then
    destroyWindow()
  end

  local window
  if options.multiline then
    window = g_ui.createWidget('MultilineTextEditWindow', rootWidget)
    window.text = window.textPanel.text
  else
    window = g_ui.createWidget('SinglelineTextEditWindow', rootWidget)
  end
  -- functions
  local validate = function(text)
    if type(options.range) == 'table' then
      local value = tonumber(text)
      return value >= options.range[1] and value <= options.range[2]
    elseif type(options.validation) == 'string' and options.validation:len() > 0 then
      return #regexMatch(text, options.validation) == 1
    end
    return true
  end
  local destroy = function()
    window:destroy()
  end
  local doneFunc = function()
    local text = window.text:getText()
    if not validate(text) then return end
    destroy()
    if callback then
      callback(text)
    end
  end

  window.buttons.ok.onClick = doneFunc
  window.buttons.cancel.onClick = destroy
  if not options.multiline then
    window.onEnter = doneFunc
  end
  window.onEscape = destroy
  window.onDestroy = function()
    if window == activeWindow then
      activeWindow = nil
    end
  end

  if options.title then
    window:setText(options.title)
  end
  if options.description then
    window.description:show()
    window.description:setText(options.description)
  end
  if type(options.examples) == 'table' and #options.examples > 0 then
    window.examples:show()
    for i, title_text in ipairs(options.examples) do
      window.examples:addOption(title_text[1], title_text[2])
    end
    window.examples.onOptionChange = function(widget, option, data)
      window.text:setText(data)
      window.text:setCursorPos(-1)
    end
  end

  window.text:setText(text)
  window.text:setCursorPos(-1)

  window.text.onTextChange = function(widget, text)
    if validate(text) then
      window.buttons.ok:enable()
      if g_platform.isMobile() then
        doneFunc()
      end
    else
      window.buttons.ok:disable()
    end
  end

  if type(options.width) == 'number' then
    window:setWidth(options.width)
  end

  activeWindow = window
  activeWindow:raise()
  activeWindow:focus()
  if g_platform.isMobile() then
    window.text:focus()
    local flags = 0
    if options.multiline then
      flags = 1
    end
    g_window.showTextEditor(window:getText(), window.description:getText(), window.text:getText(), flags)
  end
  return activeWindow
end

function hide()
  destroyWindow()
end

function edit(...)
  return show(...)
end

-- legacy
function singlelineEditor(text, callback)
  return show(text, {}, callback)
end

-- legacy
function multilineEditor(description, text, callback)
  return show(text, { description = description, multiline = true }, callback)
end

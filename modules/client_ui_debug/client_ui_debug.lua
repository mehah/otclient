local clientUiDebug
local clientUiDebugLabel
local clientUiDebugHighlightWidget
local clientUiDebugActivateButton
local enabled = true

function onClientUiDebuggerMouseMove(mouseBindWidget, mousePos, mouseMove)
    local widgets = rootWidget:recursiveGetChildrenByPos(mousePos)

    local smallestWidget
local countLines = 1
    local widgetNames = {}
    for wi = #widgets, 1, -1 do
        local widget = widgets[wi]
        if (widget:getId() ~= 'highlightWidget') then
            local text = widget:getClassName() .. '#' .. widget:getId()
            if wi % 2 == 0 then
                text = text .. "\n"
                countLines = countLines + 1
            end
            table.insert(widgetNames, text)
        end
    end
    clientUiDebugLabel:setText(table.concat(widgetNames, " -> "))
    clientUiDebug:setHeight(countLines * 20)
end

function activate()
  enabled = not enabled
  if enabled then
    clientUiDebugActivateButton:setText("Disable")
    connect(rootWidget, {
        onMouseMove = onClientUiDebuggerMouseMove,
    })
  else
    clientUiDebugActivateButton:setText("Enable")
    clientUiDebugHighlightWidget:setSize({0, 0})
    --clientUiDebugLabel:setText("")
    disconnect(rootWidget, {
        onMouseMove = onClientUiDebuggerMouseMove,
    })
  end
end

function init()
    connect(rootWidget, {
        onMouseMove = onClientUiDebuggerMouseMove,
    })
    clientUiDebug = g_ui.displayUI('client_ui_debug')
    clientUiDebugLabel = clientUiDebug:getChildById('clientUiDebugLabel')
    clientUiDebugHighlightWidget = g_ui.createWidget('HighlightWidget', rootWidget)
    clientUiDebugActivateButton = clientUiDebug:getChildById('activateButton')
    activate()
end

function terminate()
    disconnect(rootWidget, {
        onMouseMove = onClientUiDebuggerMouseMove,
    })
    clientUiDebug:destroy()
    clientUiDebugHighlightWidget:destroy()
    clientUiDebugActivateButton:destroy()
end

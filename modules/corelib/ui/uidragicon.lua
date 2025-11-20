UIDragIcon = {}
local uiIcon = nil

function UIDragIcon:display(item)
    if modules.client_options.getOption('showDragIcon') then
        uiIcon = g_ui.createWidget('UIDragIcon', rootWidget)
        uiIcon:setItem(item)
        uiIcon:setVirtual(true)
        uiIcon:setShowCount(false)
        uiIcon:show()
    end
    
    connect(rootWidget, { onMouseMove = onMouseMove })
end

function UIDragIcon:hide()
    if uiIcon ~= nil then
        uiIcon:hide()
    end
    disconnect(rootWidget, { onMouseMove = onMouseMove })
end

function onMouseMove(self, mousePos, mouseMoved)
    if uiIcon ~= nil then
        uiIcon:setPosition(mousePos)
    end
end
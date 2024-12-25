local debugInfoWindow = nil
local debugInfoButton = nil

local updateEvent = nil

function init()
    debugInfoButton = modules.client_topmenu.addTopRightToggleButton('debugInfoButton', tr('Debug Info'),
            '/images/topbuttons/debug', toggle)
    debugInfoButton:setOn(false)

    debugInfoWindow = g_ui.displayUI('debug_info')
    debugInfoWindow:hide()

    Keybind.new("Debug", "Toggle Stats", "Ctrl+Alt+D", "")
    Keybind.bind("Debug", "Toggle Stats", {
      {
        type = KEY_DOWN,
        callback = toggle,
      }
    })

    updateEvent = scheduleEvent(update, 2000)
end

function terminate()
    debugInfoWindow:destroy()
    debugInfoButton:destroy()

    Keybind.delete("Debug", "Toggle Stats")

    removeEvent(updateEvent)
end

function onClose()
    debugInfoButton:setOn(false)
end

function toggle()
    if debugInfoButton:isOn() then
        debugInfoWindow:hide()
        debugInfoButton:setOn(false)
    else
        debugInfoWindow:show()
        debugInfoWindow:raise()
        debugInfoWindow:focus()
        debugInfoButton:setOn(true)
    end
end

function update()
    updateEvent = scheduleEvent(update, 20)

    if not debugInfoWindow:isVisible() then
        return
    end

    if g_proxy then
        local text = ""
        local proxiesDebug = g_proxy.getProxiesDebugInfo()
        for proxy_name, proxy_debug in pairs(proxiesDebug) do
            text = text .. proxy_name .. " - " .. proxy_debug .. "\n"
        end
        debugInfoWindow.debugPanel.proxies:setText(text)
    end
end

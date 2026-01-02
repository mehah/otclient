tibiaInspect = nil
function init()
    tibiaInspect = g_ui.displayUI('styles/inspectItem')
    hide()

    connect(g_game, { onInspection = onInspection, onGameStart = hide, onGameEnd = hide })
end

function terminate()
    if tibiaInspect then
        tibiaInspect:destroy()
        tibiaInspect = nil
    end

    disconnect(g_game, { onInspection = onInspection, onGameStart = hide, onGameEnd = hide })
end

function toggle()
    if tibiaInspect:isVisible() then
        tibiaInspect:unlock()
        tibiaInspect:hide()
    else
        tibiaInspect:show(true)
        tibiaInspect:lock()
    end
end

function hide()
    tibiaInspect:unlock()
    tibiaInspect:hide()
end

function show()
    tibiaInspect:show(true)
    tibiaInspect:lock()
end

function proficiency()
    if currentItemId <= 0 then
        return
    end

    tibiaInspect:unlock()
    g_game.inspectionObject(4, currentItemId, 0)
end

local lastInspection = ""
function onInspection(inspectType, itemName, item, descriptions)
    if inspectType > 0 then
        return
    end
    show()

    tibiaInspect.contentPanel.item:setItemId(item:getId())
    currentItemId = item:getId()
    tibiaInspect.contentPanel.item:getItem():setTier(item:getTier())
    tibiaInspect.contentPanel.name:setText("You are inspecting: " .. itemName)

    tibiaInspect.contentPanel.itemInfo:destroyChildren()
    for _, data in pairs(descriptions) do
        local widget = g_ui.createWidget("InspectLabel", tibiaInspect.contentPanel.itemInfo)
        widget.label:setText(data[1] .. ":")
        data[2] = data[2] or "N/A"
        widget.content:setText(data[2])

        if #data[2] > 30 then
            local wrappedLines = widget.content:getWrappedLinesCount(20)
            if wrappedLines == 1 then
                widget:setSize(tosize("270 " .. 19 * (wrappedLines + 1)))
            else
                widget:setSize(tosize("270 " .. 21 * (wrappedLines)))
            end
        end
    end
end

function clipboard()
    local text = ""
    local children = tibiaInspect.contentPanel.itemInfo:getChildren()

    for _, widget in ipairs(children) do
        local label = widget.label:getText()
        local content = widget.content:getText()
        text = text .. label .. " " .. content .. "\n"
    end

    if text ~= "" then
        g_window.setClipboardText(text)
    end
end

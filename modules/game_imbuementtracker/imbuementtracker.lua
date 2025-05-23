local IMBUEMENTTRACKER_SLOTS = {
    INVENTORYSLOT_HEAD = 1,
    INVENTORYSLOT_BACKPACK = 3,
    INVENTORYSLOT_ARMOR = 4,
    INVENTORYSLOT_RIGHT = 5,
    INVENTORYSLOT_LEFT = 6,
    INVENTORYSLOT_FEET = 8
}

local IMBUEMENTTRACKER_FILTERS = {
    ["showLessThan1h"] = true,
    ["showBetween1hAnd3h"] = true,
    ["showMoreThan3h"] = true,
    ["showNoImbuements"] = true
}

imbuementTrackerButton = nil
imbuementTrackerMenuButton = nil

function loadFilters()
    local settings = g_settings.getNode("ImbuementTracker")
    if not settings or not settings['filters'] then
        return IMBUEMENTTRACKER_FILTERS
    end
    return settings['filters']
end

function saveFilters()
    g_settings.mergeNode('ImbuementTracker', { ['filters'] = loadFilters() })
end

function getFilter(filter)
    return loadFilters()[filter] or false
end

function setFilter(filter)
    local filters = loadFilters()
    local value = filters[filter]
    if value == nil then
        return false
    end
    
    filters[filter] = not value
    g_settings.mergeNode('ImbuementTracker', { ['filters'] = filters })    
    g_game.imbuementDurations(imbuementTrackerButton:isOn())
end

function initialize()
    g_ui.importStyle('imbuementtracker')
    connect(g_game, {
        onGameStart = onGameStart,
        onGameEnd = onGameEnd,
        onUpdateImbuementTracker = onUpdateImbuementTracker
    })
    
    imbuementTracker = g_ui.createWidget('ImbuementTracker', modules.game_interface.getRightPanel())

    imbuementTracker.menuButton.onClick = function(widget, mousePos, mouseButton)
        local menu = g_ui.createWidget('ImbuementTrackerMenu')
        menu:setGameMenu(true)
        for _, choice in ipairs(menu:getChildren()) do
            local choiceId = choice:getId()
            choice:setChecked(getFilter(choiceId))
            choice.onCheckChange = function()
                setFilter(choiceId)
                menu:destroy()
            end
        end
        menu:display(mousePos)
        return true
    end

    imbuementTracker:moveChildToIndex(imbuementTracker.menuButton, 4)
    imbuementTracker:setup()
    imbuementTracker:hide()
end

function onMiniWindowOpen()
    if imbuementTrackerButton then
        imbuementTrackerButton:setOn(true)
    end
end

function onMiniWindowClose()
    if imbuementTrackerButton then
        imbuementTrackerButton:setOn(false)
    end
end

function terminate()
    disconnect(g_game, {
        onGameStart = onGameStart,
        onGameEnd = onGameEnd,
        onUpdateImbuementTracker = onUpdateImbuementTracker
    })

    if imbuementTrackerButton then
        imbuementTrackerButton:destroy()
        imbuementTrackerButton = nil
    end
    imbuementTracker:destroy()
end

function toggle()
    if imbuementTrackerButton:isOn() then
        imbuementTrackerButton:setOn(false)
        imbuementTracker:close()
    else
        if not imbuementTracker:getParent() then
            local panel = modules.game_interface.findContentPanelAvailable(imbuementTracker, imbuementTracker:getMinimumHeight())
            if not panel then
                return
            end

            panel:addChild(imbuementTracker)
        end
        imbuementTracker:open()
        imbuementTrackerButton:setOn(true)
        -- updateHeight()
    end
    g_game.imbuementDurations(imbuementTrackerButton:isOn())
end

local function getTrackedItems(items)
    local trackedItems = {}
    for _, item in ipairs(items) do
        if table.contains(IMBUEMENTTRACKER_SLOTS, item['slot']) then
            trackedItems[#trackedItems + 1] = item
        end
    end
    return trackedItems
end

local function setDuration(label, duration)
    if duration == 0 then
        label:setVisible(false)
        return
    end
    local hours = math.floor(duration / 3600)
    local minutes = math.floor(duration / 60 - (hours * 60))
    if duration < 60 then
        label:setColor('#ff0000')
        label:setText(string.format('%2.fs', duration))
    elseif duration < 3600 then
        label:setColor('#ff0000')
        label:setText(string.format('%2.fm', minutes))
    elseif duration < 10800 then
        label:setColor('#ffff00')
        label:setText(string.format('%2.fh%02.f', hours, minutes))
    else
        label:setColor('#ffffff')
        label:setText(string.format('%02.fh', hours))
    end
    label:setVisible(true)
end

local function addTrackedItem(item)
    local trackedItem = g_ui.createWidget('InventoryItem')
    trackedItem.item:setItem(item['item'])
    ItemsDatabase.setTier(trackedItem.item, trackedItem.item:getItem())
    trackedItem.item:setVirtual(true)
    local maxDuration = 0
    for _, imbuementSlot in ipairs(item['slots']) do
        local slot = g_ui.createWidget('ImbuementSlot')
        slot:setId('slot' .. imbuementSlot['id'])
        slot:setImageSource('/images/game/imbuing/icons/' .. imbuementSlot['iconId'])
        slot:setMarginLeft(3)
        setDuration(slot.duration, imbuementSlot['duration'])
        trackedItem.imbuementSlots:addChild(slot)
        if imbuementSlot['duration'] > maxDuration then
            maxDuration = imbuementSlot['duration']
        end
    end
    return trackedItem, maxDuration
end

function onUpdateImbuementTracker(items)
    imbuementTracker.contentsPanel:destroyChildren()
    for _, item in ipairs(getTrackedItems(items)) do
        local trackedItem, duration = addTrackedItem(item)
        local show = true
        if duration == 0 and not getFilter('showNoImbuements') then
            show = false
        elseif duration > 0 and duration < 3600 and not getFilter('showLessThan1h') then
            show = false
        elseif duration >= 3600 and duration < 10800 and not getFilter('showBetween1hAnd3h') then
            show = false
        elseif duration >= 10800 and not getFilter('showMoreThan3h') then
            show = false
        end
        if show then imbuementTracker.contentsPanel:addChild(trackedItem) end
    end
end

function onGameStart()
    if g_game.getClientVersion() >= 1100 then
        imbuementTrackerButton = modules.game_mainpanel.addToggleButton('imbuementTrackerButton', tr('Imbuement Tracker'), '/images/options/button_imbuementtracker', toggle)
        g_game.imbuementDurations(imbuementTrackerButton:isOn())
        imbuementTracker:setupOnStart()
        loadFilters()
    end
end

function onGameEnd()
    imbuementTracker.contentsPanel:destroyChildren()
    saveFilters()
end


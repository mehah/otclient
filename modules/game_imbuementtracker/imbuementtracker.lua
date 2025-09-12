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
    
    -- Set minimum height for imbuement tracker window
    imbuementTracker:setContentMinimumHeight(80)

    -- Hide toggleFilterButton and adjust button positioning
    local toggleFilterButton = imbuementTracker:recursiveGetChildById('toggleFilterButton')
    if toggleFilterButton then
        toggleFilterButton:setVisible(false)
        toggleFilterButton:setOn(false)
    end
    
    -- Hide newWindowButton
    local newWindowButton = imbuementTracker:recursiveGetChildById('newWindowButton')
    if newWindowButton then
        newWindowButton:setVisible(false)
    end

    -- Make sure contextMenuButton is visible and set up its positioning and click handler
    local contextMenuButton = imbuementTracker:recursiveGetChildById('contextMenuButton')
    local lockButton = imbuementTracker:recursiveGetChildById('lockButton')
    local minimizeButton = imbuementTracker:recursiveGetChildById('minimizeButton')
    
    if contextMenuButton then
        contextMenuButton:setVisible(true)
        
        -- Position contextMenuButton where toggleFilterButton was (similar to containers without upButton)
        if minimizeButton then
            contextMenuButton:breakAnchors()
            contextMenuButton:addAnchor(AnchorTop, minimizeButton:getId(), AnchorTop)
            contextMenuButton:addAnchor(AnchorRight, minimizeButton:getId(), AnchorLeft)
            contextMenuButton:setMarginRight(7)
            contextMenuButton:setMarginTop(0)
        end
        
        -- Position lockButton to the left of contextMenu
        if lockButton then
            lockButton:breakAnchors()
            lockButton:addAnchor(AnchorTop, contextMenuButton:getId(), AnchorTop)
            lockButton:addAnchor(AnchorRight, contextMenuButton:getId(), AnchorLeft)
            lockButton:setMarginRight(2)
            lockButton:setMarginTop(0)
        end
        
        contextMenuButton.onClick = function(widget, mousePos, mouseButton)
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
    end

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
    
    -- Create a table to track which slots are active
    local activeSlots = {}
    for _, imbuementSlot in ipairs(item['slots']) do
        activeSlots[imbuementSlot['id']] = imbuementSlot
    end
    
    -- Add slots (both active and inactive) based on totalSlots
    local totalSlots = item['totalSlots'] or 0
    for slotIndex = 0, totalSlots - 1 do
        local imbuementSlot = activeSlots[slotIndex]
        if imbuementSlot then
            -- Active slot with imbuement
            local slot = g_ui.createWidget('ImbuementSlot')
            slot:setId('slot' .. imbuementSlot['id'])
            slot:setImageSource('/images/game/imbuing/icons/' .. imbuementSlot['iconId'])
            slot:setMarginLeft(3)
            setDuration(slot.duration, imbuementSlot['duration'])
            trackedItem.imbuementSlots:addChild(slot)
            if imbuementSlot['duration'] > maxDuration then
                maxDuration = imbuementSlot['duration']
            end
        else
            -- Inactive slot placeholder
            local inactiveSlot = g_ui.createWidget('ImbuementSlotInactive')
            inactiveSlot:setId('inactiveSlot' .. slotIndex)
            inactiveSlot:setMarginLeft(3)
            trackedItem.imbuementSlots:addChild(inactiveSlot)
        end
    end
    
    return trackedItem, maxDuration
end

function onUpdateImbuementTracker(items)
    imbuementTracker.contentsPanel:destroyChildren()
    for _, item in ipairs(getTrackedItems(items)) do
        local trackedItem, duration = addTrackedItem(item)
        local show = true
        local hasActiveImbuements = #item['slots'] > 0 and duration > 0
        local hasSlots = (item['totalSlots'] or 0) > 0
        
        -- Show items based on filters
        if not hasActiveImbuements and hasSlots and not getFilter('showNoImbuements') then
            -- Item has slots but no active imbuements, check showNoImbuements filter
            show = false
        elseif not hasActiveImbuements and not hasSlots then
            -- Item has no slots at all, don't show it
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


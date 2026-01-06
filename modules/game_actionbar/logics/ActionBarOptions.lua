-- checkbox client_options (data_options.lua)
function updateVisibleOptions(option, state)
    for _, actionbar in pairs(activeActionBars) do
        local childs = actionbar.tabBar:getChildren()
        for _, button in pairs(childs) do
            if button:isVisible() then
                if option == "hotkey" then
                    button.hotkeyLabel:setVisible(state)
                elseif option == "amount" then
                    button.item:setShowCount(state) --\src\client\uiitem.cpp L#55 need improve
                elseif option == "parameter" then
                    button.parameterText:setVisible(state)
                end
                if option == "tooltip" then
                    if not state then
                        button.item:setTooltip("")
                    else
                        setupButtonTooltip(button, false)
                    end
                end
            end
        end
    end
end
-- check boxcooldownSecond, graphicalCooldown  client_options (data_options.lua)
function toggleCooldownOption()
    local showTime = modules.client_options.getOption("cooldownSecond")
    local showProgress = modules.client_options.getOption("graphicalCooldown")

    for _, actionbar in pairs(activeActionBars) do
        for _, button in pairs(actionbar.tabBar:getChildren()) do
            local cache = getButtonCache(button)
            if cache.isSpell or cache.isRuneSpell then
                button.cooldown:showTime(showTime)
                button.cooldown:showProgress(showProgress)
            end
        end
    end
end

-- checkbox client_options (data_options.lua) bar all
function configureActionBar(barStr, visible)
    if not g_game.isOnline() then
        return
    end
    local bottom = string.find(barStr, "Bottom") ~= nil
    local left = string.find(barStr, "Left") ~= nil
    local right = string.find(barStr, "Right") ~= nil
    local actionNumber = tonumber(string.sub(barStr, -1))
    if bottom then
        local actionBar = actionBars[actionNumber]
        if not actionBar then
            return true
        end
        actionBar:setVisible(visible)
        actionBar:setOn(visible)
        ApiJson.setBarVisibility(actionNumber, "actionBarShowBottom" .. actionNumber, visible, true)
        resizeLockButtons()
        unbindActionBarEvent(actionBar)
        isLoaded = false
        setupActionBar(actionNumber)
        isLoaded = true
        if visible then
            addActiveActionBar(actionBar)
        else
            removeActiveActionBar(actionBar)
        end
        ActionBarController:scheduleEvent(function()
            updateVisibleWidgets()
            local bottomSplitter = modules.game_interface.getBottomSplitter()
            local bottomBars = getActiveBottomBars and getActiveBottomBars() or 0
            local minMargin = 118 + (35 * bottomBars)
            local adjustedMargin = bottomSplitter:canUpdateMargin(minMargin)

            if bottomSplitter:getMarginBottom() < adjustedMargin then
                bottomSplitter:setMarginBottom(adjustedMargin)
            end
        end, 10, "updateVisibleWidgetsBottom")
        updateActionBarEventSubscriptions()
        return
    end
    if left then
        local actionBar = actionBars[actionNumber + 3]
        if not actionBar then
            return true
        end
        actionBar:setVisible(visible)
        actionBar:setOn(visible)
        ApiJson.setBarVisibility(actionNumber + 3, "actionBarShowLeft" .. actionNumber, visible)
        resizeLockButtons()
        unbindActionBarEvent(actionBar)
        isLoaded = false
        setupActionBar(actionNumber + 3)
        isLoaded = true
        if visible then
            addActiveActionBar(actionBar)
        else
            removeActiveActionBar(actionBar)
        end
        ActionBarController:scheduleEvent(function()
            updateVisibleWidgets()
        end, 10, "updateVisibleWidgetsLeft")
        updateActionBarEventSubscriptions()
        return
    end
    if right then
        local actionBar = actionBars[actionNumber + 6]
        if not actionBar then
            return true
        end
        actionBar:setVisible(visible)
        actionBar:setOn(visible)
        ApiJson.setBarVisibility(actionNumber + 6, "actionBarShowRight" .. actionNumber, visible)
        resizeLockButtons()
        unbindActionBarEvent(actionBar)
        isLoaded = false
        setupActionBar(actionNumber + 6)
        isLoaded = true
        if visible then
            addActiveActionBar(actionBar)
        else
            removeActiveActionBar(actionBar)
        end
        ActionBarController:scheduleEvent(function()
            updateVisibleWidgets()
        end, 10, "updateVisibleWidgetsRight")
        updateActionBarEventSubscriptions()
        return
    end
end

-- boton reset
function resetActionBar()
    if not player then
        player = g_game.getLocalPlayer()
    end

    if dragButton and dragItem then
        resetDragWidget(dragItem, dragButton)
        dragItem = nil
        dragButton = nil
    end

    isLoaded = false
    for _, actionbar in pairs(activeActionBars) do
        for _, button in pairs(actionbar.tabBar:getChildren()) do
            if button.cache.hotkey then
                unbindHotkey(button.cache.hotkey)
                button.cache.hotkey = nil
                button.hotkeyLabel:setText("")
            end

            clearButton(button, false)
            resetButtonCache(button)
            updateButton(button)
        end
    end
    isLoaded = true
end

-- boton clean?
function resetSlots(slot)
    for _, actionbar in pairs(activeActionBars) do
        if actionbar:getId() == "actionbar." .. slot then
            for _, button in pairs(actionbar.tabBar:getChildren()) do
                if button.cache.hotkey then
                    unbindHotkey(button.cache.hotkey)
                    button.cache.hotkey = nil
                    button.hotkeyLabel:setText("")
                    ApiJson.removeHotkey(button:getId())
                end

                clearButton(button, false)
                resetButtonCache(button)
            end
            break
        end
    end
end


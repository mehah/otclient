stashWindow = nil
itemsPanel = nil
radioItemSet = nil
stashSelectAmount = nil
searchEdit = nil
stashItems = {}

function resetSelectAmount()
    if stashSelectAmount then
        stashSelectAmount:destroy()
        stashSelectAmount = nil
    end
end

function resetItems()
    if itemsPanel then
        itemsPanel:destroyChildren()
    end
    if radioItemSet then
        radioItemSet:destroy()
        radioItemSet = nil
    end
end

function prepareWithdraw(itemId, itemAmount)
    resetSelectAmount()

    stashSelectAmount = g_ui.createWidget('StashSelectAmount', rootWidget)
    stashSelectAmount:lock()

    local itembox = stashSelectAmount:getChildById('item')
    itembox:setItemId(itemId)
    itembox:setItemCount(itemAmount)

    local scrollbar = stashSelectAmount:getChildById('countScrollBar')
    scrollbar:setMaximum(itemAmount)
    scrollbar:setMinimum(1)
    scrollbar:setValue(itemAmount)
    scrollbar.onValueChange = function(self, value)
        itembox:setItemCount(value)
    end

    g_keyboard.bindKeyPress('Up', function()
        scrollbar:setValue(scrollbar:getValue() + 10)
    end, stashSelectAmount)
    g_keyboard.bindKeyPress('Down', function()
        scrollbar:setValue(scrollbar:getValue() - 10)
    end, stashSelectAmount)
    g_keyboard.bindKeyPress('Right', function()
        scrollbar:onIncrement()
    end, stashSelectAmount)
    g_keyboard.bindKeyPress('Left', function()
        scrollbar:onDecrement()
    end, stashSelectAmount)
    g_keyboard.bindKeyPress('PageUp', function()
        scrollbar:setValue(scrollbar:getMaximum())
    end, stashSelectAmount)
    g_keyboard.bindKeyPress('PageDown', function()
        scrollbar:setValue(scrollbar:getMinimum())
    end, stashSelectAmount)

    local okButton = stashSelectAmount:getChildById('buttonOk')
    local withdrawFunc = function()
        g_game.stashWithdraw(itemId, itembox:getItemCount(), 1)
        stashSelectAmount:unlock()
        resetSelectAmount()
    end
    local cancelButton = stashSelectAmount:getChildById('buttonCancel')
    local cancelFunc = function()
        stashSelectAmount:unlock()
        resetSelectAmount()
    end

    stashSelectAmount.onEnter = withdrawFunc
    stashSelectAmount.onEscape = cancelFunc

    okButton.onClick = withdrawFunc
    cancelButton.onClick = cancelFunc
end

function renderItems()
    if not g_game.isOnline() then
        return
    end
    resetItems()
    radioItemSet = UIRadioGroup.create()
    local searchFilter = searchEdit:getText()
    for itemId, amount in pairs(stashItems) do
        local thingType = g_things.getThingType(itemId, 0)
        if thingType then
            local itemName = thingType:getName()
            if not itemName or itemName:lower():find(searchFilter) then
                local item = Item.create(itemId)
                item:setCount(amount)
                local itemBox = g_ui.createWidget('StashItemBox', itemsPanel)
                itemBox:getChildById('item'):setItem(item)
                radioItemSet:addWidget(itemBox)
                if itemName then
                    itemBox:setTooltip(itemName)
                else
                    itemBox:setTooltip("Loading...")
                end
                g_mouse.bindPress(itemBox, function()
                    prepareWithdraw(itemId, amount)
                end, MouseLeftButton)
            end
        end
    end
    if stashWindow:isHidden() then
        stashWindow:show()
        stashWindow:lock()
    end
end

function onSupplyStashEnter(payload)
    stashItems = {}
    for i = 1, #payload do
        local itemId = payload[i][1]
        local amount = payload[i][2]
        stashItems[itemId] = amount
    end
    renderItems()
end

function onSupplyStashClose()
    stashItems = {}
    resetItems()
    resetSelectAmount()
    if searchEdit then
        searchEdit:setText('')
    end
    if not stashWindow:isHidden() then
        stashWindow:hide()
        stashWindow:unlock()
        modules.game_interface.getRootPanel():focus()
    end
end

function init()
    g_ui.importStyle('game_stash')
    connect(g_game, {
        onSupplyStashEnter = onSupplyStashEnter,
        onGameEnd = onSupplyStashClose,
    })
    stashWindow = g_ui.createWidget('StashWindow', rootWidget)
    stashWindow:hide()
    itemsPanel = stashWindow:recursiveGetChildById('itemsPanel')
    searchEdit = stashWindow:recursiveGetChildById('searchEdit')
end

function terminate()
    disconnect(g_game, {
        onSupplyStashEnter = onSupplyStashEnter,
        onGameEnd = onSupplyStashClose,
    })
    stashWindow:destroy()
end

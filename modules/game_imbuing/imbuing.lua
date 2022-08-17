Imbuing = {}
local imbuingWindow
local bankGold = 0
local inventoryGold = 0
local itemImbuements = {}
local emptyImbue
local groupsCombo
local imbueLevelsCombo
local protectionBtn
local clearImbue
local selectedImbue
local imbueItems = {}
local protection = false
local clearConfirmWindow
local imbueConfirmWindow

function init()
    connect(g_game, {
        onGameEnd = hide,
        onResourcesBalanceChange = Imbuing.onResourcesBalanceChange,
        onImbuementWindow = Imbuing.onImbuementWindow,
        onCloseImbuementWindow = Imbuing.onCloseImbuementWindow
    })

    imbuingWindow = g_ui.displayUI('imbuing')
    emptyImbue = imbuingWindow.emptyImbue
    groupsCombo = emptyImbue.groups
    imbueLevelsCombo = emptyImbue.imbuement
    protectionBtn = emptyImbue.protection
    clearImbue = imbuingWindow.clearImbue
    imbuingWindow:hide()
    local player = g_game.getLocalPlayer()
    if player then
        bankGold = player:getResourceBalance(ResourceTypes.BANK_BALANCE)
        inventoryGold = player:getResourceBalance(ResourceTypes.GOLD_EQUIPPED)
        imbuingWindow.balance:setText(tr('Balance') .. ':\n' .. (player:getTotalMoney()))
    end

    groupsCombo.onOptionChange = function(widget)
        imbueLevelsCombo:clearOptions()
        if itemImbuements ~= nil then
            local selectedGroup = groupsCombo:getCurrentOption().text
            for _, imbuement in ipairs(itemImbuements) do
                if imbuement['group'] == selectedGroup then
                    emptyImbue.imbuement:addOption(imbuement['name'])
                end
            end
            imbueLevelsCombo.onOptionChange(imbueLevelsCombo) -- update options
        end
    end

    imbueLevelsCombo.onOptionChange = function(widget)
        setProtection(false)
        local selectedGroup = groupsCombo:getCurrentOption().text
        for _, imbuement in ipairs(itemImbuements) do
            if imbuement['group'] == selectedGroup then
                if #imbuement['sources'] == widget.currentIndex then
                    selectedImbue = imbuement
                    for i, source in ipairs(imbuement['sources']) do
                        for _, item in ipairs(imbueItems) do
                            if item:getId() == source['item']:getId() then
                                if item:getCount() >= source['item']:getCount() then
                                    emptyImbue.imbue:setImageSource('/images/game/imbuing/imbue_green')
                                    emptyImbue.imbue:setEnabled(true)
                                    emptyImbue.requiredItems:getChildByIndex(i).count:setColor('white')
                                end
                                if item:getCount() < source['item']:getCount() then
                                    emptyImbue.imbue:setEnabled(false)
                                    emptyImbue.imbue:setImageSource('/images/game/imbuing/imbue_empty')
                                    emptyImbue.requiredItems:getChildByIndex(i).count:setColor('red')
                                end
                                emptyImbue.requiredItems:getChildByIndex(i).count:setText(item:getCount() .. '/' ..
                                                                                              source['item']:getCount())
                            end
                        end
                        emptyImbue.requiredItems:getChildByIndex(i).item:setItemId(source['item']:getId())
                        emptyImbue.requiredItems:getChildByIndex(i).item:setTooltip('The imbuement requires ' ..
                                                                                        source['description'] .. '.')
                    end
                    for i = 3, widget.currentIndex + 1, -1 do
                        emptyImbue.requiredItems:getChildByIndex(i).count:setText('')
                        emptyImbue.requiredItems:getChildByIndex(i).item:setItemId(0)
                        emptyImbue.requiredItems:getChildByIndex(i).item:setTooltip('')
                    end
                    emptyImbue.protectionCost:setText(imbuement['protectionCost'])
                    emptyImbue.cost:setText(imbuement['cost'])
                    if not protection and (bankGold + inventoryGold) < imbuement['cost'] then
                        emptyImbue.imbue:setEnabled(false)
                        emptyImbue.imbue:setImageSource('/images/game/imbuing/imbue_empty')
                        emptyImbue.cost:setColor('red')
                    end
                    if not protection and (bankGold + inventoryGold) >= imbuement['cost'] then
                        emptyImbue.cost:setColor('white')
                    end
                    if protection and (bankGold + inventoryGold) < (imbuement['cost'] + imbuement['protectionCost']) then
                        emptyImbue.imbue:setEnabled(false)
                        emptyImbue.imbue:setImageSource('/images/game/imbuing/imbue_empty')
                        emptyImbue.cost:setColor('red')
                    end
                    if protection and (bankGold + inventoryGold) >= (imbuement['cost'] + imbuement['protectionCost']) then
                        emptyImbue.cost:setColor('white')
                    end
                    emptyImbue.successRate:setText(imbuement['successRate'] .. '%')
                    if selectedImbue['successRate'] > 50 then
                        emptyImbue.successRate:setColor('white')
                    else
                        emptyImbue.successRate:setColor('red')
                    end
                    emptyImbue.description:setText(imbuement['description'])
                end
            end
        end
    end

    protectionBtn.onClick = function()
        setProtection(not protection)
    end
end

function setProtection(value)
    protection = value
    if protection then
        emptyImbue.cost:setText(selectedImbue['cost'] + selectedImbue['protectionCost'])
        emptyImbue.successRate:setText('100%')
        emptyImbue.successRate:setColor('green')
        protectionBtn:setImageClip(torect('66 0 66 66'))
    else
        if selectedImbue then
            emptyImbue.cost:setText(selectedImbue['cost'])
            emptyImbue.successRate:setText(selectedImbue['successRate'] .. '%')
            if selectedImbue['successRate'] > 50 then
                emptyImbue.successRate:setColor('white')
            else
                emptyImbue.successRate:setColor('red')
            end
        end
        protectionBtn:setImageClip(torect('0 0 66 66'))
    end
end

function terminate()
    disconnect(g_game, {
        onGameEnd = hide,
        onResourcesBalanceChange = Imbuing.onResourcesBalanceChange,
        onImbuementWindow = Imbuing.onImbuementWindow,
        onCloseImbuementWindow = Imbuing.onCloseImbuementWindow
    })

    imbuingWindow:destroy()
end

function resetSlots()
    emptyImbue:setVisible(false)
    clearImbue:setVisible(false)
    for i = 1, 3 do
        imbuingWindow.itemInfo.slots:getChildByIndex(i):setText('Slot ' .. i)
        imbuingWindow.itemInfo.slots:getChildByIndex(i):setEnabled(false)
        imbuingWindow.itemInfo.slots:getChildByIndex(i):setTooltip(
            'Items can have up to three imbuements slots. This slot is not available for this item.')
        imbuingWindow.itemInfo.slots:getChildByIndex(i).onClick = nil
    end
end

function selectSlot(widget, slotId, activeSlot)
    if activeSlot then
        emptyImbue:setVisible(false)
        widget:setText(activeSlot[1]['name'])
        clearImbue.title:setText('Clear Imbuement "' .. activeSlot[1]['name'] .. '"')
        clearImbue.groups:clearOptions()
        clearImbue.groups:addOption(activeSlot[1]['group'])
        clearImbue.imbuement:clearOptions()
        clearImbue.imbuement:addOption(activeSlot[1]['name'])
        clearImbue.description:setText(activeSlot[1]['description'])

        hours = string.format('%02.f', math.floor(activeSlot[2] / 3600))
        mins = string.format('%02.f', math.floor(activeSlot[2] / 60 - (hours * 60)))
        clearImbue.time.timeRemaining:setText(hours .. ':' .. mins .. 'h')

        clearImbue.cost:setText(activeSlot[3])
        if (bankGold + inventoryGold) < activeSlot[3] then
            emptyImbue.clear:setEnabled(false)
            emptyImbue.clear:setImageSource('/images/game/imbuing/imbue_empty')
            emptyImbue.cost:setColor('red')
        end

        local yesCallback = function()
            g_game.clearImbuement(slotId)
            widget:setText('Slot ' .. (slotId + 1))
            if clearConfirmWindow then
                clearConfirmWindow:destroy()
                clearConfirmWindow = nil
            end
        end
        local noCallback = function()
            imbuingWindow:show()
            if clearConfirmWindow then
                clearConfirmWindow:destroy()
                clearConfirmWindow = nil
            end
        end

        clearImbue.clear.onClick = function()
            imbuingWindow:hide()
            clearConfirmWindow = displayGeneralBox(tr('Confirm Clearing'),
                                                   tr(
                                                       'Do you wish to spend ' .. activeSlot[3] ..
                                                           ' gold coins to clear the imbuement "' ..
                                                           activeSlot[1]['name'] .. '" from your item?'), {
                {
                    text = tr('Yes'),
                    callback = yesCallback
                },
                {
                    text = tr('No'),
                    callback = noCallback
                },
                anchor = AnchorHorizontalCenter
            }, yesCallback, noCallback)
        end

        clearImbue:setVisible(true)
    else
        emptyImbue:setVisible(true)
        clearImbue:setVisible(false)

        local yesCallback = function()
            g_game.applyImbuement(slotId, selectedImbue['id'], protection)
            if clearConfirmWindow then
                clearConfirmWindow:destroy()
                clearConfirmWindow = nil
            end
            widget:setText(selectedImbue['name'])
            imbuingWindow:show()
        end
        local noCallback = function()
            imbuingWindow:show()
            if clearConfirmWindow then
                clearConfirmWindow:destroy()
                clearConfirmWindow = nil
            end
        end

        emptyImbue.imbue.onClick = function()
            imbuingWindow:hide()
            local cost = selectedImbue['cost']
            local successRate = selectedImbue['successRate']
            if protection then
                cost = cost + selectedImbue['protectionCost']
                successRate = '100'
            end
            clearConfirmWindow = displayGeneralBox(tr('Confirm Imbuing Attempt'),
                                                   'You are about to imbue your item with "' .. selectedImbue['name'] ..
                                                       '".\nYour chance to succeed is ' .. successRate ..
                                                       '%. It will consume the required astral sources and ' .. cost ..
                                                       ' gold coins.\nDo you wish to proceed?', {
                {
                    text = tr('Yes'),
                    callback = yesCallback
                },
                {
                    text = tr('No'),
                    callback = noCallback
                },
                anchor = AnchorHorizontalCenter
            }, yesCallback, noCallback)
        end
    end
end

function Imbuing.onImbuementWindow(itemId, slots, activeSlots, imbuements, needItems)
    if not itemId then
        return
    end
    resetSlots()
    imbueItems = table.copy(needItems)
    imbuingWindow.itemInfo.item:setItemId(itemId)

    for i = 1, slots do
        local slot = imbuingWindow.itemInfo.slots:getChildByIndex(i)
        slot.onClick = function(widget)
            selectSlot(widget, i - 1)
        end
        slot:setTooltip(
            'Use this slot to imbue your item. Depending on the item you can have up to three different imbuements.')
        slot:setEnabled(true)

        if slot:getId() == 'slot0' then
            selectSlot(slot, i - 1)
        end
    end

    for i, slot in pairs(activeSlots) do
        local activeSlotBtn = imbuingWindow.itemInfo.slots:getChildById('slot' .. i)
        activeSlotBtn.onClick = function(widget)
            selectSlot(widget, i, slot)
        end
        if activeSlotBtn:getId() == 'slot0' then
            selectSlot(activeSlotBtn, i, slot)
        end
    end

    if imbuements ~= nil then
        groupsCombo:clearOptions()
        imbueLevelsCombo:clearOptions()
        itemImbuements = table.copy(imbuements)
        for _, imbuement in ipairs(itemImbuements) do
            if not groupsCombo:isOption(imbuement['group']) then
                groupsCombo:addOption(imbuement['group'])
            end
        end
    end
    show()
end

function Imbuing.onResourcesBalanceChange(balance, oldBalance, type)
    if type == ResourceTypes.BANK_BALANCE then
        bankGold = balance
    elseif type == ResourceTypes.GOLD_EQUIPPED then
        inventoryGold = balance
    end
    local player = g_game.getLocalPlayer()
    if player then
        if type == ResourceTypes.BANK_BALANCE or type == ResourceTypes.GOLD_EQUIPPED then
            imbuingWindow.balance:setText(tr('Balance') .. ':\n' .. (player:getTotalMoney()))
        end
    end
end

function Imbuing.onCloseImbuementWindow()
    resetSlots()
end

function hide()
    g_game.closeImbuingWindow()
    imbuingWindow:hide()
end

function show()
    imbuingWindow:show()
    imbuingWindow:raise()
    imbuingWindow:focus()
end

function toggle()
    if imbuingWindow:isVisible() then
        return hide()
    end
    show()
end

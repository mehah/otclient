local CODE_TOOLTIPS = 105

InventorySlotStyles = {
    [InventorySlotHead] = 'HeadSlot',
    [InventorySlotNeck] = 'NeckSlot',
    [InventorySlotBack] = 'BackSlot',
    [InventorySlotBody] = 'BodySlot',
    [InventorySlotRight] = 'RightSlot',
    [InventorySlotLeft] = 'LeftSlot',
    [InventorySlotLeg] = 'LegSlot',
    [InventorySlotFeet] = 'FeetSlot',
    [InventorySlotFinger] = 'FingerSlot',
    [InventorySlotAmmo] = 'AmmoSlot'
}

inventoryWindow = nil
inventoryPanel = nil
inventoryButton = nil
purseButton = nil

function init()
    connect(LocalPlayer, {
        onInventoryChange = onInventoryChange,
        onBlessingsChange = onBlessingsChange
    })
    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })
    ProtocolGame.registerExtendedOpcode(CODE_TOOLTIPS, onExtendedOpcode)

    g_keyboard.bindKeyDown('Ctrl+I', toggle)

    inventoryButton = modules.client_topmenu.addRightGameToggleButton('inventoryButton', tr('Inventory') .. ' (Ctrl+I)',
                                                                      '/images/topbuttons/inventory', toggle)
    inventoryButton:setOn(true)

    inventoryWindow = g_ui.loadUI('inventory')
    inventoryWindow:disableResize()
    inventoryPanel = inventoryWindow:getChildById('contentsPanel')

    purseButton = inventoryPanel:getChildById('purseButton')
    local function purseFunction()
        local purse = g_game.getLocalPlayer():getInventoryItem(InventorySlotPurse)
        if purse then
            g_game.use(purse)
        end
    end
    purseButton.onClick = purseFunction

    refresh()
    inventoryWindow:setup()
    if g_game.isOnline() then
        inventoryWindow:setupOnStart()
    end
end

function terminate()
    disconnect(LocalPlayer, {
        onInventoryChange = onInventoryChange,
        onBlessingsChange = onBlessingsChange
    })
    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })
    ProtocolGame.unregisterExtendedOpcode(CODE_TOOLTIPS, onExtendedOpcode)

    g_keyboard.unbindKeyDown('Ctrl+I')

    inventoryWindow:destroy()
    inventoryButton:destroy()

    inventoryWindow = nil
    inventoryPanel = nil
    inventoryButton = nil
    purseButton = nil
end

function toggleAdventurerStyle(hasBlessing)
    for slot = InventorySlotFirst, InventorySlotLast do
        local itemWidget = inventoryPanel:getChildById('slot' .. slot)
        if itemWidget then
            itemWidget:setOn(hasBlessing)
        end
    end
end

function online()
    inventoryWindow:setupOnStart() -- load character window configuration
    refresh()
end

function offline()
    inventoryWindow:setParent(nil, true)
end

function refresh()
    local player = g_game.getLocalPlayer()
    for i = InventorySlotFirst, InventorySlotPurse do
        if g_game.isOnline() then
            onInventoryChange(player, i, player:getInventoryItem(i))
        else
            onInventoryChange(player, i, nil)
        end
        toggleAdventurerStyle(player and Bit.hasBit(player:getBlessings(), Blessings.Adventurer) or false)
    end

    purseButton:setVisible(g_game.getFeature(GamePurseSlot))
end

function toggle()
    if inventoryButton:isOn() then
        inventoryWindow:close()
        inventoryButton:setOn(false)
    else
        inventoryWindow:open()
        inventoryButton:setOn(true)
    end
end

function onMiniWindowOpen()
    inventoryButton:setOn(true)
end

function onMiniWindowClose()
    inventoryButton:setOn(false)
end

-- hooked events
function onInventoryChange(player, slot, item, oldItem)
    if slot > InventorySlotPurse then
        return
    end
    local protocolGame = g_game.getProtocolGame()

    if slot == InventorySlotPurse then
        if g_game.getFeature(GamePurseSlot) then
            purseButton:setEnabled(item and true or false)
        end
        return
    end

    local itemWidget = inventoryPanel:getChildById('slot' .. slot)
    if item then
        itemWidget:setStyle('InventoryItem')
        itemWidget:setItem(item)
        local pos = item:getPosition()
        protocolGame:sendExtendedOpcode(CODE_TOOLTIPS, json.encode({widgetId = itemWidget:getId(), position = {pos.x, pos.y, pos.z, item:getStackPos()}}))
    else
        itemWidget:setStyle(InventorySlotStyles[slot])
        itemWidget:setItem(nil)
        itemWidget:setData(nil)
    end
end

function onBlessingsChange(player, blessings, oldBlessings)
    local hasAdventurerBlessing = Bit.hasBit(blessings, Blessings.Adventurer)
    if hasAdventurerBlessing ~= Bit.hasBit(oldBlessings, Blessings.Adventurer) then
        toggleAdventurerStyle(hasAdventurerBlessing)
    end
end

function onExtendedOpcode(protocol, code, buffer)
  local json_status, json_data =
    pcall(
    function()
      return json.decode(buffer)
    end
  )

  if not json_status then
    g_logger.error("Tooltips JSON error: " .. json_data)
    return
  end
  local action = json_data.action
  local data = json_data.data
  local widget = json_data.widgetId
  if not action or not data or not widget then
    return
  end
  local itemWidget = inventoryPanel:getChildById(widget)
  if action == "new" then
    itemWidget:setData(newTooltip(data))
  end
end

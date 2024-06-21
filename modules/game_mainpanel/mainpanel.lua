function init()

    healthManaController:init()
    inventoryController:init()
    optionsController:init()
end

function terminate()

    healthManaController:terminate()
    inventoryController:terminate()
    optionsController:terminate()
end

local standModeBox
local chaseModeBox
local optionsAmount = 0
local specialsAmount = 0
local storeAmount = 0

local chaseModeRadioGroup

function reloadMainPanelSizes()
    local main = modules.game_interface.getMainRightPanel()
    local rightPanel = modules.game_interface.getRightPanel()

    if not main or not rightPanel then
        return
    end

    local height = 4
    for _, panel in ipairs(main:getChildren()) do
        if panel.panelHeight ~= nil then
            if panel:isVisible() then
                panel:setHeight(panel.panelHeight)
                height = height + panel.panelHeight

                if panel:getId() == 'mainoptionspanel' and panel:isOn() then
                    local currentOptionsAmount = math.ceil(optionsAmount / 5)
                    local optionsHeight = (currentOptionsAmount * 28) + 3
                    local currentSpecialsAmount = math.ceil(specialsAmount / 2)
                    local specialsHeight = (currentSpecialsAmount * 28) + 3
                    local maxPanelHeight = math.max(optionsHeight, specialsHeight)

                    if storeAmount > 1 then
                        local currentStoreAmount = math.ceil(storeAmount / 1)
                        local storeHeight = (currentStoreAmount * 20) + 3
                        panel.onPanel.store:setHeight(storeHeight)
                        maxPanelHeight = math.max(maxPanelHeight, storeHeight)
                    end

                    panel:setHeight(panel:getHeight() + maxPanelHeight)
                    height = height + maxPanelHeight
                    if storeAmount >= 2 then
                        height = height + 15
                    end
                end
            else
                panel:setHeight(0)
            end
        end
    end

    main:setHeight(height)
    rightPanel:fitAll()
end

-- @ Options
local optionsShrink = false
local function refreshOptionsSizes()
    if optionsShrink then
        optionsController.ui:setOn(false)
        optionsController.ui.onPanel:hide()
        optionsController.ui.offPanel:show()
    else
        optionsController.ui:setOn(true)
        optionsController.ui.onPanel:show()
        optionsController.ui.offPanel:hide()
    end
    reloadMainPanelSizes()
end

local function createButton_large(id, description, image, callback, special, front)
    -- fast version
    local panel = optionsController.ui.onPanel.store

    storeAmount = storeAmount + 1

    local button = panel:getChildById(id)
    if not button then
        button = g_ui.createWidget('largeToggleButton')
        if front then
            panel:insertChild(1, button)
        else
            panel:addChild(button)
        end
    end
    button:setId(id)
    button:setTooltip(description)
    button:setImageSource(image)
    button:setImageClip('0 0 108 20')
    button.onMouseRelease = function(widget, mousePos, mouseButton)
        if widget:containsPoint(mousePos) and mouseButton ~= MouseMidButton then
            callback()
            return true
        end
    end

    return button
end

local function createButton(id, description, image, callback, special, front, index)
    local panel
    if special then
        panel = optionsController.ui.onPanel.specials
        specialsAmount = specialsAmount + 1
    else
        panel = optionsController.ui.onPanel.options
        optionsAmount = optionsAmount + 1
    end

    local button = panel:getChildById(id)
    if not button then
        button = g_ui.createWidget('MainToggleButton')
        if front then
            panel:insertChild(1, button)
        else
            panel:addChild(button)
        end
    end

    button:setId(id)
    button:setTooltip(description)
    button:setSize('20 20')
    button:setImageSource(image)
    button:setImageClip('0 0 20 20')
    button.onMouseRelease = function(widget, mousePos, mouseButton)
        if widget:containsPoint(mousePos) and mouseButton ~= MouseMidButton then
            callback()
            return true
        end
    end
    if not button.index and type(index) == 'number' then
        button.index = index or 1000
    end

    refreshOptionsSizes()
    return button
end

optionsController = Controller:new()
optionsController:setUI('mainoptionspanel', modules.game_interface.getMainRightPanel())

function optionsController:onInit()
end

function optionsController:onTerminate()
end

function optionsController:onGameStart()
    optionsShrink = g_settings.getBoolean('mainpanel_shrink_options')
    refreshOptionsSizes()
    modules.game_interface.setupOptionsMainButton()
    modules.client_options.setupOptionsMainButton()
    local getOptionsPanel = optionsController.ui.onPanel.options
    local children = getOptionsPanel:getChildren()
    table.sort(children, function(a, b)
        return (a.index or 1000) < (b.index or 1000)
    end)
    getOptionsPanel:reorderChildren(children)
end

function optionsController:onGameEnd()
end

function changeOptionsSize()
    optionsShrink = not optionsShrink
    g_settings.set('mainpanel_shrink_options', optionsShrink)
    refreshOptionsSizes()
end

function addToggleButton(id, description, image, callback, front, index)
    return createButton(id, description, image, callback, false, front, index)
end

function addSpecialToggleButton(id, description, image, callback, front, index)
    return createButton(id, description, image, callback, true, front, index)
end

function addStoreButton(id, description, image, callback, front)
    return createButton_large(id, description, image, callback, true, front)
end
-- @ End of Options

-- @ Health/Mana
local function healthManaEvent()
    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    healthManaController.ui.health.text:setText(player:getHealth())
    healthManaController.ui.health.current:setWidth(math.max(12, math.ceil(
        (healthManaController.ui.health.total:getWidth() * player:getHealth()) / player:getMaxHealth())))

    healthManaController.ui.mana.text:setText(player:getMana())
    healthManaController.ui.mana.current:setWidth(math.max(12, math.ceil(
        (healthManaController.ui.mana.total:getWidth() * player:getMana()) / player:getMaxMana())))
end

healthManaController = Controller:new()
healthManaController:setUI('mainhealthmanapanel', modules.game_interface.getMainRightPanel())

local healthManaControllerEvents = healthManaController:addEvent(LocalPlayer, {
    onHealthChange = healthManaEvent,
    onManaChange = healthManaEvent
})

function healthManaController:onInit()
end

function healthManaController:onTerminate()
end

function healthManaController:onGameStart()
    healthManaControllerEvents:connect()
    healthManaControllerEvents:execute('onHealthChange')
    healthManaControllerEvents:execute('onManaChange')
end

function healthManaController:onGameEnd()
    healthManaControllerEvents:disconnect()
end
-- @ End of Health/Mana

-- @ Inventory
local inventoryShrink = false
local function getInventoryUi()
    if inventoryShrink then
        return inventoryController.ui.offPanel
    end

    return inventoryController.ui.onPanel
end

local function walkEvent()
    if modules.client_options.getOption('autoChaseOverride') then
        if g_game.isAttacking() and g_game.getChaseMode() == ChaseOpponent then
            selectPosture('stand', true)
        end
    end
end

local function combatEvent()
    local chaseMode = g_game.getChaseMode()
    if chaseMode == 1 then
        chaseModeRadioGroup:selectWidget(chaseModeBox, true)
    else
        chaseModeRadioGroup:selectWidget(standModeBox, true)
    end

    if g_game.getFightMode() == FightOffensive then
        selectCombat('attack', true)
    elseif g_game.getFightMode() == FightBalanced then
        selectCombat('balanced', true)
    elseif g_game.getFightMode() == FightDefensive then
        selectCombat('defense', true)
    end
   
    selectPvp(g_game.getPVPMode() == PVPRedFist, true)
end

local function inventoryEvent(player, slot, item, oldItem)
    if inventoryShrink then
        return
    end

    local ui = getInventoryUi()
    local slotPanel
    local toggler
    if slot == InventorySlotHead then
        slotPanel = ui.helmet
        toggler = slotPanel.helmet
    elseif slot == InventorySlotNeck then
        slotPanel = ui.amulet
        toggler = slotPanel.amulet
    elseif slot == InventorySlotBack then
        slotPanel = ui.backpack
        toggler = slotPanel.backpack
    elseif slot == InventorySlotBody then
        slotPanel = ui.armor
        toggler = slotPanel.armor
    elseif slot == InventorySlotRight then
        slotPanel = ui.shield
        toggler = slotPanel.shield
    elseif slot == InventorySlotLeft then
        slotPanel = ui.sword
        toggler = slotPanel.sword
    elseif slot == InventorySlotLeg then
        slotPanel = ui.legs
        toggler = slotPanel.legs
    elseif slot == InventorySlotFeet then
        slotPanel = ui.boots
        toggler = slotPanel.boots
    elseif slot == InventorySlotFinger then
        slotPanel = ui.ring
        toggler = slotPanel.ring
    elseif slot == InventorySlotAmmo then
        slotPanel = ui.tools
        toggler = slotPanel.tools
    end

    if not slotPanel then
        return
    end

    slotPanel.item:setItem(item)
    toggler:setEnabled(not item)
    slotPanel.item:setWidth(34)
    slotPanel.item:setHeight(34)
end

local function onSoulChange(localPlayer, soul)
    local ui = getInventoryUi()
    if not localPlayer then
        return
    end
    if not soul then
        return
    end

    if ui.soulPanel and ui.soulPanel.soul then
        ui.soulPanel.soul:setText(soul)
    end

    if ui.soulAndCapacity and ui.soulAndCapacity.soul then
        ui.soulAndCapacity.soul:setText(soul)
    end

end

local function onFreeCapacityChange(player, freeCapacity)
    if not player then
        return
    end

    if not freeCapacity then
        return
    end
    if freeCapacity > 99999 then
        freeCapacity = math.min(9999, math.floor(freeCapacity / 1000)) .. "k"
    elseif freeCapacity > 999 then
        freeCapacity = math.floor(freeCapacity)
    elseif freeCapacity > 99 then
        freeCapacity = math.floor(freeCapacity * 10) / 10
    end
    local ui = getInventoryUi()
    if ui.capacityPanel and ui.capacityPanel.capacity then
        ui.capacityPanel.capacity:setText(freeCapacity)
    end
    if ui.soulAndCapacity and ui.soulAndCapacity.capacity then
        ui.soulAndCapacity.capacity:setText(freeCapacity)
    end
end

function getIconsPanelOn()
    return inventoryController.ui.onPanel.icons
end

function getIconsPanelOff()
    return inventoryController.ui.offPanel.icons
end

local function refreshInventory_panel()
    local player = g_game.getLocalPlayer()
    if player then
        onSoulChange(player, player:getSoul())
        onFreeCapacityChange(player, player:getFreeCapacity())
    end
    if inventoryShrink then
        return
    end

    for i = InventorySlotFirst, InventorySlotPurse do
        if g_game.isOnline() then
            inventoryEvent(player, i, player:getInventoryItem(i))
        else
            inventoryEvent(player, i, nil)
        end
    end

end

local function refreshInventorySizes()
    if inventoryShrink then
        inventoryController.ui:setOn(false)
        inventoryController.ui.onPanel:hide()
        inventoryController.ui.offPanel:show()
    else
        inventoryController.ui:setOn(true)
        inventoryController.ui.onPanel:show()
        inventoryController.ui.offPanel:hide()
        refreshInventory_panel()
    end
    combatEvent()
    walkEvent()
    reloadMainPanelSizes()
end

function onSetChaseMode(self, selectedChaseModeButton)
    if selectedChaseModeButton == nil then
        return
    end
    local buttonId = selectedChaseModeButton:getId()
    local chaseMode

    if buttonId == 'followPosture' then
        chaseMode = ChaseOpponent
    else -- standModeBox
        chaseMode = DontChase
    end

    g_game.setChaseMode(chaseMode)
end

inventoryController = Controller:new()
inventoryController:setUI('maininventorypanel', modules.game_interface.getMainRightPanel())

local inventoryControllerEvents = inventoryController:addEvent(LocalPlayer, {
    onInventoryChange = inventoryEvent,
    onSoulChange = onSoulChange,
    onFreeCapacityChange = onFreeCapacityChange
})

local inventoryControllerEvents_game = inventoryController:addEvent(g_game, {
    onWalk = walkEvent,
    onAutoWalk = walkEvent,
    onFightModeChange = combatEvent,
    onChaseModeChange = combatEvent,
    onSafeFightChange = combatEvent,
    onPVPModeChange = combatEvent
})

function inventoryController:onInit()
    refreshInventory_panel()
    local ui = getInventoryUi()
    standModeBox = ui.standPosture
    chaseModeBox = ui.followPosture
    chaseModeRadioGroup = UIRadioGroup.create()
    chaseModeRadioGroup:addWidget(standModeBox)
    chaseModeRadioGroup:addWidget(chaseModeBox)
    connect(chaseModeRadioGroup, {
        onSelectionChange = onSetChaseMode
    })
end

function inventoryController:onTerminate()
    inventoryControllerEvents:disconnect()
    inventoryControllerEvents_game:disconnect()
end

function inventoryController:onGameStart()
    inventoryControllerEvents:connect()
    inventoryControllerEvents:execute('onInventoryChange')
    inventoryControllerEvents:execute('onSoulChange')
    inventoryControllerEvents:execute('onFreeCapacityChange')

    inventoryControllerEvents_game:connect()
    inventoryControllerEvents_game:execute('onWalk')
    inventoryControllerEvents_game:execute('onAutoWalk')
    inventoryControllerEvents_game:execute('onFightModeChange')
    inventoryControllerEvents_game:execute('onChaseModeChange')
    inventoryControllerEvents_game:execute('onSafeFightChange')
    inventoryControllerEvents_game:execute('onPVPModeChange')

    inventoryShrink = g_settings.getBoolean('mainpanel_shrink_inventory')
    refreshInventorySizes()
    refreshInventory_panel()

    if g_game.getClientVersion() < 1000 then
        inventoryController.ui.offPanel.blessings:hide()
        inventoryController.ui.offPanel.expert:hide()
        inventoryController.ui.onPanel.blessings:hide()
        inventoryController.ui.onPanel.expert:hide()
    end
end

function inventoryController:onGameEnd()
    inventoryControllerEvents:disconnect()
    inventoryControllerEvents_game:disconnect()
end

function selectPosture(key, ignoreUpdate)
    local ui = getInventoryUi()
    if key == 'stand' then
        ui.standPosture:setEnabled(false)
        ui.followPosture:setEnabled(true)
        if not ignoreUpdate then
            g_game.setChaseMode(DontChase)
        end
    elseif key == 'follow' then
        ui.standPosture:setEnabled(true)
        ui.followPosture:setEnabled(false)
        if not ignoreUpdate then
            g_game.setChaseMode(ChaseOpponent)
        end
    end
end

function selectCombat(combat, ignoreUpdate)
    local ui = getInventoryUi()
    if combat == 'attack' then
        ui.attack:setEnabled(false)
        ui.balanced:setEnabled(true)
        ui.defense:setEnabled(true)
        if not ignoreUpdate then
            g_game.setFightMode(FightOffensive)
        end
    elseif combat == 'balanced' then
        ui.attack:setEnabled(true)
        ui.balanced:setEnabled(false)
        ui.defense:setEnabled(true)
        if not ignoreUpdate then
            g_game.setFightMode(FightBalanced)
        end
    elseif combat == 'defense' then
        ui.attack:setEnabled(true)
        ui.balanced:setEnabled(true)
        ui.defense:setEnabled(false)
        if not ignoreUpdate then
            g_game.setFightMode(FightDefensive)
        end
    end
end

function selectPvp(pvp, ignoreUpdate)
    local ui = getInventoryUi()
    if pvp then
        ui.pvp:setImageClip(
            ui.pvp.imageClipCheckedX .. ' ' .. ui.pvp.imageClipCheckedY .. ' ' .. ui.pvp.imageClipWidth .. ' 20')
        if not ignoreUpdate then
            g_game.setPVPMode(PVPRedFist)
        end
    else
        ui.pvp:setImageClip(ui.pvp.imageClipUncheckedX .. ' ' .. ui.pvp.imageClipUncheckedY .. ' ' ..
                                ui.pvp.imageClipWidth .. ' 20')
        if not ignoreUpdate then
            g_game.setPVPMode(PVPWhiteHand)
        end
    end
end

function changeInventorySize()
    inventoryShrink = not inventoryShrink
    g_settings.set('mainpanel_shrink_inventory', inventoryShrink)
    refreshInventorySizes()
    reloadMainPanelSizes()
    local player = g_game.getLocalPlayer()
    if player and g_game.isOnline() then

        onFreeCapacityChange(player, player:getFreeCapacity())
        onSoulChange(player, player:getSoul())
    end
end

function getSlot5()
    return inventoryController.ui.offPanel.shield
end

-- @ End of Inventory

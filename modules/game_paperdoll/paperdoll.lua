local iconTopMenu = nil

paperdollController = Controller:new()
paperdollController:setUI('paperdoll', modules.game_interface.getMainRightPanel())

local UI = nil

local SLOT_MAP = {
  [InventorySlotHead] = 'slot1',
  [InventorySlotNeck] = 'slot2',
  [InventorySlotBack] = 'slot3',
  [InventorySlotBody] = 'slot4',
  [InventorySlotRight] = 'slot5',
  [InventorySlotLeft] = 'slot6',
  [InventorySlotLeg] = 'slot7',
  [InventorySlotFeet] = 'slot8',
  [InventorySlotFinger] = 'slot9',
  [InventorySlotAmmo] = 'slot10',
  [InventorySlotPurse] = 'slot11',
}

local function refreshAll()
  local player = g_game.getLocalPlayer()
  if not player then return end

  -- avatar
  UI.avatar:setOutfit(player:getOutfit())
  UI.avatar:getCreature():setStaticWalking(1000)

  -- items
  for i = InventorySlotFirst, InventorySlotPurse do
    local item = player:getInventoryItem(i)
    local slotId = SLOT_MAP[i]
    if slotId and UI.grid[slotId] then
      UI.grid[slotId]:setItem(item)
    end
  end
end

local function onInventoryChange(player, slot, item, oldItem)
  local slotId = SLOT_MAP[slot]
  if slotId and UI and UI.grid and UI.grid[slotId] then
    UI.grid[slotId]:setItem(item)
  end
end

local function onOutfitChange(creature, outfit)
  if UI and UI.avatar then
    UI.avatar:setOutfit(outfit)
  end
end

function paperdollController:onInit()
  UI = self.ui
end

function paperdollController:onGameStart()
  UI = self.ui
  if not UI then return end
  refreshAll()

  self:registerEvents(LocalPlayer, {
    onInventoryChange = onInventoryChange,
    onOutfitChange = onOutfitChange,
  }):execute()
end

function paperdollController:onGameEnd()
end

function paperdollController:onTerminate()
  if iconTopMenu then
    iconTopMenu:destroy()
    iconTopMenu = nil
  end
end

function extendedView(extended)
  if extended then
    if not iconTopMenu then
      iconTopMenu = modules.client_topmenu.addTopRightToggleButton('paperdoll', tr('Paperdoll'), '/images/topbuttons/inventory', toggle)
      iconTopMenu:setOn(paperdollController.ui:isVisible())
      paperdollController.ui:setBorderColor('black')
      paperdollController.ui:setBorderWidth(2)
    end
  else
    if iconTopMenu then
      iconTopMenu:destroy()
      iconTopMenu = nil
    end
    paperdollController.ui:setBorderColor('alpha')
    paperdollController.ui:setBorderWidth(0)
    local mainRightPanel = modules.game_interface.getMainRightPanel()
    if not mainRightPanel:hasChild(paperdollController.ui) then
      mainRightPanel:insertChild(4, paperdollController.ui)
    end
    paperdollController.ui:show()
  end
  paperdollController.ui.moveOnlyToMain = not extended
end

function toggle()
  if iconTopMenu:isOn() then
    paperdollController.ui:hide()
    iconTopMenu:setOn(false)
  else
    paperdollController.ui:show()
    iconTopMenu:setOn(true)
  end
end

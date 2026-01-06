local listItems = {}
gameStashWindown = nil
itemsPanel = nil
countWithdraw = nil
stowContainer = nil

local sellerOption = nil
local stashOption = nil
local otherOption = nil

local imbuementSources = {
  5877, 5920, 9633, 9635, 9636, 9638, 9639, 9640, 9641, 9644, 9647, 9650, 9654,
  9657, 9660, 9661, 9663, 9665, 9685, 9686, 9691, 9694, 10196, 10281, 10295, 10298,
  10302, 10304, 10307, 10309, 10311, 10405, 10420, 11444, 11447, 11452, 11464, 11466,
  11484, 11489, 11492, 11658, 11702, 11703, 14012, 14079, 14081, 16131, 17458, 17823,
  18993, 18994, 20199, 20200, 20205, 21194, 21200, 21202, 21975, 22007, 22053, 22189,
  22728, 22730, 23507, 23508, 25694, 25702, 28567, 40529,
}

local enhancedSources = {
  41767, 41757, 41769, 41768, 41762, 41763, 41770, 41764,
  41773, 41774, 41765, 41771, 41772, 41755, 64860, 41766,
}

local otherOptions = {
  {
    name = "Name (A-Z)",
    func = function(a, b)
      return a.marketData.name:lower() <
          b.marketData.name:lower()
    end
  },
  {
    name = "Name (Z-A)",
    func = function(a, b)
      return a.marketData.name:lower() >
          b.marketData.name:lower()
    end
  },
  -- { name = "Market Value (High to Low)", func = function(a, b) return a.marketValue > b.marketValue end },
  -- { name = "Market Value (Low to High)", func = function(a, b) return a.marketValue < b.marketValue end },
  -- {
  --   name = "Total Market Value (High t...",
  --   func = function(a, b)
  --     return (a.marketValue * a.itemCount) >
  --         (b.marketValue * b.itemCount)
  --   end
  -- },
  -- {
  --   name = "Total Market Value (Low t...",
  --   func = function(a, b)
  --     return (a.marketValue * a.itemCount) <
  --         (b.marketValue * b.itemCount)
  --   end
  -- },
  { name = "Sell To Value (High to Low)", func = function(a, b) return a.defaultValue > b.defaultValue end },
  { name = "Sell To Value (Low to High)", func = function(a, b) return a.defaultValue < b.defaultValue end },
  {
    name = "Total Sell To Value (High t...",
    func = function(a, b)
      return (a.defaultValue * a.itemCount) >
          (b.defaultValue * b.itemCount)
    end
  },
  {
    name = "Total Sell To Value (Low t...",
    func = function(a, b)
      return (a.defaultValue * a.itemCount) <
          (b.defaultValue * b.itemCount)
    end
  },
  { name = "Quantity (High to Low)", func = function(a, b) return a.itemCount > b.itemCount end },
  { name = "Quantity (Low to High)", func = function(a, b) return a.itemCount < b.itemCount end },
}

function init()
  gameStashWindown = g_ui.displayUI('stash')
  gameStashWindown:hide()

  itemsPanel = gameStashWindown:recursiveGetChildById('itemsPanel')

  g_ui.importStyle('withdraw')
  g_ui.importStyle('stow-container')
  connect(LocalPlayer, {
    onPositionChange = onPlayerPositionChange
  })

  connect(g_game, { onSupplyStashEnter = showStash, onGameEnd = offline })
end

function terminate(...)
  listItems = {}
  gameStashWindown:destroy()
  disconnect(LocalPlayer, {
    onPositionChange = onPlayerPositionChange
  })
  disconnect(g_game, { onSupplyStashEnter = showStash, onGameEnd = offline })

  if countWithdraw then
    countWithdraw:destroy()
    countWithdraw = nil
  end

  if stowContainer then
    stowContainer:destroy()
    stowContainer = nil
  end
end

function offline()
  if countWithdraw then
    countWithdraw:destroy()
    countWithdraw = nil
  end
  if stowContainer then
    stowContainer:destroy()
    stowContainer = nil
  end
  gameStashWindown:hide()
end

function showStash(payload, maxSlots)
  local prevOpen = gameStashWindown:isVisible()
  if g_game.isOnline() then
    -- g_client.setInputLockWidget(gameStashWindown)
    gameStashWindown:show(true)
  end

  gameStashWindown:focus()
  sellerOption = gameStashWindown.sellerOptions
  stashOption = gameStashWindown.stashOptions
  otherOption = gameStashWindown.otherOptions

  countWithdraw = nil

  local items = {}
  for i = 1, #payload do
    local itemId = payload[i][1]
    local amount = payload[i][2]
    local item = Item.create(itemId, amount)
    local market = item:getMarketData()
    local npc = item:getNpcSaleData()
    -- TODO:
    -- local marketValue = modules.game_cyclopedia.Cyclopedia.Items.getMarketOfferAverages(itemId) or 0

    local defaultValue = 0

    for _, v in pairs(npc) do
      if v.salePrice > defaultValue then
        defaultValue = v.salePrice
      end
    end

    table.insert(items, {
      itemId = itemId,
      itemCount = amount,
      marketData = {
        categoryName = getMarketCategoryName(market.category) or "Unknown Category",
        name = market.name or "Unknown Item",
        marketValue = marketValue,
      },
      marketValue = 0,
      npcSaleData = npc,
      ref = item,
      defaultValue = defaultValue,
    })
  end

  listItems = items

  local currentOption = stashOption:getCurrentOption() and stashOption:getCurrentOption().text or nil
  local currentSeller = sellerOption:getCurrentOption() and sellerOption:getCurrentOption().text or nil
  local currentOhter = otherOption:getCurrentOption() and otherOption:getCurrentOption().text or nil

  stashOption:clearOptions()
  stashOption:addOption("Show All")

  local currentList = {}
  for key, data in pairs(listItems) do
    if not table.contains(currentList, data.marketData.categoryName) then
      table.insert(currentList, data.marketData.categoryName)
    end
  end

  table.insert(currentList, "Imbuement Items")
  table.insert(currentList, "Enhanced Items")
  table.sort(currentList, function(a, b) return a < b end)
  for _, v in pairs(currentList) do
    stashOption:addOption("Show " .. v)
  end

  otherOption:clearOptions()
  for _, v in pairs(otherOptions) do
    otherOption:addOption(v.name)
  end

  stashOption:setCurrentOption("Show All", true)
  sellerOption:setCurrentOption("No Trader Selected", true)

  if currentOption ~= nil then
    stashOption:setCurrentOption(currentOption, true)
  end

  if currentSeller ~= nil then
    sellerOption:setCurrentOption(currentSeller, true)
  end

  if currentOhter ~= nil then
    otherOption:setCurrentOption(currentOhter, true)
  end

  if not prevOpen then
    stashOption:setCurrentOption("Show All", true)
    sellerOption:setCurrentOption("No Trader Selected", true)
    gameStashWindown.searchText:clearText(true)
  end
  refreshStashItems(gameStashWindown.searchText:getText())
end

function hideStash()
  local layout = itemsPanel:getLayout()
  layout:disableUpdates()
  itemsPanel:destroyChildren()
  layout:enableUpdates()
  layout:update()
  if gameStashWindown:isVisible() then
    -- g_client.setInputLockWidget(nil)
    gameStashWindown:hide()
    modules.game_interface.getRootPanel():focus()
  end
end

function openQuick()
  modules.game_stash.hideStash()
  modules.game_quickloot.QuickLoot.toggle()
end

function refreshStashItems(searchText)
  if not itemsPanel then
    return true
  end

  local layout = itemsPanel:getLayout()
  layout:disableUpdates()
  itemsPanel:destroyChildren()

  local additionalSort = otherOptions[otherOption.currentIndex]
  if additionalSort then
    table.sort(listItems, additionalSort.func)
  end

  for key, itemData in pairs(listItems) do
    local stashItem = itemData.ref
    if searchText and #searchText > 0 and not matchText(searchText, itemData.marketData.name) then
      goto continue
    end

    if sellerOption.currentIndex ~= 1 then
      local foundSeller = false
      for _, v in pairs(itemData.npcSaleData) do
        if string.find(sellerOption:getCurrentOption().text:lower(), v.name:lower()) and not table.contains(enhancedSources, itemData.itemId) then
          foundSeller = true
          break
        end
      end

      if not foundSeller then
        goto continue
      end
    end

    if stashOption.currentIndex ~= 1 then
      if stashOption:getCurrentOption().text == "Show Imbuement Items" then
        if not table.contains(imbuementSources, itemData.itemId) then
          goto continue
        end
      elseif stashOption:getCurrentOption().text == "Show Enhanced Items" then
        if not table.contains(enhancedSources, itemData.itemId) then
          goto continue
        end
      else
        if not string.find(stashOption:getCurrentOption().text:lower(), itemData.marketData.categoryName:lower()) then
          goto continue
        end
      end
    end

    local itemBox = g_ui.createWidget('StashItemBox', itemsPanel)
    itemBox.item = itemData

    local itemWidget = itemBox:getChildById('item')
    itemWidget:setItem(stashItem)
    itemWidget:setItemCount(itemData.itemCount)
    ItemsDatabase.setRarityItem(itemWidget, stashItem)

    local tooltip = itemData.itemCount == 1 and itemData.marketData.name or
        (itemData.marketData.name .. " (" .. itemData.itemCount .. "x)")
    itemWidget:setTooltip(tooltip)
    itemWidget:setActionId(itemData.itemCount)
    itemWidget.onMouseRelease = function(widget, mousePos, mouseButton)
      if mouseButton ~= MouseRightButton and (mouseButton ~= MouseLeftButton or not g_keyboard.isCtrlPressed()) then
        return false
      end

      local menu = g_ui.createWidget('PopupMenu')
      menu:setGameMenu(true)
      menu:addOption(tr('Retrieve'), function() withdrawItem(itemWidget) end)
      menu:addSeparator()
      menu:addOption(tr('Cyclopedia'),
        function()
          hideStash()
          modules.game_cyclopedia.Cyclopedia.Items.onRedirect(stashItem:getId())
        end)
      if stashItem:isMarketable() and g_game.getLocalPlayer():isSupplyStashAvailable() then
        menu:addSeparator()
        menu:addOption(tr('Show in Market'), function()
          if stashItem:isMarketable() and g_game.getLocalPlayer():isSupplyStashAvailable() then
            hideStash()
            modules.game_market.onRedirect(stashItem)
          end
        end)
      end
      menu:addSeparator()



      -- if not modules.game_cyclopedia.Items.isInQuickSellWhitelist(stashItem:getId()) then
      --   menu:addOption(tr('Add to Loot List'), function() modules.game_quickloot.addToQuickLoot(stashItem:getId()) end)
      -- else
      --   menu:addOption(tr('Remove from Loot List'),
      --     function() modules.game_quickloot.removeItemInList(stashItem:getId()) end)
      -- end
      -- if not modules.game_npctrade.inWhiteList(stashItem:getId()) then
      --   menu:addOption(tr('Add to Quick Sell BlackList'),
      --     function() modules.game_npctrade.addToWhitelist(stashItem:getId()) end)
      -- else
      --   menu:addOption(tr('Remove from Quick Sell BlackList'),
      --     function() modules.game_npctrade.removeItemInList(stashItem:getId()) end)
      -- end
      menu:display(mousePos)
    end

    :: continue ::
  end

  layout:enableUpdates()
  layout:update()
end

function onPlayerPositionChange(creature, newPos, oldPos)
  if creature == g_game.getLocalPlayer() then
    hideStash()
  end
end

function showStashWithdraw()
  if countWithdraw then
    countWithdraw:destroy()
  end
  countWithdraw = nil
  gameStashWindown:show(true)
  -- g_client.setInputLockWidget(gameStashWindown)
end

function hideStashWithdraw()
  gameStashWindown:hide()
  countWithdraw = nil
  -- g_client.setInputLockWidget(nil)
end

function retrieveItem(itemId, count, otherWindow)
  g_game.stashWithdraw(itemId, count, 1)
  if countWithdraw then
    countWithdraw:destroy()
    countWithdraw = nil
  end

  if otherWindow then
    return
  end
  -- g_client.setInputLockWidget(nil)
  showStashWithdraw()
  -- g_client.setInputLockWidget(gameStashWindown)
end

function withdrawItem(widget)
  local itemCount = widget:getActionId()
  if itemCount == 1 then
    retrieveItem(widget:getItemId(), itemCount)
    return
  end

  hideStashWithdraw()

  countWithdraw = g_ui.createWidget('CountWithdraw', rootWidget)
  countWithdraw.contentPanel.item:setItemId(widget:getItemId())
  countWithdraw.contentPanel.item:setItemCount(itemCount)
  -- g_client.setInputLockWidget(countWithdraw)

  local scrollbar = countWithdraw:recursiveGetChildById("countScrollBar")
  scrollbar:setMaximum(itemCount)
  scrollbar:setMinimum(1)
  scrollbar:setValue(itemCount)

  local spinbox = countWithdraw:recursiveGetChildById('spinBox')
  spinbox:setMaximum(itemCount)
  spinbox:setMinimum(0)
  spinbox:setValue(0)
  spinbox:hideButtons()
  spinbox:focus()

  local spinBoxValueChange = function(self, value)
    scrollbar:setValue(value)
  end
  spinbox.onValueChange = spinBoxValueChange

  local check = function()
    if spinbox.firstEdit then
      spinbox:setValue(spinbox:getMaximum())
      spinbox.firstEdit = false
    end
  end

  g_keyboard.bindKeyPress("Left",
    function() scrollbar:setValue(math.max(scrollbar:getMinimum(), scrollbar:getValue() - 1)) end, countWithdraw)
  g_keyboard.bindKeyPress("Shift+Left",
    function() scrollbar:setValue(math.max(scrollbar:getMinimum(), scrollbar:getValue() - 10)) end, countWithdraw)
  g_keyboard.bindKeyPress("Ctrl+Left",
    function() scrollbar:setValue(math.max(scrollbar:getMinimum(), scrollbar:getValue() - 100)) end, countWithdraw)
  g_keyboard.bindKeyPress("Right",
    function() scrollbar:setValue(math.min(scrollbar:getMaximum(), scrollbar:getValue() + 1)) end, countWithdraw)
  g_keyboard.bindKeyPress("Shift+Right",
    function() scrollbar:setValue(math.min(scrollbar:getMaximum(), scrollbar:getValue() + 10)) end, countWithdraw)
  g_keyboard.bindKeyPress("Ctrl+Right",
    function() scrollbar:setValue(math.min(scrollbar:getMaximum(), scrollbar:getValue() + 100)) end, countWithdraw)

  scrollbar.onValueChange = function(self, value)
    countWithdraw.contentPanel.item:setItemCount(value)
  end

  scrollbar.onClick =
      function()
        local mousePos = g_window.getMousePosition()
        local sliderButton = scrollbar:getChildById('sliderButton')

        scrollbar:setSliderClick(sliderButton, sliderButton:getPosition())
        scrollbar:setSliderPos(sliderButton, sliderButton:getPosition(),
          { x = mousePos.x - sliderButton:getPosition().x, y = 0 })
      end

  countWithdraw.onEnter = function() retrieveItem(widget:getItemId(), scrollbar:getValue()) end
  countWithdraw.onEscape = function() showStashWithdraw() end
  countWithdraw.contentPanel.buttonOk.onClick = function()
    gameStashWindown:show()
    retrieveItem(widget:getItemId(), scrollbar:getValue())
  end
  countWithdraw.contentPanel.buttonCancel.onClick = function() showStashWithdraw() end
end

function stowContainerContent(item, toPos, moveItem)
  if stowContainer then
    return
  end

  stowContainer = g_ui.createWidget('StowContainer', rootWidget)
  stowContainer.contentPanel.buttonNo.onClick = function()
    stowContainer:destroy()
    stowContainer = nil
  end

  stowContainer.contentPanel.buttonYes.onClick = function()
    if moveItem then
      g_game.move(item, toPos, 1)
    else
      g_game.stashStowItem(item:getPosition(), item:getId(),
        item:getStackPos(), SUPPLY_STASH_ACTION_STOW_CONTAINER)
    end

    stowContainer:destroy()
    stowContainer = nil
  end
end

function withdrawItemID(itemID, itemCount)
  if itemCount == 1 then
    retrieveItem(itemID, itemCount, true)
    return
  end

  countWithdraw = g_ui.createWidget('CountWithdraw', rootWidget)
  countWithdraw.contentPanel.item:setItemId(itemID)
  countWithdraw.contentPanel.item:setItemCount(itemCount)
  -- g_client.setInputLockWidget(countWithdraw)

  local scrollbar = countWithdraw:recursiveGetChildById("countScrollBar")
  scrollbar:setMaximum(itemCount)
  scrollbar:setMinimum(1)
  scrollbar:setValue(itemCount)

  local spinbox = countWithdraw:recursiveGetChildById('spinBox')
  spinbox:setMaximum(itemCount)
  spinbox:setMinimum(0)
  spinbox:setValue(0)
  spinbox:hideButtons()
  spinbox:focus()

  local spinBoxValueChange = function(self, value)
    scrollbar:setValue(value)
  end
  spinbox.onValueChange = spinBoxValueChange

  local check = function()
    if spinbox.firstEdit then
      spinbox:setValue(spinbox:getMaximum())
      spinbox.firstEdit = false
    end
  end

  g_keyboard.bindKeyPress("Left",
    function() scrollbar:setValue(math.max(scrollbar:getMinimum(), scrollbar:getValue() - 1)) end, countWithdraw)
  g_keyboard.bindKeyPress("Shift+Left",
    function() scrollbar:setValue(math.max(scrollbar:getMinimum(), scrollbar:getValue() - 10)) end, countWithdraw)
  g_keyboard.bindKeyPress("Ctrl+Left",
    function() scrollbar:setValue(math.max(scrollbar:getMinimum(), scrollbar:getValue() - 100)) end, countWithdraw)
  g_keyboard.bindKeyPress("Right",
    function() scrollbar:setValue(math.min(scrollbar:getMaximum(), scrollbar:getValue() + 1)) end, countWithdraw)
  g_keyboard.bindKeyPress("Shift+Right",
    function() scrollbar:setValue(math.min(scrollbar:getMaximum(), scrollbar:getValue() + 10)) end, countWithdraw)
  g_keyboard.bindKeyPress("Ctrl+Right",
    function() scrollbar:setValue(math.min(scrollbar:getMaximum(), scrollbar:getValue() + 100)) end, countWithdraw)
  g_keyboard.bindKeyPress("Enter", function() retrieveItem(itemID, scrollbar:getValue(), true) end, countWithdraw)

  scrollbar.onValueChange = function(self, value)
    countWithdraw.contentPanel.item:setItemCount(value)
  end

  scrollbar.onClick =
      function()
        local mousePos = g_window.getMousePosition()
        local sliderButton = scrollbar:getChildById('sliderButton')

        scrollbar:setSliderClick(sliderButton, sliderButton:getPosition())
        scrollbar:setSliderPos(sliderButton, sliderButton:getPosition(),
          { x = mousePos.x - sliderButton:getPosition().x, y = 0 })
      end

  countWithdraw.contentPanel.onEnter = function() retrieveItem(itemID, scrollbar:getValue(), true) end
  countWithdraw.contentPanel.onEscape = function() end
  countWithdraw.contentPanel.buttonOk.onClick = function() retrieveItem(itemID, scrollbar:getValue(), true) end
  countWithdraw.contentPanel.buttonCancel.onClick = function() end
end

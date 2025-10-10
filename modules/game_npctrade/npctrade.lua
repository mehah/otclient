BUY = 1
SELL = 2
CURRENCY = 'gold'
CURRENCYID = GOLD_COINS
CURRENCY_DECIMAL = false
WEIGHT_UNIT = 'oz'
LAST_INVENTORY = 10
SORT_BY = 'name'

npcWindow = nil
itemsPanel = nil
radioTabs = nil
radioItems = nil
searchText = nil
setupPanel = nil
quantity = nil
quantityScroll = nil
amountText = nil
idLabel = nil
nameLabel = nil
priceLabel = nil
currencyMoneyLabel = nil
moneyLabel = nil
weightDesc = nil
weightLabel = nil
capacityDesc = nil
capacityLabel = nil
tradeButton = nil
itemButton = nil
headPanel = nil
currencyItem = nil
itemBorder = nil
currencyLabel = nil
buyTab = nil
sellTab = nil
initialized = false

showWeight = true
local buyWithBackpack = false
local ignoreCapacity = false
local ignoreEquipped = true
showAllItems = nil
sellAllButton = nil
sellAllWithDelayButton = nil
playerFreeCapacity = 0
playerMoney = 0
tradeItems = {}
playerItems = {}
sellAllWhitelist = {}
selectedItem = nil

quickSellButton = nil

-- Utility function to truncate text to a specified length
function short_text(text, maxLength)
  if not text then return "" end
  if string.len(text) <= maxLength then
    return text
  end
  return string.sub(text, 1, maxLength)
end

-- Utility function to escape special pattern characters for safe string searching
function string.searchEscape(str)
  if not str then return "" end
  -- Escape special Lua pattern characters: ( ) . % + - * ? [ ] ^ $
  return str:gsub("([%(%)%.%+%-%*%?%[%]%^%$%%])", "%%%1")
end

cancelNextRelease = nil
sellAllWithDelayEvent = nil

function saveData()
  local player = g_game.getLocalPlayer()
  if not player then return end

  local file = "/characterdata/" .. player:getId() .. "/sellAllWhitelist.json"
  local status, result = pcall(function() return json.encode(sellAllWhitelist, 2) end)
  if not status then
    return g_logger.error("Error while saving profile sellAllWhitelist. Data won't be saved. Details: " .. result)
  end

  if result:len() > 100 * 1024 * 1024 then
    return g_logger.error("Something went wrong, file is above 100MB, won't be saved")
  end
  g_resources.writeFileContents(file, result)
end

function loadData()
  local player = g_game.getLocalPlayer()
  if not player then return end

  local file = "/characterdata/" .. player:getId() .. "/sellAllWhitelist.json"
  if g_resources.fileExists(file) then
    local status, result = pcall(function()
      return json.decode(g_resources.readFileContents(file))
    end)
    if not status then
      return g_logger.error(
      "Error while reading profiles file. To fix this problem you can delete storage.json. Details: " .. result)
    end
    sellAllWhitelist = result
  else
    sellAllWhitelist = {}
  end
end

function removeItemInList(clientId)
  if type(clientId) ~= "number" then
    return
  end
  if not table.contains(sellAllWhitelist, clientId) then
    return
  end
  for k, v in pairs(sellAllWhitelist) do
    if v == clientId then
      table.remove(sellAllWhitelist, k)
      break
    end
  end
end

function inWhiteList(clientId)
  if not clientId then
    clientId = 0
  end
  if not sellAllWhitelist then
    return false
  end

  return table.contains(sellAllWhitelist, clientId)
end

function addToWhitelist(clientId)
  if type(clientId) ~= "number" then
    return
  end

  if table.contains(sellAllWhitelist, clientId) then
    return
  end

  table.insert(sellAllWhitelist, clientId)
end

function init()
  npcWindow = g_ui.loadUI('npctrade', modules.game_interface.getRightPanel())
  npcWindow:show()
  npcWindow:setVisible(false)

  npcWindow:setContentMinimumHeight(175)
  npcWindow:setContentHeight(175)
  npcWindow:setup()

  itemsPanel = npcWindow:recursiveGetChildById('contentsPanel')
  searchText = npcWindow:recursiveGetChildById('searchText')

  setupPanel = npcWindow:recursiveGetChildById('setupPanel')
  quantityScroll = setupPanel:getChildById('quantityScroll')
  amountText = setupPanel:getChildById('amountText')

  priceLabel = setupPanel:getChildById('price')
  currencyMoneyLabel = setupPanel:getChildById('currencyMoneyLabel')
  moneyLabel = setupPanel:getChildById('money')
  itemButton = setupPanel:getChildById('item')
  tradeButton = npcWindow:recursiveGetChildById('tradeButton')
  headPanel = npcWindow:recursiveGetChildById('headPanel')
  currencyItem = headPanel:getChildById('currencyItem')
  itemBorder = headPanel:getChildById('itemBorder')
  currencyLabel = headPanel:getChildById('currencyLabel')

  buyTab = npcWindow:recursiveGetChildById('buyTab')
  sellTab = npcWindow:recursiveGetChildById('sellTab')

  quickSellButton = npcWindow:recursiveGetChildById('quickSellButton')

  radioTabs = UIRadioGroup.create()
  radioTabs:addWidget(buyTab)
  radioTabs:addWidget(sellTab)
  radioTabs:selectWidget(buyTab)
  radioTabs.onSelectionChange = onTradeTypeChange

  cancelNextRelease = false
  if g_game.isOnline() then
    playerFreeCapacity = g_game.getLocalPlayer():getFreeCapacity()
  end

  connect(g_game, {
    onGameStart = start,
    onGameEnd = hide,
    onOpenNpcTrade = onOpenNpcTrade,
    onCloseNpcTrade = onCloseNpcTrade,
    onPlayerGoods = onPlayerGoods
  })

  connect(LocalPlayer, {
    onFreeCapacityChange = onFreeCapacityChange,
    onInventoryChange = onInventoryChange
  })

  initialized = true
end

function terminate()
  initialized = false
  npcWindow:destroy()

  sellAllWhitelist = {}

  disconnect(g_game, {
    onGameEnd = hide,
    onOpenNpcTrade = onOpenNpcTrade,
    onCloseNpcTrade = onCloseNpcTrade,
    onPlayerGoods = onPlayerGoods
  })

  disconnect(LocalPlayer, {
    onFreeCapacityChange = onFreeCapacityChange,
    onInventoryChange = onInventoryChange
  })
end

function show()
  if g_game.isOnline() then
    if #tradeItems[BUY] > 0 then
      radioTabs:selectWidget(buyTab)
      quickSellButton:setEnabled(false)
    else
      radioTabs:selectWidget(sellTab)
      quickSellButton:setEnabled(true)
    end

    npcWindow:show()
    if not npcWindow:getParent() then
      local panel = modules.game_interface.findContentPanelAvailable(npcWindow, npcWindow:getMinimumHeight())
      if not panel then
        return false
      end
      panel:addChild(npcWindow)
    end

    if npcWindow and npcWindow:isVisible() then
      npcWindow:getParent():moveChildToIndex(npcWindow, #npcWindow:getParent():getChildren())
      npcWindow.close = function() closeNpcTrade() end
      npcWindow:focus()
      setupPanel:enable()
    end
  end
end

function start()
  local benchmark = g_clock.millis()
  loadData()
  --consoleln("Sell All Whitelist Loot loaded in " .. (g_clock.millis() - benchmark) / 1000 .. " seconds.")
end

function hide()
  if not npcWindow then
    return
  end

  saveData()

  npcWindow:hide()

  toggleNPCFocus(false)
  modules.game_console.getConsole():focus()

  local layout = itemsPanel:getLayout()
  layout:disableUpdates()

  clearSelectedItem()

  searchText:clearText()
  setupPanel:disable()
  itemsPanel:destroyChildren()

  if radioItems then
    radioItems:destroy()
    radioItems = nil
  end

  layout:enableUpdates()
  layout:update()
end

function onItemBoxChecked(widget)
  itemButton:setItemId(0)
  quantityScroll:setValue(0)
  if widget:isChecked() then
    local item = widget.item
    selectedItem = item
    refreshItem(item)
    tradeButton:enable()

    if getCurrentTradeType() == SELL then
      quantityScroll:setValue(quantityScroll:getMaximum())
      amountText:setText(quantityScroll:getMaximum())
    end
  end
end

function onQuantityValueChange(quantity)
  if selectedItem then
    priceLabel:setText(comma_value(formatCurrency(getItemPrice(selectedItem))))
    amountText:setText(quantity)
  end
end

function onTradeTypeChange(radioTabs, selected, deselected)
  tradeButton:setText(selected:getText())
  selected:setOn(true)
  deselected:setOn(false)

  if selected == buyTab then
    quickSellButton:setEnabled(false)
  else
    quickSellButton:setEnabled(true)
  end

  refreshTradeItems()
  refreshPlayerGoods()
end

function onTradeClick()
  if not selectedItem then return end
  removeEvent(sellAllWithDelayEvent)
  if getCurrentTradeType() == BUY then
    g_game.buyItem(selectedItem.ptr, quantityScroll:getValue(), ignoreCapacity, buyWithBackpack)
  else
    g_game.sellItem(selectedItem.ptr, quantityScroll:getValue(), ignoreEquipped)
  end
end

function onSearchTextChange()
  refreshPlayerGoods()
  clearSelectedItem()
end

function onExtraMenu()
  local mousePosition = g_window.getMousePosition()
  if cancelNextRelease then
    cancelNextRelease = false
    return false
  end

  local menu = g_ui.createWidget('PopupMenu')
  menu:setGameMenu(true)
  menu:addCheckBoxOption(tr('Sort by name'), function()
    SORT_BY = 'name'; refreshPlayerGoods()
  end, "", SORT_BY == 'name')
  menu:addCheckBoxOption(tr('Sort by price'), function()
    SORT_BY = 'price'; refreshPlayerGoods()
  end, "", SORT_BY == 'price')
  menu:addCheckBoxOption(tr('Sort by weight'), function()
    SORT_BY = 'weight'; refreshPlayerGoods()
  end, "", SORT_BY == 'weight')
  menu:addSeparator()
  if getCurrentTradeType() == BUY then
    if CURRENCYID == GOLD_COINS then
      menu:addCheckBoxOption(tr('Buy in shopping bags'),
        function()
          buyWithBackpack = not buyWithBackpack; refreshPlayerGoods()
        end, "", buyWithBackpack)
    end
    menu:addCheckBoxOption(tr('Ignore capacity'), function()
      ignoreCapacity = not ignoreCapacity; refreshPlayerGoods()
    end, "", ignoreCapacity)
  else
    local equippedState = true
    if ignoreEquipped then
      equippedState = false
    end
    menu:addCheckBoxOption(tr('Sell equipped'),
      function()
        ignoreEquipped = not ignoreEquipped; refreshTradeItems(); refreshPlayerGoods()
      end, "", equippedState)
  end
  menu:addSeparator()
  menu:addCheckBoxOption(tr('Show search field'), function() end, "", true)
  menu:addCheckBoxOption(tr('Do not show a warning when trading large amounts'), function() end, "", false)
  menu:display(mousePosition)
  return true
end

function itemPopup(self, mousePosition, mouseButton)
  if cancelNextRelease then
    cancelNextRelease = false
    return false
  end

  local itemWidget = self:getChildById('item')
  if not itemWidget then
    itemWidget = self
  end

  if mouseButton == MouseRightButton then
    local menu = g_ui.createWidget('PopupMenu')
    menu:setGameMenu(true)
    menu:addOption(tr('Look'), function() return g_game.inspectNpcTrade(itemWidget:getItem()) end)
    menu:addOption(tr('Inspect'), function() g_game.sendInspectionObject(3, itemWidget:getItem():getId(), 1) end)
    menu:addSeparator()
    menu:addCheckBoxOption(tr('Sort by name'), function()
      SORT_BY = 'name'; refreshPlayerGoods()
    end, "", SORT_BY == 'name')
    menu:addCheckBoxOption(tr('Sort by price'), function()
      SORT_BY = 'price'; refreshPlayerGoods()
    end, "", SORT_BY == 'price')
    menu:addCheckBoxOption(tr('Sort by weight'), function()
      SORT_BY = 'weight'; refreshPlayerGoods()
    end, "", SORT_BY == 'weight')
    menu:addSeparator()
    if getCurrentTradeType() == BUY then
      if CURRENCYID == GOLD_COINS then
        menu:addCheckBoxOption(tr('Buy in shopping bags'),
          function()
            buyWithBackpack = not buyWithBackpack; refreshPlayerGoods()
          end, "", buyWithBackpack)
      end
      menu:addCheckBoxOption(tr('Ignore capacity'),
        function()
          ignoreCapacity = not ignoreCapacity; refreshPlayerGoods()
        end, "", ignoreCapacity)
    else
      local equippedState = true
      if ignoreEquipped then
        equippedState = false
      end

      menu:addCheckBoxOption(tr('Sell equipped'),
        function()
          ignoreEquipped = not ignoreEquipped; refreshTradeItems(); refreshPlayerGoods()
        end, "", equippedState)
    end
    menu:addSeparator()
    menu:addCheckBoxOption(tr('Show search field'), function() end, "", true)
    menu:addCheckBoxOption(tr('Do not show a warning when trading large amounts'), function() end, "", false)
    menu:display(mousePosition)
    return true
  elseif ((g_mouse.isPressed(MouseLeftButton) and mouseButton == MouseRightButton)
        or (g_mouse.isPressed(MouseRightButton) and mouseButton == MouseLeftButton)) then
    cancelNextRelease = true
    g_game.inspectNpcTrade(itemWidget:getItem())
    return true
  end
  return false
end

function onBuyWithBackpackChange()
  if selectedItem then
    refreshItem(selectedItem)
  end
end

function onIgnoreCapacityChange()
  refreshPlayerGoods()
end

function onIgnoreEquippedChange()
  refreshPlayerGoods()
end

function onShowAllItemsChange()
  refreshPlayerGoods()
end

function setCurrency(currency, decimal)
  CURRENCY = currency
  CURRENCY_DECIMAL = decimal
end

function setShowWeight(state)
  showWeight = state
end

function setShowYourCapacity(state)

end

function clearSelectedItem()
  priceLabel:setText("0")
  quantityScroll:setMinimum(0)
  quantityScroll:setMaximum(0)
  quantityScroll:setValue(0)
  quantityScroll:setOn(true)
  amountText:setText('0')
  if selectedItem then
    radioItems:selectWidget(nil)
    selectedItem = nil
  end
end

function getCurrentTradeType()
  if tradeButton:getText() == tr('Buy') then
    return BUY
  else
    return SELL
  end
end

function getItemPrice(item, single)
  local amount = 1
  local single = single or false
  if not single then
    amount = quantityScroll:getValue()
  end
  if getCurrentTradeType() == BUY then
    if buyWithBackpack then
      if item.ptr:isStackable() then
        return item.price * amount + 20
      else
        return item.price * amount + math.ceil(amount / 20) * 20
      end
    end
  end
  return item.price * amount
end

function getSellQuantity(item)
  if not item or not playerItems[item:getId()] then return 0 end
  local removeAmount = 0
  if ignoreEquipped then
    local localPlayer = g_game.getLocalPlayer()
    for i = 1, LAST_INVENTORY do
      local inventoryItem = localPlayer:getInventoryItem(i)
      if inventoryItem and (inventoryItem:getId() == item:getId() and inventoryItem:getTier() == item:getTier()) then
        removeAmount = removeAmount + inventoryItem:getCount()
      end
    end
  end
  return playerItems[item:getId()] - removeAmount
end

function canTradeItem(item)
  if getCurrentTradeType() == BUY then
    return (ignoreCapacity or (not ignoreCapacity and playerFreeCapacity >= item.weight)) and
    getPlayerMoney() >= getItemPrice(item, true)
  else
    return getSellQuantity(item.ptr) > 0
  end
end

function refreshItem(item)
  priceLabel:setText(formatCurrency(getItemPrice(item)))
  itemButton:setItem(item.ptr)
  itemButton.onMouseRelease = itemPopup

  if getCurrentTradeType() == BUY then
    local capacityMaxCount = math.floor(playerFreeCapacity / item.weight)
    if ignoreCapacity then
      capacityMaxCount = uint32Max
    end
    local priceMaxCount = math.floor(getPlayerMoney() / getItemPrice(item, true))
    local finalCount = math.max(0, math.min(getMaxAmount(item), math.min(priceMaxCount, capacityMaxCount)))
    quantityScroll:setMinimum(1)
    quantityScroll:setMaximum(finalCount)
  else
    quantityScroll:setMinimum(1)
    quantityScroll:setMaximum(math.max(0, math.min(getMaxAmount(), getSellQuantity(item.ptr))))
  end

  local text = tonumber(amountText:getText())
  if not text then
    amountText:setText(quantityScroll:getMinimum())
  elseif text < quantityScroll:getMinimum() then
    amountText:setText(quantityScroll:getMinimum())
  elseif text > quantityScroll:getMaximum() then
    amountText:setText(quantityScroll:getMaximum())
  end

  setupPanel:enable()
  g_mouse.bindPress(itemButton,
    function(mousePos, mouseMoved) if g_keyboard.isShiftPressed() then g_game.inspectNpcTrade(itemButton:getItem()) end end)
end

function refreshTradeItems()
  if not g_game.isOnline() then
    return
  end

  local layout = itemsPanel:getLayout()
  layout:disableUpdates()

  clearSelectedItem()

  searchText:clearText()
  itemsPanel:destroyChildren()

  if radioItems then
    radioItems:destroy()
  end
  radioItems = UIRadioGroup.create()

  local currentTradeItems = tradeItems[getCurrentTradeType()]
  for key, item in ipairs(currentTradeItems) do
    if getCurrentTradeType() == SELL and not canTradeItem(item) then
      goto continue
    end
    local itemBox = g_ui.createWidget('NPCItemBox', itemsPanel)
    itemBox:setId("itemBox_" .. item.name)
    itemBox.item = item
  
    local price = formatCurrency(item.price)
    local informationText = 'Price ' .. price
  
    if showWeight and item.weight > 0 then
      local weight = string.format('%.2f', item.weight) .. ' ' .. WEIGHT_UNIT
      informationText = informationText .. ', ' .. weight
    end

    local description = string.format('%s\n%s', short_text(item.name, 15), short_text(informationText, 16))
    itemBox.nameLabel:setText(description, true)

    local itemWidget = itemBox:getChildById('item')
    itemWidget:setItem(item.ptr)
    itemBox.onMouseRelease = itemPopup

    if (string.len(item.name) > 15) or (string.len(informationText) > 16) then
      itemBox:setTooltip(string.format('%s\n%s', item.name, informationText))
    end

    if not canTradeItem(item) then
      itemBox.nameLabel:setColor('#707070')
    end

    radioItems:addWidget(itemBox)
    ::continue::
  end

  layout:enableUpdates()
  layout:update()
end

function refreshPlayerGoods()
  if not initialized then return end

  moneyLabel:setText(comma_value(formatCurrency(getPlayerMoney())))

  local currentTradeType = getCurrentTradeType()
  local searchFilter = searchText:getText():lower()
  local foundSelectedItem = false

  local itemWidgets = {}
  local items = itemsPanel:getChildCount()
  for i = 1, items do
    local itemWidget = itemsPanel:getChildByIndex(i)
    table.insert(itemWidgets, itemWidget)
  end

  local function sortByName(a, b)
    return a.item.name:lower() < b.item.name:lower()
  end

  local function sortByPrice(a, b)
    return a.item.price < b.item.price
  end

  local function sortByWeight(a, b)
    return a.item.weight < b.item.weight
  end

  if SORT_BY == "name" then
    table.sort(itemWidgets, sortByName)
  elseif SORT_BY == "price" then
    table.sort(itemWidgets, sortByPrice)
  elseif SORT_BY == "weight" then
    table.sort(itemWidgets, sortByWeight)
  end

  for index, itemWidget in ipairs(itemWidgets) do
    itemsPanel:moveChildToIndex(itemWidget, index)
  end

  for _, itemWidget in ipairs(itemWidgets) do
    local item = itemWidget.item

    local canTrade = canTradeItem(item)
    itemWidget:setOn(canTrade)
    itemWidget.nameLabel:setEnabled(canTrade)
    local searchFilterEscaped = string.searchEscape(searchFilter)
    local searchCondition = (searchFilterEscaped == '') or
    (searchFilterEscaped ~= '' and string.find(item.name:lower(), searchFilterEscaped) ~= nil)
    local showAllItemsCondition = (currentTradeType == BUY) or (currentTradeType == SELL and canTrade)
    itemWidget:setVisible(searchCondition and showAllItemsCondition)

    if selectedItem == item and itemWidget:isEnabled() and itemWidget:isVisible() then
      foundSelectedItem = true
    end
  end

  if not foundSelectedItem then
    clearSelectedItem()
  end

  if selectedItem then
    refreshItem(selectedItem)
  end
end

function onOpenNpcTrade(items, currencyId, currencyName)
  CURRENCYID = currencyId
  currencyItem:setItemId(currencyId)
  currencyItem:setVisible(true)
  itemBorder:setVisible(true)
  currencyItem:setItemCount(100)
  currencyItem:setShowCount(false)
  currencyMoneyLabel:setText('Gold:')

  if currencyId ~= GOLD_COINS and currencyName == '' then
    currencyName = getItemServerName(currencyId)
    buyWithBackpack = false
    currencyMoneyLabel:setText('Stock:')
  elseif currencyName ~= '' then
    currencyItem:setVisible(false)
    itemBorder:setVisible(false)
    currencyMoneyLabel:setText('Stock:')
  end

  local currencyName = currencyName ~= '' and currencyName or 'Gold Coin'
  currencyLabel:setText(short_text(currencyName, 11))
  currencyLabel:removeTooltip()
  if #currencyName > 11 then
    currencyLabel:setTooltip(currencyName)
  end

  tradeItems[BUY] = {}
  tradeItems[SELL] = {}
  for _, item in pairs(items) do
    if item[4] > 0 then
      local newItem = {}
      newItem.ptr = item[1]
      newItem.name = item[2]
      newItem.weight = item[3] / 100
      newItem.price = item[4]
      table.insert(tradeItems[BUY], newItem)
    end

    if item[5] > 0 then
      local newItem = {}
      newItem.ptr = item[1]
      newItem.name = item[2]
      newItem.weight = item[3] / 100
      newItem.price = item[5]
      table.insert(tradeItems[SELL], newItem)
    end
  end

  addEvent(show) -- player goods has not been parsed yet
  scheduleEvent(refreshTradeItems, 50)
  scheduleEvent(refreshPlayerGoods, 50)
  if tradeButton:getText() == "Ok" then
    tradeButton:setText("Buy")
  end
end

function closeNpcTrade()
  g_game.doThing(false)
  g_game.closeNpcTrade()
  g_game.doThing(true)
  addEvent(hide)
end

function onCloseNpcTrade()
  addEvent(hide)
end

function onPlayerGoods(items)
  playerItems = {}
  
  -- Ensure items is a table before using pairs
  if type(items) ~= 'table' then
    return
  end
  
  for id, amount in pairs(items) do
    if not playerItems[id] then
      playerItems[id] = amount
    else
      playerItems[id] = playerItems[id] + amount
    end
  end

  refreshPlayerGoods()
end

function onFreeCapacityChange(localPlayer, freeCapacity, oldFreeCapacity)
  playerFreeCapacity = freeCapacity

  if npcWindow:isVisible() then
    refreshPlayerGoods()
  end
end

function onInventoryChange(inventory, item, oldItem)
  refreshPlayerGoods()
end

function getTradeItemData(id, type)
  if table.empty(tradeItems[type]) then
    return false
  end

  if type then
    for key, item in pairs(tradeItems[type]) do
      if item.ptr and item.ptr:getId() == id then
        return item
      end
    end
  else
    for _, items in pairs(tradeItems) do
      for key, item in pairs(items) do
        if item.ptr and item.ptr:getId() == id then
          return item
        end
      end
    end
  end
  return false
end

function checkSellAllTooltip()
  sellAllButton:setEnabled(true)
  sellAllButton:removeTooltip()
  sellAllWithDelayButton:setEnabled(true)
  sellAllWithDelayButton:removeTooltip()

  local total = 0
  local info = ''
  local first = true

  for key, amount in pairs(playerItems) do
    local data = getTradeItemData(key, SELL)
    if data then
      amount = getSellQuantity(data.ptr)
      if amount > 0 then
        if data and amount > 0 then
          info = info .. (not first and "\n" or "") ..
              amount .. " " ..
              data.name .. " (" ..
              data.price * amount .. " gold)"

          total = total + (data.price * amount)
          if first then first = false end
        end
      end
    end
  end
  if info ~= '' then
    info = info .. "\nTotal: " .. total .. " gold"
    sellAllButton:setTooltip(info)
    sellAllWithDelayButton:setTooltip(info)
  else
    sellAllButton:setEnabled(false)
    sellAllWithDelayButton:setEnabled(false)
  end
end

function formatCurrency(amount)
  if CURRENCY_DECIMAL then
    return string.format("%.02f", amount / 100.0)
  else
    return amount
  end
end

function getMaxAmount(item)
  if getCurrentTradeType() == SELL and g_game.getFeature(GameDoubleShopSellAmount) then
    return 10000
  end

  if item and getCurrentTradeType() == BUY and item.ptr:isStackable() then
    return 10000
  end

  return 100
end

function sellAll(delayed, exceptions)
  -- backward support
  if type(delayed) == "table" then
    exceptions = delayed
    delayed = false
  end
  exceptions = exceptions or {}
  removeEvent(sellAllWithDelayEvent)
  local queue = {}
  for _, entry in ipairs(tradeItems[SELL]) do
    local id = entry.ptr:getId()
    if not table.find(exceptions, id) then
      local sellQuantity = getSellQuantity(entry.ptr)
      while sellQuantity > 0 do
        local maxAmount = math.min(sellQuantity, getMaxAmount())
        if delayed then
          g_game.sellItem(entry.ptr, maxAmount, ignoreEquipped)
          sellAllWithDelayEvent = scheduleEvent(function() sellAll(true) end, 1100)
          return
        end
        table.insert(queue, { entry.ptr, maxAmount, ignoreEquipped })
        sellQuantity = sellQuantity - maxAmount
      end
    end
  end
  for _, entry in ipairs(queue) do
    g_game.sellItem(entry[1], entry[2], entry[3])
  end
end

function getPlayerMoney()
  playerMoney = g_game.getLocalPlayer():getResourceBalance(ResourceBank) + g_game.getLocalPlayer():getResourceBalance(ResourceInventary)
  if CURRENCYID ~= GOLD_COINS and CURRENCYID > 0 then
    playerMoney = g_game.getLocalPlayer():getResourceBalance(ResourceNpcTrade)
  elseif CURRENCYID == 0 then
    playerMoney = g_game.getLocalPlayer():getResourceBalance(ResourceNpcStorageTrade)
  end

  return playerMoney
end

function onAmountEdit(self)
  local text = tonumber(self:getText())
  if not text then
    return
  end

  local minValue = quantityScroll:getMinimum()
  local maxValue = quantityScroll:getMaximum()
  if minValue > text then
    self:setText(minValue, false)
    text = minValue
  elseif maxValue < text then
    self:setText(maxValue, false)
    text = maxValue
  end

  quantityScroll:setValue(text)
  onQuantityValueChange(tonumber(text))
end

function clearSearch()
  searchText:setText('')
  clearSelectedItem()
end

function onTypeFieldsHover(widget, hovered)
  if not npcWindow then
    return true
  end

  if not hovered and npcWindow:getBorderTopWidth() > 0 then
    return
  end

  -- Focus handling is typically managed automatically by the UI system
  -- modules.game_interface.toggleFocus(hovered, "npctrade")
end

function toggleNPCFocus(visible)
  -- Focus handling is typically managed automatically by the UI system
  -- modules.game_interface.toggleFocus(visible, "npctrade")
  if visible then
    npcWindow:setBorderWidth(2)
    npcWindow:setBorderColor('white')
  else
    npcWindow:setBorderWidth(0)
    -- modules.game_interface.toggleInternalFocus()
  end
end

function checkItemToSell(self)
  local parent = self:getParent()
  local checkBox = parent:recursiveGetChildById('sellCheckbox')
  local gray = parent:recursiveGetChildById('gray')
  if checkBox:isChecked() then
    self:setBackgroundColor("#404040")
    checkBox:setChecked(false)
    gray:setVisible(true)
  else
    self:setBackgroundColor("#585858")
    checkBox:setChecked(true)
    gray:setVisible(false)
  end
end

function SellItemList(items, window)
  if not g_game.isOnline() then
    return
  end

  window:hide()

  local total = 0

  local itemsToSend = {}
  local maxItems = math.min(#items, 300)

  for i = 1, maxItems do
    local widget = items[i]
    if widget and widget.sellCheckbox:isChecked() and widget.item.ptr and widget.item.ptr:getId() > 0 then
      local quantity = getSellQuantity(widget.item.ptr)
      total = total + (quantity * widget.item.price)

      table.insert(itemsToSend, {
        itemId = widget.item.ptr:getId(),
        count = widget.item.ptr:getCountOrSubType(),
        amount = quantity,
        ignoreEquipped = ignoreEquipped
      })
    end
  end

  g_game.sellAllItems(itemsToSend)
  g_client.setInputLockWidget(nil)
  window:destroy()
  displayInfoBox("Quick Sell", string.format("You have sold %d items for %d gold.", #items, total))
end

local function updateBlacklist(window)
  if not window then
    return
  end

  local list = window:recursiveGetChildById('itemsList')
  if not list then
    return
  end

  list:destroyChildren()

  local count = 0
  for i, itemId in pairs(sellAllWhitelist) do
    count = count + 1
    local widget = g_ui.createWidget('QuickSellItemBox', list)
    local color = (count % 2) == 0 and '#414141' or '#484848'
    widget:setId(itemId)
    widget.itemName:setText(getItemServerName(itemId))
    widget.itemId:setItemId(itemId)
    widget:setBackgroundColor(color)
    widget:getChildById('buttonItemClear').onClick = function()
      removeItemInList(itemId)
      updateBlacklist(window)
    end
  end
end

function openBlacklist()
  local blacklistWindow = g_ui.loadUI('styles/blacklist', g_ui.getRootWidget())
  if not blacklistWindow then
    onTradeAllClick()
    return
  end

  blacklistWindow:show()
  blacklistWindow:raise()
  blacklistWindow:focus()

  g_client.setInputLockWidget(blacklistWindow)

  updateBlacklist(blacklistWindow)

  local close = function()
    g_client.setInputLockWidget(nil)
    if blacklistWindow then
      blacklistWindow:destroy()
    end
    onTradeAllClick()
  end

  blacklistWindow.contentPanel.closeButton.onClick = close
end

function onTradeAllClick()
  if getCurrentTradeType() == BUY then
    return
  end

  local radio = UIRadioGroup.create()
  window = g_ui.loadUI('styles/quicksell', g_ui.getRootWidget())
  if not window then
    return true
  end

  window:setText("Quick Sell")
  window:show(true)
  window:raise()
  window:focus()

  local saleValue = 0
  local currentTradeItems = tradeItems[getCurrentTradeType()]
  for key, item in pairs(currentTradeItems) do
    if getCurrentTradeType() == SELL and not canTradeItem(item) then
      goto continue
    elseif inWhiteList(item.ptr:getId()) then
      goto continue
    end

    local itemSquare = g_ui.createWidget('ItemQuickSell', window.contentPanel.itemsList)

    itemSquare:setId("itemSquare_" .. item.name)
    itemSquare.item = item
    itemSquare.nameLabel:setText(getSellQuantity(item.ptr) .. "x " .. item.name, true)
    itemSquare.priceLabel:setText(item.price, true)

    itemSquare.sellCheckbox.onCheckChange = function(self)
      local price = item.price * getSellQuantity(item.ptr)
      saleValue = saleValue + (self:isChecked() and price or -price)
      window.contentPanel.total:setText("Total: " .. formatMoney(saleValue, ",") .. " gps")
    end

    itemSquare.itemButton:setBackgroundColor("#585858")
    itemSquare.sellCheckbox:setChecked(true)

    local itemWidget = itemSquare:getChildById('item')
    itemWidget:setItem(item.ptr)

    radio:addWidget(itemSquare)
    ::continue::
  end

  local items = window.contentPanel.itemsList:getChildren()
  table.sort(items, function(a, b)
    local priceA = tonumber(a.priceLabel:getText())
    local priceB = tonumber(b.priceLabel:getText())
    return priceA > priceB
  end)
  for i, widget in ipairs(items) do
    window.contentPanel.itemsList:moveChildToIndex(widget, i)
  end

  g_client.setInputLockWidget(window)

  local close = function()
    g_client.setInputLockWidget(nil)
    window:destroy()
  end

  local sell = function()
    local warningWindow = nil
    local selectedItems = {}
    local notWorthItems = {}
    local items = window.contentPanel.itemsList:getChildren()
    for i, widget in ipairs(items) do
      if widget.sellCheckbox:isChecked() then
        table.insert(selectedItems, widget.item)
        if tonumber(widget.priceLabel:getText()) < widget.item.ptr:getAverageMarketValue() then
          table.insert(notWorthItems, widget.item)
        end
      end
    end

    if #selectedItems <= 0 then
      return
    end

    if #notWorthItems > 0 then
      local message = ""
      for i, item in ipairs(notWorthItems) do
        message = message .. string.format("  - %s\n", item.name)
      end
      local yesCallback = function()
        SellItemList(items, window)
        if warningWindow then
          warningWindow:destroy()
          warningWindow = nil
          g_client.setInputLockWidget(nil)
        end
      end
      local noCallback = function()
        if window then
          window:show()
          g_client.setInputLockWidget(window)
        else
          g_client.setInputLockWidget(nil)
        end
        if warningWindow then
          warningWindow:destroy()
          warningWindow = nil
        end
      end
      window:hide()
      warningWindow = g_ui.createWidget('WarningQuickWindow', rootWidget)
      warningWindow.itemTextWarning:setText(message)
      warningWindow.itemTextWarning:setEditable(false)
      warningWindow.itemTextWarning:setCursorVisible(false)
      warningWindow:getChildById('okButton').onClick = yesCallback
      warningWindow:getChildById('cancelButton').onClick = noCallback
      warningWindow:show()
      warningWindow:focus()
      g_client.setInputLockWidget(warningWindow)
    else
      SellItemList(items, window)
    end
  end

  window.contentPanel.blackListButton.onClick = function()
    close(); openBlacklist()
  end
  window.contentPanel.cancelButton.onClick = close
  window.onEscape = close
  window.contentPanel.okButton.onClick = sell
  window.onEnter = sell
end

marketWindow = nil

-- Donation URL for buying points/coins
local DONATION_URL = "http://localhost/?subtopic=shop&step=terms"

local marketItems = {}
local categoryList = {}
local depotLockerItems = {}
local buyOffers = {}
local sellOffers = {}

local lastSelectedCategory = nil
local lastSelectedItem = {}

local lastSelectedMySell = nil
local lastSelectedMyBuy = nil

local lastSelectedHistorySell = nil
local lastSelectedHistoryBuy = nil

local showLockerOnly = false
local mainMarket = nil

local lastItemID = 0
local lastItemTier = 0
local currentActionType = 1
local isSearching = false

local cache = {
	SCROLL_MARKET_ITEMS = {
		listMin = 0,
		listMax = 0,
		listFit = 0,
		listPool = 14,
		listData = {},
		offset = 0,
		scrollDelay = 0
	},

	SCROLL_SELL_OFFERS = {
		listMin = 0,
		listMax = 0,
		listFit = 0,
		listPool = 14,
		listData = {},
		lastSelected = 0
	},

	SCROLL_BUY_OFFERS = {
		listMin = 0,
		listMax = 0,
		listFit = 0,
		listPool = 14,
		listData = {},
		lastSelected = 0
	}
}

local sortButtons = {
	["levelButton"] = false,
	["vocButton"] = false,
	["oneButton"] = false,
	["twoButton"] = false,
	["classFilter"] = -1,
	["tierFilter"] = 0
}

local enableCategories = { 17, 18, 19, 20, 21, 27, 32 }
local enableClassification = {1, 3, 7, 8, 15, 17, 18, 19, 20, 21, 24, 27, 32 }

function init()
  marketWindow = g_ui.displayUI('t_market')
  mainMarket = marketWindow.contentPanel.mainMarket
  marketWindow.contentPanel.lockerOnly.onCheckChange = function(self, checked) toggleShowLockerOnly(self, checked) end

  hide()
  mainMarket.createOfferSell:setChecked(true)
  connect(g_game, {
	onResourcesBalanceChange = onResourcesBalanceChange,
	onGameEnd = hide,
	onGameStart = hide,
	onMarketEnter = onMarketEnter,
	onMarketBrowse = onMarketBrowse,
	onMarketDetail = onMarketDetail,
	onMarketReadOffer = onMarketReadOffer,
	onParseStoreGetCoin = onParseStoreGetCoin,
	onMarketLeave = hide,
  })
end

function terminate()
   disconnect(g_game, {
	  onResourcesBalanceChange = onResourcesBalanceChange,
	  onGameStart = hide,
	  onGameEnd = hide,
	  onMarketEnter = onMarketEnter,
	  onMarketBrowse = onMarketBrowse,
	  onMarketDetail = onMarketDetail,
	  onMarketReadOffer = onMarketReadOffer,
	  onParseStoreGetCoin = onParseStoreGetCoin,
	  onMarketLeave = hide,
	})

	if marketWindow then
	  marketWindow:destroy()
	  marketWindow = nil
	end
end

function toggle()
  if marketWindow:isVisible() then
    marketWindow:hide()
	modules.game_console.getConsole():focus()
  else
    marketWindow:show(true)
    marketWindow.contentPanel.searchText:focus()
  end
end

function hide()
	local benchmark = g_clock.millis()
	local mainMarket = marketWindow.contentPanel:getChildById('mainMarket')
	local detailsMarket = marketWindow.contentPanel:getChildById('detailsMarket')
	local closeButton = marketWindow.contentPanel:getChildById('closeButton')
	local marketButton = marketWindow.contentPanel:getChildById('marketButton')
	mainMarket:setVisible(true)
	closeButton:setVisible(true)
  	detailsMarket:setVisible(false)
  	marketButton:setVisible(false)

	onClearMainMarket(true)
	marketWindow:hide()
	onClearSearch()

	sendMarketLeave()
  	lastSelectedItem = {}
	modules.game_console.getConsole():focus()
	print("Market closed in " .. (g_clock.millis() - benchmark) / 1000 .. " seconds.")
end

function show()
  marketWindow:show(true)
  marketWindow.contentPanel.searchText:focus()
  sortButtons["classFilter"] = -1
  sortButtons["tierFilter"] = 0
end

function buyPoints()
  if DONATION_URL and DONATION_URL ~= "https://yourserver.com/donate" then
    g_platform.openUrl(DONATION_URL)
  else
    displayInfoBox("Information", "Donation URL not configured. Please contact the server administrator.")
  end
end

function detailsButton()
  local mainMarket = marketWindow.contentPanel:getChildById('mainMarket')
  local detailsMarket = marketWindow.contentPanel:getChildById('detailsMarket')
  local closeButton = marketWindow.contentPanel:getChildById('closeButton')
  local marketButton = marketWindow.contentPanel:getChildById('marketButton')

  if detailsMarket:isVisible() then
    return
  end

  if mainMarket:isVisible() then
    mainMarket:setVisible(false)
    detailsMarket:setVisible(true)
    closeButton:setVisible(false)
    marketButton:setVisible(true)
  else
    detailsMarket:setVisible(false)
    mainMarket:setVisible(true)
    marketButton:setVisible(false)
    closeButton:setVisible(true)
  end
end

function offersButton()
  local mainMarket = marketWindow.contentPanel:getChildById('mainMarket')
  local detailsMarket = marketWindow.contentPanel:getChildById('detailsMarket')
  local closeButton = marketWindow.contentPanel:getChildById('closeButton')
  local marketButton = marketWindow.contentPanel:getChildById('marketButton')
  if not mainMarket:isVisible() then
    detailsMarket:setVisible(false)
    mainMarket:setVisible(true)
    marketButton:setVisible(false)
    closeButton:setVisible(true)
  end
end

function myOffersButton(widget)
  local marketPanel = marketWindow.contentPanel:getChildById('mainMarket')
  local detailsMarket = marketWindow.contentPanel:getChildById('detailsMarket')
  local marketMain = marketWindow:getChildById('contentPanel')
  local marketHistory = marketWindow:getChildById('MarketHistory')
  local sellButton = marketWindow.MarketHistory.currentOffers.buyCancelOffer
  local closeButton = marketWindow.contentPanel:getChildById('closeButton')

  MarketOwnOffers.myBuyOffers = {}
  MarketOwnOffers.mySellOffers = {}

  if widget:getId() == 'myOffers' then
	sendMarketAction(2)
  elseif widget:getId() == "currentOffers" then
	sendMarketAction(2)
	return
  elseif widget:getId() == 'historyButton' then
	sendMarketAction(1)
	return
  end

  if widget:getId() ~= 'myOffers' then
	if lastItemID and lastItemID > 0 then
		sendMarketAction(3, lastItemID, lastItemTier)
	end
	lastItemID = 0
	lastItemTier = 0
  end

  if marketMain:isVisible() then
	marketWindow.MarketHistory.currentOffers.sellSeparator:setVisible(false)
	marketWindow.MarketHistory.currentOffers.sellStatusButton:setVisible(false)
	marketWindow.MarketHistory.currentOffers.buySeparator:setVisible(false)
	marketWindow.MarketHistory.currentOffers.buyStatusButton:setVisible(false)
	marketWindow.MarketHistory.currentOffers.sellEndButton:setWidth(220)
	marketWindow.MarketHistory.currentOffers.buyEndButton:setWidth(220)
    marketMain:setVisible(false)
	closeButton:setVisible(false)
    marketHistory:setVisible(true)
  else
	lastSelectedMySell = nil
	lastSelectedMyBuy = nil
	lastSelectedHistorySell = nil
	lastSelectedHistoryBuy = nil
    marketHistory:setVisible(false)
    marketMain:setVisible(true)
    detailsMarket:setVisible(false)
    marketPanel:setVisible(true)
	closeButton:setVisible(true)
  end
end

function getDepotItemCount(itemId, tier)
	for _, data in pairs(depotLockerItems) do
		if data[1] == itemId and data[2] == tier then
			return data[3]
		end
	end

	if itemId == 22118 then
		return getTransferableTibiaCoins()
	end

	return 0
end

-- Temporary storage for collecting market offers
local marketOffersBuy = {}
local marketOffersSell = {}
local marketHistoryBuy = {}
local marketHistorySell = {}

function onMarketReadOffer(action, amount, counter, itemId, playerName, price, state, timestamp, var, itemTier)
	print("onMarketReadOffer - action:", action, "amount:", amount, "itemId:", itemId, "var:", var, "player:", playerName, "price:", price, "counter:", counter, "timestamp:", timestamp)
	
	-- Create offer data structure
	local offer = {
		timestamp = timestamp,
		counter = counter,
		action = action,
		itemId = itemId,
		amount = amount,
		price = price,
		holder = playerName,
		state = state,
		var = var,
		tier = itemTier or 0
	}
	
	-- Since var seems to be itemId, we need to determine request type differently
	-- For now, just accumulate all offers - onMarketBrowse will process them
	if action == 0 then  -- Buy offer (MarketAction.Buy)
		table.insert(marketOffersBuy, offer)
		print("Added to marketOffersBuy, count now:", #marketOffersBuy)
	else  -- Sell offer (action == 1, MarketAction.Sell)
		table.insert(marketOffersSell, offer)
		print("Added to marketOffersSell, count now:", #marketOffersSell)
	end
end

function onParseStoreGetCoin(coins, transferableCoins)
	if not marketWindow or not marketWindow:isVisible() then
		return
	end
	
	local coinTooltip = "Total Tibia Coins: " .. comma_value(coins + transferableCoins) .. 
	                    "\nIncluded transferable Tibia Coins: " .. comma_value(transferableCoins)

	marketWindow.contentPanel.coinPanel.gold:setText(comma_value(transferableCoins))
	marketWindow.contentPanel.coinPanel.gold:setTooltip(coinTooltip)
	marketWindow.MarketHistory.currentOffers.coinPanel.gold:setText(comma_value(transferableCoins))
	marketWindow.MarketHistory.currentOffers.coinPanel.gold:setTooltip(coinTooltip)

	local selectedItem = marketWindow.contentPanel.selectedItem:getItem()
	if selectedItem and selectedItem:getId() == 22118 then
		selectedItem:setCount(transferableCoins)
	end

	local itemList = marketWindow:recursiveGetChildById("itemList")
	if not itemList then
		return
	end

	for _, widget in pairs(itemList:getChildren()) do
		local widgetItem = widget.item:getItem()
		if widgetItem and widgetItem:getId() == 22118 then
			widgetItem:setCount(transferableCoins)
			break
		end
	end
end

function onResourcesBalanceChange(value, oldBalance, resourceType)
	-- Only update if it's bank (0) or inventory (1) gold
	if resourceType > 1 then
		return
	end
	
	if not g_game.isOnline() or not marketWindow or not marketWindow:isVisible() then
		return
	end

	local playerBank = g_game.getLocalPlayer():getResourceBalance(ResourceTypes.BANK_BALANCE)
	local playerInventory = g_game.getLocalPlayer():getResourceBalance(ResourceTypes.GOLD_EQUIPPED)
	local playerCoins = getTransferableTibiaCoins()
	local moneyTooltip = "Cash: " .. comma_value(playerInventory) .. 
	                     "\nBank: " .. comma_value(playerBank)

	marketWindow.contentPanel.moneyPanel.gold:setText(comma_value(playerBank + playerInventory))
	marketWindow.contentPanel.moneyPanel.gold:setTooltip(moneyTooltip)
	marketWindow.contentPanel.coinPanel.gold:setText(comma_value(playerCoins))

	marketWindow.MarketHistory.currentOffers.moneyPanel.gold:setText(comma_value(playerBank + playerInventory))
	marketWindow.MarketHistory.currentOffers.moneyPanel.gold:setTooltip(moneyTooltip)
	marketWindow.MarketHistory.currentOffers.coinPanel.gold:setText(comma_value(playerCoins))
end

function configureList()
	marketItems = {}
	for c = MarketCategory.First, MarketCategoryWeaponsAll do
		marketItems[c] = {}
	end
	-- Initialize FistWeapons category
	marketItems[MarketCategoryFistWeapons] = {}

	local types = g_things.findThingTypeByAttr(ThingAttrMarket, 0)
	for _, itemType in pairs(types) do
		if itemType:getId() == 49870 or itemType:getId() == 14258 then
			goto continue
		end

		local item = Item.create(itemType:getId())
		if item then
			local marketData = itemType:getMarketData()
			if not table.empty(marketData) then
				item:setId(marketData.showAs)
				local marketItem = { displayItem = item, thingType = itemType, marketData = marketData }
				if marketItems[marketData.category] ~= nil then
					table.insert(marketItems[marketData.category], marketItem)
				end
			end
		end

		:: continue ::
	end

	-- Weapons all category
	for c = MarketCategory.Ammunition, MarketCategory.WandsRods do
		if marketItems[c] then
			for _, data in pairs(marketItems[c]) do
				table.insert(marketItems[MarketCategoryWeaponsAll], data)
			end
		end
	end

	if marketItems[MarketCategoryFistWeapons] then
		for _, data in pairs(marketItems[MarketCategoryFistWeapons]) do
			table.insert(marketItems[MarketCategoryWeaponsAll], data)
		end
	end

	local function compareMarketItemsByNameCaseInsensitive(a, b)
		local nameA = string.lower(a.marketData.name)
		local nameB = string.lower(b.marketData.name)
		return nameA < nameB
	end

	for c = MarketCategory.First, MarketCategoryWeaponsAll do
		if marketItems[c] then
			table.sort(marketItems[c], compareMarketItemsByNameCaseInsensitive)
		end
	end

	categoryList = {}
	-- Build category list from MarketCategory constants
	for i = MarketCategory.First, MarketCategory.Last do
		if i >= MarketCategory.Ammunition and i <= MarketCategory.WandsRods then
			-- Skip weapon subcategories, they go into WeaponsAll
		else
			local categoryName = getMarketCategoryName(i)
			if categoryName then
				table.insert(categoryList, {i, categoryName})
			end
		end
	end

	table.insert(categoryList, {MarketCategoryWeaponsAll, "Weapons: All"})
	table.sort(categoryList, function(a, b) return a[2] < b[2] end)
end

-- Main Window
function onMarketEnter(items, offerCount, balance, vocation)
	configureList()
	depotLockerItems = items

	if marketWindow:isVisible() then
		return
	end

	marketWindow.contentPanel.category:destroyChildren()

	local colorCount = 0
	for _, pair in pairs(categoryList) do
		local widget = g_ui.createWidget('CategoryItemListLabel', marketWindow.contentPanel.category)
		local color = colorCount % 2 == 0 and '#414141' or '#484848'
		widget.categoryId = pair[1]  -- Store category ID in widget property
		widget.color = color
		widget:setId(pair[2])
		widget:setText(pair[2])
		widget:setBackgroundColor(color)
		colorCount = colorCount + 1
	end

	local firstWidget = marketWindow.contentPanel.category:getFirstChild()
	marketWindow.contentPanel.category:moveChildToIndex(firstWidget, 2)

	local lastWidget = marketWindow.contentPanel.category:getChildById('Weapons: All')
	marketWindow.contentPanel.category:moveChildToIndex(lastWidget, marketWindow.contentPanel.category:getChildCount())

	marketWindow.contentPanel.classFilter:clearOptions()
	marketWindow.contentPanel.tierFilter:clearOptions()

	local itemListScroll = marketWindow:recursiveGetChildById("itemListScroll")
	itemListScroll:setValue(0)
	itemListScroll:setMinimum(0)
	itemListScroll:setMaximum(0)
	itemListScroll.onValueChange = nil

	show()
	marketWindow:focus()
	onResourcesBalanceChange(0, 0, 0)
	marketWindow.contentPanel.category.onChildFocusChange = function(self, selected) onSelectChildCategory(self, selected) end
end

function onMarketBrowse(intOffers, nameOffers)
	print("=== onMarketBrowse START ===")
	print("intOffers type:", type(intOffers), "value:", intOffers)
	print("nameOffers type:", type(nameOffers), "value:", nameOffers)
	print("marketOffersBuy before processing:", #marketOffersBuy, "items")
	print("marketOffersSell before processing:", #marketOffersSell, "items")
	
	if table.empty(lastSelectedItem) then 
		print("lastSelectedItem is empty, returning")
		return 
	end

	-- Process accumulated offers from onMarketReadOffer
	local buyOffersData = marketOffersBuy
	local sellOffersData = marketOffersSell
	
	print("Buy offers count:", #buyOffersData, "Sell offers count:", #sellOffersData)
	
	-- Clear the accumulator for next browse
	marketOffersBuy = {}
	marketOffersSell = {}
	
	-- Get current item info
	local itemID = lastSelectedItem.itemId
	local tier = lastSelectedItem.tier or 0

	if lastItemID == itemID and lastItemTier == tier then
		-- Update existing offers (single offer update)
		if #buyOffersData == 1 then
			local updateItem = buyOffersData[1]
			if buyOffers then
				for i, data in pairs(buyOffers) do
					if data.counter == updateItem.counter and data.timestamp == updateItem.timestamp then
						if updateItem.amount == 0 then
							table.remove(buyOffers, i)
						else
							buyOffers[i] = updateItem
						end
						break
					end
				end
			end
		end

		if #sellOffersData == 1 then
			local updateItem = sellOffersData[1]
			if sellOffers then
				for i, data in pairs(sellOffers) do
					if data.counter == updateItem.counter and data.timestamp == updateItem.timestamp then
						if updateItem.amount == 0 then
							table.remove(sellOffers, i)
						else
							sellOffers[i] = updateItem
						end
						break
					end
				end
			end
		end
	else
		-- Full refresh - replace all offers
		buyOffers = buyOffersData
		sellOffers = sellOffersData
		lastItemID = itemID
		lastItemTier = tier
	end

	cache.SCROLL_BUY_OFFERS.listFit = math.floor(mainMarket.buyOffersList:getHeight() / 16) - 1
	cache.SCROLL_BUY_OFFERS.listMin = 0
	cache.SCROLL_BUY_OFFERS.listPool = {}
	cache.SCROLL_BUY_OFFERS.listData = buyOffers or {}
	cache.SCROLL_BUY_OFFERS.lastSelected = 0

	local colorCount = 0
	mainMarket.buyOffersList:destroyChildren()

	print("Displaying buy offers - total:", buyOffers and #buyOffers or 0)
	
	if buyOffers then
		for i, data in ipairs(buyOffers) do
			if i > cache.SCROLL_BUY_OFFERS.listFit then
				break
			end

			local widget = g_ui.createWidget('MarketOfferWidget', mainMarket.buyOffersList)
			local color = colorCount % 2 == 0 and '#414141' or '#484848'
			local holder = data.holder
			widget:setId(color)
			widget.offerId = i  -- Store offer index as property
			widget:setBackgroundColor(color)
			widget.name:setText(short_text(data.holder, 15))
			widget.amount:setText(data.amount)
			widget.endAt:setText(os.date("%Y-%m-%d, %H:%M:%S", data.timestamp))


		if #holder >= 15 then
			widget.name:setTooltip(data.holder)
		end

		local totalPrice = data.price * data.amount
		local unitPrice = data.price
		widget.piecePrice:setText(convertGold(unitPrice))
		widget.totalPrice:setText(convertGold(totalPrice))
		colorCount = colorCount + 1

		local count = getDepotItemCount(itemID, tier)
		widget.piecePrice:setColor(count > 0 and "#c0c0c0" or "#808080")
		widget.totalPrice:setColor(count > 0 and "#c0c0c0" or "#808080")
		widget.name:setColor(count > 0 and "#c0c0c0" or "#808080")
		widget.amount:setColor(count > 0 and "#c0c0c0" or "#808080")
		widget.endAt:setColor(count > 0 and "#c0c0c0" or "#808080")
		table.insert(cache.SCROLL_BUY_OFFERS.listPool, widget)
		end
	end

	print("Buy offers displayed:", #cache.SCROLL_BUY_OFFERS.listPool)

	cache.SCROLL_BUY_OFFERS.listMin = (buyOffers and #buyOffers > 0) and 1 or 0
	cache.SCROLL_BUY_OFFERS.listMax = (buyOffers and #buyOffers or 0) + 1

	local buyListScroll = marketWindow:recursiveGetChildById("buyOffersListScroll")
	buyListScroll:setValue(cache.SCROLL_BUY_OFFERS.listMin)
	buyListScroll:setMinimum(cache.SCROLL_BUY_OFFERS.listMin)
	buyListScroll:setMaximum(#cache.SCROLL_BUY_OFFERS.listPool < 11 and 0 or math.max(0, cache.SCROLL_BUY_OFFERS.listMax - #cache.SCROLL_BUY_OFFERS.listPool))
	buyListScroll.onValueChange = function(self, value, delta) onBuyListValueChange(self, value, delta) end
	
	cache.SCROLL_SELL_OFFERS.listFit = math.floor(mainMarket.sellOffersList:getHeight() / 16) - 1
	cache.SCROLL_SELL_OFFERS.listMin = 0
	cache.SCROLL_SELL_OFFERS.listPool = {}
	cache.SCROLL_SELL_OFFERS.listData = sellOffers or {}
	cache.SCROLL_SELL_OFFERS.lastSelected = 0

	colorCount = 0
	mainMarket.sellOffersList:destroyChildren()

	if sellOffers then
		for i, data in ipairs(sellOffers) do
			if i > cache.SCROLL_SELL_OFFERS.listFit then
				break
			end

			local widget = g_ui.createWidget('MarketOfferWidget', mainMarket.sellOffersList)
			local color = colorCount % 2 == 0 and '#414141' or '#484848'
			local holder = data.holder
			widget:setId(color)
			widget.offerId = i  -- Store offer index as property
			widget:setBackgroundColor(color)
			widget.name:setText(short_text(data.holder, 15))
			widget.amount:setText(data.amount)
			widget.endAt:setText(os.date("%Y-%m-%d, %H:%M:%S", data.timestamp))


		local totalPrice = data.price * data.amount
		local unitPrice = data.price
		widget.piecePrice:setText(convertGold(unitPrice))
		widget.totalPrice:setText(convertGold(totalPrice))

		if #holder >= 15 then
			widget.name:setTooltip(data.holder)
		end

		if totalPrice > 99999999 then
		widget.totalPrice:setTooltip(comma_value(totalPrice))
		end

		if unitPrice > 99999999 then
		widget.piecePrice:setTooltip(comma_value(unitPrice))
		end

		local hasMoney = getTotalMoney() >= unitPrice
		widget.piecePrice:setColor(hasMoney and "#c0c0c0" or "#808080")
		widget.totalPrice:setColor(hasMoney and "#c0c0c0" or "#808080")
		widget.name:setColor(hasMoney and "#c0c0c0" or "#808080")
		widget.amount:setColor(hasMoney and "#c0c0c0" or "#808080")
		widget.endAt:setColor(hasMoney and "#c0c0c0" or "#808080")
		colorCount = colorCount + 1
		table.insert(cache.SCROLL_SELL_OFFERS.listPool, widget)
		end
	end

	cache.SCROLL_SELL_OFFERS.listMin = (sellOffers and #sellOffers > 0) and 1 or 0
	cache.SCROLL_SELL_OFFERS.listMax = (sellOffers and #sellOffers or 0) + 1

	local sellListScroll = marketWindow:recursiveGetChildById("sellOffersListScroll")
	sellListScroll:setValue(cache.SCROLL_SELL_OFFERS.listMin)
	sellListScroll:setMinimum(cache.SCROLL_SELL_OFFERS.listMin)
	sellListScroll:setMaximum(#cache.SCROLL_SELL_OFFERS.listPool < 11 and 0 or math.max(0, cache.SCROLL_SELL_OFFERS.listMax - #cache.SCROLL_SELL_OFFERS.listPool))
	sellListScroll.onValueChange = function(self, value, delta) onSellListValueChange(self, value, delta) end

	lastItemID = itemID
	lastItemTier = tier
	mainMarket.sellOffersList.onChildFocusChange = function(self, selected, oldFocus) onSelectSellOffer(self, selected, oldFocus) end
	mainMarket.buyOffersList.onChildFocusChange = function(self, selected, oldFocus) onSelectBuyOffer(self, selected, oldFocus) end

	onUpdateChildItem(itemID, tier)
	local firstChild = mainMarket.sellOffersList:getChildren()[1]
	if firstChild then
		mainMarket.sellOffersList:focusChild(firstChild)
	end

	firstChild = mainMarket.buyOffersList:getChildren()[1]
	if firstChild then
		mainMarket.buyOffersList:focusChild(firstChild)
	end
end

function onBuyListValueChange(scroll, value, delta)
	local startLabel = math.max(cache.SCROLL_BUY_OFFERS.listMin, value)
	local endLabel = startLabel + #cache.SCROLL_BUY_OFFERS.listPool - 1
  
	if endLabel > cache.SCROLL_BUY_OFFERS.listMax then
	  endLabel = cache.SCROLL_BUY_OFFERS.listMax
	  startLabel = endLabel - #cache.SCROLL_BUY_OFFERS.listPool + 1
	end

	for i, widget in ipairs(cache.SCROLL_BUY_OFFERS.listPool) do
	  local index = startLabel + i - 1
	  local data = cache.SCROLL_BUY_OFFERS.listData[index]

	  if data then
		local color = index % 2 == 0 and '#414141' or '#484848'
		local holder = data.holder
		widget:setId(color)
		widget.offerId = index  -- Store offer index as property
		widget:setBackgroundColor(color)
		widget.name:setText(short_text(data.holder, 15))
		widget.amount:setText(data.amount)
		widget.endAt:setText(os.date("%Y-%m-%d, %H:%M:%S", data.timestamp))

		if #holder >= 15 then
			widget.name:setTooltip(data.holder)
		end

		local totalPrice = data.price * data.amount
		local unitPrice = data.price
		widget.piecePrice:setText(convertGold(unitPrice))
		widget.totalPrice:setText(convertGold(totalPrice))

		local count = getDepotItemCount(lastItemID, lastItemTier)
		widget.piecePrice:setColor(count > 0 and "#c0c0c0" or "#808080")
		widget.totalPrice:setColor(count > 0 and "#c0c0c0" or "#808080")
		widget.name:setColor(count > 0 and "#c0c0c0" or "#808080")
		widget.amount:setColor(count > 0 and "#c0c0c0" or "#808080")
		widget.endAt:setColor(count > 0 and "#c0c0c0" or "#808080")

		if index == cache.SCROLL_BUY_OFFERS.lastSelected then
			widget:setBackgroundColor('#585858')
			widget.piecePrice:setColor("#f4f4f4")
			widget.totalPrice:setColor("#f4f4f4")
			widget.name:setColor("#f4f4f4")
			widget.amount:setColor("#f4f4f4")
			widget.endAt:setColor("#f4f4f4")
		end
	  end
	end
end

function onSellListValueChange(scroll, value, delta)
	local startLabel = math.max(cache.SCROLL_SELL_OFFERS.listMin, value)
	local endLabel = startLabel + #cache.SCROLL_SELL_OFFERS.listPool - 1
  
	if endLabel > cache.SCROLL_SELL_OFFERS.listMax then
	  endLabel = cache.SCROLL_SELL_OFFERS.listMax
	  startLabel = endLabel - #cache.SCROLL_SELL_OFFERS.listPool + 1
	end

	for i, widget in ipairs(cache.SCROLL_SELL_OFFERS.listPool) do
	  local index = startLabel + i - 1
	  local data = cache.SCROLL_SELL_OFFERS.listData[index]

	  if data then
		local color = index % 2 == 0 and '#414141' or '#484848'
		local holder = data.holder
		widget:setId(color)
		widget.offerId = index  -- Store offer index as property
		widget:setBackgroundColor(color)
		widget.name:setText(short_text(data.holder, 15))
		widget.amount:setText(data.amount)
		widget.endAt:setText(os.date("%Y-%m-%d, %H:%M:%S", data.timestamp))


		local totalPrice = data.price * data.amount
		local unitPrice = data.price
		widget.piecePrice:setText(convertGold(unitPrice))
		widget.totalPrice:setText(convertGold(totalPrice))

		if #holder >= 15 then
			widget.name:setTooltip(data.holder)
		end

		if totalPrice > 99999999 then
			widget.totalPrice:setTooltip(comma_value(totalPrice))
		end

		if unitPrice > 99999999 then
			widget.piecePrice:setTooltip(comma_value(unitPrice))
		end

		local hasMoney = getTotalMoney() >= unitPrice
		widget.piecePrice:setColor(hasMoney and "#c0c0c0" or "#808080")
		widget.totalPrice:setColor(hasMoney and "#c0c0c0" or "#808080")
		widget.name:setColor(hasMoney and "#c0c0c0" or "#808080")
		widget.amount:setColor(hasMoney and "#c0c0c0" or "#808080")
		widget.endAt:setColor(hasMoney and "#c0c0c0" or "#808080")

		if index == cache.SCROLL_SELL_OFFERS.lastSelected then
			widget:setBackgroundColor('#585858')
			widget.piecePrice:setColor("#f4f4f4")
			widget.totalPrice:setColor("#f4f4f4")
			widget.name:setColor("#f4f4f4")
			widget.amount:setColor("#f4f4f4")
			widget.endAt:setColor("#f4f4f4")
		end
	  end
	end
end

function onItemListValueChange(scroll, value, delta)
	local startLabel = math.max(cache.SCROLL_MARKET_ITEMS.listMin, value)
	local endLabel = startLabel + #cache.SCROLL_MARKET_ITEMS.listPool - 1
  
	if endLabel > cache.SCROLL_MARKET_ITEMS.listMax then
	  endLabel = cache.SCROLL_MARKET_ITEMS.listMax
	  startLabel = endLabel - #cache.SCROLL_MARKET_ITEMS.listPool + 1
	end

	cache.SCROLL_MARKET_ITEMS.offset = cache.SCROLL_MARKET_ITEMS.offset + ((value % 5) * 2)
	if cache.SCROLL_MARKET_ITEMS.offset > 20 or value == 0 or value == 133 then
		cache.SCROLL_MARKET_ITEMS.offset = 0
	end
  
	if value >= #cache.SCROLL_MARKET_ITEMS.listData - 6 then
		cache.SCROLL_MARKET_ITEMS.offset = 28
	end

	local list = marketWindow:recursiveGetChildById("itemList")
	list:setVirtualOffset({x = 0, y = cache.SCROLL_MARKET_ITEMS.offset})

	for i, widget in ipairs(cache.SCROLL_MARKET_ITEMS.listPool) do
	  local index = value > 0 and (startLabel + i - 1) or (startLabel + i)
	  local data = cache.SCROLL_MARKET_ITEMS.listData[index]
	  if data and widget.item then

		local isSelected = lastSelectedItem.itemId == data.thingType:getId()
		if data.tier then
			isSelected = lastSelectedItem.itemId == data.thingType:getId() and data.tier == lastSelectedItem.tier
		end

		local backgroundColor = isSelected and '#585858' or '#404040'
		widget:setBackgroundColor(backgroundColor)
		if isSelected then
			lastSelectedItem.lastWidget = widget
		end

		local tier = sortButtons["tierFilter"] or 0
		local count = getDepotItemCount(data.thingType:getId(), tier)
		widget.item:setItemId(data.thingType:getId())

		widget.name:setTooltip('')
		widget.name:setText(data.marketData.name)
		if widget.name:getText():len() > 15 then
			widget.name:setText(short_text(data.marketData.name, 15))
			widget.name:setTooltip(data.marketData.name)
		end

		widget.item:getItem():setCount(count)
		widget.item.itemIndex = i  -- Store item index as property
		widget.item:setTooltip(tr("%s%s%s%s", comma_value(count), "x", (count > 65000 and "+ " or " "), data.marketData.name))
		widget.item:getItem():setTier(data.tier and data.tier or tier)

		if widget.name:getText():len() <= 15 then
			widget.name:setMarginTop(1)
		end

		widget.grayHover:setOpacity(count > 0 and '0.0' or '0.5')
	  end
	end
end

function onSelectChildCategory(widget, selected, keepFilter)
	if lastSelectedCategory then
		lastSelectedCategory:setBackgroundColor(lastSelectedCategory.color)
		lastSelectedCategory:setColor('#c0c0c0')
	end

	local itemList = marketWindow:recursiveGetChildById("itemList")
	if not itemList then
		return true
	end

	lastSelectedCategory = selected
	selected:setBackgroundColor('#585858')
	selected:setColor('#f4f4f4')

	cache.SCROLL_MARKET_ITEMS.listFit = math.floor(itemList:getHeight() / 36) + 1
	cache.SCROLL_MARKET_ITEMS.listMin = 0
	cache.SCROLL_MARKET_ITEMS.listPool = {}
	cache.SCROLL_MARKET_ITEMS.listData = {}

	cache.SCROLL_SELL_OFFERS.lastSelected = 0
	cache.SCROLL_BUY_OFFERS.lastSelected = 0

	marketWindow.contentPanel.itemList:destroyChildren()

	local clearHands = not lastSelectedCategory or not table.contains(enableCategories, lastSelectedCategory.categoryId)

	lastSelectedItem = {}
	onClearSearch(clearHands)
	onClearMainMarket(true)

	marketWindow.contentPanel.mainMarket.getPotionsButton:setVisible(false)

	-- Habilitar botoes
	if table.contains(enableCategories, selected.categoryId) then
		marketWindow.contentPanel.oneButton:setEnabled(true)
		marketWindow.contentPanel.twoButton:setEnabled(true)
	else
		onClearHandFilter()
	end

	if not keepFilter then
		sortButtons["classFilter"] = -1
		sortButtons["tierFilter"] = 0

		if table.contains(enableClassification, selected.categoryId) then
			marketWindow.contentPanel.classFilter:clearOptions()
			marketWindow.contentPanel.classFilter:addOption("All", nil, true)
			marketWindow.contentPanel.classFilter:addOption("None", nil, true)
			for i = 1, 4 do
				marketWindow.contentPanel.classFilter:addOption("Class " .. i, nil, true)
			end

			marketWindow.contentPanel.tierFilter:clearOptions()
			for i = 0, 10 do
				marketWindow.contentPanel.tierFilter:addOption("Tier " .. i, nil, true)
			end
		else
			marketWindow.contentPanel.classFilter:clearOptions()
			marketWindow.contentPanel.tierFilter:clearOptions()
		end
	end

	marketWindow.contentPanel.selectedItem:setItemId(0)
	itemList.onChildFocusChange = function(self, selected, oldFocus) onSelectChildItem(self, selected, oldFocus) end

	local tier = sortButtons["tierFilter"] or 0
	-- Sorted items
	for i, itemInfo in pairs(marketItems[selected.categoryId]) do
		if not checkSortMarketOptions(itemInfo) or (showLockerOnly and getDepotItemCount(itemInfo.thingType:getId(), tier) == 0) then
			goto continue
		end

		table.insert(cache.SCROLL_MARKET_ITEMS.listData, itemInfo)
		:: continue ::
	end

	for i, itemInfo in pairs(cache.SCROLL_MARKET_ITEMS.listData) do
		if #cache.SCROLL_MARKET_ITEMS.listPool >= cache.SCROLL_MARKET_ITEMS.listFit then
			break
		end

		local count = getDepotItemCount(itemInfo.thingType:getId(), tier)
		if not checkSortMarketOptions(itemInfo) or (count == 0 and showLockerOnly) then
			goto continue
		end

		local widget = g_ui.createWidget('MarketItemList', itemList)

		widget.item:setItemId(itemInfo.thingType:getId())

		widget.name:setText(itemInfo.marketData.name)
		if widget.name:getText():len() > 15 then
			widget.name:setText(short_text(itemInfo.marketData.name, 15))
			widget.name:setTooltip(itemInfo.marketData.name)
		end

		widget:setBackgroundColor('#404040')
		widget.item:getItem():setCount(count)
		widget.item.itemIndex = i  -- Store item index as property
		widget.item:setTooltip(tr("%s%s%s%s", comma_value(count), "x", (count > 65000 and "+ " or " "), itemInfo.marketData.name))

		if tier ~= 0 then
			widget.item:getItem():setTier(tier)
		end

		if widget.name:getText():len() <= 15 then
			widget.name:setMarginTop(1)
		end

		if count > 0 then
			widget.grayHover:setOpacity('0.0')
		end

		table.insert(cache.SCROLL_MARKET_ITEMS.listPool, widget)

		:: continue ::
	end

	cache.SCROLL_MARKET_ITEMS.listMax = #cache.SCROLL_MARKET_ITEMS.listData

	local itemListScroll = marketWindow:recursiveGetChildById("itemListScroll")
	itemListScroll:setValue(0)
	itemListScroll:setMinimum(cache.SCROLL_MARKET_ITEMS.listMin)
	itemListScroll:setMaximum(#cache.SCROLL_MARKET_ITEMS.listPool < 8 and 0 or math.max(0, cache.SCROLL_MARKET_ITEMS.listMax - #cache.SCROLL_MARKET_ITEMS.listPool) + 2)
	itemListScroll.onValueChange = function(self, value, delta) onItemListValueChange(self, value, delta) end

	itemList:setVirtualOffset({x = 0, y = 0})

	if selected.categoryId == 10 then
		marketWindow.contentPanel.mainMarket.getPotionsButton:setVisible(true)
	end
end

function onUpdateChildItem(itemID, tier)
	for _, widget in pairs(marketWindow.contentPanel.itemList:getChildren()) do
		if widget.item:getItem():getId() == itemID and widget.item:getItem():getTier() == tier then
			local count = itemID == 22118 and getTransferableTibiaCoins() or getDepotItemCount(itemID, tier)

			if lastSelectedCategory then
				local itemInfo = marketItems[lastSelectedCategory.categoryId][widget.item.itemIndex]
				widget.item:setTooltip(tr("%s%s%s%s", comma_value(count), "x", (count > 65000 and "+ " or " "), itemInfo.marketData.name))
			end

			widget.item:getItem():setCount(count == 0 and 0 or count)
			widget.grayHover:setOpacity(count == 0 and '0.5' or '0.0')
			break
		end
	end

	local firstChild = mainMarket.sellOffersList:getChildren()[1]
	if firstChild then
		mainMarket.sellOffersList:onChildFocusChange(firstChild, nil, KeyboardFocusReason)
	end

	firstChild = mainMarket.buyOffersList:getChildren()[1]
	if firstChild then
		mainMarket.buyOffersList:onChildFocusChange(firstChild, nil, KeyboardFocusReason)
	end
end

function onSelectChildItem(widget, selected, oldFocus)
	if not selected then return end

	if oldFocus then
		oldFocus:setBackgroundColor('#404040')
	end

	if lastSelectedItem.lastWidget then
		lastSelectedItem.lastWidget:setBackgroundColor('#404040')
	end

	selected:setBackgroundColor('#585858')
	local itemID = selected.item:getItemId()
	local itemTier = selected.item:getItem():getTier()
	if lastSelectedItem.itemId == itemID and lastSelectedItem.tier == itemTier then
		return true
	end

	marketWindow.contentPanel.selectedItem:setItemId(itemID)
	marketWindow.contentPanel.selectedItem:getItem():setTier(itemTier)

	lastSelectedItem = {itemId = itemID, tier = itemTier, lastWidget = widget}

	if itemID == 22118 then
		marketWindow.contentPanel.selectedItem:getItem():setCount(getTransferableTibiaCoins())
	else
		marketWindow.contentPanel.selectedItem:getItem():setCount(getDepotItemCount(itemID, itemTier))
	end
	onClearMainMarket(false)
	
	-- Clear the offer accumulators before requesting new data from server
	marketOffersBuy = {}
	marketOffersSell = {}
	
	sendMarketAction(3, itemID, selected.item:getItem():getTier())
end

function onClearMainMarket(cleanList)
	buyOffers = {}
	sellOffers = {}
	MarketOwnOffers.mySellOffers = {}
	MarketOwnOffers.myBuyOffers = {}
	
	-- Don't clear the accumulators here - let onMarketBrowse handle that
	-- when it receives the new data from the server
	
	lastItemID = 0
	lastItemTier = 0
	mainMarket.sellAcceptButton:setEnabled(false)
	mainMarket.buyAcceptButton:setEnabled(false)
	mainMarket.sellOffersList:destroyChildren()
	mainMarket.buyOffersList:destroyChildren()
	mainMarket.amountSellScrollBar:setRange(0, 0)
	mainMarket.amountBuyScrollBar:setRange(0, 0)
	mainMarket.piecePriceCreate:clearText()

	marketWindow.contentPanel.detailsMarket.detailsList:destroyChildren()
	marketWindow.contentPanel.detailsMarket.statisticsList:destroyChildren()

	if cleanList then
		updateSellCount(nil, 0)
		updateBuyCount(nil, 0)
		marketWindow.contentPanel.selectedItem:setItemId(0)
		marketWindow.contentPanel.itemList:destroyChildren()
	end

	cache.SCROLL_BUY_OFFERS.listMin = 0
	cache.SCROLL_BUY_OFFERS.listMax = 0
	cache.SCROLL_BUY_OFFERS.listFit = 0
	cache.SCROLL_BUY_OFFERS.listMin = 0
	cache.SCROLL_BUY_OFFERS.listPool = {}
	cache.SCROLL_BUY_OFFERS.listData = {}
	cache.SCROLL_BUY_OFFERS.lastSelected = 0

	cache.SCROLL_SELL_OFFERS.listMin = 0
	cache.SCROLL_SELL_OFFERS.listMax = 0
	cache.SCROLL_SELL_OFFERS.listFit = 0
	cache.SCROLL_SELL_OFFERS.listMin = 0
	cache.SCROLL_SELL_OFFERS.listPool = {}
	cache.SCROLL_SELL_OFFERS.listData = {}
	cache.SCROLL_SELL_OFFERS.lastSelected = 0

	local buyListScroll = marketWindow:recursiveGetChildById("buyOffersListScroll")
	buyListScroll.onValueChange = nil
	buyListScroll:setValue(0)
	buyListScroll:setMinimum(0)
	buyListScroll:setMaximum(0)

	local sellListScroll = marketWindow:recursiveGetChildById("sellOffersListScroll")
	sellListScroll.onValueChange = nil
	sellListScroll:setValue(0)
	sellListScroll:setMinimum(0)
	sellListScroll:setMaximum(0)

	mainMarket.totalValue:setText(0)
	mainMarket.totalSellValue:setText(0)

  mainMarket.grossAmount:setText(0)
  mainMarket.grossAmount.value = 0
end

function toggleShowLockerOnly(widget, checked)
	showLockerOnly = checked
	if not lastSelectedCategory then
		if #marketWindow.contentPanel.searchText:getText() > 0 then
			onSearchItem(marketWindow.contentPanel.searchText)
		end
		return true
	end

	onSelectChildCategory(nil, lastSelectedCategory, true)
end

function onSelectSellOffer(widget, selected, oldFocus)
	if not selected then return end

	local money = getTotalMoney()
	if oldFocus then
		local offer = sellOffers[cache.SCROLL_SELL_OFFERS.lastSelected]
		local offerPrice = offer and offer.price or 0
		local color = money >= offerPrice and "#c0c0c0" or "#808080"
		oldFocus:setBackgroundColor(oldFocus:getId())
		oldFocus.piecePrice:setColor(color)
		oldFocus.totalPrice:setColor(color)
		oldFocus.name:setColor(color)
		oldFocus.amount:setColor(color)
		oldFocus.endAt:setColor(color)
	end

	selected:setBackgroundColor('#585858')
	selected.piecePrice:setColor("#f4f4f4")
	selected.totalPrice:setColor("#f4f4f4")
	selected.name:setColor("#f4f4f4")
	selected.amount:setColor("#f4f4f4")
	selected.endAt:setColor("#f4f4f4")
	cache.SCROLL_SELL_OFFERS.lastSelected = selected.offerId

	local currentOffer = sellOffers[cache.SCROLL_SELL_OFFERS.lastSelected]
	if money < currentOffer.price then
		mainMarket.sellAcceptButton:setEnabled(false)
		updateSellCount(nil, 0)
		mainMarket.amountSellScrollBar:setRange(0, 0)
		return
	end

	local maxValue = math.min(currentOffer.amount, math.floor(money / currentOffer.price))
	mainMarket.amountSellScrollBar:setValue(1)
	mainMarket.amountSellScrollBar:setRange(1, maxValue)
	mainMarket.amountSellScrollBar:setIncrementStep(1)
	mainMarket.totalValue:setText(comma_value(currentOffer.price))
	mainMarket.sellAcceptButton:setEnabled(true)

	local startValue = 1
	if not table.empty(lastSelectedItem) and lastSelectedItem.itemId == 22118 then
		local sellCount = math.floor(money / (currentOffer.price * 25))
		if sellCount > 0 then
			mainMarket.amountSellScrollBar:setRange(25, math.min(currentOffer.amount, sellCount * 25))
			mainMarket.amountSellScrollBar:setValue(25)
			mainMarket.sellAcceptButton:setEnabled(true)
			mainMarket.amountSellScrollBar:setStep(25)
			mainMarket.amountSellScrollBar:setIncrementStep(25)
			startValue = 25
		else
			mainMarket.amountSellScrollBar:setRange(0, 0)
			mainMarket.amountSellScrollBar:setValue(0)
			mainMarket.sellAcceptButton:setEnabled(false)
			startValue = 0
		end
	end

  	updateSellCount(nil, startValue)
	local sellListScroll = marketWindow:recursiveGetChildById("sellOffersListScroll")
	if cache.SCROLL_SELL_OFFERS.listFit > 11 then
		onSellListValueChange(sellListScroll, sellListScroll:getValue(), 0)
	end
end

function onSelectBuyOffer(widget, selected, oldFocus)
	if not selected or table.empty(lastSelectedItem) then return end

	local count = getDepotItemCount(lastItemID, lastItemTier)
	if oldFocus then
		local color = count > 0 and "#c0c0c0" or "#808080"
		oldFocus:setBackgroundColor(oldFocus:getId())
		oldFocus.piecePrice:setColor(color)
		oldFocus.totalPrice:setColor(color)
		oldFocus.name:setColor(color)
		oldFocus.amount:setColor(color)
		oldFocus.endAt:setColor(color)
	end

	selected:setBackgroundColor('#585858')
	selected.piecePrice:setColor("#f4f4f4")
	selected.totalPrice:setColor("#f4f4f4")
	selected.name:setColor("#f4f4f4")
	selected.amount:setColor("#f4f4f4")
	selected.endAt:setColor("#f4f4f4")
	cache.SCROLL_BUY_OFFERS.lastSelected = selected.offerId

	if count == 0 then
		mainMarket.buyAcceptButton:setEnabled(false)
		mainMarket.amountBuyScrollBar:setRange(0, 0)
		updateBuyCount(nil, 0)
		return
	end

	local currentOffer = buyOffers[cache.SCROLL_BUY_OFFERS.lastSelected]
	mainMarket.amountBuyScrollBar:setValue(lastSelectedItem.itemId == 22118 and 25 or 1)
	mainMarket.amountBuyScrollBar:setRange(1, math.min(count, currentOffer.amount))
	mainMarket.amountBuyScrollBar:setIncrementStep(1)
	mainMarket.totalSellValue:setText(comma_value(currentOffer.price))
	mainMarket.buyAcceptButton:setEnabled(true)

	local steps = getCoinStepValue(lastSelectedItem.itemId)
	mainMarket.amountBuyScrollBar:setStep(steps)

	if lastSelectedItem.itemId == 22118 then
		local startValue = 0
		local coinBalance = getTransferableTibiaCoins()
		local buyCount = math.floor(coinBalance / 25)
		if buyCount > 0 then
			mainMarket.amountBuyScrollBar:setRange(25, math.min(currentOffer.amount, buyCount * 25))
			mainMarket.amountBuyScrollBar:setValue(25)
			mainMarket.buyAcceptButton:setEnabled(true)
			mainMarket.amountBuyScrollBar:setStep(25)
			mainMarket.amountBuyScrollBar:setIncrementStep(25)
			startValue = 25
		else
			mainMarket.amountBuyScrollBar:setRange(0, 0)
			mainMarket.amountBuyScrollBar:setValue(0)
			mainMarket.buyAcceptButton:setEnabled(false)
		end

		updateBuyCount(nil, startValue)
	end

	local buyListScroll = marketWindow:recursiveGetChildById("buyOffersListScroll")
	if cache.SCROLL_BUY_OFFERS.listFit > 11 then
		onBuyListValueChange(buyListScroll, buyListScroll:getValue(), 0)
	end
end

function updateSellCount(widget, value)
	if table.empty(lastSelectedItem) then
		return
	end

	if widget and widget:getIncrementValue() > 1 then
		value = math.cround(value, widget:getIncrementValue())
	end

	if cache.SCROLL_SELL_OFFERS.lastSelected == 0 then
		mainMarket.amountSell:setText(value)
		mainMarket.totalValue:setText(value)
		return
	end

	local steps = getCoinStepValue(lastSelectedItem.itemId)
	mainMarket.amountSellScrollBar:setStep(steps)

	local currentOffer = sellOffers[cache.SCROLL_SELL_OFFERS.lastSelected]
	if currentOffer then
		mainMarket.amountSell:setText(value)
		mainMarket.totalValue:setText(comma_value(currentOffer.price * value))
	end
end

function updateBuyCount(widget, value)
	if widget and widget:getIncrementValue() > 1 then
		value = math.cround(value, widget:getIncrementValue())
	end

	if cache.SCROLL_BUY_OFFERS.lastSelected == 0 then
		mainMarket.amountBuy:setText(value)
		mainMarket.totalSellValue:setText(convertGold(value))
		return
	end

	local currentOffer = buyOffers[cache.SCROLL_BUY_OFFERS.lastSelected]
	if currentOffer then
		mainMarket.amountBuy:setText(value)
		mainMarket.totalSellValue:setText(convertGold(currentOffer.price * value))
	end
end

function onAcceptSellOffer()
	if cache.SCROLL_SELL_OFFERS.lastSelected == 0 then
		return
	end

	local currentOffer = sellOffers[cache.SCROLL_SELL_OFFERS.lastSelected]
	if not currentOffer then
		return
	end

  local amount = tonumber(mainMarket.amountSell:getText())

	sendMarketAcceptOffer(currentOffer.timestamp, currentOffer.counter, amount)
end

function onAcceptBuyOffer()
	if cache.SCROLL_BUY_OFFERS.lastSelected == 0 then
		return
	end

	local currentOffer = buyOffers[cache.SCROLL_BUY_OFFERS.lastSelected]
	if not currentOffer then
		return
	end

  local amount = tonumber(mainMarket.amountBuy:getText())

	sendMarketAcceptOffer(currentOffer.timestamp, currentOffer.counter, amount)
end

function updateCreateCount(widget, value)
	if widget and widget:getIncrementValue() > 1 then
		value = math.cround(value, widget:getIncrementValue())
	end

	mainMarket.createOfferAmount:setText("Amount: " .. value)
	onPiecePriceEdit(mainMarket.piecePriceCreate)
end

function onPiecePriceEdit(widget)
	if table.empty(lastSelectedItem) then
		return
	end

	if #widget:getText() == 0 then
		mainMarket.grossAmount.value = 0
		mainMarket.profitAmount:setText(0)
		mainMarket.feeAmount:setText(0)
		mainMarket.createButton:setEnabled(false)
		mainMarket.amountCreateScrollBar:setIncrementStep(25)
		mainMarket.amountCreateScrollBar:setRange(0, 0)
		return
	end

	local currentText = widget:getText():gsub("[^%d]", "")
	widget:setText(currentText)

	if #currentText > 12 then
		currentText = currentText:sub(1, -2)
		widget:setText(currentText)
	end

	local isTibiaCoin = lastSelectedItem.itemId == 22118
	local numericValue = tonumber(currentText)
	if not numericValue then
		return true
	end

	if numericValue >= 999999999999 then
		currentText = "999999999999"
		widget:setText(currentText)
	end

	local amount = mainMarket.amountCreateScrollBar:getValue()
	if mainMarket.amountCreateScrollBar:getIncrementValue() > 1 then
		amount = math.cround(amount, mainMarket.amountCreateScrollBar:getIncrementValue())
	end

	local fee = math.ceil((numericValue / 50) * amount)
	if fee < 20 then
		fee = 20
	elseif fee > 1000000 then
		fee = 1000000
	end

	local thing = g_things.getThingType(lastSelectedItem.itemId)
	local stackable = thing:isStackable()
	local maxCount = stackable and 64000 or 2000

	local maxValue = 999999999999
	if not isTibiaCoin and numericValue * amount >= maxValue then
		local newAmount = math.floor(maxValue / numericValue)
		amount = newAmount
		maxCount = newAmount
		mainMarket.amountCreateScrollBar:setValue(amount)
	end

	local steps = getCoinStepValue(lastSelectedItem.itemId)
	mainMarket.amountCreateScrollBar:setIncrementStep(1)
	if isTibiaCoin then
		steps = 25
		mainMarket.amountCreateScrollBar:setIncrementStep(25)
	end

	mainMarket.amountCreateScrollBar:setStep(steps)

	if currentActionType == 0 then
		local grossProfit = numericValue * amount
		mainMarket.grossAmount:setText(convertGold(grossProfit, true))
		mainMarket.grossAmount.value = numericValue
		mainMarket.profitAmount:setText(convertGold(grossProfit + fee, true))
		mainMarket.createButton:setEnabled(true)
		mainMarket.feeAmount:setText(convertGold(fee))

		local balance = getTotalMoney()
		local barCount = 0
		if isTibiaCoin then
			barCount = math.floor(balance / (numericValue * 25))
			if mainMarket.amountCreateScrollBar:getValue() <= 1 then
				mainMarket.amountCreateScrollBar:setValue(25)
				mainMarket.amountCreateScrollBar:setStep(25)
				mainMarket.amountCreateScrollBar:setIncrementStep(25)
			end

			if barCount > 0 then
				mainMarket.amountCreateScrollBar:setRange(25, barCount * 25)
			else
				mainMarket.amountCreateScrollBar:setRange(0, 0)
			end
		else
			if getTotalMoney() >= numericValue then
				barCount = math.min(maxCount, getTotalMoney() / numericValue)
			end
			if barCount > 0 then
				mainMarket.amountCreateScrollBar:setRange(1, barCount)
			else
				mainMarket.amountCreateScrollBar:setRange(0, 0)
			end
		end
	else
		local itemCount = isTibiaCoin and getTransferableTibiaCoins() or getDepotItemCount(lastSelectedItem.itemId, lastSelectedItem.tier)
		if itemCount > 0 then
			if isTibiaCoin and itemCount < 25 then
				mainMarket.amountCreateScrollBar:setValue(0)
				mainMarket.amountCreateScrollBar:setStep(25)
				mainMarket.amountCreateScrollBar:setIncrementStep(25)
			else
				mainMarket.amountCreateScrollBar:setRange((isTibiaCoin and 25 or 1), math.min(maxCount, itemCount))
				mainMarket.createButton:setEnabled(true)
			end
		else
			mainMarket.amountCreateScrollBar:setRange(0, 0)
		end

		local grossProfit = numericValue * amount
		mainMarket.grossAmount:setText(convertGold(grossProfit, true))
		mainMarket.grossAmount.value = numericValue
		mainMarket.profitAmount:setText(convertGold(grossProfit - fee, true))
		mainMarket.feeAmount:setText(convertGold(fee))
	end
end

function changeOfferType(widget, primary)
	if widget:isChecked() then
		return
	end

	if primary then
		widget:setChecked(true)
		mainMarket.createOfferBuy:setChecked(false)
		currentActionType = 1
		mainMarket.grossProfit:setText("Gross Profit:")
		mainMarket.profitLabel:setText("Total Profit:")
	else
		widget:setChecked(true)
		mainMarket.createOfferSell:setChecked(false)
		currentActionType = 0
		mainMarket.grossProfit:setText("Price:")
		mainMarket.profitLabel:setText("Total Price:")
	end

	mainMarket.piecePriceCreate:clearText()
end

function createMarketOffer()
	if table.empty(lastSelectedItem) then
		return
	end

	local n = mainMarket.createOfferAmount:getText()
	local amount = n:gsub("%D", "")
	local price = tonumber(mainMarket.grossAmount.value)
	if currentActionType == 0 and getTotalMoney() < price then
		return
	end
	mainMarket.amountCreateScrollBar:setRange(0, 0)
	mainMarket.createButton:setEnabled(false)
	mainMarket.amountCreateScrollBar:setValue(0)
	mainMarket.amountCreateScrollBar:setIncrementStep(1)
	mainMarket.grossAmount:setText("0")
	mainMarket.grossAmount.value = 0
	mainMarket.profitAmount:setText("0")
	mainMarket.feeAmount:setText("0")
	mainMarket.piecePriceCreate:clearText()

	lastItemID = 0
	lastItemTier = 0

	sendMarketCreateOffer(currentActionType, lastSelectedItem.itemId, lastSelectedItem.tier, amount, price, mainMarket.anonymous:isChecked())
	
	-- Refresh the offers list for the current item after a short delay to allow server to process
	scheduleEvent(function()
		if not table.empty(lastSelectedItem) then
			-- Clear accumulators before requesting fresh data
			marketOffersBuy = {}
			marketOffersSell = {}
			sendMarketAction(3, lastSelectedItem.itemId, lastSelectedItem.tier)
		end
	end, 500)
end

function onSearchItem(textField)
	if isSearching then
		return
	end
	isSearching = true
	
	lastSelectedItem = {}
	if #textField:getText() == 0 then
		onClearSearch()
		isSearching = false
		return
	end

	if lastSelectedCategory then
		local colourCount = 0
		for i, pair in ipairs(categoryList) do
			local colour = colourCount % 2 == 0 and '#414141' or '#484848'
			if pair[2] == lastSelectedCategory:getText() then
				lastSelectedCategory:setBackgroundColor(colour)
				lastSelectedCategory:setColor('#c0c0c0')
			end
			colourCount = colourCount + 1
		end
		lastSelectedCategory = nil
	end

	local itemList = marketWindow:recursiveGetChildById("itemList")
	if not itemList then
		isSearching = false
		return true
	end

	itemList:setVirtualOffset({x = 0, y = 0})

	cache.SCROLL_MARKET_ITEMS.listFit = math.floor(itemList:getHeight() / 36) + 1
	cache.SCROLL_MARKET_ITEMS.listMin = 0
	cache.SCROLL_MARKET_ITEMS.listPool = {}
	cache.SCROLL_MARKET_ITEMS.listData = {}

	marketWindow.contentPanel.itemList:destroyChildren()

	onClearMainMarket(true)

	marketWindow.contentPanel.mainMarket.getPotionsButton:setVisible(false)
	marketWindow.contentPanel.selectedItem:setItemId(0)

	itemList.onChildFocusChange = function(self, selected, oldFocus) onSelectChildItem(self, selected, oldFocus) end

	if sortButtons["classFilter"] == -1 then
		marketWindow.contentPanel.classFilter:clearOptions()
		marketWindow.contentPanel.classFilter:addOption("All", nil, true)
		marketWindow.contentPanel.classFilter:addOption("None", nil, true)
		for i = 1, 4 do
			marketWindow.contentPanel.classFilter:addOption("Class " .. i, nil, true)
		end
	end

	if sortButtons["tierFilter"] == 0 then
		marketWindow.contentPanel.tierFilter:clearOptions()
		for i = 0, 10 do
			marketWindow.contentPanel.tierFilter:addOption("Tier " .. i, nil, true)
		end
	end

	local tier = sortButtons["tierFilter"] or 0
	for c = MarketCategory.First, MarketCategory.Last do
		local marketItem = marketItems[c]
		if marketItem then
			for _, data in pairs(marketItem) do
				if not checkSortMarketOptions(data) or (showLockerOnly and getDepotItemCount(data.thingType:getId(), tier) == 0)then
					goto continue
				end

				if matchText(data.marketData.name, textField:getText()) then
					table.insert(cache.SCROLL_MARKET_ITEMS.listData, data)
				end

				::continue::
			end
		else
			perror("MarketData ".. c .. " is nil")
		end
	end

	for i, itemInfo in ipairs(cache.SCROLL_MARKET_ITEMS.listData) do
		if #cache.SCROLL_MARKET_ITEMS.listPool >= cache.SCROLL_MARKET_ITEMS.listFit then
			break
		end

		local count = getDepotItemCount(itemInfo.thingType:getId(), tier)
		if not checkSortMarketOptions(itemInfo) or (count == 0 and showLockerOnly) then
			goto continue
		end

		local widget = g_ui.createWidget('MarketItemList', itemList)

		widget.item:setItemId(itemInfo.thingType:getId())

		widget.name:setText(itemInfo.marketData.name)
		if widget.name:getText():len() > 15 then
			widget.name:setText(short_text(itemInfo.marketData.name, 15))
			widget.name:setTooltip(itemInfo.marketData.name)
		end

		widget:setBackgroundColor('#404040')
		widget.item:getItem():setCount(count)
		widget.item.itemIndex = i  -- Store item index as property
		widget.item:setTooltip(tr("%s%s%s%s", comma_value(count), "x", (count > 65000 and "+ " or " "), itemInfo.marketData.name))

		if tier ~= 0 then
			widget.item:getItem():setTier(tier)
		end

		if widget.name:getText():len() <= 15 then
			widget.name:setMarginTop(1)
		end

		if count > 0 then
			widget.grayHover:setOpacity('0.0')
		end

		table.insert(cache.SCROLL_MARKET_ITEMS.listPool, widget)

		:: continue ::
	end

	cache.SCROLL_MARKET_ITEMS.listMax = #cache.SCROLL_MARKET_ITEMS.listData

	local sellScrollbar = marketWindow:recursiveGetChildById("itemListScroll")
	sellScrollbar:setValue(0)
	sellScrollbar:setMinimum(cache.SCROLL_MARKET_ITEMS.listMin)
	sellScrollbar:setMaximum(#cache.SCROLL_MARKET_ITEMS.listPool < 8 and 0 or math.max(0, cache.SCROLL_MARKET_ITEMS.listMax - #cache.SCROLL_MARKET_ITEMS.listPool) + 2)

	sellScrollbar.onValueChange = function(self, value, delta) onItemListValueChange(self, value, delta) end
	itemList:setVirtualOffset({x = 0, y = 0})
	
	isSearching = false
end

function onShowRedirect(item)
	lastSelectedItem = {}

	if lastSelectedCategory then
		local colourCount = 0
		for i, pair in ipairs(categoryList) do
			local colour = colourCount % 2 == 0 and '#414141' or '#484848'
			if pair[2] == lastSelectedCategory:getText() then
				lastSelectedCategory:setBackgroundColor(colour)
				lastSelectedCategory:setColor('#c0c0c0')
			end
			colourCount = colourCount + 1
		end
		lastSelectedCategory = nil
	end

	local itemList = marketWindow:recursiveGetChildById("itemList")
	if not itemList then
		return true
	end

	itemList:setVirtualOffset({x = 0, y = 0})

	cache.SCROLL_MARKET_ITEMS.listFit = math.floor(itemList:getHeight() / 36) + 1
	cache.SCROLL_MARKET_ITEMS.listMin = 0
	cache.SCROLL_MARKET_ITEMS.listPool = {}
	cache.SCROLL_MARKET_ITEMS.listData = {}

	marketWindow.contentPanel.itemList:destroyChildren()

	onClearMainMarket(true)

	marketWindow.contentPanel.mainMarket.getPotionsButton:setVisible(false)
	marketWindow.contentPanel.selectedItem:setItemId(0)

	itemList.onChildFocusChange = function(self, selected, oldFocus) onSelectChildItem(self, selected, oldFocus) end

	if sortButtons["classFilter"] == -1 then
		marketWindow.contentPanel.classFilter:clearOptions()
		marketWindow.contentPanel.classFilter:addOption("All", nil, true)
		marketWindow.contentPanel.classFilter:addOption("None", nil, true)
		for i = 1, 4 do
			marketWindow.contentPanel.classFilter:addOption("Class " .. i, nil, true)
		end
	end

	if sortButtons["tierFilter"] == 0 then
		marketWindow.contentPanel.tierFilter:clearOptions()
	end

	for c = MarketCategory.First, MarketCategory.Last do
		local marketItem = marketItems[c]
		if marketItem then
			for _, data in pairs(marketItem) do
				if item:getId() == data.thingType:getId() then
					local tierCount = item:getClassification()
					if tierCount == 4 then
						tierCount = 10
					end

					-- Duplicate items for tiers
					for i = 0, tierCount do
						local tableCopy = table.copy(data)
						tableCopy.tier = i
						table.insert(cache.SCROLL_MARKET_ITEMS.listData, tableCopy)
					end

					break
				end
			end
		end
	end

	for i, itemInfo in pairs(cache.SCROLL_MARKET_ITEMS.listData) do
		if #cache.SCROLL_MARKET_ITEMS.listPool >= cache.SCROLL_MARKET_ITEMS.listFit then
			break
		end

		local count = getDepotItemCount(itemInfo.thingType:getId(), tier)
		if not checkSortMarketOptions(itemInfo) or (count == 0 and showLockerOnly) then
			goto continue
		end

		local widget = g_ui.createWidget('MarketItemList', itemList)

		widget.item:setItemId(itemInfo.thingType:getId())

		widget.name:setText(itemInfo.marketData.name)
		if widget.name:getText():len() > 15 then
			widget.name:setText(short_text(itemInfo.marketData.name, 15))
			widget.name:setTooltip(itemInfo.marketData.name)
		end

		widget:setBackgroundColor('#404040')
		widget.item:getItem():setCount(count)
		widget.item.itemIndex = i  -- Store item index as property
		widget.item:setTooltip(tr("%s%s%s%s", comma_value(count), "x", (count > 65000 and "+ " or " "), itemInfo.marketData.name))

		-- Tier as index
		widget.item:getItem():setTier(itemInfo.tier)

		if widget.name:getText():len() <= 15 then
			widget.name:setMarginTop(1)
		end

		if count > 0 then
			widget.grayHover:setOpacity('0.0')
		end

		table.insert(cache.SCROLL_MARKET_ITEMS.listPool, widget)

		:: continue ::
	end

	cache.SCROLL_MARKET_ITEMS.listMax = #cache.SCROLL_MARKET_ITEMS.listData

	local sellScrollbar = marketWindow:recursiveGetChildById("itemListScroll")
	sellScrollbar:setValue(0)
	sellScrollbar:setMinimum(cache.SCROLL_MARKET_ITEMS.listMin)
	sellScrollbar:setMaximum(#cache.SCROLL_MARKET_ITEMS.listPool < 8 and 0 or math.max(0, cache.SCROLL_MARKET_ITEMS.listMax - #cache.SCROLL_MARKET_ITEMS.listPool) + 2)

	sellScrollbar.onValueChange = function(self, value, delta) onItemListValueChange(self, value, delta) end
	itemList:setVirtualOffset({x = 0, y = 0})

	itemList:focusChild(itemList:getFirstChild())
end

-- Clear one/two handed filter
function onClearHandFilter()
	marketWindow.contentPanel.oneButton:setEnabled(false)
	marketWindow.contentPanel.oneButton:setChecked(false)
	marketWindow.contentPanel.twoButton:setEnabled(false)
	marketWindow.contentPanel.twoButton:setChecked(false)
	sortButtons["oneButton"] = false
	sortButtons["twoButton"] = false
end

function onClearSearch(clearHands)
	marketWindow.contentPanel.searchText:clearText(true)
	onClearMainMarket(true)
	if clearHands then
		onClearHandFilter()
	end
	marketWindow.contentPanel.itemList:updateScrollBars()
end

function checkSortMarketOptions(itemData)
	local player = g_game.getLocalPlayer()
	if not player then
		return false
	end

	local playerLevel = player:getLevel()
	local playerVocation = translateWheelVocation(player:getVocation())

	if sortButtons["levelButton"] then
		if itemData.marketData.requiredLevel > playerLevel then
			return false
		end
	end

	if sortButtons["vocButton"] then
		local itemVocation = itemData.marketData.restrictVocation
		if #itemVocation > 0 and not table.contains(itemVocation, playerVocation) then
			return false
		end
	end

	if sortButtons["oneButton"] then
		if itemData.thingType:getClothSlot() ~= 6 then
			return false
		end
	end

	if sortButtons["twoButton"] then
		if itemData.thingType:getClothSlot() ~= 0 then
			return false
		end
	end

	if sortButtons["classFilter"] ~= -1 then
		if itemData.thingType:getClassification() ~= sortButtons["classFilter"] then
			return false
		end
	end

	if sortButtons["tierFilter"] > 0 and itemData.thingType:getClassification() == 0 then
		return false
	end

	return true
end

function onSortMarketFields(widget, checked)
	if table.contains({'oneButton', 'twoButton'}, widget:getId()) then
		widget:setChecked(not checked)
		sortButtons[widget:getId()] = not checked
		if widget:getId() == 'oneButton' then
			sortButtons["twoButton"] = false
			marketWindow.contentPanel.twoButton:setChecked(false)
		elseif widget:getId() == 'twoButton' then
			marketWindow.contentPanel.oneButton:setChecked(false)
			sortButtons["oneButton"] = false
		end
	elseif table.contains({'classFilter', 'tierFilter'}, widget:getId()) then
		if checked > 1 and widget:getId() == "classFilter" then
			sortButtons["classFilter"] = (checked - 2)
		elseif widget:getId() == "tierFilter" then
			sortButtons["tierFilter"] = checked - 1
		end
	elseif table.contains({'levelButton', 'vocButton'}, widget:getId()) then
		widget:setChecked(not checked)
		sortButtons[widget:getId()] = not checked
	end

	if not lastSelectedCategory then
		if #marketWindow.contentPanel.searchText:getText() > 0 then
			onSearchItem(marketWindow.contentPanel.searchText)
		end
		return true
	end

	lastSelectedItem = {}
	onClearMainMarket(true)
	onSelectChildCategory(nil, lastSelectedCategory, true)
end

function onMarketDetail(itemID, tier, details, purchase, sale)
	marketWindow.contentPanel.detailsMarket.detailsList:destroyChildren()
	for i, str in pairs(details) do
		if #str == 0 then
			goto continue
		end

		local widget = g_ui.createWidget('DatailsLabel', marketWindow.contentPanel.detailsMarket.detailsList)
		widget:setText(MarketDetailNames[i + 1] .. str)
		:: continue ::
	end

	marketWindow.contentPanel.detailsMarket.statisticsList:destroyChildren()
	local purchaseWidget = g_ui.createWidget('StatisticWidget', marketWindow.contentPanel.detailsMarket.statisticsList)
	purchaseWidget.header:setText("Buy Offers:")
	if #purchase > 0 then
		local transactionsText = purchaseWidget.transactions:getText():gsub("0", purchase[1].numTransactions)
		purchaseWidget.transactions:setText(transactionsText)

		local highestText = purchaseWidget.highestPrice:getText():gsub("0", comma_value(purchase[1].highestPrice))
		purchaseWidget.highestPrice:setText(highestText)

		local avgText = purchaseWidget.avgPrice:getText():gsub("0", comma_value(math.floor(purchase[1].totalPrice / purchase[1].numTransactions)))
		purchaseWidget.avgPrice:setText(avgText)

		local lowText = purchaseWidget.lowPrice:getText():gsub("0", comma_value(purchase[1].lowestPrice))
		purchaseWidget.lowPrice:setText(lowText)
	end

	local saleWidget = g_ui.createWidget('StatisticWidget', marketWindow.contentPanel.detailsMarket.statisticsList)
	saleWidget.header:setText("Sell Offers:")
	if #sale > 0 then
		local transactionsText = saleWidget.transactions:getText():gsub("0", sale[1].numTransactions)
		saleWidget.transactions:setText(transactionsText)

		local highestText = saleWidget.highestPrice:getText():gsub("0", comma_value(sale[1].highestPrice))
		saleWidget.highestPrice:setText(highestText)

		local avgText = saleWidget.avgPrice:getText():gsub("0", comma_value(math.floor(sale[1].totalPrice / sale[1].numTransactions)))
		saleWidget.avgPrice:setText(avgText)

		local lowText = saleWidget.lowPrice:getText():gsub("0", comma_value(sale[1].lowestPrice))
		saleWidget.lowPrice:setText(lowText)
	end
end

function getItemNameById(itemId)
  for c = MarketCategory.First, MarketCategoryWeaponsAll do
		local marketItem = marketItems[c]
		if marketItem then
			for _, data in pairs(marketItem) do
				if data.thingType:getId() == itemId then
					return data.marketData.name
				end
			end
		end
	end
  return ''
end

function onRedirect(item)
  sendMarketAction(3, item:getId(), 0)

  scheduleEvent(function()
	onShowRedirect(item)
  end, 100)
end

function focusPrevItemWidget(list)
	if cache.SCROLL_MARKET_ITEMS.scrollDelay >= g_clock.millis() then
		return
	end

	local c = list:getFocusedChild()
	if not c then return end
	local cIndex = list:getChildIndex(c)
	local scrollbar = marketWindow:recursiveGetChildById('itemListScroll')
	if scrollbar:getMaximum() > 0 and cIndex == 1 and scrollbar:getValue() == scrollbar:getMinimum() then
		return
	end

	if cIndex > 1 then
		if cIndex < 3 then
			list:setVirtualOffset({x = 0, y = 0})
		end
	  	list:focusPreviousChild(KeyboardFocusReason)
	else
	  scrollbar:setValue(scrollbar:getValue() - 1)
	  if cIndex == 1 then
		local a = list:getFocusedChild()
		local nextChild = list:getChildByIndex(cIndex + 1)
		if nextChild then
			list:focusChild(nextChild)
		end
		list:focusChild(a)
		list:setVirtualOffset({x = 0, y = 0})
	  end
	end

	cache.SCROLL_MARKET_ITEMS.scrollDelay = g_clock.millis() + 30
end
  
function focusNextItemWidget(list)
	if cache.SCROLL_MARKET_ITEMS.scrollDelay >= g_clock.millis() then
		return
	end

	local c = list:getFocusedChild()
	local cIndex = list:getChildIndex(c)
	local cCount = list:getChildCount()
	local scrollbar = marketWindow:recursiveGetChildById('itemListScroll')
	if scrollbar:getMaximum() > 0 and cIndex == cCount and scrollbar:getValue() == scrollbar:getMaximum() then
		return
	end

	if cIndex < (cCount - 1) then
	  list:focusNextChild(KeyboardFocusReason)
	else
	  scrollbar:setValue(scrollbar:getValue() + 1)
	  if cIndex == (cCount - 1) then
		list:focusNextChild(KeyboardFocusReason)
		if scrollbar:getMaximum() > 0 then
			list:setVirtualOffset({x = 0, y = 28})
		end
	  elseif cIndex == cCount then
		if scrollbar:getMaximum() > 0 then
			list:setVirtualOffset({x = 0, y = 28})
		end

		local prevChild = list:getChildByIndex(cIndex - 1)
		if prevChild then
			list:focusChild(prevChild)
		end
		list:focusChild(c)
	  end
	end

	cache.SCROLL_MARKET_ITEMS.scrollDelay = g_clock.millis() + 30
end

function focusPrevSellLabel(list)
	local c = list:getFocusedChild()
	if not c then return end
	local cIndex = list:getChildIndex(c)

	local scrollbar = list:getParent():recursiveGetChildById('sellOffersListScroll')
	if cache.SCROLL_SELL_OFFERS.lastSelected - 1 > 0 then
		cache.SCROLL_SELL_OFFERS.lastSelected = cache.SCROLL_SELL_OFFERS.lastSelected - 1
	end

	if cIndex > 1 then
	  list:focusPreviousChild(KeyboardFocusReason)
	else
	  scrollbar:setValue(scrollbar:getValue() - 1)
	  list:focusChild(c)
	  if cIndex == 1 then
		list:focusPreviousChild(KeyboardFocusReason)
	  end
	end

	scrollbar:setValue(scrollbar:getValue())
end
  
function focusNextSellLabel(list)
	local scrollbar = list:getParent():recursiveGetChildById('sellOffersListScroll')

	local c = list:getFocusedChild()
	local cIndex = list:getChildIndex(c)
	local cCount = list:getChildCount()

	if cIndex < cCount then
	  list:focusNextChild(KeyboardFocusReason)
	else
	  scrollbar:setValue(scrollbar:getValue() + 1)
	  list:focusChild(c)
	  if cIndex == cCount then
		list:focusNextChild(KeyboardFocusReason)
	  end
	end

	if cache.SCROLL_SELL_OFFERS.lastSelected + 1 < #cache.SCROLL_SELL_OFFERS.listData then
		cache.SCROLL_SELL_OFFERS.lastSelected = cache.SCROLL_SELL_OFFERS.lastSelected + 1
	end
end

function focusPrevBuyLabel(list)
	local c = list:getFocusedChild()
	if not c then return end
	local cIndex = list:getChildIndex(c)
	local scrollbar = list:getParent():recursiveGetChildById('buyOffersListScroll')

	if cache.SCROLL_BUY_OFFERS.lastSelected - 1 > 0 then
		cache.SCROLL_BUY_OFFERS.lastSelected = cache.SCROLL_BUY_OFFERS.lastSelected - 1
	end

	if cIndex > 1 then
	  list:focusPreviousChild(KeyboardFocusReason)
	else
	  scrollbar:setValue(scrollbar:getValue() - 1)
	  list:focusChild(c)
	  if cIndex == 1 then
		list:focusPreviousChild(KeyboardFocusReason)
	  end
	end
end
  
function focusNextBuyLabel(list)
	local c = list:getFocusedChild()
	local cIndex = list:getChildIndex(c)
	local cCount = list:getChildCount()
	local scrollbar = list:getParent():recursiveGetChildById('buyOffersListScroll')

	if cIndex < cCount then
	  list:focusNextChild(KeyboardFocusReason)
	else
	  scrollbar:setValue(scrollbar:getValue() + 1)
	  list:focusChild(c)
	  if cIndex == cCount then
		list:focusNextChild(KeyboardFocusReason)
	  end
	end

	if cache.SCROLL_BUY_OFFERS.lastSelected + 1 < #cache.SCROLL_BUY_OFFERS.listData then
		cache.SCROLL_BUY_OFFERS.lastSelected = cache.SCROLL_BUY_OFFERS.lastSelected + 1
	end
end


function onOpenNpcTrade(items, currencyId, currencyName)
    local ui = controllerNpcTrader.ui
    if not ui or not ui:isVisible() then
        controllerNpcTrader:loadHtml('templates/game_npctrader.html')
    end
    controllerNpcTrader.isTradeOpen = true
    controllerNpcTrader.widthConsole = 600
    controllerNpcTrader.buyItems = {}
    controllerNpcTrader.sellItems = {}
    if items then
        for _, itemData in ipairs(items) do
            local ptr = itemData[1]
            local name = itemData[2]
            local weight = itemData[3] / 100
            local buyPrice = itemData[4]
            local sellPrice = itemData[5]
            if buyPrice > 0 then
                table.insert(controllerNpcTrader.buyItems, {
                    ptr = ptr,
                    name = name,
                    weight = weight,
                    price = buyPrice,
                    count = 1
                })
            end
            if sellPrice > 0 then
                table.insert(controllerNpcTrader.sellItems, {
                    ptr = ptr,
                    name = name,
                    weight = weight,
                    price = sellPrice,
                    count = 1
                })
            end
        end
    end
    controllerNpcTrader.currencyId = currencyId or 3031
    controllerNpcTrader.currencyName = currencyName or "Gold Coin"
    local currencyLabel = controllerNpcTrader:findWidget(".tradeCurrencyName")
    if currencyLabel then
        currencyLabel:setText(controllerNpcTrader.currencyName)
    end
    local currencyIcon = controllerNpcTrader:findWidget(".tradeCurrencyIcon")
    if currencyIcon then
        local item = Item.create(controllerNpcTrader.currencyId)
        if item then
            currencyIcon:setItem(item)
        else
            currencyIcon:setItemId(controllerNpcTrader.currencyId)
        end
    end

    -- Initial State
    controllerNpcTrader.tradeMode = BUY
    controllerNpcTrader.searchText = ""
    controllerNpcTrader.itemBatchSize = 30
    controllerNpcTrader.loadedItems = 0
    controllerNpcTrader.currentList = {}

    -- Settings & Sorting
    controllerNpcTrader.sortBy = 'name'
    controllerNpcTrader.ignoreCapacity = false
    controllerNpcTrader.buyWithBackpack = false
    controllerNpcTrader.ignoreEquipped = true

    controllerNpcTrader:setTradeMode(BUY)
end

function controllerNpcTrader:setTradeMode(mode)
    self.tradeMode = mode
    self.selectedItem = nil

    local buyTab = self:findWidget("#tabBuy")
    local sellTab = self:findWidget("#tabSell")

    if buyTab then
        buyTab:setEnabled(mode ~= BUY)
    end
    if sellTab then
        sellTab:setEnabled(mode ~= SELL)
    end

    self:findWidget(".tradeBuyButton"):setText(mode == BUY and "Buy" or "Sell")

    self.shouldFocusFirst = true
    self:updateListSource()
    self:refreshPlayerGoods()
end

function controllerNpcTrader:updateListSource()
    if self.tradeMode == BUY then
        self.allTradeItems = self.buyItems
    else
        self.allTradeItems = self.sellItems
    end
    self:filterTradeList(self.searchText or "")
end

function controllerNpcTrader:loadNextBatch()
    if not self.currentList then
        return
    end

    local total = #self.currentList
    local current = self.loadedItems
    if current >= total then
        return
    end

    local newItems = {unpack(self.tradeItems)}
    local limit = math.min(total, current + self.itemBatchSize)

    for i = current + 1, limit do
        table.insert(newItems, self.currentList[i])
    end

    self.tradeItems = newItems
    self.loadedItems = limit
end

function controllerNpcTrader:onTradeScroll(widget, offset)
    if self.loadedItems >= #self.currentList then
        return
    end

    local rowHeight = 48
    local contentHeight = self.loadedItems * rowHeight
    local viewportHeight = widget:getHeight()
    local maxScroll = math.max(0, contentHeight - viewportHeight)

    local value = offset.y
    if value >= maxScroll - 50 then
        self:loadNextBatch()
    end
end

function controllerNpcTrader:onTradeListRendered()
    local list = self:findWidget("#tradeListScroll")
    if list then
        if not list.onScrollEventConnected then
            list.onScrollChange = function(widget, offset)
                self:onTradeScroll(widget, offset)
            end
            list.onScrollEventConnected = true
        end
        for i = 1, list:getChildCount() do
            local child = list:getChildByIndex(i)
            local item = child.tradeItem
            if item then
                child.onMouseRelease = function(widget, mousePos, mouseButton)
                    self:onTradeItemMouseRelease(item, widget, mousePos, mouseButton)
                end
            end
        end
        if self.shouldFocusFirst then
            local firstChild = list:getChildByIndex(1)
            if firstChild then
                self:selectTradeItem(self.tradeItems[1], firstChild)
            end
            self.shouldFocusFirst = false
        elseif self.selectedItem then
            for i = 1, list:getChildCount() do
                local child = list:getChildByIndex(i)
                if child.tradeItem == self.selectedItem then
                    child:focus()
                    break
                end
            end
        end
    end
end

function controllerNpcTrader:onTradeItemMouseRelease(item, widget, mousePos, mouseButton)
    if mouseButton == MouseRightButton then
        local menu = g_ui.createWidget('PopupMenu')
        menu:setGameMenu(true)
        menu:addOption("Look", function()
            g_game.inspectNpcTrade(item.ptr)
        end)
        menu:addOption("Inspect", function()
            print("TODO create module InspectionObject in html")
        end)
        menu:display(mousePos)
        return true
    elseif mouseButton == MouseLeftButton then
        self:selectTradeItem(item, widget)
        return true
    end
    return false
end

function controllerNpcTrader:selectTradeItem(item, widget)
    self.selectedItem = item
    if widget then
        widget:focus()
    end
    self:updateAmount(1)

    local scroll = self:findWidget("#amountScrollBar")
    if scroll then
        scroll:enable()
        scroll:setValue(1)
    end
end

function controllerNpcTrader:updateAmount(amount)
    amount = tonumber(amount) or 1
    if self.selectedItem then
        local maxAmount = 100
        if self.tradeMode == BUY then
            local playerMoney = self:getPlayerMoney()
            local maxByMoney = math.floor(playerMoney / self.selectedItem.price)
            maxAmount = math.max(1, math.min(100, maxByMoney))
            if self.selectedItem.ptr and self.selectedItem.ptr:isStackable() then
                maxAmount = math.max(1, math.min(10000, maxByMoney))
            end
        else
            local sellable = self:getSellQuantity(self.selectedItem.ptr)
            maxAmount = math.max(1, sellable)
        end
        if amount > maxAmount then
            amount = maxAmount
        end
        if amount < 1 then
            amount = 1
        end
        local scroll = self:findWidget("#amountScrollBar")
        if scroll then
            scroll:setMaximum(maxAmount)
            scroll:setMinimum(1)
            if scroll:getValue() ~= amount then
                scroll:setValue(amount)
            end
        end
    end
    self.amount = amount
    if self.selectedItem then
        self.totalPrice = self.selectedItem.price * amount
        self.totalWeight = string.format("%.2f", self.selectedItem.weight * amount)
    else
        self.totalPrice = 0
        self.totalWeight = "0.00"
    end
end

function controllerNpcTrader:onAmountScrollBarChange(value)
    self:updateAmount(value)
end

function controllerNpcTrader:onAmountInputChange(event)
    local input = event.target
    local text = input:getText()
    local cleanText = text:gsub("[^%d]", "")
    if cleanText ~= text then
        input:setText(cleanText)
        text = cleanText
    end
    local amount = tonumber(text) or 1
    self:updateAmount(amount)
    local scroll = self:findWidget("#amountScrollBar")
    if scroll then
        if self.amount ~= amount then
            input:setText(self.amount)
        end
        scroll:setValue(self.amount)
    end
end

function controllerNpcTrader:getPlayerMoney()
    local player = g_game.getLocalPlayer()
    if not player then
        return 0
    end
    local money = player:getResourceBalance(ResourceBank) + player:getResourceBalance(ResourceInventary)
    local currencyId = self.currencyId or 3031
    if currencyId ~= 3031 and currencyId > 0 then
        money = player:getResourceBalance(ResourceNpcTrade)
    elseif currencyId == 0 then
        money = player:getResourceBalance(ResourceNpcStorageTrade)
    end
    return money
end

function controllerNpcTrader:getSellQuantity(itemPtr)
    if not itemPtr then
        return 0
    end
    local id = itemPtr:getId()
    local inventoryTotal = self.playerItems and self.playerItems[id] or 0

    if self.ignoreEquipped then
        local player = g_game.getLocalPlayer()
        local equippedCount = 0
        for i = 1, 10 do
            local item = player:getInventoryItem(i)
            if item and item:getId() == id then
                equippedCount = equippedCount + item:getCount()
            end
        end
        return math.max(0, inventoryTotal - equippedCount)
    end

    return inventoryTotal
end

function controllerNpcTrader:onPlayerGoods(items)
    if not self.playerItems then
        self.playerItems = {}
    end
    for id, amount in pairs(items) do
        if not self.playerItems[id] then
            self.playerItems[id] = amount
        else
            self.playerItems[id] = self.playerItems[id] + amount
        end
    end
    self:refreshPlayerGoods()
end

function controllerNpcTrader:refreshPlayerGoods()
    local money = self:getPlayerMoney()
    local display = self:findWidget("#playerMoneyDisplay")
    if display then
        display:setText(tostring(money))
    end
    if self.tradeMode == SELL then
        if self.selectedItem then
            self:updateAmount(self.amount)
        end
    end
end

function controllerNpcTrader:executeTrade()
    if not self.selectedItem then
        return
    end
    if self.tradeMode == BUY then
        g_game.buyItem(self.selectedItem.ptr, self.amount, self.ignoreCapacity, self.buyWithBackpack)
    else
        g_game.sellItem(self.selectedItem.ptr, self.amount, self.ignoreEquipped)
    end
end

function controllerNpcTrader:clearSearch()
    local input = self:findWidget(".tradeSearchInput")
    if input then
        input:setText("")
        self:filterTradeList("")
    end
end

function controllerNpcTrader:filterQuestListShowHidden(event)
    self:filterTradeList(event.value)
end

function controllerNpcTrader:filterTradeList(searchText)
    if not self.allTradeItems then
        return
    end

    self.searchText = searchText
    local lowerSearch = searchText:lower()
    local filteredItems = {}

    if searchText == "" then
        for _, v in ipairs(self.allTradeItems) do
            table.insert(filteredItems, v)
        end
    else
        for _, item in ipairs(self.allTradeItems) do
            if item.name:lower():find(lowerSearch, 1, true) then
                table.insert(filteredItems, item)
            end
        end
    end

    self:sortTradeItems(filteredItems)

    self.currentList = filteredItems
    self.tradeItems = {}
    self.loadedItems = 0
    self:loadNextBatch()

    if #self.tradeItems > 0 then
        if not self.selectedItem then
            self:selectTradeItem(self.tradeItems[1])
        end
    end
end

function onCloseNpcTrade()
    controllerNpcTrader.isTradeOpen = false
    if controllerNpcTrader.ui and controllerNpcTrader.ui:isVisible() then
        controllerNpcTrader:unloadHtml()
    end
end

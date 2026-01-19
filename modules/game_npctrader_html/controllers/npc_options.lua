function controllerNpcTrader:onOptionsClick()
    local menu = g_ui.createWidget('PopupMenu')
    menu:setGameMenu(true)
    menu:addOption("Sort by Name", function()
        self:setSortBy('name')
    end)
    menu:addOption("Sort by Price", function()
        self:setSortBy('price')
    end)
    menu:addOption("Sort by Weight", function()
        self:setSortBy('weight')
    end)
    menu:addSeparator()
    if self.tradeMode == BUY then
        if self.currencyId == 3031 then
            local backpackOption = menu:addOption("Buy with Backpack", function()
                self:toggleBuyWithBackpack()
            end)
            if self.buyWithBackpack then
                backpackOption:setIcon('/images/ui/console/checked')
            end
        end
        local capText = "Ignore Capacity" .. (self.ignoreCapacity and " [x]" or "")
        menu:addOption(capText, function()
            self:toggleIgnoreCapacity()
        end)
        local bagText = "Buy with Backpack" .. (self.buyWithBackpack and " [x]" or "")
        menu:addOption(bagText, function()
            self:toggleBuyWithBackpack()
        end)
    else
        local equipText = "Sell Equipped" .. (self.ignoreEquipped and " [x]" or " [ ]")
        menu:addOption("Sell Equipped" .. (not self.ignoreEquipped and " [x]" or ""), function()
            self:toggleIgnoreEquipped()
        end)
    end
    menu:display()
end

function controllerNpcTrader:sortTradeItems(items)
    if not items then
        return
    end
    table.sort(items, function(a, b)
        if self.sortBy == 'price' then
            return a.price < b.price
        elseif self.sortBy == 'weight' then
            return a.weight < b.weight
        else
            return a.name:lower() < b.name:lower()
        end
    end)
end

function controllerNpcTrader:setSortBy(sort)
    self.sortBy = sort
    self:filterTradeList(self.searchText or "")
end

function controllerNpcTrader:toggleIgnoreCapacity()
    self.ignoreCapacity = not self.ignoreCapacity
    self:updateAmount(self.amount)
end

function controllerNpcTrader:toggleBuyWithBackpack()
    self.buyWithBackpack = not self.buyWithBackpack
    self:updateAmount(self.amount)
end

function controllerNpcTrader:toggleIgnoreEquipped()
    self.ignoreEquipped = not self.ignoreEquipped
    self:refreshPlayerGoods()
    self:updateAmount(self.amount)
end

controllerNpcTrader = Controller:new()
controllerNpcTrader.widthConsole = 395
controllerNpcTrader.lookType = 23
controllerNpcTrader.creatureName = ""
controllerNpcTrader.outfit = {}
controllerNpcTrader.buttons = {}
controllerNpcTrader.isTradeOpen = false

function controllerNpcTrader:onInit()
    g_modules.enableAutoReload()
end

function controllerNpcTrader:onGameStart()
    controllerNpcTrader:registerEvents(g_game, {
        onNpcChatWindow = onNpcChatWindow,
        onOpenNpcTrade = onOpenNpcTrade,
    })
    controllerNpcTrader:loadHtml('game_npctrader.html')
end

function controllerNpcTrader:onTerminate()
    controllerNpcTrader:unloadHtml()
end

function controllerNpcTrader:onGameEnd()
 controllerNpcTrader:unloadHtml()
end

function onNpcChatWindow(data)
    controllerNpcTrader.widthConsole = 395
    controllerNpcTrader.isTradeOpen = false
    local creature = g_map.getCreatureById(data.npcIds[1])
    if not creature then 
        controllerNpcTrader.creatureName = "NPC"
        controllerNpcTrader.outfit = {type = controllerNpcTrader.lookType}
        controllerNpcTrader.buttons = data.buttons or {}
        return 
    end

    controllerNpcTrader.creatureName = creature:getName() or "NPC"
    controllerNpcTrader.outfit = creature:getOutfit()
    controllerNpcTrader.buttons = data.buttons or {}
end

function onOpenNpcTrade(items)
    controllerNpcTrader.isTradeOpen = true
    controllerNpcTrader.widthConsole = 600
    local formattedItems = {}
    if items and #items > 0 then
        for i, itemData in ipairs(items) do
            table.insert(formattedItems, {
                ptr = itemData[1],
                name = itemData[2],
                weight = itemData[3] / 100,
                price = itemData[4],
                count = itemData[5]
            })
        end
    end
    controllerNpcTrader.tradeItems = formattedItems
    
    controllerNpcTrader:selectTradeItem(nil)
end

function controllerNpcTrader:selectTradeItem(item)
    self.selectedItem = item
    self.amount = 1
    if self.ui and self.ui.tradeScrollBar then
        self.ui.tradeScrollBar:setValue(1)
    end
    self:onQuantityValueChange(1)
end

function controllerNpcTrader:onQuantityValueChange(quantity)
    self.amount = quantity
    if self.selectedItem then
        self.totalPrice = self.selectedItem.price * quantity
        self.totalWeight = string.format("%.2f", self.selectedItem.weight * quantity)
    else
        self.totalPrice = 0
        self.totalWeight = "0.00"
    end
end

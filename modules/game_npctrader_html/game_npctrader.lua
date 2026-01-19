controllerNpcTrader = Controller:new()
controllerNpcTrader.widthConsole = 395
controllerNpcTrader.lookType = 23
controllerNpcTrader.creatureName = ""
controllerNpcTrader.outfit = nil
controllerNpcTrader.buttons = {}
controllerNpcTrader.isTradeOpen = false

local testMode = true

function controllerNpcTrader:onInit()
    if testMode then
        g_modules.enableAutoReload()
    end
end

function controllerNpcTrader:onGameStart()
    controllerNpcTrader:registerEvents(g_game, {
        onNpcChatWindow = onNpcChatWindow,
        onOpenNpcTrade = onOpenNpcTrade,
    })
    if testMode then
        local mockTradeItems = {
            { Item.create(3031), "Gold Coin", 10, 1, 100 },
            { Item.create(3357), "Plate Armor", 120000, 400, 100 },
            { Item.create(3351), "Steel Helmet", 46000, 190, 100 },
            { Item.create(190), "Health Potion", 500, 45, 100 }
        }
        onNpcChatWindow({ 
            ["buttons"] = { 
                [1] = { ["id"] = 7, ["text"] = "yes" },
                [2] = { ["id"] = 8, ["text"] = "no" },
                [3] = { ["id"] = 9, ["text"] = "bye" },
                [4] = { ["id"] = 0, ["text"] = "trade" }
            },
            ["npcIds"] = { [1] = 2147484212 }
        })
        controllerNpcTrader:scheduleEvent(function() onOpenNpcTrade(mockTradeItems) end, 1500, "controllertest")
    end
end

function controllerNpcTrader:onTerminate()
    local ui = controllerNpcTrader.ui
    if ui and ui:isVisible() then
        controllerNpcTrader:unloadHtml()
    end
end

function controllerNpcTrader:onGameEnd()
    local ui = controllerNpcTrader.ui
    if ui and ui:isVisible() then
        controllerNpcTrader:unloadHtml()
    end
end

function onNpcChatWindow(data)
    local creature = g_map.getCreatureById(data.npcIds[1])
    if not creature then 
        return 
    end

    controllerNpcTrader.widthConsole = 395
    controllerNpcTrader.isTradeOpen = false
    controllerNpcTrader.creatureName = creature:getName() or "NPC"
    controllerNpcTrader.outfit = creature:getOutfit()
    controllerNpcTrader.buttons = data.buttons or {}
    controllerNpcTrader:loadHtml('game_npctrader.html')
end

function onOpenNpcTrade(items)
    local ui = controllerNpcTrader.ui
    if not ui or not ui:isVisible() then
        controllerNpcTrader:loadHtml('game_npctrader.html')
    end
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
    if #formattedItems > 0 then
        controllerNpcTrader:findWidget("#amountScrollBar"):enable()
        controllerNpcTrader:selectTradeItem(formattedItems[1])
    else
        controllerNpcTrader:findWidget("#amountScrollBar"):disable()
    end

end
function controllerNpcTrader:onTradeListRendered()

    print(1111111111)
    local list = self:findWidget("#tradeListScroll")
    if list then
        local firstChild = list:getChildByIndex(1)
        if firstChild then
            firstChild:focus()
        end
    end
end

function controllerNpcTrader:selectTradeItem(item, widget)
    self.selectedItem = item
    if widget then
        widget:focus()
    end
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

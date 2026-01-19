controllerNpcTrader = Controller:new()
controllerNpcTrader.widthConsole = 395
controllerNpcTrader.lookType = 23
controllerNpcTrader.creatureName = ""
controllerNpcTrader.outfit = nil
controllerNpcTrader.buttons = {}
controllerNpcTrader.isTradeOpen = false
--@ DELETEME
local testMode = false
local function test_reactive_loop(numItems)
    -- Test reactive loop helper
    modules.game_npctrader_html.test_reactive_loop(500)
    local mockTradeItems = {}
    for i = 1, numItems do
        local itemId = math.random(1000, 9999)
        local itemName = "Item #" .. itemId
        local itemPrice = math.random(100, 5000)
        local itemAmount = math.random(1, 100)
        local itemWeight = math.random(1, 10)
        table.insert(mockTradeItems, {Item.create(itemId), itemName, itemPrice, itemAmount, itemWeight})
    end
    onOpenNpcTrade(mockTradeItems)
end

function controllerNpcTrader:onInit()
    if testMode then
        g_modules.enableAutoReload()
    end
end

function controllerNpcTrader:onGameStart()
    self:registerEvents(g_game, {
        onNpcChatWindow = onNpcChatWindow,
        onOpenNpcTrade = onOpenNpcTrade,
        onPlayerGoods = onPlayerGoods,
        onCloseNpcTrade = onCloseNpcTrade
    })

    if testMode then
        -- LuaFormatter off
        local mockTradeItems = {
            { Item.create(3031), "LOOOOOOOOOOONG TEXT", 10, 1000000000, 100 },
            { Item.create(3357), "Plate Armor", 120000, 400, 100 },
            { Item.create(3351), "Steel Helmet", 46000, 190, 100 },
            { Item.create(190), "Health Potion", 500, 45, 100 }
        }
        
        onNpcChatWindow({ 
            ["buttons"] = { 
                [1] = { ["id"] = KeywordButtonIcon.KEYWORDBUTTONICON_YES, ["text"] = "yes" },
                [2] = { ["id"] = KeywordButtonIcon.KEYWORDBUTTONICON_NO, ["text"] = "no" },
                [3] = { ["id"] = KeywordButtonIcon.KEYWORDBUTTONICON_BYE, ["text"] = "bye" },
                [4] = { ["id"] = KeywordButtonIcon.KEYWORDBUTTONICON_GENERALTRADE, ["text"] = "trade" },
            },
            ["npcIds"] = { [1] = 2147484212 }
        })
        -- LuaFormatter on

        self:scheduleEvent(function()
            onOpenNpcTrade(mockTradeItems)
        end, 1500, "controllertest")
--@ 
    end
end

function controllerNpcTrader:onTerminate()
    local ui = self.ui
    if ui and ui:isVisible() then
        self:unloadHtml()
    end
end

function controllerNpcTrader:onGameEnd()
    local ui = self.ui
    if ui and ui:isVisible() then
        self:unloadHtml()
    end
end


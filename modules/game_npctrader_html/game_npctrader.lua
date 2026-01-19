controllerNpcTrader = Controller:new()
controllerNpcTrader.widthConsole = controllerNpcTrader.DEFAULT_CONSOLE_WIDTH
controllerNpcTrader.lookType = 23
controllerNpcTrader.creatureName = ""
controllerNpcTrader.outfit = nil
controllerNpcTrader.buttons = {}
controllerNpcTrader.isTradeOpen = false

function controllerNpcTrader:onInit()
    self:registerEvents(g_game, {
        onNpcChatWindow = onNpcChatWindow,
        onOpenNpcTrade = onOpenNpcTrade,
        onPlayerGoods = onPlayerGoods,
        onCloseNpcTrade = self.onCloseNpcTrade,
        onTalk = onNpcTalk
    })
end

function controllerNpcTrader:onGameStart()
end

function controllerNpcTrader:onTerminate()
    self:onCloseNpcTrade()
end

function controllerNpcTrader:onGameEnd()
    self:onCloseNpcTrade()
end

function controllerNpcTrader:onCloseNpcTrade()
    controllerNpcTrader.isTradeOpen = false
    -- Clean up state
    controllerNpcTrader.buyItems = {}
    controllerNpcTrader.sellItems = {}
    controllerNpcTrader.playerItems = {}
    controllerNpcTrader.selectedItem = nil
    controllerNpcTrader.tradeItems = {}
    controllerNpcTrader.currentList = {}
    controllerNpcTrader.allTradeItems = {}
    if controllerNpcTrader.ui and controllerNpcTrader.ui:isVisible() then
        controllerNpcTrader:unloadHtml()
    end
end


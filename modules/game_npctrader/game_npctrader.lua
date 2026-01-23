controllerNpcTrader = Controller:new()
controllerNpcTrader.widthConsole = controllerNpcTrader.DEFAULT_CONSOLE_WIDTH
controllerNpcTrader.creatureName = ""
controllerNpcTrader.outfit = nil
controllerNpcTrader.buttons = {}
controllerNpcTrader.isTradeOpen = false

function controllerNpcTrader:onInit()

end

function controllerNpcTrader:onGameStart()
    if g_game.getClientVersion() < 1510 then
        self:legacy_init()
    end

    self:registerEvents(g_game, {
        onNpcChatWindow = onNpcChatWindow,
        onOpenNpcTrade = function(...)
            if g_game.getClientVersion() < 1510 then
                self:onOpenNpcTradeLegacy(...)
            else
                onOpenNpcTrade(...)
            end
        end,
        onPlayerGoods = function(...)
            if g_game.getClientVersion() < 1510 then
                self:onPlayerGoodsLegacy(...)
            else
                --onPlayerGoods(...)
            end
        end,
        onCloseNpcTrade = function()
            if g_game.getClientVersion() < 1510 then
                self:onCloseNpcTradeLegacy()
            else
                --onCloseNpcTrade()
            end
        end,
        onTalk = onNpcTalk
    })
end

function controllerNpcTrader:onTerminate()
    self:onCloseNpcTrade()
    if g_game.getClientVersion() < 1510 then
        self:legacy_terminate()
    end
end

function controllerNpcTrader:onGameEnd()
    self:onCloseNpcTrade()
    if g_game.getClientVersion() < 1510 then
        self:legacy_hide()
    end
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
    
    if g_game.getClientVersion() < 1510 then
        self:legacy_hide()
    end

    if controllerNpcTrader.ui and controllerNpcTrader.ui:isVisible() then
        controllerNpcTrader:unloadHtml()
    end
end


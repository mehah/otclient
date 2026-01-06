MarketProtocol = {}

-- private functions

local silent
local protocol
local statistics = runinsandbox('offerstatistic')

local function send(msg)
    if protocol and not silent then
        protocol:send(msg)
    end
end

-- public functions
function initProtocol()
    connect(g_game, {
        onGameStart = MarketProtocol.registerProtocol,
        onGameEnd = MarketProtocol.unregisterProtocol
    })

    -- reloading module
    if g_game.isOnline() then
        MarketProtocol.registerProtocol()
    end

    MarketProtocol.silent(false)
end

function terminateProtocol()
    disconnect(g_game, {
        onGameStart = MarketProtocol.registerProtocol,
        onGameEnd = MarketProtocol.unregisterProtocol
    })

    -- reloading module
    MarketProtocol.unregisterProtocol()
    MarketProtocol = nil
end

function MarketProtocol.updateProtocol(_protocol)
    protocol = _protocol
end

function MarketProtocol.registerProtocol()
    MarketProtocol.updateProtocol(g_game.getProtocolGame())
end

function MarketProtocol.unregisterProtocol()
    MarketProtocol.updateProtocol(nil)
end

function MarketProtocol.silent(mode)
    silent = mode
end

-- sending protocols

function MarketProtocol.sendMarketBrowse(browseId, itemId, tier)
    if g_game.getFeature(GamePlayerMarket) then
        local msg = OutputMessage.create()
        msg:addU8(ClientOpcodes.ClientMarketBrowse)
        if g_game.getClientVersion() >= 1251 then
            msg:addU8(browseId)
            msg:addU16(itemId)
            if g_game.getFeature(GameThingUpgradeClassification) then
                msg:addU8(tier)
            end
        else
            msg:addU16(itemId)
        end
        send(msg)
    else
        g_logger.error('MarketProtocol.sendMarketBrowse does not support the current protocol.')
    end
end

function MarketProtocol.sendMarketBrowseMyOffers()
    if g_game.getClientVersion() >= 1251 then
        MarketProtocol.sendMarketBrowse(MarketRequest.MyOffers, 0, 0)
    else
        MarketProtocol.sendMarketBrowse(0, MarketRequest.OldMyOffers, 0)
    end
end
function MarketProtocol.sendMarketBrowseOfferHistory()
    if g_game.getClientVersion() >= 1251 then
        MarketProtocol.sendMarketBrowse(MarketRequest.MyHistory, 0, 0)
    else
        MarketProtocol.sendMarketBrowse(0, MarketRequest.OldMyHistory, 0)
    end
end

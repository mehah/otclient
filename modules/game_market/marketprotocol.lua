MarketProtocol = {}

-- private functions

local silent
local protocol
local statistics = runinsandbox('offerstatistic')

local function send(msg) if protocol and not silent then protocol:send(msg) end end

-- public functions
function initProtocol()
    connect(g_game, {
        onGameStart = MarketProtocol.registerProtocol,
        onGameEnd = MarketProtocol.unregisterProtocol
    })

    -- reloading module
    if g_game.isOnline() then MarketProtocol.registerProtocol() end

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

function MarketProtocol.updateProtocol(_protocol) protocol = _protocol end

function MarketProtocol.registerProtocol()
    MarketProtocol.updateProtocol(g_game.getProtocolGame())
end

function MarketProtocol.unregisterProtocol()
    MarketProtocol.updateProtocol(nil)
end

function MarketProtocol.silent(mode) silent = mode end

-- sending protocols

function MarketProtocol.sendMarketBrowse(browseId, browseType)
    if g_game.getFeature(GamePlayerMarket) then
        local msg = OutputMessage.create()
        msg:addU8(ClientOpcodes.ClientMarketBrowse)
		msg:addU8(browseId)
		g_logger.debug("" .. tostring(browseId))
		if browseType > 0 then
			msg:addU16(browseType)
		end
        send(msg)
    else
        g_logger.error('MarketProtocol.sendMarketBrowse does not support the current protocol.')
    end
end

function MarketProtocol.sendMarketBrowseMyOffers() MarketProtocol.sendMarketBrowse(MarketRequest.MyOffers, 2) end
function MarketProtocol.sendMarketBrowseOfferHistory() MarketProtocol.sendMarketBrowse(MarketRequest.MyHistory, 1) end

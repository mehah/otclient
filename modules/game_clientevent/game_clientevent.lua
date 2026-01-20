clientEventController = Controller:new()
function clientEventController:onInit()
    self.bannerQueue = {}
    self.bannerState = "idle"
    self:registerEvents(g_game, {
        onClientEvent = function(...)
            self:onClientEvent(...)
        end,
    })
end
function clientEventController:onTerminate()
    screenshot_onTerminate()
    infoBanner_onTerminate()
end

function clientEventController:onGameStart()
    screenshot_onGameStart()
end

function clientEventController:onGameEnd()
    screenshot_onGameEnd()
end

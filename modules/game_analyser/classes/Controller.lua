if not ControllerAnalyser then
    ControllerAnalyser = {
        name = "ControllerAnalyser",
        class = "ControllerAnalyser",
        window = nil,
        session = nil,
        event250 = nil,
        event1000 = nil,
        event2000 = nil,
        eventGraph = nil,
        data = {}
    }
    ControllerAnalyser.__index = ControllerAnalyser
end


function ControllerAnalyser:startEvent()
	HuntingAnalyser.session = os.time()
    LootAnalyser.session = os.time()
    SupplyAnalyser.session = os.time()
    ImpactAnalyser.session = os.time()
    InputAnalyser.session = os.time()
    XPAnalyser.session = os.time()
    DropTrackerAnalyser.session = os.time()
    MiscAnalyzer.session = os.time()

	if ControllerAnalyser.eventGraph then ControllerAnalyser.eventGraph:cancel() end
	if ControllerAnalyser.event250 then ControllerAnalyser.event250:cancel() end
	if ControllerAnalyser.event1000 then ControllerAnalyser.event1000:cancel() end
	if ControllerAnalyser.event2000 then ControllerAnalyser.event2000:cancel() end

    ControllerAnalyser.event250 = cycleEvent(function()
        if g_game.isOnline() then
            BossCooldown:checkTicks()
        end
	end, 250)

    ControllerAnalyser.event1000 = cycleEvent(function()
        if g_game.isOnline() then
            HuntingAnalyser:updateWindow()
            LootAnalyser:checkBalance()
            ImpactAnalyser:updateWindow()
            InputAnalyser:checkDPS()
            XPAnalyser:checkExpHour()
            DropTrackerAnalyser:checkTracker()
            MiscAnalyzer:updateWindow()
            SupplyAnalyser:updateGraphics()
        end
	end, 1000)
	ControllerAnalyser.event2000 = cycleEvent(function()
        if g_game.isOnline() then
            InputAnalyser:updateWindow()
            SupplyAnalyser:checkBalance()
        end
	end, 2000)
	ControllerAnalyser.eventGraph = cycleEvent(function()
        if g_game.isOnline() then
            LootAnalyser:updateGraphics()
            SupplyAnalyser:updateGraphics()
            XPAnalyser:updateWindow()
        end
	end, 60*1000)


    ImpactAnalyser:checkAnchos()
    InputAnalyser:checkAnchos()
end

GameAnalyzer = {}

Analyzers = {
    GameExpAnalyzer = {
        name = "Experience",
        toggle = GameExpAnalyzerToggle,
    },
}

contentPanel = nil
analyzerButton = nil
analyzerWindow = nil
expAnalyzerWindow = nil
expStart = nil
expHourStart = 0
expTimeElapsed = 0

function GameAnalyzer.init()
    print("Init Game Analyzer")
    analyzerButton = modules.game_mainpanel.addToggleButton('analyzerButton', 
                                                            tr('Open analytics selector window'),
                                                            '/images/options/analyzers',
                                                            GameAnalyzer.toggle)

    analyzerButton:setOn(false)
    analyzerWindow = g_ui.loadUI('game_analyzer')
    analyzerWindow:disableResize()
    
    expAnalyzerInit()
    
    loadContentPanel()

    connect(LocalPlayer, {
        onExperienceChange = onExperienceChange,
    })
    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline,
        onPingBack = refresh
    })
    refresh()
end

function expAnalyzerInit()
    expAnalyzerWindow = g_ui.loadUI('game_exp_analyzer')
    expAnalyzerWindow:disableResize()

    
    expHourStart = g_clock.seconds()
    
    local expGainValue = expAnalyzerWindow:getChildById('expGainValue')
    if expGainValue then
        expGainValue:setText(0)
    end

    local expHourValue = expAnalyzerWindow:getChildById('expHourValue')
    if expHourValue then
        expHourValue:setText(0)
    end
end

function expAnalyzerTerminate()
    expAnalyzerWindow:destroy()
    expStart = nil
    expHourStart = nil
    expTimeElapsed = 0
end

function GameAnalyzer.terminate()
    analyzerButton:destroy()
    analyzerWindow:destroy()
    expAnalyzerTerminate()
    disconnect(LocalPlayer, {
        onExperienceChange = onExperienceChange,
    })
    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline,
        onPingBack = refresh
    })

    GameAnalyzer = nil
end

function onMiniWindowOpen()
    analyzerButton:setOn(true)
end

function onMiniWindowClose()
    analyzerButton:setOn(false)
end

function loadContentPanel()
    contentPanel = modules.game_interface.findContentPanelAvailable(analyzerWindow, analyzerWindow:getMinimumHeight())
    if not contentPanel then
        print("No content panel available")
        return
    end
end

function GameAnalyzer.toggle()
    if analyzerButton:isOn() then
        analyzerWindow:close()
        analyzerWindow:setOn(false)
    else
        if not analyzerWindow:getParent() then
            contentPanel:addChild(analyzerWindow)
        end
        analyzerWindow:open()
        analyzerButton:setOn(true)
    end
end

function online()
    analyzerButton:show()
    refresh()
    expStart = nil
    expHourStart = 0
    expTimeElapsed = 0
end

function offline()
    analyzerButton:hide()
    analyzerWindow:setParent(nil, true)
    expStart = nil
    expHourStart = 0
    expTimeElapsed = 0
end

function refresh()
    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    if expStart == nil then
        expStart = player:getExperience()
    end

    onExperienceChange(player, player:getExperience())
end

function toggleAnalyzer(analyzer)
    analyzer:setChecked(not analyzer:isChecked())
    toggleFromAnalyzer(analyzer)
end

function toggleFromAnalyzer(analyzer)
    local analyzerType = getFirstWordBeforeCapital(analyzer:getId())
    analyzerType = 'Game' .. analyzerType .. 'Analyzer'

    local analyzerConfig = Analyzers[analyzerType]
    if analyzerConfig and analyzerConfig.toggle then
        analyzerConfig.toggle(analyzer)
    else
        print("Toggle function for " .. analyzerType .. " not found")
    end
end

function GameExpAnalyzerToggle(analyzer)
    if analyzer:isChecked() then
        if not expAnalyzerWindow:getParent() then
            contentPanel:addChild(expAnalyzerWindow)
        end
        expAnalyzerWindow:open()
    else
        expAnalyzerWindow:close()
    end
end

function onExperienceChange(player, exp, oldExp)
    if expAnalyzerWindow then
        local expGainValue = expAnalyzerWindow:getChildById('expGainValue')
        if expGainValue then
            if expStart == nil then
                expStart = exp
            end
            expGainValue:setText(exp - expStart)
        end

        local expHourValue = expAnalyzerWindow:getChildById('expHourValue')
        if expHourValue then
            if expHourStart == 0 then
                expHourStart = g_clock.seconds()
            end
            
            timeElapsed = g_clock.seconds() - expHourStart
            expHourValue:setText(calculateExpPerHour(exp, expStart, timeElapsed, expHourStart))
        end
    end
end

function calculateExpPerHour(exp, expStart, currentTime, expHourStart)
    local expGained = exp - expStart
    local timeElapsed = currentTime - expHourStart
    local expPerHour = math.floor(((expGained / timeElapsed) * 360) * 4)
    print("Exp Per Hour:" .. expPerHour)
    return comma_value(expPerHour)
end

function getFirstWordBeforeCapital(str)
    local firstWord = str:match("^[^A-Z]*")
    if firstWord then
        firstWord = firstWord:sub(1, 1):upper() .. firstWord:sub(2)
    end
    return firstWord
end
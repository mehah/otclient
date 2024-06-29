GameAnalyzer = {}
GameExpAnalyzer = {}

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

function GameAnalyzer.init()
    print("Init 2")
    analyzerButton = modules.game_mainpanel.addToggleButton('analyzerButton', 
                                                            tr('Open analytics selector window'),
                                                            '/images/options/analyzers',
                                                            GameAnalyzer.toggle)

    analyzerButton:setOn(false)
    analyzerWindow = g_ui.loadUI('game_analyzer')
    expAnalyzerWindow = g_ui.loadUI('game_exp_analyzer')
    xerecaAnalyzerWindow = g_ui.loadUI('game_xereca_analyzer')

    analyzerWindow:disableResize()

    GameExpAnalyzer = modules.game_exp_analyzer
    

    loadContentPanel()

    

    -- expAnalyzerButton = analyzerWindow:recursiveGetChildById('expAnalyzerButton')

    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline,
    })
end

function GameAnalyzer.terminate()
    analyzerButton:destroy()
    analyzerWindow:destroy()
    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline,
    })

    GameAnalyzer = nil
    GameExpAnalyzer = nil
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
end

function offline()
    analyzerButton:hide()
    analyzerWindow:setParent(nil, true)
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

function getFirstWordBeforeCapital(str)
    local firstWord = str:match("^[^A-Z]*")
    if firstWord then
        firstWord = firstWord:sub(1, 1):upper() .. firstWord:sub(2)
    end
    return firstWord
end
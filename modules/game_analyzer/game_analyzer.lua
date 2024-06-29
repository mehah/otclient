analyzerButton = nil
analyzerWindow = nil
expAnalyzerButton = nil

function init()
    analyzerButton = modules.game_mainpanel.addToggleButton('analyzerButton', 
                                                            tr('Open analytics selector window'),
                                                            '/images/options/analyzers',
                                                            toggle)

    analyzerButton:setOn(false)
    analyzerButton:hide()

    analyzerWindow = g_ui.loadUI('game_analyzer')
    analyzerWindow:disableResize()

    expAnalyzerButton = analyzerWindow:getChildById('expAnalyzerButton')

    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline,
    })
end

function terminate()
    analyzerButton:destroy()
    analyzerWindow:destroy()
    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline,
    })
end

function onMiniWindowOpen()
    analyzerButton:setOn(true)
end

function onMiniWindowClose()
    analyzerButton:setOn(false)
end

function toggle()
    if analyzerButton:isOn() then
        analyzerWindow:close()
        analyzerWindow:setOn(false)
    else
        if not analyzerWindow:getParent() then
            local panel = modules.game_interface.findContentPanelAvailable(analyzerWindow, analyzerWindow:getMinimumHeight())
            if not panel then
                return
            end

            panel:addChild(analyzerWindow)
        end
        analyzerWindow:open()
        analyzerButton:setOn(true)
    end
end

function online()
    analyzerButton:show()
end

function offline()
    analyzerWindow:setParent(nil, true)
end

function toggleAnalyzer(analyzer)
    analyzer:setChecked(not expAnalyzerButton:isChecked())
end
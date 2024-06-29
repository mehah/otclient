function init()
    -- bottomPanel = modules.game_interface.getBottomPanel()
    
    print("analyzerxloaded")

    analyzerButton = modules.game_mainpanel.addToggleButton('analyzerButton', 
                                                            tr('Open analytics selector window'),
                                                            '/images/options/analyzers',
                                                            toggle)

    analyzerButton:setOn(true)
    analyzerButton:hide()

    analyzerWindow = g_ui.loadUI('game_analyzer')
    analyzerWindow:disableResize()
    analyzerWindow:setup()

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
        -- analyzerWindow:getMinimumHeight()
        if not analyzerWindow:getParent() then
            local panel = modules.game_interface.findContentPanelAvailable(analyzerWindow, 200)
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

end

function offline()
    
end
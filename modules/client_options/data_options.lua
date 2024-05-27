return {
    vsync = {
        value = true,
        action = function(value, options, controller, panels, extraWidgets, extraWidgets)
            g_window.setVerticalSync(value)
        end
    },
    showFps = {
        value = false,
        action = function(value, options, controller, panels, extraWidgets)
            modules.client_topmenu.setFpsVisible(value)
        end
    },
    showPing = {
        value = false,
        action = function(value, options, controller, panels, extraWidgets)
            modules.client_topmenu.setPingVisible(value)
        end
    },
    fullscreen = {
        value = false,
        action = function(value, options, controller, panels, extraWidgets)
            g_window.setFullscreen(value)
        end
    },
    classicControl = false,
    smartWalk = false,
    preciseControl = {
        value = false,
        action = function(value, options, controller, panels, extraWidgets)
            g_game.setScheduleLastWalk(not value)
        end
    },
    autoChaseOverride = true,
    moveStack = false,
    showStatusMessagesInConsole = true,
    showEventMessagesInConsole = true,
    showInfoMessagesInConsole = true,
    showTimestampsInConsole = true,
    showLevelsInConsole = true,
    showPrivateMessagesInConsole = true,
    showOthersStatusMessagesInConsole = false,
    showPrivateMessagesOnScreen = true,
    openMaximized = false,
    backgroundFrameRate = {
        value = 201,
        action = function(value, options, controller, panels, extraWidgets)
            local text, v = value, value
            if value <= 0 or value >= 201 then
                text = 'max'
                v = 0
            end

            panels.graphicsPanel:getChildById('backgroundFrameRateLabel'):setText(tr('Game framerate limit: %s', text))
            g_app.setMaxFps(v)
        end
    },
    enableAudio = {
        value = true,
        action = function(value, options, controller, panels, extraWidgets)
            if g_sounds then
                g_sounds.setAudioEnabled(value)
            end

            if value then
                extraWidgets.audioButton:setIcon('/images/topbuttons/audio')
            else
                extraWidgets.audioButton:setIcon('/images/topbuttons/audio_mute')
            end
        end
    },
    enableMusicSound = {
        value = true,
        action = function(value, options, controller, panels, extraWidgets)
            if g_sounds then
                g_sounds.getChannel(SoundChannels.Music):setEnabled(value)
            end
        end
    },
    musicSoundVolume = {
        value = 100,
        action = function(value, options, controller, panels, extraWidgets)
            if g_sounds then
                g_sounds.getChannel(SoundChannels.Music):setGain(value / 100)
            end
            panels.soundPanel:getChildById('musicSoundVolumeLabel'):setText(tr('Music volume: %d', value))
        end
    },
    enableLights = {
        value = true,
        action = function(value, options, controller, panels, extraWidgets)
            panels.gameMapPanel:setDrawLights(value and options.ambientLight.value < 100)
            panels.graphicsPanel:getChildById('ambientLight'):setEnabled(value)
            panels.graphicsPanel:getChildById('ambientLightLabel'):setEnabled(value)
        end
    },
    limitVisibleDimension = {
        value = false,
        action = function(value, options, controller, panels, extraWidgets)
            panels.gameMapPanel:setLimitVisibleDimension(value)
        end
    },
    floatingEffect = {
        value = false,
        action = function(value, options, controller, panels, extraWidgets)
            g_map.setFloatingEffect(value)
        end
    },
    ambientLight = {
        value = 0,
        action = function(value, options, controller, panels, extraWidgets)
            panels.graphicsPanel:getChildById('ambientLightLabel'):setText(tr('Ambient light: %s%%', value))
            panels.gameMapPanel:setMinimumAmbientLight(value / 100)
            panels.gameMapPanel:setDrawLights(options.enableLights.value)
        end
    },
    displayNames = {
        value = true,
        action = function(value, options, controller, panels, extraWidgets)
            panels.gameMapPanel:setDrawNames(value)

            if g_gameConfig.isDrawingInformationByWidget() then
                modules.game_creatureinformation.toggleInformation()
            end
        end
    },
    displayHealth = {
        value = true,
        action = function(value, options, controller, panels, extraWidgets)
            panels.gameMapPanel:setDrawHealthBars(value)

            if g_gameConfig.isDrawingInformationByWidget() then
                modules.game_creatureinformation.toggleInformation()
            end
        end
    },
    displayMana = {
        value = true,
        action = function(value, options, controller, panels, extraWidgets)
            panels.gameMapPanel:setDrawManaBar(value)

            if g_gameConfig.isDrawingInformationByWidget() then
                modules.game_creatureinformation.toggleInformation()
            end
        end
    },
    displayText = {
        value = true,
        action = function(value, options, controller, panels, extraWidgets)
            g_app.setDrawTexts(value)
        end
    },
    turnDelay = {
        value = 50,
        action = function(value, options, controller, panels, extraWidgets)
            panels.controlPanel:getChildById('turnDelayLabel'):setText(tr('Turn delay: %sms', value))
        end
    },
    hotkeyDelay = {
        value = 70,
        action = function(value, options, controller, panels, extraWidgets)
            panels.controlPanel:getChildById('hotkeyDelayLabel'):setText(tr('Hotkey delay: %sms', value))
        end
    },
    crosshair = {
        value = 'default',
        action = function(value, options, controller, panels, extraWidgets)
            local crossPath = '/images/game/crosshair/'
            local newValue = value
            if newValue == 'disabled' then
                newValue = nil
            end

            panels.gameMapPanel:setCrosshairTexture(newValue and crossPath .. newValue or nil)
            panels.generalPanel.crosshair:setCurrentOptionByData(newValue, true)
        end
    },
    enableHighlightMouseTarget = {
        value = true,
        action = function(value, options, controller, panels, extraWidgets)
            panels.gameMapPanel:setDrawHighlightTarget(value)
        end
    },
    antialiasingMode = {
        value = 1,
        action = function(value, options, controller, panels, extraWidgets)
            panels.gameMapPanel:setAntiAliasingMode(value)
            panels.generalPanel.crosshair:setCurrentOptionByData(value, true)
        end
    },
    shadowFloorIntensity = {
        value = 30,
        action = function(value, options, controller, panels, extraWidgets)
            panels.graphicsPanel:getChildById('shadowFloorIntensityLevel'):setText(tr('Shadow floor Intensity: %s%%',
                value))
            panels.gameMapPanel:setShadowFloorIntensity(1 - (value / 100))
        end
    },
    optimizeFps = {
        value = true,
        action = function(value, options, controller, panels, extraWidgets)
            g_app.optimize(value)
        end
    },
    forceEffectOptimization = {
        value = true,
        action = function(value, options, controller, panels, extraWidgets)
            g_app.forceEffectOptimization(value)
        end
    },
    drawEffectOnTop = {
        value = false,
        action = function(value, options, controller, panels, extraWidgets)
            g_app.setDrawEffectOnTop(value)
        end
    },
    floorViewMode = {
        value = 1,
        action = function(value, options, controller, panels, extraWidgets)
            panels.gameMapPanel:setFloorViewMode(value)
            panels.graphicsPanel.floorViewMode:setCurrentOptionByData(value, true)

            local fadeMode = value == 1
            panels.graphicsPanel:getChildById('floorFading'):setEnabled(fadeMode)
            panels.graphicsPanel:getChildById('floorFadingLabel'):setEnabled(fadeMode)
        end
    },
    floorFading = {
        value = 500,
        action = function(value, options, controller, panels, extraWidgets)
            panels.graphicsPanel:getChildById('floorFadingLabel'):setText(tr('Floor Fading: %s ms', value))
            panels.gameMapPanel:setFloorFading(tonumber(value))
        end
    },
    asyncTxtLoading = {
        value = false,
        action = function(value, options, controller, panels, extraWidgets)
            if g_game.isUsingProtobuf() then
                value = true
            elseif g_app.isEncrypted() then
                local asyncWidget = panels.graphicsPanel:getChildById('asyncTxtLoading')
                asyncWidget:setEnabled(false)
                asyncWidget:setChecked(false)
                return
            end

            g_app.setLoadingAsyncTexture(value)
        end
    },
    creatureInformationScale = {
        value = 0,
        action = function(value, options, controller, panels, extraWidgets)
            if value == 0 then
                value = g_window.getDisplayDensity() - 0.5
            else
                value = value / 2
            end
            g_app.setCreatureInformationScale(math.max(value + 0.5, 1))
            panels.generalPanel:getChildById('creatureInformationScaleLabel'):setText(
                tr('Creature Information Scale: %sx', math.max(value + 0.5, 1)))
        end
    },
    staticTextScale = {
        value = 0,
        action = function(value, options, controller, panels, extraWidgets)
            if value == 0 then
                value = g_window.getDisplayDensity() - 0.5
            else
                value = value / 2
            end
            g_app.setStaticTextScale(math.max(value + 0.5, 1))
            panels.generalPanel:getChildById('staticTextScaleLabel'):setText(tr('Message Scale: %sx',
                math.max(value + 0.5, 1)))
        end
    },
    animatedTextScale = {
        value = 0,
        action = function(value, options, controller, panels, extraWidgets)
            if value == 0 then
                value = g_window.getDisplayDensity() - 0.5
            else
                value = value / 2
            end
            g_app.setAnimatedTextScale(math.max(value + 0.5, 1))
            panels.generalPanel:getChildById('animatedTextScaleLabel'):setText(
                tr('Animated Message Scale: %sx', math.max(value + 0.5, 1)))
        end
    },
    showLeftPanel = {
        value = true,
        action = function(value, options, controller, panels, extraWidgets)
            modules.game_interface.getLeftPanel():setOn(value)
        end
    },
    showRightExtraPanel = {
        value = false,
        action = function(value, options, controller, panels, extraWidgets)
            modules.game_interface.getRightExtraPanel():setOn(value)
        end
    },
    dontStretchShrink = {
        value = false,
        action = function(value, options, controller, panels, extraWidgets)
            addEvent(function()
                modules.game_interface.updateStretchShrink()
            end)
        end
    },
    setEffectAlphaScroll = {
        value = 100,
        action = function(value, options, controller, panels, extraWidgets)
            g_client.setEffectAlpha(value / 100)
            panels.generalPanel:getChildById('setEffectAlphaLabel'):setText(tr('Opacity Effect: %s%%', value))
        end
    },
    setMissileAlphaScroll = {
        value = 100,
        action = function(value, options, controller, panels, extraWidgets)
            g_client.setMissileAlpha(value / 100)
            panels.generalPanel:getChildById('setMissileAlphaLabel'):setText(tr('Opacity Missile: %s%%', value))
        end
    },
}

local defaultOptions = {
    vsync = true,
    showFps = false,
    showPing = false,
    fullscreen = false,
    classicControl = false,
    smartWalk = false,
    preciseControl = false,
    autoChaseOverride = true,
    moveStack = false,
    showStatusMessagesInConsole = true,
    showEventMessagesInConsole = true,
    showInfoMessagesInConsole = true,
    showTimestampsInConsole = true,
    showLevelsInConsole = true,
    showPrivateMessagesInConsole = true,
    showPrivateMessagesOnScreen = true,
    showLeftPanel = false,
    showLeftExtraPanel = false,
    showRightExtraPanel = false,
    openMaximized = false,
    backgroundFrameRate = 201,
    enableAudio = true,
    enableMusicSound = true,
    musicSoundVolume = 100,
    enableLights = true,
    limitVisibleDimension = false,
    floatingEffect = false,
    ambientLight = 0,
    displayNames = true,
    displayHealth = true,
    displayMana = true,
    displayText = true,
    dontStretchShrink = false,
    turnDelay = 50,
    hotkeyDelay = 70,
    crosshair = 'default',
    enableHighlightMouseTarget = true,
    antialiasingMode = 1,
    shadowFloorIntensity = 30,
    optimizeFps = true,
    forceEffectOptimization = false,
    drawEffectOnTop = false,
    floorViewMode = 1,
    floorFading = 500,
    asyncTxtLoading = false,
    creatureInformationScale = 0,
    staticTextScale = 0,
    animatedTextScale = 0,
    showOutfitsOnList = true,
    setEffectAlphaScroll = 100 ,
    setMissileAlphaScroll = 100 ,
}

local optionsWindow
local optionsButton
local optionsTabBar
local options = {}
local generalPanel
local controlPanel
local consolePanel
local graphicsPanel
local soundPanel
local audioButton
local optionsButtons

local crosshairCombobox
local antialiasingModeCombobox
local floorViewModeCombobox

-- @ Note: kokekanon delete this, before the murge
local repareEvent
local executedRepair = false
-- @
function init()
    for k, v in pairs(defaultOptions) do
        g_settings.setDefault(k, v)
        options[k] = v
    end

    optionsWindow = g_ui.displayUI('options')
    optionsWindow:hide()

    optionsTabBar = optionsWindow:getChildById('optionsTabBar')
    optionsTabBar:setContentWidget(optionsWindow:getChildById('optionsTabContent'))

    g_keyboard.bindKeyDown('Ctrl+Shift+F', function()
        toggleOption('fullscreen')
    end)
    g_keyboard.bindKeyDown('Ctrl+N', toggleDisplays)

    generalPanel = g_ui.loadUI('general')
    optionsTabBar:addTab(tr('Options'), generalPanel, '/images/icons/icon_options')

    controlPanel = g_ui.loadUI('control')
    optionsTabBar:addTab(tr('Controls'), controlPanel, '/images/icons/icon_controls')

    consolePanel = g_ui.loadUI('console')
    optionsTabBar:addTab(tr('Interface'), consolePanel, '/images/icons/icon_interface')

    graphicsPanel = g_ui.loadUI('graphics')
    optionsTabBar:addTab(tr('Graphics'), graphicsPanel, '/images/icons/icon_graphics')

    soundPanel = g_ui.loadUI('audio')
    optionsTabBar:addTab(tr('Sound'), soundPanel, '/images/icons/icon_sound')

    optionsButton = modules.client_topmenu.addTopRightToggleButton('optionsButton', tr('Options'), '/images/topbuttons/button_options',
                                                         toggle)
    audioButton = modules.client_topmenu.addTopRightToggleButton('audioButton', tr('Audio'), '/images/topbuttons/button_mute_up',
                                                       function()
        toggleOption('enableAudio')
    end)

    addEvent(function()
        setup()
    end)
end

function terminate()
    g_keyboard.unbindKeyDown('Ctrl+Shift+F')
    g_keyboard.unbindKeyDown('Ctrl+N')
    optionsWindow:destroy()
    optionsButton:destroy()
    audioButton:destroy()
    -- @ Note: kokekanon delete this, before the murge
    if repareEvent then
        removeEvent(repareEvent)
        repareEvent = nil
    end
    -- @ 
end

function setupOptionsMainButton()
    if optionsButtons then
        return
    end

    optionsButtons = modules.game_mainpanel.addSpecialToggleButton('optionsMainButton', tr('Options'),
                                                                   '/images/options/button_options', toggle,true)
end

function setupComboBox()
    crosshairCombobox = generalPanel:recursiveGetChildById('crosshair')

    crosshairCombobox:addOption('Disabled', 'disabled')
    crosshairCombobox:addOption('Default', 'default')
    crosshairCombobox:addOption('Full', 'full')

    crosshairCombobox.onOptionChange = function(comboBox, option)
        setOption('crosshair', comboBox:getCurrentOption().data)
    end

    antialiasingModeCombobox = graphicsPanel:recursiveGetChildById('antialiasingMode')

    antialiasingModeCombobox:addOption('None', 0)
    antialiasingModeCombobox:addOption('Antialiasing', 1)
    antialiasingModeCombobox:addOption('Smooth Retro', 2)

    antialiasingModeCombobox.onOptionChange = function(comboBox, option)
        setOption('antialiasingMode', comboBox:getCurrentOption().data)
    end

    floorViewModeCombobox = graphicsPanel:recursiveGetChildById('floorViewMode')

    floorViewModeCombobox:addOption('Normal', 0)
    floorViewModeCombobox:addOption('Fade', 1)
    floorViewModeCombobox:addOption('Locked', 2)
    floorViewModeCombobox:addOption('Always', 3)
    floorViewModeCombobox:addOption('Always with transparency', 4)

    floorViewModeCombobox.onOptionChange = function(comboBox, option)
        setOption('floorViewMode', comboBox:getCurrentOption().data)
    end
end

function setup()
    setupComboBox()

    -- load options
    for k, v in pairs(defaultOptions) do
        if type(v) == 'boolean' then
            setOption(k, g_settings.getBoolean(k), true)
        elseif type(v) == 'number' then
            setOption(k, g_settings.getNumber(k), true)
        elseif type(v) == 'string' then
            setOption(k, g_settings.getString(k), true)
        end
    end
end

function toggle()
    if optionsWindow:isVisible() then
        hide()
    else
        show()
    end
end

function show()
    optionsWindow:show()
    optionsWindow:raise()
    optionsWindow:focus()
end

function hide()
    optionsWindow:hide()
end

function toggleDisplays()
    if options['displayNames'] and options['displayHealth'] and options['displayMana'] then
        setOption('displayNames', false)
    elseif options['displayHealth'] then
        setOption('displayHealth', false)
        setOption('displayMana', false)
    else
        if not options['displayNames'] and not options['displayHealth'] then
            setOption('displayNames', true)
        else
            setOption('displayHealth', true)
            setOption('displayMana', true)
        end
    end
end

function toggleOption(key)
    setOption(key, not getOption(key))
end

function setOption(key, value, force)
    if not force and options[key] == value then
        return
    end

    if not modules.game_interface then
        return
    end

    local gameMapPanel = modules.game_interface.getMapPanel()

    if key == 'vsync' then
        g_window.setVerticalSync(value)
    elseif key == 'showOutfitsOnList' then
        CharacterList.updateCharactersAppearances(value)
    elseif key == 'distFromCenScrollbar' then
        local bar = modules.game_healthcircle.optionPanel:recursiveGetChildById('distFromCenScrollbar')
        bar:setText(tr('Distance: %s', bar:recursiveGetChildById('valueBar'):getValue()))
        modules.game_healthcircle.setDistanceFromCenter(bar:recursiveGetChildById('valueBar'):getValue())
    elseif key == 'opacityScrollbar' then
        local bar = modules.game_healthcircle.optionPanel:recursiveGetChildById('opacityScrollbar')
        bar:setText(tr('Opacity: %s', bar:recursiveGetChildById('valueBar'):getValue() / 100))
        modules.game_healthcircle.setCircleOpacity(bar:recursiveGetChildById('valueBar'):getValue() / 100)
    elseif key == 'showFps' then
        modules.client_topmenu.setFpsVisible(value)
    elseif key == 'optimizeFps' then
        g_app.optimize(value)
    elseif key == 'forceEffectOptimization' then
        g_app.forceEffectOptimization(value)
    elseif key == 'drawEffectOnTop' then
        g_app.setDrawEffectOnTop(value)
    elseif key == 'asyncTxtLoading' then
        if g_game.isUsingProtobuf() then
            value = true
        elseif g_app.isEncrypted() then
            local asyncWidget = generalPanel:recursiveGetChildById('asyncTxtLoading')
            asyncWidget:setEnabled(false)
            asyncWidget:setChecked(false)
            return
        end

        g_app.setLoadingAsyncTexture(value)
    elseif key == 'showPing' then
        modules.client_topmenu.setPingVisible(value)
    elseif key == 'fullscreen' then
        g_window.setFullscreen(value)
    elseif key == 'enableAudio' then
        if g_sounds then
            g_sounds.setAudioEnabled(value)
        end
        if value then
            audioButton:setIcon('/images/topbuttons/button_mute_up')
        else
            audioButton:setIcon('/images/topbuttons/button_mute_pressed')
        end
    elseif key == 'enableMusicSound' then
        if g_sounds then
            g_sounds.getChannel(SoundChannels.Music):setEnabled(value)
        end
    elseif key == 'musicSoundVolume' then
        if g_sounds then
            g_sounds.getChannel(SoundChannels.Music):setGain(value / 100)
        end
        soundPanel:recursiveGetChildById('musicSoundVolume'):setText(tr('Music volume: %d', value))
    elseif key == 'showLeftPanel' then
        modules.game_interface.getLeftPanel():setOn(value)
    elseif key == 'showLeftExtraPanel' then
        modules.game_interface.getLeftExtraPanel():setOn(value)
    elseif key == 'showRightExtraPanel' then
        modules.game_interface.getRightExtraPanel():setOn(value)
    elseif key == 'backgroundFrameRate' then
        local text, v = value, value
        if value <= 0 or value >= 201 then
            text = 'max'
            v = 0
        end
        graphicsPanel:recursiveGetChildById('backgroundFrameRate'):setText(tr('Game framerate limit: %s', text))
        g_app.setMaxFps(v)
    elseif key == 'enableLights' then
        gameMapPanel:setDrawLights(value and options['ambientLight'] < 100)
        graphicsPanel:recursiveGetChildById('ambientLight'):setEnabled(value)
    elseif key == 'ambientLight' then
        graphicsPanel:recursiveGetChildById('ambientLight'):setText(string.format('Ambient light: %s%%', value))
        gameMapPanel:setMinimumAmbientLight(value / 100)
        gameMapPanel:setDrawLights(options['enableLights'])
    elseif key == 'shadowFloorIntensity' then
        graphicsPanel:recursiveGetChildById('shadowFloorIntensity'):setText(string.format('Shadow floor Intensity: %s%%', value))
        gameMapPanel:setShadowFloorIntensity(1 - (value / 100))
    elseif key == 'floorFading' then
        graphicsPanel:recursiveGetChildById('floorFading'):setText(string.format('Floor Fading: %s ms', value))
        gameMapPanel:setFloorFading(tonumber(value))
    elseif key == 'creatureInformationScale' then
        if value == 0 then
            value = g_window.getDisplayDensity() - 0.5
        else
            value = value / 2
        end
        g_app.setCreatureInformationScale(math.max(value + 0.5, 1))
        consolePanel:recursiveGetChildById('creatureInformationScale'):setText(string.format('Creature Information Scale: %sx', math.max(value + 0.5, 1)))
        value = value * 2
    elseif key == 'staticTextScale' then
        if value == 0 then
            value = g_window.getDisplayDensity() - 0.5
        else
            value = value / 2
        end
        g_app.setStaticTextScale(math.max(value + 0.5, 1))
        consolePanel:recursiveGetChildById('staticTextScale'):setText(string.format('Message Scale: %sx', math.max(value + 0.5, 1)))
        value = value * 2
    elseif key == 'animatedTextScale' then
        if value == 0 then
            value = g_window.getDisplayDensity() - 0.5
        else
            value = value / 2
        end
        g_app.setAnimatedTextScale(math.max(value + 0.5, 1))
        consolePanel:recursiveGetChildById('animatedTextScale'):setText(
            tr('Animated Message Scale: %sx', math.max(value + 0.5, 1)))
        value = value * 2
    elseif key == 'limitVisibleDimension' then
        gameMapPanel:setLimitVisibleDimension(value)
    elseif key == 'floatingEffect' then
        g_map.setFloatingEffect(value)
    elseif key == 'displayNames' then
        gameMapPanel:setDrawNames(value)
    elseif key == 'displayHealth' then
        gameMapPanel:setDrawHealthBars(value)
    elseif key == 'displayMana' then
        gameMapPanel:setDrawManaBar(value)
    elseif key == 'displayText' then
        g_app.setDrawTexts(value)
    elseif key == 'dontStretchShrink' then
        addEvent(function()
            modules.game_interface.updateStretchShrink()
        end)
    elseif key == 'preciseControl' then
        g_game.setScheduleLastWalk(not value)
    elseif key == 'turnDelay' then
        controlPanel:recursiveGetChildById('turnDelay'):setText(string.format('Turn delay: %sms', value))
    elseif key == 'hotkeyDelay' then
        controlPanel:recursiveGetChildById('hotkeyDelay'):setText(string.format('Hotkey delay: %sms', value))
    elseif key == 'crosshair' then
        local crossPath = '/images/game/crosshair/'
        local newValue = value
        if newValue == 'disabled' then
            newValue = nil
        end
        gameMapPanel:setCrosshairTexture(newValue and crossPath .. newValue or nil)
        crosshairCombobox:setCurrentOptionByData(newValue, true)
    elseif key == 'enableHighlightMouseTarget' then
        gameMapPanel:setDrawHighlightTarget(value)
    elseif key == 'floorShadowing' then
        gameMapPanel:setFloorShadowingFlag(value)
        floorShadowingComboBox:setCurrentOptionByData(value, true)
    elseif key == 'antialiasingMode' then
        gameMapPanel:setAntiAliasingMode(value)
        antialiasingModeCombobox:setCurrentOptionByData(value, true)
    elseif key == 'floorViewMode' then
        gameMapPanel:setFloorViewMode(value)
        floorViewModeCombobox:setCurrentOptionByData(value, true)

        local fadeMode = value == 1
        graphicsPanel:recursiveGetChildById('floorFading'):setEnabled(fadeMode)
    elseif key == 'setEffectAlphaScroll' then
        g_client.setEffectAlpha(value/100)
        consolePanel:recursiveGetChildById('setEffectAlphaScroll'):setText(tr('Opacity Effect: %s%%', value))
    elseif key == 'setMissileAlphaScroll' then
        g_client.setMissileAlpha(value/100)
        consolePanel:recursiveGetChildById('setMissileAlphaScroll'):setText(tr('Opacity Missile: %s%%', value))
    end

    -- change value for keybind updates
    for _, panel in pairs(optionsTabBar:getTabsPanel()) do
        local widget = panel:recursiveGetChildById(key)
        if widget then
            if widget:getStyle().__class == 'UICheckBox' then
                widget:setChecked(value)
            elseif widget:getStyle().__class == 'UIScrollBar' then
                widget:setValue(value)
            elseif widget:recursiveGetChildById('valueBar') then
                widget:recursiveGetChildById('valueBar'):setValue(value)
            end
            break
        end
    end

    g_settings.set(key, value)
    options[key] = value
end

function getOption(key)
    return options[key]
end

function addTab(name, panel, icon)
    optionsTabBar:addTab(name, panel, icon)
end

function removeTab(v)
    if type(v) == 'string' then
        v = optionsTabBar:getTab(v)
    end

    optionsTabBar:removeTab(v)
end

function addButton(name, func, icon)
    optionsTabBar:addButton(name, func, icon)
end

-- @ Note: kokekanon delete this, before the murge
function repairClient()
    if executedRepair then
        return
    end

    g_settings.clearCache()
--[[     if repareEvent then
        removeEvent(repareEvent)
        repareEvent = nil
    end ]]
    repareEvent = scheduleEvent(function()
        g_app.restart()
    end, 1000)

    executedRepair = true
end
-- @

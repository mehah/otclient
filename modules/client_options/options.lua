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
    animatedTextScale = 0
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

local crosshairCombobox
local antialiasingModeCombobox
local floorViewModeCombobox

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
    optionsTabBar:addTab(tr('General'), generalPanel, '/images/optionstab/game')

    controlPanel = g_ui.loadUI('control')
    optionsTabBar:addTab(tr('Control'), controlPanel, '/images/optionstab/controls')

    consolePanel = g_ui.loadUI('console')
    optionsTabBar:addTab(tr('Console'), consolePanel, '/images/optionstab/console')

    graphicsPanel = g_ui.loadUI('graphics')
    optionsTabBar:addTab(tr('Graphics'), graphicsPanel, '/images/optionstab/graphics')

    soundPanel = g_ui.loadUI('audio')
    optionsTabBar:addTab(tr('Audio'), soundPanel, '/images/optionstab/audio')

    optionsButton = modules.client_topmenu.addLeftButton('optionsButton', tr('Options'), '/images/topbuttons/options',
                                                         toggle)
    audioButton = modules.client_topmenu.addLeftButton('audioButton', tr('Audio'), '/images/topbuttons/audio',
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

    local gameMapPanel = modules.game_interface.getMapPanel()

    if key == 'vsync' then
        g_window.setVerticalSync(value)
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
            local asyncWidget = graphicsPanel:getChildById('asyncTxtLoading')
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
            audioButton:setIcon('/images/topbuttons/audio')
        else
            audioButton:setIcon('/images/topbuttons/audio_mute')
        end
    elseif key == 'enableMusicSound' then
        if g_sounds then
            g_sounds.getChannel(SoundChannels.Music):setEnabled(value)
        end
    elseif key == 'musicSoundVolume' then
        if g_sounds then
            g_sounds.getChannel(SoundChannels.Music):setGain(value / 100)
        end
        soundPanel:getChildById('musicSoundVolumeLabel'):setText(tr('Music volume: %d', value))
    elseif key == 'showLeftPanel' then
        modules.game_interface.getLeftPanel():setOn(value)
    elseif key == 'showRightExtraPanel' then
        modules.game_interface.getRightExtraPanel():setOn(value)
    elseif key == 'backgroundFrameRate' then
        local text, v = value, value
        if value <= 0 or value >= 201 then
            text = 'max'
            v = 0
        end
        graphicsPanel:getChildById('backgroundFrameRateLabel'):setText(tr('Game framerate limit: %s', text))
        g_app.setMaxFps(v)
    elseif key == 'enableLights' then
        gameMapPanel:setDrawLights(value and options['ambientLight'] < 100)
        graphicsPanel:getChildById('ambientLight'):setEnabled(value)
        graphicsPanel:getChildById('ambientLightLabel'):setEnabled(value)
    elseif key == 'ambientLight' then
        graphicsPanel:getChildById('ambientLightLabel'):setText(tr('Ambient light: %s%%', value))
        gameMapPanel:setMinimumAmbientLight(value / 100)
        gameMapPanel:setDrawLights(options['enableLights'])
    elseif key == 'shadowFloorIntensity' then
        graphicsPanel:getChildById('shadowFloorIntensityLevel'):setText(tr('Shadow floor Intensity: %s%%', value))
        gameMapPanel:setShadowFloorIntensity(1 - (value / 100))
    elseif key == 'floorFading' then
        graphicsPanel:getChildById('floorFadingLabel'):setText(tr('Floor Fading: %s ms', value))
        gameMapPanel:setFloorFading(tonumber(value))
    elseif key == 'creatureInformationScale' then
        if value == 0 then
            value = g_window.getDisplayDensity() - 0.5
        else
            value = value / 2
        end
        g_app.setCreatureInformationScale(math.max(value + 0.5, 1))
        generalPanel:getChildById('creatureInformationScaleLabel'):setText(
            tr('Creature Information Scale: %sx', math.max(value + 0.5, 1)))
        value = value * 2
    elseif key == 'staticTextScale' then
        if value == 0 then
            value = g_window.getDisplayDensity() - 0.5
        else
            value = value / 2
        end
        g_app.setStaticTextScale(math.max(value + 0.5, 1))
        generalPanel:getChildById('staticTextScaleLabel'):setText(tr('Message Scale: %sx', math.max(value + 0.5, 1)))
        value = value * 2
    elseif key == 'animatedTextScale' then
        if value == 0 then
            value = g_window.getDisplayDensity() - 0.5
        else
            value = value / 2
        end
        g_app.setAnimatedTextScale(math.max(value + 0.5, 1))
        generalPanel:getChildById('animatedTextScaleLabel'):setText(
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
        controlPanel:getChildById('turnDelayLabel'):setText(tr('Turn delay: %sms', value))
    elseif key == 'hotkeyDelay' then
        controlPanel:getChildById('hotkeyDelayLabel'):setText(tr('Hotkey delay: %sms', value))
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
        graphicsPanel:getChildById('floorFading'):setEnabled(fadeMode)
        graphicsPanel:getChildById('floorFadingLabel'):setEnabled(fadeMode)
    end

    -- change value for keybind updates
    for _, panel in pairs(optionsTabBar:getTabsPanel()) do
        local widget = panel:recursiveGetChildById(key)
        if widget then
            if widget:getStyle().__class == 'UICheckBox' then
                widget:setChecked(value)
            elseif widget:getStyle().__class == 'UIScrollBar' then
                widget:setValue(value)
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

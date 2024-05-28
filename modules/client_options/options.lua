local options = dofile("data_options")

local panels = {
    generalPanel = nil,
    controlPanel = nil,
    consolePanel = nil,
    graphicsPanel = nil,
    soundPanel = nil,
    gameMapPanel = nil
}

local extraWidgets = {
    audioButton = nil,
    optionsButton = nil,
    optionsButtons = nil
}

local function toggleDisplays()
    if options['displayNames'].value and options['displayHealth'].value and options['displayMana'].value then
        setOption('displayNames', false)
    elseif options['displayHealth'].value then
        setOption('displayHealth', false)
        setOption('displayMana', false)
    else
        if not options['displayNames'].value and not options['displayHealth'].value then
            setOption('displayNames', true)
        else
            setOption('displayHealth', true)
            setOption('displayMana', true)
        end
    end
end

local function toggleOption(key)
    setOption(key, not getOption(key))
end

local function setupComboBox()
    local crosshairCombo = panels.generalPanel:recursiveGetChildById('crosshair')
    local antialiasingModeCombobox = panels.graphicsPanel:recursiveGetChildById('antialiasingMode')
    local floorViewModeCombobox = panels.graphicsPanel:recursiveGetChildById('floorViewMode')

    for k, v in pairs({ { 'Disabled', 'disabled' }, { 'Default', 'default' }, { 'Full', 'full' } }) do
        crosshairCombo:addOption(v[1], v[2])
    end

    crosshairCombo.onOptionChange = function(comboBox, option)
        setOption('crosshair', comboBox:getCurrentOption().data)
    end


    for k, t in pairs({ 'None', 'Antialiasing', 'Smooth Retro' }) do
        antialiasingModeCombobox:addOption(t, k - 1)
    end

    antialiasingModeCombobox.onOptionChange = function(comboBox, option)
        setOption('antialiasingMode', comboBox:getCurrentOption().data)
    end


    for k, t in pairs({ 'Normal', 'Fade', 'Locked', 'Always', 'Always with transparency' }) do
        floorViewModeCombobox:addOption(t, k - 1)
    end

    floorViewModeCombobox.onOptionChange = function(comboBox, option)
        setOption('floorViewMode', comboBox:getCurrentOption().data)
    end
end

local function setup()
    panels.gameMapPanel = modules.game_interface.getMapPanel()

    setupComboBox()

    -- load options
    for k, obj in pairs(options) do
        local v = obj.value

        if type(v) == 'boolean' then
            setOption(k, g_settings.getBoolean(k), true)
        elseif type(v) == 'number' then
            setOption(k, g_settings.getNumber(k), true)
        elseif type(v) == 'string' then
            setOption(k, g_settings.getString(k), true)
        end
    end
end


controller = Controller:new()
controller:setUI('options')
controller:bindKeyDown('Ctrl+Shift+F', function() toggleOption('fullscreen') end)
controller:bindKeyDown('Ctrl+N', toggleDisplays)

function controller:onInit()
    for k, obj in pairs(options) do
        if type(obj) ~= "table" then
            obj = { value = v }
            options[k] = obj
        end
        g_settings.setDefault(k, obj.value)
    end

    extraWidgets.optionsButton = modules.client_topmenu.addTopRightToggleButton('optionsButton', tr('Options'),
        '/images/topbuttons/button_options', toggle)
    extraWidgets.audioButton = modules.client_topmenu.addTopRightToggleButton('audioButton', tr('Audio'),
        '/images/topbuttons/button_mute_up', function() toggleOption('enableAudio') end)

    panels.generalPanel = g_ui.loadUI('general')
    panels.controlPanel = g_ui.loadUI('control')
    panels.consolePanel = g_ui.loadUI('console')
    panels.graphicsPanel = g_ui.loadUI('graphics')
    panels.soundPanel = g_ui.loadUI('audio')

    self.ui:hide()
    self.ui.optionsTabBar:setContentWidget(self.ui.optionsTabContent)
    self.ui.optionsTabBar:addTab(tr('Options'), panels.generalPanel, '/images/icons/icon_options')
    self.ui.optionsTabBar:addTab(tr('Controls'), panels.controlPanel, '/images/icons/icon_controls')
    self.ui.optionsTabBar:addTab(tr('Interface'), panels.consolePanel, '/images/icons/icon_interface')
    self.ui.optionsTabBar:addTab(tr('Graphics'), panels.graphicsPanel, '/images/icons/icon_graphics')
    self.ui.optionsTabBar:addTab(tr('Sound'), panels.soundPanel, '/images/icons/icon_sound')

    addEvent(setup)
end

function controller:onTerminate()
    extraWidgets.optionsButton:destroy()
    extraWidgets.audioButton:destroy()
    panels = nil
    extraWidgets = nil
end

function setOption(key, value, force)
    if not modules.game_interface then
        return
    end

    local option = options[key]
    if option == nil or not force and option.value == value then
        return
    end

    if option.action then
        option.action(value, options, controller, panels, extraWidgets)
    end


    -- change value for keybind updates
    for _, panel in pairs(controller.ui.optionsTabBar:getTabsPanel()) do
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

    option.value = value
    g_settings.set(key, value)
end

function setupOptionsMainButton()
    if extraWidgets.optionsButtons then
        return
    end

    extraWidgets.optionsButtons = modules.game_mainpanel.addSpecialToggleButton('optionsMainButton', tr('Options'),
        '/images/options/button_options', toggle, true)
end

function getOption(key)
    return options[key].value
end

function show()
    controller.ui:show()
    controller.ui:raise()
    controller.ui:focus()
end

function hide()
    controller.ui:hide()
end

function toggle()
    if controller.ui:isVisible() then
        hide()
    else
        show()
    end
end

function addTab(name, panel, icon)
    controller.ui.optionsTabBar:addTab(name, panel, icon)
end

function removeTab(v)
    if type(v) == 'string' then
        v = controller.ui.optionsTabBar:getTab(v)
    end

    controller.ui.optionsTabBar:removeTab(v)
end

function addButton(name, func, icon)
    controller.ui.optionsTabBar:addButton(name, func, icon)
end

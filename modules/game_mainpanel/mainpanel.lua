function init()

    healthManaController:init()

    optionsController:init()
end

function terminate()

    healthManaController:terminate()

    optionsController:terminate()
end

local standModeBox
local chaseModeBox
local optionsAmount = 0
local specialsAmount = 0
local storeAmount = 0

local chaseModeRadioGroup

function reloadMainPanelSizes()
    local main = modules.game_interface.getMainRightPanel()
    local rightPanel = modules.game_interface.getRightPanel()

    if not main or not rightPanel then
        return
    end

    local height = 4
    for _, panel in ipairs(main:getChildren()) do
        if panel.panelHeight ~= nil then
            if panel:isVisible() then
                panel:setHeight(panel.panelHeight)
                height = height + panel.panelHeight

                if panel:getId() == 'mainoptionspanel' and panel:isOn() then
                    local currentOptionsAmount = math.ceil(optionsAmount / 5)
                    local optionsHeight = (currentOptionsAmount * 28) + 3
                    local currentSpecialsAmount = math.ceil(specialsAmount / 2)
                    local specialsHeight = (currentSpecialsAmount * 28) + 3
                    local maxPanelHeight = math.max(optionsHeight, specialsHeight)

                    if storeAmount > 1 then
                        local currentStoreAmount = math.ceil(storeAmount / 1)
                        local storeHeight = (currentStoreAmount * 20) + 3
                        panel.onPanel.store:setHeight(storeHeight)
                        maxPanelHeight = math.max(maxPanelHeight, storeHeight)
                    end

                    panel:setHeight(panel:getHeight() + maxPanelHeight)
                    height = height + maxPanelHeight
                    if storeAmount >= 2 then
                        height = height + 15
                    end
                end
            else
                panel:setHeight(0)
            end
        end
    end

    main:setHeight(height)
    rightPanel:fitAll()
end

-- @ Options
local optionsShrink = false
local function refreshOptionsSizes()
    if optionsShrink then
        optionsController.ui:setOn(false)
        optionsController.ui.onPanel:hide()
        optionsController.ui.offPanel:show()
    else
        optionsController.ui:setOn(true)
        optionsController.ui.onPanel:show()
        optionsController.ui.offPanel:hide()
    end
    reloadMainPanelSizes()
end

local function createButton_large(id, description, image, callback, special, front)
    -- fast version
    local panel = optionsController.ui.onPanel.store

    storeAmount = storeAmount + 1

    local button = panel:getChildById(id)
    if not button then
        button = g_ui.createWidget('largeToggleButton')
        if front then
            panel:insertChild(1, button)
        else
            panel:addChild(button)
        end
    end
    button:setId(id)
    button:setTooltip(description)
    button:setImageSource(image)
    button:setImageClip('0 0 108 20')
    button.onMouseRelease = function(widget, mousePos, mouseButton)
        if widget:containsPoint(mousePos) and mouseButton ~= MouseMidButton then
            callback()
            return true
        end
    end

    return button
end

local function createButton(id, description, image, callback, special, front, index)
    local panel
    if special then
        panel = optionsController.ui.onPanel.specials
        specialsAmount = specialsAmount + 1
    else
        panel = optionsController.ui.onPanel.options
        optionsAmount = optionsAmount + 1
    end

    local button = panel:getChildById(id)
    if not button then
        button = g_ui.createWidget('MainToggleButton')
        if front then
            panel:insertChild(1, button)
        else
            panel:addChild(button)
        end
    end

    button:setId(id)
    button:setTooltip(description)
    button:setSize('20 20')
    button:setImageSource(image)
    button:setImageClip('0 0 20 20')
    button.onMouseRelease = function(widget, mousePos, mouseButton)
        if widget:containsPoint(mousePos) and mouseButton ~= MouseMidButton then
            callback()
            return true
        end
    end
    if not button.index and type(index) == 'number' then
        button.index = index or 1000
    end

    refreshOptionsSizes()
    return button
end

optionsController = Controller:new()
optionsController:setUI('mainoptionspanel', modules.game_interface.getMainRightPanel())

function optionsController:onInit()
end

function optionsController:onTerminate()
end

function optionsController:onGameStart()
    optionsShrink = g_settings.getBoolean('mainpanel_shrink_options')
    refreshOptionsSizes()
    modules.game_interface.setupOptionsMainButton()
    modules.client_options.setupOptionsMainButton()
    local getOptionsPanel = optionsController.ui.onPanel.options
    local children = getOptionsPanel:getChildren()
    table.sort(children, function(a, b)
        return (a.index or 1000) < (b.index or 1000)
    end)
    getOptionsPanel:reorderChildren(children)
end

function optionsController:onGameEnd()
end

function changeOptionsSize()
    optionsShrink = not optionsShrink
    g_settings.set('mainpanel_shrink_options', optionsShrink)
    refreshOptionsSizes()
end

function addToggleButton(id, description, image, callback, front, index)
    return createButton(id, description, image, callback, false, front, index)
end

function addSpecialToggleButton(id, description, image, callback, front, index)
    return createButton(id, description, image, callback, true, front, index)
end

function addStoreButton(id, description, image, callback, front)
    return createButton_large(id, description, image, callback, true, front)
end
-- @ End of Options

-- @ Health/Mana
local function healthManaEvent()
    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    healthManaController.ui.health.text:setText(player:getHealth())
    healthManaController.ui.health.current:setWidth(math.max(12, math.ceil(
        (healthManaController.ui.health.total:getWidth() * player:getHealth()) / player:getMaxHealth())))

    healthManaController.ui.mana.text:setText(player:getMana())
    healthManaController.ui.mana.current:setWidth(math.max(12, math.ceil(
        (healthManaController.ui.mana.total:getWidth() * player:getMana()) / player:getMaxMana())))
end

healthManaController = Controller:new()
healthManaController:setUI('mainhealthmanapanel', modules.game_interface.getMainRightPanel())

local healthManaControllerEvents = healthManaController:addEvent(LocalPlayer, {
    onHealthChange = healthManaEvent,
    onManaChange = healthManaEvent
})

function healthManaController:onInit()
end

function healthManaController:onTerminate()
end

function healthManaController:onGameStart()
    healthManaControllerEvents:connect()
    healthManaControllerEvents:execute('onHealthChange')
    healthManaControllerEvents:execute('onManaChange')
end

function healthManaController:onGameEnd()
    healthManaControllerEvents:disconnect()
end
-- @ End of Health/Mana

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
    
    local height = 1
    local function calculatePanelHeight(icon_count, max_icons_per_row, icon_size)
        local rows = math.ceil(icon_count / max_icons_per_row)
        return (rows * icon_size) + (rows * 3)
    end

    for _, panel in ipairs(main:getChildren()) do
        if panel.panelHeight ~= nil then
            if panel:isVisible() then
                panel:setHeight(panel.panelHeight)
                height = height + panel.panelHeight

                if panel:getId() == 'mainoptionspanel' and panel:isOn() then
             
                    local function calculatePanelHeightFromPanel(panel, icon_width, icon_height, max_icons_per_row)
                        local icon_count = 0
                        for _, icon in ipairs(panel:getChildren()) do
                            if icon:isVisible() then
                                icon_count = icon_count + 1
                            end
                        end

                        local rows = math.ceil(icon_count / max_icons_per_row)
                        return (rows * icon_height) + (rows * 3) 
                    end

                    local options_panel = optionsController.ui.onPanel.options
                    local options_height = calculatePanelHeightFromPanel(options_panel, 18, 18, 5) 

                    local specials_panel = optionsController.ui.onPanel.specials
                    local specials_height = calculatePanelHeightFromPanel(specials_panel, 18, 18, 2) 

                    local max_panel_height = math.max(options_height, specials_height)
                    panel:setHeight(panel:getHeight() + max_panel_height)
                    height = height + options_height

                    local store_panel = panel.onPanel.store
                    local store_height = calculatePanelHeightFromPanel(store_panel, 18, 18, 1) 

                    store_panel:setHeight(store_height)
                    height = height + store_height

                    if store_panel:getChildCount() >= 2 then
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
    createButton_large('Store shop', tr('Store shop'), '/images/options/store_large', toggleStore,
    false, 8)

end

function toggleStore()
    if g_game.getFeature(GamePurseSlot) then
        modules.game_store.toggle()
    else
        modules.game_shop.toggle() --game_shopv8
    end
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


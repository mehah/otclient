-- private variables
local topMenu
local rightButtonsPanel
local leftButtonsPanel
local rightGameButtonsPanel
local topLeftTogglesPanel
local topLeftButtonsPanel
local topLeftOnlinePlayersLabel

local topLeftDiscordStreamersLabel
local topLeftYoutubeViewersLabel
local topLeftYoutubeStreamersLabel
local fpsLabel
local pingLabel
local topLeftYoutubeLink
local topLeftDiscordLink
local url_discord = ""
local url_youtube = ""
local lastSyncValue = -1
local fpsEvent = nil
local fpsMin = -1;
local fpsMax = -1;
local pingPanel
local MainPingPanel
local mainFpsPanel
local fpsPanel2
local PingWidget
local pingImg

local zoomInButton = nil
local zoomOutButton = nil
local zoomLevel = 2

local managerAccountsButton
-- private functions
local function addButton(id, description, icon, callback, panel, toggle, front)
    local class
    if toggle then
        class = 'MainToggleButton'
    else
        class = 'Button'
    end

    local button = panel:getChildById(id)
    if not button then
        button = g_ui.createWidget(class)
        if front then
            panel:insertChild(1, button)
        else
            panel:addChild(button)
        end
    end
    button:setId(id)
    button:setTooltip(description)
    if toggle then
        button:setIcon(resolvepath(icon, 3))
    else
        button:setText(description)
    end
    button.onMouseRelease = function(widget, mousePos, mouseButton)
        if widget:containsPoint(mousePos) and mouseButton ~= MouseMidButton then
            callback()
            return true
        end
    end
    return button
end

local function updateZoomButtons()
    if zoomInButton then
        zoomInButton:setEnabled(zoomLevel < 6)
    end
    if zoomOutButton then
        zoomOutButton:setEnabled(zoomLevel > 1.5)
    end
end

local function setZoom(value)
    local oldValue = zoomLevel
    zoomLevel = math.max(1.5, math.min(6, value))
    modules.client_options.setOption('hudScale', zoomLevel)
    updateZoomButtons()
    return oldValue ~= zoomLevel
end

-- public functions
function init()
    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline,
        onPingBack = updatePing
    })
    connect(g_app, {
        onFps = updateFps
    })

    topMenu = g_ui.displayUI('topmenu')

    topLeftButtonsPanel = topMenu:getChildById('topLeftButtonsPanel')
    topLeftTogglesPanel = topMenu:getChildById('topLeftTogglesPanel')
    rightButtonsPanel = topMenu:getChildById('rightButtonsPanel')
    leftButtonsPanel = topMenu:getChildById('leftButtonsPanel')
    rightGameButtonsPanel = topMenu:getChildById('rightGameButtonsPanel')
    pingLabel = topMenu:getChildById('pingLabel')
    fpsLabel = topMenu:getChildById('fpsLabel')

    topLeftOnlinePlayersLabel = topMenu:recursiveGetChildById('topLeftOnlinePlayersLabel')

    topLeftDiscordStreamersLabel = topMenu:recursiveGetChildById('topLeftDiscordStreamersLabel')
    topLeftYoutubeViewersLabel = topMenu:recursiveGetChildById('topLeftYoutubeViewersLabel')
    topLeftYoutubeStreamersLabel = topMenu:recursiveGetChildById('topLeftYoutubeStreamersLabel')

    topLeftYoutubeLink = topMenu:recursiveGetChildById('youtubeIcon')
    topLeftDiscordLink = topMenu:recursiveGetChildById('discordIcon')

    Keybind.new("UI", "Toggle Top Menu", "Ctrl+Shift+T", "")
    Keybind.bind("UI", "Toggle Top Menu", {
      {
        type = KEY_DOWN,
        callback = toggle,
      }
    })
    if Services.websites then
        managerAccountsButton = modules.client_topmenu.addTopRightRegularButton('hotkeysButton', tr('Manage Account'),
            nil, openManagerAccounts)
    end
    if g_platform.isMobile() then
        zoomInButton = modules.client_topmenu.addLeftToggleButton('zoomInButton', 'Zoom In',
            '/images/topbuttons/zoomin', function()
                setZoom(zoomLevel + 0.5)
            end)

        zoomOutButton = modules.client_topmenu.addLeftToggleButton('zoomOutButton', 'Zoom Out',
            '/images/topbuttons/zoomout', function()
                setZoom(zoomLevel - 0.5)
            end)
        updateZoomButtons()
    end
    if g_game.isOnline() then
        online()
    end
end

function terminate()
    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline,
        onPingBack = updatePing
    })
    disconnect(g_app, {
        onFps = updateFps
    })

    topMenu:destroy()
    if PingWidget and not PingWidget:isDestroyed() then
        PingWidget:destroy()
        PingWidget = nil
    end
    if managerAccountsButton then
        managerAccountsButton:destroy()
        managerAccountsButton = nil
    end
    if g_platform.isMobile() then
        if zoomInButton and not zoomOutButton:isDestroyed() then
            zoomInButton:destroy()
            zoomInButton= nil
        end
        if zoomOutButton and not zoomOutButton:isDestroyed() then
            zoomOutButton:destroy()
            zoomOutButton= nil
        end
    end

    Keybind.delete("UI", "Toggle Top Menu")
end

function hide()
    topMenu:hide()
    modules.game_interface.getRootPanel():addAnchor(AnchorTop, 'parent', AnchorTop)
end

function show()
    topMenu:show()
    topMenu:raise()
    topMenu:focus()
end

function online()
    showGameButtons()

    addEvent(function()
        hide()
        local showPing = modules.client_options.getOption('showPing')
        local pingFeatureAvailable = g_game.getFeature(GameClientPing) or g_game.getFeature(GameExtendedClientPing)
        
        if not PingWidget then
            PingWidget = g_ui.loadUI("pingFps", modules.game_interface.getMapPanel())
            MainPingPanel = g_ui.createWidget("testPingPanel", PingWidget:getChildByIndex(1))
            MainPingPanel:setId("ping")
            
            pingImg = MainPingPanel:getChildByIndex(1)
            pingPanel = MainPingPanel:getChildByIndex(2)
            
            mainFpsPanel = g_ui.createWidget("testPingPanel", PingWidget:getChildByIndex(2))
            mainFpsPanel:setId("fps")
            fpsPanel2 = mainFpsPanel:getChildByIndex(2)
        end

        if showPing and pingFeatureAvailable then
            pingLabel:show()
            if pingPanel then
                pingPanel:show()
                pingImg:show()
            end
        else
            pingLabel:hide()
            if pingPanel then
                pingPanel:hide()
                pingImg:hide()
            end
        end

        pingImg:setVisible(showPing)
        pingPanel:setVisible(showPing)
        
        local showFps = modules.client_options.getOption('showFps')
        fpsPanel2:setVisible(showFps)
    end)
end

function offline()
    hideGameButtons()
    pingLabel:hide()
    if pingPanel then
        pingPanel:hide()
        pingImg:hide()
    end
    fpsMin = -1
end

function updateFps(fps)
    if fpsLabel:isVisible() then -- for the time being retained for the extended view
        local text = 'FPS ' .. fps
        if g_game.isOnline() then
            local vsync = modules.client_options.getOption('vsync')
            if fpsEvent == nil and lastSyncValue ~= vsync then
                fpsEvent = scheduleEvent(function()
                    fpsMin = -1
                    lastSyncValue = vsync
                    fpsEvent = nil
                end, 2000)
            end

            if fpsMin == -1 then
                fpsMin = fps
                fpsMax = fps
            end

            if fps > fpsMax then
                fpsMax = fps
            end

            if fps < fpsMin then
                fpsMin = fps
            end

            local midFps = math.floor((fpsMin + fpsMax) / 2)
            fpsLabel:setTooltip('Min: ' .. fpsMin .. '\nMid: ' .. midFps .. '\nMax: ' .. fpsMax)
        else
            fpsLabel:removeTooltip()
        end
        fpsLabel:setText(text)
    end

    local text = fps .. ' fps'
    if fpsPanel2 and fpsPanel2:isVisible() then
        if g_game.isOnline() then
            fpsPanel2:setText(text)
        end
    end

end

function updatePing(ping)
    if pingLabel:isVisible() then -- for the time being retained for the extended view

        local text = 'Ping: '
        local color
        if ping < 0 then
            text = text .. '??'
            color = 'yellow'
        else
            text = text .. ping .. ' ms'
            if ping >= 500 then
                color = 'red'
            elseif ping >= 250 then
                color = 'yellow'
            else
                color = 'green'
            end
        end
        pingLabel:setColor(color)
        pingLabel:setText(text)
    end
    if pingPanel and pingPanel:isVisible() then

        local text
        local imagen
        if ping < 0 then
            text = 'High lag (??)'
            imagen = nil
        elseif ping >= 500 then
            text = 'High lag (' .. ping .. ' ms)'
            imagen = '/images/ui/high_ping'
        elseif ping >= 250 then
            text = 'Medium lag (' .. ping .. ' ms)'
            imagen = '/images/ui/medium_ping'
        else
            text = 'Low lag (' .. ping .. ' ms)'
            imagen = '/images/ui/low_ping'
        end

        pingImg:setImageSource(imagen)
        pingPanel:setText(text)
    end
end

function setPingVisible(enable)
    pingLabel:setVisible(enable)
    if pingPanel then
        pingPanel:setVisible(enable)
        pingImg:setVisible(enable)
    end
end

function setFpsVisible(enable)
    fpsLabel:setVisible(enable)
    if fpsPanel2 then
        fpsPanel2:setVisible(enable)
    end
end

function setPlayersOnline(value)
    topLeftOnlinePlayersLabel:setText(value .. " " .. tr('players online'))
end
function setDiscordStreams(value)
    topLeftDiscordStreamersLabel:setText(value)
end

function setYoutubeStreams(value)
    topLeftYoutubeStreamersLabel:setText(value)
end
function setYoutubeViewers(value)
    topLeftYoutubeViewersLabel:setText(value)
end

function setLinkYoutube(value)

    url_youtube = value
    topLeftYoutubeLink.onClick = function()
        if url_youtube then
            g_platform.openUrl(url_youtube)
        end
    end

end

function setLinkDiscord(value)

    url_discord = value
    topLeftDiscordLink.onClick = function()
        if url_discord then
            g_platform.openUrl(url_discord)
        end
    end

end

function addLeftButton(id, description, icon, callback, front)
    return addButton(id, description, icon, callback, leftButtonsPanel, false, front)
end

function addLeftToggleButton(id, description, icon, callback, front)
    return addButton(id, description, icon, callback, leftButtonsPanel, true, front)
end

function addRightButton(id, description, icon, callback, front)
    return addButton(id, description, icon, callback, topLeftTogglesPanel, false, front)
end

function addRightToggleButton(id, description, icon, callback, front)
    return addButton(id, description, icon, callback, rightButtonsPanel, true, front)
end

function addLeftGameButton(id, description, icon, callback, front, index)
    if not g_modules.getModule("game_mainpanel"):isLoaded() then
        -- Temp fix. game_mainpanel is not loaded if called from a client_XXX.
        scheduleEvent(function()
            return modules.game_mainpanel.addSpecialToggleButton(id, description, icon, callback, front, index)
        end, 100)
    else
        return modules.game_mainpanel.addSpecialToggleButton(id, description, icon, callback, front, index)

    end
end

function addLeftGameToggleButton(id, description, icon, callback, front, index)
    if not g_modules.getModule("game_mainpanel"):isLoaded() then
        -- Temp fix. game_mainpanel is not loaded if called from a client_XXX.
        scheduleEvent(function()
            return modules.game_mainpanel.addSpecialToggleButton(id, description, icon, callback, front, index)
        end, 100)
    else
        return modules.game_mainpanel.addSpecialToggleButton(id, description, icon, callback, front, index)

    end
end

function addRightGameButton(id, description, icon, callback, front, index)
    if not g_modules.getModule("game_mainpanel"):isLoaded() then
        -- Temp fix. game_mainpanel is not loaded if called from a client_XXX.
        scheduleEvent(function()
            return modules.game_mainpanel.addToggleButton(id, description, icon, callback, front, index)
        end, 100)
    else
        return modules.game_mainpanel.addToggleButton(id, description, icon, callback, front, index)

    end
end

function addRightGameToggleButton(id, description, icon, callback, front, index)
    if not g_modules.getModule("game_mainpanel"):isLoaded() then
        -- Temp fix. game_mainpanel is not loaded if called from a client_XXX.
        scheduleEvent(function()
            return modules.game_mainpanel.addToggleButton(id, description, icon, callback, front, index)
        end, 100)
    else
        return modules.game_mainpanel.addToggleButton(id, description, icon, callback, front, index)

    end

end

function addTopRightRegularButton(id, description, icon, callback, front)
    return addButton(id, description, icon, callback, topLeftButtonsPanel, false, front)
end

function addTopRightToggleButton(id, description, icon, callback, front)
    return addButton(id, description, icon, callback, topLeftTogglesPanel, true, front)
end

function showGameButtons()

    rightGameButtonsPanel:show()
end

function hideGameButtons()

    rightGameButtonsPanel:hide()
end

function getButton(id)
    return topMenu:recursiveGetChildById(id)
end

function getTopMenu()
    return topMenu
end

function getRightGameButtonsPanel()
    return topLeftTogglesPanel
end

function toggle()
    if not topMenu then
        return
    end

    if topMenu:isVisible() then
        hide()
    else
        show()
    end
end

function openManagerAccounts()
    if Services.websites then
        g_platform.openUrl(Services.websites)
    end

end

function extendedView(extendedView)
    if not topMenu then
        return
    end
    topMenu:breakAnchors()
    if extendedView then
        topMenu:show()
        topMenu:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        topMenu:addAnchor(AnchorRight, 'parent', AnchorRight)
        modules.game_interface.getRootPanel():addAnchor(AnchorTop, 'topMenu', AnchorBottom)
        pingLabel:setVisible(false)
        fpsLabel:setVisible(false)
        topMenu.topLeftOnlinePlayers:hide()
        topMenu.topLeftDiscord:setWidth(0)
        topMenu.topLeftYoutube:setWidth(0)
        topMenu.topLeftDiscord:hide()
        topMenu.topLeftYoutube:hide()
    else
        if g_game.isOnline() then
            topMenu:hide()
        end
        topMenu:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
        modules.game_interface.getRootPanel():addAnchor(AnchorTop, 'parent', AnchorTop)
        topMenu:setWidth(1020)
        topMenu.topLeftDiscord:setWidth(110)
        topMenu.topLeftYoutube:setWidth(100)
        topMenu.topLeftOnlinePlayers:show()
        topMenu.topLeftDiscord:show()
        topMenu.topLeftYoutube:show()
    end
end

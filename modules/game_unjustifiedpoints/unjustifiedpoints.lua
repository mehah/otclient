unjustifiedPointsWindow = nil
unjustifiedPointsButton = nil
contentsPanel = nil

openPvpSituationsLabel = nil
currentSkullWidget = nil
skullTimeLabel = nil

dayProgressBar = nil
weekProgressBar = nil
monthProgressBar = nil

dayProgressBarBackground = nil
weekProgressBarBackground = nil
monthProgressBarBackground = nil

daySkullWidget = nil
weekSkullWidget = nil
monthSkullWidget = nil

function init()
    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline,
        onUnjustifiedPointsChange = onUnjustifiedPointsChange,
        onOpenPvpSituationsChange = onOpenPvpSituationsChange,
        onAttackingCreatureChange = onAttack
    })
    connect(LocalPlayer, {
        onSkullChange = onSkullChange
    })

    unjustifiedPointsWindow = g_ui.loadUI('unjustifiedpoints')
    unjustifiedPointsWindow:disableResize()
    unjustifiedPointsWindow:setup()

    contentsPanel = unjustifiedPointsWindow:getChildById('contentsPanel')

    -- Set the title and icon in the header elements
    local titleWidget = unjustifiedPointsWindow:getChildById('miniwindowTitle')
    if titleWidget then
        titleWidget:setText('Unjustified Points')
    else
        -- Fallback to old method if miniwindowTitle doesn't exist
        unjustifiedPointsWindow:setText('Unjustified Points')
    end

    local iconWidget = unjustifiedPointsWindow:getChildById('miniwindowIcon')
    if iconWidget then
        iconWidget:setImageSource('/images/icons/icon-unjustified-points-widget')
    end

    openPvpSituationsLabel = contentsPanel:getChildById('openPvpSituationsLabel')
    currentSkullWidget = contentsPanel:getChildById('currentSkullWidget')
    skullTimeLabel = contentsPanel:getChildById('skullTimeLabel')

    dayProgressBar = contentsPanel:getChildById('dayProgressBar')
    weekProgressBar = contentsPanel:getChildById('weekProgressBar')
    monthProgressBar = contentsPanel:getChildById('monthProgressBar')
    
    dayProgressBarBackground = contentsPanel:getChildById('dayProgressBarBackground')
    weekProgressBarBackground = contentsPanel:getChildById('weekProgressBarBackground')
    monthProgressBarBackground = contentsPanel:getChildById('monthProgressBarBackground')
    
    daySkullWidget = contentsPanel:getChildById('daySkullWidget')
    weekSkullWidget = contentsPanel:getChildById('weekSkullWidget')
    monthSkullWidget = contentsPanel:getChildById('monthSkullWidget')

    -- Hide buttons as requested
    local toggleFilterButton = unjustifiedPointsWindow:recursiveGetChildById('toggleFilterButton')
    if toggleFilterButton then
        toggleFilterButton:setVisible(false)
    end
    
    local contextMenuButton = unjustifiedPointsWindow:recursiveGetChildById('contextMenuButton')
    if contextMenuButton then
        contextMenuButton:setVisible(false)
    end
    
    local newWindowButton = unjustifiedPointsWindow:recursiveGetChildById('newWindowButton')
    if newWindowButton then
        newWindowButton:setVisible(false)
    end

    -- Position lockButton where toggleFilterButton was (to the left of minimize button)
    local lockButton = unjustifiedPointsWindow:recursiveGetChildById('lockButton')
    local minimizeButton = unjustifiedPointsWindow:recursiveGetChildById('minimizeButton')
    
    if lockButton and minimizeButton then
        lockButton:breakAnchors()
        lockButton:addAnchor(AnchorTop, minimizeButton:getId(), AnchorTop)
        lockButton:addAnchor(AnchorRight, minimizeButton:getId(), AnchorLeft)
        lockButton:setMarginRight(7)  -- Same margin as toggleFilterButton had
        lockButton:setMarginTop(0)
    end

    if unjustifiedPointsButton then
        unjustifiedPointsButton:setOn(true)
    end

    if g_game.isOnline() then
        online()
    end
end

function terminate()
    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline,
        onUnjustifiedPointsChange = onUnjustifiedPointsChange,
        onOpenPvpSituationsChange = onOpenPvpSituationsChange,
        onAttackingCreatureChange = onOpenPvpSituationsChange
    })
    disconnect(LocalPlayer, {
        onSkullChange = onSkullChange
    })

    unjustifiedPointsWindow:destroy()
    if unjustifiedPointsButton then
        unjustifiedPointsButton:destroy()
        unjustifiedPointsButton = nil
    end
end

function onMiniWindowOpen()
    if unjustifiedPointsButton then
        unjustifiedPointsButton:setOn(true)
    end
end

function onMiniWindowClose()
    if unjustifiedPointsButton then
        unjustifiedPointsButton:setOn(false)
    end
end

function toggle()
    if unjustifiedPointsButton:isOn() then
        unjustifiedPointsWindow:close()
        unjustifiedPointsButton:setOn(false)
    else
        if not unjustifiedPointsWindow:getParent() then
            local panel = modules.game_interface.findContentPanelAvailable(unjustifiedPointsWindow, unjustifiedPointsWindow:getMinimumHeight())
            if not panel then
                return
            end

            panel:addChild(unjustifiedPointsWindow)
        end
        unjustifiedPointsWindow:open()
        unjustifiedPointsButton:setOn(true)
    end
end

function online()
    if g_game.getFeature(GameUnjustifiedPoints) and not unjustifiedPointsButton then
        unjustifiedPointsWindow:setupOnStart() -- load character window configuration
        unjustifiedPointsButton = modules.game_mainpanel.addToggleButton('unjustifiedPointsButton',
        tr('Unjustified Points'), '/images/options/button_frags', toggle)
        unjustifiedPointsButton:setOn(false)
    end

    refresh()
end

function offline()
    if g_game.getFeature(GameUnjustifiedPoints) then
        unjustifiedPointsWindow:setParent(nil, true)
    end
end

function refresh()
    local localPlayer = g_game.getLocalPlayer()

    local unjustifiedPoints = g_game.getUnjustifiedPoints()
    onUnjustifiedPointsChange(unjustifiedPoints)

    onSkullChange(localPlayer, localPlayer:getSkull())
    onOpenPvpSituationsChange(g_game.getOpenPvpSituations())
end

function onSkullChange(localPlayer, skull)
    if not localPlayer:isLocalPlayer() then
        return
    end

    if skull == SkullRed or skull == SkullBlack then
        currentSkullWidget:setIcon(getSkullImagePath(skull))
        currentSkullWidget:setTooltip('Remaining skull time')
    else
        currentSkullWidget:setIcon('')
        currentSkullWidget:setTooltip('You have no skull')
    end

    daySkullWidget:setIcon(getSkullImagePath(getNextSkullId(skull)))
    weekSkullWidget:setIcon(getSkullImagePath(getNextSkullId(skull)))
    monthSkullWidget:setIcon(getSkullImagePath(getNextSkullId(skull)))
end

function onOpenPvpSituationsChange(amount)
    -- This shows the actual open PvP situations count
    local validAmount = tonumber(amount) or 0
    openPvpSituationsLabel:setText('Open: ' .. validAmount)
end

local function getImageByKills(kills, maxKills, period)
    if period == 'day' then
        -- Day: 1/3 or 2/6 of max = green, 2/3 or 4/6 of max = orange, 3/3 or 6/6 of max = red
        if kills <= maxKills / 3 then
            return '/images/ui/unjustified-points-bar-texture-green'
        elseif kills <= maxKills * 2 / 3 then
            return '/images/ui/unjustified-points-bar-texture-yellow'
        else
            return '/images/ui/unjustified-points-bar-texture-red'
        end
    elseif period == 'week' then
        -- Week: up to 2/5 or 4/10 of max = green, 3/5 or 6/10 of max = orange, 4-5/5 or 8-10/10 of max = red
        if kills <= math.floor(maxKills * 2 / 5) then
            return '/images/ui/unjustified-points-bar-texture-green'
        elseif kills <= math.floor(maxKills * 3 / 5) then
            return '/images/ui/unjustified-points-bar-texture-yellow'
        else
            return '/images/ui/unjustified-points-bar-texture-red'
        end
    elseif period == 'month' then
        -- Month: up to 4/10 or 8/20 of max = green, 5-8/10 or 10-16/20 = orange, 9-10/10 or 17-20/20 = red
        if kills <= math.floor(maxKills * 4 / 10) then
            return '/images/ui/unjustified-points-bar-texture-green'
        elseif kills <= math.floor(maxKills * 8 / 10) then
            return '/images/ui/unjustified-points-bar-texture-yellow'
        else
            return '/images/ui/unjustified-points-bar-texture-red'
        end
    end
    
    -- Fallback to green
    return '/images/ui/unjustified-points-bar-texture-green'
end

local function setProgressBarImage(progressBar, progressBarBackground, currentKills, maxKills, tooltip, period)
    -- Set tooltip on both progress bar and background so it's always visible
    progressBar:setTooltip(tooltip)
    if progressBarBackground then
        progressBarBackground:setTooltip(tooltip)
    end
    
    -- If no kills, don't show any colored fill
    if currentKills == 0 then
        progressBar:setImageSource('')
        progressBar:setVisible(false)
        return
    end
    
    progressBar:setVisible(true)
    
    -- Calculate the percentage and set the progress bar width accordingly
    local percentage = currentKills / maxKills
    local backgroundWidth = progressBarBackground:getWidth()
    local foregroundWidth = math.floor(backgroundWidth * percentage)
    
    -- Break current anchors and set fixed width
    progressBar:breakAnchors()
    progressBar:addAnchor(AnchorTop, progressBarBackground:getId(), AnchorTop)
    progressBar:addAnchor(AnchorLeft, progressBarBackground:getId(), AnchorLeft)
    progressBar:setWidth(foregroundWidth)
    progressBar:setHeight(progressBarBackground:getHeight())
    
    -- Get the appropriate colored image for the fill based on period and maxKills
    local imagePath = getImageByKills(currentKills, maxKills, period)
    
    -- Set the foreground (fill) image
    progressBar:setImageSource(imagePath)
    progressBar:setImageBorder(1)
    progressBar:setImageBorderTop(1)
    progressBar:setImageBorderBottom(1)
end

function onUnjustifiedPointsChange(unjustifiedPoints)    
    if unjustifiedPoints.skullTime == 0 then
        skullTimeLabel:setText('0 days')
        skullTimeLabel:setTooltip('No Skull time active')
    else
        skullTimeLabel:setText(unjustifiedPoints.skullTime .. ' days')
        skullTimeLabel:setTooltip('Remaining skull time')
    end

    -- Check if player has red skull to determine max kill thresholds
    local localPlayer = g_game.getLocalPlayer()
    local hasRedBlackSkull = localPlayer and localPlayer:getSkull() == SkullRed or localPlayer:getSkull() == SkullBlack

    -- Set base thresholds: 3 daily, 5 weekly, 10 monthly for red skull
    -- Double these amounts (6, 10, 20) for black skull when player already has red skull
    local maxDayKills = hasRedBlackSkull and 6 or 3
    local maxWeekKills = hasRedBlackSkull and 10 or 5
    local maxMonthKills = hasRedBlackSkull and 20 or 10

    -- Calculate actual kills based on remaining kills vs max kills
    -- If you have 2 kills remaining out of 3 max, you have 1 kill (3-2=1)
    local actualDayKills = math.max(0, maxDayKills - (unjustifiedPoints.killsDayRemaining or maxDayKills))
    local actualWeekKills = math.max(0, maxWeekKills - (unjustifiedPoints.killsWeekRemaining or maxWeekKills))
    local actualMonthKills = math.max(0, maxMonthKills - (unjustifiedPoints.killsMonthRemaining or maxMonthKills))

    -- Day progress bar with background image
    local dayTooltip = string.format('Unjustified points gained during the last 24 hours.\n%i kill%s left.',
                                      unjustifiedPoints.killsDayRemaining,
                                      (unjustifiedPoints.killsDayRemaining == 1 and '' or 's'))
    setProgressBarImage(dayProgressBar, dayProgressBarBackground, actualDayKills, maxDayKills, dayTooltip, 'day')

    -- Week progress bar with background image
    local weekTooltip = string.format('Unjustified points gained during the last 7 days.\n%i kill%s left.',
                                       unjustifiedPoints.killsWeekRemaining,
                                       (unjustifiedPoints.killsWeekRemaining == 1 and '' or 's'))
    setProgressBarImage(weekProgressBar, weekProgressBarBackground, actualWeekKills, maxWeekKills, weekTooltip, 'week')

    -- Month progress bar with background image
    local monthTooltip = string.format('Unjustified points gained during the last 30 days.\n%i kill%s left.',
                                        unjustifiedPoints.killsMonthRemaining,
                                        (unjustifiedPoints.killsMonthRemaining == 1 and '' or 's'))
    setProgressBarImage(monthProgressBar, monthProgressBarBackground, actualMonthKills, maxMonthKills, monthTooltip, 'month')
end

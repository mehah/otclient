local helper = dofile("helpers/helper.lua")

WheelController = Controller:new()
WheelButton = nil

local baseButtonClip = { x = 0, y = 0, width = 322, height = 34 }
local baseButtonClipped = { x = 0, y = 34, width = 322, height = 34 }

WheelController.wheel = {
    clip = baseButtonClipped,
    backdropVocationOverlay = nil,
    borders = {},
    colors = {},
    slots = {},
    currentSelectSlotId = -1,
    hovers = {},
    currentHoverSlot = -1,
    currentPoints = 0,
    extraPoints = 0,
    totalPoints = 0,
    currentSelectSlotData = nil,
    data = {},
    passiveBorders = {
        TL = "/images/game/wheel/backdrop_skillwheel_largebonus_front0_TL.png",
        TR = "/images/game/wheel/backdrop_skillwheel_largebonus_front0_TR.png",
        BL = "/images/game/wheel/backdrop_skillwheel_largebonus_front0_BL.png",
        BR = "/images/game/wheel/backdrop_skillwheel_largebonus_front0_BR.png"
    },
    slotProgressLabel = "0/50",
    dedicationPerk = {
        hitPoints = 0,
        mana = 0,
        cap = 0,
        mitigation = "0%"
    },
    convictionPerks = {},
}
WheelController.gem = {
    clip = baseButtonClip
}
WheelController.fragment = {
    clip = baseButtonClip
}

function WheelController:resetTabs()
    self.wheel.clip = baseButtonClip
    self.gem.clip = baseButtonClip
    self.fragment.clip = baseButtonClip
end

function WheelController:toggleMenu(menu)
    self:resetTabs()
    self.currentTab = menu
    self[menu].clip = baseButtonClipped
end

local quadrantFramesByMaxPoints = {
    [50] = 5,
    [75] = 8,
    [100] = 10,
    [150] = 15,
    [200] = 20
}

local baseWheelColorPath = "/images/game/wheel/wheel-colors/%s/%s_%s.png"
local baseColorSlotPath = "/images/game/wheel/wheel-colors/%s/slot%s/%s.png"

function WheelController.wheel:handleOnHover(slotId)
    WheelController.wheel.currentHoverSlot = slotId
end

function WheelController.wheel:handleSelectSlot(slotId)
    WheelController.wheel.currentSelectSlotId = slotId
    WheelController.wheel.currentSelectSlotData = WheelController.wheel.data[slotId]
    g_logger.info("Selected slot ID: " .. tostring(slotId)) --- IGNORE ---
end

function WheelController:show(skipRequest)
    -- if not g_game.getFeature(GameForgeConvergence) then
    --     return WheelController:hide()
    -- end
    WheelController.wheel.currentSelectSlotId = -1
    WheelController.wheel.currentSelectSlotData = nil
    local player = g_game.getLocalPlayer()
    g_game.openWheelOfDestiny(player:getId())

    local needsReload = not self.ui or self.ui:isDestroyed()
    if needsReload then
        self:loadHtml('game_wheel.html')
    end

    if not self.ui then
        return
    end

    self.ui:centerIn('parent')
    self.ui:show()
    self.ui:raise()
    self.ui:focus()

    if WheelButton then
        WheelButton:setOn(true)
    end
end

function WheelController:hide()
    if not self.ui then
        return
    end

    self.ui:hide()

    if WheelButton then
        WheelButton:setOn(false)
    end
end

function WheelController:toggle()
    if not self.ui or self.ui:isDestroyed() then
        self:show()
        return
    end

    if self.ui:isVisible() then
        self:hide()
    else
        self:show()
    end
end

function WheelController:onInit()
    self:registerEvents(g_game, {
        onWheelOfDestinyOpenWindow = onWheelOfDestinyOpenWindow
    })

    if not WheelButton then
        WheelButton = modules.game_mainpanel.addToggleButton('WheelButton', tr('Open Wheel of Destiny'),
            '/images/options/wheel', function() self:toggle() end)
    end

    self.currentTab = 'wheel'
    WheelController:toggleMenu('wheel')
end

function WheelController.wheel:handleMousePress(event, id)
    if event.mouseButton == MouseRightButton then
        local data = WheelController.wheel.data[id]
        WheelController.wheel.currentSelectSlotId = id
        if WheelController.wheel.pointInvested[id] >= data.totalPoints then
            WheelController.wheel:onRemoveAllPoints()
        elseif WheelController.wheel.pointInvested[id] >= 0 then
            WheelController.wheel:onAddAllPoints()
        end
    end
end

function WheelController.wheel:getSlotProgressWidth(index, barWidth)
    index = index or WheelController.wheel.currentSelectSlotId
    if not index or index == -1 then
        return 0
    end
    barWidth = barWidth or 205
    local pointInvested = WheelController.wheel.pointInvested[index] or 0
    local bonus = helper.bonus.WheelBonus[index - 1]
    WheelController.wheel.slotProgressLabel = string.format("%d/%d", pointInvested, bonus.maxPoints)
    local progress = pointInvested / bonus.maxPoints
    return progress * barWidth
end

function WheelController.wheel:isSlotInvested(index)
    if not WheelController.wheel.pointInvested[index] then return false end
    return WheelController.wheel.pointInvested[index] > 0
end

function WheelController.wheel:isSlotFull(index)
    return WheelController.wheel.pointInvested[index] == helper.bonus.WheelBonus[index - 1].maxPoints
end

function WheelController.wheel:canRemovePoints(index)
    if not WheelController.wheel:isSlotInvested(index) then
        return false
    end

    if WheelController.wheel.options ~= 1 then
        return false
    end

    local button = helper.buttons.WheelButtons[index]
    if button.radius == button.BIG_LARGE_CIRCLE then
        return true
    end

    local nodes = helper.nodes.WheelNodes[index]

    local iconInfo = nodes
    if not iconInfo.connections or #iconInfo.connections == 0 then
        return true
    end

    local c = nodes.connections
    for _, id in pairs(c) do
        if WheelController.wheel:isSlotInvested(id) and not helper.nodes.canReachConnectedNodes(id, index) then
            return false
        end
    end

    return true
end

function WheelController.wheel:removePoint(index, points)
    local bonus = helper.bonus.WheelBonus[index - 1]
    if points > 0 then
        local button = helper.buttons.WheelButtons[index]
        if points >= bonus.maxPoints then
            local maxcolor = 20
            if button.radius == button.BIG_LARGE_CIRCLE then
                maxcolor = 20
            elseif button.radius == button.LARGE_CIRCLE then
                maxcolor = 15
            elseif button.radius == button.BIG_MEDIUM_CIRCLE then
                maxcolor = 10
            elseif button.radius == button.MEDIUM_CIRCLE then
                maxcolor = 8
            elseif button.radius == button.SMALL_CIRCLE then
                maxcolor = 5
            end
            local path = button.colorImageBase .. maxcolor
            WheelController.wheel.data[index].colorPath = path .. ".png"
            WheelController.wheel.insertUnlockedThe(index)
        else
            local _maxcolor = math.floor(points / 10) + 1
            _maxcolor = math.min(quadrantFramesByMaxPoints[bonus.maxPoints], _maxcolor)
            if _maxcolor > 0 then
                WheelController.wheel.data[index].colorPath = button.colorImageBase .. _maxcolor .. ".png"
            end
        end
    else
        WheelController.wheel.data[index].colorPath = ""
    end
end

function WheelController.wheel:removeUnlockedThe(index)
    local iconInfo = helper.nodes.WheelNodes[index]
    if #iconInfo.connections == 0 then
        return false
    end

    for _, unlocked_point in pairs(iconInfo.connections) do
        local skipUnlock = {}
        for __, alternative_unlocker in ipairs(helper.nodes.WheelNodes[unlocked_point].connecteds) do
            if alternative_unlocker ~= index and WheelController.wheel.isSlotInvested(alternative_unlocker) then
                skipUnlock[#skipUnlock + 1] = unlocked_point
            end
        end

        if not table.contains(skipUnlock, unlocked_point) then
            WheelController.wheel.data[unlocked_point].adjacentPath = ""
        end
    end
end

function WheelController.wheel:getTotalPoints()
    return WheelController.wheel.points +
        (WheelController.wheel.extraGemPoints + WheelController.wheel.promotionScrollPoints)
end

function WheelController.wheel:handlePassiveBorders()
    -- TODO: get gem atelier points

    local border = "TL"
    for domain, points in ipairs(WheelController.wheel.passivePoints) do
        if domain == 1 then
            border = "TL"
        elseif domain == 2 then
            border = "TR"
        elseif domain == 3 then
            border = "BL"
        elseif domain == 4 then
            border = "BR"
        end

        if points < 250 then
            WheelController.wheel.passiveBorders[border] =
                "/images/game/wheel/backdrop_skillwheel_largebonus_front0_" .. border .. ".png"
        elseif points < 500 then
            WheelController.wheel.passiveBorders[border] =
                "/images/game/wheel/backdrop_skillwheel_largebonus_front1_" .. border .. ".png"
        elseif points < 1000 then
            WheelController.wheel.passiveBorders[border] =
                "/images/game/wheel/backdrop_skillwheel_largebonus_front2_" .. border .. ".png"
        else
            WheelController.wheel.passiveBorders[border] =
                "/images/game/wheel/backdrop_skillwheel_largebonus_front3_" .. border .. ".png"
        end
    end

    -- TODO: Lembrar de configurar as relevation perks
end

local function handleUpdatePoints()
    WheelController.wheel.passivePoints = {}

    local usedPoints = 0
    for id, _points in pairs(WheelController.wheel.pointInvested) do
        usedPoints = usedPoints + _points
        local bonus = helper.bonus.WheelBonus[id - 1]
        WheelController.wheel.passivePoints[bonus.domain] = (WheelController.wheel.passivePoints[bonus.domain] or 0) +
            _points
        if bonus.maxPoints <= _points then
            WheelController.wheel:insertUnlockedThe(id)
        end
    end

    WheelController.wheel.usedPoints = usedPoints
    local totalPoints = WheelController.wheel:getTotalPoints()
    WheelController.wheel.summaryPointsLabel = string.format("%d/%d", totalPoints - WheelController.wheel.usedPoints,
        totalPoints)

    WheelController.wheel:handlePassiveBorders()
    helper.bonus.configureDedicationPerk(WheelController)
    WheelController.wheel:configureConvictionPerk()
end

function WheelController.wheel:configureConvictionPerk()
    local convictions = helper.bonus.getConvictionPerks(WheelController)
    WheelController.wheel.convictionPerks = convictions
end

function WheelController.wheel:onRemoveAllPoints()
    local index = WheelController.wheel.currentSelectSlotId

    if not WheelController.wheel:canRemovePoints(index) then
        return false
    end

    WheelController.wheel.pointInvested[index] = 0
    WheelController.wheel:removePoint(index, WheelController.wheel.pointInvested[index])
    WheelController.wheel:removeUnlockedThe(index)
    handleUpdatePoints()
end

function WheelController.wheel:onAddAllPoints()
    local index = WheelController.wheel.currentSelectSlotId
    if not index or index == -1 then
        return false
    end
    if WheelController.wheel.options ~= 1 then
        return false
    end
    local pointInvested = WheelController.wheel.pointInvested[index]
    local bonus = helper.bonus.WheelBonus[index - 1]
    if pointInvested >= bonus.maxPoints then
        return
    end

    local totalPoints = WheelController.wheel:getTotalPoints()

    local pointToInvest = math.max(totalPoints - WheelController.wheel.usedPoints, 0)

    if pointToInvest == 1 then
        return WheelController.wheel:onAddOnePoint()
    end

    if not WheelController.wheel:canAddPoints(index, true) then
        return
    end

    WheelController.wheel.pointInvested[index] = math.min((pointInvested + pointToInvest), bonus.maxPoints)
    WheelController.wheel:insertPoint(index, WheelController.wheel.pointInvested[index])
    WheelController.wheel:insertUnlockedThe(index)
    handleUpdatePoints()
end

function WheelController.wheel:onAddOnePoint()
    local index = WheelController.wheel.currentSelectSlotId
    if not index or index == -1 then
        return false
    end
    if WheelController.wheel.options ~= 1 then
        return false
    end

    local pointInvested = WheelController.wheel.pointInvested[index]
    local bonus = helper.bonus.WheelBonus[index - 1]


    if pointInvested >= bonus.maxPoints then
        return
    end
    g_logger.info("pointInvested>" .. pointInvested .. " bonus.maxPoints>" .. bonus.maxPoints)

    if not WheelController.wheel:canAddPoints(index, true) then
        return
    end

    g_logger.info("can add")
    WheelController.wheel.pointInvested[index] = pointInvested + 1
    WheelController.wheel:insertPoint(index, WheelController.wheel.pointInvested[index])
    WheelController.wheel:insertUnlockedThe(index)

    handleUpdatePoints()
end

function WheelController.wheel:onRemoveOnePoint()
    local index = WheelController.wheel.currentSelectSlotId
    if not index or index == -1 then
        return false
    end
    if WheelController.wheel.options ~= 1 then
        return false
    end

    if not WheelController.wheel:canRemovePoints(index) then
        return
    end

    local pointInvested = WheelController.wheel.pointInvested[index]
    if pointInvested == 0 then
        return
    end

    WheelController.wheel.pointInvested[index] = pointInvested - 1
    WheelController.wheel:removePoint(index, WheelController.wheel.pointInvested[index])
    handleUpdatePoints()
end

function WheelController.wheel:canAddPoints(index, ignoreMaxPoint)
    if WheelController.wheel.vocationId == 0 then
        return false
    end

    if ignoreMaxPoint == nil then
        ignoreMaxPoint = false
    end

    local bonus = helper.bonus.WheelBonus[index - 1]
    if not ignoreMaxPoint then
        if WheelController.wheel.pointInvested[index] >= bonus.maxPoints then
            return false
        end
    end

    if not WheelController.wheel.points then
        WheelController.wheel.points = 0
    end

    local totalPoints = WheelController.wheel.points +
        (WheelController.wheel.extraGemPoints + WheelController.wheel.promotionScrollPoints)

    if not ignoreMaxPoint then
        if totalPoints - WheelController.wheel.usedPoints <= 0 then
            return false
        end
    end

    if bonus.maxPoints == 50 then
        return true
    end

    local iconInfo = helper.nodes.WheelNodes[index]
    if #iconInfo.connecteds == 0 then
        return true
    end

    for _, id in pairs(iconInfo.connecteds) do
        local _bonus = helper.bonus.WheelBonus[id - 1]
        local pointInvested = WheelController.wheel.pointInvested[id]
        if pointInvested >= _bonus.maxPoints then
            return true
        end
    end

    return false
end

function WheelController.wheel:handleChangePointsButton(currentType)
    local index = WheelController.wheel.currentSelectSlotId

    if currentType == "all" and (not index or index == -1) then
        return false
    end

    if WheelController.wheel:canAddPoints(index) and currentType == "add" then
        return true
    end
    if WheelController.wheel:canRemovePoints(index) and currentType == "remove" then
        return true
    end

    return false
end

function WheelController.wheel:insertUnlockedThe(index)
    local iconInfo = helper.nodes.WheelNodes[index]
    if #iconInfo.connections == 0 then
        return false
    end

    local bonus = helper.bonus.WheelBonus[index - 1]
    local pointInvested = WheelController.wheel.pointInvested[index]
    if pointInvested < bonus.maxPoints then
        return false
    end

    for _, id in pairs(iconInfo.connections) do
        local data = WheelController.wheel.data[id]
        WheelController.wheel.data[id].adjacentPath = string.format(baseColorSlotPath,
            data.quadrant,
            data.index,
            quadrantFramesByMaxPoints[data.totalPoints])
    end
end

function WheelController.wheel:insertPoint(index, points)
    local bonus                                  = helper.bonus.WheelBonus[index - 1]
    local data                                   = WheelController.wheel.data[index]
    local button                                 = helper.buttons.WheelButtons[index]
    WheelController.wheel.data[index].id         = index
    WheelController.wheel.data[index].borderPath = button.borderImageBase .. ".png"
    WheelController.wheel.data[index].hoverPath  = button.focusImageBase .. ".png"
    WheelController.wheel.data[index].bgPath     = string.format(baseWheelColorPath, data.quadrant, data.color,
        data.index)

    local isBaseSlot                             = helper.wheel.isFirstSlot(index)

    if points > 0 then
        if points >= bonus.maxPoints then
            local maxcolor = 20
            if button.radius == helper.buttons.BIG_LARGE_CIRCLE then
                maxcolor = 20
            elseif button.radius == helper.buttons.LARGE_CIRCLE then
                maxcolor = 15
            elseif button.radius == helper.buttons.BIG_MEDIUM_CIRCLE then
                maxcolor = 10
            elseif button.radius == helper.buttons.MEDIUM_CIRCLE then
                maxcolor = 8
            elseif button.radius == helper.buttons.SMALL_CIRCLE then
                maxcolor = 5
            end

            local path = button.colorImageBase .. maxcolor
            WheelController.wheel.data[index].colorPath = path .. ".png"
            WheelController.wheel:insertUnlockedThe(index)
        else
            local _maxcolor = math.floor(points / 10) + 1
            _maxcolor = math.min(quadrantFramesByMaxPoints[bonus.maxPoints], _maxcolor)
            if _maxcolor > 0 then
                WheelController.wheel.data[index].colorPath = button.colorImageBase .. _maxcolor .. ".png"
            end
        end
    elseif not isBaseSlot then
        WheelController.wheel.data[index].colorPath = ""
        WheelController.wheel.data[index].adjacentPath = ""
    else
        WheelController.wheel.data[index].adjacentPath = button.colorImageBase .. "5.png"
    end
end

function onWheelOfDestinyOpenWindow(data)
    WheelController.wheel.options = data.options
    WheelController.wheel.vocationId = data.vocationId or 0
    WheelController.wheel.points = data.points or 0
    WheelController.wheel.extraGemPoints = 0
    WheelController.wheel.usedPoints = 0
    data.points = data.points or 0
    data.extraPoints = data.extraPoints or 0
    WheelController.wheel.pointInvested = {}
    WheelController.wheel.passivePoints = {}
    WheelController.wheel.currentPoints = data.points
    WheelController.wheel.promotionScrollPoints = data.extraPoints
    WheelController.wheel.data = helper.wheel.WheelSlotsParser
    data.wheelPoints = data.wheelPoints or {}

    -- order
    local orderned = {
        15, 9, 14, 3, 8, 13, 2, 7, 1, 16, 10, 17, 4, 11, 18, 5, 12, 6, 22, 23, 28, 24, 29, 34, 30, 35, 36, 21, 20, 27, 19, 26, 33, 25, 32, 31
    }

    for _, tier in pairs(data.basicGrades) do
        if tier == 3 then
            WheelController.wheel.extraGemPoints = WheelController.wheel.extraGemPoints + 1
        end
    end

    for _, tier in pairs(data.supremeGrades) do
        if tier == 3 then
            WheelController.wheel.extraGemPoints = WheelController.wheel.extraGemPoints + 1
        end
    end


    local currentPoints = 0
    for k, v in pairs(data.wheelPoints) do
        currentPoints = currentPoints + v
    end


    -- for k, v in pairs(data) do
    --     g_logger.info("WOD DATA key: " .. k .. " value: " .. tostring(v))
    -- end


    for _, id in pairs(orderned) do
        local points = data.wheelPoints[id]
        local bonus = helper.bonus.WheelBonus[id - 1]
        WheelController.wheel.pointInvested[id] = 0
        for __ = 1, points do
            WheelController.wheel.usedPoints = WheelController.wheel.usedPoints + 1
            WheelController.wheel.passivePoints[bonus.domain] = (WheelController.wheel.passivePoints[bonus.domain] or 0) +
                1
            WheelController.wheel.pointInvested[id] = WheelController.wheel.pointInvested[id] + 1
        end
    end

    local _currentPoints = 0
    for k, v in pairs(WheelController.wheel.pointInvested) do
        _currentPoints = _currentPoints + v
    end

    -- check slot integrity
    for id, points in pairs(WheelController.wheel.pointInvested) do
        if not WheelController.wheel:canAddPoints(id, true) and points > 0 then
            local bonus = helper.bonus.WheelBonus[id - 1]
            WheelController.wheel.usedPoints = WheelController.wheel.usedPoints - points
            WheelController.wheel.passivePoints[bonus.domain] = WheelController.wheel.passivePoints[bonus.domain] -
                points
            points = 0
        end
    end

    for id, _points in pairs(WheelController.wheel.pointInvested) do
        WheelController.wheel:insertPoint(id, _points)
    end

    for id, _points in pairs(WheelController.wheel.pointInvested) do
        local bonus = helper.bonus.WheelBonus[id - 1]
        if bonus.maxPoints <= _points then
            WheelController.wheel:insertUnlockedThe(id)
        end
    end

    WheelController.wheel.atelierGems = data.revealedGems or {}

    local function incrementBonusCount(_bonus, bonusType)
        if _bonus ~= -1 then
            local _data = bonusType[tostring(_bonus)]
            if _data then
                bonusType[tostring(_bonus)] = _data + 1
            else
                bonusType[tostring(_bonus)] = 1
            end
        end
    end

    WheelController.wheel.basicModCount = {}
    WheelController.wheel.supremeModCount = {}
    for _, info in pairs(WheelController.wheel.atelierGems) do
        incrementBonusCount(info.lesserBonus, WheelController.wheel.basicModCount)
        incrementBonusCount(info.regularBonus, WheelController.wheel.basicModCount)
        incrementBonusCount(info.supremeBonus, WheelController.wheel.supremeModCount)
    end


    local totalPoints = WheelController.wheel.currentPoints +
        (WheelController.wheel.extraGemPoints + WheelController.wheel.promotionScrollPoints)
    WheelController.wheel.summaryPointsLabel = string.format("%d/%d", totalPoints - WheelController.wheel.usedPoints,
        totalPoints)


    g_logger.info(string.format(
        "Received WOD data: points=%d, extraPoints=%d, currentPoints=%d, data.promotionScrolls=%d",
        data.points, data.extraPoints, currentPoints, #data.promotionScrolls))

    WheelController.wheel.currentPoints = currentPoints
    WheelController.wheel.extraPoints = data.extraPoints
    WheelController.wheel.totalPoints = data.points + data.extraPoints
    WheelController.wheel.slots = helper.wheel.WheelSlotsParser
    local basicVocationId = helper.wheel.getBasicVocation(data.vocationId)
    local overlayImage = helper.wheel.getVocationImage(basicVocationId)
    if not overlayImage then
        return WheelController:hide()
    end

    WheelController.wheel.backdropVocationOverlay = overlayImage .. ".png"

    helper.wheel.handleLargePerkClip(data.vocationId, WheelController)

    WheelController.wheel.icons = {}

    for id, iconInfo in pairs(helper.icons.WheelIcons[data.vocationId]) do
        local iconRect = iconInfo.iconRect
        local miniIconRect = iconInfo.miniIconRect

        local x, y, width, height = iconRect:match("(%d+) (%d+) (%d+) (%d+)")

        WheelController.wheel.data[id].iconClip = {
            x = tonumber(x),
            y = tonumber(y),
            width = tonumber(width),
            height = tonumber(height)
        }

        WheelController.wheel.data[id].left = WheelController.wheel.data[id].left or 0
        WheelController.wheel.data[id].top = WheelController.wheel.data[id].top or 0

        x, y, width, height = miniIconRect:match("(%d+) (%d+) (%d+) (%d+)")

        WheelController.wheel.data[id].miniIconClip = {
            x = tonumber(x),
            y = tonumber(y),
            width = tonumber(width),
            height = tonumber(height)
        }
    end

    helper.bonus.configureDedicationPerk(WheelController)
    WheelController.wheel:configureConvictionPerk()
end

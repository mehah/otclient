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
    points = 0,
    extraPoints = 0,
    totalPoints = 0,
    currentSelectSlotData = nil,
    data = {}
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

local VocationConfig = {
    -- Basic vocation IDs
    KNIGHT = 1,
    PALADIN = 2,
    SORCERER = 3,
    DRUID = 4,
    MONK = 5,

    -- Minimum requirements
    MIN_LEVEL = 51,
    MIN_PROMOTED_VOCATION = 11,

    -- Mapping from promoted to basic vocations
    promotedToBasic = {
        [11] = 1, -- Elite Knight -> Knight
        [12] = 2, -- Royal Paladin -> Paladin
        [13] = 3, -- Master Sorcerer -> Sorcerer
        [14] = 4, -- Elder Druid -> Druid
        [15] = 5  -- Exalted Monk -> Monk
    },

    -- Images by vocation
    images = {
        [1] = '/images/game/wheel/wheel-vocations/backdrop_skillwheel_knight',
        [2] = '/images/game/wheel/wheel-vocations/backdrop_skillwheel_paladin',
        [3] = '/images/game/wheel/wheel-vocations/backdrop_skillwheel_sorcerer',
        [4] = '/images/game/wheel/wheel-vocations/backdrop_skillwheel_druid',
        [5] = '/images/game/wheel/wheel-vocations/backdrop_skillwheel_monk'
    },
}

local function getVocationImage(basicVocationId)
    if basicVocationId == VocationConfig.MONK and g_game.getClientVersion() < 1500 then
        return nil
    end
    return VocationConfig.images[basicVocationId]
end

local function getBasicVocation(vocationId)
    return VocationConfig.promotedToBasic[vocationId] or vocationId
end

local quadrants = {
    "top_left",
    "top_right",
    "bottom_right",
    "bottom_left"
}
local colorQuadrants = {
    "TopLeft",
    "TopRight",
    "BottomRight",
    "BottomLeft"
}

local quadrantFrames = {
    [1] = 5,
    [2] = 8,
    [3] = 8,
    [4] = 10,
    [5] = 10,
    [6] = 10,
    [7] = 15,
    [8] = 15,
    [9] = 20
}


local baseBorderPath = "/images/game/wheel/wheel-border/%s/%s.png"
local baseWheelColorPath = "/images/game/wheel/wheel-colors/%s/%s_%s.png"
local baseColorSlotPath = "/images/game/wheel/wheel-colors/%s/slot%s/%s.png"
local otherBorders = { "revelationPerk", "vesselGem" }

function WheelController.wheel:handleOnHover(slotId)
    if WheelController.wheel.currentHoverSlot == slotId then return end
    WheelController.wheel.currentHoverSlot = slotId
end

local indexByTotalPoints = {
    [50] = 1,
    [75] = 2,
    [100] = 3,
    [150] = 4,
    [200] = 5
}

function WheelController.wheel.getSlotFramePercentage(data)
    data.totalPoints = helper.wheel.WheelSlotsParser[data.id].totalPoints
    local numericValue = tonumber(data.currentPoints) or 0
    local sanitizedValue = math.max(0, numericValue)
    local clampedValue = math.min(sanitizedValue, data.totalPoints)
    local progress = clampedValue / data.totalPoints
    local frames = quadrantFrames[data.index]

    if not frames or frames <= 0 then
        return ""
    end

    local clampedProgress = math.max(0, math.min(1, progress))
    if clampedProgress == 0 then
        return ""
    end

    local idx = math.ceil(clampedProgress * frames)
    if idx < 1 then idx = 1 end
    if idx > frames then idx = frames end
    local path = string.format(baseColorSlotPath, data.quadrant, data.index, idx)
    g_logger.info(string.format(
        "quadrant: %s, index: %d, currentPoints: %d, totalPoints: %d, progress: %.2f, frames: %d, idx: %d, path: %s",
        data.quadrant, data.index, data.currentPoints, data.totalPoints, progress, frames, idx, path))
    return path
end

function WheelController.wheel.getSlotFinalFramePath(data)
    if not data or not data.index or not data.quadrant then
        return ""
    end

    local frames = quadrantFrames[data.index]

    if not frames or frames <= 0 then
        return ""
    end

    return string.format(baseColorSlotPath, data.quadrant, data.index, frames)
end

function WheelController.wheel:onChangeSlotPoints(value)
    if not WheelController.wheel.currentSelectSlotId then return end
    local slotId = WheelController.wheel.currentSelectSlotId
    local data = WheelController.wheel.data[slotId]
    if not data then return end
    data.index = helper.wheel.WheelSlotsParser[slotId].index
    data.quadrant = helper.wheel.WheelSlotsParser[slotId].quadrant
    data.color = helper.wheel.WheelSlotsParser[slotId].color
    data.totalPoints = helper.wheel.WheelSlotsParser[slotId].totalPoints
    if type(value) == "string" then
        if value == "-max" then
            WheelController.wheel.points = WheelController.wheel.points + data.currentPoints
            data.currentPoints = 0
        elseif value == "+max" then
            local diff = data.totalPoints - data.currentPoints
            if diff > WheelController.wheel.points then
                diff = WheelController.wheel.points
            end
            data.currentPoints = data.currentPoints + diff
            WheelController.wheel.points = WheelController.wheel.points - diff
        end
        WheelController.wheel.currentSelectSlotData = data
        data.colorPath = WheelController.wheel.getSlotFramePercentage(data)
        data.isComplete = data.currentPoints == data.totalPoints
        WheelController.wheel.data[slotId] = data
        helper.wheel.propagateAdjacentSelection(WheelController.wheel.data, WheelController)
        return
    end


    local numericValue = tonumber(value) or 0
    if numericValue == 0 then return end
    data.currentPoints = data.currentPoints + numericValue
    if data.currentPoints < 0 then
        data.currentPoints = 0
    end
    if data.currentPoints > data.totalPoints then
        data.currentPoints = data.totalPoints
    end
    data.isComplete = data.currentPoints == data.totalPoints
    WheelController.wheel.data[slotId] = data
    WheelController.wheel.currentSelectSlotData = data
    helper.wheel.propagateAdjacentSelection(WheelController.wheel.data, WheelController)
end

function WheelController.wheel:fillQuadrantsBorders()
    WheelController.wheel.borders = {}
    WheelController.wheel.colors = {}
    WheelController.wheel.hovers = {}
    WheelController.wheel.data = {}

    for slot, data in pairs(self.slots) do
        if slot == 4 then
            g_logger.info("INDEX: " .. data.index .. " QUADRANT: " .. data.quadrant)
        end
        local current = {
            quadrant = data.quadrant,
            border = data.border,
            color = data.color,
            index = data.index,
            currentPoints = data.currentPoints,
            totalPoints = data.totalPoints,
            isHovered = data.isHovered,
            isSelected = data.isSelected,
            isAdjacent = data.isAdjacent,
            colorPath = "",
            hoverPath = string.format(baseWheelColorPath, data.quadrant, data.color, data.index),
            adjacentPath = "",
            adjacents = data.adjacents,
            id = slot,
            borderPath = string.format(baseBorderPath, data.quadrant, data.index),
            bgPath = string.format(baseWheelColorPath, data.quadrant, data.color, data.index),
            height = "522",
            width = "522",
            isComplete = data.currentPoints == data.totalPoints,
        }

        current.colorPath = WheelController.wheel.getSlotFramePercentage(current)
        WheelController.wheel.data[slot] = current
    end

    helper.wheel.propagateAdjacentSelection(WheelController.wheel.data, WheelController)
end

function WheelController.wheel:handleSelectSlot(slotId)
    WheelController.wheel.currentSelectSlotId = slotId
    WheelController.wheel.currentSelectSlotData = WheelController.wheel.data[slotId]
    g_logger.info("Selected slot ID: " .. slotId)
end

function WheelController:show(skipRequest)
    -- if not g_game.getFeature(GameForgeConvergence) then
    --     return WheelController:hide()
    -- end
    WheelController.wheel.currentSelectSlotId = -1
    WheelController.wheel.currentSelectSlotData = nil
    local player = g_game.getLocalPlayer()
    g_game.openWheelOfDestiny(player:getId())

    local basicVocationId = getBasicVocation(player:getVocation())
    local overlayImage = getVocationImage(basicVocationId)
    if not overlayImage then
        return WheelController:hide()
    end

    self.wheel.backdropVocationOverlay = overlayImage .. ".png"

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
    self:registerEvents(g_game, { onWheelOfDestinyOpenWindow = onWheelOfDestinyOpenWindow })

    if not WheelButton then
        WheelButton = modules.game_mainpanel.addToggleButton('WheelButton', tr('Open Wheel of Destiny'),
            '/images/options/wheel', function() self:toggle() end)
    end

    self.currentTab = 'wheel'
    WheelController:toggleMenu('wheel')
end

function onWheelOfDestinyOpenWindow(data)
    data.wheelPoints = data.wheelPoints or {}
    local currentPoints = 0
    for slot, point in pairs(data.wheelPoints) do
        if helper.wheel.WheelSlotsParser[slot] then
            helper.wheel.WheelSlotsParser[slot].currentPoints = point
            currentPoints = currentPoints + point
        end
    end

    -- for k, v in pairs(data) do
    --     g_logger.info("WOD DATA key: " .. k .. " value: " .. tostring(v))
    -- end

    for k, v in pairs(data.promotionScrolls) do
        g_logger.info("Promotion Scrolls key: " .. k .. " value: " .. tostring(v))
    end

    data.points = data.points or 0
    data.extraPoints = data.extraPoints or 0

    g_logger.info(string.format(
        "Received WOD data: points=%d, extraPoints=%d, currentPoints=%d, data.promotionScrolls=%d",
        data.points, data.extraPoints, currentPoints, #data.promotionScrolls))

    WheelController.wheel.points = currentPoints
    WheelController.wheel.extraPoints = data.extraPoints
    WheelController.wheel.totalPoints = data.points + data.extraPoints
    WheelController.wheel.slots = helper.wheel.WheelSlotsParser
    WheelController.wheel:fillQuadrantsBorders()
end

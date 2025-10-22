WheelController = Controller:new()
WheelButton = nil

local baseButtonClip = { x = 0, y = 0, width = 322, height = 34 }
local baseButtonClipped = { x = 0, y = 34, width = 322, height = 34 }

local WheelSlots =
{
    SLOT_GREEN_200 = 1,
    SLOT_GREEN_TOP_150 = 2,
    SLOT_GREEN_TOP_100 = 3,

    SLOT_RED_TOP_100 = 4,
    SLOT_RED_TOP_150 = 5,
    SLOT_RED_200 = 6,

    SLOT_GREEN_BOTTOM_150 = 7,
    SLOT_GREEN_MIDDLE_100 = 8,
    SLOT_GREEN_TOP_75 = 9,

    SLOT_RED_TOP_75 = 10,
    SLOT_RED_MIDDLE_100 = 11,
    SLOT_RED_BOTTOM_150 = 12,

    SLOT_GREEN_BOTTOM_100 = 13,
    SLOT_GREEN_BOTTOM_75 = 14,
    SLOT_GREEN_50 = 15,

    SLOT_RED_50 = 16,
    SLOT_RED_BOTTOM_75 = 17,
    SLOT_RED_BOTTOM_100 = 18,

    SLOT_BLUE_TOP_100 = 19,
    SLOT_BLUE_TOP_75 = 20,
    SLOT_BLUE_50 = 21,

    SLOT_PURPLE_50 = 22,
    SLOT_PURPLE_TOP_75 = 23,
    SLOT_PURPLE_TOP_100 = 24,

    SLOT_BLUE_TOP_150 = 25,
    SLOT_BLUE_MIDDLE_100 = 26,
    SLOT_BLUE_BOTTOM_75 = 27,

    SLOT_PURPLE_BOTTOM_75 = 28,
    SLOT_PURPLE_MIDDLE_100 = 29,
    SLOT_PURPLE_TOP_150 = 30,

    SLOT_BLUE_200 = 31,
    SLOT_BLUE_BOTTOM_150 = 32,
    SLOT_BLUE_BOTTOM_100 = 33,

    SLOT_PURPLE_BOTTOM_100 = 34,
    SLOT_PURPLE_BOTTOM_150 = 35,
    SLOT_PURPLE_200 = 36,
}

WheelController.wheel = {
    clip = baseButtonClipped,
    backdropVocationOverlay = nil,
    borders = {},
    colors = {},
    slots = {},
    currentSelectSlot = -1,
    hovers = {},
    currentHoverSlot = -1,
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

local WheelSlotsParser = {
    [WheelSlots.SLOT_GREEN_200] = {
        quadrant = "top_left",
        border = "top_left",
        color = "TopLeft",
        index = 9,
        currentPoints = 0,
        totalPoints = 200,
        adjacents = {}
    },
    [WheelSlots.SLOT_GREEN_TOP_150] = {
        quadrant = "top_left",
        border = "top_left",
        color = "TopLeft",
        index = 8,
        currentPoints = 0,
        totalPoints = 150,
        adjacents = { WheelSlots.SLOT_GREEN_200 },
    },
    [WheelSlots.SLOT_GREEN_BOTTOM_150] = {
        quadrant = "top_left",
        border = "top_left",
        color = "TopLeft",
        index = 7,
        currentPoints = 0,
        totalPoints = 150,
        adjacents = { WheelSlots.SLOT_GREEN_200 },
    },
    [WheelSlots.SLOT_GREEN_TOP_100] = {
        quadrant = "top_left",
        border = "top_left",
        color = "TopLeft",
        index = 6,
        currentPoints = 0,
        totalPoints = 100,
        adjacents = { WheelSlots.SLOT_GREEN_BOTTOM_150, WheelSlots.SLOT_RED_TOP_100 },
    },
    [WheelSlots.SLOT_GREEN_MIDDLE_100] = {
        quadrant = "top_left",
        border = "top_left",
        color = "TopLeft",
        index = 5,
        currentPoints = 0,
        totalPoints = 100,
        adjacents = { WheelSlots.SLOT_GREEN_BOTTOM_150, WheelSlots.SLOT_GREEN_TOP_150, },
    },
    [WheelSlots.SLOT_GREEN_BOTTOM_100] = {
        quadrant = "top_left",
        border = "top_left",
        color = "TopLeft",
        index = 4,
        currentPoints = 0,
        totalPoints = 100,
        adjacents = { WheelSlots.SLOT_GREEN_BOTTOM_150, WheelSlots.SLOT_BLUE_BOTTOM_100, },
    },
    [WheelSlots.SLOT_GREEN_TOP_75] = {
        quadrant = "top_left",
        border = "top_left",
        color = "TopLeft",
        index = 3,
        currentPoints = 0,
        totalPoints = 75,
        adjacents = { WheelSlots.SLOT_GREEN_MIDDLE_100, WheelSlots.SLOT_GREEN_TOP_100, WheelSlots.SLOT_RED_TOP_75, },
    },
    [WheelSlots.SLOT_GREEN_BOTTOM_75] = {
        quadrant = "top_left",
        border = "top_left",
        color = "TopLeft",
        index = 2,
        currentPoints = 0,
        totalPoints = 75,
        adjacents = { WheelSlots.SLOT_GREEN_MIDDLE_100, WheelSlots.SLOT_GREEN_BOTTOM_100, WheelSlots.SLOT_BLUE_BOTTOM_75, },
    },
    [WheelSlots.SLOT_GREEN_50] = {
        quadrant = "top_left",
        border = "top_left",
        color = "TopLeft",
        index = 1,
        currentPoints = 0,
        totalPoints = 50,
        adjacents = { WheelSlots.SLOT_GREEN_BOTTOM_75, WheelSlots.SLOT_GREEN_TOP_75, },
    },
    [WheelSlots.SLOT_RED_200] = {
        quadrant = "top_right",
        border = "top_right",
        color = "TopRight",
        index = 9,
        currentPoints = 0,
        totalPoints = 200,
        adjacents = {},
    },
    [WheelSlots.SLOT_RED_TOP_150] = {
        quadrant = "top_right",
        border = "top_right",
        color = "TopRight",
        index = 8,
        currentPoints = 0,
        totalPoints = 150,
        adjacents = { WheelSlots.SLOT_RED_200 },
    },
    [WheelSlots.SLOT_RED_BOTTOM_150] = {
        quadrant = "top_right",
        border = "top_right",
        color = "TopRight",
        index = 7,
        currentPoints = 0,
        totalPoints = 150,
        adjacents = { WheelSlots.SLOT_RED_200 },
    },
    [WheelSlots.SLOT_RED_TOP_100] = {
        quadrant = "top_right",
        border = "top_right",
        color = "TopRight",
        index = 6,
        currentPoints = 0,
        totalPoints = 100,
        adjacents = { WheelSlots.SLOT_RED_TOP_150, WheelSlots.SLOT_GREEN_TOP_100 },
    },
    [WheelSlots.SLOT_RED_MIDDLE_100] = {
        quadrant = "top_right",
        border = "top_right",
        color = "TopRight",
        index = 5,
        currentPoints = 0,
        totalPoints = 100,
        adjacents = { WheelSlots.SLOT_RED_TOP_150, WheelSlots.SLOT_RED_BOTTOM_150 },
    },
    [WheelSlots.SLOT_RED_BOTTOM_100] = {
        quadrant = "top_right",
        border = "top_right",
        color = "TopRight",
        index = 4,
        currentPoints = 0,
        totalPoints = 100,
        adjacents = { WheelSlots.SLOT_RED_BOTTOM_150, WheelSlots.SLOT_PURPLE_BOTTOM_100 },
    },
    [WheelSlots.SLOT_RED_TOP_75] = {
        quadrant = "top_right",
        border = "top_right",
        color = "TopRight",
        index = 3,
        currentPoints = 0,
        totalPoints = 75,
        adjacents = { WheelSlots.SLOT_RED_TOP_100, WheelSlots.SLOT_RED_MIDDLE_100, WheelSlots.SLOT_GREEN_TOP_75, },
    },
    [WheelSlots.SLOT_RED_BOTTOM_75] = {
        quadrant = "top_right",
        border = "top_right",
        color = "TopRight",
        index = 2,
        currentPoints = 0,
        totalPoints = 75,
        adjacents = { WheelSlots.SLOT_RED_BOTTOM_100, WheelSlots.SLOT_RED_MIDDLE_100, WheelSlots.SLOT_PURPLE_BOTTOM_75, },
    },
    [WheelSlots.SLOT_RED_50] = {
        quadrant = "top_right",
        border = "top_right",
        color = "TopRight",
        index = 1,
        currentPoints = 0,
        totalPoints = 50,
        adjacents = { WheelSlots.SLOT_RED_BOTTOM_75, WheelSlots.SLOT_RED_TOP_75 },
    },
    [WheelSlots.SLOT_BLUE_200] = {
        quadrant = "bottom_left",
        border = "bottom_left",
        color = "BottomLeft",
        index = 9,
        currentPoints = 0,
        totalPoints = 200,
        adjacents = {}
    },
    [WheelSlots.SLOT_BLUE_TOP_150] = {
        quadrant = "bottom_left",
        border = "bottom_left",
        color = "BottomLeft",
        index = 8,
        currentPoints = 0,
        totalPoints = 150,
        adjacents = { WheelSlots.SLOT_BLUE_200 },
    },
    [WheelSlots.SLOT_BLUE_BOTTOM_150] = {
        quadrant = "bottom_left",
        border = "bottom_left",
        color = "BottomLeft",
        index = 7,
        currentPoints = 0,
        totalPoints = 150,
        adjacents = { WheelSlots.SLOT_BLUE_200 },
    },
    [WheelSlots.SLOT_BLUE_TOP_100] = {
        quadrant = "bottom_left",
        border = "bottom_left",
        color = "BottomLeft",
        index = 4,
        currentPoints = 0,
        totalPoints = 100,
        adjacents = { WheelSlots.SLOT_BLUE_BOTTOM_150, WheelSlots.SLOT_PURPLE_TOP_100 },

    },
    [WheelSlots.SLOT_BLUE_MIDDLE_100] = {
        quadrant = "bottom_left",
        border = "bottom_left",
        color = "BottomLeft",
        index = 5,
        currentPoints = 0,
        totalPoints = 100,
        adjacents = { WheelSlots.SLOT_BLUE_BOTTOM_150, WheelSlots.SLOT_BLUE_TOP_150 },
    },
    [WheelSlots.SLOT_BLUE_BOTTOM_100] = {
        quadrant = "bottom_left",
        border = "bottom_left",
        color = "BottomLeft",
        index = 6,
        currentPoints = 0,
        totalPoints = 100,
        adjacents = { WheelSlots.SLOT_BLUE_TOP_150, WheelSlots.SLOT_PURPLE_BOTTOM_100 },
    },
    [WheelSlots.SLOT_BLUE_TOP_75] = {
        quadrant = "bottom_left",
        border = "bottom_left",
        color = "BottomLeft",
        index = 2,
        currentPoints = 0,
        totalPoints = 75,
        adjacents = { WheelSlots.SLOT_BLUE_MIDDLE_100, WheelSlots.SLOT_BLUE_TOP_100, WheelSlots.SLOT_PURPLE_TOP_75 },
    },
    [WheelSlots.SLOT_BLUE_BOTTOM_75] = {
        quadrant = "bottom_left",
        border = "bottom_left",
        color = "BottomLeft",
        index = 3,
        currentPoints = 0,
        totalPoints = 75,
        adjacents = { WheelSlots.SLOT_BLUE_MIDDLE_100, WheelSlots.SLOT_BLUE_BOTTOM_100, WheelSlots.SLOT_PURPLE_BOTTOM_75 },
    },
    [WheelSlots.SLOT_BLUE_50] = {
        quadrant = "bottom_left",
        border = "bottom_left",
        color = "BottomLeft",
        index = 1,
        currentPoints = 0,
        totalPoints = 50,
        adjacents = { WheelSlots.SLOT_BLUE_BOTTOM_75, WheelSlots.SLOT_BLUE_TOP_75 },
    },
    [WheelSlots.SLOT_PURPLE_200] = {
        quadrant = "bottom_right",
        border = "bottom_right",
        color = "BottomRight",
        index = 9,
        currentPoints = 0,
        totalPoints = 200,
        adjacents = {}
    },
    [WheelSlots.SLOT_PURPLE_TOP_150] = {
        quadrant = "bottom_right",
        border = "bottom_right",
        color = "BottomRight",
        index = 7,
        currentPoints = 0,
        totalPoints = 150,
        adjacents = { WheelSlots.SLOT_PURPLE_200 }
    },
    [WheelSlots.SLOT_PURPLE_BOTTOM_150] = {
        quadrant = "bottom_right",
        border = "bottom_right",
        color = "BottomRight",
        index = 8,
        currentPoints = 0,
        totalPoints = 150,
        adjacents = { WheelSlots.SLOT_PURPLE_200 }
    },
    [WheelSlots.SLOT_PURPLE_TOP_100] = {
        quadrant = "bottom_right",
        border = "bottom_right",
        color = "BottomRight",
        index = 4,
        currentPoints = 0,
        totalPoints = 100,
        adjacents = { WheelSlots.SLOT_PURPLE_TOP_150, WheelSlots.SLOT_BLUE_TOP_100 },
    },
    [WheelSlots.SLOT_PURPLE_MIDDLE_100] = {
        quadrant = "bottom_right",
        border = "bottom_right",
        color = "BottomRight",
        index = 5,
        currentPoints = 0,
        totalPoints = 100,
        adjacents = { WheelSlots.SLOT_PURPLE_TOP_150, WheelSlots.SLOT_PURPLE_BOTTOM_150 }
    },
    [WheelSlots.SLOT_PURPLE_BOTTOM_100] = {
        quadrant = "bottom_right",
        border = "bottom_right",
        color = "BottomRight",
        index = 6,
        currentPoints = 0,
        totalPoints = 100,
        adjacents = { WheelSlots.SLOT_PURPLE_BOTTOM_150, WheelSlots.SLOT_RED_BOTTOM_100 },
    },
    [WheelSlots.SLOT_PURPLE_TOP_75] = {
        quadrant = "bottom_right",
        border = "bottom_right",
        color = "BottomRight",
        index = 2,
        currentPoints = 0,
        totalPoints = 75,
        adjacents = { WheelSlots.SLOT_PURPLE_MIDDLE_100, WheelSlots.SLOT_PURPLE_TOP_100, WheelSlots.SLOT_BLUE_TOP_75 },
    },
    [WheelSlots.SLOT_PURPLE_BOTTOM_75] = {
        quadrant = "bottom_right",
        border = "bottom_right",
        color = "BottomRight",
        index = 3,
        currentPoints = 0,
        totalPoints = 75,
        adjacents = { WheelSlots.SLOT_PURPLE_MIDDLE_100, WheelSlots.SLOT_PURPLE_BOTTOM_100, WheelSlots.SLOT_RED_BOTTOM_75 },
    },
    [WheelSlots.SLOT_PURPLE_50] = {
        quadrant = "bottom_right",
        border = "bottom_right",
        color = "BottomRight",
        index = 1,
        currentPoints = 0,
        totalPoints = 50,
        adjacents = { WheelSlots.SLOT_PURPLE_BOTTOM_75, WheelSlots.SLOT_PURPLE_TOP_75 },
    },
}

local baseBorderPath = "/images/game/wheel/wheel-border/%s/%s.png"
local baseWheelColorPath = "/images/game/wheel/wheel-colors/%s/%s_%s.png"
local baseColorSlotPath = "/images/game/wheel/wheel-colors/%s/slot%s/%s.png"
local otherBorders = { "revelationPerk", "vesselGem" }

local function propagateAdjacentSelection(slotList)
    -- group slots by quadrant and index safely
    local byQuadrant = {}

    for _, data in ipairs(slotList) do
        if data.selected then
            for _, slotId in ipairs(WheelController.wheel.slots[data.id].adjacents) do
                table.insert(byQuadrant, slotId)
            end
        end
    end

    for _, slotId in ipairs(byQuadrant) do
        for _, data in ipairs(slotList) do
            if data.id == slotId then
                data.adjacent = true
                break
            end
        end
    end
end

function WheelController.wheel:handleOnHover(slotId)
    if WheelController.wheel.currentHoverSlot == slotId then return end
    g_logger.info("Hover slotId: " .. slotId)
    WheelController.wheel.currentHoverSlot = slotId
end

function WheelController.wheel:fillQuadrantsBorders()
    WheelController.wheel.borders = {}
    WheelController.wheel.colors = {}
    WheelController.wheel.hovers = {}

    for slot, data in pairs(self.slots) do
        table.insert(WheelController.wheel.borders, {
            id = slot,
            path = string.format(baseBorderPath, data.quadrant, data.index),
            height = "522",
            width = "522",
            index = data.index,
            selected = false
        })

        -- local baseColorSlotPath = "/images/game/wheel/wheel-colors/%s/slot%s/%s.png"
        local slotPath = string.format(baseColorSlotPath, data.quadrant, data.index, quadrantFrames[data.index])

        g_logger.info(string.format("slot id %d, index: %d, path: %s", slot, data.index, slotPath))

        table.insert(WheelController.wheel.colors, {
            id = slot,
            path = slotPath,
            -- path = string.format(baseWheelColorPath, data.quadrant, data.color, data.index),
            height = "522",
            width = "522",
            index = data.index,
            selected = data.currentPoints == data.totalPoints,
            adjacent = data.index == 1,
        })

        table.insert(WheelController.wheel.hovers, {
            id = slot,
            path = string.format(baseWheelColorPath, data.quadrant, data.color, data.index),
            height = "522",
            width = "522",
            index = data.index,
        })
    end

    propagateAdjacentSelection(WheelController.wheel.colors)
end

function WheelController.wheel:handleSlectSlot(slotId)
    g_logger.info("slotId: " .. slotId)
    if WheelController.wheel.currentSelectSlot == slotId then return end
    WheelController.wheel.currentSelectSlot = slotId
end

function WheelController:show(skipRequest)
    -- if not g_game.getFeature(GameForgeConvergence) then
    --     return WheelController:hide()
    -- end
    WheelController.wheel.currentSelectSlot = -1
    local player = g_game.getLocalPlayer()
    g_logger.info("player id: " .. tostring(player:getId()))
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
    for slot, point in pairs(data.wheelPoints) do
        if WheelSlotsParser[slot] then
            WheelSlotsParser[slot].currentPoints = point
        end
    end

    WheelController.wheel.slots = WheelSlotsParser
    WheelController.wheel:fillQuadrantsBorders()
end

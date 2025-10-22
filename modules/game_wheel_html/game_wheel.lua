WheelController = Controller:new()
WheelButton = nil

local baseButtonClip = { x = 0, y = 0, width = 322, height = 34 }
local baseButtonClipped = { x = 0, y = 34, width = 322, height = 34 }


WheelController.wheel = {
    clip = baseButtonClipped,
    backdropVocationOverlay = nil,
    borders = {},
    colors = {},
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
local baseBorderPath = "/images/game/wheel/wheel-border/%s/%s.png"
local baseWheelColorPath = "/images/game/wheel/wheel-colors/%s/%s_%s.png"
local otherBorders = { "revelationPerk", "vesselGem" }
function WheelController.wheel:fillQuadrantsBorders()
    WheelController.wheel.borders = {}
    for _, quadrant in pairs(quadrants) do
        for i = 1, 1 do
            table.insert(WheelController.wheel.borders, {
                id = string.format("%s_%s", quadrant, tostring(i)),
                path = string.format(baseBorderPath, quadrant, tostring(i)),
                height = "522",
                width = "522",
                selected = true
            })
        end

        -- local revelation = baseBorderPath:format(quadrant, otherBorders[1])
        -- table.insert(WheelController.wheel.borders, {
        --     id = string.format("%s_%s", quadrant, otherBorders[1]),
        --     path = revelation,
        --     height = "178",
        --     width = "179",
        --     selected = false,
        -- })

        -- local vesselGem = baseBorderPath:format(quadrant, otherBorders[2])
        -- table.insert(WheelController.wheel.borders, {
        --     id = string.format("%s_%s", quadrant, otherBorders[2]),
        --     path = vesselGem,
        --     height = "85",
        --     width = "119",
        --     selected = false,
        -- })
    end

    for _, color in pairs(colorQuadrants) do
        for i = 1, 1 do
            local _quadrant = quadrants[i]
            table.insert(WheelController.wheel.colors, {
                id = string.format("%s_%s", _quadrant, tostring(i)),
                path = string.format(baseWheelColorPath, _quadrant, color, tostring(i)),
                height = "522",
                width = "522",
                selected = true
            })
        end
    end
end

function WheelController.wheel:handleSelectBorder(borderId)
    g_logger.info("borderid: " .. borderId)
    for _, border in pairs(WheelController.wheel.borders) do
        if border.id == borderId then
            border.selected = not border.selected
        else
            border.selected = false
        end
    end
end

function WheelController:show(skipRequest)
    -- if not g_game.getFeature(GameForgeConvergence) then
    --     return WheelController:hide()
    -- end
    local player = g_game.getLocalPlayer()
    local basicVocationId = getBasicVocation(player:getVocation())
    local overlayImage = getVocationImage(basicVocationId)

    if not overlayImage then
        return WheelController:hide()
    end

    self.wheel.backdropVocationOverlay = overlayImage .. ".png"
    WheelController.wheel:fillQuadrantsBorders()

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
    self:registerEvents(g_game, {})

    if not WheelButton then
        WheelButton = modules.game_mainpanel.addToggleButton('WheelButton', tr('Open Wheel of Destiny'),
            '/images/options/wheel', function() self:toggle() end)
    end

    self.currentTab = 'wheel'
    WheelController:toggleMenu('wheel')
end

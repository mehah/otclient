WheelOfDestiny = {}

-- ============================================================================
-- CONFIGURATION AND CONSTANTS
-- ============================================================================

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
        [3] = '/images/game/wheel/wheel-vocations/backdrop_skillwheel_sorc',
        [4] = '/images/game/wheel/wheel-vocations/backdrop_skillwheel_druid',
        [5] = '/images/game/wheel/wheel-vocations/backdrop_skillwheel_monk'
    },
    
    -- Icon clips by vocation
    iconClips = {
        [1] = { -- Knight
            topLeft = "0 0 34 34",
            topRight = "34 0 34 34",
            bottomLeft = "68 0 34 34",
            bottomRight = "102 0 34 34"
        },
        [2] = { -- Paladin
            topLeft = "0 0 34 34",
            topRight = "136 0 34 34",
            bottomLeft = "170 0 34 34",
            bottomRight = "204 0 34 34"
        },
        [3] = { -- Sorcerer
            topLeft = "0 0 34 34",
            topRight = "238 0 34 34",
            bottomLeft = "272 0 34 34",
            bottomRight = "306 0 34 34"
        },
        [4] = { -- Druid
            topLeft = "0 0 34 34",
            topRight = "374 0 34 34",
            bottomLeft = "340 0 34 34",
            bottomRight = "408 0 34 34"
        },
        [5] = { -- Monk
            topLeft = "0 0 34 34",
            topRight = "442 0 34 34",
            bottomLeft = "476 0 34 34",
            bottomRight = "510 0 34 34"
        }
    },
    
    -- Bonus per step by vocation
    bonusSteps = {
        [1] = {life = 3, mana = 1, capacity = 5}, -- Knight
        [2] = {life = 2, mana = 3, capacity = 4}, -- Paladin
        [3] = {life = 1, mana = 6, capacity = 2}, -- Sorcerer
        [4] = {life = 1, mana = 6, capacity = 2}, -- Druid
        [5] = {life = 2, mana = 2, capacity = 4}  -- Monk
    }
}

-- ============================================================================
-- VOCATION UTILITIES
-- ============================================================================

local VocationUtils = {
    -- Converts promoted vocation to basic
    getBasicVocation = function(vocationId)
        return VocationConfig.promotedToBasic[vocationId] or vocationId
    end,
    
    -- Checks if it's a valid vocation
    isValidVocation = function(basicVocationId)
        return basicVocationId >= 1 and basicVocationId <= 5
    end,
    
    -- Checks if Monk is available in client version
    isMonkAvailable = function()
        return g_game.getClientVersion() > 1500
    end,
    
    -- Gets vocation image
    getVocationImage = function(basicVocationId)
        if basicVocationId == VocationConfig.MONK and not VocationUtils.isMonkAvailable() then
            return nil
        end
        return VocationConfig.images[basicVocationId]
    end
}

-- ============================================================================
-- ACCESS VALIDATION
-- ============================================================================

local AccessValidator = {
    -- Validates all access requirements
    validateAccess = function()
        local player = g_game.getLocalPlayer()
        if not player then
            return false, "Player not found"
        end
        
        local level = player:getLevel()
        local vocation = player:getVocation()
        local isPremium = player:isPremium()
        local basicVocation = VocationUtils.getBasicVocation(vocation)
        
        -- Check valid vocation
        if not VocationUtils.isValidVocation(basicVocation) then
            return false, AccessValidator.getErrorMessage()
        end
        
        -- Check minimum level
        if level < VocationConfig.MIN_LEVEL then
            return false, AccessValidator.getErrorMessage()
        end
        
        -- Check if promoted
        if vocation < VocationConfig.MIN_PROMOTED_VOCATION then
            return false, AccessValidator.getErrorMessage()
        end
        
        -- Check premium
        if not isPremium then
            return false, AccessValidator.getErrorMessage()
        end
        
        return true, nil
    end,
    
    getErrorMessage = function()
        return "To be able to use the Wheel of Destiny, a character must be at least level " .. 
               VocationConfig.MIN_LEVEL .. ", be promoted and have active Premium Time."
    end
}

-- ============================================================================
-- UI CONFIGURATORS
-- ============================================================================

local UIConfigurator = {
    -- Configures vocation overlay
    setupVocationOverlay = function(ui, basicVocationId)
        local overlayImage = VocationUtils.getVocationImage(basicVocationId)
        if not overlayImage then return end
        
        local overlay = ui:getChildById('vocationOverlay')
        if overlay then
            overlay:setImageSource(overlayImage)
            overlay:setVisible(true)
        end
    end,
    
    -- Configures vocation-specific icons
    setupVocationIcons = function(ui, basicVocationId)
        local clips = VocationConfig.iconClips[basicVocationId]
        if not clips then return end
        
        local iconIds = {"perkIconTopLeft", "perkIconTopRight", "perkIconBottomLeft", "perkIconBottomRight"}
        local clipKeys = {"topLeft", "topRight", "bottomLeft", "bottomRight"}
        
        for i, iconId in ipairs(iconIds) do
            local icon = ui:recursiveGetChildById(iconId)
            if icon then
                icon:setImageClip(clips[clipKeys[i]])
            end
        end
    end,
    
    -- Configures bonus overlays
    setupBonusOverlays = function(ui, showBonuses)
        local bonusWidgets = {'largeBonusTL', 'largeBonusTR', 'largeBonusBL', 'largeBonusBR'}
        
        for _, widgetId in ipairs(bonusWidgets) do
            local widget = ui:getChildById(widgetId)
            if widget then
                widget:setVisible(showBonuses or false)
            end
        end
    end,
    
    -- Configures data windows
    setupDataWindows = function(ui)
        local windowTitles = {
            leftWindow1 = "Selection",
            leftWindow2 = "Information",
            rightWindow1 = "Dedication Perks",
            rightWindow2 = "Conviction Perks",
            rightWindow3 = "Vessels",
            rightWindow4 = "Revelation Perks"
        }
        
        for windowId, title in pairs(windowTitles) do
            local window = ui:getChildById(windowId)
            if window then
                local titleLabel = window:getChildById(windowId:gsub("Window", "Title"))
                if titleLabel then
                    titleLabel:setText(title)
                end
                window:setVisible(true)
            end
        end
    end
}

-- ============================================================================
-- BONUS SYSTEM
-- ============================================================================

local BonusCalculator = {
    -- Gets bonus steps for a vocation
    getBonusSteps = function(basicVocationId)
        return VocationConfig.bonusSteps[basicVocationId] or {life = 1, mana = 1, capacity = 1}
    end,
    
    -- Calculates bonus based on vocation and number of steps
    calculateBonus = function(basicVocationId, bonusType, steps)
        local stepValues = BonusCalculator.getBonusSteps(basicVocationId)
        return (stepValues[bonusType] or 0) * (steps or 0)
    end
}

-- ============================================================================
-- PUBLIC API
-- ============================================================================

-- Main function to show the Wheel of Destiny
function WheelOfDestiny.show(container)
    -- Validate access
    local canAccess, errorMsg = AccessValidator.validateAccess()
    if not canAccess then
        displayErrorBox(tr('Info'), errorMsg)
        return
    end
    
    -- Load UI
    local wodUI = g_ui.loadUI('wod', container)
    if not wodUI then return end
    
    wodUI:fill('parent')
    
    -- Get player vocation
    local player = g_game.getLocalPlayer()
    local basicVocation = VocationUtils.getBasicVocation(player:getVocation())
    
    -- Configure UI based on vocation
    UIConfigurator.setupVocationOverlay(wodUI, basicVocation)
    UIConfigurator.setupVocationIcons(wodUI, basicVocation)
    UIConfigurator.setupBonusOverlays(wodUI, true)
    UIConfigurator.setupDataWindows(wodUI)
end

-- Function to check if can access the wheel
function WheelOfDestiny.canAccessWheel()
    return AccessValidator.validateAccess()
end

-- Function to calculate bonus by vocation
function WheelOfDestiny.calculateVocationBonus(bonusType, steps)
    local player = g_game.getLocalPlayer()
    if not player then return 0 end
    
    local basicVocation = VocationUtils.getBasicVocation(player:getVocation())
    return BonusCalculator.calculateBonus(basicVocation, bonusType, steps)
end

-- Function to get player's basic vocation
function WheelOfDestiny.getPlayerBasicVocation()
    local player = g_game.getLocalPlayer()
    if not player then return nil end
    
    return VocationUtils.getBasicVocation(player:getVocation())
end


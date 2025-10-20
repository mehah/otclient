local VocationInformation = dofile('wod_information.lua')

WheelOfDestiny = {}

local currentWodUI = nil

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
        [3] = '/images/game/wheel/wheel-vocations/backdrop_skillwheel_sorcerer',
        [4] = '/images/game/wheel/wheel-vocations/backdrop_skillwheel_druid',
        [5] = '/images/game/wheel/wheel-vocations/backdrop_skillwheel_monk'
    },
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
local baseQuadrantValues = { 50, 75, 75, 100, 100, 100, 150, 150, 200 }
local QuadrantProgressConfig = {
    topLeft = {
        slicePrefix = 'colorTopLeft',
        totals = baseQuadrantValues
    }
}

local function applyQuadrantSliceProgress(ui, quadrantKey, sliceIndex, value, total)
    local numericIndex = tonumber(sliceIndex)
    if not numericIndex then
        return
    end

    local quadrantConfig = QuadrantProgressConfig[quadrantKey]
    if not quadrantConfig then
        return
    end

    local sliceId = string.format('%s%d', quadrantConfig.slicePrefix, numericIndex)
    local sliceWidget = ui:recursiveGetChildById(sliceId)

    if not sliceWidget then
        return
    end

    local resolvedTotal = total
    if resolvedTotal == nil then
        resolvedTotal = quadrantConfig.totals and quadrantConfig.totals[numericIndex]
    end

    resolvedTotal = tonumber(resolvedTotal) or 0

    if resolvedTotal <= 0 then
        sliceWidget:setOpacity(0)
        sliceWidget:setTooltip(nil)
        return
    end

    local numericValue = tonumber(value) or 0
    local sanitizedValue = math.max(0, numericValue)
    local clampedValue = math.min(sanitizedValue, resolvedTotal)
    local progress = clampedValue / resolvedTotal

    sliceWidget:setOpacity(progress)
    sliceWidget:setTooltip(string.format('%d/%d', sanitizedValue, resolvedTotal))
end

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

    resetQuadrantSlices = function(ui, quadrantKey)
        local quadrantConfig = QuadrantProgressConfig[quadrantKey]
        if not quadrantConfig then
            return
        end

        for index, defaultTotal in ipairs(quadrantConfig.totals or {}) do
            applyQuadrantSliceProgress(ui, quadrantKey, index, 0, defaultTotal)
        end
    end,

    setQuadrantSliceProgress = function(ui, quadrantKey, sliceIndex, value, total)
        applyQuadrantSliceProgress(ui, quadrantKey, sliceIndex, value, total)
    end,


    -- Configures bonus overlays
    setupBonusOverlays = function(ui, showBonuses)
        local bonusWidgets = { 'largeBonusTL', 'largeBonusTR', 'largeBonusBL', 'largeBonusBR' }

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
            dedicationPerksPanel = "Dedication Perks",
            convictionPerksPanel = "Conviction Perks",
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
    end,

    setupVocationInformation = function(ui, basicVocationId)
        -- Dedication Perks
        local infoDedicationMitigation = ui:recursiveGetChildById('infoDedicationMitigation')
        if infoDedicationMitigation and VocationInformation.dedication[1][basicVocationId] then
            infoDedicationMitigation:setTooltip(VocationInformation.dedication[1][basicVocationId])
        end

        -- Conviction Perks Panel Info Icon
        local convictionPanel = ui:getChildById('convictionPerksPanel')
        if convictionPanel then
            local infoConvictionPerks = convictionPanel:getChildById('infoConvictionPerks')
            if infoConvictionPerks and VocationInformation.conviction[1] and
                VocationInformation.conviction[1][basicVocationId] then
                infoConvictionPerks:setTooltip(VocationInformation.conviction[1][basicVocationId])
            end
        end

        -- Conviction Perks (6 icons)
        for i = 2, 6 do
            local infoConviction = ui:recursiveGetChildById('infoConviction' .. i)
            if infoConviction and VocationInformation.conviction[i] and
                VocationInformation.conviction[i][basicVocationId] then
                infoConviction:setTooltip(VocationInformation.conviction[i][basicVocationId])
            end
        end

        -- Vessels
        local infoVessel1 = ui:recursiveGetChildById('infoVessel1')
        if infoVessel1 and VocationInformation.vessels[1][basicVocationId] then
            infoVessel1:setTooltip(VocationInformation.vessels[1][basicVocationId])
        end

        -- Summary (11 icons)
        for i = 1, 11 do
            local infoSummary = ui:recursiveGetChildById('infoSummary' .. i)
            if infoSummary and VocationInformation.summary[i] and
                VocationInformation.summary[i][basicVocationId] then
                infoSummary:setTooltip(VocationInformation.summary[i][basicVocationId])
            end
        end

        -- Revelation Perks (5 icons)
        for i = 1, 5 do
            local infoRevelation = ui:recursiveGetChildById('infoRevelation' .. i)
            if infoRevelation and VocationInformation.revelation[i] and
                VocationInformation.revelation[i][basicVocationId] then
                infoRevelation:setTooltip(VocationInformation.revelation[i][basicVocationId])
            end
        end
    end,

    updateDedicationStats = function(ui, hitPoints, mana, capacity, mitigationMult)
        local hpWidget = ui:recursiveGetChildById('dedicationHitPoints')
        if hpWidget then
            local valueLabel = hpWidget:getChildById('value')
            if valueLabel then
                valueLabel:setText(tostring(hitPoints))
            end
        end

        local manaWidget = ui:recursiveGetChildById('dedicationMana')
        if manaWidget then
            local valueLabel = manaWidget:getChildById('value')
            if valueLabel then
                valueLabel:setText(tostring(mana))
            end
        end

        local capacityWidget = ui:recursiveGetChildById('dedicationCapacity')
        if capacityWidget then
            local valueLabel = capacityWidget:getChildById('value')
            if valueLabel then
                valueLabel:setText(tostring(capacity))
            end
        end

        local mitigationWidget = ui:recursiveGetChildById('dedicationMitigation')
        if mitigationWidget then
            local valueLabel = mitigationWidget:getChildById('value')
            if valueLabel then
                valueLabel:setText(string.format("%.2f%%", mitigationMult))
            end
        end
    end
}

-- ============================================================================
-- BONUS SYSTEM
-- ============================================================================

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

    currentWodUI = wodUI

    wodUI:fill('parent')

    -- Get player vocation
    local player = g_game.getLocalPlayer()
    local basicVocation = VocationUtils.getBasicVocation(player:getVocation())

    -- Configure UI based on vocation
    UIConfigurator.setupVocationOverlay(wodUI, basicVocation)
    UIConfigurator.setupBonusOverlays(wodUI, true)
    UIConfigurator.setupDataWindows(wodUI)
    UIConfigurator.setupVocationInformation(wodUI, basicVocation)
    UIConfigurator.resetQuadrantSlices(wodUI, 'topLeft')

    -- Conectar ambos os botões summary
    local summaryButton = wodUI:getChildById('summaryButton')
    local summaryButtonInside = wodUI:recursiveGetChildById('summaryButtonInside')

    if summaryButton then
        connect(summaryButton, {
            onCheckChange = WheelOfDestiny.toggleSummaryPanel
        })
    end

    if summaryButtonInside then
        connect(summaryButtonInside, {
            onCheckChange = WheelOfDestiny.toggleSummaryPanel
        })
    end
end

-- Function to check if can access the wheel
function WheelOfDestiny.canAccessWheel()
    return AccessValidator.validateAccess()
end

function WheelOfDestiny.updateDedicationStats(hitPoints, mana, capacity, mitigationMult)
    if currentWodUI then
        UIConfigurator.updateDedicationStats(currentWodUI, hitPoints, mana, capacity, mitigationMult)
    end
end

function WheelOfDestiny.updateSlicesProgress(quadrantKey, progressList)
    if not currentWodUI or type(progressList) ~= 'table' then
        return
    end

    if not quadrantKey or not type(quadrantKey) == 'string' then
        return
    end

    for index, entry in pairs(progressList) do
        local numericIndex = tonumber(index)
        if numericIndex then
            local value
            local total

            if type(entry) == 'table' then
                value = entry.value or entry.current or entry[1] or 0
                total = entry.total or entry[2]
            else
                value = entry
            end

            applyQuadrantSliceProgress(currentWodUI, quadrantKey, numericIndex, value, total)
        end
    end
end

-- Function to get player's basic vocation
function WheelOfDestiny.getPlayerBasicVocation()
    local player = g_game.getLocalPlayer()
    if not player then return nil end

    return VocationUtils.getBasicVocation(player:getVocation())
end

function WheelOfDestiny.toggleSummaryPanel(widget, checked)
    if not currentWodUI then
        return
    end

    local summaryPanel = currentWodUI:getChildById('summaryPanel')
    local summaryButton = currentWodUI:getChildById('summaryButton')
    local summaryButtonInside = currentWodUI:recursiveGetChildById('summaryButtonInside')

    if not summaryPanel then return end

    -- Toggle da visibilidade do painel baseado no estado do checkbox
    summaryPanel:setVisible(checked)

    -- Traz o painel para frente quando visível
    if checked then
        summaryPanel:raise()
        summaryPanel:setPhantom(false)
    end

    -- Sincroniza o estado de ambos os botões
    if summaryButton then
        summaryButton:setChecked(checked)
    end
    if summaryButtonInside then
        summaryButtonInside:setChecked(checked)
    end
end

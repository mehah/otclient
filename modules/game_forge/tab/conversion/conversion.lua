-- Todo
-- change to TypeScript

local ConversionTab = {}

local function resolveConversionDependencies(controller, dependencies)
    dependencies = dependencies or {}

    if not dependencies.resourceTypes then
        dependencies.resourceTypes = controller and controller.conversionResourceTypes or nil
    end

    if not dependencies.actions then
        dependencies.actions = controller and controller.conversionActions or nil
    end

    return dependencies
end

function ConversionTab.formatDustAmount(controller, value)
    local numericValue = tonumber(value) or 0
    local maxDust = 100

    if controller then
        maxDust = tonumber(controller.maxDustLevel)
            or tonumber(controller.currentDustLevel)
            or maxDust
    end

    if not maxDust or maxDust <= 0 then
        return tostring(numericValue)
    end

    g_logger.info(">>" .. string.format('%d/%d', numericValue, maxDust))
    return string.format('%d/%d', numericValue, maxDust)
end

function ConversionTab.updateDustLevelLabel(controller, panel, dustLevel, dependencies)
    dependencies = resolveConversionDependencies(controller, dependencies)
    panel = panel or (ui.panels and ui.panels['conversion'])
    if not panel or panel:isDestroyed() then
        return
    end

    g_logger.info(">>>>updateDustLevelLabel")

    local dustLevelLabel = panel:recursiveGetChildById('forgeDustLevel')
    if not dustLevelLabel or dustLevelLabel:isDestroyed() then
        return
    end

    local dustLevelValue = dustLevel or tonumber(controller.currentDustLevel)
        or tonumber(controller.maxDustLevel) or 0
    local displayedDustLevel = math.max(dustLevelValue - 75, 0)
    dustLevelLabel:setText(tostring(displayedDustLevel))
    g_logger.info("displayedDustLevel > " .. displayedDustLevel)

    local forgeIncreaseDustCurrentLevelLabel = panel:recursiveGetChildById('forgeIncreaseDustCurrentLevel')
    if forgeIncreaseDustCurrentLevelLabel and not forgeIncreaseDustCurrentLevelLabel:isDestroyed() then
        forgeIncreaseDustCurrentLevelLabel:setText(("Raise limit from %d"):format(dustLevelValue))

        g_logger.info("forgeIncreaseDustCurrentLevelLabel > " .. dustLevelValue)
    end
    local forgeIncreaseDustNextLevelLabel = panel:recursiveGetChildById('forgeIncreaseDustNextLevel')
    if forgeIncreaseDustNextLevelLabel and not forgeIncreaseDustNextLevelLabel:isDestroyed() then
        forgeIncreaseDustNextLevelLabel:setText(("to %d"):format(dustLevelValue + 1))
        g_logger.info("forgeIncreaseDustNextLevelLabel > " .. dustLevelValue + 1)
    end

end

function ConversionTab.onConversion(controller, conversionType, dependencies)
    if not controller or not controller.ui then
        return
    end

    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    dependencies = resolveConversionDependencies(controller, dependencies)
    local resourceTypes = dependencies.resourceTypes or {}
    local actions = dependencies.actions or {}

    local function finalizeConversion()
        controller:updateFusionCoreButtons()
        controller:updateResourceBalances(resourceTypes.dust)
        controller:updateDustLevelLabel()
    end

    if conversionType == actions.DUST2SLIVER then
        local dustType = resourceTypes.dust
        local dustBalance = dustType and player:getResourceBalance(dustType) or 0
        if dustBalance <= 60 then
            return
        end
        g_game.forgeRequest(conversionType)
        finalizeConversion()
        return
    end

    if conversionType == actions.SLIVER2CORE then
        local sliverType = resourceTypes.sliver
        local sliverBalance = sliverType and player:getResourceBalance(sliverType) or 0
        if sliverBalance <= 50 then
            return
        end
        g_game.forgeRequest(conversionType)
        finalizeConversion()
        return
    end

    if conversionType == actions.INCREASELIMIT then
        local dustType = resourceTypes.dust
        local dustBalance = dustType and player:getResourceBalance(dustType) or 0
        local maxDustLevel = tonumber(controller.currentDustLevel)
            or tonumber(controller.maxDustLevel) or 0
        local currentNecessaryDust = maxDustLevel - 75
        local maxDustCap = tonumber(controller.maxDustCap) or 0

        if maxDustCap > 0 and maxDustLevel >= maxDustCap then
            return
        end

        if dustBalance < currentNecessaryDust then
            return
        end
        g_game.forgeRequest(conversionType)

        local newDustLevel = maxDustLevel + 1
        if maxDustCap > 0 then
            newDustLevel = math.min(newDustLevel, maxDustCap)
        end

        controller.currentDustLevel = newDustLevel
        if not controller.maxDustLevel or controller.maxDustLevel < newDustLevel then
            controller.maxDustLevel = newDustLevel
        end

        finalizeConversion()
        return
    end

    finalizeConversion()
end

function ConversionTab.onTabLoaded(controller, tabName, panel)
    if tabName ~= 'conversion' then
        return
    end

    ConversionTab.updateDustLevelLabel(controller, panel)
end

function ConversionTab.applyInitialValues(controller, openData)
    local maxDustLevel = tonumber(openData.maxDustLevel)
        or tonumber(openData.maxDust)
        or tonumber(openData.dustLevel)

    g_logger.info("maxDustLevel: " .. tostring(maxDustLevel))

    if maxDustLevel and maxDustLevel >= 0 then
        controller.maxDustLevel = maxDustLevel
    end

    local currentDustLevel = tonumber(openData.currentDustLevel)
        or tonumber(openData.dustLevel)

    if currentDustLevel and currentDustLevel >= 0 then
        controller.currentDustLevel = currentDustLevel
    end

    local maxDustCap = tonumber(openData.maxDustCap)
    if maxDustCap and maxDustCap >= 0 then
        controller.maxDustCap = maxDustCap
    end

    if (not controller.maxDustLevel or controller.maxDustLevel <= 0) and controller.currentDustLevel then
        controller.maxDustLevel = controller.currentDustLevel
    end

    if (not controller.currentDustLevel or controller.currentDustLevel <= 0) and controller.maxDustLevel then
        controller.currentDustLevel = controller.maxDustLevel
    end

    ConversionTab.updateDustLevelLabel(controller, ui.panels and ui.panels['conversion'], maxDustLevel)
end

function ConversionTab.onOpenForge(controller)
    ConversionTab.updateDustLevelLabel(controller, ui.panels and ui.panels['conversion'])
end

function ConversionTab.registerDependencies(controller, dependencies)
    dependencies = resolveConversionDependencies(controller, dependencies)

    if controller then
        controller.conversionResourceTypes = dependencies.resourceTypes
        controller.conversionActions = dependencies.actions
    end
end

function showConversion()
    return forgeController:loadTab('conversion')
end

return ConversionTab

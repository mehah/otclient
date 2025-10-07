local windowTypes = {}
local TAB_ORDER = { 'fusion', 'transfer', 'conversion', 'history' }
local TAB_CONFIG = {
    fusion = {
        modeProperty = 'modeFusion'
    },
    transfer = {
        modeProperty = 'modeTransfer'
    },
    conversion = {},
    history = {}
}

ui = {
    panels = {}
}
forgeController = Controller:new()
forgeController.historyState = {
    page = 1,
    lastPage = 1,
    currentCount = 0
}

local forgeButton

local forgeResourceTypes = {
    dust = ResourceTypes and ResourceTypes.FORGE_DUST or 70,
    sliver = ResourceTypes and ResourceTypes.FORGE_SLIVER or 71,
    cores = ResourceTypes and ResourceTypes.FORGE_CORES or 72
}

local forgeActions = {
    FUSION = 0,
    TRANSFER = 1,
    DUST2SLIVER = 2,
    SLIVER2CORE = 3,
    INCREASELIMIT = 4,
}

-- local fusionTab = require('modules.game_forge.tab.fusion.fusion')
local helpers = require('modules.game_forge.game_forge_helpers')

-- fusionTab.registerDependencies(forgeController, {
--     resourceTypes = forgeResourceTypes
-- })

local cloneValue = helpers.cloneValue
local normalizeTierPriceEntries = helpers.normalizeTierPriceEntries
local normalizeClassPriceEntries = helpers.normalizeClassPriceEntries
local normalizeFusionGradeEntries = helpers.normalizeFusionGradeEntries
local defaultResourceFormatter = helpers.defaultResourceFormatter
local formatGoldAmount = helpers.formatGoldAmount
local formatHistoryDate = helpers.formatHistoryDate
local resolveStatusWidget = helpers.resolveStatusWidget

local function loadTabFragment(tabName)
    return helpers.loadTabFragment(forgeController, tabName)
end


local forgeResourceConfig = {}


local historyActionLabels = {
    [0] = tr('Fusion'),
    [1] = tr('Transfer'),
    [2] = tr('Conversion'),
    [3] = tr('Conversion'),
    [4] = tr('Conversion')
}

local function setWindowState(window, enabled)
    if window.obj then
        window.obj:setOn(not enabled)
        if enabled then
            window.obj:enable()
        else
            window.obj:disable()
        end
    end
end

local function hideAllPanels()
    for _, panel in pairs(ui.panels) do
        if panel and panel.hide then
            panel:hide()
        end
    end
end

local function resetWindowTypes()
    for key in pairs(windowTypes) do
        windowTypes[key] = nil
    end
end

local function show(self, skipRequest)
    local needsReload = not self.ui or self.ui:isDestroyed()
    if needsReload then
        self:loadHtml('game_forge.html')
        ui.panels = {}
        -- fusionTab.invalidateContext(self)
    end

    if not self.ui then
        return
    end

    if not skipRequest then
        g_game.openPortableForgeRequest()
    end

    self.modeFusion, self.modeTransfer = false, false

    resetWindowTypes()

    for _, tabName in ipairs(TAB_ORDER) do
        self:loadTab(tabName)
    end

    hideAllPanels()

    local buttonPanel = self.ui.buttonPanel
    for tabName, config in pairs(TAB_CONFIG) do
        windowTypes[tabName .. 'Menu'] = {
            obj = buttonPanel and buttonPanel[tabName .. 'Btn'],
            panel = tabName,
            modeProperty = config.modeProperty
        }
    end

    self.ui:centerIn('parent')
    self.ui:show()
    self.ui:raise()
    self.ui:focus()

    if forgeButton then
        forgeButton:setOn(true)
    end

    SelectWindow('fusionMenu')
    self:updateResourceBalances()
end

local function hide()
    if not forgeController.ui then
        return
    end

    forgeController.ui:hide()

    if forgeButton then
        forgeButton:setOn(false)
    end
end


local baseSelectedFusionItem = {
    id = -1,
    tier = 0,
    clip = {},
    imagePath = nil,
    rarityClipObject = nil,
    count = 0
}
forgeController.selectedFusionItem = baseSelectedFusionItem
forgeController.selectedFusionItemTarget = baseSelectedFusionItem

function forgeController:close()
    hide()
end

local function toggle(self)
    forgeController.fusionPrice = "???"
    forgeController.fusionChanceImprovedIsChecked = false
    forgeController.fusionReduceTierLossIsChecked = false
    forgeController.selectedFusionItem = baseSelectedFusionItem
    forgeController.selectedFusionConvergenceItem = baseSelectedFusionItem
    forgeController.selectedFusionItemTarget = baseSelectedFusionItem
    forgeController.fusionConvergence = false
    forgeController.fusionConvergenceTitle = nil
    forgeController.fusionConvergenceList = {}
    if not self.ui or self.ui:isDestroyed() then
        show(self)
        return
    end

    if self.ui:isVisible() then
        hide()
    else
        show(self)
    end
end

function forgeController:toggle()
    toggle(self)
end

function forgeController:show(skipRequest)
    show(self, skipRequest)
end

function forgeController:hide()
    forgeController.fusionPrice = "???"
    forgeController.fusionChanceImprovedIsChecked = false
    forgeController.fusionReduceTierLossIsChecked = false
    forgeController.selectedFusionItem = baseSelectedFusionItem
    forgeController.selectedFusionConvergenceItem = baseSelectedFusionItem
    forgeController.selectedFusionItemTarget = baseSelectedFusionItem
    forgeController.fusionConvergence = false
    forgeController.fusionConvergenceTitle = nil
    forgeController.fusionConvergenceList = {}
    hide()
end

local function updateStatusConfig(controller, config, player)
    local widget = resolveStatusWidget(controller, config)
    if not widget then
        return
    end

    local amount = 0
    if config.getValue then
        amount = config.getValue(player) or 0
    elseif player and config.resourceType then
        amount = player:getResourceBalance(config.resourceType) or 0
    end

    local formatter = config.formatter or defaultResourceFormatter
    widget:setText(formatter(amount))
end

function forgeController:updateResourceBalances(resourceType)
    if not self.ui then
        return
    end

    local player = g_game.getLocalPlayer()

    if resourceType then
        local config = forgeResourceConfig[resourceType]
        if config then
            updateStatusConfig(self, config, player)
        end
    end
    -- if not resourceType or resourceType == forgeResourceTypes.cores then
    --     self:updateFusionCoreButtons()
    -- end
end

-- function forgeController:updateFusionCoreButtons()
--     fusionTab.updateFusionCoreButtons(self)
-- end

-- function forgeController:onToggleFusionCore(coreType)
--     fusionTab.onToggleFusionCore(self, coreType)
-- end

function forgeController:onInit()
    connect(g_game, {
        onBrowseForgeHistory = onBrowseForgeHistory,
        forgeData = forgeData,
    })

    if not forgeButton then
        forgeButton = modules.game_mainpanel.addToggleButton('forgeButton', tr('Open Exaltation Forge'),
            '/images/options/button-exaltation-forge.png', function() toggle(self) end)
    end

    self:registerEvents(g_game, {
        onResourcesBalanceChange = function(_, _, resourceType)
            if forgeResourceConfig[resourceType] then
                self:updateResourceBalances(resourceType)
            end
        end
    })
end

function SelectWindow(type, isBackButtonPress)
    local nextWindow = windowTypes[type]
    if not nextWindow then
        return
    end

    for windowType, window in pairs(windowTypes) do
        if windowType ~= type then
            setWindowState(window, true)
        end
    end

    setWindowState(nextWindow, false)
    forgeController.currentWindowType = type

    hideAllPanels()
    local panel = forgeController:loadTab(nextWindow.panel)
    if panel then
        panel:show()
        panel:raise()
    end

    if type == "historyMenu" then
        if not isBackButtonPress then
            g_game.sendForgeBrowseHistoryRequest(1)
        end
    end
end

function forgeController:loadTab(tabName)
    if ui.panels[tabName] then
        return ui.panels[tabName]
    end

    local panel = loadTabFragment(tabName)
    if panel then
        ui.panels[tabName] = panel
    end
    return panel
end

function forgeController:getCurrentWindow()
    return self.currentWindowType and windowTypes[self.currentWindowType]
end

forgeController.historyCurrentPage = 1
forgeController.historyLastPage = 1
function onBrowseForgeHistory(page, lastPage, currentCount, historyList)
    page = math.max(tonumber(page) or 1, 1)
    lastPage = math.max(tonumber(lastPage) or page, 1)
    currentCount = tonumber(currentCount) or 0
    lastPage = lastPage > 1 and lastPage - 1 or lastPage

    forgeController.historyCurrentPage = page
    forgeController.historyLastPage = lastPage

    forgeController.historyMustDisablePreviousButton = page <= 1
    forgeController.historyMustDisableNextButton = page == lastPage

    local historyPanel = forgeController:loadTab('history')
    if not historyPanel then
        return
    end

    for index, entry in ipairs(historyList) do
        entry.createdAt = formatHistoryDate(entry.createdAt)
        entry.actionType = historyActionLabels[entry.actionType]
        entry.description = entry.description or '-'
    end
    forgeController.historyList = historyList or {}
end

function forgeController:onHistoryPreviousPage()
    local currentPage = forgeController.historyCurrentPage or 1
    g_logger.info("onHistoryPreviousPage>Current page: " .. tostring(currentPage))
    if currentPage <= 1 then
        return
    end

    g_game.sendForgeBrowseHistoryRequest(currentPage - 1)
end

function forgeController:onHistoryNextPage()
    local currentPage = forgeController.historyCurrentPage or 1
    g_logger.info("onHistoryNextPage>Current page: " .. tostring(currentPage))
    local lastPage = forgeController.historyLastPage or currentPage

    if currentPage >= lastPage then
        return
    end

    g_game.sendForgeBrowseHistoryRequest(currentPage + 1)
end

function forgeController:onTerminate()
    disconnect(g_game, {
        onBrowseForgeHistory = onBrowseForgeHistory,
        forgeData = forgeData,
    })
end

function forgeController:onGameStart()
    g_ui.importStyle('otui/style.otui')
    if not self.ui or self.ui:isDestroyed() then
        self:loadHtml('game_forge.html')
        ui.panels = {}
        -- fusionTab.invalidateContext(self)
    end

    resetWindowTypes()

    if self.ui then
        self.ui:hide()
    end

    self.historyState = {
        page = 1,
        lastPage = 1,
        currentCount = 0
    }

    -- fusionTab.resetCoreSelections(self)
end

function forgeController:onGameEnd()
    if self.ui and self.ui:isVisible() then
        self.ui:hide()
    end

    if forgeButton then
        forgeButton:setOn(false)
    end
end

function forgeController:setInitialValues(openData)
    if type(openData) ~= 'table' then
        openData = {}
    end

    self.openData = cloneValue(openData)

    self.initialValues = {}

    for key, value in pairs(openData) do
        if type(key) == 'string' then
            self.initialValues[key] = cloneValue(value)
        end
    end

    self.fusionItems = cloneValue(openData.fusionItems or self.fusionItems or {})
    self.convergenceFusion = cloneValue(openData.convergenceFusion or self.convergenceFusion or {})
    self.transfers = cloneValue(openData.transfers or self.transfers or {})
    self.convergenceTransfers = cloneValue(openData.convergenceTransfers or self.convergenceTransfers or {})

    local trackedKeys = {
        'fusionPrices',
        'convergenceFusionPrices',
        'transferPrices',
        'convergenceTransferPrices',
        'normalDustFusion',
        'convergenceDustFusion',
        'normalDustTransfer',
        'convergenceDustTransfer',
        'fusionChanceBase',
        'fusionChanceImproved',
        'fusionReduceTierLoss',
        'fusionNormalValues',
        'fusionConvergenceValues',
        'transferNormalValues',
        'transferConvergenceValues'
    }

    for _, key in ipairs(trackedKeys) do
        if openData[key] ~= nil then
            self[key] = cloneValue(openData[key])
        end
    end
end

forgeController.conversionNecessaryDustToIncrease = 25
forgeController.conversionRaiseFrom = 100
forgeController.conversionRaiseTo = 101
function forgeController:applyForgeConfiguration(config)
    if type(config) ~= 'table' then
        return
    end

    self.forgeConfiguration = cloneValue(config)

    local initial = {}

    local classPrices = normalizeClassPriceEntries(config.classPrices or config.fusionPrices)
    if next(classPrices) then
        initial.fusionPrices = classPrices
    end

    local convergenceFusion = normalizeTierPriceEntries(config.convergenceFusionPrices)
    if next(convergenceFusion) then
        initial.convergenceFusionPrices = convergenceFusion
    end

    local convergenceTransfer = normalizeTierPriceEntries(config.convergenceTransferPrices)
    if next(convergenceTransfer) then
        initial.convergenceTransferPrices = convergenceTransfer
    end

    local fusionGrades = normalizeFusionGradeEntries(config.fusionGrades or config.fusionNormalValues)
    if next(fusionGrades) then
        initial.fusionNormalValues = fusionGrades
    end

    local fusionConvergenceValues = normalizeTierPriceEntries(config.fusionConvergenceValues)
    if next(fusionConvergenceValues) then
        initial.fusionConvergenceValues = fusionConvergenceValues
    end

    local transferNormalValues = normalizeTierPriceEntries(config.transferNormalValues)
    if next(transferNormalValues) then
        initial.transferNormalValues = transferNormalValues
    end

    local transferConvergenceValues = normalizeTierPriceEntries(config.transferConvergenceValues)
    if next(transferConvergenceValues) then
        initial.transferConvergenceValues = transferConvergenceValues
    end

    local numericFields = {
        normalDustFusion = config.normalDustFusion,
        convergenceDustFusion = config.convergenceDustFusion,
        normalDustTransfer = config.normalDustTransfer,
        convergenceDustTransfer = config.convergenceDustTransfer,
        fusionChanceBase = config.fusionChanceBase,
        fusionChanceImproved = config.fusionChanceImproved,
        fusionReduceTierLoss = config.fusionReduceTierLoss,
        dustPercent = config.dustPercent,
        dustToSliver = config.dustToSliver,
        sliverToCore = config.sliverToCore,
        dustPercentUpgrade = config.dustPercentUpgrade,
        maxDustLevel = config.maxDustLevel or config.maxDust,
        maxDustCap = config.maxDustCap,
    }

    for key, value in pairs(numericFields) do
        local numericValue = tonumber(value)
        if numericValue then
            initial[key] = numericValue

            g_logger.info("key: " .. tostring(key) .. " value: " .. tostring(numericValue))
        end
    end

    forgeController.maxDustCap = tonumber(numericFields.maxDustCap) or 225
    forgeController.maxDustLevel = numericFields.maxDustLevel or 0
    forgeController.conversionNecessaryDustToIncrease = math.max((forgeController.maxDustLevel - 75), 25)
    if forgeController.maxDustLevel >= forgeController.maxDustCap then
        forgeController.conversionRaiseFrom = "You have reached the maximum dust limit"
    else
        forgeController.conversionRaiseFrom = ("Raise limit from %d to %d"):format(forgeController.maxDustLevel,
            forgeController.maxDustLevel + 1)
    end
    local player = g_game.getLocalPlayer()
    forgeController.currentDust = player:getResourceBalance(forgeResourceTypes.dust) or 0
    forgeController.dustToSliver = numericFields.dustToSliver or 3
    forgeController.conversionNecessaryDustToSliver = 60

    forgeController.mustDisableConvertDustToSliverButton = forgeController.currentDust <
        forgeController.conversionNecessaryDustToSliver
    forgeController.conversionNecessaryDustToSliverLabel = forgeController.mustDisableConvertDustToSliverButton and "red" or
        "white"

    forgeController.mustDisableIncreaseDustLimitButton = forgeController.currentDust <
        forgeController.conversionNecessaryDustToIncrease
    forgeController.conversionNecessaryDustToIncreaseLabel = forgeController.mustDisableIncreaseDustLimitButton and "red" or
        "white"

    forgeController.currentDustLevel = ("%d / %d"):format(forgeController.currentDust, forgeController.maxDustLevel)
    forgeController.currentSlivers = player:getResourceBalance(forgeResourceTypes.sliver) or 0
    forgeController.sliverToCore = numericFields.sliverToCore or 50
    forgeController.mustDisableConvertSliverToCoreButton = forgeController.currentSlivers <
        forgeController.sliverToCore
    forgeController.conversionNecessarySliverToCoreLabel = forgeController.mustDisableConvertSliverToCoreButton and "red" or
        "white"

    forgeController.currentExaltedCores = player:getResourceBalance(forgeResourceTypes.cores) or 0
    forgeController.rawCurrentGold = player:getTotalMoney() or 0
    forgeController.currentGold = formatGoldAmount(forgeController.rawCurrentGold)

    self:setInitialValues(initial)

    forgeController.normalDustFusion = numericFields.normalDustFusion or 100
    forgeController.convergenceDustFusion = numericFields.convergenceDustFusion or 130

    forgeController.fusionPlayerHasDustToNormalFusion = (forgeController.currentDust >= forgeController.normalDustFusion) and
        "white" or "red"
    forgeController.fusionPlayerHasDustToConvergenceFusion = (forgeController.currentDust >= forgeController.convergenceDustFusion) and
        "white" or "red"

    forgeController.fusionPlayerHasExaltedCoreToImproveRateSuccess = (forgeController.currentExaltedCores >= 1) and
        "white" or "red"
    forgeController.fusionPlayerHasExaltedCoreToReduceTierLoss = (forgeController.currentExaltedCores >= 1) and
        "white" or "red"

    forgeController.fusionDisableImproveRateSuccessButton = (forgeController.currentExaltedCores < 1)
    forgeController.fusionDisableReduceTierLossButton = (forgeController.currentExaltedCores < 1)

    forgeController.fusionReduceTierLoss = numericFields.fusionReduceTierLoss or 50
    forgeController.fusionReduceTierLossLabel = ("Reduce to %d%%"):format(forgeController.fusionReduceTierLoss)

    forgeController.fusionChanceBase = numericFields.fusionChanceBase or 50
    forgeController.fusionTierLossChanceBase = 100
    forgeController.fusionTierLossChanceBaseLabel = ("%d%%"):format(forgeController.fusionTierLossChanceBase)
    forgeController.fusionChanceBaseLabel = ("%d%%"):format(forgeController.fusionChanceBase)

    forgeController.fusionChanceImproved = numericFields.fusionChanceImproved or 15
    forgeController.fusionChanceImprovedLabel = ("Increase to %d%%"):format(forgeController.fusionChanceImproved +
        forgeController.fusionChanceBase)
end

forgeController.fusionChanceImprovedIsChecked = false
forgeController.fusionReduceTierLossIsChecked = false
function forgeController:onFusionImproveChanceChange(improveType)
    if improveType == 1 then
        self.fusionChanceImprovedIsChecked = not self.fusionChanceImprovedIsChecked
        if self.fusionChanceImprovedIsChecked then
            if self.currentExaltedCores == 1 then
                self.fusionDisableReduceTierLossButton = true
                self.fusionPlayerHasExaltedCoreToReduceTierLoss = "red"
            end
            self.fusionChanceBaseLabel = ("%d%%"):format(self.fusionChanceBase +
                self.fusionChanceImproved)
            self.fusionPlayerHasExaltedCoreToImproveRateSuccess = "green"
        else
            self.fusionPlayerHasExaltedCoreToImproveRateSuccess = (self.currentExaltedCores >= 1) and
                "white" or "red"

            self.fusionChanceBaseLabel = ("%d%%"):format(self.fusionChanceBase)

            if self.fusionDisableReduceTierLossButton and not self.fusionReduceTierLossIsChecked then
                self.fusionDisableReduceTierLossButton = false
            end
        end
    end

    if improveType == 2 then
        self.fusionReduceTierLossIsChecked = not self.fusionReduceTierLossIsChecked
        if self.fusionReduceTierLossIsChecked then
            if self.currentExaltedCores == 1 then
                self.fusionDisableImproveRateSuccessButton = true
                self.fusionPlayerHasExaltedCoreToImproveRateSuccess = "red"
            end

            self.fusionPlayerHasExaltedCoreToReduceTierLoss = "green"

            self.fusionTierLossChanceBaseLabel = ("%d%%"):format(self.fusionTierLossChanceBase -
                self.fusionReduceTierLoss)
        else
            self.fusionPlayerHasExaltedCoreToReduceTierLoss = (self.currentExaltedCores >= 1) and
                "white" or "red"

            self.fusionTierLossChanceBaseLabel = ("%d%%"):format(self.fusionTierLossChanceBase)

            if self.fusionDisableImproveRateSuccessButton and not self.fusionChanceImprovedIsChecked then
                self.fusionDisableImproveRateSuccessButton = false
            end
        end
    end
end

function forgeController:onConversion(conversionType, dependencies)
    if not self or not self.ui then
        return
    end

    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    if conversionType == forgeActions.DUST2SLIVER then
        local dustBalance = player:getResourceBalance(forgeResourceTypes.dust) or 0
        if dustBalance <= 60 then
            return
        end
        g_game.forgeRequest(conversionType)
        return
    end

    if conversionType == forgeActions.SLIVER2CORE then
        local sliverBalance = player:getResourceBalance(forgeResourceTypes.sliver) or 0
        if sliverBalance <= 50 then
            return
        end
        g_game.forgeRequest(conversionType)
        return
    end

    if conversionType == forgeActions.INCREASELIMIT then
        local dustBalance = player:getResourceBalance(forgeResourceTypes.dust) or 0
        local currentNecessaryDust = self.conversionNecessaryDustToIncrease
        local maxDustCap = forgeController.maxDustCap
        local maxDustLevel = forgeController.maxDustLevel

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
    end
end

forgeController.fusionPrice = "???"
forgeController.rawFusionPrice = 0
local resolveForgePrice = helpers.resolveForgePrice
function forgeController:getFusionPrice(prices, itemId, tier, isConvergence)
    local price = 0
    if not isConvergence then
        local itemPtr = Item.create(itemId, 1)
        price = resolveForgePrice(prices, itemPtr, tier)
    else
        for currentTier, tierPrice in pairs(prices) do
            if tier == currentTier then
                price = tierPrice or 0
                break
            end
        end
    end
    self.rawFusionPrice = price
    self.fusionPrice = formatGoldAmount(price)
end

local function handleParseFusionItems(items)
    local parsedItems = cloneValue(items or {})
    for _, item in pairs(parsedItems) do
        item.key = ("%d_%d"):format(item.id, item.tier)
        if item.tier > 0 then
            item.clip = ItemsDatabase.getTierClip(item.tier)
        end

        local _, imagePath, rarityClipObject = ItemsDatabase.getClipAndImagePath(item.id)
        if imagePath then
            item.imagePath = imagePath
            item.rarityClipObject = rarityClipObject
        end
    end

    return parsedItems
end

local function handleParseConvergenceFusionItems(items)
    local parsedItems = cloneValue(items or {})
    local parsedItemsBySlot = {}
    for slot, sloItems in pairs(parsedItems) do
        for _, item in pairs(sloItems) do
            item.key = ("%d_%d"):format(item.id, item.tier)
            item.slot = slot
            if item.tier > 0 then
                item.clip = ItemsDatabase.getTierClip(item.tier)
            end

            local _, imagePath, rarityClipObject = ItemsDatabase.getClipAndImagePath(item.id)
            if imagePath then
                item.imagePath = imagePath
                item.rarityClipObject = rarityClipObject
            end

            table.insert(parsedItemsBySlot, item)
        end
    end

    return parsedItems, parsedItemsBySlot
end

function g_game.onOpenForge(openData)
    forgeController:setInitialValues(openData)
    forgeController.modeFusion = false
    forgeController.modeTransfer = false

    local shouldShow = not forgeController.ui or forgeController.ui:isDestroyed() or not forgeController.ui:isVisible()
    if shouldShow then
        forgeController:show(true)
    end

    forgeController:updateResourceBalances()
    forgeController.fusionItems = handleParseFusionItems(openData.fusionItems)
    local parsedItems, parsedItemsBySlot = handleParseConvergenceFusionItems(openData.convergenceFusion)
    forgeController.convergenceFusion = parsedItems
    forgeController.convergenceFusionBySlot = parsedItemsBySlot
    forgeController.currentItemList = forgeController.fusionItems
end

function forgeController:onTryFusion()
    if not self.selectedFusionItem or self.selectedFusionItem.id == -1 then
        return
    end

    if not self.selectedFusionItemTarget or self.selectedFusionItemTarget.id == -1 then
        return
    end

    if self.rawFusionPrice <= 0 then
        return
    end

    if not self.canTryFusion then
        return
    end

    if tonumber(self.rawCurrentGold) < tonumber(self.rawFusionPrice) then
        return
    end

    if self.currentDust < self.normalDustFusion then return end

    g_game.forgeRequest(forgeActions.FUSION, self.fusionConvergence,
        self.selectedFusionItem.id,
        self.selectedFusionItem.tier,
        self.selectedFusionItemTarget.id,
        self.fusionChanceImprovedIsChecked,
        self.fusionReduceTierLossIsChecked
    )

    self:close()
end

function forgeData(config)
    forgeController:applyForgeConfiguration(config)
end

forgeController.selectedFusionItemTarget = baseSelectedFusionItem
forgeController.fusionConvergenceList = {}
function forgeController:handleSelectItem(selectedItem, isConvergence)
    if self.selectedFusionItem and self.selectedFusionItem.key == selectedItem.key then
        self.selectedFusionItem = baseSelectedFusionItem
        self.selectedFusionItemTarget = baseSelectedFusionItem
        self.rawFusionPrice = 0
        self.fusionPrice = "???"
        self.fusionConvergenceList = {}
        self.selectedFusionConvergenceItem = baseSelectedFusionItem
        return
    end

    for _, item in pairs(self.currentItemList) do
        if item.key == selectedItem.key then
            item.key = ("%d_%d"):format(item.id, item.tier)
            self.selectedFusionItem = cloneValue(item)

            if not isConvergence then
                self.selectedFusionItemTarget = cloneValue(item)
                if self.selectedFusionItemTarget.tier < 10 then
                    self.selectedFusionItemTarget.tier = self.selectedFusionItemTarget.tier + 1
                    self.selectedFusionItemTarget.clip = ItemsDatabase.getTierClip(self.selectedFusionItemTarget.tier)
                end

                local _, imagePath, rarityClipObject = ItemsDatabase.getClipAndImagePath(self.selectedFusionItemTarget
                    .id)
                if imagePath then
                    self.selectedFusionItemTarget.imagePath = imagePath
                    self.selectedFusionItemTarget.rarityClipObject = rarityClipObject
                end
            end
            break
        end
    end

    if isConvergence then
        local convergenceList = cloneValue(self.convergenceFusion or {})
        local parsedConvergenceList = {}

        for slot, sloItems in pairs(convergenceList) do
            for _, item in pairs(sloItems) do
                if slot == selectedItem.slot then
                    if item.key == selectedItem.key and selectedItem.count > 1 then
                        table.insert(parsedConvergenceList, item)
                    elseif item.key ~= selectedItem.key and selectedItem.tier == item.tier then
                        table.insert(parsedConvergenceList, item)
                    end
                end
            end
        end
        self.fusionConvergenceList = parsedConvergenceList
    else
        local prices = self.fusionPrices or {}
        self:getFusionPrice(prices, self.selectedFusionItem.id, self.selectedFusionItem.tier)

        self.canTryFusion = self.rawFusionPrice > 0 and tonumber(self.rawCurrentGold) >= tonumber(self.rawFusionPrice) and
            self.currentDust >= self.normalDustFusion
    end
end

function forgeController:handleSelectConvergenceItem(selectedItem, isTransfer)
    if self.selectedFusionConvergenceItem and self.selectedFusionConvergenceItem.key == selectedItem.key then
        self.selectedFusionItem = baseSelectedFusionItem
        self.selectedFusionConvergenceItem = baseSelectedFusionItem
        self.selectedFusionItemTarget = baseSelectedFusionItem
        self.rawFusionPrice = 0
        self.fusionPrice = "???"
        self.fusionConvergenceList = {}
        return
    end

    for _, item in pairs(self.fusionConvergenceList) do
        if item.key == selectedItem.key then
            item.key = ("%d_%d"):format(item.id, item.tier)
            self.selectedFusionConvergenceItem = cloneValue(item)
            self.selectedFusionItemTarget = cloneValue(item)

            if self.selectedFusionItemTarget.tier < 10 then
                self.selectedFusionItemTarget.tier = self.selectedFusionItemTarget.tier + 1
                self.selectedFusionItemTarget.clip = ItemsDatabase.getTierClip(self.selectedFusionItemTarget.tier)
            end

            local _, imagePath, rarityClipObject = ItemsDatabase.getClipAndImagePath(self.selectedFusionItemTarget.id)
            if imagePath then
                self.selectedFusionItemTarget.imagePath = imagePath
                self.selectedFusionItemTarget.rarityClipObject = rarityClipObject
            end
            break
        end
    end

    local prices = self.convergenceFusionPrices or {}
    self:getFusionPrice(prices, self.selectedFusionItem.id, self.selectedFusionItemTarget.tier, self.convergenceFusion)

    self.canTryFusion = self.rawFusionPrice > 0 and tonumber(self.rawCurrentGold) >= tonumber(self.rawFusionPrice) and
        self.currentDust >= self.convergenceDustFusion
end

function forgeController:updateFusionItems(isConvergence)
    g_logger.info("updateFusionItems> isConvergence: " .. tostring(isConvergence))
    self.selectedFusionItem = baseSelectedFusionItem
    self.selectedFusionConvergenceItem = baseSelectedFusionItem
    self.selectedFusionItemTarget = baseSelectedFusionItem
    self.rawFusionPrice = 0
    self.fusionPrice = "???"
    self.fusionConvergenceList = {}
    if isConvergence then
        self.currentItemList = self.convergenceFusionBySlot or {}
    else
        self.currentItemList = self.fusionItems or {}
    end
end

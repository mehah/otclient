-- Todo
-- change to TypeScript

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

local conversionTab = require('modules.game_forge.tab.conversion.conversion')
local fusionTab = require('modules.game_forge.tab.fusion.fusion')
local helpers = require('modules.game_forge.game_forge_helpers')

conversionTab.registerDependencies(forgeController, {
    resourceTypes = forgeResourceTypes,
    actions = forgeActions
})
fusionTab.registerDependencies(forgeController, {
    resourceTypes = forgeResourceTypes
})

local cloneValue = helpers.cloneValue
local normalizeTierPriceEntries = helpers.normalizeTierPriceEntries
local normalizeClassPriceEntries = helpers.normalizeClassPriceEntries
local normalizeFusionGradeEntries = helpers.normalizeFusionGradeEntries
local resolveForgePrice = helpers.resolveForgePrice
local defaultResourceFormatter = helpers.defaultResourceFormatter
local formatGoldAmount = helpers.formatGoldAmount
local formatHistoryDate = helpers.formatHistoryDate
local resolveHistoryList = helpers.resolveHistoryList
local resolveStatusWidget = helpers.resolveStatusWidget
local resolveScrollContents = helpers.resolveScrollContents
local getChildrenByStyleName = helpers.getChildrenByStyleName
local getFirstChildByStyleName = helpers.getFirstChildByStyleName

local function formatDustAmount(value)
    return conversionTab.formatDustAmount(forgeController, value)
end

local function loadTabFragment(tabName)
    return helpers.loadTabFragment(forgeController, tabName)
end

local forgeStatusConfigs = {
    {
        selector = '#forgeGoldAmount',
        formatter = formatGoldAmount,
        getValue = function(player)
            if not player then
                return 0
            end

            return player:getTotalMoney() or 0
        end,
        eventResourceTypes = {
            ResourceTypes and ResourceTypes.BANK_BALANCE or 0,
            ResourceTypes and ResourceTypes.GOLD_EQUIPPED or 1
        }
    },
    {
        selector = '#forgeDustAmount',
        formatter = formatDustAmount,
        resourceType = forgeResourceTypes.dust
    },
    {
        selector = '#forgeSliverAmount',
        formatter = defaultResourceFormatter,
        resourceType = forgeResourceTypes.sliver
    },
    {
        selector = '#forgeCoreAmount',
        formatter = defaultResourceFormatter,
        resourceType = forgeResourceTypes.cores
    }
}

local forgeResourceConfig = {}

helpers.handleInitialValues(forgeStatusConfigs, forgeResourceConfig)

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
        fusionTab.invalidateContext(self)
    end

    if not self.ui then
        return
    end

    if not skipRequest then
        g_game.openPortableForgeRequest()
    end

    for _, config in ipairs(forgeStatusConfigs) do
        config.widget = nil
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

function forgeController:close()
    hide()
end

local function toggle(self)
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
    else
        for _, config in ipairs(forgeStatusConfigs) do
            updateStatusConfig(self, config, player)
        end
    end
    if not resourceType or resourceType == forgeResourceTypes.cores then
        self:updateFusionCoreButtons()
    end
end

function forgeController:updateDustLevelLabel(panel, dustLevel)
    conversionTab.updateDustLevelLabel(self, panel, dustLevel)
end

function forgeController:updateFusionCoreButtons()
    fusionTab.updateFusionCoreButtons(self)
end

function forgeController:onConversion(conversionType)
    conversionTab.onConversion(self, conversionType)
end

function forgeController:onToggleFusionCore(coreType)
    fusionTab.onToggleFusionCore(self, coreType)
end

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
        conversionTab.onTabLoaded(self, tabName, ui.panels[tabName])
        return ui.panels[tabName]
    end

    local panel = loadTabFragment(tabName)
    if panel then
        ui.panels[tabName] = panel
        conversionTab.onTabLoaded(self, tabName, panel)
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
    g_logger.info("forgeController.historyList: " ..
        tostring(forgeController.historyList[1].createdAt .. " desc> " .. forgeController.historyList[1].description))

    -- local pageLabel = historyPanel.historyPageLabel
    -- if not pageLabel or pageLabel:isDestroyed() then
    --     pageLabel = historyPanel:recursiveGetChildById('historyPageLabel')
    --     historyPanel.historyPageLabel = pageLabel
    -- end
    -- if pageLabel then
    --     pageLabel:setText(tr('Page %d/%d', page, lastPage))
    -- end

    -- local prevButton = historyPanel.previousPageButton
    -- if not prevButton or prevButton:isDestroyed() then
    --     prevButton = historyPanel:recursiveGetChildById('previousPageButton')
    --     historyPanel.previousPageButton = prevButton
    -- end
    -- if prevButton then
    --     prevButton:setVisible(page > 1)
    -- end

    -- local nextButton = historyPanel.nextPageButton
    -- if not nextButton or nextButton:isDestroyed() then
    --     nextButton = historyPanel:recursiveGetChildById('nextPageButton')
    --     historyPanel.nextPageButton = nextButton
    -- end
    -- if nextButton then
    --     nextButton:setVisible(lastPage > page)
    -- end
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
        fusionTab.invalidateContext(self)
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

    fusionTab.resetCoreSelections(self)
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

    conversionTab.applyInitialValues(self, openData)
end

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
        end
    end

    self:setInitialValues(initial)
end

function g_game.onOpenForge(openData)
    forgeController:setInitialValues(openData)
    conversionTab.onOpenForge(forgeController)
    forgeController.modeFusion = false
    forgeController.modeTransfer = false

    local shouldShow = not forgeController.ui or forgeController.ui:isDestroyed() or not forgeController.ui:isVisible()
    if shouldShow then
        forgeController:show(true)
    end

    forgeController:updateResourceBalances()
    forgeController:updateFusionItems()
end

function forgeData(config)
    forgeController:applyForgeConfiguration(config)
end

function forgeController:configureFusionConversionPanel(selectedWidget)
    fusionTab.configureConversionPanel(self, selectedWidget)
end

function forgeController:resetFusionConversionPanel()
    fusionTab.resetConversionPanel(self)
end

function forgeController:updateFusionItems(fusionData)
    fusionTab.updateFusionItems(self, fusionData)
end

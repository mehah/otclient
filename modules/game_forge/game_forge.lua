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

forgeController.fusionCoreSelections = {
    success = false,
    tier = false
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
conversionTab.registerDependencies(forgeController, {
    resourceTypes = forgeResourceTypes,
    actions = forgeActions
})

local function cloneValue(value)
    if type(value) == 'table' then
        if table and type(table.recursivecopy) == 'function' then
            return table.recursivecopy(value)
        end

        local copy = {}
        for key, child in pairs(value) do
            copy[key] = cloneValue(child)
        end
        return copy
    end

    return value
end

local function normalizeTierPriceEntries(entries)
    local prices = {}
    if type(entries) ~= 'table' then
        return prices
    end

    for _, entry in ipairs(entries) do
        if type(entry) == 'table' then
            local tierId = tonumber(entry.tier) or tonumber(entry.tierId) or tonumber(entry.id)
            local price = tonumber(entry.price) or tonumber(entry.cost) or tonumber(entry.value)
            if tierId then
                prices[tierId + 1] = price or 0
            end
        end
    end

    return prices
end

local function normalizeClassPriceEntries(entries)
    local pricesByClass = {}
    if type(entries) ~= 'table' then
        return pricesByClass
    end

    for _, classInfo in ipairs(entries) do
        if type(classInfo) == 'table' then
            local classId = tonumber(classInfo.classId) or tonumber(classInfo.id) or tonumber(classInfo.classification)
            if classId then
                pricesByClass[classId] = normalizeTierPriceEntries(classInfo.tiers)
            end
        end
    end

    return pricesByClass
end

local function normalizeFusionGradeEntries(entries)
    local values = {}
    if type(entries) ~= 'table' then
        return values
    end

    for _, entry in ipairs(entries) do
        if type(entry) == 'table' then
            local tierId = tonumber(entry.tier) or tonumber(entry.tierId) or tonumber(entry.id)
            if tierId then
                local value = tonumber(entry.exaltedCores) or tonumber(entry.cores) or tonumber(entry.value)
                values[tierId + 1] = value or 0
            end
        end
    end

    return values
end

local function resolveForgePrice(priceMap, itemPtr, itemTier)
    if type(priceMap) ~= 'table' then
        return 0
    end

    local tierIndex = (tonumber(itemTier) or 0) + 1

    local directValue = priceMap[tierIndex] or priceMap[tierIndex - 1]
    if directValue ~= nil then
        return tonumber(directValue) or 0
    end

    local classification = itemPtr and itemPtr.getClassification and itemPtr:getClassification()
    if classification then
        local classPrices = priceMap[classification] or priceMap[tostring(classification)]
        if type(classPrices) ~= 'table' then
            classPrices = priceMap[classification + 1]
        end

        if type(classPrices) == 'table' then
            return tonumber(classPrices[tierIndex]) or tonumber(classPrices[tierIndex - 1]) or 0
        end
    end

    return 0
end

local function defaultResourceFormatter(value)
    local numericValue = tonumber(value) or 0
    return tostring(numericValue)
end

local function formatGoldAmount(value)
    local numericValue = tonumber(value) or 0
    if type(comma_value) == 'function' then
        return comma_value(tostring(numericValue))
    end

    return tostring(numericValue)
end

local function formatDustAmount(value)
    return conversionTab.formatDustAmount(forgeController, value)
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

local fusionTabContext
local fusionSelectionRadioGroup
local fusionConvergenceRadioGroup

local historyActionLabels = {
    [0] = tr('Fusion'),
    [1] = tr('Transfer'),
    [2] = tr('Conversion'),
    [3] = tr('Conversion'),
    [4] = tr('Conversion')
}

local function formatHistoryDate(timestamp)
    if not timestamp or timestamp == 0 then
        return tr('Unknown')
    end

    return os.date('%Y-%m-%d, %H:%M:%S', timestamp)
end

local function resolveHistoryList(panel)
    if not panel then
        return nil
    end

    if panel.historyList and not panel.historyList:isDestroyed() then
        return panel.historyList
    end

    local list = panel:getChildById('historyList')
    if list then
        panel.historyList = list
    end
    return list
end

local function registerResourceConfig(resourceType, config)
    if not resourceType or forgeResourceConfig[resourceType] == config then
        return
    end

    forgeResourceConfig[resourceType] = config
end

local function handleInitialValues()
    for _, config in ipairs(forgeStatusConfigs) do
        if config.resourceType then
            registerResourceConfig(config.resourceType, config)
        end

        if config.eventResourceTypes then
            for _, resourceType in ipairs(config.eventResourceTypes) do
                registerResourceConfig(resourceType, config)
            end
        end
    end
end
handleInitialValues()

local function resolveStatusWidget(controller, config)
    if config.widget then
        if config.widget:isDestroyed() then
            config.widget = nil
        else
            return config.widget
        end
    end

    if not controller.ui then
        return nil
    end

    local widget = controller:findWidget(config.selector)
    if widget then
        config.widget = widget
    end

    return widget
end

local function loadTabFragment(tabName)
    local fragment = io.content(('modules/%s/tab/%s/%s.html'):format(forgeController.name, tabName, tabName))
    local container = forgeController.ui.content:prepend(fragment)
    local panel = container and container[tabName]
    if panel and panel.hide then
        panel:hide()
    end
    return panel
end

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

local function invalidateFusionContext()
    fusionTabContext = nil

    if fusionSelectionRadioGroup then
        fusionSelectionRadioGroup:destroy()
        fusionSelectionRadioGroup = nil
    end

    if fusionConvergenceRadioGroup then
        fusionConvergenceRadioGroup:destroy()
        fusionConvergenceRadioGroup = nil
    end
end

local function resolveScrollContents(widget)
    if not widget or widget:isDestroyed() then
        return nil
    end

    if widget.getChildById then
        local contents = widget:getChildById('contentsPanel')
        if contents and not contents:isDestroyed() then
            return contents
        end
    end

    return widget
end

local function getChildrenByStyleName(widget, styleName)
    if not widget or widget:isDestroyed() then
        return {}
    end

    local children = widget:recursiveGetChildrenByStyleName(styleName)
    if type(children) ~= 'table' then
        return {}
    end

    local results = {}
    for _, child in ipairs(children) do
        if child and not child:isDestroyed() then
            table.insert(results, child)
        end
    end

    return results
end

local function getFirstChildByStyleName(widget, styleName)
    local children = getChildrenByStyleName(widget, styleName)
    return children[1]
end

local function resolveFusionTabContext()
    local panel = forgeController:loadTab('fusion')
    if not panel then
        return nil
    end

    if not fusionTabContext or fusionTabContext.panel ~= panel or panel:isDestroyed() then
        local resultArea = panel.test or panel:recursiveGetChildById('test')
        local selectionPanel = panel.fusionSelectionArea or getFirstChildByStyleName(panel, 'fusion-selection-area')
        local convergenceSection = panel.fusionConvergenceSection
            or (resultArea and resultArea.fusionConvergenceSection)
            or getFirstChildByStyleName(resultArea, 'fusion-convergence-section')

        local targetItem = panel.fusionTargetItemPreview
            or panel:recursiveGetChildById('fusionTargetItemPreview')
            or getFirstChildByStyleName(panel, 'fusion-slot-item')

        fusionTabContext = {
            panel = panel,
            selectionPanel = selectionPanel,
            targetItem = targetItem,
            selectedItemIcon = panel.fusionSelectedItemIcon
                or panel:recursiveGetChildById('fusionSelectedItemIcon'),
            selectedItemQuestion = panel.fusionSelectedItemQuestion
                or panel:recursiveGetChildById('fusionSelectedItemQuestion'),
            selectedItemCounter = panel.fusionSelectedItemCounter
                or panel:recursiveGetChildById('fusionSelectedItemCounter'),
            resultArea = resultArea,
            placeholder = getFirstChildByStyleName(resultArea, 'forge-result-placeholder'),
            convergenceSection = convergenceSection,
            fusionButton = nil,
            fusionButtonItem = nil,
            fusionButtonItemTo = nil,
            convergenceItemsPanel = nil,
            dustAmountLabel = nil,
            costLabel = nil
        }
    end

    if not fusionTabContext.selectionPanel or fusionTabContext.selectionPanel:isDestroyed() then
        fusionTabContext.selectionPanel = panel.fusionSelectionArea or
            getFirstChildByStyleName(panel, 'fusion-selection-area')
        fusionTabContext.selectionItemsPanel = nil
    end

    if fusionTabContext.selectionPanel and (not fusionTabContext.selectionItemsPanel or fusionTabContext.selectionItemsPanel:isDestroyed()) then
        local selectionGrid = fusionTabContext.selectionPanel.fusionSelectionGrid
            or panel.fusionSelectionGrid
        if not selectionGrid then
            local selectionGrids = getChildrenByStyleName(fusionTabContext.selectionPanel, 'forge-slot-grid')
            selectionGrid = selectionGrids[1]
        end
        fusionTabContext.selectionItemsPanel = resolveScrollContents(selectionGrid)
    end

    if fusionTabContext.targetItem and fusionTabContext.targetItem:isDestroyed() then
        fusionTabContext.targetItem = nil
    end

    if not fusionTabContext.targetItem then
        fusionTabContext.targetItem = panel.fusionTargetItemPreview
            or panel:recursiveGetChildById('fusionTargetItemPreview')
            or getFirstChildByStyleName(panel, 'fusion-slot-item')
    end

    if not fusionTabContext.selectedItemIcon or fusionTabContext.selectedItemIcon:isDestroyed() then
        fusionTabContext.selectedItemIcon = panel.fusionSelectedItemIcon
            or panel:recursiveGetChildById('fusionSelectedItemIcon')
    end

    if fusionTabContext.selectedItemIcon then
        fusionTabContext.selectedItemIcon:setShowCount(true)
    end

    if not fusionTabContext.selectedItemQuestion or fusionTabContext.selectedItemQuestion:isDestroyed() then
        fusionTabContext.selectedItemQuestion = panel.fusionSelectedItemQuestion
            or panel:recursiveGetChildById('fusionSelectedItemQuestion')
    end

    if not fusionTabContext.selectedItemCounter or fusionTabContext.selectedItemCounter:isDestroyed() then
        fusionTabContext.selectedItemCounter = panel.fusionSelectedItemCounter
            or panel:recursiveGetChildById('fusionSelectedItemCounter')
    end

    if fusionTabContext.resultArea and (not fusionTabContext.fusionButton or fusionTabContext.fusionButton:isDestroyed()) then
        local actionButton = getFirstChildByStyleName(fusionTabContext.resultArea, 'forge-action-button')
        if actionButton then
            fusionTabContext.fusionButton = actionButton
            local resultItems = getChildrenByStyleName(actionButton, 'forge-result-item')
            fusionTabContext.fusionButtonItem = resultItems[1]
            fusionTabContext.fusionButtonItemTo = resultItems[2]
        end
    end

    if fusionTabContext.resultArea and (not fusionTabContext.costLabel or fusionTabContext.costLabel:isDestroyed()) then
        local costContainer = getFirstChildByStyleName(fusionTabContext.resultArea, 'fusion-result-cost')
        if costContainer then
            local labels = getChildrenByStyleName(costContainer, 'forge-full-width-label')
            fusionTabContext.costLabel = labels[1]
        end
    end

    if fusionTabContext.resultArea and (not fusionTabContext.successCoreButton or fusionTabContext.successCoreButton:isDestroyed()) then
        fusionTabContext.successCoreButton = fusionTabContext.panel.fusionImproveButton
            or fusionTabContext.resultArea.fusionImproveButton
            or fusionTabContext.panel:recursiveGetChildById('fusionImproveButton')
    end

    if fusionTabContext.resultArea and (not fusionTabContext.tierCoreButton or fusionTabContext.tierCoreButton:isDestroyed()) then
        fusionTabContext.tierCoreButton = fusionTabContext.panel.fusionReduceButton
            or fusionTabContext.resultArea.fusionReduceButton
            or fusionTabContext.panel:recursiveGetChildById('fusionReduceButton')
    end

    if fusionTabContext.resultArea and (not fusionTabContext.successRateLabel or fusionTabContext.successRateLabel:isDestroyed()) then
        fusionTabContext.successRateLabel = fusionTabContext.panel.fusionSuccessRateValue
            or fusionTabContext.resultArea.fusionSuccessRateValue
            or fusionTabContext.panel:recursiveGetChildById('fusionSuccessRateValue')
    end

    if fusionTabContext.resultArea and (not fusionTabContext.tierLossLabel or fusionTabContext.tierLossLabel:isDestroyed()) then
        fusionTabContext.tierLossLabel = fusionTabContext.panel.fusionTierLossValue
            or fusionTabContext.resultArea.fusionTierLossValue
            or fusionTabContext.panel:recursiveGetChildById('fusionTierLossValue')
    end

    if fusionTabContext.convergenceSection and (not fusionTabContext.convergenceItemsPanel or fusionTabContext.convergenceItemsPanel:isDestroyed()) then
        local convergenceGrid = fusionTabContext.convergenceSection.fusionConvergenceGrid
            or (fusionTabContext.resultArea and fusionTabContext.resultArea.fusionConvergenceGrid)
        if not convergenceGrid then
            convergenceGrid = getFirstChildByStyleName(fusionTabContext.convergenceSection, 'forge-slot-grid')
        end
        fusionTabContext.convergenceItemsPanel = resolveScrollContents(convergenceGrid)
        local labels = getChildrenByStyleName(fusionTabContext.convergenceSection, 'forge-full-width-label')
        fusionTabContext.dustAmountLabel = labels[1]
    end

    return fusionTabContext
end

local function onFusionSelectionChange(_, selectedWidget)
    if not selectedWidget or selectedWidget:isDestroyed() then
        forgeController:resetFusionConversionPanel()
        return
    end

    forgeController:configureFusionConversionPanel(selectedWidget)
end

local function onFusionConvergenceSelectionChange(_, selectedWidget)
    if not selectedWidget or selectedWidget:isDestroyed() then
        forgeController.fusionSelectedItem = nil
        return
    end

    forgeController.fusionSelectedItem = selectedWidget.fusionItemInfo
end

local function show(self, skipRequest)
    local needsReload = not self.ui or self.ui:isDestroyed()
    if needsReload then
        self:loadHtml('game_forge.html')
        ui.panels = {}
        invalidateFusionContext()
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
    if not self.ui then
        return
    end

    local context = resolveFusionTabContext()
    if not context then
        return
    end

    local successButton = context.successCoreButton
    if not successButton or successButton:isDestroyed() then
        successButton = context.panel and context.panel:recursiveGetChildById('fusionImproveButton')
        context.successCoreButton = successButton
    end

    local tierButton = context.tierCoreButton
    if not tierButton or tierButton:isDestroyed() then
        tierButton = context.panel and context.panel:recursiveGetChildById('fusionReduceButton')
        context.tierCoreButton = tierButton
    end

    local successRateLabel = context.successRateLabel
    if not successRateLabel or successRateLabel:isDestroyed() then
        successRateLabel = context.panel and context.panel:recursiveGetChildById('fusionSuccessRateValue')
        context.successRateLabel = successRateLabel
    end

    local tierLossLabel = context.tierLossLabel
    if not tierLossLabel or tierLossLabel:isDestroyed() then
        tierLossLabel = context.panel and context.panel:recursiveGetChildById('fusionTierLossValue')
        context.tierLossLabel = tierLossLabel
    end

    local lastSuccessSelection = context.lastSuccessSelection and true or false
    local lastTierSelection = context.lastTierSelection and true or false

    local function resolveBaseText(currentBase, label, defaultText, isSelected, wasSelected)
        if not label or label:isDestroyed() then
            return currentBase or defaultText
        end

        if not isSelected then
            if not wasSelected then
                local labelText = label:getText()
                if labelText and labelText ~= '' then
                    currentBase = labelText
                end
            end

            if currentBase and currentBase ~= '' then
                return currentBase
            end

            return defaultText
        end

        if currentBase and currentBase ~= '' then
            return currentBase
        end

        local labelText = label:getText()
        if labelText and labelText ~= '' then
            return labelText
        end

        return defaultText
    end

    local function updateLabel(label, text)
        if not label or label:isDestroyed() then
            return
        end

        if label:getText() ~= text then
            label:setText(text)
        end
    end



    if not successButton and not tierButton then
        local successBaseText = resolveBaseText(context.successRateBaseText, successRateLabel, '50%', false,
            lastSuccessSelection)
        local tierBaseText = resolveBaseText(context.tierLossBaseText, tierLossLabel, '100%', false, lastTierSelection)
        context.successRateBaseText = successBaseText
        context.tierLossBaseText = tierBaseText
        updateLabel(successRateLabel, successBaseText)
        updateLabel(tierLossLabel, tierBaseText)
        context.lastSuccessSelection = false
        context.lastTierSelection = false
        return
    end

    local selections = self.fusionCoreSelections
    if type(selections) ~= 'table' then
        selections = {
            success = false,
            tier = false
        }
        self.fusionCoreSelections = selections
    end

    local player = g_game.getLocalPlayer()
    local coreBalance = 0
    if player then
        coreBalance = player:getResourceBalance(forgeResourceTypes.cores) or 0
    end

    local function setButtonState(button, selected, enabled)
        if not button or button:isDestroyed() then
            return
        end

        if button.setOn then
            button:setOn(selected)
        end

        if button.setEnabled then
            button:setEnabled(enabled or selected)
        end
    end

    local successSelectedText = context.successRateSelectedText or '65%'
    local tierSelectedText = context.tierLossSelectedText or '50%'

    if coreBalance <= 0 then
        selections.success = false
        selections.tier = false
        setButtonState(successButton, false, false)
        setButtonState(tierButton, false, false)
        local successBaseText = resolveBaseText(context.successRateBaseText, successRateLabel, '50%', false,
            lastSuccessSelection)
        local tierBaseText = resolveBaseText(context.tierLossBaseText, tierLossLabel, '100%', false, lastTierSelection)
        context.successRateBaseText = successBaseText
        context.tierLossBaseText = tierBaseText
        updateLabel(successRateLabel, successBaseText)
        updateLabel(tierLossLabel, tierBaseText)
        context.lastSuccessSelection = false
        context.lastTierSelection = false
        return
    end

    local selectedSuccess = selections.success and true or false
    local selectedTier = selections.tier and true or false

    local selectedCount = (selectedSuccess and 1 or 0) + (selectedTier and 1 or 0)
    if selectedCount > coreBalance then
        if selectedTier then
            selectedTier = false
            selections.tier = false
            selectedCount = selectedCount - 1
        end
        if selectedCount > coreBalance and selectedSuccess then
            selectedSuccess = false
            selections.success = false
            selectedCount = selectedCount - 1
        end
    end

    local hasAvailableCore = coreBalance > selectedCount

    local successEnabled = selectedSuccess or hasAvailableCore
    local tierEnabled = selectedTier or hasAvailableCore

    if coreBalance == 1 then
        if selectedSuccess and not selectedTier then
            tierEnabled = false
        elseif selectedTier and not selectedSuccess then
            successEnabled = false
        end
    end

    setButtonState(successButton, selectedSuccess, successEnabled)
    setButtonState(tierButton, selectedTier, tierEnabled)

    local successBaseText = resolveBaseText(context.successRateBaseText, successRateLabel, '50%', selectedSuccess,
        lastSuccessSelection)
    local tierBaseText = resolveBaseText(context.tierLossBaseText, tierLossLabel, '100%', selectedTier, lastTierSelection)

    context.successRateBaseText = successBaseText
    context.tierLossBaseText = tierBaseText

    updateLabel(successRateLabel, selectedSuccess and successSelectedText or successBaseText)
    updateLabel(tierLossLabel, selectedTier and tierSelectedText or tierBaseText)

    context.lastSuccessSelection = selectedSuccess
    context.lastTierSelection = selectedTier
end

function forgeController:onConversion(conversionType)
    conversionTab.onConversion(self, conversionType)
end

function forgeController:onToggleFusionCore(coreType)
    if not self.ui then
        return
    end

    if coreType ~= 'success' and coreType ~= 'tier' then
        return
    end

    local context = resolveFusionTabContext()
    if not context then
        return
    end

    local button
    if coreType == 'success' then
        button = context.successCoreButton
        if not button or button:isDestroyed() then
            context.successCoreButton = context.panel and context.panel:recursiveGetChildById('fusionImproveButton') or
                nil
            button = context.successCoreButton
        end
    else
        button = context.tierCoreButton
        if not button or button:isDestroyed() then
            context.tierCoreButton = context.panel and context.panel:recursiveGetChildById('fusionReduceButton') or nil
            button = context.tierCoreButton
        end
    end

    if not button or button:isDestroyed() then
        return
    end

    local selections = self.fusionCoreSelections
    if type(selections) ~= 'table' then
        selections = {
            success = false,
            tier = false
        }
        self.fusionCoreSelections = selections
    end

    local isSelected = selections[coreType] and true or false

    local player = g_game.getLocalPlayer()
    local coreBalance = 0
    if player then
        coreBalance = player:getResourceBalance(forgeResourceTypes.cores) or 0
    end

    if isSelected then
        selections[coreType] = false
        self:updateFusionCoreButtons()
        return
    end

    local otherType = coreType == 'success' and 'tier' or 'success'
    local otherSelected = selections[otherType] and 1 or 0
    if coreBalance <= otherSelected then
        return
    end

    selections[coreType] = true
    self:updateFusionCoreButtons()
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

function onBrowseForgeHistory(page, lastPage, currentCount, historyList)
    local state = forgeController.historyState or {}
    page = math.max(tonumber(page) or 1, 1)
    lastPage = math.max(tonumber(lastPage) or page, 1)
    currentCount = tonumber(currentCount) or 0

    lastPage = lastPage > 1 and lastPage - 1 or lastPage

    state.page = page
    state.lastPage = lastPage
    state.currentCount = currentCount
    forgeController.historyState = state

    local historyPanel = forgeController:loadTab('history')
    if not historyPanel then
        return
    end

    local historyListWidget = resolveHistoryList(historyPanel)
    if not historyListWidget then
        return
    end

    historyListWidget:destroyChildren()

    if historyList and #historyList > 0 then
        for index, entry in ipairs(historyList) do
            local row = g_ui.createWidget('HistoryForgePanel', historyListWidget)
            if row then
                local rowBackground = index % 2 == 1 and '#484848' or '#414141'
                row:setBackgroundColor(rowBackground)
                local dateLabel = row:getChildById('date')
                if dateLabel then
                    dateLabel:setText(formatHistoryDate(entry.createdAt))
                end

                local actionLabel = row:getChildById('action')
                if actionLabel then
                    actionLabel:setText(historyActionLabels[entry.actionType] or tr('Unknown'))
                end

                local detailLabel = row:getChildById('details')
                if detailLabel then
                    detailLabel:setText(entry.description or '')
                end
            end
        end
    else
        local emptyRow = g_ui.createWidget('HistoryForgePanel', historyListWidget)
        if emptyRow then
            local dateLabel = emptyRow:getChildById('date')
            if dateLabel then
                dateLabel:setText('-')
            end

            local actionLabel = emptyRow:getChildById('action')
            if actionLabel then
                actionLabel:setText(tr('No history'))
            end

            local detailLabel = emptyRow:getChildById('details')
            if detailLabel then
                detailLabel:setText(tr('There are no forge history entries to display.'))
            end
        end
    end

    local pageLabel = historyPanel.historyPageLabel
    if not pageLabel or pageLabel:isDestroyed() then
        pageLabel = historyPanel:recursiveGetChildById('historyPageLabel')
        historyPanel.historyPageLabel = pageLabel
    end
    if pageLabel then
        pageLabel:setText(tr('Page %d/%d', page, lastPage))
    end

    local prevButton = historyPanel.previousPageButton
    if not prevButton or prevButton:isDestroyed() then
        prevButton = historyPanel:recursiveGetChildById('previousPageButton')
        historyPanel.previousPageButton = prevButton
    end
    if prevButton then
        prevButton:setVisible(page > 1)
    end

    local nextButton = historyPanel.nextPageButton
    if not nextButton or nextButton:isDestroyed() then
        nextButton = historyPanel:recursiveGetChildById('nextPageButton')
        historyPanel.nextPageButton = nextButton
    end
    if nextButton then
        nextButton:setVisible(lastPage > page)
    end
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
        invalidateFusionContext()
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

    self.fusionCoreSelections = {
        success = false,
        tier = false
    }
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
            g_logger.info("Setting initial value for " .. key .. " to " .. tostring(numericValue))
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
    if not selectedWidget or not selectedWidget.itemPtr then
        return
    end

    local context = resolveFusionTabContext()
    if not context then
        return
    end

    if context.convergenceSection and (not context.convergenceItemsPanel or context.convergenceItemsPanel:isDestroyed()) then
        context.convergenceItemsPanel = resolveScrollContents(
            getFirstChildByStyleName(context.convergenceSection, 'forge-slot-grid')
        )
    end

    local itemPtr = selectedWidget.itemPtr
    local itemWidget = selectedWidget.item
    local itemCount = 1
    if itemWidget and itemWidget.getItemCount then
        itemCount = tonumber(itemWidget:getItemCount()) or itemCount
    elseif itemPtr and itemPtr.getCount then
        itemCount = tonumber(itemPtr:getCount()) or itemCount
    elseif itemPtr and itemPtr.getCountOrSubType then
        itemCount = tonumber(itemPtr:getCountOrSubType()) or itemCount
    end
    local itemTier = itemPtr:getTier() or 0

    self.fusionItem = itemPtr
    self.fusionItemCount = itemCount

    if context.targetItem then
        local targetPreview = Item.create(itemPtr:getId(), 1)
        targetPreview:setTier(itemTier + 1)
        context.targetItem:setItem(targetPreview)
        context.targetItem:setItemCount(1)
        ItemsDatabase.setTier(context.targetItem, targetPreview)
    end

    if context.selectedItemIcon then
        local selectedPreview = Item.create(itemPtr:getId(), itemCount)
        selectedPreview:setTier(itemTier)
        context.selectedItemIcon:setItem(selectedPreview)
        context.selectedItemIcon:setItemCount(itemCount)
        ItemsDatabase.setTier(context.selectedItemIcon, selectedPreview)
    end

    if context.selectedItemQuestion then
        context.selectedItemQuestion:setVisible(false)
    end

    if context.selectedItemCounter then
        local ownedCount = math.max(itemCount, 0)
        context.selectedItemCounter:setText(string.format('%d / 1', ownedCount))
    end

    if context.fusionButtonItem then
        context.fusionButtonItem:setItemId(itemPtr:getId())
        context.fusionButtonItem:setItemCount(1)
        ItemsDatabase.setTier(context.fusionButtonItem, math.max(itemTier - 1, 0))
    end

    if context.fusionButtonItemTo then
        context.fusionButtonItemTo:setItemId(itemPtr:getId())
        context.fusionButtonItemTo:setItemCount(1)
        ItemsDatabase.setTier(context.fusionButtonItemTo, itemTier + 1)
    end

    if context.convergenceItemsPanel then
        context.convergenceItemsPanel:destroyChildren()
    end

    if fusionConvergenceRadioGroup then
        fusionConvergenceRadioGroup:destroy()
        fusionConvergenceRadioGroup = nil
    end

    fusionConvergenceRadioGroup = UIRadioGroup.create()
    fusionConvergenceRadioGroup.onSelectionChange = onFusionConvergenceSelectionChange

    self.fusionSelectedItem = nil

    local player = g_game.getLocalPlayer()
    local dustRequirement = (self.openData and tonumber(self.openData.convergenceDustFusion)) or
        tonumber(self.convergenceDustFusion) or 0
    local priceList = self.fusionPrices or (self.openData and self.openData.fusionPrices) or {}
    local price = resolveForgePrice(priceList, itemPtr, itemTier)

    if context.dustAmountLabel and player then
        local dustBalance = player:getResourceBalance(forgeResourceTypes.dust) or 0
        local hasEnoughDust = dustRequirement <= 0 or dustBalance >= dustRequirement
        context.dustAmountLabel:setColor(hasEnoughDust and '$var-text-cip-color' or '#d33c3c')
    end

    self.fusionPrice = price

    if context.costLabel then
        context.costLabel:setText(formatGoldAmount(price))
        if player then
            local totalMoney = player:getTotalMoney() or 0
            context.costLabel:setColor(totalMoney >= price and '$var-text-cip-color' or '#d33c3c')
        end
    end

    local hasConvergenceOptions = false
    local convergenceData = self.convergenceFusion or {}
    if context.convergenceItemsPanel then
        for _, option in ipairs(convergenceData) do
            if type(option) == 'table' then
                for _, fusionInfo in ipairs(option) do
                    if type(fusionInfo) == 'table' and fusionInfo.id then
                        local widget = g_ui.createWidget('UICheckBox', context.convergenceItemsPanel)
                        if widget then
                            widget:setText('')
                            widget:setFocusable(true)
                            widget:setHeight(36)
                            widget:setWidth(36)
                            widget:setMargin(2)

                            local itemDisplay = g_ui.createWidget('UIItem', widget)
                            if itemDisplay then
                                itemDisplay:fill('parent')
                                itemDisplay:setItemId(fusionInfo.id)
                                if fusionInfo.count and fusionInfo.count > 0 then
                                    itemDisplay:setItemCount(fusionInfo.count)
                                end
                                ItemsDatabase.setTier(itemDisplay, fusionInfo.tier or 0)
                                widget.item = itemDisplay
                            end

                            widget.fusionItemInfo = fusionInfo
                            fusionConvergenceRadioGroup:addWidget(widget)
                            hasConvergenceOptions = true
                        end
                    end
                end
            end
        end
    end

    if context.convergenceSection then
        context.convergenceSection:setVisible(self.modeFusion and hasConvergenceOptions)
    end

    local firstWidget = fusionConvergenceRadioGroup:getFirstWidget()
    if firstWidget then
        fusionConvergenceRadioGroup:selectWidget(firstWidget, true)
        onFusionConvergenceSelectionChange(fusionConvergenceRadioGroup, firstWidget)
    end

    self:updateFusionCoreButtons()
end

function forgeController:resetFusionConversionPanel()
    local context = resolveFusionTabContext()
    if not context then
        return
    end

    self.fusionItem = nil
    self.fusionItemCount = nil
    self.fusionSelectedItem = nil

    if context.targetItem then
        context.targetItem:setItemId(0)
        context.targetItem:setItemCount(0)
        ItemsDatabase.setTier(context.targetItem, 0)
    end

    if context.selectedItemIcon then
        context.selectedItemIcon:setItemId(0)
        context.selectedItemIcon:setItemCount(0)
        ItemsDatabase.setTier(context.selectedItemIcon, 0)
    end

    if context.selectedItemQuestion then
        context.selectedItemQuestion:setVisible(true)
    end

    if context.selectedItemCounter then
        context.selectedItemCounter:setText('0 / 1')
    end

    if context.placeholder then
        context.placeholder:setVisible(true)
    end

    if context.convergenceSection then
        context.convergenceSection:setVisible(false)
    end

    if context.fusionButtonItem then
        context.fusionButtonItem:setItemId(0)
        context.fusionButtonItem:setItemCount(0)
        ItemsDatabase.setTier(context.fusionButtonItem, 0)
    end

    if context.fusionButtonItemTo then
        context.fusionButtonItemTo:setItemId(0)
        context.fusionButtonItemTo:setItemCount(0)
        ItemsDatabase.setTier(context.fusionButtonItemTo, 0)
    end

    if context.convergenceItemsPanel then
        context.convergenceItemsPanel:destroyChildren()
    end

    if fusionConvergenceRadioGroup then
        fusionConvergenceRadioGroup:destroy()
        fusionConvergenceRadioGroup = nil
    end

    if context.dustAmountLabel then
        context.dustAmountLabel:setColor('$var-text-cip-color')
    end

    if context.costLabel then
        context.costLabel:setText('???')
        context.costLabel:setColor('$var-text-cip-color')
    end

    local successSelectedText = context.successRateSelectedText or '65%'
    local tierSelectedText = context.tierLossSelectedText or '50%'

    if context.successRateLabel and not context.successRateLabel:isDestroyed() then
        context.lastSuccessSelection = context.successRateLabel:getText() == successSelectedText
    else
        context.lastSuccessSelection = false
    end

    if context.tierLossLabel and not context.tierLossLabel:isDestroyed() then
        context.lastTierSelection = context.tierLossLabel:getText() == tierSelectedText
    else
        context.lastTierSelection = false
    end

    context.successRateBaseText = nil
    context.tierLossBaseText = nil

    if type(self.fusionCoreSelections) ~= 'table' then
        self.fusionCoreSelections = {
            success = false,
            tier = false
        }
    else
        self.fusionCoreSelections.success = false
        self.fusionCoreSelections.tier = false
    end

    self:updateFusionCoreButtons()
end

function forgeController:updateFusionItems(fusionData)
    local context = resolveFusionTabContext()
    if not context then
        return
    end

    if context.selectionPanel and (not context.selectionItemsPanel or context.selectionItemsPanel:isDestroyed()) then
        local selectionGrids = getChildrenByStyleName(context.selectionPanel, 'forge-slot-grid')
        context.selectionItemsPanel = resolveScrollContents(selectionGrids[1])
    end

    self:resetFusionConversionPanel()

    local itemsPanel = context.selectionItemsPanel
    if not itemsPanel then
        return
    end

    itemsPanel:destroyChildren()

    if fusionSelectionRadioGroup then
        fusionSelectionRadioGroup:destroy()
        fusionSelectionRadioGroup = nil
    end

    fusionSelectionRadioGroup = UIRadioGroup.create()
    fusionSelectionRadioGroup:clearSelected()
    fusionSelectionRadioGroup.onSelectionChange = onFusionSelectionChange

    local data = fusionData
    if not data then
        if self.modeFusion then
            data = self.convergenceFusion
        else
            data = self.fusionItems
        end
    end

    local function applySelectionHighlight(widget, checked)
        if not widget or widget:isDestroyed() then
            return
        end

        if checked then
            widget:setBorderWidth(1)
            widget:setBorderColor('#ffffff')
        else
            widget:setBorderWidth(0)
        end
    end

    local function appendItem(info)
        if type(info) ~= 'table' or not info.id or info.id <= 0 then
            return
        end

        local widget = g_ui.createWidget('UICheckBox', itemsPanel)
        if not widget then
            return
        end

        widget:setText('')
        widget:setFocusable(true)
        widget:setSize('36 36')
        widget:setBorderWidth(0)
        widget:setBorderColor('#ffffff')

        widget.onCheckChange = function(self, checked)
            applySelectionHighlight(self, checked)
        end

        local frame = g_ui.createWidget('UIWidget', widget)
        frame:setSize('34 34')
        frame:setMarginLeft(1)
        frame:setMarginTop(1)
        frame:addAnchor(AnchorTop, 'parent', AnchorTop)
        frame:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        frame:setImageSource('/images/ui/item')
        frame:setPhantom(true)
        frame:setFocusable(false)

        local itemWidget = g_ui.createWidget('UIItem', widget)
        itemWidget:setSize('32 32')
        itemWidget:setMarginTop(2)
        itemWidget:addAnchor(AnchorTop, 'parent', AnchorTop)
        itemWidget:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
        itemWidget:setPhantom(true)
        itemWidget:setVirtual(true)
        itemWidget:setShowCount(true)
        local itemPtr = Item.create(info.id, info.count or 1)
        itemPtr:setTier(info.tier or 0)
        itemWidget:setItem(itemPtr)
        itemWidget:setItemCount(info.count or itemPtr:getCount())
        ItemsDatabase.setRarityItem(itemWidget, itemWidget:getItem())
        ItemsDatabase.setTier(itemWidget, info.tier or 0)

        widget.item = itemWidget
        widget.itemPtr = itemPtr
        widget.fusionItemInfo = info

        applySelectionHighlight(widget, widget:isChecked())

        fusionSelectionRadioGroup:addWidget(widget)
    end

    local function processEntries(entries)
        if type(entries) ~= 'table' then
            return
        end

        for _, entry in ipairs(entries) do
            if type(entry) == 'table' then
                if entry.id then
                    appendItem(entry)
                else
                    processEntries(entry)
                end
            end
        end
    end

    processEntries(data or {})
end

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
    local numericValue = tonumber(value) or 0
    local maxDust = (forgeController and forgeController.maxDustLevel) or 100

    if maxDust <= 0 then
        return tostring(numericValue)
    end

    return string.format('%d/%d', numericValue, maxDust)
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
        fusionTabContext = {
            panel = panel,
            selectionPanel = nil,
            selectionItemsPanel = nil,
            targetItem = getFirstChildByStyleName(panel, 'fusion-slot-item'),
            resultArea = resultArea,
            placeholder = getFirstChildByStyleName(resultArea, 'forge-result-placeholder'),
            convergenceSection = getFirstChildByStyleName(resultArea, 'fusion-convergence-section'),
            fusionButton = nil,
            fusionButtonItem = nil,
            fusionButtonItemTo = nil,
            convergenceItemsPanel = nil,
            dustAmountLabel = nil,
            costLabel = nil
        }
    end

    if not fusionTabContext.selectionPanel or fusionTabContext.selectionPanel:isDestroyed() then
        fusionTabContext.selectionPanel = getFirstChildByStyleName(panel, 'fusion-selection-area')
        fusionTabContext.selectionItemsPanel = nil
    end

    if fusionTabContext.selectionPanel and (not fusionTabContext.selectionItemsPanel or fusionTabContext.selectionItemsPanel:isDestroyed()) then
        local selectionGrids = getChildrenByStyleName(fusionTabContext.selectionPanel, 'forge-slot-grid')
        fusionTabContext.selectionItemsPanel = resolveScrollContents(selectionGrids[1])
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

    if fusionTabContext.convergenceSection and (not fusionTabContext.convergenceItemsPanel or fusionTabContext.convergenceItemsPanel:isDestroyed()) then
        fusionTabContext.convergenceItemsPanel = resolveScrollContents(
            getFirstChildByStyleName(fusionTabContext.convergenceSection, 'forge-slot-grid')
        )
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
        g_game.forgeRequest()
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
end

function forgeController:onInit()
    connect(g_game, {
        onBrowseForgeHistory = onBrowseForgeHistory
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
        g_logger.info(page .. "/" .. lastPage)
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
        onBrowseForgeHistory = onBrowseForgeHistory
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
end

function forgeController:onGameEnd()
    if self.ui and self.ui:isVisible() then
        self.ui:hide()
    end

    if forgeButton then
        forgeButton:setOn(false)
    end
end

function g_game.onOpenForge(openData)
    openData = openData or {}

    forgeController.openData = openData
    forgeController.fusionItems = openData.fusionItems or {}
    forgeController.convergenceFusion = openData.convergenceFusion or {}
    forgeController.transfers = openData.transfers or {}
    forgeController.convergenceTransfers = openData.convergenceTransfers or {}
    local dustLevel = tonumber(openData.dustLevel) or 0
    forgeController.maxDustLevel = dustLevel > 0 and dustLevel or forgeController.maxDustLevel or 0

    forgeController.modeFusion = false
    forgeController.modeTransfer = false

    local shouldShow = not forgeController.ui or forgeController.ui:isDestroyed() or not forgeController.ui:isVisible()
    if shouldShow then
        forgeController:show(true)
    end

    forgeController:updateResourceBalances()
    forgeController:updateFusionItems()
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
        context.targetItem:setItemId(itemPtr:getId())
        context.targetItem:setItemCount(itemCount)
        ItemsDatabase.setTier(context.targetItem, itemPtr)
    end

    if context.placeholder then
        context.placeholder:setVisible(false)
    end

    if context.convergenceSection then
        context.convergenceSection:setVisible(true)
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
    local dustRequirement = (self.openData and tonumber(self.openData.convergenceDustFusion)) or tonumber(self.convergenceDustFusion) or 0
    local priceList = self.fusionPrices or (self.openData and self.openData.fusionPrices) or {}
    local price = 0

    if type(priceList) == 'table' then
        price = tonumber(priceList[itemTier + 1]) or tonumber(priceList[itemTier]) or 0
    end

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
                        end
                    end
                end
            end
        end
    end

    local firstWidget = fusionConvergenceRadioGroup:getFirstWidget()
    if firstWidget then
        fusionConvergenceRadioGroup:selectWidget(firstWidget, true)
        onFusionConvergenceSelectionChange(fusionConvergenceRadioGroup, firstWidget)
    end
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

    local function appendItem(info)
        if type(info) ~= 'table' or not info.id or info.id <= 0 then
            return
        end

        local widget = g_ui.createWidget('UICheckBox', itemsPanel)
        if not widget then
            return
        end

        widget:setStyle('fusion-item-box')
        widget:setText('')
        widget:setFocusable(true)
        widget:setSize('36 36')
        widget:setBorderColor('#ffffff')
        widget:setBorderWidth(0)

        local frame = g_ui.createWidget('UIWidget', widget)
        frame:setStyle('fusion-item-box__frame')
        frame:setSize('34 34')
        frame:setMarginLeft(1)
        frame:setMarginTop(1)
        frame:addAnchor(AnchorTop, 'parent', AnchorTop)
        frame:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        frame:setImageSource('/images/ui/item')
        frame:setPhantom(true)
        frame:setFocusable(false)

        local itemWidget = g_ui.createWidget('UIItem', widget)
        itemWidget:setStyle('fusion-item-box__item')
        itemWidget:setSize('32 32')
        itemWidget:setMarginTop(2)
        itemWidget:addAnchor(AnchorTop, 'parent', AnchorTop)
        itemWidget:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
        itemWidget:setPhantom(true)
        itemWidget:setVirtual(true)
        itemWidget:setShowCount(false)

        local itemPtr = Item.create(info.id, info.count or 1)
        itemPtr:setTier(info.tier or 0)

        itemWidget:setItem(itemPtr)
        itemWidget:setItemCount(info.count or itemPtr:getCount())
        ItemsDatabase.setTier(itemWidget, info.tier or 0)

        widget.item = itemWidget
        widget.itemPtr = itemPtr
        widget.fusionItemInfo = info

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

    local firstWidget = fusionSelectionRadioGroup:getFirstWidget()
    if firstWidget then
        fusionSelectionRadioGroup:selectWidget(firstWidget, true)
        onFusionSelectionChange(fusionSelectionRadioGroup, firstWidget)
    end
end

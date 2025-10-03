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
    return string.format('%d/100', numericValue)
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

local historyActionLabels = {
    [0] = tr('Fusion'),
    [1] = tr('Transfer'),
    [2] = tr('Dust to Sliver'),
    [3] = tr('Sliver to Core'),
    [4] = tr('Increase Limit')
}

local function measureWidgetContentWidth(widget)
    if not widget or widget:isDestroyed() then
        return 0
    end

    local width = 0
    if widget.getTextSize then
        local textSize = widget:getTextSize()
        if textSize and textSize.width then
            width = textSize.width
        end
    end

    if widget.getPaddingLeft then
        width = width + (widget:getPaddingLeft() or 0) + (widget:getPaddingRight() or 0)
    end

    return width
end

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

local function resolveHistoryHeader(panel)
    if not panel then
        return nil
    end

    if panel.historyHeaderAction and not panel.historyHeaderAction:isDestroyed() then
        return panel.historyHeaderAction
    end

    local header = panel.historyHeader or panel:getChildById('historyHeader')
    if not header then
        return nil
    end

    panel.historyHeader = header
    panel.historyHeaderAction = header:getChildById('historyHeaderAction') or header.historyHeaderAction
    return panel.historyHeaderAction
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

local function toggle(self)
    g_game.forgeRequest()
    forgeController:loadHtml('game_forge.html')
    for _, config in ipairs(forgeStatusConfigs) do
        config.widget = nil
    end
    g_ui.importStyle("otui/style.otui")
    self.modeFusion, self.modeTransfer = false, false

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

    SelectWindow("fusionMenu")
    self:updateResourceBalances()
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

    local headerAction = resolveHistoryHeader(historyPanel)
    local maxActionWidth = measureWidgetContentWidth(headerAction)
    local actionLabels = {}

    if historyList and #historyList > 0 then
        for _, entry in ipairs(historyList) do
            local row = g_ui.createWidget('HistoryForgePanel', historyListWidget)
            if row then
                local dateLabel = row:getChildById('date')
                if dateLabel then
                    dateLabel:setText(formatHistoryDate(entry.createdAt))
                end

                local actionLabel = row:getChildById('action')
                if actionLabel then
                    actionLabel:setText(historyActionLabels[entry.actionType] or tr('Unknown'))
                    local actionWidth = measureWidgetContentWidth(actionLabel)
                    if actionWidth > 0 then
                        maxActionWidth = math.max(maxActionWidth or 0, actionWidth)
                        table.insert(actionLabels, actionLabel)
                    end
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
                local actionWidth = measureWidgetContentWidth(actionLabel)
                if actionWidth > 0 then
                    maxActionWidth = math.max(maxActionWidth or 0, actionWidth)
                    table.insert(actionLabels, actionLabel)
                end
            end

            local detailLabel = emptyRow:getChildById('details')
            if detailLabel then
                detailLabel:setText(tr('There are no forge history entries to display.'))
            end
        end
    end

    local pageLabel = historyPanel.historyPageLabel or historyPanel:getChildById('historyPageLabel')
    if pageLabel then
        pageLabel:setText(string.format(tr('Page %d/%d'), page, lastPage))
    end

    local prevButton = historyPanel.previousPageButton or historyPanel:getChildById('previousPageButton')
    if prevButton then
        prevButton:setVisible(page > 1)
    end

    local nextButton = historyPanel.nextPageButton or historyPanel:getChildById('nextPageButton')
    if nextButton then
        nextButton:setVisible(lastPage > page)
    end

    if maxActionWidth and maxActionWidth > 0 then
        if headerAction then
            headerAction:setWidth(maxActionWidth)
        end

        for _, label in ipairs(actionLabels) do
            if not label:isDestroyed() then
                label:setWidth(maxActionWidth)
            end
        end
    end
end

function forgeController:onTerminate()
    disconnect(g_game, {
        onBrowseForgeHistory = onBrowseForgeHistory
    })
end

function forgeController:onGameStart()
end

function forgeController:onGameEnd()
end

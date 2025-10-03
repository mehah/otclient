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

local function show(self)
    local needsReload = not self.ui or self.ui:isDestroyed()
    if needsReload then
        self:loadHtml('game_forge.html')
        ui.panels = {}
    end

    if not self.ui then
        return
    end

    g_game.forgeRequest()

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

function forgeController:show()
    show(self)
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

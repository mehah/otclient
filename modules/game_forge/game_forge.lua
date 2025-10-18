ForgeController = Controller:new()
ForgeButton = nil

local helpers = require('modules.game_forge.game_forge_helpers')
local cloneValue = helpers.cloneValue
local normalizeClassPriceEntries = helpers.normalizeClassPriceEntries
local normalizeTierPriceEntries = helpers.normalizeTierPriceEntries
local baseSelectedFusionItem = {
    id = -1,
    tier = -1,
    clip = {},
    imagePath = nil,
    rarityClipObject = nil,
    count = 0,
    countLabel = "0 / 1",
    slot = -1
}
local function resetInfo()
    -- ForgeController.fusionPrice = "???"
    -- ForgeController.currentExaltedCoresPrice = "???"
    -- ForgeController.fusionChanceImprovedIsChecked = false
    -- ForgeController.fusionReduceTierLossIsChecked = false
    -- ForgeController.selectedFusionItem = cloneValue(baseSelectedFusionItem)
    -- ForgeController.selectedFusionConvergenceItem = cloneValue(baseSelectedFusionItem)
    -- ForgeController.selectedFusionItemTarget = cloneValue(baseSelectedFusionItem)
    -- ForgeController.fusionConvergence = false
    -- ForgeController.transferConvergence = false
    -- ForgeController.fusionConvergenceTitle = nil
    -- ForgeController.fusionConvergenceList = {}
    -- ForgeController.transferDustAmount = 100
end

local TAB_ORDER = { 'fusion', 'transfer', 'conversion', 'history' }
function ForgeController:hideAllPanels()
    for _, panel in pairs(self.ui.panels) do
        if panel and panel.hide then
            panel:hide()
        end
    end
end

function ForgeController:show(skipRequest)
    local needsReload = not self.ui or self.ui:isDestroyed()
    if needsReload then
        self:loadHtml('game_forge.html')
        self.ui.panels = {}
    end

    if not self.ui then
        return
    end

    if not skipRequest then
        g_game.openPortableForgeRequest()
    end

    self.modeFusion, self.modeTransfer = false, false

    -- for _, tabName in ipairs(TAB_ORDER) do
    --     self:loadTab(tabName)
    -- end

    local buttonPanel = self.ui.buttonPanel
    -- for tabName, config in pairs(TAB_CONFIG) do
    --     windowTypes[tabName .. 'Menu'] = {
    --         obj = buttonPanel and buttonPanel[tabName .. 'Btn'],
    --         panel = tabName,
    --         modeProperty = config.modeProperty
    --     }
    -- end

    self.ui:centerIn('parent')
    self.ui:show()
    self.ui:raise()
    self.ui:focus()

    if ForgeButton then
        ForgeButton:setOn(true)
    end

    -- SelectWindow('fusionMenu')
    self:updateResourceBalances()

    self:scheduleEvent(function()
        self.ui:centerIn('parent')
    end, 1, "LazyHtml")
end

function ForgeController:hide()
    if not self.ui then
        return
    end

    self.ui:hide()

    if ForgeButton then
        ForgeButton:setOn(false)
    end
end

function ForgeController:toggle()
    ForgeController:toggleTransferMenu()
    resetInfo()
    if ForgeController.rawData then
        forgeData(ForgeController.rawData)
    end
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

ForgeController.currentDust = 0
ForgeController.currentSlivers = 0
ForgeController.currentExaltedCores = 0
ForgeController.rawCurrentGold = 0
ForgeController.currentGold = 0

ForgeController.currentTab = 'transfer'
function ForgeController:updateResourceBalances()
    if not self.ui then
        return
    end

    local player = g_game.getLocalPlayer()

    self.currentDust = player:getResourceBalance(ResourceTypes.FORGE_DUST or 70)
    g_logger.info("Current Dust: " .. tostring(self.currentDust))
    self.currentSlivers = player:getResourceBalance(ResourceTypes.FORGE_SLIVER)
    g_logger.info("Current Slivers: " .. tostring(self.currentSlivers))
    self.currentExaltedCores = player:getResourceBalance(ResourceTypes.FORGE_CORES)
    g_logger.info("Current Exalted Cores: " .. tostring(self.currentExaltedCores))
    self.rawCurrentGold = player:getTotalMoney() or 0
    g_logger.info("Current Gold: " .. tostring(self.rawCurrentGold))
    self.currentGold = comma_value(self.rawCurrentGold)
    g_logger.info("Current Gold format: " .. tostring(self.currentGold))
end

function ForgeController:onInit()
    self:updateResourceBalances()
    self:registerEvents(g_game, {
        onBrowseForgeHistory = onBrowseForgeHistory,
        forgeData = forgeData,
        onOpenForge = onOpenForge,
        onResourcesBalanceChange = self:updateResourceBalances(),
    })

    if not ForgeButton then
        ForgeButton = modules.game_mainpanel.addToggleButton('ForgeButton', tr('Open Exaltation Forge'),
            '/images/options/button-exaltation-forge.png', function() self:toggle() end)
    end

    self.currentTab = 'conversion'
    g_game.sendForgeBrowseHistoryRequest(0)
end

-- FUSION MENU
ForgeController.fusion = {
    prices = {},
    convergencePrices = {},
    grades = {},
    dust = 100,
    convergenceDust = 130,
    reduceTierLoss = 50,
    chanceImproved = 15,
    chanceBase = 50,
    hasConvergence = false,
    clip = { x = 0, y = 0, width = 116, height = 34 }
}
-- FUSION MENU

-- TRANSFER MENU
ForgeController.transfer = {
    prices = {},
    convergencePrices = {},
    grades = {},
    dust = 100,
    convergenceDust = 160,
    hasConvergence = false,
    dustLabel = 100,
    exaltedCoresLabel = "???",
    clip = { x = 0, y = 0, width = 116, height = 34 },
    items = {
        donors = {},
        receivers = {}
    },
    convergenceItems = {
        donors = {},
        receivers = {}
    },
    currentList = {
        donors = {},
        receivers = {}
    },
    selected = nil
}
function ForgeController:toggleTransferMenu()
    self:resetTabsClip()
    self.currentTab = 'transfer'
    self.transfer.clip = { x = 0, y = 34, width = 116, height = 34 }
end

function ForgeController.transfer:handleSelect(item)
    if not item then
        return
    end

    ForgeController.transfer.selected = item
    g_logger.info("Selected Transfer Item ID: " .. tostring(item.id) .. " Slot: " .. tostring(item.slot))
end

-- TRANSFER MENU

function onOpenForge(data)
    ForgeController.conversion.dustMax = data.dustLevel or ForgeController.conversion.dustMax or 100

    -- TRANSFER ITEMS
    local transfers = cloneValue(data.transfers or {})
    local transferItems = {
        donors = {},
        receivers = {}
    }

    for slot, currentType in pairs(transfers) do
        for transferType in pairs(currentType) do
            for __, item in pairs(currentType[transferType]) do
                item.slot = slot
                if item.tier > 0 then
                    item.clip = ItemsDatabase.getTierClip(item.tier)
                end
                local _, imagePath, rarityClipObject = ItemsDatabase.getClipAndImagePath(item.id)
                if imagePath then
                    item.imagePath = imagePath
                    item.rarityClipObject = rarityClipObject
                end
                table.insert(transferItems[transferType], item)
            end
        end
    end

    ForgeController.transfer.items = transferItems
    ForgeController.transfer.currentList = cloneValue(transferItems)

    local convergenceTransferItems = {
        donors = {},
        receivers = {}
    }
    -- TRANSFER ITEMS

    for k, v in pairs(data) do
        if k == "fusionGrades" then
            for kk, vv in pairs(v) do
                g_logger.info("Fusion Grade - " .. tostring(kk) .. ": " .. tostring(vv))
            end
        else
            g_logger.info("Forge Data - " .. tostring(k) .. ": " .. tostring(v))
        end
    end

    local shouldShow = not ForgeController.ui or ForgeController.ui:isDestroyed() or not ForgeController.ui:isVisible()
    if shouldShow then
        ForgeController:show(true)
        ForgeController:toggleTransferMenu()
    end
end

function forgeData(data)
    ForgeController.rawData = data
    ForgeController:updateResourceBalances()
    -- FUSION
    local classPrices = normalizeClassPriceEntries(data.classPrices)
    if next(classPrices) then
        ForgeController.fusion.prices = classPrices
    end

    local convergenceFusion = normalizeTierPriceEntries(data.convergenceFusionPrices)
    if next(convergenceFusion) then
        ForgeController.fusion.convergencePrices = convergenceFusion
    end
    ForgeController.fusion.grades = data.fusionGrades or {}
    ForgeController.fusion.convergenceDust = data.convergenceFusionDust or 130
    ForgeController.fusion.dust = data.normalDustFusion or 100
    ForgeController.fusion.reduceTierLoss = data.fusionReduceTierLoss or 50
    ForgeController.fusion.chanceImproved = data.fusionChanceImproved or 15
    ForgeController.fusion.chanceBase = data.fusionChanceBase or 50
    ForgeController.fusion.hasConvergence = data.hasConvergence or false
    -- FUSION

    -- TRANSFER
    ForgeController.transfer.prices = data.transferPrices or {}
    local convergenceTransfer = normalizeTierPriceEntries(data.convergenceTransferPrices)
    if next(convergenceTransfer) then
        ForgeController.transfer.convergencePrices = convergenceTransfer
    end
    ForgeController.transfer.convergenceDust = data.convergenceDustTransfer or 160
    ForgeController.transfer.dust = data.normalDustTransfer or 100
    ForgeController.transfer.hasConvergence = data.hasConvergence or false
    ForgeController.transfer.dustLabel = ForgeController.transfer.dust
    -- TRANSFER

    -- CONVERSION
    ForgeController.conversion.necessaryDustToSliver = 60
    ForgeController.conversion.dustToSilver = data.dustToSilver or 3
    ForgeController.conversion.dustToSilverLabel = string.format("Generate %d", ForgeController.conversion.dustToSilver)
    ForgeController.conversion.sliverToCore = data.sliverToCore or 50
    ForgeController.conversion.sliverToCoreLabel = "Generate 1"
    ForgeController.conversion.dustCap = data.maxDustCap or 225
    local dustMax = data.maxDustLevel or 100
    ForgeController.conversion.dustMax = dustMax
    ForgeController.conversion.dustMaxIncreaseCost = dustMax - 75
    ForgeController.conversion:handleButtons()
    -- CONVERSION

    -- for k, v in pairs(data) do
    --     if k == "fusionGrades" then
    --         for kk, vv in pairs(v) do
    --             g_logger.info("Fusion Grade - " .. tostring(kk) .. ": " .. tostring(vv))
    --         end
    --     else
    --         g_logger.info("Forge Data - " .. tostring(k) .. ": " .. tostring(v))
    --     end
    -- end
end

function ForgeController:getColor(currentType)
    ForgeController.conversion:handleButtons()
    if currentType == "dustToSilver" then
        if self.currentDust >= self.conversion.necessaryDustToSliver then
            return "#c0c0c0"
        else
            return "#d33c3c"
        end
    end

    if currentType == "sliverToCore" then
        if self.currentSlivers >= self.conversion.sliverToCore then
            return "#c0c0c0"
        else
            return "#d33c3c"
        end
    end

    if currentType == "increaseDustLimit" then
        if self.currentDust >= self.conversion.dustMaxIncreaseCost then
            return "#c0c0c0"
        else
            return "#d33c3c"
        end
    end
end

-- CONVERSION MENU
ForgeController.conversion = {
    fusionPrices = {},
    dustCap = 225,
    dustMax = 100,
    necessaryDustToSliver = 60,
    dustToSliver = 3,
    sliverToCore = 50,
    dustMaxIncreaseCost = 100,
    dustToSilverLabel = "Generate 3",
    sliverToCoreLabel = "Generate 1",
    dustMaxLabel = "Raise limit from\n100 to 101",
    disableDustConversion = true,
    disableSliverConversion = true,
    disableIncreaseDustLimit = true,
    clip = { x = 0, y = 0, width = 118, height = 34 },
    types = {
        DUST2SLIVER = 2,
        SLIVER2CORE = 3,
        INCREASE_DUST_LIMIT = 4
    },
}

function ForgeController.conversion:handleButtons()
    local dustMax = ForgeController.conversion.dustMax or 100
    ForgeController.conversion.disableDustConversion = ForgeController.currentDust <
        ForgeController.conversion.necessaryDustToSliver
    ForgeController.conversion.disableSliverConversion = ForgeController.currentSlivers <
        ForgeController.conversion.sliverToCore
    ForgeController.conversion.disableIncreaseDustLimit = ForgeController.currentDust <
        ForgeController.conversion.dustMaxIncreaseCost
    ForgeController.currentDustAndMaxLabel = string.format("%d/%d", ForgeController.currentDust,
        dustMax)
    if dustMax >= ForgeController.conversion.dustCap then
        ForgeController.conversion.dustMaxLabel = "You have reached\nthe maximum dust limit"
        ForgeController.conversion.disableIncreaseDustLimit = true
    else
        ForgeController.conversion.dustMaxLabel = string.format("Raise limit from\n%d to %d", dustMax, dustMax + 1)
    end
end

function ForgeController.conversion:toggle(conversionType)
    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    if conversionType == ForgeController.conversion.types.DUST2SLIVER then
        local dustBalance = player:getResourceBalance(ResourceTypes.FORGE_DUST) or 0
        if dustBalance <= ForgeController.conversion.necessaryDustToSliver then
            return
        end
        g_game.forgeRequest(conversionType)
        return
    end

    if conversionType == ForgeController.conversion.types.SLIVER2CORE then
        local sliverBalance = player:getResourceBalance(ResourceTypes.FORGE_SLIVER) or 0
        if sliverBalance <= ForgeController.conversion.sliverToCore then
            return
        end
        g_game.forgeRequest(conversionType)
        return
    end

    if conversionType == ForgeController.conversion.types.INCREASE_DUST_LIMIT then
        local dustBalance = player:getResourceBalance(ResourceTypes.FORGE_DUST) or 0
        local currentNecessaryDust = ForgeController.conversion.dustMaxIncreaseCost
        local maxDustCap = ForgeController.conversion.dustCap
        local maxDustLevel = ForgeController.conversion.dustMax

        if maxDustCap > 0 and maxDustLevel >= maxDustCap then
            return
        end

        if dustBalance < currentNecessaryDust then
            return
        end
        g_game.forgeRequest(conversionType)
    end
end

function ForgeController:resetTabsClip()
    self.fusion.clip = { x = 0, y = 0, width = 118, height = 34 }
    self.transfer.clip = { x = 0, y = 0, width = 118, height = 34 }
    self.conversion.clip = { x = 0, y = 0, width = 116, height = 34 }
    self.history.clip = { x = 0, y = 0, width = 118, height = 34 }
end

function ForgeController:toggleConversionMenu()
    self:resetTabsClip()
    self.currentTab = 'conversion'
    self.conversion.clip = { x = 0, y = 34, width = 116, height = 34 }
end

-- CONVERSION MENU

-- HISTORY MENU
ForgeController.history = {
    currentPage = 0,
    lastPage = 0,
    showPreviousButton = false,
    showNextButton = false,
    list = {},
    clip = { x = 0, y = 0, width = 118, height = 34 }
}
function ForgeController:toggleHistoryMenu()
    self:resetTabsClip()
    self.currentTab = 'history'
    g_game.sendForgeBrowseHistoryRequest(0)
    self.history.clip = { x = 0, y = 34, width = 118, height = 34 }
end

local historyActionLabels = {
    [0] = 'Fusion',
    [1] = 'Transfer',
    [2] = 'Conversion',
    [3] = 'Conversion',
    [4] = 'Conversion'
}
local formatHistoryDate = helpers.formatHistoryDate
function onBrowseForgeHistory(page, lastPage, currentCount, historyList)
    page = math.max(tonumber(page) or 0, 1)
    lastPage = math.max(tonumber(lastPage) or page, 1)
    currentCount = tonumber(currentCount) or 0
    lastPage = lastPage > 1 and lastPage - 1 or lastPage


    ForgeController.history.currentPage = page
    ForgeController.history.lastPage = lastPage

    ForgeController.history.showPreviousButton = page > 1
    ForgeController.history.showNextButton = page < lastPage

    for _, entry in ipairs(historyList) do
        entry.createdAt = formatHistoryDate(entry.createdAt)
        entry.actionType = historyActionLabels[entry.actionType]
        entry.description = entry.description or '-'
        if entry.actionType == historyActionLabels[0] or entry.actionType == historyActionLabels[1] then
            local firstSpaceIndex = string.find(entry.description, " ")
            if firstSpaceIndex then
                entry.description = string.sub(entry.description, 1, firstSpaceIndex - 1)
            end
        end
    end
    ForgeController.history.list = historyList or {}
end

function ForgeController.history:onHistoryPreviousPage()
    local currentPage = ForgeController.history.currentPage or 0
    if currentPage <= 1 then
        return
    end

    g_game.sendForgeBrowseHistoryRequest(currentPage - 1)
end

function ForgeController.history:onHistoryNextPage()
    local currentPage = ForgeController.history.currentPage or 0
    local lastPage = ForgeController.history.lastPage or currentPage

    if currentPage >= lastPage then
        return
    end

    g_game.sendForgeBrowseHistoryRequest(currentPage + 1)
end

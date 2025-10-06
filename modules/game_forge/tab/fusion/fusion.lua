local helpers = require('modules.game_forge.game_forge_helpers')

local resolveScrollContents = helpers.resolveScrollContents
local getChildrenByStyleName = helpers.getChildrenByStyleName
local getFirstChildByStyleName = helpers.getFirstChildByStyleName
local resolveForgePrice = helpers.resolveForgePrice
local formatGoldAmount = helpers.formatGoldAmount

local FusionTab = {}

local controllerState = setmetatable({}, { __mode = 'k' })

local function ensureSelections(controller)
    if type(controller.fusionCoreSelections) ~= 'table' then
        controller.fusionCoreSelections = {
            success = false,
            tier = false
        }
    end
    return controller.fusionCoreSelections
end

local function getState(controller)
    local state = controllerState[controller]
    if not state then
        state = {}
        controllerState[controller] = state
    end
    ensureSelections(controller)
    return state
end

function FusionTab.registerDependencies(controller, dependencies)
    local state = getState(controller)
    dependencies = dependencies or {}
    state.resourceTypes = dependencies.resourceTypes or state.resourceTypes
end

function FusionTab.resetCoreSelections(controller)
    local selections = ensureSelections(controller)
    selections.success = false
    selections.tier = false
end

function FusionTab.invalidateContext(controller)
    local state = getState(controller)
    state.context = nil

    if state.selectionGroup then
        state.selectionGroup:destroy()
        state.selectionGroup = nil
    end

    if state.convergenceGroup then
        state.convergenceGroup:destroy()
        state.convergenceGroup = nil
    end
end

local function resolveContext(controller)
    local state = getState(controller)
    local panel = controller:loadTab('fusion')
    if not panel then
        return nil
    end

    local context = state.context
    if not context or context.panel ~= panel or panel:isDestroyed() then
        local resultArea = panel.test or panel:recursiveGetChildById('test')
        local selectionPanel = panel.fusionSelectionArea or getFirstChildByStyleName(panel, 'fusion-selection-area')
        local convergenceSection = panel.fusionConvergenceSection
            or (resultArea and resultArea.fusionConvergenceSection)
            or getFirstChildByStyleName(resultArea, 'fusion-convergence-section')

        local targetItem = panel.fusionTargetItemPreview
            or panel:recursiveGetChildById('fusionTargetItemPreview')
            or getFirstChildByStyleName(panel, 'fusion-slot-item')

        context = {
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
        state.context = context
    end

    if not context.selectionPanel or context.selectionPanel:isDestroyed() then
        context.selectionPanel = panel.fusionSelectionArea or getFirstChildByStyleName(panel, 'fusion-selection-area')
        context.selectionItemsPanel = nil
    end

    if context.selectionPanel and (not context.selectionItemsPanel or context.selectionItemsPanel:isDestroyed()) then
        local selectionGrid = context.selectionPanel.fusionSelectionGrid or panel.fusionSelectionGrid
        if not selectionGrid then
            local selectionGrids = getChildrenByStyleName(context.selectionPanel, 'forge-slot-grid')
            selectionGrid = selectionGrids[1]
        end
        context.selectionItemsPanel = resolveScrollContents(selectionGrid)
    end

    if context.targetItem and context.targetItem:isDestroyed() then
        context.targetItem = nil
    end

    if not context.targetItem then
        context.targetItem = panel.fusionTargetItemPreview
            or panel:recursiveGetChildById('fusionTargetItemPreview')
            or getFirstChildByStyleName(panel, 'fusion-slot-item')
    end

    if not context.selectedItemIcon or context.selectedItemIcon:isDestroyed() then
        context.selectedItemIcon = panel.fusionSelectedItemIcon
            or panel:recursiveGetChildById('fusionSelectedItemIcon')
    end

    if context.selectedItemIcon then
        context.selectedItemIcon:setShowCount(true)
    end

    if not context.selectedItemQuestion or context.selectedItemQuestion:isDestroyed() then
        context.selectedItemQuestion = panel.fusionSelectedItemQuestion
            or panel:recursiveGetChildById('fusionSelectedItemQuestion')
    end

    if not context.selectedItemCounter or context.selectedItemCounter:isDestroyed() then
        context.selectedItemCounter = panel.fusionSelectedItemCounter
            or panel:recursiveGetChildById('fusionSelectedItemCounter')
    end

    if context.resultArea and (not context.fusionButton or context.fusionButton:isDestroyed()) then
        local actionButton = getFirstChildByStyleName(context.resultArea, 'forge-action-button')
        if actionButton then
            context.fusionButton = actionButton
            local resultItems = getChildrenByStyleName(actionButton, 'forge-result-item')
            context.fusionButtonItem = resultItems[1]
            context.fusionButtonItemTo = resultItems[2]
        end
    end

    if context.resultArea and (not context.costLabel or context.costLabel:isDestroyed()) then
        local costContainer = getFirstChildByStyleName(context.resultArea, 'fusion-result-cost')
        if costContainer then
            local labels = getChildrenByStyleName(costContainer, 'forge-full-width-label')
            context.costLabel = labels[1]
        end
    end

    if context.resultArea and (not context.successCoreButton or context.successCoreButton:isDestroyed()) then
        context.successCoreButton = context.panel.fusionImproveButton
            or context.resultArea.fusionImproveButton
            or context.panel:recursiveGetChildById('fusionImproveButton')
    end

    if context.resultArea and (not context.tierCoreButton or context.tierCoreButton:isDestroyed()) then
        context.tierCoreButton = context.panel.fusionReduceButton
            or context.resultArea.fusionReduceButton
            or context.panel:recursiveGetChildById('fusionReduceButton')
    end

    if context.resultArea and (not context.successRateLabel or context.successRateLabel:isDestroyed()) then
        context.successRateLabel = context.panel.fusionSuccessRateValue
            or context.resultArea.fusionSuccessRateValue
            or context.panel:recursiveGetChildById('fusionSuccessRateValue')
    end

    if context.resultArea and (not context.tierLossLabel or context.tierLossLabel:isDestroyed()) then
        context.tierLossLabel = context.panel.fusionTierLossValue
            or context.resultArea.fusionTierLossValue
            or context.panel:recursiveGetChildById('fusionTierLossValue')
    end

    if context.convergenceSection and (not context.convergenceItemsPanel or context.convergenceItemsPanel:isDestroyed()) then
        local convergenceGrid = context.convergenceSection.fusionConvergenceGrid
            or (context.resultArea and context.resultArea.fusionConvergenceGrid)
        if not convergenceGrid then
            convergenceGrid = getFirstChildByStyleName(context.convergenceSection, 'forge-slot-grid')
        end
        context.convergenceItemsPanel = resolveScrollContents(convergenceGrid)
        local labels = getChildrenByStyleName(context.convergenceSection, 'forge-full-width-label')
        context.dustAmountLabel = labels[1]
    end

    return context
end

local function onFusionSelectionChange(controller, state, selectedWidget)
    if not selectedWidget or selectedWidget:isDestroyed() then
        controller:resetFusionConversionPanel()
        return
    end

    controller:configureFusionConversionPanel(selectedWidget)
end

local function onFusionConvergenceSelectionChange(controller, _, selectedWidget)
    if not selectedWidget or selectedWidget:isDestroyed() then
        controller.fusionSelectedItem = nil
        return
    end

    controller.fusionSelectedItem = selectedWidget.fusionItemInfo
end

function FusionTab.updateFusionCoreButtons(controller)
    if not controller.ui then
        return
    end

    local context = resolveContext(controller)
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

    local selections = ensureSelections(controller)

    local player = g_game.getLocalPlayer()
    local resourceTypes = getState(controller).resourceTypes or {}
    local coreType = resourceTypes.cores
    local coreBalance = 0
    if player and coreType then
        coreBalance = player:getResourceBalance(coreType) or 0
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

function FusionTab.onToggleFusionCore(controller, coreType)
    if not controller.ui then
        return
    end

    if coreType ~= 'success' and coreType ~= 'tier' then
        return
    end

    local context = resolveContext(controller)
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

    local selections = ensureSelections(controller)
    local isSelected = selections[coreType] and true or false

    local player = g_game.getLocalPlayer()
    local resourceTypes = getState(controller).resourceTypes or {}
    local coreTypeId = resourceTypes.cores
    local coreBalance = 0
    if player and coreTypeId then
        coreBalance = player:getResourceBalance(coreTypeId) or 0
    end

    if isSelected then
        selections[coreType] = false
        FusionTab.updateFusionCoreButtons(controller)
        return
    end

    local otherType = coreType == 'success' and 'tier' or 'success'
    local otherSelected = selections[otherType] and 1 or 0
    if coreBalance <= otherSelected then
        return
    end

    selections[coreType] = true
    FusionTab.updateFusionCoreButtons(controller)
end

function FusionTab.configureConversionPanel(controller, selectedWidget)
    if not selectedWidget or not selectedWidget.itemPtr then
        return
    end

    local state = getState(controller)
    local context = resolveContext(controller)
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

    controller.fusionItem = itemPtr
    controller.fusionItemCount = itemCount

    if context.selectedItemIcon then
        local selectedPreview = Item.create(itemPtr:getId(), itemCount)
        selectedPreview:setTier(itemTier)
        context.selectedItemIcon:setItem(selectedPreview)
        context.selectedItemIcon:setItemCount(itemCount)
        g_logger.info(">> selectedItemIcon id: " ..
            itemPtr:getId() .. " tier: " .. itemTier .. " target tier: " .. itemTier + 1)
        ItemsDatabase.setTier(context.selectedItemIcon, selectedPreview)

        controller:getFusionPrice(controller.fusionPrices, itemPtr, itemTier)
        g_logger.info("VSF?")
    end

    if context.targetItem then
        local targetDisplay = Item.create(itemPtr:getId(), itemCount)
        targetDisplay:setTier(itemTier)
        context.targetItem:setItem(targetDisplay)
        context.targetItem:setItemCount(itemCount)
        ItemsDatabase.setTier(context.targetItem, targetDisplay)
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

        g_logger.info(">> fusionButtonItemTo id: " ..
            itemPtr:getId() .. " tier: " .. itemTier .. " target tier: " .. itemTier + 1)
    end

    if context.convergenceItemsPanel then
        context.convergenceItemsPanel:destroyChildren()
    end

    if state.convergenceGroup then
        state.convergenceGroup:destroy()
        state.convergenceGroup = nil
    end

    local convergenceGroup = UIRadioGroup.create()
    convergenceGroup.onSelectionChange = function(group, widget)
        onFusionConvergenceSelectionChange(controller, group, widget)
    end
    state.convergenceGroup = convergenceGroup

    controller.fusionSelectedItem = nil

    local player = g_game.getLocalPlayer()
    local resourceTypes = state.resourceTypes or {}
    local dustType = resourceTypes.dust
    local dustRequirement = (controller.openData and tonumber(controller.openData.convergenceDustFusion))
        or tonumber(controller.convergenceDustFusion) or 0
    local priceList = controller.fusionPrices or (controller.openData and controller.openData.fusionPrices) or {}
    local price = resolveForgePrice(priceList, itemPtr, itemTier)

    if context.dustAmountLabel and player and dustType then
        local dustBalance = player:getResourceBalance(dustType) or 0
        local hasEnoughDust = dustRequirement <= 0 or dustBalance >= dustRequirement
        context.dustAmountLabel:setColor(hasEnoughDust and '$var-text-cip-color' or '#d33c3c')
    end

    if context.costLabel then
        context.costLabel:setText(formatGoldAmount(price))
        if player then
            local totalMoney = player:getTotalMoney() or 0
            context.costLabel:setColor(totalMoney >= price and '$var-text-cip-color' or '#d33c3c')
        end
    end

    local hasConvergenceOptions = false
    local convergenceData = controller.convergenceFusion or {}
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
                            convergenceGroup:addWidget(widget)
                            hasConvergenceOptions = true
                        end
                    end
                end
            end
        end
    end

    if context.convergenceSection then
        context.convergenceSection:setVisible(controller.modeFusion and hasConvergenceOptions)
    end

    local firstWidget = convergenceGroup:getFirstWidget()
    if firstWidget then
        convergenceGroup:selectWidget(firstWidget, true)
        onFusionConvergenceSelectionChange(controller, convergenceGroup, firstWidget)
    end

    FusionTab.updateFusionCoreButtons(controller)
end

function FusionTab.resetConversionPanel(controller)
    local state = getState(controller)
    local context = resolveContext(controller)
    if not context then
        return
    end

    controller.fusionItem = nil
    controller.fusionItemCount = nil
    controller.fusionSelectedItem = nil

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

    if state.convergenceGroup then
        state.convergenceGroup:destroy()
        state.convergenceGroup = nil
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

    FusionTab.resetCoreSelections(controller)
    FusionTab.updateFusionCoreButtons(controller)
end

function FusionTab.updateFusionItems(controller, fusionData)
    local state = getState(controller)
    local context = resolveContext(controller)
    if not context then
        return
    end

    if context.selectionPanel and (not context.selectionItemsPanel or context.selectionItemsPanel:isDestroyed()) then
        local selectionGrids = getChildrenByStyleName(context.selectionPanel, 'forge-slot-grid')
        context.selectionItemsPanel = resolveScrollContents(selectionGrids[1])
    end

    FusionTab.resetConversionPanel(controller)

    local itemsPanel = context.selectionItemsPanel
    if not itemsPanel then
        return
    end

    itemsPanel:destroyChildren()

    if state.selectionGroup then
        state.selectionGroup:destroy()
        state.selectionGroup = nil
    end

    local selectionGroup = UIRadioGroup.create()
    selectionGroup:clearSelected()
    selectionGroup.onSelectionChange = function(group, widget)
        onFusionSelectionChange(controller, state, widget)
    end
    state.selectionGroup = selectionGroup

    local data = fusionData
    if not data then
        if controller.modeFusion then
            data = controller.convergenceFusion
        else
            data = controller.fusionItems
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

        widget.onCheckChange = function(selfWidget, checked)
            applySelectionHighlight(selfWidget, checked)
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
        g_logger.info("item id: " .. itemPtr:getId() .. " tier: " .. itemPtr:getTier())
        itemWidget:setItem(itemPtr)
        itemWidget:setItemCount(info.count or itemPtr:getCount())
        ItemsDatabase.setRarityItem(itemWidget, itemPtr)
        ItemsDatabase.setTier(itemWidget, itemPtr)


        widget.item = itemWidget
        widget.itemPtr = itemPtr
        widget.fusionItemInfo = info

        applySelectionHighlight(widget, widget:isChecked())

        selectionGroup:addWidget(widget)
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

return FusionTab

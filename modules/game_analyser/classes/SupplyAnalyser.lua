-- Missing utility functions
local function formatMoney(value, separator)
    return comma_value(tostring(value))
end

local function tokformat(value)
    -- Simple number formatting - could be enhanced if needed
    if value >= 1000000000 then
        return string.format("%.1fB", value / 1000000000)
    elseif value >= 1000000 then
        return string.format("%.1fM", value / 1000000)
    elseif value >= 1000 then
        return string.format("%.1fK", value / 1000)
    else
        return tostring(value)
    end
end

if not SupplyAnalyser then
	SupplyAnalyser = {
		launchTime = 0,
		session = 0,
		goldValue = 0,
		goldHour = 0,
		target = 0,
		gaugeVisible = true,
		graphVisible = true,
		items = {},
		-- private
		window = nil,
	}

	SupplyAnalyser.__index = SupplyAnalyser
end

local targetMaxMargin = 142

function SupplyAnalyser:create()
	SupplyAnalyser.launchTime = 0
	SupplyAnalyser.session = 0
	SupplyAnalyser.goldValue = 0
	SupplyAnalyser.goldHour = 0
	SupplyAnalyser.target = 0
	SupplyAnalyser.gaugeVisible = true
	SupplyAnalyser.graphVisible = true
	SupplyAnalyser.items = {}
	SupplyAnalyser.forceUpdateBalance = false
	SupplyAnalyser.updateBalance = true

	SupplyAnalyser.window = openedWindows['supplyButton']
end

local function getCurrentPrice(itemPtr)
	local value = itemPtr:getDefaultBuyPrice()
	if value == 0 then
		value = itemPtr:getAverageMarketValue()
	end
	return value
end

function onSupplyExtra(mousePosition)
  if cancelNextRelease then
    cancelNextRelease = false
    return false
  end

	local menu = g_ui.createWidget('PopupMenu')
	menu:setGameMenu(true)
	menu:addOption(tr('Reset Data'), function() SupplyAnalyser:reset() return end)
	menu:addSeparator()
	menu:addOption(tr('Set Supply Per Hour Target'), function() SupplyAnalyser:openTargetConfig() return end)
	menu:addCheckBoxOption(tr('Supply Per Hour Gauge'), function() SupplyAnalyser:setSupplyPerHourGauge(not SupplyAnalyser.window.contentsPanel.targetLabel:isVisible()) end, "", SupplyAnalyser.window.contentsPanel.targetLabel:isVisible())
	menu:addCheckBoxOption(tr('Supply Per Hour Graph'), function() SupplyAnalyser:setSupplyPerHourGraph(not SupplyAnalyser.window.contentsPanel.graphPanel:isVisible()) end, "", SupplyAnalyser.window.contentsPanel.graphPanel:isVisible())
	menu:display(mousePosition)
  return true
end

function SupplyAnalyser:reset()
	SupplyAnalyser.launchTime = g_clock.millis()
	SupplyAnalyser.session = 0
	SupplyAnalyser.goldValue = 0
	SupplyAnalyser.goldHour = 0
	SupplyAnalyser.target = 0
	SupplyAnalyser.items = {}
	SupplyAnalyser.forceUpdateBalance = false
	SupplyAnalyser.updateBalance = true

	SupplyAnalyser.window.contentsPanel.graphPanel:clear()
	
	-- Initialize graph if it doesn't exist
	if SupplyAnalyser.window.contentsPanel.graphPanel:getGraphsCount() == 0 then
		SupplyAnalyser.window.contentsPanel.graphPanel:createGraph()
		SupplyAnalyser.window.contentsPanel.graphPanel:setLineWidth(1, 1)
		SupplyAnalyser.window.contentsPanel.graphPanel:setLineColor(1, "#0096c8")
	end
	
	SupplyAnalyser.window.contentsPanel.graphPanel:addValue(1, 0)
	SupplyAnalyser.window.contentsPanel.lootedItems:setVisible(false)
	SupplyAnalyser.window.contentsPanel.separatorLootedItems:setVisible(false)

	SupplyAnalyser.window.contentsPanel.lootedItems:destroyChildren()

	SupplyAnalyser:updateWindow(true)
end

function SupplyAnalyser:checkBalance()
	local oldBalance = SupplyAnalyser.goldValue
	local itemList = {}
	for index, itemInfo in pairs(SupplyAnalyser.items) do
		if itemInfo.time + 3600 < os.time() then
			SupplyAnalyser.items[index] = nil
			SupplyAnalyser:decreaseWidget(itemInfo.itemId)
		else
			if not itemList[itemInfo.itemId] then
				itemList[itemInfo.itemId] = {count = 1}
			else
				itemList[itemInfo.itemId].count = itemList[itemInfo.itemId].count + 1
			end
		end
	end

	SupplyAnalyser.forceUpdateBalance = false

	if SupplyAnalyser.updateBalance or oldBalance ~= SupplyAnalyser.goldValue then
		SupplyAnalyser:updateWindow(false)
		SupplyAnalyser.updateBalance = false
	end
end

function SupplyAnalyser:updateWindow(updateScroll, ignoreVisible)
	if not SupplyAnalyser.window:isVisible() and not ignoreVisible then
		return
	end

	local target = SupplyAnalyser.target or 0
	local goldHour = SupplyAnalyser.goldHour or 0
	local goldValue = SupplyAnalyser.goldValue or 0

	local contentsPanel = SupplyAnalyser.window.contentsPanel
	contentsPanel.gold:setText(formatMoney(goldValue, ","))
	contentsPanel.goldHour:setText(formatMoney(goldHour, ","))
	contentsPanel.goldTarget:setText(formatMoney(target, ","))

	if target == 0 and goldHour == 0 then
		SupplyAnalyser.window.contentsPanel.supplyTargetBG.supplyArrow:setMarginLeft(targetMaxMargin / 2)
	else
		local targetValue = math.max(1, target)
		local current = goldHour
		local percent = (current * 71) / targetValue
		SupplyAnalyser.window.contentsPanel.supplyTargetBG.supplyArrow:setMarginLeft(math.min(targetMaxMargin, math.ceil(percent)))
	end

	SupplyAnalyser.window.contentsPanel.supplyTargetBG:setTooltip(string.format("Current: %d\nTarget: %d", goldHour, target))

	if not updateScroll then
		return
	end

	local numOfItems = 0
	local numOfLines = 0
	for _, __ in pairs(contentsPanel.lootedItems:getChildren()) do
		numOfItems = numOfItems + 1
		if numOfItems == 4 then
			numOfItems = 0
			numOfLines = numOfLines + 1
		end
	end

	if numOfItems > 0 then
		contentsPanel.lootedItems:setVisible(true)
		contentsPanel.separatorLootedItems:setVisible(true)
	end

	numOfLines = not table.empty(SupplyAnalyser.items) and numOfLines + 1 or 0
	contentsPanel.lootedItems:setHeight(35 * numOfLines)
end

function SupplyAnalyser:updateGraphics()
	local uptime = math.floor((g_clock.millis() - SupplyAnalyser.launchTime)/1000)
	if uptime < 5*60 then
		SupplyAnalyser.goldHour = SupplyAnalyser.goldValue
	else
		SupplyAnalyser.goldHour = math.ceil((SupplyAnalyser.goldValue/uptime)*3600)
	end

	-- Ensure graph exists before adding value
	if SupplyAnalyser.window.contentsPanel.graphPanel:getGraphsCount() == 0 then
		SupplyAnalyser.window.contentsPanel.graphPanel:createGraph()
		SupplyAnalyser.window.contentsPanel.graphPanel:setLineWidth(1, 1)
		SupplyAnalyser.window.contentsPanel.graphPanel:setLineColor(1, "#0096c8")
	end
	SupplyAnalyser.window.contentsPanel.graphPanel:addValue(1, SupplyAnalyser.goldHour)
	-- ignore graph value
	SupplyAnalyser.goldHour = math.ceil((SupplyAnalyser.goldValue/uptime)*3600)
end

function SupplyAnalyser:getItemCount(itemId)
	local count = 0
	for _, item in pairs(SupplyAnalyser.items) do
		if item.itemId == itemId then
			count = count + 1
		end
	end
	return count
end

function SupplyAnalyser:checkDecrease()
end

function SupplyAnalyser:updateWidget(itemId)
	local itemPtr = Item.create(itemId, 1)
	local contentsPanel = SupplyAnalyser.window.contentsPanel
	local widget = contentsPanel.lootedItems:getChildById(tostring(itemId))
	if not widget then
		widget = g_ui.createWidget('LootItem', contentsPanel.lootedItems)
		widget:setId(itemId)
		widget:setItemId(itemId)
	end

	local count = SupplyAnalyser:getItemCount(itemId)
	widget:setItemCount(count)

	local value = getCurrentPrice(itemPtr)
	widget:setTooltip(string.format("%s (Value: %sgp, Sum: %sgp)", getItemServerName(itemId), formatMoney(value, ","), formatMoney(value * count, ",")))
end

function SupplyAnalyser:decreaseWidget(itemId)
	local contentsPanel = SupplyAnalyser.window.contentsPanel
	local count = SupplyAnalyser:getItemCount(itemId)
	local widget = contentsPanel.lootedItems:getChildById(tostring(itemId))
	if count < 1 then
		widget:destroy()
		SupplyAnalyser:updateWindow(true)
		return
	end

	local itemPtr = Item.create(itemId, 1)
	local value = getCurrentPrice(itemPtr)
	widget:setItemCount(count)
	widget:setTooltip(string.format("%s (Value: %sgp, Sum: %sgp)", getItemServerName(itemId), formatMoney(value, ","), formatMoney(value * count, ",")))
end

function SupplyAnalyser:addSuppliesItems(itemId)
	SupplyAnalyser.items[#SupplyAnalyser.items + 1] = {itemId = itemId, time = os.time()}

	local itemPtr = Item.create(itemId, 1)
	local value = getCurrentPrice(itemPtr)

	-- update balance
	SupplyAnalyser.goldValue = SupplyAnalyser.goldValue + value
	SupplyAnalyser.updateBalance = true

	SupplyAnalyser:updateWidget(itemId)
	SupplyAnalyser:checkBalance()
	SupplyAnalyser:updateWindow(true)
end

function SupplyAnalyser:setSupplyPerHourGauge(value)
	SupplyAnalyser.window.contentsPanel.targetLabel:setVisible(value)
	SupplyAnalyser.window.contentsPanel.goldLabelIcon:setVisible(value)
	SupplyAnalyser.window.contentsPanel.goldTarget:setVisible(value)
	SupplyAnalyser.window.contentsPanel.supplyTargetBG:setVisible(value)
	SupplyAnalyser.window.contentsPanel.separatorGauge:setVisible(value)

	SupplyAnalyser.gaugeVisible = value

	if value then
		SupplyAnalyser.window.contentsPanel.supplyGraphBG:addAnchor(AnchorTop, 'separatorGauge', AnchorBottom)
	else
		SupplyAnalyser.window.contentsPanel.supplyGraphBG:addAnchor(AnchorTop, 'separatorLootedItems', AnchorBottom)
	end
end

function SupplyAnalyser:setSupplyPerHourGraph(value)
	SupplyAnalyser.window.contentsPanel.supplyGraphBG:setVisible(value)
	SupplyAnalyser.window.contentsPanel.graphPanel:setVisible(value)
	SupplyAnalyser.window.contentsPanel.graphHorizontal:setVisible(value)

	SupplyAnalyser.graphVisible = value
end

function SupplyAnalyser:gaugeIsVisible()
	return SupplyAnalyser.gaugeVisible
end
function SupplyAnalyser:graphIsVisible()
	return SupplyAnalyser.graphVisible
end
function SupplyAnalyser:getTarget()
	return SupplyAnalyser.target
end
function SupplyAnalyser:setTarget(value)
	SupplyAnalyser.target = tonumber(value) or 0
	SupplyAnalyser.window.contentsPanel.goldTarget:setText(formatMoney(SupplyAnalyser.target, ","))
end

function SupplyAnalyser:openTargetConfig()
	local window = configPopupWindow["lootButton"]
	window:show()
	window:setText('Set Supply Target')
	window.contentPanel.text:setImageSource('/images/game/analyzer/labels/supply')

	window.onEnter = function()
		local value = window.contentPanel.lootTarget:getText()
		SupplyAnalyser.target = tonumber(value)
		window:hide()
	end
	window.contentPanel.lootTarget:setText(tonumber(SupplyAnalyser.target) or '0')

	window.contentPanel.ok.onClick = function()
		local value = window.contentPanel.lootTarget:getText()
		SupplyAnalyser.target = tonumber(value)
		window:hide()
	end
	window.contentPanel.cancel.onClick = function()
		window:hide()
	end
end

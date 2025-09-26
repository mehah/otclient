-- Missing utility functions
local function formatMoney(value, separator)
    return comma_value(tostring(value))
end

-- Add capitalize function to string library if it doesn't exist
if not string.capitalize then
    function string.capitalize(str)
        if not str or str == "" then
            return str
        end
        return str:gsub("(%l)(%w*)", function(first, rest)
            return first:upper() .. rest
        end)
    end
end

if not LootAnalyser then
	LootAnalyser = {
		launchTime = 0,
		session = 0,
		goldValue = 0,
		goldHour = 0,
		target = 0,
		gaugeVisible = true,
		graphVisible = true,
		lootedItems = {},
		-- private
		window = nil,
		event = nil,
		eventGraph = nil,
	}

	LootAnalyser.__index = LootAnalyser
end

local targetMaxMargin = 142


function LootAnalyser:create()
	LootAnalyser.launchTime = 0
	LootAnalyser.session = 0
	LootAnalyser.goldValue = 0
	LootAnalyser.goldHour = 0
	LootAnalyser.target = 0
	LootAnalyser.gaugeVisible = true
	LootAnalyser.graphVisible = true
	LootAnalyser.lootedItems = {}
	LootAnalyser.forceUpdateBalance = false
	LootAnalyser.updateBalance = true

	-- private
	LootAnalyser.window = openedWindows['lootButton']
	LootAnalyser.eventGraph = nil
	
	if not LootAnalyser.window then
		return
	end

	-- Hide buttons we don't want
	local toggleFilterButton = LootAnalyser.window:recursiveGetChildById('toggleFilterButton')
	if toggleFilterButton then
		toggleFilterButton:setVisible(false)
	end
	
	local newWindowButton = LootAnalyser.window:recursiveGetChildById('newWindowButton')
	if newWindowButton then
		newWindowButton:setVisible(false)
	end

	-- Position contextMenuButton where toggleFilterButton was (to the left of minimize button)
	local contextMenuButton = LootAnalyser.window:recursiveGetChildById('contextMenuButton')
	local minimizeButton = LootAnalyser.window:recursiveGetChildById('minimizeButton')
	
	if contextMenuButton and minimizeButton then
		contextMenuButton:setVisible(true)
		contextMenuButton:breakAnchors()
		contextMenuButton:addAnchor(AnchorTop, minimizeButton:getId(), AnchorTop)
		contextMenuButton:addAnchor(AnchorRight, minimizeButton:getId(), AnchorLeft)
		contextMenuButton:setMarginRight(7)  -- Same margin as toggleFilterButton had
		contextMenuButton:setMarginTop(0)
		
		-- Set up contextMenuButton click handler to show our menu
		contextMenuButton.onClick = function(widget, mousePos)
			local pos = mousePos or g_window.getMousePosition()
			return onLootingExtra(pos)
		end
	end

	-- Position lockButton to the left of contextMenuButton
	local lockButton = LootAnalyser.window:recursiveGetChildById('lockButton')
	
	if lockButton and contextMenuButton then
		lockButton:setVisible(true)
		lockButton:breakAnchors()
		lockButton:addAnchor(AnchorTop, contextMenuButton:getId(), AnchorTop)
		lockButton:addAnchor(AnchorRight, contextMenuButton:getId(), AnchorLeft)
		lockButton:setMarginRight(2)  -- Same margin as in miniwindow style
		lockButton:setMarginTop(0)
	end
end


function onLootingExtra(mousePosition)
  if cancelNextRelease then
    cancelNextRelease = false
    return false
  end

  local gaugeVisible = LootAnalyser.window.contentsPanel.targetLabel:isVisible()
  local graphVisible = LootAnalyser.window.contentsPanel.graphPanel:isVisible()

	local menu = g_ui.createWidget('PopupMenu')
	menu:setGameMenu(true)
	menu:addOption(tr('Reset Data'), function() LootAnalyser:reset(); return end)
	menu:addSeparator()
	menu:addOption(tr('Set Loot Per Hour Target'), function() LootAnalyser:openTargetConfig() return end)
	menu:addCheckBox(tr('Loot Per Hour Gauge'), gaugeVisible, function() LootAnalyser:setLootPerHourGauge(not gaugeVisible) end)
	menu:addCheckBox(tr('Loot Per Hour Graph'), graphVisible, function() LootAnalyser:setLootPerHourGraph(not graphVisible) end)
	menu:display(mousePosition)
  return true
end

function LootAnalyser:reset()
	LootAnalyser.launchTime = g_clock.millis()
	LootAnalyser.session = 0
	LootAnalyser.goldValue = 0
	LootAnalyser.goldHour = 0
	LootAnalyser.target = 0
	LootAnalyser.lootedItems = {}
	LootAnalyser.forceUpdateBalance = false
	LootAnalyser.updateBalance = true

	LootAnalyser.window.contentsPanel.graphPanel:clear()
	
	-- Initialize graph if it doesn't exist
	if LootAnalyser.window.contentsPanel.graphPanel:getGraphsCount() == 0 then
		LootAnalyser.window.contentsPanel.graphPanel:createGraph()
		LootAnalyser.window.contentsPanel.graphPanel:setLineWidth(1, 1)
		LootAnalyser.window.contentsPanel.graphPanel:setLineColor(1, "#ffca38")
	end
	
	LootAnalyser.window.contentsPanel.graphPanel:addValue(1, 0)

	LootAnalyser:updateWindow(true)
end

function LootAnalyser:updateBasePriceFromLootedItems(itemId, newPriceValue)
	local itemInfo = self.lootedItems[itemId]
	if itemInfo then
		if not newPriceValue then
			-- in case we dont have the value already
			-- lets create a dummy item just to retrieve
			-- the price value
			local itemPtr = Item.create(itemId, 1)
			newPriceValue = itemPtr:getPriceValue()
			itemPtr = nil
		end

		if itemInfo.basePrice ~= newPriceValue then
			itemInfo.basePrice = newPriceValue
			LootAnalyser.forceUpdateBalance = true
			LootAnalyser:updateWindow(true)
		end
	end
end

function LootAnalyser:checkBalance()
	local oldBalance = LootAnalyser.goldValue
	if LootAnalyser.forceUpdateBalance then
		local loot = 0
		for itemId, itemInfo in pairs(LootAnalyser.lootedItems) do
			local count = itemInfo.count
			local price = count * itemInfo.basePrice

			loot = loot + price
		end

		LootAnalyser.goldValue = loot
		LootAnalyser.forceUpdateBalance = false
	end

	if LootAnalyser.updateBalance or oldBalance ~= LootAnalyser.goldValue then
		LootAnalyser:updateWindow(false)
		LootAnalyser.updateBalance = false
	end
end

function LootAnalyser:updateWindow(updateScroll, ignoreVisible)
	if not LootAnalyser.window:isVisible() and not ignoreVisible then
		return
	end
	local contentsPanel = LootAnalyser.window.contentsPanel

	contentsPanel.gold:setText(formatMoney(LootAnalyser.goldValue, ","))
	contentsPanel.goldHour:setText(formatMoney(math.floor(LootAnalyser.goldHour), ","))
	contentsPanel.goldTarget:setText(formatMoney(LootAnalyser.target, ","))

	if LootAnalyser.target == 0 and LootAnalyser.goldHour == 0 then
		LootAnalyser.window.contentsPanel.lootTargetBG.lootArrow:setMarginLeft(targetMaxMargin / 2)
	else
		local target = math.max(1, LootAnalyser.target)
		local current = LootAnalyser.goldHour
		local percent = (current * 71) / target
		LootAnalyser.window.contentsPanel.lootTargetBG.lootArrow:setMarginLeft(math.min(targetMaxMargin, math.ceil(percent)))
	end

	LootAnalyser.window.contentsPanel.lootTargetBG:setTooltip(string.format("Current: %d\nTarget: %d", LootAnalyser.goldHour, LootAnalyser.target))

	if not updateScroll then
		return
	end

	local numOfItems = 0
	local numOfLines = 0
	if table.empty(LootAnalyser.lootedItems) and #contentsPanel.lootedItems:getChildren() then
		contentsPanel.lootedItems:destroyChildren()
	else
		for itemId, info in pairs(LootAnalyser.lootedItems) do
			local widget = contentsPanel.lootedItems:getChildById(itemId)
			if not widget then
				widget = g_ui.createWidget('LootItem', contentsPanel.lootedItems)
				widget:setId(itemId)
				widget:setItemId(itemId)
			end
			widget:setItemCount(info.count)
			widget:setTooltip(string.format("%s (Value: %dgp, Sum: %dgp)", string.capitalize(info.name), info.basePrice, info.basePrice * info.count))
			numOfItems = numOfItems + 1
			if numOfItems == 4 then
				numOfItems = 0
				numOfLines = numOfLines + 1
			end
		end
	end

	numOfLines = not table.empty(LootAnalyser.lootedItems) and numOfLines + 1 or 0
	contentsPanel.lootedItems:setHeight(35 * (numOfLines + ((numOfLines > 0 and numOfItems == 0) and -1 or 0)))
end

function LootAnalyser:updateGraphics()
	local uptime = math.floor((g_clock.millis() - LootAnalyser.launchTime)/1000)
	if uptime < 5*60 then
		LootAnalyser.goldHour = LootAnalyser.goldValue
	else
		LootAnalyser.goldHour = math.floor((LootAnalyser.goldValue/uptime)*3600)
	end

	-- Ensure graph exists before adding value
	if LootAnalyser.window.contentsPanel.graphPanel:getGraphsCount() == 0 then
		LootAnalyser.window.contentsPanel.graphPanel:createGraph()
		LootAnalyser.window.contentsPanel.graphPanel:setLineWidth(1, 1)
		LootAnalyser.window.contentsPanel.graphPanel:setLineColor(1, "#ffca38")
	end
	LootAnalyser.window.contentsPanel.graphPanel:addValue(1, LootAnalyser.goldHour)
end

function LootAnalyser:addLootedItems(item, name)
	local itemId = item:getId()
	local itemInfo = LootAnalyser.lootedItems[itemId]
	if not itemInfo then
		LootAnalyser.lootedItems[itemId] = {count = 0, name = name, basePrice = 0}
		itemInfo = LootAnalyser.lootedItems[itemId]
	end

	local count = item:getCount()
	itemInfo.basePrice = modules.game_cyclopedia.CyclopediaItems.getCurrentItemValue(item)
	itemInfo.count = itemInfo.count + count

	-- update balance
	LootAnalyser.goldValue = LootAnalyser.goldValue + (itemInfo.basePrice * count)
	LootAnalyser.updateBalance = true

	LootAnalyser:checkBalance()
	LootAnalyser:updateGraphics()
	LootAnalyser:updateWindow(true)
end

function LootAnalyser:setLootPerHourGauge(value)
	LootAnalyser.window.contentsPanel.targetLabel:setVisible(value)
	LootAnalyser.window.contentsPanel.goldLabelIcon:setVisible(value)
	LootAnalyser.window.contentsPanel.goldTarget:setVisible(value)
	LootAnalyser.window.contentsPanel.lootTargetBG:setVisible(value)
	LootAnalyser.window.contentsPanel.separatorGauge:setVisible(value)

	LootAnalyser.gaugeVisible = value

	if value then
		LootAnalyser.window.contentsPanel.lootGraphBG:addAnchor(AnchorTop, 'separatorGauge', AnchorBottom)
	else
		LootAnalyser.window.contentsPanel.lootGraphBG:addAnchor(AnchorTop, 'separatorLootedItems', AnchorBottom)
	end
end

function LootAnalyser:setLootPerHourGraph(value)
	LootAnalyser.window.contentsPanel.lootGraphBG:setVisible(value)
	LootAnalyser.window.contentsPanel.graphPanel:setVisible(value)
	LootAnalyser.window.contentsPanel.graphHorizontal:setVisible(value)

	LootAnalyser.graphVisible = value
end

function LootAnalyser:gaugeIsVisible()
	return LootAnalyser.gaugeVisible
end
function LootAnalyser:graphIsVisible()
	return LootAnalyser.graphVisible
end
function LootAnalyser:getTarget()
	return LootAnalyser.target
end
function LootAnalyser:setTarget(value)
	LootAnalyser.target = tonumber(value)
	LootAnalyser.window.contentsPanel.goldTarget:setText(formatMoney(LootAnalyser.target, ","))
end

function LootAnalyser:openTargetConfig()
	local window = configPopupWindow["lootButton"]
	window:show()
	window:setText('Set Loot Target')
	window.contentPanel.text:setImageSource('/images/game/analyzer/labels/loot')

	window.onEnter = function()
		local value = window.contentPanel.lootTarget:getText()
		LootAnalyser.target = tonumber(value)
		window:hide()
	end
	window.contentPanel.lootTarget:setText(tonumber(LootAnalyser.target) or '0')

	window.contentPanel.ok.onClick = function()
		local value = window.contentPanel.lootTarget:getText()
		LootAnalyser.target = tonumber(value)
		window:hide()
	end
	window.contentPanel.cancel.onClick = function()
		window:hide()
	end
end

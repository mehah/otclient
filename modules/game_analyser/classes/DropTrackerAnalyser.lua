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

if not DropTrackerAnalyser then
	DropTrackerAnalyser = {
		launchTime = 0,
		session = 0,

		trackedItems = {},

		autoTrackAboveValue = 0,

		-- private
		window = nil,
	}
	DropTrackerAnalyser.__index = DropTrackerAnalyser
end

function DropTrackerAnalyser:create()
	DropTrackerAnalyser.window = openedWindows['dropButton']
	
	if not DropTrackerAnalyser.window then
		return
	end

	-- Hide buttons we don't want
	local toggleFilterButton = DropTrackerAnalyser.window:recursiveGetChildById('toggleFilterButton')
	if toggleFilterButton then
		toggleFilterButton:setVisible(false)
	end
	
	local newWindowButton = DropTrackerAnalyser.window:recursiveGetChildById('newWindowButton')
	if newWindowButton then
		newWindowButton:setVisible(false)
	end

	-- Position contextMenuButton where toggleFilterButton was (to the left of minimize button)
	local contextMenuButton = DropTrackerAnalyser.window:recursiveGetChildById('contextMenuButton')
	local minimizeButton = DropTrackerAnalyser.window:recursiveGetChildById('minimizeButton')
	
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
			return onDropExtra(pos)
		end
	end

	-- Position lockButton to the left of contextMenuButton
	local lockButton = DropTrackerAnalyser.window:recursiveGetChildById('lockButton')
	
	if lockButton and contextMenuButton then
		lockButton:setVisible(true)
		lockButton:breakAnchors()
		lockButton:addAnchor(AnchorTop, contextMenuButton:getId(), AnchorTop)
		lockButton:addAnchor(AnchorRight, contextMenuButton:getId(), AnchorLeft)
		lockButton:setMarginRight(2)  -- Same margin as in miniwindow style
		lockButton:setMarginTop(0)
	end

	DropTrackerAnalyser.launchTime = g_clock.millis()
	DropTrackerAnalyser.session = 0
	DropTrackerAnalyser.autoTrackAboveValue = 0

	DropTrackerAnalyser.trackedItems = {}
end

function DropTrackerAnalyser:checkTracker()
	local needUpdate = false
	for itemId, config in pairs(DropTrackerAnalyser.trackedItems) do
		if not config.persistent and (os.time() - config.recordStartTimestamp > 120) then
			DropTrackerAnalyser.trackedItems[itemId] = nil
			needUpdate = true
		else
			-- check monstertracker
			for id, mInfo in ipairs(config.monsterDrop) do
				if (os.time() - mInfo.time) > 45 then
					needUpdate = true
				end
			end
		end
	end

	if needUpdate then
		DropTrackerAnalyser:updateWindow()
	end
end

function DropTrackerAnalyser:reset(resetAutoTrack)
	DropTrackerAnalyser.launchTime = g_clock.millis()
	DropTrackerAnalyser.session = 0
	if resetAutoTrack then
		DropTrackerAnalyser.autoTrackAboveValue = 0
	end

	for itemId, config in pairs(DropTrackerAnalyser.trackedItems) do
		if config.monsterDrop then
			config.monsterDrop = {}
		end
	end

	DropTrackerAnalyser:updateWindow()
end

function DropTrackerAnalyser:updateWindow(ignoreVisible)
	if not DropTrackerAnalyser.window:isVisible() and not ignoreVisible then
		return
	end

	local contentsPanel = DropTrackerAnalyser.window.contentsPanel
	-- lets loop through all the items and flag them for removal
	for _, widget in pairs(contentsPanel.dropItems:getChildren()) do
		widget.toBeRemoved = true
		for _, monsterWidget in pairs(widget.dropMonster:getChildren()) do
			monsterWidget.toBeRemoved = true
		end
	end

	for itemId, config in pairs(DropTrackerAnalyser.trackedItems) do
		local widget = contentsPanel.dropItems:getChildById("ItemPanel_" .. itemId)
		if not widget then
			-- unable to find the item, then it most likely is a
			-- new item being tracked, so lets create it
			widget = g_ui.createWidget('ItemPanel', contentsPanel.dropItems)
			widget:setId("ItemPanel_" .. itemId)
			widget.itemSlot:setItemId(itemId)
			widget.itemName:setText(string.capitalize(short_text(getItemServerName(itemId), 13)))
			widget.drops:setText(formatMoney(config.dropCount, ","))

			for _, monsterDrop in ipairs(config.monsterDrop) do
				local monsterWidget = g_ui.createWidget('MonsterPanel', widget.dropMonster)
				monsterWidget.monster:setOutfit(monsterDrop.outfit)
				monsterWidget.name:setText(string.capitalize(monsterDrop.monsterName))
				monsterWidget.drops:setText("(" ..formatMoney(monsterDrop.count, ",") .. ")")
				monsterDrop.widget = monsterWidget
			end

			widget:updateItemPanelSize()
		else
			-- if we found the item, and applied updates to it, must must
			-- check it to not be removed
			widget.drops:setText(formatMoney(config.dropCount, ","))
			widget.toBeRemoved = nil

			local toBeRemoved = {}
			for id, monsterDrop in ipairs(config.monsterDrop) do
				local monsterWidget = monsterDrop.widget
				if not monsterWidget then
					-- if there is no monsterWidget set, then we need to create it
					local monsterWidget = g_ui.createWidget('MonsterPanel', widget.dropMonster)
					monsterWidget.monster:setOutfit(monsterDrop.outfit)
					monsterWidget.name:setText(string.capitalize(monsterDrop.monsterName))
					monsterWidget.drops:setText("(" ..formatMoney(monsterDrop.count, ",") .. ")")
					-- we also save the reference for later on use
					monsterDrop.widget = monsterWidget
				else
					-- if the monsterWidget is already set, then we must check
					-- if it needs to be removed (time > 45s)
					if (os.time() - monsterDrop.time) > 45 then
						-- this is already being done in the
						-- initial part of this function
						-- monsterWidget.toBeRemoved = true

						-- but lets keep track of the ids to
						-- be removed later on (outside of this
						-- loop)
						table.insert(toBeRemoved, id)
					else
						monsterWidget.toBeRemoved = nil
					end
				end
			end

			if #toBeRemoved == 0 then
				-- dont need to do the update of the heights
				-- now, since it will be done later on during
				-- the widget removal
				widget:updateItemPanelSize()
			end

			-- there is no need to keep it on monsterDrop
			-- table if its removal was already scheduled
			-- and by keeping it, it would be re-added eventually
			for _, id in ipairs(toBeRemoved) do
				table.remove(config.monsterDrop, id)
			end
		end
	end

	for _, widget in pairs(contentsPanel.dropItems:getChildren()) do
		if widget.toBeRemoved then
			widget:destroy()
		end

		if widget.dropMonster then
			local destroyedAtLeastOne = false
			for _, monsterWidget in pairs(widget.dropMonster:getChildren()) do
				if monsterWidget.toBeRemoved then
					monsterWidget:destroy()
					destroyedAtLeastOne = true
				end
			end

			if destroyedAtLeastOne then
				widget:updateItemPanelSize()
			end
		end
	end
end

function DropTrackerAnalyser:managerDropItem(itemId, checked)
	if not checked then
		DropTrackerAnalyser.trackedItems[itemId] = nil
		DropTrackerAnalyser:updateWindow()
		return
	end

	if DropTrackerAnalyser.trackedItems[itemId] then
		DropTrackerAnalyser.trackedItems[itemId] = nil
	else
		DropTrackerAnalyser.trackedItems[itemId] = {monsterDrop = {}, recordStartTimestamp = os.time(), dropCount = 0, persistent = true}
	end
	DropTrackerAnalyser:updateWindow()
end

function DropTrackerAnalyser:sendDropedItems(msg, textMessageConsole)
    modules.game_textmessage.messagesPanel.statusLabel:setVisible(true)
    modules.game_textmessage.messagesPanel.statusLabel:setColoredText(msg)
    scheduleEvent(function()
      modules.game_textmessage.messagesPanel.statusLabel:setVisible(false)
    end, 3000)

    local tabName = (modules.game_console.getTabByName("Loot") and "Loot" or "Server Log")
    modules.game_console.addText(textMessageConsole, MessageModes.ChannelManagement, tabName)
end

function DropTrackerAnalyser:tryAddingMonsterDrop(item, monsterName, monsterOutfit, dropItems, dropedItems)
	local itemId = item:getId()
	local tracker = DropTrackerAnalyser.trackedItems[itemId]
	local itemPrice = item:getPriceValue() and item:getPriceValue() or 0
	if not tracker and DropTrackerAnalyser.autoTrackAboveValue == 0 then
		return
	elseif DropTrackerAnalyser.autoTrackAboveValue > 0 and DropTrackerAnalyser.autoTrackAboveValue <= itemPrice then
		tracker = DropTrackerAnalyser.trackedItems[itemId]
		if not tracker then
			DropTrackerAnalyser.trackedItems[itemId] = {monsterDrop = {}, recordStartTimestamp = os.time(), dropCount = 0, persistent = false}
			tracker = DropTrackerAnalyser.trackedItems[itemId]
		end
	elseif not tracker then
		return
	end

	dropedItems[#dropedItems + 1] = itemId
	tracker.dropCount = tracker.dropCount + item:getCount()
	tracker.recordStartTimestamp = os.time()
	tracker.monsterDrop[#tracker.monsterDrop + 1] = {monsterName = monsterName, outfit = monsterOutfit, time = os.time(), count = item:getCount()}
end

function DropTrackerAnalyser:checkMonsterKilled(monsterName, monsterOutfit, dropItems)
	if table.empty(DropTrackerAnalyser.trackedItems) and DropTrackerAnalyser.autoTrackAboveValue == 0 then
		return true
	end

	DropTrackerAnalyser.autoTrackAboveValue = tonumber(DropTrackerAnalyser.autoTrackAboveValue) or 1

	local dropedItems = {}
	for _, item in pairs(dropItems) do
		DropTrackerAnalyser:tryAddingMonsterDrop(item, monsterName, monsterOutfit, dropItems, dropedItems)
	end

	if #dropedItems ~= 0 then
		local textMessage = {}
		local textMessageConsole = {}
		local first = true
		setStringColor(textMessage, "Valuable loot:", "#f0b400")
		setStringColor(textMessageConsole, " Valuable loot:", "#f0b400")
		for _, itemId in pairs(dropedItems) do
			local name = getItemServerName(itemId)
			if not first then
				setStringColor(textMessage, ",", getItemColor(itemId))
				setStringColor(textMessageConsole, ",", getItemColor(itemId))
			else
				first = false
			end
			setStringColor(textMessage, " "..name, getItemColor(itemId))
			setStringColor(textMessageConsole, " "..name, getItemColor(itemId))
		end

		setStringColor(textMessage, " dropped by "..monsterName.."!", "#f0b400")
		setStringColor(textMessageConsole, " dropped by "..monsterName.."!", "#f0b400")
		DropTrackerAnalyser:sendDropedItems(textMessage, textMessageConsole)
	end

	DropTrackerAnalyser:updateWindow()
end

function DropTrackerAnalyser:isInDropTracker(itemId)
	local tracker = DropTrackerAnalyser.trackedItems[itemId]
	return tracker and tracker.persistent
end

function onDropTrackerExtra(mousePosition)
	local window = configPopupWindow["dropButton"]
	window:show()
	window:setText('Drop Tracker Configuration')
	window.contentPanel.text:setImageSource('/images/game/analyzer/labels/loot-track')

	window.onEnter = function()
		local value = window.contentPanel.target:getText()
		DropTrackerAnalyser.autoTrackAboveValue = tonumber(value)
		window:hide()
	end
	window.contentPanel.target:setText(tonumber(DropTrackerAnalyser.autoTrackAboveValue) or '0')

	window.contentPanel.ok.onClick = function()
		local value = window.contentPanel.target:getText()
		DropTrackerAnalyser.autoTrackAboveValue = tonumber(value)
		window:hide()
	end
	window.contentPanel.cancel.onClick = function()
		window:hide()
	end
end


function DropTrackerAnalyser:loadConfigJson()
	local config = {
		autoTrackAboveValue = 0,
		trackedItems = {},
	}

	if not g_game.isOnline() then return end
	
	local player = g_game.getLocalPlayer()
	if not player then return end

	local file = "/characterdata/" .. player:getId() .. "/itemtracking.json"
	if g_resources.fileExists(file) then
		local status, result = pcall(function()
			return json.decode(g_resources.readFileContents(file))
		end)

		if not status then
			return g_logger.error("Error while reading characterdata file. Details: " .. result)
		end

		config = result
	end

	-- set droped
  table.clear(DropTrackerAnalyser.trackedItems)
	for _, i in pairs(config.trackedItems) do
		DropTrackerAnalyser.trackedItems[i.objectType] = {monsterDrop = {}, recordStartTimestamp = i.recordStartTimestamp, dropCount = i.dropCount, persistent = true}
	end

	DropTrackerAnalyser.autoTrackAboveValue = config.autoTrackAboveValue
	DropTrackerAnalyser:updateWindow()
end

function DropTrackerAnalyser:saveConfigJson()
	local config = {
		autoTrackAboveValue = DropTrackerAnalyser.autoTrackAboveValue,
		trackedItems = {},
	}

	for itemId, insta in pairs(DropTrackerAnalyser.trackedItems) do
		if insta.persistent then
			config.trackedItems[#config.trackedItems + 1] = {
				dropCount = insta.dropCount,
				objectType = itemId,
				recordStartTimestamp = insta.recordStartTimestamp,
			}
		end
	end

	if not g_game.isOnline() then return end
	
	local player = g_game.getLocalPlayer()
	if not player then return end

	-- Ensure the characterdata directory exists
	local characterDir = "/characterdata/" .. player:getId()
	pcall(function() g_resources.makeDir("/characterdata") end)
	pcall(function() g_resources.makeDir(characterDir) end)

	local file = "/characterdata/" .. player:getId() .. "/itemtracking.json"
	local status, result = pcall(function() return json.encode(config, 2) end)
	if not status then
		return g_logger.error("Error while saving profile DropTracker data. Data won't be saved. Details: " .. result)
	end

	if result:len() > 100 * 1024 * 1024 then
		return g_logger.error("Something went wrong, file is above 100MB, won't be saved")
	end

	-- Safely attempt to write the file, ignoring errors during logout
	local writeStatus, writeError = pcall(function()
		return g_resources.writeFileContents(file, result)
	end)
	
	if not writeStatus then
		-- Log the error but don't spam the console during normal logout
		g_logger.debug("Could not save DropTrackerAnalyser config during logout: " .. tostring(writeError))
	end
end


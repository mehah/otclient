-- Add capitalize function to string library if it doesn't exist
if not string.capitalize then
    function string.capitalize(str)
        if not str or str == "" or str == nil then
            return "Unknown"
        end
        return str:gsub("(%l)(%w*)", function(first, rest)
            return first:upper() .. rest
        end)
    end
end

-- Function to truncate text to a maximum length
local function short_text(text, maxLength)
    if not text or text == "" or text == nil then
        return "Unknown"
    end
    if string.len(text) > maxLength then
        return text:sub(1, maxLength - 3) .. "..."
    end
    return text
end

if not BossCooldown then
	BossCooldown = {
		launchTime = 0,
		lastTick = 0,

		sort = 0,
		search = '',

		cooldown = {},
		widgets = {},

		-- private
		window = nil,
	}
	BossCooldown.__index = BossCooldown
end

local widgets = {}

function BossCooldown.create()
	BossCooldown.launchTime = 0

	BossCooldown.sort = 0
	BossCooldown.lastTick = 0
	BossCooldown.search = ''

	BossCooldown.cooldown = {}
	BossCooldown.widgets = {}

	BossCooldown.window = openedWindows['bossButton']
	
	if not BossCooldown.window then
		return
	end

	-- Hide buttons we don't want
	local toggleFilterButton = BossCooldown.window:recursiveGetChildById('toggleFilterButton')
	if toggleFilterButton then
		toggleFilterButton:setVisible(false)
	end
	
	local newWindowButton = BossCooldown.window:recursiveGetChildById('newWindowButton')
	if newWindowButton then
		newWindowButton:setVisible(false)
	end

	-- Position contextMenuButton where toggleFilterButton was (to the left of minimize button)
	local contextMenuButton = BossCooldown.window:recursiveGetChildById('contextMenuButton')
	local minimizeButton = BossCooldown.window:recursiveGetChildById('minimizeButton')
	
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
			return onBossExtra(pos)
		end
	end

	-- Position lockButton to the left of contextMenuButton
	local lockButton = BossCooldown.window:recursiveGetChildById('lockButton')
	
	if lockButton and contextMenuButton then
		lockButton:setVisible(true)
		lockButton:breakAnchors()
		lockButton:addAnchor(AnchorTop, contextMenuButton:getId(), AnchorTop)
		lockButton:addAnchor(AnchorRight, contextMenuButton:getId(), AnchorLeft)
		lockButton:setMarginRight(2)  -- Same margin as in miniwindow style
		lockButton:setMarginTop(0)
	end

	local cl = openedWindows['bossButton']:recursiveGetChildById('clickablePanel')
	if cl then
		cl.onMouseWheel = scrollUIPanel
	end
end

function BossCooldown:reset()
	BossCooldown.launchTime = g_clock.millis()

	BossCooldown.sort = 0
	BossCooldown.lastTick = 0
	BossCooldown.search = ''
	BossCooldown.cooldown = {}

	BossCooldown.widgets = {}

	BossCooldown:updateWindow()
end

function BossCooldown:checkTicks()
	if self.lastTick - os.time() > 0 then
		return
	end

	self.lastTick = os.time() + 1

	local layout = self.window.contentsPanel.bosses:getLayout()
	local needUpdate = false
	for _, widget in ipairs(self.widgets) do
		layout:enableUpdates()
		if self.search == '' or string.find(widget.name:lower(), self.search:lower()) then
			widget:setVisible(true)
		else
			widget:setVisible(false)
		end
		layout:disableUpdates()

		widget.tick = widget.tick - 1
		widget.cooldown = os.time() + widget.tick
		if widget.cooldown < os.time() then
			widget.cooldown = os.time() + 60*365*60*24
		end

		local bossCooldownLabel = widget:recursiveGetChildById('bossNCooldown')
		if bossCooldownLabel then
			if widget.tick <= 0 then
				bossCooldownLabel:setText('No Cooldown')
				bossCooldownLabel:setColor('#c0c0c0')
				if widget.type ~= 'nocd' then
					needUpdate = true
					widget.cooldown = os.time() + 60*365*60*24
				end
				widget.type = 'nocd'
			elseif widget.tick <= 60 then
				bossCooldownLabel:setText(widget.tick ..'s')
				bossCooldownLabel:setColor('#ff9854')
				if widget.type ~= 'second' then
					needUpdate = true
				end
				widget.type = 'second'
			else
				local duration = math.max(1, widget.tick)
				local days = math.floor(duration / 86400)
				local hours = math.floor((duration % 86400) / 3600)
				local minutes = math.floor((duration % 3600) / 60)
				if days > 0 then
					bossCooldownLabel:setText(string.format("%dd %02dh %02dmin", days, hours, minutes))
				else
					bossCooldownLabel:setText(string.format("%02dh %02dmin", hours, minutes))
				end
				bossCooldownLabel:setColor('#ff9854')
				if widget.type ~= 'timed' then
					needUpdate = true
				end
				widget.type = 'timed'
			end
		end
	end
	layout:enableUpdates()
	if needUpdate then
		if self.sort == 0 then
			table.sort(self.widgets, function(a, b)
				return a.cooldown < b.cooldown
			end)
		else
			table.sort(self.widgets, function(a, b)
				return a.name < b.name
			end)
		end

		self.window.contentsPanel.bosses:reorderChildren(self.widgets)
	end
end

function BossCooldown:updateWindow()
	local contentsPanel = BossCooldown.window.contentsPanel

	BossCooldown.widgets = {}
	contentsPanel.bosses:destroyChildren()
	if BossCooldown.sort == 0 then
		table.sort(BossCooldown.cooldown, function(a, b)
			local acd = a.cooldown
			if acd < os.time() then
				acd = os.time() + 60*365*60*24
			end
			local bcd = b.cooldown
			if bcd < os.time() then
				bcd = os.time() + 60*365*60*24
			end
			return acd < bcd
		end)
	else
		table.sort(BossCooldown.cooldown, function(a, b)
			return a.name < b.name
		end)
	end

	contentsPanel.searchText:setText('', false)

	local c = 1
	for _, info in ipairs(BossCooldown.cooldown) do
		-- Debug: Log boss information with more detail
		print("Creating boss widget for:")
		print("  - name:", info.name or "nil")
		print("  - bossId:", info.bossId or "nil") 
		print("  - cooldown:", info.cooldown or "nil")
		print("  - outfit:", info.outfit and "present" or "missing")
		
		local widget = g_ui.createWidget('BossInfo', contentsPanel.bosses)
		
		-- Get child elements properly
		local creatureWidget = widget:recursiveGetChildById('creature')
		local bossNameLabel = widget:recursiveGetChildById('bossName')
		local bossCooldownLabel = widget:recursiveGetChildById('bossNCooldown')
		
		-- Debug: Check if child widgets were found
		print("Child widgets found - creature:", creatureWidget and "yes" or "no", 
		      "bossName:", bossNameLabel and "yes" or "no", 
		      "bossCooldown:", bossCooldownLabel and "yes" or "no")
		
		-- Handle outfit data
		if creatureWidget then
			if info.outfit then
				creatureWidget:setOutfit(info.outfit)
			else
				-- Fallback outfit if no outfit data is provided
				local fallbackOutfit = {
					type = 130, -- Default human outfit
					head = 0,
					body = 0,
					legs = 0,
					feet = 0,
					addons = 0
				}
				creatureWidget:setOutfit(fallbackOutfit)
			end
		end
		
		-- Set boss name
		if bossNameLabel then
			local bossName = info.name
			
			-- If name is empty or nil, use fallback
			if not bossName or bossName == "" or bossName:trim() == "" then
				bossName = "Boss " .. (info.bossId or "Unknown")
			end
			
			local displayName = short_text(string.capitalize(bossName), 13)
			print("Setting boss name to:", displayName)
			bossNameLabel:setText(displayName)
			widget:setTooltip(string.capitalize(bossName))
		else
			widget:setTooltip("Unknown Boss")
		end
		widget.onClick = function()
			-- Open the cyclopedia at the Bosstiary tab
			if modules.game_cyclopedia then
				modules.game_cyclopedia.show("bosstiary")
			end
		end

		local resttime = math.max(0, info.cooldown - os.time())
		if bossCooldownLabel then
			if resttime <= 0 then
				bossCooldownLabel:setText('No Cooldown')
				bossCooldownLabel:setColor('#c0c0c0')
				widget.type = 'nocd'
			elseif resttime <= 60 then
				bossCooldownLabel:setText(resttime ..'s')
				bossCooldownLabel:setColor('#ff9854')
				widget.type = 'second'
			else
				local duration = math.max(1, resttime)
				local days = math.floor(duration / 86400)
				local hours = math.floor((duration % 86400) / 3600)
				local minutes = math.floor((duration % 3600) / 60)
				if days > 0 then
					bossCooldownLabel:setText(string.format("%dd %02dh %02dmin", days, hours, minutes))
				else
					bossCooldownLabel:setText(string.format("%02dh %02dmin", hours, minutes))
				end
				bossCooldownLabel:setColor('#ff9854')
				widget.type = 'timed'
			end
		end

		-- TODO: Implement tracker cooldown functionality when game_trackers module is available
		-- modules.game_trackers.BossTracker.checkTrackerCooldown(info.name, info.cooldown)

		widget.tick = resttime
		widget.name = info.name
		widget.bossId = info.bossId
		c = c + 1
		BossCooldown.widgets[#BossCooldown.widgets + 1] = widget
	end

	contentsPanel.bosses:setHeight(40 + (35 * c))
end

function BossCooldown:setupCooldown(cooldown)
	BossCooldown.cooldown = {}
	print("BossCooldown:setupCooldown called with", #cooldown, "entries")
	
	for i, cooldown in pairs(cooldown) do
		print("Processing cooldown entry", i, ":")
		print("  [1] bossId:", cooldown[1])
		print("  [2] cooldown:", cooldown[2])
		print("  [3] name:", cooldown[3])
		print("  [4] outfit:", cooldown[4] and type(cooldown[4]) or "nil")
		
		-- Get race data from g_things using the boss race ID
		local raceData = g_things.getRaceData(cooldown[1])
		
		local bossEntry = {
			bossId = cooldown[1], 
			cooldown = cooldown[2], 
			name = raceData and raceData.name or "", 
			outfit = raceData and raceData.outfit or nil
		}
		
		print("Race data found for ID", cooldown[1], ":")
		print("  - name:", bossEntry.name)
		print("  - outfit:", bossEntry.outfit and "present" or "missing")
		
		BossCooldown.cooldown[#BossCooldown.cooldown + 1] = bossEntry
	end

	BossCooldown.widgets = {}
	BossCooldown:updateWindow()
end

function checkBossSearch(text)
	if #text <= 1 then
		BossCooldown.search = ''
	else
		BossCooldown.search = text
	end
end
function clearSearch()
	BossCooldown.search = ''
	BossCooldown.window.contentsPanel.searchText:setText('', false)
end

function onBossExtra(mousePosition)
	if cancelNextRelease then
		cancelNextRelease = false
		return false
	end

	local player = g_game.getLocalPlayer()
	if not player then return false end

	local sortByCooldown = BossCooldown.sort == 0
	local sortByName = BossCooldown.sort == 1

	local menu = g_ui.createWidget('PopupMenu')
	menu:setGameMenu(true)
	menu:addCheckBox(tr('sort by cooldown'), sortByCooldown, function()
		BossCooldown.sort = 0
		BossCooldown:updateWindow()
	end)
	menu:addCheckBox(tr('sort by name'), sortByName, function()
		BossCooldown.sort = 1
		BossCooldown:updateWindow()
	end)

	menu:display(mousePosition)
	return true
end

function toggleBossCDFocus(visible)
	local widget = BossCooldown.window:recursiveGetChildById('clickablePanel')
	if widget and visible then
		widget:setPhantom(true)
	elseif widget then
		widget:setPhantom(false)
		widget.onClick = function() 
			-- m_interface.toggleInternalFocus() -- Function doesn't exist, commenting out
			toggleBossCDFocus(not visible) 
		end
	end
	-- m_interface.toggleFocus(visible, "bosscooldown") -- Function doesn't exist, commenting out
	if visible then
		BossCooldown.window:setBorderWidth(2)
		BossCooldown.window:setBorderColor('white')
		local text = BossCooldown.window.contentsPanel.searchText
		text:focus()
	else
		BossCooldown.window:setBorderWidth(0)
	end
end

function updateBossFocus()
	scheduleEvent(function() BossCooldown.window:recursiveGetChildById('miniwindowScrollBar'):setValue(1) end, 1)
end

function BossCooldown:hasCooldown(raceId)
	for _, info in ipairs(BossCooldown.cooldown) do
		if info.bossId == raceId then
			return info.name, info.cooldown
		end
	end
	return "", -1
end

function BossCooldown:getCooldown(raceId)
	for _, widget in pairs(BossCooldown.widgets) do
		if widget.bossId and widget.bossId == raceId and widget.cooldown and widget.cooldown > os.time() then
			local bossCooldownLabel = widget:recursiveGetChildById('bossNCooldown')
			if bossCooldownLabel then
				return bossCooldownLabel:getText()
			end
		end
	end

	return ""
end

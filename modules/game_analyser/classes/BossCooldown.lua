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

		if widget.tick <= 0 then
			widget.bossNCooldown:setText('No Cooldown')
			widget.bossNCooldown:setColor('$var-text-cip-color')
			if widget.type ~= 'nocd' then
				needUpdate = true
				widget.cooldown = os.time() + 60*365*60*24
			end
			widget.type = 'nocd'
		elseif widget.tick <= 60 then
			widget.bossNCooldown:setText(widget.tick ..'s')
			widget.bossNCooldown:setColor('$var-text-cip-color-orange')
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
				widget.bossNCooldown:setText(string.format("%dd %02dh %02dmin", days, hours, minutes))
			else
				widget.bossNCooldown:setText(string.format("%02dh %02dmin", hours, minutes))
			end
			widget.bossNCooldown:setColor('$var-text-cip-color-orange')
			if widget.type ~= 'timed' then
				needUpdate = true
			end
			widget.type = 'timed'
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
		local widget = g_ui.createWidget('BossInfo', contentsPanel.bosses)
		widget.creature:setOutfit(info.outfit)
		widget.bossName:setText(short_text(string.capitalize(info.name), 13))
		widget:setTooltip(string.capitalize(info.name))
		widget.onClick = function()
			modules.game_cyclopedia.Bosstiary.onSideButtonRedirect(info.name)
		end

		local resttime = math.max(0, info.cooldown - os.time())
		if resttime <= 0 then
			widget.bossNCooldown:setText('No Cooldown')
			widget.bossNCooldown:setColor('$var-text-cip-color')
			widget.type = 'nocd'
		elseif resttime <= 60 then
			widget.bossNCooldown:setText(resttime ..'s')
			widget.bossNCooldown:setColor('$var-text-cip-color-orange')
			widget.type = 'second'
		else
			local duration = math.max(1, resttime)
			local days = math.floor(duration / 86400)
			local hours = math.floor((duration % 86400) / 3600)
			local minutes = math.floor((duration % 3600) / 60)
			if days > 0 then
				widget.bossNCooldown:setText(string.format("%dd %02dh %02dmin", days, hours, minutes))
			else
				widget.bossNCooldown:setText(string.format("%02dh %02dmin", hours, minutes))
			end
			widget.bossNCooldown:setColor('$var-text-cip-color-orange')
			widget.type = 'timed'
		end

		modules.game_trackers.BossTracker.checkTrackerCooldown(info.name, info.cooldown)

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
	for _, cooldown in pairs(cooldown) do
		BossCooldown.cooldown[#BossCooldown.cooldown + 1] = {bossId = cooldown[1], cooldown = cooldown[2], name = cooldown[3], outfit = cooldown[4]}
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

	local menu = g_ui.createWidget('PopupMenu')
	menu:setGameMenu(true)
	menu:addCheckBoxOption(tr('sort by cooldown'), function()
		BossCooldown.sort = 0
		BossCooldown:updateWindow()
	end, "", BossCooldown.sort == 0)
	menu:addCheckBoxOption(tr('sort by name'), function()
		BossCooldown.sort = 1
		BossCooldown:updateWindow()
	end, "", BossCooldown.sort == 1)

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
		text:recursiveFocus(2)
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
			return widget.bossNCooldown:getText()
		end
	end

	return ""
end

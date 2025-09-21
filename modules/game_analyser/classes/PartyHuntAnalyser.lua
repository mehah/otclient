
-- Missing utility functions
local function formatMoney(value, separator)
    return comma_value(tostring(value))
end

if not PartyHuntAnalyser then
	PartyHuntAnalyser = {
		launchTime = 0,
		session = 0,
		lootType = 0,
		leaderID = 0,

		--
		loot = 0,
		supplies = 0,
		balance = 0,

		membersData = {},
		membersName = {},

		-- private
		window = nil,
		event = nil,
		leader = false
	}
	PartyHuntAnalyser.__index = PartyHuntAnalyser
end

local packetSend = false

function PartyHuntAnalyser.create()
	PartyHuntAnalyser.launchTime = g_clock.millis()
	PartyHuntAnalyser.session = 0

	PartyHuntAnalyser.lootType = PriceTypeEnum.Market
	PartyHuntAnalyser.leaderID = 0
	PartyHuntAnalyser.leader = false

	--
	PartyHuntAnalyser.loot = 0
	PartyHuntAnalyser.supplies = 0
	PartyHuntAnalyser.balance = 0
	PartyHuntAnalyser.event = nil

	PartyHuntAnalyser.membersData = {}
	PartyHuntAnalyser.membersName = {}
	PartyHuntAnalyser.window = openedWindows['partyButton']
	
	if not PartyHuntAnalyser.window then
		return
	end

	-- Hide buttons we don't want
	local toggleFilterButton = PartyHuntAnalyser.window:recursiveGetChildById('toggleFilterButton')
	if toggleFilterButton then
		toggleFilterButton:setVisible(false)
	end
	
	local newWindowButton = PartyHuntAnalyser.window:recursiveGetChildById('newWindowButton')
	if newWindowButton then
		newWindowButton:setVisible(false)
	end

	-- Position contextMenuButton where toggleFilterButton was (to the left of minimize button)
	local contextMenuButton = PartyHuntAnalyser.window:recursiveGetChildById('contextMenuButton')
	local minimizeButton = PartyHuntAnalyser.window:recursiveGetChildById('minimizeButton')
	
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
			return onPartyExtra(pos)
		end
	end

	-- Position lockButton to the left of contextMenuButton
	local lockButton = PartyHuntAnalyser.window:recursiveGetChildById('lockButton')
	
	if lockButton and contextMenuButton then
		lockButton:setVisible(true)
		lockButton:breakAnchors()
		lockButton:addAnchor(AnchorTop, contextMenuButton:getId(), AnchorTop)
		lockButton:addAnchor(AnchorRight, contextMenuButton:getId(), AnchorLeft)
		lockButton:setMarginRight(2)  -- Same margin as in miniwindow style
		lockButton:setMarginTop(0)
	end
end

function PartyHuntAnalyser:startEvent()
	PartyHuntAnalyser.session = 0
	if PartyHuntAnalyser.event then PartyHuntAnalyser.event:cancel() end
end

function PartyHuntAnalyser:reset()
	PartyHuntAnalyser.launchTime = g_clock.millis()
	PartyHuntAnalyser.session = 0

	PartyHuntAnalyser.lootType = PriceTypeEnum.Market
	PartyHuntAnalyser.leaderID = 0
	PartyHuntAnalyser.leader = false

	--
	PartyHuntAnalyser.loot = 0
	PartyHuntAnalyser.supplies = 0
	PartyHuntAnalyser.balance = 0

	PartyHuntAnalyser.membersData = {}
	PartyHuntAnalyser.membersName = {}

	if PartyHuntAnalyser.event then PartyHuntAnalyser.event:cancel() end

	local contentsPanel = PartyHuntAnalyser.window:getChildById('contentsPanel')
	contentsPanel.party:destroyChildren()
	PartyHuntAnalyser:updateWindow(true, true)
end

function PartyHuntAnalyser:updateWindow(updateMembers, ignoreVisible)
	if not PartyHuntAnalyser.window:isVisible() and not ignoreVisible then
		return
	end
	local contentsPanel = PartyHuntAnalyser.window.contentsPanel

    contentsPanel.lootType:setText(PartyHuntAnalyser.lootType == PriceTypeEnum.Market and "Market" or "Leader")

	local duration = math.max(1, PartyHuntAnalyser.session )
	local hours = math.floor(duration / 3600)
	local minutes = math.floor((duration % 3600) / 60)
	contentsPanel.session:setText(string.format("%02d:%02dh", hours, minutes))

	if not updateMembers then
		return
	end

	local lootTotal = 0
	local supplyTotal = 0

	local c = 0
	for id, data in pairs(PartyHuntAnalyser.membersData) do
		local widget = contentsPanel.party:getChildById(id)
		if not widget then
			if id == PartyHuntAnalyser.leaderID then
				widget = g_ui.createWidget('LeaderInfo', contentsPanel.party)
			else
				widget = g_ui.createWidget('Info', contentsPanel.party)
			end
		end

		c = c + 1

		lootTotal = lootTotal + data[1]
		supplyTotal = supplyTotal + data[2]
		local playerBalance = data[1] - data[2]
		local playerName = PartyHuntAnalyser.membersName[id] or "Unknow"
		widget.name:setText(playerName)
		if not data[5] then
			widget.name:setColor("$var-cip-inactive-color")
		end
		widget.balance:setText(comma_value(playerBalance))
		widget.balance:setColor(playerBalance >= 0 and "$var-text-cip-color-green" or "$var-text-cip-color-orange")
		widget.damage:setText(comma_value(data[3]))
		widget.healing:setText(comma_value(data[4]))
		widget:setId(id)

		local tooltipMessage = {}
		setStringColor(tooltipMessage, tr("Loot: %s ", comma_value(data[1])), "#3f3f3f")
		setStringColor(tooltipMessage, "$\n", "yellow")
		setStringColor(tooltipMessage, tr("Supplies: %s ", comma_value(data[2])), "#3f3f3f")
		setStringColor(tooltipMessage, "$\n", "yellow")
		setStringColor(tooltipMessage, tr("Balance: %s ", comma_value(playerBalance)), "#3f3f3f")
		setStringColor(tooltipMessage, "$", "yellow")
		widget.balance:setTooltip(tooltipMessage)
	end

	contentsPanel.party:setHeight(40 + (c * 61))

	local balance = lootTotal - supplyTotal

	PartyHuntAnalyser.loot = lootTotal
	PartyHuntAnalyser.supplies = supplyTotal
	PartyHuntAnalyser.balance = balance

	contentsPanel.loot:setText(formatMoney(lootTotal, ","))
	contentsPanel.supplies:setText(formatMoney(supplyTotal, ","))
	contentsPanel.balance:setText(comma_value(balance))
	contentsPanel.balance:setColor(balance >= 0 and '#00EB00' or '#f36500')

end

function PartyHuntAnalyser:onPartyAnalyzer(startTime, leaderID, lootType, membersData, membersName)
	PartyHuntAnalyser.session = startTime
	PartyHuntAnalyser.leaderID = leaderID
	PartyHuntAnalyser.lootType = lootType
	PartyHuntAnalyser.membersData = membersData
	PartyHuntAnalyser.membersName = membersName

	if PartyHuntAnalyser.event then PartyHuntAnalyser.event:cancel() end
	PartyHuntAnalyser.event = cycleEvent(function()
		if not g_game.isOnline() then return end
		PartyHuntAnalyser.session = PartyHuntAnalyser.session + 1
		PartyHuntAnalyser:updateWindow(false)
	end, 1000)

	PartyHuntAnalyser:updateWindow(true)
	PartyHuntAnalyser.leader = g_game.getLocalPlayer():getId() == leaderID
end

function getLeaderLootType()
	return PartyHuntAnalyser.lootType
end

function isLeaderParty()
	local player = g_game.getLocalPlayer()
	return table.contains({ShieldYellow, ShieldYellowSharedExp, ShieldYellowNoSharedExpBlink}, player:getShield())
end

function onPartyHuntExtra(mousePosition)
	if cancelNextRelease then
		cancelNextRelease = false
		return false
	end

	local player = g_game.getLocalPlayer()
	if not player then return false end

	local menu = g_ui.createWidget('PopupMenu')
	menu:setGameMenu(true)

	if table.contains({ShieldYellow, ShieldYellowSharedExp, ShieldYellowNoSharedExpBlink}, player:getShield()) then
		local lootType = PartyHuntAnalyser.lootType == PriceTypeEnum.Market and "Leader" or "Market"
		menu:addOption(tr('Reset Data of Current Party Session'), function() g_game.sendPartyResetSession() return end)
		menu:addOption(tr('Use %s Prices', lootType), function()
			g_game.sendPartyLootType(PartyHuntAnalyser.lootType == PriceTypeEnum.Market and PriceTypeEnum.Leader or PriceTypeEnum.Market)
			if PartyHuntAnalyser.lootType == PriceTypeEnum.Market then
				modules.game_cyclopedia.CyclopediaItems.sendPartyLootItems()
			end
		return end)
		menu:addSeparator()
	elseif player:getShield() == ShieldNone then
		menu:addOption(tr('Reset Data of Last Session'), function() PartyHuntAnalyser:reset(); PartyHuntAnalyser:startEvent() return end)
	end

	menu:addOption(tr('Copy to Clipboard'), function() PartyHuntAnalyser:clipboardData() return end)
	menu:addOption(tr('Copy to LootSplitter'), function() PartyHuntAnalyser:lootSplitter() return end)

	menu:display(mousePosition)
  return true
end

function PartyHuntAnalyser:clipboardData()

	local duration = math.max(1, PartyHuntAnalyser.session )
	local hours = math.floor(duration / 3600)
	local minutes = math.floor((duration % 3600) / 60)

	local final = "Session data: From " .. os.date('%Y-%m-%d, %H:%M:%S', os.time() - PartyHuntAnalyser.session) .." to ".. os.date('%Y-%m-%d, %H:%M:%S') .. "\n"
	if PartyHuntAnalyser.session == 0 then
		final = ""
	end
	final = final .. "Session: " .. string.format("%02d:%02dh", hours, minutes)
	final = final .. "\nLoot Type: " .. (PartyHuntAnalyser.lootType ~= PriceTypeEnum.Market and "Leader" or "Market")
	final = final .. "\nLoot: " .. comma_value(PartyHuntAnalyser.loot)
	final = final .. "\nSupplies: " .. comma_value(PartyHuntAnalyser.supplies)
	final = final .. "\nBalance: " .. comma_value(PartyHuntAnalyser.balance)

	--user data now
	for id, data in pairs(PartyHuntAnalyser.membersData) do
		local playerName = PartyHuntAnalyser.membersName[id] or "Unknow"
		final = final.. "\n".. playerName .. (id == PartyHuntAnalyser.leaderID and ' (Leader)' or '')

		final = final.. "\n\tLoot: ".. comma_value(data[1])
		final = final.. "\n\tSupplies: "..comma_value(data[2])
		final = final.. "\n\tBalance: "..comma_value(data[1] - data[2])
		final = final.. "\n\tDamage: "..comma_value(data[3])
		final = final.. "\n\tHealing: "..comma_value(data[4])
	end

	g_window.setClipboardText(final)
end

function PartyHuntAnalyser:lootSplitter()

	local duration = math.max(1, PartyHuntAnalyser.session )
	local hours = math.floor(duration / 3600)
	local minutes = math.floor((duration % 3600) / 60)

	local final = "Session data: From " .. os.date('%Y-%m-%d, %H:%M:%S', os.time() - PartyHuntAnalyser.session) .." to ".. os.date('%Y-%m-%d, %H:%M:%S') .. "\n"
	if PartyHuntAnalyser.session == 0 then
		final = ""
	end
	final = final .. "Session: " .. string.format("%02d:%02dh", hours, minutes)
	final = final .. "\nLoot Type: " .. (PartyHuntAnalyser.lootType ~= PriceTypeEnum.Market and "Leader" or "Market")
	final = final .. "\nLoot: " .. comma_value(PartyHuntAnalyser.loot)
	final = final .. "\nSupplies: " .. comma_value(PartyHuntAnalyser.supplies)
	final = final .. "\nBalance: " .. comma_value(PartyHuntAnalyser.balance)

	--user data now
	for id, data in pairs(PartyHuntAnalyser.membersData) do
		local playerName = PartyHuntAnalyser.membersName[id] or "Unknow"
		final = final.. "\n".. playerName .. (id == PartyHuntAnalyser.leaderID and ' (Leader)' or '')

		final = final.. "\n\tLoot: ".. comma_value(data[1])
		final = final.. "\n\tSupplies: "..comma_value(data[2])
		final = final.. "\n\tBalance: "..comma_value(data[1] - data[2])
		final = final.. "\n\tDamage: "..comma_value(data[3])
		final = final.. "\n\tHealing: "..comma_value(data[4])
	end

	local huntLogContent = modules.game_lootsplitter.lootsplitter.contentPanel:getChildById('huntLogContent')
	huntLogContent:setText(final)
	modules.game_lootsplitter.onGenerateButtonClick()
	modules.game_lootsplitter.show(true)
end

function onShieldChange(creature, shieldId)
    if creature == g_game.getLocalPlayer() then
        if table.contains({ShieldYellow, ShieldYellowSharedExp, ShieldYellowNoSharedExpBlink}, shieldId) and not packetSend then
			PartyHuntAnalyser.leader = true
            packetSend = true
			g_game.doThing(false)
            g_game.sendPartyLootPrice({})
			g_game.doThing(true)
        elseif shieldId == 0 and packetSend then
			PartyHuntAnalyser.leader = false
            packetSend = false
            PartyHuntAnalyser.session = 0
            if PartyHuntAnalyser.event then PartyHuntAnalyser.event:cancel() end
        end
    end
end

function onPartyMembersChange(self, members)
	if #members == 0 then
		PartyHuntAnalyser:reset()

		local contentsPanel = PartyHuntAnalyser.window.contentsPanel
		if contentsPanel then
			contentsPanel.party:destroyChildren()
			contentsPanel.party:setHeight(61)
		end
	end
end

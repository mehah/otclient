
-- Missing utility functions
local function formatMoney(value, separator)
    return comma_value(tostring(value))
end

-- Helper function to append colored text to a string
local function setStringColor(textString, text, color)
    return textString .. "[color=" .. color .. "]" .. text .. "[/color]"
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
	PartyHuntAnalyser.session = os.time()

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
			return onPartyHuntExtra(pos)
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
	PartyHuntAnalyser.session = os.time()
	if PartyHuntAnalyser.event then PartyHuntAnalyser.event:cancel() end
end

function PartyHuntAnalyser:reset()
	PartyHuntAnalyser.launchTime = g_clock.millis()
	PartyHuntAnalyser.session = os.time()

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

	local session = PartyHuntAnalyser.session
	if session == 0 then
		contentsPanel.session:setText("00:00h")
	else
		local duration = math.max(1, os.time() - session)
		local hours = math.floor(duration / 3600)
		local minutes = math.floor((duration % 3600) / 60)
		contentsPanel.session:setText(string.format("%02d:%02dh", hours, minutes))
	end

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

		lootTotal = lootTotal + data[3]
		supplyTotal = supplyTotal + data[4]
		local playerBalance = data[3] - data[4]  -- loot - supplies
		local playerName = PartyHuntAnalyser.membersName[id] or "Unknown"
		
		-- Debug: Check name lookup
		if not PartyHuntAnalyser.membersName[id] then
			print("PartyHuntAnalyser: Looking up name for ID " .. tostring(id) .. " - not found")
			print("Available names in lookup table:")
			for nameId, name in pairs(PartyHuntAnalyser.membersName) do
				print("  ID " .. tostring(nameId) .. " (" .. type(nameId) .. ") = " .. tostring(name))
			end
		end
		
		widget.name:setText(playerName)
		if not data[5] then
			widget.name:setColor("#707070")
		end
		widget.balance:setText(comma_value(playerBalance))
		widget.balance:setColor(playerBalance >= 0 and "#44ad25" or "#ff9854")
		widget.damage:setText(comma_value(data[5]))
		widget.healing:setText(comma_value(data[6]))
		widget:setId(id)

		local tooltipMessage = ""
		tooltipMessage = setStringColor(tooltipMessage, tr("Loot: %s ", comma_value(data[3])), "#3f3f3f")
		tooltipMessage = setStringColor(tooltipMessage, "$\n", "yellow")
		tooltipMessage = setStringColor(tooltipMessage, tr("Supplies: %s ", comma_value(data[4])), "#3f3f3f")
		tooltipMessage = setStringColor(tooltipMessage, "$\n", "yellow")
		tooltipMessage = setStringColor(tooltipMessage, tr("Balance: %s ", comma_value(playerBalance)), "#3f3f3f")
		tooltipMessage = setStringColor(tooltipMessage, "$", "yellow")
		widget.balance.parseColoreDisplay = tooltipMessage
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
	-- Check if server is telling us party is disbanded (empty data)
	if not membersData or not next(membersData) or not membersName or #membersName == 0 then
		print("PartyHuntAnalyser: Server indicates party is disbanded - clearing data")
		PartyHuntAnalyser:reset()
		return
	end
	
	-- startTime appears to be the session duration in seconds, not actual start time
	-- So we calculate the actual session start time
	PartyHuntAnalyser.session = os.time() - startTime
	PartyHuntAnalyser.leaderID = leaderID
	PartyHuntAnalyser.lootType = lootType
	
	-- Debug: Let's see what we're getting
	print("PartyHuntAnalyser: Received data:")
	print("  membersData type: " .. type(membersData))
	print("  membersData:")
	for k, v in pairs(membersData) do
		print("    Key " .. tostring(k) .. " (" .. type(k) .. "):")
		if type(v) == "table" then
			for i, val in ipairs(v) do
				print("      [" .. i .. "] = " .. tostring(val))
			end
		else
			print("      Value: " .. tostring(v))
		end
	end
	
	print("  membersName type: " .. type(membersName))
	print("  membersName:")
	for k, v in pairs(membersName) do
		print("    Key " .. tostring(k) .. " (" .. type(k) .. "): " .. tostring(v))
	end
	
	-- If membersData keys are player IDs, use them directly
	-- If they are positions (1,2,3...), we need to map them to the actual player IDs
	-- Server data is authoritative, so we can safely replace our data with server data
	local newMembersData = membersData
	
	-- Convert membersName from array format to lookup table format
	local newMembersName = {}
	if membersName then
		for i, memberInfo in ipairs(membersName) do
			if type(memberInfo) == "table" then
				local memberId = memberInfo[1]  -- First element is the ID
				local memberName = memberInfo[2]  -- Second element is the name
				newMembersName[memberId] = memberName
				print("  Mapped ID " .. tostring(memberId) .. " to name '" .. tostring(memberName) .. "'")
			end
		end
	end
	
	-- If membersData uses position keys (1,2,3...) but membersName uses player IDs,
	-- we need to remap the membersData to use player IDs as keys
	if membersName and type(newMembersData) == "table" then
		local remappedData = {}
		local memberIndex = 1
		
		-- Try to match positions in membersData with IDs from membersName
		for i, memberInfo in ipairs(membersName) do
			if type(memberInfo) == "table" then
				local playerId = memberInfo[1]
				local memberData = newMembersData[memberIndex]
				if memberData then
					remappedData[playerId] = memberData
					print("  Remapped position " .. memberIndex .. " to player ID " .. tostring(playerId))
					memberIndex = memberIndex + 1
				end
			end
		end
		
		-- Only use remapped data if we successfully mapped something
		if next(remappedData) then
			newMembersData = remappedData
			print("  Successfully remapped membersData to use player IDs as keys")
		else
			print("  Failed to remap membersData, keeping original")
		end
	end
	
	-- Server data is authoritative - replace our data with server data
	-- This ensures that if a player left the party, they are removed from our tracking
	local serverMemberIds = {}
	for playerId, serverData in pairs(newMembersData) do
		serverMemberIds[playerId] = true
		PartyHuntAnalyser.membersData[playerId] = serverData
		if newMembersName[playerId] then
			PartyHuntAnalyser.membersName[playerId] = newMembersName[playerId]
		end
	end
	
	-- Remove any members we have locally but server doesn't (they left the party)
	local membersToRemove = {}
	for playerId, existingData in pairs(PartyHuntAnalyser.membersData) do
		if not serverMemberIds[playerId] then
			table.insert(membersToRemove, playerId)
		end
	end
	
	-- Remove members that are no longer in the party according to server
	for _, playerId in ipairs(membersToRemove) do
		local playerName = PartyHuntAnalyser.membersName[playerId] or "Unknown"
		print("PartyHuntAnalyser: Server indicates " .. playerName .. " left party - removing")
		
		PartyHuntAnalyser.membersData[playerId] = nil
		PartyHuntAnalyser.membersName[playerId] = nil
		
		-- Remove widget from UI
		local contentsPanel = PartyHuntAnalyser.window.contentsPanel
		if contentsPanel and contentsPanel.party then
			local widget = contentsPanel.party:getChildById(playerId)
			if widget then
				widget:destroy()
			end
		end
	end

	if PartyHuntAnalyser.event then PartyHuntAnalyser.event:cancel() end
	PartyHuntAnalyser.event = cycleEvent(function()
		if not g_game.isOnline() then return end
		-- Update the window to show current time
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

	local session = PartyHuntAnalyser.session
	local final = ""
	if session == 0 then
		final = "Session: 00:00h"
	else
		local duration = math.max(1, os.time() - session)
		local hours = math.floor(duration / 3600)
		local minutes = math.floor((duration % 3600) / 60)
		
		final = "Session data: From " .. os.date('%Y-%m-%d, %H:%M:%S', session) .." to ".. os.date('%Y-%m-%d, %H:%M:%S') .. "\n"
		final = final .. "Session: " .. string.format("%02d:%02dh", hours, minutes)
	end
	final = final .. "\nLoot Type: " .. (PartyHuntAnalyser.lootType ~= PriceTypeEnum.Market and "Leader" or "Market")
	final = final .. "\nLoot: " .. comma_value(PartyHuntAnalyser.loot)
	final = final .. "\nSupplies: " .. comma_value(PartyHuntAnalyser.supplies)
	final = final .. "\nBalance: " .. comma_value(PartyHuntAnalyser.balance)

	--user data now
	for id, data in pairs(PartyHuntAnalyser.membersData) do
		local playerName = PartyHuntAnalyser.membersName[id] or "Unknown"
		final = final.. "\n".. playerName .. (id == PartyHuntAnalyser.leaderID and ' (Leader)' or '')

		final = final.. "\n\tLoot: ".. comma_value(data[3])
		final = final.. "\n\tSupplies: "..comma_value(data[4])
		final = final.. "\n\tBalance: "..comma_value(data[3] - data[4])
		final = final.. "\n\tDamage: "..comma_value(data[5])
		final = final.. "\n\tHealing: "..comma_value(data[6])
	end

	g_window.setClipboardText(final)
end

function PartyHuntAnalyser:lootSplitter()

	local session = PartyHuntAnalyser.session
	local final = ""
	if session == 0 then
		final = "Session: 00:00h"
	else
		local duration = math.max(1, os.time() - session)
		local hours = math.floor(duration / 3600)
		local minutes = math.floor((duration % 3600) / 60)
		
		final = "Session data: From " .. os.date('%Y-%m-%d, %H:%M:%S', session) .." to ".. os.date('%Y-%m-%d, %H:%M:%S') .. "\n"
		final = final .. "Session: " .. string.format("%02d:%02dh", hours, minutes)
	end
	final = final .. "\nLoot Type: " .. (PartyHuntAnalyser.lootType ~= PriceTypeEnum.Market and "Leader" or "Market")
	final = final .. "\nLoot: " .. comma_value(PartyHuntAnalyser.loot)
	final = final .. "\nSupplies: " .. comma_value(PartyHuntAnalyser.supplies)
	final = final .. "\nBalance: " .. comma_value(PartyHuntAnalyser.balance)

	--user data now
	for id, data in pairs(PartyHuntAnalyser.membersData) do
		local playerName = PartyHuntAnalyser.membersName[id] or "Unknown"
		final = final.. "\n".. playerName .. (id == PartyHuntAnalyser.leaderID and ' (Leader)' or '')

		final = final.. "\n\tLoot: ".. comma_value(data[3])
		final = final.. "\n\tSupplies: "..comma_value(data[4])
		final = final.. "\n\tBalance: "..comma_value(data[3] - data[4])
		final = final.. "\n\tDamage: "..comma_value(data[5])
		final = final.. "\n\tHealing: "..comma_value(data[6])
	end

	local huntLogContent = modules.game_lootsplitter.lootsplitter.contentPanel:getChildById('huntLogContent')
	huntLogContent:setText(final)
	modules.game_lootsplitter.onGenerateButtonClick()
	modules.game_lootsplitter.show(true)
end

function onShieldChange(creature, shieldId)
    -- Handle local player becoming party leader or leaving party
    if creature == g_game.getLocalPlayer() then
        if table.contains({ShieldYellow, ShieldYellowSharedExp, ShieldYellowNoSharedExpBlink}, shieldId) and not packetSend then
			PartyHuntAnalyser.leader = true
            packetSend = true
            PartyHuntAnalyser:updateWindow(true)
        elseif shieldId == 0 and packetSend then
			-- Local player left party - clear all party data
			PartyHuntAnalyser.leader = false
            packetSend = false
            PartyHuntAnalyser.session = os.time()
            if PartyHuntAnalyser.event then PartyHuntAnalyser.event:cancel() end
            
            -- Clear all party members when local player leaves party
            print("[PartyTracker] Local player left party - clearing all party data")
            PartyHuntAnalyser:reset()
            return
        end
    end
    
    -- Only add new party members when they become visible, never remove based on visibility
    if creature:isPlayer() and creature ~= g_game.getLocalPlayer() then
        local oldShield = creature.lastKnownShield or ShieldNone
        creature.lastKnownShield = shieldId
        
        -- Check if this player just joined the party (became party member from non-party state)
        local wasPartyMember = (oldShield == ShieldYellow or oldShield == ShieldYellowSharedExp or 
                               oldShield == ShieldYellowNoSharedExpBlink or oldShield == ShieldYellowNoSharedExp or 
                               oldShield == ShieldBlue or oldShield == ShieldBlueSharedExp or 
                               oldShield == ShieldBlueNoSharedExpBlink or oldShield == ShieldBlueNoSharedExp)
        
        local isPartyMember = (shieldId == ShieldYellow or shieldId == ShieldYellowSharedExp or 
                              shieldId == ShieldYellowNoSharedExpBlink or shieldId == ShieldYellowNoSharedExp or 
                              shieldId == ShieldBlue or shieldId == ShieldBlueSharedExp or 
                              shieldId == ShieldBlueNoSharedExpBlink or shieldId == ShieldBlueNoSharedExp)
        
        -- Only add new party members when they become visible with party shield
        if not wasPartyMember and isPartyMember then
            print("[PartyTracker] New party member detected: " .. creature:getName())
            
            -- Add this new party member to our tracking
            local memberId = creature:getId()
            if not PartyHuntAnalyser.membersData[memberId] then
                PartyHuntAnalyser.membersData[memberId] = {
                    0, -- memberID (not used in data array)
                    1, -- highlight (active)
                    0, -- loot
                    0, -- supplies
                    0, -- damage
                    0  -- healing
                }
                PartyHuntAnalyser.membersName[memberId] = creature:getName()
                print("PartyHuntAnalyser: Added new visible party member - " .. creature:getName() .. " (ID: " .. memberId .. ")")
                
                -- Update UI to show the new member
                PartyHuntAnalyser:updateWindow(true)
            end
        end
    end
end

function onPartyMembersChange(self, members)
	if #members == 0 then
		-- Party completely disbanded - reset everything
		print("[PartyTracker] Party disbanded - resetting all data")
		PartyHuntAnalyser:reset()

		local contentsPanel = PartyHuntAnalyser.window.contentsPanel
		if contentsPanel then
			contentsPanel.party:destroyChildren()
			contentsPanel.party:setHeight(61)
		end
	else
		-- Party exists - preserve all existing members and add any new ones
		local contentsPanel = PartyHuntAnalyser.window.contentsPanel
		if contentsPanel and contentsPanel.party then
			-- Get current member IDs from the provided members list
			local visibleMemberIds = {}
			for _, member in ipairs(members) do
				visibleMemberIds[member:getId()] = member
			end
			
			-- Add any new party members who aren't already tracked
			local newMembersAdded = false
			for _, member in ipairs(members) do
				local memberId = member:getId()
				if not PartyHuntAnalyser.membersData[memberId] then
					-- New member joined - add them with default values
					PartyHuntAnalyser.membersData[memberId] = {
						0, -- memberID (not used in data array)
						1, -- highlight (active)
						0, -- loot
						0, -- supplies
						0, -- damage
						0  -- healing
					}
					PartyHuntAnalyser.membersName[memberId] = member:getName()
					print("PartyHuntAnalyser: Added new party member - " .. member:getName() .. " (ID: " .. memberId .. ")")
					newMembersAdded = true
				else
					-- Update name in case it changed
					PartyHuntAnalyser.membersName[memberId] = member:getName()
				end
			end
			
			-- Update the window to show changes only if new members were added
			if newMembersAdded then
				PartyHuntAnalyser:updateWindow(true)
			end
			
			-- NOTE: We do NOT remove party members here when they're not visible
			-- Party members should persist even when they move far away
			-- Only the server data (onPartyAnalyzer) or explicit party disband should remove members
		end
	end
end

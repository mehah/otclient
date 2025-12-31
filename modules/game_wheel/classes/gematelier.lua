---------------------------
-- Lua code author: R1ck --
-- Company: VICTOR HUGO PERENHA - JOGOS ON LINE  --
---------------------------

GemAtelier = {}
GemAtelier.__index = GemAtelier

local lockedOnly = false

-- Helper function for price formatting
function formatPrice(price)
	if price >= 1000000 then
		local millions = price / 1000000
		if millions == math.floor(millions) then
			return string.format("%.0fM", millions)
		else
			return string.format("%.1fM", millions)
		end
	elseif price >= 1000 then
		local thousands = price / 1000
		if thousands == math.floor(thousands) then
			return string.format("%.0fK", thousands)
		else
			return string.format("%.1fK", thousands)
		end
	else
		return tostring(price)
	end
end

-- Helper function for comma formatting
function comma_value(amount)
	local formatted = tostring(amount)
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then
			break
		end
	end
	return formatted
end

-- Helper function for colored text
function setStringColor(table, text, color)
	if type(table) == "table" then
		table[#table + 1] = {text = text, color = color}
		return table
	else
		return text
	end
end

local sortQuality = 1
local sortAffinity = 1
local currentPage = 1

local destroyGemWindow = nil
local lastSelectedGem = nil
local lastSelectedVessel = nil
local currentGemList = {}
local totalGemList = {}
local currentSearchText = ""

local cachedBasicMods = {}
local cachedSupremeMods = {}

-- Wrapper functions for ActionId compatibility
function setActionId(widget, value)
	widget.gemID = value
end

function getActionId(widget)
	return widget.gemID
end

-- Add methods to widget objects
function addActionIdMethods(widget)
	if not widget.setActionId then
		widget.setActionId = function(self, value)
			self.gemID = value
		end
	end
	if not widget.getActionId then
		widget.getActionId = function(self)
			return self.gemID
		end
	end
end

function GemAtelier.resetFields()
	lockedOnly = false
	sortQuality = 1
	sortAffinity = 1
	destroyGemWindow = nil
	lastSelectedGem = nil
	currentGemList = {}
	currentSearchText = ""
	totalGemList = {}
	currentPage = 1
	gemAtelierWindow:recursiveGetChildById("filterPanel").searchText:clearText()
	gemAtelierWindow:recursiveGetChildById("affinitiesBox"):setCurrentIndex(1, true)
	gemAtelierWindow:recursiveGetChildById("qualitiesBox"):setCurrentIndex(1, true)
	gemAtelierWindow:recursiveGetChildById("lockedOnly"):setChecked(false, true)
	if lastSelectedVessel then
		lastSelectedVessel:setVisible(false)
		lastSelectedVessel = nil
	end

	cachedBasicMods = {}
	cachedSupremeMods = {}
	for _, data in pairs(Workshop.getFragmentList()) do
		if data.supreme then
			cachedSupremeMods[data.modID] = data
		else
			cachedBasicMods[data.modID] = data
		end
	end
end

function GemAtelier.redirectToGem(gemData)
	if not WheelOfDestiny or not gemAtelierWindow then
		return true
	end

	GemAtelier.resetFields()
	GemAtelier.setupVesselPanel()
	local gemList = gemAtelierWindow:recursiveGetChildById("gemContent")
	if not gemList then
		return true
	end

	gemList:destroyChildren()

	if gemData then
		local affinityWidget = gemAtelierWindow:recursiveGetChildById("affinitiesBox")
		local qualityWidget = gemAtelierWindow:recursiveGetChildById("qualitiesBox")
		affinityWidget:setCurrentIndex(gemData.gemDomain + 2, true)
		qualityWidget:setCurrentIndex(gemData.gemType + 2, true)
		sortQuality = gemData.gemType + 2
		sortAffinity = gemData.gemDomain + 2

		local highLight = gemAtelierWindow:recursiveGetChildById("selectVessel" .. gemData.gemDomain)
		highLight:setVisible(true)

		if lastSelectedVessel then
			lastSelectedVessel:setVisible(false)
		end

		lastSelectedVessel = highLight
	end

	totalGemList = {}
	currentGemList = {}

	local index = 1
	local foundIndex = 1

	for i, data in pairs(WheelOfDestiny.atelierGems) do
		if (sortQuality > 1 and data.gemType ~= sortQuality - 2) or (sortAffinity > 1 and data.gemDomain ~= sortAffinity - 2) then
		 	goto continue
	 	end

		if gemData.gemID == data.gemID then
			currentPage = math.ceil(index / 15)
			foundIndex = math.max(1, index - 15)
		end

		index = index + 1
		table.insert(totalGemList, data)
		:: continue ::
	end

	local gemCount = 0
	local beginList = (currentPage - 1) * 15 + 1
	local focusedGem = nil

	for i, data in pairs(totalGemList) do
		if gemCount == 15 then
			break
		end

		if i < beginList then
			goto continue
		end

		local widget = g_ui.createWidget('GemPanel', gemList)
		addActionIdMethods(widget)
		GemAtelier.setupGemWidget(widget, data)

		currentGemList[#currentGemList + 1] = data
		widget:setActionId(#currentGemList)
		gemCount = gemCount + 1

		if data.gemID == gemData.gemID then
			focusedGem = widget
		end

		:: continue ::
	end

	GemAtelier.showGemRevelation()
	GemAtelier.configurePages()

	gemList.onChildFocusChange = function(self, selected) GemAtelier.onSelectGem(selected, true) end
	gemList:focusChild(focusedGem, ActiveFocusReason, true)
end

function GemAtelier.showGems(selectFirst, lastIndex)
	if not WheelOfDestiny or not gemAtelierWindow then
		return true
	end

	GemAtelier.setupVesselPanel()
	local gemList = gemAtelierWindow:recursiveGetChildById("gemContent")
	if not gemList then
		return true
	end

	totalGemList = {}
	currentGemList = {}
	for i, data in pairs(WheelOfDestiny.atelierGems) do
		if (lockedOnly and not data.locked) or
		   (sortQuality > 1 and data.gemType ~= sortQuality - 2) or
		   (sortAffinity > 1 and data.gemDomain ~= sortAffinity - 2) or
		   (#currentSearchText > 0 and not GemAtelier.matchGemText(data)) then
			goto continue
		end

		table.insert(totalGemList, data)
		:: continue ::
	end

	gemList:destroyChildren()
	gemList.onChildFocusChange = function(self, selected) GemAtelier.onSelectGem(selected, true) end

	local gemCount = 0
	local beginList = (currentPage - 1) * 15 + 1

	for i, data in pairs(totalGemList) do
		if gemCount == 15 then
			break
		end

		if i < beginList then
			goto continue
		end

		local widget = g_ui.createWidget('GemPanel', gemList)
		addActionIdMethods(widget)
		GemAtelier.setupGemWidget(widget, data)

		currentGemList[#currentGemList + 1] = data
		widget:setActionId(#currentGemList)
		gemCount = gemCount + 1

		:: continue ::
	end

	GemAtelier.showGemRevelation()
	GemAtelier.configurePages()

	local panel = gemAtelierWindow:recursiveGetChildById("clickedPanel")
	local children = gemList:getChildren()

	if #children == 0 then
		panel.clickedContent:setVisible(false)
		panel.cleanContent:setVisible(true)
	else
		gemList:focusChild(nil)
		panel.cleanContent:setVisible(false)
		if selectFirst then
			gemList:focusChild(gemList:getFirstChild())
		elseif lastIndex then
			gemList:focusChild(children[lastIndex])
		elseif lastSelectedGem and lastSelectedGem:isVisible() and lastSelectedGem.getActionId then
			gemList:focusChild(children[lastSelectedGem:getActionId()])
		end
	end
end

function GemAtelier.matchGemText(data)
	local descriptions = {RegularGemDescription[data.lesserBonus].text, cachedBasicMods[data.lesserBonus].tooltip}

	if data.gemType > 0 then
		table.insert(descriptions, RegularGemDescription[data.regularBonus].text)
		table.insert(descriptions, cachedBasicMods[data.regularBonus].tooltip)
	end
	if data.gemType > 1 then
		table.insert(descriptions, SupremeGemDescription[data.supremeBonus].text)
		table.insert(descriptions, cachedSupremeMods[data.supremeBonus].tooltip)
	end

	for _, text in pairs(descriptions) do
		if matchText(currentSearchText, text) then
			return true
		end
	end
	return false
end

function GemAtelier.setupGemWidget(widget, data)
	local typeOffset = data.gemType * 32
	local domainOffet = data.gemDomain * 96
	local vocationOffset = (WheelOfDestiny.vocationId - 1) * 384
	local gemOffset = vocationOffset + domainOffet + typeOffset

	local tmpData = GemVocations[WheelOfDestiny.vocationId][data.gemType]
	if not tmpData then
		-- gem id not found
		return
	end


	widget.locker:setChecked(data.locked)
	widget.locker.onClick = GemAtelier.onLockGem
	widget.gemRevelationItem:setImageClip(gemOffset .. " 0 32 32")
	widget.gemRevelationItem:setTooltip(tmpData.name:gsub(" %(x 0%)", ""))

	if GemAtelier.isGemEquipped(data.gemID) then
		widget.gemDomainImage:setVisible(true)
		widget.gemDomainImage:setImageClip(data.gemDomain * 26 .. " 0 26 26")
	end

	local gemType = widget:recursiveGetChildById("modType" .. data.gemType)
	gemType:setVisible(true)

	GemAtelier.setupGemSlot(gemType.fragmentType0.gemMod0, data.lesserBonus, WheelOfDestiny.basicModsUpgrade, false, data, 0)
	GemAtelier.setGemUpgradeImage(gemType.fragmentType0, data.lesserBonus, WheelOfDestiny.basicModsUpgrade, nil)

	if data.gemType > 0 then
		GemAtelier.setupGemSlot(gemType.fragmentType1.gemMod1, data.regularBonus, WheelOfDestiny.basicModsUpgrade, false, data, 1)
		GemAtelier.setGemUpgradeImage(gemType.fragmentType1, data.regularBonus, WheelOfDestiny.basicModsUpgrade, WheelOfDestiny.basicModsUpgrade[data.lesserBonus] or 0, true)
	end

	if data.gemType > 1 then
		GemAtelier.setupGemSlot(gemType.fragmentType2.gemMod2, data.supremeBonus, WheelOfDestiny.supremeModsUpgrade, true, data, 2)
		local effectiveBonus = math.min(WheelOfDestiny.basicModsUpgrade[data.lesserBonus] or 0, WheelOfDestiny.basicModsUpgrade[data.regularBonus] or 0)
		GemAtelier.setGemUpgradeImage(gemType.fragmentType2, data.supremeBonus, WheelOfDestiny.supremeModsUpgrade, effectiveBonus)
	end
end

function GemAtelier.setupGemSlot(gemSlot, bonus, upgradeData, isSupreme, gemData, gemPosition)
	gemSlot:setImageClip(bonus * (isSupreme and 35 or 30) .. " 0 " .. (isSupreme and 35 or 30) .. " " .. (isSupreme and 35 or 30))
	GemAtelier.createGemInformation(gemSlot, bonus, isSupreme, true, gemData, gemPosition)
end

function GemAtelier.setGemUpgradeImage(gemFragment, bonus, upgradeData, prevBonus, debug)
	local upgradeLevel = upgradeData[bonus] or 0
	if prevBonus then
		if upgradeLevel > prevBonus then
			gemFragment.potential:setVisible(true)
			gemFragment.potential:setImageClip(upgradeLevel * 50 .. " 0 50 50")
			gemFragment:setImageClip(prevBonus * 50 .. " 0 50 50")
		else
			gemFragment:setImageClip(upgradeLevel * 50 .. " 0 50 50")
		end
	else
		gemFragment:setImageClip(upgradeLevel * 50 .. " 0 50 50")
	end
end

function GemAtelier.showGemRevelation()
	local data = GemVocations[WheelOfDestiny.vocationId]
	if not data then
		return true
	end

	local player = g_game:getLocalPlayer()
	local revelation = gemAtelierWindow.gemRevelation
	local totalBalance = (player:getResourceBalance(ResourceTypes.BANK_BALANCE) or 0) + (player:getResourceBalance(ResourceTypes.GOLD_EQUIPPED) or 0)
	local resources = {
		[0] = player:getResourceBalance(ResourceTypes.LESSER_GEMS) or 0, -- Lesser gem fragments
		[1] = player:getResourceBalance(ResourceTypes.REGULAR_GEMS) or 0, -- Regular gem fragments  
		[2] = player:getResourceBalance(ResourceTypes.GREATER_GEMS) or 0  -- Greater gem fragments
	}

	for i = 0, 2 do
		local itemWidget = revelation:recursiveGetChildById("gemRevelationItem" .. i)
		local gemInfo = revelation:recursiveGetChildById("gemInfo" .. i)
		local revealCost = revelation:recursiveGetChildById("gemRevealCost" .. i)
		local button = revelation:recursiveGetChildById("revealButton" .. i)

		-- Gem data
		itemWidget:setItemId(data[i].id)
		gemInfo:setText(data[i].name:gsub("%d", resources[i]))
		-- isTextWraped not available in this client, using fixed margin
		gemInfo:setMarginTop(50)

		-- Gem prices
		local gemString = {}
		local textColor = totalBalance >= GemRevealPrice[i] and "#c0c0c0" or "#d33c3c"
		local priceText = formatPrice(GemRevealPrice[i])
		
		if setStringColor and comma_value then
			setStringColor(gemString, priceText, textColor)
		else
			gemString = priceText
		end
		
		if revealCost and revealCost.gold then
			if type(gemString) == "table" and gemString[1] then
				revealCost.gold:setText(gemString[1].text)
			else
				revealCost.gold:setText(gemString)
			end
		end

		-- Gem buttons
		local toolTip = ""
		button:setOn(true)
		button:setTooltip("")
		if totalBalance < GemRevealPrice[i] then
			toolTip = tr(GemStaticTooltips[0], comma_value(GemRevealPrice[i]))
		end

		if resources[i] < 1 then
			toolTip = tr("%s" .. GemStaticTooltips[1], (#toolTip > 0 and toolTip .. "\n" or ""), comma_value(GemRevealPrice[i]))
		end

		if WheelOfDestiny.changeState ~= 1 then
			toolTip = tr("%s%s", (#toolTip > 0 and toolTip .. "\n" or ""), GemStaticTooltips[2])
		end

		if #WheelOfDestiny.atelierGems >= 225 then
			toolTip = tr("%s%s", (#toolTip > 0 and toolTip .. "\n" or ""), GemStaticTooltips[3])
		end

		if #toolTip > 0 then
			button:setTooltip(toolTip)
			button:setOn(false)
		end
	end
end

function GemAtelier.configurePages()
	if not gemAtelierWindow then
		return true
	end

	local panel = gemAtelierWindow:recursiveGetChildById("filterPanel")
	local totalCount = #totalGemList
	local maxPage = math.max(1, math.ceil(totalCount / 15))
	panel.pagesPanel.pagesLabel:setText(tr('Page %s / %s (%s Gems)', currentPage, maxPage, totalCount))

	if currentPage == 1 and maxPage == 1  then
		panel.pagesPanel.leftArrow:setOn(false)
		panel.pagesPanel.rightArrow:setOn(false)
	end

	if currentPage == 1 and maxPage > 1 then
		panel.pagesPanel.leftArrow:setOn(false)
		panel.pagesPanel.rightArrow:setOn(true)
	end

	if currentPage > 1 and currentPage < maxPage then
		panel.pagesPanel.leftArrow:setOn(true)
		panel.pagesPanel.rightArrow:setOn(true)
	end

	if currentPage > 1 and currentPage == maxPage then
		panel.pagesPanel.leftArrow:setOn(true)
		panel.pagesPanel.rightArrow:setOn(false)
	end
end

function GemAtelier.managePage(button, foward)
	if not button:isOn() then
		return true
	end

	local totalCount = #WheelOfDestiny.atelierGems
	local maxPage = math.max(1, math.ceil(totalCount / 15))

	if foward then
		currentPage = math.min(currentPage + 1, math.ceil(maxPage))
	else
		currentPage = math.max(1, currentPage - 1)
	end
	GemAtelier.showGems(true)
end

function shortenAfterCooldown(text)
    local cooldownIndex = text:find("Cooldown")
    if cooldownIndex then
        local afterCooldownIndex = cooldownIndex + #"Cooldown" - 1
        if text:sub(afterCooldownIndex + 1):match("%S") then
            return text:sub(1, afterCooldownIndex) .. "…"
        else
            return text
        end
    else
        return text
    end
end

function GemAtelier.getEffectiveLevel(gemData, currentBonusID, supreme, gemSlot)
	local basicUpgrade = WheelOfDestiny.basicModsUpgrade
	local supremeUpgrade = WheelOfDestiny.supremeModsUpgrade
	local upgradeTier = supreme and (supremeUpgrade[currentBonusID] or 0) or (basicUpgrade[currentBonusID] or 0)

	if gemSlot == 0 then
		return upgradeTier
	elseif gemSlot == 1 then
		local lesserUpgradeTier = basicUpgrade[gemData.lesserBonus] or 0
		return math.min(upgradeTier, lesserUpgradeTier)
	elseif gemSlot == 2 then
		local lesserUpgradeTier = basicUpgrade[gemData.lesserBonus] or 0
		local regularUpgradeTier = basicUpgrade[gemData.regularBonus] or 0
		local effectiveTier = math.min(lesserUpgradeTier, regularUpgradeTier)
		return math.min(upgradeTier, effectiveTier)
	end
end

function GemAtelier.createGemInformation(widget, gemTypeID, supremeMod, tooltip, gemData, gemSlot)
	local search = nil
	if supremeMod then
		search = cachedSupremeMods[gemTypeID]
	else
		search = cachedBasicMods[gemTypeID]
	end

	if not search then
		return true
	end

	local function shortenAfterCooldown(text)
		local cooldownIndex = text:find("Cooldown")
		if cooldownIndex then
			local afterCooldownIndex = cooldownIndex + #"Cooldown" - 1
			if text:sub(afterCooldownIndex + 1):match("%S") then
				return text:sub(1, afterCooldownIndex) .. "...", true
			else
				return text, false
			end
		else
			return text, false
		end
	end

	local shorted = false
	local currentTier = GemAtelier.getEffectiveLevel(gemData, gemTypeID, supremeMod, gemSlot)
	local text = Workshop.getBonusDescription(search, currentTier)
	if tooltip then
		widget:setTooltip(text)
	else
		local originalText = text
		text, shorted = shortenAfterCooldown(text)
		widget:setTooltip(shorted and originalText or "")
		widget:setText(text)
	end
end

function GemAtelier.onSelectGem(selected, clicked)
	if not selected then
		return true
	end

	if #currentGemList == 0 then
		return true
	end

	if lastSelectedGem then
		lastSelectedGem:setBorderWidth(0)
		lastSelectedGem:setBorderColor('alpha')
	end

	lastSelectedGem = selected
	lastSelectedGem:setBorderWidth(2)
	lastSelectedGem:setBorderColor('white')

	local panel = gemAtelierWindow:recursiveGetChildById("clickedPanel")
	if panel.cleanContent:isVisible() then
		panel.cleanContent:setVisible(false)
	end

	panel.clickedContent:setVisible(true)
	local gemData = currentGemList[lastSelectedGem:getActionId()]
	local typeOffset = gemData.gemType * 64
	local domainOffet = gemData.gemDomain * 192
	local vocationOffset = (WheelOfDestiny.vocationId - 1) * 64
	local gemOffset = domainOffet + typeOffset

	-- try fix empty gemData
	local gemText = GemVocations[WheelOfDestiny.vocationId][gemData.gemType].name
	panel.clickedContent.gemDetails.gemName:setText(string.gsub(gemText, " %(x 0%)", ""))
	panel.clickedContent.gemDetails.gemDetailItem:setImageClip(gemOffset .. " " .. vocationOffset .. " 64 64")

	panel.clickedContent.gemDetails.domain:setImageClip(gemData.gemDomain * 26 .. " 0 26 26")

	local widgetMods = panel.clickedContent.gemMods

	for i = 0, 2 do
		widgetMods:recursiveGetChildById("fragmentType" .. i):setVisible(false)
		widgetMods:recursiveGetChildById("gemModItem" .. i):setVisible(false)
		widgetMods:recursiveGetChildById("modLabel" .. i):setVisible(false)
	end

  widgetMods.fragmentType0.gemModItem0:setImageClip(gemData.lesserBonus * 30 .. " 0 30 30")
  GemAtelier.setupModAvailable(widgetMods, 0, 1, gemData)
  GemAtelier.createGemInformation(widgetMods.modLabel0, gemData.lesserBonus, false, false, gemData, 0)

	if gemData.gemType > 0 then
		widgetMods.fragmentType1.gemModItem1:setImageClip(gemData.regularBonus * 30 .. " 0 30 30")
		GemAtelier.setupModAvailable(widgetMods, 1, 2, gemData)
		GemAtelier.createGemInformation(widgetMods.modLabel1, gemData.regularBonus, false, false, gemData, 1)
  end

	if gemData.gemType > 1 then
		widgetMods.fragmentType2.gemModItem2:setImageClip(gemData.supremeBonus * 35 .. " 0 35 35")
		GemAtelier.setupModAvailable(widgetMods, 2, 3, gemData)
		GemAtelier.createGemInformation(widgetMods.modLabel2, gemData.supremeBonus, true, false, gemData, 2)
	end

	local player = g_game.getLocalPlayer()
	local totalBalance = (player:getResourceBalance(ResourceTypes.BANK_BALANCE) or 0) + (player:getResourceBalance(ResourceTypes.GOLD_EQUIPPED) or 0)
	local gemCount = GemAtelier.getGemCountByDomain(gemData.gemDomain)
	local goldMessage = {}

	local switchPrice = GemSwitchPrice[gemData.gemType]
	local priceText = formatPrice(switchPrice)
	local textColor = totalBalance < switchPrice and "#d33c3c" or "#c0c0c0"
	
	-- Set price text with color
	panel.clickedContent.switchCost.gold:setText(priceText)
	panel.clickedContent.switchCost.gold:setColor(textColor)
	
	-- Set tooltip with full price
	panel.clickedContent.switchCost:setTooltip(comma_value(switchPrice))

	if GemAtelier.isGemEquipped(gemData.gemID) then
		panel.clickedContent.placeVessel:setVisible(false)
		panel.clickedContent.removeVessel:setVisible(true)
	else
		panel.clickedContent.placeVessel:setVisible(true)
		panel.clickedContent.removeVessel:setVisible(false)
	end

	local swtichTip = ""
	local destroyTip = ""
	panel.clickedContent.switch:setOn(WheelOfDestiny.changeState == 1)
	panel.clickedContent.destroy:setOn(WheelOfDestiny.changeState == 1)

	if gemCount < 2 then
		swtichTip = tr("%s%sYou cannot switch the last gem of the domain.", swtichTip, (#swtichTip > 0 and "\n" or ""))
		destroyTip = tr("%s%sYou cannot destroy the last gem of the domain.", destroyTip, (#destroyTip > 0 and "\n" or ""))
	end

	if totalBalance < GemSwitchPrice[gemData.gemType] then
		local switchPrice = comma_value and comma_value(GemSwitchPrice[gemData.gemType]) or tostring(GemSwitchPrice[gemData.gemType])
		swtichTip = tr("%s%sYou need at least %s gold to change the domain of this gem.", swtichTip, (#swtichTip > 0 and "\n" or ""), switchPrice)
	end

	-- TEMPORARILY DISABLED - lock check
	--[[
	if gemData.locked then
		swtichTip = tr("%s%sBefore you can change the domain of this gem, you must unlock it.", swtichTip, (#swtichTip > 0 and "\n" or ""))
		destroyTip = tr("%s%sBefore you can destroy the gem, you must unlock it.", destroyTip, (#destroyTip > 0 and "\n" or ""))
	end
	--]]

	if GemAtelier.isGemEquipped(gemData.gemID) then
		swtichTip = tr("%s%sYou must remove the gem from its vessel before you can switch its domain.", swtichTip, (#swtichTip > 0 and "\n" or ""))
		destroyTip = tr("%s%sThe gem must be removed from its vessel before it can be destroyed.", destroyTip, (#destroyTip > 0 and "\n" or ""))
	end

	panel.clickedContent.switch:setTooltip(swtichTip)
	panel.clickedContent.destroy:setTooltip(destroyTip)
	if #swtichTip > 0 then
		panel.clickedContent.switch:setOn(false)
	end

	if #destroyTip > 0 then
		panel.clickedContent.destroy:setOn(false)
	end
end

function GemAtelier.isVesselAvailable(domain, count)
	local vesselFilled = 0
	local domainIndex = VesselIndex[domain]
	if not domainIndex then
		return false
	end

	for _, index in pairs(domainIndex) do
		local bonus = WheelBonus[index]
		local currentPoints = WheelOfDestiny.pointInvested[index + 1]
		if currentPoints >= bonus.maxPoints then
			vesselFilled = vesselFilled + 1
		end
	end
	return vesselFilled >= count
end

function GemAtelier.getFilledVesselCount(domain)
	local vesselFilled = 0
	local domainIndex = VesselIndex[domain]
	for _, index in pairs(domainIndex) do
		local bonus = WheelBonus[index]
		local currentPoints = WheelOfDestiny.pointInvested[index + 1]
		if bonus and currentPoints and currentPoints >= bonus.maxPoints then
			vesselFilled = vesselFilled + 1
		end
	end
	return vesselFilled
end

function GemAtelier.setupModAvailable(widget, gemType, vesselCount, gemData)
	if not widget then
		return true
	end

	local gemDomain = gemData.gemDomain
	local fragmentType = widget:recursiveGetChildById("fragmentType" .. gemType)
	local modItem = widget:recursiveGetChildById("gemModItem" .. gemType)
	local modLabel = widget:recursiveGetChildById("modLabel" .. gemType)
	local potentialLevel = fragmentType:recursiveGetChildById("potential")

	fragmentType:setVisible(true)
	modItem:setVisible(true)
	modLabel:setVisible(true)

	if GemAtelier.isVesselAvailable(gemDomain, vesselCount) then
		-- Clear shader if method exists
		if fragmentType.setImageShader then
			fragmentType:setImageShader("")
		end
		if modItem.setImageShader then
			modItem:setImageShader("")
		end
		modLabel:setColor("#dfdfdf")
	else
		-- Apply grayscale shader if method exists
		if fragmentType.setImageShader then
			fragmentType:setImageShader("image_black_white")
		end
		if modItem.setImageShader then
			modItem:setImageShader("image_black_white")
		end
		modLabel:setColor("#808080")
	end

	potentialLevel:setVisible(false)
	local gemBonusID = (gemType == 0 and gemData.lesserBonus or gemType == 1 and gemData.regularBonus or gemType == 2 and gemData.supremeBonus)
	local upgradeTier = WheelOfDestiny.basicModsUpgrade[gemBonusID] or 0
	if vesselCount == 3 then
		upgradeTier= WheelOfDestiny.supremeModsUpgrade[gemBonusID] or 0
	end

	if gemType == 0 then
		fragmentType:setImageClip(upgradeTier * 50 .. " 0 50 50")
		fragmentType.currentTier = upgradeTier
	elseif gemType == 1 then
		local lesserUpgradeTier = WheelOfDestiny.basicModsUpgrade[gemData.lesserBonus] or 0
		if upgradeTier > lesserUpgradeTier then
			fragmentType:setImageClip(lesserUpgradeTier * 50 .. " 0 50 50")
			potentialLevel:setVisible(true)
			potentialLevel:setImageClip(upgradeTier * 50 .. " 0 50 50")
			fragmentType.currentTier = lesserUpgradeTier
		else
			fragmentType:setImageClip(upgradeTier * 50 .. " 0 50 50")
			fragmentType.currentTier = upgradeTier
		end
	elseif gemType == 2 then
		local lesserUpgradeTier = WheelOfDestiny.basicModsUpgrade[gemData.lesserBonus] or 0
		local regularUpgradeTier = WheelOfDestiny.basicModsUpgrade[gemData.regularBonus] or 0
		local effectiveTier = math.min(lesserUpgradeTier, regularUpgradeTier)

		if upgradeTier > effectiveTier then
			fragmentType:setImageClip(effectiveTier * 50 .. " 0 50 50")
			potentialLevel:setVisible(true)
			potentialLevel:setImageClip(upgradeTier * 50 .. " 0 50 50")
			fragmentType.currentTier = effectiveTier
		else
			fragmentType:setImageClip(upgradeTier * 50 .. " 0 50 50")
			fragmentType.currentTier = upgradeTier
		end
	end

	fragmentType.modID = gemBonusID
	fragmentType.isSupreme = vesselCount == 3
end

function GemAtelier.manageVessel(remove)
    if not lastSelectedGem or type(lastSelectedGem.getActionId) ~= "function" then
        return true
    end

    local gemData = currentGemList[lastSelectedGem:getActionId()]
    local equipedList = {}

    for _, id in pairs(WheelOfDestiny.equipedGems) do
        local domain = GemAtelier.getGemDomainById(id)
        if domain ~= gemData.gemDomain then
            table.insert(equipedList, id)
        end
    end

	if not remove then
		table.insert(equipedList, gemData.gemID)
	end

	WheelOfDestiny.equipedGems = equipedList
	GemAtelier.showGems(false, lastSelectedGem:getActionId())
end

function GemAtelier.isGemEquipped(gemID)
	for _, id in pairs(WheelOfDestiny.equipedGems) do
		if id == gemID then
			return true
		end
	end
	return false
end

function GemAtelier.getGemDomainById(id)
	for _, data in pairs(WheelOfDestiny.atelierGems) do
		if data.gemID == id then
			return data.gemDomain
		end
	end
	return -1
end

function GemAtelier.getGemCountByDomain(domain)
	local count = 0
	for _, data in pairs(WheelOfDestiny.atelierGems) do
		if data.gemDomain == domain then
			count = count + 1
		end
	end
	return count
end

function GemAtelier.getGemDataById(id)
	for _, data in pairs(WheelOfDestiny.atelierGems) do
		if data.gemID == id then
			return data
		end
	end
	return nil
end

function GemAtelier.getEquipedGem(domain)
  for _, data in pairs(WheelOfDestiny.atelierGems) do
		if data.gemDomain == domain and GemAtelier.isGemEquipped(data.gemID) then
			return data
		end
	end
	return nil
end

function GemAtelier.onRevealGem(button, gemType)
	if not button:isOn() then
		return true
	end
	g_game.sendGemAtelierAction(1, gemType)
end

function GemAtelier.onSwitchDomain(button)
	if not button:isOn() or not lastSelectedGem then
		return true
	end
	g_game.sendGemAtelierAction(2, 0, currentGemList[lastSelectedGem:getActionId()].gemID)
end

function GemAtelier.onDestroyGem(button)
	if not button or not button:isOn() or not lastSelectedGem or destroyGemWindow ~= nil then
		return true
	end

	wheelWindow:hide()
    -- g_client.setInputLockWidget(nil) -- TEMPORARILY DISABLED
	local yesFunction = function() g_game.sendGemAtelierAction(0, 0, currentGemList[lastSelectedGem:getActionId()].gemID) wheelWindow:show(true) destroyGemWindow:destroy() destroyGemWindow = nil end -- g_client.setInputLockWidget(wheelWindow) end
	local noFunction = function() wheelWindow:show(true) destroyGemWindow:destroy() destroyGemWindow = nil end -- g_client.setInputLockWidget(wheelWindow) end
	destroyGemWindow = displayGeneralBox('Destroy Gem', "Are you sure you want to destroy this gem?",
		{ { text=tr('Yes'), callback=yesFunction }, { text=tr('No'), callback=noFunction }
	}, yesFunction, noFunction)
end

function GemAtelier.onLockGem(button)
	-- TEMPORARILY DISABLED
	return true
	--[[
	if not lastSelectedGem then
		return true
	end

	local currentWidget = button:getParent()
	if lastSelectedGem ~= currentWidget then
		GemAtelier.onSelectGem(currentWidget)
	end

	local checked = button:isChecked()
	local gemID = currentGemList[lastSelectedGem:getActionId()].gemID
	button:setChecked(not checked)
	g_game.sendGemAtelierAction(3, 0, gemID)
	--]]
end

function GemAtelier.showLockedOnly(button)
	if not gemAtelierWindow then
		return true
	end

	lockedOnly = button:isChecked()
	currentPage = 1
	GemAtelier.showGems()
	GemAtelier.configurePages()
	local gemList = gemAtelierWindow:recursiveGetChildById("gemContent")
	if not gemList then
		return true
	end

	if #gemList:getChildren() > 0 then
		GemAtelier.onSelectGem(gemList:getChildren()[1])
	end
end

function GemAtelier.onSortQuality(selected)
	if not gemAtelierWindow then
		return true
	end

	sortQuality = selected
	currentPage = 1
	GemAtelier.showGems()
	GemAtelier.configurePages()
	local gemList = gemAtelierWindow:recursiveGetChildById("gemContent")
	if not gemList then
		return true
	end

	if #gemList:getChildren() > 0 then
		GemAtelier.onSelectGem(gemList:getChildren()[1])
	end
end

function GemAtelier.onSortAffinity(selected)
	if not gemAtelierWindow then
		return true
	end

	sortAffinity = selected
	currentPage = 1
	GemAtelier.showGems()
	GemAtelier.configurePages()
	local gemList = gemAtelierWindow:recursiveGetChildById("gemContent")
	if not gemList then
		return true
	end

	if #gemList:getChildren() > 0 then
		GemAtelier.onSelectGem(gemList:getChildren()[1])
	end
end

function GemAtelier.onSearchChange(self)
	local text = self:getText()
	if #text == 0 then
		currentSearchText = ""
		GemAtelier.showGems(true)
		return true
	end
	currentSearchText = text
	GemAtelier.showGems(true)
end

function GemAtelier.setupVesselPanel()
	if not gemAtelierWindow then
		return true
	end

	local selectWidget = gemAtelierWindow:recursiveGetChildById("vesselsContent")
	
	-- Add ActionId methods to existing gemItem widgets
	for i = 0, 3 do
		local gemItem = selectWidget:recursiveGetChildById("gemItem" .. i)
		if gemItem then
			addActionIdMethods(gemItem)
		end
	end
	for i = 0, 3 do
		local background = selectWidget:recursiveGetChildById("vesselBg" .. i)
		local gemContainer = selectWidget:recursiveGetChildById("vessel" .. i)
		local gemItem = selectWidget:recursiveGetChildById("gemItem" .. i)

		background:setImageSource("/images/game/destiny_wheel/backdrop_skillwheel_socket_inactive")
		gemContainer:setVisible(false)
		gemItem:setImageClip("0 0 32 32")
		gemItem:setActionId(0)
		gemItem:setVisible(false)

		local filledCount = GemAtelier.getFilledVesselCount(i)
		if filledCount ~= 0 then
			local startPos = 442
			local domainOffset = startPos + (102 * i)
			local modOffset = 34 * math.max(0, filledCount - 1)
			gemContainer:setImageClip(domainOffset + modOffset .. " 0 34 34")
			gemContainer:setVisible(true)
			background:setImageSource("/images/game/destiny_wheel/backdrop_skillwheel_socket_active")
		end
	end

	for _, id in pairs(WheelOfDestiny.equipedGems) do
		local data = GemAtelier.getGemDataById(id)
		if data then
			local background = selectWidget:recursiveGetChildById("vesselBg" .. data.gemDomain)
			local gemContainer = selectWidget:recursiveGetChildById("vessel" .. data.gemDomain)
			local gemItem = selectWidget:recursiveGetChildById("gemItem" .. data.gemDomain)

			if GemAtelier.isVesselAvailable(data.gemDomain, 1) then
				background:setImageSource("/images/game/destiny_wheel/backdrop_skillwheel_socket_active")
				gemContainer:setVisible(true)
			end

			local typeOffset = data.gemType * 32
			local domainOffet = data.gemDomain * 96
			local vocationOffset = (WheelOfDestiny.vocationId - 1) * 384
			local gemOffset = vocationOffset + domainOffet + typeOffset

			gemItem:setImageClip(gemOffset .. " 0 32 32")
			gemItem:setActionId(data.gemID)
			gemItem:setVisible(true)

			local startPos = 442
			local filledCount = GemAtelier.getFilledVesselCount(data.gemDomain)
			if filledCount == (data.gemType + 1) then
				startPos = 34
			end

			local domainOffset = startPos + (102 * data.gemDomain)
			local modOffset = 34 * math.max(0, filledCount - 1)
			gemContainer:setImageClip(domainOffset + modOffset .. " 0 34 34")
		end
	end
end

function GemAtelier.onClickVessel(widget, domain)
	local highLight = gemAtelierWindow:recursiveGetChildById("selectVessel" .. domain)
	if highLight:isVisible() then
		return true
	end

	local selectedGem = gemAtelierWindow:recursiveGetChildById("gemItem" .. domain)
	local data = GemAtelier.getGemDataById(selectedGem:getActionId())

	if data then
		highLight:setVisible(true)
	end

	if lastSelectedVessel then
		lastSelectedVessel:setVisible(false)
	end

	lastSelectedVessel = highLight

	local affinityWidget = gemAtelierWindow:recursiveGetChildById("affinitiesBox")
	local qualityWidget = gemAtelierWindow:recursiveGetChildById("qualitiesBox")

	if data then
		GemAtelier.redirectToGem(data)
	else
		lockedOnly = false
		gemAtelierWindow:recursiveGetChildById("lockedOnly"):setChecked(false)
		gemAtelierWindow:recursiveGetChildById("filterPanel").searchText:clearText()
		affinityWidget:setCurrentIndex(domain + 2)
		qualityWidget:setCurrentIndex(1)
	end
end

function GemAtelier.onUnlockGem(gemID)
	-- TODO redirect to gemID
end

function GemAtelier.onModRedirect(self)
	local modID = self.modID
	local isSupreme = self.isSupreme
	local itemsPerPage = 30
	local pageIndex = nil
	local focusIndex = 0

	for i, k in pairs(Workshop.getFragmentList()) do
		if (isSupreme and k.supreme and k.modID == modID) or (not isSupreme and not k.supreme and k.modID == modID) then
			pageIndex = math.ceil(i / itemsPerPage)
			focusIndex = ((i - 1) % itemsPerPage) + 1
			break
		end
	end

	if not pageIndex then
		return true
	end

	Workshop.setCurrentPage(pageIndex)
	Workshop.showFragmentList(true, false, false, "", focusIndex)
	gemAtelierWindow:hide()
	fragmentWindow:show(true)
    gemMenuButton:setChecked(false)
    fragmentMenuButton:setChecked(true)
end

function GemAtelier.onHoverGem(self, hovered)
	local hoverWidget = self:recursiveGetChildById("hover")
	if not hoverWidget then
		return true
	end
	hoverWidget:setVisible(hovered)
	hoverWidget:setImageClip(self.currentTier and (200 + self.currentTier * 50 .. " 0 50 50") or "0 0 50 50")
	if hovered then
		g_mouse.pushCursor('pointer')
	else
		g_mouse.popCursor('pointer')
	end
end

function GemAtelier.getDamageAndHealing(self)
  local damage = 0
	for i = 0, 3 do
		local data = self.getEquipedGem(i)
		if data then
			local filledCount = self.getFilledVesselCount(i)
			if filledCount >= (data.gemType + 1) then
				damage = damage + (data.gemType == 2 and 2 or 1)
			end
		end
	end
  return damage
end

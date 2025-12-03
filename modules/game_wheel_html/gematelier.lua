local helper = dofile("helpers/helper.lua")
local Workshop = dofile("workshop.lua")
local GemAtelier = {}

function GemAtelier.getEffectiveLevel(gemData, currentBonusID, supreme, gemSlot)
    local basicUpgrade = WheelController.wheel.basicModsUpgrade
    local supremeUpgrade = WheelController.wheel.supremeModsUpgrade
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

function GemAtelier.isVesselAvailable(domain, count)
    local vesselFilled = 0
    local domainIndex = helper.gems.VesselIndex[domain]
    if not domainIndex then
        return false
    end

    for _, index in pairs(domainIndex) do
        local bonus = helper.bonus.WheelBonus[index]
        local currentPoints = WheelController.wheel.pointInvested[index + 1]
        if currentPoints >= bonus.maxPoints then
            vesselFilled = vesselFilled + 1
        end
    end
    return vesselFilled >= count
end

function GemAtelier.getFilledVesselCount(domain)
    local vesselFilled = 0
    local domainIndex = helper.gems.VesselIndex[domain]
    for _, index in pairs(domainIndex) do
        local bonus = helper.bonus.WheelBonus[index]
        local currentPoints = WheelController.wheel.pointInvested[index + 1]
        if bonus and currentPoints and currentPoints >= bonus.maxPoints then
            vesselFilled = vesselFilled + 1
        end
    end
    return vesselFilled
end

function GemAtelier.isGemEquipped(gemID)
    for _, id in pairs(WheelController.wheel.equipedGems) do
        if id == gemID then
            return true
        end
    end
    return false
end

function GemAtelier.getGemDomainById(id)
    for _, data in pairs(WheelController.wheel.atelierGems) do
        if data.gemID == id then
            return data.gemDomain
        end
    end
    return -1
end

function GemAtelier.getGemCountByDomain(domain)
    local count = 0
    for _, data in pairs(WheelController.wheel.atelierGems) do
        if data.gemDomain == domain then
            count = count + 1
        end
    end
    return count
end

function GemAtelier.getGemDataById(id)
    for _, data in pairs(WheelController.wheel.atelierGems) do
        if data.gemID == id then
            return data
        end
    end
    return nil
end

function GemAtelier.getEquipedGem(domain)
    for _, data in pairs(WheelController.wheel.atelierGems) do
        if data.gemDomain == domain and GemAtelier.isGemEquipped(data.gemID) then
            return data
        end
    end
    return nil
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

local totalGemList = {}
local currentGemList = {}
local cachedBasicMods = {}
local cachedSupremeMods = {}
function GemAtelier.resetFields()
    WheelController.gem.lockedOnly = false
    WheelController.gem.sortQuality = 1
    WheelController.gem.sortAffinity = 1
    WheelController.gem.destroyGemWindow = nil
    WheelController.gem.lastSelectedGem = nil
    WheelController.gem.currentGemList = {}
    WheelController.gem.currentSearchText = ""
    WheelController.gem.totalGemList = {}
    WheelController.gem.currentPage = 1
    WheelController.gem.searchText = ""
    WheelController.gem.searchText = ""
    WheelController.gem.lastSelectedVessel = nil
    WheelController.gem.data = {}

    -- gemAtelierWindow:recursiveGetChildById("filterPanel").searchText:clearText()
    -- gemAtelierWindow:recursiveGetChildById("affinitiesBox"):setCurrentIndex(1, true)
    -- gemAtelierWindow:recursiveGetChildById("qualitiesBox"):setCurrentIndex(1, true)
    -- gemAtelierWindow:recursiveGetChildById("lockedOnly"):setChecked(false, true)
    -- if lastSelectedVessel then
    -- 	lastSelectedVessel:setVisible(false)
    -- 	lastSelectedVessel = nil
    -- end

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

function GemAtelier.createGemInformation(gemTypeID, supremeMod, tooltip, gemData, gemSlot)
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
    print("181text>", text)
    -- local tooltip = nil
    if tooltip then
        return text, nil
    else
        local originalText = text
        text, shorted = shortenAfterCooldown(text)
        return text, shorted and originalText or ""
        -- widget:setTooltip(shorted and originalText or "")
        -- widget:setText(text)
    end
end

function GemAtelier.setupGemSlot(bonus, upgradeData, isSupreme, gemData, gemPosition)
    local clip = { x = bonus * (isSupreme and 35 or 30), y = 0, width = (isSupreme and 35 or 30), height = (isSupreme and 35 or 30) }
    -- gemSlot:setImageClip(clip.x .. " " .. clip.y .. " " .. clip.width .. " " .. clip.height)
    local text, tooltip = GemAtelier.createGemInformation(bonus, isSupreme, true, gemData, gemPosition)
    return clip, text, tooltip
end

function GemAtelier.setGemUpgradeImage(bonus, upgradeData, prevBonus, debug)
    local upgradeLevel = upgradeData[bonus] or 0
    local clip = { x = upgradeLevel * 50, y = 0, width = 50, height = 50 }
    if prevBonus then
        if upgradeLevel > prevBonus then
            -- gemFragment.potential:setVisible(true)
            -- gemFragment.potential:setImageClip(upgradeLevel * 50 .. " 0 50 50")
            local previousClip = { x = prevBonus * 50, y = 0, width = 50, height = 50 }
            -- gemFragment:setImageClip(prevBonus * 50 .. " 0 50 50")
            return clip, previousClip
        else
            return clip, nil
            -- gemFragment:setImageClip(upgradeLevel * 50 .. " 0 50 50")
        end
    else
        return clip, nil
        -- gemFragment:setImageClip(upgradeLevel * 50 .. " 0 50 50")
    end
end

function GemAtelier.setupGemWidget(data)
    local typeOffset = data.gemType * 32
    local domainOffet = data.gemDomain * 96
    local vocationOffset = (WheelController.wheel.vocationId - 1) * 384
    local gemOffset = vocationOffset + domainOffet + typeOffset

    local tmpData = helper.gems.GemVocations[WheelController.wheel.vocationId][data.gemType]
    if not tmpData then
        -- gem id not found
        return
    end

    local current = {
        locked = data.locked,
        gemClip = { x = gemOffset, y = 0, width = 32, height = 32 },
        tooltip = tmpData.name:gsub(" %(x 0%)", ""),
        isEquipped = GemAtelier.isGemEquipped(data.gemID),
        domainClip = nil,
        mods = {},
        lesserClip = nil,
        regularClip = nil,
        supremeClip = nil,
        text = nil,
        upgradeClip = nil,
        previousClip = nil,
    }

    -- widget.locker:setChecked(data.locked)
    -- widget.locker.onClick = GemAtelier.onLockGem
    -- widget.gemRevelationItem:setImageClip(gemOffset .. " 0 32 32")
    -- widget.gemRevelationItem:setTooltip(tmpData.name:gsub(" %(x 0%)", ""))

    if current.isEquipped then
        -- widget.gemDomainImage:setVisible(true)
        current.domainClip = { x = data.gemDomain * 26, y = 0, width = 26, height = 26 }
        print("current.domainClip", current.domainClip.x)
        -- widget.gemDomainImage:setImageClip(data.gemDomain * 26 .. " 0 26 26")
    end

    -- local gemType = widget:recursiveGetChildById("modType" .. data.gemType)
    -- gemType:setVisible(true)

    current.lesserClip, current.text, tooltip = GemAtelier.setupGemSlot(data.lesserBonus,
        WheelController.wheel.basicModsUpgrade,
        false, data, 0)
    current.upgradeClip, current.previousClip = GemAtelier.setGemUpgradeImage(data.lesserBonus,
        WheelController.wheel.basicModsUpgrade, nil)

    table.insert(current.mods, {
        clip = current.lesserClip,
        upgradeClip = current.upgradeClip,
        previousClip = current.previousClip
    })

    print("current.lesserClip", current.text)

    if data.gemType > 0 then
        current.regularClip, current.text, tooltip = GemAtelier.setupGemSlot(data.regularBonus,
            WheelController.wheel.basicModsUpgrade,
            false, data, 1)
        current.upgradeClip, current.previousClip = GemAtelier.setGemUpgradeImage(data.regularBonus,
            WheelController.wheel.basicModsUpgrade,
            WheelController.wheel.basicModsUpgrade[data.lesserBonus] or 0, true)
        print("current.regular", current.text)

        table.insert(current.mods, {
            clip = current.regularClip,
            upgradeClip = current.upgradeClip,
            previousClip = current.previousClip
        })
    end

    if data.gemType > 1 then
        current.supremeClip, current.text, tooltip = GemAtelier.setupGemSlot(data.supremeBonus,
            WheelController.wheel.supremeModsUpgrade, true, data, 2)
        local effectiveBonus = math.min(WheelController.wheel.basicModsUpgrade[data.lesserBonus] or 0,
            WheelController.wheel.basicModsUpgrade[data.regularBonus] or 0)
        current.upgradeClip, current.previousClip = GemAtelier.setGemUpgradeImage(data.supremeBonus,
            WheelController.wheel.supremeModsUpgrade,
            effectiveBonus)
        print("current.supreme", current.text)

        table.insert(current.mods, {
            clip = current.supremeClip,
            upgradeClip = current.upgradeClip,
            previousClip = current.previousClip
        })
    end

    return current
end

function GemAtelier.setupVesselPanel()
    -- if not gemAtelierWindow then
    -- 	return true
    -- end

    -- local selectWidget = gemAtelierWindow:recursiveGetChildById("vesselsContent")
    -- for i = 0, 3 do
    -- 	local background = selectWidget:recursiveGetChildById("vesselBg" .. i)
    -- 	local gemContainer = selectWidget:recursiveGetChildById("vessel" .. i)
    -- 	local gemItem = selectWidget:recursiveGetChildById("gemItem" .. i)

    -- 	background:setImageSource("/images/game/destiny_wheel/backdrop_skillwheel_socket_inactive")
    -- 	gemContainer:setVisible(false)
    -- 	gemItem:setImageClip("0 0 32 32")
    -- 	gemItem:setActionId(0)
    -- 	gemItem:setVisible(false)

    -- 	local filledCount = GemAtelier.getFilledVesselCount(i)
    -- 	if filledCount ~= 0 then
    -- 		local startPos = 442
    -- 		local domainOffset = startPos + (102 * i)
    -- 		local modOffset = 34 * math.max(0, filledCount - 1)
    -- 		gemContainer:setImageClip(domainOffset + modOffset .. " 0 34 34")
    -- 		gemContainer:setVisible(true)
    -- 		background:setImageSource("/images/game/destiny_wheel/backdrop_skillwheel_socket_active")
    -- 	end
    -- end

    -- for _, id in pairs(WheelOfDestiny.equipedGems) do
    -- 	local data = GemAtelier.getGemDataById(id)
    -- 	if data then
    -- 		local background = selectWidget:recursiveGetChildById("vesselBg" .. data.gemDomain)
    -- 		local gemContainer = selectWidget:recursiveGetChildById("vessel" .. data.gemDomain)
    -- 		local gemItem = selectWidget:recursiveGetChildById("gemItem" .. data.gemDomain)

    -- 		if GemAtelier.isVesselAvailable(data.gemDomain, 1) then
    -- 			background:setImageSource("/images/game/destiny_wheel/backdrop_skillwheel_socket_active")
    -- 			gemContainer:setVisible(true)
    -- 		end

    -- 		local typeOffset = data.gemType * 32
    -- 		local domainOffet = data.gemDomain * 96
    -- 		local vocationOffset = (WheelOfDestiny.vocationId - 1) * 384
    -- 		local gemOffset = vocationOffset + domainOffet + typeOffset

    -- 		gemItem:setImageClip(gemOffset .. " 0 32 32")
    -- 		gemItem:setActionId(data.gemID)
    -- 		gemItem:setVisible(true)

    -- 		local startPos = 442
    -- 		local filledCount = GemAtelier.getFilledVesselCount(data.gemDomain)
    -- 		if filledCount == (data.gemType + 1) then
    -- 			startPos = 34
    -- 		end

    -- 		local domainOffset = startPos + (102 * data.gemDomain)
    -- 		local modOffset = 34 * math.max(0, filledCount - 1)
    -- 		gemContainer:setImageClip(domainOffset + modOffset .. " 0 34 34")
    -- 	end
    -- end
end

function GemAtelier.showGemRevelation()
    local data = helper.gems.GemVocations[WheelController.wheel.vocationId]
    if not data then
        return true
    end

    local player = g_game:getLocalPlayer()
    local resources = {
        [0] = player:getResourceBalance(ResourceTypes.LESSER_GEMS),
        [1] = player:getResourceBalance(ResourceTypes.REGULAR_GEMS),
        [2] = player:getResourceBalance(ResourceTypes.GREATER_GEMS)
    }

    WheelController.gem.revelations = {}

    for i = 0, 2 do
        local current = {
            text = (data[i].name:match("^(.-)%s*Gem") or ""):gsub("%s+$", ""),
            gem = nil,
            itemId = data[i].id,
            requiredGems = resources[i],
            price = 0,
            color = "#d33c3c",
            resourceTooltip = nil,
            disabled = false
        }

        local totalBalance = WheelController.rawGold
        current.color = totalBalance >= helper.gems.GemRevealPrice[i] and "#c0c0c0" or "#d33c3c"
        current.price = comma_value(helper.gems.GemRevealPrice[i] / 1000) .. " k"

        local toolTip = ""
        if totalBalance < helper.gems.GemRevealPrice[i] then
            current.disabled = true
            current.resourceTooltip = tr(helper.gems.GemStaticTooltips[0], comma_value(helper.gems.GemRevealPrice[i]))
        end

        if WheelController.wheel.options ~= 1 then
            current.disabled = true
            current.resourceTooltip = tr("%s%s", (#toolTip > 0 and toolTip .. "\n" or ""),
                helper.gems.GemStaticTooltips[2])
        end

        WheelController.wheel.atelierGems = WheelController.wheel.atelierGems or {}
        if #WheelController.wheel.atelierGems >= 225 then
            current.disabled = true
            current.resourceTooltip = tr("%s%s", (#toolTip > 0 and toolTip .. "\n" or ""),
                helper.gems.GemStaticTooltips[3])
        end

        current.gem = string.format("Gem (x %d)", current.requiredGems)
        table.insert(WheelController.gem.revelations, current)

        -- TODO: adicionar ação no botão reveal
    end
end

function GemAtelier.showGems(selectFirst, lastIndex)
    print("GemAtelier.showGems")
    if not WheelController.gem or WheelController.currentTab ~= "gem" then
        return true
    end
    print("GemAtelier.showGem2")

    GemAtelier.setupVesselPanel()
    -- local gemList = gemAtelierWindow:recursiveGetChildById("gemContent")
    -- if not gemList then
    --     return true
    -- end

    totalGemList = {}
    currentGemList = {}
    WheelController.wheel.atelierGems = WheelController.wheel.atelierGems or {}
    for i, data in pairs(WheelController.wheel.atelierGems) do
        if (WheelController.gem.lockedOnly and not data.locked) or
            (WheelController.gem.sortQuality > 1 and data.gemType ~= WheelController.gem.sortQuality - 2) or
            (WheelController.gem.sortAffinity > 1 and data.gemDomain ~= WheelController.gem.sortAffinity - 2) or
            (#WheelController.gem.currentSearchText > 0 and not GemAtelier.matchGemText(data)) then
            goto continue
        end

        table.insert(totalGemList, data)
        :: continue ::
    end

    -- gemList:destroyChildren()
    -- gemList.onChildFocusChange = function(self, selected) GemAtelier.onSelectGem(selected, true) end
    local gemCount = 0
    local beginList = (WheelController.gem.currentPage - 1) * 15 + 1

    for i, data in pairs(totalGemList) do
        if gemCount == 15 then
            break
        end

        if i < beginList then
            goto continue
        end

        -- local widget = g_ui.createWidget('GemPanel', gemList)
        local current = GemAtelier.setupGemWidget(data)
        if current then
            table.insert(WheelController.gem.data, current)
            if i == 1 then
                print("First gem tooltip: ", current.text)
            end
        end

        currentGemList[#currentGemList + 1] = data
        -- widget:setActionId(#currentGemList)
        gemCount = gemCount + 1

        :: continue ::
    end

    GemAtelier.showGemRevelation()

    print("show revelation", #WheelController.gem.revelations)
    -- TODO: pages
    -- GemAtelier.configurePages()

    -- local panel = gemAtelierWindow:recursiveGetChildById("clickedPanel")
    -- local children = gemList:getChildren()

    -- if #children == 0 then
    --     panel.clickedContent:setVisible(false)
    --     panel.cleanContent:setVisible(true)
    -- else
    --     gemList:focusChild(nil)
    --     panel.cleanContent:setVisible(false)
    if selectFirst then
        WheelController.gem.lastSelectedGem = currentGemList[1]
        --         gemList:focusChild(gemList:getFirstChild())
    elseif lastIndex then
        WheelController.gem.lastSelectedGem = currentGemList[lastIndex]
    end
    --         gemList:focusChild(children[lastIndex])
    --     elseif lastSelectedGem and lastSelectedGem:isVisible() then
    --         gemList:focusChild(children[lastSelectedGem:getActionId()])
    --     end
    -- end
end

return GemAtelier

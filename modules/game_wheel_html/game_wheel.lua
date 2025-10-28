local helper = dofile("helpers/helper.lua")
local GemAtelier = dofile("gematelier.lua")
local Workshop = dofile("workshop.lua")

WheelController = Controller:new()

WheelController.GemAtelier = GemAtelier
WheelController.Workshop = Workshop
WheelButton = nil

local baseButtonClip = { x = 0, y = 0, width = 322, height = 34 }
local baseButtonClipped = { x = 0, y = 34, width = 322, height = 34 }

local activeColor = "#c0c0c0"
local inactiveColor = "#707070"
WheelController.currentWindow = "main-window"
WheelController.wheel = helper.wheel.baseWheelValues
WheelController.wheel.hasChanges = false
WheelController.wheel.originalPointInvested = {}
WheelController.wheel.trackChanges = false
WheelController.gem = {
    clip = baseButtonClip
}
WheelController.fragment = {
    clip = baseButtonClip
}

function WheelController:resetTabs()
    self.wheel.clip = baseButtonClip
    self.gem.clip = baseButtonClip
    self.fragment.clip = baseButtonClip
end

function WheelController:toggleMenu(menu)
    self:resetTabs()
    self.currentTab = menu
    self[menu].clip = baseButtonClipped
end

local quadrantFramesByMaxPoints = {
    [50] = 5,
    [75] = 8,
    [100] = 10,
    [150] = 15,
    [200] = 20
}

local baseWheelColorPath = "/images/game/wheel/wheel-colors/%s/%s_%s.png"
local baseColorSlotPath = "/images/game/wheel/wheel-colors/%s/slot%s/%s.png"

local baseInfoData = {
    title = nil,
    text = "\n\nFill or empty a slice with a\nright-click.",
}

function WheelController.wheel:handleOnHover(slotId, forceUpdate)
    if slotId == WheelController.wheel.currentHoverSlotId and not forceUpdate then
        return
    end
    WheelController.wheel.information.data = {}
    WheelController.wheel.information.hoveredSlotData = nil
    WheelController.wheel.currentHoverSlotId = slotId

    local data = WheelController.wheel.data[slotId]
    if data then
        WheelController.wheel.information.hoveredSlotData = data
        local pointInvested = WheelController.wheel.pointInvested[slotId] or 0
        local bonus = helper.bonus.WheelBonus[slotId - 1]
        WheelController.wheel.information.slotProgressCurrent = pointInvested
        WheelController.wheel.information.slotProgressTotal = bonus.maxPoints
        WheelController.wheel.information.slotProgressLabel = string.format("%d/%d", pointInvested, bonus.maxPoints)
        WheelController.wheel:getSlotProgressWidth("information")
        WheelController.wheel:configureDedication(WheelController.wheel.information.data, "hover", slotId)
        WheelController.wheel:configureConviction(WheelController.wheel.information.data, "hover", slotId)
    end
    table.insert(WheelController.wheel.information.data, baseInfoData)
end

local function resetSelection()
    WheelController.wheel.selectedPerkDomain = -1
    WheelController.wheel.selectedGemVesselDomain = -1
    WheelController.wheel.selectionBonus.showButtons = false
    WheelController.wheel.selectionBonus.canAdd = false
    WheelController.wheel.selectionBonus.canRemove = false
    WheelController.wheel.selectionBonus.showMoreDetails = false
    WheelController.wheel.selectionBonus.moreDetailsTitle = nil
    WheelController.wheel.selectionBonus.moreDetails = nil
    WheelController.wheel.selectionBonus.moreDetailsTooltip = nil
    WheelController.wheel.selectionBonus.moreDetailsColor = activeColor
    WheelController.wheel.selectionBonus.data = {}
    WheelController.wheel.selectionBonus.showChangeGemButton = false
    WheelController.wheel.information.data = baseInfoData
end

local function copyWheelPoints(source)
    local copy = {}
    if not source then
        return copy
    end

    for slotId, points in pairs(source) do
        copy[slotId] = points
    end

    return copy
end

local function hasDifferentPoints(original, current)
    for slotId, points in pairs(current) do
        if (original[slotId] or 0) ~= (points or 0) then
            return true
        end
    end

    for slotId, points in pairs(original) do
        if (current[slotId] or 0) ~= (points or 0) then
            return true
        end
    end

    return false
end

function WheelController.wheel:updateHasChanges()
    if not self.trackChanges then
        self.hasChanges = false
        return
    end

    local original = self.originalPointInvested or {}
    local current = self.pointInvested or {}

    self.hasChanges = hasDifferentPoints(original, current)
end

local function setPerk(index, path, _x, _y, _width, _height)
    path = path or "/images/game/wheel/icons-skillwheel-mediumperks.png"
    local iconInfo = helper.gems.WheelIcons[WheelController.wheel.vocationId][index]
    local x, y, width, height = iconInfo.iconRect:match("(%d+) (%d+) (%d+) (%d+)")
    WheelController.wheel.data[index].perkImage = path
    WheelController.wheel.data[index].iconClip = {
        x = _x or tonumber(x),
        y = _y or tonumber(y),
        width = _width or tonumber(width),
        height = _height or tonumber(height)
    }
end

local function getGemDomainDistribution()
    local data = {
        [helper.gems.GemDomains.GREEN] = 0,
        [helper.gems.GemDomains.RED] = 0,
        [helper.gems.GemDomains.ACQUA] = 0,
        [helper.gems.GemDomains.PURPLE] = 0,
    }

    local source = WheelController.wheel.equipedGems
    for _, id in pairs(source) do
        local domain = GemAtelier.getGemDomainById(id)
        if domain ~= -1 then
            data[domain] = id
        end
    end

    return data
end

function WheelController.wheel:apply()
    local activeGems = getGemDomainDistribution()

    g_game.applyWheelOfDestiny(WheelController.wheel.pointInvested, activeGems)

    WheelController.wheel.originalPointInvested = copyWheelPoints(WheelController.wheel.pointInvested)
    WheelController.wheel:updateHasChanges()
end

function WheelController.wheel:resetWheel()
    WheelController.wheel.passivePoints = {}
    for slotId in pairs(helper.wheel.WheelSlotsParser) do
        WheelController.wheel.pointInvested[slotId] = 0
        WheelController.wheel:removePoint(slotId, WheelController.wheel.pointInvested[slotId])
        WheelController.wheel:removeUnlockedThe(slotId)
        WheelController.wheel:handleUpdatePoints()
    end

    for id in pairs(helper.gems.WheelIcons[WheelController.wheel.vocationId]) do
        setPerk(id)
        WheelController.wheel.data[id].left = WheelController.wheel.data[id].left or 0
        WheelController.wheel.data[id].top = WheelController.wheel.data[id].top or 0
    end

    for i = 0, 3 do
        WheelController.wheel.vesselEnabled[i] = {}
    end

    WheelController.wheel.equipedGemBonuses = {}
    helper.bonus.configureDedicationPerk()
    helper.bonus.configureRevelationPerks()
    helper.bonus.configureVessels()
    WheelController.wheel:configureConvictionPerk()
    WheelController.wheel:handlePassiveBorders()
    WheelController.wheel:configureEquippedGems()
end

function WheelController.wheel:configureDedication(currentTable, currentType, index)
    index = index or WheelController.wheel.currentSelectSlotId or -1
    currentType = currentType or "click"
    currentTable = currentTable or WheelController.wheel.selectionBonus.data
    if index == -1 then
        resetSelection()
        return
    end
    local color = activeColor

    if WheelController.wheel.pointInvested[index] <= 0 then
        color = inactiveColor
    end

    if currentType == "click" then
        WheelController.wheel.selectionBonus.showButtons = true
    end
    table.insert(currentTable,
        {
            title = "Dedication Perk",
            text = helper.bonus.getDedicationBonus(index),
            color = color,
            tooltip = helper.bonus.getDedicationTooltip(index)
        }
    )
end

function WheelController.wheel:configureConviction(currentTable, currentType, index)
    index = index or WheelController.wheel.currentSelectSlotId or -1
    currentTable = currentTable or WheelController.wheel.selectionBonus.data
    currentType = currentType or "click"
    if index == -1 then
        resetSelection()
        return
    end

    local bonus = helper.bonus.WheelBonus[index - 1]
    local conviction = helper.bonus.getConvictionBonus(index)
    if currentType == "click" then
        WheelController.wheel.selectionBonus.showButtons = true
    end
    local tooltip = helper.bonus.getConvictionBonusTooltip(index)
    if type(conviction) == "table" then
        local firstIcon = true
        for i = 1, #conviction, 2 do
            local msg = conviction[i]
            msg = msg:gsub("\n+$", "")
            if #msg > 3 then
                local color = conviction[i + 1]
                local hasIcon = msg:find(":") ~= nil
                local iconPath = nil
                local activePath = color:lower() == activeColor and "active" or
                    "inactive"
                if hasIcon then
                    local iconNumber = firstIcon and 1 or 2
                    iconPath = string.format("/images/game/wheel/icon-augmentation%s-%s.png", iconNumber,
                        activePath)
                    firstIcon = false
                end
                table.insert(currentTable, {
                    title = i == 1 and "Conviction Perk" or nil,
                    tooltip = i == 1 and tooltip or nil,
                    text = msg,
                    color = color,
                    icon = iconPath,
                })
            end
        end
    else
        table.insert(currentTable, {
            title = "Conviction Perk",
            tooltip = tooltip,
            text = conviction,
            color = WheelController.wheel.pointInvested[index] >= bonus.maxPoints and activeColor or inactiveColor,
        })
    end
end

function WheelController.wheel:largePerkClick(domain)
    resetSelection()
    WheelController.wheel.currentSelectSlotId = -1
    WheelController.wheel.currentSelectSlotData = nil

    local domainToSpells = {
        [1] = "giftOfLife",
        [2] = "spellTR",
        [3] = "spellBL",
        [4] = "avatar"
    }

    local passive = WheelController.wheel.passivePoints[domain]
    local maximum = 250

    local extraPoints = WheelController.wheel.extraPassivePoints[domain] or 0
    passive = passive + extraPoints

    if passive >= 1000 then
        maximum = 1000
    elseif passive >= 500 then
        maximum = 1000
    elseif passive >= 250 then
        maximum = 500
    end

    if passive < 0 then
        passive = 0
    end

    WheelController.wheel.slotProgressCurrent = passive
    WheelController.wheel.slotProgressTotal = maximum
    WheelController.wheel:getSlotProgressWidth()

    local tooltip =
    "To unlock a Revelation Perk, you need to distribute promotion \npoints in the corresponding domain.\nTo unlock stage 1 of a Revelation Perk, you need 250 promotion \npoints. Stage 2 requires 500 promotion points. As soon as you have \ndistributed 1000 promotion points, stage 3 is unlocked.\nRevelation Mastery, which can be found on some gems, provides \nadditional points to unlock Revelation Perks.\n\nUnlocked Revelation Perks grant a bonus to all damage and \nhealing:\n* Stage 1 grants a bonus of +4 damage and healing\n* Stage 2 increases this bonus to +9\n* Stage 3 increases this bonus to +20"

    local spell = domainToSpells[domain]
    if WheelController.wheel.revelationPerks[spell] then
        WheelController.wheel.selectionBonus.showMoreDetails = true
        WheelController.wheel.selectionBonus.moreDetailsTitle = "More Details:"
        WheelController.wheel.selectionBonus.moreDetails = WheelController.wheel.revelationPerks[spell].text
        WheelController.wheel.selectionBonus.moreDetailsTooltip = WheelController.wheel.revelationPerks[spell].tooltip
        table.insert(WheelController.wheel.selectionBonus.data, {
            title = "Revelation Perk",
            text = WheelController.wheel.revelationPerks[spell].message,
            color = passive >= 250 and activeColor or inactiveColor,
            tooltip = tooltip,
        })
    end

    WheelController.wheel.selectedPerkDomain = domain
end

function WheelController.wheel:onGemVesselClick(domain)
    WheelController.wheel.currentSelectSlotId = -1
    WheelController.wheel.currentSelectSlotData = nil
    resetSelection()
    local filledCount = GemAtelier.getFilledVesselCount(domain)
    local data = GemAtelier.getEquipedGem(domain)

    local romanLetter = { "I", "II", "III" }
    local vesselStatus = "Sealed"
    if filledCount == 1 then
        vesselStatus = "Dormant"
    elseif filledCount == 2 then
        vesselStatus = "Awakened"
    elseif filledCount == 3 then
        vesselStatus = "Radiant"
    end

    WheelController.wheel.selectionBonus.showMoreDetails = true
    local filled = filledCount == 0 and "0" or romanLetter[filledCount]
    WheelController.wheel.selectionBonus.moreDetailsTitle = string.format("%s Vessel (VR %s)", vesselStatus, filled)
    WheelController.wheel.selectionBonus.moreDetailsTooltip =
    "If the Vessel Resonance matches the gem quality in this domain,a\nbonus of +1 to all damage and healing is granted. This bonus is\nincreased by 1 for greater gems.\n\nRegardless of the match, gems will always grant mod bonuses based on the Vessel Resonance.\n<ul><li style='margin-left:-26px'>Lesser gems match Dormant Vessels (VR I)</li>\n<li style='margin-left:-26px'>Regular gems match Awakened Vessels (VR II)</li>\n<li style='margin-left:-26px'>Greater gems match Radiant Vessels (VR III)</li></ul>"

    local tooltip =
    "Gems can be revealed within the Gem Atelier. Different gem qualities yield different amounts of mods:\n<ul><li style='margin-left:-26px'>Lesser gem: one basic mod</li>\n<li style='margin-left:-26px'>Regular gem: two basic mods</li>\n<li style='margin-left:-26px'>Greater gem: two basic mods and one supreme mod</li></ul>\nYou can enhance the effects of a mod by increasing its grade in the Fragment Workshop."

    WheelController.wheel.selectionBonus.showChangeGemButton = true

    local title = "Vessel contains no gem"
    local insertedTitle = false
    if data then
        title = helper.gems.GemVocations[WheelController.wheel.vocationId][data.gemType].name:gsub(
            " %(x 0%)", "")
        local decription = "(Unkown)"

        if data.gemType == 0 then
            decription = Workshop.getGemInformationByBonus(data.lesserBonus, false, data.gemID, 0)
            table.insert(WheelController.wheel.selectionBonus.data, {
                title = title,
                tooltip = tooltip,
                text = decription,
                color = (filledCount >= 1 and activeColor or inactiveColor)
            })
            insertedTitle = true
        elseif data.gemType == 1 then
            decription = Workshop.getGemInformationByBonus(data.lesserBonus, false, data.gemID, 0)
            table.insert(WheelController.wheel.selectionBonus.data, {
                title = not insertedTitle and title or nil,
                tooltip = not insertedTitle and tooltip or nil,
                text = decription,
                color = (filledCount >= 1 and activeColor or inactiveColor)
            })
            insertedTitle = true
            decription = Workshop.getGemInformationByBonus(data.regularBonus, false, data.gemID, 1)

            table.insert(WheelController.wheel.selectionBonus.data, {
                title = not insertedTitle and title or nil,
                tooltip = not insertedTitle and tooltip or nil,
                text = decription,
                color = (filledCount >= 2 and activeColor or inactiveColor)
            })
        elseif data.gemType == 2 then
            decription = Workshop.getGemInformationByBonus(data.lesserBonus, false, data.gemID, 0)

            table.insert(WheelController.wheel.selectionBonus.data, {
                title = not insertedTitle and title or nil,
                tooltip = not insertedTitle and tooltip or nil,
                text = decription,
                color = (filledCount >= 1 and activeColor or inactiveColor)
            })
            insertedTitle = true
            decription, gemSlot2 = Workshop.getGemInformationByBonus(data.regularBonus, false, data.gemID, 1)

            table.insert(WheelController.wheel.selectionBonus.data, {
                title = not insertedTitle and title or nil,
                tooltip = not insertedTitle and tooltip or nil,
                text = decription,
                color = (filledCount >= 2 and activeColor or inactiveColor)
            })

            decription = Workshop.getGemInformationByBonus(data.supremeBonus, true, data.gemID, 2)

            table.insert(WheelController.wheel.selectionBonus.data, {
                title = not insertedTitle and title or nil,
                tooltip = not insertedTitle and tooltip or nil,
                text = decription,
                color = (filledCount >= 3 and activeColor or inactiveColor)
            })
        end

        WheelController.wheel.selectionBonus.moreDetails = string.format("+%s Damage and Healing",
            (data.gemType == 2 and 2 or 1))
        WheelController.wheel.selectionBonus.moreDetailsColor = (filledCount == 3 and activeColor or inactiveColor)

        -- local replaceStr = { [0] = "�", [1] = "�", [2] = "�", [3] = "�" }
        -- TODO: adicionar ícones ao lado do tooltip do titulo baseado no nivel da gema
    end

    if not insertedTitle then
        WheelController.wheel.selectionBonus.moreDetails = " "
        table.insert(WheelController.wheel.selectionBonus.data, {
            title = title,
            color = activeColor,
            tooltip = tooltip
        })
    end

    WheelController.wheel.selectedGemVesselDomain = domain
end

function WheelController.wheel:handleSelectSlot(slotId)
    WheelController.wheel.currentSelectSlotId = slotId
    if WheelController.wheel.currentSelectSlotId == -1 then return end
    WheelController.wheel.currentSelectSlotData = WheelController.wheel.data[slotId]
    resetSelection()

    local pointInvested = WheelController.wheel.pointInvested[slotId] or 0
    local bonus = helper.bonus.WheelBonus[slotId - 1]
    WheelController.wheel.slotProgressCurrent = pointInvested
    WheelController.wheel.slotProgressTotal = bonus.maxPoints
    WheelController.wheel.slotProgressLabel = string.format("%d/%d", pointInvested, bonus.maxPoints)
    WheelController.wheel:getSlotProgressWidth()

    WheelController.wheel.selectionBonus.canAdd = WheelController.wheel:canAddPoints(slotId)
    WheelController.wheel.selectionBonus.canRemove = WheelController.wheel:canRemovePoints(slotId)

    WheelController.wheel:configureDedication()
    WheelController.wheel:configureConviction()
    WheelController.wheel:handleOnHover(slotId, true)

    g_logger.info("Selected slot ID: " .. tostring(slotId)) --- IGNORE ---
end

function WheelController:show(skipRequest)
    -- if not g_game.getFeature(GameForgeConvergence) then
    --     return WheelController:hide()
    -- end
    WheelController.wheel.currentSelectSlotId = -1
    WheelController.wheel.currentSelectSlotData = nil
    local player = g_game.getLocalPlayer()
    g_game.openWheelOfDestiny(player:getId())

    local needsReload = not self.ui or self.ui:isDestroyed()
    if needsReload then
        self:loadHtml('game_wheel.html')
    end

    if not self.ui then
        return
    end

    self.ui:centerIn('parent')
    self.ui:show()
    self.ui:raise()
    self.ui:focus()

    if WheelButton then
        WheelButton:setOn(true)
    end
end

local function resetValues()
    WheelController.wheel.currentSelectSlotId = -1
    WheelController.wheel.currentSelectedData = nil
    WheelController.wheel.slotProgressCurrent = 0
    WheelController.wheel.slotProgressTotal = 0
    WheelController.wheel.slotProgressWidth = 205
    WheelController.wheel.slotProgressLabel = "0/50"

    WheelController.wheel.information.slotProgressCurrent = 0
    WheelController.wheel.information.slotProgressTotal = 0
    WheelController.wheel.information.slotProgressLabel = "0/50"
    WheelController.wheel.information.slotProgressWidth = 205

    resetSelection()
end

function WheelController:handlePressEnter()
    if not self.wheel.hasChanges then
        self:hide()
        return
    end

    self.wheel:apply()
    self:hide()
end

function WheelController:handleClose()
    if self.wheel.hasChanges and self.currentWindow ~= "close-window" then
        self.currentWindow = "close-window"
    else
        self:hide()
    end
end

function WheelController:hide()
    resetValues()
    if not self.ui then
        return
    end

    WheelController.currentWindow = "main-window"
    WheelController.wheel:resetWheel()
    self.ui:hide()
    if WheelButton then
        WheelButton:setOn(false)
    end
end

function WheelController:toggle()
    WheelController.wheel.information.data = baseInfoData
    resetValues()
    if not self.ui or self.ui:isDestroyed() then
        self:show()
        return
    end

    if self.ui:isVisible() then
        self:hide()
    else
        self:show()
    end
end

function WheelController:onInit()
    self:registerEvents(g_game, {
        onWheelOfDestinyOpenWindow = onWheelOfDestinyOpenWindow,
        onResourcesBalanceChange = onResourcesBalanceChange,
    })

    if not WheelButton then
        WheelButton = modules.game_mainpanel.addToggleButton('WheelButton', tr('Open Wheel of Destiny'),
            '/images/options/wheel', function() self:toggle() end)
    end

    WheelController:updateResources()
    self.currentTab = 'wheel'
    WheelController:toggleMenu('wheel')
end

function WheelController.wheel:handleMousePress(event, id)
    local totalPoints = WheelController.wheel:getTotalPoints()
    local pointToInvest = math.max(totalPoints - WheelController.wheel.usedPoints, 0)
    resetSelection()
    WheelController.wheel:handleSelectSlot(id)
    WheelController.wheel:handleOnHover(id, true)
    if event.mouseButton == MouseRightButton then
        local data = WheelController.wheel.data[id]
        WheelController.wheel.currentSelectSlotId = id
        if WheelController.wheel.pointInvested[id] >= data.totalPoints or pointToInvest == 0 then
            WheelController.wheel:onRemoveAllPoints()
        elseif WheelController.wheel.pointInvested[id] >= 0 then
            WheelController.wheel:onAddAllPoints()
        end
    end
end

function WheelController.wheel:getSlotProgressWidth(tab, barWidth)
    barWidth = barWidth or 205
    tab = tab or "click"
    if tab == "click" then
        WheelController.wheel.slotProgressLabel = string.format("%d/%d", WheelController.wheel.slotProgressCurrent,
            WheelController.wheel.slotProgressTotal)
        local progress = WheelController.wheel.slotProgressCurrent / WheelController.wheel.slotProgressTotal
        WheelController.wheel.slotProgressWidth = progress * barWidth
    else
        WheelController.wheel.information.slotProgressLabel = string.format("%d/%d",
            WheelController.wheel.information.slotProgressCurrent,
            WheelController.wheel.information.slotProgressTotal)
        local progress = WheelController.wheel.information.slotProgressCurrent /
            WheelController.wheel.information.slotProgressTotal
        WheelController.wheel.information.slotProgressWidth = progress * barWidth
    end
end

function WheelController.wheel:isSlotInvested(index)
    if not WheelController.wheel.pointInvested[index] then return false end
    return WheelController.wheel.pointInvested[index] > 0
end

function WheelController.wheel:isSlotFull(index)
    return WheelController.wheel.pointInvested[index] == helper.bonus.WheelBonus[index - 1].maxPoints
end

function WheelController.wheel:canRemovePoints(index)
    if not WheelController.wheel:isSlotInvested(index) then
        return false
    end

    if WheelController.wheel.options ~= 1 then
        return false
    end

    local button = helper.buttons.WheelButtons[index]
    if button.radius == button.BIG_LARGE_CIRCLE then
        return true
    end

    local nodes = helper.nodes.WheelNodes[index]

    local iconInfo = nodes
    if not iconInfo.connections or #iconInfo.connections == 0 then
        return true
    end

    local c = nodes.connections
    for _, id in pairs(c) do
        if WheelController.wheel:isSlotInvested(id) and not helper.nodes.canReachConnectedNodes(id, index) then
            return false
        end
    end

    return true
end

function WheelController.wheel:removePoint(index, points)
    local bonus = helper.bonus.WheelBonus[index - 1]
    if points > 0 then
        local button = helper.buttons.WheelButtons[index]
        if points >= bonus.maxPoints then
            local maxcolor = 20
            if button.radius == button.BIG_LARGE_CIRCLE then
                maxcolor = 20
            elseif button.radius == button.LARGE_CIRCLE then
                maxcolor = 15
            elseif button.radius == button.BIG_MEDIUM_CIRCLE then
                maxcolor = 10
            elseif button.radius == button.MEDIUM_CIRCLE then
                maxcolor = 8
            elseif button.radius == button.SMALL_CIRCLE then
                maxcolor = 5
            end
            local path = button.colorImageBase .. maxcolor
            WheelController.wheel.data[index].colorPath = path .. ".png"
            WheelController.wheel.insertUnlockedThe(index)
        else
            if table.contains(helper.gems.VesselIndex[bonus.domain - 1], index - 1) then
                setPerk(index)
                WheelController.wheel.equipedGemBonuses[index] = { bonusID = -1, supreme = false, id = 0 }
                local removeIndex = 0
                for k, id in pairs(WheelController.wheel.vesselEnabled[bonus.domain - 1]) do
                    if id == index then
                        removeIndex = k;
                    end
                end
                table.remove(WheelController.wheel.vesselEnabled[bonus.domain - 1], removeIndex)
                WheelController.wheel:checkFilledVessels(index)
            end
            local _maxcolor = math.floor(points / 10) + 1
            _maxcolor = math.min(quadrantFramesByMaxPoints[bonus.maxPoints], _maxcolor)
            if _maxcolor > 0 then
                WheelController.wheel.data[index].colorPath = button.colorImageBase .. _maxcolor .. ".png"
            end
        end
    else
        if table.contains(helper.gems.VesselIndex[bonus.domain - 1], index - 1) then
            setPerk(index)
            WheelController.wheel.equipedGemBonuses[index] = { bonusID = -1, supreme = false, id = 0 }
            local removeIndex = 0
            for k, id in pairs(WheelController.wheel.vesselEnabled[bonus.domain - 1]) do
                if id == index then
                    removeIndex = k;
                end
            end
            table.remove(WheelController.wheel.vesselEnabled[bonus.domain - 1], removeIndex)
            WheelController.wheel:checkFilledVessels(index)
        end

        WheelController.wheel.data[index].colorPath = ""
    end
end

function WheelController.wheel:removeUnlockedThe(index)
    local iconInfo = helper.nodes.WheelNodes[index]
    if #iconInfo.connections == 0 then
        return false
    end

    for _, unlocked_point in pairs(iconInfo.connections) do
        local skipUnlock = {}
        for __, alternative_unlocker in ipairs(helper.nodes.WheelNodes[unlocked_point].connecteds) do
            if alternative_unlocker ~= index and WheelController.wheel.isSlotInvested(alternative_unlocker) then
                skipUnlock[#skipUnlock + 1] = unlocked_point
            end
        end

        if not table.contains(skipUnlock, unlocked_point) then
            WheelController.wheel.data[unlocked_point].adjacentPath = ""
        end
    end
end

function WheelController.wheel:getTotalPoints()
    return WheelController.wheel.points +
        (WheelController.wheel.extraGemPoints + WheelController.wheel.promotionScrollPoints)
end

function WheelController.wheel:handlePassiveBorders()
    for i = 0, 3 do
        local data = GemAtelier.getEquipedGem(i)
        local filledCount = GemAtelier.getFilledVesselCount(i)
        if data and data.supremeBonus > 0 and filledCount == 3 then
            local vocationId = helper.wheel.translateVocation(WheelController.wheel.vocationId)
            local supremeList = data.supremeBonus > 5 and helper.gems.VocationSupremeMods[vocationId] or
                helper.gems.FlatSupremeMods
            if supremeList then
                local bonus = supremeList[data.supremeBonus]
                if bonus and bonus.domain then
                    local gemValue = helper.bonus.getBonusValueUpgrade(data.supremeBonus, data.gemID, true, true)
                    local currentValue = WheelController.wheel.extraPassivePoints[bonus.domain + 1] or 0
                    WheelController.wheel.extraPassivePoints[bonus.domain + 1] = gemValue + currentValue
                end
            end
        end
    end


    local border = "TL"
    for domain, points in ipairs(WheelController.wheel.passivePoints) do
        if domain == 1 then
            border = "TL"
        elseif domain == 2 then
            border = "TR"
        elseif domain == 3 then
            border = "BL"
        elseif domain == 4 then
            border = "BR"
        end

        if points < 250 then
            WheelController.wheel.passiveBorders[border] =
                "/images/game/wheel/backdrop_skillwheel_largebonus_front0_" .. border .. ".png"
        elseif points < 500 then
            WheelController.wheel.passiveBorders[border] =
                "/images/game/wheel/backdrop_skillwheel_largebonus_front1_" .. border .. ".png"
        elseif points < 1000 then
            WheelController.wheel.passiveBorders[border] =
                "/images/game/wheel/backdrop_skillwheel_largebonus_front2_" .. border .. ".png"
        else
            WheelController.wheel.passiveBorders[border] =
                "/images/game/wheel/backdrop_skillwheel_largebonus_front3_" .. border .. ".png"
        end
    end
end

function WheelController.wheel:handleUpdatePoints()
    WheelController.wheel.passivePoints = {}

    local usedPoints = 0
    for id, _points in pairs(WheelController.wheel.pointInvested) do
        usedPoints = usedPoints + _points
        local bonus = helper.bonus.WheelBonus[id - 1]
        WheelController.wheel.passivePoints[bonus.domain] = (WheelController.wheel.passivePoints[bonus.domain] or 0) +
            _points
        if bonus.maxPoints <= _points then
            WheelController.wheel:insertUnlockedThe(id)
        end
    end

    WheelController.wheel.usedPoints = usedPoints
    local totalPoints = WheelController.wheel:getTotalPoints()
    WheelController.wheel.summaryPointsLabel = string.format("%d/%d", totalPoints - WheelController.wheel.usedPoints,
        totalPoints)

    WheelController.wheel:handlePassiveBorders()
    helper.bonus.configureDedicationPerk(WheelController)
    helper.bonus.configureRevelationPerks(WheelController)
    helper.bonus.configureVessels()
    WheelController.wheel:configureConvictionPerk()
    WheelController.wheel:configureEquippedGems()

    WheelController.wheel:handleSelectSlot(WheelController.wheel.currentSelectSlotId)

    for _, slot in pairs(helper.wheel.baseSlotIndex) do
        if WheelController.wheel.pointInvested[slot] == 0 then
            local button = helper.buttons.WheelButtons[slot]
            WheelController.wheel.data[slot].adjacentPath = button.colorImageBase .. "5.png"
        end
    end

    WheelController.wheel:updateHasChanges()
end

function WheelController.wheel:configureConvictionPerk()
    local convictions = helper.bonus.getConvictionPerks()
    WheelController.wheel.convictionPerks = convictions
end

function WheelController.wheel:onRemoveAllPoints()
    local index = WheelController.wheel.currentSelectSlotId

    if not WheelController.wheel:canRemovePoints(index) then
        return false
    end

    WheelController.wheel.pointInvested[index] = 0
    WheelController.wheel:removePoint(index, WheelController.wheel.pointInvested[index])
    WheelController.wheel:removeUnlockedThe(index)
    WheelController.wheel:handleUpdatePoints()
end

function WheelController.wheel:onAddAllPoints()
    local index = WheelController.wheel.currentSelectSlotId
    if not index or index == -1 then
        return false
    end
    if WheelController.wheel.options ~= 1 then
        return false
    end
    local pointInvested = WheelController.wheel.pointInvested[index]
    local bonus = helper.bonus.WheelBonus[index - 1]
    if pointInvested >= bonus.maxPoints then
        return
    end

    local totalPoints = WheelController.wheel:getTotalPoints()

    local pointToInvest = math.max(totalPoints - WheelController.wheel.usedPoints, 0)

    if pointToInvest == 1 then
        return WheelController.wheel:onAddOnePoint()
    end

    if not WheelController.wheel:canAddPoints(index, true) then
        return
    end

    WheelController.wheel.pointInvested[index] = math.min((pointInvested + pointToInvest), bonus.maxPoints)
    WheelController.wheel:insertPoint(index, WheelController.wheel.pointInvested[index])
    WheelController.wheel:handleUpdatePoints()
end

function WheelController.wheel:onAddOnePoint()
    local index = WheelController.wheel.currentSelectSlotId
    if not index or index == -1 then
        return false
    end
    if WheelController.wheel.options ~= 1 then
        return false
    end

    local pointInvested = WheelController.wheel.pointInvested[index]
    local bonus = helper.bonus.WheelBonus[index - 1]


    if pointInvested >= bonus.maxPoints then
        return
    end

    if not WheelController.wheel:canAddPoints(index, true) then
        return
    end

    WheelController.wheel.pointInvested[index] = pointInvested + 1
    WheelController.wheel:insertPoint(index, WheelController.wheel.pointInvested[index])
    WheelController.wheel:insertUnlockedThe(index)

    WheelController.wheel:handleUpdatePoints()
end

function WheelController.wheel:onRemoveOnePoint()
    local index = WheelController.wheel.currentSelectSlotId
    if not index or index == -1 then
        return false
    end
    if WheelController.wheel.options ~= 1 then
        return false
    end

    if not WheelController.wheel:canRemovePoints(index) then
        return
    end

    local pointInvested = WheelController.wheel.pointInvested[index]
    if pointInvested == 0 then
        return
    end

    WheelController.wheel.pointInvested[index] = pointInvested - 1
    WheelController.wheel:removePoint(index, WheelController.wheel.pointInvested[index])
    WheelController.wheel:handleUpdatePoints()
end

function WheelController.wheel:canAddPoints(index, ignoreMaxPoint)
    if WheelController.wheel.vocationId == 0 then
        return false
    end

    if ignoreMaxPoint == nil then
        ignoreMaxPoint = false
    end

    local bonus = helper.bonus.WheelBonus[index - 1]
    if not ignoreMaxPoint then
        if WheelController.wheel.pointInvested[index] >= bonus.maxPoints then
            return false
        end
    end

    if not WheelController.wheel.points then
        WheelController.wheel.points = 0
    end

    local totalPoints = WheelController.wheel.points +
        (WheelController.wheel.extraGemPoints + WheelController.wheel.promotionScrollPoints)

    if not ignoreMaxPoint then
        if totalPoints - WheelController.wheel.usedPoints <= 0 then
            return false
        end
    end

    if bonus.maxPoints == 50 then
        return true
    end

    local iconInfo = helper.nodes.WheelNodes[index]
    if #iconInfo.connecteds == 0 then
        return true
    end

    for _, id in pairs(iconInfo.connecteds) do
        local _bonus = helper.bonus.WheelBonus[id - 1]
        local pointInvested = WheelController.wheel.pointInvested[id]
        if pointInvested >= _bonus.maxPoints then
            return true
        end
    end

    return false
end

function WheelController.wheel:handleChangePointsButton(currentType)
    local index = WheelController.wheel.currentSelectSlotId

    if currentType == "all" and (not index or index == -1) then
        return false
    end

    if WheelController.wheel:canAddPoints(index) and currentType == "add" then
        return true
    end
    if WheelController.wheel:canRemovePoints(index) and currentType == "remove" then
        return true
    end

    return false
end

function WheelController.wheel:insertUnlockedThe(index)
    local iconInfo = helper.nodes.WheelNodes[index]
    if #iconInfo.connections == 0 then
        return false
    end

    local bonus = helper.bonus.WheelBonus[index - 1]
    local pointInvested = WheelController.wheel.pointInvested[index]
    if pointInvested < bonus.maxPoints then
        return false
    end

    for _, id in pairs(iconInfo.connections) do
        local data = WheelController.wheel.data[id]
        WheelController.wheel.data[id].adjacentPath = string.format(baseColorSlotPath,
            data.quadrant,
            data.index,
            quadrantFramesByMaxPoints[data.totalPoints])
    end
end

function WheelController.wheel:checkFilledVessels(index)
    local bonus = helper.bonus.WheelBonus[index - 1]
    local order = helper.bonus.WheelDomainOrder[bonus.domain - 1]
    local function findIndex(value)
        for i, v in ipairs(order) do
            if v == value then
                return i
            end
        end
        return nil
    end

    local function customSort(a, b)
        local indexA = findIndex(a)
        local indexB = findIndex(b)
        return indexA < indexB
    end

    WheelController.wheel.vesselEnabled[bonus.domain - 1] = WheelController.wheel.vesselEnabled[bonus.domain - 1] or {}

    table.sort(WheelController.wheel.vesselEnabled[bonus.domain - 1], customSort)

    local lastModInserted = 0
    for _, id in pairs(WheelController.wheel.vesselEnabled[bonus.domain - 1]) do
        bonus = helper.bonus.WheelBonus[id - 1]
        local gem = GemAtelier.getEquipedGem(bonus.domain - 1, WheelController)
        if not gem then
            goto continue
        end

        if lastModInserted == 0 and gem.lesserBonus > -1 then
            setPerk(id, "/images/game/wheel/icons-skillwheel-basicmods.png", 30 * gem.lesserBonus, 0, 30, 30)
            WheelController.wheel.equipedGemBonuses[id] = {
                bonusID = gem.lesserBonus,
                supreme = false,
                gemID = gem.gemID
            }
            lastModInserted = 1
        elseif lastModInserted == 1 and gem.regularBonus > -1 then
            setPerk(id, "/images/game/wheel/icons-skillwheel-basicmods.png", 30 * gem.regularBonus, 0, 30, 30)
            WheelController.wheel.equipedGemBonuses[id] = {
                bonusID = gem.regularBonus,
                supreme = false,
                gemID = gem.gemID
            }
            lastModInserted = 2
        elseif lastModInserted == 2 and gem.supremeBonus > -1 then
            setPerk(id, "/images/game/wheel/icons-skillwheel-suprememods.png", 35 * gem.supremeBonus, 0, 35, 35)
            WheelController.wheel.equipedGemBonuses[id] = {
                bonusID = gem.supremeBonus,
                supreme = true,
                gemID = gem.gemID
            }
            lastModInserted = 3
        end
        :: continue ::
    end
end

function WheelController.wheel:insertPoint(id, points)
    local bonus                               = helper.bonus.WheelBonus[id - 1]
    local data                                = WheelController.wheel.data[id]
    local button                              = helper.buttons.WheelButtons[id]
    WheelController.wheel.data[id].id         = id
    WheelController.wheel.data[id].borderPath = button.borderImageBase .. ".png"
    WheelController.wheel.data[id].hoverPath  = button.focusImageBase .. ".png"
    WheelController.wheel.data[id].bgPath     = string.format(baseWheelColorPath, data.quadrant, data.color,
        data.index)

    local isBaseSlot                          = helper.wheel.isFirstSlot(id)

    if points > 0 then
        if points >= bonus.maxPoints then
            local maxcolor = 20
            if button.radius == helper.buttons.BIG_LARGE_CIRCLE then
                maxcolor = 20
            elseif button.radius == helper.buttons.LARGE_CIRCLE then
                maxcolor = 15
            elseif button.radius == helper.buttons.BIG_MEDIUM_CIRCLE then
                maxcolor = 10
            elseif button.radius == helper.buttons.MEDIUM_CIRCLE then
                maxcolor = 8
            elseif button.radius == helper.buttons.SMALL_CIRCLE then
                maxcolor = 5
            end

            local path = button.colorImageBase .. maxcolor
            WheelController.wheel.data[id].colorPath = path .. ".png"
            WheelController.wheel:insertUnlockedThe(id)

            if table.contains(helper.gems.VesselIndex[bonus.domain - 1], id - 1) then
                local gem = GemAtelier.getEquipedGem(bonus.domain - 1, WheelController)
                if gem then
                    local enabled = WheelController.wheel.vesselEnabled[bonus.domain - 1]
                    if #enabled == 0 and gem.lesserBonus > -1 then
                        setPerk(id, "/images/game/wheel/icons-skillwheel-basicmods.png", 30 * gem.lesserBonus, 0,
                            30, 30)
                        WheelController.wheel.equipedGemBonuses[id] = {
                            bonusID = gem.lesserBonus,
                            supreme = false,
                            gemID = gem.gemID
                        }
                        table.insert(WheelController.wheel.vesselEnabled[bonus.domain - 1], id)
                    elseif #enabled == 1 and gem.regularBonus > -1 then
                        setPerk(id, "/images/game/wheel/icons-skillwheel-basicmods.png", 30 * gem.regularBonus,
                            0, 30, 30)

                        WheelController.wheel.equipedGemBonuses[id] = {
                            bonusID = gem.regularBonus,
                            supreme = false,
                            gemID = gem.gemID
                        }
                        table.insert(WheelController.wheel.vesselEnabled[bonus.domain - 1], id)
                    elseif #enabled == 2 and gem.supremeBonus > -1 then
                        setPerk(id, "/images/game/wheel/icons-skillwheel-suprememods.png", 35 * gem
                            .supremeBonus, 0, 35, 35)
                        WheelController.wheel.equipedGemBonuses[id] = {
                            bonusID = gem.supremeBonus,
                            supreme = false,
                            gemID = gem.gemID
                        }
                        table.insert(WheelController.wheel.vesselEnabled[bonus.domain - 1], id)
                    end
                else
                    -- setPerk(index)
                end
            end
        else
            local _maxcolor = math.floor(points / 10) + 1
            _maxcolor = math.min(quadrantFramesByMaxPoints[bonus.maxPoints], _maxcolor)
            if _maxcolor > 0 then
                WheelController.wheel.data[id].colorPath = button.colorImageBase .. _maxcolor .. ".png"
            end
        end
    elseif not isBaseSlot then
        WheelController.wheel.data[id].colorPath = ""
    end

    if isBaseSlot and points == 0 then
        WheelController.wheel.data[id].adjacentPath = button.colorImageBase .. "5.png"
    end

    WheelController.wheel:checkFilledVessels(id)
end

function WheelController.wheel:configureEquippedGems()
    WheelController.wheel.activeGems = {}
    for i = 0, 3 do
        local data = GemAtelier.getEquipedGem(i)
        local filledCount = GemAtelier.getFilledVesselCount(i)
        local backgroundImage = (filledCount == 0 and "backdrop_skillwheel_largebonus_socketdisabled_" .. i or "backdrop_skillwheel_largebonus_socketenabled_" .. i)
        local current = {
            backgroundPath = "/images/game/wheel/" .. backgroundImage .. ".png",
            socketPath = "/images/game/wheel/icons-skillwheel-sockets.png",
            socketClip = { x = 0, y = 0, width = 34, height = 34 },
            gemPath = nil,
            gemClip = nil,
        }

        local showSocket = filledCount > 0
        if showSocket then
            local startPos = 442
            if data and filledCount == (data.gemType + 1) then
                startPos = 34
            end

            local domainOffset = startPos + (102 * i)
            local modOffset = 34 * math.max(0, filledCount - 1)
            current.socketClip = { x = domainOffset + modOffset, y = 0, width = 34, height = 34 }
        end
        if data then
            local typeOffset = data.gemType * 32
            local domainOffet = data.gemDomain * 96
            local vocationOffset = (WheelController.wheel.vocationId - 1) * 384
            local gemOffset = vocationOffset + domainOffet + typeOffset
            current.gemClip = { x = gemOffset, y = 0, width = 32, height = 32 }
            current.gemPath = "/images/game/wheel/icons-gematelier-gemvariants.png"
        else
            current.gemPath = nil
            current.gemClip = nil
        end
        table.insert(WheelController.wheel.activeGems, current)
    end
end

function WheelController.wheel:selectInformationTab(tabOrder)
    local buttons = helper.wheel.informationButtonClips
    if tabOrder == 1 then
        WheelController.wheel.information.secondButton.path = buttons.secondButton.unselected
        WheelController.wheel.information.secondButton.clip = buttons.secondButton.unselectedClip
        WheelController.wheel.information.secondButton.width = buttons.secondButton.unselectedWidth
        WheelController.wheel.information.secondButton.active = false

        WheelController.wheel.information.firstButton.path = buttons.firstButton.selected
        WheelController.wheel.information.firstButton.clip = buttons.firstButton.selectedClip
        WheelController.wheel.information.firstButton.width = buttons.firstButton.selectedWidth
        WheelController.wheel.information.firstButton.active = true
    elseif tabOrder == 2 then
        WheelController.wheel.information.firstButton.path = buttons.firstButton.unselected
        WheelController.wheel.information.firstButton.clip = buttons.firstButton.unselectedClip
        WheelController.wheel.information.firstButton.width = buttons.firstButton.unselectedWidth
        WheelController.wheel.information.firstButton.active = false

        WheelController.wheel.information.secondButton.path = buttons.secondButton.selected
        WheelController.wheel.information.secondButton.clip = buttons.secondButton.selectedClip
        WheelController.wheel.information.secondButton.width = buttons.secondButton.selectedWidth
        WheelController.wheel.information.secondButton.active = true
    end
end

function WheelController:updateResources()
    WheelController.gold = WheelController.gold or "0"
    WheelController.lesserFragment = WheelController.lesserFragment or 0
    WheelController.greaterFragment = WheelController.greaterFragment or 0

    local player = g_game.getLocalPlayer()
    if player then
        WheelController.lesserFragment = player:getResourceBalance(ResourceTypes.LESSER_FRAGMENT)
        WheelController.greaterFragment = player:getResourceBalance(ResourceTypes.GREATER_FRAGMENT)
        WheelController.gold = comma_value(player:getTotalMoney())
    end
end

function onResourcesBalanceChange(balance, oldBalance, type)
    WheelController:updateResources()
end

function onWheelOfDestinyOpenWindow(data)
    WheelController.wheel.trackChanges = false
    WheelController.wheel.options = data.options
    WheelController.wheel.vocationId = data.vocationId or 0
    WheelController.wheel.points = data.points or 0
    WheelController.wheel.extraGemPoints = 0
    WheelController.wheel.usedPoints = 0
    data.points = data.points or 0
    data.extraPoints = data.extraPoints or 0
    WheelController.wheel.pointInvested = {}
    WheelController.wheel.passivePoints = {}
    WheelController.wheel.currentPoints = data.points
    WheelController.wheel.promotionScrollPoints = data.extraPoints
    WheelController.wheel.equipedGems = data.activeGems or {}
    WheelController.wheel.data = helper.wheel.WheelSlotsParser
    data.wheelPoints = data.wheelPoints or {}
    WheelController.wheel.vesselEnabled = {}
    WheelController.wheel.atelierGems = data.revealedGems or {}
    WheelController.wheel.basicModsUpgrade = data.basicGrades or {}
    WheelController.wheel.supremeModsUpgrade = data.supremeGrades or {}
    Workshop.createFragments()
    for id, gem in pairs(WheelController.wheel.atelierGems) do
        gem.lesserBonus = gem.basicModifier1 > 0 and gem.basicModifier1 or -1
        gem.regularBonus = gem.basicModifier2 > 0 and gem.basicModifier2 or -1
        gem.supremeBonus = gem.supremeModifier > 0 and gem.supremeModifier or -1
        gem.gemType = gem.quality
        gem.gemDomain = gem.affinity
        gem.gemID = id
    end

    WheelController.wheel.equipedGemBonuses = {}

    -- order
    local orderned = {
        15, 9, 14, 3, 8, 13, 2, 7, 1, 16, 10, 17, 4, 11, 18, 5, 12, 6, 22, 23, 28, 24, 29, 34, 30, 35, 36, 21, 20, 27, 19, 26, 33, 25, 32, 31
    }

    for _, tier in pairs(WheelController.wheel.basicModsUpgrade) do
        if tier == 3 then
            WheelController.wheel.extraGemPoints = WheelController.wheel.extraGemPoints + 1
        end
    end

    for _, tier in pairs(WheelController.wheel.supremeModsUpgrade) do
        if tier == 3 then
            WheelController.wheel.extraGemPoints = WheelController.wheel.extraGemPoints + 1
        end
    end


    local currentPoints = 0
    for k, v in pairs(data.wheelPoints) do
        currentPoints = currentPoints + v
    end

    for _, id in pairs(orderned) do
        local points = data.wheelPoints[id]
        local bonus = helper.bonus.WheelBonus[id - 1]
        WheelController.wheel.usedPoints = WheelController.wheel.usedPoints + points
        WheelController.wheel.passivePoints[bonus.domain] = (WheelController.wheel.passivePoints[bonus.domain] or 0) +
            points
        WheelController.wheel.pointInvested[id] = points
    end

    local _currentPoints = 0
    for k, v in pairs(WheelController.wheel.pointInvested) do
        _currentPoints = _currentPoints + v
    end

    for id, iconInfo in pairs(helper.gems.WheelIcons[data.vocationId]) do
        local miniIconRect = iconInfo.miniIconRect
        setPerk(id)
        WheelController.wheel.data[id].left = WheelController.wheel.data[id].left or 0
        WheelController.wheel.data[id].top = WheelController.wheel.data[id].top or 0

        local x, y, width, height = miniIconRect:match("(%d+) (%d+) (%d+) (%d+)")
        WheelController.wheel.data[id].miniIconClip = {
            x = tonumber(x),
            y = tonumber(y),
            width = tonumber(width),
            height = tonumber(height)
        }
    end

    for i = 1, 4 do
        WheelController.wheel.vesselEnabled[i - 1] = {}
        for _, index in pairs(helper.bonus.WheelDomainOrder[i - 1]) do
            local bonus = helper.bonus.WheelBonus[index - 1]
            local pointInvested = WheelController.wheel.pointInvested[index]
            if pointInvested >= bonus.maxPoints and bonus.conviction == "vessel" then
                table.insert(WheelController.wheel.vesselEnabled[bonus.domain - 1], index)
                WheelController.wheel:checkFilledVessels(index)
            end
        end
    end

    -- check slot integrity
    for id, points in pairs(WheelController.wheel.pointInvested) do
        if not WheelController.wheel:canAddPoints(id, true) and points > 0 then
            local bonus = helper.bonus.WheelBonus[id - 1]
            WheelController.wheel.usedPoints = WheelController.wheel.usedPoints - points
            WheelController.wheel.passivePoints[bonus.domain] = WheelController.wheel.passivePoints[bonus.domain] -
                points
            points = 0
        end
    end

    for id, _points in pairs(WheelController.wheel.pointInvested) do
        WheelController.wheel:insertPoint(id, _points)
    end

    local function incrementBonusCount(_bonus, bonusType)
        if _bonus ~= -1 then
            local _data = bonusType[tostring(_bonus)]
            if _data then
                bonusType[tostring(_bonus)] = _data + 1
            else
                bonusType[tostring(_bonus)] = 1
            end
        end
    end

    WheelController.wheel.basicModCount = {}
    WheelController.wheel.supremeModCount = {}
    for _, info in pairs(WheelController.wheel.atelierGems) do
        incrementBonusCount(info.lesserBonus, WheelController.wheel.basicModCount)
        incrementBonusCount(info.regularBonus, WheelController.wheel.basicModCount)
        incrementBonusCount(info.supremeBonus, WheelController.wheel.supremeModCount)
    end

    local totalPoints = WheelController.wheel:getTotalPoints()
    WheelController.wheel.summaryPointsLabel = string.format("%d/%d", totalPoints - WheelController.wheel.usedPoints,
        totalPoints)

    WheelController.wheel.currentPoints = currentPoints
    WheelController.wheel.extraPoints = data.extraPoints
    WheelController.wheel.totalPoints = data.points + data.extraPoints
    WheelController.wheel.slots = helper.wheel.WheelSlotsParser
    local basicVocationId = helper.wheel.getBasicVocation(data.vocationId)
    local overlayImage = helper.wheel.getVocationImage(basicVocationId)
    if not overlayImage then
        return WheelController:hide()
    end

    WheelController.wheel.backdropVocationOverlay = overlayImage .. ".png"

    helper.wheel.handleLargePerkClip(data.vocationId, WheelController)
    helper.bonus.configureDedicationPerk(WheelController)
    helper.bonus.configureRevelationPerks(WheelController)
    helper.bonus.configureVessels()
    WheelController.wheel:configureConvictionPerk()
    WheelController.wheel:handlePassiveBorders()
    WheelController.wheel:configureEquippedGems()

    WheelController.wheel.originalPointInvested = copyWheelPoints(WheelController.wheel.pointInvested)
    WheelController.wheel.trackChanges = true
    WheelController.wheel:updateHasChanges()
end

local helper = dofile("helpers/helper.lua")

local function translateVocation(id)
    if id == 1 or id == 11 then
        return 8 -- ek
    elseif id == 2 or id == 12 then
        return 7 -- rp
    elseif id == 3 or id == 13 then
        return 5 -- ms
    elseif id == 4 or id == 14 then
        return 6 -- ed
    elseif id == 5 or id == 15 then
        return 9 -- em
    end
    return 0
end

local Workshop = {}
local fragmentList = {}

function Workshop.getFragmentList()
    return fragmentList
end

function Workshop.getDataByBonus(bonusID, supreme)
    for _, data in pairs(fragmentList) do
        if (supreme and data.supreme and bonusID == data.modID) or (not supreme and not data.supreme and bonusID == data.modID) then
            return data
        end
    end
    return nil
end

function Workshop.createFragments()
    local player = g_game.getLocalPlayer()
    if not player then
        return true
    end

    local vocationId = translateVocation(player:getVocation())

    fragmentList = {}
    for id = 0, #helper.gems.FlatSupremeMods do
        local info = helper.gems.FlatSupremeMods[id]
        if info then
            if id == 4 and vocationId > 6 then
                goto continue
            end

            info.modID = id
            info.supreme = true
            table.insert(fragmentList, info)
            ::continue::
        end
    end

    local vocationMods = helper.gems.VocationSupremeMods[vocationId]
    local vocationIDRanges = {
        [8] = { fromID = 6, toID = 24 },
        [7] = { fromID = 23, toID = 41 },
        [5] = { fromID = 42, toID = 58 },
        [6] = { fromID = 59, toID = 75 },
        [9] = { fromID = 76, toID = 93 }
    }

    local idRange = vocationIDRanges[vocationId]
    if idRange then
        for id = idRange.fromID, idRange.toID do
            local info = vocationMods[id]
            if info then
                info.modID = id
                info.supreme = true
                table.insert(fragmentList, info)
            end
        end
    end

    for id = 0, #helper.gems.BasicMods do
        local info = helper.gems.BasicMods[id]
        if info then
            info.modID = id
            info.supreme = false
            table.insert(fragmentList, info)
        end
    end
end

function Workshop.getBonusDescription(modInfo, relativeTier)
    local description = ""
    if modInfo.desc and modInfo.showDesc then
        description = tr("%s\n", modInfo.desc)
    end

    local targetTier = modInfo.supreme and WheelController.wheel.supremeModsUpgrade[modInfo.modID] or
        WheelController.wheel.basicModsUpgrade[modInfo.modID]
    if relativeTier then
        targetTier = relativeTier
    end

    local step = helper.gems.bonusStep[WheelController.wheel.vocationId]

    local function getStepBonus(baseStep, stepType)
        if modInfo.type and modInfo.type == "cooldown" then
            if not targetTier or targetTier == 0 then
                return 0
            end

            local specialValue = modInfo.baseII + (modInfo.baseII * (targetTier - 1))
            return (targetTier == 3 and math.round(specialValue) or specialValue)
        elseif not stepType then
            return Workshop.getUpgradeBonus(baseStep, modInfo.modID, modInfo.supreme, relativeTier)
        elseif stepType == "mana" then
            return Workshop.getUpgradeBonus(modInfo.baseStepI * step.mana, modInfo.modID, modInfo.supreme, relativeTier)
        elseif stepType == "health" then
            return Workshop.getUpgradeBonus(modInfo.baseStepI * step.life, modInfo.modID, modInfo.supreme, relativeTier)
        elseif stepType == "capacity" then
            return Workshop.getUpgradeBonus(modInfo.baseStepI * step.capacity, modInfo.modID, modInfo.supreme,
                relativeTier)
        else
            return Workshop.getUpgradeBonus(baseStep, modInfo.modID, modInfo.supreme, relativeTier)
        end
    end

    local bonusI = getStepBonus(modInfo.baseI, modInfo.stepTypeI)
    local bonusII = modInfo.baseII and getStepBonus(modInfo.baseII, modInfo.stepTypeII)

    local function processTooltip(bonusI, bonusII)
        if modInfo.type == "cooldown" then
            if targetTier == 0 then
                local str = modInfo.tooltip
                local result = str:gsub("\n.*", "")
                return result
            end
            return tr(modInfo.tooltip, bonusII)
        end

        if bonusII then
            return tr(modInfo.tooltip, bonusI, bonusII)
        end
        return tr(modInfo.tooltip, bonusI)
    end
    description = description .. processTooltip(bonusI, bonusII)
    return description
end

function Workshop.getSideBonusDescription(data, targetTier)
    local description = ""
    local step = helper.gems.bonusStep[WheelController.wheel.vocationId]

    local function calculateSpecialValue(baseII, targetTier)
        local specialValue = baseII + (baseII * (targetTier - 1))
        if targetTier == 3 then
            specialValue = math.round(specialValue)
        end
        return specialValue
    end

    local function getStepBonus(baseStep, stepType)
        if data.type and data.type == "cooldown" then
            if targetTier == 0 then
                return 0
            end

            local specialValue = data.baseII + (data.baseII * (targetTier - 1))
            if targetTier == 3 then
                specialValue = math.round(specialValue)
            end
            return specialValue
        elseif not stepType then
            return Workshop.getUpgradeBonus(baseStep, data.modID, data.supreme, targetTier)
        elseif stepType == "mana" then
            return Workshop.getUpgradeBonus(data.baseStepI * step.mana, data.modID, data.supreme, targetTier)
        elseif stepType == "health" then
            return Workshop.getUpgradeBonus(data.baseStepI * step.life, data.modID, data.supreme, targetTier)
        elseif stepType == "capacity" then
            return Workshop.getUpgradeBonus(data.baseStepI * step.capacity, data.modID, data.supreme, targetTier)
        else
            return Workshop.getUpgradeBonus(baseStep, data.modID, data.supreme, targetTier)
        end
    end

    local bonusI = getStepBonus(data.baseI, data.stepTypeI)
    local bonusII = data.baseII and getStepBonus(data.baseII, data.stepTypeII)

    local function processTooltip(bonusI, bonusII)
        if data.type == "cooldown" then
            if targetTier == 0 then
                local str = data.tooltip
                local result = str:gsub("\n.*", "")
                return result
            end
            return tr(data.tooltip, bonusII)
        end

        if bonusII then
            return tr(data.tooltip, bonusI, bonusII)
        end
        return tr(data.tooltip, bonusI)
    end
    description = description .. processTooltip(bonusI, bonusII)
    return description
end

function Workshop.getBonusValue(modInfo, targetTier, firstBonus)
    if not modInfo then
        return 0
    end

    local step = helper.gems.bonusStep[WheelController.wheel.vocationId]
    local function getStepBonus(baseStep, stepType)
        if modInfo.type and modInfo.type == "cooldown" then
            if not targetTier or targetTier == 0 then
                return 0
            end

            local specialValue = modInfo.baseII + (modInfo.baseII * (targetTier - 1))
            return (targetTier == 3 and math.round(specialValue) or specialValue)
        elseif not stepType then
            return Workshop.getUpgradeBonus(baseStep, modInfo.modID, modInfo.supreme, targetTier)
        elseif stepType == "mana" then
            return Workshop.getUpgradeBonus(modInfo.baseStepI * step.mana, modInfo.modID, modInfo.supreme, targetTier)
        elseif stepType == "health" then
            return Workshop.getUpgradeBonus(modInfo.baseStepI * step.life, modInfo.modID, modInfo.supreme, targetTier)
        elseif stepType == "capacity" then
            return Workshop.getUpgradeBonus(modInfo.baseStepI * step.capacity, modInfo.modID, modInfo.supreme, targetTier)
        else
            return Workshop.getUpgradeBonus(baseStep, modInfo.modID, modInfo.supreme, targetTier)
        end
    end

    local bonusI = getStepBonus(modInfo.baseI, modInfo.stepTypeI)
    local bonusII = modInfo.baseII and getStepBonus(modInfo.baseII, modInfo.stepTypeII)
    return firstBonus and bonusI or bonusII
end

function Workshop.getGemInformationByBonus(gemBonusID, supremeMod, gemID, gemSlot)
    local gem = WheelController.GemAtelier.getGemDataById(gemID)
    if not gem then
        return 0
    end

    local effectiveLevel = WheelController.GemAtelier.getEffectiveLevel(gem, gemBonusID, supremeMod, gemSlot)
    local modInfo = Workshop.getDataByBonus(gemBonusID, supremeMod)
    if not modInfo then
        return "(Unkown)", 0
    end

    local text = Workshop.getBonusDescription(modInfo, effectiveLevel)
    if text:find("Aug.") then
        text = text:gsub("Aug.", "Augmented")
    end

    local translateText = { [0] = "(I)", [1] = "(II)", [2] = "(III)", [3] = "(IV)" }
    text = text .. " " .. translateText[effectiveLevel]
    return text, effectiveLevel
end

function Workshop.getUpgradeBonus(baseBonus, modID, supreme, targetTier)
    local modTier = targetTier and targetTier or
        (supreme and WheelController.wheel.supremeModsUpgrade[modID] or WheelController.wheel.basicModsUpgrade[modID])
    if not modTier then
        return baseBonus
    end

    if modTier == 3 then
        baseBonus = baseBonus + (baseBonus * 50 / 100)
    else
        baseBonus = baseBonus + (baseBonus * (10 * modTier) / 100)
    end

    baseBonus = math.floor(baseBonus * 100 + 0.5) / 100
    return baseBonus
end

return Workshop

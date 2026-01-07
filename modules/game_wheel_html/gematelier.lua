local helper = dofile("helpers/helper.lua")

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

return GemAtelier

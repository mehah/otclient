-- @docclass Player
-- local index = math.log(bit) / math.log(2)
PlayerStates = {
	None = 0,	-- vbot
	Poison = 1,
	Burn = 2,
	Energy = 4,
	Drunk = 8,
	ManaShield = 16,
	Paralyze = 32,
	Haste = 64,
	Swords = 128,
	Drowning = 256,
	Freezing = 512,
	Dazzled = 1024,
	Cursed = 2048,
	PartyBuff = 4096,
	RedSwords = 8192,
	PzBlock = 8192,	-- vbot
	Pz = 16384,	-- vbot
	Pigeon = 16384,
	Bleeding = 32768,
	Hungry = 65536,	-- vbot
	LesserHex = 65536,
	IntenseHex = 131072,
	GreaterHex = 262144,
	Rooted = 524288,
	Feared = 1048576,
	GoshnarTaint1 = 2097152,
	GoshnarTaint2 = 4194304,
	GoshnarTaint3 = 8388608,
	GoshnarTaint4 = 16777216,
	GoshnarTaint5 = 33554432,
	NewManaShield = 67108864,
	Agony = 134217728,
-- force icons
	Rewards = 30
}

Icons = {}
Icons[PlayerStates.Poison] = { clip = 1, tooltip = tr('You are poisoned'),  id = 'condition_poisoned' }
Icons[PlayerStates.Burn] = { clip = 2, tooltip = tr('You are burning'),  id = 'condition_burning' }
Icons[PlayerStates.Energy] = { clip = 3, tooltip = tr('You are electrified'),  id = 'condition_electrified' }
Icons[PlayerStates.Drunk] = { clip = 4, tooltip = tr('You are drunk'),  id = 'condition_drunk' }
Icons[PlayerStates.ManaShield] = { clip = 5, tooltip = tr('You are protected by a magic shield'),  id = 'condition_magic_shield' }
Icons[PlayerStates.Paralyze] = { clip = 6, tooltip = tr('You are paralysed'),  id = 'condition_slowed' }
Icons[PlayerStates.Haste] = { clip = 7, tooltip = tr('You are hasted'),  id = 'condition_haste' }
Icons[PlayerStates.Swords] = { clip = 8, tooltip = tr('You may not logout during a fight'),  id = 'condition_logout_block' }
Icons[PlayerStates.Drowning] = { clip = 9, tooltip = tr('You are drowning'),  id = 'condition_drowning' }
Icons[PlayerStates.Freezing] = { clip = 10, tooltip = tr('You are freezing'),  id = 'condition_freezing' }
Icons[PlayerStates.Dazzled] = { clip = 11, tooltip = tr('You are dazzled'),  id = 'condition_dazzled' }
Icons[PlayerStates.Cursed] = { clip = 12, tooltip = tr('You are cursed'),  id = 'condition_cursed' }
Icons[PlayerStates.PartyBuff] = { clip = 13, tooltip = tr('You are strengthened'),  id = 'condition_strengthened' }
Icons[PlayerStates.RedSwords] = { clip = 14, tooltip = tr('You may not logout or enter a protection zone'),  id = 'condition_RedSwords' }
Icons[PlayerStates.Pigeon] = { clip = 15, tooltip = tr('You are within a protection zone'),  id = 'condition_Pigeon' }
Icons[PlayerStates.Bleeding] = { clip = 16, tooltip = tr('You are Bleeding'),  id = 'condition_Bleeding' }
Icons[PlayerStates.LesserHex] = { clip = 17, tooltip = tr('You are LesserHex'),  id = 'condition_LesserHex' }
Icons[PlayerStates.IntenseHex] = { clip = 18, tooltip = tr('You are IntenseHex'),  id = 'condition_IntenseHex' }
Icons[PlayerStates.GreaterHex] = { clip = 19, tooltip = tr('You are GreaterHex'),  id = 'condition_GreaterHex' }
Icons[PlayerStates.Rooted] = { clip = 20, tooltip = tr('You are Rooted'),  id = 'condition_Rooted' }
Icons[PlayerStates.Feared] = { clip = 21, tooltip = tr('You are Feared'),  id = 'condition_Feared' }
Icons[PlayerStates.GoshnarTaint1] = { clip = 22, tooltip = tr('You are GoshnarTaint'),  id = 'condition_GoshnarTaint1' }
Icons[PlayerStates.GoshnarTaint2] = { clip = 23, tooltip = tr('You are GoshnarTaint'),  id = 'condition_GoshnarTaint2' }
Icons[PlayerStates.GoshnarTaint3] = { clip = 24, tooltip = tr('You are GoshnarTaint'),  id = 'condition_GoshnarTaint3' }
Icons[PlayerStates.GoshnarTaint4] = { clip = 25, tooltip = tr('You are GoshnarTaint'),  id = 'condition_GoshnarTaint4' }
Icons[PlayerStates.GoshnarTaint5] = { clip = 26, tooltip = tr('You are GoshnarTaint'),  id = 'condition_GoshnarTaint5' }
Icons[PlayerStates.NewManaShield] = {  clip = 27, tooltip = tr('You are NewManaShield'), id = 'condition_NewManaShield' }
Icons[PlayerStates.Agony] = { clip = 28, tooltip = tr('You are Agony'),  id = 'condition_Agony' }
Icons[PlayerStates.Rewards] = { clip = 30, tooltip = tr('Rewards'),  id = 'condition_Rewards' }
Icons[PlayerStates.Hungry] = { clip = 32, tooltip = tr('You are hungry'),  id = 'condition_hungry' }

InventorySlotOther = 0
InventorySlotHead = 1
InventorySlotNeck = 2
InventorySlotBack = 3
InventorySlotBody = 4
InventorySlotRight = 5
InventorySlotLeft = 6
InventorySlotLeg = 7
InventorySlotFeet = 8
InventorySlotFinger = 9
InventorySlotAmmo = 10
InventorySlotPurse = 11

InventorySlotFirst = 1
InventorySlotLast = 10

vocationNamesByClientId = {
    [0] = "No Vocation",
    [1] = "Knight",
    [2] = "Paladin",
    [3] = "Sorcerer",
    [4] = "Druid",
    [11]= "Elite Knight",
    [12] = "Royal Paladin",
    [13] = "Master Sorcerer",
    [14] = "Elder Druid"
}

function Player:isPartyLeader()
    local shield = self:getShield()
    return (shield == ShieldWhiteYellow or shield == ShieldYellow or shield == ShieldYellowSharedExp or shield ==
               ShieldYellowNoSharedExpBlink or shield == ShieldYellowNoSharedExp)
end

function Player:isPartyMember()
    local shield = self:getShield()
    return (shield == ShieldWhiteYellow or shield == ShieldYellow or shield == ShieldYellowSharedExp or shield ==
               ShieldYellowNoSharedExpBlink or shield == ShieldYellowNoSharedExp or shield == ShieldBlueSharedExp or
               shield == ShieldBlueNoSharedExpBlink or shield == ShieldBlueNoSharedExp or shield == ShieldBlue)
end

function Player:isPartySharedExperienceActive()
    local shield = self:getShield()
    return (shield == ShieldYellowSharedExp or shield == ShieldYellowNoSharedExpBlink or shield ==
               ShieldYellowNoSharedExp or shield == ShieldBlueSharedExp or shield == ShieldBlueNoSharedExpBlink or
               shield == ShieldBlueNoSharedExp)
end

function Player:hasVip(creatureName)
    for id, vip in pairs(g_game.getVips()) do
        if (vip[1] == creatureName) then
            return true
        end
    end
    return false
end

function Player:isMounted()
    local outfit = self:getOutfit()
    return outfit.mount ~= nil and outfit.mount > 0
end

function Player:toggleMount()
    if g_game.getFeature(GamePlayerMounts) then
        g_game.mount(not self:isMounted())
    end
end

function Player:mount()
    if g_game.getFeature(GamePlayerMounts) then
        g_game.mount(true)
    end
end

function Player:dismount()
    if g_game.getFeature(GamePlayerMounts) then
        g_game.mount(false)
    end
end

function Player:getItem(itemId, subType)
    return g_game.findPlayerItem(itemId, subType or -1)
end

function Player:getItems(itemId, subType)
    local subType = subType or -1

    local items = {}
    for i = InventorySlotFirst, InventorySlotLast do
        local item = self:getInventoryItem(i)
        if item and item:getId() == itemId and (subType == -1 or item:getSubType() == subType) then
            table.insert(items, item)
        end
    end

    for i, container in pairs(g_game.getContainers()) do
        for j, item in pairs(container:getItems()) do
            if item:getId() == itemId and (subType == -1 or item:getSubType() == subType) then
                item.container = container
                table.insert(items, item)
            end
        end
    end
    return items
end

function Player:getItemsCount(itemId)
    local items, count = self:getItems(itemId), 0
    for i = 1, #items do
        count = count + items[i]:getCount()
    end
    return count
end

function Player:hasState(state, states)
    if not states then
        states = self:getStates()
    end

    for i = 1, 32 do
        local pow = math.pow(2, i - 1)
        if pow > states then
            break
        end

        local states = bit.band(states, pow)
        if states == state then
            return true
        end
    end
    return false
end

function Player:getVocationNameByClientId()
    return vocationNamesByClientId[self:getVocation()] or "Unknown Vocation"
end

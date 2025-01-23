-- @docclass Player
PlayerStates = {
	Poison = 0,
	Burn = 1,
	Energy = 2,
	Drunk = 3,
	ManaShield = 4,
	Paralyze = 5,
	Haste = 6,
	Swords = 7,
	Drowning = 8,
	Freezing = 9,
	Dazzled = 10,
	Cursed = 11,
	PartyBuff = 12,
	RedSwords = 13,
	Pigeon = 14,
	Bleeding = 15,
	LesserHex = 16,
	IntenseHex = 17,
	GreaterHex = 18,
	Rooted = 19,
	Feared = 20,
	GoshnarTaint1 = 21,
	GoshnarTaint2 = 22,
	GoshnarTaint3 = 23,
	GoshnarTaint4 = 24,
	GoshnarTaint5 = 25,
	NewManaShield = 26,
	Agony = 27,
}

Icons = {}
Icons[PlayerStates.Poison] = { tooltip = tr('You are poisoned'), path = '/images/game/states/poisoned', id = 'condition_poisoned' }
Icons[PlayerStates.Burn] = { tooltip = tr('You are burning'), path = '/images/game/states/burning', id = 'condition_burning' }
Icons[PlayerStates.Energy] = { tooltip = tr('You are electrified'), path = '/images/game/states/electrified', id = 'condition_electrified' }
Icons[PlayerStates.Drunk] = { tooltip = tr('You are drunk'), path = '/images/game/states/drunk', id = 'condition_drunk' }
Icons[PlayerStates.ManaShield] = { tooltip = tr('You are protected by a magic shield'), path = '/images/game/states/magic_shield', id = 'condition_magic_shield' }
Icons[PlayerStates.Paralyze] = { tooltip = tr('You are paralysed'), path = '/images/game/states/slowed', id = 'condition_slowed' }
Icons[PlayerStates.Haste] = { tooltip = tr('You are hasted'), path = '/images/game/states/haste', id = 'condition_haste' }
Icons[PlayerStates.Swords] = { tooltip = tr('You may not logout during a fight'), path = '/images/game/states/logout_block', id = 'condition_logout_block' }
Icons[PlayerStates.Drowning] = { tooltip = tr('You are drowning'), path = '/images/game/states/drowning', id = 'condition_drowning' }
Icons[PlayerStates.Freezing] = { tooltip = tr('You are freezing'), path = '/images/game/states/freezing', id = 'condition_freezing' }
Icons[PlayerStates.Dazzled] = { tooltip = tr('You are dazzled'), path = '/images/game/states/dazzled', id = 'condition_dazzled' }
Icons[PlayerStates.Cursed] = { tooltip = tr('You are cursed'), path = '/images/game/states/cursed', id = 'condition_cursed' }
Icons[PlayerStates.PartyBuff] = { tooltip = tr('You are strengthened'), path = '/images/game/states/strengthened', id = 'condition_strengthened' }
Icons[PlayerStates.RedSwords] = { tooltip = tr('You may not logout or enter a protection zone'), path = '/images/game/states/feared', id = 'condition_RedSwords' }
Icons[PlayerStates.Pigeon] = { tooltip = tr('You are within a protection zone'), path = '/images/game/states/feared', id = 'condition_Pigeon' }
Icons[PlayerStates.Bleeding] = { tooltip = tr('You are Bleeding'), path = '/images/game/states/feared', id = 'condition_Bleeding' }
Icons[PlayerStates.LesserHex] = { tooltip = tr('You are LesserHex'), path = '/images/game/states/feared', id = 'condition_LesserHex' }
Icons[PlayerStates.IntenseHex] = { tooltip = tr('You are IntenseHex'), path = '/images/game/states/feared', id = 'condition_IntenseHex' }
Icons[PlayerStates.GreaterHex] = { tooltip = tr('You are GreaterHex'), path = '/images/game/states/feared', id = 'condition_GreaterHex' }
Icons[PlayerStates.Rooted] = { tooltip = tr('You are Rooted'), path = '/images/game/states/feared', id = 'condition_Rooted' }
Icons[PlayerStates.Feared] = { tooltip = tr('You are Feared'), path = '/images/game/states/feared', id = 'condition_Feared' }
Icons[PlayerStates.GoshnarTaint1] = { tooltip = tr('You are GoshnarTaint1'), path = '/images/game/states/feared', id = 'condition_GoshnarTaint1' }
Icons[PlayerStates.GoshnarTaint2] = { tooltip = tr('You are GoshnarTaint2'), path = '/images/game/states/feared', id = 'condition_GoshnarTaint2' }
Icons[PlayerStates.GoshnarTaint3] = { tooltip = tr('You are GoshnarTaint3'), path = '/images/game/states/feared', id = 'condition_GoshnarTaint3' }
Icons[PlayerStates.GoshnarTaint4] = { tooltip = tr('You are GoshnarTaint4'), path = '/images/game/states/feared', id = 'condition_GoshnarTaint4' }
Icons[PlayerStates.GoshnarTaint5] = { tooltip = tr('You are GoshnarTaint5'), path = '/images/game/states/feared', id = 'condition_GoshnarTaint5' }
Icons[PlayerStates.NewManaShield] = { tooltip = tr('You are NewManaShield'), path = '/images/game/states/feared', id = 'condition_NewManaShield' }
Icons[PlayerStates.Agony] = { tooltip = tr('You are Agony'), path = '/images/game/states/feared', id = 'condition_Agony' }

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

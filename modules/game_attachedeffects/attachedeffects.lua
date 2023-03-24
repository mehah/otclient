controller = Controller:new()

-- uncomment this line to apply an effect on the local player, just for testing purposes.
--[[controller:onGameStart(function()
    g_game.getLocalPlayer():attachEffect(AttachedEffectManager.create(1))
    g_game.getLocalPlayer():attachEffect(AttachedEffectManager.create(2))
    g_game.getLocalPlayer():attachEffect(AttachedEffectManager.create(4))

    local angelLight1 = AttachedEffectManager.create(3)
    local angelLight2 = AttachedEffectManager.create(3)
    local angelLight3 = AttachedEffectManager.create(3)
    local angelLight4 = AttachedEffectManager.create(3)

    angelLight1:setOffset(-50, 50, true)
    angelLight2:setOffset(50, 50, true)
    angelLight3:setOffset(50, -50, true)
    angelLight4:setOffset(-50, -50, true)

    g_game.getLocalPlayer():attachEffect(angelLight1)
    g_game.getLocalPlayer():attachEffect(angelLight2)
    g_game.getLocalPlayer():attachEffect(angelLight3)
    g_game.getLocalPlayer():attachEffect(angelLight4)
end)

controller:onGameEnd(function()
    g_game.getLocalPlayer():clearAttachedEffects()
end)]]

local function onAttach(effect, owner)
    local category, thingId = AttachedEffectManager.getDataThing(owner)
    local config = AttachedEffectManager.getConfig(effect:getId(), category, thingId)

    if config.onAttach then
        config.onAttach(effect, owner, config.__onAttach)
    end
end

local function onDetach(effect, oldOwner)
    local category, thingId = AttachedEffectManager.getDataThing(oldOwner)
    local config = AttachedEffectManager.getConfig(effect:getId(), category, thingId)

    if config.onDetach then
        config.onDetach(effect, oldOwner, config.__onDetach)
    end
end

local function onOutfitChange(creature, outfit, oldOutfit)
    for _i, effect in pairs(creature:getAttachedEffects()) do
        AttachedEffectManager.executeThingConfig(effect, ThingCategoryCreature, outfit.type)
    end
end

controller:attachExternalEvent(EventController:new(LocalPlayer, {
    onOutfitChange = onOutfitChange
}))
controller:attachExternalEvent(EventController:new(Creature, {
    onOutfitChange = onOutfitChange
}))
controller:attachExternalEvent(EventController:new(AttachedEffect, {
    onAttach = onAttach,
    onDetach = onDetach
}))

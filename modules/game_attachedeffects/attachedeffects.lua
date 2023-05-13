controller = Controller:new()

-- uncomment this line to apply an effect on the local player, just for testing purposes.
--[[function controller:onGameStart()
    g_game.getLocalPlayer():attachEffect(g_attachedEffects.getById(1))
    g_game.getLocalPlayer():attachEffect(g_attachedEffects.getById(2))
    g_game.getLocalPlayer():attachEffect(g_attachedEffects.getById(3))
end

function controller:onGameEnd()
    g_game.getLocalPlayer():clearAttachedEffects()
end]]
function controller:onTerminate()
    g_attachedEffects.clear()
end

local function onAttach(effect, owner)
    local category, thingId = AttachedEffectManager.getDataThing(owner)
    local config = AttachedEffectManager.getConfig(effect:getId(), category, thingId)

    if config.isThingConfig then
        AttachedEffectManager.executeThingConfig(effect, category, thingId)
    end

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

-- Example
--[[
function onGameStart()
    g_game.getLocalPlayer():attachEffect(AttachedEffectManager.create(1))
    g_game.getLocalPlayer():attachEffect(AttachedEffectManager.create(2))

    onOutfitChange(g_game.getLocalPlayer(), g_game.getLocalPlayer():getOutfit())
end

function onGameEnd()
    g_game.getLocalPlayer():clearAttachedEffects()
end
]] --
function init()
    connect(LocalPlayer, {
        onOutfitChange = onOutfitChange
    })

    connect(Creature, {
        onOutfitChange = onOutfitChange
    })

    connect(AttachedEffect, {
        onAdd = onAdd,
        onRemove = onRemove
    })

    connect(g_game, {
        onGameStart = onGameStart,
        onGameEnd = onGameEnd
    })

    if g_game.isOnline() then
        onGameStart()
    end
end

function terminate()
    if g_game.isOnline() then
        onGameEnd()
    end

    disconnect(LocalPlayer, {
        onOutfitChange = onOutfitChange
    })

    disconnect(Creature, {
        onOutfitChange = onOutfitChange
    })

    disconnect(AttachedEffect, {
        onAdd = onAdd,
        onRemove = onRemove
    })

    disconnect(g_game, {
        onGameStart = onGameStart,
        onGameEnd = onGameEnd
    })
end

function onAdd(effect, owner)
    local config = AttachedEffectManager.get(effect:getId()).config

    if owner:isCreature() then
        if config.disableWalkAnimation then
            owner:setDisableWalkAnimation(config.disableWalkAnimation)
        end
    end

    if config.onAdd then
        config.onAdd(effect, owner, config.__onAdd)
    end
end

function onRemove(effect, oldOwner)
    local config = AttachedEffectManager.get(effect:getId()).config
    if config.disableWalkAnimation then
        oldOwner:setDisableWalkAnimation(false)
    end

    if config.onRemove then
        config.onRemove(effect, oldOwner, config.__onRemove)
    end
end

function onOutfitChange(creature, outfit, oldOutfit)
    for _i, effect in pairs(creature:getAttachedEffects()) do
        AttachedEffectManager.executeThingConfig(effect, ThingCategoryCreature, outfit.type)
    end
end

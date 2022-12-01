function init()

    connect(LocalPlayer, {
        onOutfitChange = onOutfitChange
    })

    connect(Creature, {
        onOutfitChange = onOutfitChange
    })

    connect(StaticEffect, {
        onAdd = onAddStaticEffect,
        onRemove = onRemoveStaticEffect
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

    disconnect(StaticEffect, {
        onAdd = onAddStaticEffect,
        onRemove = onRemoveStaticEffect
    })

    disconnect(g_game, {
        onGameStart = onGameStart,
        onGameEnd = onGameEnd
    })
end

function onGameStart()
    g_game.getLocalPlayer():addStaticEffect(StaticEffectManager.create(1))
    g_game.getLocalPlayer():addStaticEffect(StaticEffectManager.create(2))

    onOutfitChange(g_game.getLocalPlayer(), g_game.getLocalPlayer():getOutfit())
end

function onGameEnd()
    g_game.getLocalPlayer():clearStaticEffect()
end

function onAddStaticEffect(effect, owner)
    print(123)
end

function onRemoveStaticEffect(effect, oldOwner)
    print(345)
end

function onOutfitChange(creature, outfit, oldOutfit)
    for _i, effect in pairs(creature:getStaticEffects()) do
        StaticEffectManager.executeThingConfig(effect, ThingCategoryCreature, outfit.type)
    end
end

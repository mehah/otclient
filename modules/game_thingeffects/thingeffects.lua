function init()

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
    onGameEnd()

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
    local staticEffect = StaticEffect.create(1, 12, ThingCategoryEffect)
    staticEffect:setSpeed(0.2)
    staticEffect:setOffset(0, -10)
    staticEffect:setOnTop(false)

    g_game.getLocalPlayer():addStaticEffect(staticEffect)
end

function onGameEnd()
    g_game.getLocalPlayer():removeStaticEffectById(1)
end

function onAddStaticEffect(effect, owner)
    print(123)
end

function onRemoveStaticEffect(effect, oldOwner)
    print(345)
end

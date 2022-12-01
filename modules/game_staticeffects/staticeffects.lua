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
    if g_game.isOnline() then
        onGameEnd()
    end

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

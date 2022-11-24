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
    g_game.getLocalPlayer():addStaticEffect(createEffectById(1))
    g_game.getLocalPlayer():addStaticEffect(createEffectById(2))

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

function getEffectById(id)
    for i, effect in pairs(__EFFECTS) do
        if effect.id == id then
            return effect
        end
    end
    return nil
end

function createEffectById(id)
    local effect = getEffectById(id)

    if effect then
        if effect.id == id then
            local staticEffect = StaticEffect.create(effect.id, effect.thingId, effect.category)
            if effect.speed then
                staticEffect:setSpeed(effect.speed)
            end
            if effect.offset then
                staticEffect:setOffset(effect.offset.x, effect.offsety)
            end
            if effect.onTop then
                staticEffect:setOnTop(effect.onTop)
            end

            if effect.dirsControl then
                for dir, control in pairs(effect.dirsControl) do
                    local offset = control.offset
                    if not offset and control.x and control.y then
                        offset = {
                            x = control.x,
                            y = control.y
                        }
                    end

                    if not offset and effect.offset then
                        offset = effect.offset
                    end

                    if offset then
                        staticEffect:setDirOffset(dir, offset.x, offset.y, control.onTop or effect.onTop or false)
                    elseif control.onTop then
                        staticEffect:setOnTopByDir(dir, control.onTop)
                    end
                end
            end
            return staticEffect
        end
    end

    return nil
end

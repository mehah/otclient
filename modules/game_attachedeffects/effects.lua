--[[
    register(id, name, thingId, thingType, config)
    config = {
        speed, disableWalkAnimation, shader,
        offset{x, y, onTop}, dirOffset[dir]{x, y, onTop},
        onAttach, onDetach
    }
]] --
AttachedEffectManager.register(1, 'Spoke Lighting', 12, ThingCategoryEffect, {
    speed = 0.5,
    onAttach = function(effect, owner)
        print('onAttach: ', effect:getId(), owner:getName())
    end,
    onDetach = function(effect, oldOwner)
        print('onDetach: ', effect:getId(), oldOwner:getName())
    end
})

AttachedEffectManager.register(2, 'Bat Wings', 307, ThingCategoryCreature, {
    speed = 5,
    disableWalkAnimation = true,
    shader = 'Outfit - Rainbow',
    dirOffset = {
        [North] = {0, -10, true},
        [East] = {5, -5},
        [South] = {-5, 0},
        [West] = {-10, -5, true}
    }
})

AttachedEffectManager.register(3, 'Angel Light', 50, ThingCategoryEffect, {
    opacity = 0.5,
    drawOnUI = false
})

AttachedEffectManager.register(4, 'Transform Demon', 35, ThingCategoryCreature, {
    hideOwner = true,
    duration = 5000,
    shader = 'Outfit - Rainbow',
    onAttach = function(effect, owner)
        local e = Effect.create()
        e:setId(51)
        owner:getTile():addThing(e)
    end,
    onDetach = function(effect, oldOwner)
        local e = Effect.create()
        e:setId(7)
        oldOwner:getTile():addThing(e)
    end
})

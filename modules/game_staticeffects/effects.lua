--[[
    register(id, name, thingId, thingType, config)
    config = {speed, disableWalkAnimation, offset{x, y, onTop}, dirOffset[dir]{x, y, onTop}}
]] --
StaticEffectManager.register(1, 'Spoke Lighting', 12, ThingCategoryEffect, {
    speed = 0.5
})

StaticEffectManager.register(2, 'Bat Wings', 307, ThingCategoryCreature, {
    disableWalkAnimation = true,
    dirOffset = {
        [North] = {0, -10, true},
        [East] = {5, -5},
        [South] = {-5, 0},
        [West] = {-10, -5, true}
    }
})

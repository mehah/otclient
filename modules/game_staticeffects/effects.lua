--[[ id, name, thingId, thingType, {speed, offset[x, y], dirOffset{[x, y, onTop]}} --]] --
StaticEffectManager.register(1, 'Spoke Lighting', 12, ThingCategoryEffect, {
    speed = 0.5
})

StaticEffectManager.register(2, 'Bat Wings', 307, ThingCategoryCreature, {
    dirOffset = {
        [North] = {0, 2, true},
        [East] = {5, -5},
        [South] = {-5, 0},
        [West] = {-10, -5, true}
    }
})

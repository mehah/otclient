--[[ (thingId, thingType) ]] --
local c = StaticEffectManager.registerThingConfig(ThingCategoryCreature, 618)

--[[ set(staticEffectId, {offsetX, offsetY, onTop} or {[dir] = {offsetX, offsetY, onTop}}) ]]

c:set(1, {
    speed = 10
})

c:set(2, {
    speed = 2,
    dirOffset = {
        [North] = {0, -5, true},
        [East] = {10, -5},
        [South] = {0, 10},
        [West] = {-10, 0, true}
    }
})

--[[
    registerThingConfig(thingId, thingType)
    set(staticEffectId, config)
]] --
local c = StaticEffectManager.registerThingConfig(ThingCategoryCreature, 618)

c:set(1, {
    speed = 10
})

c:set(2, {
    speed = 1, -- Default Speed
    dirOffset = {
        [North] = {0, -5, true},
        [East] = {10, -5},
        [South] = {0, 10},
        [West] = {-10, 0, true}
    },
    onAdd = function(effect, owner)
        print('OnAdd in Config: ', effect:getId(), owner:getName())
    end,
    onRemove = function(effect, oldOwner)
        print('OnRemove in Config: ', effect:getId(), oldOwner:getName())
    end
})

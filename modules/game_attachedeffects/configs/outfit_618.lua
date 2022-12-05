--[[
    registerThingConfig(thingId, thingType)
    set(attachedEffectId, config)
]] --
local c = AttachedEffectManager.registerThingConfig(ThingCategoryCreature, 618)

c:set(1, {
    speed = 10,
    onAttach = function(effect, owner, oldEventFnc)
        oldEventFnc(effect, owner)
        print('onAttach in Config: ', effect:getId(), owner:getName())
    end
})

c:set(2, {
    speed = 1, -- Default Speed
    dirOffset = {
        [North] = {0, -5, true},
        [East] = {10, -5},
        [South] = {0, 10},
        [West] = {-10, 0, true}
    },
    onAttach = function(effect, owner, oldEventFnc)
        print('onAttach in Config: ', effect:getId(), owner:getName())
    end,
    onDetach = function(effect, oldOwner, oldEventFnc)
        print('onDetach in Config: ', effect:getId(), oldOwner:getName())
    end
})

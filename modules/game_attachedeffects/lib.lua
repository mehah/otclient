local __EFFECTS = {}
local __THING_CONFIG = {}

local executeConfig = function(attachedEffect, config)
    local x = 0
    local y = 0
    local onTop = false

    if config then
        if config.speed then
            attachedEffect:setSpeed(config.speed)
        end

        if config.offset then
            x = config.offset[1] or 0
            y = config.offset[2] or 0
            onTop = config.offset[3] or false
        end

        if config.drawOnUI == false then
            attachedEffect:setCanDrawOnUI(false)
        end

        if config.shader then
            attachedEffect:setShader(config.shader)
        end

        if config.opacity ~= nil and config.opacity < 1.0 then
            attachedEffect:setOpacity(config.opacity)
        end

        if config.duration ~= nil and config.duration > 0 then
            attachedEffect:setDuration(config.duration)
        end

        if config.loop ~= nil and config.loop > 0 then
            attachedEffect:setLoop(config.loop)
        end

        if config.transform then
            attachedEffect:setTransform(config.transform)
        end

        if config.hideOwner then
            attachedEffect:setHideOwner(config.hideOwner)
        end

        if config.disableWalkAnimation then
            attachedEffect:setDisableWalkAnimation(config.disableWalkAnimation)
        end

        if x ~= 0 or y ~= 0 then
            attachedEffect:setOffset(x, y)
        end
        if onTop then
            attachedEffect:setOnTop(true)
        end

        if config.dirOffset then
            for dir, offset in pairs(config.dirOffset) do
                local _x = offset[1] or x
                local _y = offset[2] or y
                local _onTop = offset[3] or onTop

                if type(x) == 'boolean' then -- onTop Config
                    attachedEffect:setOnTopByDir(dir, _x)
                else
                    attachedEffect:setDirOffset(dir, _x, _y, _onTop)
                end
            end
        end
    end

end

AttachedEffectManager = {
    get = function(id)
        return __EFFECTS[id]
    end,
    register = function(id, name, thingId, thingCategory, config)
        if __EFFECTS[id] ~= nil then
            g_logger.error('A static effect has already been registered with id(' .. id .. ')')
            return
        end
        __EFFECTS[id] = {
            id = id,
            name = name,
            thingId = thingId,
            thingCategory = thingCategory,
            config = config
        }
    end,
    create = function(id)
        local effect = __EFFECTS[id]
        if effect == nil then
            g_logger.error('Invalid Static Effect ID(' .. id .. ')')
            return
        end

        local attachedEffect = AttachedEffect.create(effect.id, effect.thingId, effect.thingCategory)
        executeConfig(attachedEffect, effect.config)

        return attachedEffect
    end,
    registerThingConfig = function(category, thingId)
        if __THING_CONFIG[category] == nil then
            __THING_CONFIG[category] = {}
        end

        if __THING_CONFIG[category][thingId] == nil then
            __THING_CONFIG[category][thingId] = {}
        end

        local thingConfig = __THING_CONFIG[category][thingId]

        local methods = {
            set = function(self, id, config)
                local effect = AttachedEffectManager.get(id)
                if effect == nil then
                    g_logger.error('Invalid Static Effect ID(' .. id .. ')')
                    return
                end

                local __config = table.recursivecopy(effect.config)
                table.merge(__config, config)

                thingConfig[id] = __config

                local originalConfig = effect.config
                if config.onAttach then
                    __config.__onAttach = effect.config.onAttach
                end

                if config.onDetach then
                    __config.__onDetach = effect.config.onDetach
                end
            end
        }

        return methods
    end,
    getConfig = function(id, category, thingId)
        local config = __THING_CONFIG[category]
        if config then
            config = config[thingId]
            if config then
                config = config[id]
                if config then
                    return config
                end
            end
        end
        return __EFFECTS[id].config
    end,
    executeThingConfig = function(effect, category, thingId)
        executeConfig(effect, AttachedEffectManager.getConfig(effect:getId(), category, thingId))
    end,
    getDataThing = function(thing)
        if thing:isCreature() then
            return ThingCategoryCreature, thing:getOutfit().type
        end

        if thing:isItem() then
            return ThingCategoryItem, thing:getId()
        end

        return ThingInvalidCategory, 0
    end
}

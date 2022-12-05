local __EFFECTS = {}
local __THING_CONFIG = {}

local executeConfig = function(staticEffect, config)
    local x = 0
    local y = 0
    local onTop = false

    if config then
        if config.speed then
            staticEffect:setSpeed(config.speed)
        end

        if config.offset then
            x = config.offset[1] or 0
            y = config.offset[2] or 0
            onTop = config.offset[3] or false
        end

        if config.shader then
            staticEffect:setShader(g_shaders.getShader(config.shader))
        end

        staticEffect:setOffset(x, y)
        staticEffect:setOnTop(onTop)

        if config.dirOffset then
            for dir, offset in pairs(config.dirOffset) do
                local _x = offset[1] or x
                local _y = offset[2] or y
                local _onTop = offset[3] or onTop

                if type(x) == 'boolean' then -- onTop Config
                    staticEffect:setOnTopByDir(dir, _x)
                else
                    staticEffect:setDirOffset(dir, _x, _y, _onTop)
                end
            end
        end
    end

end

StaticEffectManager = {
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

        local staticEffect = StaticEffect.create(effect.id, effect.thingId, effect.thingCategory)
        executeConfig(staticEffect, effect.config)

        return staticEffect
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
                thingConfig[id] = config
                local effect = StaticEffectManager.get(id)
                if effect then
                    local originalConfig = effect.config
                    if config.onAdd then
                        originalConfig.__onAdd = originalConfig.onAdd
                        originalConfig.onAdd = config.onAdd
                    end

                    if config.onRemove then
                        originalConfig.__onRemove = originalConfig.onRemove
                        originalConfig.onRemove = config.onRemove
                    end
                end
            end
        }

        return methods
    end,
    executeThingConfig = function(effect, category, thingId)
        local config = __THING_CONFIG[category]
        if config then
            config = config[thingId]
            if config then
                config = config[effect:getId()]
                if config then
                    executeConfig(effect, config)
                    return
                end
            end
        end

        executeConfig(effect, __EFFECTS[effect:getId()].config)
    end
}

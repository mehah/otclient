local __EFFECTS = {}

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

        local x = 0
        local y = 0
        local onTop = false

        if effect.config then
            if effect.config.speed then
                staticEffect:setSpeed(effect.config.speed)
            end

            local config = effect.config
            if effect.config.offset then
                x = config.offset[1] or 0
                y = config.offset[2] or 0
                onTop = config.offset[3] or false

                staticEffect:setOffset(x, y)
                if onTop then
                    staticEffect:setOnTop(onTop)
                end
            end

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

        return staticEffect
    end
}

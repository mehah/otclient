local __OBJECTS = {}
local __THING_CONFIG = {}

local executeConfig = function(paperdoll, config)
    if not config then
        return
    end

    local x = 0
    local y = 0
    local onTop = config.onTop or true

    if config.speed then
        paperdoll:setSpeed(config.speed)
    end

    if config.drawOnUI == false then
        paperdoll:setCanDrawOnUI(false)
    end

    if config.shader then
        paperdoll:setShader(config.shader)
    end

    if config.priority then
        paperdoll:setPriority(config.priority)
    end

    if config.opacity ~= nil and config.opacity < 1.0 then
        paperdoll:setOpacity(config.opacity)
    end

    if config.onlyAddon then
        paperdoll:setOnlyAddon(config.onlyAddon)
    end

    if config.addon then
        paperdoll:setAddon(config.addon)
    end

    if config.size then
        paperdoll:setSize({
            width = config.size[1],
            height = config.size[2]
        })
    end

    if config.offset then
        x = config.offset[1] or 0
        y = config.offset[2] or 0
        onTop = config.offset[3] or false
    end

    if x ~= 0 or y ~= 0 then
        paperdoll:setOffset(x, y)
    end

    if onTop ~= nil then
        paperdoll:setOnTop(onTop)
    end

    if config.dirOffset then
        for dir, offset in pairs(config.dirOffset) do
            local _x = offset[1] or x
            local _y = offset[2] or y
            local _onTop = offset[3] or onTop

            if type(x) == 'boolean' then -- onTop Config
                paperdoll:setOnTopByDir(dir, _x)
            else
                paperdoll:setDirOffset(dir, _x, _y, _onTop)
            end
        end
    end
end

PaperdollManager = {
    get = function(id)
        return __OBJECTS[id]
    end,
    register = function(id, name, thingId, config)
        local paperdoll = g_paperdolls.register(id, thingId)
        if paperdoll == nil then
            return
        end

        executeConfig(paperdoll, config)
        config.isThingConfig = false

        __OBJECTS[id] = {
            id = id,
            name = name,
            thingId = thingId,
            config = config
        }
    end,
    registerThingConfig = function(thingId)
        if __THING_CONFIG[thingId] == nil then
            __THING_CONFIG[thingId] = {}
        end

        local thingConfig = __THING_CONFIG[thingId]

        local methods = {
            set = function(self, id, config)
                local paperdoll = PaperdollManager.get(id)
                if paperdoll == nil then
                    return
                end

                local __config = table.recursivecopy(paperdoll.config)
                table.merge(__config, config)

                thingConfig[id] = __config

                __config.isThingConfig = true
                if config.onAttach then
                    __config.__onAttach = paperdoll.config.onAttach
                end

                if config.onDetach then
                    __config.__onDetach = paperdoll.config.onDetach
                end
            end
        }

        return methods
    end,
    getConfig = function(id, thingId)
        local config = __THING_CONFIG[thingId]
        if config then
            config = config[id]
            if config then
                return config
            end
        end
        return __OBJECTS[id].config
    end,
    executeThingConfig = function(effect, thingId)
        executeConfig(effect, PaperdollManager.getConfig(effect:getId(), thingId))
    end
}

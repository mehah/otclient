local TypeEvent = {
    MODULE_INIT = 1,
    GAME_INIT = 2
}

local function onGameStart(self)
    if self.dataUI ~= nil and self.dataUI.onGameStart then
        self.ui = g_ui.loadUI('/' .. self.name .. '/' .. self.dataUI.name, self.dataUI.parent or g_ui.getRootWidget())
    end

    if self.__onGameStart ~= nil then
        self.currentTypeEvent = TypeEvent.GAME_INIT
        addEvent(function()
            self:__onGameStart()

            local eventList = self.events[TypeEvent.GAME_INIT]
            if eventList ~= nil then
                for _, event in pairs(eventList) do
                    event:connect()
                end
            end
        end)
    end
end

local function onGameEnd(self)
    if self.__onGameEnd ~= nil then
        self:__onGameEnd()
    end

    local eventList = self.events[TypeEvent.GAME_INIT]
    if eventList ~= nil then
        for _, event in pairs(eventList) do
            event:disconnect()
        end

        self.events[TypeEvent.GAME_INIT] = nil
    end

    if self.dataUI ~= nil and self.dataUI.onGameStart then
        self.ui:destroy()
        self.ui = nil
    end
end

Controller = {
    name = nil,
    events = nil,
    ui = nil,
    keyboardEvents = nil,
    attrs = nil,
    opcodes = nil,
    keyboardAnchor = nil
}

function Controller:new()
    local obj = {
        name = g_modules.getCurrentModule():getName(),
        currentTypeEvent = TypeEvent.MODULE_INIT,
        events = {},
        keyboardEvents = {},
        attrs = {},
        opcodes = {}
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Controller:init()
    if self.dataUI ~= nil and not self.dataUI.onGameStart then
        self.ui = g_ui.loadUI('/' .. self.name .. '/' .. self.dataUI.name, self.dataUI.parent or g_ui.getRootWidget())
    end

    if self.onInit then
        self.currentTypeEvent = TypeEvent.MODULE_INIT
        self:onInit()
    end

    self.__onGameStart = self.onGameStart
    self.onGameStart = function()
        onGameStart(self)
    end

    connect(g_game, {
        onGameStart = self.onGameStart
    })

    if g_game.isOnline() then
        self:onGameStart()
    end

    self.__onGameEnd = self.onGameEnd
    self.onGameEnd = function()
        onGameEnd(self)
    end

    connect(g_game, {
        onGameEnd = self.onGameEnd
    })

    local eventList = self.events[TypeEvent.MODULE_INIT]
    if eventList then
        for _, event in pairs(eventList) do
            event:connect()
        end
    end
end

function Controller:setKeyboardAnchor(widget)
    self.keyboardAnchor = widget
end

function Controller:setUI(name, parent, onGameStart)
    if type(parent) == "boolean" then
        onGameStart = parent
        parent = nil
    end

    self.dataUI = { name = name, parent = parent, onGameStart = onGameStart or false }
end

function Controller:terminate()
    if self.onTerminate then
        self:onTerminate()
    end

    if self.onGameStart then
        disconnect(g_game, { onGameStart = self.onGameStart })
    end

    if self.onGameEnd then
        if g_game.isOnline() then self:onGameEnd() end
        disconnect(g_game, { onGameEnd = self.onGameEnd })
    end

    for i, event in pairs(self.keyboardEvents) do
        g_keyboard['unbind' .. event.name](event.args[1], event.args[2], event.args[3])
    end

    for i, opcode in pairs(self.opcodes) do
        ProtocolGame.unregisterExtendedOpcode(opcode)
    end

    for type, events in pairs(self.events) do
        if events ~= nil then
            for _, event in pairs(events) do
                event:disconnect()
            end
        end
    end

    if self.ui ~= nil then
        self.ui:destroy()
    end

    self.events = nil
    self.dataUI = nil
    self.ui = nil
    self.keyboardEvents = nil
    self.attrs = nil
    self.opcodes = nil
    self.keyboardAnchor = nil
    self.__onGameStart = nil
    self.__onGameEnd = nil
end

--[[
    If you register an event in onInit() or in the general scope of the script,
    the event will be automatically registered at startup and disconnected when the module is destroyed.
    If it is inside onGameStart(), the events will be connected when entering the game map and disconnected when leaving and also when the module is destroyed.
]]
function Controller:registerEvents(actor, events)
    if self.events[self.currentTypeEvent] == nil then
        self.events[self.currentTypeEvent] = {}
    end

    local evt = EventController:new(actor, events)
    table.insert(self.events[self.currentTypeEvent], evt)

    return evt
end

function Controller:registerExtendedOpcode(opcode, fnc)
    ProtocolGame.registerExtendedOpcode(opcode, fnc)
    table.insert(self.opcodes, opcode)
end

function Controller:sendExtendedOpcode(opcode, ...)
    local protocol = g_game.getProtocolGame()
    if protocol then
        protocol:sendExtendedOpcode(opcode, ...)
    end
end

function Controller:bindKeyDown(...)
    local args = { ... }
    if args[3] == nil or type(args[3]) == 'boolean' then
        args[4] = args[3]
        args[3] = self.keyboardAnchor
    end
    table.insert(self.keyboardEvents, {
        name = 'KeyDown',
        args = args
    })
    g_keyboard.bindKeyDown(args[1], args[2], args[3])
end

function Controller:bindKeyUp(...)
    local args = { ... }
    if args[3] == nil or type(args[3]) == 'boolean' then
        args[4] = args[3]
        args[3] = self.keyboardAnchor
    end
    table.insert(self.keyboardEvents, {
        name = 'KeyUp',
        args = args
    })

    g_keyboard.bindKeyUp(args[1], args[2], args[3])
end

function Controller:bindKeyPress(...)
    local args = { ... }
    if args[3] == nil or type(args[3]) == 'boolean' then
        args[4] = args[3]
        args[3] = self.keyboardAnchor
    end
    table.insert(self.keyboardEvents, {
        name = 'KeyPress',
        args = args
    })
    g_keyboard.bindKeyPress(args[1], args[2], args[3])
end

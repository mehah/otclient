local TypeEvent = {
    MODULE_INIT = 1,
    GAME_INIT = 2
}

local function onGameStart(self)
    if self.dataUI ~= nil and self.dataUI.onGameStart then
        self.ui = g_ui.loadUI('/' .. self.name .. '/' .. self.dataUI.name, g_ui.getRootWidget())
    end

    if self.__onGameStart ~= nil then
        self.currentTypeEvent = TypeEvent.GAME_INIT
        addEvent(function()
            self:__onGameStart()
        end)
    end

    local eventList = self.events[TypeEvent.GAME_INIT]
    if eventList ~= nil then
        for actor, events in pairs(eventList) do
            connect(actor, events)
        end
    end
end

local function onGameEnd(self)
    if self.__onGameEnd ~= nil then
        self:__onGameEnd()
    end

    local eventList = self.events[TypeEvent.GAME_INIT]
    if eventList ~= nil then
        for actor, events in pairs(eventList) do
            disconnect(actor, events)
        end
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
    externalEvents = nil,
    keyboardEvents = nil,
    attrs = nil,
    opcodes = nil
}

function Controller:new()
    local obj = {
        name = g_modules.getCurrentModule():getName(),
        currentTypeEvent = TypeEvent.MODULE_INIT,
        events = {},
        externalEvents = {},
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
        self.ui = g_ui.loadUI('/' .. self.name .. '/' .. self.dataUI.name, g_ui.getRootWidget())
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

    self:connectExternalEvents()

    local eventList = self.events[TypeEvent.MODULE_INIT]
    if eventList ~= nil then
        for actor, events in pairs(eventList) do
            connect(actor, events)
        end
    end
end

function Controller:setUI(name, onGameStart)
    self.dataUI = { name = name, onGameStart = onGameStart or false }
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
        g_keyboard['unbind' .. event.name](event.args)
    end

    for i, opcode in pairs(self.opcodes) do
        ProtocolGame.unregisterExtendedOpcode(opcode)
    end

    self:disconnectExternalEvents()

    local eventList = self.events[TypeEvent.MODULE_INIT]
    if eventList ~= nil then
        for actor, events in pairs(eventList) do
            disconnect(actor, events)
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
    self.externalEvents = nil
    self.__onGameStart = nil
    self.__onGameEnd = nil
end

function Controller:addEvent(actor, events)
    local evt = EventController:new(actor, events)
    table.insert(self.externalEvents, evt)
    return evt
end

function Controller:attachExternalEvent(event)
    table.insert(self.externalEvents, event)
end

function Controller:connectExternalEvents()
    for i, event in pairs(self.externalEvents) do
        event:connect()
    end
end

function Controller:disconnectExternalEvents()
    for i, event in pairs(self.externalEvents) do
        event:disconnect()
    end
end

function Controller:registerEvents(actor, events)
    if self.events[self.currentTypeEvent] == nil then
        self.events[self.currentTypeEvent] = {}
    end

    self.events[self.currentTypeEvent][actor] = events
end

function Controller:connectEvents(actor, events)
    if type(actor) == 'table' then
        for _, target in pairs(actor) do
            self:connectEvents(target, events)
        end
        return
    end

    if not events then
        events = self.events[actor]
    else
        self.events[actor] = events
    end

    assert(events ~= nil, 'Events are empty')
    connect(actor, events)
end

function Controller:disconnectEvents(actor, destroy)
    if type(actor) == 'table' then
        for _, target in pairs(actor) do
            self:disconnectEvents(target, destroy)
        end
        return
    end

    local events = self.events[actor]
    if events then
        disconnect(actor, events)
        if destroy ~= false then
            self.events[actor] = nil
        end
    end
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
    table.insert(self.keyboardEvents, {
        name = 'KeyDown',
        args = ...
    })
    g_keyboard.bindKeyDown(...)
end

function Controller:bindKeyUp(...)
    table.insert(self.keyboardEvents, {
        name = 'KeyUp',
        args = ...
    })
    g_keyboard.bindKeyUp(...)
end

function Controller:bindKeyPress(...)
    table.insert(self.keyboardEvents, {
        name = 'KeyPress',
        args = ...
    })
    g_keyboard.bindKeyPress(...)
end

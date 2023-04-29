Controller = {
    name = nil,
    events = nil,
    ui = nil,
    externalEvents = nil,
    keyboardEvents = nil,
    attributes = nil,
    opcodes = nil
}

function Controller:new()
    local obj = {
        name = g_modules.getCurrentModule():getName(),
        events = {},
        externalEvents = {},
        keyboardEvents = {},
        attributes = {},
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
        self:onInit()
    end

    if self.onGameStart then
        self.__onGameStart = self.onGameStart

        self.onGameStart = function()
            if self.dataUI ~= nil and self.dataUI.onGameStart then
                self.ui = g_ui.loadUI('/' .. self.name .. '/' .. self.dataUI.name, g_ui.getRootWidget())
            end

            if self.__onGameStart ~= nil then
                self:__onGameStart()
            end

            for actor, events in pairs(self.events) do
                connect(actor, events)
            end
        end

        if g_game.isOnline() then
            self:onGameStart()
        end

        self.__onGameStartEvet = function()
            self:onGameStart()
        end
        connect(g_game, {
            onGameStart = self.__onGameStartEvet
        })
    end

    if self.onGameStart then
        self.__onGameEndEvet = function()
            self:onGameEnd()
        end
        connect(g_game, {
            onGameEnd = self.__onGameEndEvet
        })
    end

    self:connectExternalEvents()
end

function Controller:setUI(name, onGameStart)
    self.dataUI = { name = name, onGameStart = onGameStart or false }
end

function Controller:terminate()
    if self.onTerminate then
        self:onTerminate(self)
    end

    if self.onGameStart then
        disconnect(g_game, { onGameStart = self.__onGameStartEvet })
    end

    if self.onGameEnd then
        if g_game.isOnline() then
            self:onGameEnd()
        end
        disconnect(g_game, { onGameEnd = self.__onGameEndEvet })
    end

    for actor, events in pairs(self.events) do
        disconnect(actor, events)
    end

    for i, event in pairs(self.keyboardEvents) do
        g_keyboard['unbind' .. event.name](event.args)
    end

    for i, opcode in pairs(self.opcodes) do
        ProtocolGame.unregisterExtendedOpcode(opcode)
    end

    self:disconnectExternalEvents()

    for actor, events in pairs(self.events) do
        disconnect(actor, events)
    end

    if self.ui ~= nil then
        self.ui:destroy()
    end

    self.events = nil
    self.dataUI = nil
    self.ui = nil
    self.keyboardEvents = nil
    self.attributes = nil
    self.opcodes = nil
    self.externalEvents = nil
    self.__onGameStartEvet = nil
    self.__onGameEndEvet = nil
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
    self.events[actor] = events
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

function Controller:setAttribute(name, value)
    self.attributes[name] = value
end

function Controller:getAttribute(name)
    return self.attributes[name]
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

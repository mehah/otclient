local TypeEvent = {
    MODULE_INIT = 1,
    GAME_INIT = 2
}

local function onGameStart(self)
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
            event:destroy()
        end

        self.events[TypeEvent.GAME_INIT] = nil
    end

    local scheduledEventsList = self.scheduledEvents and self.scheduledEvents[TypeEvent.GAME_INIT]
    if scheduledEventsList then
        for _, eventId in pairs(scheduledEventsList) do
            removeEvent(eventId)
        end

        if self.scheduledEvents then
            self.scheduledEvents[TypeEvent.GAME_INIT] = nil
        end
    end

    if self.dataUI ~= nil and self.dataUI.onGameStart and self.ui then
        self:destroyUI()
    end

    table.remove_if(self.keyboardEvents, function(i, event)
        local destroy = event.controllerEventType == TypeEvent.GAME_INIT
        if destroy then
            g_keyboard['unbind' .. event.name](event.args[1], event.args[2], event.args[3])
        end
        return destroy
    end)
end

Controller = {
    ui = nil,
    name = nil,
    attrs = nil,
    extendedOpcodes = nil,
    opcodes = nil,
    events = nil,
    uiEvents = nil,
    htmlId = nil,
    keyboardAnchor = nil,
    scheduledEvents = nil,
    keyboardEvents = nil
}

if not G_CONTROLLER_CALLED then
    G_CONTROLLER_CALLED = {}
end

function Controller:new()
    local module = g_modules.getCurrentModule()
    local obj = {
        name = module and module:getName() or nil,
        currentTypeEvent = TypeEvent.MODULE_INIT,
        events = {},
        uiEvents = {},
        scheduledEvents = {},
        keyboardEvents = {},
        attrs = {},
        extendedOpcodes = {},
        opcodes = {},
    }
    setmetatable(obj, self)
    self.__index = self

    if obj.name then
        G_CONTROLLER_CALLED[obj.name] = obj
    end

    return obj
end

function Controller:init()
    if self.dataUI ~= nil then
        self:loadUI()
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

function Controller:loadHtml(path, parent)
    local suffix = ".html"
    if path:sub(- #suffix) ~= suffix then
        path = path .. suffix
    end

    self:setUI(path, parent)
    self.htmlId = g_html.load(self.name, path, g_ui.getRootWidget())
    self.ui = g_html.getRootWidget(self.htmlId);
end

function Controller:unloadHtml()
    if self.htmlId == nil then
        error('HTML unload operation failed: no HTML was previously loaded.')
        return
    end

    self:destroyUI()
end

function Controller:destroyUI()
    if self.htmlId ~= nil then
        g_html.destroy(self.htmlId)
        self.ui = nil
    end

    if self.ui then
        self.ui:destroy()
        self.ui = nil
    end

    for _, event in pairs(self.uiEvents) do
        event:destroy()
    end

    self.uiEvents = {}
    WidgetWatch.update() -- Prevent warnings from stale widget references in the watch list.
end

function Controller:findWidget(query)
    return self.ui and self.ui:querySelector(query:trim())
end

function Controller:findWidgets(query)
    return self.ui and self.ui:querySelectorAll(query:trim())
end

function Controller:createWidgetFromHTML(html, parent)
    local widget = g_html.createWidgetFromHTML(html, parent, self.htmlId)
    return widget
end

function Controller:loadUI(name, parent)
    if self.ui then
        return
    end

    if not self.dataUI then
        self:setUI(name, parent)
    end

    self.ui = g_ui.loadUI('/' .. self.name .. '/' .. self.dataUI.name, self.dataUI.parent or g_ui.getRootWidget())
end

function Controller:setKeyboardAnchor(widget)
    self.keyboardAnchor = widget
end

function Controller:setUI(name, parent)
    self.dataUI = { name = name, parent = parent, onGameStart = self.currentTypeEvent == TypeEvent.GAME_INIT }
end

function Controller:terminate()
    if self.onGameStart then
        disconnect(g_game, { onGameStart = self.onGameStart })
    end

    if self.onGameEnd then
        if g_game.isOnline() then self:onGameEnd() end
        disconnect(g_game, { onGameEnd = self.onGameEnd })
    end

    if self.onTerminate then
        self:onTerminate()
    end

    for i, event in pairs(self.keyboardEvents) do
        g_keyboard['unbind' .. event.name](event.args[1], event.args[2], event.args[3])
    end

    for i, opcode in pairs(self.extendedOpcodes) do
        ProtocolGame.unregisterExtendedOpcode(opcode)
    end

    for _, opcode in ipairs(self.opcodes) do
        ProtocolGame.unregisterOpcode(opcode)
    end

    for type, events in pairs(self.events) do
        if events ~= nil then
            for _, event in pairs(events) do
                event:destroy()
            end
        end
    end

    for type, events in pairs(self.scheduledEvents or {}) do
        if events ~= nil then
            for _, eventId in pairs(events) do
                removeEvent(eventId)
            end
        end
    end

    if self.ui ~= nil then
        self:destroyUI()
    end

    self.ui = nil
    self.attrs = nil
    self.events = nil
    self.dataUI = nil
    self.extendedOpcodes = nil
    self.opcodes = nil
    self.keyboardEvents = nil
    self.keyboardAnchor = nil
    self.scheduledEvents = nil
    self.htmlId = nil

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

function Controller:registerUIEvents(actor, events)
    local evt = EventController:new(actor, events)
    table.insert(self.uiEvents, evt)

    -- fix html lazy loading
    if actor and actor.isOnHtml and actor:isOnHtml() then
        evt:connect()
    end

    return evt
end

function Controller:checkWidgetsDestroyed()
    table.remove_if(self.uiEvents, function(i, e)
        if e:actorIsDestroyed() then
            e:disconnect()
            return true
        end

        return false
    end)
end

function Controller:registerExtendedOpcode(opcode, fnc)
    ProtocolGame.registerExtendedOpcode(opcode, fnc)
    table.insert(self.extendedOpcodes, opcode)
end

function Controller:registerOpcode(opcode, fnc)
    ProtocolGame.registerOpcode(opcode, fnc)
    table.insert(self.opcodes, opcode)
end

function Controller:sendExtendedOpcode(opcode, ...)
    local protocol = g_game.getProtocolGame()
    if protocol then
        protocol:sendExtendedOpcode(opcode, ...)
    end
end

local function registerScheduledEvent(controller, fncRef, fnc, delay, name)
    local currentType = controller.currentTypeEvent
    controller.scheduledEvents = controller.scheduledEvents or {}
    if controller.scheduledEvents[currentType] == nil then
        controller.scheduledEvents[currentType] = {}
    end

    local _rmvEvent = function()
        if not controller.scheduledEvents then return end
        local list = controller.scheduledEvents[currentType]
        if not list then return end
        if name and list[name] then
            removeEvent(list[name])
            list[name] = nil
        end
    end
    _rmvEvent()

    local evt = nil
    local action = function()
        local res = fnc()

        if fncRef == scheduleEvent then
            if name then
                _rmvEvent()
            else
                if controller.scheduledEvents and controller.scheduledEvents[currentType] then
                    table.removevalue(controller.scheduledEvents[currentType], evt)
                end
            end
        elseif res == false then
            removeEvent(evt)
        end
    end

    evt = fncRef(action, delay)

    if name then
        if controller.scheduledEvents then
            controller.scheduledEvents[currentType][name] = evt
        end
    else
        if controller.scheduledEvents and controller.scheduledEvents[currentType] then
            table.insert(controller.scheduledEvents[currentType], evt)
        end
    end

    return evt
end

function Controller:scheduleEvent(fnc, delay, name)
    return registerScheduledEvent(self, scheduleEvent, fnc, delay, name)
end

function Controller:cycleEvent(fnc, delay, name)
    return registerScheduledEvent(self, cycleEvent, fnc, delay, name)
end

function Controller:removeEvent(evt)
    if self.scheduledEvents[TypeEvent.GAME_INIT] then
        if table.removevalue(self.scheduledEvents[TypeEvent.GAME_INIT], evt) then
            removeEvent(evt)
            return
        end
    end

    if self.scheduledEvents[TypeEvent.MODULE_INIT] then
        if table.find(self.scheduledEvents[TypeEvent.MODULE_INIT], evt) then
            error('It is not possible to remove events registered at controller init.')
            return
        end
    end

    error('The event was not registered by the controller.')
end

function Controller:bindKeyDown(...)
    local args = { ... }
    if args[3] == nil or type(args[3]) == 'boolean' then
        args[4] = args[3]
        args[3] = self.keyboardAnchor
    end
    table.insert(self.keyboardEvents, {
        name = 'KeyDown',
        args = args,
        controllerEventType = self.currentTypeEvent
    })
    g_keyboard.bindKeyDown(args[1], args[2], args[3], args[4])
end

function Controller:bindKeyUp(...)
    local args = { ... }
    if args[3] == nil or type(args[3]) == 'boolean' then
        args[4] = args[3]
        args[3] = self.keyboardAnchor
    end
    table.insert(self.keyboardEvents, {
        name = 'KeyUp',
        args = args,
        controllerEventType = self.currentTypeEvent
    })

    g_keyboard.bindKeyUp(args[1], args[2], args[3], args[4])
end

function Controller:bindKeyPress(...)
    local args = { ... }
    if args[3] == nil or type(args[3]) == 'boolean' then
        args[4] = args[3]
        args[3] = self.keyboardAnchor
    end
    table.insert(self.keyboardEvents, {
        name = 'KeyPress',
        args = args,
        controllerEventType = self.currentTypeEvent
    })
    g_keyboard.bindKeyPress(args[1], args[2], args[3])
end

-- @docclass UIWidget
function UIWidget:setMargin(...)
    local params = { ... }
    if #params == 1 then
        self:setMarginTop(params[1])
        self:setMarginRight(params[1])
        self:setMarginBottom(params[1])
        self:setMarginLeft(params[1])
    elseif #params == 2 then
        self:setMarginTop(params[1])
        self:setMarginRight(params[2])
        self:setMarginBottom(params[1])
        self:setMarginLeft(params[2])
    elseif #params == 4 then
        self:setMarginTop(params[1])
        self:setMarginRight(params[2])
        self:setMarginBottom(params[3])
        self:setMarginLeft(params[4])
    end
end

function UIWidget:parseColoredText(text, default_color)
    default_color = default_color or "#ffffff"
    local result, last_pos = "", 1
    for start, stop in text:gmatch("()%[color=#?%x+%]()") do
        if start > last_pos then
            result = result .. "{" .. text:sub(last_pos, start - 1) .. ", " .. default_color .. "}"
        end
        local closing_tag_start = text:find("%[/color%]", stop)
        if not closing_tag_start then break end
        local content = text:sub(stop, closing_tag_start - 1)
        local color = text:match("#%x+", start) or default_color
        result = result .. "{" .. content .. ", " .. color .. "}"
        last_pos = closing_tag_start + 8
    end
    if last_pos <= #text then
        result = result .. "{" .. text:sub(last_pos) .. ", " .. default_color .. "}"
    end
    self:setColoredText(result)
end

local WATCH_LIST = {}
local WATCH_CYCLE_CHECK_MS = 50
local WATCH_EVENT = nil

local function START_WATCH_LIST()
    if WATCH_EVENT ~= nil or #WATCH_LIST == 0 then
        return
    end

    WATCH_EVENT = cycleEvent(function()
        table.remove_if(WATCH_LIST, function(i, obj)
            local isDestroyed = obj.widget:isDestroyed()
            if isDestroyed then
                obj.widget = nil
            else
                obj.fnc(obj)
            end

            return isDestroyed
        end)

        if #WATCH_LIST == 0 then
            removeEvent(WATCH_EVENT)
            WATCH_EVENT = nil
        end
    end, WATCH_CYCLE_CHECK_MS)
end

function UIWidget:__applyOrBindHtmlAttribute(attr, value)
    local controller = G_CONTROLLER_CALLED

    if attr == 'image-source' then
        value = '/modules/' .. controller.name .. '/' .. value
    end

    local setterName = ''
    for _, _name in pairs(attr:trim():split('-')) do
        setterName = setterName .. _name:gsub("^%l", string.upper)
    end

    local watchObj = nil

    local isBinding = setterName:starts('*')
    if isBinding then
        setterName = setterName:sub(2):gsub("^%l", string.upper)

        local vStr = value
        local f = loadstring('return function(self, target) return ' .. vStr .. ' end')
        local fnc = f()
        value = fnc(controller)

        watchObj = {
            widget = self,
            res = value,
            method = nil,
            fnc = function(self)
                local value = fnc(controller, self.widget)
                if value ~= self.res then
                    self.method(self.widget, value)
                    self.res = value
                end
            end
        }
    elseif value == '' or value == 'true' or value == setterName then
        value = true
    elseif value == 'false' then
        value = false
    end

    value = tonumber(value) or toboolean(value) or value

    local method = self['set' .. setterName]
    if method then
        method(self, value)

        if watchObj then
            watchObj.method = method
            table.insert(WATCH_LIST, watchObj)
            START_WATCH_LIST()
        end
    else
        local _name = string.sub(setterName, 1, 1):lower() .. string.sub(setterName, 2, -1)
        self[_name] = value
    end
end

local EVENTS_TRANSLATED = {
    onstyleapply     = 'onStyleApply',
    ondestroy        = 'onDestroy',
    onidchange       = 'onIdChange',
    onwidthchange    = 'onWidthChange',
    onheightchange   = 'onHeightChange',
    onresize         = 'onResize',
    onenabled        = 'onEnabled',
    onpropertychange = 'onPropertyChange',
    ongeometrychange = 'onGeometryChange',
    onlayoutupdate   = 'onLayoutUpdate',
    onfocus          = 'onFocusChange',
    onchildfocus     = 'onChildFocusChange',
    onhover          = 'onHoverChange',
    onvisibility     = 'onVisibilityChange',
    ondragenter      = 'onDragEnter',
    ondragleave      = 'onDragLeave',
    ondragmove       = 'onDragMove',
    ondrop           = 'onDrop',
    onkeytext        = 'onKeyText',
    onkeydown        = 'onKeyDown',
    onkeypress       = 'onKeyPress',
    onkeyup          = 'onKeyUp',
    onmousepress     = 'onMousePress',
    onmouserelease   = 'onMouseRelease',
    onmousemove      = 'onMouseMove',
    onmousewheel     = 'onMouseWheel',
    onclick          = 'onClick',
    ondoubleclick    = 'onDoubleClick',
    oncreate         = 'onCreate',
    onsetup          = 'onSetup',
    ontextareaupdate = 'onTextAreaUpdate',
    onfontchange     = 'onFontChange',
    ontextchange     = 'onTextChange',
    onescape         = 'onEscape',
}

local parseEvents = function(widget, eventName, callStr, controller)
    local eventCall = loadstring('return function(self, event, target) ' .. callStr .. ' end')()
    local event = { target = widget }
    local function execEventCall()
        eventCall(controller, event, widget)
    end

    if eventName == 'onchange' then
        if widget.__class == 'UIComboBox' then
            controller:registerEvents(widget, {
                onOptionChange = function(widget, text, data)
                    event.name = 'onOptionChange'
                    event.text = text
                    event.data = data
                    execEventCall()
                end
            })
        elseif widget.__class == 'UIRadioGroup' then
            controller:registerEvents(widget, {
                onSelectionChange = function(widget, selectedWidget, previousSelectedWidget)
                    event.name = 'onSelectionChange'
                    event.selectedWidget = selectedWidget
                    event.previousSelectedWidget = previousSelectedWidget
                    execEventCall()
                end
            })
        elseif widget.__class == 'UICheckBox' then
            controller:registerEvents(widget, {
                onCheckChange = function(widget, checked)
                    event.name = 'onCheckChange'
                    event.checked = checked
                    execEventCall()
                end
            })
        elseif widget.__class == 'UIScrollBar' then
            controller:registerEvents(widget, {
                onValueChange = function(widget, value, delta)
                    event.name = 'onValueChange'
                    event.value = value
                    event.delta = delta
                    execEventCall()
                end
            })
        elseif widget.setValue then
            controller:registerEvents(widget, {
                onValueChange = function(widget, value)
                    event.name = 'onValueChange'
                    event.value = value
                    execEventCall()
                end
            })
        else
            controller:registerEvents(widget, {
                onTextChange = function(widget, value)
                    event.name = 'onTextChange'
                    event.value = value
                    execEventCall()
                end
            })
        end

        return
    end

    local trEventName = EVENTS_TRANSLATED[eventName]
    if not trEventName then
        pwarning('[' .. HTML_PATH .. ']:' .. el.name .. ' Event ' .. eventName .. ' does not exist.')
        return
    end

    local data = {}
    data[trEventName] = function(widget, value)
        event.name = trEventName
        event.value = value
        execEventCall()
    end

    controller:registerEvents(widget, data)
end

function UIWidget:onCreateByHTML(attrs)
    local controller = G_CONTROLLER_CALLED
    for attr, v in pairs(attrs) do
        if attr:starts('on') then
            parseEvents(self, attr:lower(), v, controller)
            return
        end
    end

    local getFncSet = function(exp)
        local f = loadstring('return function(self, value) ' .. exp .. '=value end')
        return f and f() or nil
    end

    if attrs['*checked'] then
        local set = getFncSet(attrs['*checked'])
        if set then
            controller:registerEvents(self, {
                onCheckChange = function(widget, value)
                    set(controller, value)
                end
            })
        end
    end

    if attrs['*value'] then
        local set = getFncSet(attrs['*value'])
        if set then
            if self.getCurrentOption then
                controller:registerEvents(self, {
                    onOptionChange = function(widget, text, data)
                        set(controller, data)
                    end
                })
            else
                controller:registerEvents(self, {
                    onTextChange = function(widget, value)
                        set(controller, value)
                    end
                })
            end
        end
    end
end

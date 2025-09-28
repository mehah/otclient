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

function UIWidget:setTitle(title)
    self:setText(title)
    self:setTextAlign(AlignTopCenter)
    self:setColor("#c0c0c0")
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

local function ExprHandlerError(runtime, error, widget, controller, nodeStr, onError)
    if runtime then
        error = "[Script runtime error]\n" .. error
    end
    if onError then error = error .. '\n' .. onError() end
    error = error .. '\nWidget[#' .. widget:getId() .. ']:\n\n' .. nodeStr
    pwarning(error .. "\n\n------------------------------------")
end

local function getFncByExpr(exp, nodeStr, widget, controller, onError)
    local f, syntaxErr = loadstring(exp,
        ("Controller: %s | %s"):format(controller.name, controller.dataUI.name))

    if not f then
        ExprHandlerError(false, syntaxErr, widget, controller, nodeStr, onError)
        return
    end

    return f()
end

local function execFnc(f, args, widget, controller, nodeStr, onError)
    if not f or not args then
        return
    end

    local success, value = xpcall(function()
        return f(unpack(args))
    end, function(e) return "Erro: " .. tostring(e) end)

    if not success then
        ExprHandlerError(true, value, widget, controller, nodeStr, onError)
    end

    return value, success
end

function UIWidget:__applyOrBindHtmlAttribute(attr, value, controllerName, NODE_STR)
    local controller = G_CONTROLLER_CALLED[controllerName]

    if attr == 'image-source' then
        if not value:starts('/') and not value:starts('base64:') then
            value = '/modules/' .. controller.name .. '/' .. value
        end
    end

    local setterName = ''
    for _, _name in pairs(attr:trim():split('-')) do
        setterName = setterName .. _name:gsub("^%l", string.upper)
    end

    local watchObj = nil

    local isBinding = setterName:starts('*')
    if isBinding then
        setterName = setterName:sub(2):gsub("^%l", string.upper)

        local success = false
        local fnc = getFncByExpr('return function(self, target) return ' .. value .. ' end',
            NODE_STR, self, controller, function()
                return ('Attribute Error[%s]: %s'):format(attr, value)
            end)

        value, success = execFnc(fnc, { controller }, self, controller, NODE_STR, function()
            return ('Attribute Error[%s]: %s'):format(attr, value)
        end)

        if not success then return end

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
    else
        value = tonumber(value) or toboolean(value) or value
    end

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

local parseEvents = function(widget, eventName, callStr, controller, NODE_STR)
    local fnc = getFncByExpr('return function(self, event, target) ' .. callStr .. ' end',
        NODE_STR, widget, controller, function()
            return ('Event Error[%s]: %s'):format(eventName, callStr)
        end)

    local event = { target = widget }
    local function execEventCall()
        execFnc(fnc, { controller, event, widget }, widget, controller, NODE_STR, function()
            return ('Event Error[%s]: %s'):format(eventName, callStr)
        end)
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
        pwarning('[' .. controller.dataUI.name .. ']:' .. widget:getId() .. ' Event ' .. eventName .. ' does not exist.')
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

function UIWidget:onCreateByHTML(attrs, controllerName, NODE_STR)
    local controller = G_CONTROLLER_CALLED[controllerName]
    for attr, v in pairs(attrs) do
        if attr:starts('on') then
            parseEvents(self, attr:lower(), v, controller, NODE_STR)
        end
    end

    local getFncSet = function(attrName)
        local exp = attrs[attrName]
        return getFncByExpr('return function(self, value, target) ' .. exp .. '=value end',
            NODE_STR, self, controller, function()
                return ('Attribute error[%s]: %s'):format(attrName, exp)
            end)
    end

    local attrName = '*checked'
    if attrs[attrName] then
        local set = getFncSet(attrName)
        if set then
            controller:registerEvents(self, {
                onCheckChange = function(widget, value)
                    execFnc(set, { controller, value, widget }, self, controller, NODE_STR, function()
                        return ('Attribute error[%s]: %s'):format(attrName, attrs[attrName])
                    end)
                end
            })
        end
    end

    attrName = '*value'
    if attrs['*value'] then
        local set = getFncSet(attrName)
        if set then
            if self.getCurrentOption then
                controller:registerEvents(self, {
                    onOptionChange = function(widget, text, data)
                        execFnc(set, { controller, data, widget }, self, controller, NODE_STR, function()
                            return ('Attribute error[%s]: %s'):format(attrName, attrs[attrName])
                        end)
                    end
                })
            else
                controller:registerEvents(self, {
                    onTextChange = function(widget, value)
                        execFnc(set, { controller, value, widget }, self, controller, NODE_STR, function()
                            return ('Attribute error[%s]: %s'):format(attrName, attrs[attrName])
                        end)
                    end
                })
            end
        end
    end
end

function UIWidget:__scriptHtml(moduleName, script, NODE_STR)
    local controller = G_CONTROLLER_CALLED[moduleName]
    local fnc = getFncByExpr('return function(self) ' .. script .. ' end',
        NODE_STR, self, controller)

    execFnc(fnc, { controller }, self, controller, NODE_STR)
end

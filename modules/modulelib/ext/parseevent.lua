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

local parseEvents = function(el, widget, eventName, callStr, controller)
    local eventCall = loadstring('return function(self, event) ' .. callStr .. ' end')()
    local event = { target = widget }
    local function execEventCall()
        eventCall(controller, event)
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

local onCreateWidget = function(el, widget, controller)
    local getFncSet = function(exp)
        local f = loadstring('return function(self, value) ' .. exp .. '=value end')
        return f and f() or nil
    end

    if el.attributes['*checked'] then
        local set = getFncSet(el.attributes['*checked'])
        if set then
            controller:registerEvents(widget, {
                onCheckChange = function(widget, value)
                    set(controller, value)
                end
            })
        end
    end

    if el.attributes['*value'] then
        local set = getFncSet(el.attributes['*value'])
        if set then
            if widget.getCurrentOption then
                controller:registerEvents(widget, {
                    onOptionChange = function(widget, text, data)
                        set(controller, data)
                    end
                })
            else
                controller:registerEvents(widget, {
                    onTextChange = function(widget, value)
                        set(controller, value)
                    end
                })
            end
        end
    end
end

local function setText(el, text)
    if text then
        local whiteSpace = el.style and el.style['white-space'] or 'nowrap'
        el.widget:setTextWrap(true)
        if whiteSpace == 'normal' then
            text = text:trim()
        elseif whiteSpace == 'nowrap' then
            text = text:gsub("  ", ""):gsub("[\n\r\t]", " ")
            el.widget:setTextWrap(false)
        elseif whiteSpace == 'pre' then
            el.widget:setTextWrap(false)
        end

        el.widget:setText(text)
    end
end

local createRadioGroup = function(el, groups, controller)
    local name = el.attributes.name
    if not name then
        return
    end

    if not groups[name] then
        groups[name] = UIRadioGroup.create()
    end

    groups[name]:addWidget(el.widget)
end

local function afterLoadElement(el)
    if el.name == 'hr' then
        if el.widget:hasAnchoredLayout() then
            el.widget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
            el.widget:addAnchor(AnchorRight, 'parent', AnchorRight)
        end
    end

    if #el.nodes == 0 then
        setText(el, el:getcontent())
    end
end

return parseEvents, onCreateWidget, setText, createRadioGroup, afterLoadElement

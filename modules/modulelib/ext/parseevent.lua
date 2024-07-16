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
}

local parseEvents = function(el, widget, eventName, callStr, controller)
    local event = { target = widget }
    local function execEventCall()
        local f = loadstring('return function(self, event) ' .. callStr .. ' end')
        f()(controller, event)
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
        else
            controller:registerEvents(widget, {
                onValueChange = function(widget, value)
                    event.name = 'onValueChange'
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

local registerActionEvents = function(el, widget, controller)
    if el.attributes['*value'] then
        local exp = el.attributes['*value']

        local f = loadstring('return function(self, value) ' .. exp .. '=value end')
        f = f()

        controller:registerEvents(widget, {
            onTextChange = function(widget, value)
                f(controller, value)
            end
        })
    end
end

return parseEvents, registerActionEvents

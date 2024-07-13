local OFICIAL_HTML_CSS = {}

local function parseStyleElement(content, cssList)
    local css = CssParse.new()
    css:parse(content)
    local data = css:get_objects()

    for _, o in ipairs(data) do
        table.insert(cssList, {
            selector = o.selector:trim(), attrs = o.declarations
        })
    end
end

parseStyleElement(g_resources.readFileContents('html.css'), OFICIAL_HTML_CSS)

local function displayBlock(widget)
    if widget:getAnchoredLayout() then
        widget:addAnchor(AnchorLeft, 'prev', AnchorLeft)
        widget:addAnchor(AnchorTop, 'prev', AnchorBottom)
    end
end

local function displayInline(widget, anchor)
    widget:addAnchor(AnchorLeft, anchor, AnchorRight)
    widget:addAnchor(AnchorTop, anchor, AnchorTop)
end

local parseAttrPropList = function(str)
    local obj = {}
    for _, style_v in pairs(str:split(';')) do
        local attr = style_v:split(':')
        local name = attr[1]
        local value = attr[2]:trim()
        value = tonumber(value) or value
        obj[name:trim()] = value
    end
    return obj
end

local parseStyle = function(widget, el)
    local style = parseAttrPropList(el.attributes.style)
    widget:mergeStyle(style)
    el.style = style

    if el.style.display == 'none' then
        widget:setVisible(false)
    end
end



local parseLayout = function(widget, el)
    local layout = parseAttrPropList(el.attributes.layout)
    widget:mergeStyle({ layout = layout })
end


local parseEvents = function(widget, eventName, callStr, controller)
    local event = { target = widget }
    local function execEventCall()
        local f = loadstring('return function(self, event) ' .. callStr .. ' end')
        f()(controller, event)
    end

    if eventName == 'onchange' then
        if widget.__class == 'UIComboBox' then
            widget.onOptionChange = function(widget, text, data)
                event.name = 'onOptionChange'
                event.text = text
                event.data = data
                execEventCall()
            end
        elseif widget.__class == 'UIRadioGroup' then
            widget.onSelectionChange = function(widget, selectedWidget, previousSelectedWidget)
                event.name = 'onSelectionChange'
                event.selectedWidget = selectedWidget
                event.previousSelectedWidget = previousSelectedWidget
                execEventCall()
            end
        elseif widget.__class == 'UICheckBox' then
            widget.onCheckChange = function(widget, checked)
                event.name = 'onCheckChange'
                event.checked = checked
                execEventCall()
            end
        elseif widget.__class == 'UIScrollBar' then
            widget.onValueChange = function(widget, value, delta)
                event.name = 'onValueChange'
                event.value = value
                event.delta = delta
                execEventCall()
            end
        elseif widget.__class == 'UISpinBox' then
            widget.onValueChange = function(widget, value)
                event.name = 'onValueChange'
                event.value = value
                execEventCall()
            end
        end
    end
end

local function readNode(el, prevEl, parent, controller)
    local tagName = el.name

    local breakLine = tagName:lower() == 'br'

    local styleName = g_ui.getStyleName(tagName)
    local widget = g_ui.createWidget(styleName ~= '' and styleName or 'UIWidget', parent or rootWidget)

    el.widget = widget

    local anchor = 'prev'
    for attr, v in pairs(el.attributes) do
        if attr:starts('on') then
            parseEvents(widget, attr:lower(), v, controller)
        elseif attr == 'anchor' then
            anchor = v
        elseif attr == 'style' then
            parseStyle(widget, el)
        elseif attr == 'layout' then
            parseLayout(widget, el)
        elseif attr == 'class' then
            for _, className in pairs(v:split(' ')) do
                local css = g_ui.getStyle(className)
                if css then
                    widget:mergeStyle(css)
                end
            end
        else
            v = tonumber(v) or v

            local methodName = ''
            for _, _name in pairs(attr:trim():split('-')) do
                methodName = methodName .. _name:gsub("^%l", string.upper)
            end

            methodName = 'set' .. methodName
            local method = widget[methodName]
            if method then
                method(widget, v)
            else
                error('[' .. tagName .. '] attribute ' .. attr .. ' not exist.')
            end
        end
    end

    if #el.nodes > 0 then
        local prevEl = nil
        for _, chield in pairs(el.nodes) do
            readNode(chield, prevEl, widget, controller)
            prevEl = chield
        end
    else
        widget:setText(el:getcontent())
    end

    if prevEl and not breakLine then
        breakLine = prevEl.style and prevEl.style.display == 'block'
    end

    if parent then
        if widget:getAnchoredLayout() then
            if widget:getChildIndex() == 1 or anchor == 'parent' then
                widget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
                widget:addAnchor(AnchorTop, 'parent', AnchorTop)
            elseif breakLine then
                displayBlock(widget)
            else
                displayInline(widget, anchor)
            end
        end
    end



    return widget
end


function HtmlLoader(path, parent, controller)
    local cssList = {}
    table.insertall(cssList, OFICIAL_HTML_CSS)

    local root = HtmlParser.parse(g_resources.readFileContents(path))

    local mainWidget = nil
    local prevEl = nil

    for _, el in pairs(root.nodes) do
        local tagName = el.name
        if tagName == 'style' then
            parseStyleElement(el:getcontent(), cssList)
        else
            mainWidget = readNode(el, prevEl, parent, controller)
            prevEl = el
        end
    end

    for _, css in pairs(cssList) do
        local els = root:find(css.selector)

        if #els == 0 then
            pwarning('[' .. path .. '][style] selector(' .. css.selector .. ') no element was found.')
        end

        for _, el in pairs(els) do
            if css.attrs.display == 'block' then
                local next = el.widget:getNextWidget()
                if next then
                    displayBlock(next)
                end
            elseif el.style and el.style.display == 'none' then
                el.widget:setVisible(false)
            end

            if el.widget then
                el.widget:mergeStyle(css.attrs)
            end
        end
    end

    return mainWidget, root
end

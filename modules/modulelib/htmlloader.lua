local main = nil

local function parseStyleElement(el, cssList)
    local css = CssParse.new()
    css:parse(el:getcontent())
    local data = css:get_objects()

    for _, o in ipairs(data) do
        table.insert(cssList, {
            selector = o.selector:trim(), attrs = o.declarations
        })
    end
end

local function readNode(el, parent)
    local tagName = el.name

    local isBR = tagName:lower() == 'br'
    if isBR then
        tagName = 'UIWidget'
    end

    local widget = g_ui.createWidget(tagName, parent or rootWidget)

    widget:setVisible(true)
    widget:setTextAutoResize(true)

    el.widget = widget

    local parseStyle = function()
        local style = {}
        for _, style_v in pairs(el.attributes.style:split(';')) do
            local attr = style_v:split(':')
            local name = attr[1]
            local value = attr[2]:trim()
            value = tonumber(value) or value
            style[name:trim()] = value
        end

        widget:mergeStyle(style)
    end

    local anchor = 'prev'
    for attr, v in pairs(el.attributes) do
        if attr == 'anchor' then
            anchor = v
        elseif attr == 'style' then
            parseStyle()
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
        for _, chield in pairs(el.nodes) do
            readNode(chield, widget)
        end
    else
        widget:setText(el:getcontent())
    end

    if parent then
        if widget:getChildIndex() == 1 or anchor == 'parent' then
            widget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
            widget:addAnchor(AnchorTop, 'parent', AnchorTop)
        elseif isBR then
            widget:addAnchor(AnchorLeft, anchor, AnchorLeft)
            widget:addAnchor(AnchorTop, anchor, AnchorBottom)
        else
            widget:addAnchor(AnchorLeft, anchor, AnchorRight)
            widget:addAnchor(AnchorTop, anchor, AnchorTop)
        end
    end

    return widget
end

function HtmlLoader(path, parent)
    local cssList = {}

    local root = HtmlParser.parse(g_resources.readFileContents(path))

    local mainWidget = nil
    for _, el in pairs(root.nodes) do
        local tagName = el.name
        if tagName == 'style' then
            parseStyleElement(el, cssList)
        else
            mainWidget = readNode(el, parent)
        end
    end

    for _, css in pairs(cssList) do
        local els = root:select(css.selector)

        if #els == 0 then
            pwarning('[' .. path .. '][style] selector(' .. css.selector .. ') no element was found.')
        end

        for _, el in pairs(els) do
            if el.widget then
                el.widget:mergeStyle(css.attrs)
            end
        end
    end

    return mainWidget, root
end

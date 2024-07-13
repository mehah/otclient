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

local function displayBlock(widget)
    widget:addAnchor(AnchorLeft, 'prev', AnchorLeft)
    widget:addAnchor(AnchorTop, 'prev', AnchorBottom)
end


local function getNextWidget(widget)
    local parent = widget:getParent()
    if parent:getChildCount() > widget:getChildIndex() then
        return parent:getChildByIndex(widget:getChildIndex() + 1)
    end

    return nil
end

local function getPrevWidget(widget)
    local parent = widget:getParent()
    if widget:getChildIndex() > 1 then
        return parent:getChildByIndex(widget:getChildIndex() - 1)
    end

    return nil
end

local function readNode(el, prevEl, parent)
    local tagName = el.name

    local breakLine = tagName:lower() == 'br'

    local styleExist = g_ui.getStyle(tagName) ~= nil
    local widget = g_ui.createWidget(styleExist and tagName or 'UIWidget', parent or rootWidget)

    widget:setVisible(true)
    -- widget:setTextAutoResize(true)

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
        el.style = style
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
        local prevEl = nil
        for _, chield in pairs(el.nodes) do
            readNode(chield, prevEl, widget)
            prevEl = chield
        end
    else
        widget:setText(el:getcontent())
    end

    if prevEl then
        breakLine = prevEl.style and prevEl.style.display == 'block'
    end

    if parent then
        if widget:getChildIndex() == 1 or anchor == 'parent' then
            widget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
            widget:addAnchor(AnchorTop, 'parent', AnchorTop)
        elseif breakLine then
            displayBlock(widget)
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
    local prevEl = nil

    for _, el in pairs(root.nodes) do
        local tagName = el.name
        if tagName == 'style' then
            parseStyleElement(el, cssList)
        else
            mainWidget = readNode(el, prevEl, parent)
            prevEl = el
        end
    end

    for _, css in pairs(cssList) do
        local els = root:select(css.selector)

        if #els == 0 then
            pwarning('[' .. path .. '][style] selector(' .. css.selector .. ') no element was found.')
        end

        for _, el in pairs(els) do
            if css.attrs.display == 'block' then
                local next = getNextWidget(el.widget)
                if next then
                    displayBlock(next)
                end
            end

            if el.widget then
                el.widget:mergeStyle(css.attrs)
            end
        end
    end

    return mainWidget, root
end

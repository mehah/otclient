local OFICIAL_HTML_CSS = {}

local parseStyleElement, translateStyleNameToHTML = dofile('ext/style')
local parseStyle, parseLayout = dofile('ext/parse')
local parseEvents = dofile('ext/parseevent')

local function processDisplayStyle(el)
    if el.widget:getChildIndex() == 1 or el.attributes and el.attributes.anchor == 'parent' then
        el.widget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        el.widget:addAnchor(AnchorTop, 'parent', AnchorTop)
        return;
    end

    if el.widget:hasAnchoredLayout() then
        if el.prev and el.prev.style and el.prev.style.display == 'block' then
            el.widget:addAnchor(AnchorLeft, 'prev', AnchorLeft)
            el.widget:addAnchor(AnchorTop, 'prev', AnchorBottom)
        else -- if el.prev.style.display == 'inline' then
            el.widget:addAnchor(AnchorLeft, 'prev', AnchorRight)
            el.widget:addAnchor(AnchorTop, 'prev', AnchorTop)
        end
    end

    if not el.style then
        return
    end

    if el.style.display == 'none' then
        el.widget:setVisible(false)
    end
end

local function processFloatStyle(el)
    if not el.style or not el.style.float then
        return
    end

    if el.style.float == 'right' then
        local anchor = 'parent'
        local anchorType = AnchorRight
        for _, child in pairs(el.parent.nodes) do
            if child ~= el and child.style and child.style.float == 'right' then
                anchor = child.widget:getId()
                anchorType = AnchorLeft
                break
            end
        end

        el.widget:removeAnchor(AnchorLeft)
        el.widget:addAnchor(AnchorRight, anchor, anchorType)
    elseif el.style.float == 'left' then
        local anchor = 'parent'
        local anchorType = AnchorLeft
        for _, child in pairs(el.parent.nodes) do
            if child ~= el and child.style.float == 'right' then
                anchor = child.widget:getId()
                anchorType = AnchorRight
                break
            end
        end

        el.widget:removeAnchor(AnchorRight)
        el.widget:addAnchor(AnchorLeft, anchor, anchorType)
    end
end

local function readNode(el, parent, controller)
    local tagName = el.name

    local styleName = g_ui.getStyleName(translateStyleNameToHTML(tagName))
    local widget = g_ui.createWidget(styleName ~= '' and styleName or 'UIWidget', parent or rootWidget)

    el.widget = widget

    for attr, v in pairs(el.attributes) do
        if attr:starts('on') then
            parseEvents(el, widget, attr:lower(), v, controller)
        elseif attr == 'anchor' then
            -- ignore
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
                pwarning('[' .. HTML_PATH .. ']:' .. tagName .. ' attribute ' .. attr .. ' not exist.')
            end
        end
    end

    if #el.nodes > 0 then
        if widget.HTML_onReadNodes and not widget:HTML_onReadNodes(el.nodes) then
            return
        else
            local prevEl = nil
            for _, chield in pairs(el.nodes) do
                chield.prev = prevEl
                readNode(chield, widget, controller)
                prevEl = chield
            end
        end
    else
        local text = el:getcontent()
        if text then
            local whiteSpace = el.style and el.style['white-space'] or 'nowrap'

            if whiteSpace == 'normal' then
                text = text:trim()
            elseif whiteSpace == 'nowrap' then
                text = text:gsub("[\n\r]", " ")
            elseif whiteSpace == 'pre' then
                -- nothing
            end

            widget:setText(text)
        end
    end

    if parent then
        if widget:hasAnchoredLayout() then
            processDisplayStyle(el)
            processFloatStyle(el)
        end
    end

    return widget
end

local function onProcessCSS(el)
    if el.name == 'hr' then
        if el.widget:hasAnchoredLayout() then
            el.widget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
            el.widget:addAnchor(AnchorRight, 'parent', AnchorRight)
        end
    end
end

parseStyleElement(g_resources.readFileContents('html.css'), OFICIAL_HTML_CSS, false)

function HtmlLoader(path, parent, controller)
    HTML_PATH = path

    local cssList = {}
    table.insertall(cssList, OFICIAL_HTML_CSS)

    local root = HtmlParser.parse(g_resources.readFileContents(path))
    root.widget = nil
    root.path = path

    local prevEl = nil

    for _, el in pairs(root.nodes) do
        el.prev = prevEl
        local tagName = el.name
        if tagName == 'style' then
            parseStyleElement(el:getcontent(), cssList, true)
        else
            root.widget = readNode(el, parent, controller)
            el.prev = el
        end
        prevEl = el
    end

    for _, css in pairs(cssList) do
        local els = root:find(css.selector)

        if css.checkExist and #els == 0 then
            pwarning('[' .. path .. '][style] selector(' .. css.selector .. ') no element was found.')
        end

        local prevEl = nil
        for _, el in pairs(els) do
            if not el.style then
                el.style = {};
            end

            table.merge(el.style, css.attrs)

            processDisplayStyle(el)
            processFloatStyle(el)
            if el.widget then
                el.widget:mergeStyle(el.style)
            end

            onProcessCSS(el)

            prevEl = el
        end
    end

    return root
end

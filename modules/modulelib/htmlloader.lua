local OFICIAL_HTML_CSS = {}

local parseStyleElement, translateStyleNameToHTML, processDisplayStyle, processFloatStyle = dofile('ext/style')
local parseStyle, parseLayout = dofile('ext/parse')
local parseEvents = dofile('ext/parseevent')

local function readNode(el, parent, controller)
    local tagName = el.name

    local styleName = g_ui.getStyleName(translateStyleNameToHTML(tagName))
    local widget = g_ui.createWidget(styleName ~= '' and styleName or 'UIWidget', parent or rootWidget)
    widget:setOnHtml(true)
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

            if v == '' or v == methodName then
                v = true
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
                text = text:gsub("[\n\r\t]", ""):gsub("  ", "")
            elseif whiteSpace == 'pre' then
                -- nothing
            end

            widget:setText(text)
        end
    end

    if parent then
        if widget:hasAnchoredLayout() then
            addEvent(function()
                processDisplayStyle(el)
                processFloatStyle(el)
            end)
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

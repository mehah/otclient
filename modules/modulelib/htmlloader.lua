local OFICIAL_HTML_CSS = {}

local parseStyleElement, translateStyleName = dofile('ext/style')
local parseStyle, parseLayout = dofile('ext/parse')
local parseEvents = dofile('ext/parseevent')

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

local function readNode(el, prevEl, parent, controller)
    local tagName = el.name

    local breakLine = tagName:lower() == 'br'

    local styleName = g_ui.getStyleName(translateStyleName(tagName))
    local widget = g_ui.createWidget(styleName ~= '' and styleName or 'UIWidget', parent or rootWidget)

    el.widget = widget

    local anchor = 'prev'
    for attr, v in pairs(el.attributes) do
        if attr:starts('on') then
            parseEvents(el, widget, attr:lower(), v, controller)
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
                readNode(chield, prevEl, widget, controller)
                prevEl = chield
            end
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
        local tagName = el.name
        if tagName == 'style' then
            parseStyleElement(el:getcontent(), cssList, true)
        else
            root.widget = readNode(el, prevEl, parent, controller)
            prevEl = el
        end
    end

    for _, css in pairs(cssList) do
        local els = root:find(css.selector)

        if css.checkExist and #els == 0 then
            pwarning('[' .. path .. '][style] selector(' .. css.selector .. ') no element was found.')
        end

        for _, el in pairs(els) do
            if css.attrs.display == 'block' then
                local next = el.widget:getNextWidget()
                if next then
                    displayBlock(next)
                end
            elseif css.attrs.display == 'none' then
                el.widget:setVisible(false)
            end

            if css.attrs.float == 'right' then
                el.widget:addAnchor(AnchorRight, 'parent', AnchorLeft)
            end

            if el.widget then
                el.widget:mergeStyle(css.attrs)
            end
        end
    end

    return root
end

local OFICIAL_HTML_CSS = {}

local parseStyleElement, processDisplayStyle, processFloatStyle = dofile('ext/style')
local parseStyle, parseLayout = dofile('ext/parse')
local parseEvents, registerActionEvents = dofile('ext/parseevent')
local translateStyleName, translateAttribute = dofile('ext/translator')

local function processExpression(content, controller)
    local lastPos = nil
    while true do
        local pos = content:find('{{', lastPos)
        if not pos then
            break
        end

        lastPos = content:find('}}', lastPos)

        local script = content:sub(pos + 2, lastPos - 1)

        local res = nil
        if content:sub(pos - 2, pos - 1) == 'tr' then
            pos = pos - 2
            res = tr(script)
        else
            local f = loadstring('return function(self) return ' .. script .. ' end')
            res = f()(controller)
        end

        if res then
            content = table.concat { content:sub(1, pos - 1), res, content:sub(lastPos + 2) }
        end
    end
    return content
end

local function readNode(el, parent, controller, watchList)
    local tagName = el.name

    local styleName = g_ui.getStyleName(translateStyleName(tagName))
    local widget = g_ui.createWidget(styleName ~= '' and styleName or 'UIWidget', parent or rootWidget)
    widget:setOnHtml(true)
    el.widget = widget

    registerActionEvents(el, widget, controller)

    local hasAttrText = false

    for attr, v in pairs(el.attributes) do
        local attr = translateAttribute(styleName, attr)
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
            local methodName = ''
            for _, _name in pairs(attr:trim():split('-')) do
                methodName = methodName .. _name:gsub("^%l", string.upper)
            end

            local watchObj = nil

            local isExp = methodName:starts('*')
            if isExp then
                methodName = methodName:sub(2):gsub("^%l", string.upper)

                local vStr = v
                local f = loadstring('return function(self, target) return ' .. vStr .. ' end')
                local fnc = f()
                v = fnc(controller)

                watchObj = {
                    widget = widget,
                    res = v,
                    method = nil,
                    fnc = function(self)
                        local value = fnc(controller, widget)
                        if value ~= self.res then
                            self.method(self.widget, value)
                            self.res = value
                        end
                    end
                }
            elseif v == '' or v == methodName then
                v = true
            end

            v = tonumber(v) or toboolean(v) or v

            hasAttrText = methodName == 'Text'

            methodName = 'set' .. methodName
            local method = widget[methodName]
            if method then
                method(widget, v)

                if watchObj then
                    watchObj.method = method
                    table.insert(watchList, watchObj)
                end
            else
                pwarning('[' .. HTML_PATH .. ']:' .. tagName .. ' attribute ' .. attr .. ' not exist.')
            end
        end
    end

    if #el.nodes > 0 then
        if not widget.HTML_onReadNodes or widget:HTML_onReadNodes(el.nodes) then
            local prevEl = nil
            for _, chield in pairs(el.nodes) do
                chield.prev = prevEl
                readNode(chield, widget, controller, watchList)
                prevEl = chield
            end
        end
    elseif not hasAttrText then
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
            local isVisible = widget:isVisible()
            if isVisible then
                widget:setVisible(false)
            end
            addEvent(function()
                processDisplayStyle(el)
                processFloatStyle(el)
                if isVisible then
                    widget:setVisible(true)
                end
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

parseStyleElement(io.content('modulelib/html.css'), OFICIAL_HTML_CSS, false)

function HtmlLoader(path, parent, controller)
    HTML_PATH = path

    local cssList = {}
    table.insertall(cssList, OFICIAL_HTML_CSS)

    local root = HtmlParser.parse(processExpression(io.content(path), controller))
    root.widget = nil
    root.path = path

    local prevEl = nil
    local watchList = {}

    for _, el in pairs(root.nodes) do
        el.prev = prevEl
        local tagName = el.name
        if tagName == 'style' then
            parseStyleElement(el:getcontent(), cssList, true)
        else
            root.widget = readNode(el, parent, controller, watchList)
            el.prev = el
        end
        prevEl = el
    end

    for _, css in pairs(cssList) do
        local els = root:find(css.selector)

        if css.checkExist and #els == 0 then
            pwarning('[' .. path .. '][style] selector(' .. css.selector .. ') no element was found.')
        end

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
        end
    end

    controller:cycleEvent(function()
        for _, obj in pairs(watchList) do
            obj.fnc(obj)
        end
    end, 50)

    return root
end

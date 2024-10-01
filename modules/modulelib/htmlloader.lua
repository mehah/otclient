local WATCH_CYCLE_CHECK_MS = 50
local OFICIAL_HTML_CSS = {}

local parseCss, parseAndSetDisplayAttr, parseAndSetFloatStyle = dofile('ext/style')
local parseStyle, parseLayout, parseExpression = dofile('ext/parse')
local parseEvents, onCreateWidget, setText, createRadioGroup, afterLoadElement = dofile('ext/parseevent')
local translateStyleName, translateAttribute = dofile('ext/translator')

local function readNode(el, parent, controller, watchList)
    local styleName = g_ui.getStyleName(translateStyleName(el.name, el))
    local widget = g_ui.createWidget(styleName ~= '' and styleName or 'UIWidget', parent or rootWidget)
    widget:setOnHtml(true)

    el.widget = widget

    onCreateWidget(el, widget, controller)

    for attr, v in pairs(el.attributes) do
        local attr = translateAttribute(styleName, el.name, attr)
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
                    el = el,
                    method = nil,
                    fnc = function(self)
                        local value = fnc(controller, self.widget)
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

            local method = nil
            if methodName == 'Text' then
                method = function(widget, v) setText(el, v) end
            else
                method = widget['set' .. methodName]
            end

            if method then
                method(widget, v)

                if watchObj then
                    watchObj.method = method
                    table.insert(watchList, watchObj)
                end
            else
                local _name = string.sub(methodName, 1, 1):lower() .. string.sub(methodName, 2, -1)
                widget[_name] = v
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
    end

    return widget
end

parseCss(io.content('modulelib/html.css'), OFICIAL_HTML_CSS, false)

function HtmlLoader(path, parent, controller)
    HTML_PATH = path

    local cssList = {}
    table.insertall(cssList, OFICIAL_HTML_CSS)

    local root = HtmlParser.parse(parseExpression(io.content(path), controller))
    root.widget = nil
    root.path = path

    local watchList = {}
    local prevEl = nil
    for _, el in pairs(root.nodes) do
        el.prev = prevEl
        if el.name == 'style' then
            parseCss(el:getcontent(), cssList, true)
        elseif el.name == 'link' then
            local href = el.attributes.href
            if href then
                parseCss(io.content(href), cssList, true)
            end
        else
            root.widget = readNode(el, parent, controller, watchList)
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

            if el.widget then
                el.widget:mergeStyle(el.style)
            end
        end
    end

    local radioGroups = {}
    local all = root:find('*')
    for i = #all, 1, -1 do
        local el = all[i]
        if el.widget then
            parseAndSetDisplayAttr(el)
            parseAndSetFloatStyle(el)

            if el.name == 'input' and el.attributes.type == 'radio' then
                createRadioGroup(el, radioGroups, controller)
            end

            afterLoadElement(el)
        end
    end

    if #watchList > 0 then
        local event = nil
        event = controller:cycleEvent(function()
            table.remove_if(watchList, function(i, obj)
                local isDestroyed = obj.widget:isDestroyed()
                if isDestroyed then
                    obj.widget = nil
                    obj.el.widget = nil
                else
                    obj.fnc(obj)
                end

                return isDestroyed
            end)

            if #watchList == 0 then
                removeEvent(event)
            end
        end, WATCH_CYCLE_CHECK_MS)
    end

    return root
end

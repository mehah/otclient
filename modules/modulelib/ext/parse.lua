local parseAttrPropList = function(str)
    local obj = {}
    for _, style_v in pairs(str:split(';')) do
        local attr = style_v:trim():split(':')
        local name = attr[1]
        if name then
            local value = attr[2]:trim()
            value = tonumber(value) or value
            obj[name:trim()] = value
        end
    end
    return obj
end

local parseStyle = function(widget, el)
    local styleStr = el.attributes.style:trim()
    if styleStr == '' then
        return
    end

    local style = parseAttrPropList(styleStr)
    widget:mergeStyle(style)
    el.style = style
end

local parseLayout = function(widget, el)
    local layout = parseAttrPropList(el.attributes.layout)
    widget:mergeStyle({ layout = layout })
end

local function parseExpression(content, controller)
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

return parseStyle, parseLayout, parseExpression

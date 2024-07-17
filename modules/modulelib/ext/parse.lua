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

return parseStyle, parseLayout

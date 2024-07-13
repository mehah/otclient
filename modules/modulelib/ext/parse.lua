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

return parseStyle, parseLayout

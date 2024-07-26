local function FixSelection(selector)
    selector = selector:trim()

    local lastPos = nil
    while true do
        local pos = selector:find('%[', lastPos)
        if not pos then
            break
        end

        lastPos = selector:find(']', lastPos)

        local res = nil
        local cmd = selector:sub(pos + 1, lastPos - 1)
        local values = cmd:split('=')
        if #values > 1 then
            res = '[' .. values[1] .. '="' .. values[2] .. '"]'
        end

        if res then
            selector = table.concat { selector:sub(1, pos - 1), res, selector:sub(lastPos + 2) }
        end
    end

    return selector
end

local function parseCss(content, cssList, checkExist)
    local css = CssParse.new()
    css:parse(content)
    local data = css:get_objects()
    for _, o in ipairs(data) do
        table.insert(cssList, {
            selector = FixSelection(o.selector),
            attrs = o.declarations,
            checkExist = checkExist
        })
    end
end

local function parseAndSetDisplayAttr(el)
    if el.widget:hasAnchoredLayout() then
        if el.widget:getChildIndex() == 1 or el.attributes and el.attributes.anchor == 'parent' then
            el.widget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
            el.widget:addAnchor(AnchorTop, 'parent', AnchorTop)
        elseif el.prev and el.prev.style and el.prev.style.display == 'block' then
            el.widget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
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

local function parseAndSetFloatStyle(el)
    if not el.style or not el.style.float or not el.widget:hasAnchoredLayout() then
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
            if child ~= el and child.style and child.style.float == 'right' then
                anchor = child.widget:getId()
                anchorType = AnchorRight
                break
            end
        end

        el.widget:removeAnchor(AnchorRight)
        el.widget:addAnchor(AnchorLeft, anchor, anchorType)
    end
end

return parseCss, parseAndSetDisplayAttr, parseAndSetFloatStyle

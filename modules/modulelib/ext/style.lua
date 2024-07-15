local function parseStyleElement(content, cssList, checkExist)
    local css = CssParse.new()
    css:parse(content)
    local data = css:get_objects()

    for _, o in ipairs(data) do
        table.insert(cssList, {
            selector = o.selector:trim(), attrs = o.declarations, checkExist = checkExist
        })
    end
end

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

local function translateStyleNameToHTML(styleName)
    if styleName == 'select' then
        return 'combobox'
    end

    if styleName == 'hr' then
        return 'HorizontalSeparator'
    end

    if styleName == 'input' then
        return 'TextEdit'
    end

    if styleName == 'textarea' then
        return 'MultilineTextEdit'
    end

    return styleName
end

return parseStyleElement, translateStyleNameToHTML, processDisplayStyle, processFloatStyle

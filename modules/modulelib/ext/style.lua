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

local function translateStyleNameToHTML(styleName)
    if styleName == 'select' then
        return 'combobox'
    end

    if styleName == 'hr' then
        return 'HorizontalSeparator'
    end

    return styleName
end

return parseStyleElement, translateStyleNameToHTML

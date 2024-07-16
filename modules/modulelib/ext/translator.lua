local function translateStyleName(styleName)
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

local function translateAttribute(styleName, attr)
    if attr == '*style' then
        return '*mergeStyle'
    end

    if attr == '*if' then
        return '*visible'
    end

    if attr == '*value' then
        return '*text'
    end

    if attr == 'value' then
        return 'text'
    end

    return attr
end

return translateStyleName, translateAttribute

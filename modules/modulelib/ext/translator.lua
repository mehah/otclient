local IMG_ATTR_TRANSLATED = {
    ['offset-x'] = 'image-offset-x',
    ['offset-y'] = 'image-offset-y',
    ['offset'] = 'image-offset',
    ['width'] = 'image-width',
    ['height'] = 'image-height',
    ['size'] = 'image-size',
    ['rect'] = 'image-rect',
    ['clip'] = 'image-clip',
    ['fixed-ratio'] = 'image-fixed-ratio',
    ['repeated'] = 'image-repeated',
    ['smooth'] = 'image-smooth',
    ['color'] = 'image-color',
    ['border-top'] = 'image-border-top',
    ['border-right'] = 'image-border-right',
    ['border-bottom'] = 'image-border-bottom',
    ['border-left'] = 'image-border-left',
    ['border'] = 'image-border',
    ['auto-resize'] = 'image-auto-resize',
    ['individual-animation'] = 'image-individual-animation',
    ['src'] = 'image-source'
}

local function translateStyleName(styleName, el)
    if styleName == 'select' then
        return 'QtComboBox'
    end

    if styleName == 'hr' then
        return 'HorizontalSeparator'
    end

    if styleName == 'input' then
        if el.attributes['type'] == 'checkbox' or el.attributes['type'] == 'radio' then
            return 'QtCheckBox'
        end

        return 'TextEdit'
    end

    if styleName == 'textarea' then
        return 'MultilineTextEdit'
    end

    return styleName
end

local function translateAttribute(styleName, tagName, attr)
    if attr == '*style' then
        return '*mergeStyle'
    end

    if attr == '*if' then
        return '*visible'
    end

    if styleName ~= 'CheckBox' and styleName ~= 'ComboBox' then
        if attr == '*value' then
            return '*text'
        end

        if attr == 'value' then
            return 'text'
        end
    end

    if tagName == 'img' then
        local newAttr = IMG_ATTR_TRANSLATED[attr]
        if newAttr then
            return newAttr
        end
    end

    return attr
end

return translateStyleName, translateAttribute

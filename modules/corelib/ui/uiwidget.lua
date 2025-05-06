-- @docclass UIWidget
function UIWidget:setMargin(...)
    local params = {...}
    if #params == 1 then
        self:setMarginTop(params[1])
        self:setMarginRight(params[1])
        self:setMarginBottom(params[1])
        self:setMarginLeft(params[1])
    elseif #params == 2 then
        self:setMarginTop(params[1])
        self:setMarginRight(params[2])
        self:setMarginBottom(params[1])
        self:setMarginLeft(params[2])
    elseif #params == 4 then
        self:setMarginTop(params[1])
        self:setMarginRight(params[2])
        self:setMarginBottom(params[3])
        self:setMarginLeft(params[4])
    end
end

function UIWidget:parseColoredText(text, default_color)
    default_color = default_color or "#ffffff"
    local result, last_pos = "", 1
    for start, stop in text:gmatch("()%[color=#?%x+%]()") do
        if start > last_pos then
            result = result .. "{" .. text:sub(last_pos, start - 1) .. ", " .. default_color .. "}"
        end
        local closing_tag_start = text:find("%[/color%]", stop)
        if not closing_tag_start then break end
        local content = text:sub(stop, closing_tag_start - 1)
        local color = text:match("#%x+", start) or default_color
        result = result .. "{" .. content .. ", " .. color .. "}"
        last_pos = closing_tag_start + 8
    end
    if last_pos <= #text then
        result = result .. "{" .. text:sub(last_pos) .. ", " .. default_color .. "}"
    end
    self:setColoredText(result)
end

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
    local result = ""
    local i = 1
    while i <= #text do
        local start, stop = text:find("%[color=.-%]", i)
        if start then
            result = result .. text:sub(i, start - 1)
            local closing_tag_start, closing_tag_stop = text:find("%[/color%]", stop + 1)
            if closing_tag_start then
                local content = text:sub(stop + 1, closing_tag_start - 1)
                local color_start, color_stop = text:find("#%x+", start)
                local color = text:sub(color_start, color_stop) or default_color
                result = result .. "{" .. content .. ", " .. color .. "}"
                i = closing_tag_stop + 1
            else
                break
            end
        else
            result = result .. text:sub(i)
            break
        end
    end
    self:setColoredText(result)
end

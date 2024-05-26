-- @docclass
g_tooltip = {}

-- private variables
local toolTipLabel
local SpecialoolTipLabel
local currentHoveredWidget

-- private functions
local function moveToolTip(first)
    if not first and (not toolTipLabel:isVisible() or toolTipLabel:getOpacity() < 0.1) then
        return
    end

    local pos = g_window.getMousePosition()
    local windowSize = g_window.getSize()
    local labelSize = toolTipLabel:getSize()

    pos.x = pos.x + 1
    pos.y = pos.y + 1

    if windowSize.width - (pos.x + labelSize.width) < 10 then
        pos.x = pos.x - labelSize.width - 3
    else
        pos.x = pos.x + 10
    end

    if windowSize.height - (pos.y + labelSize.height) < 10 then
        pos.y = pos.y - labelSize.height - 3
    else
        pos.y = pos.y + 10
    end

    toolTipLabel:setPosition(pos)
end
local function moveSpecialToolTip(first)
    if not first and (not SpecialoolTipLabel:isVisible() or SpecialoolTipLabel:getOpacity() < 0.1) then
        return
    end

    local pos = g_window.getMousePosition()
    local windowSize = g_window.getSize()
    local labelSize = SpecialoolTipLabel:getSize()

    pos.x = pos.x + 1
    pos.y = pos.y + 1

    if windowSize.width - (pos.x + labelSize.width) < 10 then
        pos.x = pos.x - labelSize.width - 3
    else
        pos.x = pos.x + 10
    end

    if windowSize.height - (pos.y + labelSize.height) < 10 then
        pos.y = pos.y - labelSize.height - 3
    else
        pos.y = pos.y + 10
    end

    SpecialoolTipLabel:setPosition(pos)
end

local function onWidgetDestroy(widget)
    if widget == currentHoveredWidget then
        if widget.tooltip then
            g_tooltip.hide()
        end
        if widget.specialtooltip then
            g_tooltip.hideSpecial()
        end
        currentHoveredWidget = nil
    end
end

local function onWidgetHoverChange(widget, hovered)
    if hovered then
        if widget.tooltip and not g_mouse.isPressed() then
            g_tooltip.display(widget.tooltip)
            currentHoveredWidget = widget
        elseif widget.specialtooltip and not g_mouse.isPressed() then
            g_tooltip.displaySpecial(widget.specialtooltip)
            currentHoveredWidget = widget
        end
    else
        if widget == currentHoveredWidget then
            if widget.tooltip then
                g_tooltip.hide()
            end
            if widget.specialtooltip then
                g_tooltip.hideSpecial()
            end
            currentHoveredWidget = nil
        end
    end
end

local function onWidgetStyleApply(widget, styleName, styleNode)
    if styleNode.tooltip then
        widget.tooltip = styleNode.tooltip
    end
    if styleNode.specialtooltip then
        widget.specialtooltip = {{header = '', info = styleNode.specialtooltip}}
    end

    local tooltipWidget = widget:getChildById('toolTipWidget')
    if widget:getId() == 'toolTipWidget' then
        tooltipWidget = widget
        widget = widget:getParent()
    end
    if tooltipWidget then
        if widget.tooltip then
            tooltipWidget.tooltip = widget.tooltip
            widget.tooltip = nil
        end
        if widget.specialtooltip then
            tooltipWidget.specialtooltip = widget.specialtooltip
            widget.specialtooltip = nil
        end
        if tooltipWidget.tooltip or tooltipWidget.specialtooltip then
            tooltipWidget:setOpacity(1)
        else
            tooltipWidget:setOpacity(0.4)
        end
    end
end

-- public functions
function g_tooltip.init()
    connect(UIWidget, {
        onStyleApply = onWidgetStyleApply,
        onHoverChange = onWidgetHoverChange,
        onDestroy = onWidgetDestroy
    })

    addEvent(function()
        toolTipLabel = g_ui.createWidget('UILabel', rootWidget)
        toolTipLabel:setId('toolTip')
        toolTipLabel:setBackgroundColor('#c0c0c0ff')
        toolTipLabel:setTextAlign(AlignLeft)
        toolTipLabel:setColor('#3f3f3fff')
        toolTipLabel:setBorderColor("#4c4c4cff")
        toolTipLabel:setBorderWidth(1)
        toolTipLabel:setTextOffset(topoint('5 3'))
        toolTipLabel:hide()
    end)

    addEvent(function()
        SpecialoolTipLabel = g_ui.createWidget('UIWidget', rootWidget)
        SpecialoolTipLabel:setBackgroundColor('#c0c0c0ff')
        SpecialoolTipLabel:setBorderColor("#4c4c4cff")
        SpecialoolTipLabel:setBorderWidth(1)
        SpecialoolTipLabel:setWidth(455)
        SpecialoolTipLabel:setPaddingTop(2)
        SpecialoolTipLabel:hide()
    end)
end

function g_tooltip.terminate()
    disconnect(UIWidget, {
        onStyleApply = onWidgetStyleApply,
        onHoverChange = onWidgetHoverChange,
        onDestroy = onWidgetDestroy
    })

    currentHoveredWidget = nil
    toolTipLabel:destroy()
    toolTipLabel = nil

    g_tooltip = nil
end

function g_tooltip.display(text)
    if text == nil or text:len() == 0 then
        return
    end
    if not toolTipLabel then
        return
    end

    toolTipLabel:setText(text)
    toolTipLabel:resizeToText()
    toolTipLabel:resize(toolTipLabel:getWidth() + 4, toolTipLabel:getHeight() + 4)
    toolTipLabel:show()
    toolTipLabel:raise()
    toolTipLabel:enable()
    g_effects.fadeIn(toolTipLabel, 100)
    moveToolTip(true)

    connect(rootWidget, {
        onMouseMove = moveToolTip
    })
end

function g_tooltip.displaySpecial(special)
    if not SpecialoolTipLabel then
        return
    end

    local width = 4
    local height = 4
    SpecialoolTipLabel:destroyChildren()
    for index, data in ipairs(special) do
        local headerW = 0
        local headerH = 0
        if string.len(data.header) > 0 then
            local header = g_ui.createWidget('UILabel', SpecialoolTipLabel)
            if index == 1 then
                header:addAnchor(AnchorTop, 'parent', AnchorTop)
            else
                header:addAnchor(AnchorTop, 'prev', AnchorBottom)
            end
            header:addAnchor(AnchorLeft, 'parent', AnchorLeft)
            header:setText(data.header)
            header:setTextAlign(AlignLeft)
            header:setColor("#4c4c4cff")
            header:setFont('verdana-11px-monochrome-underline')
            header:setTextOffset(topoint('5 0'))
            header:resizeToText()
            header:resize(header:getWidth(), header:getHeight())
            headerW = header:getWidth()
            headerH = header:getHeight()
        end

        local info = g_ui.createWidget('UILabel', SpecialoolTipLabel)
        if string.len(data.header) > 0 then
            info:addAnchor(AnchorTop, 'prev', AnchorBottom)
        else
            info:addAnchor(AnchorTop, 'parent', AnchorTop)
        end
        info:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        info:setText(data.info:wrap(445))
        info:setTextAlign(AlignLeft)
        info:setColor("#4c4c4cff")
        info:setTextOffset(topoint('5 0'))
        info:resizeToText()
        info:resize(info:getWidth(), info:getHeight())
        width = width + math.max(headerW, info:getWidth())
        height = height + headerH + info:getHeight()
    end

    SpecialoolTipLabel:resize(width, height)
    SpecialoolTipLabel:show()
    SpecialoolTipLabel:raise()
    SpecialoolTipLabel:enable()
    g_effects.fadeIn(SpecialoolTipLabel, 100)
    moveSpecialToolTip(true)

    connect(rootWidget, {
        onMouseMove = moveSpecialToolTip
    })
end

function g_tooltip.hide()
    g_effects.fadeOut(toolTipLabel, 100)

    disconnect(rootWidget, {
        onMouseMove = moveToolTip
    })
end

function g_tooltip.hideSpecial()
    g_effects.fadeOut(SpecialoolTipLabel, 100)

    disconnect(rootWidget, {
        onMouseMove = moveSpecialToolTip
    })
end

-- @docclass UIWidget @{

-- UIWidget extensions
function UIWidget:setTooltip(text)
    local tooltipWidget = self:getChildById('toolTipWidget')
    if tooltipWidget then
        tooltipWidget.tooltip = text
    else
        self.tooltip = text
    end
end

function UIWidget:setSpecialToolTip(special)
    if type(special) == "string" then
        special = {{header = '', info = special}}
    end
    self.specialtooltip = special
end

function UIWidget:removeTooltip()
    self.tooltip = nil
    self.specialtooltip = nil
end

function UIWidget:getTooltip()
    return self.tooltip
end

function UIWidget:getSpecialTooltip()
    return self.specialtooltip
end

-- @}

g_tooltip.init()
connect(g_app, {
    onTerminate = g_tooltip.terminate
})

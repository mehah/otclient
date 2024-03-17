-- @docclass
UICalendar = extends(UIWidget, 'UICalendar')

function UICalendar.create(title, okCallback, cancelCallback)
    local calendar = UICalendar.internalCreate()
    return calendar
end

function UICalendar:onSetup()
    self:setOn(self:isEnabled())
    for _, children in ipairs(self:getChildren()) do
        if self.disableLeftBright ~= nil then
            children.disableLeftBright = self.disableLeftBright
        end
        if self.weekName ~= nil then
            children.weekName = self.weekName
        end
        if self.dayOfTheWeek ~= nil then
            children.dayOfTheWeek = self.dayOfTheWeek
        end
        if self:getParent() and self:getParent().dayOfTheWeek ~= nil then
            self.dayOfTheWeek = self:getParent().dayOfTheWeek
        end
        if self:getParent() and self:getParent().disableLeftBright ~= nil then
            self.disableLeftBright = self:getParent().disableLeftBright
        end
        if self:getParent() and self:getParent().weekName ~= nil then
            self.weekName = self:getParent().weekName
        end
        if children:getId() == "week" and children.weekName ~= nil then
            children:setText(children.weekName)
        elseif children:getId() == "brightColumn" then
            children:setOn(not(self.disableLeftBright))
        elseif children:getId() == "dayAndSeason" then
            for _, innerChildren in ipairs(children:getChildren()) do
                if innerChildren:getId() == "day" then
                    if self.dayOfTheWeek ~= nil then
                        innerChildren:setOn(true)
                        innerChildren:setWidth(string.len(innerChildren:getText()) * 10)
                    else
                        innerChildren:setOn(false)
                    end
                end
            end
        else
            children:setOn(self:isEnabled())
        end
    end
end

function UICalendar:addScheduleEvent(event, active, onClick)
    local content = self:getChildById('content')
    if not content then
        return
    end

    if #(content:getChildren()) == 4 then
        return
    end

    local widget = g_ui.createWidget('CalendarEvent', content)
    if onClick then
        connect(widget, {
            onClick = function()
                onClick()
            end
        })
    end
    if event.season then
        widget:getParent():getParent():recursiveGetChildById('dayAndSeason'):setOn(true)
        widget:getParent():getParent():recursiveGetChildById('season'):setOn(true)
    end
    if active then
        widget:setBackgroundColor(event.active)
    else
        widget:setBackgroundColor(event.inactive)
    end
    if #(content:getChildren()) == 1 then
        widget:addAnchor(AnchorTop, 'parent', AnchorTop)
    else
        widget:addAnchor(AnchorTop, 'prev', AnchorBottom)
    end
    local special = {}
    table.insert(special, {header = (event.name .. ":"), info = event.description})
    widget:setSpecialToolTip(special)

    widget.text = widget:getChildById('text')
    local eventText = event.name
    if event.firstDay or event.lastDay then
        eventText = "* " .. eventText
        if string.len(eventText) >= 11 then
            eventText = string.sub(eventText, 1, 14) .. "..."
        end
    elseif string.len(eventText) >= 10 then
        eventText = string.sub(eventText, 1, 13) .. "..."
    end
    widget.text:setText(eventText)
    if active then
        widget.text:setOpacity(1.0)
    else
        widget.text:setOpacity(0.75)
    end
end

function UICalendar:clearEvents()
    local content = self:getChildById('content')
    if not content then
        return
    end

    content:destroyChildren()
    self:recursiveGetChildById('season'):setOn(false)
    self:recursiveGetChildById('dayAndSeason'):setOn(false)
end
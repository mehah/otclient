-- @docclass
UIMiniWindowContainer = extends(UIWidget, 'UIMiniWindowContainer')

function UIMiniWindowContainer.create()
    local container = UIMiniWindowContainer.internalCreate()
    container.scheduledWidgets = {}
    container:setFocusable(false)
    container:setPhantom(true)
    return container
end

-- TODO: connect to window onResize event
-- TODO: try to resize another widget?
-- TODO: try to find another panel?
function UIMiniWindowContainer:fitAll(noRemoveChild)
    if not self:isVisible() then
        return
    end

    if self.ignoreFillAll then
        return
    end

    if not noRemoveChild then
        local children = self:getChildren()
        if #children > 0 then
            noRemoveChild = children[#children]
        else
            return
        end
    end

    local sumHeight = 0
    local children = self:getChildren()
    for i = 1, #children do
        if children[i]:isVisible() then
            sumHeight = sumHeight + children[i]:getHeight()
        end
    end

    local selfHeight = self:getHeight() - (self:getPaddingTop() + self:getPaddingBottom())
    if sumHeight <= selfHeight then
        return
    end

    local removeChildren = {}

    -- try to resize noRemoveChild
    local maximumHeight = selfHeight - (sumHeight - noRemoveChild:getHeight())
    if noRemoveChild:isResizeable() and noRemoveChild:getMinimumHeight() <= maximumHeight then
        sumHeight = sumHeight - noRemoveChild:getHeight() + maximumHeight
        addEvent(function()
            noRemoveChild:setHeight(maximumHeight)
        end)
    end

    -- try to remove no-save widget
    for i = #children, 1, -1 do
        if sumHeight <= selfHeight then
            break
        end

        local child = children[i]
        if child ~= noRemoveChild and not child.save then
            local childHeight = child:getHeight()
            sumHeight = sumHeight - childHeight
            table.insert(removeChildren, child)
        end
    end

    -- try to remove save widget
    for i = #children, 1, -1 do
        if sumHeight <= selfHeight then
            break
        end

        local child = children[i]
        if child ~= noRemoveChild and child:isVisible() then
            local childHeight = child:getHeight()
            sumHeight = sumHeight - childHeight
            table.insert(removeChildren, child)
        end
    end

    -- close widgets
    for i = 1, #removeChildren do
        removeChildren[i]:close()
    end
end

function UIMiniWindowContainer:fits(child, minContentHeight, maxContentHeight)
    if self.ignoreFillAll then
        return 0
    end

    local containerPanel = child:getChildById('contentsPanel')
    local indispensableHeight = 0
    if containerPanel then
        indispensableHeight = containerPanel:getMarginTop() + containerPanel:getMarginBottom() +
            containerPanel:getPaddingTop() + containerPanel:getPaddingBottom()
    end

    local totalHeight = 0
    local children = self:getChildren()
    for i = 1, #children do
        if children[i]:isVisible() then
            totalHeight = totalHeight + children[i]:getHeight()
        end
    end

    local available = self:getHeight() - (self:getPaddingTop() + self:getPaddingBottom()) - totalHeight

    if maxContentHeight > 0 and available >= (maxContentHeight + indispensableHeight) then
        return maxContentHeight + indispensableHeight
    elseif available >= (minContentHeight + indispensableHeight) then
        return available
    else
        return -1
    end
end

function UIMiniWindowContainer:onDrop(widget, mousePos)
    if widget.UIMiniWindowContainer then
        local widgetId = widget:getId()
        local targetPanelId = self:getId()

        -- Block non-minimap widgets from horizontalLeftPanel
        if targetPanelId == "horizontalLeftPanel" and widgetId ~= "minimapWindow" then
            local alternativePanel = modules.game_interface.findContentPanelAvailable(widget, widget:getMinimumHeight())
            if alternativePanel and alternativePanel ~= self then
                alternativePanel:onDrop(widget, mousePos)
                return true
            else
                return false
            end
        end

        -- Block widgets that are not allowed in gameMainRightPanel
        -- Only widgets with moveOnlyToMain or allowInMainRightPanel can be placed there
        if targetPanelId == "gameMainRightPanel" and not widget.moveOnlyToMain and not widget.allowInMainRightPanel then
            local alternativePanel = modules.game_interface.findContentPanelAvailable(widget, widget:getMinimumHeight())
            if alternativePanel and alternativePanel ~= self then
                alternativePanel:onDrop(widget, mousePos)
                return true
            else
                return false
            end
        end

        local oldParent = widget:getParent()
        if oldParent == self then
            return true
        end

        -- Restore minimap size and layout when leaving horizontal panel
        if widgetId == "minimapWindow" and oldParent and (oldParent:getId() == "horizontalLeftPanel" or oldParent:getId() == "horizontalRightPanel") then
            widget:setWidth(widget.defaultWidth or 178)
            widget:setHeight(widget.defaultHeight or 178)
        end

        if oldParent then
            local oldParentId = oldParent:getId()

            oldParent:removeChild(widget)

            -- Set old horizontal panel to phantom when empty
            if oldParentId == "horizontalLeftPanel" or oldParentId == "horizontalRightPanel" then
                if oldParent:getChildCount() == 0 then
                    oldParent:setPhantom(true)
                end
            end

            -- Update layout of old parent panel to remove empty space
            if oldParent.updateLayout then
                oldParent:updateLayout()
            end

            -- Auto-fit old parent height
            if oldParent.fitAllChildren then
                oldParent:fitAllChildren()
            end
        end

        -- Clean up any temporary margins applied during drag
        if widget.movedWidget then
            if widget.setMovedChildMargin then
                widget.setMovedChildMargin(widget.movedOldMargin or 0)
            end
            local index = self:getChildIndex(widget.movedWidget)
            self:insertChild(index + widget.movedIndex, widget)
            widget.movedWidget = nil
            widget.setMovedChildMargin = nil
            widget.movedOldMargin = nil
            widget.movedIndex = nil
        else
            self:addChild(widget)
        end

        if widget:getId() == "botWindow" and
            (widget:getParent():getId() == "gameLeftPanel" or widget:getParent():getId() == "gameLeftExtraPanel" or
                widget:getParent():getId() == "gameRightExtraPanel") then
            widget:getParent():setWidth(190)
        end

        -- Auto-resize minimap when placed in horizontal panel
        if widgetId == "minimapWindow" and (targetPanelId == "horizontalLeftPanel" or targetPanelId == "horizontalRightPanel") then
            self:setPhantom(false)

            if modules.game_minimap and modules.game_minimap.expandMinimapForHorizontalPanel then
                modules.game_minimap.expandMinimapForHorizontalPanel(self)
            else
                local panel = self
                addEvent(function()
                    local panelWidth = panel:getWidth()
                    local panelHeight = panel:getHeight()

                    widget:setWidth(panelWidth)
                    widget:setHeight(panelHeight)
                end)
            end
        end

        self:fitAll(widget)

        -- Auto-fit height for gameMainRightPanel
        if self.fitAllChildren and self:getId() == "gameMainRightPanel" then
            self:fitAllChildren()
        end

        return true
    end
end

function UIMiniWindowContainer:swapInsert(widget, index)
    local oldParent = widget:getParent()
    local oldIndex = self:getChildIndex(widget)

    if oldParent == self and oldIndex ~= index then
        local oldWidget = self:getChildByIndex(index)
        if oldWidget then
            self:removeChild(oldWidget)
            self:insertChild(oldIndex, oldWidget)
        end
        self:removeChild(widget)
        self:insertChild(index, widget)
    end
end

function UIMiniWindowContainer:scheduleInsert(widget, index)
    if index - 1 > self:getChildCount() then
        if self.scheduledWidgets[index] then
            pdebug('replacing scheduled widget id ' .. widget:getId())
        end
        self.scheduledWidgets[index] = widget
    else
        local oldParent = widget:getParent()
        if oldParent ~= self then
            if oldParent then
                oldParent:removeChild(widget)
            end
            self:insertChild(index, widget)

            while true do
                local placed = false
                for nIndex, nWidget in pairs(self.scheduledWidgets) do
                    if nIndex - 1 <= self:getChildCount() then
                        -- Check if widget is already a child before inserting
                        local nWidgetParent = nWidget:getParent()
                        if nWidgetParent ~= self then
                            if nWidgetParent then
                                nWidgetParent:removeChild(nWidget)
                            end
                            self:insertChild(nIndex, nWidget)
                        end
                        self.scheduledWidgets[nIndex] = nil
                        placed = true
                        break
                    end
                end
                if not placed then
                    break
                end
            end
        end
    end
end

function UIMiniWindowContainer:order()
    local children = self:getChildren()
    for i = 1, #children do
        if not children[i].miniLoaded then
            return
        end
    end

    for i = 1, #children do
        if children[i].miniIndex then
            self:swapInsert(children[i], children[i].miniIndex)
        end
    end
end

function UIMiniWindowContainer:saveChildren()
    local children = self:getChildren()
    local ignoreIndex = 0
    for i = 1, #children do
        if children[i].save then
            children[i]:saveParentIndex(self:getId(), i - ignoreIndex)
        else
            ignoreIndex = ignoreIndex + 1
        end
    end
end

function UIMiniWindowContainer:fitAllChildren()
    local panelId = self:getId()

    -- Skip horizontal panels - they have fixed height
    if panelId == "horizontalLeftPanel" or panelId == "horizontalRightPanel" then
        return
    end

    local children = self:getChildren()
    local totalHeight = 0
    local layout = self:getLayout()
    local spacing = 0

    if layout and layout.getSpacing then
        spacing = layout:getSpacing()
    end

    local visibleCount = 0
    for i = 1, #children do
        local child = children[i]
        if child:isVisible() and child:getHeight() > 0 then
            totalHeight = totalHeight + child:getHeight() + child:getMarginTop() + child:getMarginBottom()
            visibleCount = visibleCount + 1
        end
    end

    if visibleCount > 1 then
        totalHeight = totalHeight + (spacing * (visibleCount - 1))
    end

    totalHeight = totalHeight + self:getPaddingTop() + self:getPaddingBottom()

    self:setHeight(math.max(0, totalHeight))
end

-- @docclass
UIMiniWindow = extends(UIWindow, 'UIMiniWindow')

function UIMiniWindow.create()
    local miniwindow = UIMiniWindow.internalCreate()
    miniwindow.UIMiniWindowContainer = true
    return miniwindow
end

function UIMiniWindow:open(dontSave)
    self:setVisible(true)
    if not dontSave then
        self:setSettings({
            closed = false
        })
    end
    signalcall(self.onOpen, self)
end

function UIMiniWindow:close(dontSave)
    if not self:isExplicitlyVisible() then
        return
    end
    self:setVisible(false)

    if not dontSave then
        self:setSettings({
            closed = true
        })
    end

    signalcall(self.onClose, self)
end

function UIMiniWindow:minimize(dontSave)
    self:setOn(true)
    self:getChildById('contentsPanel'):hide()
    self:getChildById('miniwindowScrollBar'):hide()
    self:getChildById('bottomResizeBorder'):hide()
    self:getChildById('minimizeButton'):setOn(true)
    self.maximizedHeight = self:getHeight()
    self:setHeight(self.minimizedHeight)

    if not dontSave then
        self:setSettings({
            minimized = true
        })
    end

    signalcall(self.onMinimize, self)
end

function UIMiniWindow:maximize(dontSave)
    self:setOn(false)
    self:getChildById('contentsPanel'):show()
    self:getChildById('miniwindowScrollBar'):show()
    self:getChildById('bottomResizeBorder'):show()
    self:getChildById('minimizeButton'):setOn(false)
    self:setHeight(self:getSettings('height') or self.maximizedHeight)

    if not dontSave then
        self:setSettings({
            minimized = false
        })
    end

    local parent = self:getParent()
    if parent and parent:getClassName() == 'UIMiniWindowContainer' then
        parent:fitAll(self)
    end

    signalcall(self.onMaximize, self)
end

function UIMiniWindow:setup()
    self:getChildById('closeButton').onClick = function()
        self:close()
    end

    self:getChildById('minimizeButton').onClick = function()
        if self:isOn() then
            self:maximize()
        else
            self:minimize()
        end
    end

    self:getChildById('lockButton').onClick = function()
        if self:isDraggable() then
            self:lock()
        else
            self:unlock()
        end
    end

    self:getChildById('miniwindowTopBar').onDoubleClick = function()
        if self:isOn() then
            self:maximize()
        else
            self:minimize()
        end
    end
end

function UIMiniWindow:setupOnStart()
    local char = g_game.getCharacterName()
    if not char or #char == 0 then
        return
    end

    local oldParent = self:getParent()
    local newParentSet = false
    local settings = g_settings.getNode('CharMiniWindows')

    if not settings then
        settings = {
            [char] = {}
        }
    elseif not settings[char] then
        -- if there are no settings for this character, we'll copy the settings from
        -- another one, so we'll have something better than all the windows randomly positioned
        for k, v in pairs(settings) do
            settings[char] = v
            g_settings.setNode('CharMiniWindows', settings)
            break
        end
    end

    local selfSettings = settings[char][self:getId()]
    if selfSettings then
        if selfSettings.parentId then
            local parent = rootWidget:recursiveGetChildById(selfSettings.parentId)
            if parent and parent:isVisible() then
                if parent:getClassName() == 'UIMiniWindowContainer' and selfSettings.index and parent:isOn() then
                    self.miniIndex = selfSettings.index
                    parent:scheduleInsert(self, selfSettings.index)
                    newParentSet = true
                elseif selfSettings.position then
                    self:setParent(parent, true)
                    self:setPosition(topoint(selfSettings.position))
                    newParentSet = true
                end
            end
        end

        if selfSettings.minimized then
            self:minimize(true)
        elseif selfSettings.height then
            if self:isResizeable() then
                self:setHeight(selfSettings.height)
            else
                self:eraseSettings({
                    height = true
                })
            end
        end

        if selfSettings.closed then
            self:close(true)
        else
            self:open(true)
        end
    else
        if self:getId() == "battleWindow" then
            self:open(true)
        end
    end

    local newParent = self:getParent()

    if not oldParent and not newParentSet then
        oldParent = modules.game_interface.getRightPanel()
        self:setParent(oldParent)
    end

    self.miniLoaded = true

    if self.save then
        if oldParent and oldParent:getClassName() == 'UIMiniWindowContainer' then
            addEvent(function()
                oldParent:order()
            end)
        end
        if newParent and newParent:getClassName() == 'UIMiniWindowContainer' and newParent ~= oldParent then
            addEvent(function()
                newParent:order()
            end)
        end
    end

    self:fitOnParent()
    if self:getId() == "botWindow" then
        local parent = self:getParent()
        local parentId = parent:getId()

        if parentId == "gameLeftPanel" or
            parentId == "gameLeftExtraPanel" or
            parentId == "gameRightExtraPanel" then
            if parent:isVisible() then
                parent:setWidth(190)
            end
        end
    end
end

function UIMiniWindow:onVisibilityChange(visible)
    self:fitOnParent()
end

function UIMiniWindow:onDragEnter(mousePos)
    local parent = self:getParent()
    if not parent then
        return false
    end

    if parent:getClassName() == 'UIMiniWindowContainer' then
        self.oldParentDrag = parent
        self.oldParentDragIndex = parent:getChildIndex(self)
        local containerParent = parent:getParent()
        parent:removeChild(self)
        containerParent:addChild(self)
        parent:saveChildren()
    end

    local oldPos = self:getPosition()
    self.movingReference = {
        x = mousePos.x - oldPos.x,
        y = mousePos.y - oldPos.y
    }
    self:setPosition(oldPos)
    self.free = true
    return true
end

function UIMiniWindow:onDragLeave(droppedWidget, mousePos)
    if self.movedWidget then
        self.setMovedChildMargin(self.movedOldMargin or 0)
        self.movedWidget = nil
        self.setMovedChildMargin = nil
        self.movedOldMargin = nil
        self.movedIndex = nil
    end

    self:saveParent(self:getParent())

    -- Note: It seems to prevent the minimap, inventory, and health widgets from moving off the interface panel.
    if self.moveOnlyToMain or droppedWidget and droppedWidget.onlyPhantomDrop then
        if not (droppedWidget) or (self.moveOnlyToMain and not (droppedWidget.onlyPhantomDrop)) or
            (not (self.moveOnlyToMain) and droppedWidget.onlyPhantomDrop) then
            local virtualParent = self:getParent()
            virtualParent:removeChild(self)
            self.oldParentDrag:insertChild(self.oldParentDragIndex, self)
            self.movedWidget = nil
        end
    end
    return true
end

function UIMiniWindow:onDragMove(mousePos, mouseMoved)
    local oldMousePosY = mousePos.y - mouseMoved.y
    local children = rootWidget:recursiveGetChildrenByMarginPos(mousePos)
    local overAnyWidget = false
    for i = 1, #children do
        local child = children[i]
        if child:getParent():getClassName() == 'UIMiniWindowContainer' then
            overAnyWidget = true

            local childCenterY = child:getY() + child:getHeight() / 2
            if child == self.movedWidget and mousePos.y < childCenterY and oldMousePosY < childCenterY then
                break
            end

            if self.movedWidget then
                self.setMovedChildMargin(self.movedOldMargin or 0)
                self.setMovedChildMargin = nil
            end

            if mousePos.y < childCenterY then
                self.movedOldMargin = child:getMarginTop()
                self.setMovedChildMargin = function(v)
                    child:setMarginTop(v)
                end
                self.movedIndex = 0
            else
                self.movedOldMargin = child:getMarginBottom()
                self.setMovedChildMargin = function(v)
                    child:setMarginBottom(v)
                end
                self.movedIndex = 1
            end

            self.movedWidget = child
            self.setMovedChildMargin(self:getHeight())
            break
        end
    end

    if not overAnyWidget and self.movedWidget then
        self.setMovedChildMargin(self.movedOldMargin or 0)
        self.movedWidget = nil
    end

    return UIWindow.onDragMove(self, mousePos, mouseMoved)
end

function UIMiniWindow:onMousePress()
    local parent = self:getParent()
    if not parent then
        return false
    end
    if parent:getClassName() ~= 'UIMiniWindowContainer' then
        self:raise()
        return true
    end
end

function UIMiniWindow:onFocusChange(focused)
    if not focused then
        return
    end
    local parent = self:getParent()
    if parent and parent:getClassName() ~= 'UIMiniWindowContainer' then
        self:raise()
    end
end

function UIMiniWindow:onHeightChange(height)
    if not self:isOn() then
        self:setSettings({
            height = height
        })
    end
    self:fitOnParent()
end

function UIMiniWindow:getSettings(name)
    if not self.save then
        return nil
    end
    local char = g_game.getCharacterName()
    if not char or #char == 0 then
        return nil
    end

    local settings = g_settings.getNode('CharMiniWindows')
    if settings then
        local selfSettings = settings[char][self:getId()]
        if selfSettings then
            return selfSettings[name]
        end
    end

    return nil
end

function UIMiniWindow:setSettings(data)
    if not self.save then
        return
    end
    local char = g_game.getCharacterName()
    if not char or #char == 0 then
        return
    end

    local settings = g_settings.getNode('CharMiniWindows')
    if not settings then
        settings = {}
    end
    if not settings[char] then
        settings[char] = {}
    end

    local id = self:getId()
    if not settings[char][id] then
        settings[char][id] = {}
    end

    for key, value in pairs(data) do
        settings[char][id][key] = value
    end

    g_settings.setNode('CharMiniWindows', settings)
end

function UIMiniWindow:eraseSettings(data)
    if not self.save then
        return
    end
    local char = g_game.getCharacterName()
    if not char or #char == 0 then
        return
    end

    local settings = g_settings.getNode('CharMiniWindows')
    if not settings then
        settings = {}
    end
    if not settings[char] then
        settings[char] = {}
    end

    local id = self:getId()
    if not settings[char][id] then
        settings[char][id] = {}
    end

    for key, value in pairs(data) do
        settings[char][id][key] = nil
    end

    g_settings.setNode('CharMiniWindows', settings)
end

function UIMiniWindow:saveParent(parent)
    local parent = self:getParent()
    if parent then
        if parent:getClassName() == 'UIMiniWindowContainer' then
            parent:saveChildren()
        else
            self:saveParentPosition(parent:getId(), self:getPosition())
        end
    end
end

function UIMiniWindow:saveParentPosition(parentId, position)
    local selfSettings = {}
    selfSettings.parentId = parentId
    selfSettings.position = pointtostring(position)
    self:setSettings(selfSettings)
end

function UIMiniWindow:saveParentIndex(parentId, index)
    local selfSettings = {}
    selfSettings.parentId = parentId
    selfSettings.index = index
    self:setSettings(selfSettings)
    self.miniIndex = index
end

function UIMiniWindow:disableResize()
    self:getChildById('bottomResizeBorder'):disable()
end

function UIMiniWindow:enableResize()
    self:getChildById('bottomResizeBorder'):enable()
end

function UIMiniWindow:fitOnParent()
    local parent = self:getParent()
    if self:isVisible() and parent and parent:getClassName() == 'UIMiniWindowContainer' then
        parent:fitAll(self)
    end
end

function UIMiniWindow:setParent(parent, dontsave)
    UIWidget.setParent(self, parent)
    if not dontsave then
        self:saveParent(parent)
    end
    self:fitOnParent()
end

function UIMiniWindow:setHeight(height)
    UIWidget.setHeight(self, height)
    signalcall(self.onHeightChange, self, height)
end

function UIMiniWindow:setContentHeight(height)
    local contentsPanel = self:getChildById('contentsPanel')
    local minHeight = contentsPanel:getMarginTop() + contentsPanel:getMarginBottom() + contentsPanel:getPaddingTop() +
        contentsPanel:getPaddingBottom()

    local resizeBorder = self:getChildById('bottomResizeBorder')
    resizeBorder:setParentSize(minHeight + height)
end

function UIMiniWindow:setContentMinimumHeight(height)
    local contentsPanel = self:getChildById('contentsPanel')
    local minHeight = contentsPanel:getMarginTop() + contentsPanel:getMarginBottom() + contentsPanel:getPaddingTop() +
        contentsPanel:getPaddingBottom()

    local resizeBorder = self:getChildById('bottomResizeBorder')
    resizeBorder:setMinimum(minHeight + height)
end

function UIMiniWindow:setContentMaximumHeight(height)
    local contentsPanel = self:getChildById('contentsPanel')
    local minHeight = contentsPanel:getMarginTop() + contentsPanel:getMarginBottom() + contentsPanel:getPaddingTop() +
        contentsPanel:getPaddingBottom()

    local resizeBorder = self:getChildById('bottomResizeBorder')
    resizeBorder:setMaximum(minHeight + height)
end

function UIMiniWindow:getMinimumHeight()
    local resizeBorder = self:getChildById('bottomResizeBorder')
    return resizeBorder:getMinimum()
end

function UIMiniWindow:getMaximumHeight()
    local resizeBorder = self:getChildById('bottomResizeBorder')
    return resizeBorder:getMaximum()
end

function UIMiniWindow:modifyMaximumHeight(height)
    local resizeBorder = self:getChildById('bottomResizeBorder')
    local newHeight = resizeBorder:getMaximum() + height
    local curHeight = self:getHeight()
    resizeBorder:setMaximum(newHeight)
    if newHeight < curHeight or newHeight - height == curHeight then
        self:setHeight(newHeight)
    end
end

function UIMiniWindow:isResizeable()
    local resizeBorder = self:getChildById('bottomResizeBorder')
    if not resizeBorder then
        return false
    end
    return resizeBorder:isExplicitlyVisible() and resizeBorder:isEnabled()
end

function UIMiniWindow:lock(dontSave)
    local lockButton = self:getChildById('lockButton')
    if lockButton then
        lockButton:setOn(true)
    end
    self:setDraggable(false)
    if not dontsave then
        self:setSettings({
            locked = true
        })
    end

    signalcall(self.onLockChange, self)
end

function UIMiniWindow:unlock(dontSave)
    local lockButton = self:getChildById('lockButton')
    if lockButton then
        lockButton:setOn(false)
    end
    self:setDraggable(true)
    if not dontsave then
        self:setSettings({
            locked = false
        })
    end
    signalcall(self.onLockChange, self)
end

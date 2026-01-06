ImbuementSelection = {
    pickWidget = nil,
    isSelecting = false,
}

function ImbuementSelection.startUp()
    ImbuementSelection.pickWidget = g_ui.createWidget('UIWidget')
    ImbuementSelection.pickWidget:setVisible(false)
    ImbuementSelection.pickWidget:setFocusable(false)
    
    connect(ImbuementSelection.pickWidget, {
        onMouseRelease = ImbuementSelection.onMouseRelease
    })
end

function ImbuementSelection:shutdown()
    if self.pickWidget then
        self.pickWidget:destroy()
        self.pickWidget = nil
    end
    self.isSelecting = false
end

function ImbuementSelection:selectItem()
    if not self.pickWidget then
        self:startUp()
    end
    
    if self.isSelecting then
        return
    end
    
    self.isSelecting = true
    self.pickWidget:setVisible(true)
    self.pickWidget:grabMouse()
    g_mouse.pushCursor('target')
end

function ImbuementSelection.onMouseRelease(widget, mousePosition, mouseButton)
    if mouseButton ~= MouseLeftButton then
        return false
    end
    
    local item = nil
    local clickedWidget = modules.game_interface.getRootPanel():recursiveGetChildByPos(mousePosition, false)
    
    if clickedWidget then
        if clickedWidget:getClassName() == 'UIGameMap' then
            local tile = clickedWidget:getTile(mousePosition)
            if tile then
                local thing = tile:getTopMoveThing()
                if thing and thing:isItem() then
                    item = thing
                end
            end
        elseif clickedWidget:getClassName() == 'UIItem' and not clickedWidget:isVirtual() then
            item = clickedWidget:getItem()
        end
    end
    
    ImbuementSelection.isSelecting = false
    ImbuementSelection.pickWidget:ungrabMouse()
    ImbuementSelection.pickWidget:setVisible(false)
    g_mouse.popCursor('target')
    
    if item then
        local pos = item:getPosition()
        modules.game_textmessage.displayGameMessage(tr('Item selected: ') .. item:getId())
    else
        modules.game_textmessage.displayFailureMessage(tr('Please select a valid item.'))
    end
    
    return true
end

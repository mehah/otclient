function init()
    g_ui.importStyle('container')

    connect(Container, {
        onOpen = onContainerOpen,
        onClose = onContainerClose,
        onSizeChange = onContainerChangeSize,
        onUpdateItem = onContainerUpdateItem
    })
    connect(Game, {
        onGameEnd = clean()
    })

    reloadContainers()
end

function terminate()
    disconnect(Container, {
        onOpen = onContainerOpen,
        onClose = onContainerClose,
        onSizeChange = onContainerChangeSize,
        onUpdateItem = onContainerUpdateItem
    })
    disconnect(Game, {
        onGameEnd = clean()
    })
end

function reloadContainers()
    clean()
    for _, container in pairs(g_game.getContainers()) do
        onContainerOpen(container)
    end
end

function clean()
    for containerid, container in pairs(g_game.getContainers()) do
        destroy(container)
    end
end

function destroy(container)
    if container.window then
        container.window:destroy()
        container.window = nil
        container.itemsPanel = nil
    end
end

function refreshContainerItems(container)
    for slot = 0, container:getCapacity() - 1 do
        local itemWidget = container.itemsPanel:getChildById('item' .. slot)
        itemWidget:setItem(container:getItem(slot))
        ItemsDatabase.setRarityItem(itemWidget, container:getItem(slot))
        ItemsDatabase.setTier(itemWidget, container:getItem(slot))
        if modules.client_options.getOption('showExpiryInContainers') then
            ItemsDatabase.setCharges(itemWidget, container:getItem(slot))
            ItemsDatabase.setDuration(itemWidget, container:getItem(slot))
        end
    end

    if container:hasPages() then
        refreshContainerPages(container)
    end
end

function toggleContainerPages(containerWindow, pages)
    local scrollbar = containerWindow:getChildById('miniwindowScrollBar')
    local pagePanel = containerWindow:getChildById('pagePanel')
    local separator = containerWindow:getChildById('separator')
    local contentsPanel = containerWindow:getChildById('contentsPanel')
    local upButton = containerWindow:getChildById('upButton')
    local contextMenuButton = containerWindow:recursiveGetChildById('contextMenuButton')
    local lockButton = containerWindow:recursiveGetChildById('lockButton')
    local minimizeButton = containerWindow:recursiveGetChildById('minimizeButton')
    
    if pages then
        -- When pages are visible, anchor scrollbar to close button bottom and separator top
        scrollbar:breakAnchors()
        scrollbar:addAnchor(AnchorTop, 'closeButton', AnchorBottom)
        scrollbar:addAnchor(AnchorRight, 'parent', AnchorRight)
        scrollbar:addAnchor(AnchorBottom, 'separator', AnchorTop)
        scrollbar:setMarginTop(2)  -- Small margin from close button
        scrollbar:setMarginRight(3)
        scrollbar:setMarginBottom(2)
        
        -- Content panel anchors to separator when pages are visible
        contentsPanel:breakAnchors()
        contentsPanel:addAnchor(AnchorTop, 'miniwindowTopBar', AnchorBottom)
        contentsPanel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        contentsPanel:addAnchor(AnchorRight, 'miniwindowScrollBar', AnchorLeft)
        contentsPanel:addAnchor(AnchorBottom, 'separator', AnchorTop)
        contentsPanel:setMarginLeft(3)
        contentsPanel:setMarginBottom(1)
        contentsPanel:setMarginTop(-2)
        contentsPanel:setMarginRight(1)
        
        -- When pages are active, move upButton to toggleFilterButton position if it's visible
        if upButton and upButton:isVisible() and contextMenuButton and minimizeButton then
            -- Position upButton where toggleFilterButton was
            upButton:breakAnchors()
            upButton:addAnchor(AnchorTop, minimizeButton:getId(), AnchorTop)
            upButton:addAnchor(AnchorRight, minimizeButton:getId(), AnchorLeft)
            upButton:setMarginRight(7)
            upButton:setMarginTop(0)
            
            -- Move contextMenuButton to the left of upButton
            contextMenuButton:breakAnchors()
            contextMenuButton:addAnchor(AnchorTop, upButton:getId(), AnchorTop)
            contextMenuButton:addAnchor(AnchorRight, upButton:getId(), AnchorLeft)
            contextMenuButton:setMarginRight(2)
            contextMenuButton:setMarginTop(0)
            
            -- Position lockButton to the left of contextMenu
            if lockButton then
                lockButton:breakAnchors()
                lockButton:addAnchor(AnchorTop, contextMenuButton:getId(), AnchorTop)
                lockButton:addAnchor(AnchorRight, contextMenuButton:getId(), AnchorLeft)
                lockButton:setMarginRight(2)
                lockButton:setMarginTop(0)
            end
        end
    else
        -- When pages are hidden, use normal bottom anchor
        scrollbar:breakAnchors()
        scrollbar:addAnchor(AnchorTop, 'parent', AnchorTop)
        scrollbar:addAnchor(AnchorRight, 'parent', AnchorRight)
        scrollbar:addAnchor(AnchorBottom, 'parent', AnchorBottom)
        scrollbar:setMarginTop(16)
        scrollbar:setMarginRight(3)
        scrollbar:setMarginBottom(3)
        
        -- Content panel extends to bottom when pages are hidden
        contentsPanel:breakAnchors()
        contentsPanel:addAnchor(AnchorTop, 'miniwindowTopBar', AnchorBottom)
        contentsPanel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        contentsPanel:addAnchor(AnchorRight, 'miniwindowScrollBar', AnchorLeft)
        contentsPanel:addAnchor(AnchorBottom, 'parent', AnchorBottom)
        contentsPanel:setMarginLeft(3)
        contentsPanel:setMarginBottom(3)
        contentsPanel:setMarginTop(-2)
        contentsPanel:setMarginRight(1)
        
        -- When pages are not active, reset button positions based on upButton visibility
        if upButton and contextMenuButton and minimizeButton then
            if upButton:isVisible() then
                -- Reset upButton to original position
                upButton:breakAnchors()
                upButton:addAnchor(AnchorTop, minimizeButton:getId(), AnchorTop)
                upButton:addAnchor(AnchorRight, minimizeButton:getId(), AnchorLeft)
                upButton:setMarginRight(3)
                upButton:setMarginTop(0)
                
                -- Position contextMenuButton to the left of upButton
                contextMenuButton:breakAnchors()
                contextMenuButton:addAnchor(AnchorTop, upButton:getId(), AnchorTop)
                contextMenuButton:addAnchor(AnchorRight, upButton:getId(), AnchorLeft)
                contextMenuButton:setMarginRight(2)
                contextMenuButton:setMarginTop(0)
            else
                -- Position contextMenuButton where toggleFilterButton was
                contextMenuButton:breakAnchors()
                contextMenuButton:addAnchor(AnchorTop, minimizeButton:getId(), AnchorTop)
                contextMenuButton:addAnchor(AnchorRight, minimizeButton:getId(), AnchorLeft)
                contextMenuButton:setMarginRight(7)
                contextMenuButton:setMarginTop(0)
            end
            
            -- Position lockButton to the left of contextMenu
            if lockButton then
                lockButton:breakAnchors()
                lockButton:addAnchor(AnchorTop, contextMenuButton:getId(), AnchorTop)
                lockButton:addAnchor(AnchorRight, contextMenuButton:getId(), AnchorLeft)
                lockButton:setMarginRight(2)
                lockButton:setMarginTop(0)
            end
        end
    end
    
    pagePanel:setVisible(pages)
    separator:setVisible(pages)
end

function refreshContainerPages(container)
    local currentPage = 1 + math.floor(container:getFirstIndex() / container:getCapacity())
    local pages = 1 + math.floor(math.max(0, (container:getSize() - 1)) / container:getCapacity())
    container.window:recursiveGetChildById('pageLabel'):setText(string.format('Page %i of %i', currentPage, pages))

    local prevPageButton = container.window:recursiveGetChildById('prevPageButton')
    local nextPageButton = container.window:recursiveGetChildById('nextPageButton')
    
    -- If there's only one page, hide both navigation buttons
    if pages == 1 then
        prevPageButton:setVisible(false)
        nextPageButton:setVisible(false)
    else
        -- Multiple pages logic
        if currentPage == 1 then
            -- Hide the back button when on the first page of multiple pages
            prevPageButton:setVisible(false)
        else
            prevPageButton:setVisible(true)
            prevPageButton:setEnabled(true)
            prevPageButton.onClick = function()
                -- Store current height before page change
                local currentHeight = container.window:getHeight()
                container.window.preservedHeight = currentHeight
                g_game.seekInContainer(container:getId(), container:getFirstIndex() - container:getCapacity())
            end
        end

        if currentPage >= pages then
            nextPageButton:setVisible(false)
        else
            nextPageButton:setVisible(true)
            nextPageButton:setEnabled(true)
            nextPageButton.onClick = function()
                -- Store current height before page change
                local currentHeight = container.window:getHeight()
                container.window.preservedHeight = currentHeight
                g_game.seekInContainer(container:getId(), container:getFirstIndex() + container:getCapacity())
            end
        end
    end
end

function onContainerOpen(container, previousContainer)
    local containerWindow
    if previousContainer then
        containerWindow = previousContainer.window
        previousContainer.window = nil
        previousContainer.itemsPanel = nil
    else
        containerWindow = g_ui.createWidget('ContainerWindow')
    end
    containerWindow:setId('container' .. container:getId())
    local containerPanel = containerWindow:getChildById('contentsPanel')
    local containerItemWidget = containerWindow:getChildById('containerItemWidget')
    containerWindow.onClose = function()
        g_game.close(container)
        containerWindow:hide()
    end

    -- this disables scrollbar auto hiding
    local scrollbar = containerWindow:getChildById('miniwindowScrollBar')
    scrollbar:mergeStyle({
        ['$!on'] = {}
    })
    
    -- Scrollbar positioning will be handled by toggleContainerPages function

    local upButton = containerWindow:getChildById('upButton')
    upButton.onClick = function()
        g_game.openParent(container)
    end
    upButton:setVisible(container:hasParent())

    -- Add minimize/maximize event handlers to manage pagePanel visibility
    containerWindow.onMinimize = function()
        local pagePanel = containerWindow:getChildById('pagePanel')
        if pagePanel and pagePanel:isVisible() then
            pagePanel.wasVisibleBeforeMinimize = true
            pagePanel:setVisible(false)
        end
    end
    
    containerWindow.onMaximize = function()
        local pagePanel = containerWindow:getChildById('pagePanel')
        if pagePanel and pagePanel.wasVisibleBeforeMinimize then
            pagePanel:setVisible(true)
            pagePanel.wasVisibleBeforeMinimize = nil
        end
    end

    -- Hide toggleFilterButton and adjust button positioning
    local toggleFilterButton = containerWindow:recursiveGetChildById('toggleFilterButton')
    if toggleFilterButton then
        toggleFilterButton:setVisible(false)
        toggleFilterButton:setOn(false)
    end
    
    -- Hide newWindowButton
    local newWindowButton = containerWindow:recursiveGetChildById('newWindowButton')
    if newWindowButton then
        newWindowButton:setVisible(false)
    end
    
    local contextMenuButton = containerWindow:recursiveGetChildById('contextMenuButton')
    local lockButton = containerWindow:recursiveGetChildById('lockButton')
    local minimizeButton = containerWindow:recursiveGetChildById('minimizeButton')
    if contextMenuButton and minimizeButton then
        if container:hasParent() then
            -- When upButton is visible, position contextMenuButton to its left
            contextMenuButton:breakAnchors()
            contextMenuButton:addAnchor(AnchorTop, upButton:getId(), AnchorTop)
            contextMenuButton:addAnchor(AnchorRight, upButton:getId(), AnchorLeft)
            contextMenuButton:setMarginRight(2)
            contextMenuButton:setMarginTop(0)
        else
            -- When upButton is not visible, position contextMenuButton where toggleFilterButton was
            contextMenuButton:breakAnchors()
            contextMenuButton:addAnchor(AnchorTop, minimizeButton:getId(), AnchorTop)
            contextMenuButton:addAnchor(AnchorRight, minimizeButton:getId(), AnchorLeft)
            contextMenuButton:setMarginRight(7)
            contextMenuButton:setMarginTop(0)
        end
        
        -- Position lockButton to the left of contextMenu
        if lockButton then
            lockButton:breakAnchors()
            lockButton:addAnchor(AnchorTop, contextMenuButton:getId(), AnchorTop)
            lockButton:addAnchor(AnchorRight, contextMenuButton:getId(), AnchorLeft)
            lockButton:setMarginRight(2)
            lockButton:setMarginTop(0)
        end
    end

    local name = container:getName()
    name = name:sub(1, 1):upper() .. name:sub(2)

    if name:len() > 14 then
        name = name:sub(1, 14) .. "..."
    end

    -- Set the title in the new miniwindowTitle element
    local titleWidget = containerWindow:getChildById('miniwindowTitle')
    if titleWidget then
        titleWidget:setText(name)
    else
        -- Fallback to old method if miniwindowTitle doesn't exist
        containerWindow:setText(name)
    end

    containerItemWidget:setItem(container:getContainerItem())
    containerItemWidget:setPhantom(true)

    containerPanel:destroyChildren()
    for slot = 0, container:getCapacity() - 1 do
        local itemWidget = g_ui.createWidget('Item', containerPanel)
        itemWidget:setId('item' .. slot)
        itemWidget:setItem(container:getItem(slot))
        ItemsDatabase.setRarityItem(itemWidget, container:getItem(slot))
        ItemsDatabase.setTier(itemWidget, container:getItem(slot))
        if modules.client_options.getOption('showExpiryInContainers') then
            ItemsDatabase.setCharges(itemWidget, container:getItem(slot))
            ItemsDatabase.setDuration(itemWidget, container:getItem(slot))
        end
        itemWidget:setMargin(0)
        itemWidget.position = container:getSlotPosition(slot)

        if not container:isUnlocked() then
            itemWidget:setBorderColor('red')
        end
    end

    container.window = containerWindow
    container.itemsPanel = containerPanel

    toggleContainerPages(containerWindow, container:hasPages())
    refreshContainerPages(container)

    local layout = containerPanel:getLayout()
    local cellSize = layout:getCellSize()
    containerWindow:setContentMinimumHeight(cellSize.height)
    
    -- Set maximum height based on whether pages are active
    local maxHeightOffset = container:hasPages() and 65 or 30
    containerWindow:setContentMaximumHeight(cellSize.height * layout:getNumLines() + maxHeightOffset)

    if not previousContainer then
        local panel = modules.game_interface.findContentPanelAvailable(containerWindow, cellSize.height)
        panel:addChild(containerWindow)
    end

    -- Always set the content height based on the current container's content
    if modules.client_options.getOption('openMaximized') then
        containerWindow:setContentHeight(cellSize.height * layout:getNumLines())
    else
        local filledLines = math.max(math.ceil(container:getItemsCount() / layout:getNumColumns()), 1)
        containerWindow:setContentHeight(filledLines * cellSize.height)
    end

    containerWindow:setup()
end

function onContainerClose(container)
    destroy(container)
end

function onContainerChangeSize(container, size)
    if not container.window then
        return
    end
    
    -- Store the current height if one was preserved from page navigation
    local preservedHeight = container.window.preservedHeight
    
    refreshContainerItems(container)
    
    -- Restore the preserved height if it exists (from page switching)
    if preservedHeight then
        container.window:setHeight(preservedHeight)
        container.window.preservedHeight = nil -- Clear the preserved height
    end
end

function onContainerUpdateItem(container, slot, item, oldItem)
    if not container.window then
        return
    end
    local itemWidget = container.itemsPanel:getChildById('item' .. slot)
    itemWidget:setItem(item)
    if modules.client_options.getOption('showExpiryInContainers') then
        ItemsDatabase.setCharges(itemWidget, container:getItem(slot))
        ItemsDatabase.setDuration(itemWidget, container:getItem(slot))
    end
end

vipWindow = nil
vipButton = nil
addVipWindow = nil
editVipWindow = nil
vipInfo = {}

-- @ Groups
addGroupWindow = nil
vipGroups = {}
maxVipGroups = 5
editableGroupCount = 1
-- @

local globalSettings = {
    showGrouped = false,
    hideOfflineVips = false,
    vipSortOrder = {}
}

controllerVip = Controller:new()
function controllerVip:onInit()

    Keybind.new("Windows", "Show/hide VIP list", "Ctrl+P", "")
    Keybind.bind("Windows", "Show/hide VIP list", {
      {
        type = KEY_DOWN,
        callback = toggle,
      }
    })
    vipButton = modules.game_mainpanel.addToggleButton('vipListButton', tr('VIP List') .. ' (Ctrl+P)',
                                                                '/images/options/button_vip', toggle, false, 3)
    vipWindow = g_ui.loadUI('viplist')
    controllerVip:registerEvents(g_game, {
        onAddVip = onAddVip,
        onVipStateChange = onVipStateChange,
        onVipGroupChange = onVipGroupChange
    })

    local settings = g_settings.getNode('VipList')
    if settings then
       globalSettings.showGrouped = settings['Grouped'] or false
       globalSettings.hideOfflineVips = settings['OfflineVips'] or false
       globalSettings.vipSortOrder = {}
       if settings['vipSortOrder'] then
           for k, v in pairs(settings['vipSortOrder']) do
               globalSettings.vipSortOrder[tonumber(k)] = v
           end
       end
    end
    refresh()
    vipWindow:setup()

    -- Hide toggleFilterButton and adjust contextMenuButton anchors
    local toggleFilterButton = vipWindow:recursiveGetChildById('toggleFilterButton')
    if toggleFilterButton then
        toggleFilterButton:setVisible(false)
        toggleFilterButton:setOn(false)
    end
    
    local contextMenuButton = vipWindow:recursiveGetChildById('contextMenuButton')
    local minimizeButton = vipWindow:recursiveGetChildById('minimizeButton')
    if contextMenuButton and minimizeButton then
        contextMenuButton:addAnchor(AnchorTop, minimizeButton:getId(), AnchorTop)
        contextMenuButton:addAnchor(AnchorRight, minimizeButton:getId(), AnchorLeft)
        contextMenuButton:setMarginRight(7)
        
        -- Add onClick handler for context menu
        contextMenuButton.onClick = function(widget, mousePos, mouseButton)
            return onVipListMousePress(widget, mousePos or widget:getPosition(), MouseRightButton)
        end
    end
    
    -- Adjust lockButton anchors to be at the left of contextMenuButton
    local lockButton = vipWindow:recursiveGetChildById('lockButton')
    if lockButton and contextMenuButton then
        lockButton:addAnchor(AnchorTop, contextMenuButton:getId(), AnchorTop)
        lockButton:addAnchor(AnchorRight, contextMenuButton:getId(), AnchorLeft)
        lockButton:setMarginRight(2)
    end
    
    -- Hide newWindowButton
    local newWindowButton = vipWindow:recursiveGetChildById('newWindowButton')
    if newWindowButton then
        newWindowButton:setVisible(false)
    end

    if g_game.isOnline() then
        vipWindow:setupOnStart()
    end
end

function controllerVip:onTerminate()
    Keybind.delete("Windows", "Show/hide VIP list")
    local ArrayWidgets = {addVipWindow, editVipWindow, vipWindow, vipButton, addGroupWindow}
    for _, widget in ipairs(ArrayWidgets) do
        if widget ~= nil or widget then
            widget:destroy()
            widget = nil
        end
    end
    vipInfo = {}
end

function controllerVip:onGameStart()
    if not g_game.getFeature(GameAdditionalVipInfo) then
        loadVipInfo()
    end
    if not g_game.getFeature(GameVipGroups) then
        vipWindow.miniborder:hide()
        globalSettings.showGrouped = false
    else
        vipInfo = {}
    end
    vipWindow:setupOnStart() -- load character window configuration
    refresh()
    vipButton:setOn(vipButton:isOn())
end

function controllerVip:onGameEnd()
    local settings = {}
    settings['Grouped'] = globalSettings.showGrouped or false
    settings['OfflineVips'] = globalSettings.hideOfflineVips or false
    settings['vipSortOrder'] = globalSettings.vipSortOrder or {}
    if not g_game.getFeature(GameVipGroups) then
        saveVipInfo()
    end
    g_settings.mergeNode('VipList', settings)

    vipWindow:setParent(nil, true)
    clear()
    if editVipWindow then
        editVipWindow:destroy()
        editVipWindow = nil
    end
    if addGroupWindow then
        addGroupWindow:destroy()
        addGroupWindow = nil
    end
end

function loadVipInfo()
    local settings = g_settings.getNode('VipList')
    if not settings then
        vipInfo = {}
        return
    end
    vipInfo = settings['VipInfo'] or {}
end

function saveVipInfo()
    if not g_game.getFeature(GameAdditionalVipInfo) then
        if not g_settings.getNode('VipList') then
            g_settings.setNode('VipList', {})
        end
        local settings = {}
        settings['VipInfo'] = vipInfo
        g_settings.mergeNode('VipList', settings)
    end
end

function refresh()
    clear()
    for id, vip in pairs(g_game.getVips()) do
        onAddVip(id, unpack(vip))
    end

    vipWindow:setContentMinimumHeight(38)
end

function clear()
    local vipList = vipWindow:getChildById('contentsPanel')
    vipList:destroyChildren()
    if not g_game.isOnline() then
        if g_game.getFeature(GameAdditionalVipInfo) then
            vipInfo = {}
            vipGroups = {}
        end
    end
    if editVipWindow ~= nil or editVipWindow then
        editVipWindow:hide()
    end
end

function toggle()
    if vipButton:isOn() then
        vipWindow:close()
        vipButton:setOn(false)
    else
        if not vipWindow:getParent() then
            local panel = modules.game_interface.findContentPanelAvailable(vipWindow, vipWindow:getMinimumHeight())
            if not panel then
                return
            end

            panel:addChild(vipWindow)
        end
        vipWindow:open()
        vipButton:setOn(true)
    end
end

function onMiniWindowOpen()
    vipButton:setOn(true)
end

function onMiniWindowClose()
    vipButton:setOn(false)
end

function createAddWindow()
    if addVipWindow then
        addVipWindow:destroy()
        addVipWindow = nil
    end
    
    addVipWindow = g_ui.displayUI('addvip')
    addVipWindow:show()
    
    local nameInput = addVipWindow:getChildById('name')
    nameInput:setText('')
    nameInput:focus()
    
    local function closeWindow()
        nameInput:setText('')
        addVipWindow:setVisible(false)
        addVipWindow:destroy()
        addVipWindow = nil
    end
    
    addVipWindow.buttonOk.onClick = function()
        local playerName = nameInput:getText()
        if playerName and playerName ~= '' then
            g_game.addVip(playerName)
        end
        closeWindow()
    end
    
    addVipWindow.closeButton.onClick = closeWindow
    addVipWindow.onEscape = closeWindow
    
    nameInput.onKeyDown = function(widget, keyCode, keyboardModifiers)
        if keyCode == KeyReturn or keyCode == KeyEnter then
            addVipWindow.buttonOk.onClick()
            return true
        elseif keyCode == KeyEscape then
            closeWindow()
            return true
        end
        return false
    end
end

function createEditWindow(widget)
    if editVipWindow then
        return
    end

    editVipWindow = g_ui.displayUI('editvip')

    local name = widget:getText()
    local id = widget:getId():sub(4)
    -- @Groups
    if not g_game.getFeature(GameVipGroups) then
        editVipWindow:setText('Edit VIP')
        editVipWindow:setSize('272 170')
    else
        editVipWindow:setHeight(350 + 2 * (#vipGroups))
    end
    editVipWindow.groups:destroyChildren()
    table.sort(vipGroups, function(a, b)
        return a[1] > b[1]
    end)
    for _, group in ipairs(vipGroups) do
        local groupBox = g_ui.createWidget('VipGroupBox', editVipWindow.groups)
        groupBox:setText(group[2])
        groupBox.id = group[1]
        groupBox:setChecked(checkPlayerGroup(name, group[1]))
    end
    -- @
    local okButton = editVipWindow:getChildById('buttonOK')
    local cancelButton = editVipWindow:getChildById('buttonCancel')

    local nameLabel = editVipWindow:getChildById('nameLabel')
    nameLabel:setText(name)

    local descriptionText = editVipWindow:getChildById('descriptionText')
    descriptionText:appendText(widget:getTooltip())

    local notifyCheckBox = editVipWindow:recursiveGetChildById('checkBoxNotify')
    notifyCheckBox:setChecked(widget.notifyLogin)

    local iconRadioGroup = UIRadioGroup.create()
    for i = VipIconFirst, VipIconLast do
        iconRadioGroup:addWidget(editVipWindow:recursiveGetChildById('icon' .. i))
    end
    if not widget.iconId then
        widget.iconId = 0
    end
    iconRadioGroup:selectWidget(editVipWindow:recursiveGetChildById('icon' .. widget.iconId))

    local cancelFunction = function()
        editVipWindow:destroy()
        iconRadioGroup:destroy()
        editVipWindow = nil
    end

    local saveFunction = function()
        local vipList = vipWindow:getChildById('contentsPanel')
        if not widget then
            cancelFunction()
            return
        end

        local name = widget:getText()
        local state = widget.vipState
        local description = descriptionText:getText()
        local iconId = tonumber(iconRadioGroup:getSelectedWidget():getId():sub(5))
        if not iconId then
            iconId = 0
        end
        local notify = notifyCheckBox:isChecked()
        local groups = {}
        for _, child in pairs(editVipWindow.groups:getChildren()) do
            if child:isChecked() then
                table.insert(groups, child.id)
            end
        end
        if g_game.getFeature(GameAdditionalVipInfo) then
            g_game.editVip(id, description, iconId, notify, groups)
        else
            if notify ~= false or #description > 0 or iconId > 0 then
                vipInfo[name] = {
                    description = description,
                    iconId = iconId,
                    notifyLogin = notify
                }
            else
                vipInfo[name] = nil
            end
        end

        widget:destroy()
        onAddVip(id, name, state, description, iconId, notify, groups, nil)
        
        if iconRadioGroup then
            iconRadioGroup:destroy()
            iconRadioGroup = nil
        end
        if editVipWindow then
            editVipWindow:destroy()
            editVipWindow = nil
        end
    end

    cancelButton.onClick = cancelFunction
    okButton.onClick = saveFunction

    editVipWindow.onEscape = cancelFunction
    editVipWindow.onEnter = saveFunction
end

function destroyAddWindow()
    if addVipWindow then
        addVipWindow:setVisible(false)
        addVipWindow:destroy()
        addVipWindow = nil
    end
end

function addVip()
    -- This function is now handled by the FloatingInputWindow's button events
    -- The actual VIP addition is done in createAddWindow's buttonOk.onClick
    if addVipWindow then
        local nameInput = addVipWindow:getChildById('name')
        local playerName = nameInput:getText()
        if playerName and playerName ~= '' then
            g_game.addVip(playerName)
            destroyAddWindow()
        end
    end
end

function removeVip(widgetOrName)
    if not widgetOrName then
        return
    end

    local widget
    local vipList = vipWindow:getChildById('contentsPanel')
    if type(widgetOrName) == 'string' then
        local entries = vipList:getChildren()
        for i = 1, #entries do
            if entries[i]:getText():lower() == widgetOrName:lower() then
                widget = entries[i]
                break
            end
        end
        if not widget then
            return
        end
    else
        widget = widgetOrName
    end

    if widget then
        local id = widget:getId():sub(4)
        local name = widget:getText()
        g_game.removeVip(id)
        if g_game.getFeature(GameVipGroups) and  globalSettings.showGrouped then
            widget:getParent():removeChild(widget)
        else
            vipList:removeChild(widget)
        end
        if vipInfo[name:lower()] and g_game.getFeature(GameAdditionalVipInfo) then
            vipInfo[name:lower()] = nil
        end
        refresh()
    end
end

function hideOffline(state)
    globalSettings.hideOfflineVips = state
    refresh()
end

function isHiddingOffline()
    local settings = g_settings.getNode('VipList')
    if not settings then
        return false
    end
    return settings['hideOffline']
end

function getSortedBy()
    if g_game.getFeature(GameAdditionalVipInfo) then 
        if not globalSettings.vipSortOrder then
            return ''
        end
        return globalSettings.vipSortOrder[1]
    else
        local settings = g_settings.getNode('VipList')
        if not settings or not settings['sortedBy'] then
            return 'status'
        end
        return settings['sortedBy']
    end
end

function sortBy(state)
    if not g_game.getFeature(GameAdditionalVipInfo) then
        local settings = {}
        settings['sortedBy'] = state
        g_settings.mergeNode('VipList', settings)
    end
    for i, v in ipairs(globalSettings.vipSortOrder) do
        if v == state then
            table.remove(globalSettings.vipSortOrder, i)
            break
        end
    end
    table.insert(globalSettings.vipSortOrder, 1, state)
    local contentPanel = vipWindow:getChildById('contentsPanel')
    if g_game.getFeature(GameVipGroups) and globalSettings.showGrouped then
        for _, groupWidget in ipairs(contentPanel:getChildren()) do
            if groupWidget:getId():find('group-') == 1 then
                local groupPanel = groupWidget:getChildById('panel')
                local children = groupPanel:getChildren()
                table.sort(children, compareVips)
                for i, child in ipairs(children) do
                    groupPanel:moveChildToIndex(child, i)
                end
            end
        end
    else
        local children = contentPanel:getChildren()
        table.sort(children, compareVips)
        for i, child in ipairs(children) do
            contentPanel:moveChildToIndex(child, i)
        end
    end
    contentPanel:updateLayout()
end

function compareVips(a, b)
    for _, orderType in ipairs(globalSettings.vipSortOrder) do
        if orderType == 'byState' or orderType == 'status' then
            if a.vipState ~= nil and b.vipState ~= nil then
                if a.vipState ~= b.vipState then
                    return a.vipState > b.vipState
                end
            end
        elseif orderType == 'byName' or orderType == 'name' then
            if a:getText() ~= nil and b:getText() ~= nil then
                if a:getText():lower() ~= b:getText():lower() then
                    return a:getText():lower() < b:getText():lower()
                end
            end
        elseif orderType == 'byType' or orderType == 'type' then
            if a.iconId ~= nil and b.iconId ~= nil then
                if a.iconId ~= b.iconId then
                    return a.iconId > b.iconId
                end
            end
        end
    end
    return false
end

function onAddVip(id, name, state, description, iconId, notify, groupID, bool)
    if g_game.getFeature(GameAdditionalVipInfo) then
        vipInfo[name] = {
            playerId = id,
            playerName = name,
            vipState = state,
            vipDesc = description,
            icon = iconId,
            hasNotify = notify,
            vipGroups = groupID
        }
        if globalSettings.showGrouped then
            showGroups()
            return
        end
    end
    local vipList = vipWindow:getChildById('contentsPanel')
    local childrenContentPanel = vipList:getChildCount()

    if bool then
        for i = 1, childrenContentPanel do
            local vipName = vipList:getChildByIndex(i)

            if vipName:getText() == name then
                setVipState(vipName, state)
                if state == VipState.Online then
                    vipName:setVisible(true)
                elseif state == VipState.Offline and globalSettings.hideOfflineVips then
                    vipName:setVisible(false)
                end
                return
            end
        end
    end

    for j = 1, childrenContentPanel do
        if vipList:getChildByIndex(j):getText() == name then
            return
        end
    end

    local label = g_ui.createWidget('VipListLabel')
    label.onMousePress = onVipListLabelMousePress
    label:setId('vip' .. id)
    label:setText(name)

    if not g_game.getFeature(GameAdditionalVipInfo) then
        local tmpVipInfo = vipInfo[name]
        label.iconId = 0
        label.notifyLogin = false
        if tmpVipInfo then
            if tmpVipInfo.iconId then
                label:setImageClip(torect((tmpVipInfo.iconId * 12) .. ' 0 12 12'))
                label.iconId = tmpVipInfo.iconId
            end
            if tmpVipInfo.description then
                label:setTooltip(tmpVipInfo.description)
            end
            label.notifyLogin = tmpVipInfo.notifyLogin or false
        end
    else
        label:setTooltip(description)
        label:setImageClip(torect((iconId * 12) .. ' 0 12 12'))
        label.iconId = iconId
        label.notifyLogin = notify
    end

    setVipState(label, state)

    label.vipState = state

    label:setPhantom(false)
    connect(label, {
        onDoubleClick = function()
            g_game.openPrivateChannel(label:getText())
            return true
        end
    })

    if state == VipState.Offline and globalSettings.hideOfflineVips then
        label:setVisible(false)
    end

    local nameLower = name:lower()
    local childrenCount = vipList:getChildCount()

    for i = 1, childrenCount do
        local child = vipList:getChildByIndex(i)
        if (state == VipState.Online and child.vipState ~= VipState.Online and getSortedBy() == 'status') or
            (label.iconId > child.iconId and getSortedBy() == 'type') then
            vipList:insertChild(i, label)
            return
        end

        if (((state ~= VipState.Online and child.vipState ~= VipState.Online) or
            (state == VipState.Online and child.vipState == VipState.Online)) and getSortedBy() == 'status') or
            (label.iconId == child.iconId and getSortedBy() == 'type') or getSortedBy() == 'name' then

            local childText = child:getText():lower()
            local length = math.min(childText:len(), nameLower:len())

            for j = 1, length do
                if nameLower:byte(j) < childText:byte(j) then
                    vipList:insertChild(i, label)
                    return
                elseif nameLower:byte(j) > childText:byte(j) then
                    break
                elseif j == nameLower:len() then -- We are at the end of nameLower, and its shorter than childText, thus insert before
                    vipList:insertChild(i, label)
                    return
                end
            end
        end
    end

    vipList:insertChild(childrenCount + 1, label)
end

function onVipStateChange(id, state, groupID)
    if g_game.getFeature(GameVipGroups) and globalSettings.showGrouped then
        local name, description, iconId, notify = searchPlayerbyId(id)
        onAddVip(id, name, state, description, iconId, notify, groupID, true)
    else
        local vipList = vipWindow:getChildById('contentsPanel')
        local label = vipList:getChildById('vip' .. id)
        local name = label:getText()
        local description = label:getTooltip()
        local iconId = label.iconId
        local notify = label.notifyLogin
        label:destroy()
    
        onAddVip(id, name, state, description, iconId, notify)
    end

    if notify and state ~= VipState.Pending then
        modules.game_textmessage.displayFailureMessage(state == VipState.Online and tr('%s has logged in.', name) or
                                                           tr('%s has logged out.', name))
    end
end

function onVipListMousePress(widget, mousePos, mouseButton)
    if mouseButton ~= MouseRightButton then
        return
    end

    local vipList = vipWindow:getChildById('contentsPanel')

    local menu = g_ui.createWidget('PopupMenu')
    menu:setGameMenu(true)
    menu:addOption(tr('Add new VIP'), function()
        createAddWindow()
    end)

    menu:addSeparator()

        if g_game.getFeature(GameVipGroups) then
        menu:addOption(tr('Add new group'), function()
            createAddGroupWindow()
        end)
    end

    menu:addSeparator()
    if not (getSortedBy() == 'name') then
        menu:addOption(tr('Sort by name'), function()
            sortBy('name')
        end)
    end

    if not (getSortedBy() == 'type') then
        menu:addOption(tr('Sort by type'), function()
            sortBy('type')
        end)
    end

    if not (getSortedBy() == 'status') then
        menu:addOption(tr('Sort by status'), function()
            sortBy('status')
        end)
    end

    if not globalSettings.hideOfflineVips then
        menu:addOption(tr('Hide offline VIPs'), function()
            hideOffline(true)
        end)
    else
        menu:addOption(tr('Show offline VIPs'), function()
            hideOffline(false)
        end)
    end

    if g_game.getFeature(GameVipGroups) then
        if not globalSettings.showGrouped then
            menu:addOption(tr('Show groups'), function()
                globalSettings.showGrouped = true
                showGroups()
            end)
        else
            menu:addOption(tr('Hide groups'), function()
                globalSettings.showGrouped = false
                refresh()
            end)
        end
    end
    
    -- Calculate proper menu position
    local menuPos = {x = mousePos.x, y = mousePos.y}
    local menuSize = menu:getSize()
    local screenSize = g_window.getSize()
    
    -- Adjust horizontal position if menu would go off screen
    if menuPos.x + menuSize.width > screenSize.width then
        menuPos.x = screenSize.width - menuSize.width
    end
    
    -- Adjust vertical position if menu would go off screen
    if menuPos.y + menuSize.height > screenSize.height then
        menuPos.y = screenSize.height - menuSize.height
    end
    
    -- Ensure menu doesn't go off the left or top edges
    if menuPos.x < 0 then
        menuPos.x = 0
    end
    if menuPos.y < 0 then
        menuPos.y = 0
    end
    
    menu:display(menuPos)

    return true
end

function onVipListLabelMousePress(widget, mousePos, mouseButton)
    if mouseButton ~= MouseRightButton then
        return
    end

    local vipList = vipWindow:getChildById('contentsPanel')
    local isGroup = string.find(widget:getId(), 'group')
    local isVip = string.find(widget:getId(), 'vip')

    local menu = g_ui.createWidget('PopupMenu')
    menu:setGameMenu(true)
    if not isGroup then
        menu:addOption(tr('Edit %s', widget:getText()), function()
            if widget then
                createEditWindow(widget)
            end
        end)
        menu:addOption(tr('Remove %s', widget:getText()), function()
            if widget then
                removeVip(widget)
            end
        end)

        if isVip and widget.vipState == VipState.Online then
            menu:addOption(tr('Message to %s', widget:getText()), function()
                g_game.openPrivateChannel(widget:getText())
            end)
        end
    end

    menu:addOption(tr('Add new VIP'), function()
        createAddWindow()
    end)
    if modules.game_console.getOwnPrivateTab() then
        menu:addSeparator()
        menu:addOption(tr('Invite to private chat'), function()
            g_game.inviteToOwnChannel(widget:getText())
        end)
        menu:addOption(tr('Exclude from private chat'), function()
            g_game.excludeFromOwnChannel(widget:getText())
        end)
    end
    if g_game.getFeature(GameVipGroups) then
        menu:addSeparator()
        if isGroup and widget.editable then
            local groupName = widget:getTooltip() and widget:getTooltip() or widget.group:getText()

            menu:addOption(tr('Edit group %s', groupName), function()
                createEditGroupWindow(groupName, widget.groupId)
            end)
            menu:addOption(tr('Remove group %s', groupName), function()
                g_game.editVipGroups(3, widget.groupId, '')
            end)
        end

        menu:addOption(tr('Add new group'), function()
            createAddGroupWindow()
        end)
    end

    menu:addSeparator()
    if not globalSettings.hideOfflineVips then
        menu:addOption(tr('Hide offline VIPs'), function()
            hideOffline(true)
        end)
    else
        menu:addOption(tr('Show offline VIPs'), function()
            hideOffline(false)
        end)
    end

    menu:addOption(tr('Sort by name'), function()
        sortBy('byName')
    end)
    menu:addOption(tr('Sort by type'), function()
        sortBy('byType')
    end)
    menu:addOption(tr('Sort by status'), function()
        sortBy('byState')
    end)

    if g_game.getFeature(GameVipGroups) then
        if not globalSettings.showGrouped then
            menu:addOption(tr('Show groups'), function()
                globalSettings.showGrouped = true
                showGroups()
            end)
        else
            menu:addOption(tr('Hide groups'), function()
                globalSettings.showGrouped = false
                refresh()
            end)
        end
    end

    if not isGroup then
        menu:addSeparator()
        menu:addOption(tr('Copy Name'), function()
            g_window.setClipboardText(widget:getText())
        end)
    end

    -- Calculate proper menu position
    local menuPos = {x = mousePos.x, y = mousePos.y}
    local menuSize = menu:getSize()
    local screenSize = g_window.getSize()
    
    -- Adjust horizontal position if menu would go off screen
    if menuPos.x + menuSize.width > screenSize.width then
        menuPos.x = screenSize.width - menuSize.width
    end
    
    -- Adjust vertical position if menu would go off screen
    if menuPos.y + menuSize.height > screenSize.height then
        menuPos.y = screenSize.height - menuSize.height
    end
    
    -- Ensure menu doesn't go off the left or top edges
    if menuPos.x < 0 then
        menuPos.x = 0
    end
    if menuPos.y < 0 then
        menuPos.y = 0
    end

    menu:display(menuPos)

    return true
end

-- @ groups
function onVipGroupChange(vipGroupsArray, groupsAmountLeft)
    vipGroups = vipGroupsArray
    maxVipGroups = groupsAmountLeft
    editableGroupCount = groupsAmountLeft
    refresh()
end

function createAddGroupWindow()
    if maxVipGroups < 1 then
        displayInfoBox(tr('Maximum of User-Created Groups Reached'),
            'You have already reached the maximum of groups you can create yourself.')
        return
    end
    
    if addGroupWindow then
        addGroupWindow:destroy()
        addGroupWindow = nil
    end
    
    addGroupWindow = g_ui.displayUI('addgroup')
    addGroupWindow:show()
    
    local nameInput = addGroupWindow:getChildById('name')
    nameInput:setText('')
    nameInput:focus()
    
    local function closeWindow()
        destroyAddGroupWindow()
    end
    
    -- The OK button click is handled by the OTUI @onClick event
    -- Just set up the close button and escape handlers
    addGroupWindow.closeButton.onClick = closeWindow
    addGroupWindow.onEscape = closeWindow
    
    nameInput.onKeyDown = function(widget, keyCode, keyboardModifiers)
        if keyCode == KeyReturn or keyCode == KeyEnter then
            addGroup() -- Call the main addGroup function
            return true
        elseif keyCode == KeyEscape then
            closeWindow()
            return true
        end
        return false
    end
end

function createEditGroupWindow(groupName, groupId)
    if addGroupWindow then
        addGroupWindow:destroy()
        addGroupWindow = nil
    end
    
    addGroupWindow = g_ui.displayUI('addgroup')
    addGroupWindow:show()
    
    -- Update header text for edit mode
    local headerLabel = addGroupWindow:getChildById('headerLabel')
    if headerLabel then
        headerLabel:setText(tr('Edit VIP Group'))
    end
    
    local nameInput = addGroupWindow:getChildById('name')
    nameInput:setText(groupName)
    nameInput:focus()
    nameInput:selectAll()
    
    local function closeWindow()
        nameInput:setText('')
        addGroupWindow:setVisible(false)
        addGroupWindow:destroy()
        addGroupWindow = nil
    end
    
    addGroupWindow.buttonOk.onClick = function()
        local newGroupName = nameInput:getText()
        if newGroupName and newGroupName ~= '' then
            g_game.editVipGroups(2, groupId, newGroupName)
        end
        closeWindow()
    end
    
    addGroupWindow.closeButton.onClick = closeWindow
    addGroupWindow.onEscape = closeWindow
    
    nameInput.onKeyDown = function(widget, keyCode, keyboardModifiers)
        if keyCode == KeyReturn or keyCode == KeyEnter then
            addGroupWindow.buttonOk.onClick()
            return true
        elseif keyCode == KeyEscape then
            closeWindow()
            return true
        end
        return false
    end
end

function addGroup()
    -- This function is called from the OTUI @onClick event
    -- Get the input from the current addGroupWindow
    if addGroupWindow then
        local nameInput = addGroupWindow:getChildById('name')
        local groupName = nameInput:getText()
        if groupName and groupName ~= '' then
            g_game.editVipGroups(1, 0, groupName)
            destroyAddGroupWindow()
        end
    end
end

function destroyAddGroupWindow()
    if addGroupWindow then
        addGroupWindow:destroy()
        addGroupWindow = nil
    end
end

function editGroup(groupId)
    g_game.editVipGroups(2, groupId, addGroupWindow:getChildById('name'):getText())
    if addGroupWindow then
        addGroupWindow:destroy()
        addGroupWindow = nil
    end
end

function getPlayersByGroup(groupId)
    local playerFromGroupID = {}
    for id, data in pairs(vipInfo) do
        if data.vipGroups and table.contains(data.vipGroups, groupId) then
            table.insert(playerFromGroupID, data)
        end
    end
    return playerFromGroupID
end

function getPlayersNoGroup()
    local playerFromNoGroup = {}
    for id, data in pairs(vipInfo) do
        if not data.vipGroups or #data.vipGroups == 0 then
            table.insert(playerFromNoGroup, data)
        end
    end
    return playerFromNoGroup
end

function showGroups(sortType)
    local contentsPanel = vipWindow:getChildById('contentsPanel')
    contentsPanel:destroyChildren()

    table.sort(vipGroups, function(a, b)
        return a[2] < b[2]
    end)

    local function createPlayerWidget(group, player)
        if not player.playerId then -- prevent error cache config.otml
            return
        end
        local playerWidget = g_ui.createWidget('VipListLabel', group.panel)
        playerWidget.onMousePress = onVipListLabelMousePress
        playerWidget:setId('vip' .. player.playerId)
        playerWidget:setText(player.playerName)
        playerWidget:setImageClip(torect(player.icon * 12 .. ' 0 12 12'))
        playerWidget.iconId = player.icon
        playerWidget.notifyLogin = player.hasNotify
        playerWidget.vipState = player.vipState

        setVipState(playerWidget, player.vipState)
        playerWidget:setPhantom(false)

        connect(playerWidget, {
            onDoubleClick = function()
                g_game.openPrivateChannel(playerWidget:getText())
                return true
            end
        })
        return playerWidget
    end

    for _, group in ipairs(vipGroups) do
        local groupId, groupName, isEditable = group[1], group[2], group[3]
        local playersInGroup = getPlayersByGroup(groupId)

        if #playersInGroup > 0 then
            local groupWidget = g_ui.createWidget('VipGroupList', contentsPanel)
            groupWidget.group:setText(groupName)
            if #groupName >= 18 then
                groupWidget:setTooltip(groupName)
            end
            groupWidget:setId('group-' .. groupId)
            groupWidget.onMousePress = onVipListLabelMousePress
            groupWidget.groupId = groupId
            groupWidget.editable = isEditable

            local visiblePlayers = 0
            for _, player in ipairs(playersInGroup) do
                if player.icon == nil then
                    break
                end
                local playerWidget = createPlayerWidget(groupWidget, player)
                if player.vipState == VipState.Offline and globalSettings.hideOfflineVips then
                    playerWidget:setVisible(false)
                else
                    visiblePlayers = visiblePlayers + 1
                end
            end

            if visiblePlayers == 0 then
                groupWidget:hide()
            else
                groupWidget:setSize('156 ' .. (16 * visiblePlayers + groupWidget:getHeight()))
            end
        end
    end

    local playersNoGroup = getPlayersNoGroup()
    if #playersNoGroup > 0 then
        local noGroupWidget = g_ui.createWidget('VipGroupList', contentsPanel)
        noGroupWidget.onMousePress = onVipListLabelMousePress
        noGroupWidget:setId('group')

        local visiblePlayers = 0
        for _, player in ipairs(playersNoGroup) do
            local playerWidget = createPlayerWidget(noGroupWidget, player)
            if player.vipState == VipState.Offline and globalSettings.hideOfflineVips then
                playerWidget:setVisible(false)
            else
                visiblePlayers = visiblePlayers + 1
            end
        end

        if visiblePlayers == 0 then
            noGroupWidget:hide()
        else
            noGroupWidget:setSize('156 ' .. (15 * visiblePlayers + noGroupWidget:getHeight()))
        end
    end
    -- contentsPanel:updateLayout()
    sortBy(getSortedBy())
end

function setVipState(widget, vipState)
    if vipState == VipState.Online then
        widget:setColor('#5ff75f')
    end
    if vipState == VipState.Pending then
        widget:setColor('#ffca38')
    elseif vipState == VipState.Offline then
        widget:setColor('#f75f5f')
    elseif vipState == VipState.Training then
        widget:setColor('#f75f5f')
    end
end

function getPlayerGroups(playerName)
    local playerGroups = {}
    for id, vip in pairs(g_game.getVips()) do
        if vip[1] == playerName then
            playerGroups = vip[6]
            break
        end
    end
    return playerGroups
end

function checkPlayerGroup(playerName, groupId)
    local vips = g_game.getVips()
    for _, vip in pairs(vips) do
        if vip[1] == playerName then
            local playerGroups = vip[6]
            for _, playerGroup in ipairs(playerGroups) do
                if playerGroup == groupId then
                    return true
                end
            end
            return false
        end
    end
    return false
end

function searchPlayerbyId(playerId)
    for key, idCache in pairs(vipInfo) do
        if tonumber(idCache.playerId) == playerId then
            local name = idCache.playerName
            local description = idCache.vipDesc
            local iconId = idCache.icon
            local notify = idCache.hasNotify

            return name, description, iconId, notify
        end
    end
end

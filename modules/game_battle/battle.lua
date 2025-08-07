-- Global Tables for main battle list
local binaryTree = {}    -- BST
local battleButtons = {} -- map of creature id

-- Global variables that will inherit from init
local battleWindow, battleButton, battlePanel, mouseWidget, filterPanel, toggleFilterButton
local lastBattleButtonSwitched, lastCreatureSelected

-- Forward declarations for functions used in BattleButtonPool
local onBattleButtonHoverChange, onBattleButtonMouseRelease

-- Forward declaration for BattleListInstance
BattleListInstance = nil

-- Battle Button Pool - will be initialized in init()
BattleButtonPool = nil

-- Utility function for table copying
function table.copy(t)
    if type(t) ~= "table" then return t end
    local meta = getmetatable(t)
    local target = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            target[k] = table.copy(v)
        else
            target[k] = v
        end
    end
    setmetatable(target, meta)
    return target
end

-- Utility function for table size
function table.size(t)
    if type(t) ~= "table" then return 0 end
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- Default filter settings for ordering/sorting
local BATTLE_FILTERS = {
    -- Sort "Age"
    ["sortAscByDisplayTime"] = false,
    ["sortDescByDisplayTime"] = false,  -- Default sort option
    -- Sort Distance
    ["sortAscByDistance"] = false,
    ["sortDescByDistance"] = false,
    -- Sort HP
    ["sortAscByHitPoints"] = false,
    ["sortDescByHitPoints"] = false,
    -- Sort Names
    ["sortAscByName"] = false,
    ["sortDescByName"] = false
}

-- Battle List Manager for handling multiple battle list instances
local BattleListManager = {
    instances = {},
    nextId = 1,
    autoSaveEvent = nil,
    isRestoring = false
}

function BattleListManager:saveInstancesState()
    local instancesData = {}
    for id, instance in pairs(self.instances) do
        if id ~= 0 then -- Don't save main instance as it's always created
            local windowPos = instance.window and instance.window:getPosition()
            local windowSize = instance.window and instance.window:getSize()
            local isLocked = instance.window and instance.window:getSettings('locked') or false
            instancesData[id] = {
                id = instance.id,
                name = instance:getName(),
                isOpen = instance.window and instance.window:isVisible(),
                windowPos = windowPos,
                windowSize = windowSize,
                isHidingFilters = instance:isHidingFilters(),
                isLocked = isLocked
            }
            -- Make sure ALL instance settings are saved
            instance:saveFilters()
            instance:saveHideButtonStates()
            print("DEBUG: Saved settings for instance", id, ":")
            print("  - name:", instance:getName())
            print("  - isOpen:", instance.window and instance.window:isVisible())
            print("  - windowPos:", windowPos)
            print("  - windowSize:", windowSize)
            print("  - isHidingFilters:", instance:isHidingFilters())
            print("  - isLocked:", isLocked)
        end
    end
    g_settings.mergeNode('BattleListInstances', instancesData)
    print("DEBUG: Saved", table.size(instancesData), "battle list instances state to g_settings")
end

function BattleListManager:restoreInstancesState()
    local instancesData = g_settings.getNode('BattleListInstances')
    if not instancesData then
        print("DEBUG: No saved battle list instances to restore")
        return
    end
    
    -- Check if we already have non-main instances running
    local hasExistingInstances = false
    for id, instance in pairs(self.instances) do
        if id ~= 0 then
            hasExistingInstances = true
            break
        end
    end
    
    if hasExistingInstances then
        print("DEBUG: Non-main instances already exist, skipping restoration to avoid duplicates")
        -- Clear the saved data since we're not restoring
        g_settings.mergeNode('BattleListInstances', {})
        return
    end
    
    self.isRestoring = true
    print("DEBUG: Restoring battle list instances...")
    for id, data in pairs(instancesData) do
        if tonumber(id) and tonumber(id) > 0 then -- Only restore non-main instances
            -- Only restore instances that were actually open when the game ended
            if data.isOpen then
                print("DEBUG: Restoring open instance", id, "with name:", data.name)
                
                local oldSettingsKey = 'BattleList_' .. id
                local oldSettings = g_settings.getNode(oldSettingsKey)
                local shouldRestoreSettings = oldSettings ~= nil
                
                if shouldRestoreSettings then
                    print("DEBUG: Found settings to restore for instance", id)
                else
                    print("DEBUG: No settings found for instance", id, "- will start fresh")
                end
                
                -- Create a fresh instance with the saved name
                local customName = data.name and data.name ~= tr('Battle List') and data.name or nil
                local instance = self:createNewInstance(customName)
                
                if instance and instance.window then
                    -- If we have settings to restore, copy them to the new instance
                    if shouldRestoreSettings and oldSettings then
                        local newSettingsKey = instance:getSettingsKey()
                        
                        print("DEBUG: About to restore settings for instance. Old settings:")
                        print("  - filters:", oldSettings.filters)
                        print("  - hideButtons:", oldSettings.hideButtons)
                        print("  - old customName:", oldSettings.customName)
                        
                        -- Copy old settings but preserve the correct custom name from saved data
                        local settingsToRestore = table.copy(oldSettings)
                        settingsToRestore.customName = data.name  -- Ensure the saved name takes precedence
                        
                        g_settings.mergeNode(newSettingsKey, settingsToRestore)
                        print("DEBUG: Copied settings from", oldSettingsKey, "to", newSettingsKey, "with name:", data.name)
                        
                        -- Update the instance name and title to reflect the restored name
                        instance.name = data.name
                        instance:updateTitle()
                        
                        -- Reload hide button states since they were copied to the new settings key
                        -- This needs to happen after createWindowForInstance has already called loadHideButtonStates
                        scheduleEvent(function()
                            instance:loadHideButtonStates()
                            print("DEBUG: Reloaded hide button states for restored instance", instance.id)
                            
                            -- Also verify the filters were restored correctly
                            local restoredFilters = instance:loadFilters()
                            print("DEBUG: Restored filters for instance", instance.id, ":", restoredFilters)
                            
                            -- Load the lock state from the copied settings
                            instance:loadLockState()
                        end, 50)
                    end
                    
                    -- Restore window properties
                    if data.windowPos then
                        instance.window:setPosition(data.windowPos)
                    end
                    if data.windowSize then
                        instance.window:setSize(data.windowSize)
                    end
                    -- Instance was open, so keep it visible (this is the default anyway)
                    
                    -- Restore lock button state
                    if data.isLocked then
                        instance.window:lock(true) -- true = don't save during restoration
                        print("DEBUG: Restored lock state (locked) for instance", instance.id)
                    else
                        instance.window:unlock(true) -- true = don't save during restoration
                        print("DEBUG: Restored lock state (unlocked) for instance", instance.id)
                    end
                    
                    -- Restore filter panel state after window is fully setup
                    scheduleEvent(function()
                        -- Ensure the panel has originalHeight set for proper show/hide functionality
                        if not instance.filterPanel.originalHeight then
                            instance.filterPanel.originalHeight = instance.filterPanel:getHeight()
                        end
                        
                        if data.isHidingFilters then
                            instance:hideFilterPanel()
                        else
                            instance:showFilterPanel()
                        end
                    end, 100)
                    
                    -- Clean up the old settings since we've either restored them or don't need them
                    g_settings.set(oldSettingsKey, nil)
                    
                    print("DEBUG: Restored battle list instance with new ID", instance.id, "and name:", instance:getName())
                end
            else
                -- Instance was closed when game ended, so we don't restore it but we should clean up its settings
                local oldSettingsKey = 'BattleList_' .. id
                g_settings.set(oldSettingsKey, nil)
                print("DEBUG: Cleaned up settings for closed instance", id)
            end
        end
    end
    
    -- Clean up any remaining orphaned settings from previous sessions
    local allSettings = g_settings.getNode() or {}
    for key, _ in pairs(allSettings) do
        if type(key) == 'string' and key:match('^BattleList_%d+$') then
            local instanceId = tonumber(key:match('%d+'))
            if instanceId and instanceId > 0 then -- Don't touch main instance (ID 0)
                g_settings.set(key, nil) -- Remove orphaned settings
                print("DEBUG: Cleaned up remaining orphaned settings for:", key)
            end
        end
    end
    
    -- Clear the old saved instances data since we've restored them with new IDs
    g_settings.mergeNode('BattleListInstances', {})
    print("DEBUG: Cleared old saved instances data after restoration")
    
    self.isRestoring = false
end

function BattleListManager:getMainInstance()
    return self.instances[0]
end

function BattleListManager:createNewInstance(customName)
    print("DEBUG: Creating new battle list instance...")
    local instance = BattleListInstance:new(self.nextId, customName)
    self.instances[self.nextId] = instance
    self.nextId = self.nextId + 1
    
    print("DEBUG: Instance created with ID:", instance.id)
    
    -- Create the window for this instance
    self:createWindowForInstance(instance)
    
    print("DEBUG: Window created for instance:", instance.id)
    return instance
end

function BattleListManager:createWindowForInstance(instance)
    -- Create a new battle window
    local newWindow = g_ui.loadUI('battle')
    instance.window = newWindow
    
    -- Set unique ID for this window
    newWindow:setId('battleWindow_' .. instance.id)
    
    -- Get panels and controls
    instance.panel = newWindow:recursiveGetChildById('battlePanel')
    instance.filterPanel = newWindow:recursiveGetChildById('filterPanel')
    instance.toggleFilterButton = newWindow:recursiveGetChildById('toggleFilterButton')
    
    -- Update the title
    instance:updateTitle()
    
    -- Setup filter buttons for this instance
    local hideButtons = {}
    local options = { 'hidePlayers', 'hideNPCs', 'hideMonsters', 'hideSkulls', 'hideParty', 'hideKnights', 'hidePaladins', 'hideDruids', 'hideSorcerers', 'hideMonks', 'hideSummons', 'hideMembersOwnGuild' }
    for i, v in ipairs(options) do
        hideButtons[v] = newWindow:recursiveGetChildById(v)
        if hideButtons[v] then
            hideButtons[v].onClick = function(button)
                instance:onFilterButtonClick(button)
            end
        end
    end
    instance.hideButtons = hideButtons
    
    -- Load saved hide button states
    instance:loadHideButtonStates()
    
    -- Setup context menu for this instance
    local contextMenuButton = newWindow:recursiveGetChildById('contextMenuButton')
    if contextMenuButton then
        contextMenuButton.onClick = function(widget, mousePos, mouseButton)
            return instance:showContextMenu(widget, mousePos, mouseButton)
        end
    end
    
    -- Setup toggle filter button
    if instance.toggleFilterButton then
        instance.toggleFilterButton.onClick = function()
            instance:toggleFilterPanel()
        end
    end
    
    -- Setup window callbacks
    newWindow.onOpen = function()
        instance:onOpen()
    end
    
    newWindow.onClose = function()
        instance:onClose()
        -- If this is not the main instance, destroy it completely when closed
        if instance.id ~= 0 then
            instance:destroy(false) -- Clear settings when manually closed
        end
    end
    
    -- Auto-save window position and size when changed during gameplay
    newWindow.onGeometryChange = function()
        if instance.id ~= 0 and not BattleListManager.isRestoring then -- Only for non-main instances and not during restoration
            -- Save the current state to ensure window position is preserved
            BattleListManager:saveInstancesState()
            print("DEBUG: Auto-saved instance", instance.id, "window geometry")
        end
    end
    
    -- Auto-save lock state when lock button is clicked
    local lockButton = newWindow:getChildById('lockButton')
    if lockButton then
        local originalOnClick = lockButton.onClick
        lockButton.onClick = function()
            if originalOnClick then
                originalOnClick()
            end
            -- Save lock state after the lock/unlock action
            if instance.id ~= 0 and not BattleListManager.isRestoring then
                scheduleEvent(function()
                    instance:saveLockState()
                    BattleListManager:saveInstancesState()
                    print("DEBUG: Auto-saved lock state for instance", instance.id)
                end, 10)
            end
        end
    end
    
    -- Add right-click context menu to window
    newWindow.onMousePress = function(widget, mousePos, button)
        if button == MouseRightButton then
            local menu = g_ui.createWidget('PopupMenu')
            menu:addOption('Edit Name', function() instance:openEditNameDialog() end)
            menu:addOption('Create New Battle List', function() BattleListManager:createNewInstance() end)
            if instance.id ~= 0 then -- Only show clear and close options for non-main instances
                menu:addOption('Clear Configurations', function() instance:clearAllConfigurations() end)
                menu:addOption('Close Battle List', function() instance:destroy(false) end) -- Clear settings when manually closed
            end
            menu:display(mousePos)
            return true
        end
        return false
    end
    
    -- Setup and show the window
    newWindow:setContentMinimumHeight(80)
    newWindow:setup()
    
    -- Find available panel and show
    local panel = modules.game_interface.findContentPanelAvailable(newWindow, newWindow:getMinimumHeight())
    if panel then
        panel:addChild(newWindow)
        newWindow:open()
    end
    
    -- Initial creature check for this instance
    if g_game.isOnline() then
        instance:checkCreatures()
    end
end

function BattleListManager:getInstance(id)
    return self.instances[id]
end

function BattleListManager:getAllInstances()
    return self.instances
end

function BattleListManager:destroyInstance(id)
    local instance = self.instances[id]
    if instance then
        print("DEBUG: Destroying battle list instance", id, "via manager")
        instance:destroy(false) -- Clear settings when manually destroyed
        -- Remove from saved instances state so it won't be restored
        self:removeSavedInstanceState(id)
    else
        print("DEBUG: Instance", id, "not found for destruction")
    end
end

function BattleListManager:removeSavedInstanceState(id)
    local instancesData = g_settings.getNode('BattleListInstances') or {}
    if instancesData[tostring(id)] then
        instancesData[tostring(id)] = nil
        g_settings.mergeNode('BattleListInstances', instancesData)
        print("DEBUG: Removed saved state for battle list instance", id)
    end
end

function BattleListManager:startPeriodicSave()
    -- Cancel any existing auto-save
    self:stopPeriodicSave()
    
    -- Set up auto-save every 30 seconds
    self.autoSaveEvent = scheduleEvent(function()
        if g_game.isOnline() and not self.isRestoring then
            self:saveInstancesState()
            print("DEBUG: Periodic auto-save completed")
            -- Schedule the next save
            self:startPeriodicSave()
        end
    end, 30000) -- 30 seconds
    
    print("DEBUG: Started periodic auto-save (every 30 seconds)")
end

function BattleListManager:stopPeriodicSave()
    if self.autoSaveEvent then
        removeEvent(self.autoSaveEvent)
        self.autoSaveEvent = nil
        print("DEBUG: Stopped periodic auto-save")
    end
end

-- Battle List Instance Class
BattleListInstance = {
    id = nil,
    window = nil,
    panel = nil,
    filterPanel = nil,
    toggleFilterButton = nil,
    binaryTree = {},
    battleButtons = {},
    lastBattleButtonSwitched = nil,
    settings = {},
    name = "Battle List"
}

function BattleListInstance:new(id, customName)
    local instance = {}
    setmetatable(instance, {__index = self})
    
    instance.id = id or BattleListManager.nextId
    instance.binaryTree = {}
    instance.battleButtons = {}
    instance.lastBattleButtonSwitched = nil
    instance.lastAge = 0  -- Instance-specific age counter
    instance.name = customName or tr('Battle List')
    instance.settings = {
        filters = table.copy(BATTLE_FILTERS),
        sortType = 'name',
        sortOrder = 'A',
        hidingFilters = false,
        customName = instance.name
    }
    
    return instance
end

function BattleListInstance:getSettingsKey()
    local key = 'BattleList_' .. self.id
    print("DEBUG: Settings key for instance", self.id, "is:", key)
    return key
end

function BattleListInstance:loadFilters()
    local settings = g_settings.getNode(self:getSettingsKey())
    if not settings or not settings['filters'] then
        print("DEBUG: BattleListInstance:loadFilters() for instance", self.id, "returning default filters")
        return table.copy(BATTLE_FILTERS)
    end
    print("DEBUG: BattleListInstance:loadFilters() for instance", self.id, "got filters:", settings['filters'])
    return settings['filters']
end

function BattleListInstance:saveFilters()
    local currentFilters = self:loadFilters()
    g_settings.mergeNode(self:getSettingsKey(), { ['filters'] = currentFilters })
    print("DEBUG: Saved filters for instance", self.id, ":", currentFilters)
end

function BattleListInstance:saveHideButtonStates()
    if not self.hideButtons then 
        print("DEBUG: No hide buttons to save for instance", self.id)
        return 
    end
    
    local hideButtonStates = {}
    for buttonName, button in pairs(self.hideButtons) do
        if button then
            hideButtonStates[buttonName] = button:isChecked()
        end
    end
    g_settings.mergeNode(self:getSettingsKey(), { ['hideButtons'] = hideButtonStates })
    print("DEBUG: Saved hide button states for instance", self.id, ":", hideButtonStates)
end

function BattleListInstance:saveLockState()
    if self.window then
        local isLocked = self.window:getSettings('locked') or false
        g_settings.mergeNode(self:getSettingsKey(), { ['isLocked'] = isLocked })
        print("DEBUG: Saved lock state for instance", self.id, ":", isLocked)
    end
end

function BattleListInstance:loadLockState()
    if not self.window then
        return false
    end
    
    local settings = g_settings.getNode(self:getSettingsKey())
    if settings and settings['isLocked'] ~= nil then
        local isLocked = settings['isLocked']
        if isLocked then
            self.window:lock(true) -- true = don't save during loading
        else
            self.window:unlock(true) -- true = don't save during loading
        end
        print("DEBUG: Loaded lock state for instance", self.id, ":", isLocked)
        return isLocked
    end
    return false
end

function BattleListInstance:loadHideButtonStates()
    if not self.hideButtons then 
        print("DEBUG: No hide buttons for instance", self.id)
        return 
    end
    
    local settings = g_settings.getNode(self:getSettingsKey())
    if settings and settings['hideButtons'] then
        print("DEBUG: Loading hide button states for instance", self.id)
        for buttonName, isChecked in pairs(settings['hideButtons']) do
            local button = self.hideButtons[buttonName]
            if button then
                button:setChecked(isChecked)
                print("DEBUG: Set button", buttonName, "to", isChecked, "for instance", self.id)
            end
        end
    else
        print("DEBUG: No saved hide button states for instance", self.id)
    end
end

function BattleListInstance:getFilter(filter)
    local filters = self:loadFilters()
    local value = filters[filter]
    if value ~= nil then
        return value
    end
    return BATTLE_FILTERS[filter] or false
end

function BattleListInstance:setFilter(filter)
    local filters = self:loadFilters()
    local value = filters[filter]
    
    if value == nil then
        value = BATTLE_FILTERS[filter]
        if value == nil then
            return false
        end
    end
    
    -- Handle mutual exclusivity for sort options
    if filter:find("sortAscBy") or filter:find("sortDescBy") then
        for filterName, _ in pairs(BATTLE_FILTERS) do
            if filterName ~= filter and (filterName:find("sortAscBy") or filterName:find("sortDescBy")) then
                filters[filterName] = false
            end
        end
    end
    
    filters[filter] = not value
    g_settings.mergeNode(self:getSettingsKey(), { ['filters'] = filters })
    
    -- Refresh battle list to apply new sorting immediately
    print("DEBUG: Filter", filter, "set to", filters[filter], "for instance", self.id)
    scheduleEvent(function()
        self:checkCreatures()
    end, 50)
    
    return true
end

function BattleListInstance:getSortType()
    local filters = self:loadFilters()
    
    -- Check which sort filter is currently active
    for filterName, isActive in pairs(filters) do
        if isActive and (filterName:find("sortAscBy") or filterName:find("sortDescBy")) then
            print("DEBUG: Active sort filter found:", filterName, "for instance", self.id)
            if filterName:find("DisplayTime") then
                return 'age'
            elseif filterName:find("Distance") then
                return 'distance'
            elseif filterName:find("HitPoints") then
                return 'health'
            elseif filterName:find("Name") then
                return 'name'
            end
        end
    end
    
    -- Default to name if no sort filter is active
    print("DEBUG: No active sort filter found for instance", self.id, "- defaulting to 'name'")
    return 'name'
end

function BattleListInstance:setSortType(state, oldSortType)
    local settings = {}
    settings['sortType'] = state
    g_settings.mergeNode(self:getSettingsKey(), settings)
    
    local order = self:getSortOrder()
    self:reSort(oldSortType, state, order, order)
end

function BattleListInstance:getSortOrder()
    local filters = self:loadFilters()
    
    -- Check which sort filter is currently active
    for filterName, isActive in pairs(filters) do
        if isActive and (filterName:find("sortAscBy") or filterName:find("sortDescBy")) then
            print("DEBUG: Sort order from filter:", filterName, "for instance", self.id)
            if filterName:find("sortAscBy") then
                return 'A'  -- Ascending
            else
                return 'D'  -- Descending
            end
        end
    end
    
    -- Default to ascending
    print("DEBUG: No active sort filter found for instance", self.id, "- defaulting to 'A'")
    return 'A'
end

function BattleListInstance:setSortOrder(state, oldSortOrder)
    local settings = {}
    settings['sortOrder'] = state
    g_settings.mergeNode(self:getSettingsKey(), settings)
    
    self:reSort(false, false, oldSortOrder, state)
end

function BattleListInstance:isSortAsc()
    return self:getSortOrder() == 'A'
end

function BattleListInstance:isSortDesc()
    return self:getSortOrder() == 'D'
end

function BattleListInstance:getName()
    local settings = g_settings.getNode(self:getSettingsKey())
    if settings and settings['customName'] then
        return settings['customName']
    end
    return tr('Battle List')
end

function BattleListInstance:setName(name)
    local settings = g_settings.getNode(self:getSettingsKey()) or {}
    if name == nil or name == '' then
        settings['customName'] = tr('Battle List')
    else
        settings['customName'] = name
    end
    g_settings.mergeNode(self:getSettingsKey(), settings)
    self:updateTitle()
    
    -- Save the instances state immediately to preserve the name change
    if self.id ~= 0 and not BattleListManager.isRestoring then -- Only for non-main instances and not during restoration
        BattleListManager:saveInstancesState()
        print("DEBUG: Auto-saved instance state after name change for instance", self.id, "new name:", name or tr('Battle List'))
    end
end

function BattleListInstance:updateTitle()
    if self.window then
        local titleLabel = self.window:recursiveGetChildById('miniwindowTitle')
        if titleLabel then
            titleLabel:setText(self:getName())
        end
    end
end

function BattleListInstance:clearAllConfigurations()
    print("DEBUG: Clearing all configurations for battle list instance", self.id)
    
    -- Clear saved settings by checking if node exists first
    local settingsKey = self:getSettingsKey()
    local settings = g_settings.getNode(settingsKey)
    if settings then
        -- Clear individual settings instead of removing the entire node
        g_settings.mergeNode(settingsKey, {
            filters = nil,
            sortType = nil,
            sortOrder = nil,
            hidingFilters = nil,
            customName = nil,
            hideButtons = nil,
            isLocked = nil
        })
    end
    
    -- Reset to default settings
    self.settings = {
        filters = table.copy(BATTLE_FILTERS),
        sortType = 'name',
        sortOrder = 'A',
        hidingFilters = false,
        customName = tr('Battle List')
    }
    
    -- Reset filter buttons to unchecked state
    if self.hideButtons then
        for _, button in pairs(self.hideButtons) do
            if button then
                button:setChecked(false)
            end
        end
    end
    
    -- Reset window title
    self:updateTitle()
    
    -- Show filter panel if it was hidden
    if self.filterPanel and not self.filterPanel:isVisible() then
        self:showFilterPanel()
    end
    
    -- Unlock the window if it was locked
    if self.window then
        self.window:unlock()
    end
    
    -- Refresh creatures with new settings
    self:checkCreatures()
end

function BattleListInstance:destroy(saveSettings)
    -- Only clear settings if explicitly requested (manual destruction)
    -- Don't clear settings on game exit to preserve them for next session
    if not saveSettings then
        local settingsKey = self:getSettingsKey()
        local settings = g_settings.getNode(settingsKey)
        if settings then
            -- Clear individual settings instead of removing the entire node
            g_settings.mergeNode(settingsKey, {
                filters = nil,
                sortType = nil,
                sortOrder = nil,
                hidingFilters = nil,
                customName = nil,
                hideButtons = nil,
                isLocked = nil
            })
        end
        print("DEBUG: Cleared configurations for battle list instance", self.id)
        
        -- Also remove from saved instances state so it won't be restored
        if self.id ~= 0 then -- Don't remove main instance from saved state
            BattleListManager:removeSavedInstanceState(self.id)
        end
    else
        -- Save current states before destroying
        self:saveFilters()
        self:saveHideButtonStates()
        self:saveLockState()
        print("DEBUG: Preserving configurations for battle list instance", self.id)
    end
    
    -- Clean up battle buttons
    for i, v in pairs(self.battleButtons) do
        BattleButtonPool:release(v)
    end
    
    self.binaryTree = {}
    self.battleButtons = {}
    
    -- Clear instance-specific data
    self.settings = nil
    self.lastBattleButtonSwitched = nil
    
    -- Only destroy window if it's not the main instance (ID 0)
    -- The main instance window (battleWindow) is handled by terminate()
    if self.window and self.id ~= 0 then
        self.window:destroy()
        self.window = nil
    end
    
    -- Clear references
    self.panel = nil
    self.filterPanel = nil
    self.toggleFilterButton = nil
    self.hideButtons = nil
    
    -- Remove from manager
    BattleListManager.instances[self.id] = nil
    
    print("DEBUG: Destroyed battle list instance", self.id)
end

-- Instance-specific methods
function BattleListInstance:onFilterButtonClick(button)
    button:setChecked(not button:isChecked())
    self:saveHideButtonStates() -- Save the button states
    self:checkCreatures()
end

function BattleListInstance:showContextMenu(widget, mousePos, mouseButton)
    local menu = g_ui.createWidget('BattleListSubMenu')
    menu:setGameMenu(true)
    for _, choice in ipairs(menu:getChildren()) do
        local choiceId = choice:getId()
        if choiceId and choiceId ~= 'HorizontalSeparator' then
            if choiceId == 'editBattleListName' or choiceId == 'openNewBattleList' then
                choice.onClick = function()
                    self:onMenuAction(choiceId)
                    menu:destroy()
                end
            else
                local filterValue = self:getFilter(choiceId)
                choice:setChecked(filterValue)
                choice.onCheckChange = function()
                    self:onMenuAction(choiceId)
                    menu:destroy()
                end
            end
        end
    end
    
    local buttonPos = widget:getPosition()
    local buttonSize = widget:getSize()
    local menuWidth = menu:getWidth()
    
    local buttonCenterX = buttonPos.x + buttonSize.width / 2
    local buttonCenterY = buttonPos.y + buttonSize.height / 2
    
    local menuX = buttonCenterX - menuWidth
    local menuY = buttonCenterY
    
    menu:display({x = menuX, y = menuY})
    return true
end

function BattleListInstance:onMenuAction(actionId)
    print("DEBUG: Menu action called with actionId:", actionId, "for instance", self.id)
    if actionId == 'editBattleListName' then
        self:openEditNameDialog()
    elseif actionId == 'openNewBattleList' then
        print("DEBUG: Opening new battle list...")
        BattleListManager:createNewInstance()
    elseif actionId == 'sortAscByDisplayTime' then
        self:setFilter(actionId)
        print("DEBUG: Set filter", actionId, "for instance", self.id)
    elseif actionId == 'sortDescByDisplayTime' then
        self:setFilter(actionId)
        print("DEBUG: Set filter", actionId, "for instance", self.id)
    elseif actionId == 'sortAscByDistance' then
        self:setFilter(actionId)
        print("DEBUG: Set filter", actionId, "for instance", self.id)
    elseif actionId == 'sortDescByDistance' then
        self:setFilter(actionId)
        print("DEBUG: Set filter", actionId, "for instance", self.id)
    elseif actionId == 'sortAscByHitPoints' then
        self:setFilter(actionId)
        print("DEBUG: Set filter", actionId, "for instance", self.id)
    elseif actionId == 'sortDescByHitPoints' then
        self:setFilter(actionId)
        print("DEBUG: Set filter", actionId, "for instance", self.id)
    elseif actionId == 'sortAscByName' then
        self:setFilter(actionId)
        print("DEBUG: Set filter", actionId, "for instance", self.id)
    elseif actionId == 'sortDescByName' then
        self:setFilter(actionId)
        print("DEBUG: Set filter", actionId, "for instance", self.id)
    end
end

function BattleListInstance:openEditNameDialog()
    local currentName = self:getName()
    if currentName == tr('Battle List') then
        currentName = ""
    end
    
    local changeListNameWindow = g_ui.displayUI('style/changeListName')
    changeListNameWindow:show()
    
    local nameInput = changeListNameWindow:getChildById('newBattleListName')
    nameInput:setText(currentName)
    nameInput:focus()
    nameInput:selectAll()
    
    local function closeWindow()
        nameInput:setText('')
        changeListNameWindow:setVisible(false)
        changeListNameWindow:destroy()
    end
    
    changeListNameWindow.buttonOk.onClick = function()
        local newName = nameInput:getText()
        self:setName(newName)
        closeWindow()
    end
    
    changeListNameWindow.closeButton.onClick = closeWindow
    changeListNameWindow.onEscape = closeWindow
    
    nameInput.onKeyDown = function(widget, keyCode, keyboardModifiers)
        if keyCode == KeyReturn or keyCode == KeyEnter then
            changeListNameWindow.buttonOk.onClick()
            return true
        elseif keyCode == KeyEscape then
            closeWindow()
            return true
        end
        return false
    end
end

function BattleListInstance:toggleFilterPanel()
    if self.filterPanel:isVisible() then
        self:hideFilterPanel()
    else
        self:showFilterPanel()
    end
end

function BattleListInstance:hideFilterPanel()
    self.filterPanel.originalHeight = self.filterPanel:getHeight()
    self.filterPanel:setHeight(0)
    self.toggleFilterButton:getParent():setMarginTop(0)
    self.toggleFilterButton:setOn(false)
    self:setHidingFilters(true)
    local HorizontalSeparator = self.window:recursiveGetChildById('HorizontalSeparator')
    if HorizontalSeparator then HorizontalSeparator:setVisible(false) end
    self.filterPanel:setVisible(false)
    local contentsPanel = self.window:recursiveGetChildById('contentsPanel')
    if contentsPanel then contentsPanel:setMarginTop(-10) end
    local miniwindowScrollBar = self.window:recursiveGetChildById('miniwindowScrollBar')
    if miniwindowScrollBar then miniwindowScrollBar:setMarginTop(-3) end
end

function BattleListInstance:showFilterPanel()
    self.toggleFilterButton:getParent():setMarginTop()
    self.filterPanel:setHeight(self.filterPanel.originalHeight)
    self:setHidingFilters(false)
    self.toggleFilterButton:setOn(true)
    local HorizontalSeparator = self.window:recursiveGetChildById('HorizontalSeparator')
    if HorizontalSeparator then HorizontalSeparator:setVisible(true) end
    self.filterPanel:setVisible(true)
    local contentsPanel = self.window:recursiveGetChildById('contentsPanel')
    if contentsPanel then contentsPanel:setMarginTop(0) end
    local miniwindowScrollBar = self.window:recursiveGetChildById('miniwindowScrollBar')
    if miniwindowScrollBar then miniwindowScrollBar:setMarginTop(0) end
end

function BattleListInstance:setHidingFilters(state)
    local settings = {}
    settings['hidingFilters'] = state
    g_settings.mergeNode(self:getSettingsKey(), settings)
end

function BattleListInstance:isHidingFilters()
    local settings = g_settings.getNode(self:getSettingsKey())
    if not settings then
        return false
    end
    return settings['hidingFilters']
end

function BattleListInstance:onOpen()
    -- Instance-specific connection logic if needed
end

function BattleListInstance:onClose()
    -- Don't clear instance configurations when window is closed during normal operation
    -- Only clear when explicitly requested through clearAllConfigurations()
    print("DEBUG: Closing battle list instance", self.id, "- configurations preserved")
    
    -- Instance-specific disconnection logic if needed
end

function BattleListInstance:checkCreatures()
    if not self.panel or not g_game.isOnline() then
        return false
    end
    
    self.panel:disableUpdateTemporarily()
    
    local player = g_game.getLocalPlayer()
    if not player then
        return false
    end
    
    local position = player:getPosition()
    if not position then
        return false
    end
    
    self:removeAllCreatures()
    
    local spectators = modules.game_interface.getMapPanel():getSpectators()
    local sortType = self:getSortType()
    local sortOrder = self:getSortOrder()
    
    print("DEBUG: checkCreatures for instance", self.id, "- sortType:", sortType, "sortOrder:", sortOrder, "creatures found:", #spectators)
    
    for _, creature in ipairs(spectators) do
        if self:doCreatureFitFilters(creature) then
            self:addCreature(creature, sortType)
        end
    end
end

function BattleListInstance:doCreatureFitFilters(creature)
    if creature:isLocalPlayer() then
        return false
    end
    
    if creature:isDead() then
        return false
    end
    
    local pos = creature:getPosition()
    if not pos then
        return false
    end
    
    local localPlayer = g_game.getLocalPlayer()
    if not localPlayer then
        return false
    end
    
    local position = localPlayer:getPosition()
    if not position then
        return false
    end
    
    if pos.z ~= localPlayer:getPosition().z or not creature:canBeSeen() then
        return false
    end
    
    for i, v in pairs(self.hideButtons or {}) do
        if v:isChecked() then
            if (i == 'hidePlayers' and creature:isPlayer()) or 
               (i == 'hideNPCs' and creature:isNpc()) or
               (i == 'hideMonsters' and creature:isMonster()) or
               (i == 'hideSkulls' and (creature:isPlayer() and creature:getSkull() == SkullNone)) or
               (i == 'hideParty' and creature:isPlayer() and (function()
                   local shield = creature:getShield()
                   return shield and (shield == ShieldYellow or 
                                    shield == ShieldYellowSharedExp or 
                                    shield == ShieldYellowNoSharedExp or 
                                    shield == ShieldBlue or 
                                    shield == ShieldBlueNoSharedExpBlink or 
                                    shield == ShieldBlueSharedExp or 
                                    shield == ShieldYellowNoSharedExpBlink)
               end)()) or
               (i == 'hideKnights' and creature:isPlayer() and creature:isKnight()) or
               (i == 'hidePaladins' and creature:isPlayer() and creature:isPaladin()) or
               (i == 'hideDruids' and creature:isPlayer() and creature:isDruid()) or
               (i == 'hideSorcerers' and creature:isPlayer() and creature:isSorcerer()) or
               (i == 'hideMonks' and creature:isPlayer() and creature:isMonk()) or
               (i == 'hideSummons' and creature:isMonster() and (function()
                   local masterId = creature:getMasterId()
                   return masterId and masterId > 0
               end)()) or
               (i == 'hideMembersOwnGuild' and creature:isPlayer() and creature:getEmblem() == localPlayer:getEmblem() and creature:getEmblem() ~= EmblemNone) then
                return false
            end
        end
    end
    
    return true
end

local lastAge = 0
function BattleListInstance:addCreature(creature, sortType)
    local creatureId = creature:getId()
    local battleButton = self.battleButtons[creatureId]
    if battleButton then
        battleButton:update()
    else
        if creature:getPosition() == nil then
            return
        end
        
        local newCreature = {}
        newCreature.id = creatureId
        newCreature.name = creature:getName():lower()
        newCreature.healthpercent = creature:getHealthPercent()
        newCreature.distance = getDistanceBetween(g_game.getLocalPlayer():getPosition(), creature:getPosition())
        newCreature.age = self.lastAge + 1
        self.lastAge = self.lastAge + 1
        
        local newIndex = binaryInsert(self.binaryTree, newCreature, BSComparatorSortType, sortType, true)
        
        battleButton = BattleButtonPool:get()
        battleButton:setup(creature, true)
        
        battleButton.data = {}
        for i, v in pairs(newCreature) do
            battleButton.data[i] = v
        end
        
        self.battleButtons[creatureId] = battleButton
        
        if creature == g_game.getAttackingCreature() then
            battleButton.isTarget = true
            battleButton:update()
        end
        
        if creature == g_game.getFollowingCreature() then
            battleButton.isFollowed = true
            battleButton:update()
        end
        
        if self:isSortAsc() then
            self.panel:insertChild(newIndex, battleButton)
        else
            self.panel:insertChild((#self.binaryTree - newIndex + 1), battleButton)
        end
    end
    
    battleButton:setVisible(canBeSeen(creature))
    self.panel:getLayout():update()
end

function BattleListInstance:removeAllCreatures()
    self:removeCreature(false, true)
end

function BattleListInstance:removeCreature(creature, all)
    if all then
        self.binaryTree = {}
        self.lastBattleButtonSwitched = nil
        for i, v in pairs(self.battleButtons) do
            BattleButtonPool:release(v)
        end
        self.battleButtons = {}
        return true
    end
    
    local creatureId = creature:getId()
    local battleButton = self.battleButtons[creatureId]
    
    if battleButton then
        if self.lastBattleButtonSwitched == battleButton then
            self.lastBattleButtonSwitched = nil
        end
        
        local sortType = self:getSortType()
        local valuetoSearch = self:getAttributeByOrderType(battleButton, sortType)
        assert(valuetoSearch, 'Could not find information (data) in sent battleButton')
        valuetoSearch.id = creatureId
        
        local index = binarySearch(self.binaryTree, valuetoSearch, BSComparatorSortType, sortType, creatureId)
        if index ~= nil and creatureId == self.binaryTree[index].id then
            local creatureListSize = #self.binaryTree
            if index < creatureListSize then
                for i = index, creatureListSize - 1 do
                    -- Swap elements in instance binary tree
                    local tmp = self.binaryTree[i]
                    self.binaryTree[i] = self.binaryTree[i + 1]
                    self.binaryTree[i + 1] = tmp
                end
            end
            self.binaryTree[creatureListSize] = nil
            BattleButtonPool:release(battleButton)
            self.battleButtons[creatureId] = nil
            return true
        end
    end
    return false
end

function BattleListInstance:getAttributeByOrderType(battleButton, orderType)
    if battleButton.data then
        local battleButton = battleButton.data
        if orderType == 'distance' then
            return {
                distance = battleButton.distance
            }
        elseif orderType == 'health' then
            return {
                healthpercent = battleButton.healthpercent
            }
        elseif orderType == 'age' then
            return {
                age = battleButton.age
            }
        else
            return {
                name = battleButton.name
            }
        end
    end
    return false
end

function BattleListInstance:correctBattleButtons(sortOrder)
    self.panel:disableUpdateTemporarily()
    
    local sortOrder = sortOrder or self:getSortOrder()
    
    local start = sortOrder == 'A' and 1 or #self.binaryTree
    local finish = #self.binaryTree - start + 1
    local increment = start <= finish and 1 or -1
    
    local index = 1
    for i = start, finish, increment do
        local v = self.binaryTree[i]
        local battleButton = self.battleButtons[v.id]
        if battleButton ~= nil then
            self.panel:moveChildToIndex(battleButton, index)
            index = index + 1
        end
    end
    return true
end

function BattleListInstance:reSort(oldSortType, newSortType, oldSortOrder, newSortOrder)
    if #self.binaryTree > 1 then
        if newSortType and newSortType ~= oldSortType then
            self:checkCreatures()
        end
        
        if newSortOrder then
            self:correctBattleButtons(newSortOrder)
        end
    end
    
    return true
end

function BattleListInstance:swap(index, newIndex) -- Swap indexes of a given table
    local highest = newIndex
    local lowest = index

    if index > newIndex then
        highest = index
        lowest = newIndex
    end

    local tmp = self.binaryTree[lowest]
    self.binaryTree[lowest] = self.binaryTree[highest]
    self.binaryTree[highest] = tmp
end

-- Hide Buttons ("hidePlayers", "hideNPCs", "hideMonsters", "hideSkulls", "hideParty")
local hideButtons = {}

local eventOnCheckCreature = nil

function loadFilters()
    local settings = g_settings.getNode("BattleList")
    if not settings or not settings['filters'] then
        return BATTLE_FILTERS
    end
    return settings['filters']
end

function saveFilters()
    g_settings.mergeNode('BattleList', { ['filters'] = loadFilters() })
end

-- Battle List Name functions
function getBattleListName()
    local settings = g_settings.getNode('BattleList')
    if settings and settings['customName'] then
        return settings['customName']
    end
    return tr('Battle List') -- Default name
end

function setBattleListName(name)
    local settings = g_settings.getNode('BattleList') or {}
    if name == nil or name == '' then
        settings['customName'] = tr('Battle List') -- Reset to default
    else
        settings['customName'] = name
    end
    g_settings.mergeNode('BattleList', settings)
    updateBattleListTitle()
end

function updateBattleListTitle()
    if battleWindow then
        local titleLabel = battleWindow:recursiveGetChildById('miniwindowTitle')
        if titleLabel then
            titleLabel:setText(getBattleListName())
        end
    end
end



function getFilter(filter)
    -- Use main instance filters instead of global filters
    local mainInstance = BattleListManager:getMainInstance()
    if mainInstance then
        return mainInstance:getFilter(filter)
    end
    
    -- Fallback to global filters for backwards compatibility
    local filters = loadFilters()
    local value = filters[filter]
    if value ~= nil then
        return value
    end
    -- Fall back to default value if not found in saved settings
    return BATTLE_FILTERS[filter] or false
end

function setFilter(filter)
    local filters = loadFilters()
    local value = filters[filter]
    
    -- If the filter doesn't exist in saved settings, get the default value
    if value == nil then
        value = BATTLE_FILTERS[filter]
        if value == nil then
            return false
        end
    end
    
    -- Handle mutual exclusivity for sort options
    if filter:find("sortAscBy") or filter:find("sortDescBy") then
        -- Turn off all other sort filters
        for filterName, _ in pairs(BATTLE_FILTERS) do
            if filterName ~= filter and (filterName:find("sortAscBy") or filterName:find("sortDescBy")) then
                filters[filterName] = false
            end
        end
    end
    
    filters[filter] = not value
    g_settings.mergeNode('BattleList', { ['filters'] = filters })
    
    -- Note: This filter system is for ordering/sorting only, not for visibility filters
    -- The hideButtons remain separate and are handled by the existing onFilterButtonClick
    
    return true
end

local function connecting()
    -- TODO: Just connect when you will be using

    connect(LocalPlayer, {
        onPositionChange = onCreaturePositionChange
    })

    connect(Creature, {
        onSkullChange = updateCreatureSkull,
        onEmblemChange = updateCreatureEmblem,
        onOutfitChange = onCreatureOutfitChange,
        onHealthPercentChange = onCreatureHealthPercentChange,
        onPositionChange = onCreaturePositionChange,
        onAppear = onCreatureAppear,
        onDisappear = onCreatureDisappear
    })

    connect(UIMap, {
        onZoomChange = onZoomChange
    })

    -- Check creatures around you - update all instances
    for _, instance in pairs(BattleListManager.instances) do
        instance:checkCreatures()
    end
    return true
end

local function disconnecting(gameEvent)
    -- TODO: Just disconnect what you're not using

    disconnect(LocalPlayer, {
        onPositionChange = onCreaturePositionChange
    })

    disconnect(Creature, {
        onSkullChange = updateCreatureSkull,
        onEmblemChange = updateCreatureEmblem,
        onOutfitChange = onCreatureOutfitChange,
        onHealthPercentChange = onCreatureHealthPercentChange,
        onPositionChange = onCreaturePositionChange,
        onAppear = onCreatureAppear,
        onDisappear = onCreatureDisappear
    })

    disconnect(UIMap, {
        onZoomChange = onZoomChange
    })

    return true
end

function init() -- Initiating the module (load)
    -- Initialize Battle Button Pool - needs to be done after corelib is loaded
    print("DEBUG: Initializing BattleButtonPool...")
    if not ObjectPool then
        print("ERROR: ObjectPool not found. Creating fallback implementation.")
        -- Create a fallback implementation
        BattleButtonPool = {
            get = function() 
                local widget = g_ui.createWidget('BattleButton')
                widget:show()
                widget:setOn(true)
                return widget
            end,
            release = function(obj)
                if obj and obj:getParent() then
                    obj:getParent():removeChild(obj)
                end
            end
        }
    else
        print("DEBUG: ObjectPool found, creating proper BattleButtonPool...")
        BattleButtonPool = ObjectPool.new(function()
                local widget = g_ui.createWidget('BattleButton')
                widget:show()
                widget:setOn(true)
                widget.onHoverChange = onBattleButtonHoverChange
                widget.onMouseRelease = onBattleButtonMouseRelease
                return widget
            end,
            function(obj)
                -- Reset the battle button state
                if obj.creature then
                    obj.creature = nil
                end
                if obj.data then
                    obj.data = nil
                end
                obj.isTarget = false
                obj.isFollowed = false
                obj.isHovered = false
                
                -- Remove from parent if it has one
                local parent = obj:getParent()
                if parent then
                    parent:removeChild(obj)
                end
            end)
        print("DEBUG: BattleButtonPool created successfully")
    end
    
    g_ui.importStyle('battlebutton')
    battleButton = modules.game_mainpanel.addToggleButton('battleButton', tr('Battle') .. ' (Ctrl+B)',
        '/images/options/button_battlelist', toggle, false, 2)
    battleButton:setOn(true)
    battleWindow = g_ui.loadUI('battle')

    -- Initialize the main battle list instance (ID 0)
    BattleListManager.nextId = 1  -- Start secondary instances from ID 1
    local mainInstance = BattleListInstance:new(0, tr('Battle List'))
    mainInstance.window = battleWindow
    mainInstance.panel = battleWindow:recursiveGetChildById('battlePanel')
    mainInstance.filterPanel = battleWindow:recursiveGetChildById('filterPanel')
    mainInstance.toggleFilterButton = battleWindow:recursiveGetChildById('toggleFilterButton')
    BattleListManager.instances[0] = mainInstance
    
    -- Store references for backward compatibility
    battlePanel = mainInstance.panel
    filterPanel = mainInstance.filterPanel
    toggleFilterButton = mainInstance.toggleFilterButton

    -- Binding Ctrl + B shortcut
    Keybind.new("Windows", "Show/hide battle list", "Ctrl+B", "")
    Keybind.bind("Windows", "Show/hide battle list", {
        {
            type = KEY_DOWN,
            callback = toggle,
        }
    })

    -- Disabling scrollbar auto hiding
    local scrollbar = battleWindow:getChildById('miniwindowScrollBar')
    scrollbar:mergeStyle({
        ['$!on'] = {}
    })

    HorizontalSeparator = battleWindow:recursiveGetChildById('HorizontalSeparator')
    contentsPanel = battleWindow:recursiveGetChildById('contentsPanel')
    miniwindowScrollBar = battleWindow:recursiveGetChildById('miniwindowScrollBar')

    -- Hide/Show Filter Options
    local settings = g_settings.getNode(mainInstance:getSettingsKey())
    if settings and settings['hidingFilters'] then
        mainInstance:hideFilterPanel()
    end

    -- Adding Filter options
    local options = { 'hidePlayers', 'hideNPCs', 'hideMonsters', 'hideSkulls', 'hideParty', 'hideKnights', 'hidePaladins', 'hideDruids', 'hideSorcerers', 'hideMonks', 'hideSummons', 'hideMembersOwnGuild' }
    for i, v in ipairs(options) do
        hideButtons[v] = battleWindow:recursiveGetChildById(v)
    end
    
    -- Set up hideButtons for main instance
    mainInstance.hideButtons = hideButtons
    
    -- Load saved hide button states for main instance
    mainInstance:loadHideButtonStates()

    -- Reorganize filter buttons layout after setup (with small delay for OTUI setup)
    scheduleEvent(reorganizeFilterButtons, 50)

    -- Adding mouse Widget
    mouseWidget = g_ui.createWidget('UIButton')
    mouseWidget:setVisible(false)
    mouseWidget:setFocusable(false)
    mouseWidget.cancelNextRelease = false

    connect(g_game, {
        onAttackingCreatureChange = onAttack,
        onFollowingCreatureChange = onFollow,
        onGameEnd = onGameEnd,
        onGameStart = onGameStart
    })

    --[[
    Configure BattleList SubMenu Hidden Options
    ]]--

    -- Setup context menu button for main instance
    local contextMenuButton = battleWindow:recursiveGetChildById('contextMenuButton')
    if contextMenuButton then
        contextMenuButton.onClick = function(widget, mousePos, mouseButton)
            return mainInstance:showContextMenu(widget, mousePos, mouseButton)
        end
    else
        print("Warning: contextMenuButton not found in battleWindow")
    end
    
    -- Setup new window button for main instance
    local newWindowButton = battleWindow:recursiveGetChildById('newWindowButton')
    if newWindowButton then
        newWindowButton.onClick = function()
            BattleListManager:createNewInstance()
        end
    else
        print("Warning: newWindowButton not found in battleWindow")
    end

    -- Determining Height and Setting up!
    battleWindow:setContentMinimumHeight(80)
    battleWindow:setup()
    
    -- Set the custom battle list name if it exists
    updateBattleListTitle()
    
    -- Add context menu to the battle window
    battleWindow.onMousePress = function(widget, mousePos, button)
        if button == MouseRightButton then
            local menu = g_ui.createWidget('PopupMenu')
            menu:addOption('Edit Name', function() mainInstance:onMenuAction('editBattleListName') end)
            menu:display(mousePos)
            return true
        end
        return false
    end
    
    if g_game.isOnline() then
        battleWindow:setupOnStart()
    end
end

-- Function to reorganize filter buttons layout when some are hidden
local function reorganizeFilterButtons()
    if not filterPanel then return end

    local filterRow1 = filterPanel:getChildById('filterRow1')
    local filterRow2 = filterPanel:getChildById('filterRow2')

    if not filterRow1 or not filterRow2 then return end

    -- The correct order for the battle filter buttons (7 for row1, 5 for row2)
    local orderedIds = {
        'hidePlayers', 'hideKnights', 'hidePaladins', 'hideDruids', 'hideSorcerers', 'hideMonks', 'hideSummons',
        'hideNPCs', 'hideMonsters', 'hideSkulls', 'hideParty', 'hideMembersOwnGuild'
    }

    -- Remove all filter buttons from their current parents (only those belonging to MiniWindowBattle)
    for _, id in ipairs(orderedIds) do
        local btn = hideButtons[id]
        if btn and btn:getParent() then
            btn:getParent():removeChild(btn)
        end
    end

    -- Add visible buttons back, 7 to row1, 5 to row2
    local visibleButtons = {}
    for _, id in ipairs(orderedIds) do
        local btn = hideButtons[id]
        if btn and btn:isVisible() then
            table.insert(visibleButtons, btn)
        end
    end

    for i, btn in ipairs(visibleButtons) do
        if i <= 7 then
            filterRow1:addChild(btn)
        else
            filterRow2:addChild(btn)
        end
    end

    -- Update layouts
    if filterRow1:getLayout() then filterRow1:getLayout():update() end
    if filterRow2:getLayout() then filterRow2:getLayout():update() end
    if filterPanel:getLayout() then filterPanel:getLayout():update() end
end

-- Binary Search, Insertion and Resort functions
local function debugTables(sortType) -- Print both battlebutton and binarytree tables
    local function getInfo(v, sortType)
        local returnedInfo = v.id
        if sortType then
            if sortType == 'distance' then
                returnedInfo = v.distance
            elseif sortType == 'health' then
                returnedInfo = v.healthpercent
            elseif sortType == 'age' then
                returnedInfo = v.age
            else
                returnedInfo = v.name
            end
        end
        return returnedInfo
    end

    print('-----------------------------')
    local msg = 'printing binaryTree: {'
    for i, v in pairs(binaryTree) do
        msg = msg .. '[' .. i .. '] = ' .. getInfo(v, 'name') .. ' [' .. getInfo(v, sortType) .. '],'
    end
    msg = msg .. '}'
    print(msg)

    msg = 'printing battleButtons: {'
    for i, v in pairs(battleButtons) do
        msg = msg .. '[' .. getInfo(v.data, 'name') .. '] = ' .. getInfo(v.data, sortType) .. ','
    end
    msg = msg .. '}'
    print(msg)

    return true
end

function BSComparator(a, b) -- Default comparator function, we probably won't use it here.
    if a > b then
        return -1
    elseif a < b then
        return 1
    else
        return 0
    end
end

function BSComparatorSortType(a, b, sortType, id) -- Comparator function by sortType (and id optionally)
    local comparatorA, comparatorB
    if sortType == 'distance' then
        comparatorA, comparatorB = a.distance, (type(b) == 'table' and b.distance or b)
    elseif sortType == 'health' then
        comparatorA, comparatorB = a.healthpercent, type(b) == 'table' and b.healthpercent or b
    elseif sortType == 'age' then
        comparatorA, comparatorB = a.age, type(b) == 'table' and b.age or b
    elseif sortType == 'name' then
        comparatorA, comparatorB = (a.name):lower(), type(b) == 'table' and (b.name):lower() or b
    end

    if comparatorA == nil or comparatorB == nil then
        return 0
    end

    if comparatorA > comparatorB then
        return -1
    elseif comparatorA < comparatorB then
        return 1
    else
        if id then
            if b and b.id and a.id > b.id then
                return -1
            elseif b and b.id and a.id < b.id then
                return 1
            end
        end
        return 0
    end
end

function binarySearch(tbl, value, comparator, ...) -- Binary Search function, to search a value in our binaryTree
    if not comparator then
        comparator = BSComparator
    end

    local mini = 1
    local maxi = #tbl
    local mid = 1

    while mini <= maxi do
        mid = math.floor((maxi + mini) / 2)
        local tmp_value = comparator(tbl[mid], value, ...)

        if tmp_value == 0 then
            return mid
        elseif tmp_value < 0 then
            maxi = mid - 1
        else
            mini = mid + 1
        end
    end
    return nil
end

function binaryInsert(tbl, value, comparator, ...) -- Binary Insertion function, to insert a value in our binaryTree
    if not comparator then
        comparator = BSComparator
    end

    local mini = 1
    local maxi = #tbl
    local state = 0
    local mid = 1

    while mini <= maxi do
        mid = math.floor((maxi + mini) / 2)

        if comparator(tbl[mid], value, ...) < 0 then
            maxi, state = mid - 1, 0
        else
            mini, state = mid + 1, 1
        end
    end
    table.insert(tbl, mid + state, value)
    return (mid + state)
end

local function swap(index, newIndex) -- Swap indexes of a given table
    local highest = newIndex
    local lowest = index

    if index > newIndex then
        highest = index
        lowest = newIndex
    end

    local tmp = binaryTree[lowest]
    binaryTree[lowest] = binaryTree[highest]
    binaryTree[highest] = tmp
end

local function correctBattleButtons(sortOrder) -- Update battleButton index based upon our binary tree
    -- Delegate to main instance
    local mainInstance = BattleListManager.instances[0]
    if mainInstance then
        mainInstance:correctBattleButtons(sortOrder)
    end
    return true
end

local function reSort(oldSortType, newSortType, oldSortOrder, newSortOrder) -- Resort the binaryTree and update battlebuttons
    -- Delegate to main instance
    local mainInstance = BattleListManager.instances[0]
    if mainInstance then
        mainInstance:reSort(oldSortType, newSortType, oldSortOrder, newSortOrder)
    end
    return true
end

function onGameStart()
    battleWindow:setupOnStart() -- load character window configuration

    -- Reorganize filter buttons layout based on client version
    reorganizeFilterButtons()
    
    -- Update battle list title in case it was customized
    updateBattleListTitle()

    -- Initialize all battle list instances
    for _, instance in pairs(BattleListManager.instances) do
        if instance.window then
            instance.window:setupOnStart()
        end
        instance:updateTitle()
    end

    -- Restore saved battle list instances
    BattleListManager:restoreInstancesState()

    -- Set up periodic auto-save to prevent data loss
    BattleListManager:startPeriodicSave()

    -- Initialize creatures for all instances (including main instance ID 0)
    scheduleEvent(function()
        for _, instance in pairs(BattleListManager.instances) do
            instance:checkCreatures()
        end
    end, 500) -- Increased delay to ensure restored instances are fully set up
end

function onGameEnd()
    -- Stop periodic auto-save
    BattleListManager:stopPeriodicSave()
    
    battleWindow:setParent(nil, true)
    removeAllCreatures()
    saveFilters()

    -- Save state and clean up all battle list instances without clearing their configurations
    BattleListManager:saveInstancesState() -- This now saves all settings including filters and hide buttons
    print("DEBUG: Final save on game end completed")
    for _, instance in pairs(BattleListManager.instances) do
        instance:removeAllCreatures()
        -- Settings are already saved by saveInstancesState(), just clean up UI elements
        if instance.id ~= 0 and instance.window then
            instance.window:setParent(nil, true)
        end
    end

    disconnecting()
end

-- Sort Type Methods
function getSortType() -- Return the current sort type (distance, age, name, health)
    local settings = g_settings.getNode('BattleList')
    if not settings or not settings['sortType'] then
        return 'name'
    end
    return settings['sortType']
end

function setSortType(state, oldSortType) -- Setting the current sort type (distance, age, name, health)
    -- Only update global settings for backwards compatibility
    local settings = {}
    settings['sortType'] = state
    g_settings.mergeNode('BattleList', settings)

    -- Update main instance (ID 0) for backward compatibility, but don't affect other instances
    local mainInstance = BattleListManager.instances[0]
    if mainInstance then
        local order = mainInstance:getSortOrder()
        mainInstance:reSort(oldSortType, state, order, order)
    end
end

function onZoomChange()
    removeEvent(eventOnCheckCreature)
    eventOnCheckCreature = scheduleEvent(function()
        -- Update all battle list instances
        for _, instance in pairs(BattleListManager.instances) do
            instance:checkCreatures()
        end
    end, 1000)
end

function onChangeSortType(comboBox, option) -- Callback when change the sort type (distance, age, name, health)
    local loption = option:lower()
    local oldType = getSortType()

    if loption ~= oldType then
        setSortType(loption, oldType)
    end
end

-- Sort Order Methods
function getSortOrder() -- Return the current sort ordenation (asc/desc)
    local settings = g_settings.getNode('BattleList')
    if not settings then
        return 'A'
    end
    return settings['sortOrder']
end

function setSortOrder(state, oldSortOrder) -- Setting the current sort ordenation (desc/asc)
    -- Only update global settings for backwards compatibility
    local settings = {}
    settings['sortOrder'] = state
    g_settings.mergeNode('BattleList', settings)

    -- Update main instance (ID 0) for backward compatibility, but don't affect other instances
    local mainInstance = BattleListManager.instances[0]
    if mainInstance then
        mainInstance:reSort(false, false, oldSortOrder, state)
    end
end

function isSortAsc() -- Return true if sorted Asc
    return getSortOrder() == 'A'
end

function isSortDesc() -- Return true if sorted Desc
    return getSortOrder() == 'D'
end

function onChangeSortOrder(comboBox, option) -- Callback when change the sort ordenation
    local soption = option:sub(1, 1)
    local oldOrder = getSortOrder()

    if soption ~= oldOrder then
        setSortOrder(option:sub(1, 1), oldOrder)
    end
end

-- Initially checking creatures
function checkCreatures() -- Function that initially populates our tree once the module is initialized
    eventOnCheckCreature = nil

    if not g_game.isOnline() then
        return false
    end

    local player = g_game.getLocalPlayer()
    if not player then
        return false
    end

    local position = player:getPosition()
    if not position then
        return false
    end

    -- Update all battle list instances
    for _, instance in pairs(BattleListManager.instances) do
        if instance.panel then
            instance:checkCreatures()
        end
    end
end

function doCreatureFitFilters(creature) -- Check if creature fit current applied filters (By changing the filter we will call checkCreatures(true) to recreate the tree)
    -- Use main instance for global calls
    local mainInstance = BattleListManager.instances[0]
    if mainInstance then
        return mainInstance:doCreatureFitFilters(creature)
    end
    return false
end

function onFilterButtonClick(button)
    button:setChecked(not button:isChecked())
    
    -- Save hide button states for main instance
    local mainInstance = BattleListManager.instances[0]
    if mainInstance then
        mainInstance:saveHideButtonStates()
    end
    
    -- Update all battle list instances
    for _, instance in pairs(BattleListManager.instances) do
        instance:checkCreatures()
    end
end

function canBeSeen(creature)
    return creature and creature:canBeSeen() and creature:getPosition() and
        modules.game_interface.getMapPanel():isInRange(creature:getPosition())
end

function getDistanceBetween(p1, p2) -- Calculate distance
    if p2 == nil then
        p2 = {
            x = 0,
            y = 0
        }
    end

    local xd = math.abs(p1.x - p2.x);
    local yd = math.abs(p1.y - p2.y);

    if xd > 0 then
        xd = xd - 1
    end
    if yd > 0 then
        yd = yd - 1
    end

    return xd + yd
end

-- Adding and Removing creatures
local function getAttributeByOrderType(battleButton, orderType) -- Return the attribute of battleButton based on the orderType
    if battleButton.data then
        local battleButton = battleButton.data
        if orderType == 'distance' then
            return {
                distance = battleButton.distance
            }
        elseif orderType == 'health' then
            return {
                healthpercent = battleButton.healthpercent
            }
        elseif orderType == 'age' then
            return {
                age = battleButton.age
            }
        else
            return {
                name = battleButton.name
            }
        end
    end
    return false
end

local lastAge = 0
function addCreature(creature, sortType) -- Insert a creature in our binary tree
    -- Delegate to main instance
    local mainInstance = BattleListManager.instances[0]
    if mainInstance then
        mainInstance:addCreature(creature, sortType)
    end
end

function removeAllCreatures() -- Remove all creatures from our binary tree
    -- Delegate to main instance
    local mainInstance = BattleListManager.instances[0]
    if mainInstance then
        mainInstance:removeAllCreatures()
    end
end

function removeCreature(creature, all) -- Remove a single creature or all
    -- Delegate to main instance
    local mainInstance = BattleListManager.instances[0]
    if mainInstance then
        return mainInstance:removeCreature(creature, all)
    end
    return false
end

-- Hide/Show Filter Options
function isHidingFilters() -- Return true if filters are hidden
    local settings = g_settings.getNode('BattleList')
    if not settings then
        return false
    end
    return settings['hidingFilters']
end

function setHidingFilters(state) -- Setting hiding filters
    settings = {}
    settings['hidingFilters'] = state
    g_settings.mergeNode('BattleList', settings)
end

function hideFilterPanel() -- Hide Filter panel
    local mainInstance = BattleListManager:getMainInstance()
    if mainInstance then
        mainInstance:hideFilterPanel()
    end
end

function showFilterPanel() -- Show Filter panel
    local mainInstance = BattleListManager:getMainInstance()
    if mainInstance then
        mainInstance:showFilterPanel()
    end
end

function toggleFilterPanel() -- Switching modes of filter panel (hide/show)
    local mainInstance = BattleListManager:getMainInstance()
    if mainInstance then
        mainInstance:toggleFilterPanel()
    end
end

function attackNext(previous)
    local foundTarget = false
    local firstElement = nil
    local lastElement = nil
    local prevElement = nil
    local nextElement = nil

    local mainInstance = BattleListManager.instances[0]
    if not mainInstance or not mainInstance.panel then
        return
    end

    local children = mainInstance.panel:getChildren()

    for _, battleButton in pairs(mainInstance.panel:getChildren()) do
        if battleButton:isVisible() then
            -- select visible first child
            if not firstElement then
                firstElement = battleButton
            end
            lastElement = battleButton

            if battleButton.isTarget then
                foundTarget = true
            elseif foundTarget and not nextElement then
                nextElement = battleButton
            elseif not foundTarget then
                prevElement = battleButton
            end
        end
    end

    if foundTarget then
        if previous then
            if prevElement then
                g_game.attack(prevElement.creature)
            else
                g_game.attack(lastElement.creature)
            end
        else
            if nextElement then
                g_game.attack(nextElement.creature)
            else
                g_game.attack(firstElement.creature)
            end
        end
    elseif firstElement then
        g_game.attack(firstElement.creature)
    else
        return false
    end
    return true
end

-- Connector Callbacks
function onAttack(creature) -- Update battleButton once you're attacking a target
    if lastCreatureSelected then
        lastCreatureSelected:hideStaticSquare()
        lastCreatureSelected = nil
    end

    local battleButton = nil
    if battleWindow:isVisible() then
        local mainInstance = BattleListManager.instances[0]
        if mainInstance then
            battleButton = creature and (mainInstance.battleButtons[creature:getId()]) or lastBattleButtonSwitched
        end
    end

    if battleButton then
        battleButton.isTarget = creature and true or false
        updateBattleButton(battleButton)
    elseif creature then
        creature:showStaticSquare(UICreatureButton.getCreatureButtonColors().onTargeted.notHovered)
    end

    lastCreatureSelected = creature
end

function onFollow(creature) -- Update battleButton once you're following a target
    if lastCreatureSelected then
        lastCreatureSelected:hideStaticSquare()
        lastCreatureSelected = nil
    end

    local battleButton = nil
    if battleWindow:isVisible() then
        local mainInstance = BattleListManager.instances[0]
        if mainInstance then
            battleButton = creature and mainInstance.battleButtons[creature:getId()] or lastBattleButtonSwitched
        end
    end

    if battleButton then
        battleButton.isFollowed = creature and true or false
        updateBattleButton(battleButton)
    elseif creature then
        creature:showStaticSquare(UICreatureButton.getCreatureButtonColors().onFollowed.notHovered)
    end
    lastCreatureSelected = creature
end

function onCreatureOutfitChange(creature, outfit, oldOutfit) -- Insert/Remove creature when it becomes visible/invisible
    -- Update all battle list instances
    for _, instance in pairs(BattleListManager.instances) do
        local battleButton = instance.battleButtons[creature:getId()]
        local fit = instance:doCreatureFitFilters(creature)

        if battleButton ~= nil and not fit then
            instance:removeCreature(creature)
        elseif battleButton == nil and fit then
            instance:addCreature(creature)
        end
    end
end

function updateCreatureSkull(creature, skullId) -- Update skull
    -- Update all battle list instances
    for _, instance in pairs(BattleListManager.instances) do
        local battleButton = instance.battleButtons[creature:getId()]
        if battleButton then
            battleButton:updateSkull(skullId)
        end
    end
end

function updateCreatureEmblem(creature, emblemId) -- Update emblem
    -- Update all battle list instances
    for _, instance in pairs(BattleListManager.instances) do
        local battleButton = instance.battleButtons[creature:getId()]
        if battleButton then
            battleButton:updateEmblem(emblemId)
        end
    end
end

function onCreaturePositionChange(creature, newPos, oldPos) -- Update battleButton once you or monsters move
    local localPlayer = g_game.getLocalPlayer()
    if not localPlayer then
        return false
    end

    local position = localPlayer:getPosition()
    if not position then
        return false
    end

    -- Update all battle list instances
    for _, instance in pairs(BattleListManager.instances) do
        if instance.panel then
            instance.panel:disableUpdateTemporarily()
            
            local sortType = instance:getSortType()
            -- If it's the local player moving
            if creature:isLocalPlayer() then
                if oldPos and newPos and newPos.z ~= oldPos.z then
                    addEvent(function() -- fix for old protocols
                        instance:checkCreatures()
                    end)
                elseif oldPos and newPos and (newPos.x ~= oldPos.x or newPos.y ~= oldPos.y) then
                    -- Distance will change when moving, recalculate and move to correct index
                    if #instance.binaryTree > 0 and sortType == 'distance' then
                        -- TODO: If the amount of creatures is higher than a given number, instead of using this approach we simply recalculate each 200ms.
                        for i, v in ipairs(instance.binaryTree) do
                            local oldDistance = v.distance
                            local battleButton = instance.battleButtons[v.id]
                            local mob = battleButton.creature or g_map.getCreatureById(v.id)
                            local newDistance = getDistanceBetween(newPos, mob:getPosition())
                            if oldDistance ~= newDistance then
                                v.distance = newDistance
                                battleButton.data.distance = newDistance
                            end
                        end
                        table.sort(instance.binaryTree, function(a, b)
                            return BSComparatorSortType(a, b, 'distance', true) == 1
                        end)
                        instance:correctBattleButtons()
                    end

                    for i, v in pairs(instance.battleButtons) do
                        local mob = v.creature
                        if mob and mob:getPosition() then
                            v:setVisible(canBeSeen(mob))
                        end
                    end
                end
            else
                -- If it's a creature moving
                local creatureId = creature:getId()
                local battleButton = instance.battleButtons[creatureId]
                local fit = instance:doCreatureFitFilters(creature)

                if battleButton == nil then
                    if fit then
                        instance:addCreature(creature, sortType)
                    end
                else
                    if not fit and newPos then -- if there's no newPos the creature is dead, let onCreatureDisappear handles that.
                        instance:removeCreature(creature)
                    elseif fit then
                        if oldPos and newPos and (newPos.x ~= oldPos.x or newPos.y ~= oldPos.y) then
                            if sortType == 'distance' then
                                local localPlayer = g_game.getLocalPlayer()
                                local newDistance = getDistanceBetween(localPlayer:getPosition(), newPos)
                                local oldDistance = battleButton.data.distance

                                local index = binarySearch(instance.binaryTree, {
                                    distance = oldDistance,
                                    id = creatureId
                                }, BSComparatorSortType, 'distance', true)

                                if index ~= nil and creatureId == instance.binaryTree[index].id then -- Safety first :)
                                    instance.binaryTree[index].distance = newDistance
                                    battleButton.data.distance = newDistance
                                    if newDistance > oldDistance then
                                        if index < #instance.binaryTree then
                                            for i = index, #instance.binaryTree - 1 do
                                                local a = instance.binaryTree[i]
                                                local b = instance.binaryTree[i + 1]
                                                if a.distance > b.distance or (a.distance == b.distance and a.id > b.id) then
                                                    instance:swap(i, i + 1)
                                                end
                                            end
                                        end
                                    elseif newDistance < oldDistance then
                                        battleButton:setVisible(canBeSeen(creature))

                                        if lastCreatureSelected == creature and not battleButton:isVisible() then
                                            lastCreatureSelected:hideStaticSquare()
                                            lastCreatureSelected = nil
                                        end

                                        if index > 1 then
                                            for i = index, 2, -1 do
                                                local a = instance.binaryTree[i - 1]
                                                local b = instance.binaryTree[i]
                                                if a.distance > b.distance or (a.distance == b.distance and a.id > b.id) then
                                                    instance:swap(i - 1, i)
                                                end
                                            end
                                        end
                                    end
                                    instance:correctBattleButtons()
                                else
                                    assert(index ~= nil,
                                        'Not able to update Position Change. Creature: ' .. creature:getName() .. ' id ' ..
                                        creatureId .. ' not found in binary search using ' .. sortType .. ' to find value ' ..
                                        oldDistance .. '.\n')
                                end
                            end
                        end
                        instance:addCreature(creature) -- should check if creature visibility has changed
                    end
                end
            end
        end
    end
end

function onCreatureHealthPercentChange(creature, healthPercent, oldHealthPercent) -- Update battleButton mobs lose/gain health
    -- Update all battle list instances
    for _, instance in pairs(BattleListManager.instances) do
        local creatureId = creature:getId()
        local battleButton = instance.battleButtons[creatureId]
        if battleButton then
            local sortType = instance:getSortType()
            if sortType == 'health' then
                if healthPercent == oldHealthPercent then
                    goto continue -- Skip this instance
                end
                if healthPercent == 0 then
                    goto continue -- Let onCreatureDisappear handle this
                end

                local index = binarySearch(instance.binaryTree, {
                    healthpercent = oldHealthPercent,
                    id = creatureId
                }, BSComparatorSortType, 'health', true)
                if index ~= nil and creatureId == instance.binaryTree[index].id then
                    instance.binaryTree[index].healthpercent = healthPercent
                    battleButton.data.healthpercent = healthPercent
                    if healthPercent > oldHealthPercent then
                        if index < #instance.binaryTree then
                            for i = index, #instance.binaryTree - 1 do
                                local a = instance.binaryTree[i]
                                local b = instance.binaryTree[i + 1]
                                if a.healthpercent > b.healthpercent or (a.healthpercent == b.healthpercent and a.id > b.id) then
                                    local tmp = instance.binaryTree[i]
                                    instance.binaryTree[i] = instance.binaryTree[i + 1]
                                    instance.binaryTree[i + 1] = tmp
                                end
                            end
                        end
                    else
                        if index > 1 then
                            for i = index, 2, -1 do
                                local a = instance.binaryTree[i - 1]
                                local b = instance.binaryTree[i]
                                if a.healthpercent > b.healthpercent or (a.healthpercent == b.healthpercent and a.id > b.id) then
                                    local tmp = instance.binaryTree[i - 1]
                                    instance.binaryTree[i - 1] = instance.binaryTree[i]
                                    instance.binaryTree[i] = tmp
                                end
                            end
                        end
                    end
                    instance:correctBattleButtons()
                end
            end
            battleButton:update()
        end
        ::continue::
    end
end

function onCreatureAppear(creature) -- Update battleButton once a creature appear (add)
    if creature:isLocalPlayer() then
        addEvent(updateStaticSquare)
    end

    -- Update all battle list instances (including main instance ID 0)
    for _, instance in pairs(BattleListManager.instances) do
        local sortType = instance:getSortType()
        if instance:doCreatureFitFilters(creature) then
            instance:addCreature(creature, sortType)
        end
    end
end

function onCreatureDisappear(creature) -- Update battleButton once a creature disappear (remove/dead)
    -- Update all battle list instances (including main instance ID 0)
    for _, instance in pairs(BattleListManager.instances) do
        instance:removeCreature(creature)
    end
end

-- BattleWindow controllers
function onBattleButtonMouseRelease(self, mousePosition, mouseButton) -- Interactions with mouse (right, left, right + left and shift interactions)
    if mouseWidget.cancelNextRelease then
        mouseWidget.cancelNextRelease = false
        return false
    end

    if ((g_mouse.isPressed(MouseLeftButton) and mouseButton == MouseRightButton) or
            (g_mouse.isPressed(MouseRightButton) and mouseButton == MouseLeftButton)) then
        mouseWidget.cancelNextRelease = true
        g_game.look(self.creature, true)
        return true
    elseif mouseButton == MouseLeftButton and g_keyboard.isShiftPressed() then
        g_game.look(self.creature, true)
        return true
    elseif mouseButton == MouseRightButton and not g_mouse.isPressed(MouseLeftButton) then
        modules.game_interface.createThingMenu(mousePosition, nil, nil, self.creature)
        return true
    elseif mouseButton == MouseLeftButton and not g_mouse.isPressed(MouseRightButton) then
        if self.isTarget then
            g_game.cancelAttack()
        else
            g_game.attack(self.creature)
        end
        return true
    end
    return false
end

function updateStaticSquare(battleButton) -- Update all static squares upon appearing the screen (login)
    -- Update all battle list instances
    for _, instance in pairs(BattleListManager.instances) do
        for _, battleButton in pairs(instance.battleButtons) do
            if battleButton.isTarget then
                battleButton:update()
            end
        end
    end
end

function updateBattleButton(battleButton) -- Update battleButton with attack/follow squares
    battleButton:update()
    if battleButton.isTarget or battleButton.isFollowed then
        -- set new last battle button switched
        if lastBattleButtonSwitched and lastBattleButtonSwitched ~= battleButton then
            lastBattleButtonSwitched.isTarget = false
            lastBattleButtonSwitched.isFollowed = false
            updateBattleButton(lastBattleButtonSwitched)
        end
        lastBattleButtonSwitched = battleButton
    end
end

function onBattleButtonHoverChange(battleButton, hovered) -- Interaction with mouse (hovering)
    if battleButton.isBattleButton then
        battleButton.isHovered = hovered
        updateBattleButton(battleButton)
    end
end

function onOpen()
    battleButton:setOn(true)
    connecting()
end

function onClose()
    battleButton:setOn(false)
    disconnecting()
end


function toggle() -- Close/Open the battle window or Pressing Ctrl + B
    if battleButton:isOn() then
        battleWindow:close()
    else
        if not battleWindow:getParent() then
            local panel = modules.game_interface
                .findContentPanelAvailable(battleWindow, battleWindow:getMinimumHeight())
            if not panel then
                return
            end

            panel:addChild(battleWindow)
        end
        battleWindow:open()
    end
end

function terminate() -- Terminating the Module (unload)
    -- Save battle list instances state before destroying
    BattleListManager:saveInstancesState()
    
    -- Destroy all battle list instances (preserving settings for next session)
    for _, instance in pairs(BattleListManager.instances) do
        instance:destroy(true) -- Preserve settings during module termination
    end
    BattleListManager.instances = {}
    
    binaryTree = {}
    battleButtons = {}
    hideButtons = {}

    if battleButton then
        battleButton:destroy()
        battleButton = nil
    end
    
    if battleWindow then
        battleWindow:destroy()
        battleWindow = nil
    end
    
    if mouseWidget then
        mouseWidget:destroy()
        mouseWidget = nil
    end

    lastCreatureSelected = nil

    battlePanel = nil
    battleButton = nil
    battleWindow = nil
    mouseWidget = nil
    filterPanel = nil
    toggleFilterButton = nil

    Keybind.delete("Windows", "Show/hide battle list")

    disconnect(g_game, {
        onAttackingCreatureChange = onAttack,
        onFollowingCreatureChange = onFollow,
        onGameEnd = onGameEnd,
        onGameStart = onGameStart
    })
    disconnecting()
end

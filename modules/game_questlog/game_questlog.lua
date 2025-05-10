questLogController = Controller:new()

-- @ todo
-- test tracker onUpdateQuestTracker
-- test 14.10
-- questLogController:bindKeyPress('Down' // 'up') focusNextChild // focusPreviousChild
-- PopMenu Miniwindows "Remove completed quests // Automatically track new quests // Automatically untrack completed quests"

-- @  windows
local trackerMiniWindow = nil
local questLogButton = nil
local buttonQuestLogTrackerButton = nil

-- @widgets
local UICheckBox = {
    showComplete = nil,
    showShidden = nil,
    showInQuestTracker = nil
}

local UIlabel = {
    numberQuestComplete = nil,
    numberQuestHidden = nil
}

local UITextList = {
    questLogList = nil,
    questLogLine = nil,
    questLogInfo = nil
}

local UITextEdit = {
    search = nil
}

-- variable
local settings = {}
local namePlayer = ""
local questLogCache = {
    items = {},
    completed = 0,
    hidden = 0,
    visible = 0
}

-- const
local COLORS = {
    BASE_1 = "#484848",
    BASE_2 = "#414141",
    SELECTED = "#585858"
}
local file = "/settings/questtracking.json"

--[[=================================================
=               Local Functions                     =
=================================================== ]] --

local function isIdInTracker(key, id)
    if not settings[key] then
        return false
    end
    return table.findbyfield(settings[key], 1, tonumber(id)) ~= nil
end

local function addUniqueIdQuest(key, id, name)
    if not settings[key] then
        settings[key] = {}
    end

    if not isIdInTracker(key, id) then
        table.insert(settings[key], {tonumber(id), name})
    end
end

local function removeNumber(key, id)
    if settings[key] then
        table.remove_if(settings[key], function(_, v)
            return v[1] == tonumber(id)
        end)
    end
end

local function load()
    if g_resources.fileExists(file) then
        local status, result = pcall(function()
            return json.decode(g_resources.readFileContents(file))
        end)
        if not status then
            return g_logger.error(
                "Error while reading profiles file. To fix this problem you can delete storage.json. Details: " ..
                    result)
        end
        return result or {}
    end
end

local function save()
    local status, result = pcall(function()
        return json.encode(settings, 2)
    end)
    if not status then
        return g_logger.error("Error while saving profile settings. Data won't be saved. Details: " .. result)
    end
    if result:len() > 100 * 1024 * 1024 then
        return g_logger.error("Something went wrong, file is above 100MB, won't be saved")
    end
    g_resources.writeFileContents(file, result)
end

local sortFunctions = {
    ["Alphabetically (A-Z)"] = function(a, b)
        return a:getText() < b:getText()
    end,
    ["Alphabetically (Z-A)"] = function(a, b)
        return a:getText() > b:getText()
    end,
    ["Completed on Top"] = function(a, b)
        local aCompleted = a.isComplete or false
        local bCompleted = b.isComplete or false

        if aCompleted and not bCompleted then
            return true
        elseif not aCompleted and bCompleted then
            return false
        else
            return a:getText() < b:getText()
        end
    end,
    ["Completed on Bottom"] = function(a, b)
        local aCompleted = a.isComplete or false
        local bCompleted = b.isComplete or false

        if aCompleted and not bCompleted then
            return false
        elseif not aCompleted and bCompleted then
            return true
        else
            return a:getText() < b:getText()
        end
    end
}

local function sendQuestTracker(listToMap)
    local map = {}
    for _, entry in ipairs(listToMap) do
        map[entry[1]] = entry[2]
    end
    g_game.sendRequestTrackerQuestLog(map)
end

local function destroyWindows(windows)
    if type(windows) == "table" then
        for _, window in pairs(windows) do
            if window and not window:isDestroyed() then
                window:destroy()
            end
        end
    else
        if windows and not windows:isDestroyed() then
            windows:destroy()
        end
    end
    return nil
end

local function resetItemCategorySelection(list)
    for _, child in pairs(list:getChildren()) do
        child:setChecked(false)
        child:setBackgroundColor(child.BaseColor)
        if child.iconShow then
            child.iconShow:setVisible(child.isHiddenQuestLog)
        end
        if child.iconPin then
            child.iconPin:setVisible(child.isPinned)
        end
    end
end

local function createQuestItem(parent, id, text, color, icon)
    local item = g_ui.createWidget("QuestLogLabel", parent)
    item:setId(id)
    item:setText(text)
    item:setBackgroundColor(color)
    item:setPhantom(false)
    item:setFocusable(true)
    item.BaseColor = color
    item.isPinned = false
    item.isComplete = false
    if icon then
        item:setIcon(icon)
    end
    if parent == UITextList.questLogList then
        table.insert(questLogCache.items, item)
        if icon ~= "" then
            item.isComplete = true
            questLogCache.completed = questLogCache.completed + 1
        end
    end
    return item
end

local function updateQuestCounter()
    UIlabel.numberQuestComplete:setText(questLogCache.completed)
    UIlabel.numberQuestHidden:setText(questLogCache.hidden)
end

local function recolorVisibleItems()
    local categoryColor = COLORS.BASE_1
    local visibleIndex = 0

    for _, item in pairs(questLogCache.items) do
        if item:isVisible() then
            visibleIndex = visibleIndex + 1
            item:setBackgroundColor(visibleIndex % 2 == 1 and COLORS.BASE_1 or COLORS.BASE_2)
            item.BaseColor = item:getBackgroundColor()
        end
    end
end

local function sortQuestList(questList, sortOrder)
    questLogController.currentSortOrder = sortOrder
    local pinnedItems = {}
    local regularItems = {}
    for _, child in pairs(questLogCache.items) do
        if child.isPinned then
            table.insert(pinnedItems, child)
        else
            table.insert(regularItems, child)
        end
    end
    local sortFunc = sortFunctions[sortOrder]
    if sortFunc then
        table.sort(regularItems, sortFunc)
    end
    questLogCache.items = {}
    local index = 1
    for _, item in ipairs(pinnedItems) do
        questList:moveChildToIndex(item, index)
        table.insert(questLogCache.items, item)
        index = index + 1
    end
    for _, item in ipairs(regularItems) do
        questList:moveChildToIndex(item, index)
        table.insert(questLogCache.items, item)
        index = index + 1
    end
    recolorVisibleItems()
    updateQuestCounter()
end


local function setupQuestItemClickHandler(item, isQuestList)
    function item:onClick()
        local list = isQuestList and UITextList.questLogList or UITextList.questLogLine
        resetItemCategorySelection(list)
        self:setChecked(true)
        self:setBackgroundColor(COLORS.SELECTED)
        if isQuestList then
            g_game.requestQuestLine(self:getId())
            self.iconShow:setVisible(true)
            self.iconPin:setVisible(true)
            questLogController.ui.panelQuestLineSelected:setText(self:getText())
        else
            UITextList.questLogInfo:setText(self.description)
        end
        UICheckBox.showInQuestTracker:setChecked(
            isIdInTracker(g_game.getCharacterName():lower(), tonumber(self:getId())))
    end

    if isQuestList then
        function item.iconPin:onClick(mousePos)
            local parent = self:getParent()
            parent.isPinned = not parent.isPinned
            if parent.isPinned then
                self:setImageColor("#00ff00")
                local list = UITextList.questLogList
                list:removeChild(parent)
                list:insertChild(1, parent)

                table.removevalue(questLogCache.items, parent)
                table.insert(questLogCache.items, 1, parent)
                recolorVisibleItems()
            else
                self:setImageColor("#ffffff")
                self:setVisible(false)
                sortQuestList(UITextList.questLogList, questLogController.currentSortOrder or "Alphabetically (A-Z)")
            end
            return true
        end

        function item.iconShow:onClick(mousePos, mouseButton)
            local parent = self:getParent()
            parent.isHiddenQuestLog = not parent.isHiddenQuestLog
            if parent.isHiddenQuestLog then
                questLogCache.hidden = questLogCache.hidden + 1
                self:setImageColor("#ff0000")
                if not UICheckBox.showShidden:isChecked() then
                    parent:setVisible(false)
                    questLogCache.visible = questLogCache.visible - 1
                end
            else
                questLogCache.hidden = questLogCache.hidden - 1
                self:setImageColor("#ffffff")
                if UICheckBox.showShidden:isChecked() then
                    parent:setVisible(false)
                    questLogCache.visible = questLogCache.visible - 1
                else
                    local isCompleted = parent.isComplete
                    local shouldBeVisible = UICheckBox.showComplete:isChecked() or not isCompleted
                    parent:setVisible(shouldBeVisible)
                    if shouldBeVisible then
                        questLogCache.visible = questLogCache.visible + 1
                    end
                end
            end

            if parent.iconShow then
                parent.iconShow:setVisible(parent.isHiddenQuestLog)
            end
            if parent.iconPin then
                parent.iconPin:setVisible(parent.isPinned)
            end

            updateQuestCounter()
            recolorVisibleItems()
            return true
        end
    end
end

--[[=================================================
=                        Windows                     =
=================================================== ]] --
local function hide()
    if not questLogController.ui then
        return
    end
    questLogController.ui:hide()
end

function show()
    if not questLogController.ui then
        return
    end
    g_game.requestQuestLog()
    questLogController.ui:show()
    questLogController.ui:raise()
    questLogController.ui:focus()
end

local function toggle()
    if not questLogController.ui then
        return
    end
    if questLogController.ui:isVisible() then
        return hide()
    end
    show()
end

local function toggleTracker()
    if trackerMiniWindow:isOn() then
        trackerMiniWindow:close()
    else
        if not trackerMiniWindow:getParent() then
            local panel = modules.game_interface
                              .findContentPanelAvailable(trackerMiniWindow, trackerMiniWindow:getMinimumHeight())
            if not panel then
                return
            end
            panel:addChild(trackerMiniWindow)
        end
        trackerMiniWindow:open()
    end
end
--[[=================================================
=                        miniWindows                     =
=================================================== ]] --
function onOpenTracker()
    buttonQuestLogTrackerButton:setOn(true)
end

function onCloseTracker()
    buttonQuestLogTrackerButton:setOn(false)
end

local function showQuestTracker()
    if trackerMiniWindow then
        toggleTracker()
        return
    end
    trackerMiniWindow = g_ui.createWidget('QuestLogTracker')
    trackerMiniWindow.menuButton.onClick = function(widget, mousePos)
        local menu = g_ui.createWidget('PopupMenu')
        menu:setGameMenu(true)
        menu:addOption('Remove All quest', function()
            if settings[namePlayer] then
                table.clear(settings[namePlayer])
                sendQuestTracker(settings[namePlayer])
                trackerMiniWindow.contentsPanel.list:getLayout():enableUpdates()
                trackerMiniWindow.contentsPanel.list:getLayout():update()
            end
        end)
        menu:addOption('Remove completed quests', function()
            print("to-do")
        end)
        menu:addSeparator()
        menu:addCheckBox('Automatically track new quests', false, function(a, b)
            print(a, b)
        end):disable()
        menu:addCheckBox('Automatically untrack completed quests', false, function(a, b)
            print(a, b)
        end):disable()

        menu:display(mousePos)
        return true
    end
    trackerMiniWindow.cyclopediaButton.onClick = function()
        show()
        return true
    end
    trackerMiniWindow:moveChildToIndex(trackerMiniWindow.menuButton, 4)
    trackerMiniWindow:moveChildToIndex(trackerMiniWindow.cyclopediaButton, 5)
    trackerMiniWindow:setContentMinimumHeight(80)
    trackerMiniWindow:setup()
    toggleTracker()
end

--[[=================================================
=                      onParse                      =
=================================================== ]] --
local function onQuestLog(questList)
    UITextList.questLogList:destroyChildren()

    questLogCache = {
        items = {},
        completed = 0,
        hidden = 0,
        visible = #questList
    }

    local categoryColor = COLORS.BASE_1
    for _, data in pairs(questList) do
        local id, questName, questCompleted = unpack(data)
        if _ == 2 and true then
            questCompleted = false
        end
        local icon = questCompleted and "/game_cyclopedia/images/checkmark-icon" or ""
        local itemCat = createQuestItem(UITextList.questLogList, id, questName, categoryColor, icon)
        setupQuestItemClickHandler(itemCat, true)
        categoryColor = categoryColor == COLORS.BASE_1 and COLORS.BASE_2 or COLORS.BASE_1
    end
    sortQuestList(UITextList.questLogList, "Alphabetically (A-Z)")
    updateQuestCounter()
end

local function onQuestLine(questId, questMissions)
    UITextList.questLogLine:destroyChildren()
    local categoryColor = COLORS.BASE_1
    for _, data in pairs(questMissions) do
        local missionName, missionDescription, missionId = unpack(data)
        local itemCat = createQuestItem(UITextList.questLogLine, missionId, missionName, categoryColor)
        itemCat.description = missionDescription
        setupQuestItemClickHandler(itemCat, false)
        categoryColor = categoryColor == COLORS.BASE_1 and COLORS.BASE_2 or COLORS.BASE_1
    end
end

local function onQuestTracker(remainingQuests, missions)
    if not trackerMiniWindow then
        showQuestTracker()
    end
    if not missions or type(missions[1]) ~= "table" then
        trackerMiniWindow.contentsPanel.list:destroyChildren()
        return
    end
    trackerMiniWindow.contentsPanel.list:destroyChildren()
    for index, mission in ipairs(missions) do
        local questId, missionId, questName, missionName, missionDesc = unpack(mission)
        local trackerLabel = g_ui.createWidget('QuestTrackerLabel', trackerMiniWindow.contentsPanel.list)
        trackerLabel:setId(missionId)
        trackerLabel.description:setText(missionDesc)
    end
end

local function onUpdateQuestTracker(questId, missionId, questName, missionName, missionDesc)
    -- untest
    -- print(questId, missionId, questName, missionName, missionDesc)
    local trackerLabel = trackerMiniWindow.contentsPanel.list:getChildById(missionId)
    if trackerLabel then
        trackerLabel.description:setText(missionDesc)
    end
end
--[[=================================================
=               onCall otui / html                  =
=================================================== ]] --
function filterQuestList(searchText)
    local showComplete = UICheckBox.showComplete:isChecked()
    local showHidden = UICheckBox.showShidden:isChecked()
    local searchPattern = searchText and string.lower(searchText) or nil
    questLogCache.visible = 0
    for _, child in pairs(questLogCache.items) do
        local isCompleted = child.isComplete
        local isHidden = child.isHiddenQuestLog
        local text = child:getText()
        local visible = true
        if searchPattern and text then
            visible = string.find(string.lower(text), searchPattern) ~= nil
        end
        if not showComplete and isCompleted then
            visible = false
        end
        if showHidden then
            visible = visible and isHidden
        else
            visible = visible and not isHidden
        end
        child:setVisible(visible)
        if visible then
            questLogCache.visible = questLogCache.visible + 1
        end
        if child.iconShow then
            child.iconShow:setVisible(child.isHiddenQuestLog)
        end
    end
    recolorVisibleItems()
end

function questLogController:onCheckChangeQuestTracker(event)
    if not trackerMiniWindow then
        showQuestTracker()
        return
    end
    if UITextList.questLogLine:hasChildren() and UITextList.questLogLine:getFocusedChild() then
        local id = tonumber(UITextList.questLogLine:getFocusedChild():getId())
        if event.checked then
            showQuestTracker()
            addUniqueIdQuest(namePlayer, id, UITextList.questLogLine:getFocusedChild():getText())
        else
            removeNumber(namePlayer, id, UITextList.questLogLine:getFocusedChild():getText())
            local trackerLabel = trackerMiniWindow.contentsPanel.list[id]
            if trackerLabel then
                trackerLabel:destroy()
                trackerLabel = nil
            end
        end
        if settings[namePlayer] and (event.checked == isIdInTracker(namePlayer, id)) then
            sendQuestTracker(settings[namePlayer])
        end
    end
end

function questLogController:onFilterQuestLog(event)
    if sortFunctions[event.text] then
        sortQuestList(UITextList.questLogList, event.text)
    end
end

function questLogController:close()
    hide()
end

function questLogController:toggleMiniWindowsTracker()
    if not trackerMiniWindow then
        showQuestTracker()
        return
    end
    if trackerMiniWindow:isVisible() then
        if buttonQuestLogTrackerButton then
            buttonQuestLogTrackerButton:setOn(false)
        end
        return trackerMiniWindow:hide()
    end
    if buttonQuestLogTrackerButton then
        buttonQuestLogTrackerButton:setOn(true)
    end
    showQuestTracker()
end

function questLogController:filterQuestListShowComplete()
    filterQuestList()
end

function questLogController:filterQuestListShowHidden()
    filterQuestList()
end

function onSearchTextChange(text)
    if text and text:len() > 0 then
        filterQuestList(text)
    else
        filterQuestList()
    end
end

function onQuestLogMousePress(widget, mousePos, mouseButton)
    if mouseButton ~= MouseRightButton then
        return
    end
    local menu = g_ui.createWidget('PopupMenu')
    menu:setGameMenu(true)
    menu:addOption(tr('remove'), function()
        removeNumber(namePlayer, widget:getParent():getId())
        if settings[namePlayer] then
            sendQuestTracker(settings[namePlayer])
        end
        widget:getParent():destroy()
    end)
    menu:display(mousePos)
    return true
end

--[[=================================================
=               Controller                     =
=================================================== ]] --
function questLogController:onInit()
    g_ui.importStyle("styles/game_questlog.otui")
    questLogController:loadHtml('game_questlog.html')
    questLogController.ui:centerIn('parent')
    hide()

    UITextList.questLogList = questLogController.ui.panelQuestLog.areaPanelQuestList.questList
    UITextList.questLogLine = questLogController.ui.panelQuestLineSelected.ScrollAreaQuestList.questList
    UITextList.questLogInfo = questLogController.ui.panelQuestLineSelected.panelQuestInfo.questList
    UITextList.questLogInfo:setBackgroundColor('#363636')

    UITextEdit.search = questLogController.ui.panelQuestLog.textEditSearchQuest
    UIlabel.numberQuestComplete = questLogController.ui.panelQuestLog.filterPanel.lblCompleteNumber
    UIlabel.numberQuestHidden = questLogController.ui.panelQuestLog.filterPanel.lblHiddenNumber
    UICheckBox.showComplete = questLogController.ui.panelQuestLog.filterPanel.checkboxShowComplete
    UICheckBox.showShidden = questLogController.ui.panelQuestLog.filterPanel.checkboxShowShidden
    UICheckBox.showInQuestTracker = questLogController.ui.panelQuestLineSelected.checkboxShowInQuestTracker

    questLogController:registerEvents(g_game, {
        onQuestLog = onQuestLog,
        onQuestLine = onQuestLine,
        onQuestTracker = onQuestTracker,
        onUpdateQuestTracker = onUpdateQuestTracker
    })

    questLogButton = modules.game_mainpanel.addToggleButton('questLogButton', tr('Quest Log'),
        '/images/options/button_questlog', function()
            toggle()
        end, false, 1000)
    Keybind.new("Windows", "Show/hide quest Log", "", "")
    Keybind.bind("Windows", "Show/hide quest Log", {{
        type = KEY_DOWN,
        callback = function()
            show()
        end
    }})
end

function questLogController:onTerminate()
    questLogButton, trackerMiniWindow, buttonQuestLogTrackerButton = destroyWindows(
        {questLogButton, trackerMiniWindow, buttonQuestLogTrackerButton})
    Keybind.delete("Windows", "Show/hide quest Log")
end

function questLogController:onGameStart()
    if g_game.getClientVersion() >= 1280 then
        namePlayer = g_game.getCharacterName():lower()
        settings = load() or {}
        if settings[namePlayer] then
            sendQuestTracker(settings[namePlayer])
        end
        if not buttonQuestLogTrackerButton then
            buttonQuestLogTrackerButton = modules.game_mainpanel.addToggleButton("QuestLogTracker",
                tr("Open QuestLog Tracker"), "/images/options/button_questlog_tracker", function()
                    questLogController:toggleMiniWindowsTracker()
                end, false, 1001)
        end
        if trackerMiniWindow then
            trackerMiniWindow:setupOnStart()
        end
    else
        UICheckBox.showInQuestTracker:setVisible(false)
        questLogController.ui.trackerButton:setVisible(false)
    end
end

function questLogController:onGameEnd()
    if g_game.getClientVersion() >= 1280 then
        save()
    end
    hide()
    if trackerMiniWindow then
        trackerMiniWindow:setParent(nil, true)
    end
end

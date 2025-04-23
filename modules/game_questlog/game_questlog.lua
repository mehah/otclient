-- https://github.com/opentibiabr/canary/pull/3499
-- https://github.com/Black-Tek/BlackTek-Server/pull/50
questLogController = Controller:new()
local trackerMiniWindow = nil
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

-- @ Auxiliar widget
local questLogButton = nil
local buttonQuestLogTrackerButton = nil
-- @ array
local settings = {}
local COLORS = {
    BASE_1 = "#484848",
    BASE_2 = "#414141",
    SELECTED = "#585858"
}
-- @ string
local namePlayer = ""
local file = "/settings/questtracking.json"

-- /*=============================================
-- =            Local functions             =
-- =============================================*/
local sortFunctions = {
    ["Alphabetically (A-Z)"] = function(a, b)
        return a:getText() < b:getText()
    end,
    ["Alphabetically (Z-A)"] = function(a, b)
        return a:getText() > b:getText()
    end
}

local function resetItemCategorySelection(list, showIcons)
    for _, child in pairs(list:getChildren()) do
        child:setChecked(false)
        child:setBackgroundColor(child.BaseColor)

        if showIcons then
            child.iconShow:setVisible(false)
            child.iconPin:setVisible(false)
        end
    end
end

local function createQuestItem(parent, id, text, color, icon)
    local item = g_ui.createWidget("QuestLogLabel", parent)
    item:setId(id)
    item:setText(text)
    item:setBackgroundColor(color)
    item:setPhantom(false)
    item.BaseColor = color

    if icon then
        item:setIcon(icon)
    end

    return item
end

local function setupQuestItemClickHandler(item, isQuestList)
    function item:onClick()
        local list = isQuestList and UITextList.questLogList or UITextList.questLogLine
        resetItemCategorySelection(list, isQuestList)

        self:setChecked(true)
        self:setBackgroundColor(COLORS.SELECTED)

        if isQuestList then
            g_game.requestQuestLine(self:getId())
            self.iconShow:setVisible(true)
            self.iconPin:setVisible(true)
        else
            UITextList.questLogInfo:setText(self.description)
        end
    end
end

local function sortQuestList(questList, sortOrder)
    local items = {}
    for _, child in pairs(questList:getChildren()) do
        table.insert(items, child)
    end

    local sortFunc = sortFunctions[sortOrder]
    if sortFunc then
        table.sort(items, sortFunc)
    end

    questList:destroyChildren()

    local categoryColor = COLORS.BASE_1
    for _, item in ipairs(items) do
        local newItem = createQuestItem(questList, item:getId(), item:getText(), categoryColor, item:getIconPath())
        setupQuestItemClickHandler(newItem, true)
        categoryColor = categoryColor == COLORS.BASE_1 and COLORS.BASE_2 or COLORS.BASE_1
    end
end

-- /*=============================================
-- =                    Windows                 =
-- =============================================*/

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

local function showQuestTracker()
    if trackerMiniWindow then
        trackerMiniWindow:show()
        return
    end
    trackerMiniWindow = g_ui.createWidget('QuestLogTracker', modules.game_interface.getRightPanel())

    trackerMiniWindow.menuButton.onClick = function(widget, mousePos, mouseButton)
        local menu = g_ui.createWidget('QuestLogMiniWindowsMenu')
        menu:setGameMenu(true)
        menu:display(mousePos)
        return true
    end

    trackerMiniWindow.cyclopediaButton.onClick = function(widget, mousePos, mouseButton)
        show()
        return true
    end

    trackerMiniWindow:moveChildToIndex(trackerMiniWindow.menuButton, 4)
    trackerMiniWindow:moveChildToIndex(trackerMiniWindow.cyclopediaButton, 5)
    trackerMiniWindow:setup()
end

local function hide()
    if not questLogController.ui then
        return
    end
    questLogController.ui:hide()
end
-- /*=============================================
-- =                    parse                   =
-- =============================================*/
local function countCompletedQuests()
    local countComplete = 0
    local countHidden = 0
    for _, child in pairs(UITextList.questLogList:getChildren()) do
        if child:getIconPath() and child:getIconPath():find("checkmark") then
            countComplete = countComplete + 1
        end
        if child.isHiddenQuestLog then
            countHidden = countHidden + 1
        end
    end
    return countComplete, countHidden
end

local function onQuestLog(questList)
    UITextList.questLogList:destroyChildren()
    local categoryColor = COLORS.BASE_1
    for _, data in pairs(questList) do
        local id, questName, questCompleted = unpack(data)
        local icon = questCompleted and "/game_cyclopedia/images/checkmark-icon" or ""
        local itemCat = createQuestItem(UITextList.questLogList, id, questName, categoryColor, icon)
        setupQuestItemClickHandler(itemCat, true)
        categoryColor = categoryColor == COLORS.BASE_1 and COLORS.BASE_2 or COLORS.BASE_1
    end
    sortQuestList(UITextList.questLogList, "Alphabetically (A-Z)")
    local countComplete, countHidden = countCompletedQuests()
    UIlabel.numberQuestComplete:setText(countComplete)
    UIlabel.numberQuestHidden:setText(countHidden)
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
    if not missions or type(missions[1]) ~= "table" then
        return
    end
    if not trackerMiniWindow then
        showQuestTracker()
        return
    end
    local missionId, questName, questIsCompleted, missionName, missionDesc = unpack(missions[1])
    local trackerLabel = trackerMiniWindow.contentsPanel.list[missionId]
    trackerLabel = trackerLabel or g_ui.createWidget('QuestTrackerLabel', trackerMiniWindow.contentsPanel.list)
    trackerLabel:setId(missionId)
    trackerLabel.description:setText(missionDesc)
end

local function onUpdateQuestTracker(missionId, missionName, questIsCompleted, missionDesc)
    print("onUpdateQuestTracker", missionId, missionName, questIsCompleted, missionDesc)
end

-- /*=============================================
-- =            call css/html/otui             =
-- =============================================*/

function questLogController:test(event)
    if UITextList.questLogLine:hasChildren() and UITextList.questLogLine:getFocusedChild() then
        local id = tonumber(UITextList.questLogLine:getFocusedChild():getId())
        if event.checked then
            addUniqueIdQuest(namePlayer, id)
        else
            removeNumber(namePlayer, id)
            local trackerLabel = trackerMiniWindow.contentsPanel.list[id]
            trackerLabel:destroy()
        end
        g_game.sendRequestTrackerQuestLog(settings[namePlayer])
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

function questLogController:filterQuestListShowComplete(event)
    if event.checked then
        for _, child in pairs(UITextList.questLogList:getChildren()) do
            if child:getIconPath() and child:getIconPath():find("checkmark") then
                child:setVisible(true)
            else
                child:setVisible(false)
            end
        end
    else
        for _, child in pairs(UITextList.questLogList:getChildren()) do
            child:setVisible(true)
        end
    end
end

function questLogController:filterQuestListShowHidden(event)
    if event.checked then
        for _, child in pairs(UITextList.questLogList:getChildren()) do
            if child.isHiddenQuestLog then
                child:setVisible(true)
            else
                child:setVisible(false)

            end
        end
    else

        for _, child in pairs(UITextList.questLogList:getChildren()) do
            child:setVisible(true)
        end
    end
end
--@ otui
function onSearchTextChange(text)
    if not text or #text == 0 then
        for _, child in pairs(UITextList.questLogList:getChildren()) do
            child:setVisible(true)
        end
    else
        text = text:lower()
        for _, child in pairs(UITextList.questLogList:getChildren()) do
            local questName = child:getText():lower()
            child:setVisible(string.find(questName, text) ~= nil)
        end
    end
end
-- /*=============================================
-- =            controller             =
-- =============================================*/

function questLogController:onInit()
    g_ui.importStyle("game_questlog.otui")
    questLogController:loadHtml('game_questlog.html')
    questLogController.ui:centerIn('parent') -- temp fix css
    hide()

    UITextList.questLogList = questLogController.ui.panelQuestLog.areaPanelQuestList.spellList
    UITextList.questLogLine = questLogController.ui.panelQuestLineSelected.ScrollAreaQuestList.spellList
    UITextList.questLogInfo = questLogController.ui.panelQuestLineSelected.panelQuestInfo.spellList
    UITextList.questLogInfo:setBackgroundColor('#363636')

    UITextEdit.search = questLogController.ui.panelQuestLog.textEditSearchQuest

    UIlabel.numberQuestComplete = questLogController.ui.panelQuestLog.filterPanel.lblCompleteNumber
    UIlabel.numberQuestHidden = questLogController.ui.panelQuestLog.filterPanel.lblHiddenNumber

    UICheckBox.showComplete = questLogController.ui.panelQuestLog.checkboxShowComplete
    UICheckBox.showShidden = questLogController.ui.panelQuestLog.checkboxShowShidden
    UICheckBox.showInQuestTracker = questLogController.ui.panelQuestLineSelected.checkboxShowInQuestTracker

    questLogController:registerEvents(g_game, {
        onQuestLog = onQuestLog,
        onQuestLine = onQuestLine,
        onQuestTracker = onQuestTracker,
        onUpdateQuestTracker = onUpdateQuestTracker
    })

    questLogButton = modules.game_mainpanel.addToggleButton('questLogButton', tr('Quest Log'),
        '/images/options/button_questlog', function()
            show()
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
    --  BlessingController:findWidget("#main"):destroy()
    if questLogButton then
        questLogButton:destroy()
        questLogButton = nil
    end
    if trackerMiniWindow then
        trackerMiniWindow:destroy()
        trackerMiniWindow = nil
    end
    if buttonQuestLogTrackerButton then
        buttonQuestLogTrackerButton:destroy()
        buttonQuestLogTrackerButton = nil
    end
    Keybind.delete("Windows", "Show/hide quest Log")
end

function questLogController:onGameStart()
    namePlayer = g_game.getCharacterName():lower()
    if g_game.getClientVersion() >= 1280 then
        load()
        g_game.sendRequestTrackerQuestLog(settings[namePlayer])
    elseif g_game.getClientVersion() >= 1410 then
        buttonQuestLogTrackerButton = modules.game_mainpanel.addToggleButton("QuestLogTracker", tr("Open QuestLog Tracker"),
        "/images/options/button_questlog_tracker", function() questLogController:toggleMiniWindowsTracker() end, false, 17)
    end
end

function questLogController:onGameEnd()
    if g_game.getClientVersion() >= 1280 then
        save()
    end
    hide()
    if trackerMiniWindow then
        trackerMiniWindow:hide()
    end
end

-- /*=============================================
-- =            json             =
-- =============================================*/

function addUniqueIdQuest(key, number)
    if not settings[key] then
        settings[key] = {}
    end
    if not table.contains(settings[key], number) then
        table.insert(settings[key], number)
    end
end

function removeNumber(key, number)
    if settings[key] then
        table.removevalue(settings[key], number)
    end
end

function load()
    if g_resources.fileExists(file) then
        local status, result = pcall(function()
            return json.decode(g_resources.readFileContents(file))
        end)
        if not status then
            return g_logger.error(
                "Error while reading profiles file. To fix this problem you can delete storage.json. Details: " ..
                    result)
        end
        settings = result
    end
end

function save()
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

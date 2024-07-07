-- @ widgets
local highscoreButton, worldTypeRadioGroup = nil, nil

-- @ delete this v
local ComboWindow
local devMode = true

-- @

-- @ number
local currentPage, countPages = 0, 0
local entriesPerPage = 20
local categoryId, vocationId = 0, 4294967295.0

-- @ Array
-- LuaFormatter off
local vocationArray, Category = {}, {}
local tempFixworldType = {
    {0, "Open Pvp"},
    {1, "Optional Pvp"},
    {2, "Hardcore Pvp"},
    {3, "Retro Open Pvp"},
    {4, "Retro Hardcore Pvp"}
}

local serverSide = {
    action = 0,
    category = 0,
    vocation = 0xFFFFFFFF,
    world = "",
    worldType = 1,
    battlEye = 1,
    page = 1,
    totalInPages = 20
}
-- LuaFormatter on

local function getMinutesDifference(t1, t2)
    local diffInSeconds = os.difftime(t2, t1)
    local diffInMinutes = diffInSeconds / 60
    local diffInHours = diffInMinutes / 60

    if diffInHours >= 1 then
        return string.format("Last Update: %.0f Hrs Ago", diffInHours)
    elseif diffInMinutes >= 1 then
        return string.format("Last Update: %.0f minutes Ago", diffInMinutes)
    else
        return string.format("Last Update: %.0f Second Ago", math.abs(diffInSeconds))
    end
end

local function getCategory(arg)
    if type(arg) == "string" then
        for i, cat in ipairs(Category) do
            if cat[2] == arg then
                return cat[1]
            end
        end
    end
    return 0
end

local function getVocation(arg)
    if type(arg) == "number" then
        for _, voc in ipairs(vocationArray) do
            if voc[1] == arg then
                return voc[2]
            end
        end
    elseif type(arg) == "string" then
        for _, voc in ipairs(vocationArray) do
            if voc[2] == arg then
                return voc[1]
            end
        end
    end
    return "All Vocations"
end

highscoreController = Controller:new()
highscoreController:setUI('game_highscore')

function highscoreController:onInit()

    highscoreController.ui:hide()


 
    highscoreController:registerEvents(g_game, {
        onProcessHighscores = onProcessHighscores
    })

    -- @ delete this V
    if devMode then
        TryInCanary()
    end

    -- @
end

function highscoreController:onTerminate()
    if highscoreButton then
        highscoreButton:destroy()
        highscoreButton = nil
    end
    if worldTypeRadioGroup then
        worldTypeRadioGroup:destroy()
        worldTypeRadioGroup = nil
    end

    -- @ delete this V
    if devMode and ComboWindow then
        ComboWindow:destroy()
        ComboWindow = nil
    end
    -- @

end

function onProcessHighscores(serverName, world, worldType, battlEye, vocations, categories, page, totalInPages,
    highscores, entriesTs)

    vocationArray = table.copy(vocations)
    Category = table.copy(categories)
    currentPage = page
    countPages = totalInPages
    local ui = highscoreController.ui
    local uiFilters = ui.filters

    if not uiFilters.PanelWorld.isFilled then
        worldTypeRadioGroup = UIRadioGroup.create()
        for _, temp in ipairs(tempFixworldType) do
            local label = g_ui.createWidget("WorldType", uiFilters.PanelWorld)
            label.text:setText(temp[2])
            worldTypeRadioGroup:addWidget(label.enabled)
        end
        uiFilters.PanelWorld.isFilled = true
    end
    -- LuaFormatter off
    local filterData = {
        {box = uiFilters.vocationBox, data = vocations, label = "All Vocations"},
        {box = uiFilters.categoryBox, data = categories, label = nil},
    }

    for _, filter in ipairs(filterData) do
        if not filter.box.isFilled then
            if filter.label then
                filter.box:addOption(filter.label)
            end
            for _, item in ipairs(filter.data) do
                filter.box:addOption(item[2])
            end
            filter.box.isFilled = true
        end
    end
    -- LuaFormatter on

    if not uiFilters.BattlEyeBox.isFilled then
        uiFilters.BattlEyeBox:addOption(battlEye)
        uiFilters.BattlEyeBox.isFilled = true
    end

    if not uiFilters.gameWorldBox.isFilled then
        uiFilters.gameWorldBox:addOption(world ~= "" and world or serverName)
        uiFilters.gameWorldBox.isFilled = true
    end

    local isFirstPage = currentPage == 1
    local isLastPage = currentPage == countPages

    ui.next:setEnabled(not isLastPage)
    ui.nextLast:setEnabled(not isLastPage)
    ui.prev:setEnabled(not isFirstPage)
    ui.prevLast:setEnabled(not isFirstPage)
    ui.ownRankButton:setEnabled(true)

    ui.page:setText(page .. " / " .. totalInPages)

    local diferenciaEnMinutos = getMinutesDifference(entriesTs, os.time())

    ui.last_update:setText(diferenciaEnMinutos)
    createHighscores(highscores)
end

function highscoreController:onGameStart()

    if g_game.getClientVersion() < 1310 then
        return
    end

    highscoreButton = modules.client_topmenu.addRightGameToggleButton('highscore', tr('highscore'),
        '/images/options/highscores', toggle, false)
    highscoreButton:setOn(false)

end

function highscoreController:onGameEnd()
    if highscoreController.ui:isVisible() then
        highscoreController.ui:hide()
    end
    if ComboWindow then
        ComboWindow:destroy()
        ComboWindow = nil
    end
end
function hide()
    if not highscoreController.ui then
        return
    end
    highscoreController.ui:hide()
end

function show()
    if not highscoreController.ui or not highscoreButton then
        return
    end

    highscoreController.ui:show()
    highscoreController.ui:raise()
    highscoreController.ui:focus()
    requestInfo()
end

function toggle()
    if not highscoreController.ui then
        return
    end

    if highscoreController.ui:isVisible() then
        return hide()
    end
    show()
end

function createHighscores(list)
    -- LuaFormatter off
    local data = highscoreController.ui.data
    data:getLayout():disableUpdates()
    data:destroyChildren()

    local playerName = g_game.getLocalPlayer():getName()

    for index, entry in ipairs(list) do
        local row = g_ui.createWidget("HighScoreData", data)
        row:setBackgroundColor(index % 2 == 0 and "#ffffff12" or "#00000012")
        row.rank:setText(entry[1] .. ".")
        row.name:setText(entry[2])
        row.voc:setText(entry[4] == 0 and "None" or getVocation(entry[4] == 1 and entry[4] + 3 or (entry[4] < 3 and entry[4] + 1 or entry[4] - 2)))
        row.world:setText(entry[5])
        row.level:setText(entry[6])
        row.points:setText(comma_value(entry[8]))
        if playerName:lower() == entry[2]:lower() then
            for _, widget in pairs({"rank", "name", "voc", "world", "level", "points"}) do
                row[widget]:setColor("#60f860")
            end
        end
    end
    data:getLayout():enableUpdates()
    data:getLayout():update()
    -- LuaFormatter on
end

local function changePage(newPage)
    disableButtons()
    highscoreRequest(newPage, 0)
end

-- LuaFormatter off
function nextPage() changePage(currentPage + 1) end
function nextEndPage() changePage(countPages) end
function prevPage() changePage(currentPage - 1) end
function prevEndPage() changePage(1) end
-- LuaFormatter on

function disableButtons()
    for _, btn in ipairs({"next", "nextLast", "prev", "prevLast", "ownRankButton"}) do
        highscoreController.ui[btn]:setEnabled(false)
    end
end

function submit()
    disableButtons()
    highscoreRequest(1, 0)
end

function showOwnRank()
    disableButtons()
    highscoreRequest(1, 1)
end

function highscoreRequest(currentPage, typex)

    local id = getVocation(highscoreController.ui.filters.vocationBox:getCurrentOption().text)
    id = (id == "All Vocations" and 0xFFFFFFFF or id)

    local categoryId = getCategory(highscoreController.ui.filters.categoryBox:getCurrentOption().text)

    g_game.requestHighscore(typex, categoryId, id, serverSide.world, serverSide.worldType, serverSide.battlEye,
        currentPage, serverSide.totalInPages)
    if devMode then
        local values = {
            NOMBBRE = "requestHighscore",
            action = typex,
            category = categoryId,
            vocation = id,
            world = serverSide.world,
            worldType = serverSide.worldType,
            battlEye = serverSide.battlEye,
            page = currentPage,
            totalInPages = serverSide.totalInPages
        }

        pdump(values)
    end
end

function requestInfo()

    g_game.requestHighscore(serverSide.action, serverSide.category, serverSide.vocation, serverSide.world,
        serverSide.worldType, serverSide.battlEye, serverSide.page, serverSide.totalInPages)

end

-- @ delete this  V  ( im trying in canary without own server)
function TryInCanary()
    local toolsButton = g_ui.createWidget("Button", highscoreController.ui)
    toolsButton:setText(tr('dev'))

    toolsButton:addAnchor(AnchorLeft, "parent", AnchorLeft)
    toolsButton:addAnchor(AnchorBottom, "parent", AnchorBottom)
    toolsButton:setMarginRight(10)

    toolsButton.onClick = function()
        ComboWindow = g_ui.createWidget("MainWindow", rootWidget)
        ComboWindow:setText(tr('me trying in canary, without own server jaja'))
        ComboWindow:setSize("300 320")
        ComboWindow.onEscape = function()
            ComboWindow:hide()
        end

        local function createTextEditWithLabel(parent, id, topMargin, labelText, text)
            local textEdit = g_ui.createWidget("TextEdit", parent)
            textEdit:setId(id)
            textEdit:addAnchor(AnchorTop, 'parent', AnchorTop)
            textEdit:addAnchor(AnchorLeft, 'parent', AnchorLeft)
            textEdit:setMarginLeft(10)
            textEdit:setMarginTop(topMargin)
            textEdit:setSize("150 20")
            textEdit:setText(text)

            local label = g_ui.createWidget("Label", parent)
            label:setColoredText(labelText)
            label:addAnchor(AnchorLeft, textEdit:getId(), AnchorRight)
            label:addAnchor(AnchorTop, textEdit:getId(), AnchorTop)
            label:setMarginLeft(5)
        end

        createTextEditWithLabel(ComboWindow, "action", 10, "action {addU8, #ff00ff}", 0)
        createTextEditWithLabel(ComboWindow, "category", 40, tr('category   {addU8, #ff00ff}'), 0)
        createTextEditWithLabel(ComboWindow, "vocation", 70, tr('vocation   {addU32, #ff00ff} '), 0xFFFFFFFF)
        createTextEditWithLabel(ComboWindow, "world", 100, tr('world  {addString, #ff00ff}'), "")
        createTextEditWithLabel(ComboWindow, "worldType", 130, tr('worldType   {addU8, #ff00ff}'), 1)
        createTextEditWithLabel(ComboWindow, "battlEye", 160, tr('battlEye  {addU8, #ff00ff} '), 1)
        createTextEditWithLabel(ComboWindow, "page", 190, tr('page  {addU16, #ff00ff} '), 3)
        createTextEditWithLabel(ComboWindow, "totalInPages", 220, tr('totalInPages {addU8, #ff00ff} '), 20)

        local closeButton = g_ui.createWidget("Button", ComboWindow)
        closeButton:setText(tr('Close'))

        closeButton:addAnchor(AnchorRight, 'parent', AnchorRight)
        closeButton:addAnchor(AnchorBottom, 'parent', AnchorBottom)
        closeButton:setMarginTop(15)
        closeButton:setMarginRight(5)
        closeButton.onClick = function()
            ComboWindow:destroy()
        end
        local sendButton = g_ui.createWidget("Button", ComboWindow)
        sendButton:setText(tr('send'))

        sendButton:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        sendButton:addAnchor(AnchorBottom, 'parent', AnchorBottom)
        sendButton:setMarginTop(15)
        sendButton:setMarginLeft(5)
        sendButton.onClick = function()

            g_game.requestHighscore(tonumber(ComboWindow.action:getText()), tonumber(ComboWindow.category:getText()),
                tonumber(ComboWindow.vocation:getText()), ComboWindow.world:getText(),
                tonumber(ComboWindow.worldType:getText()), tonumber(ComboWindow.battlEye:getText()),
                tonumber(ComboWindow.page:getText()), tonumber(ComboWindow.totalInPages:getText()))

            local values = {
                NOMBBRE = "DEV",
                action = tonumber(ComboWindow.action:getText()),
                category = tonumber(ComboWindow.category:getText()),
                vocation = tonumber(ComboWindow.vocation:getText()),
                world = ComboWindow.world:getText(),
                worldType = tonumber(ComboWindow.worldType:getText()),
                battlEye = tonumber(ComboWindow.battlEye:getText()),
                page = tonumber(ComboWindow.page:getText()),
                totalInPages = tonumber(ComboWindow.totalInPages:getText())
            }

            pdump(values)

        end
    end
end

-- @

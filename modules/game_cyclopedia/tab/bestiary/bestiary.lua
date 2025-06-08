local UI = nil

local STAGES = {
    CREATURES = 2,
    SEARCH = 4,
    CATEGORY = 1,
    CREATURE = 3
}

local storedRaceIDs = {}
local animusMasteryPoints = 0

function Cyclopedia.loadBestiaryOverview(name, creatures, animusMasteryPoints)
    if name == "Result" then
        Cyclopedia.loadBestiarySearchCreatures(creatures)
    else
        Cyclopedia.loadBestiaryCreatures(creatures)
    end

    if animusMasteryPoints and animusMasteryPoints > 0 then
        animusMasteryPoints = animusMasteryPoints
    end
end

function showBestiary()
    UI = g_ui.loadUI("bestiary", contentContainer)
    UI:show()

    UI.ListBase.CategoryList:setVisible(true)
    UI.ListBase.CreatureList:setVisible(false)
    UI.ListBase.CreatureInfo:setVisible(false)

    Cyclopedia.Bestiary.Stage = STAGES.CATEGORY
    controllerCyclopedia.ui.CharmsBase:setVisible(true)
    controllerCyclopedia.ui.GoldBase:setVisible(true)
    controllerCyclopedia.ui.BestiaryTrackerButton:setVisible(true)
    g_game.requestBestiary()
end

Cyclopedia.Bestiary = {}
Cyclopedia.BestiaryCache = Cyclopedia.BestiaryCache or {}
Cyclopedia.Bestiary.Stage = STAGES.CATEGORY

function Cyclopedia.SetBestiaryProgress(fit, firstBar, secondBar, thirdBar, killCount, firstGoal, secondGoal, thirdGoal)
    local function calculateWidth(value, max)
        return math.min(math.floor((value / max) * fit), fit)
    end

    local function setBarVisibility(bar, isVisible, width)
        isVisible = isVisible and width > 0
        bar:setVisible(isVisible)
        if isVisible then
            bar:setImageRect({
                height = 12,
                x = 0,
                y = 0,
                width = width
            })
            bar:setImageSource("/game_cyclopedia/images/bestiary/fill")
        end
    end

    local firstWidth = calculateWidth(math.min(killCount, firstGoal), firstGoal)
    setBarVisibility(firstBar, killCount > 0, firstWidth)

    local secondWidth = 0
    if killCount > firstGoal then
        secondWidth = calculateWidth(math.min(killCount - firstGoal, secondGoal - firstGoal), secondGoal - firstGoal)
    end
    setBarVisibility(secondBar, killCount > firstGoal, secondWidth)

    local thirdWidth = 0
    if killCount > secondGoal then
        thirdWidth = calculateWidth(math.min(killCount - secondGoal, thirdGoal - secondGoal), thirdGoal - secondGoal)
    end
    setBarVisibility(thirdBar, killCount > secondGoal, thirdWidth)
end

function Cyclopedia.SetBestiaryStars(value)
    UI.ListBase.CreatureInfo.StarFill:setWidth(value * 9)
end

function Cyclopedia.SetBestiaryDiamonds(value)
    UI.ListBase.CreatureInfo.DiamondFill:setWidth(value * 9)
end

function Cyclopedia.CreateCreatureItems(data)
    UI.ListBase.CreatureInfo.ItemsBase.Itemlist:destroyChildren()

    for index, _ in pairs(data) do
        local widget = g_ui.createWidget("BestiaryItemGroup", UI.ListBase.CreatureInfo.ItemsBase.Itemlist)
        widget:setId(index)

        if index == 0 then
            widget.Title:setText(tr("Common") .. ":")
        elseif index == 1 then
            widget.Title:setText(tr("Uncommon") .. ":")
        elseif index == 2 then
            widget.Title:setText(tr("Semi-Rare") .. ":")
        elseif index == 3 then
            widget.Title:setText(tr("Rare") .. ":")
        else
            widget.Title:setText(tr("Very Rare") .. ":")
        end

        for i = 1, 15 do
            local item = g_ui.createWidget("BestiaryItem", widget.Items)
            item:setId(i)
        end

        for itemIndex, itemData in ipairs(data[index]) do
            local thing = g_things.getThingType(itemData.id, ThingCategoryItem)
            local itemWidget = UI.ListBase.CreatureInfo.ItemsBase.Itemlist[index].Items[itemIndex]
            itemWidget:setItemId(itemData.id)
            itemWidget.id = itemData.id
            itemWidget.classification = thing:getClassification()

            if itemData.id == 0 then
                itemWidget.undefinedItem:setVisible(true)
            end

            if itemData.id > 0 then
                if itemData.stackable then
                    itemWidget.Stackable:setText("1+")
                else
                    itemWidget.Stackable:setText("1")
                end
            end

            ItemsDatabase.setRarityItem(itemWidget, itemWidget:getItem())

            itemWidget.onMouseRelease = onAddLootClick
        end
    end
end

function Cyclopedia.loadBestiarySelectedCreature(data)
    Cyclopedia.BestiaryCache[data.id] = data

    local occurence = {
        [0] = 1,
        2,
        3,
        4
    }

    local raceData = g_things.getRaceData(data.id)
    local formattedName = raceData.name:gsub("(%l)(%w*)", function(first, rest)
        return first:upper() .. rest
    end)

    UI.ListBase.CreatureInfo:setText(formattedName)
    Cyclopedia.SetBestiaryDiamonds(occurence[data.ocorrence])
    Cyclopedia.SetBestiaryStars(data.difficulty)
    UI.ListBase.CreatureInfo.LeftBase.Sprite:setOutfit(raceData.outfit)
    UI.ListBase.CreatureInfo.LeftBase.Sprite:getCreature():setStaticWalking(1000)

    Cyclopedia.SetBestiaryProgress(60, UI.ListBase.CreatureInfo.ProgressBack, UI.ListBase.CreatureInfo.ProgressBack33,
        UI.ListBase.CreatureInfo.ProgressBack55, data.killCounter, data.thirdDifficulty, data.secondUnlock,
        data.lastProgressKillCount)

    UI.ListBase.CreatureInfo.ProgressValue:setText(data.killCounter)

    local fullText = ""
    if data.killCounter >= data.lastProgressKillCount then
        fullText = "(fully unlocked)"
    end

    UI.ListBase.CreatureInfo.ProgressBorder1:setTooltip(string.format(" %d / %d %s", data.killCounter,
        data.thirdDifficulty, fullText))
    UI.ListBase.CreatureInfo.ProgressBorder2:setTooltip(string.format(" %d / %d %s", data.killCounter,
        data.secondUnlock, fullText))
    UI.ListBase.CreatureInfo.ProgressBorder3:setTooltip(string.format(" %d / %d %s", data.killCounter,
        data.lastProgressKillCount, fullText))
    UI.ListBase.CreatureInfo.LeftBase.TrackCheck.raceId = data.id

    -- TODO investigate when it can be track-- idk when
    --[[     if data.currentLevel == 1 then
        UI.ListBase.CreatureInfo.LeftBase.TrackCheck:enable()
    else
        UI.ListBase.CreatureInfo.LeftBase.TrackCheck:disable()
    end ]]

    if table.find(storedRaceIDs, data.id) then
        UI.ListBase.CreatureInfo.LeftBase.TrackCheck:setChecked(true)
    else
        UI.ListBase.CreatureInfo.LeftBase.TrackCheck:setChecked(false)
    end

    if data.currentLevel > 1 then
        UI.ListBase.CreatureInfo.Value1:setText(data.maxHealth)
        UI.ListBase.CreatureInfo.Value2:setText(data.experience)
        UI.ListBase.CreatureInfo.Value3:setText(data.speed)
        UI.ListBase.CreatureInfo.Value4:setText(data.armor)
        UI.ListBase.CreatureInfo.Value5:setText(data.mitigation .. "%")
        UI.ListBase.CreatureInfo.BonusValue:setText(data.charmValue)
    else
        UI.ListBase.CreatureInfo.Value1:setText("?")
        UI.ListBase.CreatureInfo.Value2:setText("?")
        UI.ListBase.CreatureInfo.Value3:setText("?")
        UI.ListBase.CreatureInfo.Value4:setText("?")
        UI.ListBase.CreatureInfo.Value5:setText("?")
        UI.ListBase.CreatureInfo.BonusValue:setText("?")
    end

    if data.attackMode == 1 then
        local rect = {
            height = 9,
            x = 18,
            y = 0,
            width = 18
        }

        UI.ListBase.CreatureInfo.SubTextLabel:setImageSource("/images/icons/icons-skills")
        UI.ListBase.CreatureInfo.SubTextLabel:setImageClip(rect)
        UI.ListBase.CreatureInfo.SubTextLabel:setSize("18 9")
    else
        local rect = {
            height = 9,
            x = 0,
            y = 0,
            width = 18
        }
        UI.ListBase.CreatureInfo.SubTextLabel:setImageSource("/images/icons/icons-skills")
        UI.ListBase.CreatureInfo.SubTextLabel:setImageClip(rect)
        UI.ListBase.CreatureInfo.SubTextLabel:setSize("18 9")
    end

    local resists = {"PhysicalProgress", "FireProgress", "EarthProgress", "EnergyProgress", "IceProgress",
                     "HolyProgress", "DeathProgress", "HealingProgress"}

    if not table.empty(data.combat) then
        for i = 1, 8 do
            local combat = Cyclopedia.calculateCombatValues(data.combat[i])
            UI.ListBase.CreatureInfo[resists[i]].Fill:setMarginRight(combat.margin)
            UI.ListBase.CreatureInfo[resists[i]].Fill:setBackgroundColor(combat.color)
            UI.ListBase.CreatureInfo[resists[i]]:setTooltip(string.format("Sensitive to %s : %s", string.gsub(
                resists[i], "Progress", ""):lower(), combat.tooltip))
        end
    else
        for i = 1, 8 do
            UI.ListBase.CreatureInfo[resists[i]].Fill:setMarginRight(65)
        end
    end

    local lootData = {}
    for _, value in ipairs(data.loot) do
        local loot = {
            name = value.name,
            id = value.itemId,
            type = value.type,
            difficulty = value.diffculty,
            stackable = value.stackable == 1 and true or false
        }

        if not lootData[value.diffculty] then
            lootData[value.diffculty] = {}
        end

        table.insert(lootData[value.diffculty], loot)
    end

    Cyclopedia.CreateCreatureItems(lootData)
    UI.ListBase.CreatureInfo.LocationField.Textlist.Text:setText(data.location)

    if data.AnimusMasteryPoints and data.AnimusMasteryPoints > 1 then
        UI.ListBase.CreatureInfo.AnimusMastery:setTooltip("The Animus Mastery for this creature is unlocked.\nIt yields "..(data.AnimusMasteryBonus / 10).."% bonus experience points, plus an additional 0.1% for every 10 Animus Masteries unlocked, up to a maximum of 4%.\nYou currently benefit from "..(data.AnimusMasteryBonus / 10).."% bonus experience points due to having unlocked ".. data.AnimusMasteryPoints .." Animus Masteries.")
        UI.ListBase.CreatureInfo.AnimusMastery:setVisible(true)
    else
        UI.ListBase.CreatureInfo.AnimusMastery:removeTooltip()
        UI.ListBase.CreatureInfo.AnimusMastery:setVisible(false)
    end
end

function Cyclopedia.ShowBestiaryCreature()
    Cyclopedia.Bestiary.Stage = STAGES.CREATURE
    Cyclopedia.onStageChange()
end

function Cyclopedia.ShowBestiaryCreatures(Category)
    UI.ListBase.CreatureList:destroyChildren()
    UI.ListBase.CategoryList:setVisible(false)
    UI.ListBase.CreatureInfo:setVisible(false)
    UI.ListBase.CreatureList:setVisible(true)
    g_game.requestBestiaryOverview(Category)
end

function Cyclopedia.CreateBestiaryCategoryItem(Data)
    UI.BackPageButton:setEnabled(false)

    local widget = g_ui.createWidget("BestiaryCategory", UI.ListBase.CategoryList)
    widget:setText(Data.name)
    widget.ClassIcon:setImageSource("/game_cyclopedia/images/bestiary/creatures/" .. Data.name:lower():gsub(" ", "_"))
    widget.Category = Data.name
    widget:setColor("#C0C0C0")
    widget.TotalValue:setText(string.format("Total: %d", Data.amount))
    widget.KnownValue:setText(string.format("Known: %d", Data.know))

    function widget.ClassBase:onClick()
        UI.BackPageButton:setEnabled(true)
        Cyclopedia.ShowBestiaryCreatures(self:getParent().Category)
        Cyclopedia.Bestiary.Stage = STAGES.CREATURES
        Cyclopedia.onStageChange()
    end
end

function Cyclopedia.loadBestiarySearchCreatures(data)
    UI.ListBase.CategoryList:setVisible(false)
    UI.ListBase.CreatureInfo:setVisible(false)
    UI.ListBase.CreatureList:setVisible(true)
    UI.BackPageButton:setEnabled(true)

    Cyclopedia.Bestiary.Stage = STAGES.SEARCH
    Cyclopedia.onStageChange()
    Cyclopedia.Bestiary.Search = {}
    Cyclopedia.Bestiary.Page = 1

    local maxCategoriesPerPage = 15
    Cyclopedia.Bestiary.TotalSearchPages = math.ceil(#data / maxCategoriesPerPage)

    UI.PageValue:setText(string.format("%d / %d", Cyclopedia.Bestiary.Page, Cyclopedia.Bestiary.TotalSearchPages))

    local page = 1
    Cyclopedia.Bestiary.Search[page] = {}

    for i = 0, #data do
        if i % maxCategoriesPerPage == 0 and i > 0 then
            page = page + 1
            Cyclopedia.Bestiary.Search[page] = {}
        end
        local creature = {
            id = data[i].id,
            currentLevel = data[i].currentLevel,
            AnimusMasteryBonus = data[i].AnimusMasteryBonus,

        }

        table.insert(Cyclopedia.Bestiary.Search[page], creature)
    end

    Cyclopedia.Bestiary.Stage = STAGES.SEARCH
    Cyclopedia.loadBestiaryCreature(Cyclopedia.Bestiary.Page, true)
    Cyclopedia.verifyBestiaryButtons()
end

function Cyclopedia.loadBestiaryCreatures(data)
    Cyclopedia.Bestiary.Creatures = {}
    Cyclopedia.Bestiary.Page = 1

    local maxCategoriesPerPage = 15
    Cyclopedia.Bestiary.TotalCreaturesPages = math.ceil(#data / maxCategoriesPerPage)

    UI.PageValue:setText(string.format("%d / %d", Cyclopedia.Bestiary.Page, Cyclopedia.Bestiary.TotalCreaturesPages))

    local page = 1
    Cyclopedia.Bestiary.Creatures[page] = {}

    for i = 1, #data do
        if (i - 1) % maxCategoriesPerPage == 0 and i > 1 then
            page = page + 1
            Cyclopedia.Bestiary.Creatures[page] = {}
        end

        local creature = {
            id = data[i].id,
            currentLevel = data[i].currentLevel,
            AnimusMasteryBonus = data[i].creatureAnimusMasteryBonus,

        }

        table.insert(Cyclopedia.Bestiary.Creatures[page], creature)
    end

    Cyclopedia.loadBestiaryCreature(Cyclopedia.Bestiary.Page, false)
    Cyclopedia.verifyBestiaryButtons()
end

-- note: this one needs refactor
-- expected result:
-- when a string is entered
-- the list should generate client-side
-- the list of search results that match the search string
-- looks identical to category view
function Cyclopedia.BestiarySearch()
    local text = UI.SearchEdit:getText()
    local raceList = g_things.getRacesByName(text)
    if #raceList > 0 then
        g_game.requestBestiarySearch(raceList[1].raceId)
    end

    UI.SearchEdit:setText("")
end

function Cyclopedia.BestiarySearchText(text)
    if text ~= "" then
        UI.SearchButton:enable(true)
    else
        UI.SearchButton:disable(false)
    end
end

function Cyclopedia.CreateBestiaryCreaturesItem(data)
    local raceData = g_things.getRaceData(data.id)

    local function verify(name)
        if #name > 18 then
            return name:sub(1, 15) .. "..."
        else
            return name
        end
    end

    local widget = g_ui.createWidget("BestiaryCreature", UI.ListBase.CreatureList)
    widget:setId(data.id)

    local formattedName = raceData.name:gsub("(%l)(%w*)", function(first, rest)
        return first:upper() .. rest
    end)

    widget.Name:setText(verify(formattedName))
    widget.Sprite:setOutfit(raceData.outfit)
    widget.Sprite:getCreature():setStaticWalking(1000)

    if data.AnimusMasteryBonus > 0 then
        widget.AnimusMastery:setTooltip("The Animus Mastery for this creature is unlocked.\nIt yields ".. data.AnimusMasteryBonus.. "% bonus experience points, plus an additional 0.1% for every 10 Animus Masteries unlocked, up to a maximum of 4%.\nYou currently benefit from ".. data.AnimusMasteryBonus.. "% bonus experience points due to having unlocked ".. animusMasteryPoints.." Animus Masteries.")
        widget.AnimusMastery:setVisible(true)
    else
        widget.AnimusMastery:removeTooltip()
        widget.AnimusMastery:setVisible(false)
    end

    if data.currentLevel >= 3 then
        widget.Finalized:setVisible(true)
        widget.KillsLabel:setVisible(false)
        widget.Sprite:getCreature():setShader("")
    else
        if data.currentLevel < 1 then
            widget.KillsLabel:setText("?")
            widget.Sprite:getCreature():setShader("Outfit - cyclopedia-black")
            widget.Name:setText("Unknown")
            widget.AnimusMastery:setVisible(false)
        else
            widget.KillsLabel:setText(string.format("%d / 3", data.currentLevel - 1))
        end

    end

    function widget.ClassBase:onClick()
        if data.currentLevel < 1 then
            return
        end

        UI.BackPageButton:setEnabled(true)
        g_game.requestBestiarySearch(widget:getId())
        Cyclopedia.ShowBestiaryCreature()
    end
end

function Cyclopedia.loadBestiaryCreature(page, search)
    local state = "Creatures"
    if search then
        state = "Search"
    end

    if not Cyclopedia.Bestiary[state][page] then
        return
    end

    UI.ListBase.CreatureList:destroyChildren()

    for _, data in ipairs(Cyclopedia.Bestiary[state][page]) do
        Cyclopedia.CreateBestiaryCreaturesItem(data)
    end
end

function Cyclopedia.loadBestiaryCategories(data)
    Cyclopedia.Bestiary.Categories = {}
    Cyclopedia.Bestiary.Page = 1

    local maxCategoriesPerPage = 15
    Cyclopedia.Bestiary.TotalCategoriesPages = math.ceil(#data / maxCategoriesPerPage)

    if UI == nil or UI.PageValue == nil then -- I know, don't change it
        return
    end

    UI.PageValue:setText(string.format("%d / %d", Cyclopedia.Bestiary.Page, Cyclopedia.Bestiary.TotalCategoriesPages))

    local page = 1
    Cyclopedia.Bestiary.Categories[page] = {}

    for i = 1, #data do
        if (i - 1) % maxCategoriesPerPage == 0 and i > 1 then
            page = page + 1
            Cyclopedia.Bestiary.Categories[page] = {}
        end

        local category = {
            name = data[i].bestClass,
            amount = data[i].count,
            know = data[i].unlockedCount,
            AnimusMasteryBonus = data[i].AnimusMasteryBonus,
        }

        table.insert(Cyclopedia.Bestiary.Categories[page], category)
    end

    Cyclopedia.loadBestiaryCategory(Cyclopedia.Bestiary.Page)
    Cyclopedia.verifyBestiaryButtons()
end

function Cyclopedia.loadBestiaryCategory(page)
    if not Cyclopedia.Bestiary.Categories[page] then
        return
    end

    UI.ListBase.CategoryList:destroyChildren()

    for _, data in ipairs(Cyclopedia.Bestiary.Categories[page]) do
        Cyclopedia.CreateBestiaryCategoryItem(data)
    end
end

function Cyclopedia.onStageChange()
    Cyclopedia.Bestiary.Page = 1

    if Cyclopedia.Bestiary.Stage == STAGES.CATEGORY then
        UI.BackPageButton:setEnabled(false)
        UI.ListBase.CategoryList:setVisible(true)
        UI.ListBase.CreatureList:setVisible(false)
        UI.ListBase.CreatureInfo:setVisible(false)
    end

    if Cyclopedia.Bestiary.Stage == STAGES.CREATURES then
        UI.BackPageButton:setEnabled(true)
        UI.ListBase.CategoryList:setVisible(false)
        UI.ListBase.CreatureList:setVisible(true)
        UI.ListBase.CreatureInfo:setVisible(false)

        function UI.BackPageButton.onClick()
            Cyclopedia.Bestiary.Stage = STAGES.CATEGORY
            Cyclopedia.onStageChange()
        end
    end

    if Cyclopedia.Bestiary.Stage == STAGES.SEARCH then
        UI.BackPageButton:setEnabled(true)
        UI.ListBase.CategoryList:setVisible(false)
        UI.ListBase.CreatureList:setVisible(true)
        UI.ListBase.CreatureInfo:setVisible(false)

        function UI.BackPageButton.onClick()
            Cyclopedia.Bestiary.Stage = STAGES.CATEGORY
            Cyclopedia.onStageChange()
        end
    end

    if Cyclopedia.Bestiary.Stage == STAGES.CREATURE then
        UI.BackPageButton:setEnabled(true)
        UI.ListBase.CategoryList:setVisible(false)
        UI.ListBase.CreatureList:setVisible(false)
        UI.ListBase.CreatureInfo:setVisible(true)

        function UI.BackPageButton.onClick()
            Cyclopedia.Bestiary.Stage = STAGES.CREATURES
            Cyclopedia.onStageChange()
        end
    end

    Cyclopedia.verifyBestiaryButtons()
end

function Cyclopedia.changeBestiaryPage(prev, next)
    if next then
        Cyclopedia.Bestiary.Page = Cyclopedia.Bestiary.Page + 1
    end

    if prev then
        Cyclopedia.Bestiary.Page = Cyclopedia.Bestiary.Page - 1
    end

    local stage = Cyclopedia.Bestiary.Stage
    if stage == STAGES.CATEGORY then
        Cyclopedia.loadBestiaryCategory(Cyclopedia.Bestiary.Page)
    elseif stage == STAGES.CREATURES then
        Cyclopedia.loadBestiaryCreature(Cyclopedia.Bestiary.Page, false)
    elseif stage == STAGES.SEARCH then
        Cyclopedia.loadBestiaryCreature(Cyclopedia.Bestiary.Page, true)
    end

    Cyclopedia.verifyBestiaryButtons()
end

function Cyclopedia.verifyBestiaryButtons()
    local function updateButtonState(button, condition)
        if condition then
            button:enable()
        else
            button:disable()
        end
    end

    local function updatePageValue(currentPage, totalPages)
        UI.PageValue:setText(string.format("%d / %d", currentPage, totalPages))
    end

    updateButtonState(UI.SearchButton, UI.SearchEdit:getText() ~= "")

    local stage = Cyclopedia.Bestiary.Stage
    local totalSearchPages = Cyclopedia.Bestiary.TotalSearchPages
    local page = Cyclopedia.Bestiary.Page
    if stage == STAGES.SEARCH and totalSearchPages then
        local totalPages = totalSearchPages
        updateButtonState(UI.PrevPageButton, page > 1)
        updateButtonState(UI.NextPageButton, page < totalPages)
        updatePageValue(page, totalPages)
        return
    end

    if stage == STAGES.CREATURE then
        UI.PrevPageButton:disable()
        UI.NextPageButton:disable()
        updatePageValue(1, 1)
        return
    end

    local totalCategoriesPages = Cyclopedia.Bestiary.TotalCategoriesPages
    local totalCreaturesPages = Cyclopedia.Bestiary.TotalCreaturesPages
    if stage == STAGES.CATEGORY and totalCategoriesPages or stage == STAGES.CREATURES and totalCreaturesPages then
        local totalPages = stage == STAGES.CATEGORY and totalCategoriesPages or totalCreaturesPages
        updateButtonState(UI.PrevPageButton, page > 1)
        updateButtonState(UI.NextPageButton, page < totalPages)
        updatePageValue(page, totalPages)
    end
end

--[[
===================================================
=                     Tracker                     =
===================================================
]]

function Cyclopedia.toggleBestiaryTracker()
    if not trackerMiniWindow then
        return
    end

    if trackerButton:isOn() then
        trackerMiniWindow:close()
        trackerButton:setOn(false)
    else
        if not trackerMiniWindow:getParent() then
            local panel = modules.game_interface.findContentPanelAvailable(trackerMiniWindow,
            trackerMiniWindow:getMinimumHeight())
            if not panel then
                return
            end
            panel:addChild(trackerMiniWindow)
        end
        trackerMiniWindow:open()
        trackerButton:setOn(true)
    end
end

function Cyclopedia.toggleBosstiaryTracker()
    if not trackerMiniWindowBosstiary then
        return
    end

    if trackerButtonBosstiary:isOn() then
        trackerMiniWindowBosstiary:close()
        trackerButtonBosstiary:setOn(false)
    else
        if not trackerMiniWindowBosstiary:getParent() then
            local panel = modules.game_interface.findContentPanelAvailable(trackerMiniWindowBosstiary,
            trackerMiniWindowBosstiary:getMinimumHeight())
            if not panel then
                return
            end
            panel:addChild(trackerMiniWindowBosstiary)
        end
        trackerMiniWindowBosstiary:open()
        trackerButtonBosstiary:setOn(true)
    end
end

function Cyclopedia.onTrackerClose(temp)
    if temp == "Bosstiary Tracker" then
        trackerButtonBosstiary:setOn(false)
    else
        trackerButton:setOn(false)
    end
end

function Cyclopedia.setBarPercent(widget, percent)
    if percent > 92 then
        widget.killsBar:setBackgroundColor("#00BC00")
    elseif percent > 60 then
        widget.killsBar:setBackgroundColor("#50A150")
    elseif percent > 30 then
        widget.killsBar:setBackgroundColor("#A1A100")
    elseif percent > 8 then
        widget.killsBar:setBackgroundColor("#BF0A0A")
    elseif percent > 3 then
        widget.killsBar:setBackgroundColor("#910F0F")
    else
        widget.killsBar:setBackgroundColor("#850C0C")
    end

    widget.killsBar:setPercent(percent)
end

function Cyclopedia.onParseCyclopediaTracker(trackerType, data)
    if not data then
        return
    end

    local isBoss = trackerType == 1
    local window = isBoss and trackerMiniWindowBosstiary or trackerMiniWindow

    window.contentsPanel:destroyChildren()
    storedRaceIDs = {}

    for _, entry in ipairs(data) do
        local raceId, kills, uno, dos, maxKills = unpack(entry)
        table.insert(storedRaceIDs, raceId)
        local raceData = g_things.getRaceData(raceId)
        local name = raceData.name

        local widget = g_ui.createWidget("TrackerButton", window.contentsPanel)
        widget:setId(raceId)
        widget.creature:setOutfit(raceData.outfit)
        widget.label:setText(name:len() > 12 and name:sub(1, 9) .. "..." or name)
        widget.kills:setText(kills .. "/" .. maxKills)
        widget.onMouseRelease = onTrackerClick

        Cyclopedia.SetBestiaryProgress(54,widget.killsBar2, widget.ProgressBack33, widget.ProgressBack55, kills, uno, dos, maxKills)
    end
end

local BESTIATYTRACKER_FILTERS = {
    ["sortByName"] = true,
    ["ShortByPercentage"] = false,
    ["sortByKills"] = false,
    ["sortByAscending"] = false,
    ["sortByDescending"] = false
}

function loadFilters()
    local settings = g_settings.getNode("bestiaryTracker")
    if not settings or not settings['filters'] then
        return BESTIATYTRACKER_FILTERS
    end
    return settings['filters']
end

function saveFilters()
    g_settings.mergeNode('bestiaryTracker', {
        ['filters'] = loadFilters()
    })
end

function getFilter(filter)
    return loadFilters()[filter] or false
end

function setFilter(filter)
    local filters = loadFilters()
    local value = filters[filter]
    if value == nil then
        return false
    end

    filters[filter] = not value
    g_settings.mergeNode('bestiaryTracker', {
        ['filters'] = filters
    })
end

-- trackerMiniWindow.contentsPanel:moveChildToIndex(battleButton, index)
-- TODO Add sort by name, kills, percentage, ascending, descending
function test(index)
    trackerMiniWindow.contentsPanel:moveChildToIndex(trackerMiniWindow.contentsPanel:getLastChild(), index)
end

function onTrackerClick(widget, mousePosition, mouseButton)
    local taskId = tonumber(widget:getId())
    local menu = g_ui.createWidget("PopupMenu")

    menu:setGameMenu(true)
    menu:addOption("stop Tracking " .. widget.label:getText(), function()
        g_game.sendStatusTrackerBestiary(taskId, false)
    end)
    menu:display(menuPosition)

    return true
end

function onAddLootClick(widget, mousePosition, mouseButton)
    local itemId = widget:getItemId()
    local quickLoot = modules.game_quickloot.QuickLoot
    local lootFilterValue = quickLoot.data.filter
    local menu = g_ui.createWidget("PopupMenu")

    menu:setGameMenu(true)

    if not quickLoot.lootExists(itemId, lootFilterValue) then
        menu:addOption("Add to Loot List",
        function()
            quickLoot.addLootList(itemId, lootFilterValue)
        end)
    else
        menu:addOption("Remove from Loot List", 
        function() 
            quickLoot.removeLootList(itemId, lootFilterValue)
        end)
    end

    menu:display(menuPosition)

    return true
end

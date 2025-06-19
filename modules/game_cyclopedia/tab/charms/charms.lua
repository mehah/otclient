local UI = nil

function showCharms()
    UI = g_ui.loadUI("charms", contentContainer)
    UI:show()
    g_game.requestBestiary()
    controllerCyclopedia.ui.CharmsBase:setVisible(true)
    controllerCyclopedia.ui.GoldBase:setVisible(true)
    controllerCyclopedia.ui.BestiaryTrackerButton:setVisible(false)
end

Cyclopedia.Charms = {}

local CHARMS = {
    { ID = 0, IMAGE = "/game_cyclopedia/images/charms/0", TYPE = 4, NAME = "Wound", DESCRIPTION = "Triggers on a creature with a certain chance and deals 5% of its initial hit points as physical damage once.", POINTS = {240, 360, 1200} },
    { ID = 1, IMAGE = "/game_cyclopedia/images/charms/1", TYPE = 4, NAME = "Enflame", DESCRIPTION = "Triggers on a creature with a certain chance and deals 5% of its initial hit points as fire damage once.", POINTS = {400, 600, 2000} },
    { ID = 2, IMAGE = "/game_cyclopedia/images/charms/2", TYPE = 4, NAME = "Poison", DESCRIPTION = "Triggers on a creature with a certain chance and deals 5% of its initial hit points as earth damage once.", POINTS = {240, 360, 1200} },
    { ID = 3, IMAGE = "/game_cyclopedia/images/charms/3", TYPE = 4, NAME = "Freeze", DESCRIPTION = "Triggers on a creature with a certain chance and deals 5% of its initial hit points as ice damage once.", POINTS = {320, 480, 1600} },
    { ID = 4, IMAGE = "/game_cyclopedia/images/charms/4", TYPE = 4, NAME = "Zap", DESCRIPTION = "Triggers on a creature with a certain chance and deals 5% of its initial hit points as energy damage once.", POINTS = {320, 480, 1600} },
    { ID = 5, IMAGE = "/game_cyclopedia/images/charms/5", TYPE = 4, NAME = "Curse", DESCRIPTION = "Triggers on a creature with a certain chance and deals 5% of its initial hit points as death damage once.", POINTS = {360, 540, 1800} },
    { ID = 6, IMAGE = "/game_cyclopedia/images/charms/6", TYPE = 2, NAME = "Cripple", DESCRIPTION = "Cripples the creature with a certain chance and paralyzes it for 10 seconds.", POINTS = {100, 150, 225} },
    { ID = 7, IMAGE = "/game_cyclopedia/images/charms/7", TYPE = 3, NAME = "Parry", DESCRIPTION = "Any damage taken is reflected to the aggressor with a certain chance.", POINTS = {400, 600, 2000} },
    { ID = 8, IMAGE = "/game_cyclopedia/images/charms/8", TYPE = 2, NAME = "Dodge", DESCRIPTION = "Dodges an attack with a certain chance without taking any damage at all.", POINTS = {240, 360, 1200} },
    { ID = 9, IMAGE = "/game_cyclopedia/images/charms/9", TYPE = 1, NAME = "Adrenaline Burst", DESCRIPTION = "Bursts of adrenaline enhance your reflexes with a certain chance after you get hit and let you move faster for 10 seconds.", POINTS = {100, 150, 225} },
    { ID = 10, IMAGE = "/game_cyclopedia/images/charms/10", TYPE = 3, NAME = "Numb", DESCRIPTION = "Numbs the creature with a certain chance after its attack and paralyzes the creature for 10 seconds.", POINTS = {100, 150, 225} },
    { ID = 11, IMAGE = "/game_cyclopedia/images/charms/11", TYPE = 2, NAME = "Cleanse", DESCRIPTION = "Cleanses you from within with a certain chance after you get hit and removes one random active negative status effect and temporarily makes you immune against it.", POINTS = {100, 150, 225} },
    { ID = 12, IMAGE = "/game_cyclopedia/images/charms/12", TYPE = 6, NAME = "Bless", DESCRIPTION = "Blesses you and reduces skill and xp loss by 10% when killed by the chosen creature.", POINTS = {100, 150, 225} },
    { ID = 13, IMAGE = "/game_cyclopedia/images/charms/13", TYPE = 6, NAME = "Scavenge", DESCRIPTION = "Enhances your chances to successfully skin/dust a skinnable/dustable creature.", POINTS = {100, 150, 225} },
    { ID = 14, IMAGE = "/game_cyclopedia/images/charms/14", TYPE = 6, NAME = "Gut", DESCRIPTION = "Gutting the creature yields 20% more creature products.", POINTS = {100, 150, 225} },
    { ID = 15, IMAGE = "/game_cyclopedia/images/charms/15", TYPE = 6, NAME = "Low Blow", DESCRIPTION = "Adds 8% critical hit chance to attacks with critical hit weapons.", POINTS = {800, 1200, 4000} },
    { ID = 16, IMAGE = "/game_cyclopedia/images/charms/16", TYPE = 5, NAME = "Divine Wrath", DESCRIPTION = "Triggers on a creature with a certain chance and deals 5% of its initial hit points as holy damage once.", POINTS = {600, 900, 3000} },
    { ID = 17, IMAGE = "/game_cyclopedia/images/charms/17", TYPE = 6, NAME = "Vampiric Embrace", DESCRIPTION = "Adds 4% Life Leech to attacks if wearing equipment that provides life leech.", POINTS = {100, 150, 225} },
    { ID = 18, IMAGE = "/game_cyclopedia/images/charms/18", TYPE = 6, NAME = "Void's Call", DESCRIPTION = "Adds 2% Mana Leech to attacks if wearing equipment that provides mana leech.", POINTS = {100, 150, 225} },

    -- New charms (14.12+)
    { ID = 19, IMAGE = "/game_cyclopedia/images/charms/19", TYPE = 6, NAME = "Savage Blow", DESCRIPTION = "Adds critical extra damage to attacks with critical hit weapons.", POINTS = {800, 1200, 4000}, MIN_VERSION = 1412 },
    { ID = 20, IMAGE = "/game_cyclopedia/images/charms/20", TYPE = 6, NAME = "Fatal Hold", DESCRIPTION = "Prevents creatures from fleeing due to low health for 30 seconds.", POINTS = {100, 150, 225}, MIN_VERSION = 1412 },
    { ID = 21, IMAGE = "/game_cyclopedia/images/charms/21", TYPE = 6, NAME = "Void Inversion", DESCRIPTION = "Chance to gain mana instead of losing it when taking Mana Drain damage.", POINTS = {100, 150, 225}, MIN_VERSION = 1412 },
    { ID = 22, IMAGE = "/game_cyclopedia/images/charms/22", TYPE = 6, NAME = "Carnage", DESCRIPTION = "Killing a monster deals physical damage to others in a small radius.", POINTS = {600, 900, 3000}, MIN_VERSION = 1412 },
    { ID = 23, IMAGE = "/game_cyclopedia/images/charms/23", TYPE = 6, NAME = "Overpower", DESCRIPTION = "Deals physical damage based on your maximum health.", POINTS = {600, 900, 3000}, MIN_VERSION = 1412 },
    { ID = 24, IMAGE = "/game_cyclopedia/images/charms/24", TYPE = 6, NAME = "Overflux", DESCRIPTION = "Deals physical damage based on your maximum mana.", POINTS = {600, 900, 3000}, MIN_VERSION = 1412 },
    { ID = 25, IMAGE = "/game_cyclopedia/images/charms/25", TYPE = 6, NAME = "Charm of the Void", DESCRIPTION = "Special charm with unique behavior.", POINTS = {0, 0, 0}, MIN_VERSION = 1412 },
}

function Cyclopedia.UpdateCharmsBalance(Value)
    for i, child in pairs(UI.Bottombase:getChildren()) do
        if child.CharmsBase then
            child.CharmsBase.Value:setText(Value)
        end
    end
end

function Cyclopedia.CreateCharmItem(data)
    local widget = g_ui.createWidget("CharmItem", UI.CharmList)
    local value = widget.PriceBase.Value

    widget:setId(data.id)

    if data.id ~= nil then
        widget.charmBase.image:setImageSource("/game_cyclopedia/images/charms/" .. data.id)
    else
        g_logger.error(string.format("Cyclopedia.CreateCharmItem - charm %s is nil", data.id))
        return
    end

    widget:setText(data.name)
    widget.data = data

    if data.asignedStatus then
        if data.raceId then
            widget.InfoBase.Sprite:setOutfit(g_things.getRaceData(data.raceId).outfit)
            widget.InfoBase.Sprite:getCreature():setStaticWalking(1000)
        else
            g_logger.error("Cyclopedia.CreateCharmItem - no race id provided")
        end
    end

    if data.unlocked then
        widget.PriceBase.Charm:setVisible(false)
        widget.PriceBase.Gold:setVisible(true)
        widget.charmBase.lockedMask:setVisible(false)
        widget.icon = 1
        if data.asignedStatus then
            widget.PriceBase.Value:setText(comma_value(data.removeRuneCost))
        else
            widget.PriceBase.Value:setText(0)
        end
    else
        widget.PriceBase.Charm:setVisible(true)
        widget.PriceBase.Gold:setVisible(false)
        widget.charmBase.lockedMask:setVisible(true)
        widget.PriceBase.Value:setText(comma_value(data.unlockPrice))
        widget.icon = 0
    end

    if widget.icon == 1 and g_game.getLocalPlayer():getResourceBalance(1) then
        if data.removeRuneCost > g_game.getLocalPlayer():getResourceBalance(1) then
            value:setColor("#D33C3C")
        else
            value:setColor("#C0C0C0")
        end
    end

    if widget.icon == 0 then
        if data.unlockPrice > UI.CharmsPoints then
            value:setColor("#D33C3C")
        else
            value:setColor("#C0C0C0")
        end
    end
end

function Cyclopedia.loadCharms(charmsData)
    if not charmsData.charms then
        g_logger.warning("Cyclopedia.loadCharms - charmsData.charms is nil, skipping loading")
        return
    end

    controllerCyclopedia.ui.CharmsBase.Value:setText(Cyclopedia.formatGold(charmsData.points))

    if UI == nil or UI.CharmList == nil then -- I know, don't change it
        return
    end

    UI.CharmsPoints = charmsData.points

    local raceIdNamePairs = {}

    local version = g_game.getClientVersion()

    local monsterIds = {}

    if version >= 1412 then
        for id, data in pairs(Cyclopedia.BestiaryCache) do
            if data.currentLevel and data.currentLevel >= 1 then
                table.insert(monsterIds, id)
            end
        end
    else
        monsterIds = charmsData.finishedMonsters or {}
    end

    for _, raceId in ipairs(monsterIds) do
        local raceName = g_things.getRaceData(raceId).name
        if #raceName == 0 then
            raceName = string.format("unnamed_%d", raceId)
        end

        table.insert(raceIdNamePairs, {
            raceId = raceId,
            name = raceName
        })
    end

    local function compareByName(a, b)
        return a.name:lower() < b.name:lower()
    end

    table.sort(raceIdNamePairs, compareByName)

    Cyclopedia.Charms.Monsters = {}

    for _, pair in ipairs(raceIdNamePairs) do
        table.insert(Cyclopedia.Charms.Monsters, pair.raceId)
    end

    UI.CharmList:destroyChildren()

    local formatedData = {}

    local maxCharmId = 0
    for _, charm in ipairs(CHARMS) do
        if (not charm.MIN_VERSION) or (version >= charm.MIN_VERSION) then
            if charm.ID > maxCharmId then
                maxCharmId = charm.ID
            end
        end
    end

    for _, charmData in pairs(charmsData.charms) do
        local internalId = charmData.id
        if internalId and internalId <= maxCharmId then
            local charmTemplate = CHARMS[internalId + 1]
            if charmTemplate and (not charmTemplate.MIN_VERSION) or (version >= charmTemplate.MIN_VERSION) then
                charmData.internalId = internalId
                charmData.typePriority = charmTemplate.TYPE
                charmData.name = charmTemplate.NAME
                charmData.description = charmTemplate.DESCRIPTION
                charmData.unlockPrice = charmTemplate.POINTS[#charmTemplate.POINTS]
                table.insert(formatedData, charmData)
            else
                g_logger.error(string.format("Cyclopedia.loadCharms - unknown charm id %d", internalId))
            end
        else
            g_logger.warning(string.format("Cyclopedia.loadCharms - skipping charm id %d for client version %d", internalId, version))
        end
    end

    table.sort(formatedData, function(a, b)
        if a.unlocked == b.unlocked then
            if a.typePriority == b.typePriority then
                return a.name < b.name
            else
                return a.typePriority < b.typePriority
            end
        else
            return a.unlocked and not b.unlocked
        end
    end)

    for _, value in ipairs(formatedData) do
        Cyclopedia.CreateCharmItem(value)
    end

    if Cyclopedia.Charms.redirect then
        Cyclopedia.selectCharm(UI.CharmList:getChildById(Cyclopedia.Charms.redirect),
            UI.CharmList:getChildById(Cyclopedia.Charms.redirect):isChecked())
        Cyclopedia.Charms.redirect = nil
    else
        Cyclopedia.selectCharm(UI.CharmList:getChildByIndex(1), UI.CharmList:getChildByIndex(1):isChecked())
    end
end

function Cyclopedia.selectCharm(widget, isChecked)
    UI.InformationBase.CreaturesBase.CreatureList:destroyChildren()

    local parent = widget:getParent()
    local button = UI.InformationBase.UnlockButton
    local value = UI.InformationBase.PriceBase.Value

    UI.InformationBase.data = widget.data

    local function format(text)
        local capitalizedText = text:gsub("(%l)(%w*)", function(first, rest)
            return first:upper() .. rest
        end)

        if #capitalizedText > 19 then
            return capitalizedText:sub(1, 16) .. "..."
        else
            return capitalizedText
        end
    end

    for i = 1, parent:getChildCount() do
        local internalWidget = parent:getChildByIndex(i)

        if internalWidget:isChecked() and widget:getId() ~= internalWidget:getId() then
            internalWidget:setChecked(false)
        end
    end

    if not isChecked then
        widget:setChecked(true)
    end

    UI.InformationBase.TextBase:setText(widget.data.description)
    UI.InformationBase.ItemBase.image:setImageSource(widget.charmBase.image:getImageSource())

    if widget.data.asignedStatus then
        UI.InformationBase.InfoBase.sprite:setVisible(true)
        UI.InformationBase.InfoBase.sprite:setOutfit(g_things.getRaceData(widget.data.raceId).outfit)
        UI.InformationBase.InfoBase.sprite:getCreature():setStaticWalking(1000)
        UI.InformationBase.InfoBase.sprite:setOpacity(1)
    else
        UI.InformationBase.InfoBase.sprite:setVisible(false)
    end

    if widget.icon == 1 then
        UI.InformationBase.PriceBase.Gold:setVisible(true)
        UI.InformationBase.PriceBase.Charm:setVisible(false)
    else
        UI.InformationBase.PriceBase.Gold:setVisible(false)
        UI.InformationBase.PriceBase.Charm:setVisible(true)
    end

    if widget.icon == 1 and g_game.getLocalPlayer():getResourceBalance(1) then
        if widget.data.removeRuneCost > g_game.getLocalPlayer():getResourceBalance(1) then
            value:setColor("#D33C3C")
            button:setEnabled(false)
        else
            value:setColor("#C0C0C0")
            button:setEnabled(true)
        end

        if widget.data.unlocked and not widget.data.asignedStatus then
            value:setText(0)
        else
            value:setText(comma_value(widget.data.removeRuneCost))
        end
    end

    if widget.icon == 0 then
        if widget.data.unlockPrice > UI.CharmsPoints then
            value:setColor("#D33C3C")
            button:setEnabled(false)
        else
            value:setColor("#C0C0C0")
            button:setEnabled(true)
        end

        value:setText(widget.data.unlockPrice)
    end

    if widget.data.unlocked and not widget.data.asignedStatus then
        button:setText("Select")

        local color = "#484848"

        for index, raceId in ipairs(Cyclopedia.Charms.Monsters) do
            local internalWidget = g_ui.createWidget("CharmCreatureName", UI.InformationBase.CreaturesBase.CreatureList)
            internalWidget:setId(index)
            internalWidget:setText(format(g_things.getRaceData(raceId).name))
            internalWidget.raceId = raceId
            internalWidget:setBackgroundColor(color)
            internalWidget.color = color
            color = color == "#484848" and "#414141" or "#484848"
        end

        button:setEnabled(false)
        UI.InformationBase.SearchEdit:setEnabled(true)
        UI.InformationBase.SearchLabel:setEnabled(true)
        UI.InformationBase.CreaturesLabel:setEnabled(true)
    end

    if widget.data.asignedStatus then
        button:setText("Remove")

        local internalWidget = g_ui.createWidget("CharmCreatureName", UI.InformationBase.CreaturesBase.CreatureList)
        internalWidget:setText(format(g_things.getRaceData(widget.data.raceId).name))
        internalWidget:setEnabled(false)
        internalWidget:setColor("#707070")
        UI.InformationBase.SearchEdit:setEnabled(false)
        UI.InformationBase.SearchLabel:setEnabled(false)
        UI.InformationBase.CreaturesLabel:setEnabled(false)
    end

    if not widget.data.unlocked then
        button:setText("Unlock")
        UI.InformationBase.SearchEdit:setEnabled(false)
        UI.InformationBase.SearchLabel:setEnabled(false)
        UI.InformationBase.CreaturesLabel:setEnabled(false)
    end
end

function Cyclopedia.selectCreatureCharm(widget, isChecked)
    local parent = widget:getParent()

    for i = 1, parent:getChildCount() do
        local internalWidget = parent:getChildByIndex(i)

        if internalWidget:isChecked() and widget:getId() ~= internalWidget:getId() then
            internalWidget:setChecked(false)
            internalWidget:setBackgroundColor(internalWidget.color)
        end
    end

    if not isChecked then
        widget:setChecked(true)
    end

    UI.InformationBase.InfoBase.sprite:setVisible(true)
    UI.InformationBase.InfoBase.sprite:setOutfit(g_things.getRaceData(widget.raceId).outfit)
    UI.InformationBase.InfoBase.sprite:getCreature():setStaticWalking(1000)
    UI.InformationBase.InfoBase.sprite:setOpacity(0.5)
    UI.InformationBase.UnlockButton:setEnabled(true)

    Cyclopedia.Charms.SelectedCreature = widget.raceId
end

function Cyclopedia.searchCharmMonster(text)
    UI.InformationBase.CreaturesBase.CreatureList:destroyChildren()

    local function format(string)
        local capitalizedText = string:gsub("(%l)(%w*)", function(first, rest)
            return first:upper() .. rest
        end)

        if #capitalizedText > 19 then
            return capitalizedText:sub(1, 16) .. "..."
        else
            return capitalizedText
        end
    end

    local function getColor(currentColor)
        return currentColor == "#484848" and "#414141" or "#484848"
    end

    local searchedMonsters = {}

    if text ~= "" then
        for _, raceId in ipairs(Cyclopedia.Charms.Monsters) do
            local name = g_things.getRaceData(raceId).name
            if string.find(name:lower(), text:lower()) then
                table.insert(searchedMonsters, raceId)
            end
        end
    else
        searchedMonsters = Cyclopedia.Charms.Monsters
    end

    local color = "#484848"

    for _, raceId in ipairs(searchedMonsters) do
        local internalWidget = g_ui.createWidget("CharmCreatureName", UI.InformationBase.CreaturesBase.CreatureList)
        internalWidget:setId(raceId)
        internalWidget:setText(format(g_things.getRaceData(raceId).name))
        internalWidget.raceId = raceId
        internalWidget:setBackgroundColor(color)
        internalWidget.color = color
        color = getColor(color)
    end
end

function Cyclopedia.actionCharmButton(widget)
    local confirmWindow
    local type = widget:getText()
    local data = widget:getParent().data

    if type == "Unlock" then
        local function yesCallback()
            g_game.BuyCharmRune(data.id)
            if confirmWindow then
                confirmWindow:destroy()
                confirmWindow = nil
                -- Cyclopedia.Toggle(true, false, 3)
            end

            Cyclopedia.Charms.redirect = data.id
        end

        local function noCallback()
            if confirmWindow then
                confirmWindow:destroy()
                confirmWindow = nil
            end
        end

        if not confirmWindow then
            confirmWindow = displayGeneralBox(tr("Confirm Unlocking of Charm"), tr(
                "Do you want to unlock the Charm %s? This will cost you %d Charm Points?", data.name, data.unlockPrice),
                {
                    {
                        text = tr("Yes"),
                        callback = yesCallback
                    },
                    {
                        text = tr("No"),
                        callback = noCallback
                    },
                    anchor = AnchorHorizontalCenter
                }, yesCallback, noCallback
            )
        end
    end

    if type == "Select" then
        local function yesCallback()
            g_game.BuyCharmRune(data.id, 1, Cyclopedia.Charms.SelectedCreature)
            if confirmWindow then
                confirmWindow:destroy()
                confirmWindow = nil
            end
            Cyclopedia.Charms.redirect = data.id
        end

        local function noCallback()
            if confirmWindow then
                confirmWindow:destroy()
                confirmWindow = nil
            end
        end

        if not confirmWindow then
            confirmWindow = displayGeneralBox(tr("Confirm Selected Charm"),
                tr("Do you want to use the Charm %s for this creature?", data.name), {
                    {
                        text = tr("Yes"),
                        callback = yesCallback
                    },
                    {
                        text = tr("No"),
                        callback = noCallback
                    },
                    anchor = AnchorHorizontalCenter
                }, yesCallback, noCallback
            )
        end
    end

    if type == "Remove" then
        local function yesCallback()
            g_game.BuyCharmRune(data.id, 2)
            if confirmWindow then
                confirmWindow:destroy()
                confirmWindow = nil
            end

            Cyclopedia.Charms.redirect = data.id
        end

        local function noCallback()
            if confirmWindow then
                confirmWindow:destroy()
                confirmWindow = nil
            end
        end

        if not confirmWindow then
            confirmWindow = displayGeneralBox(tr("Confirm Charm Removal"),
                tr("Do you want to remove the Charm %s from this creature? This will cost you %s gold pieces.",
                    data.name, comma_value(data.removeRuneCost)), {
                    {
                        text = tr("Yes"),
                        callback = yesCallback
                    },
                    {
                        text = tr("No"),
                        callback = noCallback
                    },
                    anchor = AnchorHorizontalCenter
                }, yesCallback, noCallback
            )
        end
    end
end

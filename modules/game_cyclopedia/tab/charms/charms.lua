local UI = nil
local TypeCharmRadioGroup = nil
Cyclopedia.Charms = {}
local  charmCategory_t =  {
	CHARM_ALL = 0,
	CHARM_MAJOR = 1,
	CHARM_MINOR = 2,
};

local charm_t = {
	CHARM_UNDEFINED = 0,
	CHARM_OFFENSIVE = 1,
	CHARM_DEFENSIVE = 2,
	CHARM_PASSIVE = 3,
};
local charmRune_t = {
	CHARM_WOUND = 0,
	CHARM_ENFLAME = 1,
	CHARM_POISON = 2,
	CHARM_FREEZE = 3,
	CHARM_ZAP = 4,
	CHARM_CURSE = 5,
	CHARM_CRIPPLE = 6,
	CHARM_PARRY = 7,
	CHARM_DODGE = 8,
	CHARM_ADRENALINE = 9,
	CHARM_NUMB = 10,
	CHARM_CLEANSE = 11,
	CHARM_BLESS = 12,
	CHARM_SCAVENGE = 13,
	CHARM_GUT = 14,
	CHARM_LOW = 15,
	CHARM_DIVINE = 16,
	CHARM_VAMP = 17,
	CHARM_VOID = 18,
	CHARM_SAVAGE = 19,
	CHARM_FATAL = 20,
	CHARM_VOIDINVERSION = 21,
	CHARM_CARNAGE = 22,
	CHARM_OVERPOWER = 23,
	CHARM_OVERFLUX = 24,
}
-- Apparently, in versions higher than 14.10, relevant information such as name and description isn't sent by the server. 
-- Should Protobuf be modified?
local charms = {
    [charmRune_t.CHARM_WOUND] = { name = "Wound", description = "Triggers on a creature with a chance to deal 5% of its initial HP as physical damage.", category = charmCategory_t.CHARM_MAJOR, type = charm_t.CHARM_OFFENSIVE, clip = "32 0 32 32" },
    [charmRune_t.CHARM_ENFLAME] = { name = "Enflame", description = "Triggers on a creature with a chance to deal 5% of its initial HP as fire damage.", category = charmCategory_t.CHARM_MAJOR, type = charm_t.CHARM_OFFENSIVE, clip = "32 0 32 32" },
    [charmRune_t.CHARM_POISON] = { name = "Poison", description = "Triggers on a creature with a chance to deal 5% of its initial HP as earth damage.", category = charmCategory_t.CHARM_MAJOR, type = charm_t.CHARM_OFFENSIVE, clip = "32 0 32 32" },
    [charmRune_t.CHARM_FREEZE] = { name = "Freeze", description = "Triggers on a creature with a chance to deal 5% of its initial HP as ice damage.", category = charmCategory_t.CHARM_MAJOR, type = charm_t.CHARM_OFFENSIVE, clip = "32 0 32 32" },
    [charmRune_t.CHARM_ZAP] = { name = "Zap", description = "Triggers on a creature with a chance to deal 5% of its initial HP as energy damage.", category = charmCategory_t.CHARM_MAJOR, type = charm_t.CHARM_OFFENSIVE, clip = "32 0 32 32" },
    [charmRune_t.CHARM_CURSE] = { name = "Curse", description = "Triggers on a creature with a chance to deal 5% of its initial HP as death damage.", category = charmCategory_t.CHARM_MAJOR, type = charm_t.CHARM_OFFENSIVE, clip = "32 0 32 32" },
    [charmRune_t.CHARM_CRIPPLE] = { name = "Cripple", description = "Cripples the creature and paralyzes it for 10 seconds.", category = charmCategory_t.CHARM_MINOR, type = charm_t.CHARM_OFFENSIVE, clip = "32 0 32 32" },
    [charmRune_t.CHARM_PARRY] = { name = "Parry", description = "Reflects incoming damage back to the aggressor.", category = charmCategory_t.CHARM_MAJOR, type = charm_t.CHARM_DEFENSIVE, clip = "32 0 32 32" },
    [charmRune_t.CHARM_DODGE] = { name = "Dodge", description = "Dodges an attack with a chance, avoiding all damage.", category = charmCategory_t.CHARM_MAJOR, type = charm_t.CHARM_DEFENSIVE, clip = "32 0 32 32" },
    [charmRune_t.CHARM_ADRENALINE] = { name = "Adrenaline Burst", description = "Boosts movement speed for 10 seconds after being hit.", category = charmCategory_t.CHARM_MINOR, type = charm_t.CHARM_DEFENSIVE, clip = "32 0 32 32" },
    [charmRune_t.CHARM_NUMB] = { name = "Numb", description = "Numbs the creature and paralyzes it for 10 seconds.", category = charmCategory_t.CHARM_MINOR, type = charm_t.CHARM_DEFENSIVE, clip = "32 0 32 32" },
    [charmRune_t.CHARM_CLEANSE] = { name = "Cleanse", description = "Removes a negative status effect and grants temporary immunity.", category = charmCategory_t.CHARM_MINOR, type = charm_t.CHARM_DEFENSIVE, clip = "32 0 32 32" },
    [charmRune_t.CHARM_BLESS] = { name = "Bless", description = "Reduces skill and XP loss by 10% when killed by the chosen creature.", category = charmCategory_t.CHARM_MINOR, type = charm_t.CHARM_PASSIVE, clip = "32 0 32 32" },
    [charmRune_t.CHARM_SCAVENGE] = { name = "Scavenge", description = "Enhances chances to successfully skin or dust a creature.", category = charmCategory_t.CHARM_MINOR, type = charm_t.CHARM_PASSIVE, clip = "32 0 32 32" },
    [charmRune_t.CHARM_GUT] = { name = "Gut", description = "Increases creature product yields by 20%.", category = charmCategory_t.CHARM_MINOR, type = charm_t.CHARM_PASSIVE, clip = "32 0 32 32" },
    [charmRune_t.CHARM_LOW] = { name = "Low Blow", description = "Adds 8% critical hit chance to attacks with critical hit weapons.", category = charmCategory_t.CHARM_MAJOR, type = charm_t.CHARM_PASSIVE, clip = "32 0 32 32" },
    [charmRune_t.CHARM_DIVINE] = { name = "Divine Wrath", description = "Triggers on a creature and deals 5% of its initial HP as holy damage.", category = charmCategory_t.CHARM_MAJOR, type = charm_t.CHARM_OFFENSIVE, clip = "32 0 32 32" },
    [charmRune_t.CHARM_VAMP] = { name = "Vampiric Embrace", description = "Adds 4% life leech to attacks if using life-leeching equipment.", category = charmCategory_t.CHARM_MINOR, type = charm_t.CHARM_PASSIVE, clip = "32 0 32 32" },
    [18] = { name = "Void's Call", description = "Adds 2% mana leech to attacks if using mana-leeching equipment.", category = charmCategory_t.CHARM_MINOR, type = charm_t.CHARM_PASSIVE, clip = "32 0 32 32" },
    [charmRune_t.CHARM_SAVAGE] = { name = "Savage Blow", description = "Adds extra critical damage to attacks with critical hit weapons.", category = charmCategory_t.CHARM_MAJOR, type = charm_t.CHARM_PASSIVE, clip = "32 0 32 32" },
    [charmRune_t.CHARM_FATAL] = { name = "Fatal Hold", description = "Prevents creatures from fleeing due to low health for 30 seconds.", category = charmCategory_t.CHARM_MINOR, type = charm_t.CHARM_PASSIVE, clip = "32 0 32 32" },
    [charmRune_t.CHARM_VOIDINVERSION] = { name = "Void Inversion", description = "Chance to gain mana instead of losing it when taking Mana Drain damage.", category = charmCategory_t.CHARM_MINOR, type = charm_t.CHARM_PASSIVE, clip = "32 0 32 32" },
    [charmRune_t.CHARM_CARNAGE] = { name = "Carnage", description = "Killing a monster deals physical damage to others nearby.", category = charmCategory_t.CHARM_MAJOR, type = charm_t.CHARM_OFFENSIVE, clip = "32 0 32 32" },
    [charmRune_t.CHARM_OVERPOWER] = { name = "Overpower", description = "Deals physical damage based on your maximum health.", category = charmCategory_t.CHARM_MAJOR, type = charm_t.CHARM_OFFENSIVE, clip = "32 0 32 32" },
    [charmRune_t.CHARM_OVERFLUX] = { name = "Overflux", description = "Deals physical damage based on your maximum mana.", category = charmCategory_t.CHARM_MAJOR, type = charm_t.CHARM_OFFENSIVE, clip = "32 0 32 32" },
}
local lastCategory = charmCategory_t.CHARM_MAJOR


function showCharms()
    local UIUX = g_game.getClientVersion() >= 1410 and "charms1410" or "charms"
    UI = g_ui.loadUI(UIUX, contentContainer)
    UI:show()
    g_game.requestBestiary()
    controllerCyclopedia.ui.CharmsBase:setVisible(true)
    controllerCyclopedia.ui.GoldBase:setVisible(true)
    controllerCyclopedia.ui.BestiaryTrackerButton:setVisible(false)
    if g_game.getClientVersion() >= 1410 then
        controllerCyclopedia.ui.CharmsBase1410:setVisible(true)
        TypeCharmRadioGroup = UIRadioGroup.create()
        TypeCharmRadioGroup:addWidget(UI.mainPanelCharmsType.typeCharmPanel.MajorCharms)
        TypeCharmRadioGroup:addWidget(UI.mainPanelCharmsType.typeCharmPanel.MinorCharms)
        TypeCharmRadioGroup:selectWidget(TypeCharmRadioGroup:getFirstWidget())
        connect(TypeCharmRadioGroup, {
            onSelectionChange = onTypeCharmRadioGroup
        })
    end
end

function onTerminateCharm()
    if TypeCharmRadioGroup then
        disconnect(TypeCharmRadioGroup, {
            onSelectionChange = onTypeCharmRadioGroup
        })
        TypeCharmRadioGroup:destroy()
        TypeCharmRadioGroup = nil
    end
end

function Cyclopedia.CreateCharmItem(data)
    local CharmList = g_game.getClientVersion() >= 1410 and UI.mainPanelCharmsType.panelCharmList.CharmList or UI.CharmList
    local widget = g_ui.createWidget("CharmItem", CharmList)
    local value = widget.PriceBase.Value

    widget:setId(data.id)
    widget.charmBase.image:setImageSource("/game_cyclopedia/images/charms/monster-bonus-effects")

    if data.id ~= nil then
        widget.charmBase.image:setImageClip((data.id * 32) .. ' 0 32 32')
    else
        g_logger.error(string.format("Cyclopedia.CreateCharmItem - charm %s is nil", data.id))
        return
    end

    if g_game.getClientVersion() >= 1410 then
        widget:setText(charms[data.id].name)
    else
        widget:setText(data.name)
    end
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
    
    widget.category = charms[data.id].category
end

function Cyclopedia.loadCharms(charmsData)
    if not UI then
        return
    end

    local CharmList = g_game.getClientVersion() >= 1410 and UI.mainPanelCharmsType.panelCharmList.CharmList or UI.CharmList
    local player = g_game.getLocalPlayer()
    
    if g_game.getClientVersion() >= 1410 then
        local mainCharmValue = string.format("%d/%d", 
            player:getResourceBalance(ResourceTypes.CHARM),
            player:getResourceBalance(ResourceTypes.MAX_CHARM))
        controllerCyclopedia.ui.CharmsBase.Value:setText(mainCharmValue)
        
        local minorCharmValue = string.format("%d/%d", 
            player:getResourceBalance(ResourceTypes.MINOR_CHARM),
            player:getResourceBalance(ResourceTypes.MAX_MINOR_CHARM))
        controllerCyclopedia.ui.CharmsBase1410.Value:setText(minorCharmValue)
    else
        controllerCyclopedia.ui.CharmsBase.Value:setText(Cyclopedia.formatGold(charmsData.points))
    end

    UI.CharmsPoints = charmsData.points

    Cyclopedia.Charms.Monsters = {}
    local raceIdNamePairs = {}

    for _, raceId in ipairs(charmsData.finishedMonsters) do
        local raceData = g_things.getRaceData(raceId)
        local raceName = raceData.name ~= "" and raceData.name or string.format("unnamed_%d", raceId)
        table.insert(raceIdNamePairs, { raceId = raceId, name = raceName })
    end

    table.sort(raceIdNamePairs, function(a, b) return a.name:lower() < b.name:lower() end)

    for _, pair in ipairs(raceIdNamePairs) do
        table.insert(Cyclopedia.Charms.Monsters, pair.raceId)
    end

    CharmList:destroyChildren()

    local formatedData = {}

    for _, charmData in pairs(charmsData.charms) do
        local internalId = charmData.id
        if internalId ~= nil then
            if charms[internalId] then
                local charm = charms[internalId]
                charmData.name = charmData.name ~= "" and charmData.name or charm.name
                charmData.description = charmData.description ~= "" and charmData.description or charm.description
                charmData.internalId = internalId
                charmData.typePriority = charm.type
                charmData.category = charm.category
                table.insert(formatedData, charmData)
            end
        end
    end
    table.sort(formatedData, function(a, b)
        if a.unlocked ~= b.unlocked then
            return a.unlocked and not b.unlocked
        end
        return a.name:lower() < b.name:lower()
    end)

    for _, value in ipairs(formatedData) do
        if value and value.name and value.description and 
           value.internalId ~= nil and value.typePriority ~= nil then
            local status, err = pcall(function()
                Cyclopedia.CreateCharmItem(value)
            end)
            
            if not status then
                g_logger.error("Error al crear charm item: " .. tostring(err) .. 
                               " para charm ID: " .. tostring(value.internalId) .. 
                               " (" .. tostring(value.name) .. ")")
            end
        else
            g_logger.error("Charm data incompleto: " .. 
                          (value and ("ID: " .. tostring(value.internalId or "unknown")) or "nil"))
        end
    end

    if g_game.getClientVersion() >= 1410 then
        local selectedWidget = TypeCharmRadioGroup:getSelectedWidget()
        if selectedWidget then
            local charmCategory = selectedWidget:getId() == "MajorCharms" and charmCategory_t.CHARM_MAJOR or charmCategory_t.CHARM_MINOR
            
            for _, widget in ipairs(CharmList:getChildren()) do
                widget:setVisible(widget.category == charmCategory)
            end
            
            CharmList:getLayout():update()
        end
    end

    local firstCharm
    if Cyclopedia.Charms.redirect then
        firstCharm = CharmList:getChildById(Cyclopedia.Charms.redirect)
        Cyclopedia.Charms.redirect = nil
    else
        firstCharm = CharmList:getChildByIndex(1)
    end
    
    if firstCharm then
        Cyclopedia.selectCharm(firstCharm, firstCharm:isChecked())
    end
end

function Cyclopedia.selectCharm(widget, isChecked)
    local clientVersion = g_game.getClientVersion()
    local UI_BASE = {}
    
    if clientVersion >= 1410 then
        UI_BASE.CreatureList = UI.InformationBase.PanelCreatureList.CreaturesBase.CreatureList
        UI_BASE.InfoBase = UI.InformationBase.panelSelectCreature.InfoBase
        UI_BASE.TextBase = UI.InformationBase.TextBase
        UI_BASE.ItemBase = UI.InformationBase.ItemBase
        UI_BASE.PriceBase = UI.InformationBase.verticalPanelUnLockClearChram.PriceBaseGold
        UI_BASE.UnlockButton = UI.InformationBase.verticalPanelUnLockClearChram.UnlockButton
        UI_BASE.SearchEdit = UI.InformationBase.PanelCreatureList.SearchEdit.SearchEdit
        UI_BASE.SearchLabel = UI.InformationBase.SearchLabel
        UI_BASE.CreaturesBase = UI.InformationBase.PanelCreatureList.CreaturesBase
        UI_BASE.CreaturesLabel = UI.InformationBase.panelSelectCreature.CreaturesLabel
    else
        UI_BASE.CreatureList = UI.InformationBase.CreaturesBase.CreatureList
        UI_BASE.InfoBase = UI.InformationBase.InfoBase
        UI_BASE.TextBase = UI.InformationBase.TextBase
        UI_BASE.ItemBase = UI.InformationBase.ItemBase
        UI_BASE.PriceBase = UI.InformationBase.PriceBase
        UI_BASE.UnlockButton = UI.InformationBase.UnlockButton
        UI_BASE.SearchEdit = UI.InformationBase.SearchEdit
        UI_BASE.SearchLabel = UI.InformationBase.SearchLabel
        UI_BASE.CreaturesBase = UI.InformationBase.CreaturesBase
        UI_BASE.CreaturesLabel = UI.InformationBase.CreaturesLabel
    end
    
    UI_BASE.CreatureList:destroyChildren()

    local parent = widget:getParent()
    local button = UI_BASE.UnlockButton
    local value = UI_BASE.PriceBase.Value

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

    UI_BASE.TextBase:setText(widget.data.description)
    UI_BASE.ItemBase.image:setImageSource(widget.charmBase.image:getImageSource())
    UI_BASE.ItemBase.image:setImageClip(widget.charmBase.image:getImageClip())

    if clientVersion >= 1410 then
        UI.InformationBase:setText(widget:getText())
    end
    if widget.data.asignedStatus then
        UI_BASE.InfoBase.sprite:setVisible(true)
        UI_BASE.InfoBase.sprite:setOutfit(g_things.getRaceData(widget.data.raceId).outfit)
        UI_BASE.InfoBase.sprite:getCreature():setStaticWalking(1000)
        UI_BASE.InfoBase.sprite:setOpacity(1)
    else
        UI_BASE.InfoBase.sprite:setVisible(false)
    end

    if widget.icon == 1 then
        UI_BASE.PriceBase.Gold:setVisible(true)
        UI_BASE.PriceBase.Charm:setVisible(false)
    else
        UI_BASE.PriceBase.Gold:setVisible(false)
        UI_BASE.PriceBase.Charm:setVisible(true)
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
    if (widget.data.unlocked and not widget.data.asignedStatus) or clientVersion >= 1410  then
        button:setText("Select")

        local color = "#484848"

        for index, raceId in ipairs(Cyclopedia.Charms.Monsters) do
            local internalWidget = g_ui.createWidget("CharmCreatureName", UI_BASE.CreatureList)
            internalWidget:setId(index)
            internalWidget:setText(format(g_things.getRaceData(raceId).name))
            internalWidget.raceId = raceId
            internalWidget:setBackgroundColor(color)
            internalWidget.color = color
            color = color == "#484848" and "#414141" or "#484848"
        end

        button:setEnabled(false)
        UI_BASE.SearchEdit:setEnabled(true)
        if UI_BASE.SearchLabel then
            UI_BASE.SearchLabel:setEnabled(true)
        end
        UI_BASE.CreaturesLabel:setEnabled(true)
    end

    if widget.data.asignedStatus then
        button:setText("Remove")

        local internalWidget = g_ui.createWidget("CharmCreatureName", UI_BASE.CreatureList)
        internalWidget:setText(format(g_things.getRaceData(widget.data.raceId).name))
        internalWidget:setEnabled(false)
        internalWidget:setColor("#707070")
        UI_BASE.SearchEdit:setEnabled(false)
        if UI_BASE.SearchLabel then
        UI_BASE.SearchLabel:setEnabled(false)        

        end
        UI_BASE.CreaturesLabel:setEnabled(false)
    end

    if not widget.data.unlocked then
        button:setText("Unlock")
        UI_BASE.SearchEdit:setEnabled(false)
        if UI_BASE.SearchLabel then

        UI_BASE.SearchLabel:setEnabled(false)
        end
        UI_BASE.CreaturesLabel:setEnabled(false)
    end
end

function Cyclopedia.selectCreatureCharm(widget, isChecked)
    local UI_BASE = {}
    local clientVersion = g_game.getClientVersion()
    
    if clientVersion >= 1410 then
        UI_BASE.InfoBase = UI.InformationBase.panelSelectCreature.InfoBase
        UI_BASE.UnlockButton = UI.InformationBase.verticalPanelUnLockClearChram.UnlockButton
    else
        UI_BASE.InfoBase = UI.InformationBase.InfoBase
        UI_BASE.UnlockButton = UI.InformationBase.UnlockButton
    end
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

    UI_BASE.InfoBase.sprite:setVisible(true)
    UI_BASE.InfoBase.sprite:setOutfit(g_things.getRaceData(widget.raceId).outfit)
    UI_BASE.InfoBase.sprite:getCreature():setStaticWalking(1000)
    UI_BASE.InfoBase.sprite:setOpacity(0.5)
    UI_BASE.UnlockButton:setEnabled(true)

    Cyclopedia.Charms.SelectedCreature = widget.raceId
end

function Cyclopedia.searchCharmMonster(text)
    local clientVersion = g_game.getClientVersion()
    local UI_BASE = {}
    
    if clientVersion >= 1410 then
        UI_BASE.CreaturesBase = UI.InformationBase.PanelCreatureList.CreaturesBase
    else
        UI_BASE.CreaturesBase = UI.InformationBase.CreaturesBase
    end


    UI_BASE.CreaturesBase.CreatureList:destroyChildren()

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
        local internalWidget = g_ui.createWidget("CharmCreatureName", UI_BASE.CreaturesBase.CreatureList)
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

function onTypeCharmRadioGroup(radioGroup, selectedWidget)
    local charmCategory = selectedWidget:getId() == "MajorCharms" and charmCategory_t.CHARM_MAJOR or charmCategory_t.CHARM_MINOR
    local CharmList = UI.mainPanelCharmsType.panelCharmList.CharmList
    
    for _, widget in ipairs(CharmList:getChildren()) do
        if widget.category == charmCategory then
            widget:setVisible(true)
        else
            widget:setVisible(false)
        end
    end
    
    CharmList:getLayout():update()
end
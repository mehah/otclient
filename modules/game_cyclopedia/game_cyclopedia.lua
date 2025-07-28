Cyclopedia = {}

trackerButton = nil
trackerMiniWindow = nil
trackerButtonBosstiary = nil
trackerMiniWindowBosstiary = nil
contentContainer = nil

local buttonSelection = nil
local items = nil
local bestiary = nil
local charms = nil
local map = nil
local houses = nil
local character = nil
local CyclopediaButton = nil
local bosstiary = nil
local bossSlot = nil
local ButtonBossSlot = nil
local ButtonBestiary = nil
local tabStack = {}
local previousType = nil
local windowTypes = {}
local magicalArchives = nil
function toggle(defaultWindow)
    if not controllerCyclopedia.ui then
        return
    end
    if controllerCyclopedia.ui:isVisible() then
        return hide()
    end
    show(defaultWindow)
end

controllerCyclopedia = Controller:new()
controllerCyclopedia:setUI('game_cyclopedia')

function controllerCyclopedia:onInit()
end

function controllerCyclopedia:onGameStart()
    if g_game.getClientVersion() >= 1310 then
        CyclopediaButton = modules.game_mainpanel.addToggleButton('CyclopediaButton', tr('Cyclopedia'),
            '/images/options/cooldowns', function() toggle("items") end, false, 7)
        ButtonBossSlot = modules.game_mainpanel.addToggleButton("bossSlot", tr("Open Boss Slots dialog"),
            "/images/options/ButtonBossSlot", function() toggle("bossSlot") end, false, 20)
        CyclopediaButton:setOn(false)
        ButtonBestiary = modules.game_mainpanel.addToggleButton("bosstiary", tr("Open Bosstiary dialog"),
            "/images/options/ButtonBosstiary", function() toggle("bosstiary") end, false, 17)

        contentContainer = controllerCyclopedia.ui:recursiveGetChildById('contentContainer')
        buttonSelection = controllerCyclopedia.ui:recursiveGetChildById('buttonSelection')
        items = buttonSelection:recursiveGetChildById('items')
        bestiary = buttonSelection:recursiveGetChildById('bestiary')
        charms = buttonSelection:recursiveGetChildById('charms')
        map = buttonSelection:recursiveGetChildById('map')
        houses = buttonSelection:recursiveGetChildById('houses')
        character = buttonSelection:recursiveGetChildById('character')
        bosstiary = buttonSelection:recursiveGetChildById('bosstiary')
        bossSlot = buttonSelection:recursiveGetChildById('bossSlot')
        magicalArchives = buttonSelection:recursiveGetChildById('magicalArchives')

        windowTypes = {
            items = { obj = items, func = showItems },
            bestiary = { obj = bestiary, func = showBestiary },
            charms = { obj = charms, func = showCharms },
            map = { obj = map, func = showMap },
            houses = { obj = houses, func = showHouse },
            character = { obj = character, func = showCharacter },
            bosstiary = { obj = bosstiary, func = showBosstiary },
            bossSlot = { obj = bossSlot, func = showBossSlot },
            magicalArchives = { obj = magicalArchives, func = showMagicalArchives },
        }

        g_ui.importStyle("cyclopedia_widgets")
        g_ui.importStyle("cyclopedia_pages")

        controllerCyclopedia:registerEvents(g_game, {
            -- bestiary
            onParseBestiaryRaces = Cyclopedia.loadBestiaryCategories,
            onParseBestiaryOverview = Cyclopedia.loadBestiaryOverview,
            onUpdateBestiaryMonsterData = Cyclopedia.loadBestiarySelectedCreature,
            -- bosstiary // bestiary
            onParseCyclopediaTracker = Cyclopedia.onParseCyclopediaTracker,
            -- bosstiary
            onParseSendBosstiary = Cyclopedia.LoadBosstiaryCreatures,
            -- boss_slot
            onParseBosstiarySlots = Cyclopedia.loadBossSlots,
            -- character
            onParseCyclopediaCharacterGeneralStats = Cyclopedia.loadCharacterGeneralStats,
            onParseCyclopediaCharacterCombatStats = Cyclopedia.loadCharacterCombatStats,
            onParseCyclopediaCharacterBadges = Cyclopedia.loadCharacterBadges,
            onCyclopediaCharacterRecentDeaths = Cyclopedia.loadCharacterRecentDeaths,
            onCyclopediaCharacterRecentKills = Cyclopedia.loadCharacterRecentKills,
            onUpdateCyclopediaCharacterItemSummary = Cyclopedia.loadCharacterItems,
            onParseCyclopediaCharacterAppearances = Cyclopedia.loadCharacterAppearances,
            onParseCyclopediaStoreSummary = Cyclopedia.onParseCyclopediaStoreSummary,
-- character 14.10
            onCyclopediaCharacterOffenceStats = Cyclopedia.onCyclopediaCharacterOffenceStats,
            onCyclopediaCharacterDefenceStats = Cyclopedia.onCyclopediaCharacterDefenceStats,
            onCyclopediaCharacterMiscStats = Cyclopedia.onCyclopediaCharacterMiscStats,


            -- charms
            onUpdateBestiaryCharmsData = Cyclopedia.loadCharms,
            -- items
            onParseItemDetail = Cyclopedia.loadItemDetail
        })

        --[[===================================================
    =               Tracker Bestiary                      =
    =================================================== ]] --

        trackerButton = modules.game_mainpanel.addToggleButton("trackerButton", tr("Bestiary Tracker"),
            "/images/options/bestiaryTracker", Cyclopedia.toggleBestiaryTracker, false, 17)

        trackerButton:setOn(false)
        trackerMiniWindow = g_ui.createWidget('BestiaryTracker', modules.game_interface.getRightPanel())

        trackerMiniWindow.menuButton.onClick = function(widget, mousePos, mouseButton)
            local menu = g_ui.createWidget('bestiaryTrackerMenu')
            menu:setGameMenu(true)
            local shortCreature = UIRadioGroup.create()
            local shortAlphabets = UIRadioGroup.create()

            for i, choice in ipairs(menu:getChildren()) do
                if i >= 1 and i <= 3 then
                    shortCreature:addWidget(choice)
                elseif i == 5 or i == 6 then
                    shortAlphabets:addWidget(choice)
                end
            end

            menu:display(mousePos)
            return true
        end

        trackerMiniWindow.cyclopediaButton.onClick = function(widget, mousePos, mouseButton)
            toggle("bestiary")
            return true
        end

        trackerMiniWindow:moveChildToIndex(trackerMiniWindow.menuButton, 4)
        trackerMiniWindow:moveChildToIndex(trackerMiniWindow.cyclopediaButton, 5)
        trackerMiniWindow:setup()
        trackerMiniWindow:hide()

        --[[===================================================
    =               Tracker Bosstiary                     =
    =================================================== ]] --

        trackerButtonBosstiary = modules.game_mainpanel.addToggleButton("bosstiarytrackerButton",
            tr("Bosstiary Tracker"), "/images/options/bosstiaryTracker", Cyclopedia.toggleBosstiaryTracker, false, 17)

        trackerButtonBosstiary:setOn(false)
        trackerMiniWindowBosstiary = g_ui.createWidget('BestiaryTracker', modules.game_interface.getRightPanel())
        trackerMiniWindowBosstiary:setText("Bosstiary Tracker")

        trackerMiniWindowBosstiary.menuButton.onClick = function(widget, mousePos, mouseButton)
            local menu = g_ui.createWidget('bestiaryTrackerMenu')
            menu:setGameMenu(true)
            local shortCreature = UIRadioGroup.create()
            local shortAlphabets = UIRadioGroup.create()

            for i, choice in ipairs(menu:getChildren()) do
                if i >= 1 and i <= 3 then
                    shortCreature:addWidget(choice)
                elseif i == 5 or i == 6 then
                    shortAlphabets:addWidget(choice)
                end
            end

            menu:display(mousePos)
            return true
        end

        trackerMiniWindowBosstiary.cyclopediaButton.onClick =
            function(widget, mousePos, mouseButton)
                toggle("bosstiary")
                return true
            end

        trackerMiniWindowBosstiary:moveChildToIndex(trackerMiniWindowBosstiary.menuButton, 4)
        trackerMiniWindowBosstiary:moveChildToIndex(trackerMiniWindowBosstiary.cyclopediaButton, 5)
        trackerMiniWindowBosstiary:setup()
        trackerMiniWindowBosstiary:hide()
        trackerMiniWindow:setupOnStart()
        loadFilters()
        Cyclopedia.BossSlots.UnlockBosses = {}
        Keybind.new("Windows", "Show/hide Bosstiary Tracker", "", "")

        Keybind.bind("Windows", "Show/hide Bosstiary Tracker", {{
            type = KEY_DOWN,
            callback = Cyclopedia.toggleBosstiaryTracker
        }})

        Keybind.new("Windows", "Show/hide Bestiary Tracker", "", "")
        Keybind.bind("Windows", "Show/hide Bestiary Tracker", {{
            type = KEY_DOWN,
            callback = Cyclopedia.toggleBestiaryTracker
        }})

    end
    if g_game.getClientVersion() >= 1410 then
        controllerCyclopedia.ui.CharmsBase.Icon:setImageSource("/game_cyclopedia/images/monster-icon-bonuspoints")
    end
end


function controllerCyclopedia:onGameEnd()
    if trackerMiniWindow then
        trackerMiniWindow.contentsPanel:destroyChildren()
    end
    hide()
    saveFilters()
    Keybind.delete("Windows", "Show/hide Bosstiary Tracker")
    Keybind.delete("Windows", "Show/hide Bestiary Tracker")
end

function controllerCyclopedia:onTerminate()
    if trackerButton then
        trackerButton:destroy()
        trackerButton = nil
    end

    if trackerMiniWindow then
        trackerMiniWindow:destroy()
        trackerMiniWindow = nil
    end

    if trackerButtonBosstiary then
        trackerButtonBosstiary:destroy()
        trackerButtonBosstiary = nil
    end

    if trackerMiniWindowBosstiary then
        trackerMiniWindowBosstiary:destroy()
        trackerMiniWindowBosstiary = nil
    end

    if CyclopediaButton then
        CyclopediaButton:destroy()
        CyclopediaButton = nil
    end
    if ButtonBossSlot then
        ButtonBossSlot:destroy()
        ButtonBossSlot = nil
    end
    if ButtonBestiary then
        ButtonBestiary:destroy()
        ButtonBestiary = nil
    end
    onTerminateCharm()
end

function hide()
    if not controllerCyclopedia.ui then
        return
    end
    resetCyclopediaTabs()
    controllerCyclopedia.ui:hide()
end

function resetCyclopediaTabs()
    tabStack = {}
    controllerCyclopedia.ui.BackButton:setEnabled(false)
    if previousType then
        local previousWindow = windowTypes[previousType]
        previousWindow.obj:enable()
        previousWindow.obj:setOn(false)
        previousType = nil;
    end
end

function show(defaultWindow)
    if not controllerCyclopedia.ui or not CyclopediaButton then
        return
    end

    controllerCyclopedia.ui:show()
    controllerCyclopedia.ui:raise()
    controllerCyclopedia.ui:focus()
    SelectWindow(defaultWindow, false)
    controllerCyclopedia.ui.GoldBase.Value:setText(Cyclopedia.formatGold(g_game.getLocalPlayer():getResourceBalance()))
end

function toggleBack()
    local previousTab = table.remove(tabStack, #tabStack)
    if #tabStack < 1 then
        controllerCyclopedia.ui.BackButton:setEnabled(false)
    end
    SelectWindow(previousTab, true)
end

function SelectWindow(type, isBackButtonPress)
    if previousType then
        local previousWindow = windowTypes[previousType]
        previousWindow.obj:enable()
        previousWindow.obj:setOn(false)
        if not isBackButtonPress then
            table.insert(tabStack, previousType)
            controllerCyclopedia.ui.BackButton:setEnabled(true)
        end
    end
    contentContainer:destroyChildren()

    local window = windowTypes[type]
    if window then
        window.obj:setOn(true)
        window.obj:disable()
        previousType = type
        if window.func then
            window.func(contentContainer)
        end
    end
end

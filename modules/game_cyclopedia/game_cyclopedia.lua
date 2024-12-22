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

function toggle()
    if not controllerCyclopedia.ui then
        return
    end
    if controllerCyclopedia.ui:isVisible() then
        return hide()
    end
    show()
end

controllerCyclopedia = Controller:new()
controllerCyclopedia:setUI('game_cyclopedia')

function controllerCyclopedia:onInit()
end

function controllerCyclopedia:onGameStart()
    if g_game.getClientVersion() >= 1310 then
        CyclopediaButton = modules.game_mainpanel.addToggleButton('CyclopediaButton', tr('Cyclopedia'),
            '/images/options/cooldowns', toggle, false, 7)
        ButtonBossSlot = modules.game_mainpanel.addToggleButton("bossSlot", tr("Open Boss Slots dialog"),
            "/images/options/ButtonBossSlot", getBossSlot, false, 20)
        CyclopediaButton:setOn(false)
        ButtonBestiary = modules.game_mainpanel.addToggleButton("bosstiary", tr("Open Bosstiary dialog"),
            "/images/options/ButtonBosstiary", getBosstiary, false, 17)

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
            onParseSendBosstiary = Cyclopedia.LoadBoostiaryCreatures,
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
            toggle()
            SelectWindow("bestiary")
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
            tr("bosstiary Tracker"), "/images/options/bosstiaryTracker", Cyclopedia.toggleBosstiaryTracker, false, 17)

        trackerButtonBosstiary:setOn(false)
        trackerMiniWindowBosstiary = g_ui.createWidget('BestiaryTracker', modules.game_interface.getRightPanel())
        trackerMiniWindowBosstiary:setText("Boosteary Tracker")

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
                toggle()
                SelectWindow("bosstiary")
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

    if focusCategoryList then
        disconnect(focusCategoryList, {
            onChildFocusChange = function(self, focusedChild)
                if focusedChild == nil then
                    return
                end
                focusedChild:onClick()
            end
        })
    end
end

function hide()
    if not controllerCyclopedia.ui then
        return
    end
    controllerCyclopedia.ui:hide()
    if focusCategoryList then
        disconnect(focusCategoryList, {
            onChildFocusChange = function(self, focusedChild)
                if focusedChild == nil then
                    return
                end
                focusedChild:onClick()
            end
        })
    end
end

function show()
    if not controllerCyclopedia.ui or not CyclopediaButton then
        return
    end

    controllerCyclopedia.ui:show()
    controllerCyclopedia.ui:raise()
    controllerCyclopedia.ui:focus()
    SelectWindow("items")
    controllerCyclopedia.ui.GoldBase.Value:setText(Cyclopedia.formatGold(g_game.getLocalPlayer():getResourceBalance(1)))
end

function SelectWindow(type)
    local windowTypes = {
        items = { obj = items, func = showItems },
        bestiary = { obj = bestiary, func = showBestiary },
        charms = { obj = charms, func = showCharms },
        map = { obj = map, func = showMap },
        houses = { obj = houses, func = showHouse }, 
        character = { obj = character, func = showCharacter },
        bosstiary = { obj = bosstiary, func = showBosstiary },
        bossSlot = { obj = bossSlot, func = showBossSlot }
    }

    if previousType then
        previousType.obj:enable()
        previousType.obj:setOn(false)
    end
    contentContainer:destroyChildren()

    local window = windowTypes[type]
    if window then
        window.obj:setOn(true)
        window.obj:disable()
        previousType = window
        if window.func then
            window.func(contentContainer)
        end
    end
end

function getBosstiary()
    if not controllerCyclopedia.ui then
        return
    end
    if controllerCyclopedia.ui:isVisible() then
        return hide()
    end
    show()
    SelectWindow("bosstiary")
end

function getBossSlot()
    if not controllerCyclopedia.ui then
        return
    end
    if controllerCyclopedia.ui:isVisible() then
        return hide()
    end
    show()
    SelectWindow("bossSlot")
end

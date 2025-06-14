gameRootPanel = nil
gameMapPanel = nil
gameMainRightPanel = nil
gameRightPanel = nil
gameRightExtraPanel = nil
gameLeftPanel = nil
gameLeftExtraPanel = nil
gameSelectedPanel = nil
panelsList = {}
panelsRadioGroup = nil
gameTopPanel = nil
gameBottomStatsBarPanel = nil
gameBottomPanel = nil
showTopMenuButton = nil
logoutButton = nil
logOutMainButton = nil
mouseGrabberWidget = nil
countWindow = nil
logoutWindow = nil
exitWindow = nil
bottomSplitter = nil
limitedZoom = false
currentViewMode = 0
leftIncreaseSidePanels = nil
leftDecreaseSidePanels = nil
rightIncreaseSidePanels = nil
rightDecreaseSidePanels = nil
hookedMenuOptions = {}
local lastStopAction = 0
local mobileConfig = {
    mobileWidthJoystick = 0,
    mobileWidthShortcuts = 0,
    mobileHeightJoystick = 0,
    mobileHeightShortcuts = 0
}

function init()
    g_ui.importStyle('styles/countwindow')

    connect(g_game, {
        onGameStart = onGameStart,
        onGameEnd = onGameEnd,
        onLoginAdvice = onLoginAdvice
    }, true)

    -- Call load AFTER game window has been created and
    -- resized to a stable state, otherwise the saved
    -- settings can get overridden by false onGeometryChange
    -- events
    if g_app.hasUpdater() then
        connect(g_app, {
            onUpdateFinished = load,
        })
    else
        connect(g_app, {
            onRun = load,
        })
    end

    connect(g_app, {
        onExit = save
    })

    gameRootPanel = g_ui.displayUI('gameinterface')
    gameRootPanel:hide()
    gameRootPanel:lower()
    gameRootPanel.onGeometryChange = updateStretchShrink

    mouseGrabberWidget = gameRootPanel:getChildById('mouseGrabber')
    mouseGrabberWidget.onMouseRelease = onMouseGrabberRelease

    bottomSplitter = gameRootPanel:getChildById('bottomSplitter')
    gameMapPanel = gameRootPanel:getChildById('gameMapPanel')
    gameMainRightPanel = gameRootPanel:getChildById('gameMainRightPanel')
    gameRightPanel = gameRootPanel:getChildById('gameRightPanel')
    gameRightExtraPanel = gameRootPanel:getChildById('gameRightExtraPanel')
    gameLeftExtraPanel = gameRootPanel:getChildById('gameLeftExtraPanel')
    gameLeftPanel = gameRootPanel:getChildById('gameLeftPanel')
    gameBottomPanel = gameRootPanel:getChildById('gameBottomPanel')
    gameTopPanel = gameRootPanel:getChildById('gameTopPanel')
    gameBottomStatsBarPanel = gameRootPanel:getChildById('gameBottomStatsBarPanel')

    leftIncreaseSidePanels = gameRootPanel:getChildById('leftIncreaseSidePanels')
    leftDecreaseSidePanels = gameRootPanel:getChildById('leftDecreaseSidePanels')
    rightIncreaseSidePanels = gameRootPanel:getChildById('rightIncreaseSidePanels')
    rightDecreaseSidePanels = gameRootPanel:getChildById('rightDecreaseSidePanels')

    leftIncreaseSidePanels:setEnabled(not modules.client_options.getOption('showLeftExtraPanel'))
    if g_platform.isMobile() then
        leftDecreaseSidePanels:setEnabled(false)
    else
        leftDecreaseSidePanels:setEnabled(true)
    end
    rightIncreaseSidePanels:setEnabled(not modules.client_options.getOption('showRightExtraPanel'))
    rightDecreaseSidePanels:setEnabled(modules.client_options.getOption('showRightExtraPanel'))

    if g_platform.isMobile() then
        gameRightPanel:setMarginBottom(mobileConfig.mobileHeightShortcuts)
        gameLeftPanel:setMarginBottom(mobileConfig.mobileHeightJoystick)
    end

    panelsList = { {
        panel = gameRightPanel,
        checkbox = gameRootPanel:getChildById('gameSelectRightColumn')
    }, {
        panel = gameRightExtraPanel,
        checkbox = gameRootPanel:getChildById('gameSelectRightExtraColumn')
    }, {
        panel = gameLeftPanel,
        checkbox = gameRootPanel:getChildById('gameSelectLeftColumn')
    }, {
        panel = gameLeftExtraPanel,
        checkbox = gameRootPanel:getChildById('gameSelectLeftExtraColumn')
    } }

    panelsRadioGroup = UIRadioGroup.create()
    for k, v in pairs(panelsList) do
        panelsRadioGroup:addWidget(v.checkbox)
        connect(v.checkbox, {
            onCheckChange = onSelectPanel
        })
    end
    panelsRadioGroup:selectWidget(panelsList[1].checkbox)

    logoutButton = modules.client_topmenu.addTopRightToggleButton('logoutButton', tr('Exit'), '/images/topbuttons/logout',
        tryLogout, true)

    showTopMenuButton = gameMapPanel:getChildById('showTopMenuButton')
    showTopMenuButton.onClick = function()
        modules.client_topmenu.toggle()
    end

    bindKeys()

    if g_game.isOnline() then
        show()
    end

    StatsBar.init()
end

function bindKeys()
    gameRootPanel:setAutoRepeatDelay(50)

    g_keyboard.bindKeyPress('Ctrl+=', function()
        gameMapPanel:zoomIn()
    end, gameRootPanel)
    g_keyboard.bindKeyPress('Ctrl+-', function()
        gameMapPanel:zoomOut()
    end, gameRootPanel)

    Keybind.new("Movement", "Stop All Actions", "Escape", "", true)
    Keybind.bind("Movement", "Stop All Actions", {
        {
            type = KEY_PRESS,
            callback = function()
                if lastStopAction + 50 > g_clock.millis() then return end
                lastStopAction = g_clock.millis()
                g_game.cancelAttackAndFollow()
            end,
        }
    }, gameRootPanel)

    Keybind.new("Misc", "Logout", "Ctrl+L", "Ctrl+Q")
    Keybind.bind("Misc", "Logout", {
        {
            type = KEY_PRESS,
            callback = function() tryLogout(false) end,
        }
    }, gameRootPanel)

    Keybind.new("UI", "Clear All Texts", "Ctrl+W", "")
    Keybind.bind("UI", "Clear All Texts", {
        {
            type = KEY_DOWN,
            callback = function()
                g_map.cleanTexts()
                modules.game_textmessage.clearMessages()
            end,
        }
    }, gameRootPanel)

    g_keyboard.bindKeyDown('Ctrl+.', nextViewMode, gameRootPanel)
end

function terminate()
    StatsBar.terminate()

    hide()
    if g_app.hasUpdater() then
        disconnect(g_app, {
            onUpdateFinished = load,
        })
    else
        disconnect(g_app, {
            onRun = load,
        })
    end
    disconnect(g_app, {
        onExit = save,
    })

    hookedMenuOptions = {}

    disconnect(g_game, {
        onGameStart = onGameStart,
        onGameEnd = onGameEnd,
        onLoginAdvice = onLoginAdvice
    })

    for k, v in pairs(panelsList) do
        disconnect(v.checkbox, {
            onCheckChange = onSelectPanel
        })
    end

    logoutButton:destroy()
    gameRootPanel:destroy()
    Keybind.delete("Movement", "Stop All Actions")
    Keybind.delete("Misc", "Logout")
    Keybind.delete("UI", "Clear All Texts")
end

function onGameStart()
    show()

    leftIncreaseSidePanels:setEnabled(not modules.client_options.getOption('showLeftExtraPanel'))
    if g_platform.isMobile() then
        leftDecreaseSidePanels:setEnabled(false)
    else
        leftDecreaseSidePanels:setEnabled(true)
    end
    rightIncreaseSidePanels:setEnabled(not modules.client_options.getOption('showRightExtraPanel'))
    rightDecreaseSidePanels:setEnabled(modules.client_options.getOption('showRightExtraPanel'))

    if g_platform.isMobile() then
        gameRightPanel:setMarginBottom(mobileConfig.mobileHeightShortcuts)
        gameLeftPanel:setMarginBottom(mobileConfig.mobileHeightJoystick)
    end
end

function onGameEnd()
    hide()
end

function show()
    connect(g_app, {
        onClose = tryExit
    })
    modules.client_background.hide()
    gameRootPanel:show()
    gameRootPanel:focus()
    gameMapPanel:followCreature(g_game.getLocalPlayer())

    updateStretchShrink()
    logoutButton:setTooltip(tr('Logout'))

    setupViewMode(0)
    if g_platform.isMobile() then
        mobileConfig.mobileWidthJoystick = modules.game_joystick.getPanel():getWidth()
        mobileConfig.mobileWidthShortcuts = modules.game_shortcuts.getPanel():getWidth()
        mobileConfig.mobileHeightJoystick = modules.game_joystick.getPanel():getHeight()
        mobileConfig.mobileHeightShortcuts = modules.game_shortcuts.getPanel():getHeight()
        setupViewMode(1)
        setupViewMode(2)
    end

    addEvent(function()
        if not limitedZoom or g_game.isGM() then
            gameMapPanel:setMaxZoomOut(513)
            gameMapPanel:setLimitVisibleRange(false)
        else
            gameMapPanel:setMaxZoomOut(11)
            gameMapPanel:setLimitVisibleRange(true)
        end
    end)
end

function hide()
    setupViewMode(0)

    disconnect(g_app, {
        onClose = tryExit
    })
    logoutButton:setTooltip(tr('Exit'))

    if logoutWindow then
        logoutWindow:destroy()
        logoutWindow = nil
    end
    if exitWindow then
        exitWindow:destroy()
        exitWindow = nil
    end
    if countWindow then
        countWindow:destroy()
        countWindow = nil
    end
    gameRootPanel:hide()
    modules.client_background.show()
end

function save()
    local settings = {}
    settings.splitterMarginBottom = bottomSplitter:getMarginBottom()
    g_settings.setNode('game_interface', settings)
end

function load()
    local settings = g_settings.getNode('game_interface')
    if settings then
        if settings.splitterMarginBottom then
            bottomSplitter:setMarginBottom(settings.splitterMarginBottom)
        end
    end
end

function onLoginAdvice(message)
    displayInfoBox(tr('For Your Information'), message)
end

function forceExit()
    g_game.cancelLogin()
    scheduleEvent(exit, 10)
    return true
end

function tryExit()
    if exitWindow then
        return true
    end

    local exitFunc = function()
        g_game.safeLogout()
        forceExit()
    end
    local logoutFunc = function()
        g_game.safeLogout()
        exitWindow:destroy()
        exitWindow = nil
    end
    local cancelFunc = function()
        exitWindow:destroy()
        exitWindow = nil
    end

    exitWindow = displayGeneralBox(tr('Exit'), tr(
            'If you shut down the program, your character might stay in the game.\nClick on \'Logout\' to ensure that you character leaves the game properly.\nClick on \'Exit\' if you want to exit the program without logging out your character.'),
        {
            {
                text = tr('Cancel'),
                callback = cancelFunc
            },
            {
                text = tr('Logout'),
                callback = logoutFunc
            },
            {
                text = tr('Force Exit'),
                callback = exitFunc
            },
            anchor = AnchorHorizontalCenter
        }, logoutFunc, cancelFunc)

    return true
end

function tryLogout(prompt)
    if type(prompt) ~= 'boolean' then
        prompt = true
    end
    if not g_game.isOnline() then
        exit()
        return
    end

    if logoutWindow then
        return
    end

    local msg, yesCallback
    if not g_game.isConnectionOk() then
        msg =
        'Your connection is failing, if you logout now your character will be still online, do you want to force logout?'

        yesCallback = function()
            g_game.forceLogout()
            if logoutWindow then
                logoutWindow:destroy()
                logoutWindow = nil
            end
        end
    else
        msg = 'Are you sure you want to logout?'

        yesCallback = function()
            g_game.safeLogout()
            if logoutWindow then
                logoutWindow:destroy()
                logoutWindow = nil
            end
        end
    end

    local noCallback = function()
        logoutWindow:destroy()
        logoutWindow = nil
    end

    if prompt then
        logoutWindow = displayGeneralBox(tr('Logout'), tr(msg), {
            {
                text = tr('No'),
                callback = noCallback
            },
            {
                text = tr('Yes'),
                callback = yesCallback
            },
            anchor = AnchorHorizontalCenter
        }, yesCallback, noCallback)
    else
        yesCallback()
    end
end

function updateStretchShrink()
    if modules.client_options.getOption('dontStretchShrink') and not alternativeView then
        gameMapPanel:setVisibleDimension({
            width = 15,
            height = 11
        })

        -- Set gameMapPanel size to height = 11 * 32 + 2
        bottomSplitter:setMarginBottom(bottomSplitter:getMarginBottom() + (gameMapPanel:getHeight() - 32 * 11) - 10)
    end
end

function onMouseGrabberRelease(self, mousePosition, mouseButton)
    if selectedThing == nil then
        return false
    end
    if mouseButton == MouseLeftButton then
        local clickedWidget = gameRootPanel:recursiveGetChildByPos(mousePosition, false)
        if clickedWidget then
            if selectedType == 'use' then
                onUseWith(clickedWidget, mousePosition)
            elseif selectedType == 'trade' then
                onTradeWith(clickedWidget, mousePosition)
            end
        end
    end

    selectedThing = nil
    g_mouse.popCursor('target')
    self:ungrabMouse()
    return true
end

function onUseWith(clickedWidget, mousePosition)
    if clickedWidget:getClassName() == 'UIGameMap' then
        local tile = clickedWidget:getTile(mousePosition)
        if tile then
            if selectedThing:isFluidContainer() or selectedThing:isMultiUse() then
                g_game.useWith(selectedThing, tile:getTopMultiUseThing())
            else
                g_game.useWith(selectedThing, tile:getTopUseThing())
            end
        end
    elseif clickedWidget:getClassName() == 'UIItem' and not clickedWidget:isVirtual() then
        g_game.useWith(selectedThing, clickedWidget:getItem())
    elseif clickedWidget:getClassName() == 'UICreatureButton' then
        local creature = clickedWidget:getCreature()
        if creature then
            g_game.useWith(selectedThing, creature)
        end
    end
end

function onTradeWith(clickedWidget, mousePosition)
    if clickedWidget:getClassName() == 'UIGameMap' then
        local tile = clickedWidget:getTile(mousePosition)
        if tile then
            g_game.requestTrade(selectedThing, tile:getTopCreature())
        end
    elseif clickedWidget:getClassName() == 'UICreatureButton' then
        local creature = clickedWidget:getCreature()
        if creature then
            g_game.requestTrade(selectedThing, creature)
        end
    end
end

function startUseWith(thing)
    if not thing then
        return
    end
    if g_ui.isMouseGrabbed() then
        if selectedThing then
            selectedThing = thing
            selectedType = 'use'
        end
        return
    end
    selectedType = 'use'
    selectedThing = thing
    mouseGrabberWidget:grabMouse()
    g_mouse.pushCursor('target')
end

function startTradeWith(thing)
    if not thing then
        return
    end
    if g_ui.isMouseGrabbed() then
        if selectedThing then
            selectedThing = thing
            selectedType = 'trade'
        end
        return
    end
    selectedType = 'trade'
    selectedThing = thing
    mouseGrabberWidget:grabMouse()
    g_mouse.pushCursor('target')
end

function isMenuHookCategoryEmpty(category)
    if category then
        for _, opt in pairs(category) do
            if opt then
                return false
            end
        end
    end
    return true
end

function addMenuHook(category, name, callback, condition, shortcut)
    if not hookedMenuOptions[category] then
        hookedMenuOptions[category] = {}
    end
    hookedMenuOptions[category][name] = {
        callback = callback,
        condition = condition,
        shortcut = shortcut
    }
end

function removeMenuHook(category, name)
    if not name then
        hookedMenuOptions[category] = {}
    else
        hookedMenuOptions[category][name] = nil
    end
end

function createThingMenu(menuPosition, lookThing, useThing, creatureThing)
    if not g_game.isOnline() then
        return
    end

    local menu = g_ui.createWidget('PopupMenu')
    menu:setGameMenu(true)

    local classic = modules.client_options.getOption('classicControl')
    local mobile = g_platform.isMobile()
    local shortcut = nil

    if not classic and not mobile then
        shortcut = '(Shift)'
    else
        shortcut = nil
    end
    if lookThing then
        menu:addOption(tr('Look'), function()
            g_game.look(lookThing)
        end, shortcut)
    end

    if not classic and not mobile then
        shortcut = '(Ctrl)'
    else
        shortcut = nil
    end
    if useThing then
        if useThing:isContainer() then
            if useThing:getParentContainer() then
                menu:addOption(tr('Open'), function()
                    g_game.open(useThing, useThing:getParentContainer())
                end, shortcut)
                menu:addOption(tr('Open in new window'), function()
                    g_game.open(useThing)
                end)
            else
                menu:addOption(tr('Open'), function()
                    g_game.open(useThing)
                end, shortcut)
            end
        else
            if useThing:isMultiUse() then
                menu:addOption(tr('Use with ...'), function()
                    startUseWith(useThing)
                end, shortcut)
            else
                menu:addOption(tr('Use'), function()
                    g_game.use(useThing)
                end, shortcut)
            end
        end

        if useThing:isRotateable() then
            menu:addOption(tr('Rotate'), function()
                g_game.rotate(useThing)
            end)
        end

        local onWrapItem = function()
            g_game.wrap(useThing)
        end
        if useThing:isWrapable() then
            menu:addOption(tr('Wrap'), onWrapItem)
        end
        if useThing:isUnwrapable() then
            menu:addOption(tr('Unwrap'), onWrapItem)
        end

        if g_game.getFeature(GameBrowseField) and useThing:getPosition().x ~= 0xffff then
            menu:addOption(tr('Browse Field'), function()
                g_game.browseField(useThing:getPosition())
            end)
        end
        if useThing:isLyingCorpse() and g_game.getFeature(GameThingQuickLoot) and modules.game_quickloot and useThing:getPosition().x ~= 0xffff then
            menu.addOption(menu, tr("Loot corpse"), function()
                g_game.sendQuickLoot(1, useThing)
            end)
        end
    end

    if lookThing and not lookThing:isCreature() and not lookThing:isNotMoveable() and lookThing:isPickupable() then
        menu:addSeparator()
        menu:addOption(tr('Trade with ...'), function()
            startTradeWith(lookThing)
        end)
    end

    if lookThing then
        local parentContainer = lookThing:getParentContainer()
        if parentContainer and parentContainer:hasParent() then
            menu:addOption(tr('Move up'), function()
                g_game.moveToParentContainer(lookThing, lookThing:getCount())
            end)
        end
    end

    if creatureThing then
        local localPlayer = g_game.getLocalPlayer()
        menu:addSeparator()

        if creatureThing:isLocalPlayer() then
            menu:addOption(tr(g_game.getClientVersion() >= 1000 and "Customise Character" or "Set Outfit"), function()
                g_game.requestOutfit()
            end)

            if g_game.getFeature(GamePrey) then
                menu:addOption(tr('Prey Dialog'), function()
                    modules.game_prey.show()
                end)
            end

            if g_game.getFeature(GamePlayerMounts) then
                if not localPlayer:isMounted() then
                    menu:addOption(tr('Mount'), function()
                        localPlayer:mount()
                    end)
                else
                    menu:addOption(tr('Dismount'), function()
                        localPlayer:dismount()
                    end)
                end
            end

            if creatureThing:isPartyMember() then
                if creatureThing:isPartyLeader() then
                    if creatureThing:isPartySharedExperienceActive() then
                        menu:addOption(tr('Disable Shared Experience'), function()
                            g_game.partyShareExperience(false)
                        end)
                    else
                        menu:addOption(tr('Enable Shared Experience'), function()
                            g_game.partyShareExperience(true)
                        end)
                    end
                end
                menu:addOption(tr('Leave Party'), function()
                    g_game.partyLeave()
                end)
            end
        else
            local localPosition = localPlayer:getPosition()
            if not classic and not mobile then
                shortcut = '(Alt)'
            else
                shortcut = nil
            end
            if creatureThing:getPosition().z == localPosition.z then
                if g_game.getAttackingCreature() ~= creatureThing then
                    menu:addOption(tr('Attack'), function()
                        g_game.attack(creatureThing)
                    end, shortcut)
                else
                    menu:addOption(tr('Stop Attack'), function()
                        g_game.cancelAttack()
                    end, shortcut)
                end

                if g_game.getFollowingCreature() ~= creatureThing then
                    menu:addOption(tr('Follow'), function()
                        g_game.follow(creatureThing)
                    end)
                else
                    menu:addOption(tr('Stop Follow'), function()
                        g_game.cancelFollow()
                    end)
                end
            end

            if creatureThing:isPlayer() then
                menu:addSeparator()
                local creatureName = creatureThing:getName()
                menu:addOption(tr('Message to %s', creatureName), function()
                    g_game.openPrivateChannel(creatureName)
                end)
                if modules.game_console.getOwnPrivateTab() then
                    menu:addOption(tr('Invite to private chat'), function()
                        g_game.inviteToOwnChannel(creatureName)
                    end)
                    menu:addOption(tr('Exclude from private chat'), function()
                        g_game.excludeFromOwnChannel(creatureName)
                    end) -- [TODO] must be removed after message's popup labels been implemented
                end
                if not localPlayer:hasVip(creatureName) then
                    menu:addOption(tr('Add to VIP list'), function()
                        g_game.addVip(creatureName)
                    end)
                end

                if modules.game_console.isIgnored(creatureName) then
                    menu:addOption(tr('Unignore') .. ' ' .. creatureName, function()
                        modules.game_console.removeIgnoredPlayer(creatureName)
                    end)
                else
                    menu:addOption(tr('Ignore') .. ' ' .. creatureName, function()
                        modules.game_console.addIgnoredPlayer(creatureName)
                    end)
                end

                local localPlayerShield = localPlayer:getShield()
                local creatureShield = creatureThing:getShield()

                if localPlayerShield == ShieldNone or localPlayerShield == ShieldWhiteBlue then
                    if creatureShield == ShieldWhiteYellow then
                        menu:addOption(tr('Join %s\'s Party', creatureThing:getName()), function()
                            g_game.partyJoin(creatureThing:getId())
                        end)
                    else
                        menu:addOption(tr('Invite to Party'), function()
                            g_game.partyInvite(creatureThing:getId())
                        end)
                    end
                elseif localPlayerShield == ShieldWhiteYellow then
                    if creatureShield == ShieldWhiteBlue then
                        menu:addOption(tr('Revoke %s\'s Invitation', creatureThing:getName()), function()
                            g_game.partyRevokeInvitation(creatureThing:getId())
                        end)
                    end
                elseif localPlayerShield == ShieldYellow or localPlayerShield == ShieldYellowSharedExp or
                    localPlayerShield == ShieldYellowNoSharedExpBlink or localPlayerShield == ShieldYellowNoSharedExp then
                    if creatureShield == ShieldWhiteBlue then
                        menu:addOption(tr('Revoke %s\'s Invitation', creatureThing:getName()), function()
                            g_game.partyRevokeInvitation(creatureThing:getId())
                        end)
                    elseif creatureShield == ShieldBlue or creatureShield == ShieldBlueSharedExp or creatureShield ==
                        ShieldBlueNoSharedExpBlink or creatureShield == ShieldBlueNoSharedExp then
                        menu:addOption(tr('Pass Leadership to %s', creatureThing:getName()), function()
                            g_game.partyPassLeadership(creatureThing:getId())
                        end)
                    else
                        menu:addOption(tr('Invite to Party'), function()
                            g_game.partyInvite(creatureThing:getId())
                        end)
                    end
                end
            end
        end

        if modules.game_ruleviolation.hasWindowAccess() and creatureThing:isPlayer() then
            menu:addSeparator()
            menu:addOption(tr('Rule Violation'), function()
                modules.game_ruleviolation.show(creatureThing:getName())
            end)
        end

        menu:addSeparator()
        menu:addOption(tr('Copy Name'), function()
            g_window.setClipboardText(creatureThing:getName())
        end)
    end

    -- hooked menu options
    for _, category in pairs(hookedMenuOptions) do
        if not isMenuHookCategoryEmpty(category) then
            menu:addSeparator()
            for name, opt in pairs(category) do
                if opt and opt.condition(menuPosition, lookThing, useThing, creatureThing) then
                    menu:addOption(name, function()
                        opt.callback(menuPosition, lookThing, useThing, creatureThing)
                    end, opt.shortcut)
                end
            end
        end
    end

    if modules.game_bot and useThing and useThing:isItem() then
        menu:addSeparator()
        local useThingId = useThing:getId()
        menu:addOption("ID: " .. useThingId, function() g_window.setClipboardText(useThingId) end)
    end

    if g_game.getFeature(GameThingQuickLoot) and modules.game_quickloot and lookThing and not lookThing:isCreature() and lookThing:isPickupable() then
        local quickLoot = modules.game_quickloot.QuickLoot
        menu.addSeparator(menu)

        if lookThing:isContainer() then
            menu.addOption(menu, tr("Manage Loot Containers"), function()
                quickLoot.toggle()
            end)
        end

        local lootExists = quickLoot.lootExists(lookThing:getId())
        local optionText = lootExists and "Remove from" or "Add to"
        local actionFunction = lootExists and quickLoot.removeLootList or quickLoot.addLootList

        menu.addOption(menu, tr(optionText .. " loot list"), function()
            actionFunction(lookThing:getId())
        end)
    end

    menu:display(menuPosition)
end

function processMouseAction(menuPosition, mouseButton, autoWalkPos, lookThing, useThing, creatureThing, attackCreature)
    local keyboardModifiers = g_keyboard.getModifiers()

    if g_platform.isMobile() then
        if mouseButton == MouseRightButton then
            createThingMenu(menuPosition, lookThing, useThing, creatureThing)
            return true
        end
        local shortcut = modules.game_shortcuts.getShortcut()
        if shortcut == "look" then
            if lookThing then
                modules.game_shortcuts.resetShortcuts()
                g_game.look(lookThing)
                return true
            end
            return true
        elseif shortcut == "use" then
            if useThing then
                modules.game_shortcuts.resetShortcuts()
                if useThing:isContainer() then
                    if useThing:getParentContainer() then
                        g_game.open(useThing, useThing:getParentContainer())
                    else
                        g_game.open(useThing)
                    end
                    return true
                elseif useThing:isMultiUse() then
                    startUseWith(useThing)
                    return true
                else
                    g_game.use(useThing)
                    return true
                end
            end
            return true
        elseif shortcut == "attack" then
            if attackCreature and attackCreature ~= player then
                modules.game_shortcuts.resetShortcuts()
                g_game.attack(attackCreature)
                return true
            elseif creatureThing and creatureThing ~= player and creatureThing:getPosition().z == autoWalkPos.z then
                modules.game_shortcuts.resetShortcuts()
                g_game.attack(creatureThing)
                return true
            end
            return true
        elseif shortcut == "follow" then
            if attackCreature and attackCreature ~= player then
                modules.game_shortcuts.resetShortcuts()
                g_game.follow(attackCreature)
                return true
            elseif creatureThing and creatureThing ~= player and creatureThing:getPosition().z == autoWalkPos.z then
                modules.game_shortcuts.resetShortcuts()
                g_game.follow(creatureThing)
                return true
            end
            return true
        elseif not autoWalkPos and useThing then
            createThingMenu(menuPosition, lookThing, useThing, creatureThing)
            return true
        end
    elseif not modules.client_options.getOption('classicControl') then
        if keyboardModifiers == KeyboardNoModifier and mouseButton == MouseRightButton then
            createThingMenu(menuPosition, lookThing, useThing, creatureThing)
            return true
        elseif lookThing and keyboardModifiers == KeyboardShiftModifier and
            (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
            g_game.look(lookThing)
            return true
        elseif useThing and keyboardModifiers == KeyboardCtrlModifier and
            (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
            if useThing:isContainer() then
                if useThing:getParentContainer() then
                    g_game.open(useThing, useThing:getParentContainer())
                else
                    g_game.open(useThing)
                end
                return true
            elseif useThing:isMultiUse() then
                startUseWith(useThing)
                return true
            else
                g_game.use(useThing)
                return true
            end
            return true
        elseif useThing and useThing:isContainer() and keyboardModifiers == KeyboardCtrlShiftModifier and
            (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
            g_game.open(useThing)
            return true
        elseif attackCreature and g_keyboard.isAltPressed() and
            (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
            g_game.attack(attackCreature)
            return true
        elseif creatureThing and creatureThing:getPosition().z == autoWalkPos.z and g_keyboard.isAltPressed() and
            (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
            g_game.attack(creatureThing)
            return true
        end

        -- classic control
    else
        if useThing and keyboardModifiers == KeyboardNoModifier and mouseButton == MouseRightButton and
            not g_mouse.isPressed(MouseLeftButton) then
            local player = g_game.getLocalPlayer()
            if attackCreature and attackCreature ~= player then
                g_game.attack(attackCreature)
                return true
            elseif creatureThing and creatureThing ~= player and creatureThing:getPosition().z == autoWalkPos.z then
                g_game.attack(creatureThing)
                return true
            elseif useThing:isContainer() then
                if useThing:getParentContainer() then
                    g_game.open(useThing, useThing:getParentContainer())
                    return true
                else
                    g_game.open(useThing)
                    return true
                end
            elseif useThing:isMultiUse() then
                startUseWith(useThing)
                return true
            else
                g_game.use(useThing)
                return true
            end
            return true
        elseif useThing and useThing:isContainer() and keyboardModifiers == KeyboardCtrlShiftModifier and
            (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
            g_game.open(useThing)
            return true
        elseif lookThing and keyboardModifiers == KeyboardShiftModifier and
            (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
            g_game.look(lookThing)
            return true
        elseif lookThing and ((g_mouse.isPressed(MouseLeftButton) and mouseButton == MouseRightButton) or
                (g_mouse.isPressed(MouseRightButton) and mouseButton == MouseLeftButton)) then
            g_game.look(lookThing)
            return true
        elseif useThing and keyboardModifiers == KeyboardCtrlModifier and
            (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
            createThingMenu(menuPosition, lookThing, useThing, creatureThing)
            return true
        elseif attackCreature and g_keyboard.isAltPressed() and
            (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
            g_game.attack(attackCreature)
            return true
        elseif creatureThing and creatureThing:getPosition().z == autoWalkPos.z and g_keyboard.isAltPressed() and
            (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
            g_game.attack(creatureThing)
            return true
        end
    end

    local player = g_game.getLocalPlayer()
    player:stopAutoWalk()

    if autoWalkPos and keyboardModifiers == KeyboardNoModifier and mouseButton == MouseLeftButton then
        player:autoWalk(autoWalkPos)
        if g_game.isAttacking() and g_game.getChaseMode() == ChaseOpponent then
            g_game.setChaseMode(DontChase)
            return true
        end
        return true
    end

    return false
end

function moveStackableItem(item, toPos)
    if countWindow then
        return
    end
    if g_keyboard.isShiftPressed() then
        g_game.move(item, toPos, 1)
        return
    elseif g_keyboard.isCtrlPressed() ~= modules.client_options.getOption('moveStack') then
        g_game.move(item, toPos, item:getCount())
        return
    end
    local count = item:getCount()

    countWindow = g_ui.createWidget('CountWindow', rootWidget)
    local itembox = countWindow:getChildById('item')
    local scrollbar = countWindow:getChildById('countScrollBar')
    itembox:setItemId(item:getId())
    itembox:setItemCount(count)
    scrollbar:setMaximum(count)
    scrollbar:setMinimum(1)
    scrollbar:setValue(count)

    local spinbox = countWindow:getChildById('spinBox')
    spinbox:setMaximum(count)
    spinbox:setMinimum(0)
    spinbox:setValue(0)
    spinbox:hideButtons()
    spinbox:focus()
    spinbox.firstEdit = true

    local spinBoxValueChange = function(self, value)
        spinbox.firstEdit = false
        scrollbar:setValue(value)
    end
    spinbox.onValueChange = spinBoxValueChange

    local check = function()
        if spinbox.firstEdit then
            spinbox:setValue(spinbox:getMaximum())
            spinbox.firstEdit = false
        end
    end
    g_keyboard.bindKeyPress('Up', function()
        check()
        spinbox:upSpin()
    end, spinbox)
    g_keyboard.bindKeyPress('Down', function()
        check()
        spinbox:downSpin()
    end, spinbox)
    g_keyboard.bindKeyPress('Right', function()
        check()
        spinbox:upSpin()
    end, spinbox)
    g_keyboard.bindKeyPress('Left', function()
        check()
        spinbox:downSpin()
    end, spinbox)
    g_keyboard.bindKeyPress('PageUp', function()
        check()
        spinbox:setValue(spinbox:getValue() + 10)
    end, spinbox)
    g_keyboard.bindKeyPress('PageDown', function()
        check()
        spinbox:setValue(spinbox:getValue() - 10)
    end, spinbox)

    scrollbar.onValueChange = function(self, value)
        itembox:setItemCount(value)
        spinbox.onValueChange = nil
        spinbox:setValue(value)
        spinbox.onValueChange = spinBoxValueChange
    end

    local okButton = countWindow:getChildById('buttonOk')
    local moveFunc = function()
        g_game.move(item, toPos, itembox:getItemCount())
        okButton:getParent():destroy()
        countWindow = nil
        modules.game_hotkeys.enableHotkeys(true)
    end
    local cancelButton = countWindow:getChildById('buttonCancel')
    local cancelFunc = function()
        cancelButton:getParent():destroy()
        countWindow = nil
        modules.game_hotkeys.enableHotkeys(true)
    end

    countWindow.onEnter = moveFunc
    countWindow.onEscape = cancelFunc

    okButton.onClick = moveFunc
    cancelButton.onClick = cancelFunc

    modules.game_hotkeys.enableHotkeys(false)
end

function onSelectPanel(self, checked)
    if checked then
        for k, v in pairs(panelsList) do
            if v.checkbox == self then
                gameSelectedPanel = v.panel
                break
            end
        end
    end
end

function getRootPanel()
    return gameRootPanel
end

function getMapPanel()
    return gameMapPanel
end

function getRightPanel()
    return gameRightPanel
end

function getMainRightPanel()
    return gameMainRightPanel
end

function getLeftPanel()
    return gameLeftPanel
end

function getRightExtraPanel()
    return gameRightExtraPanel
end

function getLeftExtraPanel()
    return gameLeftExtraPanel
end

function getSelectedPanel()
    return gameSelectedPanel
end

function getBottomPanel()
    return gameBottomPanel
end

function getShowTopMenuButton()
    return showTopMenuButton
end

function getGameTopStatsBar()
    return gameTopPanel
end

function getGameBottomStatsBar()
    return gameBottomStatsBarPanel
end

function getGameMapPanel()
    return gameMapPanel
end

function findContentPanelAvailable(child, minContentHeight)
    if gameSelectedPanel and gameSelectedPanel:isVisible() and gameSelectedPanel:fits(child, minContentHeight, 0) >= 0 then
        return gameSelectedPanel
    end

    for k, v in pairs(panelsList) do
        if v.panel ~= gameSelectedPanel and v.panel:isVisible() and v.panel:fits(child, minContentHeight, 0) >= 0 then
            return v.panel
        end
    end

    return gameSelectedPanel
end

function nextViewMode()
    setupViewMode((currentViewMode + 1) % 3)
end

function setupViewMode(mode)
    if mode == currentViewMode then
        return
    end

    leftIncreaseSidePanels:setEnabled(not modules.client_options.getOption('showLeftExtraPanel'))
    if g_platform.isMobile() then
        leftDecreaseSidePanels:setEnabled(false)
    else
        leftDecreaseSidePanels:setEnabled(true)
    end
    rightIncreaseSidePanels:setEnabled(not modules.client_options.getOption('showRightExtraPanel'))
    rightDecreaseSidePanels:setEnabled(modules.client_options.getOption('showRightExtraPanel'))

    if g_platform.isMobile() then
        gameRightPanel:setMarginBottom(mobileConfig.mobileHeightShortcuts)
        gameLeftPanel:setMarginBottom(mobileConfig.mobileHeightJoystick)
    end

    if currentViewMode == 2 then
        gameMapPanel:addAnchor(AnchorLeft, 'gameLeftPanel', AnchorRight)
        gameMapPanel:addAnchor(AnchorRight, 'gameRightPanel', AnchorLeft)
        gameMapPanel:addAnchor(AnchorRight, 'gameRightExtraPanel', AnchorLeft)
        gameMapPanel:addAnchor(AnchorBottom, 'gameBottomPanel', AnchorTop)
        gameRootPanel:addAnchor(AnchorTop, 'parent', AnchorTop)
        gameLeftPanel:setOn(modules.client_options.getOption('showLeftPanel'))
        gameRightExtraPanel:setOn(modules.client_options.getOption('showRightExtraPanel'))
        gameLeftExtraPanel:setOn(modules.client_options.getOption('showLeftExtraPanel'))
        gameLeftPanel:setImageColor('white')
        gameRightPanel:setImageColor('white')
        gameRightExtraPanel:setImageColor('white')
        gameLeftExtraPanel:setImageColor('white')
        gameLeftPanel:setMarginTop(0)
        gameRightPanel:setMarginTop(0)
        gameRightExtraPanel:setMarginTop(0)
        gameLeftExtraPanel:setMarginTop(0)
        gameBottomPanel:setImageColor('white')
        if g_platform.isMobile() then
            gameRightPanel:setMarginBottom(mobileConfig.mobileHeightShortcuts)
            gameLeftPanel:setMarginBottom(mobileConfig.mobileHeightJoystick)
        end
    end

    if mode == 0 then
        gameMapPanel:setKeepAspectRatio(true)
        gameMapPanel:setLimitVisibleRange(false)
        gameMapPanel:setZoom(11)
        gameMapPanel:setVisibleDimension({
            width = 15,
            height = 11
        })
        if g_platform.isMobile() then
            gameRightPanel:setMarginBottom(mobileConfig.mobileHeightShortcuts)
            gameLeftPanel:setMarginBottom(mobileConfig.mobileHeightJoystick)
        end
    elseif mode == 1 then
        gameMapPanel:setKeepAspectRatio(false)
        gameMapPanel:setLimitVisibleRange(true)
        gameMapPanel:setZoom(11)
        gameMapPanel:setVisibleDimension({
            width = 15,
            height = 11
        })
        if g_platform.isMobile() then
            gameRightPanel:setMarginBottom(mobileConfig.mobileHeightShortcuts)
            gameLeftPanel:setMarginBottom(mobileConfig.mobileHeightJoystick)
        end
    elseif mode == 2 then
        local limit = limitedZoom and not g_game.isGM()
        gameMapPanel:setLimitVisibleRange(limit)
        gameMapPanel:setZoom(11)
        gameMapPanel:setVisibleDimension({
            width = 15,
            height = 11
        })
        gameMapPanel:fill('parent')
        gameRootPanel:fill('parent')
        gameLeftPanel:setImageColor('alpha')
        gameRightPanel:setImageColor('alpha')
        gameRightExtraPanel:setImageColor('alpha')
        gameLeftExtraPanel:setImageColor('alpha')
        gameLeftPanel:setOn(true)
        gameLeftPanel:setVisible(true)
        gameRightPanel:setOn(true)
        gameRightExtraPanel:setOn(false)
        gameRightExtraPanel:setVisible(false)
        gameLeftExtraPanel:setOn(false)
        gameLeftExtraPanel:setVisible(false)
        gameMapPanel:setOn(true)
        gameBottomPanel:setImageColor('#ffffff88')
        if g_platform.isMobile() then
            gameRightPanel:setMarginBottom(mobileConfig.mobileHeightShortcuts)
            gameLeftPanel:setMarginBottom(mobileConfig.mobileHeightJoystick)
        end
    end

    currentViewMode = mode
    testExtendedView(mode)
end

function limitZoom()
    limitedZoom = true
end

function updateStatsBar(dimension, placement)
    StatsBar.updateCurrentStats(dimension, placement)
    StatsBar.updateStatsBarOption()
end

function onIncreaseLeftPanels()
    leftDecreaseSidePanels:setEnabled(true)
    if not modules.client_options.getOption('showLeftPanel') then
        modules.client_options.setOption('showLeftPanel', true)
        return
    end

    if not modules.client_options.getOption('showLeftExtraPanel') then
        modules.client_options.setOption('showLeftExtraPanel', true)
        leftIncreaseSidePanels:setEnabled(false)
        return
    end
end

local function movePanel(mainpanel)
    for _, widget in pairs(mainpanel:getChildren()) do
        if widget then
            local panel = modules.game_interface.findContentPanelAvailable(widget, widget:getMinimumHeight())
            if panel then
                if not panel:hasChild(widget) then
                    widget:close()
                    panel:addChild(widget)
                else
                    print("Error: Attempt to add a widget that already exists in the target panel")
                end
            else
                print("Warning: No suitable panel found for widget, unable to move")
            end
        end
    end
end

function onDecreaseLeftPanels()
    leftIncreaseSidePanels:setEnabled(true)
    if modules.client_options.getOption('showLeftExtraPanel') then
        modules.client_options.setOption('showLeftExtraPanel', false)
        movePanel(gameLeftExtraPanel)
        if g_platform.isMobile() then
            leftDecreaseSidePanels:setEnabled(false)
        end
        return
    end

    if not g_platform.isMobile() then
        if modules.client_options.getOption('showLeftPanel') then
            modules.client_options.setOption('showLeftPanel', false)
            movePanel(gameLeftPanel)
            leftDecreaseSidePanels:setEnabled(false)
            return
        end
    end
end

function onIncreaseRightPanels()
    rightIncreaseSidePanels:setEnabled(false)
    rightDecreaseSidePanels:setEnabled(true)
    modules.client_options.setOption('showRightExtraPanel', true)
end

function onDecreaseRightPanels()
    rightIncreaseSidePanels:setEnabled(true)
    rightDecreaseSidePanels:setEnabled(false)
    movePanel(gameRightExtraPanel)
    modules.client_options.setOption('showRightExtraPanel', false)
end

function setupOptionsMainButton()
    if logOutMainButton then
        return
    end

    logOutMainButton = modules.game_mainpanel.addSpecialToggleButton('logoutButton', tr('Exit'),
        '/images/options/button_logout',
        tryLogout)
end

function checkAndOpenLeftPanel()
    leftDecreaseSidePanels:setEnabled(true)
    if not modules.client_options.getOption('showLeftPanel') then
        modules.client_options.setOption('showLeftPanel', true)
        return
    end
end

function testExtendedView(mode)
    local extendedView = mode == 2
    if extendedView then
        local buttons = {leftIncreaseSidePanels, rightIncreaseSidePanels, rightDecreaseSidePanels,
                         leftDecreaseSidePanels}
        for _, button in ipairs(buttons) do
            button:hide()
        end

        if not g_platform.isMobile() then
            gameBottomPanel:breakAnchors()
            gameBottomPanel:bindRectToParent()
            gameBottomPanel:setDraggable(true)
        else
            gameBottomPanel:setWidth(g_window.getWidth() - mobileConfig.mobileWidthJoystick - mobileConfig.mobileWidthShortcuts)
            gameBottomPanel:setPosition({
                x = mobileConfig.mobileWidthJoystick,
                y = gameBottomPanel:getY()
            })
        end
        gameBottomPanel:getChildById('rightResizeBorder'):setMaximum(gameBottomPanel:getWidth())
        gameBottomPanel:getChildById('bottomResizeBorder'):enable()
        gameBottomPanel:getChildById('rightResizeBorder'):enable()
        bottomSplitter:setVisible(false)

        gameMainRightPanel:setHeight(0)
        gameMainRightPanel:setImageColor('alpha')

    else
        -- Reset to normal view
        gameMainRightPanel:setHeight(200)
        gameMainRightPanel:setMarginTop(0)
        gameMainRightPanel:setImageColor('white')

        local buttons = {leftIncreaseSidePanels, rightIncreaseSidePanels, rightDecreaseSidePanels,
                         leftDecreaseSidePanels}

        for _, button in ipairs(buttons) do
            button:setMarginTop(0)
            button:show()
        end

        -- Reset bottom panel
        gameBottomPanel:setDraggable(false)

        bottomSplitter:setVisible(true)

        -- Set anchors
        if not g_platform.isMobile() then
            gameBottomPanel:breakAnchors()
            gameBottomPanel:addAnchor(AnchorLeft, 'gameLeftExtraPanel', AnchorRight)
            gameBottomPanel:addAnchor(AnchorRight, 'gameRightExtraPanel', AnchorLeft)
            gameBottomPanel:addAnchor(AnchorTop, 'gameBottomStatsBarPanel', AnchorBottom)
            gameBottomPanel:addAnchor(AnchorBottom, 'parent', AnchorBottom)
        end
        gameBottomPanel:getChildById('bottomResizeBorder'):disable()
        gameBottomPanel:getChildById('rightResizeBorder'):disable()

        -- Move children back to gameMainRightPanel
        local children = gameRightPanel:getChildren()
        for _, child in ipairs(children) do
            if child.moveOnlyToMain then
                child:setParent(gameMainRightPanel)
            end
        end
    end
    addEvent(function()
        modules.game_console.setExtendedView(extendedView)
        modules.game_minimap.extendedView(extendedView)
        modules.game_healthinfo.extendedView(extendedView)
        modules.game_inventory.extendedView(extendedView)
        modules.client_topmenu.extendedView(extendedView)
        modules.game_mainpanel.toggleExtendedViewButtons(extendedView)
    end)
end

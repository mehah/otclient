MessageSettings = {
    none = {},
    consoleRed = {
        color = TextColors.red,
        consoleTab = 'ChatChannelNameDefault'
    },
    consoleOrange = {
        color = TextColors.orange,
        consoleTab = 'ChatChannelNameDefault'
    },
    consoleBlue = {
        color = TextColors.blue,
        consoleTab = 'ChatChannelNameDefault'
    },
    centerRed = {
        color = TextColors.red,
        consoleTab = 'ChatChannelNameServerLog',
        screenTarget = 'lowCenterLabel'
    },
    centerGreen = {
        color = TextColors.green,
        consoleTab = 'ChatChannelNameServerLog',
        screenTarget = 'highCenterLabel',
        consoleOption = 'showInfoMessagesInConsole'
    },
    centerWhite = {
        color = TextColors.white,
        consoleTab = 'ChatChannelNameServerLog',
        screenTarget = 'middleCenterLabel',
        consoleOption = 'showEventMessagesInConsole'
    },
    bottomWhite = {
        color = TextColors.white,
        consoleTab = 'ChatChannelNameServerLog',
        screenTarget = 'statusLabel',
        consoleOption = 'showEventMessagesInConsole'
    },
    status = {
        color = TextColors.white,
        consoleTab = 'ChatChannelNameServerLog',
        screenTarget = 'statusLabel',
        consoleOption = 'showStatusMessagesInConsole'
    },
    othersStatus = {
        color = TextColors.white,
        consoleTab = 'ChatChannelNameServerLog',
        consoleOption = 'showOthersStatusMessagesInConsole'
    },
    statusSmall = {
        color = TextColors.white,
        screenTarget = 'statusLabel'
    },
    private = {
        color = TextColors.lightblue,
        screenTarget = 'privateLabel'
    },
    loot = {
        color = TextColors.white,
        consoleTab = 'ChatChannelNameLoot',
        screenTarget = 'highCenterLabel',
        consoleOption = 'showInfoMessagesInConsole'
    }
}

MessageTypes = {
    [MessageModes.MonsterSay] = MessageSettings.consoleOrange,
    [MessageModes.MonsterYell] = MessageSettings.consoleOrange,
    [MessageModes.BarkLow] = MessageSettings.consoleOrange,
    [MessageModes.BarkLoud] = MessageSettings.consoleOrange,
    [MessageModes.Failure] = MessageSettings.statusSmall,
    [MessageModes.Login] = MessageSettings.bottomWhite,
    [MessageModes.Game] = MessageSettings.centerWhite,
    [MessageModes.Status] = MessageSettings.status,
    [MessageModes.Warning] = MessageSettings.centerRed,
    [MessageModes.Look] = MessageSettings.centerGreen,
    [MessageModes.Loot] = MessageSettings.loot,
    [MessageModes.Red] = MessageSettings.consoleRed,
    [MessageModes.Blue] = MessageSettings.consoleBlue,
    [MessageModes.PrivateFrom] = MessageSettings.consoleBlue,

    [MessageModes.GamemasterBroadcast] = MessageSettings.consoleRed,

    [MessageModes.DamageDealed] = MessageSettings.status,
    [MessageModes.DamageReceived] = MessageSettings.status,
    [MessageModes.Heal] = MessageSettings.status,
    [MessageModes.Exp] = MessageSettings.status,

    [MessageModes.DamageOthers] = MessageSettings.othersStatus,
    [MessageModes.HealOthers] = MessageSettings.othersStatus,
    [MessageModes.ExpOthers] = MessageSettings.othersStatus,
    [MessageModes.Potion] = MessageSettings.othersStatus,

    [MessageModes.TradeNpc] = MessageSettings.centerWhite,
    [MessageModes.Guild] = MessageSettings.centerWhite,
    [MessageModes.Party] = MessageSettings.centerGreen,
    [MessageModes.PartyManagement] = MessageSettings.centerWhite,
    [MessageModes.TutorialHint] = MessageSettings.centerWhite,
    [MessageModes.BeyondLast] = MessageSettings.centerWhite,
    [MessageModes.Report] = MessageSettings.consoleRed,
    [MessageModes.GameHighlight] = MessageSettings.centerRed,
    [MessageModes.HotkeyUse] = MessageSettings.centerGreen,
    [MessageModes.Attention] = MessageSettings.bottomWhite,
    [MessageModes.BoostedCreature] = MessageSettings.centerWhite,
    [MessageModes.OfflineTrainning] = MessageSettings.centerWhite,
    [MessageModes.Transaction] = MessageSettings.centerWhite,

    [254] = MessageSettings.private
}

messagesPanel = nil

function init()
    for messageMode, _ in pairs(MessageTypes) do
        registerMessageMode(messageMode, displayMessage)
    end

    connect(g_game, 'onGameEnd', clearMessages)
    messagesPanel = g_ui.loadUI('textmessage', modules.game_interface.getRootPanel())
end

function terminate()
    for messageMode, _ in pairs(MessageTypes) do
        unregisterMessageMode(messageMode, displayMessage)
    end

    disconnect(g_game, 'onGameEnd', clearMessages)
    clearMessages()
    messagesPanel:destroy()
    messagesPanel = nil
end

function calculateVisibleTime(text)
    return math.max(#text * 50, 4000)
end

function displayMessage(mode, text)

    if not g_game.isOnline() then
        return
    end

    local msgtype = MessageTypes[mode]
    if not msgtype then
        return
    end

    if msgtype == MessageSettings.none then
        return
    end

    if msgtype.consoleTab ~= nil and
        (msgtype.consoleOption == nil or modules.client_options.getOption(msgtype.consoleOption)) then
        modules.game_console.addText(text, msgtype, localize(msgtype.consoleTab))
        -- TODO move to game_console
    end

    if msgtype.screenTarget then
        local label = messagesPanel:recursiveGetChildById(msgtype.screenTarget)
        if msgtype == MessageSettings.loot then
            local coloredText = ItemsDatabase.setColorLootMessage(text)
            label:setColoredText(coloredText)
            local getTabServerLog = modules.game_console.consoleTabBar:getTabPanel(modules.game_console.serverTab)
            if getTabServerLog then
                getTabServerLog:getChildById('consoleBuffer'):getLastChild():setColoredText(coloredText)
            end
		else
            label:setText(text)
            label:setColor(msgtype.color)
        end
        label:setVisible(true)
        removeEvent(label.hideEvent)
        label.hideEvent = scheduleEvent(function()
            label:setVisible(false)
        end, calculateVisibleTime(text))
    end
end

function displayPrivateMessage(text)
    displayMessage(254, text)
end

function displayStatusMessage(text)
    displayMessage(MessageModes.Status, text)
end

function displayFailureMessage(text)
    displayMessage(MessageModes.Failure, text)
end

function displayGameMessage(text)
    displayMessage(MessageModes.Game, text)
end

function displayBroadcastMessage(text)
    displayMessage(MessageModes.Warning, text)
end

function clearMessages()
    for _i, child in pairs(messagesPanel:recursiveGetChildren()) do
        if child:getId():match('Label') then
            child:hide()
            removeEvent(child.hideEvent)
        end
    end
end

function LocalPlayer:onAutoWalkFail(player)
    modules.game_textmessage.displayFailureMessage(localize('ThereIsNoWay'))
end

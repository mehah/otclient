local deathTexts = {
    regular = {
        text = 'Alas! Brave adventurer, you have met a sad fate.\nBut do not despair, for the gods will bring you back\ninto this world in exchange for a small sacrifice\n\nClick on the button below to resume your journeys!',
        height = 140,
        width = 0
    },
    unfair = {
        text = 'Alas! Brave adventurer, you have met a sad fate.\nBut do not despair, for the gods will bring you back\ninto this world in exchange for a small sacrifice\n\nThis death penalty has been reduced by %i%%\nbecause it was an unfair fight.\n\nClick on the button below to resume your journeys!',
        height = 185,
        width = 0
    },
    blessed = {
        text = 'Alas! Brave adventurer, you have met a sad fate.\nBut do not despair, for the gods will bring you back into this world\n\nThis death penalty has been reduced by 100%\nbecause you are blessed with the Adventurer\'s Blessing\n\nClick on the button below to resume your journeys!',
        height = 170,
        width = 90
    }
}

controller = Controller:new()
controller:setUI('deathwindow')
function controller:onInit()
    controller:registerEvents(g_game, {
        onDeath = display,
        onGameEnd = reset
    })
end

function controller:onTerminate()
    reset()
end

function reset()
    if controller.ui then
        controller.ui:destroy()
        controller.ui = nil
    end
end

function display(deathType, penalty)
    displayDeadMessage()
    openWindow(deathType, penalty)
    scheduleReconnect()
end

function displayDeadMessage()
    local advanceLabel = modules.game_interface.getRootPanel():recursiveGetChildById('middleCenterLabel')
    if advanceLabel:isVisible() then
        return
    end

    modules.game_textmessage.displayGameMessage(tr('You are dead.'))
end

function openWindow(deathType, penalty)
    if controller.ui then
        controller.ui:destroy()
        return
    end

    controller.ui = g_ui.createWidget('DeathWindow', rootWidget)

    local textLabel = controller.ui:getChildById('labelText')
    if deathType == DeathType.Regular then
        if penalty == 100 then
            textLabel:setText(deathTexts.regular.text)
            controller.ui:setHeight(controller.ui.baseHeight + deathTexts.regular.height)
            controller.ui:setWidth(controller.ui.baseWidth + deathTexts.regular.width)
        else
            textLabel:setText(string.format(deathTexts.unfair.text, 100 - penalty))
            controller.ui:setHeight(controller.ui.baseHeight + deathTexts.unfair.height)
            controller.ui:setWidth(controller.ui.baseWidth + deathTexts.unfair.width)
        end
    elseif deathType == DeathType.Blessed then
        textLabel:setText(deathTexts.blessed.text)
        controller.ui:setHeight(controller.ui.baseHeight + deathTexts.blessed.height)
        controller.ui:setWidth(controller.ui.baseWidth + deathTexts.blessed.width)
    end

    local okButton = controller.ui:getChildById('buttonOk')

    local okFunc = function()
        CharacterList.doLogin()
        okButton:getParent():destroy()
        controller.ui = nil
    end

    controller.ui.onEnter = okFunc
    controller.ui.onEscape = cancelFunc

    okButton.onClick = okFunc
end

function scheduleReconnect()
    if not g_settings.getBoolean('autoReconnect') then
        return
    end
    controller:scheduleEvent(function()
        if controller.ui then
            controller.ui:destroy()
            controller.ui = nil
        end
        g_game.cancelLogin()
        CharacterList.doLogin()
    end, 2000, 'scheduleAutoReconnect')
end

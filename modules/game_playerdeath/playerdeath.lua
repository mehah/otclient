local deathTexts = {
    regular = {
        text = 'DeathMessageRegular',
        height = 140,
        width = 0
    },
    unfair = {
        text = 'DeathMessageUnfair',
        height = 185,
        width = 0
    },
    blessed = {
        text = 'DeathMessageBlessed',
        height = 170,
        width = 90
    }
}

deathController = Controller:new()
deathController:setUI('deathwindow')
function deathController:onInit()
    deathController:registerEvents(g_game, {
        onDeath = display,
        onGameEnd = reset
    })
end

function deathController:onTerminate()
    reset()
end

function reset()
    if deathController.ui then
        deathController.ui:destroy()
        deathController.ui = nil
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

    modules.game_textmessage.displayGameMessage(localize('DeathWindowTitle') .. ".")
end

function openWindow(deathType, penalty)
    if deathController.ui then
        deathController.ui:destroy()
        return
    end

    deathController.ui = g_ui.createWidget('DeathWindow', rootWidget)

    local textLabel = deathController.ui:getChildById('labelText')
    if deathType == DeathType.Regular then
        if penalty == 100 then
            textLabel:setText(localize(deathTexts.regular.text))
            deathController.ui:setHeight(deathController.ui.baseHeight + deathTexts.regular.height)
            deathController.ui:setWidth(deathController.ui.baseWidth + deathTexts.regular.width)
        else
            textLabel:setText(localize(deathTexts.unfair.text, 100 - penalty))
            deathController.ui:setHeight(deathController.ui.baseHeight + deathTexts.unfair.height)
            deathController.ui:setWidth(deathController.ui.baseWidth + deathTexts.unfair.width)
        end
    elseif deathType == DeathType.Blessed then
        textLabel:setText(localize(deathTexts.blessed.text))
        deathController.ui:setHeight(deathController.ui.baseHeight + deathTexts.blessed.height)
        deathController.ui:setWidth(deathController.ui.baseWidth + deathTexts.blessed.width)
    end

    local okButton = deathController.ui:getChildById('buttonOk')
    local cancelButton = deathController.ui:getChildById('buttonCancel')

    local okFunc = function()
        CharacterList.doLogin()
        okButton:getParent():destroy()
        deathController.ui = nil
    end
    local cancelFunc = function()
        g_game.safeLogout()
        cancelButton:getParent():destroy()
        deathController.ui = nil
    end

    deathController.ui.onEnter = okFunc
    deathController.ui.onEscape = cancelFunc

    okButton.onClick = okFunc
    cancelButton.onClick = cancelFunc
end

function scheduleReconnect()
    if not g_settings.getBoolean('autoReconnect') then
        return
    end
    deathController:scheduleEvent(function()
        if deathController.ui then
            deathController.ui:destroy()
            deathController.ui = nil
        end
        g_game.cancelLogin()
        CharacterList.doLogin()
    end, 2000, 'scheduleAutoReconnect')
end

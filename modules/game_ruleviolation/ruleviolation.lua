rvreasons = {}
rvreasons[1] = localize('RuleViolationRule1a')
rvreasons[2] = localize('RuleViolationRule1b')
rvreasons[3] = localize('RuleViolationRule1c')
rvreasons[4] = localize('RuleViolationRule1d')
rvreasons[5] = localize('RuleViolationRule2a')
rvreasons[6] = localize('RuleViolationRule2b')
rvreasons[7] = localize('RuleViolationRule2c')
rvreasons[8] = localize('RuleViolationRule2d')
rvreasons[9] = localize('RuleViolationRule2e')
rvreasons[10] = localize('RuleViolationRule2f')
rvreasons[11] = localize('RuleViolationRule3a')
rvreasons[12] = localize('RuleViolationRule3b')
rvreasons[13] = localize('RuleViolationRule3c')
rvreasons[14] = localize('RuleViolationRule3d')
rvreasons[15] = localize('RuleViolationRule3e')
rvreasons[16] = localize('RuleViolationRule3f')
rvreasons[17] = localize('RuleViolationRule4a')
rvreasons[18] = localize('RuleViolationRule4b')
rvreasons[19] = localize('RuleViolationRule4c')
rvreasons[20] = localize('RuleViolationDestructiveBehaviour')
rvreasons[21] = localize('RuleViolationExcessivePK')

rvactions = {}
rvactions[0] = localize('RuleViolationActionNote')
rvactions[1] = localize('RuleViolationActionNamelock')
rvactions[2] = localize('RuleViolationActionBan')
rvactions[3] = localize('RuleViolationActionBanPlusNamelock')
rvactions[4] = localize('RuleViolationActionBanPlusFinalWarning')
rvactions[5] = localize('RuleViolationActionBanPlusFinalPlusNamelock')
rvactions[6] = localize('RuleViolationActionReport')

ruleViolationWindow = nil
reasonsTextList = nil
actionsTextList = nil

function init()
    connect(g_game, {
        onGMActions = loadReasons
    })

    ruleViolationWindow = g_ui.displayUI('ruleviolation')
    ruleViolationWindow:setVisible(false)

    reasonsTextList = ruleViolationWindow:getChildById('reasonList')
    actionsTextList = ruleViolationWindow:getChildById('actionList')

    g_keyboard.bindKeyDown('Ctrl+U', function()
        show()
    end)

    if g_game.isOnline() then
        loadReasons()
    end
end

function terminate()
    disconnect(g_game, {
        onGMActions = loadReasons
    })
    g_keyboard.unbindKeyDown('Ctrl+U')

    ruleViolationWindow:destroy()
end

function hasWindowAccess()
    return reasonsTextList:getChildCount() > 0
end

function loadReasons()
    reasonsTextList:destroyChildren()
    actionsTextList:destroyChildren()

    local actions = g_game.getGMActions()
    for reason, actionFlags in pairs(actions) do
        local label = g_ui.createWidget('RVListLabel', reasonsTextList)
        label.onFocusChange = onSelectReason
        label:setText(rvreasons[reason])
        label.reasonId = reason
        label.actionFlags = actionFlags
    end

    if not hasWindowAccess() and ruleViolationWindow:isVisible() then
        hide()
    end
end

function show(target, statement)
    if g_game.isOnline() and hasWindowAccess() then
        if target then
            ruleViolationWindow:getChildById('nameText'):setText(target)
        end

        if statement then
            ruleViolationWindow:getChildById('statementText'):setText(statement)
        end

        ruleViolationWindow:show()
        ruleViolationWindow:raise()
        ruleViolationWindow:focus()
        ruleViolationWindow:getChildById('commentText'):focus()
    end
end

function hide()
    ruleViolationWindow:hide()
    clearForm()
end

function onSelectReason(reasonLabel, focused)
    if reasonLabel.actionFlags and focused then
        actionsTextList:destroyChildren()
        for actionBaseFlag = 0, #rvactions do
            local actionFlagString = rvactions[actionBaseFlag]
            if bit.band(reasonLabel.actionFlags, math.pow(2, actionBaseFlag)) > 0 then
                local label = g_ui.createWidget('RVListLabel', actionsTextList)
                label:setText(actionFlagString)
                label.actionId = actionBaseFlag
            end
        end
    end
end

function report()
    local reasonLabel = reasonsTextList:getFocusedChild()
    if not reasonLabel then
        displayErrorBox(localize('Error'), localize('RuleViolationNeedReason'))
        return
    end

    local actionLabel = actionsTextList:getFocusedChild()
    if not actionLabel then
        displayErrorBox(localize('Error'), localize('RuleViolationNeedAction'))
        return
    end

    local target = ruleViolationWindow:getChildById('nameText'):getText()
    local reason = reasonLabel.reasonId
    local action = actionLabel.actionId
    local comment = ruleViolationWindow:getChildById('commentText'):getText()
    local statement = ruleViolationWindow:getChildById('statementText'):getText()
    local statementId = 0 -- TODO: message unique id ?
    local ipBanishment = ruleViolationWindow:getChildById('ipBanCheckBox'):isChecked()
    if action == 6 and statement == '' then
        displayErrorBox(localize('Error'), localize('RuleViolationNeedStatement'))
    elseif comment == '' then
        displayErrorBox(localize('Error'), localize('RuleViolationNeedComment'))
    else
        g_game.reportRuleViolation(target, reason, action, comment, statement, statementId, ipBanishment)
        hide()
    end
end

function clearForm()
    ruleViolationWindow:getChildById('nameText'):clearText()
    ruleViolationWindow:getChildById('commentText'):clearText()
    ruleViolationWindow:getChildById('statementText'):clearText()
    ruleViolationWindow:getChildById('ipBanCheckBox'):setChecked(false)
end

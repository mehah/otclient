CharacterList = {}

-- private variables
local charactersWindow
local loadBox
local characterList
local errorBox
local waitingWindow
local updateWaitEvent
local resendWaitEvent
local loginEvent
local showOutfitsCheckbox

-- private functions
local function tryLogin(charInfo, tries)
    tries = tries or 1

    if tries > 50 then
        return
    end

    if g_game.isOnline() then
        if tries == 1 then
            g_game.safeLogout()
			if loginEvent then
				removeEvent(loginEvent)
				loginEvent = nil
			end
        end
        loginEvent = scheduleEvent(function()
            tryLogin(charInfo, tries + 1)
        end, 100)
        return
    end

    CharacterList.hide()

    g_game.loginWorld(G.account, G.password, charInfo.worldName, charInfo.worldHost, charInfo.worldPort,
                      charInfo.characterName, G.authenticatorToken, G.sessionKey)

    loadBox = displayCancelBox(tr('Please wait'), tr('Connecting to game server...'))
    connect(loadBox, {
        onCancel = function()
            loadBox = nil
            g_game.cancelLogin()
            CharacterList.show()
        end
    })

    -- save last used character
    g_settings.set('last-used-character', charInfo.characterName)
    g_settings.set('last-used-world', charInfo.worldName)
end

local function updateWait(timeStart, timeEnd)
    if waitingWindow then
        local time = g_clock.seconds()
        if time <= timeEnd then
            local percent = ((time - timeStart) / (timeEnd - timeStart)) * 100
            local timeStr = string.format('%.0f', timeEnd - time)

            local progressBar = waitingWindow:getChildById('progressBar')
            progressBar:setPercent(percent)

            local label = waitingWindow:getChildById('timeLabel')
            label:setText(tr('Trying to reconnect in %s seconds.', timeStr))

            updateWaitEvent = scheduleEvent(function()
                updateWait(timeStart, timeEnd)
            end, 1000 * progressBar:getPercentPixels() / 100 * (timeEnd - timeStart))
            return true
        end
    end

    if updateWaitEvent then
        updateWaitEvent:cancel()
        updateWaitEvent = nil
    end
end

local function resendWait()
    if waitingWindow then
        waitingWindow:destroy()
        waitingWindow = nil

        if updateWaitEvent then
            updateWaitEvent:cancel()
            updateWaitEvent = nil
        end

        if charactersWindow then
            local selected = characterList:getFocusedChild()
            if selected then
                local charInfo = {
                    worldHost = selected.worldHost,
                    worldPort = selected.worldPort,
                    worldName = selected.worldName,
                    characterName = selected.characterName,
                    characterLevel = selected.characterLevel,
                    main = selected.main,
                    dailyreward = selected.dailyreward,
                    hidden = selected.hidden,
                    outfitid = selected.outfitid,
                    headcolor = selected.headcolor,
                    torsocolor = selected.torsocolor,
                    legscolor = selected.legscolor,
                    detailcolor = selected.detailcolor,
                    addonsflags = selected.addonsflags,
                    characterVocation = selected.characterVocation
                }
                tryLogin(charInfo)
            end
        end
    end
end

local function onLoginWait(message, time)
    CharacterList.destroyLoadBox()

    waitingWindow = g_ui.displayUI('waitinglist')

    local label = waitingWindow:getChildById('infoLabel')
    label:setText(message)

    updateWaitEvent = scheduleEvent(function()
        updateWait(g_clock.seconds(), g_clock.seconds() + time)
    end, 0)
    resendWaitEvent = scheduleEvent(resendWait, time * 1000)
end

function onGameLoginError(message)
    CharacterList.destroyLoadBox()
    errorBox = displayErrorBox(tr('Login Error'), message)
    errorBox.onOk = function()
        errorBox = nil
        CharacterList.showAgain()
    end
end

function onGameSessionEnd(reason)
    CharacterList.destroyLoadBox()
    CharacterList.showAgain()
end

function onGameConnectionError(message, code)
    CharacterList.destroyLoadBox()
    local text = translateNetworkError(code, g_game.getProtocolGame() and g_game.getProtocolGame():isConnecting(),
                                       message)
    errorBox = displayErrorBox(tr('Connection Error'), text)
    errorBox.onOk = function()
        errorBox = nil
        CharacterList.showAgain()
    end
end

function onGameUpdateNeeded(signature)
    CharacterList.destroyLoadBox()
    errorBox = displayErrorBox(tr('Update needed'), tr('Enter with your account again to update your client.'))
    errorBox.onOk = function()
        errorBox = nil
        CharacterList.showAgain()
    end
end

-- public functions
function CharacterList.init()
    connect(g_game, {
        onLoginError = onGameLoginError
    })
    connect(g_game, {
        onSessionEnd = onGameSessionEnd
    })
    connect(g_game, {
        onUpdateNeeded = onGameUpdateNeeded
    })
    connect(g_game, {
        onConnectionError = onGameConnectionError
    })
    connect(g_game, {
        onGameStart = CharacterList.destroyLoadBox
    })
    connect(g_game, {
        onLoginWait = onLoginWait
    })
    connect(g_game, {
        onGameEnd = CharacterList.showAgain
    })

    if G.characters then
        CharacterList.create(G.characters, G.characterAccount)
    end
end

function CharacterList.terminate()
    disconnect(g_game, {
        onLoginError = onGameLoginError
    })
    disconnect(g_game, {
        onSessionEnd = onGameSessionEnd
    })
    disconnect(g_game, {
        onUpdateNeeded = onGameUpdateNeeded
    })
    disconnect(g_game, {
        onConnectionError = onGameConnectionError
    })
    disconnect(g_game, {
        onGameStart = CharacterList.destroyLoadBox
    })
    disconnect(g_game, {
        onLoginWait = onLoginWait
    })
    disconnect(g_game, {
        onGameEnd = CharacterList.showAgain
    })

    if charactersWindow then
        characterList = nil
        charactersWindow:destroy()
        charactersWindow = nil
    end

    if loadBox then
        g_game.cancelLogin()
        loadBox:destroy()
        loadBox = nil
    end

    if waitingWindow then
        waitingWindow:destroy()
        waitingWindow = nil
    end

    if updateWaitEvent then
        removeEvent(updateWaitEvent)
        updateWaitEvent = nil
    end

    if resendWaitEvent then
        removeEvent(resendWaitEvent)
        resendWaitEvent = nil
    end

    if loginEvent then
        removeEvent(loginEvent)
        loginEvent = nil
    end

    CharacterList = nil
end

function CharacterList.create(characters, account, otui)
    if not otui then
        otui = 'characterlist'
    end

    if charactersWindow then
        charactersWindow:destroy()
    end

    charactersWindow = g_ui.displayUI(otui)
    characterList = charactersWindow:getChildById('characters')

    -- characters
    G.characters = characters
    G.characterAccount = account

    showOutfitsCheckbox = charactersWindow:recursiveGetChildById('showOutfitsOnList')
    if g_settings.getBoolean('showOutfitsOnList') ~= showOutfitsCheckbox:isChecked() then
        showOutfitsCheckbox:setChecked(g_settings.getBoolean('showOutfitsOnList'))
    end
    characterList:destroyChildren()
    local accountStatusLabel = charactersWindow:getChildById('accountStatusLabel')

    local focusLabel
    local grade = 'alpha'
    for i, characterInfo in ipairs(characters) do
        local widget = g_ui.createWidget('CharacterWidget', characterList)
        if grade == 'alpha' then
            grade = '#484848ff'
        else
            grade = 'alpha'
        end
        widget.backgroundGradeColor = grade
        widget:setBackgroundColor(grade)
        widget.characterInfo = characterInfo
        widget.creature = widget:recursiveGetChildById('creature')
        widget.creatureBorder = widget.creature:getParent()
        for key, value in pairs(characterInfo) do
            local child

            -- Texts
            if key == 'name' then
                child = widget:getChildById('appearance')
            elseif key == 'level' then
                child = widget:getChildById('level')
            elseif key == 'vocation' then
                child = widget:getChildById('vocation')
            elseif key == 'worldName' then
                child = widget:getChildById('world')
            end
            if child then
                if key ~= 'name' then
                    child:getChildById('brightColumn'):setOn(true)
                else
                    child:getChildById('brightColumn'):setOn(false)
                end
                child.info = child:getChildById('info')
                child.info:setText(value)
                goto continue
            end

            -- Specials
            if key == 'dailyreward' then
                child = widget:getChildById('status')
                child:getChildById('brightColumn'):setOn(true)
                child.info = child:getChildById('info')
                child.info:setText("")
                child.icon = child:getChildById('daily')
                if value == 0 then
                    child.icon:setImageSource('/images/game/entergame/dailyreward_collected')
                    child.icon:setSpecialToolTip('Either you have already collected your daily reward or you have not reached main continent yet.')
                elseif value == 1 then
                    child.icon:setImageSource('/images/game/entergame/dailyreward_notcollected')
                    child.icon:setSpecialToolTip('Your daily reward has not been collected, yet.')
                else
                    child.icon:setImageSource('/images/game/entergame/dailyreward_deactivated')
                    child.icon:setSpecialToolTip('Daily rewards are deactivated on this gameworld.')
                end
                goto continue
            elseif key == 'main' then
                child = widget:getChildById('status')
                child:getChildById('brightColumn'):setOn(true)
                child.info = child:getChildById('info')
                child.info:setText("")
                goto continue
            end


            ::continue::
        end

        -- Appearances
        CharacterList.updateCharactersAppearance(widget, characterInfo, g_settings.getBoolean('showOutfitsOnList'))

        -- these are used by login
        widget.characterName = characterInfo.name
        widget.worldName = characterInfo.worldName
        widget.worldHost = characterInfo.worldIp
        widget.worldPort = characterInfo.worldPort

        connect(widget, {
            onDoubleClick = function()
                CharacterList.doLogin()
                return true
            end
        })

        if i == 1 or
            (g_settings.get('last-used-character') == widget.characterName and g_settings.get('last-used-world') ==
                widget.worldName) then
            focusLabel = widget
        end
    end

    if focusLabel then
        characterList:focusChild(focusLabel, KeyboardFocusReason)
        addEvent(function()
            characterList:ensureChildVisible(focusLabel)
        end)
    end

    -- account
    local status = ''
    if account.status == AccountStatus.Frozen then
        status = tr(' (Frozen)')
    elseif account.status == AccountStatus.Suspended then
        status = tr(' (Suspended)')
    end

    if account.subStatus == SubscriptionStatus.Free then
        accountStatusLabel:setText(('%s%s'):format(tr('Free Account'), status))
    elseif account.subStatus == SubscriptionStatus.Premium then
        if account.premDays == 0 or account.premDays >= 100 then
            accountStatusLabel:setText(('%s%s'):format(tr('Gratis Premium Account'), status))
        else
            accountStatusLabel:setText(('%s%s'):format(tr('Premium Account (%s) days left', account.premDays), status))
        end
    end

    if account.premDays > 0 and account.premDays <= 7 then
        accountStatusLabel:setOn(true)
    else
        accountStatusLabel:setOn(false)
    end
end

function CharacterList.destroy()
    CharacterList.hide(true)

    if charactersWindow then
        characterList = nil
        charactersWindow:destroy()
        charactersWindow = nil
    end
end

function CharacterList.show()
    if loadBox or errorBox or not charactersWindow then
        return
    end
    charactersWindow:show()
    charactersWindow:raise()
    charactersWindow:focus()
end

function CharacterList.hide(showLogin)
    showLogin = showLogin or false
    charactersWindow:hide()

    if showLogin and EnterGame and not g_game.isOnline() then
        EnterGame.show()
    end
end

function CharacterList.showAgain()
    if characterList and characterList:hasChildren() then
        CharacterList.show()
    end
end

function CharacterList.isVisible()
    if charactersWindow and charactersWindow:isVisible() then
        return true
    end
    return false
end

function CharacterList.doLogin()
    local selected = characterList:getFocusedChild()
    if selected then
        local charInfo = {
            worldHost = selected.worldHost,
            worldPort = selected.worldPort,
            worldName = selected.worldName,
            characterName = selected.characterName
        }
        charactersWindow:hide()
        if loginEvent then
            removeEvent(loginEvent)
            loginEvent = nil
        end
        tryLogin(charInfo)
    else
        displayErrorBox(tr('Error'), tr('You must select a character to login!'))
    end
end

function CharacterList.destroyLoadBox()
    if loadBox then
        loadBox:destroy()
        loadBox = nil
    end
end

function CharacterList.cancelWait()
    if waitingWindow then
        waitingWindow:destroy()
        waitingWindow = nil
    end

    if updateWaitEvent then
        removeEvent(updateWaitEvent)
        updateWaitEvent = nil
    end

    if resendWaitEvent then
        removeEvent(resendWaitEvent)
        resendWaitEvent = nil
    end

    CharacterList.destroyLoadBox()
    CharacterList.showAgain()
end

function CharacterList.updateCharactersAppearance(widget, character, showOutfits)
    if not showOutfits then
        widget.creature:hide()
        widget.creatureBorder:hide()
        widget.creatureBorder:setWidth(0)
        widget.creatureBorder:setHeight(0)
        widget.creatureBorder:setMarginLeft(0)
        widget.creatureBorder:setMarginTop(0)
        widget:setHeight(30)
        return
    end

    widget.creature:show()
    widget.creatureBorder:show()
    widget.creatureBorder:setWidth(64)
    widget.creatureBorder:setHeight(64)
    widget.creatureBorder:setMarginLeft(5)
    widget.creatureBorder:setMarginTop(3)
    widget:setHeight(66)

    local outfit = {
        type = character.outfitid,
        auxType = 0,
        addons = character.addonsflags,
        head = character.headcolor,
        body = character.torsocolor,
        legs = character.legscolor,
        feet = character.detailcolor
    }
    widget.creature:setOutfit(outfit)

    local type = g_things.getThingType(outfit.type, ThingCategoryCreature)
    if type then
        widget.creature:setMarginRight(type:getDisplacementX() * 2)
        widget.creature:setMarginBottom(type:getDisplacementY() * 1.5)
    end
end

function CharacterList.updateCharactersAppearances(showOutfits)
    if showOutfitsCheckbox and showOutfits ~= showOutfitsCheckbox:isChecked() then
        showOutfitsCheckbox:setChecked(showOutfits)
    end

    if not(characterList) or #(characterList:getChildren()) == 0 then
        return
    end

    for _, widget in ipairs(characterList:getChildren()) do
        if not widget.characterInfo then
            break
        end

        if not(widget.creature) or not(widget.creatureBorder) then
            widget.creature = widget:recursiveGetChildById('creature')
            widget.creatureBorder = widget.creature:getParent()
        end

        CharacterList.updateCharactersAppearance(widget, widget.characterInfo, showOutfits)
    end
end

EnterGame = {}

-- private variables
local loadBox
local enterGame
local protocolLogin

-- private functions
local function onError(protocol, message, errorCode)
    if loadBox then
        loadBox:destroy()
        loadBox = nil
    end

    if not errorCode then
        EnterGame.clearAccountFields()
    end

    local errorBox = displayErrorBox(tr('Login Error'), message)
    connect(errorBox, {
        onOk = EnterGame.show
    })
end

local function onSessionKey(protocol, sessionKey)
    G.sessionKey = sessionKey
end

local function onCharacterList(protocol, characters, account, otui)
    if enterGame:getChildById('rememberEmailBox'):isChecked() then
        local account = g_crypt.encrypt(G.account)

        g_settings.set('account', account)
    else
        EnterGame.clearAccountFields()
    end

    if loadBox ~= nil then
        loadBox:destroy()
        loadBox = nil
    end

    for _, characterInfo in pairs(characters) do
        if characterInfo.previewState and characterInfo.previewState ~= PreviewState.Default then
            characterInfo.worldName = characterInfo.worldName .. ', Preview'
        end
    end

    CharacterList.create(characters, account, otui)
    CharacterList.show()
end

local function onUpdateNeeded(protocol, signature)
    loadBox:destroy()
    loadBox = nil

    if EnterGame.updateFunc then
        local continueFunc = EnterGame.show
        local cancelFunc = EnterGame.show
        EnterGame.updateFunc(signature, continueFunc, cancelFunc)
    else
        local errorBox = displayErrorBox(tr('Update needed'), tr('Your client needs updating, try redownloading it.'))
        connect(errorBox, {
            onOk = EnterGame.show
        })
    end
end

-- public functions
function EnterGame.init()
    enterGame = g_ui.displayUI('entergame')
    g_keyboard.bindKeyDown('Ctrl+G', EnterGame.openWindow)

    local account = g_settings.get('account')
    local password = g_settings.get('password')

    EnterGame.setAccountName(account)
    EnterGame.setPassword(password)

    enterGame:hide()

    connect(g_game, {
        onGameStart = EnterGame.hidePanels
    })
    connect(g_game, {
        onGameEnd = EnterGame.showPanels
    })

    if g_app.isRunning() and not g_game.isOnline() then
        enterGame:show()
    end
end

function EnterGame.hidePanels()
    modules.client_bottommenu.hide()
    modules.client_topmenu.toggle()
end

function EnterGame.showPanels()
    modules.client_bottommenu.show()
    modules.client_topmenu.toggle()
end

function EnterGame.firstShow()
    EnterGame.show()
    EnterGame.postCacheInfo()
    EnterGame.postEventScheduler()
    EnterGame.postShowOff()
end

function EnterGame.terminate()
    g_keyboard.unbindKeyDown('Ctrl+G')
    disconnect(g_game, {
        onGameStart = EnterGame.hidePanels
    })
    disconnect(g_game, {
        onGameEnd = EnterGame.showPanels
    })

    enterGame:destroy()
    enterGame = nil
    if loadBox then
        loadBox:destroy()
        loadBox = nil
    end
    if protocolLogin then
        protocolLogin:cancelLogin()
        protocolLogin = nil
    end
    EnterGame = nil
end

function EnterGame.postCacheInfo()
    local onRecvInfo = function(message, err)
        if err then
            onError(nil, 'Bad Request.', 400)
            return
        end

        local _, bodyStart = message:find('{')
        local _, bodyEnd = message:find('.*}')
        if not bodyStart or not bodyEnd then
            onError(nil, 'Bad Request.', 400)
            return
        end

        local response = json.decode(message:sub(bodyStart, bodyEnd))
        if response.errorMessage then
            onError(nil, response.errorMessage, response.errorCode)
            return
        end

        modules.client_topmenu.setPlayersOnline(response.playersonline)
        modules.client_topmenu.setTwitchStreams(response.twitchstreams)
        modules.client_topmenu.setTwitchViewers(response.twitchviewer)
        modules.client_topmenu.setYoutubeStreams(response.gamingyoutubestreams)
        modules.client_topmenu.setYoutubeViewers(response.gamingyoutubeviewer)
    end

    HTTP.post(ClientHost.ip,
        json.encode({
            type = 'cacheinfo'
        }),
        onRecvInfo, false
    )
end

function EnterGame.postEventScheduler()
    local onRecvInfo = function(message, err)
        if err then
            onError(nil, 'Bad Request.', 400)
            return
        end

        local _, bodyStart = message:find('{')
        local _, bodyEnd = message:find('.*}')
        if not bodyStart or not bodyEnd then
            onError(nil, 'Bad Request.', 400)
            return
        end

        local response = json.decode(message:sub(bodyStart, bodyEnd))
        if response.errorMessage then
            onError(nil, response.errorMessage, response.errorCode)
            return
        end

        modules.client_bottommenu.setEventsSchedulerTimestamp(response.lastupdatetimestamp)
        modules.client_bottommenu.setEventsSchedulerCalender(response.eventlist)
    end

    HTTP.post(ClientHost.ip,
        json.encode({
            type = 'eventschedule'
        }),
        onRecvInfo, false
    )
end

function EnterGame.postShowOff()
    local onRecvInfo = function(message, err)
        if err then
            onError(nil, 'Bad Request.', 400)
            return
        end

        local _, bodyStart = message:find('{')
        local _, bodyEnd = message:find('.*}')
        if not bodyStart or not bodyEnd then
            onError(nil, 'Bad Request.', 400)
            return
        end

        local response = json.decode(message:sub(bodyStart, bodyEnd))
        if response.errorMessage then
            onError(nil, response.errorMessage, response.errorCode)
            return
        end

        modules.client_bottommenu.setShowOffData(response)
    end

    HTTP.post(ClientHost.ip,
        json.encode({
            type = 'showoff'
        }),
        onRecvInfo, false
    )
end

function EnterGame.show()
    if loadBox then
        return
    end
    enterGame:show()
    enterGame:raise()
    enterGame:focus()
end

function EnterGame.hide()
    enterGame:hide()
end

function EnterGame.openWindow()
    if g_game.isOnline() then
        CharacterList.show()
    elseif not g_game.isLogging() and not CharacterList.isVisible() then
        EnterGame.show()
    end
end

function EnterGame.setAccountName(account)
    local account = g_crypt.decrypt(account)
    enterGame:getChildById('accountNameTextEdit'):setText(account)
    enterGame:getChildById('accountNameTextEdit'):setCursorPos(-1)
    enterGame:getChildById('rememberEmailBox'):setChecked(#account > 0)
end

function EnterGame.setPassword(password)
    local password = g_crypt.decrypt(password)
    enterGame:getChildById('accountPasswordTextEdit'):setText(password)
end

function EnterGame.clearAccountFields()
    enterGame:getChildById('accountNameTextEdit'):clearText()
    enterGame:getChildById('accountPasswordTextEdit'):clearText()
    enterGame:getChildById('accountNameTextEdit'):focus()
    g_settings.remove('account')
    g_settings.remove('password')
end

function EnterGame.tryHttpLogin(clientVersion)
    -- http login server
    local onRecv = function(message, err)
        if err then
            onError(nil, 'Bad Request.', 400)
            return
        end

        local _, bodyStart = message:find('{')
        local _, bodyEnd = message:find('.*}')
        if not bodyStart or not bodyEnd then
            onError(nil, 'Bad Request.', 400)
            return
        end

        local response = json.decode(message:sub(bodyStart, bodyEnd))
        if response.errorMessage then
            onError(nil, response.errorMessage, response.errorCode)
            return
        end

        local worlds = {}
        for _, world in ipairs(response.playdata.worlds) do
            worlds[world.id] = {
                name = world.name,
                ip = world.externaladdress,
                port = world.externalport,
                previewState = world.previewstate == 1
            }
        end

        local characters = {}
        for index, character in ipairs(response.playdata.characters) do
            local world = worlds[character.worldid]
            characters[index] = {
                name = character.name,
                level = character.level,
                main = character.ismaincharacter,
                dailyreward = character.dailyrewardstate,
                hidden = character.ishidden,
                vocation = character.vocation,
                outfitid = character.outfitid,
                headcolor = character.headcolor,
                torsocolor = character.torsocolor,
                legscolor = character.legscolor,
                detailcolor = character.detailcolor,
                addonsflags = character.addonsflags,
                worldName = world.name,
                worldIp = world.ip,
                worldPort = world.port,
                previewState = world.previewstate
            }
        end

        local premiumUntil = tonumber(response.session.premiumuntil)

        local account = {
            status = '',
            premDays = math.floor((premiumUntil - os.time()) / 86400),
            subStatus = premiumUntil > os.time() and SubscriptionStatus.Premium or SubscriptionStatus.Free
        }

        -- set session key
        G.sessionKey = response.session.sessionkey

        onCharacterList(nil, characters, account)
    end

    HTTP.post(G.host,
        json.encode({
            email = G.account,
            password = G.password,
            type = 'login'
        }),
        onRecv, false
    )

    loadBox = displayCancelBox(tr('Please wait'), tr('Connecting to login server...'))
    connect(loadBox, {
        onCancel = function(msgbox)
            loadBox = nil
            EnterGame.show()
        end
    })

    g_game.setClientVersion(clientVersion)
    g_game.setProtocolVersion(g_game.getClientProtocolVersion(clientVersion))
    g_game.chooseRsa(G.host)
    if modules.game_things.isLoaded() then
    else
        loadBox:destroy()
        loadBox = nil
        EnterGame.show()
    end
end

function EnterGame.doLogin()
    G.account = enterGame:getChildById('accountNameTextEdit'):getText()
    G.password = enterGame:getChildById('accountPasswordTextEdit'):getText()
    G.authenticatorToken = ''
    G.stayLogged = ''
    G.host = ClientHost.ip
    G.port = ClientHost.port
    local clientVersion = ClientHost.version
    EnterGame.hide()

    if g_game.isOnline() then
        local errorBox = displayErrorBox(tr('Login Error'), tr('Cannot login while already in game.'))
        connect(errorBox, {
            onOk = EnterGame.show
        })
        return
    end

    g_settings.set('host', G.host)
    g_settings.set('port', G.port)
    g_settings.set('client-version', clientVersion)

    if clientVersion >= 1281 and G.port ~= 7171 then
        EnterGame.tryHttpLogin(clientVersion)
    else
        protocolLogin = ProtocolLogin.create()
        protocolLogin.onLoginError = onError
        protocolLogin.onSessionKey = onSessionKey
        protocolLogin.onCharacterList = onCharacterList
        protocolLogin.onUpdateNeeded = onUpdateNeeded

        loadBox = displayCancelBox(tr('Please wait'), tr('Connecting to login server...'))
        connect(loadBox, {
            onCancel = function(msgbox)
                loadBox = nil
                protocolLogin:cancelLogin()
                EnterGame.show()
            end
        })

        g_game.setClientVersion(clientVersion)
        g_game.setProtocolVersion(g_game.getClientProtocolVersion(clientVersion))
        g_game.chooseRsa(G.host)

        if modules.game_things.isLoaded() then
            protocolLogin:login(G.host, G.port, G.account, G.password, G.authenticatorToken, G.stayLogged)
        else
            loadBox:destroy()
            loadBox = nil
            EnterGame.show()
        end
    end
end

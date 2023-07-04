filename = nil
loaded = false

function init()
    connect(g_game, {
        onClientVersionChange = load
    })
end

function terminate()
    disconnect(g_game, {
        onClientVersionChange = load
    })
end

function setFileName(name)
    filename = name
end

function isLoaded()
    return loaded
end

function load(version)
    local errorMessage = ''

    if version >= 1281 and not g_game.getFeature(GameLoadSprInsteadProtobuf) then
        if not g_things.loadAppearances(resolvepath(string.format('/things/%d/', version))) then
            errorMessage = errorMessage .. 'Couldn\'t load assets'
        end
    else
        if g_game.getFeature(GameLoadSprInsteadProtobuf) then
            local warningBox = displayErrorBox(tr('Warning'),
                'Load spr instead protobuf it\'s unstable, use by yours risk!')
            addEvent(function()
                warningBox:raise()
                warningBox:focus()
            end)
        end
        local datPath, sprPath
        if filename then
            datPath = resolvepath('/data/things/' .. filename)
            sprPath = resolvepath('/data/things/' .. filename)
        else
            datPath = resolvepath('/data/things/' .. version .. '/Tibia')
            sprPath = resolvepath('/data/things/' .. version .. '/Tibia')
        end

        if not g_things.loadDat(datPath) then
            errorMessage = errorMessage ..
                tr('Unable to load dat file, please place a valid dat in \'%s.dat\'', datPath) .. '\n'
        end
        if not g_sprites.loadSpr(sprPath) then
            errorMessage = errorMessage ..
                tr('Unable to load spr file, please place a valid spr in \'%s.spr\'', sprPath)
        end
    end

    loaded = (errorMessage:len() == 0)

    if errorMessage:len() > 0 then
        local messageBox = displayErrorBox(tr('Error'), errorMessage)
        addEvent(function()
            messageBox:raise()
            messageBox:focus()
        end)

        disconnect(g_game, {
            onClientVersionChange = load
        })
        g_game.setClientVersion(0)
        g_game.setProtocolVersion(0)
        connect(g_game, {
            onClientVersionChange = load
        })
    end
end

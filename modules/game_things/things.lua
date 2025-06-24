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
    local errorList = {}

    if version >= 1281 and not g_game.getFeature(GameLoadSprInsteadProtobuf) then
        local filePath = resolvepath(string.format('/things/%d/', version))
        if not g_things.loadAppearances(filePath) then
            errorList[#errorList + 1] = "Couldn't load assets"
        end
        if not g_things.loadStaticData(filePath) then
            errorList[#errorList + 1] = "Couldn't load staticdata"
        end
    else
        local datPath, sprPath
        if filename then
            datPath = resolvepath('/data/things/' .. filename)
            sprPath = resolvepath('/data/things/' .. filename)
        else
            datPath = resolvepath('/data/things/' .. version .. '/Tibia')
            sprPath = resolvepath('/data/things/' .. version .. '/Tibia')
        end

        if not g_things.loadDat(datPath) then
            errorList[#errorList + 1] = tr('Unable to load dat file, please place a valid dat in \'%s.dat\'', datPath)
        end
        if not g_sprites.loadSpr(sprPath) then
            errorList[#errorList + 1] = tr('Unable to load spr file, please place a valid spr in \'%s.spr\'', sprPath)
        end
        if g_game.getFeature(GameLoadSprInsteadProtobuf) and version >= 1281 then
            local staticPath = resolvepath(string.format('/things/%d/appearances', version))
            if not g_things.loadAppearances(staticPath) then
                g_logger.warning(string.format("[game_things.load()] Couldn't load /things/%d/appearances.dat, possible packets error.", version))
            end
        end
    end

    loaded = #errorList == 0
    if loaded then
        -- loading client files was successful, try to load sounds now
        -- sound files are optional, this means that failing to load them
        -- will not block logging into game
        g_sounds.loadClientFiles(resolvepath(string.format('/sounds/%d/', version)))
        return
    end

    -- loading client files failed, show an error
    local messageBox = displayErrorBox(tr('Error'), table.concat(errorList, "\n"))
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

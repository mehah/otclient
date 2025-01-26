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
            errorList[#errorList + 1] = localize('ThingsAssetLoadingFailed')
        end
        if not g_things.loadStaticData(filePath) then
            errorList[#errorList + 1] = localize('ThingsStaticDataLoadingFailed')
        end
    else
        if g_game.getFeature(GameLoadSprInsteadProtobuf) then
            local warningBox = displayErrorBox(localize('Warning'),
                localize('ThingsProtocolSpritesWarning'))
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
            errorList[#errorList + 1] = localize('ThingsDatLoadingFailed', datPath)
        end
        if not g_sprites.loadSpr(sprPath) then
            errorList[#errorList + 1] = localize('ThingsSprLoadingFailed', sprPath)
        end
    end

    loaded = #errorList == 0

    if not loaded then
        local messageBox = displayErrorBox(localize('Error'), table.concat(errorList, "\n"))
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

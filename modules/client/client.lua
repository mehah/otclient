local musicFilename = '/sounds/startup'
local musicChannel = nil
if g_sounds then
    musicChannel = g_sounds.getChannel(SoundChannels.Music)
end

function setMusic(filename)
    musicFilename = filename

    if not g_game.isOnline() then
        musicChannel:stop()
        musicChannel:enqueue(musicFilename, 3)
    end
end

function startup()
    -- Play startup music (The Silver Tree, by Mattias Westlund)
    if musicChannel then
        musicChannel:enqueue(musicFilename, 3)
        connect(g_game, {
            onGameStart = function()
                musicChannel:stop(3)
            end
        })
        connect(g_game, {
            onGameEnd = function()
                g_sounds.stopAll()
                musicChannel:enqueue(musicFilename, 3)
            end
        })
    end

    -- Check for startup errors
    local errtitle = nil
    local errmsg = nil

    if g_graphics.getRenderer():lower():match('gdi generic') then
        errtitle = tr('Graphics card driver not detected')
        errmsg = tr(
                     'No graphics card detected, everything will be drawn using the CPU,\nthus the performance will be really bad.\nPlease update your graphics driver to have a better performance.')
    end

    -- Show entergame
    if errmsg or errtitle then
        local msgbox = displayErrorBox(errtitle, errmsg)
        msgbox.onOk = function()
            EnterGame.firstShow()
        end
    else
        EnterGame.firstShow()
    end
end

function init()
    connect(g_app, {
        onRun = startup,
        onExit = exit
    })

    g_window.setMinimumSize({
        width = 600,
        height = 480
    })
    if musicChannel then
        g_sounds.preload(musicFilename)
    end

    -- generate machine uuid, this is a security measure for storing passwords
    if not g_crypt.setMachineUUID(g_settings.get('uuid')) then
        g_settings.set('uuid', g_crypt.getMachineUUID())
        g_settings.save()
    end
end

function terminate()
    disconnect(g_app, {
        onRun = startup,
        onExit = exit
    })
    -- save window configs
    g_settings.set('window-size', g_window.getUnmaximizedSize())
    g_settings.set('window-pos', g_window.getUnmaximizedPos())
    g_settings.set('window-maximized', g_window.isMaximized())
end

function exit()
    g_logger.info('Exiting application..')
end

function init()
    connect(g_app, {
        onExit = exit
    })

    if g_platform.isMobile() then
        g_window.setMinimumSize({ width = 640, height = 360 })
    else
        g_window.setMinimumSize({ width = 800, height = 640 })
    end

    -- window size
    local size = { width = 1024, height = 600 }
    size = g_settings.getSize('window-size', size)
    g_window.resize(size)

    -- window position, default is the screen center
    local displaySize = g_window.getDisplaySize()
    local defaultPos = {
        x = (displaySize.width - size.width) / 2,
        y = (displaySize.height - size.height) / 2
    }
    local pos = g_settings.getPoint('window-pos', defaultPos)
    pos.x = math.max(pos.x, 0)
    pos.y = math.max(pos.y, 0)
    g_window.move(pos)

    -- window maximized?
    local maximized = g_settings.getBoolean('window-maximized', false)
    if maximized then g_window.maximize() end

    g_window.setTitle(g_app.getName())
    g_window.setIcon('/images/clienticon')

    -- poll resize events
    g_window.poll()

    -- generate machine uuid, this is a security measure for storing passwords
    if not g_crypt.setMachineUUID(g_settings.get('uuid')) then
        g_settings.set('uuid', g_crypt.getMachineUUID())
        g_settings.save()
    end
end

function terminate()
    disconnect(g_app, {
        onExit = exit
    })

    -- save window configs
    g_settings.set('window-size', g_window.getUnmaximizedSize())
    g_settings.set('window-pos', g_window.getUnmaximizedPos())
    g_settings.set('window-maximized', g_window.isMaximized())
    g_settings.save()
end

function exit()
    g_logger.info('Exiting application..')
end

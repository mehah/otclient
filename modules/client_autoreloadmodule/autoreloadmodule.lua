function init()
    if not AUTO_RELOAD_MODULE then
        return
    end

    for i, module in ipairs(g_modules.getModules()) do
        local id = live_module_reload(module)
    end
end

function live_module_reload(module)
    if not module:isReloadble() or not module:canReload() then
        return
    end

    local name = module:getName()

    local files = {}
    local hasFile = false
    for _, file in pairs(g_resources.listDirectoryFiles('/' .. name, true, false, true)) do
        local time = g_resources.getFileTime(file)
        if time > 0 then
            files[file] = time
            hasFile = true
        end
    end

    if not hasFile then
        pcolored('ERROR: unable to find any file for module(' .. name .. ')', 'red')
        return
    end

    return cycleEvent(function()
        for filepath, time in pairs(files) do
            local newtime = g_resources.getFileTime(filepath)
            if newtime > time then
                pcolored('Reloading ' .. name, 'green')
                modules.client_terminal.flushLines()
                module:reload()
                files[filepath] = newtime

                if name == 'client_terminal' then
                    modules.client_terminal.show()
                end
                break
            end
        end
    end, 1000)
end

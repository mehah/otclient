local WALK_STEPS_RETRY = 10

local firstStep = false
local smartWalkDirs = {}
local smartWalkDir = nil
local lastDirTime = g_clock.millis()
local lastManualWalk = 0

function init()
    connect(g_game, {
        onGameStart = onGameStart,
    }, true)

    bindKeys()
end

function terminate()
    disconnect(g_game, {
        onGameStart = onGameStart,
    })

    stopSmartWalk()
end

function onGameStart()
    modules.game_interface.getRootPanel().onFocusChange = stopSmartWalk

    modules.game_joystick.addOnJoystickMoveListener(function(dir, firstStep) 
        g_game.walk(dir, firstStep)
    end)

    -- open tibia has delay in auto walking
    if not g_game.isOfficialTibia() then
        g_game.enableFeature(GameForceFirstAutoWalkStep)
    else
        g_game.disableFeature(GameForceFirstAutoWalkStep)
    end
end

function bindKeys()
    modules.game_interface.getRootPanel():setAutoRepeatDelay(200)

    bindWalkKey('Up', North)
    bindWalkKey('Right', East)
    bindWalkKey('Down', South)
    bindWalkKey('Left', West)
    bindWalkKey('Numpad8', North)
    bindWalkKey('Numpad9', NorthEast)
    bindWalkKey('Numpad6', East)
    bindWalkKey('Numpad3', SouthEast)
    bindWalkKey('Numpad2', South)
    bindWalkKey('Numpad1', SouthWest)
    bindWalkKey('Numpad4', West)
    bindWalkKey('Numpad7', NorthWest)

    bindTurnKey('Ctrl+Up', North)
    bindTurnKey('Ctrl+Right', East)
    bindTurnKey('Ctrl+Down', South)
    bindTurnKey('Ctrl+Left', West)
    bindTurnKey('Ctrl+Numpad8', North)
    bindTurnKey('Ctrl+Numpad6', East)
    bindTurnKey('Ctrl+Numpad2', South)
    bindTurnKey('Ctrl+Numpad4', West)
end

function bindWalkKey(key, dir)
    g_keyboard.bindKeyDown(key, function()
        onWalkKeyDown(dir)
    end, modules.game_interface.getRootPanel(), true)
    g_keyboard.bindKeyUp(key, function()
        changeWalkDir(dir, true)
    end, modules.game_interface.getRootPanel(), true)
    g_keyboard.bindKeyPress(key, function()
        smartWalk(dir)
    end, modules.game_interface.getRootPanel())
end

function unbindWalkKey(key)
    g_keyboard.unbindKeyDown(key, modules.game_interface.getRootPanel())
    g_keyboard.unbindKeyUp(key, modules.game_interface.getRootPanel())
    g_keyboard.unbindKeyPress(key, modules.game_interface.getRootPanel())
end

function bindTurnKey(key, dir)
    local function callback(widget, code, repeatTicks)
        if g_clock.millis() - lastDirTime >= modules.client_options.getOption('turnDelay') then
            g_game.turn(dir)
            changeWalkDir(dir)

            lastDirTime = g_clock.millis()
        end
    end

    g_keyboard.bindKeyPress(key, callback, modules.game_interface.getRootPanel())
end

function unbindTurnKey(key)
    g_keyboard.unbindKeyPress(key, modules.game_interface.getRootPanel())
end

function stopSmartWalk()
    smartWalkDirs = {}
    smartWalkDir = nil
end

function onWalkKeyDown(dir)
    if modules.client_options.getOption('autoChaseOverride') then
        if g_game.isAttacking() and g_game.getChaseMode() == ChaseOpponent then
            g_game.setChaseMode(DontChase)
        end
    end
    firstStep = true
    changeWalkDir(dir)
end

function changeWalkDir(dir, pop)
    while table.removevalue(smartWalkDirs, dir) do
    end
    if pop then
        if #smartWalkDirs == 0 then
            stopSmartWalk()
            return
        end
    else
        table.insert(smartWalkDirs, 1, dir)
    end

    smartWalkDir = smartWalkDirs[1]
    if modules.client_options.getOption('smartWalk') and #smartWalkDirs > 1 then
        for _, d in pairs(smartWalkDirs) do
            if (smartWalkDir == North and d == West) or (smartWalkDir == West and d == North) then
                smartWalkDir = NorthWest
                break
            elseif (smartWalkDir == North and d == East) or (smartWalkDir == East and d == North) then
                smartWalkDir = NorthEast
                break
            elseif (smartWalkDir == South and d == West) or (smartWalkDir == West and d == South) then
                smartWalkDir = SouthWest
                break
            elseif (smartWalkDir == South and d == East) or (smartWalkDir == East and d == South) then
                smartWalkDir = SouthEast
                break
            end
        end
    end
end

function smartWalk(dir)
    if g_keyboard.getModifiers() ~= KeyboardNoModifier then
        return false
    end

    local dire = smartWalkDir or dir
    g_game.walk(dire, firstStep)
    firstStep = false

    lastManualWalk = g_clock.millis()
    return true
end

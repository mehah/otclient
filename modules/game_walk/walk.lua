local smartWalkDirs = {}
local smartWalkDir = nil
local walkEvent = nil
local lastTurn = 0
local nextWalkDir = nil

WalkController = Controller:new()

local function stopSmartWalk()
    smartWalkDirs = {}
    smartWalkDir = nil
end

local function cancelWalkEvent()
    if walkEvent then
        removeEvent(walkEvent)
        walkEvent = nil
    end

    nextWalkDir = nil
end

local function canChangeFloorDown(pos)
    pos.z = pos.z + 1
    local toTile = g_map.getTile(pos)
    return toTile and toTile:hasElevation(3)
end

local function canChangeFloorUp(pos)
    pos.z = pos.z - 1
    local toTile = g_map.getTile(pos)
    return toTile and toTile:isWalkable()
end

local function walk(dir)
    local player = g_game.getLocalPlayer()
    if not player or g_game.isDead() or player:isDead() then
        return
    end

    if player:isWalkLocked() then
        cancelWalkEvent()
        return
    end

    if not player:canWalk(dir) then
        nextWalkDir = dir
        return
    end

    if g_game.isFollowing() then
        g_game.cancelFollow()
    end

    if player:isAutoWalking() then
        player:stopAutoWalk()
        g_game.stop()
    end

    nextWalkDir = nil

    if g_game.getFeature(GameAllowPreWalk) then
        local toPos = Position.translatedToDirection(player:getPosition(), dir)
        local toTile = g_map.getTile(toPos)
        if toTile and toTile:isWalkable() then
            if not player:isPreWalking() then
                player:preWalk(dir)
            end
        else
            -- check for stairs/elevation steps
            if not canChangeFloorDown(toPos) and not canChangeFloorUp(toPos) then
                return false
            end
        end
    end

    g_game.walk(dir)

    return true
end

local function addWalkEvent(dir, delay)
    cancelWalkEvent()

    local function walkCallback()
        if g_keyboard.getModifiers() ~= KeyboardNoModifier then
            return
        end

        local direction = smartWalkDir or dir
        walk(direction)
    end

    if delay and delay == 0 then
        walkEvent = addEvent(walkCallback)
        return
    end

    walkEvent = scheduleEvent(walkCallback, delay or 10)
end

local function smartWalk(dir)
    addWalkEvent(dir)
end

local function changeWalkDir(dir, pop)
    while table.removevalue(smartWalkDirs, dir) do end
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

local function turn(dir, repeated)
    local player = g_game.getLocalPlayer()
    if player:isWalking() and player:getDirection() == dir then
        return
    end

    cancelWalkEvent()

    local delay = repeated and 1000 or 200

    if lastTurn + delay < g_clock.millis() then
        g_game.turn(dir)
        changeWalkDir(dir)
        lastTurn = g_clock.millis()
        player:lockWalk(g_settings.getNumber("walkTurnDelay"))
    end
end


local function bindKeys()
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

-- events
local function onTeleport(player, newPos, oldPos)
    if not newPos or not oldPos then
        return
    end

    if Position.offsetX(newPos, oldPos) >= 3 or Position.offsetY(newPos, oldPos) >= 3 or Position.offsetZ(newPos, oldPos) >= 2 then
        -- teleport
        player:lockWalk(g_settings.getNumber("walkTeleportDelay"))
    else
        -- floor change is also teleport
        player:lockWalk(g_settings.getNumber("walkStairsDelay"))
    end
end

local function onWalkFinish(player)
    if nextWalkDir then
        if not g_game.getFeature(GameAllowPreWalk) then
            walk(nextWalkDir)
        else
            addWalkEvent(nextWalkDir)
        end
    end
end

local function onCancelWalk(player)
    player:lockWalk(50)
end

function WalkController:onInit()
    bindKeys()
end

function WalkController:onGameStart()
    self:registerEvents(g_game, {
        onGameStart = onGameStart,
        onTeleport = onTeleport
    })

    self:registerEvents(LocalPlayer, {
        onCancelWalk = onCancelWalk,
        onWalkFinish = onWalkFinish,
    })

    modules.game_interface.getRootPanel().onFocusChange = stopSmartWalk

    modules.game_joystick.addOnJoystickMoveListener(function(dir)
        g_game.walk(dir)
    end)

    -- open tibia has delay in auto walking
    if not g_game.isOfficialTibia() then
        g_game.enableFeature(GameForceFirstAutoWalkStep)
    else
        g_game.disableFeature(GameForceFirstAutoWalkStep)
    end
end

function WalkController:onGameEnd()
    stopSmartWalk()
end

-- use by console

function bindWalkKey(key, dir)
    local gameRootPanel = modules.game_interface.getRootPanel()

    WalkController:bindKeyDown(key, function()
        g_keyboard.setKeyDelay(key, 10)
        changeWalkDir(dir)
    end, gameRootPanel, true)

    WalkController:bindKeyUp(key, function()
        g_keyboard.setKeyDelay(key, 30)
        changeWalkDir(dir, true)
    end, gameRootPanel, true)

    WalkController:bindKeyPress(key, function(_, _, ticks) smartWalk(dir) end, gameRootPanel)
end

function bindTurnKey(key, dir)
    if not modules.game_interface then
        return
    end

    local gameRootPanel = modules.game_interface.getRootPanel()
    WalkController:bindKeyDown(key, function() turn(dir, false) end, gameRootPanel)
    WalkController:bindKeyPress(key, function() turn(dir, true) end, gameRootPanel)
    WalkController:bindKeyUp(key, function()
        local player = g_game.getLocalPlayer()
        if player then player:lockWalk(200) end
    end, gameRootPanel)
end

function unbindWalkKey(key)
    local gameRootPanel = modules.game_interface.getRootPanel()
    g_keyboard.unbindKeyDown(key, gameRootPanel)
    g_keyboard.unbindKeyUp(key, gameRootPanel)
    g_keyboard.unbindKeyPress(key, gameRootPanel)
end

function unbindTurnKey(key)
    if not modules.game_interface then
        return
    end

    local gameRootPanel = modules.game_interface.getRootPanel()
    g_keyboard.unbindKeyDown(key, gameRootPanel)
    g_keyboard.unbindKeyPress(key, gameRootPanel)
    g_keyboard.unbindKeyUp(key, gameRootPanel)
end

local smartWalkDirs = {}
local smartWalkDir = nil
local walkEvent = nil
local lastTurn = 0
local lastCancelWalkTime = 0
local nextWalkDir = nil

WalkController = Controller:new()

--- Stops the smart walking process.
local function stopSmartWalk()
    smartWalkDirs = {}
    smartWalkDir = nil
end

--- Cancels the current walk event if active.
local function cancelWalkEvent()
    if walkEvent then
        removeEvent(walkEvent)
        walkEvent = nil
    end
    nextWalkDir = nil
end

--- Generalized floor change check.
local function canChangeFloor(pos, deltaZ)
    pos.z = pos.z + deltaZ
    local toTile = g_map.getTile(pos)

    if deltaZ > 0 then
        return toTile and toTile:hasElevation(3)
    end

    return toTile and toTile:isWalkable()
end

--- Makes the player walk in the given direction.
local function walk(dir)
    local player = g_game.getLocalPlayer()
    if not player or g_game.isDead() or player:isDead() or player:isWalkLocked() then
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
        if not toTile or not toTile:isWalkable() then
            if not canChangeFloor(toPos, 1) and not canChangeFloor(toPos, -1) then
                return false
            end
        elseif not player:isPreWalking() then
            player:preWalk(dir)
        end
    end

    g_game.walk(dir)
    return true
end

--- Adds a walk event with an optional delay.
local function addWalkEvent(dir, delay)
    if os.time() - lastCancelWalkTime > 10 then
        cancelWalkEvent()
        lastCancelWalkTime = os.time()
    end

    local function walkCallback()
        if g_keyboard.getModifiers() ~= KeyboardNoModifier then
            return
        end
        walk(smartWalkDir or dir)
    end

    walkEvent = delay == 0 and addEvent(walkCallback) or scheduleEvent(walkCallback, delay or 10)
end

--- Initiates a smart walk in the given direction.
local function smartWalk(dir)
    addWalkEvent(dir)
end

--- Changes the current walking direction.
local function changeWalkDir(dir, pop)
    -- Remove all occurrences of the specified direction
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
        local diagonalMap = {
            [North] = { [West] = NorthWest, [East] = NorthEast },
            [South] = { [West] = SouthWest, [East] = SouthEast },
            [West]  = { [North] = NorthWest, [South] = SouthWest },
            [East]  = { [North] = NorthEast, [South] = SouthEast }
        }

        for _, d in ipairs(smartWalkDirs) do
            if diagonalMap[smartWalkDir] and diagonalMap[smartWalkDir][d] then
                smartWalkDir = diagonalMap[smartWalkDir][d]
                break
            end
        end
    end
end

--- Handles turning the player.
local function turn(dir, repeated)
    local player = g_game.getLocalPlayer()
    if player:isWalking() and player:getDirection() == dir then
        return
    end

    cancelWalkEvent()

    local TURN_DELAY_REPEATED = 1000
    local TURN_DELAY_DEFAULT = 200

    local delay = repeated and TURN_DELAY_REPEATED or TURN_DELAY_DEFAULT

    if lastTurn + delay < g_clock.millis() then
        g_game.turn(dir)
        changeWalkDir(dir)
        lastTurn = g_clock.millis()
        player:lockWalk(g_settings.getNumber("walkTurnDelay"))
    end
end

--- Binds movement keys to their respective directions.
local function bindKeys()
    modules.game_interface.getRootPanel():setAutoRepeatDelay(200)

    local keys = {
        { "Up",      North },
        { "Right",   East },
        { "Down",    South },
        { "Left",    West },
        { "Numpad8", North },
        { "Numpad9", NorthEast },
        { "Numpad6", East },
        { "Numpad3", SouthEast },
        { "Numpad2", South },
        { "Numpad1", SouthWest },
        { "Numpad4", West },
        { "Numpad7", NorthWest },
    }

    for _, keyDir in ipairs(keys) do
        bindWalkKey(keyDir[1], keyDir[2])
    end

    local turnKeys = {
        { "Ctrl+Up",    North },
        { "Ctrl+Right", East },
        { "Ctrl+Down",  South },
        { "Ctrl+Left",  West },
    }

    for _, keyDir in ipairs(turnKeys) do
        bindTurnKey(keyDir[1], keyDir[2])
    end
end

--- Handles player teleportation events.
local function onTeleport(player, newPos, oldPos)
    if not newPos or not oldPos then
        return
    end

    local offsetX, offsetY, offsetZ = Position.offsetX(newPos, oldPos), Position.offsetY(newPos, oldPos),
        Position.offsetZ(newPos, oldPos)
    local TELEPORT_DELAY = g_settings.getNumber("walkTeleportDelay")
    local STAIRS_DELAY = g_settings.getNumber("walkStairsDelay")
    local delay = (offsetX >= 3 or offsetY >= 3 or offsetZ >= 2) and TELEPORT_DELAY or STAIRS_DELAY
    player:lockWalk(delay)
end

--- Handles the end of a walking event.
local function onWalkFinish(player)
    if nextWalkDir then
        if not g_game.getFeature(GameAllowPreWalk) then
            walk(nextWalkDir)
        else
            addWalkEvent(nextWalkDir)
        end
    end
end

--- Handles cancellation of a walking event.
local function onCancelWalk(player)
    player:lockWalk(50)
end

--- Initializes the WalkController.
function WalkController:onInit()
    bindKeys()
end

--- Sets up game-related events for the WalkController.
function WalkController:onGameStart()
    self:registerEvents(g_game, {
        onGameStart = onGameStart,
        onTeleport = onTeleport,
    })

    self:registerEvents(LocalPlayer, {
        onCancelWalk = onCancelWalk,
        onWalkFinish = onWalkFinish,
    })

    modules.game_interface.getRootPanel().onFocusChange = stopSmartWalk
    modules.game_joystick.addOnJoystickMoveListener(function(dir) g_game.walk(dir) end)

    if not g_game.isOfficialTibia() then
        g_game.enableFeature(GameForceFirstAutoWalkStep)
    else
        g_game.disableFeature(GameForceFirstAutoWalkStep)
    end
end

--- Cleans up resources when the game ends.
function WalkController:onGameEnd()
    stopSmartWalk()
end

--- Utility functions for binding and unbinding keys.
function bindWalkKey(key, dir)
    local gameRootPanel = modules.game_interface.getRootPanel()

    g_keyboard.bindKeyDown(key, function()
        g_keyboard.setKeyDelay(key, 10)
        changeWalkDir(dir)
    end, gameRootPanel, true)

    g_keyboard.bindKeyUp(key, function()
        g_keyboard.setKeyDelay(key, 30)
        changeWalkDir(dir, true)
    end, gameRootPanel, true)

    g_keyboard.bindKeyPress(key, function() smartWalk(dir) end, gameRootPanel)
end

function bindTurnKey(key, dir)
    local gameRootPanel = modules.game_interface.getRootPanel()

    g_keyboard.bindKeyDown(key, function() turn(dir, false) end, gameRootPanel)
    g_keyboard.bindKeyPress(key, function() turn(dir, true) end, gameRootPanel)
    g_keyboard.bindKeyUp(key, function()
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
    local gameRootPanel = modules.game_interface.getRootPanel()
    g_keyboard.unbindKeyDown(key, gameRootPanel)
    g_keyboard.unbindKeyPress(key, gameRootPanel)
    g_keyboard.unbindKeyUp(key, gameRootPanel)
end

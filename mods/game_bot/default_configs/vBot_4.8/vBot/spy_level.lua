-- config

local keyUp = "="
local keyDown = "-"
setDefaultTab("Tools")

-- script

local lockedLevel = pos().z

onPlayerPositionChange(function(newPos, oldPos)
    lockedLevel = pos().z
    modules.game_interface.getMapPanel():unlockVisibleFloor()
end)

onKeyPress(function(keys)
    if keys == keyDown then
        lockedLevel = lockedLevel + 1
        modules.game_interface.getMapPanel():lockVisibleFloor(lockedLevel)
    elseif keys == keyUp then
        lockedLevel = lockedLevel - 1
        modules.game_interface.getMapPanel():lockVisibleFloor(lockedLevel)
    end
end)
-- walking
local expectedDirs = {}
local isWalking = {}
local walkPath = {}
local walkPathIter = 0

CaveBot.resetWalking = function()
  expectedDirs = {}
  walkPath = {}
  isWalking = false
end

CaveBot.doWalking = function()
  if CaveBot.Config.get("mapClick") then
    return false
  end
  if #expectedDirs == 0 then
    return false
  end
  if #expectedDirs >= 3 then
    CaveBot.resetWalking()
  end
  local dir = walkPath[walkPathIter]
  if dir then
    g_game.walk(dir, false)
    table.insert(expectedDirs, dir)
    walkPathIter = walkPathIter + 1
    CaveBot.delay(CaveBot.Config.get("walkDelay") + player:getStepDuration(false, dir))
    return true
  end
  return false  
end

-- called when player position has been changed (step has been confirmed by server)
onPlayerPositionChange(function(newPos, oldPos)
  if not oldPos or not newPos then return end
  
  local dirs = {{NorthWest, North, NorthEast}, {West, 8, East}, {SouthWest, South, SouthEast}}
  local dir = dirs[newPos.y - oldPos.y + 2]
  if dir then
    dir = dir[newPos.x - oldPos.x + 2]
  end
  if not dir then
    dir = 8 -- 8 is invalid dir, it's fine
  end

  if not isWalking or not expectedDirs[1] then
    -- some other walk action is taking place (for example use on ladder), wait
    walkPath = {}
    CaveBot.delay(CaveBot.Config.get("ping") + player:getStepDuration(false, dir) + 150)
    return
  end
  
  if expectedDirs[1] ~= dir then
    if CaveBot.Config.get("mapClick") then
      CaveBot.delay(CaveBot.Config.get("walkDelay") + player:getStepDuration(false, dir))
    else
      CaveBot.delay(CaveBot.Config.get("mapClickDelay") + player:getStepDuration(false, dir))
    end
    return
  end
  
  table.remove(expectedDirs, 1)  
  if CaveBot.Config.get("mapClick") and #expectedDirs > 0 then
    CaveBot.delay(CaveBot.Config.get("mapClickDelay") + player:getStepDuration(false, dir))
  end
end)

CaveBot.walkTo = function(dest, maxDist, params)
  local path = getPath(player:getPosition(), dest, maxDist, params)
  if not path or not path[1] then
    return false
  end
  local dir = path[1]
  
  if CaveBot.Config.get("mapClick") then
    local ret = autoWalk(path)
    if ret then
      isWalking = true
      expectedDirs = path
      CaveBot.delay(CaveBot.Config.get("mapClickDelay") + math.max(CaveBot.Config.get("ping") + player:getStepDuration(false, dir), player:getStepDuration(false, dir) * 2))
    end
    return ret
  end
  
  g_game.walk(dir, false)
  isWalking = true    
  walkPath = path
  walkPathIter = 2
  expectedDirs = { dir }
  CaveBot.delay(CaveBot.Config.get("walkDelay") + player:getStepDuration(false, dir))
  return true
end

local context = G.botContext

context.getMapView = function() return modules.game_interface.getMapPanel() end
context.getMapPanel = context.getMapView
context.zoomIn = function() modules.game_interface.getMapPanel():zoomIn() end
context.zoomOut = function() modules.game_interface.getMapPanel():zoomOut() end

context.getSpectators = function(param1, param2)
--[[
  if param1 is table (position) then it's used for central position, then param2 is used as param1
  if param1 is creature, then creature position and direction of creature is used, then param2 is used as param1
  if param1 is true/false then it's used for multifloor, example: getSpectators(true)
  if param1 is string then it's used for getSpectatorsByPattern
]]--
  local pos = context.player:getPosition()
  local direction = context.player:getDirection()
  if type(param1) == 'table' then
    pos = param1
    direction = 8 -- invalid direction
    param1 = param2
  end
  if type(param1) == 'userdata' then
    pos = param1:getPosition()
    direction = param1:getDirection()
    param1 = param2
  end
  
  if type(param1) == 'string' then
    return g_map.getSpectatorsByPattern(pos, param1, direction)  
  end
  
  local multifloor = false
  if type(param1) == 'boolean' and param1 == true then
    multifloor = true
  end
  return g_map.getSpectators(pos, multifloor)
end

context.getCreatureById = function(id, multifloor)
  if type(id) ~= 'number' then return nil end
  if multifloor ~= true then
    multifloor = false
  end
  for i, spec in ipairs(g_map.getSpectators(context.player:getPosition(), multifloor)) do
     if spec:getId() == id then
        return spec
     end
  end
  return nil
end

context.getCreatureByName = function(name, multifloor)
  if not name then return nil end
  name = name:lower()
  if multifloor ~= true then
    multifloor = false
  end
  for i, spec in ipairs(g_map.getSpectators(context.player:getPosition(), multifloor)) do
     if spec:getName():lower() == name then
        return spec
     end
  end
  return nil
end

context.getPlayerByName = function(name, multifloor)
  if not name then return nil end
  name = name:lower()
  if multifloor ~= true then
    multifloor = false
  end
  for i, spec in ipairs(g_map.getSpectators(context.player:getPosition(), multifloor)) do
     if spec:isPlayer() and spec:getName():lower() == name then
        return spec
     end
  end
  return nil
end

context.findAllPaths = function(start, maxDist, params)
  --[[
    Available params:
      ignoreLastCreature
      ignoreCreatures
      ignoreNonPathable
      ignoreNonWalkable
      ignoreStairs
      ignoreCost
      allowUnseen
      allowOnlyVisibleTiles
      maxDistanceFrom
  ]]--
  if type(params) ~= 'table' then
    params = {}
  end
  for key, value in pairs(params) do
    if value == nil or value == false then
      params[key] = 0
    elseif value == true then
      params[key] = 1    
    end
  end
  if type(params['maxDistanceFrom']) == 'table' then
    if #params['maxDistanceFrom'] == 2 then
      params['maxDistanceFrom'] = params['maxDistanceFrom'][1].x .. "," .. params['maxDistanceFrom'][1].y ..
        "," .. params['maxDistanceFrom'][1].z .. "," .. params['maxDistanceFrom'][2]
    elseif #params['maxDistanceFrom'] == 4 then
      params['maxDistanceFrom'] = params['maxDistanceFrom'][1] .. "," .. params['maxDistanceFrom'][2] ..
        "," .. params['maxDistanceFrom'][3] .. "," .. params['maxDistanceFrom'][4]
    end
  end
  return g_map.findEveryPath(start, maxDist, params)
end
context.findEveryPath = context.findAllPaths

context.translateAllPathsToPath = function(paths, destPos)
  local predirections = {}
  local directions = {}
  local destPosStr = destPos
  if type(destPos) ~= 'string' then
    destPosStr = destPos.x .. "," .. destPos.y .. "," .. destPos.z
  end
  
  while destPosStr:len() > 0 do
    local node = paths[destPosStr]
    if not node then
      break
    end
    if node[3] < 0 then
      break
    end
    table.insert(predirections, node[3])
    destPosStr = node[4]
  end
  -- reverse
  for i=#predirections,1,-1 do
    table.insert(directions, predirections[i])
  end
  return directions
end
context.translateEveryPathToPath = context.translateAllPathsToPath


context.findPath = function(startPos, destPos, maxDist, params)
  --[[
    Available params:
      ignoreLastCreature
      ignoreCreatures
      ignoreNonPathable
      ignoreNonWalkable
      ignoreStairs
      ignoreCost
      allowUnseen
      allowOnlyVisibleTiles
      precision
      marginMin
      marginMax
      maxDistanceFrom
  ]]--
  if not destPos or startPos.z ~= destPos.z then
    return
  end
  if type(maxDist) ~= 'number' then
    maxDist = 100
  end
  if type(params) ~= 'table' then
    params = {}
  end
  local destPosStr = destPos.x .. "," .. destPos.y .. "," .. destPos.z
  params["destination"] = destPosStr
  local paths = context.findAllPaths(startPos, maxDist, params)
  local marginMin = params.marginMin or params.minMargin
  local marginMax = params.marginMax or params.maxMargin
  if type(marginMin) == 'number' and type(marginMax) == 'number' then
    local bestCandidate = nil
    local bestCandidatePos = nil    
    for x = -marginMax, marginMax do
      for y = -marginMax, marginMax do
        if math.abs(x) >= marginMin or math.abs(y) >= marginMin then
          local dest = (destPos.x + x) .. "," .. (destPos.y + y) .. "," .. destPos.z
          local node = paths[dest]
          if node and (not bestCandidate or bestCandidate[1] > node[1]) then
            bestCandidate = node
            bestCandidatePos = dest
          end          
        end
      end
    end
    if bestCandidate then
      return context.translateAllPathsToPath(paths, bestCandidatePos)      
    end
    return
  end

  if not paths[destPosStr] then  
    local precision = params.precision
    if type(precision) == 'number' then
      for p = 1, precision do
        local bestCandidate = nil
        local bestCandidatePos = nil
        for x = -p, p do
          for y = -p, p do
            local dest = (destPos.x + x) .. "," .. (destPos.y + y) .. "," .. destPos.z
            local node = paths[dest]
            if node and (not bestCandidate or bestCandidate[1] > node[1]) then
              bestCandidate = node
              bestCandidatePos = dest
            end
          end
        end
        if bestCandidate then
          return context.translateAllPathsToPath(paths, bestCandidatePos)      
        end
      end
    end
    return nil
  end
  
  return context.translateAllPathsToPath(paths, destPos)
end
context.getPath = context.findPath

-- also works as autoWalk(dirs) where dirs is a list eg.: {1,2,3,0,1,1,2,}
context.autoWalk = function(destination, maxDist, params) 
  if type(destination) == "table" and table.isList(destination) and not maxDist and not params then
    g_game.autoWalk(destination, {x=0,y=0,z=0})
    return true
  end

  -- Available params same as for findPath
  local path = context.findPath(context.player:getPosition(), destination, maxDist, params)
  if not path then
    return false
  end
  -- autowalk without prewalk animation
  g_game.autoWalk(path, {x=0,y=0,z=0})
  return true
end

context.getTileUnderCursor = function()
  if not modules.game_interface.gameMapPanel.mousePos then return end
  return modules.game_interface.gameMapPanel:getTile(modules.game_interface.gameMapPanel.mousePos)
end

context.canShoot = function(pos, distance)
  if not distance then distance = 5 end
  local tile = g_map.getTile(pos, distance)
  if tile then
    return tile:canShoot(distance)
  end
  return false
end

context.isTrapped = function(creature)
  if not creature then
    creature = context.player
  end
  local pos = creature:getPosition()
  local dirs = {{-1,1}, {0,1}, {1,1}, {-1, 0}, {1, 0}, {-1, -1}, {0, -1}, {1, -1}}
  for i=1,#dirs do
    local tile = g_map.getTile({x=pos.x-dirs[i][1],y=pos.y-dirs[i][2],z=pos.z})
    if tile and tile:isWalkable(false) then
      return false
    end
  end
  return true
end

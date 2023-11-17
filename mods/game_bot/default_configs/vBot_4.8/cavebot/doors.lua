CaveBot.Extensions.OpenDoors = {}

CaveBot.Extensions.OpenDoors.setup = function()
  CaveBot.registerAction("OpenDoors", "#00FFFF", function(value, retries)
    local pos = string.split(value, ",")
    local key = nil
    if #pos == 4 then
      key = tonumber(pos[4])
    end
    if not pos[1] then
      warn("CaveBot[OpenDoors]: invalid value. It should be position (x,y,z), is: " .. value)
      return false
    end

    if retries >= 5 then
      print("CaveBot[OpenDoors]: too many tries, can't open doors")
      return false -- tried 5 times, can't open
    end

    pos = {x=tonumber(pos[1]), y=tonumber(pos[2]), z=tonumber(pos[3])}  

    local doorTile
    if not doorTile then
      for i, tile in ipairs(g_map.getTiles(posz())) do
        if tile:getPosition().x == pos.x and tile:getPosition().y == pos.y and tile:getPosition().z == pos.z then
          doorTile = tile
        end
      end
    end

    if not doorTile then
      return false
    end
  
    if not doorTile:isWalkable() then
      if not key then
        use(doorTile:getTopUseThing())
        delay(200)
        return "retry"
      else
        useWith(key, doorTile:getTopUseThing())
        delay(200)
        return "retry"
      end
    else
      print("CaveBot[OpenDoors]: possible to cross, proceeding")
      return true
    end
  end)

  CaveBot.Editor.registerAction("opendoors", "open doors", {
    value=function() return posx() .. "," .. posy() .. "," .. posz() end,
    title="Door position",
    description="doors position (x,y,z) and key id (optional)",
    multiline=false,
    validation=[[\d{1,5},\d{1,5},\d{1,2}(?:,\d{1,5}$|$)]]
})
end
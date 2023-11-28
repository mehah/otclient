CaveBot.Extensions.PosCheck = {}

local posCheckRetries = 0
CaveBot.Extensions.PosCheck.setup = function()
  CaveBot.registerAction("PosCheck", "#00FFFF", function(value, retries)
    local tilePos
    local data = string.split(value, ",")
    if #data ~= 5 then
     warn("wrong travel format, should be: label, distance, x, y, z")
     return false
    end

    local tilePos = player:getPosition()

    tilePos.x = tonumber(data[3])
    tilePos.y = tonumber(data[4])
    tilePos.z = tonumber(data[5])

    if posCheckRetries > 10 then
        posCheckRetries = 0
        print("CaveBot[CheckPos]: waypoints locked, too many tries, unclogging cavebot and proceeding")
        return false
    elseif (tilePos.z == player:getPosition().z) and (getDistanceBetween(player:getPosition(), tilePos) <= tonumber(data[2])) then
        posCheckRetries = 0
        print("CaveBot[CheckPos]: position reached, proceeding")
        return true
    else
        posCheckRetries = posCheckRetries + 1
        if data[1] == "last" then
          CaveBot.gotoFirstPreviousReachableWaypoint()
          print("CaveBot[CheckPos]: position not-reached, going back to first reachable waypoint.")
          return false
        else
          CaveBot.gotoLabel(data[1])
          print("CaveBot[CheckPos]: position not-reached, going back to label: " .. data[1])
          return false
        end
    end
  end)

  CaveBot.Editor.registerAction("poscheck", "pos check", {
    value=function() return "last" .. "," .. "10" .. "," .. posx() .. "," .. posy() .. "," .. posz() end,
    title="Location Check",
    description="label name, accepted dist from coordinates, x, y, z",
    multiline=false,
})
end
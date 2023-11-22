CaveBot.Extensions.Travel = {}

CaveBot.Extensions.Travel.setup = function()
  CaveBot.registerAction("Travel", "#db5a5a", function(value, retries)
   local data = string.split(value, ",")
    if #data < 2 then
     warn("CaveBot[Travel]: incorrect travel value!")
     return false
    end

    local npcName = data[1]:trim()
    local dest = data[2]:trim()

    if retries > 5 then
      print("CaveBot[Travel]: too many tries, can't travel")
     return false
    end

    local npc = getCreatureByName(npcName)
    if not npc then 
      print("CaveBot[Travel]: NPC not found, can't travel")
     return false 
    end

    if not CaveBot.ReachNPC(npcName) then
      return "retry"
    end

    CaveBot.Travel(dest)
    delay(storage.extras.talkDelay*3)
    print("CaveBot[Travel]: travel action finished")
    return true
  end)

 CaveBot.Editor.registerAction("travel", "travel", {
  value="NPC name, city",
  title="Travel",
  description="NPC name, City name, delay in ms(default is 200ms)",
 })
end
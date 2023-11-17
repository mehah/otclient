CaveBot.Extensions.SellAll = {}

local sellAllCap = 0
CaveBot.Extensions.SellAll.setup = function()
  CaveBot.registerAction("SellAll", "#C300FF", function(value, retries)
    local val = string.split(value, ",")
    local wait

    -- table formatting
    for i, v in ipairs(val) do
      v = v:trim()
      v = tonumber(v) or v
      val[i] = v
    end

    if table.find(val, "yes", true) then
      wait = true
    end

    local npcName = val[1]
    local npc = getCreatureByName(npcName)
    if not npc then 
      print("CaveBot[SellAll]: NPC not found! skipping")
      return false 
    end

    if retries > 10 then
      print("CaveBot[SellAll]: can't sell, skipping")
      return false
    end

    if freecap() == sellAllCap then
      sellAllCap = 0 
      print("CaveBot[SellAll]: Sold everything, proceeding")
      return true
    end

    delay(800)
    if not CaveBot.ReachNPC(npcName) then
      return "retry"
    end

    if not NPC.isTrading() then
      CaveBot.OpenNpcTrade()
      delay(storage.extras.talkDelay*2)
      return "retry"
    else
      sellAllCap = freecap()
    end

    storage.cavebotSell = storage.cavebotSell or {}
    for i, item in ipairs(storage.cavebotSell) do
      local data = type(item) == 'number' and item or item.id
      if not table.find(val, data) then
        table.insert(val, data)
      end
    end

    table.dump(val)
    
    modules.game_npctrade.sellAll(wait, val)
    if wait then
      print("CaveBot[SellAll]: Sold All with delay")
    else
      print("CaveBot[SellAll]: Sold All without delay")
    end

    return "retry"
  end)

 CaveBot.Editor.registerAction("sellall", "sell all", {
  value="NPC",
  title="Sell All",
  description="NPC Name, 'yes' if sell with delay, exceptions: id separated by comma",
 })
end
CaveBot.Extensions.SupplyCheck = {}

local supplyRetries = 0
local missedChecks = 0
local rawRound = 0
local time = now
vBot.CaveBotData =
  vBot.CaveBotData or
  {
    refills = 0,
    rounds = 0,
    time = {},
    lastRefill = os.time(),
    refillTime = {}
  }

local function setCaveBotData(hunting)
  if hunting then
    supplyRetries = supplyRetries + 1
  else
    supplyRetries = 0
    table.insert(vBot.CaveBotData.refillTime, os.difftime(os.time() - vBot.CaveBotData.lastRefill))
    vBot.CaveBotData.lastRefill = os.time()
    vBot.CaveBotData.refills = vBot.CaveBotData.refills + 1
  end

  table.insert(vBot.CaveBotData.time, rawRound)
  vBot.CaveBotData.rounds = vBot.CaveBotData.rounds + 1
  missedChecks = 0
end

CaveBot.Extensions.SupplyCheck.setup = function()
  CaveBot.registerAction(
    "supplyCheck",
    "#db5a5a",
    function(value)
      local data = string.split(value, ",")
      local round = 0
      rawRound = 0
      local label = data[1]:trim()
      local pos = nil
      if #data == 4 then
        pos = {x = tonumber(data[2]), y = tonumber(data[3]), z = tonumber(data[4])}
      end

      if pos then
        if missedChecks >= 4 then
          missedChecks = 0
          supplyRetries = 0
          print("CaveBot[SupplyCheck]: Missed 5 supply checks, proceeding with waypoints")
          return true
        end
        if getDistanceBetween(player:getPosition(), pos) > 10 then
          missedChecks = missedChecks + 1
          print("CaveBot[SupplyCheck]: Missed supply check! " .. 5 - missedChecks .. " tries left before skipping.")
          return CaveBot.gotoLabel(label)
        end
      end

      if time then
        rawRound = math.ceil((now - time) / 1000)
        round = rawRound .. "s"
      else
        round = ""
      end
      time = now

      local softCount = itemAmount(6529) + itemAmount(3549)
      local supplyData = Supplies.hasEnough()
      local supplyInfo = Supplies.getAdditionalData()

      if storage.caveBot.forceRefill then
        print("CaveBot[SupplyCheck]: User forced, going back on refill. Last round took: " .. round)
        storage.caveBot.forceRefill = false
        supplyRetries = 0
        missedChecks = 0
        return false
      elseif storage.caveBot.backStop then
        print("CaveBot[SupplyCheck]: User forced, going back to city and turning off CaveBot. Last round took: " .. round)
        supplyRetries = 0
        missedChecks = 0
        return false
      elseif storage.caveBot.backTrainers then
        print("CaveBot[SupplyCheck]: User forced, going back to city, then on trainers. Last round took: " .. round)
        supplyRetries = 0
        missedChecks = 0
        return false
      elseif storage.caveBot.backOffline then
        print("CaveBot[SupplyCheck]: User forced, going back to city, then on offline training. Last round took: " .. round)
        supplyRetries = 0
        missedChecks = 0
        return false
      elseif supplyRetries > (storage.extras.huntRoutes or 50) then
        print("CaveBot[SupplyCheck]: Round limit reached, going back on refill. Last round took: " .. round)
        setCaveBotData()
        return false
      elseif (supplyInfo.imbues.enabled and player:getSkillLevel(11) == 0) then
        print("CaveBot[SupplyCheck]: Imbues ran out. Going on refill. Last round took: " .. round)
        setCaveBotData()
        return false
      elseif (supplyInfo.stamina.enabled and stamina() < tonumber(supplyInfo.stamina.value)) then
        print("CaveBot[SupplyCheck]: Stamina ran out. Going on refill. Last round took: " .. round)
        setCaveBotData()
        return false
      elseif (supplyInfo.softBoots.enabled and softCount < 1) then
        print("CaveBot[SupplyCheck]: No soft boots left. Going on refill. Last round took: " .. round)
        setCaveBotData()
        return false
      elseif type(supplyData) == "table" then
        print("CaveBot[SupplyCheck]: Not enough item: " .. supplyData.id .. "(only " .. supplyData.amount .. " left). Going on refill. Last round took: " .. round)
        setCaveBotData()
        return false
      elseif (supplyInfo.capacity.enabled and freecap() < tonumber(supplyInfo.capacity.value)) then
        print("CaveBot[SupplyCheck]: Not enough capacity. Going on refill. Last round took: " .. round)
        setCaveBotData()
        return false
      else
        print("CaveBot[SupplyCheck]: Enough supplies. Hunting. Round (" .. supplyRetries .. "/" .. (storage.extras.huntRoutes or 50) .. "). Last round took: " .. round)
        setCaveBotData(true)
        return CaveBot.gotoLabel(label)
      end
    end
  )

  CaveBot.Editor.registerAction(
    "supplycheck",
    "supply check",
    {
      value = function()
        return "startHunt," .. posx() .. "," .. posy() .. "," .. posz()
      end,
      title = "Supply check label",
      description = "Insert here hunting start label",
      validation = [[[^,]+,\d{1,5},\d{1,5},\d{1,2}$]]
    }
  )
end

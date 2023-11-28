CaveBot.Extensions.Bank = {}

local balance = 0

CaveBot.Extensions.Bank.setup = function()
  CaveBot.registerAction("bank", "#db5a5a", function(value, retries)
   local data = string.split(value, ",")
   local waitVal = 300
   local amount = 0
   local actionType
   local npcName
   local transferName
   local balanceLeft
    if #data ~= 3 and #data ~= 2 and #data ~= 4 then
     warn("CaveBot[Bank]: incorrect value!")
     return false
    else
      actionType = data[1]:trim():lower()
      npcName = data[2]:trim()
      if #data == 3 then
        amount = tonumber(data[3]:trim())
      end
      if #data == 4 then
        transferName = data[3]:trim()
        balanceLeft = tonumber(data[4]:trim())
      end
    end

    if actionType ~= "withdraw" and actionType ~= "deposit" and actionType ~= "transfer" then
      warn("CaveBot[Bank]: incorrect action type! should be withdraw/deposit/transfer, is: " .. actionType)
      return false
    elseif actionType == "withdraw" then
      local value = tonumber(amount)
      if not value then
        warn("CaveBot[Bank]: incorrect amount value! should be number, is: " .. amount)
        return false
      end
    end

    if retries > 5 then
      print("CaveBot[Bank]: too many tries, skipping")
     return false
    end

    local npc = getCreatureByName(npcName)
    if not npc then 
      print("CaveBot[Bank]: NPC not found, skipping")
     return false 
    end

    if not CaveBot.ReachNPC(npcName) then
      return "retry"
    end

    if actionType == "deposit" then
      CaveBot.Conversation("hi", "deposit all", "yes")
      CaveBot.delay(storage.extras.talkDelay*3)
      return true
    elseif actionType == "withdraw" then
      CaveBot.Conversation("hi", "withdraw", value, "yes")
      CaveBot.delay(storage.extras.talkDelay*4)
      return true
    else
      -- first check balance
      CaveBot.Conversation("hi", "balance")
      schedule(5000, function()
        local amountToTransfer = balance - balanceLeft
        if amountToTransfer <= 0 then
          warn("CaveBot[Bank] Not enough gold to transfer! proceeding")
          return false
        end
        CaveBot.Conversation("hi", "transfer", amountToTransfer, transferName, "yes")
        warn("CaveBot[Bank] transferred "..amountToTransfer.." gold to: "..transferName)
      end)
      CaveBot.delay(storage.extras.talkDelay*11)
      return true
    end
  end)

 CaveBot.Editor.registerAction("bank", "bank", {
  value="action, NPC name",
  title="Banker",
  description="action type(withdraw/deposit/transfer), NPC name, (if withdraw: amount|if transfer: name, balance left)",
 })
end


onTalk(function(name, level, mode, text, channelId, pos)
  if mode == 51 and text:find("Your account balance is") then
    balance = getFirstNumberInText(text)
  end
end)
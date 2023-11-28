-- config
setDefaultTab("Tools")
local defaultBp = "shopping bag"
local id = 21411

-- script

local playerContainer = nil
local depotContainer = nil
local mailContainer = nil

function reopenLootContainer()
  for _, container in pairs(getContainers()) do
    if container:getName():lower() == defaultBp:lower() then
      g_game.close(container)
    end
  end

  local lootItem = findItem(id)
  if lootItem then
    schedule(500, function() g_game.open(lootItem) end)
  end

end

macro(50, "Depot Withdraw", function()
  
  -- set the containers
  if not potionsContainer or not runesContainer or not ammoContainer then
    for i, container in pairs(getContainers()) do
      if container:getName() == defaultBp then
        playerContainer = container
      elseif string.find(container:getName(), "Depot") then
        depotContainer = container
      elseif string.find(container:getName(), "your inbox") then
        mailContainer = container
      end 
    end
  end

  if playerContainer and #playerContainer:getItems() == 20 then
    for j, item in pairs(playerContainer:getItems()) do
      if item:getId() == id then
        g_game.open(item, playerContainer)
       return
      end
    end
  end


if playerContainer and freecap() >= 200 then
  local time = 500
    if depotContainer then 
      for i, container in pairs(getContainers()) do
        if string.find(container:getName(), "Depot") then
          for j, item in pairs(container:getItems()) do
            g_game.move(item, playerContainer:getSlotPosition(playerContainer:getItemsCount()), item:getCount())
            return
          end
        end
      end
    end

    if mailContainer then 
      for i, container in pairs(getContainers()) do
        if string.find(container:getName(), "your inbox") then
          for j, item in pairs(container:getItems()) do
            g_game.move(item, playerContainer:getSlotPosition(playerContainer:getItemsCount()), item:getCount())
            return
          end
        end
      end
    end
end

end)
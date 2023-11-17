local context = G.botContext

context.SlotOther = InventorySlotOther
context.SlotHead = InventorySlotHead
context.SlotNeck = InventorySlotNeck
context.SlotBack = InventorySlotBack
context.SlotBody = InventorySlotBody
context.SlotRight = InventorySlotRight
context.SlotLeft = InventorySlotLeft
context.SlotLeg = InventorySlotLeg
context.SlotFeet = InventorySlotFeet
context.SlotFinger = InventorySlotFinger
context.SlotAmmo = InventorySlotAmmo
context.SlotPurse = InventorySlotPurse

context.getInventoryItem = function(slot) return context.player:getInventoryItem(slot) end
context.getSlot = context.getInventoryItem

context.getHead = function() return context.getInventoryItem(context.SlotHead) end
context.getNeck = function() return context.getInventoryItem(context.SlotNeck) end
context.getBack = function() return context.getInventoryItem(context.SlotBack) end
context.getBody = function() return context.getInventoryItem(context.SlotBody) end
context.getRight = function() return context.getInventoryItem(context.SlotRight) end
context.getLeft = function() return context.getInventoryItem(context.SlotLeft) end
context.getLeg = function() return context.getInventoryItem(context.SlotLeg) end
context.getFeet = function() return context.getInventoryItem(context.SlotFeet) end
context.getFinger = function() return context.getInventoryItem(context.SlotFinger) end
context.getAmmo = function() return context.getInventoryItem(context.SlotAmmo) end
context.getPurse = function() return context.getInventoryItem(context.SlotPurse) end

context.getContainers = function() return g_game.getContainers() end
context.getContainer = function(index) return g_game.getContainer(index) end

context.moveToSlot = function(item, slot, count)
  if type(item) == 'number' then
    item = context.findItem(item)
  end
  if not item then
    return
  end
  if count == nil then
    count = item:getCount()
  end
  return g_game.move(item, {x=65535, y=slot, z=0}, count)
end
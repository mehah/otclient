local quiverSlot = modules.game_inventory.inventoryWindow:recursiveGetChildById('slot5')
local label = quiverSlot.count

label = label or g_ui.loadUIFromString([[
Label
  id: count
  color: #bfbfbf
  font: verdana-11px-rounded
  anchors.left: parent.left
  anchors.right: parent.right
  anchors.bottom: parent.bottom
  text-align: right
  margin-right: 3
  margin-left: 3
  text:
]], quiverSlot)


function getQuiverAmount()
    -- old tibia
    if g_game.getClientVersion() < 1000 then return end


    local isQuiverEquipped = getRight() and getRight():isContainer() or false
    local quiver = isQuiverEquipped and getContainerByItem(getRight():getId())
    local count = 0

    if quiver then
        for i, item in ipairs(quiver:getItems()) do
            count = count + item:getCount()
        end
    else
        return label:setText("")
    end

    return label:setText(count)
end
getQuiverAmount()

onContainerOpen(function(container, previousContainer)
    getQuiverAmount()
end)

onContainerClose(function(container)
    getQuiverAmount()
end)
  
onAddItem(function(container, slot, item, oldItem)
    getQuiverAmount()
end)

onRemoveItem(function(container, slot, item)
    getQuiverAmount()
end)

onContainerUpdateItem(function(container, slot, item, oldItem)
    getQuiverAmount()
end)
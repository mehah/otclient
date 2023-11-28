if voc() == 2 or voc() == 12 then
    local bows = { 3350, 31581, 27455, 8027, 20082, 36664, 7438, 28718, 36665, 14246, 19362, 35518, 34150, 29417, 9378, 16164, 22866, 12733, 8029, 20083, 20084, 8026, 8028, 34088}
    local xbows = { 30393, 3349, 27456, 20085, 16163, 5947, 8021, 14247, 22867, 8023, 22711, 19356, 20086, 20087, 34089}
    local arrows = { 16143, 763, 761, 7365, 3448, 762, 21470, 7364, 14251, 3447, 3449, 15793, 25757, 774, 35901 }
    local bolts = { 6528, 7363, 3450, 16141, 25758, 14252, 3446, 16142, 35902 }
    local hold = false

    onContainerOpen(function(container, previousContainer)
        hold = false
    end)

    onContainerClose(function(container)
        hold = false
    end)
    
    onAddItem(function(container, slot, item, oldItem)
        hold = false
    end)

    onRemoveItem(function(container, slot, item)
        hold = false
    end)

    onContainerUpdateItem(function(container, slot, item, oldItem)
        hold = false
    end)



    local function manageQuiver(isBowEquipped, quiverContainer)
        local ammo = isBowEquipped and arrows or bolts
        local dest = nil
        local containers = getContainers()
        for i, container in ipairs(containers) do
            if container ~= quiverContainer and not containerIsFull(container) then
                local cname = container:getName():lower()
                if not cname:find("loot") and (cname:find("backpack") or cname:find("bag") or cname:find("chess")) then
                    dest = container
                end
            end
        end

        -- clearing
        if dest then
            for i, item in ipairs(quiverContainer:getItems()) do
                if not table.find(ammo, item:getId()) then
                    local pos = dest:getSlotPosition(dest:getItemsCount())
                    return g_game.move(item, pos, item:getCount())
                end
            end
        end

        if not containerIsFull(quiverContainer) then
            for i, container in ipairs(containers) do
                if container ~= quiverContainer then
                    for j, item in ipairs(container:getItems()) do
                        if table.find(ammo, item:getId()) then
                            local pos = quiverContainer:getSlotPosition(quiverContainer:getItemsCount())
                            return g_game.move(item, pos, item:getCount())
                        end
                    end
                end
            end
        end
        return true
    end

    UI.Separator()
    macro(100, "Quiver Manager", function()
        if hold then return end -- do nothing if nothing to do
        local hand = getLeft() and getLeft():getId()
        local quiverEquipped = getRight() and getRight():isContainer()

        if not hand then return end
        if not quiverEquipped then return end

        local quiverContainer = getContainerByItem(getRight():getId())
        if not quiverContainer then return end

        local isBowEquipped = getLeft() and table.find(bows, hand) and true or false
        if not isBowEquipped then
            if not table.find(xbows, hand) then
                return -- neither bow and xbow is equipped
            end
        end

        if manageQuiver(isBowEquipped, quiverContainer) then -- if true then it didn't do anything
            hold = true
        end
    end)
end
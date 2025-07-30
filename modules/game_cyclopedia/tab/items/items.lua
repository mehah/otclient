Cyclopedia.Items = {}
Cyclopedia.CategoryItems = {
    { id = 1, name = "Armors" },
    { id = 2, name = "Amulets" },
    { id = 3, name = "Boots" },
    { id = 4, name = "Containers" },
    { id = 24, name = "Creature Products" },
    { id = 5, name = "Decoration" },
    { id = 6, name = "Food" },
    { id = 30, name = "Gold" },
    { id = 7, name = "Helmets and Hats" },
    { id = 8, name = "Legs" },
    { id = 9, name = "Others" },
    { id = 10, name = "Potions" },
    { id = 25, name = "Quivers" },
    { id = 11, name = "Rings" },
    { id = 12, name = "Runes" },
    { id = 13, name = "Shields" },
    { id = 26, name = "Soul Cores" },
    { id = 14, name = "Tools" },
    { id = 31, name = "Unsorted" },
    { id = 15, name = "Valuables" },
    { id = 16, name = "Weapons: Ammo" },
    { id = 17, name = "Weapons: Axe" },
    { id = 18, name = "Weapons: Clubs" },
    { id = 19, name = "Weapons: Distance" },
    { id = 20, name = "Weapons: Swords" },
    { id = 21, name = "Weapons: Wands" },
    { id = 1000, name = "Weapons: All" }
}

local UI = nil

focusCategoryList = nil

function Cyclopedia.ResetItemCategorySelection(list)
    for i, child in pairs(list:getChildren()) do
        child:setChecked(false)
        child:setBackgroundColor(child.BaseColor)
    end
end

function showItems()
    UI = g_ui.loadUI("items", contentContainer)
    UI:show()
    UI.VocFilter = false
    UI.LevelFilter = false
    UI.h1Filter = false
    UI.h2Filter = false
    UI.ClassificationFilter = 0
    UI.SelectedCategory = nil
    UI.LootValue.NpcBuyCheck.onClick = Cyclopedia.onChangeLootValue
    UI.LootValue.MarketCheck.onClick = Cyclopedia.onChangeLootValue
    UI.EmptyLabel:setVisible(true)
    UI.InfoBase:setVisible(false)
    UI.LootValue:setVisible(false)
    UI.H1Button:disable()
    UI.H2Button:disable()
    UI.ItemFilter:disable()
    controllerCyclopedia.ui.CharmsBase:setVisible(false)
    controllerCyclopedia.ui.GoldBase:setVisible(false)
    controllerCyclopedia.ui.BestiaryTrackerButton:setVisible(false)
    if g_game.getClientVersion() >= 1410 then
        controllerCyclopedia.ui.CharmsBase1410:setVisible(false)
    end
    local CategoryColor = "#484848"

    for _, data in ipairs(Cyclopedia.CategoryItems) do
        local ItemCat = g_ui.createWidget("ItemCategory", UI.CategoryList)

        ItemCat:setId(data.id)
        ItemCat:setText(data.name)
        ItemCat:setBackgroundColor(CategoryColor)
        ItemCat:setPhantom(false)
        ItemCat.BaseColor = CategoryColor

        function ItemCat:onClick()
            Cyclopedia.ResetItemCategorySelection(UI.CategoryList)
            self:setChecked(true)
            self:setBackgroundColor("#585858")
        end

        CategoryColor = CategoryColor == "#484848" and "#414141" or "#484848"
    end

    Cyclopedia.ItemList = {}
    Cyclopedia.AllItemList = {}
    Cyclopedia.loadItemsCategories()

    focusCategoryList = UI.CategoryList

    g_keyboard.bindKeyPress('Down', function()
        focusCategoryList:focusNextChild(KeyboardFocusReason)
    end, focusCategoryList:getParent())

    g_keyboard.bindKeyPress('Up', function()
        focusCategoryList:focusPreviousChild(KeyboardFocusReason)
    end, focusCategoryList:getParent())

    connect(focusCategoryList, {
        onChildFocusChange = function(self, focusedChild)
            if focusedChild == nil then
                return
            end
            focusedChild:onClick()
        end
    })
end

function Cyclopedia.onCategoryChange(widget)
    if widget:isChecked() then
        Cyclopedia.selectItemCategory(tonumber(widget:getId()))
        UI.selectedCategory = widget
    end
end

function Cyclopedia.vocationFilter(value)
    UI.ItemListBase.List:destroyChildren()
    Cyclopedia.Items.VocFilter = value
    Cyclopedia.applyFilters()
end

function Cyclopedia.levelFilter(value)
    UI.ItemListBase.List:destroyChildren()
    Cyclopedia.Items.LevelFilter = value
    Cyclopedia.applyFilters()
end

local ignoreRecursiveCalls = false
local function setCheckedWithoutRecursion(h1Val, h2Val)
    ignoreRecursiveCalls = true
    UI.H1Button:setChecked(h1Val)
    UI.H2Button:setChecked(h2Val)
    ignoreRecursiveCalls = false
end

function Cyclopedia.handFilter(h1Val, h2Val)
    Cyclopedia.Items.h1Filter = h1Val
    Cyclopedia.Items.h2Filter = h2Val

    if ignoreRecursiveCalls then
        return
    end

    setCheckedWithoutRecursion(h1Val, h2Val)
    UI.ItemListBase.List:destroyChildren()
    Cyclopedia.applyFilters()
end

function Cyclopedia.classificationFilter(data)
    UI.ItemListBase.List:destroyChildren()
    Cyclopedia.Items.ClassificationFilter = tonumber(data)
    Cyclopedia.applyFilters()
end

local function processItemsById(id)
    local idsToProcess = {}
    local tempTable = {}

    if id == 1000 then
        idsToProcess = {17, 18, 19, 20, 21}
    else
        idsToProcess = {id}
    end

    for _, idToProcess in pairs(idsToProcess) do
        if not table.empty(Cyclopedia.ItemList[idToProcess]) then
            for _, data in pairs(Cyclopedia.ItemList[idToProcess]) do
                table.insert(tempTable, data)
            end
        end
    end

    table.sort(tempTable, function(a, b)
        return string.lower(a:getMarketData().name) < string.lower((b:getMarketData().name))
    end)

    for _, data in pairs(tempTable) do
        local item = Cyclopedia.internalCreateItem(data)
    end
end

function Cyclopedia.applyFilters()
    local isSearching = UI.SearchEdit:getText() ~= ""
    if not isSearching then
        if UI.selectedCategory then
           processItemsById(tonumber(UI.selectedCategory:getId()))
        end
    else
        Cyclopedia.ItemSearch(UI.SearchEdit:getText(), false)
    end
end

function Cyclopedia.internalCreateItem(data)
    local player = g_game.getLocalPlayer()
    local vocation = player:getVocation()
    local level = player:getLevel()
    local classification = data:getClassification()
    local marketData = data:getMarketData()
    local vocFilter = Cyclopedia.Items.VocFilter
    local levelFilter = Cyclopedia.Items.LevelFilter
    local h1Filter = Cyclopedia.Items.h1Filter
    local h2Filter = Cyclopedia.Items.h2Filter
    local classificationFilter = Cyclopedia.Items.ClassificationFilter

    if vocFilter and tonumber(marketData.restrictVocation) > 0 then
        local demotedVoc = vocation > 10 and (vocation - 10) or vocation
        local vocBitMask = Bit.bit(tonumber(demotedVoc))
        if not Bit.hasBit(marketData.restrictVocation, vocBitMask) then
            return
        end
    end

    if levelFilter and level < marketData.requiredLevel then
        return
    end

    if h1Filter and data:getClothSlot() ~= 6 then
        return
    end

    if h2Filter and data:getClothSlot() ~= 0 then
        return
    end

    if classificationFilter == -1 and classification ~= 0 then
        return
    elseif classificationFilter == 1 and classification ~= 1 then
        return
    elseif classificationFilter == 2 and classification ~= 2 then
        return
    elseif classificationFilter == 3 and classification ~= 3 then
        return
    elseif classificationFilter == 4 and classification ~= 4 then
        return
    end

    local item = g_ui.createWidget("ItemsListBaseItem", UI.ItemListBase.List)

    item:setId(data:getId())
    item.Sprite:setItemId(data:getId())
    item.Name:setText(marketData.name)
    local price = data:getMeanPrice()

    item.Value = price
    item.Vocation = marketData.restrictVocation
    ItemsDatabase.setRarityItem(item.Sprite, item.Sprite:getItem())

    function item.onClick(widget)
        UI.InfoBase.SellBase.List:destroyChildren()
        UI.InfoBase.BuyBase.List:destroyChildren()

        local oldSelected = UI.selectItem
        local lootValue = UI.LootValue
        local itemId = tonumber(widget:getId())
        local internalData = g_things.getThingType(itemId, ThingCategoryItem)

        if oldSelected then
            oldSelected:setBackgroundColor("#00000000")
        end

        g_game.inspectionObject(3, itemId)

        if not lootValue:isVisible() then
            lootValue:setVisible(true)
        end

        UI.EmptyLabel:setVisible(false)
        UI.InfoBase:setVisible(true)
        UI.InfoBase.ResultGoldBase.Value:setText(Cyclopedia.formatGold(item.Value))
        UI.SelectedItem.Sprite:setItemId(data:getId())

        if price > 0 then
            ItemsDatabase.setRarityItem(UI.SelectedItem.Rarity, price)
            ItemsDatabase.setRarityItem(UI.InfoBase.ResultGoldBase.Rarity, price)
        else
            UI.InfoBase.ResultGoldBase.Rarity:setImageSource("")
            UI.SelectedItem.Rarity:setImageSource("")
        end
        widget:setBackgroundColor("#585858")
       
        if modules.game_quickloot.QuickLoot.data.filter == 2 then
            UI.InfoBase.quickLootCheck:setText("Loot when Quick Looting")
        else
            UI.InfoBase.quickLootCheck:setText('Skip when Quick Looting')
        end
        UI.InfoBase.quickLootCheck.onCheckChange = function(self, checked)
            if checked then
                modules.game_quickloot.QuickLoot.addLootList(data:getId(), modules.game_quickloot.QuickLoot.data.filter)
            else
                modules.game_quickloot.QuickLoot.removeLootList(data:getId(), modules.game_quickloot.QuickLoot.data.filter)
            end
        end
        UI.InfoBase.quickLootCheck:setChecked(modules.game_quickloot.QuickLoot.lootExists(data:getId(), modules.game_quickloot.QuickLoot.data.filter))

        local buy, sell = Cyclopedia.formatSaleData(internalData:getNpcSaleData())
        local sellColor = "#484848"

        for index, value in ipairs(sell) do
            local t_widget = g_ui.createWidget("UIWidget", UI.InfoBase.SellBase.List)

            t_widget:setId(index)
            t_widget:setText(value)
            t_widget:setTextAlign(AlignLeft)
            t_widget:setBackgroundColor(sellColor)

            t_widget.BaseColor = sellColor

            function t_widget:onClick()
                Cyclopedia.ResetItemCategorySelection(UI.InfoBase.SellBase.List)
                self:setChecked(true)
                self:setBackgroundColor("#585858")
            end

            sellColor = sellColor == "#484848" and "#414141" or "#484848"
        end

        local buyColor = "#484848"

        for index, value in ipairs(buy) do
            local t_widget = g_ui.createWidget("UIWidget", UI.InfoBase.BuyBase.List)

            t_widget:setId(index)
            t_widget:setText(value)
            t_widget:setTextAlign(AlignLeft)
            t_widget:setBackgroundColor(buyColor)

            t_widget.BaseColor = buyColor

            function t_widget:onClick()
                Cyclopedia.ResetItemCategorySelection(UI.InfoBase.BuyBase.List)
                self:setChecked(true)
                self:setBackgroundColor("#585858")
            end

            buyColor = buyColor == "#484848" and "#414141" or "#484848"
        end 

        UI.selectItem = widget
    end

    return item
end

function Cyclopedia.ItemSearch(text, clearTextEdit)
    UI.ItemListBase.List:destroyChildren()
    if text ~= "" then
        UI.SelectedItem.Sprite:setItemId(0)
        UI.SelectedItem.Rarity:setImageSource("")

        local searchedItems = {}

        local oldSelected = UI.selectedCategory
        if oldSelected then
            oldSelected:setBackgroundColor(oldSelected.BaseColor)
            oldSelected:setChecked(false)
        end

        local searchTermLower = string.lower(text)

        for _, data in pairs(Cyclopedia.AllItemList) do
            local marketData = data:getMarketData()
            local itemNameLower = string.lower(marketData.name)
            local _, endIndex = itemNameLower:find(searchTermLower, 1, true)

            if endIndex and (itemNameLower:sub(endIndex + 1, endIndex + 1) == " " or endIndex == #itemNameLower) then
                table.insert(searchedItems, data)
            end
        end

        for _, data in ipairs(searchedItems) do
            local item = Cyclopedia.internalCreateItem(data)
        end
    else
        UI.SelectedItem.Sprite:setItemId(0)
        UI.SelectedItem.Rarity:setImageSource("")
    end

    if clearTextEdit then
        UI.SearchEdit:setText("")
    end
end

local function isHandWeapon(id)
    if id >= 17 and id <= 21 or id == 1000 then
        return true
    end
end

function Cyclopedia.selectItemCategory(id)
    if not isHandWeapon(id) then
        setCheckedWithoutRecursion(false, false)
    end

    if UI.SearchEdit:getText() ~= "" then
        Cyclopedia.ItemSearch("", true)
    end

    UI.ItemListBase.List:destroyChildren()

    if Cyclopedia.hasClassificationFilter(id) then
        UI.ItemFilter:clearOptions()
        UI.ItemFilter:addOption("All", 0, true)
        UI.ItemFilter:addOption("None", -1, true)

        for class = 1, 4 do
            UI.ItemFilter:addOption("Class " .. class, class, true)
        end

        UI.ItemFilter:enable()
    else
        UI.ItemFilter:clearOptions()
        Cyclopedia.Items.ClassificationFilter = 0
    end

    processItemsById(id)

    if Cyclopedia.hasHandedFilter(id) then
        UI.H1Button:enable()
        UI.H2Button:enable()
    else
        UI.H1Button:disable()
        UI.H2Button:disable()
    end
end

function Cyclopedia.loadItemsCategories()
    local types = g_things.findThingTypeByAttr(ThingAttrMarket, 0)
    local tempItemList = {}

    for _, data in pairs(types) do
        local marketData = data:getMarketData()
        if not tempItemList[marketData.category] then
            tempItemList[marketData.category] = {}
        end

        if marketData then
            table.insert(Cyclopedia.AllItemList, data)
        end

        table.insert(tempItemList[marketData.category], data)
    end

    for category, itemList in pairs(tempItemList) do
        table.sort(itemList, Cyclopedia.compareItems)
        Cyclopedia.ItemList[category] = itemList
    end
end

function Cyclopedia.FillItemList()
    local types = g_things.findThingTypeByAttr(ThingAttrMarket, 0)

    for i = 1, #types do
        local itemType = types[i]
        local item = Item.create(itemType:getId())
        if item then
            local marketData = itemType:getMarketData()
            if not table.empty(marketData) then
                item:setId(marketData.showAs)

                local marketItem = {
                    displayItem = item,
                    thingType = itemType,
                    marketData = marketData
                }

                if Cyclopedia.ItemList[marketData.category] ~= nil then
                    table.insert(Cyclopedia.ItemList[marketData.category], marketItem)
                end
            end
        end
    end
end

function Cyclopedia.loadItemDetail(itemId, descriptions)
    UI.InfoBase.DetailsBase.List:destroyChildren()

    local internalData = g_things.getThingType(itemId, ThingCategoryItem)
    local classification = internalData:getClassification()

    for _, description in ipairs(descriptions) do
        local widget = g_ui.createWidget("UIWidget", UI.InfoBase.DetailsBase.List)
        local key = description[1]
        local value = description[2]
        widget:setText(key .. ": " .. value)
        widget:setColor("#C0C0C0")
        widget:setTextWrap(true)
    end

    if classification > 0 then
        local widget = g_ui.createWidget("UIWidget", UI.InfoBase.DetailsBase.List)
        widget:setText("Classification: " .. classification)
        widget:setColor("#C0C0C0")
    end
end

local acceptWindow = nil
local oldProtocol = false
local offerDescriptions = {}

-- TODO:
-- - Implement stack offers (x100, x250) for consumables/potions
-- - Add gifting option
-- - Fix character name change
-- - Fix filter functionality
-- - Correct HTML string syntax
-- - fix protocol 11.00
-- - Fix scroll in history panel
-- - Fix onclick behavior in "home", link to category/item

GameStore = {}
-- == Enums ==--
GameStore.website = {
    WEBSITE_GETCOINS = "https://github.com/mehah/otclient",
    -- IMAGES_URL =  "http://localhost/images/store/" --./game_store --https://docs.opentibiabr.com/opentibiabr/downloads/website-applications/applications#store-for-client-13-1
}

GameStore.OfferTypes = {
    OFFER_TYPE_NONE = 0,
    OFFER_TYPE_ITEM = 1,
    OFFER_TYPE_STACKABLE = 2,
    OFFER_TYPE_CHARGES = 3,
    OFFER_TYPE_OUTFIT = 4,
    OFFER_TYPE_OUTFIT_ADDON = 5,
    OFFER_TYPE_MOUNT = 6,
    OFFER_TYPE_NAMECHANGE = 7,
    OFFER_TYPE_SEXCHANGE = 8,
    OFFER_TYPE_HOUSE = 9,
    OFFER_TYPE_EXPBOOST = 10,
    OFFER_TYPE_PREYSLOT = 11,
    OFFER_TYPE_PREYBONUS = 12,
    OFFER_TYPE_TEMPLE = 13,
    OFFER_TYPE_BLESSINGS = 14,
    OFFER_TYPE_PREMIUM = 15,
    OFFER_TYPE_ALLBLESSINGS = 17,
    OFFER_TYPE_INSTANT_REWARD_ACCESS = 18,
    OFFER_TYPE_CHARMS = 19,
    OFFER_TYPE_HIRELING = 20,
    OFFER_TYPE_HIRELING_NAMECHANGE = 21,
    OFFER_TYPE_HIRELING_SEXCHANGE = 22,
    OFFER_TYPE_HIRELING_SKILL = 23,
    OFFER_TYPE_HIRELING_OUTFIT = 24,
    OFFER_TYPE_HUNTINGSLOT = 25,
    OFFER_TYPE_ITEM_BED = 26,
    OFFER_TYPE_ITEM_UNIQUE = 27
}

GameStore.SubActions = {
    PREY_THIRDSLOT_REAL = 0,
    PREY_WILDCARD = 1,
    INSTANT_REWARD = 2,
    BLESSING_TWIST = 3,
    BLESSING_SOLITUDE = 4,
    BLESSING_PHOENIX = 5,
    BLESSING_SUNS = 6,
    BLESSING_SPIRITUAL = 7,
    BLESSING_EMBRACE = 8,
    BLESSING_BLOOD = 9,
    BLESSING_HEART = 10,
    BLESSING_ALL_PVE = 11,
    BLESSING_ALL_PVP = 12,
    CHARM_EXPANSION = 13,
    TASKHUNTING_THIRDSLOT = 14,
    PREY_THIRDSLOT_REDIRECT = 15
}

GameStore.ActionType = {
    OPEN_HOME = 0,
    OPEN_PREMIUM_BOOST = 1,
    OPEN_CATEGORY = 2,
    OPEN_USEFUL_THINGS = 3,
    OPEN_OFFER = 4,
    OPEN_SEARCH = 5
}

GameStore.CoinType = {
    Coin = 0,
    Transferable = 1
}

GameStore.Storages = {
    expBoostCount = 51052
}

GameStore.ConverType = {
    SHOW_NONE = 0,
    SHOW_MOUNT = 1,
    SHOW_OUTFIT = 2,
    SHOW_ITEM = 3,
    SHOW_HIRELING = 4
}

GameStore.ConfigureOffers = {
    SHOW_NORMAL = 0,
    SHOW_CONFIGURE = 1
}

GameStore.ClientOfferTypes = {
    CLIENT_STORE_OFFER_OTHER = 0,
    CLIENT_STORE_OFFER_NAMECHANGE = 1,
    CLIENT_STORE_OFFER_HIRELING = 3
}

GameStore.HistoryTypes = {
    HISTORY_TYPE_NONE = 0,
    HISTORY_TYPE_GIFT = 1,
    HISTORY_TYPE_REFUND = 2
}

GameStore.States = {
    STATE_NONE = 0,
    STATE_NEW = 1,
    STATE_SALE = 2,
    STATE_TIMED = 3
}

GameStore.StoreErrors = {
    STORE_ERROR_PURCHASE = 0,
    STORE_ERROR_NETWORK = 1,
    STORE_ERROR_HISTORY = 2,
    STORE_ERROR_TRANSFER = 3,
    STORE_ERROR_INFORMATION = 4
}

GameStore.ServiceTypes = {
    SERVICE_STANDERD = 0,
    SERVICE_OUTFITS = 3,
    SERVICE_MOUNTS = 4,
    SERVICE_BLESSINGS = 5
}

GameStore.SendingPackets = {
    S_CoinBalance = 0xDF, -- 223
    S_StoreError = 0xE0, -- 224
    S_RequestPurchaseData = 0xE1, -- 225
    S_CoinBalanceUpdating = 0xF2, -- 242
    S_OpenStore = 0xFB, -- 251
    S_StoreOffers = 0xFC, -- 252
    S_OpenTransactionHistory = 0xFD, -- 253
    S_CompletePurchase = 0xFE -- 254
}

GameStore.RecivedPackets = {
    C_StoreEvent = 0xE9, -- 233
    C_TransferCoins = 0xEF, -- 239
    C_ParseHirelingName = 0xEC, -- 236
    C_OpenStore = 0xFA, -- 250
    C_RequestStoreOffers = 0xFB, -- 251
    C_BuyStoreOffer = 0xFC, -- 252
    C_OpenTransactionHistory = 0xFD, -- 253
    C_RequestTransactionHistory = 0xFE -- 254
}

GameStore.ExpBoostValues = {
    [1] = 30,
    [2] = 45,
    [3] = 90,
    [4] = 180,
    [5] = 360
}

GameStore.DefaultValues = {
    DEFAULT_VALUE_ENTRIES_PER_PAGE = 26
}

-- /*=============================================
-- =            Local Function                  =
-- =============================================*/
local function setImagenHttp(widget, url, isIcon)
    if GameStore.website.IMAGES_URL then
        HTTP.downloadImage(GameStore.website.IMAGES_URL .. url, function(path, err)
            if err then
                g_logger.warning("HTTP error: " .. err .. " - " .. GameStore.website.IMAGES_URL .. url)
                if isIcon then
                    widget:setIcon("/game_store/images/dynamic-image-error")
                else
                    widget:setImageSource("/game_store/images/dynamic-image-error")
                    widget:setImageFixedRatio(false)
                end
                return
            end
            if isIcon then
                widget:setIcon(path)
            else
                widget:setImageSource(path)
            end
        end)
    else
        if not g_resources.fileExists("/game_store/images/" .. url) then
            widget:setImageSource("/game_store/images/dynamic-image-error")
            widget:setImageFixedRatio(false)
        else
            widget:setImageSource("/game_store/images/" .. url)
        end

    end
end

local function getCoinsBalance()
    local function extractNumber(text)
        return tonumber((text:match("%d[%d,]*"):gsub(",", "")))
    end

    local coins1 = extractNumber(controllerShop.ui.lblCoins.numero:getText())
    local coins2 = extractNumber(controllerShop.ui.lblCoins.numerodos:getText())
    return coins1, coins2
end

local function convertir_timestamp(timestamp)
    local fecha_hora = os.date("%Y-%m-%d, %H:%M:%S", timestamp)
    return fecha_hora
end

local function getProductData(product)
    if product.itemId or product.itemType then
        return {
            VALOR = "item",
            ID = product.itemId or product.itemType
        }
    elseif product.icon then
        return {
            VALOR = "icon",
            ID = product.icon
        }
    elseif product.outfitId or product.mountId or product.sexId then
        return {
            VALOR = "mountId",
            ID = product.outfitId or product.mountId or product.sexId
        }
    elseif product.maleOutfitId then
        return {
            VALOR = "outfitId",
            ID = product.maleOutfitId
        }
    end
end
-- /*=============================================
-- =            Botones                         =
-- =============================================*/

local function disableAllButtons()
    local panel = controllerShop.ui.panelItem
    panel:getChildById('btnBuy'):disable()
    panel:getChildById('lblName'):setText("")
    panel:getChildById('lblPrice'):setText("")
    panel:getChildById('image'):destroyChildren()
    for i = 1, controllerShop.ui.listCategory:getChildCount() do
        local widget = controllerShop.ui.listCategory:getChildByIndex(i)
        if widget and widget.Button then
            widget.Button:setEnabled(false)
            if widget.subCategories then
                for subId, _ in ipairs(widget.subCategories) do
                    local subWidget = widget:getChildById(subId)
                    if subWidget and subWidget.Button then
                        subWidget.Button:setEnabled(false)
                    end
                end
            end
        end
    end
    offerDescriptions = {}
end

local function enableAllButtons()
    for i = 1, controllerShop.ui.listCategory:getChildCount() do
        local widget = controllerShop.ui.listCategory:getChildByIndex(i)
        if widget and widget.Button then
            widget.Button:setEnabled(true)
            if widget.subCategories then
                for subId, _ in ipairs(widget.subCategories) do
                    local subWidget = widget:getChildById(subId)
                    if subWidget and subWidget.Button then
                        subWidget.Button:setEnabled(true)
                    end
                end
            end
        end
    end
end

local function toggleSubCategories(parent, isOpen)
    for subId, _ in ipairs(parent.subCategories) do
        local subWidget = parent:getChildById(subId)
        if subWidget then
            subWidget:setVisible(isOpen)
            if subId == 1 then
                subWidget.Button:setChecked(true)
                subWidget.Button.Arrow:setVisible(true)
                subWidget.Button.Arrow:setImageSource("/images/ui/icon-arrow7x7-right")
            end
        end
    end
    parent:setHeight(isOpen and parent.openedSize or parent.closedSize)
    parent.opened = isOpen
    parent.Button.Arrow:setVisible(not isOpen)
end

local function close(parent)
    if parent.subCategories then
        toggleSubCategories(parent, false)
    end
end

local function open(parent)
    local oldOpen = controllerShop.ui.openedCategory
    if oldOpen and oldOpen ~= parent then
        close(oldOpen)
    end
    toggleSubCategories(parent, true)
    controllerShop.ui.openedCategory = parent

end

local function closeCharacterButtons()
    for i = 1, controllerShop.ui.listCategory:getChildCount() do
        local widget = controllerShop.ui.listCategory:getChildByIndex(i)
        if widget and widget.subCategories then
            for subId, _ in ipairs(widget.subCategories) do
                local subWidget = widget:getChildById(subId)
                if subWidget then
                    subWidget.Button:setChecked(false)
                    subWidget.Button.Arrow:setVisible(false)
                end
            end
        end
    end
end

local function createSubWidget(parent, subId, subButton)
    local subWidget = g_ui.createWidget("storeCategory", parent)
    subWidget:setId(subId)
    setImagenHttp(subWidget.Button.Icon, subButton.icon, true)
    subWidget.Button.Title:setText(subButton.text)
    subWidget:setVisible(false)
    subWidget.open = subButton.open
    subWidget:setMarginLeft(15)
    subWidget.Button:setSize('163 20')
    function subWidget.Button.onClick()
        disableAllButtons()
        local selectedOption = controllerShop.ui.selectedOption
        closeCharacterButtons()
        parent.Button:setChecked(false)
        parent.Button.Arrow:setVisible(true)
        parent.Button.Arrow:setImageSource("")
        subWidget.Button:setChecked(true)
        subWidget.Button.Arrow:setVisible(true)
        subWidget.Button.Arrow:setImageSource("/images/ui/icon-arrow7x7-right")
        controllerShop.ui.openedSubCategory = subWidget

        if selectedOption then
            selectedOption:hide()
        end
        if subWidget.open == "Home" then
            g_game.requestStoreOffers("", GameStore.ActionType.OPEN_HOME)
        else
            g_game.requestStoreOffers(subButton.text, GameStore.ActionType.OPEN_CATEGORY)
        end

    end

    subWidget:addAnchor(AnchorHorizontalCenter, "parent", AnchorHorizontalCenter)
    if subId == 1 then
        subWidget:addAnchor(AnchorTop, "parent", AnchorTop)
        subWidget:setMarginTop(20)
    else
        subWidget:addAnchor(AnchorTop, "prev", AnchorBottom)
        subWidget:setMarginTop(-1)
    end

    return subWidget
end

local function createProductImage(imageParent, data)
    if data.VALOR == "item" then
        local itemWidget = g_ui.createWidget('Item', imageParent)
        itemWidget:setId(data.ID)
        itemWidget:setItemId(data.ID)
        itemWidget:fill('parent')
    elseif data.VALOR == "icon" then
        local widget = g_ui.createWidget('UIWidget', imageParent)
        -- widget:setImageSource("/game_store/images/64/" .. data.ID)
        setImagenHttp(widget, "/64/" .. data.ID, false)
        widget:fill('parent')
    elseif data.VALOR == "mountId" or data.VALOR:find("outfitId") then
        local creature = g_ui.createWidget('Creature', imageParent)
        creature:setOutfit({
            type = data.ID
        })
        creature:getCreature():setStaticWalking(1000)
        creature:fill('parent')
    end
end

local function formatNumberWithCommas(value)
    local formattedValue = string.format("%d", value)
    -- Add commas to the formatted value
    formattedValue = formattedValue:reverse():gsub("(%d%d%d)", "%1,")
    return formattedValue:reverse():gsub("^,", "")
end
-- /*=============================================
-- =            Controller                   =
-- =============================================*/
controllerShop = Controller:new()
g_ui.importStyle("style/ui.otui")
controllerShop:setUI('game_store')
function controllerShop:onInit()
    controllerShop.ui:hide()

    -- /*=============================================
    -- =            ComboBox                         =
    -- =============================================*/

    for k, v in pairs({{'Disabled', 'disabled'}}) do
        controllerShop.ui.panelItem.comboBoxContainer.showAll:addOption(v[1], v[2])
    end

    --[[     
    controllerShop.ui.panelItem.comboBoxContainer.MostPopularFirst.onOptionChange = function(comboBox, option)
    end 
    ]]
    for k, v in pairs({{'Most Popular Fist', 'MostPopularFist'}, {'Alphabetically', 'Alphabetically'},
                       {'Newest Fist', 'NewestFist'}}) do
        controllerShop.ui.panelItem.comboBoxContainer.MostPopularFirst:addOption(v[1], v[2])
    end

    --[[     
    controllerShop.ui.panelItem.comboBoxContainer.MostPopularFirst.onOptionChange = function(comboBox, option)
    end
 ]]

    controllerShop.ui.panelItem.listProduct.onChildFocusChange = chooseOffert

    -- /*=============================================
    -- =            Parse                         =
    -- =============================================*/

    --[[     ProtocolGame.registerOpcode(0xE1, function(protocol, msg)
        local purchaseData = msg:getString()
        print("0xE1", purchaseData)
    end)
 ]]

    controllerShop:registerEvents(g_game, {
        onParseStoreGetCoin = onParseStoreGetCoin,
        onParseStoreGetCategories = onParseStoreGetCategories,
        onParseStoreCreateHome = onParseStoreCreateHome,
        onParseStoreCreateProducts = onParseStoreCreateProducts,
        onParseStoreGetHistory = onParseStoreGetHistory,
        onParseStoreGetPurchaseStatus = onParseStoreGetPurchaseStatus,
        onParseStoreOfferDescriptions = onParseStoreOfferDescriptions,
        onParseStoreError = onParseStoreError

    })
end

function onParseStoreGetCoin(getTibiaCoins, getTransferableCoins)
    controllerShop.ui.lblCoins.numero:setText(formatNumberWithCommas(getTibiaCoins))
    controllerShop.ui.lblCoins.numerodos:setText(string.format("(Including: %s",
        formatNumberWithCommas(getTransferableCoins)))
end

function onParseStoreOfferDescriptions(offerId, description)
    offerDescriptions[offerId] = {
        id = offerId,
        description = description
    }
end

function onParseStoreGetPurchaseStatus(purchaseStatus)
    controllerShop.ui:hide()
    local messageBox = g_ui.createWidget('confirmarSHOP', g_ui.getRootWidget())
    messageBox.Box:setText(purchaseStatus)
    messageBox.Box:setTextWrap(true)
    messageBox.Box:setTextAlign(AlignLeft)
    messageBox.additionalLabel.onClick = function(widget)
        messageBox.additionalLabel:disable()
        messageBox.additionalLabel:getChildren()[1]:setImageSource("/game_store/images/open")
        if not controllerShop.ui.openedSubCategory then -- temp fix
            controllerShop.ui.openedCategory.Button:onClick()
        else
            controllerShop.ui.openedSubCategory.Button:onClick()
        end
        controllerShop:scheduleEvent(function()
            messageBox:destroy()
            controllerShop.ui:show()
        end, 2000, 'animation')
    end
end

function controllerShop:onGameStart()
    oldProtocol = g_game.getClientVersion() < 1332
end

function controllerShop:onGameEnd()
    if controllerShop.ui:isVisible() then
        controllerShop.ui:hide()
    end
    if acceptWindow then
        acceptWindow:destroy()
        acceptWindow = nil
    end
end

function controllerShop:onTerminate()

    -- ProtocolGame.unregisterOpcode(0xE1)

end

-- /*=============================================
-- =            Build widget                     =
-- =============================================*/

function onParseStoreCreateProducts(storeProducts)
    -- local descriptionInfo = offerDescriptions[storeProducts.offers.subOffers[1].id]

    local listProduct = controllerShop.ui.panelItem.listProduct
    listProduct:destroyChildren()

    if not storeProducts then
        return
    end

    for _, product in ipairs(storeProducts.offers) do
        local row = g_ui.createWidget('RowStore', listProduct)
        row.store, row.product, row.type = store, product, product.type

        local subOffer = product.subOffers[1]
        local nameLabel = row:getChildById('lblName')
        nameLabel:setText(product.name)
        nameLabel:setTextAlign(AlignCenter)
        nameLabel:setMarginRight(10)

        if subOffer.disabled then
            row:disable()
            row:setOpacity(0.5)
        end

        row:getChildById('lblPrice'):setText(subOffer.price)
        if subOffer.count > 0 then
            row:getChildById('count'):setText(subOffer.count .. "x")
        end

        local coinsBalance2, coinsBalance1 = getCoinsBalance()
        local priceLabel = row:getChildById('lblPrice')
        local isTransferable = subOffer.coinType == GameStore.CoinType.Transferable
        local price = product.subOffers[1].price
        local balance = isTransferable and coinsBalance1 or coinsBalance2
        priceLabel:setColor(balance < price and "#d33c3c" or "white")

        if isTransferable then
            priceLabel:setIcon("/game_store/images/icon-tibiacointransferable")
        end

        local data = getProductData(product)
        if data then
            createProductImage(row:getChildById('image'), data)
        end
    end

    local firstChild = listProduct:getFirstChild()
    if firstChild and firstChild:isEnabled() then
        listProduct:focusChild(firstChild)
    end
    enableAllButtons()
end

function onParseStoreCreateHome(offer)

    local homeProductos = controllerShop.ui.HomePanel.HomeRecentlyAdded.HomeProductos
    for _, product in ipairs(offer.offers) do
        local row = g_ui.createWidget('RowStore', homeProductos)
        row.store, row.product, row.type = store, product, product.type

        local nameLabel = row:getChildById('lblName')
        nameLabel:setText(product.name)
        nameLabel:setTextAlign(AlignCenter)
        nameLabel:setMarginRight(10)
        row:getChildById('lblPrice'):setText(product.price)
        if product.coinType == GameStore.CoinType.Transferable then
            row:getChildById('lblPrice'):setIcon("/game_store/images/icon-tibiacointransferable")
        end

        local data = getProductData(product)
        if data then
            createProductImage(row:getChildById('image'), data)
        end
    end

    local ramdomImg = offer.banners[math.random(1, #offer.banners)].image
    -- controllerShop.ui.HomePanel.HomeImagen:setImageSource("/game_store/images/" .. ramdomImg)
    setImagenHttp(controllerShop.ui.HomePanel.HomeImagen, ramdomImg, false)
    enableAllButtons()
end

function onParseStoreGetHistory(currentPage, pageCount, array2)

    local transferHistory = controllerShop.ui.transferHistory
    transferHistory:destroyChildren()

    for i = 1, #array2 do
        local row = g_ui.createWidget('HistoryEntry', controllerShop.ui.transferHistory)
        row.index = i
        row:getChildById('historyDate'):setText(convertir_timestamp(array2[i][1]))
        row:getChildById('historyDescription'):setText(array2[i][3])

        local amount = -tonumber(array2[i][2])
        local balanceLabel = row:getChildById('historyBalance')
        balanceLabel:setText(amount)

        if amount < 0 then
            balanceLabel:setColor("#d33c3c")
        else
            balanceLabel:setMarginLeft(151)
            balanceLabel:setColor("#00ff00")
        end
        if (i > 1) then
            row:setMarginTop(24 + ((i - 1) * 15))
        end

        if (i % 2 == 0) then
            row:setBackgroundColor("#414141")
        end
    end

end

function onParseStoreGetCategories(buttons)

    controllerShop.ui.listCategory:destroyChildren()

    local categories = {
        ["Home"] = {
            ["subCategories"] = {},
            ["name"] = "Home",
            ["icons"] = {
                [1] = "icon-store-home.png"
            },
            ["state"] = 0
        }

    }

    local subcategories = {}

    for _, button in ipairs(buttons) do
        if not button.parent then
            categories[button.name] = button
            categories[button.name].subCategories = {}
        else
            table.insert(subcategories, button)
        end
    end

    for _, subcat in ipairs(subcategories) do
        if categories[subcat.parent] then
            table.insert(categories[subcat.parent].subCategories, subcat)
        end
    end

    local orderedCategoryNames = {"Home", "Premium Time", "Consumables", "Cosmetics", "Houses", "Boosts", "Extras",
                                  "Tournament"}

    for _, categoryName in ipairs(orderedCategoryNames) do
        local category = categories[categoryName]
        if category then
            local widget = g_ui.createWidget("storeCategory", controllerShop.ui.listCategory)
            widget:setId(category.name)
            -- widget.Button.Icon:setIcon("/game_store/images/13/" .. category.icons[1])
            if category.icons[1] == "icon-store-home.png" then
                widget.Button.Icon:setIcon("/game_store/images/icon-store-home")
            else
                setImagenHttp(widget.Button.Icon, "/13/" .. category.icons[1], true)
            end

            widget.Button.Title:setText(category.name)
            widget.open = category.name

            if #category.subCategories > 0 then
                widget.subCategories = category.subCategories
                widget.subCategoriesSize = #category.subCategories
                widget.Button.Arrow:setVisible(true)

                for subId, subButton in ipairs(category.subCategories) do
                    local subWidget = createSubWidget(widget, subId, {
                        text = subButton.name,
                        icon = "/13/" .. subButton.icons[1],
                        open = subButton.name
                    })
                end
            end

            widget:setMarginTop(10)

            widget.Button.onClick = function()
                disableAllButtons()
                local parent = widget
                local oldOpen = controllerShop.ui.openedCategory
                local panel = controllerShop.ui.panelItem
                local btnBuy = panel:getChildById('btnBuy')
                local image = panel:getChildById('image')
                local lblPrice = panel:getChildById('lblPrice')

                btnBuy:disable()
                image:setImageSource("")
                lblPrice:setText("")

                local firstChild = image:getFirstChild()
                if image:getChildCount() ~= 0 and firstChild then
                    local styleClass = firstChild:getStyle().__class
                    if styleClass == "UIItem" then
                        firstChild:setItemId(nil)
                    elseif styleClass == "UICreature" then
                        firstChild:setOutfit({
                            type = nil
                        })
                    else
                        firstChild:setImageSource("")
                    end
                end

                if oldOpen and oldOpen ~= parent then
                    if oldOpen.Button then
                        oldOpen.Button:setChecked(false)
                        oldOpen.Button.Arrow:setImageSource("/images/ui/icon-arrow7x7-down")
                    end
                    close(oldOpen)
                end

                if parent.subCategoriesSize then
                    parent.closedSize = parent.closedSize or parent:getHeight() / (parent.subCategoriesSize + 1) + 15
                    parent.openedSize = parent.openedSize or parent:getHeight() * (parent.subCategoriesSize + 1) - 6

                    open(parent)

                else
                    widget.Button:setChecked(true)
                end

                widget.Button.Arrow:setImageSource("/images/ui/icon-arrow7x7-right")
                widget.Button.Arrow:setVisible(true)

                if controllerShop.ui.selectedOption then
                    controllerShop.ui.selectedOption:hide()
                end
                if category.name == "Home" then
                    controllerShop.ui.HomePanel.HomeRecentlyAdded.HomeProductos:destroyChildren()

                    g_game.requestStoreOffers("", GameStore.ActionType.OPEN_HOME)
                    controllerShop.ui.panelItem:setVisible(false)
                    controllerShop.ui.transferHistory:setVisible(false)
                    controllerShop.ui.HomePanel:setVisible(true)

                else

                    g_game.requestStoreOffers(category.name, GameStore.ActionType.OPEN_CATEGORY)
                    controllerShop.ui.panelItem:setVisible(true)
                    controllerShop.ui.transferHistory:setVisible(false)
                    controllerShop.ui.HomePanel:setVisible(false)

                end

                controllerShop.ui.openedCategory = parent
            end
        end
    end

end

-- /*=============================================
-- =            Botones                          =
-- =============================================*/

function hide()
    if not controllerShop.ui then
        return
    end
    controllerShop.ui:hide()
end

function toggle()
    if not controllerShop.ui then
        return
    end

    if controllerShop.ui:isVisible() then
        return hide()
    end
    show()

end

function show()
    if not controllerShop.ui then
        return
    end

    controllerShop.ui:show()
    controllerShop.ui:raise()
    controllerShop.ui:focus()

    g_game.openStore()
    controllerShop:scheduleEvent(function()

        local firstCategory = controllerShop.ui.listCategory:getChildByIndex(1)
        if firstCategory then
            controllerShop.ui.openedCategory = firstCategory
            firstCategory.Button:onClick()
        else
            g_logger.warning(
                "[game_store] function show() L815, increase scheduleEvent time 300 -> 500. reason: information is late in arriving ")
        end
    end, 300, 'fuck antibot')
end

function getCoinsWebsite()
    if GameStore.website.WEBSITE_GETCOINS ~= "" then
        g_platform.openUrl(GameStore.website.WEBSITE_GETCOINS)
    else
        sendMessageBox("Error", "No data for store URL.")
    end
end

function toggleTransferHistory()
    if controllerShop.ui.transferHistory:isVisible() then
        controllerShop.ui.transferHistory:setVisible(false)

        if controllerShop.ui.openedCategory:getId() == "Home" then
            controllerShop.ui.HomePanel:setVisible(true)

        else
            controllerShop.ui.panelItem:setVisible(true)
        end

    else
        controllerShop.ui.transferHistory:setVisible(true)
        -- listCategory:getFocusedChild():focus(false)
        controllerShop.ui.panelItem:setVisible(false)

        controllerShop.ui.HomePanel:setVisible(false)

        g_game.requestTransactionHistory()

    end
end
-- /*=============================================
-- =            focusedChild                     =
-- =============================================*/

function chooseOffert(self, focusedChild)
    if not focusedChild then
        return
    end

    local product = focusedChild.product
    local panel = controllerShop.ui.panelItem

    local descriptionInfo = offerDescriptions[product.subOffers[1].id] or {
        id = 0xFFFF,
        description = ""
    }

    panel:getChildById('lblName'):setText(product.name)
    panel:getChildById('lblDescription'):setText(descriptionInfo.description)

    local priceLabel = panel:getChildById('lblPrice')
    priceLabel:setText(product.subOffers[1].price)

    local data = getProductData(product)
    local imagePanel = panel:getChildById('image')
    imagePanel:destroyChildren()
    if data then
        createProductImage(imagePanel, data)
    end

    local coinsBalance2, coinsBalance1 = getCoinsBalance()
    local price = product.subOffers[1].price
    local btnBuy = panel:getChildById('btnBuy')

    local isTransferable = product.subOffers[1].coinType == GameStore.CoinType.Transferable
    local currentBalance = isTransferable and coinsBalance1 or coinsBalance2

    if isTransferable then
        priceLabel:setIcon("/game_store/images/icon-tibiacointransferable")
    else
        priceLabel:setIcon("/game_store/images/tibiaCoin")
    end

    if currentBalance < price then
        priceLabel:setColor("#d33c3c")
        btnBuy:disable()
    else
        priceLabel:setColor("white")
        btnBuy:enable()
    end

    btnBuy.onClick = function(widget)
        if acceptWindow then
            return true
        end

        local function acceptFunc()
            local latestBalance2, latestBalance1 = getCoinsBalance()
            local latestCurrentBalance = isTransferable and latestBalance1 or latestBalance2

            if latestCurrentBalance >= price then
                if product.name == "Character Name Change" then
                    displayErrorBox(controllerShop.ui:getText(), "no yet,UI missing")
                elseif product.name == "Hireling Apprentice" then
                    displayErrorBox(controllerShop.ui:getText(), "no yet, UI missing")
                else
                    g_game.buyStoreOffer(product.subOffers[1].id, product.type)
                end
                if acceptWindow then
                    acceptWindow:destroy()
                    acceptWindow = nil
                end
            else
                displayErrorBox(controllerShop.ui:getText(), tr("You don't have enough coins"))
                acceptWindow:destroy()
                acceptWindow = nil
            end
        end

        local function cancelFunc()
            acceptWindow:destroy()
            acceptWindow = nil
        end

        local coinType = isTransferable and "transferable coins" or "regular coins"
        local confirmationMessage = string.format('Do you want to buy the product "%s" for %d %s?', product.name, price,
            coinType)
        local detailsMessage = string.format("%dx %s\nPrice: %d %s", product.subOffers[1].count, product.name, price,
            coinType)

        acceptWindow = displayGeneralSHOPBox(tr('Confirmation of Purchase'), confirmationMessage, detailsMessage,
            getProductData(product), {
                {
                    text = tr('Buy'),
                    callback = acceptFunc
                },
                {
                    text = tr('Cancel'),
                    callback = cancelFunc
                },
                anchor = AnchorHorizontalCenter
            }, acceptFunc, cancelFunc)
    end
end

function onParseStoreError(errorMessage)
    displayErrorBox(controllerShop.ui:getText(), errorMessage)
end

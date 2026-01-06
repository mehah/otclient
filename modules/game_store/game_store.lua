-- Auxiliar miniWindows
local acceptWindow = nil
local changeNameWindow = nil
local transferPointsWindow = nil
local processingWindow = nil
local messageBox = nil


local oldProtocol = false
local a0xF2 = true

local offerDescriptions = {}
local reasonCategory = {}
local bannersHome = {}

local currentIndex = 1
local descriptionRequestEvent = nil
local descriptionRequestDelay = 100 -- ms, similar ao RTC Store.displayDescription

-- /*=============================================
-- =            To-do                  =
-- =============================================*/
-- - Fix filter functionality
-- - Correct HTML string syntax
-- - cache
-- - try on outfit
-- - improve homePanel/hystoryPanel

GameStore = {}
-- == Enums ==--

GameStore.website = {
    WEBSITE_GETCOINS = "https://teste.com",
    IMAGES_URL =  "http://217.196.60.153/store/" --./game_store --https://docs.opentibiabr.com/opentibiabr/downloads/website-applications/applications#store-for-client-13-1
}

GameStore.coins = 0
GameStore.transferableCoins = 0
GameStore.reservedCoins = 0
GameStore.coinsPacketSize = 25
GameStore.imageRequests = {}
GameStore.currentRequest = 0

GameStore.CoinType = {
    Coin = 0,
    Transferable = 1
}

GameStore.ClientOfferTypes = {
	CLIENT_STORE_OFFER_OTHER = 0,
	CLIENT_STORE_OFFER_NAMECHANGE = 1,
	CLIENT_STORE_OFFER_WORLD_TRANSFER = 2,
	CLIENT_STORE_OFFER_HIRELING = 3, --idk
	CLIENT_STORE_OFFER_CHARACTER = 4,--idk
	CLIENT_STORE_OFFER_TOURNAMENT = 5,--idk
	CLIENT_STORE_OFFER_CONFIRM = 6,--idk
}

GameStore.States = {
    STATE_NONE = 0,
    STATE_NEW = 1,
    STATE_SALE = 2,
    STATE_TIMED = 3
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

-- /*=============================================
-- =            Local Function auxiliaries      =
-- =============================================*/

local function showPanel(panel)
    if panel == "HomePanel" then
        controllerShop.ui.HomePanel:setVisible(true)
        controllerShop.ui.panelItem:setVisible(false)
        controllerShop.ui.transferHistory:setVisible(false)
    elseif panel == "transferHistory" then
        controllerShop.ui.HomePanel:setVisible(false)
        controllerShop.ui.panelItem:setVisible(false)
        controllerShop.ui.transferHistory:setVisible(true)
    elseif panel == "panelItem" then
        controllerShop.ui.HomePanel:setVisible(false)
        controllerShop.ui.panelItem:setVisible(true)
        controllerShop.ui.transferHistory:setVisible(false)
    end
end

local function destroyWindow(windows)
    if type(windows) == "table" then
        for _, window in ipairs(windows) do
            if window and not window:isDestroyed() then
                window:destroy()
                window = nil
            end
        end
    else
        if windows and not windows:isDestroyed() then
            windows:destroy()
            windows = nil
        end
    end
end

local function getPageLabelHistory()
    local text = controllerShop.ui.transferHistory.lblPage:getText()
    local currentPage, pageCount = text:match("Page (%d+)/(%d+)")
    return tonumber(currentPage), tonumber(pageCount)
end

local function setImagenHttp(widget, url, isIcon)
    if GameStore.website.IMAGES_URL then
        HTTP.downloadImage(GameStore.website.IMAGES_URL .. url, function(path, err)
            if err then
                if DEVELOPERMODE then
                    g_logger.warning("HTTP error: " .. err .. " - " .. GameStore.website.IMAGES_URL .. url)
                end
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

local function formatNumberWithCommas(value)
    if not value or value == 0 then
        return "0"
    end
    local sign = value < 0 and "-" or ""
    value = math.abs(value)
    local formattedValue = string.format("%d", value)
    formattedValue = formattedValue:reverse():gsub("(%d%d%d)", "%1,")
    formattedValue = formattedValue:reverse():gsub("^,", "")
    return sign .. formattedValue
end

local function formatMoney(value, separator)
    return formatNumberWithCommas(value)
end

local function getCoinsBalance()
    -- Try to get from GameStore first (more reliable)
    if GameStore.coins and GameStore.transferableCoins then
        return GameStore.coins, GameStore.transferableCoins
    end
    
    local function extractNumber(text)
        if type(text) ~= "string" then 
            return 0 
        end
        local numberStr = text:match("%d[%d,]*")
        if not numberStr then 
            return 0 
        end
        local cleanNumber = numberStr:gsub("[^%d]", "")
        return tonumber(cleanNumber) or 0
    end

    -- get coins: normal (non transferableCoins) | transfer(transferableCoins))
    local lblNormal = controllerShop.ui.lblCoins.lblTibiaCoins
    local lblTransfer = controllerShop.ui.lblCoins.lblTibiaTransfer

    local normalCoins = lblNormal and extractNumber(lblNormal:getText()) or 0
    local transferableCoins = lblTransfer and extractNumber(lblTransfer:getText()) or 0

    return normalCoins, transferableCoins
end

local function fixServerNoSend0xF2()
    if a0xF2 then
        local player = g_game.getLocalPlayer()
        if not player then
            return
        end
        
        local coin, transfer = getCoinsBalance()
        local coinBalance = player:getResourceBalance(ResourceTypes.COIN_NORMAL)
        local transferBalance = player:getResourceBalance(ResourceTypes.COIN_TRANSFERRABLE)
        
        if not coin or not transfer or coin ~= coinBalance or transfer ~= transferBalance then
            GameStore.coins = coinBalance
            GameStore.transferableCoins = transferBalance
            
            controllerShop.ui.lblCoins.lblTibiaCoins:setText(formatNumberWithCommas(coinBalance))
    
            if transfer ~= transferBalance then
                controllerShop.ui.lblCoins.lblTibiaTransfer:setText(
                    string.format("(Including: %s", formatNumberWithCommas(transferBalance))
                )
            end
            
            if DEVELOPERMODE then
                local packet2 = GameStore.SendingPackets.S_CoinBalanceUpdating
                g_logger.warning(string.format("[game_store BUG] Check 0x%X (%d) on server onParseStoreGetCoin", packet2, packet2))
            end
        end 
    end
end

local function convert_timestamp(timestamp)
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
    elseif product.mountClientId then
        -- Servidor envia mountClientId diretamente para mounts
        return {
            VALOR = "mountId",
            ID = product.mountClientId
        }
    else
        return nil
    end
end

local function createProductImage(imageParent, data, isDetailPanel)
    if data.VALOR == "item" then
        local itemWidget = g_ui.createWidget('StoreListItem', imageParent)
        itemWidget:setId(data.ID)
        itemWidget:setItemId(data.ID)
        itemWidget:setVirtual(true)
        local itemSize = isDetailPanel and 64 or 32
        itemWidget:resize(itemSize, itemSize)
        itemWidget:setFixedSize(true)
        itemWidget:centerIn('parent')
    elseif data.VALOR == "icon" then
        local widget = g_ui.createWidget('UIWidget', imageParent)
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

-- /*=============================================
-- =    behavior categories and subcategories    =
-- =============================================*/

local function disableAllButtons()
    local panel = controllerShop.ui.panelItem
    local btnBuy1 = panel:getChildById('btnBuy1')
    local btnBuy2 = panel:getChildById('btnBuy2')
    local lblPrice1 = panel:getChildById('lblPrice1')
    local lblPrice2 = panel:getChildById('lblPrice2')
    
    if btnBuy1 then
        btnBuy1:setVisible(false)
        btnBuy1:setEnabled(false)
    end
    if btnBuy2 then
        btnBuy2:setVisible(false)
        btnBuy2:setEnabled(false)
    end
    if lblPrice1 then
        lblPrice1:setVisible(false)
    end
    if lblPrice2 then
        lblPrice2:setVisible(false)
    end
    
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

local function closeCategoryButtons()
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
        closeCategoryButtons()
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
            g_game.sendRequestStoreHome()
        else
            g_game.requestStoreOffers(subButton.text,"", 0, 1)
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

-- /*=============================================
-- =            Controller                   =
-- =============================================*/
controllerShop = Controller:new()
g_ui.importStyle("style/ui.otui")
controllerShop:setUI('game_store')
function controllerShop:onInit()
    controllerShop.ui:hide()

    for k, v in pairs({{'Most Popular Fist', 'MostPopularFist'}, {'Alphabetically', 'Alphabetically'},
                       {'Newest Fist', 'NewestFist'}}) do
        controllerShop.ui.panelItem.comboBoxContainer.MostPopularFirst:addOption(v[1], v[2])
    end

    controllerShop.ui.transferPoints.onClick = onGiftWindow
    controllerShop.ui.panelItem.listProduct.onChildFocusChange = chooseOffert
    controllerShop.ui.HomePanel.HomeRecentlyAdded.HomeProductos.onChildFocusChange = chooseHome

    -- Configurar busca - botão desabilitado por padrão
    controllerShop:scheduleEvent(function()
        if controllerShop.ui.SearchClearButton then
            controllerShop.ui.SearchClearButton:setEnabled(false)
            controllerShop.ui.SearchClearButton:setOpacity(0.5)
        end

        -- Registrar eventos de busca após a UI ser carregada
        if controllerShop.ui.SearchEdit then
            connect(controllerShop.ui.SearchEdit, {
                onTextChange = onSearchEdit,
                onEnter = onEnterSearch
            })
        end
    end, 100)
    -- /*=============================================
    -- =            Parse                         =
    -- =============================================*/

    controllerShop:registerEvents(g_game, {
        onParseStoreGetCoin = onParseStoreGetCoin,
        onParseStoreGetCategories = onParseStoreGetCategories,
        onParseStoreCreateHome = onParseStoreCreateHome,
        onParseStoreCreateProducts = onParseStoreCreateProducts,
        onParseStoreGetHistory = onParseStoreGetHistory,
        onParseStoreGetPurchaseStatus = onParseStoreGetPurchaseStatus,
        onParseStoreOfferDescriptions = onParseStoreOfferDescriptions,
        onParseStoreError = onParseStoreError,
        onStoreInit = onStoreInit
    })
end

function controllerShop:onGameStart()
    oldProtocol = g_game.getClientVersion() < 1310
end

function controllerShop:onGameEnd()
    if controllerShop.ui:isVisible() then
        controllerShop.ui:hide()
    end

    destroyWindow({transferPointsWindow, changeNameWindow, acceptWindow, processingWindow,messageBox})
end

function controllerShop:onTerminate()
    destroyWindow({transferPointsWindow, changeNameWindow, acceptWindow, processingWindow,messageBox})
end

-- /*=============================================
-- =            Parse                           =
-- =============================================*/

function onStoreInit(url, coinsPacketSize)
    if not GameStore.website.IMAGES_URL then
        GameStore.website.IMAGES_URL = url
    end
    GameStore.coinsPacketSize = coinsPacketSize or 25
end

function onParseStoreGetCoin(getTibiaCoins, getTransferableCoins, reservedCoins)
    a0xF2 = false
    GameStore.coins = getTibiaCoins or 0
    GameStore.transferableCoins = getTransferableCoins or 0
    GameStore.reservedCoins = reservedCoins or 0
    
    controllerShop.ui.lblCoins.lblTibiaCoins:setText(formatNumberWithCommas(getTibiaCoins))
    controllerShop.ui.lblCoins.lblTibiaTransfer:setText(string.format("(Including: %s",
        formatNumberWithCommas(getTransferableCoins)))
end

function onParseStoreOfferDescriptions(offerId, description)
    offerDescriptions[offerId] = {
        id = offerId,
        description = description
    }
    
    -- Atualizar descrição na UI se a oferta estiver selecionada
    if controllerShop and controllerShop.ui and controllerShop.ui.panelItem then
        local panel = controllerShop.ui.panelItem
        local listProduct = panel:getChildById('listProduct')
        if listProduct then
            local focusedChild = listProduct:getFocusedChild()
            if focusedChild and focusedChild.product then
                local product = focusedChild.product
                local subOffers = product.subOffers or {}
                local currentOfferId = not table.empty(subOffers) and subOffers[1].id or product.id
                
                if currentOfferId == offerId then
                    local lblDescription = panel:getChildById('lblDescription')
                    if lblDescription then
                        -- Converter quebras de linha para exibição
                        local displayDescription = description:gsub("\n", " ")
                        lblDescription:setText(displayDescription)
                    end
                end
            end
        end
    end
end

local function requestOfferDescription(offerId)
    if descriptionRequestEvent then
        removeEvent(descriptionRequestEvent)
        descriptionRequestEvent = nil
    end
    
    descriptionRequestEvent = scheduleEvent(function()
        if g_game.requestOfferDescription then
            g_game.requestOfferDescription(offerId)
        end
        descriptionRequestEvent = nil
    end, descriptionRequestDelay)
end

function onParseStoreGetPurchaseStatus(purchaseStatus)
    destroyWindow({processingWindow, messageBox})
    controllerShop.ui:hide()
    messageBox = g_ui.createWidget('confirmarSHOP', g_ui.getRootWidget())
    messageBox.Box:setText(purchaseStatus)
    messageBox.buttonAnimation.animation:setImageClip("0 0 108 108")
    messageBox.buttonAnimation.onClick = function(widget)
        messageBox.buttonAnimation:disable()
        local phase = 0
        local animationEvent = periodicalEvent(function()
            if messageBox and messageBox.buttonAnimation and messageBox.buttonAnimation.animation then
                messageBox.buttonAnimation.animation:setImageClip((phase % 13 * 108) .. " 0 108 108")
                phase = phase + 1
                if phase >= 12 then
                    phase = 11
                end
            end
        end, function()
            return messageBox and messageBox.buttonAnimation and messageBox.buttonAnimation.animation
        end, 120, 120)
        controllerShop:scheduleEvent(function()
            destroyWindow({messageBox})
            controllerShop.ui:show()
            if animationEvent then
                removeEvent(animationEvent)
                animationEvent = nil
            end
            fixServerNoSend0xF2()
            g_game.sendRequestStorePremiumBoost() -- fix: request and refresh store to prevent XP Boost purchase bug
        end, 2000)
    end
end

function onParseStoreCreateProducts(storeProducts)
    -- Se for resultado de busca, fechar categorias abertas
    if storeProducts.categoryName == "Search" then
        if controllerShop.ui.openedCategory ~= nil then
            close(controllerShop.ui.openedCategory)
        end
    end
    
    local comboBox = controllerShop.ui.panelItem.comboBoxContainer.showAll
    comboBox:clearOptions()
    comboBox:addOption("Disable", 0)

    if #storeProducts.menuFilter > 0 then
        for k, t in pairs(storeProducts.menuFilter) do
            comboBox:addOption(t, k - 1)
        end
--[[         comboBox.onOptionChange = function(a, b, c, d)
            pdump(a:getCurrentOption())
        end ]]
    end
    reasonCategory = storeProducts.disableReasons
    local listProduct = controllerShop.ui.panelItem.listProduct
    listProduct:destroyChildren()
    if not storeProducts then
        return
    end

    -- Verificar se não há resultados (especialmente para busca)
    if storeProducts.categoryName == "Search" then
        if not storeProducts.offers or #storeProducts.offers == 0 then
            local noResultsLabel = g_ui.createWidget('UIWidget', listProduct)
            noResultsLabel:setSize('100% 50')
            noResultsLabel:setTextAlign(AlignCenter)
            noResultsLabel:setText('No items found matching your search.')
            noResultsLabel:setColor('#ff6666')
            noResultsLabel:setFont('verdana-11px-rounded')
            showPanel("panelItem")
            return
        end
        
        -- Verificar se há muitos resultados
        if storeProducts.tooManyResults then
            local warningLabel = g_ui.createWidget('UIWidget', listProduct)
            warningLabel:setSize('100% 30')
            warningLabel:setTextAlign(AlignCenter)
            warningLabel:setText('Too many results. Please refine your search.')
            warningLabel:setColor('#ffaa00')
            warningLabel:setFont('verdana-11px-rounded')
        end
    end
    for _, product in ipairs(storeProducts.offers) do
        local row = g_ui.createWidget('RowStore', listProduct)
        row.product, row.type = product, product.type

        local nameLabel = row:getChildById('lblName')
        nameLabel:setText(product.name)
        nameLabel:setTextAlign(AlignCenter)
        nameLabel:setMarginRight(10)

        local subOffers = product.subOffers or { product }
        for _, subOffer in ipairs(subOffers) do
            local offerI = g_ui.createWidget('stackOfferPanel', row:getChildById('StackOffers'))
            offerI:setId(subOffer.id)
            if subOffer.disabled then
                offerI:disable()
                row:setOpacity(0.5)
            end
            local priceLabel = offerI:getChildById('lblPrice')
            if subOffer.price > 0 then
                priceLabel:setText(formatMoney(subOffer.price, ","))
            else
                priceLabel:setText("Free")
            end

            if subOffer.count and subOffer.count > 0 then
                offerI:getChildById('count'):setText(subOffer.count .. "x")
            end
            fixServerNoSend0xF2()
            local coinsBalance2, coinsBalance1 = getCoinsBalance()
            local isTransferable = subOffer.coinType == GameStore.CoinType.Transferable
            local price = subOffer.price
            local balance = isTransferable and coinsBalance1 or (coinsBalance1 + coinsBalance2)
            priceLabel:setColor(balance < price and "#d33c3c" or "white")

            if isTransferable then
                priceLabel:setIcon("/game_store/images/icon-tibiacointransferable")
            end
        end
        local data = getProductData(product)
        if data then
            createProductImage(row:getChildById('image'), data)
        end
    end

    controllerShop:scheduleEvent(function()
        local redirectId = storeProducts.redirectId
        if redirectId and type(redirectId) == "number" and redirectId ~= 0 then -- home behavior 
            for _, child in ipairs(listProduct:getChildren()) do
                for _, subOffer in ipairs(child.product.subOffers or { child.product }) do
                    if subOffer.id == redirectId then
                        listProduct:focusChild(child)
                        listProduct:ensureChildVisible(child)
                        return
                end
            end
        end
    else
            local firstChild = listProduct:getFirstChild()
            if firstChild and firstChild:isEnabled() then
                listProduct:focusChild(firstChild)
                listProduct:ensureChildVisible(firstChild)
            end
        end
    end, 300, 'onParseStoreOfferDescriptionsSafeDelay')

    enableAllButtons()
    showPanel("panelItem")
    fixServerNoSend0xF2()
end

function onParseStoreCreateHome(offer)
    local homeProductos = controllerShop.ui.HomePanel.HomeRecentlyAdded.HomeProductos
    for _, product in ipairs(offer.offers) do
        local row = g_ui.createWidget('RowStore', homeProductos)
        row.product, row.type = product, product.type

        local nameLabel = row:getChildById('lblName')
        nameLabel:setText(product.name)
        nameLabel:setTextAlign(AlignCenter)
        nameLabel:setMarginRight(10)

        local subOfferWidget = g_ui.createWidget('stackOfferPanel', row:getChildById('StackOffers'))

        if product.price > 0 then
            subOfferWidget.lblPrice:setText(formatMoney(product.price, ","))
        else
            subOfferWidget.lblPrice:setText("Free")
        end
        if product.coinType == GameStore.CoinType.Transferable then
            subOfferWidget.lblPrice:setIcon("/game_store/images/icon-tibiacointransferable")
        end

        local data = getProductData(product)
        if data then
            createProductImage(row:getChildById('image'), data)
        end
    end

    -- Se não há banners no offer, tentar carregar banners padrão ou usar imagem local
    if not offer.banners or #offer.banners == 0 then
        -- Tentar usar banners locais se disponíveis
        local defaultBanners = {
            { image = "home/bogtyrant_small_goldenborder.jpg" },
            { image = "home/bladedancer_small_goldenborder.jpg" },
            { image = "home/dawnbringer_pegasus_small_goldenborder.jpg" }
        }
        bannersHome = table.copy(defaultBanners)
        local ramdomImg = defaultBanners[math.random(1, #defaultBanners)].image
        setImagenHttp(controllerShop.ui.HomePanel.HomeImagen, ramdomImg, false)
    else
        local ramdomImg = offer.banners[math.random(1, #offer.banners)].image
        setImagenHttp(controllerShop.ui.HomePanel.HomeImagen, ramdomImg, false)
        bannersHome = table.copy(offer.banners)
    end

    enableAllButtons()
    showPanel("HomePanel")
    fixServerNoSend0xF2()
end

function onParseStoreGetHistory(currentPage, pageCount, historyData)
    local transferHistory = controllerShop.ui.transferHistory.historyPanel
    transferHistory:destroyChildren()
    local headerRow = g_ui.createWidget("historyData2", transferHistory)
    headerRow:setBackgroundColor("#363636")
    headerRow:setBorderColor("#00000077")
    headerRow:setBorderWidth(1)
    headerRow.date:setText("Date")
    headerRow.Balance:setText("Balance")
    headerRow.Description:setText("Description")
    controllerShop.ui.transferHistory.lblPage:setText(string.format("Page %d/%d", currentPage + 1, pageCount))
    for i, data in ipairs(historyData) do
        local row = g_ui.createWidget("historyData2", transferHistory)
        row.date:setText(convert_timestamp(data[1]))
        local balance = data[3]
        row.Balance:setText(formatNumberWithCommas(balance))
        row.Balance:setColor(balance < 0 and "#D33C3C" or "#3CD33C")
        row.Description:setText(data[5])
        row.Balance:setIcon(data[4] == GameStore.CoinType.Transferable and 
                            "/game_store/images/icon-tibiacointransferable" or 
                            "images/ui/tibiaCoin")
        row:setBackgroundColor(i % 2 == 0 and "#ffffff12" or "#00000012")
    end
    showPanel("transferHistory")
end

function onParseStoreGetCategories(buttons)
    if controllerShop.ui.listCategory:getChildCount() > 0 then
        return
    end
    controllerShop.ui.listCategory:destroyChildren()

    local categories = {}
    local categoryOrder = {} -- Para manter a ordem das categorias principais

    local subcategories = {}

    for _, button in ipairs(buttons) do
        if not button.parent then
            categories[button.name] = button
            categories[button.name].subCategories = {}
            table.insert(categoryOrder, button.name) -- Manter ordem de recebimento
        else
            table.insert(subcategories, button)
        end
    end

    -- Adicionar categoria Home apenas se não foi enviada pelo servidor
    if not oldProtocol and not categories["Home"] then
        categories["Home"] = {
            ["subCategories"] = {},
            ["name"] = "Home",
            ["icons"] = {
                [1] = "icon-store-home.png"
            },
            ["state"] = 0
        }
        table.insert(categoryOrder, 1, "Home") -- Inserir no início se não existir
    end

    for _, subcat in ipairs(subcategories) do
        if categories[subcat.parent] then
            table.insert(categories[subcat.parent].subCategories, subcat)
        end
    end

    -- Usar a ordem de recebimento em vez de ordenação por prioridade
    local categoryArray = {}
    for _, name in ipairs(categoryOrder) do
        table.insert(categoryArray, categories[name])
    end


    for _, category in ipairs(categoryArray) do
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
                local parent = widget
                local oldOpen = controllerShop.ui.openedCategory

                -- Se a categoria clicada já está aberta, fechar ela
                if oldOpen and oldOpen == parent then
                    if parent.Button then
                        parent.Button:setChecked(false)
                        parent.Button.Arrow:setImageSource("/images/ui/icon-arrow7x7-down")
                    end
                    close(parent)
                    controllerShop.ui.openedCategory = nil
                    return
                end

                disableAllButtons()
                local panel = controllerShop.ui.panelItem
                local image = panel:getChildById('image')
                local btnBuy1 = panel:getChildById('btnBuy1')
                local btnBuy2 = panel:getChildById('btnBuy2')
                local lblPrice1 = panel:getChildById('lblPrice1')
                local lblPrice2 = panel:getChildById('lblPrice2')

                image:setImageSource("")
                if btnBuy1 then
                    btnBuy1:setVisible(false)
                end
                if btnBuy2 then
                    btnBuy2:setVisible(false)
                end
                if lblPrice1 then
                    lblPrice1:setVisible(false)
                end
                if lblPrice2 then
                    lblPrice2:setVisible(false)
                end

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
                    g_game.sendRequestStoreHome()
                    -- Não chamar showPanel aqui se for abertura automática (sem categoria anterior)
                    if controllerShop.ui.openedCategory then
                        showPanel("HomePanel")
                    end
                else
                    g_game.requestStoreOffers(category.name,"", 0, 1)
                end
                controllerShop.ui.openedCategory = parent
            end
        end

        -- Tentar abrir a categoria "Home" automaticamente, independente da ordem
        if controllerShop.ui.openedCategory == nil then
            -- Primeiro tentar encontrar a categoria "Home" especificamente
            local homeCategory = nil
            for i = 1, controllerShop.ui.listCategory:getChildCount() do
                local category = controllerShop.ui.listCategory:getChildByIndex(i)
                if category and category:getId() == "Home" then
                    homeCategory = category
                    break
                end
            end

            -- Se não encontrou Home, usar a primeira categoria disponível
            if not homeCategory then
                homeCategory = controllerShop.ui.listCategory:getChildByIndex(1)
            end

            if homeCategory then
                -- Não definir openedCategory aqui, deixar o onClick fazer isso
                homeCategory.Button:onClick()
            end
        end

end

function onParseStoreError(errorMessage)
    destroyWindow(processingWindow)
    displayErrorBox(controllerShop.ui:getText(), errorMessage)
end

-- /*=============================================
-- =            buttons                          =
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
        if controllerShop.ui.listCategory:getChildCount() == 0 then
            g_game.sendRequestStoreHome() -- fix 13.10
            local packet1 = GameStore.RecivedPackets.C_OpenStore
            g_logger.warning(string.format("[game_store BUG] Check 0x%X (%d) L827", packet1, packet1))
        end
    end, 1000, function() return 'serverNoSendPackets0xF20xFA' end)
end

function getUI()
    return controllerShop.ui
end

function getCoinsWebsite()
    if GameStore.website.WEBSITE_GETCOINS ~= "" then
        g_platform.openUrl(GameStore.website.WEBSITE_GETCOINS)
    else
        sendMessageBox("Error", "No data for store URL.")
    end
end
-- /*=============================================
-- =            History                         =
-- =============================================*/

function toggleTransferHistory()
    if controllerShop.ui.transferHistory:isVisible() then
        if controllerShop.ui.openedCategory and controllerShop.ui.openedCategory:getId() == "Home" then
            showPanel("HomePanel")
        else
            showPanel("panelItem")
        end
    else
        g_game.requestTransactionHistory()
    end
end

function requestTransactionHistory(widget)
    local currentPage, pageCount = getPageLabelHistory()
    local newPage = currentPage + (widget:getId() == "btnNextPage" and 1 or -1)
    
    if newPage > 0 and newPage <= pageCount then
        g_game.requestTransactionHistory(newPage - 1)
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
    panel:getChildById('lblName'):setText(product.name)
    
    -- Buscar descrição da oferta selecionada
    local description = product.description or ""
    local subOffers = product.subOffers or {}
    local offerId = product.id
    
    -- Se houver sub-ofertas, usar a primeira para buscar descrição
    if not table.empty(subOffers) then
        offerId = subOffers[1].id
        local descriptionInfo = offerDescriptions[offerId] or { id = 0xFFFF, description = "" }
        description = descriptionInfo.description or ""
    else
        -- Tentar buscar descrição da oferta principal
        local descriptionInfo = offerDescriptions[offerId] or { id = 0xFFFF, description = "" }
        if descriptionInfo.description then
            description = descriptionInfo.description
        end
    end
    
    -- Solicitar descrição se não estiver disponível (com delay como no RTC)
    if description == "" and offerId and offerId ~= 0xFFFF then
        requestOfferDescription(offerId)
    end

    local lblDescription = panel:getChildById('lblDescription')
    if lblDescription then
        lblDescription:setText(description)
    end

    local data = getProductData(product)
    local imagePanel = panel:getChildById('image')
    imagePanel:destroyChildren()
    if data then
        createProductImage(imagePanel, data, true)
    end
    fixServerNoSend0xF2()

    -- example use getCoinsBalance
    local normalCoins, transferableCoins = getCoinsBalance()
    
    local buyButtonsPanel = panel:getChildById('buyButtonsPanel')
    if not buyButtonsPanel then
        g_logger.error("buyButtonsPanel not found")
        return
    end
    
    local btnBuy1 = buyButtonsPanel:getChildById('btnBuy1')
    local btnBuy2 = buyButtonsPanel:getChildById('btnBuy2')
    local lblPrice1 = buyButtonsPanel:getChildById('lblPrice1')
    local lblPrice2 = buyButtonsPanel:getChildById('lblPrice2')
    
    if not btnBuy1 or not lblPrice1 then
        g_logger.error("Failed to find btnBuy1 or lblPrice1 in buyButtonsPanel")
        return
    end
    
    buyButtonsPanel:setVisible(true)

    local offers = not table.empty(subOffers) and subOffers or { product }
    
    -- Primeira oferta (sempre visível)
    local offer1 = offers[1]
    if offer1 then
        if offer1.price > 0 then
            lblPrice1:setText(formatMoney(offer1.price, ","))
        else
            lblPrice1:setText("Free")
        end

        local itemCount1 = (offer1.count and offer1.count > 0) and offer1.count or 1
        if product.configurable then
            btnBuy1:setText("Configurable")
        else
            btnBuy1:setText("Buy " .. itemCount1)
        end
        
        btnBuy1:setVisible(true)
        btnBuy1:setEnabled(true)
        btnBuy1:setOpacity(1.0)
        lblPrice1:setVisible(true)

        local isTransferable1 = offer1.coinType == GameStore.CoinType.Transferable
        local currentBalance1 = isTransferable1 and transferableCoins or (normalCoins + transferableCoins)

        if isTransferable1 then
            lblPrice1:setIcon("/game_store/images/icon-tibiacointransferable")
        else
            lblPrice1:setIcon("images/ui/tibiaCoin")
        end

        if currentBalance1 < offer1.price then
            lblPrice1:setColor("#d33c3c")
            btnBuy1:disable()
        else
            lblPrice1:setColor("white")
            btnBuy1:enable()
        end

        if offer1.disabled then
            btnBuy1:disable()
            btnBuy1:setOpacity(0.8)
            if offer1.reasonIdDisable then
                local reasonText = oldProtocol and offer1.reasonIdDisable or reasonCategory[offer1.reasonIdDisable + 1]
                btnBuy1:setTooltip(string.format(
                    "The product is not available for this character:\n\n- %s",
                    reasonText
                ))
            end
        else
            btnBuy1:setTooltip('')
        end

        btnBuy1.onClick = function(widget)
            if acceptWindow then
                destroyWindow(acceptWindow)
            end

            if product.configurable or product.name == "Character Name Change" then
                return displayChangeName(offer)
            end

            if product.name == "Hireling Apprentice" then
                return displayErrorBox(controllerShop.ui:getText(), "not yet, UI missing")
            end

            local function acceptFunc()
                fixServerNoSend0xF2()
                local latestNormal, latestTransferable = getCoinsBalance()
                local latestCurrentBalance = isTransferable and latestTransferable or (latestNormal + latestTransferable)

                if latestCurrentBalance >= offer.price then
                    g_game.buyStoreOffer(offer.id, GameStore.ClientOfferTypes.CLIENT_STORE_OFFER_OTHER)
                    local closeWindow = function() destroyWindow(processingWindow) end
                    controllerShop.ui:hide()
                    processingWindow = displayGeneralBox(
                        'Processing purchase.', 
                        'Your purchase is being processed',
                        {
                          { text = tr('ok'),  callback = closeWindow },
                          anchor = 50
                        }, 
                        closeWindow, 
                        closeWindow
                    )
                else
                    displayErrorBox(controllerShop.ui:getText(), tr("You don't have enough coins"))
                end
                destroyWindow(acceptWindow)
            end

            local function cancelFunc()
                destroyWindow(acceptWindow)
            end

            local coinType = isTransferable and "transferable coins" or "regular coins"
            local confirmationMessage = string.format(
                'Do you want to buy the product "%s" for %d %s?', 
                product.name, 
                offer.price, 
                coinType
            )

            local itemCountConfirm = (offer.count and offer.count > 0) and offer.count or 1
            local detailsMessage = string.format(
                "%dx %s\nPrice: %d %s",
                itemCountConfirm,
                product.name,
                offer.price,
                coinType
            )

            acceptWindow = displayGeneralSHOPBox(
                tr('Confirmation of Purchase'),
                confirmationMessage,
                detailsMessage,
                {
                    { text = tr('Buy'), callback = acceptFunc },
                    { text = tr('Cancel'), callback = cancelFunc },
                    anchor = AnchorHorizontalCenter
                },
                acceptFunc,
                cancelFunc
            )
            if data then
                createProductImage(acceptWindow.Box, data)
            end
        end
    end
    
    -- Segunda oferta (se houver)
    if #offers > 1 then
        if not btnBuy2 or not lblPrice2 then
            g_logger.warning("btnBuy2 or lblPrice2 not found for second offer")
        else
        local offer2 = offers[2]
        if offer2.price > 0 then
            lblPrice2:setText(formatMoney(offer2.price, ","))
        else
            lblPrice2:setText("Free")
        end

        local itemCount2 = (offer2.count and offer2.count > 0) and offer2.count or 1
        btnBuy2:setText("Buy " .. itemCount2)
        btnBuy2:setVisible(true)
        btnBuy2:setEnabled(true)
        btnBuy2:setOpacity(1.0)
        lblPrice2:setVisible(true)

        local isTransferable2 = offer2.coinType == GameStore.CoinType.Transferable
        local currentBalance2 = isTransferable2 and transferableCoins or (normalCoins + transferableCoins)

        if isTransferable2 then
            lblPrice2:setIcon("/game_store/images/icon-tibiacointransferable")
        else
            lblPrice2:setIcon("images/ui/tibiaCoin")
        end

        if currentBalance2 < offer2.price then
            lblPrice2:setColor("#d33c3c")
            btnBuy2:disable()
        else
            lblPrice2:setColor("white")
            btnBuy2:enable()
        end

        if offer2.disabled then
            btnBuy2:disable()
            btnBuy2:setOpacity(0.8)
            if offer2.reasonIdDisable then
                local reasonText = oldProtocol and offer2.reasonIdDisable or reasonCategory[offer2.reasonIdDisable + 1]
                btnBuy2:setTooltip(string.format(
                    "The product is not available for this character:\n\n- %s",
                    reasonText
                ))
            end
        else
            btnBuy2:setTooltip('')
        end

        -- Mostrar preço em transferable coins como informação adicional
        -- mesmo quando há segunda oferta
        if transferableCoins > 0 and offer1 and offer1.price and offer1.price > 0 then
            -- Adicionar tooltip ou informação adicional sobre preço em transferable coins
            local transferablePriceText = string.format("Transferable: %s", formatMoney(offer1.price, ","))
            local currentTooltip = btnBuy2:getTooltip()
            if currentTooltip and currentTooltip ~= "" then
                btnBuy2:setTooltip(currentTooltip .. "\n" .. transferablePriceText)
            else
                btnBuy2:setTooltip(transferablePriceText)
            end
        end

        btnBuy2.onClick = function(widget)
            if acceptWindow then
                destroyWindow(acceptWindow)
            end

            if product.configurable or product.name == "Character Name Change" then
                return displayChangeName(offer2)
            end

            if product.name == "Hireling Apprentice" then
                return displayErrorBox(controllerShop.ui:getText(), "not yet, UI missing")
            end

            local function acceptFunc()
                fixServerNoSend0xF2()
                local latestNormal, latestTransferable = getCoinsBalance()
                local latestCurrentBalance = isTransferable2 and latestTransferable or (latestNormal + latestTransferable)

                if latestCurrentBalance >= offer2.price then
                    g_game.buyStoreOffer(offer2.id, GameStore.ClientOfferTypes.CLIENT_STORE_OFFER_OTHER)
                    local closeWindow = function() destroyWindow(processingWindow) end
                    controllerShop.ui:hide()
                    processingWindow = displayGeneralBox(
                        'Processing purchase.', 
                        'Your purchase is being processed',
                        {
                          { text = tr('ok'),  callback = closeWindow },
                          anchor = 50
                        }, 
                        closeWindow, 
                        closeWindow
                    )
                else
                    displayErrorBox(controllerShop.ui:getText(), tr("You don't have enough coins"))
                end
                destroyWindow(acceptWindow)
            end

            local function cancelFunc()
                destroyWindow(acceptWindow)
            end

            local coinType = isTransferable2 and "transferable coins" or "regular coins"
            local confirmationMessage = string.format(
                'Do you want to buy the product "%s" for %d %s?', 
                product.name, 
                offer2.price, 
                coinType
            )

            local itemCountConfirm = (offer2.count and offer2.count > 0) and offer2.count or 1
            local detailsMessage = string.format(
                "%dx %s\nPrice: %d %s",
                itemCountConfirm,
                product.name,
                offer2.price,
                coinType
            )

            acceptWindow = displayGeneralSHOPBox(
                tr('Confirmation of Purchase'),
                confirmationMessage,
                detailsMessage,
                {
                    { text = tr('Buy'), callback = acceptFunc },
                    { text = tr('Cancel'), callback = cancelFunc },
                    anchor = AnchorHorizontalCenter
                },
                acceptFunc,
                cancelFunc
            )
            if data then
                createProductImage(acceptWindow.Box, data)
            end
        end
        end
    else
        if btnBuy2 then
            btnBuy2:setVisible(false)
        end
        if lblPrice2 then
            lblPrice2:setVisible(false)
        end
    end
end


-- /*=============================================
-- =            Home                             =
-- =============================================*/

function chooseHome(self, focusedChild)
    if not focusedChild then
        return
    end
    local product = focusedChild.product
    local panel = controllerShop.ui.HomePanel.HomeRecentlyAdded.HomeProductos
    g_game.sendRequestStoreOfferById(product.id)
end

function changeImagenHome(direction)
    -- Verificar se bannersHome não está vazio
    if not bannersHome or #bannersHome == 0 then
        print("DEBUG: bannersHome está vazio, não é possível trocar imagem")
        return
    end

    if direction == "nextImagen" then
        currentIndex = currentIndex + 1
        if currentIndex > #bannersHome then
            currentIndex = 1
        end
    elseif direction == "prevImagen" then
        currentIndex = currentIndex - 1
        if currentIndex < 1 then
            currentIndex = #bannersHome
        end
    end
    local currentBanner = bannersHome[currentIndex]
    if currentBanner and currentBanner.image then
        local imagePath = currentBanner.image
        setImagenHttp(controllerShop.ui.HomePanel.HomeImagen, imagePath, false)
    else
        print("DEBUG: currentBanner ou image está nil")
    end
end

-- /*=============================================
-- =            Behavior  Change Name            =
-- =============================================*/

function displayChangeName(offer)
    controllerShop.ui:hide()
    g_game.buyStoreOffer(offer.id, GameStore.ClientOfferTypes.CLIENT_STORE_OFFER_OTHER) -- canary send this packets?
    destroyWindow(changeNameWindow)
    changeNameWindow = g_ui.displayUI('style/changename')
    changeNameWindow:show()
    local newName = changeNameWindow:getChildById('transferPointsText')
    newName:setText('')
    local function closeWindow()
        newName:setText('')
        changeNameWindow:setVisible(false)
    end
    changeNameWindow.closeButton.onClick = closeWindow
    changeNameWindow.buttonOk.onClick = function()
        g_game.buyStoreOffer(offer.id, GameStore.ClientOfferTypes.CLIENT_STORE_OFFER_NAMECHANGE,newName:getText() )
        closeWindow()
    end
    changeNameWindow.onEscape = function()
        destroyWindow(changeNameWindow)
    end
end

-- /*=============================================
-- =            Button TransferPoints            =
-- =============================================*/

function onGiftWindow()
    local player = g_game.getLocalPlayer()
    if not player then
        return
    end
    
    local normalCoins, transferableCoins = getCoinsBalance()
    local coinsPacketSize = GameStore.coinsPacketSize or 25
    
    if transferableCoins < coinsPacketSize then
        if controllerShop and controllerShop.ui then
            displayErrorBox(controllerShop.ui:getText(), "You don't have enough coins to gift.")
        end
        return
    end
    
    transferPoints()
end

function transferPoints()
    destroyWindow(transferPointsWindow)
    transferPointsWindow = g_ui.displayUI('style/transferpoints')
    transferPointsWindow:show()

    local player = g_game.getLocalPlayer()
    if not player then
        return
    end
    
    fixServerNoSend0xF2()

    local normalCoins, transferableCoins = getCoinsBalance()
    local playerBalance = transferableCoins
    
    -- Fallback: se getCoinsBalance retornar 0, tentar do player
    if playerBalance == 0 then
        local resourceBalance = player:getResourceBalance(ResourceTypes.COIN_TRANSFERRABLE)
        if resourceBalance > 0 then
            playerBalance = resourceBalance
        end
    end

    transferPointsWindow.giftable:setText(formatNumberWithCommas(playerBalance))

    local coinsPacketSize = GameStore.coinsPacketSize or 25
    local initialValue, minimumValue = 0, 0
    if playerBalance >= coinsPacketSize then
        initialValue = coinsPacketSize
        minimumValue = coinsPacketSize
    end

    transferPointsWindow.amountBar:setStep(coinsPacketSize)
    transferPointsWindow.amountBar:setMinimum(minimumValue)
    local maxStep = math.floor(playerBalance / coinsPacketSize) * coinsPacketSize
    transferPointsWindow.amountBar:setMaximum(maxStep)
    transferPointsWindow.amountBar:setValue(initialValue)
    transferPointsWindow.amount:setText(formatNumberWithCommas(initialValue))

    local sliderButton = transferPointsWindow.amountBar:getChildById('sliderButton')
    if sliderButton then
        sliderButton:setEnabled(true)
        sliderButton:setVisible(true)
    end

    transferPointsWindow.onEscape = function()
        destroyWindow(transferPointsWindow)
    end

    local lastDisplayedValue = initialValue
    transferPointsWindow.amountBar.onValueChange = function(scrollbar, value)
        -- Round to the nearest multiple of coinsPacketSize
        local val = math.floor((value + (coinsPacketSize / 2)) / coinsPacketSize) * coinsPacketSize
        
        -- Only update the display if the value has changed
        if val ~= lastDisplayedValue then
            lastDisplayedValue = val
            transferPointsWindow.amount:setText(formatNumberWithCommas(val))
        end
    end

    transferPointsWindow.closeButton.onClick = function()
        destroyWindow(transferPointsWindow)
    end

    transferPointsWindow.buttonOk.onClick = function()
        local receipient = transferPointsWindow.transferPointsText:getText():trim()
        local amount = transferPointsWindow.amountBar:getValue()

        if receipient:len() < 3 then
            return
        end
        if amount < 1 or playerBalance < amount then
            return
        end

        g_game.transferCoins(receipient, amount)
        destroyWindow(transferPointsWindow)
    end
end

function openBaazarWindow()
    if not controllerShop or not controllerShop.ui then
        return
    end
    displayErrorBox(controllerShop.ui:getText(), "Bazaar functionality not yet implemented")
end

function showError(title, errorMessage)
    if not controllerShop or not controllerShop.ui then
        return
    end
    displayErrorBox(controllerShop.ui:getText(), errorMessage)
end




-- /*=============================================
-- =            Search Button            =
-- =============================================*/

local searchTimeout = nil

function onSearchEdit(widget)
    if not widget or not controllerShop.ui then
        return
    end

    local text = widget:getText()
    local searchButton = controllerShop.ui.SearchClearButton or controllerShop.ui:getChildById('SearchClearButton')

    if not text then
        if searchButton then
            searchButton:setEnabled(false)
            searchButton:setOpacity(0.5)
        end
        return
    end

    if text:len() < 3 then
        if searchButton then
            searchButton:setEnabled(false)
            searchButton:setOpacity(0.5)
        end
        -- Cancelar busca automática se houver
        if searchTimeout then
            removeEvent(searchTimeout)
            searchTimeout = nil
        end
        return
    end

    if searchButton then
        searchButton:setEnabled(true)
        searchButton:setOpacity(1.0)
    end

    -- Busca automática após 800ms sem digitar (delay para evitar muitas requisições)
    if searchTimeout then
        removeEvent(searchTimeout)
    end
    
    searchTimeout = scheduleEvent(function()
        if text:len() >= 3 then
            search()
        end
        searchTimeout = nil
    end, 800)
end

function onEnterSearch()
    if not controllerShop.ui or not controllerShop.ui.SearchEdit then
        return
    end

    local text = controllerShop.ui.SearchEdit:getText()
    if not text or text:len() < 3 then
        return
    end

    search()
end

function search()
    if not controllerShop.ui or not controllerShop.ui.SearchEdit then
        return
    end

    local searchText = controllerShop.ui.SearchEdit:getText()
    if not searchText or searchText:len() < 3 then
        return
    end

    -- Cancelar timeout se ainda estiver ativo
    if searchTimeout then
        removeEvent(searchTimeout)
        searchTimeout = nil
    end

    if controllerShop.ui.openedCategory ~= nil then
        close(controllerShop.ui.openedCategory)
    end

    -- Não limpar o campo de busca automaticamente (usuário pode querer ver o que digitou)
    -- controllerShop.ui.SearchEdit:setText('')

    -- Usar sendRequestStoreSearch se disponível, senão usar requestStoreOffers com OPEN_SEARCH
    if g_game.sendRequestStoreSearch then
        g_game.sendRequestStoreSearch(searchText, 0, 1)
    elseif g_game.requestStoreOffers then
        -- Fallback: usar requestStoreOffers se sendRequestStoreSearch não estiver disponível
        -- OPEN_SEARCH = 5 (definido no RTC)
        g_game.requestStoreOffers(5, searchText, 0)
    else
        -- Último fallback: tentar usar a função original
        g_game.sendRequestStoreSearch(searchText, 0, 1)
    end
end


-- private variables
local SHOP_EXTENTED_OPCODE = 201

shop = nil
transferWindow = nil
local otcv8shop = false
local shopButton = nil
local msgWindow = nil
local browsingHistory = false
local transferValue = 0

-- for classic store
local storeUrl = ""
local coinsPacketSize = 0

local CATEGORIES = {}
local HISTORY = {}
local STATUS = {}
local AD = {}

local selectedOffer = {}

local function sendAction(action, data)

    local protocolGame = g_game.getProtocolGame()
    if data == nil then
        data = {}
    end
    if protocolGame then
        protocolGame:sendExtendedJSONOpcode(SHOP_EXTENTED_OPCODE, {
            action = action,
            data = data
        })
    end
end

-- public functions
function init()
    connect(g_game, {
        onGameStart = check,
        onGameEnd = hide

    })

    ProtocolGame.registerExtendedJSONOpcode(SHOP_EXTENTED_OPCODE, onExtendedJSONOpcode)

    if g_game.isOnline() then
        check()
    end
    createShop()
    createTransferWindow()
end

function terminate()
    disconnect(g_game, {
        onGameStart = check,
        onGameEnd = hide

    })

    ProtocolGame.unregisterExtendedJSONOpcode(SHOP_EXTENTED_OPCODE, onExtendedJSONOpcode)

    if shopButton then
        shopButton:destroy()
        shopButton = nil
    end
    if shop then
        disconnect(shop.categories, {
            onChildFocusChange = changeCategory
        })
        shop:destroy()
        shop = nil
    end
    if msgWindow then
        msgWindow:destroy()
    end
end

function check()
    otcv8shop = false
    sendAction("init")
end

function hide()
    if not shop then
        return
    end
    shop:hide()
end

function show()
    if not shop  then
        return
    end

    shop:show()
    shop:raise()
    shop:focus()
end

function softHide()
    if not transferWindow then
        return
    end

    transferWindow:hide()
    shop:show()
end

function showTransfer()
    if not shop or not transferWindow then
        return
    end

    hide()
    transferWindow:show()
    transferWindow:raise()
    transferWindow:focus()
end

function hideTransfer()
    if not shop or not transferWindow then
        return
    end

    transferWindow:hide()
    show()
end

function toggle()
    if not shop then
        return
    end
    if shop:isVisible() then
        return hide()
    end
    show()
    check()
end

function createShop()
    if shop then
        return
    end
    shop = g_ui.displayUI('shop')
    shop:hide()
   -- shopButton = modules.game_mainpanel.addStoreButton('store', tr('Shop'), '/images/options/store_large', toggle,false, 8) -- \game_mainpanel\mainpanel.lua
    shopButton = nil

    connect(shop.categories, {
        onChildFocusChange = changeCategory
    })

end

function createTransferWindow()
    if transferWindow then
        return
    end
    transferWindow = g_ui.displayUI('transfer')
    transferWindow:hide()
end

function onStoreInit(url, coins)
    if otcv8shop then
        return
    end
    storeUrl = url
    if storeUrl:len() > 0 then
        if storeUrl:sub(storeUrl:len(), storeUrl:len()) ~= "/" then
            storeUrl = storeUrl .. "/"
        end
        storeUrl = storeUrl .. "64/"
        if storeUrl:sub(1, 4):lower() ~= "http" then
            storeUrl = "http://" .. storeUrl
        end
    end
    coinsPacketSize = coins
    createShop()
    createTransferWindow()
end

function onStoreCategories(categories)
    if not shop or otcv8shop then
        return
    end
    local correctCategories = {}
    for i, category in ipairs(categories) do
        local image = ""
        if category.icon:len() > 0 then
            image = storeUrl .. category.icon
        end
        table.insert(correctCategories, {
            type = "image",
            image = image,
            name = category.name,
            offers = {}
        })
    end
    processCategories(correctCategories)
end

function onStoreOffers(categoryName, offers)
    if not shop or otcv8shop then
        return
    end
    local updated = false

    for i, category in ipairs(CATEGORIES) do
        if category.name == categoryName then
            if #category.offers ~= #offers then
                updated = true
            end
            for i = 1, #category.offers do
                if category.offers[i].title ~= offers[i].name or category.offers[i].id ~= offers[i].id or
                    category.offers[i].cost ~= offers[i].price then
                    updated = true
                end
            end
            if updated then
                for offer in pairs(category.offers) do
                    category.offers[offer] = nil
                end
                for i, offer in ipairs(offers) do
                    local image = ""
                    if offer.icon:len() > 0 then
                        image = storeUrl .. offer.icon
                    end
                    table.insert(category.offers, {
                        id = offer.id,
                        type = "image",
                        image = image,
                        cost = offer.price,
                        title = offer.name,
                        description = offer.description
                    })
                end
            end
        end
    end
    if not updated then
        return
    end

    local activeCategory = shop.categories:getFocusedChild()
    changeCategory(activeCategory, activeCategory)
end

function onStoreTransactionHistory(currentPage, hasNextPage, offers)
    if not shop or otcv8shop then
        return
    end
    HISTORY = {}
    for i, offer in ipairs(offers) do
        table.insert(HISTORY, {
            id = offer.id,
            type = "image",
            image = storeUrl .. offer.icon,
            cost = offer.price,
            title = offer.name,
            description = offer.description
        })
    end

    if not browsingHistory then
        return
    end
    clearOffers()
    shop.categories:focusChild(nil)
    for i, transaction in ipairs(HISTORY) do
        addOffer(0, transaction)
    end
end

function onStorePurchase(message)
    if not shop or otcv8shop then
        return
    end
    if not transferWindow:isVisible() then
        processMessage({
            title = "Successful shop purchase",
            msg = message
        })
    else
        processMessage({
            title = "Successfuly gifted coins",
            msg = message
        })
        softHide()
    end
end

function onStoreError(errorType, message)
    if not shop or otcv8shop then
        return
    end
    if not transferWindow:isVisible() then
        processMessage({
            title = "Shop Error",
            msg = message
        })
    else
        processMessage({
            title = "Gift coins error",
            msg = message
        })
    end
end

function onCoinBalance(coins, transferableCoins)
    if not shop or otcv8shop then
        return
    end
    shop.infoPanel.points:setText(tr("Points:") .. " " .. coins)
    transferWindow.coinsBalance:setText(tr('Transferable Tibia Coins: ') .. coins)
    transferWindow.coinsAmount:setMaximum(coins)
    shop.infoPanel.buy:hide()
    shop.infoPanel:setHeight(20)
end

function transferCoins()
    if not transferWindow then
        return
    end
    local amount = 0
    amount = transferWindow.coinsAmount:getValue()
    local recipient = transferWindow.recipient:getText()

    g_game.transferCoins(recipient, amount)
    transferWindow.recipient:setText('')
    transferWindow.coinsAmount:setValue(0)
end

function onExtendedJSONOpcode(protocol, code, json_data)
    createShop()
    createTransferWindow()

    local action = json_data['action']
    local data = json_data['data']
    local status = json_data['status']
    if not action or not data then
        return false
    end

    otcv8shop = true
    if action == 'categories' then
        processCategories(data)
    elseif action == 'history' then
        processHistory(data)
    elseif action == 'message' then
        processMessage(data)
    end

    if status then
        processStatus(status)
    end
end

function clearOffers()
    while shop.offers:getChildCount() > 0 do
        local child = shop.offers:getLastChild()
        shop.offers:destroyChildren(child)
    end
end

function clearCategories()
    CATEGORIES = {}
    clearOffers()
    while shop.categories:getChildCount() > 0 do
        local child = shop.categories:getLastChild()
        shop.categories:destroyChildren(child)
    end
end

function clearHistory()
    HISTORY = {}
    if browsingHistory then
        clearOffers()
    end
end

function processCategories(data)
    if table.equal(CATEGORIES, data) then
        return
    end
    clearCategories()
    CATEGORIES = data
    for i, category in ipairs(data) do
        addCategory(category)
    end
    if not browsingHistory then
        local firstCategory = shop.categories:getChildByIndex(1)
        if firstCategory then
            firstCategory:focus()
        end
    end
end

function processHistory(data)
    if table.equal(HISTORY, data) then
        return
    end
    HISTORY = data
    if browsingHistory then
        showHistory(true)
    end
end

function processMessage(data)
    if msgWindow then
        msgWindow:destroy()
    end

    local title = tr(data["title"])
    local msg = data["msg"]
    msgWindow = displayInfoBox(title, msg)
    msgWindow.onDestroy = function(widget)
        if widget == msgWindow then
            msgWindow = nil
        end
    end
    msgWindow:show()
    msgWindow:raise()
    msgWindow:focus()
end
local function formatNumberWithCommas(value)
    local formattedValue = string.format("%d", value)
    -- Add commas to the formatted value
    formattedValue = formattedValue:reverse():gsub("(%d%d%d)", "%1,")
    return formattedValue:reverse():gsub("^,", "")
end

function processStatus(data)
    if table.equal(STATUS, data) then
        return
    end
    STATUS = data

    if data['ad'] then
        processAd(data['ad'])
    end
    if data['points'] then
        shop.infoPanel.points:setText(tr("Points:") .. " " .. formatNumberWithCommas(data['points']))
    end
    if data['buyUrl'] and data['buyUrl']:sub(1, 4):lower() == "http" then
        shop.infoPanel.buy:show()
        shop.infoPanel.buy.onMouseRelease = function()
            scheduleEvent(function()
                g_platform.openUrl(data['buyUrl'])
            end, 50)
        end
    else
        shop.infoPanel.buy:hide()
        shop.infoPanel:setHeight(20)
    end
end

function processAd(data)
    if table.equal(AD, data) then
        return
    end
    AD = data

    if data['image'] then

        shop.adPanel:setHeight(shop.infoPanel:getHeight())
        shop.adPanel.ad:setText("")
        shop.adPanel.ad:setImageSource(data['image'])
        shop.adPanel.ad:setImageFixedRatio(true)
        shop.adPanel.ad:setImageAutoResize(true)
        shop.adPanel.ad:setHeight(shop.infoPanel:getHeight())

    elseif data['text'] and data['text']:len() > 0 then
        shop.adPanel:setHeight(shop.infoPanel:getHeight())
        shop.adPanel.ad:setText(data['text'])
        shop.adPanel.ad:setHeight(shop.infoPanel:getHeight())
    else
        shop.adPanel:setHeight(0)
    end
    if data['url'] and data['url']:sub(1, 4):lower() == "http" then
        shop.adPanel.ad.onMouseRelease = function()
            scheduleEvent(function()
                g_platform.openUrl(data['url'])
            end, 50)
        end
    else
        shop.adPanel.ad.onMouseRelease = nil
    end
end

function addCategory(data)

    local category
    if data["type"] == "item" then
        category = g_ui.createWidget('ShopCategoryItem', shop.categories)
        category.item:setItemId(data["item"])
        category.item:setItemCount(data["count"])
        -- category.item:setShowCount(false)
    elseif data["type"] == "outfit" then
        category = g_ui.createWidget('ShopCategoryCreature', shop.categories)
        category.creature:setOutfit(data["outfit"])

    elseif data["type"] == "shader" then
        category = g_ui.createWidget('ShopCategoryCreature', shop.categories)
        category.creature:setOutfit(g_game.getLocalPlayer():getOutfit())
        category.creature:getCreature():setShader(data["shader"])

    elseif data["type"] == "image" then
        category = g_ui.createWidget('ShopCategoryImage', shop.categories)
        if data["image"] and data["image"]:sub(1, 4):lower() == "http" then
            HTTP.downloadImage(data['image'], function(path, err)
                if err then
                    g_logger.warning("HTTP error: " .. err .. " - " .. data["image"])
                    return
                end
                category.image:setImageSource(path)
            end)
        else
            category.image:setImageSource(data["image"])
        end
    else
        g_logger.error("Invalid shop category type: " .. tostring(data["type"]))
        return
    end
    category:setId("category_" .. shop.categories:getChildCount())
    category.name:setText(data["name"])
end

function showHistory(force)
    if browsingHistory and not force then
        return
    end

    sendAction("history")

    browsingHistory = true
    clearOffers()
    shop.categories:focusChild(nil)
    for i, transaction in ipairs(HISTORY) do
        addOffer(0, transaction)
    end
end

function addOffer(category, data)
    local offer
    if data["type"] == "item" then
        offer = g_ui.createWidget('ShopOfferItem', shop.offers)
        offer.item:setItemId(data["item"])
        offer.item:setItemCount(data["count"])
        -- offer.item:setShowCount(false)

    elseif data["type"] == "effect" then

        offer = g_ui.createWidget('ShopOfferCreature', shop.offers)
        offer.creature:setOutfit(g_game.getLocalPlayer():getOutfit())
        offer.creature:getCreature():attachEffect(g_attachedEffects.getById(data["title"]))

    elseif data["type"] == "shader" then

        offer = g_ui.createWidget('ShopOfferCreature', shop.offers)
        offer.creature:setOutfit(g_game.getLocalPlayer():getOutfit())
        offer.creature:getCreature():setShader(data["title"])

    elseif data["type"] == "outfit" then
        offer = g_ui.createWidget('ShopOfferCreature', shop.offers)
        offer.creature:setOutfit(data["outfit"])
        if data["outfit"]["rotating"] then
            -- offer.creature:setAutoRotating(true)
        end
    elseif data["type"] == "image" then
        offer = g_ui.createWidget('ShopOfferImage', shop.offers)
        if data["image"] and data["image"]:sub(1, 4):lower() == "http" then
            HTTP.downloadImage(data['image'], function(path, err)
                if err then
                    g_logger.warning("HTTP error: " .. err .. " - " .. data['image'])
                    return
                end
                if not offer.image then
                    return
                end
                offer.image:setImageSource(path)
            end)
        elseif data["image"] and data["image"]:len() > 1 then
            offer.image:setImageSource(data["image"])
        end
    else
        g_logger.error("Invalid shop offer type: " .. tostring(data["type"]))
        return
    end
    offer:setId("offer_" .. category .. "_" .. shop.offers:getChildCount())
    offer.title:setColoredText(data["title"] .. " {[" .. data["cost"] .. " points], #ff0000}")
    offer.description:setText(data["description"])
    offer.offerId = data["id"]
    if category ~= 0 then
        offer.onDoubleClick = buyOffer
        offer.buyButton.onClick = function()
            buyOffer(offer)
        end
    else
        offer.buyButton:hide()
    end
end

function changeCategory(widget, newCategory)
    if not newCategory then
        return
    end

    browsingHistory = false
    local id = tonumber(newCategory:getId():split("_")[2])
    clearOffers()
    for i, offer in ipairs(CATEGORIES[id]["offers"]) do
        addOffer(id, offer)
    end
end

function buyOffer(widget)
    if not widget then
        return
    end
    local split = widget:getId():split("_")
    if #split ~= 3 then
        return
    end
    local category = tonumber(split[2])
    local offer = tonumber(split[3])
    local item = CATEGORIES[category]["offers"][offer]
    if not item then
        return
    end

    selectedOffer = {
        category = category,
        offer = offer,
        title = item.title,
        cost = item.cost,
        id = widget.offerId
    }

    scheduleEvent(function()
        if msgWindow then
            msgWindow:destroy()
        end

        local title = tr("Buying from shop")
        local msg = "Do you want to buy " .. item.title .. " for " .. item.cost .. " premium points?"
        msgWindow = displayGeneralBox(title, msg, {
            {
                text = tr('Yes'),
                callback = buyConfirmed
            },
            {
                text = tr('No'),
                callback = buyCanceled
            },
            anchor = AnchorHorizontalCenter
        }, buyConfirmed, buyCanceled)
        msgWindow:show()
        msgWindow:raise()
        msgWindow:focus()
        msgWindow:raise()
    end, 50)
end

function buyConfirmed()
    msgWindow:destroy()
    msgWindow = nil
    sendAction("buy", selectedOffer)

end

function buyCanceled()
    msgWindow:destroy()
    msgWindow = nil
    selectedOffer = {}
end

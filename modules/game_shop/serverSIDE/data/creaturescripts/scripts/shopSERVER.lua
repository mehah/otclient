-- Instruction: 
-- creaturescripts.xml      <event type="extendedopcode" name="Shop" script="shop.lua" />
-- and in login.lua         player:registerEvent("Shop")
-- create sql table shop_history
-- set variables
-- set up function init(), add there items and categories, follow examples
-- set up callbacks at the bottom to add player item/outfit/whatever you want

local SHOP_EXTENDED_OPCODE = 201
local SHOP_OFFERS = {}
local SHOP_CALLBACKS = {}
local SHOP_CATEGORIES = nil
local SHOP_BUY_URL = "http://otland.net" -- can be empty
local SHOP_AD = { -- can be nil
  image = "",
  url = "http://otclient.ovh",
  text = ""
}
local MAX_PACKET_SIZE = 50000
-- local MAX_PACKET_SIZE = 5088
--[[ SQL TABLE

CREATE TABLE `shop_history` (
  `id` int(11) NOT NULL,
  `account` int(11) NOT NULL,
  `player` int(11) NOT NULL,
  `date` datetime NOT NULL,
  `title` varchar(100) NOT NULL,
  `cost` int(11) NOT NULL,
  `details` varchar(500) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `shop_history`
  ADD PRIMARY KEY (`id`);
ALTER TABLE `shop_history`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

]]--

function init()
  --  print(json.encode(g_game.getLocalPlayer():getOutfit())) -- in console in otclient, will print current outfit and mount
  
  SHOP_CATEGORIES = {}

  local category1 = addCategory({
    type="item",
    item=ItemType(2160):getClientId(),
    count=100,
    name="Items"
  })
  local category2 = addCategory({
    type="outfit",
    name="Outfits",
    outfit={
        mount=0,
        feet=114,
        legs=114,
        body=116,
        type=143,
        auxType=0,
        addons=3,
        head=2,
        rotating=true
    }
  })
  local category3 = addCategory({
    type="image",
    image="http://otclient.ovh/images/137.png",
    name="Category with http image"
  })
  local category4 = addCategory({
    type="image",
    image="/data/images/game/states/electrified.png",
    name="Category with local image"
  })
  
  
  category1.addItem(1, 2160, 1, "1 Crystal coin", "description of cristal coin")
  category1.addItem(5, 2160, 5, "5 Crystal coin", "description of cristal coin")
  category1.addItem(50, 2160, 50, "50 Crystal coin", "description of cristal coin")
  category1.addItem(90, 2160, 100, "100 Crystal coin", "description of cristal coin")
  category1.addItem(200, 2493, 1, "Demon helmet1", "woo\ndemon helmet\nnice, you should buy it")
  category1.addItem(1, 2160, 1, "1 Crystal coin1", "description of cristal coin")
  category1.addItem(5, 2160, 5, "5 Crystal coin1", "description of cristal coin")
  category1.addItem(50, 2160, 50, "50 Crystal coin1", "description of cristal coin")
  category1.addItem(90, 2160, 100, "100 Crystal coin1", "description of cristal coin")
  category1.addItem(200, 2493, 1, "Demon helmet2", "woo\ndemon helmet\nnice, you should buy it")
  category1.addItem(1, 2160, 1, "1 Crystal coin3", "description of cristal coin")
  category1.addItem(5, 2160, 5, "5 Crystal coin3", "description of cristal coin")
  category1.addItem(50, 2160, 50, "50 Crystal coin3", "description of cristal coin")
  category1.addItem(90, 2160, 100, "100 Crystal coin3", "description of cristal coin")
  category1.addItem(200, 2493, 1, "Demon helmet3", "wooxD\ndemon helmet\nnice, you should buy it")
  
  category2.addOutfit(500, {
        mount=0,
        feet=114,
        legs=114,
        body=116,
        type=143,
        auxType=0,
        addons=3,
        head=2,
        rotating=true
    }, "title of this cool outfit or whatever", "this is your new cool outfit. You can buy it here.\nsrlsy")
    category2.addOutfit(100, {
        mount=682,
        feet=0,
        legs=0,
        body=0,
        type=143,
        auxType=0,
        addons=0,
        head=0,
        rotating=true
    }, "MOUNT!!!", "DOUBLE CLICK TO BUY THIS MOUNT. IDK NAME")
    
    category2.addOutfit(100, {
        mount=0,
        feet=0,
        legs=0,
        body=0,
        type=35,
        auxType=0,
        addons=0,
        head=0,
        rotating=true
    }, "Demon outfit", "Want be a demon?\nNo problem")
    category2.addOutfit(100, {
        mount=0,
        feet=0,
        legs=0,
        body=0,
        type=35,
        auxType=0,
        addons=0,
        head=0,
        rotating=false
    }, "Demon outfit2", "This one is not rotating")
    
    category4.addImage(10000, "/data/images/game/states/haste.png", "Offer with local image", "another local image\n/data/images/game/states/haste.png")
    category4.addImage(10000, "http://otclient.ovh/images/freezing.png", "Offer with remote image and custom buy action", "blalasdasd image\nhttp://otclient.ovh/images/freezing.png", customImageBuyAction)
end

function addCategory(data)
  data['offers'] = {}
  table.insert(SHOP_CATEGORIES, data)
  table.insert(SHOP_CALLBACKS, {})
  local index = #SHOP_CATEGORIES
  return {
    addItem = function(cost, itemId, count, title, description, callback)      
      if not callback then
        callback = defaultItemBuyAction
      end
      table.insert(SHOP_CATEGORIES[index]['offers'], {
        cost=cost,
        type="item",
        item=ItemType(itemId):getClientId(), -- displayed
        itemId=itemId,
        count=count,
        title=title,
        description=description
      })
      table.insert(SHOP_CALLBACKS[index], callback)
    end,
    addOutfit = function(cost, outfit, title, description, callback)
      if not callback then
        callback = defaultOutfitBuyAction
      end
      table.insert(SHOP_CATEGORIES[index]['offers'], {
        cost=cost,
        type="outfit",
        outfit=outfit,
        title=title,
        description=description
      })    
      table.insert(SHOP_CALLBACKS[index], callback)
    end,
    addImage = function(cost, image, title, description, callback)
      if not callback then
        callback = defaultImageBuyAction
      end
      table.insert(SHOP_CATEGORIES[index]['offers'], {
        cost=cost,
        type="image",
        image=image,
        title=title,
        description=description
      })
      table.insert(SHOP_CALLBACKS[index], callback)
    end
  }
end

function getPoints(player)
  local points = 0
  local resultId = db.storeQuery("SELECT `premium_points` FROM `accounts` WHERE `id` = " .. player:getAccountId())
  if resultId ~= false then
    points = result.getDataInt(resultId, "premium_points")
    result.free(resultId)
  end
  return points
end

function getStatus(player)
  local status = {
    ad = SHOP_AD,
    points = getPoints(player),
    buyUrl = SHOP_BUY_URL
  }
  return status
end

function sendJSON(player, action, data, forceStatus)
  local status = nil
  if not player:getStorageValue(1150001) or player:getStorageValue(1150001) + 10 < os.time() or forceStatus then
      status = getStatus(player)
  end
  player:setStorageValue(1150001, os.time())
  

  local buffer = json.encode({action = action, data = data, status = status})  
  local s = {}
  for i=1, #buffer, MAX_PACKET_SIZE do
     s[#s+1] = buffer:sub(i,i+MAX_PACKET_SIZE - 1)
  end
  local msg = NetworkMessage()
  if #s == 1 then
    msg:addByte(50)
    msg:addByte(SHOP_EXTENDED_OPCODE)
    msg:addString(s[1])
    msg:sendToPlayer(player)
    return  
  end
  -- split message if too big
  msg:addByte(50)
  msg:addByte(SHOP_EXTENDED_OPCODE)
  msg:addString("S" .. s[1])
  msg:sendToPlayer(player)
  for i=2,#s - 1 do
    msg = NetworkMessage()
    msg:addByte(50)
    msg:addByte(SHOP_EXTENDED_OPCODE)
    msg:addString("P" .. s[i])
    msg:sendToPlayer(player)
  end
  msg = NetworkMessage()
  msg:addByte(50)
  msg:addByte(SHOP_EXTENDED_OPCODE)
  msg:addString("E" .. s[#s])
  msg:sendToPlayer(player)
end

function sendMessage(player, title, msg, forceStatus)
  sendJSON(player, "message", {title=title, msg=msg}, forceStatus)
end

function onExtendedOpcode(player, opcode, buffer)
  if opcode ~= SHOP_EXTENDED_OPCODE then
    return false
  end
  local status, json_data = pcall(function() return json.decode(buffer) end)
  if not status then
    return false
  end

  local action = json_data['action']
  local data = json_data['data']
  if not action or not data then
    return false
  end

  if SHOP_CATEGORIES == nil then
    init()    
  end

  if action == 'init' then
    sendJSON(player, "categories", SHOP_CATEGORIES)
  elseif action == 'buy' then
    processBuy(player, data)
  elseif action == "history" then
    sendHistory(player)
  end
  return true
end

function processBuy(player, data)
  local categoryId = tonumber(data["category"])
  local offerId = tonumber(data["offer"])
  local offer = SHOP_CATEGORIES[categoryId]['offers'][offerId]
  local callback = SHOP_CALLBACKS[categoryId][offerId]
  if not offer or not callback or data["title"] ~= offer["title"] or data["cost"] ~= offer["cost"] then
    sendJSON(player, "categories", SHOP_CATEGORIES) -- refresh categories, maybe invalid
    return sendMessage(player, "Error!", "Invalid offer")      
  end
  local points = getPoints(player)
  if not offer['cost'] or offer['cost'] > points or points < 1 then
    return sendMessage(player, "Error!", "You don't have enough points to buy " .. offer['title'] .."!", true)    
  end
  local status = callback(player, offer)
  if status == true then    
    db.query("UPDATE `accounts` set `premium_points` = `premium_points` - " .. offer['cost'] .. " WHERE `id` = " .. player:getAccountId())
    db.asyncQuery("INSERT INTO `shop_history` (`account`, `player`, `date`, `title`, `cost`, `details`) VALUES ('" .. player:getAccountId() .. "', '" .. player:getGuid() .. "', NOW(), " .. db.escapeString(offer['title']) .. ", " .. db.escapeString(offer['cost']) .. ", " .. db.escapeString(json.encode(offer)) .. ")")
    return sendMessage(player, "Success!", "You bought " .. offer['title'] .."!", true)
  end
  if status == nil or status == false then
    status = "Unknown error while buying " .. offer['title']
  end
  sendMessage(player, "Error!", status)
end

function sendHistory(player)
  if player:getStorageValue(1150002) and player:getStorageValue(1150002) + 10 > os.time() then
    return -- min 10s delay
  end
  player:setStorageValue(1150002, os.time())
  
  local history = {}
	local resultId = db.storeQuery("SELECT * FROM `shop_history` WHERE `account` = " .. player:getAccountId() .. " order by `id` DESC")

	if resultId ~= false then
    repeat
      local details = result.getDataString(resultId, "details")
      local status, json_data = pcall(function() return json.decode(details) end)
      if not status then    
        json_data = {
          type = "image",
          title = result.getDataString(resultId, "title"),
          cost = result.getDataInt(resultId, "cost")
        }
      end
      table.insert(history, json_data)
      history[#history]["description"] = "Bought on " .. result.getDataString(resultId, "date") .. " for " .. result.getDataInt(resultId, "cost") .. " points."
    until not result.next(resultId)
    result.free(resultId)
	end
  
  sendJSON(player, "history", history)
end

-- BUY CALLBACKS
-- May be useful: print(json.encode(offer))

function defaultItemBuyAction(player, offer)
  -- todo: check if has capacity
  if player:addItem(offer["itemId"], offer["count"], false) then
    return true
  end
  return "Can't add item! Do you have enough space?"
end

function defaultOutfitBuyAction(player, offer)
  return "default outfit buy action is not implemented"
end

function defaultImageBuyAction(player, offer)
  return "default image buy action is not implemented"
end

function customImageBuyAction(player, offer)
  return "custom image buy action is not implemented. Offer: " .. offer['title']
end
local DONATION_URL = "https://github.com/mehah/otclient"

local CODE_GAMESHOP = 102
local GAME_SHOP = nil

local LoginEvent = CreatureEvent("GameShopLogin")

function LoginEvent.onLogin(player)
	player:registerEvent("GameShopExtended")
	return true
end

function gameShopInitialize()
	GAME_SHOP = {
		categories = {},
		offers = {}
	}

	addCategory("Items", "Tools, Dolls & Boxes.", "item", 27277)
	addItem("Items", "Rainbow Shader", "Use this item to get access to rainbow shader.", 30380, 1, 1500)
	addItem("Items", "Rainbow Outline Shader", "Use this item to get access to rainbow outline shader.", 30379, 1, 900)
	addItem("Items", "VIP Medal (30 days)", "Earn 10% more exp, Access To Gambling\nAnd Gold Dump(Obtainable ingame)", 10135, 1, 200)
	addItem("Items", "Revolution Mystery Box", "Can contain Store items\nGame Tokens\nEvent Items.", 28494, 1, 350)
	addItem("Items", "Eradicator", "Used to convert tokens into clear tokens.", 27315, 1, 500)
	addItem("Items", "Portable Lootomatic", "Allows you to sell items on the go.", 27278, 1, 600)
	addItem("Items", "Token Box", "Contains 30 random Tokens.", 26144, 1, 100)
	addItem("Items", "Token Box", "Contains 30 random Tokens. (10 boxes)", 26144, 10, 900)
	addItem("Items", "Catalyst Box", "Contains 15 random Upgrade Catalysts.", 13044, 1, 150)
	addItem("Items", "Orb of Return", "Returns you to temple.(5 min cd)", 27471, 1, 500)
	addItem("Items", "Rainbow Falcon", "Use to activate rainbow colors on your outfit.", 2141, 1, 400)
	addItem("Items", "Radioactive Shit", "Infinite Food Item.", 24841, 1, 150)
	addItem("Items", "Golden Die", "A golden die to gamble.", 28499, 1, 500)
	-- addItem("Items", "Outfit Doll", "Use this to obtain one outfit with full Addons.", 8982, 1, 300)
	addItem("Items", "Gender Doll", "Can be used to change your gender.", 13581, 1, 200)
	addItem("Items", "Name Doll", "Can be used to change your name.", 12666, 1, 400)
	addItem("Items", "Frag Remover", "Use this to remove your frags & Red/Black Skull.", 16105, 1, 500)
	-- addItem("Items", "Stamina Refiller", "Can be used to fully recharge your stamina.", 21705, 1, 400)
	addItem("Items", "Squeezing Gear of Girlpower", "Multitool", 10513, 1, 200)

	addCategory(
		"Outfits",
		"Contains all addons.",
		"outfit",
		{
			mount = 0,
			type = 971,
			addons = 0,
			head = 0,
			body = 114,
			legs = 85,
			feet = 76
		}
	)
	addOutfit(
		"Outfits",
		"Golden Outfit",
		"Golden outfit",
		{
			mount = 0,
			type = 957,
			addons = 3,
			head = 114,
			body = 114,
			legs = 114,
			feet = 114
		},
		{
			mount = 0,
			type = 958,
			addons = 3,
			head = 114,
			body = 114,
			legs = 114,
			feet = 114
		},
		1500
	)
	addOutfit(
		"Outfits",
		"Glire Suit Outfit",
		"Glire Suit",
		{
			mount = 0,
			type = 1263,
			addons = 3,
			head = 85,
			body = 91,
			legs = 114,
			feet = 85
		},
		{
			mount = 0,
			type = 1262,
			addons = 3,
			head = 85,
			body = 91,
			legs = 114,
			feet = 85
		},
		1000
	)
	addOutfit(
		"Outfits",
		"Alienist Outfit",
		"Alienist",
		{
			mount = 0,
			type = 1265,
			addons = 3,
			head = 68,
			body = 117,
			legs = 29,
			feet = 101
		},
		{
			mount = 0,
			type = 1264,
			addons = 3,
			head = 68,
			body = 117,
			legs = 29,
			feet = 101
		},
		1000
	)
	addOutfit(
		"Outfits",
		"Revenant Outfit",
		"Revenant",
		{
			mount = 0,
			type = 1348,
			addons = 3,
			head = 86,
			body = 114,
			legs = 114,
			feet = 86
		},
		{
			mount = 0,
			type = 1349,
			addons = 3,
			head = 86,
			body = 114,
			legs = 114,
			feet = 86
		},
		800
	)
	addOutfit(
		"Outfits",
		"Mercenary Outfit",
		"Mercenary",
		{
			mount = 0,
			type = 1025,
			addons = 3,
			head = 78,
			body = 78,
			legs = 77,
			feet = 96
		},
		{
			mount = 0,
			type = 1024,
			addons = 3,
			head = 78,
			body = 78,
			legs = 77,
			feet = 96
		},
		700
	)
	addOutfit(
		"Outfits",
		"Rascoohan Outfit",
		"Rascoohan",
		{
			mount = 0,
			type = 1354,
			addons = 3,
			head = 64,
			body = 79,
			legs = 64,
			feet = 64
		},
		{
			mount = 0,
			type = 1355,
			addons = 3,
			head = 64,
			body = 79,
			legs = 64,
			feet = 64
		},
		700
	)
	addOutfit(
		"Outfits",
		"Dragon Slayer Outfit",
		"Dragon Slayer",
		{
			mount = 0,
			type = 1344,
			addons = 3,
			head = 120,
			body = 120,
			legs = 120,
			feet = 120
		},
		{
			mount = 0,
			type = 1345,
			addons = 3,
			head = 120,
			body = 120,
			legs = 120,
			feet = 120
		},
		700
	)
	addOutfit(
		"Outfits",
		"Jouster Outfit",
		"Jouster",
		{
			mount = 0,
			type = 1350,
			addons = 3,
			head = 108,
			body = 111,
			legs = 74,
			feet = 69
		},
		{
			mount = 0,
			type = 1351,
			addons = 3,
			head = 108,
			body = 111,
			legs = 74,
			feet = 69
		},
		650
	)
	addOutfit(
		"Outfits",
		"Discoverer Outfit",
		"Discoverer",
		{
			mount = 0,
			type = 1002,
			addons = 3,
			head = 114,
			body = 94,
			legs = 95,
			feet = 95
		},
		{
			mount = 0,
			type = 1001,
			addons = 3,
			head = 114,
			body = 94,
			legs = 95,
			feet = 95
		},
		600
	)
	addOutfit(
		"Outfits",
		"Poltergeist Outfit",
		"Poltergeist",
		{
			mount = 0,
			type = 1180,
			addons = 3,
			head = 114,
			body = 114,
			legs = 128,
			feet = 113
		},
		{
			mount = 0,
			type = 1179,
			addons = 3,
			head = 114,
			body = 114,
			legs = 128,
			feet = 113
		},
		550
	)
	addOutfit(
		"Outfits",
		"Tomb Assassin Outfit",
		"Tomb Assassin",
		{
			mount = 0,
			type = 1184,
			addons = 3,
			head = 98,
			body = 115,
			legs = 77,
			feet = 114
		},
		{
			mount = 0,
			type = 1183,
			addons = 3,
			head = 98,
			body = 115,
			legs = 77,
			feet = 114
		},
		550
	)
	addOutfit(
		"Outfits",
		"Forest Warden Outfit",
		"Forest Warden",
		{
			mount = 0,
			type = 1458,
			addons = 3,
			head = 114,
			body = 87,
			legs = 22,
			feet = 3
		},
		{
			mount = 0,
			type = 1457,
			addons = 3,
			head = 114,
			body = 87,
			legs = 22,
			feet = 3
		},
		500
	)
	addOutfit(
		"Outfits",
		"Retro Hunter Outfit",
		"Retro Hunter",
		{
			mount = 0,
			type = 951,
			addons = 3,
			head = 95,
			body = 75,
			legs = 20,
			feet = 114
		},
		{
			mount = 0,
			type = 950,
			addons = 3,
			head = 95,
			body = 75,
			legs = 20,
			feet = 114
		},
		450
	)
	addOutfit(
		"Outfits",
		"Retro Knight Outfit",
		"Retro Knight",
		{
			mount = 0,
			type = 939,
			addons = 3,
			head = 83,
			body = 91,
			legs = 87,
			feet = 0
		},
		{
			mount = 0,
			type = 938,
			addons = 3,
			head = 83,
			body = 91,
			legs = 87,
			feet = 0
		},
		450
	)
	addOutfit(
		"Outfits",
		"Retro Mage Outfit",
		"Retro Mage",
		{
			mount = 0,
			type = 941,
			addons = 3,
			head = 114,
			body = 70,
			legs = 94,
			feet = 94
		},
		{
			mount = 0,
			type = 940,
			addons = 3,
			head = 114,
			body = 70,
			legs = 94,
			feet = 94
		},
		450
	)
	addOutfit(
		"Outfits",
		"Retro Noblewoman Outfit",
		"Retro Noblewoman",
		{
			mount = 0,
			type = 943,
			addons = 3,
			head = 0,
			body = 82,
			legs = 0,
			feet = 0
		},
		{
			mount = 0,
			type = 942,
			addons = 3,
			head = 0,
			body = 82,
			legs = 0,
			feet = 0
		},
		450
	)
	addOutfit(
		"Outfits",
		"Retro Summoner Outfit",
		"Retro Summoner",
		{
			mount = 0,
			type = 945,
			addons = 3,
			head = 94,
			body = 114,
			legs = 128,
			feet = 79
		},
		{
			mount = 0,
			type = 944,
			addons = 3,
			head = 94,
			body = 114,
			legs = 128,
			feet = 79
		},
		450
	)
	addOutfit(
		"Outfits",
		"Retro Warrior Outfit",
		"Retro Warrior",
		{
			mount = 0,
			type = 947,
			addons = 3,
			head = 0,
			body = 76,
			legs = 124,
			feet = 0
		},
		{
			mount = 0,
			type = 946,
			addons = 3,
			head = 0,
			body = 76,
			legs = 124,
			feet = 0
		},
		450
	)
	addOutfit(
		"Outfits",
		"Sun priest Outfit",
		"Sun Priest",
		{
			mount = 0,
			type = 1054,
			addons = 3,
			head = 114,
			body = 94,
			legs = 101,
			feet = 114
		},
		{
			mount = 0,
			type = 1053,
			addons = 3,
			head = 114,
			body = 94,
			legs = 101,
			feet = 114
		},
		450
	)
	addOutfit(
		"Outfits",
		"Dream Warden Outfit",
		"Dream Warden",
		{
			mount = 0,
			type = 577,
			addons = 3,
			head = 9,
			body = 126,
			legs = 124,
			feet = 116
		},
		{
			mount = 0,
			type = 578,
			addons = 3,
			head = 9,
			body = 126,
			legs = 124,
			feet = 116
		},
		400
	)
	addOutfit(
		"Outfits",
		"Dream Warrior Outfit",
		"Dream Warrior",
		{
			mount = 0,
			type = 1087,
			addons = 3,
			head = 0,
			body = 0,
			legs = 97,
			feet = 114
		},
		{
			mount = 0,
			type = 1088,
			addons = 3,
			head = 0,
			body = 0,
			legs = 97,
			feet = 114
		},
		350
	)

	addCategory("Mounts", "Giddy up", "mount", 426)
	addMount("Mounts", "Moo Moo", "Did somebody say Moo?.", 148, 1127, 1000)
	addMount("Mounts", "Rainbow Pixel", "We're going to candy mountain!!", 103, 919, 1000)
	addMount("Mounts", "Krakoloss", "Did somebody say tentacles?", 166, 1377, 900)
	addMount("Mounts", "Santa", "Ride on santa's shoulders just like you wished when you were a kid!", 107, 929, 900)
	addMount("Mounts", "Singeing Steed", "Fire spreads wherever it gallops.", 174, 1439, 800)
	addMount("Mounts", "Phantasmal Jade", "My little pony, my little pony.", 167, 1385, 800)
	addMount("Mounts", "Coocoo", "Cutest lil bird you'll ever lay your hands on!", 104, 923, 750)
	addMount("Mounts", "Ice Flaming Lupos", "Ice or Fire?", 160, 1194, 700)
	addMount("Mounts", "Bareback Hound", "This wild beast will attack anything on sight!!", 173, 1410, 700)
	addMount("Mounts", "Phant", "Protected with golden armor.!", 175, 1459, 700)
	addMount("Mounts", "Cunning Hyaena", "Might hurt your butt to sit on it.", 169, 1390, 650)
	addMount("Mounts", "Benevolent Eventide Nandu", "Comes with a feathery seat.", 164, 1372, 600)
	addMount("Mounts", "Gold Sphinx", "Raised by Sol.", 115, 969, 600)
	addMount("Mounts", "Festive Snowman", "Will it melt?.", 142, 1105, 500)
	addMount("Mounts", "Jousting Eagle", "Armored bird, too heavy to fly.", 108, 955, 450)
	addMount("Mounts", "Ember Saurian", "Lizardy creature from the lagoons.", 111, 965, 450)
	addMount("Mounts", "Stone Rhino", "Hard as a Rock.", 116, 975, 450)
	addMount("Mounts", "Frogger", "Jumping ahead.", 105, 924, 400)
	addMount("Mounts", "Neon Sparkid", "Luminescent shining moth.", 98, 889, 400)
	addMount("Mounts", "Mole", "Dig dig dig.", 125, 1031, 400)
	addMount("Mounts", "Blackpelt", "Wont be taking any damage with that armor..", 58, 651, 400)
	addMount("Mounts", "Toxic Toad", "Hypnotoad deluxe edition.", 123, 1027, 400)
	addMount("Mounts", "Doombringer", "Shall curse your enemies with doom.", 53, 644, 350)
	addMount("Mounts", "Walker", "Mechanical experiment.", 43, 606, 300)
	addMount("Mounts", "Ladybug", "Lets out a mighty roar.", 27, 447, 300)

	addCategory("Heirlooms", "Beginner Item Sets.", "item", 2331)
	addItem("Heirlooms", "Mage Starter Box", "Contains a full mage beginner set.(Item level 100)", 29223, 1, 500)
	addItem("Heirlooms", "Archer Starter Box", "Contains a full archer beginner set.(Item level 100)", 29224, 1, 500)
	addItem("Heirlooms", "Squire Starter Box", "Contains a full squire beginner set.(Item level 100)", 29225, 1, 500)
	addItem("Heirlooms", "Scout Starter Box", "Contains a full scout beginner set.(Item level 100)", 29226, 1, 500)
	addItem("Heirlooms", "Warrior Starter Box", "Contains a full warrior beginner set.(Item level 100)", 29227, 1, 500)
end

local ExtendedEvent = CreatureEvent("GameShopExtended")

function ExtendedEvent.onExtendedOpcode(player, opcode, buffer)
	if opcode == CODE_GAMESHOP then
		if not GAME_SHOP then
			gameShopInitialize()
			addEvent(refreshPlayersPoints, 10 * 1000)
		end

		local status, json_data =
			pcall(
			function()
				return json.decode(buffer)
			end
		)
		if not status then
			return
		end

		local action = json_data.action
		local data = json_data.data
		if not action or not data then
			return
		end

		if action == "fetch" then
			gameShopFetch(player)
		elseif action == "purchase" then
			gameShopPurchase(player, data)
		elseif action == "gift" then
			gameShopPurchaseGift(player, data)
		end
	end
end

function gameShopFetch(player)
	local sex = player:getSex()

	player:sendExtendedOpcode(CODE_GAMESHOP, json.encode({action = "fetchBase", data = {categories = GAME_SHOP.categories, url = DONATION_URL}}))

	for category, offersTable in pairs(GAME_SHOP.offers) do
		local offers = {}

		for i = 1, #offersTable do
			local offer = offersTable[i]
			local data = {
				type = offer.type,
				title = offer.title,
				description = offer.description,
				price = offer.price
			}

			if offer.count then
				data.count = offer.count
			end
			if offer.clientId then
				data.clientId = offer.clientId
			end
			if sex == PLAYERSEX_MALE then
				if offer.outfitMale then
					data.outfit = offer.outfitMale
				end
			else
				if offer.outfitFemale then
					data.outfit = offer.outfitFemale
				end
			end
			if offer.data then
				data.data = offer.data
			end
			table.insert(offers, data)
		end
		player:sendExtendedOpcode(CODE_GAMESHOP, json.encode({action = "fetchOffers", data = {category = category, offers = offers}}))
	end

	gameShopUpdatePoints(player)
	gameShopUpdateHistory(player)
end

function gameShopUpdatePoints(player)
	if type(player) == "number" then
		player = Player(player)
	end
	player:sendExtendedOpcode(CODE_GAMESHOP, json.encode({action = "points", data = getPoints(player)}))
end

function gameShopUpdateHistory(player)
	if type(player) == "number" then
		player = Player(player)
	end
	local history = {}
	local resultId = db.storeQuery("SELECT * FROM `shop_history` WHERE `account` = " .. player:getAccountId() .. " order by `id` DESC")

	if resultId ~= false then
		repeat
			local desc = "Bought " .. result.getDataString(resultId, "title")
			local count = result.getDataInt(resultId, "count")
			if count > 0 then
				desc = desc .. " (x" .. count .. ")"
			end
			local target = result.getDataString(resultId, "target")
			if target ~= "" then
				desc = desc .. " on " .. result.getDataString(resultId, "date") .. " for " .. target .. " for " .. result.getDataInt(resultId, "price") .. " points."
			else
				desc = desc .. " on " .. result.getDataString(resultId, "date") .. " for " .. result.getDataInt(resultId, "price") .. " points."
			end
			table.insert(history, desc)
		until not result.next(resultId)
		result.free(resultId)
	end
	player:sendExtendedOpcode(CODE_GAMESHOP, json.encode({action = "history", data = history}))
end

function gameShopPurchase(player, offer)
	local offers = GAME_SHOP.offers[offer.category]
	if not offers then
		return errorMsg(player, "Something went wrong, try again or contact server admin [#1]!")
	end
	for i = 1, #offers do
		if offers[i].title == offer.title and offers[i].price == offer.price then
			local callback = offers[i].callback
			if not callback then
				return errorMsg(player, "Something went wrong, try again or contact server admin [#2]!")
			end

			local points = getPoints(player)
			if offers[i].price > points then
				return errorMsg(player, "You don't have enough points!")
			end

			local status = callback(player, offers[i])
			if status ~= true then
				return errorMsg(player, status)
			end

			local aid = player:getAccountId()
			local escapeTitle = db.escapeString(offers[i].title)
			local escapePrice = db.escapeString(offers[i].price)
			local escapeCount = offers[i].count and db.escapeString(offers[i].count) or 0

			db.query("UPDATE `znote_accounts` set `points` = `points` - " .. offers[i].price .. " WHERE `account_id` = " .. aid)
			db.asyncQuery(
				"INSERT INTO `shop_history` VALUES (NULL, '" ..
					aid .. "', '" .. player:getGuid() .. "', NOW(), " .. escapeTitle .. ", " .. escapePrice .. ", " .. escapeCount .. ", NULL)"
			)
			addEvent(gameShopUpdateHistory, 1000, player:getId())
			addEvent(gameShopUpdatePoints, 1000, player:getId())
			return infoMsg(player, "You've bought " .. offers[i].title .. "!", true)
		end
	end
	return errorMsg(player, "Something went wrong, try again or contact server admin [#4]!")
end

function gameShopPurchaseGift(player, offer)
	local offers = GAME_SHOP.offers[offer.category]
	if not offers then
		return errorMsg(player, "Something went wrong, try again or contact server admin [#1]!")
	end
	if not offer.target then
		return errorMsg(player, "Target player not found!")
	end
	for i = 1, #offers do
		if offers[i].title == offer.title and offers[i].price == offer.price then
			local callback = offers[i].callback
			if not callback then
				return errorMsg(player, "Something went wrong, try again or contact server admin [#2]!")
			end

			local points = getPoints(player)
			if offers[i].price > points then
				return errorMsg(player, "You don't have enough points!")
			end

			local targetPlayer = Player(offer.target)
			if not targetPlayer then
				return errorMsg(player, "Target player not found!")
			end

			local status = callback(targetPlayer, offers[i])
			if status ~= true then
				return errorMsg(player, status)
			end

			local aid = player:getAccountId()
			local escapeTitle = db.escapeString(offers[i].title)
			local escapePrice = db.escapeString(offers[i].price)
			local escapeCount = offers[i].count and db.escapeString(offers[i].count) or 0
			local escapeTarget = db.escapeString(targetPlayer:getName())
			db.query("UPDATE `znote_accounts` set `points` = `points` - " .. offers[i].price .. " WHERE `account_id` = " .. aid)
			db.asyncQuery(
				"INSERT INTO `shop_history` VALUES (NULL, '" ..
					aid .. "', '" .. player:getGuid() .. "', NOW(), " .. escapeTitle .. ", " .. escapePrice .. ", " .. escapeCount .. ", " .. escapeTarget .. ")"
			)
			addEvent(gameShopUpdateHistory, 1000, player:getId())
			addEvent(gameShopUpdatePoints, 1000, player:getId())
			return infoMsg(player, "You've bought " .. offers[i].title .. " for " .. targetPlayer:getName() .. "!", true)
		end
	end
	return errorMsg(player, "Something went wrong, try again or contact server admin [#4]!")
end

function getPoints(player)
	local points = 0
	local resultId = db.storeQuery("SELECT `points` FROM `znote_accounts` WHERE `account_id` = " .. player:getAccountId())
	if resultId ~= false then
		points = result.getDataInt(resultId, "points")
		result.free(resultId)
	end
	return points
end

function errorMsg(player, msg)
	player:sendExtendedOpcode(CODE_GAMESHOP, json.encode({action = "msg", data = {type = "error", msg = msg}}))
end

function infoMsg(player, msg, close)
	if not close then
		close = false
	end
	player:sendExtendedOpcode(CODE_GAMESHOP, json.encode({action = "msg", data = {type = "info", msg = msg, close = close}}))
end

function addCategory(title, description, iconType, iconData)
	if iconType == "item" then
		iconData = ItemType(iconData):getClientId()
	end

	table.insert(
		GAME_SHOP.categories,
		{
			title = title,
			description = description,
			iconType = iconType,
			iconData = iconData
		}
	)
end

function addItem(category, title, description, itemId, count, price, callback)
	if not GAME_SHOP.offers[category] then
		GAME_SHOP.offers[category] = {}
	end

	if not callback then
		callback = defaultItemCallback
	end

	table.insert(
		GAME_SHOP.offers[category],
		{
			type = "item",
			title = title,
			description = description,
			itemId = itemId,
			count = count,
			price = price,
			clientId = ItemType(itemId):getClientId(),
			callback = callback
		}
	)
end

function addOutfit(category, title, description, outfitMale, outfitFemale, price, callback)
	if not GAME_SHOP.offers[category] then
		GAME_SHOP.offers[category] = {}
	end

	if not callback then
		callback = defaultOutfitCallback
	end

	table.insert(
		GAME_SHOP.offers[category],
		{
			type = "outfit",
			title = title,
			description = description,
			outfitMale = outfitMale,
			outfitFemale = outfitFemale,
			price = price,
			callback = callback
		}
	)
end

function addMount(category, title, description, mountId, clientId, price, callback)
	if not GAME_SHOP.offers[category] then
		GAME_SHOP.offers[category] = {}
	end

	if not callback then
		callback = defaultMountCallback
	end

	table.insert(
		GAME_SHOP.offers[category],
		{
			type = "mount",
			title = title,
			description = description,
			mount = mountId,
			clientId = clientId,
			price = price,
			callback = callback
		}
	)
end

function addCustom(category, type, title, description, data, count, price, callback)
	if not GAME_SHOP.offers[category] then
		GAME_SHOP.offers[category] = {}
	end

	if not callback then
		error("[Game Shop] addCustom " .. title .. " without callback")
		return
	end

	table.insert(
		GAME_SHOP.offers[category],
		{
			type = type,
			title = title,
			description = description,
			data = data,
			price = price,
			count = count,
			callback = callback
		}
	)
end

function defaultItemCallback(player, offer)
	local weight = ItemType(offer.itemId):getWeight(offer.count)
	if player:getFreeCapacity() < weight then
		return "This item is too heavy for you!"
	end

	local item = player:getSlotItem(CONST_SLOT_BACKPACK)
	if not item then
		return "You don't have enough space in backpack."
	end
	local slots = item:getEmptySlots(true)
	if slots <= 0 then
		return "You don't have enough space in backpack."
	end

	if player:addItem(offer.itemId, offer.count, false) then
		return true
	end

	return "Something went wrong, item couldn't be added."
end

function defaultOutfitCallback(player, offer)
	if offer.outfitMale.addons > 0 then
		if player:hasOutfit(offer.outfitMale.type, offer.outfitMale.addons) then
			return "You already have this outfit with addons."
		end

		player:addOutfitAddon(offer.outfitMale.type, offer.outfitMale.addons)
	else
		if player:hasOutfit(offer.outfitMale.type) then
			return "You already have this outfit."
		end

		player:addOutfit(offer.outfitMale.type)
	end
	if offer.outfitFemale.addons > 0 then
		player:addOutfitAddon(offer.outfitFemale.type, offer.outfitFemale.addons)
	else
		player:addOutfit(offer.outfitFemale.type)
	end
	return true
end

function defaultMountCallback(player, offer)
	if player:hasMount(offer.mount) then
		return "You already have this mount."
	end

	player:addMount(offer.mount)
	return true
end

function refreshPlayersPoints()
	for _, p in ipairs(Game.getPlayers()) do
		if p:getIp() > 0 then
			gameShopUpdatePoints(p)
		end
	end
	addEvent(refreshPlayersPoints, 10 * 1000)
end

LoginEvent:type("login")
LoginEvent:register()
ExtendedEvent:type("extendedopcode")
ExtendedEvent:register()

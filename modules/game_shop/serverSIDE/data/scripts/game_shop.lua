local DONATION_URL = "https://github.com/mehah/otclient"
local GAME_SHOP = nil
local SECOND_CURRENCY_ENABLED = false

if not GlobalStorage then
    GlobalStorage = {}
end
GlobalStorage.GameShopRefreshCount = 89412

local pointsCache = {}
local secondPointsCache = {}
local shopInitialized = false

local LoginEvent = CreatureEvent("GameShopLogin")

local chars = {
    ' ', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 
    'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 
    'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 
    'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 
    'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
}

local ExtendedOPCodes = {
	CODE_GAMESHOP = 201
}

local forbiddenWords = {
'gm','adm','tutor','god','cm','admin','owner','g m','g o d','g0d','g 0 d','c m','administrator','senior','a d m',
'Trainer','Devil My Cry','Lavahole','Deaththrower','A Carved Stone Tile','Acolyte Of The Cult','Adept Of The Cult','Amazon','Ancient Scarab','Ashmunrah','Assassin','Azure Frog','Badger','Bandit','Banshee','Barbarian Bloodwalker','Barbarian Brutetamer','Barbarian Headsplitter','Barbarian Skullhunter','Bat','Bear','Behemoth','Beholder','Betrayed Wraith','Black Knight','Black Sheep','Blightwalker','Blood Crab','Blue Butterfly','Blue Djinn','Bonebeast','Braindeath','Bug','Carniphila','Carrion Worm','Cave Rat','Centipede','Chakoya Toolshaper','Chakoya Tribewarden','Chakoya Windcaller','Chicken','Cobra','Coral Frog','Crab','Crimson Frog','Crocodile','Crypt Shambler','Crystal Spider','Cyclops','Dark Magician','Dark Monk','Dark Torturer','Deathslicer','Deer','Defiler','Demon Skeleton','Demon','Destroyer','Diabolic Imp','Dipthrah','Dog','Dragon Lord','Dragon','Dwarf Geomancer','Dwarf Guard','Dwarf Soldier','Dwarf','Dworc Fleshhunter','Dworc Venomsniper','Dworc Voodoomaster','Efreet','Elder Beholder','Elephant','Elf Arcanist','Elf Scout','Elf','Enlightened Of The Cult','Eye Of The Seven','Fire Devil','Fire Elemental','Flamethrower','Flamingo','Frost Dragon','Frost Giant','Frost Giantess','Frost Troll','Fury','Gargoyle','Gazer','Ghost','Ghoul','Giant Spider','Goblin','Green Djinn','Green Frog','Hand Of Cursed Fate','Hell Hole','Hellfire Fighter','Hellhound','Hero','Hunter','Husky','Hyaena','Hydra','Ice Golem','Ice Witch','Juggernaut','Kongra','Larva','Lich','Lion','Lizard Noble','Lizard Sentinel','Lizard Snakecharmer','Lizard Templar','Lost Soul','Magic Pillar','Magicthrower','Mahrdis','Mammoth','Marid','Massive Fire Elemental','Massive Water Elemental','Merlkin','Minotaur Archer','Minotaur Guard','Minotaur Mage','Minotaur','Monk','Morguthis','Mummy','Necromancer','Nightmare','Nomad','Novice Of The Cult','Omruc','Orc Berserker','Orc Leader','Orc Rider','Orc Shaman','Orc Spearman','Orc Warlord','Orc Warrior','Orc','Orchid Frog','Panda','Parrot','Penguin','Phantasm Summon','Phantasm','Pig','Pillar','Pirate Buccaneer','Pirate Corsair','Pirate Cutthroat','Pirate Ghost','Pirate Marauder','Pirate Skeleton','Plaguesmith','Plaguethrower','Poison Spider','Polar Bear','Priestess','Purple Butterfly','Quara Constrictor Scout','Quara Constrictor','Quara Hydromancer Scout','Quara Hydromancer','Quara Mantassin Scout','Quara Mantassin','Quara Pincher Scout','Quara Pincher','Quara Predator Scout','Quara Predator','Rabbit','Rahemos','Rat','Red Butterfly','Rotworm','Scarab','Scorpion','Seagull','Serpent Spawn','Sheep','Shredderthrower','Sibang','Silver Rabbit','Skeleton','Skunk','Slime','Smuggler','Snake','Son Of Verminor','Spectre','Spider','Spit Nettle','Stalker','Stone Golem','Swamp Troll','Tarantula','Terror Bird','Thalas','Thornback Tortoise','Tiger','Toad','Tortoise','Troll','Undead Dragon','Valkyrie','Vampire','Vashresamun','War wolf','Warlock','Wasp','Wild Warrior','Winter Wolf','Witch','Wolf','Wyvern','Yellow Butterfly','Yeti','Annihilon','Apprentice Sheng','Barbaria','Bones','Brutus Bloodbeard','Countess Sorrow','Deadeye Devious','Demodras','Dharalion','Dire Penguin','Dracola','Fernfang','Ferumbras','Fluffy','Foreman Kneebiter','General Murius','Ghazbaran','Golgordan','Grorlam','Hairman The Huge',	'Hellgorak','Koshei The Deathless','Latrivan','Lethal Lissy','Mad Technomancer','Madareth','Man In The Cave','Massacre','Minishabaal','Morgaroth','Mr. Punish','Munster','Necropharus','Orshabaal',	'Ron the Ripper','The Abomination','The Evil Eye','The Handmaiden','The Horned Fox','The Imperor','The Old Widow','The Plasmother','Thul','Tiquandas Revenge','Undead Minion','Ungreez','Ushuriel','Xenia','Zugurosh'
}

local maxWords = 5
local maxLength = 20
local minChars = 2

function LoginEvent.onLogin(player)
	player:registerEvent("GameShopExtended")
	
	local accountId = player:getAccountId()
	
	local resultId = db.storeQuery("SELECT `points`, `points_second` FROM `znote_accounts` WHERE `id` = " .. accountId)
	if resultId ~= false then
		local points = result.getDataInt(resultId, "points")
		local secondPoints = result.getDataInt(resultId, "points_second")
		result.free(resultId)
		
		pointsCache[accountId] = {
			points = points,
			time = os.time()
		}
		
		if SECOND_CURRENCY_ENABLED then
			secondPointsCache[accountId] = {
				points = secondPoints,
				time = os.time()
			}
		end
	end
	
	return true
end

local CATEGORY_NONE = -1
local CATEGORY_PREMIUM = 0
local CATEGORY_ITEM = 1
local CATEGORY_BLESSING = 2
local CATEGORY_OUTFIT = 3
local CATEGORY_MOUNT = 4
local CATEGORY_EXTRAS = 5

local HEALTH_POTION_DESCRIPTION = "Restores your character's hit points.\n\n- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded"
local MANA_POTION_DESCRIPTION = "Refills your character's mana.\n\n- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded"
local PREMIUM_DESCRIPTION = "Enhance your gaming experience by gaining additional abilities and advantages:\n\n* access to Premium areas\n* use Tibia's transport system (ships, carpet)\n* more spells\n* rent houses\n* found guilds\n* larger Depots\n* and many more\n\n- valid for all characters on this account\n- activated at purchase"
local BLESSING_DESCRIPTION = "Reduces your character's chance to lose any items as well as the amount of your character's experience and skill loss upon death:\n\n* 1 blessing = 8.00% less Skill / XP loss, 30% equipment protection\n* 2 blessing = 16.00% less Skill / XP loss, 55% equipment protection\n* 3 blessing = 24.00% less Skill / XP loss, 75% equipment protection\n* 4 blessing = 32.00% less Skill / XP loss, 90% equipment protection\n* 5 blessing = 40.00% less Skill / XP loss, 100% equipment protection\n* 6 blessing = 48.00% less Skill / XP loss, 100% equipment protection\n* 7 blessing = 56.00% less Skill / XP loss, 100% equipment protection\n\n- only usable by purchasing character\n- maximum amount that can be owned by character: 5\n- added directly to the Record of Blessings\n- characters with a red or black skull will always lose all equipment upon death"

function gameShopInitialize()
	if shopInitialized then
		return
	end
	
	GAME_SHOP = {
		categories = {},
		categoriesId = {},
		offers = {}
	}
	
	addCategory(nil, "Premium Time", 20, CATEGORY_PREMIUM)
	addItem("Premium Time", "30 Days of Premium Time", "30_days", 250, false, 30, PREMIUM_DESCRIPTION)
	addItem("Premium Time", "90 Days of Premium Time", "90_days", 750, false, 90, PREMIUM_DESCRIPTION)
	addItem("Premium Time", "180 Days of Premium Time", "180_days", 1500, false, 180, PREMIUM_DESCRIPTION)
	addItem("Premium Time", "360 Days of Premium Time", "360_days", 3000, false, 360, PREMIUM_DESCRIPTION)

	addCategory(nil, "Rookgaard Items", 12, CATEGORY_ITEM)
	addItem("Rookgaard Items", "Health Potion", 7618, 6, false, 5, HEALTH_POTION_DESCRIPTION)
	addItem("Rookgaard Items", "Mana Potion", 7620, 6, false, 5, MANA_POTION_DESCRIPTION)

	addCategory(nil, "Consumables", 6, CATEGORY_NONE)
	addCategory("Consumables", "Blessings", 8, CATEGORY_BLESSING)
	addItem("Blessings", "All regular Blessings", "All_regular_Blessings", 130, false, -1, BLESSING_DESCRIPTION)
	addItem("Blessings", "The Spiritual Shielding", "The_Spiritual_Shielding", 25, false, 1, BLESSING_DESCRIPTION)
	addItem("Blessings", "The Embrace of Tibia", "The_Embrace_of_Tibia", 25, false, 2, BLESSING_DESCRIPTION)
	addItem("Blessings", "The Fire of the Suns", "The_Fire_of_the_Suns", 25, false, 3, BLESSING_DESCRIPTION)
	addItem("Blessings", "The Wisdom of Solitude", "The_Wisdom_of_Solitude", 25, false, 4, BLESSING_DESCRIPTION)
	addItem("Blessings", "The Spark of the Phoenix", "The_Spark_of_the_Phoenix", 25, false, 5, BLESSING_DESCRIPTION)

	addCategory("Consumables", "Potions", 10, CATEGORY_ITEM)
	addItem("Potions", "Mana Potion", 7620, 6, false, 125, MANA_POTION_DESCRIPTION)
	addItem("Potions", "Mana Potion", 7620, 12, false, 300, MANA_POTION_DESCRIPTION)
	addItem("Potions", "Strong Mana Potion", 7589, 7, false, 100, MANA_POTION_DESCRIPTION)
	addItem("Potions", "Strong Mana Potion", 7589, 17, false, 250, MANA_POTION_DESCRIPTION)
	addItem("Potions", "Great Mana Potion", 7590, 11, false, 100, MANA_POTION_DESCRIPTION)
	addItem("Potions", "Great Mana Potion", 7590, 26, false, 250, MANA_POTION_DESCRIPTION)
	addItem("Potions", "Health Potion", 7618, 6, false, 125, HEALTH_POTION_DESCRIPTION)
	addItem("Potions", "Health Potion", 7618, 11, false, 300, HEALTH_POTION_DESCRIPTION)
	addItem("Potions", "Strong Health Potion", 7588, 10, false, 100, HEALTH_POTION_DESCRIPTION)
	addItem("Potions", "Strong Health Potion", 7588, 21, false, 250, HEALTH_POTION_DESCRIPTION)
	addItem("Potions", "Great Health Potion", 7591, 18, false, 100, HEALTH_POTION_DESCRIPTION)
	addItem("Potions", "Great Health Potion", 7591, 41, false, 250, HEALTH_POTION_DESCRIPTION)
	
	addCategory("Consumables", "Runes", 19, CATEGORY_ITEM)
	addItem("Runes", "Animate Dead Rune", 2316, 75, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nAfter a long time of research, the magicians of Edron succeeded in storing some life energy in a rune. When this energy was unleashed onto a body it was found that an undead creature arose that could be mentally controlled by the user of the rune. This rune is useful to create allies in combat.")
	addItem("Runes", "Avalanche Rune", 2274, 12, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nThe ice damage which arises from this rune is a useful weapon in every battle but it comes in particularly handy if you fight against a horde of creatures dominated by the element fire.")
	addItem("Runes", "Chameleon Rune", 2291, 42, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nThe metamorphosis caused by this rune is only superficial, and while casters who are using the rune can take on the exterior form of nearly any inanimate object, they will always retain their original smell and mental abilities. So there is no real practical use for this rune, making this largely a fun rune.")
	addItem("Runes", "Convince Creature Rune", 2290, 16, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nUsing this rune together with some mana, you can convince certain creatures. The needed amount of mana is determined by the power of the creature one wishes to convince, so the amount of mana to convince a rat is lower than that which is needed for an orc.")
	addItem("Runes", "Cure Poison Rune", 2266, 13, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nIn the old days, many adventurers fell prey to poisonous creatures that were roaming the caves and forests. After many years of research druids finally succeeded in altering the cure poison spell so it could be bound to a rune. By using this rune it is possible to stop the effect of any known poison.")
	addItem("Runes", "Disintegrate Rune", 2310, 5, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nNothing is worse than being cornered when fleeing from an enemy you just cannot beat, especially if the obstacles in your way are items you could easily remove if only you had the time! However, there is one reliable remedy: The Disintegrate rune will instantly destroy up to 500 movable items that are in your way, making room for a quick escape.")
	addItem("Runes", "Energy Bomb Rune", 2262, 40, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nUsing the Energy Bomb rune will create a field of deadly energy that deals damage to all who carelessly step into it. Its area of effect is covering a full 9 square metres! Creatures that are caught in the middle of an Energy Bomb are frequently confused by the unexpected effect, and some may even stay in the field of deadly sparks for a while.")
	addItem("Runes", "Energy Field Rune", 2277, 8, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nThis spell creates a limited barrier made up of crackling energy that will cause electrical damage to all those passing through. Since there are few creatures that are immune to the harmful effects of energy this spell is not to be underestimated.")
	addItem("Runes", "Energy Wall Rune", 2279, 17, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nCasting this spell generates a solid wall made up of magical energy. Walls made this way surpass any other magically created obstacle in width, so it is always a good idea to have an Energy Wall rune or two in one's pocket when travelling through the wilderness.")
	addItem("Runes", "Explosion Rune", 2313, 6, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nThis rune must be aimed at areas rather than at specific creatures, so it is possible for explosions to be unleashed even if no targets are close at all. These explosions cause a considerable physical damage within a substantial blast radius.")
	addItem("Runes", "Fireball Rune", 2302, 6, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nWhen this rune is used a massive fiery ball is released which hits the aimed foe with immense power. It is especially effective against opponents of the element earth.")
	addItem("Runes", "Fire Bomb Rune", 2305, 29, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nThis rune is a deadly weapon in the hands of the skilled user. On releasing it an area of 9 square metres is covered by searing flames that will scorch all those that are unfortunate enough to be caught in them. Worse, many monsters are confused by the unexpected blaze, and with a bit of luck a caster will even manage to trap his opponents by using the spell.")
	addItem("Runes", "Fire Field Rune", 2301, 6, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nWhen this rune is used a field of one square metre is covered by searing fire that will last for some minutes, gradually diminishing as the blaze wears down. As with all field spells, Fire Field is quite useful to block narrow passageways or to create large, connected barriers.")
	addItem("Runes", "Fire Wall Rune", 2303, 12, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nThis rune offers reliable protection against all creatures that are afraid of fire. The exceptionally long duration of the spell as well as the possibility to form massive barriers or even protective circles out of fire walls make this a versatile, practical spell.")
	addItem("Runes", "Great Fireball Rune", 2304, 12, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nA shot of this rune affects a huge area - up to 37 square metres! It stands to reason that the Great Fireball is a favourite of most Tibians, as it is well suited both to hit whole crowds of monsters and individual targets that are difficult to hit because they are fast or hard to spot.")
	addItem("Runes", "Icicle Rune", 2271, 6, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nParticularly creatures determined by the element fire are vulnerable against this ice-cold rune. Being hit by the magic stored in this rune, an ice arrow seems to pierce the heart of the struck victim. The damage done by this rune is quite impressive which makes this a quite popular rune among Tibian mages.")
	addItem("Runes", "Intense Healing Rune", 2265, 19, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nThis rune is commonly used by young adventurers who are not skilled enough to use the rune's stronger version. Also, since the rune's effectiveness is determined by the user's magic skill, it is still popular among experienced spell casters who use it to get effective healing magic at a cheap price.")
	addItem("Runes", "Magic Wall Rune", 2293, 23, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nThis spell causes all particles that are contained in the surrounding air to quickly gather and contract until a solid wall is formed that covers one full square metre. The wall that is formed that way is impenetrable to any missiles or to light and no creature or character can walk through it. However, the wall will only last for a couple of seconds.")
	addItem("Runes", "Poison Bomb Rune", 2286, 19, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nThis rune causes an area of 9 square metres to be contaminated with toxic gas that will poison anybody who is caught within it. Conceivable applications include the blocking of areas or the combat against fast-moving or invisible targets. Keep in mind, however, that there are a number of creatures that are immune to poison.")
	addItem("Runes", "Poison Wall Rune", 2289, 10, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nWhen this rune is used a wall of concentrated toxic fumes is created which inflicts a moderate poison on all those who are foolish enough to enter it. The effect is usually impressive enough to discourage monsters from doing so, although few of the stronger ones will hesitate if there is nothing but a poison wall between them and their dinner.")
	addItem("Runes", "Soulfire Rune", 2308, 9, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nSoulfire is an immensely evil spell as it directly targets a creature's very life essence. When the rune is used on a victim, its soul is temporarily moved out of its body, casting it down into the blazing fires of hell itself! Note that the experience and the mental strength of the caster influence the damage that is caused.")
	addItem("Runes", "Stone Shower Rune", 2288, 9, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nParticularly creatures with an affection to energy will suffer greatly from this rune filled with powerful earth damage. As the name already says, a shower of stones drums on the opponents of the rune user in an area up to 37 squares.")
	addItem("Runes", "Sudden Death Rune", 2268, 28, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nNearly no other spell can compare to Sudden Death when it comes to sheer damage. For this reason it is immensely popular despite the fact that only a single target is affected. However, since the damage caused by the rune is of deadly nature, it is less useful against most undead creatures.")
	addItem("Runes", "Thunderstorm Rune", 2315, 9, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nFlashes filled with dangerous energy hit the rune user's opponent when this rune is being used. It is especially effective against ice dominated creatures. Covering up an area up to 37 squares, this rune is particularly useful when you meet a whole mob of opponents.")
	addItem("Runes", "Ultimate Healing Rune", 2273, 35, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nThe coveted Ultimate Healing rune is an all-time favourite among all vocations. No other healing enchantments that are bound into runes can compare to its salutary effect.")
	addItem("Runes", "Wild Growth Rune", 2269, 32, false, 250, "- only usable by purchasing character\n- will be sent to your backpack\n- cannot be purchased by characters with protection zone block or battle sign\n- cannot be purchased if capacity is exceeded\n\nBy unleashing this spell, all seeds that are lying dormant in the surrounding quickly sprout and grow into full-sized plants, thus forming an impenetrable thicket. Unfortunately, plant life created this way is short-lived and will collapse within minutes, so the magically created obstacle will not last long.")

	addCategory(nil, "Cosmetics", 21, CATEGORY_NONE)
	addCategory("Cosmetics", "Mounts", 14, CATEGORY_MOUNT)
	addItem("Mounts", "Arctic Unicorn", 1018, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThe Arctic Unicorn lives in a deep rivalry with its cousin the Blazing Unicorn. Even though they were born in completely different areas, they somehow share the same bloodline. The eternal battle between fire and ice continues. Who will win? Tangerine vs.crystal blue! The choice is yours!")
	addItem("Mounts", "Armoured War Horse", 426, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThe Armoured War Horse is a dangerous black beauty! When you see its threatening, blood-red eyes coming towards you, you'll know trouble is on its way. Protected by its heavy armour plates, the warhorse is the perfect partner for dangerous hunting sessions and excessive enemy slaughtering.")
	addItem("Mounts", "Batcat", 728, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nRumour has it that many years ago elder witches had gathered to hold a magical feast high up in the mountains. They had crossbred Batcat to easily conquer rocky canyons and deep valleys. Nobody knows what happened on their way up but only the mount has been seen ever since.")
	addItem("Mounts", "Battle Badger", 1247, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nBadgers have been a staple of the Tibian fauna for a long time, and finally some daring souls have braved the challenge to tame some exceptional specimens - and succeeded! While the common badger you can encounter during your travels might seem like a rather unassuming creature, the Battle Badger, the Ether Badger, and the Zaoan Badger are fierce and mighty beasts, which are at your beck and call.")
	addItem("Mounts", "Black Stag", 686, 660, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nTreat your character to a new travelling companion with a gentle nature and an impressive antler: The noble Black Stag will carry you through the deepest snow.")
	addItem("Mounts", "Blackpelt", 651, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThe Blackpelt is out searching for the best bamboo in Tibia. Its heavy armour allows it to visit even the most dangerous places. Treat it nicely with its favourite food from time to time and it will become a loyal partner.")
	addItem("Mounts", "Blazing Unicorn", 1017, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThe Blazing Unicorn lives in a deep rivalry with its cousin the Arctic Unicorn. Even though they were born in completely different areas, they somehow share the same bloodline. The eternal battle between fire and ice continues. Who will win? Crystal blue vs. tangerine! The choice is yours!")
	addItem("Mounts", "Bloodcurl", 869, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nYou are fascinated by insectoid creatures and can picture yourself riding one during combat or just for travelling? The Bloodcurl will carry you through the Tibian wilderness with ease.")
	addItem("Mounts", "Bog Tyrant", 1743, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThis monstrous creature lords over swamps, its body covered in toxic moss and grime.")
	addItem("Mounts", "Bogwurm", 1447, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nBurrowing from the depths of forgotten tunnels, this creature thrives in the shadows. The Bogwurm is as tough as steel and as fast as fear.")
	addItem("Mounts", "Boisterous Bull", 1672, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nA symbol of raw power and determination. The Boisterous Bull is as loud as it is loyal.")
	addItem("Mounts", "Boreal Owl", 1106, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nOwls have always been a symbol of mystery, magic and wisdom in Tibian myths and fairy tales. Having one of these enigmatic creatures of the night as a trustworthy companion provides you with a silent guide whose ever-watchful eyes will cut through the shadows, help you navigate the darkness and unravel great secrets.")
	addItem("Mounts", "Brass Speckled Koi", 1609, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nElegant, serene, and ever-gliding — these koi mounts are symbols of balance and beauty.")
	addItem("Mounts", "Bumblebee", 1778, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nBuzzing with energy, the Bumblebee zips through the skies leaving a trail of pollen and sparks.")
	addItem("Mounts", "Bunny Dray", 1180, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nYour lower back worsens with every trip you spend on the back of your mount and you are looking for a more comfortable alternative to travel through the lands? Say no more! The Bunny Dray comes with two top-performing hares that never get tired thanks to the brand new and highly innovative propulsion technology. Just keep some back-up carrots in your pocket and you will be fine!")
	addItem("Mounts", "Caped Snowman", 1169, 900, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nWhen the nights are getting longer and freezing wind brings driving snow into the land, snowmen rise and shine on every corner. Lately, a peaceful, arcane creature has found shelter in one of them and used its magical power to call the Caped Snowman into being. Wrap yourself up well and warmly and jump on the back of your new frosty companion.")
	addItem("Mounts", "Cave Tarantula", 1026, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nIt is said that the Cave Tarantula was born long before Banor walked the earth of Tibia. While its parents died in the war against the cruel hordes sent by Brog and Zathroth, their child survived by hiding in skulls of burned enemies. It never left its hiding spot and as it grew older, the skulls merged into its body. Now, it is fully-grown and thirsts for revenge.")
	addItem("Mounts", "Cerberus Champion", 1209, 1250, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nA fierce and grim guardian of the underworld has risen to fight side by side with the bravest warriors in order to send evil creatures into the realm of the dead. The three headed Cerberus Champion is constantly baying for blood and using its sharp fangs it easily rips apart even the strongest armour and shield.")
	addItem("Mounts", "Cinderhoof", 851, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nIf you are more of an imp than an angel, you may prefer riding out on a Cinderhoof to scare fellow Tibians on their festive strolls. Its devilish mask, claw-like hands and sharp hooves makes it the perfect companion for any daring adventurer who likes to stand out.")
	addItem("Mounts", "Cinnamon Ibex", 1528, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nSurefooted and resilient, these ibexes were raised among mountain peaks. Their floral names are a nod to the patches of wildflowers found high above the clouds.")
	addItem("Mounts", "Cony Cart", 1181, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nYour lower back worsens with every trip you spend on the back of your mount and you are looking for a more comfortable alternative to travel through the lands? Say no more! The Cony Cart comes with two top-performing hares that never get tired thanks to the brand new and highly innovative propulsion technology. Just keep some back-up carrots in your pocket and you will be fine!")
	addItem("Mounts", "Copper Fly", 671, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nIf you are more interested in the achievements of science, you may enjoy a ride on the Copper Fly, one of the new insect-like flying machines. Even if you do not move around, the wings of these unusual vehicles are always in motion.")
	addItem("Mounts", "Coral Rhea", 1325, 500, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nDespite their inability to fly, these strong-legged birds are lightning-fast and utterly reliable when crossing large distances over dry terrain.")
	addItem("Mounts", "Coralripper", 735, 570, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nIf the Coralripper moves its fins, it generates enough air pressure that it can even float over land. Its numerous eyes allow it to quickly detect dangers even in confusing situations and eliminate them with one powerful bite. If you watch your fingers, you are going to be good friends.")
	addItem("Mounts", "Corpsefire Skull", 1687, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nForged from cursed bones and shadowed flame, this skull mount is only tamed by death itself.")
	addItem("Mounts", "Cranium Spider", 1025, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nIt is said that the Cranium Spider was born long before Banor walked the earth of Tibia. While its parents died in the war against the cruel hordes sent by Brog and Zathroth, their child survived by hiding in skulls of burned enemies. It never left its hiding spot and as it grew older, the skulls merged into its body. Now, it is fully-grown and thirsts for revenge.")
	addItem("Mounts", "Crimson Fang", 1744, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nBlood-red and battle-scarred, this predator obeys no one except its chosen rider.")
	addItem("Mounts", "Crimson Ray", 521, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nHave you ever dreamed of gliding through the air on the back of a winged creature? With its deep red wings, the majestic Crimson Ray is a worthy mount for courageous heroes. Feel like a king on its back as you ride into your next adventure.")
	addItem("Mounts", "Cunning Hyaena", 1334, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThese rugged animals are fearsome in packs and cunning when left alone. Riding one gives you not only speed but a fearsome reputation.")
	addItem("Mounts", "Dandelion", 1441, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThese graceful mounts are named after the vibrant flowers they resemble. They are calm, enduring, and add a blooming touch to your journey.")
	addItem("Mounts", "Darkfire Devourer", 1677, 1300, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nFrom the deepest rift beneath hell, the Darkfire Devourer hungers for conquest. Only the strongest may ride it.")
	addItem("Mounts", "Dawn Strayer", 1286, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nSome spirits are born from pure elements. The Dawn Strayer is a beacon of hope and a bringer of light. Ride it to greet the new day and strike fear into the hearts of nocturnal foes.")
	addItem("Mounts", "Dawnbringer Pegasus", 1727, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nA majestic celestial horse born of morning light, it shines with hope.")
	addItem("Mounts", "Death Crawler", 624, 600, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThe Death Crawler is a scorpion that has surpassed the natural boundaries of its own kind. Way bigger, stronger and faster than ordinary scorpions, it makes a perfect companion for fearless heroes and explorers. Just be careful of his poisonous sting when you mount it.")
	addItem("Mounts", "Desert King", 572, 450, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nIts roaring is piercing marrow and bone and can be heard over ten miles away. The Desert King is the undisputed ruler of its territory and no one messes with this animal. Show no fear and prove yourself worthy of its trust and you will get yourself a valuable companion for your adventures.")
	addItem("Mounts", "Doom Skull", 1685, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nForged from cursed bones and shadowed flame, this skull mount is only tamed by death itself.")
	addItem("Mounts", "Doombringer", 644, 780, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nOnce captured and held captive by a mad hunter, the Doombringer is the result of sick experiments. Fed only with demon dust and concentrated demonic blood it had to endure a dreadful transformation. The demonic blood that is now running through its veins, however, provides it with incredible strength and endurance.")
	addItem("Mounts", "Dreadhare", 906, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nDo you like fluffy bunnies but think they are too small? Do you admire the majesty of stags and their antlers but are afraid of their untameable wilderness? Do not worry, the mystic creature Dreadhare consolidates the best qualities of both animals. Hop on its backs and enjoy the ride.")
	addItem("Mounts", "Dusk Pryer", 1285, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nSome spirits are born from pure elements. The Dusk Pryer embodies the essence of twilight, ever seeking knowledge hidden in the transition between light and darkness.")
	addItem("Mounts", "Ebony Tiger", 1091, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nIt is said that in ancient times, the sabre-tooth tiger was already used as a mount by elder warriors of Svargrond. As seafaring began to expand, this noble big cat was also transported to other regions in Tibia. Influenced by the new environment and climatic changes, the fur of the Ebony Tiger has developed its extraordinary colouring over several generations.")
	addItem("Mounts", "Ember Saurian", 960, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThousands of years ago, its ancestors ruled the world. Only recently, it found its way into Tibia. The Ember Saurian has been spotted in a sea of flames and fire deep down in the depths of Kazordoon.")
	addItem("Mounts", "Emerald Raven", 1453, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nGraceful and mysterious, ravens have long been symbols of magic. The Emerald Raven's plumage glows faintly, enchanted by forest spirits.")
	addItem("Mounts", "Emerald Sphinx", 951, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nRide an Emerald Sphinx on your way through ancient chambers and tombs and have a loyal friend by your side while fighting countless mummies and other creatures.")
	addItem("Mounts", "Emerald Waccoon", 693, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nWaccoons are cuddly creatures that love nothing more than to be petted and snuggled! Share a hug, ruffle the fur of the Emerald Waccoon and scratch it behind its ears to make it happy.")
	addItem("Mounts", "Emperor Deer", 687, 660, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nTreat your character to a new travelling companion with a gentle nature and an impressive antler: The noble Emperor Deer will carry you through the deepest snow.")
	addItem("Mounts", "Ether Badger", 1248, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nBadgers have been a staple of the Tibian fauna for a long time, and finally some daring souls have braved the challenge to tame some exceptional specimens - and succeeded! While the common badger you can encounter during your travels might seem like a rather unassuming creature, the Battle Badger, the Ether Badger, and the Zaoan Badger are fierce and mighty beasts, which are at your beck and call.")
	addItem("Mounts", "Eventide Nandu", 1326, 500, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nDespite their inability to fly, these strong-legged birds are lightning-fast and utterly reliable when crossing large distances over dry terrain.")
	addItem("Mounts", "Feral Tiger", 1092, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nAs seafaring began to expand, this noble big cat was also transported to other regions in Tibia. Influenced by the new environment and climatic changes, the fur of the Feral Tiger has developed its extraordinary colouring over several generations.")
	addItem("Mounts", "Festive Mammoth", 1381, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nNot all mammoths are grim and gruff. This one's festive nature and cheerful demeanor will lighten even the darkest dungeon.")
	addItem("Mounts", "Festive Snowman", 1167, 900, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nWhen the nights are getting longer and freezing wind brings driving snow into the land, snowmen rise and shine on every corner. Lately, a peaceful, arcane creature has found shelter in one of them and used its magical power to call the Festive Snowman into being. Wrap yourself up well and warmly and jump on the back of your new frosty companion.")
	addItem("Mounts", "Flamesteed", 626, 900, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nOnce a majestic and proud warhorse, the Flamesteed has fallen in a horrible battle many years ago. Driven by agony and pain, its spirit once again took possession of its rotten corpse to avenge its death. Stronger than ever, it seeks a master to join the battlefield, aiming for nothing but death and destruction.")
	addItem("Mounts", "Flitterkatzen", 726, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nRumour has it that many years ago elder witches had gathered to hold a magical feast high up in the mountains. They had crossbred Flitterkatzen to easily conquer rocky canyons and deep valleys. Nobody knows what happened on their way up but only the mount has been seen ever since.")
	addItem("Mounts", "Floating Augur", 1266, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThese creatures are Floating Savants whose mind has been warped and bent to focus their extraordinary mental capabilities on one single goal: to do their master's bidding. Instead of being filled with an endless pursuit of knowledge, their live is now one of continuous thralldom and serfhood. The Floating Sage, the Floating Scholar and the Floating Augur are at your disposal.")
	addItem("Mounts", "Floating Kashmir", 690, 900, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThe Floating Kashmir is the perfect mount for those who are too busy to take care of an animal mount or simply like to travel on a beautiful, magic hand-woven carpet.")
	addItem("Mounts", "Floating Sage", 1264, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThese creatures are Floating Savants whose mind has been warped and bent to focus their extraordinary mental capabilities on one single goal: to do their master's bidding. Instead of being filled with an endless pursuit of knowledge, their live is now one of continuous thralldom and serfhood. The Floating Sage, the Floating Scholar and the Floating Augur are at your disposal.")
	addItem("Mounts", "Floating Scholar", 1265, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThese creatures are Floating Savants whose mind has been warped and bent to focus their extraordinary mental capabilities on one single goal: to do their master's bidding. Instead of being filled with an endless pursuit of knowledge, their live is now one of continuous thralldom and serfhood. The Floating Sage, the Floating Scholar and the Floating Augur are at your disposal.")
	addItem("Mounts", "Flying Divan", 688, 900, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThe Flying Divan is the perfect mount for those who are too busy to take care of an animal mount or simply like to travel on a beautiful, magic hand-woven carpet.")
	addItem("Mounts", "Foxmouse", 1632, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nAn unusual crossbreed of cunning and curiosity, this mount's playful energy is matched by its speed.")
	addItem("Mounts", "Frostbringer", 1615, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThis mount was born of the first winter storm and embodies the fury and beauty of snow.")
	addItem("Mounts", "Frostflare", 850, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nIf you are more of an imp than an angel, you may prefer riding out on a Frostflare to scare fellow Tibians on their festive strolls. Its devilish mask, claw-like hands and sharp hooves makes it the perfect companion for any daring adventurer who likes to stand out.")
	addItem("Mounts", "Glacier Vagabond", 674, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nWith its thick, shaggy hair, the Glacier Vagabond will keep you warm even in the chilly climate of the Ice Islands. Due to its calm and peaceful nature, it is not letting itself getting worked up easily.")
	addItem("Mounts", "Glacier Wyrm", 1742, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nCold-blooded and ancient, the Glacier Wyrm coils through frostbitten mountains in silence.")
	addItem("Mounts", "Gloom Widow", 1027, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nIt is said that the Gloom Widow was born long before Banor walked the earth of Tibia. While its parents died in the war against the cruel hordes sent by Brog and Zathroth, their child survived by hiding in skulls of burned enemies. It never left its hiding spot and as it grew older, the skulls merged into its body. Now, it is fully-grown and thirsts for revenge.")
	addItem("Mounts", "Gloomwurm", 1448, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nBurrowing from the depths of forgotten tunnels, this creature thrives in the shadows. The Gloomwurm is as tough as steel and as fast as fear.")
	addItem("Mounts", "Gold Sphinx", 950, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nRide a Gold Sphinx on your way through ancient chambers and tombs and have a loyal friend by your side while fighting countless mummies and other creatures.")
	addItem("Mounts", "Golden Dragonfly", 669, 600, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nIf you are more interested in the achievements of science, you may enjoy a ride on the Golden Dragonfly, one of the new insect-like flying machines. Even if you do not move around, the wings of these unusual vehicles are always in motion.")
	addItem("Mounts", "Gorgon Hydra", 1724, 1000, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nFew dare gaze into the many eyes of the Gorgon Hydra. This fearsome creature obeys no one — except you.")
	addItem("Mounts", "Gorongra", 738, 720, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nGet yourself a mighty travelling companion with broad shoulders and a gentle heart. Gorongra is a physically imposing creature that is much more peaceful than its relatives, Tiquanda's wild kongras, and will carry you safely wherever you ask it to go.")
	addItem("Mounts", "Hailstorm Fury", 648, 780, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nOnce captured and held captive by a mad hunter, the Hailstorm Fury is the result of sick experiments. Fed only with demon dust and concentrated demonic blood it had to endure a dreadful transformation. The demonic blood that is now running through its veins, however, provides it with incredible strength and endurance.")
	addItem("Mounts", "Highland Yak", 673, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nWith its thick, shaggy hair, the Highland Yak will keep you warm even in the chilly climate of the Ice Islands. Due to its calm and peaceful nature, it is not letting itself getting worked up easily.")
	addItem("Mounts", "Holiday Mammoth", 1380, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nNot all mammoths are grim and gruff. This one's festive nature and cheerful demeanor will lighten even the darkest dungeon.")
	addItem("Mounts", "Hyacinth", 1439, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThese graceful mounts are named after the vibrant flowers they resemble. They are calm, enduring, and add a blooming touch to your journey.")
	addItem("Mounts", "Icebreacher", 1617, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThis mount was born of the first winter storm and embodies the fury and beauty of snow.")
	addItem("Mounts", "Ink Spotted Koi", 1610, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nElegant, serene, and ever-gliding — these koi mounts are symbols of balance and beauty.")
	addItem("Mounts", "Ivory Fang", 901, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nIncredible strength and smartness, an irrepressible will to survive, passionately hunting in groups. If these attributes apply to your character, we have found the perfect partner for you. Have a proper look at Ivory Fang, which stands loyally by its master's side in every situation. It is time to become the leader of the wolf pack!")
	addItem("Mounts", "Jackalope", 905, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nDo you like fluffy bunnies but think they are too small? Do you admire the majesty of stags and their antlers but are afraid of their untameable wilderness? Do not worry, the mystic creature Jackalope consolidates the best qualities of both animals. Hop on its backs and enjoy the ride.")
	addItem("Mounts", "Jade Lion", 627, 450, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nIts roaring is piercing marrow and bone and can be heard over ten miles away. The Jade Lion is the undisputed ruler of its territory and no one messes with this animal. Show no fear and prove yourself worthy of its trust and you will get yourself a valuable companion for your adventures.")
	addItem("Mounts", "Jade Pincer", 628, 600, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThe Jade Pincer is a scorpion that has surpassed the natural boundaries of its own kind. Way bigger, stronger and faster than ordinary scorpions, it makes a perfect companion for fearless heroes and explorers. Just be careful of his poisonous sting when you mount it.")
	addItem("Mounts", "Jade Shrine", 1492, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nImbued with ancient divine energy, this shrine floats effortlessly. The Jade Shrine blesses its rider with peace and clarity.")
	addItem("Mounts", "Jousting Eagle", 1208, 800, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nHigh above the clouds far away from dry land, the training of giant eagles takes place. Only the cream of the crop is able to survive in such harsh environment long enough to call themselves Jousting Eagles while the weaklings find themselves at the bottom of the sea. The tough ones become noble and graceful mounts that are well known for their agility and endurance.")
	addItem("Mounts", "Jousting Horse", 1579, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nBred for ceremony and flair, this horse carries itself with grace and rhythm. Perfect for heroes who crave the spotlight.")
	addItem("Mounts", "Jungle Saurian", 959, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThousands of years ago, its ancestors ruled the world. Only recently, it found its way into Tibia. The Jungle Saurian likes to hide in dense wood and overturned trees.")
	addItem("Mounts", "Jungle Tiger", 1093, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nAs seafaring began to expand, this noble big cat was also transported to other regions in Tibia. Influenced by the new environment and climatic changes, the fur of the Jungle Tiger has developed its extraordinary colouring over several generations.")
	addItem("Mounts", "Lagoon Saurian", 961, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThousands of years ago, its ancestors ruled the world. Only recently, it found its way into Tibia. The Lagoon Saurian feels most comfortable in torrential rivers and behind dangerous waterfalls.")
	addItem("Mounts", "Leafscuttler", 870, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nYou are fascinated by insectoid creatures and can picture yourself riding one during combat or just for travelling? The Leafscuttler will carry you through the Tibian wilderness with ease.")
	addItem("Mounts", "Magic Carpet", 689, 900, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThe Magic Carpet is the perfect mount for those who are too busy to take care of an animal mount or simply like to travel on a beautiful, magic hand-woven carpet.")
	addItem("Mounts", "Magma Skull", 1686, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nForged from cursed bones and shadowed flame, this skull mount is only tamed by death itself.")
	addItem("Mounts", "Marsh Toad", 1052, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThe Magic Carpet is the perfect mount for those who are too busy to take cFor centuries, humans and monsters have dumped their garbage in the swamps around Venore. The combination of old, rusty weapons, stale mana and broken runes have turned some of the swamp dwellers into gigantic frogs. Benefit from those mutations and make the Marsh Toad a faithful mount for your adventures even beyond the bounds of the swamp.")
	addItem("Mounts", "Merry Mammoth", 1379, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nNot all mammoths are grim and gruff. This one's festive nature and cheerful demeanor will lighten even the darkest dungeon.")
	addItem("Mounts", "Mint Ibex", 1527, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nSurefooted and resilient, these ibexes were raised among mountain peaks. Their floral names are a nod to the patches of wildflowers found high above the clouds.")
	addItem("Mounts", "Mould Shell", 887, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nYou are intrigued by tortoises and would love to throne on a tortoise shell when travelling the Tibian wilderness? The Mould Shell might become your new trustworthy companion then, which will transport you safely and even carry you during combat.")
	addItem("Mounts", "Mouldpincer", 868, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nYou are fascinated by insectoid creatures and can picture yourself riding one during combat or just for travelling? The Mouldpincer will carry you through the Tibian wilderness with ease.")
	addItem("Mounts", "Muffled Snowman", 1168, 900, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nWhen the nights are getting longer and freezing wind brings driving snow into the land, snowmen rise and shine on every corner. Lately, a peaceful, arcane creature has found shelter in one of them and used its magical power to call the Muffled Snowman into being. Wrap yourself up well and warmly and jump on the back of your new frosty companion.")
	addItem("Mounts", "Mystic Raven", 1454, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nGraceful and mysterious, ravens have long been symbols of magic. The Mystic Raven's plumage glows faintly, enchanted by forest spirits.")
	addItem("Mounts", "Nethersteed", 629, 900, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nOnce a majestic and proud warhorse, the Nethersteed has fallen in a horrible battle many years ago. Driven by agony and pain, its spirit once again took possession of its rotten corpse to avenge its death. Stronger than ever, it seeks a master to join the battlefield, aiming for nothing but death and destruction.")
	addItem("Mounts", "Night Waccoon", 692, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nWaccoons are cuddly creatures that love nothing more than to be petted and snuggled! Share a hug, ruffle the fur of the Night Waccoon and scratch it behind its ears to make it happy.")
	addItem("Mounts", "Nightdweller", 849, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nIf you are more of an imp than an angel, you may prefer riding out on a Nightdweller to scare fellow Tibians on their festive strolls. Its devilish mask, claw-like hands and sharp hooves makes it the perfect companion for any daring adventurer who likes to stand out.")
	addItem("Mounts", "Nightmarish Crocovile", 1185, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nTo the keen observer, the crocovile is clearly a relative of the crocodile, albeit their look suggests an even more aggressive nature. While it is true that the power of its massive and muscular body can not only crush enemies dead but also break through any gate like a battering ram, a crocovile is, above all, a steadfast companion showing unwavering loyalty to its owner.")
	addItem("Mounts", "Nightstinger", 762, 780, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThe Nightstinger has external characteristics of different breeds. It is assumed that his brain is also composed of many different species, which makes it completely unpredictable. Only few have managed to approach this creature unharmed and only the best could tame it.")
	addItem("Mounts", "Noctungra", 739, 720, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nGet yourself a mighty travelling companion with broad shoulders and a gentle heart. Noctungra is a physically imposing creature that is much more peaceful than its relatives, Tiquanda's wild kongras, and will carry you safely wherever you ask it to go.")
	addItem("Mounts", "Obsidian Shrine", 1493, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nImbued with ancient divine energy, this shrine floats effortlessly. The Obsidian Shrine blesses its rider with peace and clarity.")
	addItem("Mounts", "Obstinate Ox", 1674, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nA symbol of raw power and determination. The Obstinate Ox is as loud as it is loyal.")
	addItem("Mounts", "Parade Horse", 1578, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nBred for ceremony and flair, this horse carries itself with grace and rhythm. Perfect for heroes who crave the spotlight.")
	addItem("Mounts", "Peony", 1440, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThese graceful mounts are named after the vibrant flowers they resemble. They are calm, enduring, and add a blooming touch to your journey.")
	addItem("Mounts", "Plumfish", 736, 570, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nIf the Plumfish moves its fins, it generates enough air pressure that it can even float over land. Its numerous eyes allow it to quickly detect dangers even in confusing situations and eliminate them with one powerful bite. If you watch your fingers, you are going to be good friends.")
	addItem("Mounts", "Poisonbane", 650, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThe Poisonbane is out searching for the best bamboo in Tibia. Its heavy armour allows it to visit even the most dangerous places. Treat it nicely with its favourite food from time to time and it will become a loyal partner.")
	addItem("Mounts", "Poppy Ibex", 1526, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nSurefooted and resilient, these ibexes were raised among mountain peaks. Their floral names are a nod to the patches of wildflowers found high above the clouds.")
	addItem("Mounts", "Prismatic Unicorn", 1019, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nLegend has it that a mare and a stallion once reached the end of a rainbow and decided to stay there. Influenced by the mystical power of the rainbow, the mare gave birth to an exceptional foal: Not only the big, strong horn on its forehead but the unusual colouring of its hair makes the Prismatic Unicorn a unique mount in every respect.")
	addItem("Mounts", "Rabbit Rickshaw", 1179, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nYour lower back worsens with every trip you spend on the back of your mount and you are looking for a more comfortable alternative to travel through the lands? Say no more! The Rabbit Rickshaw comes with two top-performing hares that never get tired thanks to the brand new and highly innovative propulsion technology. Just keep some back-up carrots in your pocket and you will be fine!")
	addItem("Mounts", "Radiant Raven", 1455, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nGraceful and mysterious, ravens have long been symbols of magic. The Radiant Raven's plumage glows faintly, enchanted by forest spirits.")
	addItem("Mounts", "Razorcreep", 763, 780, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThe Razorcreep has external characteristics of different breeds. It is assumed that his brain is also composed of many different species, which makes it completely unpredictable. Only few have managed to approach this creature unharmed and only the best could tame it.")
	addItem("Mounts", "Reed Lurker", 888, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nYou are intrigued by tortoises and would love to throne on a tortoise shell when travelling the Tibian wilderness? The Reed Lurker might become your new trustworthy companion then, which will transport you safely and even carry you during combat.")
	addItem("Mounts", "Rift Watcher", 1391, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nSilent, patient and always on the lookout for rifts in reality, these beings are drawn to those who walk between worlds. The Rift Watcher will not falter.")
	addItem("Mounts", "Ringtail Waccoon", 691, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nWaccoons are cuddly creatures that love nothing more than to be petted and snuggled! Share a hug, ruffle the fur of the Ringtail Waccoon and scratch it behind its ears to make it happy.")
	addItem("Mounts", "River Crocovile", 1183, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nTo the keen observer, the crocovile is clearly a relative of the crocodile, albeit their look suggests an even more aggressive nature. While it is true that the power of its massive and muscular body can not only crush enemies dead but also break through any gate like a battering ram, a crocovile is, above all, a steadfast companion showing unwavering loyalty to its owner.")
	addItem("Mounts", "Rune Watcher", 1390, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nSilent, patient and always on the lookout for rifts in reality, these beings are drawn to those who walk between worlds. The Rune Watcher will not falter.")
	addItem("Mounts", "Rustwurm", 1446, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nBurrowing from the depths of forgotten tunnels, this creature thrives in the shadows. The Rustwurm is as tough as steel and as fast as fear.")
	addItem("Mounts", "Sanguine Frog", 1053, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nFor centuries, humans and monsters have dumped their garbage in the swamps around Venore. The combination of old, rusty weapons, stale mana and broken runes have turned some of the swamp dwellers into gigantic frogs. Benefit from those mutations and make the Sanguine Frog a faithful mount for your adventures even beyond the bounds of the swamp.")
	addItem("Mounts", "Savanna Ostrich", 1324, 500, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nDespite their inability to fly, these strong-legged birds are lightning-fast and utterly reliable when crossing large distances over dry terrain.")
	addItem("Mounts", "Scruffy Hyaena", 1335, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThese rugged animals are fearsome in packs and cunning when left alone. Riding one gives you not only speed but a fearsome reputation.")
	addItem("Mounts", "Sea Devil", 734, 570, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nIf the Sea Devil moves its fins, it generates enough air pressure that it can even float over land. Its numerous eyes allow it to quickly detect dangers even in confusing situations and eliminate them with one powerful bite. If you watch your fingers, you are going to be good friends.")
	addItem("Mounts", "Shadow Claw", 902, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nIncredible strength and smartness, an irrepressible will to survive, passionately hunting in groups. If these attributes apply to your character, we have found the perfect partner for you. Have a proper look at Shadow Claw, which stands loyally by its master's side in every situation. It is time to become the leader of the wolf pack!")
	addItem("Mounts", "Shadow Draptor", 427, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nA wild, ancient creature, which had been hiding in the depths of the shadows for a very long time, has been spotted in Tibia again! The almighty Shadow Draptor has returned and only the bravest Tibians can control such a beast!")
	addItem("Mounts", "Shadow Hart", 685, 660, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nTreat your character to a new travelling companion with a gentle nature and an impressive antler: The noble Shadow Hart will carry you through the deepest snow.")
	addItem("Mounts", "Shadow Sphinx", 952, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nRide a Shadow Sphinx on your way through ancient chambers and tombs and have a loyal friend by your side while fighting countless mummies and other creatures.")
	addItem("Mounts", "Siegebreaker", 649, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThe Siegebreaker is out searching for the best bamboo in Tibia. Its heavy armour allows it to visit even the most dangerous places. Treat it nicely with its favourite food from time to time and it will become a loyal partner.")
	addItem("Mounts", "Silverneck", 740, 720, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nGet yourself a mighty travelling companion with broad shoulders and a gentle heart. Silverneck is a physically imposing creature that is much more peaceful than its relatives, Tiquanda's wild kongras, and will carry you safely wherever you ask it to go.")
	addItem("Mounts", "Skybreaker Pegasus", 1729, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nA mount that rides thunderclouds and breaks the heavens. The storm is its domain.")
	addItem("Mounts", "Slagsnare", 761, 780, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThe Slagsnare has external characteristics of different breeds. It is assumed that his brain is also composed of many different species, which makes it completely unpredictable. Only few have managed to approach this creature unharmed and only the best could tame it.")
	addItem("Mounts", "Snow Pelt", 903, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nIncredible strength and smartness, an irrepressible will to survive, passionately hunting in groups. If these attributes apply to your character, we have found the perfect partner for you. Have a proper look at Snow Pelt, which stands loyally by its master's side in every situation. It is time to become the leader of the wolf pack!")
	addItem("Mounts", "Snow Strider", 1284, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nSome spirits are born from pure elements. The Snow Strider came into being through a mix of pristine ice and eternal northern wind. With sharp hooves and sturdy legs, it glides effortlessly over snow and ice.")
	addItem("Mounts", "Snowy Owl", 1105, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nOwls have always been a symbol of mystery, magic and wisdom in Tibian myths and fairy tales. Having one of these enigmatic creatures of the night as a trustworthy companion provides you with a silent guide whose ever-watchful eyes will cut through the shadows, help you navigate the darkness and unravel great secrets.")
	addItem("Mounts", "Spirit of Purity", 1682, 1000, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nA radiant entity of light and truth, this mount protects those with noble hearts.")
	addItem("Mounts", "Steel Bee", 670, 600, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nIf you are more interested in the achievements of science, you may enjoy a ride on the Steel Bee, one of the new insect-like flying machines. Even if you do not move around, the wings of these unusual vehicles are always in motion.")
	addItem("Mounts", "Steelbeak", 522, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nForged by only the highest skilled blacksmiths in the depths of Kazordoon's furnaces, a wild animal made out of the finest steel arose from glowing embers and blazing heat. Protected by its impenetrable armour, the Steelbeak is ready to accompany its master on every battleground.")
	addItem("Mounts", "Surly Steer", 1673, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nA symbol of raw power and determination. The Surly Steer is as loud as it is loyal.")
	addItem("Mounts", "Swamp Crocovile", 1184, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nTo the keen observer, the crocovile is clearly a relative of the crocodile, albeit their look suggests an even more aggressive nature. While it is true that the power of its massive and muscular body can not only crush enemies dead but also break through any gate like a battering ram, a crocovile is, above all, a steadfast companion showing unwavering loyalty to its owner.")
	addItem("Mounts", "Swamp Snapper", 886, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nYou are intrigued by tortoises and would love to throne on a tortoise shell when travelling the Tibian wilderness? The Swamp Snapper might become your new trustworthy companion then, which will transport you safely and even carry you during combat.")
	addItem("Mounts", "Tangerine Flecked Koi", 1608, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nElegant, serene, and ever-gliding — these koi mounts are symbols of balance and beauty.")
	addItem("Mounts", "Tawny Owl", 1104, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nHaving one of these enigmatic creatures of the night as a trustworthy companion provides you with a silent guide whose ever-watchful eyes will cut through the shadows, help you navigate the darkness and unravel great secrets.")
	addItem("Mounts", "Tempest", 630, 900, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nOnce a majestic and proud warhorse, the Tempest has fallen in a horrible battle many years ago. Driven by agony and pain, its spirit once again took possession of its rotten corpse to avenge its death. Stronger than ever, it seeks a master to join the battlefield, aiming for nothing but death and destruction.")
	addItem("Mounts", "Tombstinger", 546, 600, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThe Tombstinger is a scorpion that has surpassed the natural boundaries of its own kind. Way bigger, stronger and faster than ordinary scorpions, it makes a perfect companion for fearless heroes and explorers. Just be careful of his poisonous sting when you mount it.")
	addItem("Mounts", "Topaz Shrine", 1491, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nImbued with ancient divine energy, this shrine floats effortlessly. The Topaz Shrine blesses its rider with peace and clarity.")
	addItem("Mounts", "Tourney Horse", 1580, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nBred for ceremony and flair, this horse carries itself with grace and rhythm. Perfect for heroes who crave the spotlight.")
	addItem("Mounts", "Toxic Toad", 1054, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nFor centuries, humans and monsters have dumped their garbage in the swamps around Venore. The combination of old, rusty weapons, stale mana and broken runes have turned some of the swamp dwellers into gigantic frogs. Benefit from those mutations and make the Toxic Toad a faithful mount for your adventures even beyond the bounds of the swamp.")
	addItem("Mounts", "Tundra Rambler", 672, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nWith its thick, shaggy hair, the Tundra Rambler will keep you warm even in the chilly climate of the Ice Islands. Due to its calm and peaceful nature, it is not letting itself getting worked up easily.")
	addItem("Mounts", "Venompaw", 727, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nRumour has it that many years ago elder witches had gathered to hold a magical feast high up in the mountains. They had crossbred Venompaw to easily conquer rocky canyons and deep valleys. Nobody knows what happened on their way up but only the mount has been seen ever since.")
	addItem("Mounts", "Void Watcher", 1389, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nSilent, patient and always on the lookout for rifts in reality, these beings are drawn to those who walk between worlds. The Void Watcher will not falter.")
	addItem("Mounts", "Voracious Hyaena", 1333, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThese rugged animals are fearsome in packs and cunning when left alone. Riding one gives you not only speed but a fearsome reputation.")
	addItem("Mounts", "Winter King", 631, 450, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nIts roaring is piercing marrow and bone and can be heard over ten miles away. The Winter King is the undisputed ruler of its territory and no one messes with this animal. Show no fear and prove yourself worthy of its trust and you will get yourself a valuable companion for your adventures.")
	addItem("Mounts", "Winterstride", 1616, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThis mount was born of the first winter storm and embodies the fury and beauty of snow.")
	addItem("Mounts", "Wolpertinger", 907, 870, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nOnce captured and held captive by a mad hunter, the Woodland Prince is the result of sick experiments. Fed only with demon dust and concentrated demonic blood it had to endure a dreadful transformation. The demonic blood that is now running through its veins, however, provides it with incredible strength and endurance.")
	addItem("Mounts", "Woodland Prince", 647, 780, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nOnce captured and held captive by a mad hunter, the Woodland Prince is the result of sick experiments. Fed only with demon dust and concentrated demonic blood it had to endure a dreadful transformation. The demonic blood that is now running through its veins, however, provides it with incredible strength and endurance.")
	addItem("Mounts", "Wrathfire Pegasus", 1728, 750, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nThis pegasus was forged in wrath and fire. Ride it to war, and leave a trail of flame.")
	addItem("Mounts", "Zaoan Badger", 1249, 690, false, 1, "- only usable by purchasing character\n- provides character with a speed boost\n\nBadgers have been a staple of the Tibian fauna for a long time, and finally some daring souls have braved the challenge to tame some exceptional specimens - and succeeded! While the common badger you can encounter during your travels might seem like a rather unassuming creature, the Battle Badger, the Ether Badger, and the Zaoan Badger are fierce and mighty beasts, which are at your beck and call.")

	addCategory("Cosmetics", "Outfits", 15, CATEGORY_OUTFIT)
	addItem("Outfits", "Elementalist", 432, 450, false, 1, "The warm and cosy cloak of the Winter Warden outfit will keep you warm in every situation. Best thing, it is not only comfortable but fashionable as well. You will be the envy of any snow queen or king, guaranteed!")
	addItem("Outfits", "Deepling", 463, 450, false, 1, "The Trailblazer is on a mission of enlightenment and carries the flame of wisdom near and far. The everlasting shine brightens the hearts and minds of all creatures its rays touch, bringing light even to the darkest corners of the world as a beacon of insight and knowledge.")
	addItem("Outfits", "Insectoid", 465, 450, false, 1, "Do you worship warm temperatures and are opposed to the thought of long and dark winter nights? Do you refuse to spend countless evenings in front of your chimney while ice-cold wind whistles through the cracks and niches of your house? It is time to stop freezing and to become an honourable Sun Priest! With this stylish outfit, you can finally show the world your unconditional dedication and commitment to the sun!")
	addItem("Outfits", "Entrepreneur", 472, 450, false, 1, "The mutated pumpkin is too weak for your mighty weapons? Time to show that evil vegetable how to scare the living daylight out of people! Put on a scary looking pumpkin on your head and spread terror and fear amongst the Tibian population.")

	addCategory(nil, "Boosts", 17, CATEGORY_EXTRAS)
	addItem("Boosts", "XP Boost", "XP_Boost", 30, false, 1, "Purchase a boost that increases the experience points your character gains from hunting by 50%!\n\n* only usable by purchasing character\n* lasts for 1 hour hunting time\n* paused if stamina falls under 14 hours\n* cannot be purchased if an XP boost is already active")

	addCategory(nil, "Extras", 9, CATEGORY_NONE)
	addCategory("Extras", "Extra Services", 7, CATEGORY_EXTRAS)
	addItem("Extra Services", "Name Change", "Name_Change", 250, false, 1, "Tired of your current character name? Purchase a new one!\n\n- only usable by purchasing character\n- relog required after purchase to finalise the name change")
	addItem("Extra Services", "Sex Change", "Sex_Change", 120, false, 1, "Turns your female character into a male one - or vice versa.\n\n- only usable by purchasing character\n- activated at purchase\n- you will keep all outfits you have purchased or earned in quest")
	
	addCategory("Extras", "Useful Things", 24, CATEGORY_EXTRAS)
	addItem("Useful Things", "Temple Teleport", "Temple_Teleport", 15, false, 1, "Teleports you instantly to your home temple.\n\n- only usable by purchasing character\n- use it to teleport you to your home temple\n- cannot be used while having a battle sign or a protection zone block")
	
	shopInitialized = true
end

function addCategory(parent, title, iconId, categoryId, description)
	GAME_SHOP.categoriesId[title] = categoryId
	table.insert(GAME_SHOP.categories, {
		title = title,
		parent = parent,
		iconId = iconId,
		categoryId = categoryId,
		description = description
	})
end

function addItem(parent, name, id, price, isSecondPrice, count, description)
	if not GAME_SHOP.offers[parent] then
		GAME_SHOP.offers[parent] = {}
	end

	local serverId = id
	if type(id) == "number" and GAME_SHOP.categoriesId[parent] == CATEGORY_ITEM then
		id = ItemType(id):getClientId()
	end

	table.insert(GAME_SHOP.offers[parent], {
		parent = parent,
		name = name,
		serverId = serverId,
		id = id,
		price = price,
		isSecondPrice = isSecondPrice,
		count = count,
		description = description,
		categoryId = GAME_SHOP.categoriesId[parent]
	})
end

function gameShopPurchase(player, offer)
	local offers = GAME_SHOP.offers[offer.parent]
	if not offers then
		return errorMsg(player, "Something went wrong, try again or contact server admin [#1]!")
	end

	for i = 1, #offers do
		if offers[i].name == offer.name and offers[i].price == offer.price and offers[i].count == offer.count then
			local points = 0
			local query = ""
			local accountId = player:getAccountId()
			
			if offers[i].isSecondPrice then
				points = getSecondCurrency(player)
				query = "points_second"
			else
				points = getPoints(player)
				query = "points"
			end
			
			if offers[i].price > points then
				return errorMsg(player, "You don't have enough points!")
			end

			offer.serverId = offers[i].serverId
			local status = finalizePurchase(player, offer)
			if status then
				return errorMsg(player, status)
			end

			local queryData = {
				"UPDATE `znote_accounts` set `", 
				query, 
				"` = `", 
				query, 
				"` - ", 
				tostring(offers[i].price), 
				" WHERE `id` = ", 
				tostring(accountId)
			}
			
			db.query(table.concat(queryData))
			
			if offers[i].isSecondPrice then
				if secondPointsCache[accountId] then
					secondPointsCache[accountId].points = secondPointsCache[accountId].points - offers[i].price
					secondPointsCache[accountId].time = os.time()
				end
			else
				if pointsCache[accountId] then
					pointsCache[accountId].points = pointsCache[accountId].points - offers[i].price
					pointsCache[accountId].time = os.time()
				end
			end
			
			local historyData = {
				"INSERT INTO `shop_history` VALUES (NULL, ", 
				tostring(accountId), 
				", ", 
				tostring(player:getGuid()), 
				", NOW(), ",
				db.escapeString(offers[i].name),
				", ",
				tostring(-offers[i].price),
				", ",
				offers[i].isSecondPrice and "1" or "0",
				", ",
				tostring(offers[i].count or 0),
				", NULL)"
			}
			
			db.asyncQuery(table.concat(historyData))
			
			addEvent(updatePlayerShopData, 1000, player:getId())
			
			return infoMsg(player, "You've bought " .. offers[i].name .. "!", true)
		end
	end
	
	return errorMsg(player, "Something went wrong, try again or contact server admin [#3]!")
end

function finalizePurchase(player, offer)
	local categoryId = GAME_SHOP.categoriesId[offer.parent]
	if categoryId == CATEGORY_PREMIUM then
		return defaultPremiumCallback(player, offer)
	elseif categoryId == CATEGORY_ITEM then
		return defaultItemCallback(player, offer)
	elseif categoryId == CATEGORY_BLESSING then
		return defaultBlessingCallback(player, offer)
	elseif categoryId == CATEGORY_OUTFIT then
		return defaultOutfitCallback(player, offer)
	elseif categoryId == CATEGORY_MOUNT then
		return defaultMountCallback(player, offer)
	elseif categoryId == CATEGORY_EXTRAS then
		return defaultExtrasCallback(player, offer)
	end

	return "Something went wrong, try again or contact server admin [#2]!"
end

function defaultPremiumCallback(player, offer)
	player:addPremiumDays(offer.count)
	return false
end

function defaultItemCallback(player, offer)
	local inPz = player:getTile():hasFlag(TILESTATE_PROTECTIONZONE)
	local inFight = player:isPzLocked() or player:getCondition(CONDITION_INFIGHT, CONDITIONID_DEFAULT)
	if not inPz or inFight then
		return "Cannot be used while having a battle sign or a protection zone block."
	end

	local weight = ItemType(offer.serverId):getWeight(offer.count)
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

	if player:addItem(offer.serverId, offer.count, false) then
		return false
	end

	return "Something went wrong, item couldn't be added."
end

function defaultBlessingCallback(player, offer)
	if offer.count == -1 then
		for i = 1, 5 do
			if not player:hasBlessing(i) then
				for i = 1, 5 do
					player:addBlessing(i)
				end

				return false
			end
		end

		return "You already have all blessings."
	elseif player:hasBlessing(offer.count) then
		return "You already have this blessing."
	end
	
	player:addBlessing(offer.count)
	return false
end

function defaultOutfitCallback(player, offer)
	if player:hasOutfit(offer.id, offer.count) then
		return "You already have this outfit."
	end

	player:addOutfitAddon(offer.id, offer.count)
	return false
end

function defaultMountCallback(player, offer)
	if player:hasMount(offer.id) then
		return "You already have this mount."
	end

	if not player:addMount(offer.id) then
		return "Something went wrong, mount cannot be added."
	end

	return false
end

function defaultExtrasCallback(player, offer)
	if offer.name == "Name Change" then
		return defaultChangeNameCallback(player, offer)
	elseif offer.name == "Sex Change" then
		return defaultChangeSexCallback(player)
	elseif offer.name == "Temple Teleport" then
		return defaultTeleportCallback(player)
	elseif offer.name == "XP Boost" then
		return defaultXPBoostCallback(player)
	end

	return "Something went wrong, extra service couldn't be executed."
end

function defaultChangeSexCallback(player)
	local inPz = player:getTile():hasFlag(TILESTATE_PROTECTIONZONE)
	local inFight = player:isPzLocked() or player:getCondition(CONDITION_INFIGHT, CONDITIONID_DEFAULT)
	if not inPz or inFight then
		return "Cannot be used while having a battle sign or a protection zone block."
	end

    if not player:getGroup() then
        return "You can't do this."
    end

    player:setSex(player:getSex() == PLAYERSEX_FEMALE and PLAYERSEX_MALE or PLAYERSEX_FEMALE)
	
    local outfit = player:getOutfit()
    if player:getSex(player) == PLAYERSEX_MALE then
        outfit.lookType = 128
    else
        outfit.lookType = 136
    end

    player:setOutfit(outfit)
    return false
end

function defaultChangeNameCallback(player, offer)
	local inPz = player:getTile():hasFlag(TILESTATE_PROTECTIONZONE)
	local inFight = player:isPzLocked() or player:getCondition(CONDITION_INFIGHT, CONDITIONID_DEFAULT)
	if not inPz or inFight then
		return "Cannot be used while having a battle sign or a protection zone block."
	end

    if not player:getGroup() then
        return "You can't do this."
    end

	local characterName = offer.nick:trim()
	local v = getValid(characterName:lower(), false)
	if not validName(v) then
		return "You can't use this character name."
	end

	if getPlayerDatabaseInfo(v) then
		return "Character name already taken."
	end

	local lastName = player:getName()
	db.query("UPDATE players SET name = "..db.escapeString(characterName).." WHERE name = "..db.escapeString(lastName)..";")
	db.query("UPDATE player_deaths SET killed_by = "..db.escapeString(characterName)..", mostdamage_by = "..db.escapeString(characterName).." WHERE killed_by = "..db.escapeString(lastName).." OR mostdamage_by = "..db.escapeString(lastName)..";")
	db.query("UPDATE player_deaths_backup SET killed_by = "..db.escapeString(characterName)..", mostdamage_by = "..db.escapeString(characterName).." WHERE killed_by = "..db.escapeString(lastName).." OR mostdamage_by = "..db.escapeString(lastName)..";")
	db.query(string.format("INSERT INTO `change_name_history` (`player_id`, `last_name`, `current_name`, `changed_name_in`) VALUES (%d, %s, %s, %d)", player:getGuid(), db.escapeString(lastName), db.escapeString(characterName), os.time()))
	return false
end

function defaultTeleportCallback(player, offer)
	local inFight = player:isPzLocked() or player:getCondition(CONDITION_INFIGHT, CONDITIONID_DEFAULT)
	if inFight then
		return "Cannot be used while having a battle sign or a protection zone block."
	end
	
	player:teleportTo(player:getTown():getTemplePosition())
	player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)	
	
	return false
end

function defaultXPBoostCallback(player, offer)
	local boostStorage = 693690
	local boostDuration = 3600
    local currentBoostEnd = player:getStorageValue(boostStorage)
    local currentStamina = player:getStamina()

    if currentBoostEnd >= os.time() and currentStamina > 14 * 60 then
        return "You already have an XP boost active!"
    end

    local newBoostEnd = os.time() + boostDuration

    if currentStamina <= 14 * 60 then
        local remainingStaminaTime = currentStamina * 60
        newBoostEnd = os.time() + remainingStaminaTime
    end

    player:setStorageValue(boostStorage, newBoostEnd)
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, "Your one hour XP boost has started! You will gain 50% extra experience while hunting.")
	return false
end

function getValid(name, opt)
    local function tchelper(first, rest)
        return first:upper()..rest:lower()
    end

    return opt and name:gsub("(%a)([%w_']*)", tchelper) or name:gsub("^%l", string.upper)
end

function validName(name)
    if not name then
		return false
	end

	local len = name:len()
	if len < minChars or len > maxLength then
		return false
	end
	
	if string.find(name, "  ") then
		return false
	end
	
	local wordCount = 1
	for i = 1, len do
		if name:sub(i, i) == " " then
			wordCount = wordCount + 1
			if wordCount > maxWords then
				return false
			end
		end
	end

	local lowerName = name:lower()
	for _, word in ipairs(forbiddenWords) do
		if string.find(lowerName, "%f[%a]" .. word .. "%f[%A]") then
			return false
		end
	end

    local charsSet = {}
    for i = 1, #chars do
        charsSet[chars[i]] = true
    end
    
    for i = 1, len do
        if not charsSet[name:sub(i, i)] then
            return false
        end
    end

    return true
end

function gameShopUpdateHistory(player)
	if type(player) == "number" then
		player = Player(player)
	end
	
	if not player then
		return
	end

	local history = {}
	local accountId = player:getAccountId()
	
	local resultId = db.storeQuery("SELECT * FROM `shop_history` WHERE `account` = " .. accountId .. " ORDER BY `id` DESC LIMIT 50")
	if resultId ~= false then
		repeat
			table.insert(history, {
				date = result.getDataString(resultId, "date"),
				price = result.getDataInt(resultId, "price"),
				isSecondPrice = result.getDataInt(resultId, "costSecond") == 1,
				name = result.getDataString(resultId, "title"),
				count = result.getDataInt(resultId, "count")
			})
		until not result.next(resultId)
		result.free(resultId)
	end
	
	player:sendExtendedOpcode(ExtendedOPCodes.CODE_GAMESHOP, json.encode({action = "history", data = history}))
end

local ExtendedEvent = CreatureEvent("GameShopExtended")

function ExtendedEvent.onExtendedOpcode(player, opcode, buffer)
    if opcode == ExtendedOPCodes.CODE_GAMESHOP then
        if not shopInitialized then
            gameShopInitialize()
            if getGlobalStorageValue(GlobalStorage.GameShopRefreshCount) == -1 then
                setGlobalStorageValue(GlobalStorage.GameShopRefreshCount, 0)
                addEvent(refreshPlayersPoints, 10 * 1000)
            end
        end

        local status, json_data = pcall(function() return json.decode(buffer) end)
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
        elseif action == "getDescription" then
            gameShopGetDescription(player, data)
        elseif action == "purchase" then
            gameShopPurchase(player, data)
        elseif action == "transfer" then
            gameShopTransferCoins(player, data)
        elseif action == "changeName" then
            gameShopChangeName(player, data)
        end
    end
end

function gameShopGetDescription(player, data)
    local category = data.category
    local name = data.name
    
    if GAME_SHOP.offers[category] then
        for _, offer in ipairs(GAME_SHOP.offers[category]) do
            if offer.name == name then
                player:sendExtendedOpcode(ExtendedOPCodes.CODE_GAMESHOP, json.encode({
                    action = "fetchDescription",
                    data = {
                        category = category,
                        name = name,
                        description = offer.description
                    }
                }))
                return
            end
        end
    end
end

function gameShopFetch(player)
    gameShopUpdatePoints(player)
    gameShopUpdateHistory(player)

    local isRookgaard = player:getVocation():getId() == 0
    local filteredCategories = {}
    
    for _, category in ipairs(GAME_SHOP.categories) do
        if isRookgaard then
            if category.title == "Rookgaard Items" or category.title == "Premium Time" or category.title == "Boosts" then
                table.insert(filteredCategories, category)
            end
        else
            if category.title ~= "Rookgaard Items" then
                table.insert(filteredCategories, category)
            end
        end
    end

    player:sendExtendedOpcode(ExtendedOPCodes.CODE_GAMESHOP, json.encode({action = "fetchBase", data = {categories = filteredCategories, url = DONATION_URL}}))

    for category, offersTable in pairs(GAME_SHOP.offers) do
        if isRookgaard then
            if category == "Rookgaard Items" or category == "Premium Time" then
                local offersWithoutDesc = {}
                for _, offer in ipairs(offersTable) do
                    local offerCopy = {}
                    for k, v in pairs(offer) do
                        if k ~= "description" then
                            offerCopy[k] = v
                        end
                    end
                    table.insert(offersWithoutDesc, offerCopy)
                end
                player:sendExtendedOpcode(ExtendedOPCodes.CODE_GAMESHOP, json.encode({action = "fetchOffers", data = {category = category, offers = offersWithoutDesc}}))
            end
        else
            if category ~= "Rookgaard Items" then
                local offersWithoutDesc = {}
                for _, offer in ipairs(offersTable) do
                    local offerCopy = {}
                    for k, v in pairs(offer) do
                        if k ~= "description" then
                            offerCopy[k] = v
                        end
                    end
                    table.insert(offersWithoutDesc, offerCopy)
                end
                player:sendExtendedOpcode(ExtendedOPCodes.CODE_GAMESHOP, json.encode({action = "fetchOffers", data = {category = category, offers = offersWithoutDesc}}))
            end
        end
    end
end

function gameShopUpdatePoints(player)
	if type(player) == "number" then
		player = Player(player)
	end
	
	if not player then
		return
	end

	player:sendExtendedOpcode(ExtendedOPCodes.CODE_GAMESHOP, json.encode({
		action = "points", 
		data = {
			points = getPoints(player), 
			secondPoints = getSecondCurrency(player)
		}
	}))
end

function gameShopUpdatePointsAndRemovePlayer(player)
	if type(player) == "number" then
		player = Player(player)
	end
	
	if not player then
		return
	end

	gameShopUpdatePoints(player)
	
	addEvent(function()
		if player then
			player:remove()
		end
	end, 500)
end

function gameShopChangeName(player, offer)
	local offers = GAME_SHOP.offers[offer.category]
	if not offers then
		return errorMsg(player, "Something went wrong, try again or contact server admin [#1]!")
	end
	
	if not offer.nick then
		return errorMsg(player, "You need to choose a new nickname.")
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

			if player:getName() == offer.nick then
				return errorMsg(player, "Please choose a new nickname different from your previous one")
			end

			local status = callback(player, offer)
			if status ~= true then
				return errorMsg(player, status)
			end

			local aid = player:getAccountId()
			local escapeTitle = db.escapeString(offers[i].title)
			local escapePrice = db.escapeString(-offers[i].price)
			local escapeIsSecondPrice = db.escapeString(-offers[i].isSecondPrice)
			local escapeCount = offers[i].count and db.escapeString(offers[i].count) or 0
			db.query("UPDATE `znote_accounts` set `points` = `points` - " .. offers[i].price .. " WHERE `id` = " .. aid)
			db.asyncQuery("INSERT INTO `shop_history` VALUES (NULL, '" .. aid .. "', '" .. player:getGuid() .. "', NOW(), " .. escapeTitle .. ", " .. escapePrice .. ", " .. escapeIsSecondPrice .. ", " .. escapeCount .. ", NULL)")

			addEvent(updatePlayerShopData, 1000, player:getId())
			return infoMsg(player, "You've bought " .. offers[i].title .. "! Please log out of your account and join us with your new name already set.", true)
		end
	end

	return errorMsg(player, "Something went wrong, try again or contact server admin [#4]!")
end

function gameShopTransferCoins(player, transfer)
	local receiver = transfer.target
	local amount = transfer.amount
	local amountSecond = transfer.amountSecond
	if not receiver then
		return errorMsg(player, "Target player not found!")
	end

	if amount > getPoints(player) then
		return errorMsg(player, "You don't have enough points!")
	end
	
	if SECOND_CURRENCY_ENABLED then
		if amountSecond > getPoints(player) then
			return errorMsg(player, "You don't have enough points!")
		end
	end

	if receiver:lower() == player:getName():lower() then
		return errorMsg(player, "You can't transfer coins to yourself.")
	end

	local accountId = 0
	local GUID = 0
	local resultId = db.storeQuery("SELECT `id`, `account_id` FROM `players` WHERE `name` = " .. db.escapeString(receiver))
	if resultId ~= false then
		accountId = result.getDataInt(resultId, "account_id")
		GUID = result.getDataInt(resultId, "id")
		result.free(resultId)
	end

	if accountId == 0 then
		return errorMsg(player, "Target player not found!")
	end

	if accountId == player:getAccountId() then
		return errorMsg(player, "You can't transfer coins to yourself.")
	end

	local aid = player:getAccountId()
	local title = "Coin Transfer from " .. player:getName() .. " to " .. receiver:sub(1, 1):upper() .. receiver:sub(2, receiver:len()):lower()
	local escapeTitle = db.escapeString(title)
	if amount > 0 then
		db.query("UPDATE `znote_accounts` set `points` = `points` - " .. amount .. " WHERE `id` = " .. aid)
		db.query("UPDATE `znote_accounts` set `points` = `points` + " .. amount .. " WHERE `id` = " .. accountId)
		
		db.asyncQuery("INSERT INTO `shop_history` VALUES (NULL, '" .. aid .. "', '" .. player:getGuid() .. "', NOW(), " .. escapeTitle .. ", " .. db.escapeString(-amount) .. ", 0, 1, " .. db.escapeString(receiver) .. ")")
		db.asyncQuery("INSERT INTO `shop_history` VALUES (NULL, '" .. accountId .. "', '" .. GUID .. "', NOW(), " .. escapeTitle .. ", " .. db.escapeString(amount) .. ", 0, 1, " .. db.escapeString(player:getName()) .. ")")
	end

	if amountSecond > 0 then
		db.query("UPDATE `znote_accounts` set `points_second` = `points_second` - " .. amountSecond .. " WHERE `id` = " .. aid)
		db.query("UPDATE `znote_accounts` set `points_second` = `points_second` + " .. amountSecond .. " WHERE `id` = " .. accountId)
	
		db.asyncQuery("INSERT INTO `shop_history` VALUES (NULL, '" .. aid .. "', '" .. player:getGuid() .. "', NOW(), " .. escapeTitle .. ", " .. db.escapeString(-amountSecond) .. ", 1, 1, " .. db.escapeString(receiver) .. ")")
		db.asyncQuery("INSERT INTO `shop_history` VALUES (NULL, '" .. accountId .. "', '" .. GUID .. "', NOW(), " .. escapeTitle .. ", " .. db.escapeString(amountSecond) .. ", 1, 1, " .. db.escapeString(player:getName()) .. ")")
	end

	addEvent(updatePlayerShopData, 1000, player:getId())
	
	local targetPlayer = Player(receiver)
	if targetPlayer then
		addEvent(updatePlayerShopData, 1000, targetPlayer:getId())
	end
	
	local message = "You've sent "
	if amount > 0 then
		message = message .. amount .. " Tibia coins "
	end

	if amountSecond > 0 then
		message = message .. (amount > 0 and " and " or "") .. amountSecond .. " Task points "
	end

	return infoMsg(player, message .. " to " .. receiver .. "!", true)
end

function getPoints(player)
	local accountId = player:getAccountId()
	
	if pointsCache[accountId] and pointsCache[accountId].time > os.time() - 300 then
		return pointsCache[accountId].points
	end
	
	local points = 0
	local resultId = db.storeQuery("SELECT `points` FROM `znote_accounts` WHERE `id` = " .. accountId)
	if resultId ~= false then
		points = result.getDataInt(resultId, "points")
		result.free(resultId)
		
		pointsCache[accountId] = {
			points = points,
			time = os.time()
		}
	end

	return points
end

function getSecondCurrency(player)
	if not SECOND_CURRENCY_ENABLED then
		return -1
	end

	local accountId = player:getAccountId()
	
	if secondPointsCache[accountId] and secondPointsCache[accountId].time > os.time() - 300 then
		return secondPointsCache[accountId].points
	end
	
	local points = 0
	local resultId = db.storeQuery("SELECT `points_second` FROM `znote_accounts` WHERE `id` = " .. accountId)
	if resultId ~= false then
		points = result.getDataInt(resultId, "points_second")
		result.free(resultId)
		
		secondPointsCache[accountId] = {
			points = points,
			time = os.time()
		}
	end

	return points
end

function errorMsg(player, msg)
	player:sendExtendedOpcode(ExtendedOPCodes.CODE_GAMESHOP, json.encode({action = "msg", data = {type = "error", msg = msg}}))
end

function infoMsg(player, msg, close)
	if not close then
		close = false
	end

	player:sendExtendedOpcode(ExtendedOPCodes.CODE_GAMESHOP, json.encode({action = "msg", data = {type = "info", msg = msg, close = close}}))
end

function refreshPlayersPoints()
	for _, p in ipairs(Game.getPlayers()) do
		if p:getIp() > 0 then
			gameShopUpdatePoints(p)
		end
	end
	addEvent(refreshPlayersPoints, 10 * 1000)
end

function updatePlayerShopData(playerId)
    local player = Player(playerId)
    if player then
        gameShopUpdatePoints(player)
        gameShopUpdateHistory(player)
    end
end

local LogoutEvent = CreatureEvent("GameShopLogout")

function LogoutEvent.onLogout(player)
	local accountId = player:getAccountId()
	pointsCache[accountId] = nil
	secondPointsCache[accountId] = nil
	
	return true
end

LoginEvent:type("login")
LoginEvent:register()

LogoutEvent:type("logout")
LogoutEvent:register()

ExtendedEvent:type("extendedopcode")
ExtendedEvent:register()
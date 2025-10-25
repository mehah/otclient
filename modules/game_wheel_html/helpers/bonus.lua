function setStringColor(t, text, color)
	table.insert(t, text)
	table.insert(t, color)
end

local KNIGHT = 1
local PALADIN = 2
local SORCERER = 3
local DRUID = 4
local MONK = 5

local WheelBonus = {
	[0] = { maxPoints = 200, domain = 1, dedication = "lifemana", conviction = "special_1" },
	[1] = { maxPoints = 150, domain = 1, dedication = "mitigation", conviction = "manaleech" },
	[2] = { maxPoints = 100, domain = 1, dedication = "health", conviction = "vessel", modType = 1 },
	[3] = { maxPoints = 100, domain = 2, dedication = "mana", conviction = "skill" },
	[4] = { maxPoints = 150, domain = 2, dedication = "health", conviction = "vessel", modType = 2 },
	[5] = { maxPoints = 200, domain = 2, dedication = "lifemana", conviction = "spell_1" },
	[6] = { maxPoints = 150, domain = 1, dedication = "mitigation", conviction = "vessel", modType = 2 },
	[7] = { maxPoints = 100, domain = 1, dedication = "health", conviction = "spell_2" },
	[8] = { maxPoints = 75, domain = 1, dedication = "mana", conviction = "lifeleech" },
	[9] = { maxPoints = 75, domain = 2, dedication = "capacity", conviction = "vessel", modType = 0 },
	[10] = { maxPoints = 100, domain = 2, dedication = "mana", conviction = "spell_3" },
	[11] = { maxPoints = 150, domain = 2, dedication = "health", conviction = "manaleech" },
	[12] = { maxPoints = 100, domain = 1, dedication = "health", conviction = "spell_4" },
	[13] = { maxPoints = 75, domain = 1, dedication = "mana", conviction = "skill" },
	[14] = { maxPoints = 50, domain = 1, dedication = "capacity", conviction = "vessel", modType = 0 },
	[15] = { maxPoints = 50, domain = 2, dedication = "mitigation", conviction = "spell_5" },
	[16] = { maxPoints = 75, domain = 2, dedication = "capacity", conviction = "lifeleech" },
	[17] = { maxPoints = 100, domain = 2, dedication = "mana", conviction = "vessel", modType = 1 },
	[18] = { maxPoints = 100, domain = 3, dedication = "mitigation", conviction = "vessel", modType = 1 },
	[19] = { maxPoints = 75, domain = 3, dedication = "health", conviction = "manaleech" },
	[20] = { maxPoints = 50, domain = 3, dedication = "mana", conviction = "spell_1" },
	[21] = { maxPoints = 50, domain = 4, dedication = "health", conviction = "vessel", modType = 0 },
	[22] = { maxPoints = 75, domain = 4, dedication = "mitigation", conviction = "skill" },
	[23] = { maxPoints = 100, domain = 4, dedication = "capacity", conviction = "spell_2" },
	[24] = { maxPoints = 150, domain = 3, dedication = "capacity", conviction = "lifeleech" },
	[25] = { maxPoints = 100, domain = 3, dedication = "mitigation", conviction = "spell_3" },
	[26] = { maxPoints = 75, domain = 3, dedication = "health", conviction = "vessel", modType = 0 },
	[27] = { maxPoints = 75, domain = 4, dedication = "mitigation", conviction = "manaleech" },
	[28] = { maxPoints = 100, domain = 4, dedication = "capacity", conviction = "spell_4" },
	[29] = { maxPoints = 150, domain = 4, dedication = "mana", conviction = "vessel", modType = 2 },
	[30] = { maxPoints = 200, domain = 3, dedication = "lifemana", conviction = "spell_5" },
	[31] = { maxPoints = 150, domain = 3, dedication = "capacity", conviction = "vessel", modType = 2 },
	[32] = { maxPoints = 100, domain = 3, dedication = "mitigation", conviction = "skill" },
	[33] = { maxPoints = 100, domain = 4, dedication = "capacity", conviction = "vessel", modType = 1 },
	[34] = { maxPoints = 150, domain = 4, dedication = "mana", conviction = "lifeleech" },
	[35] = { maxPoints = 200, domain = 4, dedication = "lifemana", conviction = "special_2" },
}

local function configureDedicationPerk(controller)
	local health = 0
	local mana = 0
	local cap = 0
	local mitigation = 0

	local vocation = controller.wheel.vocationId

	for id, bonus in pairs(WheelBonus) do
		local index = id + 1
		if not controller.wheel:isSlotInvested(index) then
			goto label
		end
		local points = controller.wheel.pointInvested[index]
		local attribute = WheelConsts[bonus.dedication]

		if bonus.dedication == "capacity" then
			cap = cap + (points * attribute[vocation])
		elseif bonus.dedication == "mana" then
			mana = mana + (points * attribute[vocation])
		elseif bonus.dedication == "health" then
			health = health + (points * attribute[vocation])
		elseif bonus.dedication == "mitigation" then
			mitigation = mitigation + (points * attribute)
		elseif bonus.dedication == "lifemana" then
			health = health + (points * attribute["life"][vocation])
			mana = mana + (points * attribute["mana"][vocation])
		end

		::label::
	end

	controller.wheel.dedicationPerk.hitpoints = health > 0 and "+ " .. health or "0"
	controller.wheel.dedicationPerk.manapoints = mana > 0 and "+ " .. mana or "0"
	controller.wheel.dedicationPerk.cap = cap > 0 and "+ " .. cap or "0"
	controller.wheel.dedicationPerk.mitigation = string.format("%.2f%%", mitigation)
end

local function getConvictionPerks(controller)
	local convictions = {}

	local vocation = controller.wheel.vocationId
	local order = {
		["special_1"] = 1,
		["special_2"] = 2,
		["special_3"] = 3,
		["special_4"] = 4,
		["skill"] = 5,
		["lifeleech"] = 6,
		["manaleech"] = 7,
		["spell_1"] = 8,
		["spell_2"] = 9,
		["spell_3"] = 10,
		["spell_4"] = 11,
		["spell_5"] = 12,
		["vessel.1"] = 13,
		["vessel.2"] = 14,
		["vessel.3"] = 15,
		["vessel.4"] = 16,
	}

	for id, bonus in pairs(WheelBonus) do
		local index = id + 1
		if not controller.wheel:isSlotInvested(index) then
			goto label
		end

		local t = order[bonus.conviction] or table.size(order) + 1
		local attribute = WheelConsts[bonus.conviction]
		local pointsInvested = controller.wheel.pointInvested[index] or 0

		if pointsInvested ~= bonus.maxPoints then
			goto label
		end

		if bonus.conviction == "special_1" then
			convictions[t] = { perk = attribute[vocation][1], tooltip = attribute[vocation][2] }
		elseif bonus.conviction == "special_2" then
			convictions[t] = { perk = attribute[vocation][1], tooltip = attribute[vocation][2] }
		elseif bonus.conviction == "special_3" then
			if vocation == MONK then
				convictions[t] = { perk = attribute[vocation][1], tooltip = attribute[vocation][2] }
			end
		elseif bonus.conviction == "special_4" then
			if vocation == MONK then
				convictions[t] = { perk = attribute[vocation][1], tooltip = attribute[vocation][2] }
			end
		elseif bonus.conviction == "manaleech" then
			if not convictions[t] then
				convictions[t] = { perk = "Mana Leech", points = 0, stringPoint = "" }
			end
			convictions[t].points = convictions[t].points + attribute
			convictions[t].stringPoint = string.format("+%.2f%%", convictions[t].points)
		elseif bonus.conviction == "lifeleech" then
			if not convictions[t] then
				convictions[t] = { perk = "Life Leech", points = 0, stringPoint = "" }
			end
			convictions[t].points = convictions[t].points + attribute
			convictions[t].stringPoint = string.format("+%.2f%%", convictions[t].points)
		elseif bonus.conviction == "vessel" then
			t = "vessel." .. bonus.domain
			t = order[t]
			if bonus.domain == 1 then
			if not convictions[t] then
					convictions[t] = { perk = "VR Top Left", points = 0, stringPoint = "I" }
			end
			convictions[t].points = convictions[t].points + 1
			if convictions[t].points == 1 then
				convictions[t].stringPoint = "I"
			elseif convictions[t].points == 2 then
				convictions[t].stringPoint = "II"
			else
				convictions[t].stringPoint = "III"
				end
			elseif bonus.domain == 2 then
				if not convictions[t] then
					convictions[t] = { perk = "VR Top Right", points = 0, stringPoint = "I" }
				end
				convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				elseif convictions[t].points == 2 then
					convictions[t].stringPoint = "II"
				else
					convictions[t].stringPoint = "III"
				end
			elseif bonus.domain == 3 then
				if not convictions[t] then
					convictions[t] = { perk = "VR Bottom Left", points = 0, stringPoint = "I" }
				end
				convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				elseif convictions[t].points == 2 then
					convictions[t].stringPoint = "II"
				else
					convictions[t].stringPoint = "III"
				end
			else
				if not convictions[t] then
					convictions[t] = { perk = "VR Bottom Right", points = 0, stringPoint = "I" }
				end
				convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				elseif convictions[t].points == 2 then
					convictions[t].stringPoint = "II"
				else
					convictions[t].stringPoint = "III"
				end
			end
			convictions[t].tooltip =
			"Each level of Vessel Resonance unlocks equivalent Gem Mods in its\ndomain. If the Vessel Resonance matches the gem quality, a\ndamage and healing bonus is granted."
		elseif bonus.conviction == "skill" then
			if not convictions[t] then
				convictions[t] = { perk = "", points = 0, stringPoint = "" }
			end
			if vocation == KNIGHT then
				convictions[t].perk = "Weapon Skill Boost"
				convictions[t].points = convictions[t].points + attribute
				convictions[t].stringPoint = string.format("+%d", convictions[t].points)
				convictions[t].tooltip = "Applies to sword, axe and club fighting"
			elseif vocation == PALADIN then
				convictions[t].perk = "Distance Skill Boost"
				convictions[t].points = convictions[t].points + attribute
				convictions[t].stringPoint = string.format("+%d", convictions[t].points)
			elseif vocation == SORCERER or vocation == DRUID then
				convictions[t].perk = "Magic Skill Boost"
				convictions[t].points = convictions[t].points + attribute
				convictions[t].stringPoint = string.format("+%.2f%%", convictions[t].points)
			elseif vocation == MONK then
				convictions[t].perk = "Fist Fighting Skill Boost"
				convictions[t].points = convictions[t].points + attribute
				convictions[t].stringPoint = string.format("+%d", convictions[t].points)
			end
		elseif bonus.conviction == "spell_1" then
			if vocation == KNIGHT then
			if not convictions[t] then
					convictions[t] = { perk = "Aug. Front Sweep", points = 0, stringPoint = "" }
			end
			convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "Adds 5% life leech to this spell\n", "#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "+8% Base Damage", "#3f3f3f")
				convictions[t].tooltip = message
			elseif vocation == PALADIN then
				if not convictions[t] then
					convictions[t] = { perk = "Aug. Sharpshooter", points = 0, stringPoint = "" }
				end
				convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message,
					"Enables the casting of support spells while active and Focus\nsecondary group cooldown -8s\n",
					"#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "-6s Cooldown; distance skill bonus increased by +5%", "#3F3F3F")
				convictions[t].tooltip = message
			elseif vocation == SORCERER then
				if not convictions[t] then
					convictions[t] = { perk = "Aug. Focus Spells", points = 0, stringPoint = "" }
				end
				convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "+8% Base Damage for Hell's Core and Rage of the Skies\n", "#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message,
					"-4s Cooldown; Focus secondary group cooldown -4s for Hell's\nCore and Rage of the Skies", "#3F3F3F")
				convictions[t].tooltip = message
			elseif vocation == DRUID then
				if not convictions[t] then
					convictions[t] = { perk = "Aug. Strong Ice Wave", points = 0, stringPoint = "" }
				end
				convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "Adds 3% mana leech to this spell\n", "#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "+8% Base Damage", "#3F3F3F")
				convictions[t].tooltip = message
			elseif vocation == MONK then
				if not convictions[t] then
					convictions[t] = { perk = "Aug. Chained Penance", points = 0, stringPoint = "" }
				end
				convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "Adds 3% mana leech to this spell\n", "#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "Adds 25% critical extra damage", "#3F3F3F")
				convictions[t].tooltip = message
			end
		elseif bonus.conviction == "spell_2" then
			if vocation == KNIGHT then
			if not convictions[t] then
					convictions[t] = { perk = "Aug. Groundshaker", points = 0, stringPoint = "" }
			end
			convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "+12.5% Base Damage\n", "#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "-2s Cooldown", "#3F3F3F")
				convictions[t].tooltip = message
			elseif vocation == PALADIN then
				if not convictions[t] then
					convictions[t] = { perk = "Aug. Strong Ethereal Spear", points = 0, stringPoint = "" }
				end
				convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "-2s Cooldown\n", "#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "+8% Base Damage", "#3F3F3F")
				convictions[t].tooltip = message
			elseif vocation == SORCERER then
				if not convictions[t] then
					convictions[t] = { perk = "Aug. Magic Shield", points = 0, stringPoint = "" }
				end
				convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "Enhanced effect\n", "#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "-6s Cooldown", "#3F3F3F")
				convictions[t].tooltip = message
			elseif vocation == DRUID then
				if not convictions[t] then
					convictions[t] = { perk = "Aug. Mass Healing", points = 0, stringPoint = "" }
				end
				convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "+5% Base Healing\n", "#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "Affected area enlarged", "#3F3F3F")
				convictions[t].tooltip = message
			elseif vocation == MONK then
				if not convictions[t] then
					convictions[t] = { perk = "Aug. Mass Spirit Mend", points = 0, stringPoint = "" }
				end
				convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "+8% Base Healing\n", "#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "Affected area enlarged", "#3F3F3F")
				convictions[t].tooltip = message
			end
		elseif bonus.conviction == "spell_3" then
			if vocation == KNIGHT then
			if not convictions[t] then
					convictions[t] = { perk = "Aug. Chivalrous Cha...", points = 0, stringPoint = "" }
			end
			convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "-20 Mana Cost\n", "#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "Jumps to +1 additional target", "#3F3F3F")
				convictions[t].tooltip = message
			elseif vocation == PALADIN then
				if not convictions[t] then
					convictions[t] = { perk = "Aug. Divine Dazzle", points = 0, stringPoint = "" }
				end
				convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "Jumps to +1 additional target\n", "#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "Duration increased; -4s Cooldown", "#3F3F3F")
				convictions[t].tooltip = message
			elseif vocation == SORCERER then
				if not convictions[t] then
					convictions[t] = { perk = "Aug. Sap Strength", points = 0, stringPoint = "" }
				end
				convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "Affected area enlarged\n", "#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "Damage reduction increased", "#3F3F3F")
				convictions[t].tooltip = message
			elseif vocation == DRUID then
				if not convictions[t] then
					convictions[t] = { perk = "Aug. Nature's Embrace", points = 0, stringPoint = "" }
				end
				convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "+11% Base Healing\n", "#3F3F3F")
				setStringColor(message, ": -10s Cooldown", (secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070"))
				convictions[t].tooltip = message
			elseif vocation == MONK then
				if not convictions[t] then
					convictions[t] = { perk = "Aug. Mystic Repulse", points = 0, stringPoint = "" }
				end
				convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "-4s Cooldown\n", "#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "+40% Base Damage", "#3F3F3F")
				convictions[t].tooltip = message
			end
		elseif bonus.conviction == "spell_4" then
			if vocation == KNIGHT then
			if not convictions[t] then
					convictions[t] = { perk = "Aug. Intense Wound C...", points = 0, stringPoint = "" }
			end
			convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "+10% Base Healing\n", "#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "-300s Cooldown", "#3F3F3F")
				convictions[t].tooltip = message
			elseif vocation == PALADIN then
				if not convictions[t] then
					convictions[t] = { perk = "Aug. Swift Foot", points = 0, stringPoint = "" }
				end
				convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message,
					"Focus secondary group cooldown -8s. Attacks and spells are\nenabled but dealt damage is reduced by 50%.\n",
					"#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "-6s Cooldown and the damage dealt is no longer reduced.", "#3F3F3F")
				convictions[t].tooltip = message
			elseif vocation == SORCERER then
				if not convictions[t] then
					convictions[t] = { perk = "Aug. Energy Wave", points = 0, stringPoint = "" }
				end
				convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "+5% Base Damage\n", "#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "Affected area enlarged", "#3F3F3F")
				convictions[t].tooltip = message
			elseif vocation == DRUID then
				if not convictions[t] then
					convictions[t] = { perk = "Aug. Terra Wave", points = 0, stringPoint = "" }
				end
				convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "+5% Base Damage\n", "#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "Adds 5% life leech to this spell", "#3F3F3F")
				convictions[t].tooltip = message
			elseif vocation == MONK then
				if not convictions[t] then
					convictions[t] = { perk = "Aug. Flurry of Blows", points = 0, stringPoint = "" }
				end
				convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "Adds 5% life leech to this spell", "#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "+15% Base Damage", "#3F3F3F")
				convictions[t].tooltip = message
			end
		elseif bonus.conviction == "spell_5" then
			if vocation == KNIGHT then
			if not convictions[t] then
					convictions[t] = { perk = "Aug. Fierce Berserk", points = 0, stringPoint = "" }
			end
			convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "-30 Mana Cost\n", "#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "+10% Base Damage", "#3F3F3F")
				convictions[t].tooltip = message
			elseif vocation == PALADIN then
				if not convictions[t] then
					convictions[t] = { perk = "Aug. Divine Caldera", points = 0, stringPoint = "" }
				end
				convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "-20 Mana Cost\n", "#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "+8.5% Base Damage", "#3F3F3F")
				convictions[t].tooltip = message
			elseif vocation == SORCERER then
				if not convictions[t] then
					convictions[t] = { perk = "Aug. Great Fire Wave", points = 0, stringPoint = "" }
				end
				convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message,
					"Adds 15% critical extra damage for this spell and grants a 10%\nchance (non-cumulative) for a critical hit.\n",
					"#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "+5% Base Damage", "#3F3F3F")
				convictions[t].tooltip = message
			elseif vocation == DRUID then
				if not convictions[t] then
					convictions[t] = { perk = "Aug. Heal Friend", points = 0, stringPoint = "" }
				end
				convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "-10 Mana Cost\n", "#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "+5% Base Healing", "#3F3F3F")
				convictions[t].tooltip = message
			elseif vocation == MONK then
				if not convictions[t] then
					convictions[t] = { perk = "Aug. Sweeping Takedown", points = 0, stringPoint = "" }
				end
				convictions[t].points = convictions[t].points + 1
				if convictions[t].points == 1 then
					convictions[t].stringPoint = "I"
				else
					convictions[t].stringPoint = "II"
				end
				local message = {}
				if not firstSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message, "Adds 3% mana leech to this spell\n", "#3F3F3F")
				if not secondSpellIsUnlocked(attribute) then
					-- setStringColor(message, "�", "white")
				else
					-- setStringColor(message, "�", "white")
				end
				setStringColor(message,
					"Adds 25% critical extra damage for this spell and grants a 10% chance (non-cumulative) for a critical hit.",
					"#3F3F3F")
				convictions[t].tooltip = message
			end
		end

		::label::
	end

	local parsedConvictions = {}

	for _, data in pairs(convictions) do
		table.insert(parsedConvictions, {
			perk = data.perk,
			stringPoint = data.stringPoint,
			tooltip = data.tooltip,
		})
	end

	return parsedConvictions, convictions
end

local function getStage(points)
	if points >= 1000 then
		return "Stage 3"
	elseif points >= 500 then
		return "Stage 2"
	elseif points >= 250 then
		return "Stage 1"
	else
		return "Locked"
	end
end

local function configureRevelationPerks(controller)
	-- damage and healing
	local damage = 0
	for domain, points in ipairs(controller.wheel.passivePoints) do
		local extraPoints = controller.wheel.extraPassivePoints[domain] or 0
		points = points + extraPoints

		if points >= 1000 then
			damage = damage + 20
		elseif points >= 500 then
			damage = damage + 9
		elseif points >= 250 then
			damage = damage + 4
		end
	end



	local data = {
		damage = {
			name = "Damage and Healing",
			text = damage > 0 and ("+ " .. damage) or "Locked",
			tooltip = "",
		},
		avatar = {
			name = "Avatar Of Nature",
			text = "Locked",
			tooltip = "",
			message = ""
		},
		spellTR = {
			name = "Blessing of the Gr...",
			text = "Locked",
			tooltip = "Blessing of the Grave",
			message = "",
		},
		spellBL = {
			name = "Blessing of the Gr...",
			text = "Locked",
			tooltip = "Blessing of the Grave",
			message = "",
		},
		giftOfLife = {
			name = "Gift of Life",
			text = "Locked",
			tooltip = "Blessing of the Grave",
			message = "",
		}
	}

	data.damage.tooltip =
	"Unlocked Revelation Perks grant a bonus to all damage and \nhealing:\n* Stage 1 grants a bonus of +4 damage and healing\n* Stage 2 increases this bonus to +9\n* Stage 3 increases this bonus to +20"

	data.giftOfLife.message, data.giftOfLife.tooltip = getPassiveInfo(1)
	local passive = (controller.wheel.passivePoints[1] or 0)
	local extraPoints = controller.wheel.extraPassivePoints[1] or 0
	passive = passive + extraPoints
	data.giftOfLife.text = getStage(passive)

	local vocation = WheelController.wheel.vocationId
	if vocation == KNIGHT then
		data.avatar.name = "Avatar of Steel"
		data.spellTR.name = "Executioner's Throw"
		data.spellTR.tooltip = "Executioner's Throw"
		data.spellBL.name = "Combat Mastery"
		data.spellBL.tooltip = "Combat Mastery"
	elseif vocation == PALADIN then
		data.avatar.name = "Avatar of Light"
		data.spellTR.name = "Divine Grenade"
		data.spellTR.tooltip = "Divine Grenade"
		data.spellBL.name = "Divine Empowerment"
		data.spellBL.tooltip = "Divine Empowerment"
	elseif vocation == SORCERER then
		data.avatar.name = "Avatar of Storm"
		data.spellTR.name = "Beam Mastery"
		data.spellTR.tooltip = "Beam Mastery"
		data.spellBL.name = "Drain Body"
		data.spellBL.tooltip = "Drain Body"
	elseif vocation == DRUID then
		data.avatar.name = "Avatar of Nature"
		data.spellTR.name = "Blessing of the Gr..."
		data.spellTR.tooltip = "Blessing of the Grave"
		data.spellBL.name = "Twin Bursts"
		data.spellBL.tooltip = "Twin Bursts"
	elseif vocation == MONK then
		data.avatar.name = "Avatar of Balance"
		data.spellTR.name = "Spiritual Outburst"
		data.spellTR.tooltip = "Spiritual Outburst"
		data.spellBL.name = "Ascetic"
		data.spellBL.tooltip = "Ascetic"
	end

	data.spellTR.message, data.spellTR.tooltip = getPassiveInfo(2)
	passive = controller.wheel.passivePoints[2] or 0
	extraPoints = controller.wheel.extraPassivePoints[2] or 0
	passive = passive + extraPoints
	data.spellTR.text = getStage(passive)

	data.spellBL.message, data.spellBL.tooltip = getPassiveInfo(3)
	passive = controller.wheel.passivePoints[3] or 0
	extraPoints = controller.wheel.extraPassivePoints[3] or 0
	passive = passive + extraPoints
	data.spellBL.text = getStage(passive)

	data.avatar.message, data.avatar.tooltip = getPassiveInfo(4)
	passive = WheelController.wheel.passivePoints[4] or 0
	extraPoints = WheelController.wheel.extraPassivePoints[4] or 0
	passive = passive + extraPoints
	data.avatar.text = getStage(passive)

	controller.wheel.revelationPerks = data
end

local bonus = {
	WheelBonus = WheelBonus,
	configureDedicationPerk = configureDedicationPerk,
	getConvictionPerks = getConvictionPerks,
	configureRevelationPerks = configureRevelationPerks,
}

return bonus

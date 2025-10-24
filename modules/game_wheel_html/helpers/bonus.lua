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

local KNIGHT = 1
local PALADIN = 2
local SORCERER = 3
local DRUID = 4
local MONK = 5

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
			-- keep points and roman numerals (I/II/III)
			t = order["vessel." .. bonus.domain]
			if not convictions[t] then
				local perkName =
					(bonus.domain == 1 and "VR Top Left") or
					(bonus.domain == 2 and "VR Top Right") or
					(bonus.domain == 3 and "VR Bottom Left") or
					"VR Bottom Right"
				convictions[t] = { perk = perkName, points = 0, stringPoint = "I" }
			end
			convictions[t].points = convictions[t].points + 1
			if convictions[t].points == 1 then
				convictions[t].stringPoint = "I"
			elseif convictions[t].points == 2 then
				convictions[t].stringPoint = "II"
			else
				convictions[t].stringPoint = "III"
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
			if not convictions[t] then
				convictions[t] = { perk = "", points = 0, stringPoint = "" }
			end
			convictions[t].points = convictions[t].points + 1
			convictions[t].stringPoint = (convictions[t].points == 1) and "I" or "II"
			if vocation == KNIGHT then
				convictions[t].perk = "Aug. Front Sweep"
				convictions[t].tooltip = "Adds 5% life leech to this spell\n\n+8% Base Damage"
			elseif vocation == PALADIN then
				convictions[t].perk = "Aug. Sharpshooter"
				convictions[t].tooltip =
				"Enables the casting of support spells while active and Focus secondary group cooldown -8s\n\n-6s Cooldown; distance skill bonus increased by +5%"
			elseif vocation == SORCERER then
				convictions[t].perk = "Aug. Focus Spells"
				convictions[t].tooltip =
				"+8% Base Damage for Hell's Core and Rage of the Skies\n\n-4s Cooldown; Focus secondary group cooldown -4s for Hell's\nCore and Rage of the Skies"
			elseif vocation == DRUID then
				convictions[t].perk = "Aug. Strong Ice Wave"
				convictions[t].tooltip = "Adds 3% mana leech to this spell\n\n+8% Base Damage"
			elseif vocation == MONK then
				convictions[t].perk = "Aug. Chained Penance"
				convictions[t].tooltip = "Adds 3% mana leech to this spell\n\nAdds 25% critical extra damage"
			end
		elseif bonus.conviction == "spell_2" then
			if not convictions[t] then
				convictions[t] = { perk = "", points = 0, stringPoint = "" }
			end
			convictions[t].points = convictions[t].points + 1
			convictions[t].stringPoint = (convictions[t].points == 1) and "I" or "II"
			if vocation == KNIGHT then
				convictions[t].perk = "Aug. Groundshaker"
				convictions[t].tooltip = "+12.5% Base Damage\n\n-2s Cooldown"
			elseif vocation == PALADIN then
				convictions[t].perk = "Aug. Strong Ethereal Spear"
				convictions[t].tooltip = "-2s Cooldown\n\n+8% Base Damage"
			elseif vocation == SORCERER then
				convictions[t].perk = "Aug. Magic Shield"
				convictions[t].tooltip = "Enhanced effect\n\n-6s Cooldown"
			elseif vocation == DRUID then
				convictions[t].perk = "Aug. Mass Healing"
				convictions[t].tooltip = "+5% Base Healing\n\n+5% Base Healing\n\nAffected area enlarged"
			elseif vocation == MONK then
				convictions[t].perk = "Aug. Mass Spirit Mend"
				convictions[t].tooltip = "+8% Base Healing\n\nAffected area enlarged"
			end
		elseif bonus.conviction == "spell_3" then
			if not convictions[t] then
				convictions[t] = { perk = "", points = 0, stringPoint = "" }
			end
			convictions[t].points = convictions[t].points + 1
			convictions[t].stringPoint = (convictions[t].points == 1) and "I" or "II"
			if vocation == KNIGHT then
				convictions[t].perk = "Aug. Chivalrous Cha..."
				convictions[t].tooltip = "-20 Mana Cost\n\nJumps to +1 additional target"
			elseif vocation == PALADIN then
				convictions[t].perk = "Aug. Divine Dazzle"
				convictions[t].tooltip = "Jumps to +1 additional target\n\nDuration increased; -4s Cooldown"
			elseif vocation == SORCERER then
				convictions[t].perk = "Aug. Sap Strength"
				convictions[t].tooltip = "Affected area enlarged\n\nDamage reduction increased"
			elseif vocation == DRUID then
				convictions[t].perk = "Aug. Nature's Embrace"
				convictions[t].tooltip = "+11% Base Healing\n\n-10s Cooldown"
			elseif vocation == MONK then
				convictions[t].perk = "Aug. Mystic Repulse"
				convictions[t].tooltip = "-4s Cooldown\n\n+40% Base Damage"
			end
		elseif bonus.conviction == "spell_4" then
			if not convictions[t] then
				convictions[t] = { perk = "", points = 0, stringPoint = "" }
			end
			convictions[t].points = convictions[t].points + 1
			convictions[t].stringPoint = (convictions[t].points == 1) and "I" or "II"
			if vocation == KNIGHT then
				convictions[t].perk = "Aug. Intense Wound C..."
				convictions[t].tooltip = "+10% Base Healing\n\n-300s Cooldown"
			elseif vocation == PALADIN then
				convictions[t].perk = "Aug. Swift Foot"
				convictions[t].tooltip =
				"Focus secondary group cooldown -8s. Attacks and spells are enabled but dealt damage is reduced by 50%.\n\n-6s Cooldown and the damage dealt is no longer reduced."
			elseif vocation == SORCERER then
				convictions[t].perk = "Aug. Energy Wave"
				convictions[t].tooltip = "+5% Base Damage\n\nAffected area enlarged"
			elseif vocation == DRUID then
				convictions[t].perk = "Aug. Terra Wave"
				convictions[t].tooltip = "+5% Base Damage\n\nAdds 5% life leech to this spell"
			elseif vocation == MONK then
				convictions[t].perk = "Aug. Flurry of Blows"
				convictions[t].tooltip = "Adds 5% life leech to this spell\n\n+15% Base Damage"
			end
		elseif bonus.conviction == "spell_5" then
			if not convictions[t] then
				convictions[t] = { perk = "", points = 0, stringPoint = "" }
			end
			convictions[t].points = convictions[t].points + 1
			convictions[t].stringPoint = (convictions[t].points == 1) and "I" or "II"
			if vocation == KNIGHT then
				convictions[t].perk = "Aug. Fierce Berserk"
				convictions[t].tooltip = "-30 Mana Cost\n\n+10% Base Damage"
			elseif vocation == PALADIN then
				convictions[t].perk = "Aug. Divine Caldera"
				convictions[t].tooltip = "-20 Mana Cost\n\n+8.5% Base Damage"
			elseif vocation == SORCERER then
				convictions[t].perk = "Aug. Great Fire Wave"
				convictions[t].tooltip =
				"Adds 15% critical extra damage for this spell and grants a 10%\nchance (non-cumulative) for a critical hit.\n\n+5% Base Damage"
			elseif vocation == DRUID then
				convictions[t].perk = "Aug. Heal Friend"
				convictions[t].tooltip = "-10 Mana Cost\n\n+5% Base Healing"
			elseif vocation == MONK then
				convictions[t].perk = "Aug. Sweeping Takedown"
				convictions[t].tooltip =
				"Adds 3% mana leech to this spell\nAdds 25% critical extra damage for this spell and grants a 10% chance (non-cumulative) for a critical hit."
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

	return parsedConvictions
end

local bonus = {
	WheelBonus = WheelBonus,
	configureDedicationPerk = configureDedicationPerk,
	getConvictionPerks = getConvictionPerks,
}

return bonus

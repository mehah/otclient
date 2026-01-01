if not ProficiencyData then
	ProficiencyData = {}
	ProficiencyData.__index = ProficiencyData

	ProficiencyData.content = {}
end

function ProficiencyData:loadProficiencyJson()
	self.content = {}

    local file = "/json/proficiencies.json"
	if not g_resources.fileExists(file) then
		g_logger.error("Hunt config file not found: " .. file)
		return
    end

	local status, result = pcall(function()
		return json.decode(g_resources.readFileContents(file))
	end)

	if not status then
		return g_logger.error("Error while reading characterdata file. Details: " .. result)
	end

	for i, data in pairs(result) do
		local ProficiencyId = data["ProficiencyId"]
		self.content[ProficiencyId] = data
	end
	WeaponProficiency:createItemCache()
end

function ProficiencyData:isValidProfiencyId(id)
	return self.content[id] ~= nil
end

function ProficiencyData:getContentById(id)
	local content = self.content[id]
	return content and content or nil
end

function ProficiencyData:getPerkLaneCount(id)
	local content = self.content[id]
	if not content then
		return 0
	end

	return table.size(content.Levels)
end

function ProficiencyData:formatFloatValue(value, roundFloat, perkType)
	local function isPercentageType(perkType)
		for _, v in ipairs(PercentageTypes) do
			if v == perkType then
				return true
			end
		end
		return false
	end

	local isInteger = math.floor(value) == value
	if not isInteger or (isInteger and isPercentageType(perkType)) then
		local percentage = value * 100
		if roundFloat then
			local intPart = math.floor(percentage)
			local decimal1 = math.floor(percentage * 10 + 0.5) / 10
			if percentage == intPart then
				return tostring(intPart)
			elseif percentage == decimal1 then
				return string.format("%.1f", percentage)
			else
				return string.format("%.2f", percentage)
			end
		else
			return string.format("%.2f", percentage)
		end
	else
		return tostring(value)
	end
end

function ProficiencyData:getImageSourceAndClip(perkData)
	local perkType = perkData.Type
	local data = PerkVisualData[perkType]
	local source = (data and data.source) or "icons-0"
	local imagePath = string.format("/images/game/proficiency/%s", source)

	if not data then
		return imagePath, "0 0"
	end

	if perkType == PERK_SPELL_AUGMENT then
		local spellData = SpellAugmentIcons[perkData.SpellId]
		return imagePath, spellData.imageOffset 
	end

	if perkType == PERK_BESTIARY_DAMAGE then
		local bestiaryType = BestiaryCategories[perkData.BestiaryName]
		return imagePath, bestiaryType.imageOffset or "0 0"
	end

	if perkType == PERK_MAGIC_BONUS then
		local elementData = MagicBoostMask[perkData.DamageType]
		return imagePath, elementData and elementData.imageOffset or "0 0"
	end

	if ElementalCritical_t[perkType] then
		local elementData = ElementalMask[perkData.ElementId]
		return imagePath, elementData.imageOffset or "0 0"
	end

	if FlatDamageBonus_t[perkType] then
		local skillData = SkillTypes[perkData.SkillId]
		return imagePath, skillData and skillData.imageOffset or "0 0"
	end

	return imagePath, data.offset or "0 0"
end

function ProficiencyData:getBonusNameAndTooltip(perkData)
	local perkType = perkData.Type
	local data = PerkTextData[perkType]
	local value = self:formatFloatValue(perkData.Value, false, perkType)
	local bonusName = data and data.name or "Empty"

	if not data then
		return bonusName, "Empty"
	end

	if perkType == PERK_SPELL_AUGMENT then
		local spellData = SpellAugmentIcons[perkData.SpellId]
		local augmentData = AugmentPerkIcons[perkData.AugmentType]

		value = self:formatFloatValue(perkData.Value, true, perkType)
		if perkData.AugmentType == AUGMENT_COOLDOWN then
			value = value / 100
		end

		local description = string.format(augmentData.desc, value, spellData.name)
		return bonusName, description
	end

	if perkType == PERK_BESTIARY_DAMAGE then
		local description = string.format(data.desc, value, perkData.BestiaryName)
		return bonusName, description
	end

	if perkType == PERK_MAGIC_BONUS then
		local elementData = MagicBoostMask[perkData.DamageType]
		local description = string.format(data.desc, value, elementData.name)
		return bonusName, description
	end

	if perkType == PERK_PERFECT_SHOT then
		local description = string.format(data.desc, value, perkData.Range)
		return bonusName, description
	end

	if ElementalCritical_t[perkType] then
		local elementData = ElementalMask[perkData.ElementId]
		local description = string.format(data.desc, value, elementData.name)
		return bonusName, description
	end

	if FlatDamageBonus_t[perkType] then
		local skillData = SkillTypes[perkData.SkillId]
		local description = string.format(data.desc, value, skillData.name)
		return bonusName, description
	end
	return bonusName, string.format(data.desc, value)
end

function ProficiencyData:getAugmentIconClip(perkData)
	local augmentData = AugmentPerkIcons[perkData.AugmentType]
	if not augmentData then
		g_logger.warning(string.format("Missing augmentId %d data", perkData.AugmentType))
		return "0 0"
	end
	return augmentData.imageOffset
end

function ProficiencyData:getCurrentCeilExperience(exp, displayItem)
	local best = nil
	local vocation = self:getWeaponProfessionType(displayItem)
	local lastExp = nil
	local limitIndex = self:getPerkLaneCount(displayItem:getProficiencyId()) + 2

	for index, stage in ipairs(ExperienceTable) do
		if index > limitIndex then
			break
		end

		local stageExp = stage[vocation]
		if stageExp then
			if stageExp > exp then
				if not best or stageExp < best then
					best = stageExp
				end
			end
			lastExp = stageExp
		end
	end
	return best or lastExp
end

function ProficiencyData:getMaxExperience(perkCount, displayItem)
	local vocation = self:getWeaponProfessionType(displayItem)
	local lastLevel = ExperienceTable[perkCount + 2]
	return lastLevel[vocation] or 0
end

function ProficiencyData:getLevelPercent(currentExperience, level, displayItem)
	local vocation = self:getWeaponProfessionType(displayItem)
	local prevLevel = math.max(level - 1, 0)
	local xpMin = prevLevel == 0 and 0 or ExperienceTable[prevLevel][vocation]
	local xpMax = ExperienceTable[level][vocation] or xpMin + 1

	local progress = math.max(0, math.min(1, (currentExperience - xpMin) / (xpMax - xpMin)))
	return math.floor(progress * 100)
end

function ProficiencyData:getTotalPercent(currentExperience, perkCount, displayItem)
	local vocation = self:getWeaponProfessionType(displayItem)
	local maxExperience = ExperienceTable[perkCount + 2][vocation] or 1
	local progress = math.max(0, math.min(1, currentExperience / maxExperience))
	return math.floor(progress * 100)
end

function ProficiencyData:getMaxExperienceByLevel(level, displayItem)
	local vocation = self:getWeaponProfessionType(displayItem)
	return ExperienceTable[level][vocation] or 0
end

function ProficiencyData:getCurrentLevelByExp(displayItem, currentExperience, includeMastery)
	local vocation = self:getWeaponProfessionType(displayItem)
	local currentLevel = 0

	for level, data in pairs(ExperienceTable) do
		local requiredExp = data[vocation]
		if requiredExp and currentExperience >= requiredExp then
			if level > currentLevel then
				currentLevel = level
			end
		end
	end

	local level = math.min(7, currentLevel)
	if includeMastery then
		level = currentLevel
	end

	return level
end

function ProficiencyData:getWeaponProfessionType(displayItem)
	local marketData = displayItem:getMarketData()

	if marketData.restrictVocation == 1 then
		return "knight"
	end

	if displayItem:getWeaponType() == WEAPON_CROSSBOW then
		return "crossbow"
	end
	return "regular"
end

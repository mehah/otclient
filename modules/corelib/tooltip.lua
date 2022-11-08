function newTooltip(data)
  local _itemUId = data.uid
  local _itemName = data.itemName
  local _itemDesc = data.desc
  local _itemId = data.clientId
  local _itemLevel = data.itemLevel or 0
  local _imp = data.imp
  local _unidentified = data.unidentified
  local _mirrored = data.mirrored
  local _upgradeLevel = data.uLevel or 0
  local _uniqueName = data.uniqueName
  local _itemRarity = data.rarityId or 0
  local _itemMaxAttributes = data.maxAttr or 0
  local _itemAttributes = data.attr
  local _requiredLevel = data.reqLvl or 0

  if _itemRarity ~= 0 then
    for i = _itemMaxAttributes, 1, -1 do
      _itemAttributes[i] = _itemAttributes[i]:gsub("%%%%", "%%")
    end
  end
  local _isStackable = data.stackable
  local _itemType = data.itemType
  local _firstStat = data.armor or data.attack or 0
  local _secondStat = data.hitChance or data.defense or 0
  local _thirdStat = data.shootRange or data.extraDefense or 0
  local _weight = data.weight
  return json.encode({
    name = _itemName,
    desc = _itemDesc,
    iLvl = _itemLevel,
    imp = _imp,
    unidentified = _unidentified,
    mirrored = _mirrored,
    uLvl = _upgradeLevel,
    uniqueName = _uniqueName,
    rarity = _itemRarity,
    maxAttributes = _itemMaxAttributes,
    attributes = _itemAttributes,
    stackable = _isStackable,
    type = _itemType,
    first = _firstStat,
    second = _secondStat,
    third = _thirdStat,
    weight = _weight,
    reqLvl = _requiredLevel,
    itemId = _itemId
  })
end
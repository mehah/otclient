local inventoryWidget = nil

local itemTooltip = {
    window = nil,
    sprite = nil,
    weightLabel = nil,
    labels = nil
}
local compareTooltip = {
    window = nil,
    sprite = nil,
    weightLabel = nil,
    labels = nil
}

local BASE_WIDTH = 110
local BASE_HEIGHT = 0

local tooltipWidth = 0
local tooltipWidthBase = BASE_WIDTH
local tooltipHeight = BASE_HEIGHT
local longestString = 0

local Colors = {
  Default = "#ffffff",
  ItemLevel = "#abface",
  Description = "#8080ff",
  Implicit = "#ffbb22",
  Attribute = "#2266ff",
  Mirrored = "#22ffbb"
}

local rarityColor = {
  {name = "", color = "#ffffff"},
  {name = "Common", color = "#7b7b7b"},
  --{name = "Rare", color = "#1258a2"},
  {name = "Rare", color = "#25fc19"},
  {name = "Epic", color = "#bd3ffa"},
  {name = "Legendary", color = "#ff7605"},
  {name = "Mythic", color = "#FF0000"}
}

local implicits = {
  ["ca"] = "Critical Damage",
  ["cc"] = "Critical Chance",
  ["la"] = "Life Leech",
  ["lc"] = "Life Leech Chance",
  ["ma"] = "Mana Leech",
  ["mc"] = "Mana Leech Chance",
  ["speed"] = "Movement Speed",
  ["fist"] = "Fist Fighting",
  ["sword"] = "Sword Fighting",
  ["club"] = "Club Fighting",
  ["axe"] = "Axe Fighting",
  ["dist"] = "Distance Fighting",
  ["shield"] = "Shielding",
  ["fish"] = "Fishing",
  ["mag"] = "Magic Level",
  ["a_phys"] = "Physical Protection",
  ["a_ene"] = "Energy Protection",
  ["a_earth"] = "Earth Protection",
  ["a_fire"] = "Fire Protection",
  ["a_ldrain"] = "Lifedrain Protection",
  ["a_mdrain"] = "Manadrain Protection",
  ["a_heal"] = "Healing Protection",
  ["a_drown"] = "Drown Protection",
  ["a_ice"] = "Ice Protection",
  ["a_holy"] = "Holy Protection",
  ["a_death"] = "Death Protection",
  ["a_all"] = "Protection All",
  ["strength"] = "Strength",
  ["agility"] = "Agility",
  ["intellect"] = "Intellect"
}

local impPercent = {
  ["ca"] = true,
  ["cc"] = true,
  ["la"] = true,
  ["lc"] = true,
  ["ma"] = true,
  ["mc"] = true,
  ["a_phys"] = true,
  ["a_ene"] = true,
  ["a_earth"] = true,
  ["a_fire"] = true,
  ["a_ldrain"] = true,
  ["a_mdrain"] = true,
  ["a_heal"] = true,
  ["a_drown"] = true,
  ["a_ice"] = true,
  ["a_holy"] = true,
  ["a_death"] = true,
  ["a_all"] = true
}

function init()
  connect(UIItem, {onHoverChange = onHoverChange})
  connect(g_game, {onGameEnd = resetData})

  itemTooltip.window = g_ui.displayUI("item_tooltip")
  itemTooltip.window:hide()

  compareTooltip.window = g_ui.displayUI("item_tooltip")
  compareTooltip.window:hide()

  itemTooltip.labels = itemTooltip.window:getChildById("labels")
  itemTooltip.weightLabel = itemTooltip.window:getChildById("itemWeightLabel")
  itemTooltip.sprite = itemTooltip.window:getChildById("itemSprite")

  compareTooltip.labels =  compareTooltip.window:getChildById("labels")
  compareTooltip.weightLabel =  compareTooltip.window:getChildById("itemWeightLabel")
  compareTooltip.sprite =  compareTooltip.window:getChildById("itemSprite")

  local rootWidget = g_ui.getRootWidget()
  inventoryWidget = rootWidget:recursiveGetChildById("inventoryWindow")
  rootWidget = nil
end

function terminate()
  disconnect(UIItem, {onHoverChange = onHoverChange})
  disconnect(g_game, {onGameEnd = resetData})

  if itemTooltip.window then
    itemTooltip.weightLabel = nil
    itemTooltip.sprite = nil
    itemTooltip.labels = nil
    itemTooltip.window:destroy()
    itemTooltip.window = nil
  end

  if compareTooltip.window then
    compareTooltip.weightLabel = nil
    compareTooltip.sprite = nil
    compareTooltip.labels = nil
    compareTooltip.window:destroy()
    compareTooltip.window = nil
  end

  inventoryWidget = nil;
end

function resetData()
  itemTooltip.window:hide()
  compareTooltip.window:hide()
end

function onHoverChange(widget, hovered)
  local item = widget:getItem()

  if not item or widget:getId() == "containerItemWidget" or widget:isVirtual() then
    return
  end

  if item and widget:getData() ~= '' then
    if hovered then
      buildItemTooltip(json.decode(widget:getData()), itemTooltip)
    else
      itemTooltip.window:hide()
      compareTooltip.window:hide()
    end
    return
  end


end

function buildItemTooltip(item, tooltip)
  tooltipWidth = 0
  longestString = 0
  tooltipWidthBase = BASE_WIDTH
  tooltipHeight = BASE_HEIGHT
  tooltip.window:setWidth(tooltipWidth)
  tooltip.window:setHeight(tooltipHeight)

  tooltip.labels:destroyChildren()
  local id = item.itemId
  local name = item.name
  local desc = item.desc
  local iLvl = item.iLvl
  local reqLvl = item.reqLvl or 0
  local unidentified = item.unidentified
  local mirrored = item.mirrored
  local rarity = item.rarity + 1
  local maxAttributes = item.maxAttributes
  local attributes = item.attributes
  local count = item.count
  local type = item.type
  local first = item.first
  local second = item.second
  local third = item.third
  local weight = item.weight


  --Check type to compare TODO: To be done when ItemTypes are reworked.
  --    if inventoryWidget and tooltip == itemTooltip then
  --      local weaponWidget = inventoryWidget:recursiveGetChildById("slot6")
  --      if weaponWidget and weaponWidget:getData() ~= '' and json.decode(weaponWidget:getData()) ~= item then
  --          buildItemTooltip(json.decode(weaponWidget:getData()) , compareTooltip)
  --     end
  --  end

  tooltip.weightLabel:setText(formatWeight(weight))

  tooltip.sprite:setItemId(id)
  tooltip.sprite:setItemCount(count)

  local itemNameColor
  if unidentified then
    itemNameColor = rarityColor[2].color
  elseif item.uniqueName then
    itemNameColor = "#dca01e"
  elseif rarity > 1 then
    itemNameColor = rarityColor[rarity].color
  else
    itemNameColor = "#ffffff"
  end

  name =
  name:gsub(
  "(%a)(%a+)",
  function(a, b)
    return string.upper(a) .. string.lower(b)
  end
  )
  if item.uLvl > 0 then
    name = name .. " +" .. item.uLvl
  end

  if unidentified then
    addString("Unidentified" .. " " .. name, rarityColor[2].color, false, tooltip)
  else
    if item.uniqueName then
      addString(item.uniqueName .. " " .. name, "#dca01e", false, tooltip)
    elseif item.rarity ~= 0 then
      addString(rarityColor[rarity].name .. " " .. name, rarityColor[rarity].color, false, tooltip)
    else
      addString(name, itemNameColor, false, tooltip)
    end
  end
  --addString(name, itemNameColor)

  if iLvl > 0 then
    addString("Item Level " .. iLvl, Colors.ItemLevel, false, tooltip)
  end

  local firstText, secondText, thirdText
  if (type == "Armor" or type == "Helmet" or type == "Legs" or type == "Ring" or type == "Necklace" or type == "Boots") and first ~= 0 then
    firstText = "Armor: " .. first
  elseif
    type == "Two-Handed Sword" or type == "Two-Handed Club" or type == "Two-Handed Axe" or type == "Sword" or type == "Club" or type == "Axe" or type == "Fist" or
      type == "Distance" or
      type == "Ammunition"
   then
    firstText = "Attack: " .. first
  elseif type == "Shield" then
    firstText = "Defense: " .. second
  end

  if type == "Two-Handed Sword" or type == "Two-Handed Club" or type == "Two-Handed Axe" or type == "Sword" or type == "Club" or type == "Axe" or type == "Fist" then
    secondText = "Defense: " .. second
  elseif type == "Distance" then
    secondText = "Hit Chance: +" .. second .. "%"
  end

  if type == "Two-Handed Sword" or type == "Two-Handed Club" or type == "Two-Handed Axe" or type == "Sword" or type == "Club" or type == "Axe" or type == "Fist" then
    thirdText = "Extra-Defense: " .. third
  elseif type == "Distance" then
    thirdText = "Shoot Range: " .. third
  end

  if reqLvl > 0 then
      addString("Required Level " .. reqLvl, Colors.ItemLevel, false, tooltip)
  end

  if (firstText and (type == "Shield" or type == "Ring" or type == "Necklace")) or (first ~= 0 and second == 0 and third == 0) then
    addSeparator(tooltip)
    addEmpty(5,tooltip)
    addString(firstText, Colors.Default, false, tooltip)
  elseif first ~= 0 and second ~= 0 and third == 0 then
    addSeparator(tooltip)
    addEmpty(5,tooltip)
    addString(firstText, Colors.Default, false, tooltip)
    addString(secondText, Colors.Default, false, tooltip)
  elseif first ~= 0 and second ~= 0 and third ~= 0 or type == "Distance" then
    addSeparator(tooltip)
    addEmpty(5,tooltip)
    addString(firstText, Colors.Default, false, tooltip)
    addString(secondText, Colors.Default, false, tooltip)
    addString(thirdText, Colors.Default, false, tooltip)
  end

  if item.imp then
    if first ~= 0 or second ~= 0 or third ~= 0 or item.rarity ~= 0 then
      addSeparator(tooltip)
      addEmpty(5,tooltip)
    end

    for key, value in pairs(item.imp) do
      if key ~= "hpticks" and key ~= "mpticks" then
        local impText
        if key == "hpgain" then
          impText = "+" .. value .. " health per " .. item.imp.hpticks / 1000 .. " second" .. (item.imp.hpticks > 1000 and "s" or "")
        elseif key == "mpgain" then
          impText = "+" .. value .. " mana per " .. item.imp.mpticks / 1000 .. " second" .. (item.imp.mpticks > 1000 and "s" or "")
        else
          if not implicits[key] then
            impText = value
          else
            impText = implicits[key] .. " " .. (value > 0 and "+" or "") .. value .. (impPercent[key] and "%" or "")
          end
        end
        addString(impText, Colors.Value, false, tooltip)
      end
    end
  end

  if item.rarity ~= 0 then
    addSeparator(tooltip)
    addEmpty(5,tooltip)
    for i = 1, maxAttributes do
      addString(attributes[i], Colors.Attribute, false, tooltip)
    end
  end

  if mirrored then
    addEmpty(5,tooltip)
    addString("Mirrored", Colors.Mirrored, false, tooltip)
  end

  if desc and desc:len() > 0 then
    addEmpty(5,tooltip)
    addString(desc, Colors.Description, true, tooltip)
  end

  shrinkSeparators(tooltip)
  showItemTooltip(tooltip)
end

function addString(text, color, resize, tooltip)
  local label = g_ui.createWidget("TooltipLabel", tooltip.labels)
  label:setColor(color)

  if resize then
    tooltip.window:setWidth(tooltipWidth)
    label:setTextWrap(true)
    label:setTextAutoResize(true)
    label:setText(text)
    tooltipHeight = tooltipHeight + label:getTextSize().height + 4
  else
    label:setText(text)
    local textSize = label:getTextSize()
    if longestString == 0 then
      longestString = textSize.width + tooltip.weightLabel:getWidth()
      tooltipWidth = tooltipWidthBase + longestString
      label:addAnchor(AnchorTop, "parent", AnchorTop)
    elseif textSize.width > longestString then
      longestString = textSize.width
      tooltipWidth = tooltipWidthBase + longestString
    end
    tooltipHeight = tooltipHeight + textSize.height
  end
end

function shrinkSeparators(tooltip)
  local children = tooltip.labels:getChildren()
  local m = math.max(60, math.floor(tooltipWidth / 4))
  for _, child in ipairs(children) do
    if child:getStyleName() == "TooltipSeparator" then
      child:setMarginLeft(m)
      child:setMarginRight(m)
    end
  end
end

function addSeparator(tooltip)
  local sep = g_ui.createWidget("TooltipSeparator", tooltip.labels)
  tooltipHeight = tooltipHeight + sep:getHeight() + sep:getMarginTop() + sep:getMarginBottom()
end

function addEmpty(height, tooltip)
  local empty = g_ui.createWidget("TooltipEmpty", tooltip.labels)
  empty:setHeight(height)
  tooltipHeight = tooltipHeight + height
end

function showItemTooltip(tooltip)
  local mousePos = g_window.getMousePosition()
  tooltipHeight = math.max(tooltipHeight, 40)
  tooltip.window:setWidth(tooltipWidth)
  tooltip.window:setHeight(tooltipHeight)
  
  local windowSize = g_window.getSize()
  if mousePos.x > windowSize.width / 2 then
    if tooltip == itemTooltip then
        tooltip.window:move(mousePos.x - (tooltipWidth + 2), math.min(windowSize.height - tooltipHeight, mousePos.y + 5))
    else
        tooltip.window:move(mousePos.x - (tooltipWidth*2 + 25), math.min(windowSize.height - tooltipHeight, mousePos.y + 5))
    end
  else
    if tooltip == itemTooltip then
        tooltip.window:move(mousePos.x + 5 , mousePos.y + 10)
    else
        tooltip.window:move(mousePos.x + tooltipWidth + 10, mousePos.y + 10)
    end
  end
  tooltip.window:raise()
  tooltip.window:show()
  g_effects.fadeIn(tooltip.window, 100)
end

function formatWeight(weight)
  local ss

  if weight < 10 then
    ss = "0.0" .. weight
  elseif weight < 100 then
    ss = "0." .. weight
  else
    local weightString = tostring(weight)
    local len = weightString:len()
    ss = weightString:sub(1, len - 2) .. "." .. weightString:sub(len - 1, len)
  end

  ss = ss .. " oz."
  return ss
end

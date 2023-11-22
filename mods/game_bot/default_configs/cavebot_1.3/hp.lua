setDefaultTab("HP")

--2x healing spell
--2x healing rune
--utani hur
--mana shield
--anti paralyze
--4x equip

UI.Label("Healing spells")

if type(storage.healing1) ~= "table" then
  storage.healing1 = {on=false, title="HP%", text="exura", min=51, max=90}
end
if type(storage.healing2) ~= "table" then
  storage.healing2 = {on=false, title="HP%", text="exura vita", min=0, max=50}
end

-- create 2 healing widgets
for _, healingInfo in ipairs({storage.healing1, storage.healing2}) do
  local healingmacro = macro(20, function()
    local hp = player:getHealthPercent()
    if healingInfo.max >= hp and hp >= healingInfo.min then
      if TargetBot then 
        TargetBot.saySpell(healingInfo.text) -- sync spell with targetbot if available
      else
        say(healingInfo.text)
      end
    end
  end)
  healingmacro.setOn(healingInfo.on)

  UI.DualScrollPanel(healingInfo, function(widget, newParams) 
    healingInfo = newParams
    healingmacro.setOn(healingInfo.on)
  end)
end

UI.Separator()

UI.Label("Mana & health potions/runes")

if type(storage.hpitem1) ~= "table" then
  storage.hpitem1 = {on=false, title="HP%", item=266, min=51, max=90}
end
if type(storage.hpitem2) ~= "table" then
  storage.hpitem2 = {on=false, title="HP%", item=3160, min=0, max=50}
end
if type(storage.manaitem1) ~= "table" then
  storage.manaitem1 = {on=false, title="MP%", item=268, min=51, max=90}
end
if type(storage.manaitem2) ~= "table" then
  storage.manaitem2 = {on=false, title="MP%", item=3157, min=0, max=50}
end

for i, healingInfo in ipairs({storage.hpitem1, storage.hpitem2, storage.manaitem1, storage.manaitem2}) do
  local healingmacro = macro(20, function()
    local hp = i <= 2 and player:getHealthPercent() or math.min(100, math.floor(100 * (player:getMana() / player:getMaxMana())))
    if healingInfo.max >= hp and hp >= healingInfo.min then
      if TargetBot then 
        TargetBot.useItem(healingInfo.item, healingInfo.subType, player) -- sync spell with targetbot if available
      else
        local thing = g_things.getThingType(healingInfo.item)
        local subType = g_game.getClientVersion() >= 860 and 0 or 1
        if thing and thing:isFluidContainer() then
          subType = healingInfo.subType
        end
        g_game.useInventoryItemWith(healingInfo.item, player, subType)
      end
    end
  end)
  healingmacro.setOn(healingInfo.on)

  UI.DualScrollItemPanel(healingInfo, function(widget, newParams) 
    healingInfo = newParams
    healingmacro.setOn(healingInfo.on and healingInfo.item > 100)
  end)
end

if g_game.getClientVersion() < 780 then
  UI.Label("In old tibia potions & runes work only when you have backpack with them opened")
end

UI.Separator()

UI.Label("Mana shield spell:")
UI.TextEdit(storage.manaShield or "utamo vita", function(widget, newText)
  storage.manaShield = newText
end)

local lastManaShield = 0
macro(20, "mana shield", function() 
  if hasManaShield() or lastManaShield + 90000 > now then return end
  if TargetBot then 
    TargetBot.saySpell(storage.manaShield) -- sync spell with targetbot if available
  else
    say(storage.manaShield)
  end
end)

UI.Label("Haste spell:")
UI.TextEdit(storage.hasteSpell or "utani hur", function(widget, newText)
  storage.hasteSpell = newText
end)

macro(500, "haste", function() 
  if hasHaste() then return end
  if TargetBot then 
    TargetBot.saySpell(storage.hasteSpell) -- sync spell with targetbot if available
  else
    say(storage.hasteSpell)
  end
end)

UI.Label("Anti paralyze spell:")
UI.TextEdit(storage.antiParalyze or "utani hur", function(widget, newText)
  storage.antiParalyze = newText
end)

macro(100, "anti paralyze", function() 
  if not isParalyzed() then return end
  if TargetBot then 
    TargetBot.saySpell(storage.antiParalyze) -- sync spell with targetbot if available
  else
    say(storage.antiParalyze)
  end
end)

UI.Separator()

UI.Label("Eatable items:")
if type(storage.foodItems) ~= "table" then
  storage.foodItems = {3582, 3577}
end

local foodContainer = UI.Container(function(widget, items)
  storage.foodItems = items
end, true)
foodContainer:setHeight(35)
foodContainer:setItems(storage.foodItems)

macro(10000, "eat food", function()
  if not storage.foodItems[1] then return end
  -- search for food in containers
  for _, container in pairs(g_game.getContainers()) do
    for __, item in ipairs(container:getItems()) do
      for i, foodItem in ipairs(storage.foodItems) do
        if item:getId() == foodItem.id then
          return g_game.use(item)
        end
      end
    end
  end
  -- can't find any food, try to eat random item using hotkey
  if g_game.getClientVersion() < 780 then return end -- hotkey's dont work on old tibia
  local toEat = storage.foodItems[math.random(1, #storage.foodItems)]
  if toEat then g_game.useInventoryItem(toEat.id) end
end)

UI.Separator()
UI.Label("Auto equip")

if type(storage.autoEquip) ~= "table" then
  storage.autoEquip = {}
end
for i=1,4 do -- if you want more auto equip panels you can change 4 to higher value
  if not storage.autoEquip[i] then
    storage.autoEquip[i] = {on=false, title="Auto Equip", item1=i == 1 and 3052 or 0, item2=i == 1 and 3089 or 0, slot=i == 1 and 9 or 0}
  end
  UI.TwoItemsAndSlotPanel(storage.autoEquip[i], function(widget, newParams)
    storage.autoEquip[i] = newParams
  end)
end
macro(250, function()
  local containers = g_game.getContainers()
  for index, autoEquip in ipairs(storage.autoEquip) do
    if autoEquip.on then
      local slotItem = getSlot(autoEquip.slot)
      if not slotItem or (slotItem:getId() ~= autoEquip.item1 and slotItem:getId() ~= autoEquip.item2) then
        for _, container in pairs(containers) do
          for __, item in ipairs(container:getItems()) do
            if item:getId() == autoEquip.item1 or item:getId() == autoEquip.item2 then
              g_game.move(item, {x=65535, y=autoEquip.slot, z=0}, item:getCount())
              delay(1000) -- don't call it too often      
              return
            end
          end
        end
      end
    end
  end
end)
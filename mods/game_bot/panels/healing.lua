local context = G.botContext
local Panels = context.Panels

Panels.Haste = function(parent)
  context.macro(500, "Auto Haste", nil, function()
    if not context.hasHaste() and context.storage.autoHasteText:len() > 0 then
      if context.saySpell(context.storage.autoHasteText, 2500) then
        context.delay(5000)
      end
    end
  end, parent)
  context.addTextEdit("autoHasteText", context.storage.autoHasteText or "utani hur", function(widget, text)    
    context.storage.autoHasteText = text
  end, parent)
end

Panels.ManaShield = function(parent)
  local lastManaShield = 0
  context.macro(100, "Auto Mana Shield", nil, function()
    if not context.hasManaShield() or context.now > lastManaShield + 90000 then
      if context.saySpell("utamo vita", 200) then
        lastManaShield = context.now
      end
    end
  end, parent)
end

Panels.AntiParalyze = function(parent)
  context.macro(100, "Anti Paralyze", nil, function()
    if context.isParalyzed() and context.storage.autoAntiParalyzeText:len() > 0 then
      context.saySpell(context.storage.autoAntiParalyzeText, 750)
    end
  end, parent)
  context.addTextEdit("autoAntiParalyzeText", context.storage.autoAntiParalyzeText or "utani hur", function(widget, text)    
    context.storage.autoAntiParalyzeText = text
  end, parent)
end


Panels.Health = function(parent)
  if not parent then
    parent = context.panel
  end
  
  local panelName = "autoHealthPanel"
  local panelId = 1
  while parent:getChildById(panelName .. panelId) do
    panelId = panelId + 1
  end
  panelName = panelName .. panelId
  
  local ui = g_ui.createWidget("DualScrollPanel", parent)
  ui:setId(panelName)
  
  if not context.storage[panelName] then
    context.storage[panelName] = {
      item = 266,
      min = 20,
      max = 80,
      text = "exura"
    }
  end

  ui.title:setOn(context.storage[panelName].enabled)
  ui.title.onClick = function(widget)
    context.storage[panelName].enabled = not context.storage[panelName].enabled
    widget:setOn(context.storage[panelName].enabled)
  end

  ui.text.onTextChange = function(widget, text)
    context.storage[panelName].text = text    
  end
  ui.text:setText(context.storage[panelName].text or "exura")
  
  local updateText = function()
    ui.title:setText("" .. context.storage[panelName].min .. "% <= hp <= " .. context.storage[panelName].max .. "%")  
  end
  
  ui.scroll1.onValueChange = function(scroll, value)
    context.storage[panelName].min = value
    updateText()
  end
  ui.scroll2.onValueChange = function(scroll, value)
    context.storage[panelName].max = value
    updateText()
  end

  ui.scroll1:setValue(context.storage[panelName].min)
  ui.scroll2:setValue(context.storage[panelName].max)
  
  context.macro(25, function()
    if context.storage[panelName].enabled and context.storage[panelName].text:len() > 0 and context.storage[panelName].min <= context.hppercent() and context.hppercent() <= context.storage[panelName].max then
      if context.saySpell(context.storage[panelName].text, 500) then
        context.delay(200)
      end
    end
  end)
end

Panels.HealthItem = function(parent)
  if not parent then
    parent = context.panel
  end
  
  local panelName = "autoHealthItemPanel"
  local panelId = 1
  while parent:getChildById(panelName .. panelId) do
    panelId = panelId + 1
  end
  panelName = panelName .. panelId
  
  local ui = g_ui.createWidget("DualScrollItemPanel", parent)
  ui:setId(panelName)
  
  if not context.storage[panelName] then
    context.storage[panelName] = {
      item = 266,
      min = 0,
      max = 60
    }
  end

  ui.title:setOn(context.storage[panelName].enabled)
  ui.title.onClick = function(widget)
    context.storage[panelName].enabled = not context.storage[panelName].enabled
    widget:setOn(context.storage[panelName].enabled)
  end

  ui.item.onItemChange = function(widget)
    context.storage[panelName].item = widget:getItemId()
  end
  ui.item:setItemId(context.storage[panelName].item)
  
  local updateText = function()
    ui.title:setText("" .. (context.storage[panelName].min or "") .. "% <= hp <= " .. (context.storage[panelName].max or "") .. "%")  
  end
  
  ui.scroll1.onValueChange = function(scroll, value)
    context.storage[panelName].min = value
    updateText()
  end
  ui.scroll2.onValueChange = function(scroll, value)
    context.storage[panelName].max = value
    updateText()
  end

  ui.scroll1:setValue(context.storage[panelName].min)
  ui.scroll2:setValue(context.storage[panelName].max)
  
  context.macro(25, function()
    if context.storage[panelName].enabled and context.storage[panelName].item >= 100 and context.storage[panelName].min <= context.hppercent() and context.hppercent() <= context.storage[panelName].max then
      if context.useRune(context.storage[panelName].item, context.player, 500) then
        context.delay(300)
      end
    end
  end)
end

Panels.Mana = function(parent)
  if not parent then
    parent = context.panel
  end
  
  local panelName = "autoManaItemPanel"
  local panelId = 1
  while parent:getChildById(panelName .. panelId) do
    panelId = panelId + 1
  end
  panelName = panelName .. panelId
  
  local ui = g_ui.createWidget("DualScrollItemPanel", parent)
  ui:setId(panelName)
  
  if not context.storage[panelName] then
    context.storage[panelName] = {
      item = 268,
      min = 0,
      max = 60
    }
  end

  ui.title:setOn(context.storage[panelName].enabled)
  ui.title.onClick = function(widget)
    context.storage[panelName].enabled = not context.storage[panelName].enabled
    widget:setOn(context.storage[panelName].enabled)
  end

  ui.item.onItemChange = function(widget)
    context.storage[panelName].item = widget:getItemId()
  end
  ui.item:setItemId(context.storage[panelName].item)
  
  local updateText = function()
    ui.title:setText("" .. (context.storage[panelName].min or "") .. "% <= mana <= " .. (context.storage[panelName].max or "") .. "%")  
  end
  
  ui.scroll1.onValueChange = function(scroll, value)
    context.storage[panelName].min = value
    updateText()
  end
  ui.scroll2.onValueChange = function(scroll, value)
    context.storage[panelName].max = value
    updateText()
  end

  ui.scroll1:setValue(context.storage[panelName].min)
  ui.scroll2:setValue(context.storage[panelName].max)
  
  context.macro(25, function()
    if context.storage[panelName].enabled and context.storage[panelName].item >= 100 and context.storage[panelName].min <= context.manapercent() and context.manapercent() <= context.storage[panelName].max then
      if context.useRune(context.storage[panelName].item, context.player, 500) then
        context.delay(300)
      end
    end
  end)
end
Panels.ManaItem = Panels.Mana

Panels.Equip = function(parent)
  if not parent then
    parent = context.panel
  end
  
  local panelName = "autoEquipItem"
  local panelId = 1
  while parent:getChildById(panelName .. panelId) do
    panelId = panelId + 1
  end
  panelName = panelName .. panelId
  
  local ui = g_ui.createWidget("TwoItemsAndSlotPanel", parent)
  ui:setId(panelName)
  
  if not context.storage[panelName] then
    context.storage[panelName] = {}
    if panelId == 1 then
      context.storage[panelName].item1 = 3052
      context.storage[panelName].item2 = 3089
      context.storage[panelName].slot = 9
    end
  end
  
  ui.title:setText("Auto equip")
  ui.title:setOn(context.storage[panelName].enabled)
  ui.title.onClick = function(widget)
    context.storage[panelName].enabled = not context.storage[panelName].enabled
    widget:setOn(context.storage[panelName].enabled)
  end
  
  ui.item1:setItemId(context.storage[panelName].item1 or 0)
  ui.item1.onItemChange = function(widget)
    context.storage[panelName].item1 = widget:getItemId()
  end
  
  ui.item2:setItemId(context.storage[panelName].item2 or 0)
  ui.item2.onItemChange = function(widget)
    context.storage[panelName].item2 = widget:getItemId()
  end
  
  if not context.storage[panelName].slot then
    context.storage[panelName].slot = 1
  end
  ui.slot:setCurrentIndex(context.storage[panelName].slot)
  ui.slot.onOptionChange = function(widget)
    context.storage[panelName].slot = widget.currentIndex
  end
  
  context.macro(250, function()
    if context.storage[panelName].enabled and context.storage[panelName].slot > 0 then
      local item1 = context.storage[panelName].item1 or 0
      local item2 = context.storage[panelName].item2 or 0
      if item1 < 100 and item2 < 100 then
        return
      end
      local slotItem = context.getSlot(context.storage[panelName].slot)
      if slotItem and (slotItem:getId() == item1 or slotItem:getId() == item2) then
        return
      end
      local newItem = context.findItem(context.storage[panelName].item1)
      if not newItem then
        newItem = context.findItem(context.storage[panelName].item2)
        if not newItem then
          return
        end
      end
      g_game.move(newItem, {x=65535, y=context.storage[panelName].slot, z=0})
      context.delay(1000)
    end
  end)
end
Panels.AutoEquip = Panels.Equip

Panels.Eating = function(parent)
  if not parent then
    parent = context.panel
  end
  
  local panelName = "autoEatingPanel"
  local panelId = 1
  while parent:getChildById(panelName .. panelId) do
    panelId = panelId + 1
  end
  panelName = panelName .. panelId
  
  local ui = g_ui.createWidget("ItemsPanel", parent)
  ui:setId(panelName)

  if not context.storage[panelName] then
    context.storage[panelName] = {}
  end

  ui.title:setText("Auto eating")
  ui.title:setOn(context.storage[panelName].enabled)
  ui.title.onClick = function(widget)
    context.storage[panelName].enabled = not context.storage[panelName].enabled
    widget:setOn(context.storage[panelName].enabled)
  end
  
  if type(context.storage[panelName].items) ~= 'table' then
    context.storage[panelName].items = {3725, 0, 0, 0, 0}
  end

  for i=1,5 do
    ui.items:getChildByIndex(i).onItemChange = function(widget)
      context.storage[panelName].items[i] = widget:getItemId()
    end
    ui.items:getChildByIndex(i):setItemId(context.storage[panelName].items[i])    
  end
  
  context.macro(15000, function()    
    if not context.storage[panelName].enabled then
      return
    end
    local candidates = {}
    for i, item in pairs(context.storage[panelName].items) do
      if item >= 100 then
        table.insert(candidates, item)
      end
    end
    if #candidates == 0 then
      return
    end    
    context.use(candidates[math.random(1, #candidates)])
  end)
end


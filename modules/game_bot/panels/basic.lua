local context = G.botContext
local Panels = context.Panels

Panels.Turning = function(parent)
  context.macro(1000, "Turning / AntiIdle", nil, function()
    context.turn(math.random(1, 4))
  end, parent)
end
Panels.AntiIdle = Panels.Turning

Panels.AttackSpell = function(parent)
  context.macro(500, "Auto attack spell", nil, function()
    local target = g_game.getAttackingCreature()
    if target and context.getCreatureById(target:getId()) and context.storage.autoAttackText:len() > 0 then
      if context.saySpell(context.storage.autoAttackText, 1000) then
        context.delay(1000)
      end
    end
  end, parent)
  context.addTextEdit("autoAttackText", context.storage.autoAttackText or "exori vis", function(widget, text)    
    context.storage.autoAttackText = text
  end, parent)
end

Panels.AttackItem = function(parent)
  if not parent then
    parent = context.panel
  end
  
  local panelName = "attackItem"
  local ui = g_ui.createWidget("ItemAndButtonPanel", parent)
  ui:setId(panelName)
  
  ui.title:setText("Auto attack item")
  
  if not context.storage.attackItem then
    context.storage.attackItem = {}
  end
  
  ui.title:setOn(context.storage.attackItem.enabled)
  ui.title.onClick = function(widget)
    context.storage.attackItem.enabled = not context.storage.attackItem.enabled
    widget:setOn(context.storage.attackItem.enabled)
  end
  
  ui.item.onItemChange = function(widget)
    context.storage.attackItem.item = widget:getItemId()
  end
  ui.item:setItemId(context.storage.attackItem.item or 3155)

  context.macro(500, function()
    local target = g_game.getAttackingCreature()
    if context.storage.attackItem.enabled and target and context.getCreatureById(target:getId()) and context.storage.attackItem.item and context.storage.attackItem.item >= 100 then
      context.useWith(context.storage.attackItem.item, target)
    end
  end)
end

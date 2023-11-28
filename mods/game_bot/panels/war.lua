local context = G.botContext
local Panels = context.Panels

Panels.AttackLeaderTarget = function(parent)
  local toAttack = nil
  context.onMissle(function(missle)
    if not context.storage.attackLeader or context.storage.attackLeader:len() == 0 then
      return
    end
    local src = missle:getSource()
    if src.z ~= context.posz() then
      return
    end
    local from = g_map.getTile(src)
    local to = g_map.getTile(missle:getDestination())
    if not from or not to then
      return
    end
    local fromCreatures = from:getCreatures()
    local toCreatures = to:getCreatures()
    if #fromCreatures ~= 1 or #toCreatures ~= 1 then
      return
    end
    local c1 = fromCreatures[1]
    if c1:getName():lower() == context.storage.attackLeader:lower() then
      toAttack = toCreatures[1]
    end
  end)
  context.macro(50, "Attack leader's target", nil, function()
    if toAttack and context.storage.attackLeader:len() > 0 and toAttack ~= g_game.getAttackingCreature() then    
      g_game.attack(toAttack)
      toAttack = nil
    end
  end, parent)
  context.addTextEdit("attackLeader", context.storage.attackLeader or "player name", function(widget, text)    
    context.storage.attackLeader = text
  end, parent)  
end


Panels.LimitFloor = function(parent)  
  context.onPlayerPositionChange(function(pos)
    if context.storage.limitFloor then
      local gameMapPanel = modules.game_interface.getMapPanel()
      if gameMapPanel then
        gameMapPanel:lockVisibleFloor(pos.z)
      end
    end
  end)

  local switch = context.addSwitch("limitFloor", "Don't show higher floors", function(widget)
    widget:setOn(not widget:isOn())
    context.storage.limitFloor = widget:isOn()
    local gameMapPanel = modules.game_interface.getMapPanel()
    if gameMapPanel then
      if context.storage.limitFloor then
        gameMapPanel:lockVisibleFloor(context.posz())
      else
        gameMapPanel:unlockVisibleFloor()      
      end
    end
  end, parent)
  switch:setOn(context.storage.limitFloor)
end

Panels.AntiPush = function(parent)
  if not parent then
    parent = context.panel
  end
  
  local panelName = "antiPushPanel"  
  local ui = g_ui.createWidget("ItemsPanel", parent)
  ui:setId(panelName)

  if not context.storage[panelName] then
    context.storage[panelName] = {}
  end

  ui.title:setText("Anti push")
  ui.title:setOn(context.storage[panelName].enabled)
  ui.title.onClick = function(widget)
    context.storage[panelName].enabled = not context.storage[panelName].enabled
    widget:setOn(context.storage[panelName].enabled)
  end
  
  if type(context.storage[panelName].items) ~= 'table' then
    context.storage[panelName].items = {3031, 3035, 0, 0, 0}
  end

  for i=1,5 do
    ui.items:getChildByIndex(i).onItemChange = function(widget)
      context.storage[panelName].items[i] = widget:getItemId()
    end
    ui.items:getChildByIndex(i):setItemId(context.storage[panelName].items[i])    
  end
  
  context.macro(100, function()    
    if not context.storage[panelName].enabled then
      return
    end
    local tile = g_map.getTile(context.player:getPosition())
    if not tile then
      return
    end
    local topItem = tile:getTopUseThing()
    if topItem and topItem:isStackable() then
      topItem = topItem:getId()
    else
      topItem = 0    
    end
    local candidates = {}
    for i, item in pairs(context.storage[panelName].items) do
      if item >= 100 and item ~= topItem and context.findItem(item) then
        table.insert(candidates, item)
      end
    end
    if #candidates == 0 then
      return
    end
    if type(context.storage[panelName].lastItem) ~= 'number' or context.storage[panelName].lastItem > #candidates then
      context.storage[panelName].lastItem = 1
    end
    local item = context.findItem(candidates[context.storage[panelName].lastItem])
    g_game.move(item, context.player:getPosition(), 1)
    context.storage[panelName].lastItem = context.storage[panelName].lastItem + 1
  end)
end

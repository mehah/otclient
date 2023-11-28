local context = G.botContext

-- callback(callbackType, callback)
context.callback = function(callbackType, callback)
  if not context._callbacks[callbackType] then
    return error("Wrong callback type: " .. callbackType)
  end
  if callbackType == "onAddThing" or callbackType == "onRemoveThing" then
    g_game.enableTileThingLuaCallback(true)
  end

  local desc = "lua"
  local info = debug.getinfo(2, "Sl")
  if info then
    desc = info.short_src .. ":" .. info.currentline
  end
  
  local callbackData = {}
  table.insert(context._callbacks[callbackType], function(...)
    if not callbackData.delay or callbackData.delay < context.now then
      local prevExecution = context._currentExecution
      context._currentExecution = callbackData       
      local start = g_clock.realMillis()
      callback(...)
      local executionTime = g_clock.realMillis() - start
      if executionTime > 100 then
        context.warning("Slow " .. callbackType .. " (" .. executionTime .. "ms): " .. desc)
      end
      context._currentExecution = prevExecution
    end
  end)
  local cb = context._callbacks[callbackType]
  return {
    remove = function()
      local index = nil
      for i, cb2 in ipairs(context._callbacks[callbackType]) do
        if cb == cb2 then
          index = i
        end
      end
      if index then
        table.remove(context._callbacks[callbackType], index)
      end
    end
  }
end

-- onKeyDown(callback) -- callback = function(keys)
context.onKeyDown = function(callback) 
  return context.callback("onKeyDown", callback)
end

-- onKeyPress(callback) -- callback = function(keys)
context.onKeyPress = function(callback) 
  return context.callback("onKeyPress", callback)
end

-- onKeyUp(callback) -- callback = function(keys)
context.onKeyUp = function(callback) 
  return context.callback("onKeyUp", callback)
end

-- onTalk(callback) -- callback = function(name, level, mode, text, channelId, pos)
context.onTalk = function(callback) 
  return context.callback("onTalk", callback)
end

-- onTextMessage(callback) -- callback = function(mode, text)
context.onTextMessage = function(callback) 
  return context.callback("onTextMessage", callback)
end

-- onLoginAdvice(callback) -- callback = function(message)
context.onLoginAdvice = function(callback) 
  return context.callback("onLoginAdvice", callback)
end

-- onAddThing(callback) -- callback = function(tile, thing)
context.onAddThing = function(callback) 
  return context.callback("onAddThing", callback)
end

-- onRemoveThing(callback) -- callback = function(tile, thing)
context.onRemoveThing = function(callback) 
  return context.callback("onRemoveThing", callback)
end

-- onCreatureAppear(callback) -- callback = function(creature)
context.onCreatureAppear = function(callback)
  return context.callback("onCreatureAppear", callback)
end

-- onCreatureDisappear(callback) -- callback = function(creature)
context.onCreatureDisappear = function(callback)
  return context.callback("onCreatureDisappear", callback)
end

-- onCreaturePositionChange(callback) -- callback = function(creature, newPos, oldPos)
context.onCreaturePositionChange = function(callback)
  return context.callback("onCreaturePositionChange", callback)
end

-- onCreatureHealthPercentChange(callback) -- callback = function(creature, healthPercent)
context.onCreatureHealthPercentChange = function(callback)
  return context.callback("onCreatureHealthPercentChange", callback)
end

-- onUse(callback) -- callback = function(pos, itemId, stackPos, subType)
context.onUse = function(callback)
  return context.callback("onUse", callback)
end

-- onUseWith(callback) -- callback = function(pos, itemId, target, subType)
context.onUseWith = function(callback)
  return context.callback("onUseWith", callback)
end

-- onContainerOpen -- callback = function(container, previousContainer)
context.onContainerOpen = function(callback)
  return context.callback("onContainerOpen", callback)
end

-- onContainerClose -- callback = function(container)
context.onContainerClose = function(callback)
  return context.callback("onContainerClose", callback)
end

-- onContainerUpdateItem -- callback = function(container, slot, item, oldItem)
context.onContainerUpdateItem = function(callback)
  return context.callback("onContainerUpdateItem", callback)
end

-- onMissle -- callback = function(missle)
context.onMissle = function(callback)
  return context.callback("onMissle", callback)
end

-- onAnimatedText -- callback = function(thing, text)
context.onAnimatedText = function(callback)
  return context.callback("onAnimatedText", callback)
end

-- onStaticText -- callback = function(thing, text)
context.onStaticText = function(callback)
  return context.callback("onStaticText", callback)
end

-- onChannelList -- callback = function(channels)
context.onChannelList = function(callback)
  return context.callback("onChannelList", callback)
end

-- onOpenChannel -- callback = function(channelId, name)
context.onOpenChannel = function(callback)
  return context.callback("onOpenChannel", callback)
end

-- onCloseChannel -- callback = function(channelId)
context.onCloseChannel = function(callback)
  return context.callback("onCloseChannel", callback)
end

-- onChannelEvent -- callback = function(channelId, name, event)
context.onChannelEvent = function(callback)
  return context.callback("onChannelEvent", callback)
end

-- onTurn -- callback = function(creature, direction)
context.onTurn = function(callback)
  return context.callback("onTurn", callback)
end

-- onWalk -- callback = function(creature, oldPos, newPos)
context.onWalk = function(callback)
  return context.callback("onWalk", callback)
end

-- onImbuementWindow -- callback = function(itemId, slots, activeSlots, imbuements, needItems)
context.onImbuementWindow = function(callback)
  return context.callback("onImbuementWindow", callback)
end

-- onModalDialog -- callback = function(id, title, message, buttons, enterButton, escapeButton, choices, priority) -- priority is unused, ignore it
context.onModalDialog = function(callback)
  return context.callback("onModalDialog", callback)
end

-- onAttackingCreatureChange -- callback = function(creature, oldCreature)
context.onAttackingCreatureChange = function(callback)
  return context.callback("onAttackingCreatureChange", callback)
end

-- onManaChange -- callback = function(player, mana, maxMana, oldMana, oldMaxMana)
context.onManaChange = function(callback)
  return context.callback("onManaChange", callback)
end

-- onAddItem - callback = function(container, slot, item, oldItem)
context.onAddItem = function(callback)
  return context.callback("onAddItem", callback)
end

-- onRemoveItem - callback = function(container, slot, item)
context.onRemoveItem = function(callback)
  return context.callback("onRemoveItem", callback)
end

-- onStatesChange - callback = function(player, states, oldStates)
context.onStatesChange = function(callback)
  return context.callback("onStatesChange", callback)
end

-- onGameEditText - callback = function(id, itemId, maxLength, text, writer, time)
context.onGameEditText = function(callback)
  return context.callback("onGameEditText", callback)
end

-- onSpellCooldown - callback = function(iconId, duration)
context.onSpellCooldown = function(callback)
  return context.callback("onSpellCooldown", callback)
end

-- onGroupSpellCooldown - callback = function(iconId, duration)
context.onGroupSpellCooldown = function(callback)
  return context.callback("onGroupSpellCooldown", callback)
end

-- onInventoryChange - callback = function(player, slot, item, oldItem)
context.onInventoryChange = function(callback)
  return context.callback("onInventoryChange", callback)
end

-- CUSTOM CALLBACKS

-- listen(name, callback) -- callback = function(text, channelId, pos)
context.listen = function(name, callback)
  if not name then return context.error("listen: invalid name") end
  name = name:lower()
  return context.onTalk(function(name2, level, mode, text, channelId, pos)
    if name == name2:lower() then
      callback(text, channelId, pos)
    end
  end)
end

-- onPlayerPositionChange(callback) -- callback = function(newPos, oldPos)
context.onPlayerPositionChange = function(callback)
  return context.onCreaturePositionChange(function(creature, newPos, oldPos)
    if creature == context.player then
      callback(newPos, oldPos)
    end
  end)
end

-- onPlayerHealthChange(callback) -- callback = function(healthPercent)
context.onPlayerHealthChange = function(callback)
  return context.onCreatureHealthPercentChange(function(creature, healthPercent)
    if creature == context.player then
      callback(healthPercent)
    end
  end)
end

-- onPlayerInventoryChange -- callback = function(slot, item, oldItem)
context.onPlayerInventoryChange = function(callback)
  return context.onInventoryChange(function(player, slot, item, oldItem)
    if player == context.player then
      callback(slot, item, oldItem)
    end
  end)
end
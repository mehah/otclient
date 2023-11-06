local minimap = modules.game_minimap.minimapWidget

minimap.onMouseRelease = function(widget,pos,button)
  if not minimap.allowNextRelease then return true end
  minimap.allowNextRelease = false

  local mapPos = minimap:getTilePosition(pos)
  if not mapPos then return end

  if button == 1 then
    local player = g_game.getLocalPlayer()
    if minimap.autowalk then
      player:autoWalk(mapPos)
    end
    return true
  elseif button == 2 then
    local menu = g_ui.createWidget('PopupMenu')
    menu:setId("minimapMenu")
    menu:setGameMenu(true)
    menu:addOption(tr('Create mark'), function() minimap:createFlagWindow(mapPos) end)
    menu:addOption(tr('Add CaveBot GoTo'), function() CaveBot.addAction("goto", mapPos.x .. "," .. mapPos.y .. "," .. mapPos.z, true) CaveBot.save() end)
    menu:display(pos)
    return true
  end
  return false
end
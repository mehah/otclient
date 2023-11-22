TargetBot.Creature.calculatePriority = function(creature, config, path)
  -- config is based on creature_editor
  local priority = 0

  -- extra priority if it's current target
  if g_game.getAttackingCreature() == creature then
    priority = priority + 1
  end

  -- check if distance is fine, if not then attack only if already attacked
  if #path > config.maxDistance then
    return priority
  end

  -- add config priority
  priority = priority + config.priority
  
  -- extra priority for close distance
  local path_length = #path
  if path_length == 1 then
    priority = priority + 3
  elseif path_length <= 3 then
    priority = priority + 1
  end

  -- extra priority for low health
  if config.chase and creature:getHealthPercent() < 30 then
    priority = priority + 5
  elseif creature:getHealthPercent() < 20 then
    priority = priority + 2.5
  elseif creature:getHealthPercent() < 40 then
    priority = priority + 1.5
  elseif creature:getHealthPercent() < 60 then
    priority = priority + 0.5
  elseif creature:getHealthPercent() < 80 then
    priority = priority + 0.2
  end

  return priority
end
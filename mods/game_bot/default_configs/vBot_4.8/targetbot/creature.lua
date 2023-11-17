
TargetBot.Creature = {}
TargetBot.Creature.configsCache = {}
TargetBot.Creature.cached = 0

TargetBot.Creature.resetConfigs = function()
  TargetBot.targetList:destroyChildren()
  TargetBot.Creature.resetConfigsCache()
end

TargetBot.Creature.resetConfigsCache = function()
  TargetBot.Creature.configsCache = {}
  TargetBot.Creature.cached = 0
end

TargetBot.Creature.addConfig = function(config, focus)
  if type(config) ~= 'table' or type(config.name) ~= 'string' then
    return error("Invalid targetbot creature config (missing name)")
  end
  TargetBot.Creature.resetConfigsCache()

  if not config.regex then
    config.regex = ""
    for part in string.gmatch(config.name, "[^,]+") do
      if config.regex:len() > 0 then
        config.regex = config.regex .. "|"
      end
      config.regex = config.regex .. "^" .. part:trim():lower():gsub("%*", ".*"):gsub("%?", ".?") .. "$"
    end
  end

  local widget = UI.createWidget("TargetBotEntry", TargetBot.targetList)
  widget:setText(config.name)
  widget.value = config

  widget.onDoubleClick = function(entry) -- edit on double click
    schedule(20, function() -- schedule to have correct focus
      TargetBot.Creature.edit(entry.value, function(newConfig)
        entry:setText(newConfig.name)
        entry.value = newConfig
        TargetBot.Creature.resetConfigsCache()
        TargetBot.save()
      end)
    end)
  end

  if focus then
    widget:focus()
    TargetBot.targetList:ensureChildVisible(widget)
  end
  return widget
end

TargetBot.Creature.getConfigs = function(creature)
  if not creature then return {} end
  local name = creature:getName():trim():lower()
  -- this function may be slow, so it will be using cache
  if TargetBot.Creature.configsCache[name] then
    return TargetBot.Creature.configsCache[name]
  end
  local configs = {}
  for _, config in ipairs(TargetBot.targetList:getChildren()) do
    if regexMatch(name, config.value.regex)[1] then
      table.insert(configs, config.value)
    end
  end
  if TargetBot.Creature.cached > 1000 then 
    TargetBot.Creature.resetConfigsCache() -- too big cache size, reset
  end
  TargetBot.Creature.configsCache[name] = configs -- add to cache
  TargetBot.Creature.cached = TargetBot.Creature.cached + 1
  return configs
end

TargetBot.Creature.calculateParams = function(creature, path)
  local configs = TargetBot.Creature.getConfigs(creature)
  local priority = 0
  local danger = 0
  local selectedConfig = nil
  for _, config in ipairs(configs) do
    local config_priority = TargetBot.Creature.calculatePriority(creature, config, path)
    if config_priority > priority then
      priority = config_priority
      danger = TargetBot.Creature.calculateDanger(creature, config, path)
      selectedConfig = config
    end
  end
  return {
    config = selectedConfig,
    creature = creature,
    danger = danger,
    priority = priority
  }
end

TargetBot.Creature.calculateDanger = function(creature, config, path)
  -- config is based on creature_editor
  return config.danger
end

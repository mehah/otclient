local context = G.botContext
local Panels = context.Panels

Panels.MonsterEditor = function(monster, config, callback, parent)
  local otherWindow = g_ui.getRootWidget():getChildById('monsterEditor')
  if otherWindow then
    otherWindow:destory()
  end

  local window = context.setupUI([[
MainWindow
  id: monsterEditor
  size: 450 450
  !text: tr("Edit monster")

  Label
    id: info
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    text-align: center
    text: Use monster name * for any other monster not on the list

  Label
    id: info2
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: prev.bottom
    text-align: center
    text: Add number (1-5) at the end of the name to create multiple configs

  TextEdit
    id: name
    anchors.top: prev.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-left: 100
    margin-top: 5
    multiline: false

  Label
    anchors.verticalCenter: prev.verticalCenter
    anchors.left: parent.left
    text: Target name:

  Label
    id: priorityText
    anchors.left: parent.left
    anchors.right: parent.horizontalCenter
    anchors.top: prev.bottom
    margin-right: 10
    margin-top: 10
    text: Priority
    text-align: center

  HorizontalScrollBar
    id: priority
    anchors.left: prev.left
    anchors.right: prev.right
    anchors.top: prev.bottom
    margin-top: 5
    minimum: 0
    maximum: 10
    step: 1

  Label
    id: dangerText
    anchors.left: parent.left
    anchors.right: parent.horizontalCenter
    anchors.top: prev.bottom
    margin-right: 10
    margin-top: 10
    text: Danger
    text-align: center

  HorizontalScrollBar
    id: danger
    anchors.left: prev.left
    anchors.right: prev.right
    anchors.top: prev.bottom
    margin-top: 5
    minimum: 0
    maximum: 10
    step: 1

  Label
    id: maxDistanceText
    anchors.left: parent.left
    anchors.right: parent.horizontalCenter
    anchors.top: prev.bottom
    margin-right: 10
    margin-top: 10
    text: Max distance to target
    text-align: center

  HorizontalScrollBar
    id: maxDistance
    anchors.left: prev.left
    anchors.right: prev.right
    anchors.top: prev.bottom
    margin-top: 5
    minimum: 1
    maximum: 10
    step: 1

  Label
    id: distanceText
    anchors.left: parent.left
    anchors.right: parent.horizontalCenter
    anchors.top: prev.bottom
    margin-right: 10
    margin-top: 10
    text: Keep distance
    text-align: center

  HorizontalScrollBar
    id: distance
    anchors.left: prev.left
    anchors.right: prev.right
    anchors.top: prev.bottom
    margin-top: 5
    minimum: 0
    maximum: 5
    step: 1

  Label
    id: minHealthText
    anchors.left: parent.left
    anchors.right: parent.horizontalCenter
    anchors.top: prev.bottom
    margin-right: 10
    margin-top: 10
    text: Minimum Health
    text-align: center

  HorizontalScrollBar
    id: minHealth
    anchors.left: prev.left
    anchors.right: prev.right
    anchors.top: prev.bottom
    margin-top: 5
    minimum: 0
    maximum: 100
    step: 1

  Label
    id: maxHealthText
    anchors.left: parent.left
    anchors.right: parent.horizontalCenter
    anchors.top: prev.bottom
    margin-right: 10
    margin-top: 10
    text: Maximum Health
    text-align: center

  HorizontalScrollBar
    id: maxHealth
    anchors.left: prev.left
    anchors.right: prev.right
    anchors.top: prev.bottom
    margin-top: 5
    minimum: 0
    maximum: 100
    step: 1

  Label
    id: dangerText
    anchors.left: parent.left
    anchors.right: parent.horizontalCenter
    anchors.top: prev.bottom
    margin-right: 5
    margin-top: 10
    text: If total danger is high (>8) bot won't auto loot until it's low again and will be trying to minimize it
    text-align: center
    text-wrap: true
    text-auto-resize: true

  Label
    id: attackSpellText
    anchors.left: parent.left
    anchors.right: parent.horizontalCenter
    anchors.top: prev.bottom
    margin-right: 5
    margin-top: 10
    text: Attack spell and attack rune are only used when you have more than 30% health
    text-align: center
    text-wrap: true
    text-auto-resize: true

  BotSwitch
    id: attack
    anchors.left: parent.horizontalCenter
    anchors.top: name.bottom
    margin-left: 10
    margin-top: 10
    width: 55
    text: Attack

  BotSwitch
    id: ignore
    anchors.left: prev.right
    anchors.top: name.bottom
    margin-left: 18
    margin-top: 10
    width: 55
    text: Ignore

  BotSwitch
    id: avoid
    anchors.left: prev.right
    anchors.top: name.bottom
    margin-left: 18
    margin-top: 10
    width: 55
    text: Avoid

  BotSwitch
    id: keepDistance
    anchors.left: parent.horizontalCenter
    anchors.right: parent.right
    anchors.top: prev.bottom
    margin-left: 10
    margin-top: 10
    text: Keep distance

  BotSwitch
    id: avoidAttacks
    anchors.left: parent.horizontalCenter
    anchors.right: parent.right
    anchors.top: prev.bottom
    margin-left: 10
    margin-top: 10
    text: Avoid monster attacks

  BotSwitch
    id: chase
    anchors.left: parent.horizontalCenter
    anchors.right: parent.right
    anchors.top: prev.bottom
    margin-left: 10
    margin-top: 10
    text: Chase when has low health

  BotSwitch
    id: loot
    anchors.left: parent.horizontalCenter
    anchors.right: parent.right
    anchors.top: prev.bottom
    margin-left: 10
    margin-top: 10
    text: Loot corpse

  BotSwitch
    id: monstersOnly
    anchors.left: parent.horizontalCenter
    anchors.right: parent.right
    anchors.top: prev.bottom
    margin-left: 10
    margin-top: 10
    text: Only for monsters

  BotSwitch
    id: dontWalk
    anchors.left: parent.horizontalCenter
    anchors.right: parent.right
    anchors.top: prev.bottom
    margin-left: 10
    margin-top: 10
    text: Don't walk to target

  Label
    id: attackSpellText
    anchors.left: parent.horizontalCenter
    anchors.right: parent.right
    anchors.top: prev.bottom
    margin-left: 10
    margin-top: 10
    text: Attack Spell:
    text-align: center

  TextEdit
    id: attackSpell
    anchors.left: prev.left
    anchors.right: prev.right
    anchors.top: prev.bottom
    margin-top: 2

  Label
    id: attackItemText
    anchors.left: parent.horizontalCenter
    anchors.top: prev.bottom
    margin-top: 20
    margin-left: 20
    text: Attack rune:
    text-align: left

  BotItem
    id: attackItem
    anchors.right: parent.right
    anchors.verticalCenter: prev.verticalCenter
    margin-right: 30

  Button
    id: okButton
    !text: tr('Ok')
    anchors.bottom: parent.bottom
    anchors.right: next.left
    margin-right: 10
    width: 60

  Button
    id: cancelButton
    !text: tr('Cancel')
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    width: 60
]], g_ui.getRootWidget())

  local destroy = function()
    window:destroy()
  end
  local doneFunc = function()
    local monster = window.name:getText()
    local config = {
      priority = window.priority:getValue(),
      danger = window.danger:getValue(),
      maxDistance = window.maxDistance:getValue(),
      distance = window.distance:getValue(),
      minHealth = window.minHealth:getValue(),
      maxHealth = window.maxHealth:getValue(),
      attack = window.attack:isOn(),
      ignore = window.ignore:isOn(),
      avoid = window.avoid:isOn(),
      keepDistance = window.keepDistance:isOn(),
      avoidAttacks = window.avoidAttacks:isOn(),
      chase = window.chase:isOn(),
      loot = window.loot:isOn(),
      monstersOnly = window.monstersOnly:isOn(),
      dontWalk = window.dontWalk:isOn(),
      attackItem = window.attackItem:getItemId(),
      attackSpell = window.attackSpell:getText()
    }
    destroy()
    callback(monster, config)
  end

  window.okButton.onClick = doneFunc
  window.cancelButton.onClick = destroy
  window.onEnter = doneFunc
  window.onEscape = destroy


  window.priority.onValueChange = function(scroll, value)
    window.priorityText:setText("Priority: " .. value)
  end
  window.danger.onValueChange = function(scroll, value)
    window.dangerText:setText("Danger: " .. value)
  end
  window.maxDistance.onValueChange = function(scroll, value)
    window.maxDistanceText:setText("Max distance to target: " .. value)
  end
  window.distance.onValueChange = function(scroll, value)
    window.distanceText:setText("Keep distance: " .. value)
  end
  window.minHealth.onValueChange = function(scroll, value)
    window.minHealthText:setText("Minimum health: " .. value .. "%")
  end
  window.maxHealth.onValueChange = function(scroll, value)
    window.maxHealthText:setText("Maximum health: " .. value .. "%")
  end

  window.priority:setValue(config.priority or 1)
  window.danger:setValue(config.danger or 1)
  window.maxDistance:setValue(config.maxDistance or 6)
  window.distance:setValue(config.distance or 1)
  window.minHealth:setValue(1) -- to force onValueChange update
  window.maxHealth:setValue(1) -- to force onValueChange update
  window.minHealth:setValue(config.minHealth or 0)
  window.maxHealth:setValue(config.maxHealth or 100)

  window.attackSpell:setText(config.attackSpell or "")
  window.attackItem:setItemId(config.attackItem or 0)

  window.attack.onClick = function(widget)
    if widget:isOn() then
      return
    end
    widget:setOn(true)
    window.ignore:setOn(false)
    window.avoid:setOn(false)
  end
  window.ignore.onClick = function(widget)
    if widget:isOn() then
      return
    end
    widget:setOn(true)
    window.attack:setOn(false)
    window.avoid:setOn(false)
  end
  window.avoid.onClick = function(widget)
    if widget:isOn() then
      return
    end
    widget:setOn(true)
    window.attack:setOn(false)
    window.ignore:setOn(false)
  end

  window.attack:setOn(config.attack)
  window.ignore:setOn(config.ignore)
  window.avoid:setOn(config.avoid)
  if not window.attack:isOn() and not window.ignore:isOn() and not window.avoid:isOn() then
    window.attack:setOn(true)
  end

  window.keepDistance.onClick = function(widget)
    widget:setOn(not widget:isOn())
  end
  window.avoidAttacks.onClick = function(widget)
    widget:setOn(not widget:isOn())
  end
  window.chase.onClick = function(widget)
    widget:setOn(not widget:isOn())
  end
  window.loot.onClick = function(widget)
    widget:setOn(not widget:isOn())
  end
  window.monstersOnly.onClick = function(widget)
    widget:setOn(not widget:isOn())
  end
  window.dontWalk.onClick = function(widget)
    widget:setOn(not widget:isOn())
  end

  window.keepDistance:setOn(config.keepDistance)
  window.avoidAttacks:setOn(config.avoidAttacks)
  window.chase:setOn(config.chase)
  window.loot:setOn(config.loot)
  if config.loot == nil then
    window.loot:setOn(true)
  end
  window.monstersOnly:setOn(config.monstersOnly)
  if config.monstersOnly == nil then
    window.monstersOnly:setOn(true)
  end
  window.dontWalk:setOn(config.dontWalk)

  window.name:setText(monster)

  window:show()
  window:raise()
  window:focus()
end

Panels.Attacking = function(parent)
  local ui = context.setupUI([[
Panel
  id: attacking
  height: 140

  BotLabel
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    text: Attacking

  ComboBox
    id: config
    anchors.top: prev.bottom
    anchors.left: parent.left
    margin-top: 5
    text-offset: 3 0
    width: 130

  Button
    id: enableButton
    anchors.top: prev.top
    anchors.left: prev.right
    anchors.right: parent.right
    margin-left: 5

  Button
    margin-top: 1
    id: add
    anchors.top: prev.bottom
    anchors.left: parent.left
    text: Add
    width: 60
    height: 17

  Button
    id: edit
    anchors.top: prev.top
    anchors.horizontalCenter: parent.horizontalCenter
    text: Edit
    width: 60
    height: 17

  Button
    id: remove
    anchors.top: prev.top
    anchors.right: parent.right
    text: Remove
    width: 60
    height: 17

  TextList
    id: list
    anchors.top: prev.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    vertical-scrollbar: listScrollbar
    margin-right: 15
    margin-top: 2
    height: 60
    focusable: false
    auto-focus: first

  VerticalScrollBar
    id: listScrollbar
    anchors.top: prev.top
    anchors.bottom: prev.bottom
    anchors.right: parent.right
    pixels-scroll: true
    step: 5

  Button
    margin-top: 2
    id: mAdd
    anchors.top: prev.bottom
    anchors.left: parent.left
    text: Add
    width: 60
    height: 17

  Button
    id: mEdit
    anchors.top: prev.top
    anchors.horizontalCenter: parent.horizontalCenter
    text: Edit
    width: 60
    height: 17

  Button
    id: mRemove
    anchors.top: prev.top
    anchors.right: parent.right
    text: Remove
    width: 60
    height: 17

]], parent)

  if type(context.storage.attacking) ~= "table" then
    context.storage.attacking = {}
  end
  if type(context.storage.attacking.configs) ~= "table" then
    context.storage.attacking.configs = {}
  end

  local getConfigName = function(config)
    local matches = regexMatch(config, [[name:\s*([^\n]*)$]])
    if matches[1] and matches[1][2] then
      return matches[1][2]:trim()
    end
    return nil
  end

  local commands = {}
  local monsters = {}
  local configName = nil
  local refreshConfig = nil -- declared later

  local createNewConfig = function()
    if not context.storage.attacking.activeConfig or not context.storage.attacking.configs[context.storage.attacking.activeConfig] then
      return
    end

    local newConfig = ""
    if configName ~= nil then
      newConfig = "name:" .. configName .. "\n"
    end
    for monster, config in pairs(monsters) do
      newConfig = newConfig .. "\n" .. monster .. ":" .. json.encode(config, 2) .. "\n"
    end

    context.storage.attacking.configs[context.storage.attacking.activeConfig] = newConfig
    refreshConfig()
  end

  local parseConfig = function(config)
    commands = {}
    monsters = {}
    configName = nil

    local matches = regexMatch(config, [[([^:^\n]+)(:?)([^\n]*)]])
    for i = 1, #matches do
      local command = matches[i][2]
      local validation = (matches[i][3] == ":")
      local text = matches[i][4]
      if validation then
        table.insert(commands, { command = command:lower(), text = text })
      elseif #commands > 0 then
        commands[#commands].text = commands[#commands].text .. "\n" .. matches[i][1]
      end
    end
    local labels = {}
    for i, command in ipairs(commands) do
      if commands[i].command == "name" then
        configName = commands[i].text
      else
        local status, result = pcall(function() return json.decode(command.text) end)
        if not status then
          context.error("Invalid monster config: " .. commands[i].command .. ", error: " .. result)
        else
          monsters[commands[i].command] = result
          table.insert(labels, commands[i].command)
        end
      end
    end
    table.sort(labels)
    for i, text in ipairs(labels) do
      local label = g_ui.createWidget("CaveBotLabel", ui.list)
      label:setText(text)
    end
  end

  local ignoreOnOptionChange = true
  refreshConfig = function(scrollDown)
    ignoreOnOptionChange = true
    if context.storage.attacking.enabled then
      ui.enableButton:setText("On")
      ui.enableButton:setColor('#00AA00FF')
    else
      ui.enableButton:setText("Off")
      ui.enableButton:setColor('#FF0000FF')
    end

    ui.config:clear()
    for i, config in ipairs(context.storage.attacking.configs) do
      local name = getConfigName(config)
      if not name then
        name = "Unnamed config"
      end
      ui.config:addOption(name)
    end

    if (not context.storage.attacking.activeConfig or context.storage.attacking.activeConfig == 0) and #context.storage.attacking.configs > 0 then
      context.storage.attacking.activeConfig = 1
    end

    ui.list:destroyChildren()

    if context.storage.attacking.activeConfig and context.storage.attacking.configs[context.storage.attacking.activeConfig] then
      ui.config:setCurrentIndex(context.storage.attacking.activeConfig)
      parseConfig(context.storage.attacking.configs[context.storage.attacking.activeConfig])
    end

    context.saveConfig()
    if scrollDown and ui.list:getLastChild() then
      ui.list:focusChild(ui.list:getLastChild())
    end

    ignoreOnOptionChange = false
  end

  ui.config.onOptionChange = function(widget)
    if not ignoreOnOptionChange then
      context.storage.attacking.activeConfig = widget.currentIndex
      refreshConfig()
    end
  end
  ui.enableButton.onClick = function()
    if not context.storage.attacking.activeConfig or not context.storage.attacking.configs[context.storage.attacking.activeConfig] then
      return
    end
    context.storage.attacking.enabled = not context.storage.attacking.enabled
    refreshConfig()
  end
  ui.add.onClick = function()
    modules.client_textedit.multilineEditor("Target list editor", "name:Config name", function(newText)
      table.insert(context.storage.attacking.configs, newText)
      context.storage.attacking.activeConfig = #context.storage.attacking.configs
      refreshConfig()
    end)
  end
  ui.edit.onClick = function()
    if not context.storage.attacking.activeConfig or not context.storage.attacking.configs[context.storage.attacking.activeConfig] then
      return
    end
    modules.client_textedit.multilineEditor("Target list editor",
      context.storage.attacking.configs[context.storage.attacking.activeConfig], function(newText)
        context.storage.attacking.configs[context.storage.attacking.activeConfig] = newText
        refreshConfig()
      end)
  end
  ui.remove.onClick = function()
    if not context.storage.attacking.activeConfig or not context.storage.attacking.configs[context.storage.attacking.activeConfig] then
      return
    end
    local questionWindow = nil
    local closeWindow = function()
      questionWindow:destroy()
    end
    local removeConfig = function()
      closeWindow()
      if not context.storage.attacking.activeConfig or not context.storage.attacking.configs[context.storage.attacking.activeConfig] then
        return
      end
      context.storage.attacking.enabled = false
      table.remove(context.storage.attacking.configs, context.storage.attacking.activeConfig)
      context.storage.attacking.activeConfig = 0
      refreshConfig()
    end
    questionWindow = context.displayGeneralBox(tr('Remove config'), tr('Do you want to remove current attacking config?'),
      {
        { text = tr('Yes'), callback = removeConfig },
        { text = tr('No'),  callback = closeWindow },
        anchor = AnchorHorizontalCenter
      }, removeConfig, closeWindow)
  end

  ui.mAdd.onClick = function()
    if not context.storage.attacking.activeConfig or not context.storage.attacking.configs[context.storage.attacking.activeConfig] then
      return
    end
    Panels.MonsterEditor("", {}, function(name, config)
      if name:len() > 0 then
        monsters[name] = config
      end
      createNewConfig()
    end, parent)
  end
  ui.mEdit.onClick = function()
    if not context.storage.attacking.activeConfig or not context.storage.attacking.configs[context.storage.attacking.activeConfig] then
      return
    end
    local monsterWidget = ui.list:getFocusedChild()
    if not monsterWidget or not monsters[monsterWidget:getText()] then
      return
    end
    Panels.MonsterEditor(monsterWidget:getText(), monsters[monsterWidget:getText()], function(name, config)
      monsters[monsterWidget:getText()] = nil
      if name:len() > 0 then
        monsters[name] = config
      end
      createNewConfig()
    end, parent)
  end
  ui.mRemove.onClick = function()
    if not context.storage.attacking.activeConfig or not context.storage.attacking.configs[context.storage.attacking.activeConfig] then
      return
    end
    local monsterWidget = ui.list:getFocusedChild()
    if not monsterWidget or not monsters[monsterWidget:getText()] then
      return
    end
    monsters[monsterWidget:getText()] = nil
    createNewConfig()
  end

  refreshConfig()

  -- processing
  local isConfigPassingConditions = function(monster, config)
    if not config or type(config.priority) ~= 'number' or type(config.danger) ~= 'number' then
      return false
    end

    if not config.attack then
      return false
    end

    if monster:isPlayer() and (config.monstersOnly == true or config.monstersOnly == nil) then
      return false
    end

    local pos = context.player:getPosition()
    local mpos = monster:getPosition()
    local hp = monster:getHealthPercent()

    if config.minHealth > hp or config.maxHealth < hp then
      return false
    end

    local maxDistance = 5
    if type(config.maxDistance) == 'number' then
      maxDistance = config.maxDistance
    end
    if config.chase and hp < 25 then
      maxDistance = maxDistance + 2
    end

    local distance = math.max(math.abs(pos.x - mpos.x), math.abs(pos.y - mpos.y))
    if distance > maxDistance then
      return false
    end

    local pathTo = context.findPath(context.player:getPosition(), { x = mpos.x, y = mpos.y, z = mpos.z }, maxDistance + 2,
      { ignoreNonPathable = true, precision = 1, allowOnlyVisibleTiles = true, ignoreCost = true })
    if not pathTo or #pathTo > maxDistance + 1 then
      return false
    end
    return true
  end

  local getMonsterConfig = function(monster)
    local name = monster:getName():lower()
    local hasConfig = false
    hasConfig = hasConfig or (monsters[name] ~= nil)
    if isConfigPassingConditions(monster, monsters[name]) then
      return monsters[name]
    end
    for i = 1, 5 do
      hasConfig = hasConfig or (monsters[name .. i] ~= nil)
      if isConfigPassingConditions(monster, monsters[name .. i]) then
        return monsters[name .. i]
      end
    end
    if not hasConfig and isConfigPassingConditions(monster, monsters["*"]) then
      return monsters["*"]
    end
    return nil
  end

  local calculatePriority = function(monster)
    local priority = 0
    local config = getMonsterConfig(monster)
    if not config then
      return -1
    end

    local pos = context.player:getPosition()
    local mpos = monster:getPosition()
    local hp = monster:getHealthPercent()
    local pathTo = context.findPath(context.player:getPosition(), { x = mpos.x, y = mpos.y, z = mpos.z }, 10,
      { ignoreNonPathable = true, ignoreLastCreature = true, precision = 0, allowOnlyVisibleTiles = true })
    if not pathTo then
      pathTo = context.findPath(context.player:getPosition(), { x = mpos.x, y = mpos.y, z = mpos.z }, 10,
        { ignoreNonPathable = true, precision = 1, allowOnlyVisibleTiles = true })
      if not pathTo then
        return -1
      end
    end
    local distance = #pathTo

    if monster == g_game.getAttackingCreature() then
      priority = priority + 10
    end

    if distance <= 4 then
      priority = priority + 10
    end
    if distance <= 2 then
      priority = priority + 10
    end
    if distance <= 1 then
      priority = priority + 10
    end

    if hp <= 25 and config.chase then
      priority = priority + 30
    end

    if hp <= 10 then
      priority = priority + 10
    end
    if hp <= 25 then
      priority = priority + 10
    end
    if hp <= 50 then
      priority = priority + 10
    end
    if hp <= 75 then
      priority = priority + 10
    end

    priority = priority + config.priority * 10
    return priority
  end

  local calculateMonsterDanger = function(monster)
    local danger = 0
    local config = getMonsterConfig(monster)
    if not config or type(config.danger) ~= 'number' then
      return danger
    end
    danger = danger + config.danger
    return danger
  end

  local lastAttack = context.now
  local lootContainers = {}
  local lootTries = 0
  local openContainerRequest = 0
  local waitForLooting = 0
  local lastAttackSpell = 0
  local lastAttackRune = 0

  local goForLoot = function()
    if #lootContainers == 0 or not context.storage.looting.enabled then
      return false
    end
    if modules.game_interface.lastManualWalk + 500 > context.now then
      return true
    end

    local pos = context.player:getPosition()
    table.sort(lootContainers, function(pos1, pos2)
      local dist1 = math.max(math.abs(pos.x - pos1.x), math.abs(pos.y - pos1.y))
      local dist2 = math.max(math.abs(pos.x - pos2.x), math.abs(pos.y - pos2.y))
      return dist1 < dist2
    end)

    local cpos = lootContainers[1]
    if cpos.z ~= pos.z then
      table.remove(lootContainers, 1)
      return true
    end

    if lootTries >= 5 then
      lootTries = 0
      table.remove(lootContainers, 1)
      return true
    end
    local dist = math.max(math.abs(pos.x - cpos.x), math.abs(pos.y - cpos.y))
    if dist <= 5 then
      local tile = g_map.getTile(cpos)
      if not tile then
        table.remove(lootContainers, 1)
        return true
      end

      local topItem = tile:getTopUseThing()
      if not topItem or not topItem:isContainer() then
        table.remove(lootContainers, 1)
        return true
      end
      topItem:setMarked('orange')

      if dist <= 1 then
        lootTries = lootTries + 1
        openContainerRequest = context.now
        g_game.open(topItem)
        waitForLooting = math.max(waitForLooting, context.now + 500)
        return true
      end
    end

    if dist <= 25 then
      if context.player:isWalking() then
        return true
      end

      lootTries = lootTries + 1
      if context.autoWalk(cpos, 20, { precision = 1 }) then
        return true
      end

      if context.autoWalk(cpos, 20, { ignoreNonPathable = true, precision = 1 }) then
        return true
      end

      if context.autoWalk(cpos, 20, { ignoreNonPathable = true, precision = 2 }) then
        return true
      end

      if context.autoWalk(cpos, 20, { ignoreNonPathable = true, ignoreCreatures = true, precision = 2 }) then
        return true
      end
    else
      table.remove(lootContainers, 1)
      return false
    end
    return true
  end

  context.onCreatureDisappear(function(creature)
    if not creature:isMonster() then
      return
    end
    local pos = context.player:getPosition()
    local tpos = creature:getPosition()
    if tpos.z ~= pos.z then
      return
    end

    local config = getMonsterConfig(creature)
    if not config or not config.loot then
      return
    end
    local distance = math.max(math.abs(pos.x - tpos.x), math.abs(pos.y - tpos.y))
    if distance > 6 then
      return
    end

    local tile = g_map.getTile(tpos)
    if not tile then
      return
    end

    local topItem = tile:getTopUseThing()
    if not topItem or not topItem:isContainer() then
      return
    end

    topItem:setMarked('blue')
    table.insert(lootContainers, tpos)
  end)

  context.onContainerOpen(function(container, prevContainer)
    lootTries = 0
    if not context.storage.attacking.enabled then
      return
    end

    if openContainerRequest + 500 > context.now and #lootContainers > 0 then
      waitForLooting = math.max(waitForLooting, context.now + 1000 + container:getItemsCount() * 100)
      table.remove(lootContainers, 1)
    end
    if prevContainer then
      container.autoLooting = prevContainer.autoLooting
    else
      container.autoLooting = (openContainerRequest + 3000 > context.now)
    end
  end)

  context.macro(200, function()
    if not context.storage.attacking.enabled then
      return
    end

    local attacking = nil
    local following = nil
    local attackingCandidate = g_game.getAttackingCreature()
    local followingCandidate = g_game.getFollowingCreature()
    local spectators = context.getSpectators()
    local monsters = {}
    local danger = 0

    for i, spec in ipairs(spectators) do
      if attackingCandidate and attackingCandidate:getId() == spec:getId() then
        attacking = spec
      end
      if followingCandidate and followingCandidate:getId() == spec:getId() then
        following = spec
      end
      if spec:isMonster() or (spec:isPlayer() and not spec:isLocalPlayer()) then
        danger = danger + calculateMonsterDanger(spec)
        spec.attackingPriority = calculatePriority(spec)
        table.insert(monsters, spec)
      end
    end

    if following then
      return
    end

    if waitForLooting > context.now then
      return
    end

    if #monsters == 0 or context.isInProtectionZone() then
      goForLoot()
      return
    end

    table.sort(monsters, function(a, b)
      return a.attackingPriority > b.attackingPriority
    end)

    local target = monsters[1]
    if target.attackingPriority < 0 then
      return
    end

    local pos = context.player:getPosition()
    local tpos = target:getPosition()
    local config = getMonsterConfig(target)
    local offsetX = pos.x - tpos.x
    local offsetY = pos.y - tpos.y

    local justStartedAttack = false
    if target ~= attacking then
      g_game.attack(target)
      attacking = target
      lastAttack = context.now
      justStartedAttack = true
    end

    -- proceed attack
    if not target:isPlayer() and lastAttack + 15000 < context.now then
      -- stop and attack again, just in case
      g_game.cancelAttack()
      g_game.attack(target)
      lastAttack = context.now
      return
    end

    if not justStartedAttack and config.attackSpell and config.attackSpell:len() > 0 then
      if context.now > lastAttackSpell + 1000 and context.player:getHealthPercent() > 30 then
        if context.saySpell(config.attackSpell, 1500) then
          lastAttackRune = context.now
        end
      end
    end

    if not justStartedAttack and config.attackItem and config.attackItem >= 100 then
      if context.now > lastAttackRune + 1000 and context.player:getHealthPercent() > 30 then
        if context.useRune(config.attackItem, target, 1500) then
          lastAttackRune = context.now
        end
      end
    end

    if modules.game_interface.lastManualWalk + 500 > context.now then
      return
    end

    if danger < 8 then
      -- low danger, go for loot first
      if goForLoot() then
        return
      end
    end

    target.ignoreByWaypoints = config.dontWalk
    if config.dontWalk then
      if goForLoot() then
        return
      end
      return
    end

    local distance = math.max(math.abs(offsetX), math.abs(offsetY))
    if config.keepDistance then
      local minDistance = config.distance
      if target:getHealthPercent() <= 25 and config.chase and danger < 10 then
        minDistance = 1
      end
      if (distance == minDistance or distance == minDistance + 1) then
        return
      else
        local bestDist = 10
        local bestPos = pos
        if not context.autoWalk(tpos, 10, { minMargin = minDistance, maxMargin = minDistance + 1, allowOnlyVisibleTiles = true }) then
          if not context.autoWalk(tpos, 10, { ignoreNonPathable = true, minMargin = minDistance, maxMargin = minDistance +
                  1, allowOnlyVisibleTiles = true }) then
            if not context.autoWalk(tpos, 10, { ignoreNonPathable = true, ignoreCreatures = true, minMargin = minDistance, maxMargin =
                    minDistance + 2, allowOnlyVisibleTiles = true }) then
              return
            end
          end
        end
        if not target:isPlayer() then
          context.delay(300)
        end
      end
      return
    end

    if config.avoidAttacks and distance <= 1 then
      if (offsetX == 0 and offsetY ~= 0) then
        if context.player:canWalk(Directions.East) then
          g_game.walk(Directions.East)
        elseif context.player:canWalk(Directions.West) then
          g_game.walk(Directions.West)
        end
      elseif (offsetX ~= 0 and offsetY == 0) then
        if context.player:canWalk(Directions.North) then
          g_game.walk(Directions.North)
        elseif context.player:canWalk(Directions.South) then
          g_game.walk(Directions.South)
        end
      end
    end

    if distance > 1 then
      if not context.autoWalk(tpos, 10, { precision = 1, allowOnlyVisibleTiles = true }) then
        if not context.autoWalk(tpos, 10, { ignoreNonPathable = true, precision = 1, allowOnlyVisibleTiles = true }) then
          if not context.autoWalk(tpos, 10, { ignoreNonPathable = true, precision = 2, allowOnlyVisibleTiles = true }) then
            return
          end
        end
      end
      if not target:isPlayer() then
        context.delay(300)
      end
    end
  end)
end

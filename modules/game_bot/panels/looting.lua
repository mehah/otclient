local context = G.botContext
local Panels = context.Panels

Panels.Looting = function(parent)
  local ui = context.setupUI([[
Panel
  id: looting
  height: 180
  
  BotLabel
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    text: Looting

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
  
  ScrollablePanel
    id: items
    anchors.top: prev.bottom
    anchors.right: parent.right
    anchors.left: parent.left
    vertical-scrollbar: scrollBar
    margin-right: 5
    margin-top: 2
    height: 70
    layout:
      type: grid
      cell-size: 34 34
      flow: true

  BotSmallScrollBar
    id: scrollBar
    anchors.top: prev.top
    anchors.bottom: prev.bottom
    anchors.right: parent.right
    step: 10
    pixels-scroll: true

  BotLabel
    anchors.top: prev.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 4
    text: Loot Containers

  ItemsRow
    id: containers
    anchors.top: prev.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 33
    margin-top: 2
    
]], parent)
  
  local lootContainers = { ui.containers.item1, ui.containers.item2, ui.containers.item3, ui.containers.item4, ui.containers.item5 }

  if type(context.storage.looting) ~= "table" then
    context.storage.looting = {}
  end
  if type(context.storage.looting.configs) ~= "table" then
    context.storage.looting.configs = {}  
  end

  local getConfigName = function(config)
    local matches = regexMatch(config, [[name:\s*([^\n]*)$]])
    if matches[1] and matches[1][2] then
      return matches[1][2]:trim()
    end
    return nil
  end

  local items = {}
  local itemsByKey = {}
  local containers = {}
  local commands = {}
  local refreshConfig = nil -- declared later

  local createNewConfig = function(focusedWidget)
    if not context.storage.looting.activeConfig or not context.storage.looting.configs[context.storage.looting.activeConfig] then
      return
    end
    
    local tmpItems = {}
    local tmpContainers = {}
    local focusIndex = 0

    local newConfig = ""
    for i, text in ipairs(commands) do
      newConfig = newConfig .. text .. "\n"
    end
    for i=1,ui.items:getChildCount() do
      local widget = ui.items:getChildByIndex(i)
      if widget and widget:getItemId() >= 100 then
        if tmpItems[widget:getItemId()] == nil then
          tmpItems[widget:getItemId()] = 1
          newConfig = newConfig .. "\n" .. widget:getItemId()
        end
      end
      if widget == focusedWidget then
        focusIndex = i
      end
    end
    for i, widget in ipairs(lootContainers) do
      if widget:getItemId() >= 100 then
        if tmpContainers[widget:getItemId()] == nil then
          tmpContainers[widget:getItemId()] = 1 -- remove duplicates
          newConfig = newConfig .. "\ncontainer:" .. widget:getItemId()    
        end
      end
    end
    
    context.storage.looting.configs[context.storage.looting.activeConfig] = newConfig
    refreshConfig(focusIndex)
  end
  
  local parseConfig = function(config)
    items = {}
    itemsByKey = {}
    containers = {}
    commands = {}
    local matches = regexMatch(config, [[([^:^\n^\s]+)(:?)([^\n]*)]])
    for i=1,#matches do
      local command = matches[i][2]
      local validation = (matches[i][3] == ":")
      local text = matches[i][4]
      local commandAsNumber = tonumber(command)
      local textAsNumber = tonumber(text)
      if commandAsNumber and commandAsNumber >= 100 then
        table.insert(items, commandAsNumber)
        itemsByKey[commandAsNumber] = 1
      elseif command == "container" and validation and textAsNumber and textAsNumber >= 100 then
        containers[textAsNumber] = 1
      elseif validation then
        table.insert(commands, command .. ":" .. text)
      end
    end

    local itemsToShow = #items + 2
    if itemsToShow % 5 ~= 0 then
      itemsToShow = itemsToShow + 5 - itemsToShow % 5
    end
    if itemsToShow < 10 then
      itemsToShow = 10
    end
    
    for i=1,itemsToShow do
      local widget = g_ui.createWidget("BotItem", ui.items)
      local itemId = 0
      if i <= #items then
        itemId = items[i]
      end
      widget:setItemId(itemId)
      widget.onItemChange = createNewConfig
    end
    
    for i, widget in ipairs(lootContainers) do
        widget:setItemId(0)
    end
    local containerIndex = 1
    for containerId, i in pairs(containers) do
      if lootContainers[containerIndex] then
        lootContainers[containerIndex]:setItemId(containerId)
      end
      containerIndex = containerIndex + 1
    end
    for i, widget in ipairs(lootContainers) do
      widget.onItemChange = createNewConfig
    end
  end
  
  local ignoreOnOptionChange = true
  refreshConfig = function(focusIndex)
    ignoreOnOptionChange = true
    if context.storage.looting.enabled then
      ui.enableButton:setText("On")
      ui.enableButton:setColor('#00AA00FF')
    else
      ui.enableButton:setText("Off")
      ui.enableButton:setColor('#FF0000FF')
    end
        
    ui.config:clear()
    for i, config in ipairs(context.storage.looting.configs) do
      local name = getConfigName(config)
      if not name then
        name = "Unnamed config"
      end
      ui.config:addOption(name)
    end
    
    if (not context.storage.looting.activeConfig or context.storage.looting.activeConfig == 0) and #context.storage.looting.configs > 0 then
       context.storage.looting.activeConfig = 1
    end
    
    ui.items:destroyChildren()
    for i, widget in ipairs(lootContainers) do
      widget.onItemChange = nil
      widget:setItemId(0)
      widget:setItemCount(0)
    end
    
    if context.storage.looting.activeConfig and context.storage.looting.configs[context.storage.looting.activeConfig] then
      ui.config:setCurrentIndex(context.storage.looting.activeConfig)
      parseConfig(context.storage.looting.configs[context.storage.looting.activeConfig])
    end
    
    context.saveConfig()
    if focusIndex and focusIndex > 0 and ui.items:getChildByIndex(focusIndex) then
      ui.items:focusChild(ui.items:getChildByIndex(focusIndex))
    end
    
    ignoreOnOptionChange = false
  end

  ui.config.onOptionChange = function(widget)
    if not ignoreOnOptionChange then
      context.storage.looting.activeConfig = widget.currentIndex
      refreshConfig()
    end
  end
  ui.enableButton.onClick = function()
    if not context.storage.looting.activeConfig or not context.storage.looting.configs[context.storage.looting.activeConfig] then
      return
    end
    context.storage.looting.enabled = not context.storage.looting.enabled
    refreshConfig()
  end
  ui.add.onClick = function()
    modules.client_textedit.multilineEditor("Looting editor", "name:Config name", function(newText)
      table.insert(context.storage.looting.configs, newText)
      context.storage.looting.activeConfig = #context.storage.looting.configs
      refreshConfig()
    end)
  end
  ui.edit.onClick = function()
    if not context.storage.looting.activeConfig or not context.storage.looting.configs[context.storage.looting.activeConfig] then
      return
    end
    modules.client_textedit.multilineEditor("Looting editor", context.storage.looting.configs[context.storage.looting.activeConfig], function(newText)
      context.storage.looting.configs[context.storage.looting.activeConfig] = newText
      refreshConfig()
    end)
  end
  ui.remove.onClick = function()
    if not context.storage.looting.activeConfig or not context.storage.looting.configs[context.storage.looting.activeConfig] then
      return
    end
    local questionWindow = nil
    local closeWindow = function()
      questionWindow:destroy()
    end
    local removeConfig = function()
      closeWindow()
      if not context.storage.looting.activeConfig or not context.storage.looting.configs[context.storage.looting.activeConfig] then
        return
      end
      context.storage.looting.enabled = false
      table.remove(context.storage.looting.configs, context.storage.looting.activeConfig)
      context.storage.looting.activeConfig = 0
      refreshConfig()
    end
    questionWindow = context.displayGeneralBox(tr('Remove config'), tr('Do you want to remove current looting config?'), {
      { text=tr('Yes'), callback=removeConfig },
      { text=tr('No'), callback=closeWindow },
      anchor=AnchorHorizontalCenter}, removeConfig, closeWindow)
  end
  refreshConfig()

  context.onContainerOpen(function(container, prevContainer)
    if context.storage.attacking.enabled then
      return
    end
    if prevContainer then
      container.autoLooting = prevContainer.autoLooting
    else
      container.autoLooting = true
    end
  end)

  context.macro(200, function()
    if not context.storage.looting.enabled then
      return
    end
    local candidates = {}
    local lootContainersCandidates = {}
    for containerId, container in pairs(g_game.getContainers()) do
      local containerItem = container:getContainerItem()
      if container.autoLooting and container:getItemsCount() > 0 and (not containerItem or containers[containerItem:getId()] == nil) then
        table.insert(candidates, container)
      elseif containerItem and containers[containerItem:getId()] ~= nil then
        table.insert(lootContainersCandidates, container)
      end
    end
    if #lootContainersCandidates == 0 then
      for slot = InventorySlotFirst, InventorySlotLast do
        local item = context.getInventoryItem(slot)
        if item and item:isContainer() and containers[item:getId()] ~= nil then
          table.insert(lootContainersCandidates, item)
        end
      end
      if #lootContainersCandidates > 0 then
        -- try to open inventory backpack
        local target = lootContainersCandidates[math.random(1,#lootContainersCandidates)]
        g_game.open(target, nil)
        context.delay(200)
      end
      return
    end

    if #candidates == 0 then
      return
    end

    local container = candidates[math.random(1,#candidates)]
    local nextContainers = {}
    local foundItem = nil
    for i, item in ipairs(container:getItems()) do
      if item:isContainer() then
        table.insert(nextContainers, item)
      elseif itemsByKey[item:getId()] ~= nil then
        foundItem = item
        break
      end
    end
    
    -- found item to loot
    if foundItem then
      -- find backpack for it, first backpack with same items
      for i, container in ipairs(lootContainersCandidates) do
        if container:getItemsCount() < container:getCapacity() or foundItem:isStackable() then -- has space
          for j, item in ipairs(container:getItems()) do
            if item:getId() == foundItem:getId() then
              if foundItem:isStackable() then
                if item:getCount() ~= 100  then
                  g_game.move(foundItem, container:getSlotPosition(j - 1), foundItem:getCount())
                  return
                end
              else
                g_game.move(foundItem, container:getSlotPosition(container:getItemsCount()), foundItem:getCount())
                return
              end
            end
          end
        end
      end
      -- now any backpack with empty slot
      for i, container in ipairs(lootContainersCandidates) do
        if container:getItemsCount() < container:getCapacity() then -- has space
          g_game.move(foundItem, container:getSlotPosition(container:getItemsCount()), foundItem:getCount())
          return
        end
      end

      -- can't find backpack, try to open new
      for i, container in ipairs(lootContainersCandidates) do
        local candidates = {}
        for j, item in ipairs(container:getItems()) do
          if item:isContainer() and containers[item:getId()] ~= nil then
            table.insert(candidates, item)
          end
        end
        if #candidates > 0 then
          g_game.open(candidates[math.random(1,#candidates)], container)
          return
        end
        -- full, close it
        g_game.close(container)
        return
      end
      return
    end

    -- open remaining containers
    if #nextContainers == 0 then
      return
    end
    local delay = 1
    for i=2,#nextContainers do 
      -- if more than 1 container, open them in new window
      context.schedule(delay, function()
        g_game.open(nextContainers[i], nil)
      end)
      delay = delay + 250
    end
    context.schedule(delay, function()
      g_game.open(nextContainers[1], container)
    end)
    context.delay(150 + delay)
  end)
end


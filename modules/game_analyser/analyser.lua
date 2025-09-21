analyserMiniWindow = nil
analyserButton = nil
if not configPopupWindow then
  configPopupWindow = {}
end

openedWindows = {}
cancelNextRelease = nil

local analyserWindows = {
  huntingButton = 'styles/hunting',
  lootButton = 'styles/loot',
  supplyButton = 'styles/supply',
  impactButton = 'styles/impact',
  damageButton = 'styles/input',
  xpButton = 'styles/xp',
  dropButton = 'styles/droptracker',
  partyButton = 'styles/partyhunt',
  bossButton = 'styles/boss',
  miscButton = 'styles/misc'
}

-- objects
function init()

  print("Init Game Analyzer")
  analyserButton = modules.game_mainpanel.addToggleButton('analyzerButton', 
                                                            tr('Open analytics selector window'),
                                                            '/images/options/analyzers',
                                                            toggle)

  analyserButton:setOn(false)
    
  analyserMiniWindow = g_ui.loadUI('analyser')
  analyserMiniWindow:disableResize()
  analyserMiniWindow:close()
  analyserMiniWindow:setup()

  -- Hide buttons we don't want in the main analyser selector window
  local toggleFilterButton = analyserMiniWindow:recursiveGetChildById('toggleFilterButton')
  if toggleFilterButton then
    toggleFilterButton:setVisible(false)
  end
  
  local newWindowButton = analyserMiniWindow:recursiveGetChildById('newWindowButton')
  if newWindowButton then
    newWindowButton:setVisible(false)
  end

  -- Position contextMenuButton where toggleFilterButton was (to the left of minimize button)
  local contextMenuButton = analyserMiniWindow:recursiveGetChildById('contextMenuButton')
  local minimizeButton = analyserMiniWindow:recursiveGetChildById('minimizeButton')
  
  if contextMenuButton and minimizeButton then
    contextMenuButton:setVisible(true)
    contextMenuButton:breakAnchors()
    contextMenuButton:addAnchor(AnchorTop, minimizeButton:getId(), AnchorTop)
    contextMenuButton:addAnchor(AnchorRight, minimizeButton:getId(), AnchorLeft)
    contextMenuButton:setMarginRight(7)  -- Same margin as toggleFilterButton had
    contextMenuButton:setMarginTop(0)
  end

  -- Position lockButton to the left of contextMenuButton
  local lockButton = analyserMiniWindow:recursiveGetChildById('lockButton')
  
  if lockButton and contextMenuButton then
    lockButton:setVisible(true)
    lockButton:breakAnchors()
    lockButton:addAnchor(AnchorTop, contextMenuButton:getId(), AnchorTop)
    lockButton:addAnchor(AnchorRight, contextMenuButton:getId(), AnchorLeft)
    lockButton:setMarginRight(2)  -- Same margin as in miniwindow style
    lockButton:setMarginTop(0)
  end

  configPopupWindow["lootButton"] = g_ui.displayUI('styles/lootTarget')
  configPopupWindow["lootButton"]:hide()

  configPopupWindow["impactButton"] = g_ui.displayUI('styles/dpshpsTarget')
  configPopupWindow["impactButton"]:hide()

  configPopupWindow["xpButton"] = g_ui.displayUI('styles/xpTarget')
  configPopupWindow["xpButton"]:hide()

  configPopupWindow["dropButton"] = g_ui.displayUI('styles/dropTarget')
  configPopupWindow["dropButton"]:hide()

  huntingButton = analyserMiniWindow:recursiveGetChildById("huntingButton")
  lootButton = analyserMiniWindow:recursiveGetChildById("lootButton")
  supplyButton = analyserMiniWindow:recursiveGetChildById("supplyButton")
  impactButton = analyserMiniWindow:recursiveGetChildById("impactButton")
  damageButton = analyserMiniWindow:recursiveGetChildById("damageButton")
  xpButton = analyserMiniWindow:recursiveGetChildById("xpButton")
  dropButton = analyserMiniWindow:recursiveGetChildById("dropButton")
  partyButton = analyserMiniWindow:recursiveGetChildById("partyButton")
  bossButton = analyserMiniWindow:recursiveGetChildById("bossButton")
  miscButton = analyserMiniWindow:recursiveGetChildById("miscButton")

  for id, style in pairs(analyserWindows) do
    openedWindows[id] = g_ui.loadUI(style)
    if openedWindows[id] then
      openedWindows[id]:setup()
      openedWindows[id].closeButton.onClick = function() toggleAnalysers(id) end
      openedWindows[id]:close()
      local scrollbar = openedWindows[id]:getChildById('miniwindowScrollBar')
      scrollbar:mergeStyle({ ['$!on'] = { }})
    end
  end

  HuntingAnalyser:create()
  HuntingAnalyser:updateWindow()

  LootAnalyser:create()
  LootAnalyser:updateWindow()

  SupplyAnalyser:create()
  SupplyAnalyser:updateWindow()

  ImpactAnalyser:create()
  ImpactAnalyser:updateWindow()

  InputAnalyser:create()
  InputAnalyser:updateWindow()

  XPAnalyser:create()
  XPAnalyser:updateWindow()

  DropTrackerAnalyser:create()
  DropTrackerAnalyser:updateWindow()

  PartyHuntAnalyser:create()
  PartyHuntAnalyser:updateWindow()

  BossCooldown:create()
  BossCooldown:updateWindow()

  MiscAnalyzer:create()
  MiscAnalyzer:updateWindow()

  connect(g_game, {
    onGameStart = onlineAnalyser,
    onGameEnd = offlineAnalyser,
    onSupplyTracker = onSupplyTracker,
    onLootStats = onLootStats,
    onImpactTracker = onImpactTracker,
    onKillTracker = onKillTracker,
    onPartyAnalyzer = onPartyAnalyzer,
    onBossCooldown = onBossCooldown,
    onUpdateExperience = onUpdateExperience,
    onCharmActivated = onCharmActivated,
    onImbuementActivated = onImbuementActivated,
    onSpecialSkillActivated = onSpecialSkillActivated,
  })

  connect(LocalPlayer, {
    onExperienceChange = onExperienceChange,
    onLevelChange = onLevelChange,
    onPartyMembersChange = onPartyMembersChange
  })

  connect(Creature, {
      onShieldChange = onShieldChange,
  })

  -- DEBUG: Auto-test XP gain after 5 seconds
  -- scheduleEvent(function()
  --   print("[DEBUG] Auto-testing XP gain...")
  --   testXPGain()
  -- end, 5000)

end

function terminate()
  if analyserButton then
    analyserButton:destroy()
    analyserButton = nil
  end

  if analyserMiniWindow then
    analyserMiniWindow:destroy()
    analyserMiniWindow = nil
  end

  for _, w in pairs(openedWindows) do
    w:destroy()
  end
  openedWindows = {}

  for _, w in pairs(configPopupWindow) do
    w:destroy()
  end
  configPopupWindow = {}

  disconnect(g_game, {
    onGameStart = onlineAnalyser,
    onGameEnd = offlineAnalyser,
    onSupplyTracker = onSupplyTracker,
    onLootStats = onLootStats,
    onImpactTracker = onImpactTracker,
    onKillTracker = onKillTracker,
    onPartyAnalyzer = onPartyAnalyzer,
    onBossCooldown = onBossCooldown,
    onUpdateExperience = onUpdateExperience,
    onCharmActivated = onCharmActivated,
    onImbuementActivated = onImbuementActivated,
    onSpecialSkillActivated = onSpecialSkillActivated,
  })
  disconnect(LocalPlayer, {
    onExperienceChange = onExperienceChange,
    onLevelChange = onLevelChange,
    onPartyMembersChange = onPartyMembersChange
  })

  disconnect(Creature, {
      onShieldChange = onShieldChange,
  })

end

function startNewSession(login)
  -- Hunting
  HuntingAnalyser:reset()
  if login then
    HuntingAnalyser:loadConfigJson()
  end
  HuntingAnalyser:updateWindow(true)

  -- Loot
  LootAnalyser:reset()
  LootAnalyser:updateWindow(true, true)

  -- Supply
  SupplyAnalyser:reset()
  SupplyAnalyser:updateWindow(true, true)

  ImpactAnalyser:reset()
  if login then
    ImpactAnalyser:loadConfigJson()
  end
  ImpactAnalyser:updateWindow(true)

  InputAnalyser:reset()
  if login then
    InputAnalyser:loadConfigJson()
  end
  InputAnalyser:updateWindow(true)

  XPAnalyser:reset()
  if login then
    XPAnalyser:loadConfigJson()
  end
  XPAnalyser:updateWindow(true)

  DropTrackerAnalyser:reset(login)
  if login then
    DropTrackerAnalyser:loadConfigJson()
  end
  DropTrackerAnalyser:updateWindow(true)

  MiscAnalyzer:reset()
  MiscAnalyzer:resetSessionData()
  MiscAnalyzer:updateWindow(true)

  PartyHuntAnalyser:reset()
  PartyHuntAnalyser:updateWindow(true, true)
  PartyHuntAnalyser:startEvent()

  ControllerAnalyser:startEvent()
end

function onlineAnalyser()
  local benchmark = g_clock.millis()
  startNewSession(true)

  loadGainAndWastConfigJson()
  --print("Analyser loaded in " .. (g_clock.millis() - benchmark) / 1000 .. " seconds")
end

function offlineAnalyser()
  -- Only save if we have a valid player and can still write to filesystem
  local player = g_game.getLocalPlayer()
  if player then
    -- Ensure the characterdata directory exists before saving anything
    local characterDir = "/characterdata/" .. player:getId()
    pcall(function() g_resources.makeDir("/characterdata") end)
    pcall(function() g_resources.makeDir(characterDir) end)
    
    -- Use pcall to safely attempt saves, catching any filesystem errors
    pcall(function() HuntingAnalyser:saveConfigJson() end)
    pcall(function() ImpactAnalyser:saveConfigJson() end)
    pcall(function() InputAnalyser:saveConfigJson() end)
    pcall(function() XPAnalyser:saveConfigJson() end)
    pcall(function() DropTrackerAnalyser:saveConfigJson() end)
    pcall(function() saveGainAndWastConfigJson() end)
  end
  BossCooldown.cooldown = {}
end

function toggle()
  if analyserMiniWindow:isVisible() then
    analyserMiniWindow:close()
    analyserButton:setOn(false)
    analyserMiniWindow.isOpen = false
  else
    if not analyserMiniWindow:getParent() then
      local panel = modules.game_interface.findContentPanelAvailable(analyserMiniWindow, analyserMiniWindow:getMinimumHeight())
      if not panel then
        return
      end
      panel:addChild(analyserMiniWindow)
    end
    analyserMiniWindow:open()
    analyserMiniWindow.isOpen = true
    analyserButton:setOn(true)
  end
end

function hide()
  analyserMiniWindow:close()
  analyserMiniWindow.isOpen = false
  analyserButton:setOn(false)
end

function onOpen()
  analyserMiniWindow:setHeight(247)
  analyserMiniWindow.isOpen = true
end

function show()
  analyserMiniWindow:open()
  analyserMiniWindow.isOpen = true
  analyserButton:setOn(true)
end

function toggleAnalysers(buttonId)
  local buttonWidget = analyserMiniWindow:recursiveGetChildById(buttonId)
  local widget = openedWindows[buttonId]
  if not widget then
    return
  end

  if widget:isVisible() then
    widget:close()
    widget.isOpen = false
    buttonWidget:setOn(false)
    if buttonId == 'bossButton' then
      toggleBossCDFocus(false)
    end
  else
    widget.isOpen = true
    widget:open()

    if buttonId == 'impactButton' then
      ImpactAnalyser:checkAnchos()
    elseif buttonId == 'damageButton' then
      InputAnalyser:checkAnchos()
    elseif buttonId == 'xpButton' then
      XPAnalyser:checkAnchos()
      XPAnalyser:forceUpdateUI()  -- Update UI with any accumulated XP data
    elseif buttonId == 'bossButton' then
      toggleBossCDFocus(false)
      widget:focus()
    elseif buttonId == 'xpAnalyser' then
      XPAnalyser:checkAnchos()
      XPAnalyser:forceUpdateUI()  -- Update UI with any accumulated XP data
    end

    -- Properly assign widget to a panel if it doesn't have a parent
    if not widget:getParent() then
      local panel = modules.game_interface.findContentPanelAvailable(widget, widget:getMinimumHeight())
      if not panel then
        return
      end
      panel:addChild(widget)
    end
    
    widget:getParent():moveChildToIndex(widget, #widget:getParent():getChildren())
    buttonWidget:setOn(true)
  end
end

function onExperienceChange(localPlayer, value)
  HuntingAnalyser:setupStartExp(value)
  XPAnalyser:setupStartExp(value)
  
  -- Calculate XP gain from experience change
  -- Use XPAnalyser.lastExp since both analyzers should track the same XP values
  if XPAnalyser.lastExp and value > XPAnalyser.lastExp then
    local gain = value - XPAnalyser.lastExp
    HuntingAnalyser:addRawXPGain(gain)
    HuntingAnalyser:addXpGain(gain)
    XPAnalyser:addRawXPGain(gain)
    XPAnalyser:addXpGain(gain)
  end
  
  -- Store the current experience for next comparison in both analyzers
  XPAnalyser.lastExp = value
  HuntingAnalyser.lastExp = value
end

function onUpdateExperience(rawExp, exp)
  -- Both rawExp and exp might already have rate modifiers applied
  -- We need to calculate the true raw experience value (base rate only)
  
  -- For raw XP gain, we'll use the exp value and remove all rate modifiers to get true base XP
  HuntingAnalyser:addRawXPGain(exp)  -- This will be processed by calculateRawXP() internally
  HuntingAnalyser:addXpGain(exp)
  XPAnalyser:addRawXPGain(exp)       -- This will be processed by calculateRawXP() internally  
  XPAnalyser:addXpGain(exp)
end

function onLootStats(item, name)
  HuntingAnalyser:addLootedItems(item, name)
  LootAnalyser:addLootedItems(item, name)
end

function onSupplyTracker(itemId)
  HuntingAnalyser:addSuppliesItems(itemId)
  SupplyAnalyser:addSuppliesItems(itemId)
end

function onImpactTracker(analyzerType, amount, effect, target)
  if analyzerType == ANALYZER_HEAL then
    HuntingAnalyser:addHealing(amount)
    ImpactAnalyser:addHealing(amount)
  elseif analyzerType == ANALYZER_DAMAGE_DEALT then
    HuntingAnalyser:addDealDamage(amount)
    ImpactAnalyser:addDealDamage(amount, effect)
  elseif analyzerType == ANALYZER_DAMAGE_RECEIVED then
    InputAnalyser:addInputDamage(amount, effect, target)
  end
end

function onKillTracker(monsterName, monsterOutfit, dropItems)
  HuntingAnalyser:addMonsterKilled(monsterName)
  DropTrackerAnalyser:checkMonsterKilled(monsterName, monsterOutfit, dropItems)
end


-- Loot and Wast file
function loadGainAndWastConfigJson()
  local config = {
    gainGaugeTarget = 0,
    gainGaugeVisible = true,
    gainGraphVisible = true,
    wasteGaugeTarget = 0,
    wasteGaugeVisible = true,
    wasteGraphVisible = true,
  }

  if not g_game.isOnline() then return end
  
  local player = g_game.getLocalPlayer()
  if not player then return end

  local file = "/characterdata/" .. player:getId() .. "/gainandwaste.json"
  if g_resources.fileExists(file) then
    local status, result = pcall(function()
      return json.decode(g_resources.readFileContents(file))
    end)

    if not status then
      return g_logger.error("Error while reading characterdata file. Details: " .. result)
    end

    config = result
  end

  LootAnalyser:setLootPerHourGauge(config.gainGaugeVisible)
  LootAnalyser:setLootPerHourGraph(config.gainGraphVisible)
  LootAnalyser:setTarget(config.gainGaugeTarget)

  SupplyAnalyser:setSupplyPerHourGauge(config.wasteGaugeVisible)
  SupplyAnalyser:setSupplyPerHourGraph(config.wasteGraphVisible)
  SupplyAnalyser:setTarget(config.wasteGaugeTarget)
end

function saveGainAndWastConfigJson()
  if not g_game.isOnline() then return end
  
  local player = g_game.getLocalPlayer()
  if not player then return end
  
  -- Ensure the characterdata directory exists
  local characterDir = "/characterdata/" .. player:getId()
  pcall(function() g_resources.makeDir("/characterdata") end)
  pcall(function() g_resources.makeDir(characterDir) end)
  
  local config = {
    gainGaugeTarget = LootAnalyser:getTarget(),
    gainGaugeVisible = LootAnalyser:gaugeIsVisible(),
    gainGraphVisible = LootAnalyser:graphIsVisible(),
    wasteGaugeTarget = SupplyAnalyser:getTarget(),
    wasteGaugeVisible = SupplyAnalyser:gaugeIsVisible(),
    wasteGraphVisible = SupplyAnalyser:graphIsVisible(),
  }

  local file = "/characterdata/" .. player:getId() .. "/gainandwaste.json"
  local status, result = pcall(function() return json.encode(config, 2) end)
  if not status then
    return g_logger.error("Error while saving profile Analyzer data. Data won't be saved. Details: " .. result)
  end

  if result:len() > 100 * 1024 * 1024 then
    return g_logger.error("Something went wrong, file is above 100MB, won't be saved")
  end
  
  -- Safely attempt to write the file, ignoring errors during logout
  local writeStatus, writeError = pcall(function()
    return g_resources.writeFileContents(file, result)
  end)
  
  if not writeStatus then
    -- Log the error but don't spam the console during normal logout
    g_logger.debug("Could not save GainAndWaste config during logout: " .. tostring(writeError))
  end
end

function checkNumber(self, text)
  local number = tonumber(text)
  if (not number or number < 0) and #text > 1 then
    self:setText('0', false)
  end
end

function onLevelChange(localPlayer, value, percent)
  XPAnalyser:setupLevel(value, percent)
end

function managerDropTracker(itemId, checked)
  DropTrackerAnalyser:managerDropItem(itemId, checked)
end

function isInDropTracker(itemId)
  return DropTrackerAnalyser:isInDropTracker(itemId)
end

function onPartyAnalyzer(startTime, leaderID, lootType, membersData, membersName)
  PartyHuntAnalyser:onPartyAnalyzer(startTime, leaderID, lootType, membersData, membersName)
end

function onBossCooldown(cooldown)
  BossCooldown:setupCooldown(cooldown)
end

function onCloseMiniWindow(self)
  self.isOpen = false
end

function onPlayerLoad()

end

function onPlayerUnload()

end

function moveAnalyser(panel, height, minimzed)
  analyserMiniWindow:setParent(panel)
  analyserMiniWindow:open()

  if minimzed then
    analyserMiniWindow:setHeight(height)
    analyserMiniWindow:minimize()
  else
    -- Hardcoded height
    if height < 247 then
      height = 247
    end

    analyserMiniWindow:maximize()
    analyserMiniWindow:setHeight(height)
  end

  return analyserMiniWindow
end

function moveChildAnalyser(type, panel, height, minimzed)
  local window = {
    ['bossCooldowns'] = 'bossButton',
    ['damageInputAnalyser'] = 'damageButton',
    ['lootTracker'] = 'dropButton',
    ['huntingSessionAnalyser'] = 'huntingButton',
    ['impactAnalyser'] = 'impactButton',
    ['lootAnalyser'] = 'lootButton',
    ['partyHuntAnalyser'] = 'partyButton',
    ['wasteAnalyser'] = 'supplyButton',
    ['xpAnalyser'] = 'xpButton',
    ['miscAnalyzer'] = 'miscButton'
  }

  local widget = openedWindows[window[type]]
  if widget then
    widget:setParent(panel)
    widget:open()

    if minimzed then
      widget:setHeight(height)
      widget:minimize()
    else
      widget:maximize()
      widget:setHeight(height)
    end

    if type == 'xpAnalyser' then
      XPAnalyser:checkAnchos()
    end

    -- check
    local buttonWidget = analyserMiniWindow:recursiveGetChildById(window[type])
    if buttonWidget then
      buttonWidget:setOn(true)
    end
  end

  return widget
end

function onCharmActivated(charmId)
  MiscAnalyzer:onCharmActivated(charmId)
end

function onImbuementActivated(imbuementId, amount)
  MiscAnalyzer:onImbuementActivated(imbuementId, amount)
end

function onSpecialSkillActivated(skillId)
  MiscAnalyzer:onSpecialSkillActivated(skillId)
end

-- DEBUG: Test function to manually trigger XP gain
-- function testXPGain()
--   print("[DEBUG] Testing XP gain manually...")
--   onUpdateExperience(100, 150) -- rawExp = 100, exp = 150
--   print("[DEBUG] XP gain test completed")
-- end

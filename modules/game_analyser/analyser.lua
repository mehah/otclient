analyserMiniWindow = nil
analyserButton = nil
if not configPopupWindow then
  configPopupWindow = {}
end

openedWindows = {}
cancelNextRelease = nil

-- Party member tracking
partyMemberCheckEvent = nil
local lastPartyMembers = {}

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

-- Utility function to get combat name from effect ID
function getCombatName(effectId)
  if not effectId then
    return "Unknown"
  end
  
  -- Use the clientCombat table from player.lua
  if clientCombat and clientCombat[effectId] then
    return clientCombat[effectId].id or "Unknown"
  end
  
  -- Fallback names if clientCombat is not available
  local combatNames = {
    [0] = "Physical",
    [1] = "Fire", 
    [2] = "Earth",
    [3] = "Energy",
    [4] = "Ice",
    [5] = "Holy",
    [6] = "Death",
    [7] = "Healing",
    [8] = "Drown",
    [9] = "Lifedrain",
    [10] = "Manadrain"
  }
  
  return combatNames[effectId] or "Unknown"
end

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
  
  -- Set up party member tracking as backup (less frequent since shield changes trigger it)
  if partyMemberCheckEvent then
    partyMemberCheckEvent:cancel()
  end
  partyMemberCheckEvent = cycleEvent(checkPartyMembersChange, 5000) -- Every 5 seconds as backup

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
  
  -- Clean up party member tracking
  if partyMemberCheckEvent then
    partyMemberCheckEvent:cancel()
    partyMemberCheckEvent = nil
  end

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
  -- This function is called when the player's total experience changes
  -- We should track the experience progression here
  
  -- Calculate XP gain BEFORE setting up start exp
  local previousExp = XPAnalyser.lastExp
  
  -- Setup start experience if this is the first time
  HuntingAnalyser:setupStartExp(value)
  XPAnalyser:setupStartExp(value)
  
  -- Calculate XP gain from experience change using the previous value
  -- Only calculate gain if we have a previous value and current value is higher
  if previousExp and previousExp > 0 and value > previousExp then
    local gain = value - previousExp
    HuntingAnalyser:addRawXPGain(gain)
    HuntingAnalyser:addXpGain(gain)
    XPAnalyser:addRawXPGain(gain)
    XPAnalyser:addXpGain(gain)
  end
  
  -- Update the last experience for next comparison
  XPAnalyser.lastExp = value
  HuntingAnalyser.lastExp = value
end

function onUpdateExperience(rawExp, exp)
  -- This function might be called with the XP gain amount directly
  -- If rawExp and exp represent gains (not totals), we should use them directly
  
  -- TEMPORARILY DISABLED: Testing if onExperienceChange is sufficient
  -- HuntingAnalyser:addRawXPGain(exp)  -- This will be processed by calculateRawXP() internally
  -- HuntingAnalyser:addXpGain(exp)
  -- XPAnalyser:addRawXPGain(exp)       -- This will be processed by calculateRawXP() internally  
  -- XPAnalyser:addXpGain(exp)
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

function onPartyMembersChange(self, members)
  PartyHuntAnalyser.onPartyMembersChange(self, members)
end

-- Alternative implementation that manually tracks party members through spectators
function checkPartyMembersChange()
  if not g_game.isOnline() then return end
  
  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer then return end
  
  -- Check if local player has left the party
  local localShield = localPlayer:getShield()
  local localIsInParty = (localShield == ShieldYellow or localShield == ShieldYellowSharedExp or localShield == ShieldYellowNoSharedExpBlink or 
     localShield == ShieldYellowNoSharedExp or localShield == ShieldBlue or localShield == ShieldBlueSharedExp or 
     localShield == ShieldBlueNoSharedExpBlink or localShield == ShieldBlueNoSharedExp)
  
  -- If local player is no longer in party, clear all party data
  if not localIsInParty and #lastPartyMembers > 0 then
    print("[PartyTracker] Local player no longer in party - clearing all party data")
    lastPartyMembers = {}
    onPartyMembersChange(localPlayer, {})
    return
  end
  
  -- Only check for new visible party members, don't remove existing ones
  if localIsInParty then
    local spectators = g_map.getSpectators(localPlayer:getPosition(), false)
    local newMembersFound = false
    
    -- Build a lookup of existing party member IDs
    local existingMemberIds = {}
    for _, member in ipairs(lastPartyMembers) do
      existingMemberIds[member:getId()] = true
    end
    
    -- Add local player to existing members if not already tracked
    if not existingMemberIds[localPlayer:getId()] then
      table.insert(lastPartyMembers, localPlayer)
      existingMemberIds[localPlayer:getId()] = true
      newMembersFound = true
      print("[PartyTracker] Added local player to party tracking")
    end
    
    -- Check for new visible party members
    for _, creature in ipairs(spectators) do
      if creature:isPlayer() and not existingMemberIds[creature:getId()] then
        local shield = creature:getShield()
        -- Check if creature has ACTUAL party shield (exclude invitation shields)
        if shield == ShieldYellow or shield == ShieldYellowSharedExp or shield == ShieldYellowNoSharedExpBlink or 
           shield == ShieldYellowNoSharedExp or shield == ShieldBlue or shield == ShieldBlueSharedExp or 
           shield == ShieldBlueNoSharedExpBlink or shield == ShieldBlueNoSharedExp then
          table.insert(lastPartyMembers, creature)
          existingMemberIds[creature:getId()] = true
          newMembersFound = true
          print("[PartyTracker] Found new party member: " .. creature:getName())
        end
      end
    end
    
    -- Only trigger update if new members were found
    if newMembersFound then
      print("[PartyTracker] New party members detected, updating party")
      onPartyMembersChange(localPlayer, lastPartyMembers)
    end
  end
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

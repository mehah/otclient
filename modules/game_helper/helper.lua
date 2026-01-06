-- Função de log segura com fallback
local function safeLog(level, message)
  local success, err = pcall(function()
    if g_logger and g_logger[level] then
      g_logger[level](message)
    else
      print(string.format("[Helper %s] %s", level:upper(), message))
    end
  end)
  if not success then
    print(string.format("[Helper %s] %s", level:upper(), message))
  end
end

-- Log imediato no carregamento do módulo (fora de funções)
--safeLog("info", "Helper: Module file loaded")

local player = nil
local healingPanel = nil
local toolsPanel = nil
local mouseGrabberWidget = nil
local helper = nil
local helperTracker = nil
local helperRules = nil
local friendListWidget = nil
local granListWidget = nil
local hotkeyHelperStatus = false
local helperButton = nil

-- fallback for LoadedPlayer when not provided by server-side module
if not LoadedPlayer then
  LoadedPlayer = g_game.getLocalPlayer()
end

-- fallback for translateVocation
if not translateVocation then
  function translateVocation(id)
    -- Vocation translation mapping client IDs to server IDs
    -- Based on game_actionbar/logics/const.lua and gamelib/creature.lua
    -- Client: Knight=1, Paladin=2, Sorcerer=3, Druid=4, Monk=5, EliteKnight=11, RoyalPaladin=12, MasterSorcerer=13, ElderDruid=14, ExaltedMonk=15
    -- Server: Sorcerer=1, Druid=2, Paladin=3, Knight=4, MasterSorcerer=5, ElderDruid=6, RoyalPaladin=7, EliteKnight=8, Monk=9, ExaltedMonk=10
    if id == 1 or id == 11 then -- Knight or Elite Knight
      return 8 -- Elite Knight
    elseif id == 2 or id == 12 then -- Paladin or Royal Paladin
      return 7 -- Royal Paladin
    elseif id == 3 or id == 13 then -- Sorcerer or Master Sorcerer
      return 5 -- Master Sorcerer
    elseif id == 4 or id == 14 then -- Druid or Elder Druid
      return 6 -- Elder Druid
    elseif id == 5 or id == 15 then -- Monk or Exalted Monk
      return 10 -- Exalted Monk
    end
    return 0
  end
end

-- fallback for SpellIcons
if not SpellIcons then
  SpellIcons = {}
  -- This is a fallback - if SpellIcons is not available, we'll use the spell ID directly
  -- The actual SpellIcons table should map icon names to spell IDs
end

-- Helper function to get spell ID from icon
local function getSpellIdFromIcon(icon)
  if not icon or icon == "" then
    return 0
  end
  if SpellIcons and SpellIcons[icon] and SpellIcons[icon][1] then
    return SpellIcons[icon][1]
  end
  -- Fallback: try to use the icon as a number, or return 0
  if type(icon) == "number" then
    return icon
  end
  -- Try to convert string to number
  local numIcon = tonumber(icon)
  if numIcon then
    return numIcon
  end
  return 0
end

-- Helper function to get image clip for spell
local function getSpellImageClip(spellId, profile)
  if Spells and Spells.getImageClipNormal then
    local success, clip = pcall(function() return Spells.getImageClipNormal(spellId, profile or 'Default') end)
    if success and clip then
      return clip
    end
  end
  -- Fallback: calculate clip based on spellId (assuming 32x32 icons in a grid)
  -- This is a simple fallback - adjust based on your icon layout
  local iconSize = 32
  local iconsPerRow = 10 -- Adjust based on your sprite sheet
  local row = math.floor(spellId / iconsPerRow)
  local col = spellId % iconsPerRow
  return {x = col * iconSize, y = row * iconSize, width = iconSize, height = iconSize}
end

-- Helper function to get spell by client ID
local function getSpellByClientId(clientId)
  if Spells and Spells.getSpellByClientId then
    local success, spell = pcall(function() return Spells.getSpellByClientId(clientId) end)
    if success and spell then
      return spell
    end
  end
  -- Fallback: try to find spell in SpellInfo by clientId
  if SpellInfo and SpellInfo.Default then
    for spellName, spellData in pairs(SpellInfo.Default) do
      if spellData.clientId == clientId then
        return spellData
      end
    end
  end
  return nil
end

-- Helper function to get spell data by ID
local function getSpellDataById(spellId)
  if not spellId or spellId == 0 then
    return nil
  end
  -- First try SpellInfo.Default (most reliable)
  if SpellInfo and SpellInfo.Default then
    for spellName, spellData in pairs(SpellInfo.Default) do
      if spellData.id == spellId then
        return spellData
      end
    end
  end
  -- Then try Spells.getSpellDataById if available
  if Spells and Spells.getSpellDataById then
    local success, spell = pcall(function() return Spells.getSpellDataById(spellId) end)
    if success and spell then
      return spell
    end
  end
  return nil
end
local autoTargetOnHold = false
local multiUseExDelay = 0
local afkTime = 180
local autoTargetModes = {
  ["A"] = 1,
  ["B"] = 2,
  ["C"] = 3,
  ["D"] = 4,
  ["E"] = 5,
  ["F"] = 6,
  ["G"] = 7,
  ["H"] = 8
}

local function deepCopy(original)
  local copy = {}
  for k, v in pairs(original) do
    if type(v) == "table" then
      copy[k] = deepCopy(v)
    else
      copy[k] = v
    end
  end
  return copy
end

local defaultShooterProfile = {
  spells = {
    {id = 0, percent = 0, creatures = 1, priority = 1, forceCast = false, selfCast = false},
    {id = 0, percent = 0, creatures = 1, priority = 2, forceCast = false, selfCast = false},
    {id = 0, percent = 0, creatures = 1, priority = 3, forceCast = false, selfCast = false},
    {id = 0, percent = 0, creatures = 1, priority = 4, forceCast = false, selfCast = false},
    {id = 0, percent = 0, creatures = 1, priority = 5, forceCast = false, selfCast = false},
  },
  runes = {
    {id = 0, creatures = 1, priority = 6, forceCast = false},
    {id = 0, creatures = 1, priority = 7, forceCast = false},
  },
  autoTargetMode = autoTargetModes['F']
}

local foodConfig = {id = "food", exhaustion = 1000}
local potionConfig = {id = "potion", exhaustion = 1000}

local helperEvents = {
  helperCycleEvent = nil,
  helperCycleTimer = 50
}

local timers = {
  checkHealthHealing = 0,
  checkMana = 0,
  routineChecks = 0,
  checkFriendHealing = 0,
  checkAutoHaste = 0,
  checkMagicShooter = 0,
  checkAutoTarget = 0,
  checkExerciseEvent = 0
}

local eventTable = {
  checkHealthHealing = { interval = 250, action = nil },
  checkMana = { interval = 100, action = nil },
  routineChecks = { interval = 1000, action = nil },
  checkFriendHealing = { interval = 250, action = nil },
  checkAutoHaste = { interval = 500, action = nil },
  checkMagicShooter = { interval = 100, action = nil },
  checkAutoTarget = { interval = 250, action = nil },
  checkExerciseEvent = { interval = 10000, action = nil }
}

local spellsCooldown = {}
local function getSpellCooldown(spellId)
  return spellsCooldown[spellId] or 0
end

local groupsCooldown = {}
local function getGroupSpellCooldown(groupId)
  return groupsCooldown[groupId] or 0
end

local function getDistanceBetween(p1, p2)
  return math.max(math.abs(p1.x - p2.x), math.abs(p1.y - p2.y))
end

local function positionCompare(position1, position2)
  return position1.x == position2.x and position1.y == position2.y and position1.z == position2.z
end

local function getDirectionTo(fromPos, toPos)
  local dx = toPos.x - fromPos.x
  local dy = toPos.y - fromPos.y
  
  if dx == 0 and dy == 0 then
    return nil
  end
  
  if math.abs(dx) > math.abs(dy) then
    if dx > 0 then
      return Directions.East
    else
      return Directions.West
    end
  else
    if dy > 0 then
      return Directions.South
    else
      return Directions.North
    end
  end
end

local function getPlayer()
  if not player then
    player = g_game.getLocalPlayer()
  end
  return player
end

local function playerHasSpell(player, spellId)
  -- getSpells() may not be available, so we'll assume the player has the spell
  -- if they meet the level and mana requirements (which are checked separately)
  -- This is a fallback - if getSpells is available, use it
  if player and player.getSpells then
    local success, spells = pcall(function() return player:getSpells() end)
    if success and spells then
      return table.contains(spells, spellId)
    end
  end
  -- If we can't check, assume the player has the spell
  -- The level/mana checks will filter out spells they can't use anyway
  return true
end

local function numberToOrdinal(n)
  local lastDigit = n % 10
  local lastTwoDigits = n % 100
  if lastTwoDigits >= 11 and lastTwoDigits <= 13 then
    return tostring(n) .. "th"
  end
  if lastDigit == 1 then
    return tostring(n) .. "st"
  elseif lastDigit == 2 then
    return tostring(n) .. "nd"
  elseif lastDigit == 3 then
    return tostring(n) .. "rd"
  else
    return tostring(n) .. "th"
  end
end

local function isWithinReach(playerPos, targetPos)
  if type(targetPos) ~= "table" then
    return false
  end

  local deltaX = math.abs(playerPos.x - targetPos.x)
  local deltaY = math.abs(playerPos.y - targetPos.y)
  local withinX = deltaX <= 7
  local withinY = deltaY <= 5
  return withinX and withinY and playerPos.z == targetPos.z
end

local spectators = {}

helperConfig = {
  spells = {
    { id = 0, percent = 80 },
    { id = 0, percent = 80 },
    { id = 0, percent = 80 }
  },
  potions = {
    { id = 0, percent = 50, priority = 0 },
    { id = 0, percent = 50, priority = 0 },
    { id = 0, percent = 50, priority = 0 }
  },
  training = {
    {id = 0, percent = 0, enabled = false }
  },
  haste = {
    {id = 0, enabled = false, safecast = false }
  },
  friendhealing = {
    {name = "", percent = 0, enabled = false },
    {name = "", percent = 0, enabled = false }
  },
  gransiohealing = {
    {name = "", percent = 0, enabled = false },
    {name = "", percent = 0, enabled = false }
  },

  shooterProfiles = {
    ["Default"] = defaultShooterProfile
  }, 
  selectedShooterProfile = "Default",

  terms = false,
  autoEatFood = false,
  autoReconnect = false,
  autoChangeGold = false,
  magicShooterEnabled = false,
  magicShooterOnHold = false,
  autoTargetEnabled = false,
  autoTargetMode = autoTargetModes['F'],
  currentLockedTargetId = 0
}

local foodIds = {
  3577, 3578, 3579, 3581, 3582, 3583, 3585, 3586, 3587,
  3588, 3589, 3592, 3595, 3597, 3600, 3601, 3602, 3606,
  3607, 3723, 3724, 3725, 3728, 3731, 3732, 8011, 8014,
  8016, 8017, 12310, 14085, 17457, 17820, 17821, 21143,
  21144, 21146, 23535, 23545
}

local infiniteFoodIds = {
  61615, 61672, 61930, 62184, 62267, 62268, 63235, 63314,
  63723
}

local exerciseDummies = {
  28558, 28559, 28560, 28561, 28562, 28563, 28564, 28565,
  61621, 61622, 61623, 61624, 61698, 61699, 61892, 61893,
  61974, 61975, 62118, 62119, 62191, 62192, 62228, 62229,
  62294, 62295, 63249, 63250, 63713
}

local exercises = {
  28552, 28553, 28554, 28555, 28556, 28557, 35279, 35280,
  35281, 35282, 35283, 35284, 35285, 35286, 35287, 35288,
  35289, 35290, 44064, 44065, 44066, 44067, 50292, 50293,
  50294, 50295, 62101, 62102, 62103, 62104, 62105, 62106,
  62107, 63492
}

-- spells that can be cast on both targets and self
local bothCastTypeSpells = {
  258
}


local ignoredSpellsIds = {
  [144] = true,  -- Cure Bleeding
  [146] = true,  -- Cure Electrification
  [29]  = true,  -- Cure Poison
  [145] = true,  -- Cure Burning
  [147] = true,   -- Cure Curse
  [160] = true,   -- Utura Gran
  [159] = true,   -- Utura
  [128] = true,   -- Utura Mas Sio
  [141] = true,   -- utori alguma coisa
  [138] = true,   -- utori alguma coisa
  [139] = true,   -- utori alguma coisa
  [140] = true,   -- utori alguma coisa
  [143] = true,   -- utori alguma coisa
  [142] = true,   -- utori alguma coisa
  [84]  =  true,
  [242] = true,
  [297] = true,
  [274] = true,
  [275] = true,
  [276] = true,
  [296] = true,
}

local ignoredTrainingSpells = {
  [144] = true,  -- Cure Bleeding
  [146] = true,  -- Cure Electrification
  [29]  = true,  -- Cure Poison
  [145] = true,  -- Cure Burning
  [147] = true,   -- Cure Curse
  [160] = true,   -- Utura Gran
  [159] = true,   -- Utura
  [128] = true,   -- Utura Mas Sio
  [141] = true,   -- utori alguma coisa
  [138] = true,   -- utori alguma coisa
  [139] = true,   -- utori alguma coisa
  [140] = true,   -- utori alguma coisa
  [143] = true,   -- utori alguma coisa
  [142] = true,   -- utori alguma coisa
  [170] = true,
  [123] = true,
  [239] = true,
  [241] = true,
  [242] = true,
  [125] = true,
  [82] = true,
  [84] = true,
  [1] = true,
  [2] = true,
  [158] = true,
  [172] = true,
  [36] = true,
  [277] = true,
}

local potionWhitelist = {
  {id = 268, name = "Mana Potion", type = "mana"},
  {id = 237, name = "Strong Mana Potion", type = "mana"},
  {id = 238, name = "Great Mana Potion", type = "mana"},
  {id = 23373, name = "Ultimate Mana Potion", type = "mana"},
  {id = 266, name = "Health Potion", type = "health"},
  {id = 236, name = "Strong Health Potion", type = "health"},
  {id = 239, name = "Great Health Potion", type = "health"},
  {id = 7643, name = "Ultimate Health Potion", type = "health"},
  {id = 23375, name = "Supreme Health Potion", type = "health"},
  {id = 7642, name = "Great Spirit Potion", type = "health"},
  {id = 23374, name = "Ultimate Spirit Potion", type = "health"},
  {id = 7876, name = "Small Health Potion", type = "health"}
}

local hasteWhiteList = {
  [9] = {6, 39}, -- em
  [8] = {6, 131}, -- ek
  [7] = {6, 134}, -- rp
  [6] = {6, 39}, -- ed
  [5] = {6, 39}, -- ms
  [0] = {}, -- rook
}


function init()
  --safeLog("info", "Helper: init() - Module initializing")
  
  local success, err = pcall(function()
    connect(LocalPlayer, {
      onPartyMembersChange = onPartyMembersChange,
    })

    connect(g_game, {
      onGameStart = function()
    --    safeLog("info", "Helper: onGameStart event triggered")
        online()
      end,
      onGameEnd = offline,
      onSpellCooldown = onSpellCooldown,
      onSpellGroupCooldown = onSpellGroupCooldown,
      onUpdateSpellArea = onUpdateSpellArea,
      onPartyDataUpdate = onPartyDataUpdate,
      onPartyDataClear = onPartyDataClear,
      onMultiUseCooldown = onMultiUseCooldown,
    })
    --safeLog("debug", "Helper: init() - Game events connected")
  end)
  
  if not success then
    safeLog("error", string.format("Helper: init() - Error connecting events: %s", tostring(err)))
  end

  success, err = pcall(function()
    connect(Creature, {
      onAppear = onCreatureAppear,
      onDisappear = onCreatureDisappear,
    })
 --   safeLog("debug", "Helper: init() - Creature events connected")
  end)
  
  if not success then
    safeLog("error", string.format("Helper: init() - Error connecting creature events: %s", tostring(err)))
  end

  success, err = pcall(function()
    g_ui.importStyle('styles/helper')
    helper = g_ui.displayUI('helper_window')
    if not helper then
      helper = g_ui.loadUI('helper_window', g_ui.getRootWidget())
    end
    if helper then
      safeLog("debug", "Helper: init() - Helper window created")
    else
      safeLog("error", "Helper: init() - Failed to create helper window")
    end
  end)
  
  if not success then
    safeLog("error", string.format("Helper: init() - Error creating UI: %s", tostring(err)))
  end

  success, err = pcall(function()
    helperTracker = g_ui.createWidget('HelperTracker')
    helperRules =  g_ui.createWidget('HelperRules', rootWidget)
    if helperRules then
      helperRules:hide()
    end
    if helperTracker then
      helperTracker:setup()
      helperTracker:close()
    end
  end)
  
  if not success then
    safeLog("error", string.format("Helper: init() - Error creating tracker/rules: %s", tostring(err)))
  end

  player = g_game.getLocalPlayer()
  hide()
  if helper and helper.contentPanel then
    healingPanel = helper.contentPanel:getChildById('healingPanel')
    toolsPanel = helper.contentPanel:getChildById('toolsPanel')
    if healingPanel then
      potionButton2 = healingPanel:recursiveGetChildById("potionButton2")
      rmvPotionPercentButton2 = healingPanel:recursiveGetChildById("rmvPotionPercentButton2")
      potionPercentBg2 = healingPanel:recursiveGetChildById("potionPercentBg2")
      addPotionPercentButton2 = healingPanel:recursiveGetChildById("addPotionPercentButton2")
      priority2 = healingPanel:recursiveGetChildById("priority2")
      friendHealingPanel = healingPanel:recursiveGetChildById("friendHealingPanel")
      granSioPanel = healingPanel:recursiveGetChildById("granSioPanel")
      spellButton2 = healingPanel:recursiveGetChildById("spellButton2")
      rmvPercentButton2 = healingPanel:recursiveGetChildById("rmvPercentButton2")
      spellPercentBg2 = healingPanel:recursiveGetChildById("spellPercentBg2")
      addPercentButton2 = healingPanel:recursiveGetChildById("addPercentButton2")
      if helper.contentPanel.healingPanel and helper.contentPanel.healingPanel.healingPanel then
        healPanel = helper.contentPanel.healingPanel.healingPanel
      end
      priorityButton1 = healingPanel:recursiveGetChildById("priority0")
      priorityButton2 = healingPanel:recursiveGetChildById("priority1")
      priorityButton3 = healingPanel:recursiveGetChildById("priority2")
      if toolsPanel then
        equipPanel = toolsPanel:recursiveGetChildById("equipPanel")
      end
      shooterPanel = helper.contentPanel:getChildById('shooterPanel')
      if shooterPanel then
        runePanel = shooterPanel:recursiveGetChildById("runePanel")
        attackSpellPanel3 = shooterPanel:recursiveGetChildById("attackSpellPanel3")
        attackSpellPanel4 = shooterPanel:recursiveGetChildById("attackSpellPanel4")
        spellPanel = shooterPanel:recursiveGetChildById("spellPanel")
        enableButtons = shooterPanel:recursiveGetChildById("enableButtons")
        presetsPanel = shooterPanel:recursiveGetChildById('presetsPanel')
      end
      friendListWidget = healingPanel:recursiveGetChildById('friendList')
      granListWidget = healingPanel:recursiveGetChildById('friendList2')
      helperTabs = helper.contentPanel.optionsTabBar
    end
  end

  botStatus()

  mouseGrabberWidget = g_ui.createWidget('UIWidget')
  mouseGrabberWidget:setVisible(false)
  mouseGrabberWidget:setFocusable(false)

  success, err = pcall(function()
    if modules.game_mainpanel then
      helperButton = modules.game_mainpanel.addToggleButton('helperDialog', tr('Helper'), '/images/ui/helperDialog', toggle, false, 17)
      if helperButton then
        helperButton:setOn(false)
        safeLog("debug", "Helper: init() - Helper button created successfully")
      else
        safeLog("error", "Helper: init() - Failed to create helper button")
      end
    else
      safeLog("error", "Helper: init() - game_mainpanel module not available")
    end
  end)
  
  if not success then
    safeLog("error", string.format("Helper: init() - Error creating button: %s", tostring(err)))
  end

  success, err = pcall(function()
    local attempts = 0
    local maxAttempts = 10
    
    local function tryInitialize()
      attempts = attempts + 1
      -- Verificar diretamente se o player existe (mais confiável que isOnline())
      if g_game and g_game.getLocalPlayer then
        local player = g_game.getLocalPlayer()
        if player then
    --      safeLog("info", "Helper: init() - Player found, calling online()")
          online()
          return true
        else
          safeLog("debug", string.format("Helper: init() - Player not available yet (attempt %d/%d)", attempts, maxAttempts))
          return false
        end
      else
        safeLog("debug", string.format("Helper: init() - g_game.getLocalPlayer not available yet (attempt %d/%d)", attempts, maxAttempts))
        return false
      end
    end
    
    -- Tentar inicializar imediatamente
    if not tryInitialize() then
      -- Se falhou, tentar novamente com intervalos progressivos
      if _G.scheduleEvent then
        safeLog("debug", "Helper: init() - Scheduling initialization retry attempts")
        local function retryAttempt()
          if helperEvents and helperEvents.helperCycleEvent then
            safeLog("info", "Helper: init() - CycleEvent already registered, stopping retries")
            return
          end
          if attempts >= maxAttempts then
            safeLog("debug", string.format("Helper: init() - Max initialization attempts reached (%d), will initialize on game start", maxAttempts))
            return
          end
          if tryInitialize() then
          --  safeLog("info", "Helper: init() - Initialization successful after retry")
          else
            -- Agendar próxima tentativa com intervalo maior
            local delay = math.min(500 + (attempts * 200), 2000)
            _G.scheduleEvent(retryAttempt, delay)
          end
        end
        _G.scheduleEvent(retryAttempt, 300)
      end
    end
  end)
  
  if not success then
    safeLog("error", string.format("Helper: init() - Error checking online status: %s", tostring(err)))
  end
  
--  safeLog("info", "Helper: init() - Initialization complete")

  -- Garantir que as funções de teste sejam globais
  _G.testHealingSystem = testHealingSystem
  _G.forceRegisterCycleEvent = forceRegisterCycleEvent
  _G.forceInitializeHelper = forceInitializeHelper

  -- Função de emergência que pode ser executada diretamente
  _G.emergencyTest = function()
    print("EMERGENCY TEST:")
    print("hotkeyHelperStatus = " .. tostring(hotkeyHelperStatus))
    print("player = " .. tostring(player ~= nil))
    print("cycleEvent = " .. tostring(cycleEvent ~= nil))
    if g_game then
      local p = g_game.getLocalPlayer()
      if p then
        local h = p:getHealth()
        local mh = p:getMaxHealth()
        local pct = (h/mh)*100
        print("Health: " .. h .. "/" .. mh .. " (" .. string.format("%.1f", pct) .. "%)")
      end
    end
  end

  -- Função para testar execução manual de magia
  _G.testSpellCast = function(spellId, percent)
    print("=== TESTE MANUAL DE MAGIA ===")
    spellId = spellId or 1  -- ID padrão se não informado
    percent = percent or 50  -- 50% padrão

    local currentPlayer = getPlayer()
    if not currentPlayer then
      print("ERRO: Player não encontrado!")
      return
    end

    local health = currentPlayer:getHealth()
    local maxHealth = currentPlayer:getMaxHealth()
    local healthPercent = (health / maxHealth) * 100

  --  print(string.format("Vida atual: %d/%d (%.1f%%)", health, maxHealth, healthPercent))
 --   print(string.format("Testando magia ID %d com percent %d%%", spellId, percent))

    if healthPercent <= percent then
--      print("Condição atendida - executando magia...")
      local result = castHealingSpell(spellId)
 --     print("Resultado: " .. tostring(result))
    else
  --    print(string.format("Condição NÃO atendida (%.1f%% > %d%%)", healthPercent, percent))
    end

 --   print("=== FIM TESTE MAGIA ===")
  end

  -- Função para configurar magia rapidamente
  _G.setupTestSpell = function(slot, spellId, percent)
    slot = slot or 1
    spellId = spellId or 1
    percent = percent or 70

    if helperConfig and helperConfig.spells and helperConfig.spells[slot] then
      helperConfig.spells[slot].id = spellId
      helperConfig.spells[slot].percent = percent
      print(string.format("Magia configurada - Slot %d: ID %d, Percent %d%%", slot, spellId, percent))
    else
      print("ERRO: helperConfig.spells não encontrado!")
    end
  end

  -- Função para configurar poção rapidamente
  _G.setupTestPotion = function(slot, potionId, percent, priority)
    slot = slot or 1
    potionId = potionId or 266  -- Small Health Potion
    percent = percent or 80
    priority = priority or 0

    if helperConfig and helperConfig.potions and helperConfig.potions[slot] then
      helperConfig.potions[slot].id = potionId
      helperConfig.potions[slot].percent = percent
      helperConfig.potions[slot].priority = priority
      print(string.format("Poção configurada - Slot %d: ID %d, Percent %d%%, Priority %d", slot, potionId, percent, priority))
    else
      print("ERRO: helperConfig.potions não encontrado!")
    end
  end

  -- Função para testar as verificações de zona de proteção nos sistemas
end

function terminate()
  disconnect(LocalPlayer, {
    onPartyMembersChange = onPartyMembersChange,
	})

  disconnect(g_game, {
		onGameStart = online,
		onGameEnd = offline,
    onSpellCooldown = onSpellCooldown,
    onSpellGroupCooldown = onSpellGroupCooldown,
    onUpdateSpellArea = onUpdateSpellArea,
    onPartyDataUpdate = onPartyDataUpdate,
    onPartyDataClear = onPartyDataClear,
    onMultiUseCooldown = onMultiUseCooldown,
	})

  disconnect(Creature, {
    onAppear = onCreatureAppear,
    onDisappear = onCreatureDisappear,
  })

  if helper then
    g_keyboard.unbindKeyPress('Tab', toggleNextWindow, helper)
    helper:destroy()
    helper = nil
  end
  if helperButton then
    helperButton:destroy()
    helperButton = nil
  end
end

function toggle()
  if helper and helper:isVisible() then
    helper:hide()
    if helperButton then
      helperButton:setOn(false)
    end
  else
    if helper then
      helper:show(true)
      helper:raise()
      helper:focus()
      g_keyboard.bindKeyPress('Tab', toggleNextWindow, helper)
      loadMenu('healingMenu')
      if helperButton then
        helperButton:setOn(true)
      end
    end
  end
end

function hide()
  if helper then
    g_keyboard.unbindKeyPress('Tab', toggleNextWindow, helper)
    helper:hide()
    saveSettings()
    if helperButton then
      helperButton:setOn(false)
    end
  end
end

function show()
  if helper then
    helper:show(true)
    helper:raise()
    helper:focus()
    g_keyboard.bindKeyPress('Tab', toggleNextWindow, helper)
    loadMenu('healingMenu')
    if helperButton then
      helperButton:setOn(true)
    end
  end
end

local helperCycleEventCount = 0

function helperCycleEvent()
  -- Debug: Check if cycle is running (log every 50 cycles to reduce spam)
  helperCycleEventCount = helperCycleEventCount + 1
  if helperCycleEventCount % 10 == 0 then  -- Reduzi para cada 10 chamadas
    safeLog("debug", string.format("Helper: helperCycleEvent - CYCLE EXECUTANDO! Count: %d, helperStatus: %s", helperCycleEventCount, tostring(hotkeyHelperStatus)))
  end
  for eventName, eventData in pairs(eventTable) do
    if not timers[eventName] then
      timers[eventName] = 0
    end
    timers[eventName] = timers[eventName] + helperEvents.helperCycleTimer
    if timers[eventName] >= eventData.interval then
      timers[eventName] = 0
      local func = eventData.action
      if func and type(func) == "function" then
        safeLog("debug", string.format("Helper: helperCycleEvent - EXECUTANDO EVENTO: %s", eventName))
        func()
        safeLog("debug", string.format("Helper: helperCycleEvent - EVENTO %s EXECUTADO", eventName))
      else
        safeLog("debug", string.format("Helper: helperCycleEvent - ERRO: Event %s has no valid action function (type: %s, value: %s)", eventName, type(func), tostring(func)))
      end
    end
  end
end

function online()
--  safeLog("info", "Helper: online() - Function called - INICIANDO SISTEMA DE CURA!")
  local benchmark = g_clock.millis()

  -- Verificar se cycleEvent está disponível ANTES de tentar usar
--  safeLog("debug", string.format("Helper: online() - cycleEvent function available: %s", tostring(cycleEvent ~= nil)))
 -- safeLog("debug", string.format("Helper: online() - type of cycleEvent: %s", type(cycleEvent)))

	player = g_game.getLocalPlayer()
 -- safeLog("info", string.format("Helper: online() - Player retrieved: %s (type: %s)", tostring(player ~= nil), type(player)))

  -- Verificar se player tem os métodos necessários
--  if player then
 --   safeLog("debug", string.format("Helper: online() - Player has getHealth: %s", tostring(player.getHealth ~= nil)))
 --   safeLog("debug", string.format("Helper: online() - Player has getMaxHealth: %s", tostring(player.getMaxHealth ~= nil)))
 -- end

  reset()
  loadSettings()
  loadProfileOptions()
  onLoadHelperData()

  helperConfig.currentLockedTargetId = 0
  
  -- Remover event anterior se existir (caso não tenha sido removido no offline)
  if helperEvents.helperCycleEvent then
  --  safeLog("info", "Helper: online() - Removing existing cycleEvent before reinitializing")
    removeEvent(helperEvents.helperCycleEvent)
    helperEvents.helperCycleEvent = nil
  end

  local success, err = pcall(function()
 --   safeLog("debug", "Helper: online() - Attempting to register cycleEvent...")

    -- Tentar _G.cycleEvent primeiro (mais confiável)
    local cycleEventFunc = _G.cycleEvent
    if not cycleEventFunc then
      cycleEventFunc = cycleEvent
    end

    if cycleEventFunc then
  --    safeLog("debug", string.format("Helper: online() - cycleEvent found, registering with timer: %d", helperEvents.helperCycleTimer))

      -- Tentar registrar o cycleEvent
      local result = cycleEventFunc(helperCycleEvent, helperEvents.helperCycleTimer)
      helperEvents.helperCycleEvent = result

  --    safeLog("debug", string.format("Helper: online() - cycleEvent() returned: %s", tostring(result)))

      if helperEvents.helperCycleEvent then
   --     safeLog("info", "Helper: online() - CycleEvent registered successfully - HELPER DEVE FUNCIONAR AGORA!")
   --     safeLog("info", "Helper: online() - checkHealthHealing assigned to eventTable: " .. tostring(eventTable.checkHealthHealing and eventTable.checkHealthHealing.action ~= nil))

        -- Verificar se o cycle event foi realmente criado
   --     safeLog("debug", string.format("Helper: online() - helperEvents.helperCycleEvent type: %s", type(helperEvents.helperCycleEvent)))
      else
        safeLog("error", "Helper: online() - Failed to register cycleEvent (returned nil)")
      end
    else
      safeLog("error", "Helper: online() - cycleEvent function not available - FUNCAO CYCLEEVENT NAO ENCONTRADA!")

      -- Listar funções disponíveis no escopo global
      safeLog("debug", "Helper: online() - Checking global functions...")
      for k, v in pairs(_G) do
        if type(v) == "function" and string.find(k, "cycle") then
          safeLog("debug", string.format("Helper: online() - Found cycle function: %s", k))
        end
      end
    end
  end)
  
  if not success then
    safeLog("error", string.format("Helper: online() - Error registering cycleEvent: %s", tostring(err)))
  end

  resetPartyPanel()
--  safeLog("info", "Helper loaded in " .. (g_clock.millis() - benchmark) / 1000 .. " seconds.")
end

function offline()
  if presetsPanel then
    local presets = presetsPanel:recursiveGetChildById('presets')
    if presets then
      presets:clear()
    end
  end
  removeEvent(helperEvents.helperCycleEvent)
  helperEvents.helperCycleEvent = nil
  player = nil
  hide()
  helperTracker:close()
  helperTracker:setParent(nil)
end

function onSpellCooldown(spellId, delay)
  spellsCooldown[spellId] = g_clock.millis() + delay
end

function onSpellGroupCooldown(groupId, delay)
  groupsCooldown[groupId] = g_clock.millis() + delay
end

function onMultiUseCooldown(time)
  multiUseExDelay = g_clock.millis() + time
end

function onUpdateSpellArea(energyWaveEnlarged)
  if energyWaveEnlarged then
    SpellInfo.Default["Energy Wave"].area = SpellAreas.AREA_SQUAREWAVE6
  else
    SpellInfo.Default["Energy Wave"].area = SpellAreas.AREA_SQUAREWAVE4
  end
end

function getShooterProfileCount()
  local i = 0
  for n, j in pairs(helperConfig.shooterProfiles) do
    i = i + 1
  end
  return i
end

function getShooterProfile()
  local profile = helperConfig.shooterProfiles[helperConfig.selectedShooterProfile]
  if not profile then
    return defaultShooterProfile
  end
  return profile
end

function loadMenu(menuId)
  if not helper or not helper.contentPanel then
    return
  end

  local buttons = {
    healMenuButton = 'healingMenu',
    toolsMenuButton = 'toolsMenu',
    shooterMenuButton = 'shooterMenu'
  }

  for buttonName, buttonId in pairs(buttons) do
    local button = helper.contentPanel.optionsTabBar:getChildById(buttonId)
    if button then
      button:setChecked(false)
    end
  end

  local selectedButton = helper.contentPanel.optionsTabBar:getChildById(menuId)
  if selectedButton then
    selectedButton:setChecked(true)
  end

  local currentPlayer = g_game.getLocalPlayer()
  if not currentPlayer then
    -- If no player, just show default layout
    if healingPanel and toolsPanel and shooterPanel then
      healingPanel:show(true)
      toolsPanel:hide()
      shooterPanel:hide()
      helper:setSize(tosize("295 240"))
    end
    return
  end

  player = currentPlayer
  local vocationId = translateVocation(currentPlayer:getVocation())

  if menuId == 'healingMenu' then
    healingPanel:show(true)
    toolsPanel:hide()
    shooterPanel:hide()
    if vocationId == 8 then -- Knight
      helper:setSize(tosize("295 278"))
      healPanel:setHeight(160)
      friendHealingPanel:setVisible(false)
      granSioPanel:setVisible(false)
      spellButton2:setVisible(true)
      rmvPercentButton2:setVisible(true)
      spellPercentBg2:setVisible(true)
      addPercentButton2:setVisible(true)
      potionButton2:setVisible(true)
      rmvPotionPercentButton2:setVisible(true)
      potionPercentBg2:setVisible(true)
      addPotionPercentButton2:setVisible(true)
      priority2:setVisible(true)
      priorityButton1:setTooltip("Uses a healing or mana potion when your health or\nmana reaches the defined percentage.")
      priorityButton2:setTooltip("Uses a healing or mana potion when your health or\nmana reaches the defined percentage.")
      priorityButton3:setTooltip("Uses a healing or mana potion when your health or\nmana reaches the defined percentage.")
    elseif vocationId == 7 then -- Paladin
      helper:setSize(tosize("295 278"))
      friendHealingPanel:setVisible(false)
      granSioPanel:setVisible(false)
      healPanel:setHeight(160)
      rmvPercentButton2:setVisible(true)
      spellPercentBg2:setVisible(true)
      addPercentButton2:setVisible(true)
      potionButton2:setVisible(true)
      rmvPotionPercentButton2:setVisible(true)
      potionPercentBg2:setVisible(true)
      addPotionPercentButton2:setVisible(true)
      priority2:setVisible(true)
      priorityButton1:setTooltip("Uses a healing or mana potion when your health or\nmana reaches the defined percentage.\nClick on this button to change the potion priority:\n  - Icon: Blue (Mana Priority)\n  - Icon: Red  (Health Priority)")
      priorityButton2:setTooltip("Uses a healing or mana potion when your health or\nmana reaches the defined percentage.\nClick on this button to change the potion priority:\n  - Icon: Blue (Mana Priority)\n  - Icon: Red  (Health Priority)")
      priorityButton3:setTooltip("Uses a healing or mana potion when your health or\nmana reaches the defined percentage.\nClick on this button to change the potion priority:\n  - Icon: Blue (Mana Priority)\n  - Icon: Red  (Health Priority)")
    elseif vocationId == 5 then -- Sorcerer
      helper:setSize(tosize("295 363"))
      healPanel:setHeight(120)
      friendHealingPanel:setVisible(true)
      granSioPanel:setVisible(false)
      friendHealingPanel.secondPanel.enableSio0:setText('Enable UH')
      friendHealingPanel.secondPanel.enableSio1:setText('Enable UH')
      rmvPercentButton2:setVisible(false)
      spellPercentBg2:setVisible(false)
      addPercentButton2:setVisible(false)
      potionButton2:setVisible(false)
      rmvPotionPercentButton2:setVisible(false)
      potionPercentBg2:setVisible(false)
      addPotionPercentButton2:setVisible(false)
      priority2:setVisible(false)
      priorityButton1:setTooltip("Uses a healing or mana potion when your health or\nmana reaches the defined percentage.")
      priorityButton2:setTooltip("Uses a healing or mana potion when your health or\nmana reaches the defined percentage.")
    elseif vocationId == 6 then -- Druid
      helper:setSize(tosize("295 490"))
      healPanel:setHeight(120)
      friendHealingPanel:setVisible(true)
      granSioPanel:setVisible(true)
      friendHealingPanel.secondPanel.enableSio0:setText('Enable Sio')
      friendHealingPanel.secondPanel.enableSio1:setText('Enable Sio')
      rmvPercentButton2:setVisible(false)
      spellPercentBg2:setVisible(false)
      addPercentButton2:setVisible(false)
      potionButton2:setVisible(false)
      rmvPotionPercentButton2:setVisible(false)
      potionPercentBg2:setVisible(false)
      addPotionPercentButton2:setVisible(false)
      priority2:setVisible(false)
      priorityButton1:setTooltip("Uses a healing or mana potion when your health or\nmana reaches the defined percentage.")
      priorityButton2:setTooltip("Uses a healing or mana potion when your health or\nmana reaches the defined percentage.")
    elseif vocationId == 9 then -- Monk
      helper:setSize(tosize("295 405"))
      healPanel:setHeight(160)
      friendHealingPanel:setVisible(true)
      granSioPanel:setVisible(false)
      friendHealingPanel.secondPanel.enableSio0:setText('Enable Sio')
      friendHealingPanel.secondPanel.enableSio1:setText('Enable Sio')
      rmvPercentButton2:setVisible(true)
      spellPercentBg2:setVisible(true)
      addPercentButton2:setVisible(true)
      potionButton2:setVisible(true)
      rmvPotionPercentButton2:setVisible(true)
      potionPercentBg2:setVisible(true)
      addPotionPercentButton2:setVisible(true)
      priority2:setVisible(true)
      priorityButton1:setTooltip("Uses a healing or mana potion when your health or\nmana reaches the defined percentage.\nClick on this button to change the potion priority:\n  - Icon: Blue (Mana Priority)\n  - Icon: Red  (Health Priority)")
      priorityButton2:setTooltip("Uses a healing or mana potion when your health or\nmana reaches the defined percentage.\nClick on this button to change the potion priority:\n  - Icon: Blue (Mana Priority)\n  - Icon: Red  (Health Priority)")
      priorityButton3:setTooltip("Uses a healing or mana potion when your health or\nmana reaches the defined percentage.\nClick on this button to change the potion priority:\n  - Icon: Blue (Mana Priority)\n  - Icon: Red  (Health Priority)")
    else
      helper:setSize(tosize("295 240"))
      healPanel:setHeight(120)
      friendHealingPanel:setVisible(false)
      granSioPanel:setVisible(false)
      rmvPercentButton2:setVisible(false)
      spellPercentBg2:setVisible(false)
      addPercentButton2:setVisible(false)
      potionButton2:setVisible(false)
      rmvPotionPercentButton2:setVisible(false)
      potionPercentBg2:setVisible(false)
      addPotionPercentButton2:setVisible(false)
      priority2:setVisible(false)
      priorityButton1:setTooltip("Uses a healing or mana potion when your health or\nmana reaches the defined percentage.")
      priorityButton2:setTooltip("Uses a healing or mana potion when your health or\nmana reaches the defined percentage.")
    end
  elseif menuId == 'toolsMenu' then
    helper:setSize(tosize("295 275"))
    healingPanel:hide()
    shooterPanel:hide()
    toolsPanel:show(true)
  elseif menuId == 'shooterMenu' then
    healingPanel:hide()
    toolsPanel:hide()
    shooterPanel:show(true)
    if vocationId == 8 or vocationId == 9 then -- Knight
      helper:setSize(tosize("295 487"))
      runePanel:setVisible(false)
      spellPanel:setHeight(245)
      attackSpellPanel3:setVisible(true)
      attackSpellPanel4:setVisible(true)
      enableButtons:addAnchor(AnchorTop, 'spellPanel', AnchorBottom)
      enableButtons:setMarginTop(5)
    else
      helper:setSize(tosize("295 533"))
      runePanel:setVisible(true)
      spellPanel:setHeight(163)
      attackSpellPanel3:setVisible(false)
      attackSpellPanel4:setVisible(false)
      enableButtons:addAnchor(AnchorTop, 'prev', AnchorBottom)
      enableButtons:setMarginTop(5)
    end
  end
end

function onCreatureAppear(creature)
  if creature:isPlayer() then return end
  if creature:getMasterId() ~= 0 then return end
  if creature:getHealthPercent() <= 0 then return end
  if not spectators[creature:getId()] and creature:isMonster() then
    spectators[creature:getId()] = creature
  end
end

function onCreatureDisappear(creature)
  if spectators[creature:getId()] then
    spectators[creature:getId()] = nil
  end
end

--[[ Events ]]--
function assignTrainingSpell(button, isHaste)
  local radio = UIRadioGroup.create()
  window = g_ui.loadUI('styles/spell', g_ui.getRootWidget())
  if not window then
    return true
  end

  window:show(true)
  window:raise()
  window:focus()
  if g_client and g_client.setInputLockWidget then
    g_client.setInputLockWidget(window)
  end
  hide()

  local windowHeader = isHaste and "Assign Haste Spell" or "Assign Training Spell"
  window:setText(windowHeader)

  local currentPlayer = g_game.getLocalPlayer()
  if not currentPlayer then
    return
  end
  player = currentPlayer
  local playerVocation = translateVocation(player:getVocation())
  local spells = modules.gamelib.SpellInfo['Default']

  for spellName, spellData in pairs(spells) do
    if isHaste and not table.contains(hasteWhiteList[playerVocation], spellData.id) then
      goto continue
    end

    if not isHaste and not (table.contains(Spells.getGroupIds(spellData), 3) or table.contains(Spells.getGroupIds(spellData), 2)) then
      goto continue
    end

    if not isHaste and table.contains(hasteWhiteList[playerVocation], spellData.id) then
      goto continue
    end

    if table.contains(spellData.vocations, playerVocation) and not ignoredTrainingSpells[spellData.id] then
      local widget = g_ui.createWidget('SpellPreview', window.contentPanel.spellList)
      local spellId = getSpellIdFromIcon(spellData.icon)

      radio:addWidget(widget)
      widget:setId(spellData.id)
      widget:setText(spellName.."\n"..spellData.words)
      widget.voc = spellData.vocations
      widget.source = SpelllistSettings['Default'].iconFile
      widget.clip = getSpellImageClip(spellId, 'Default')
      widget.image:setImageSource(widget.source)
      widget.image:setImageClip(widget.clip)

      if spellData.level then
        widget.levelLabel:setVisible(true)
        widget.levelLabel:setText(string.format("Level: %d", spellData.level))
        if player:getLevel() < spellData.level then
          widget.image.gray:setVisible(true)
        end
      end

      local primaryGroup = Spells.getPrimaryGroup(spellData)
      if primaryGroup ~= -1 then
        local offSet = 1
        if primaryGroup == 2 then
          offSet = (23 * (primaryGroup - 1))
        elseif primaryGroup == 3 then
          offSet = (23 * (primaryGroup - 1)) - 1
        end
        widget.imageGroup:setImageClip(offSet .. " 25 20 20")
        widget.imageGroup:setVisible(true)
      end
    end

    ::continue::
  end

  -- Order the spell list
  local widgets = window.contentPanel.spellList:getChildren()
  table.sort(widgets, function(a, b) return a:getText() < b:getText() end)
  for i, widget in ipairs(widgets) do
    window.contentPanel.spellList:moveChildToIndex(widget, i)
  end

  -- Callback of radio
  radio.onSelectionChange = function(widget, selected)
    if selected then
      window.contentPanel.preview:setText(selected:getText())
      window.contentPanel.preview.image:setImageSource(selected.source)
      window.contentPanel.preview.image:setImageClip(selected.clip)
      window.contentPanel.paramLabel:setOn(selected.param)
      window.contentPanel.paramText:setEnabled(selected.param)
      window.contentPanel.paramText:clearText()
      window.contentPanel.spellList:ensureChildVisible(widget)
    end
  end

  if window.contentPanel.spellList:getChildren() then
    radio:selectWidget(window.contentPanel.spellList:getChildren()[1])
  end

  local okFunc = function(destroy)
    local selected = radio:getSelectedWidget()
    if not selected then return end

    local spellIcon = selected.source
    local spellClip = selected.clip
    local spellId = selected:getId()
    local spellName = selected:getText():match("^(.-)\n")
    local spellWords = selected:getText():match("\n(.+)")

    local slotID = tonumber(button:getId():match("%d+"))
    if isHaste then
      helperConfig.haste[1].id = tonumber(spellId)
    else
      helperConfig.training[1].id = tonumber(spellId)
      if helperConfig.training[1].percent == 0 then
        helperConfig.training[1].percent = 100
        updateTrainingPercent('spellTrainingButton0', helperConfig.training[1].percent)
      end
    end

    if g_client and g_client.setInputLockWidget then
      g_client.setInputLockWidget(nil)
    end
    button:setImageSource(spellIcon)
    button:setImageClip(spellClip)
    button:setBorderColorTop("#1b1b1b")
    button:setBorderColorLeft("#1b1b1b")
    button:setBorderColorRight("#757575")
    button:setBorderColorBottom("#757575")
    button:setBorderWidth(1)
    button:setTooltip("Spell: " .. spellName .. "\nWords: " .. spellWords)

    if destroy then
      helper:show(true)
      window:destroy()
    end
  end

  local cancelFunc = function()
    helper:show(true)
    if g_client and g_client.setInputLockWidget then
      g_client.setInputLockWidget(nil)
    end
    window:destroy()
  end

  window.contentPanel.buttonOk.onClick = function() okFunc(true) end
  window.contentPanel.buttonApply.onClick = function() okFunc(false) end
  window.contentPanel.buttonClose.onClick = cancelFunc
  window.contentPanel.onEnter = function() okFunc(true) end
  window.onEscape = cancelFunc
end

local function invalidPresetName(name)
  if helperConfig.shooterProfiles[name] then
    return true, "There is already a preset with this name."
  elseif name:len() == 0 then
    return true, "The name cannot be empty."
  elseif name:len() > 7 then
    return true, "The name cannot be longer than 7 characters."
  elseif name:match("[^%w]") then
    return true, "The name cannot contain special characters or spaces."
  end
  return false
end

function sendRenameOrAddWindow(isRename)
  local radio = UIRadioGroup.create()
	window = g_ui.loadUI('styles/shooterPreset', g_ui.getRootWidget())
  if not window then
    return true
  end

  if isRename then
    window:setText("Rename shooter preset")
    window.contentPanel.target:setText(helperConfig.selectedShooterProfile)
  else
    window:setText("Add shooter preset")
    window.contentPanel.target:setText("")
  end


  local options = nil
  if presetsPanel then
    options = presetsPanel:recursiveGetChildById('presets')
  end

  window:show(true)
  window:raise()
  window:focus()
  window.contentPanel.target:focus()
  if g_client and g_client.setInputLockWidget then
    g_client.setInputLockWidget(window)
  end
  hide()

  local onWrite = function()
    local warning = window.contentPanel.warning
    local block = false
    local text = window.contentPanel.target:getText()
    local invalid, message = invalidPresetName(text)
    if invalid then
      warning:setVisible(true)
      warning:setTooltip(message)
    elseif not invalid and warning:isVisible() then
      warning:setVisible(false)
      warning:setTooltip('')
    end
  end

  local renameConfirm = function()
    local input = window.contentPanel.target:getText()
    if input == helperConfig.selectedShooterProfile then
      return
    end

    if invalidPresetName(input) then
      return
    end

    local oldProfileName = helperConfig.selectedShooterProfile
    local profileConfig = helperConfig.shooterProfiles[oldProfileName]
    if profileConfig then
      helperConfig.shooterProfiles[input] = profileConfig
      helperConfig.selectedShooterProfile = input
      options:addOption(input)
      options:setCurrentOption(input)
      helperConfig.shooterProfiles[oldProfileName] = nil
      options:removeOption(oldProfileName)
    end

    helper:show()
    window:destroy()
  end


  local addConfirm = function()
    local input = window.contentPanel.target:getText()
    for profileName, _ in pairs(helperConfig.shooterProfiles) do
      if profileName == input then
        return -- repeated profile
      end
    end

    if invalidPresetName(input) then
      return
    end

    local default = deepCopy(defaultShooterProfile)
    helperConfig.shooterProfiles[input] = default

    options:addOption(input)
    options:setCurrentOption(input)

    helper:show()
    window:destroy()
  end

  local cancel = function()
    helper:show()
    if g_client and g_client.setInputLockWidget then
      g_client.setInputLockWidget(nil)
    end
		window:destroy()
	end

	window.contentPanel.cancelButton.onClick = cancel
	window.onEscape = cancel
  window.contentPanel.target.onTextChange = function() onWrite() end
  if isRename then
    window.contentPanel.okButton.onClick = function() renameConfirm() end
    window.contentPanel.onEnter = function() renameConfirm() end
  else
    window.contentPanel.okButton.onClick = function() addConfirm() end
    window.contentPanel.onEnter = function() addConfirm() end
  end
end

function assignSpell(button, groupName, groups, tableToAssign)
  -- Clean up any existing window first
  if window and window:getId() == 'assignSpellWindow' then
    window:destroy()
    window = nil
  end
  
	local radio = UIRadioGroup.create()
	window = g_ui.loadUI('styles/spell', g_ui.getRootWidget())
  if not window then
    return true
  end
  
  -- Set window ID for proper cleanup
  window:setId('assignSpellWindow')

	window:show(true)
	window:raise()
	window:focus()
  if g_client and g_client.setInputLockWidget then
    if g_client and g_client.setInputLockWidget then
    g_client.setInputLockWidget(window)
  end
  end
  hide()

	window:setText("Assign " .. groupName .. " Spell")

  local profile = getShooterProfile()
  local currentPlayer = g_game.getLocalPlayer()
  if not currentPlayer then
    return
  end
  player = currentPlayer
	local playerVocation = translateVocation(player:getVocation())
  local spells = modules.gamelib.SpellInfo['Default']

  for spellName, spellData in pairs(spells) do
      local groupIds = Spells.getGroupIds(spellData)
      local function containsAnyGroup(groups, targetGroups)
          for _, group in ipairs(targetGroups) do
              if table.contains(groups, group) then
                  return true
              end
          end
          return false
      end
      if containsAnyGroup(groupIds, groups) and table.contains(spellData.vocations, playerVocation) and not ignoredSpellsIds[spellData.id] then
          if player:getLevel() < spellData.level or not playerHasSpell(player, spellData.id) then
              goto continue
          end
          local widget = g_ui.createWidget('SpellPreview', window.contentPanel.spellList)
          local spellId = getSpellIdFromIcon(spellData.icon)
          radio:addWidget(widget)
          widget:setId(spellData.id)
          widget:setText(spellName.."\n"..spellData.words)
          widget.voc = spellData.vocations
          widget.source = SpelllistSettings['Default'].iconFile
          widget.clip = getSpellImageClip(spellId, 'Default')
          widget.image:setImageSource(widget.source)
          widget.image:setImageClip(widget.clip)

          if spellData.level then
            widget.levelLabel:setVisible(true)
            widget.levelLabel:setText(string.format("Level: %d", spellData.level))
            if player:getLevel() < spellData.level then
              widget.image.gray:setVisible(true)
            end
          end

          local primaryGroup = Spells.getPrimaryGroup(spellData)
          if primaryGroup ~= -1 then
            local offSet = 1
            if primaryGroup == 2 then
              offSet = (23 * (primaryGroup - 1))
            elseif primaryGroup == 3 then
              offSet = (23 * (primaryGroup - 1)) - 1
            end
            widget.imageGroup:setImageClip(offSet .. " 25 20 20")
            widget.imageGroup:setVisible(true)
          end
      end
      ::continue::
  end

	-- sort alphabetically
	local widgets = window.contentPanel.spellList:getChildren()
	table.sort(widgets, function(a, b) return a:getText() < b:getText() end)
	for i, widget in ipairs(widgets) do
		window.contentPanel.spellList:moveChildToIndex(widget, i)
	end

	-- callback
	radio.onSelectionChange = function(widget, selected)
		if selected then
			window.contentPanel.preview:setText(selected:getText())
			window.contentPanel.preview.image:setImageSource(selected.source)
			window.contentPanel.preview.image:setImageClip(selected.clip)
			window.contentPanel.paramLabel:setOn(selected.param)
			window.contentPanel.paramText:setEnabled(selected.param)
			window.contentPanel.paramText:clearText()
			window.contentPanel.spellList:ensureChildVisible(widget)
		end
	end

	if window.contentPanel.spellList:getChildren() then
		radio:selectWidget(window.contentPanel.spellList:getChildren()[1])
	end

  window:recursiveGetChildById('tick'):setChecked(true)
  window:recursiveGetChildById('tick'):setEnabled(false)

  local okFunc = function(destroy, profile)
    local selected = radio:getSelectedWidget()
    if not selected then return end

    local profile = getShooterProfile()
    local spellIcon = selected.source
    local spellClip = selected.clip
    local spellId = selected:getId()
    local spellName = selected:getText():match("^(.-)\n")
    local spellWords = selected:getText():match("\n(.+)")

    local slotID = tonumber(button:getId():match("%d+"))
    if button:getId():find("attackSpellButton") then
      profile.spells[slotID + 1].id = tonumber(spellId)
    else
      tableToAssign[slotID + 1].id = tonumber(spellId)
    end

    if g_client and g_client.setInputLockWidget then
      g_client.setInputLockWidget(nil)
    end
    button:setImageSource(spellIcon)
    button:setImageClip(spellClip)
    button:setBorderColorTop("#1b1b1b")
    button:setBorderColorLeft("#1b1b1b")
    button:setBorderColorRight("#757575")
    button:setBorderColorBottom("#757575")
    button:setBorderWidth(1)
    button:setTooltip("Spell: " .. spellName .. "\nWords: " .. spellWords)

    if button:getId():find("attackSpellButton") then
      local creaturesMin = shooterPanel:recursiveGetChildById("countMinCreature" .. slotID)
      local forceCast = shooterPanel:recursiveGetChildById("conditionSetting" .. slotID)
      local selfCast = shooterPanel:recursiveGetChildById("selfCast" .. slotID)
      local spell = getSpellDataById(tonumber(spellId))
      if spell then
          if table.contains(bothCastTypeSpells, spell.id) then -- divine grenade self cast
            if not selfCast then
              selfCast = g_ui.createWidget('CheckBox', creaturesMin:getParent())
              local style = {
                ["width"] = 12,
                ["anchors.top"] = "countMinCreature" .. slotID .. ".top",
                ["anchors.left"] = "countMinCreature" .. slotID .. ".right",
                ["margin-top"] = 6,
                ["margin-left"] = 5
              }
              selfCast:mergeStyle(style)
              selfCast:setId('selfCast' .. slotID)
              selfCast:setTooltip('Cast on yourself')
              selfCast:setVisible(true)
              selfCast.onCheckChange = function() toggleSelfCast(selfCast:getId():match("%d+"), selfCast:isChecked()) end
            end
          end
          if selfCast and not table.contains(bothCastTypeSpells, spell.id) then
            profile.spells[slotID + 1].selfCast = false
            selfCast:destroy()
          end
          if (spell.range > 0 or not spell.area) and not table.contains(bothCastTypeSpells, spell.id) then
            if not profile.spells[slotID + 1].creatures or profile.spells[slotID + 1].creatures < 1 then
              profile.spells[slotID + 1].creatures = 1
            end
            creaturesMin:setCurrentOption(tostring(profile.spells[slotID + 1].creatures) .. "+")
            creaturesMin:disable()
            if forceCast then
              forceCast:setChecked(profile.spells[slotID + 1].forceCast)
              forceCast:setVisible(true)
            end
          else
            creaturesMin:enable()
            if forceCast then
              forceCast:setChecked(false)
              forceCast:setVisible(false)
              profile.spells[slotID + 1].forceCast = false
            end
          end
        end
      end
    if destroy then
      helper:show()
      if window then
        window:destroy()
        window = nil
      end
    end
  end

	local cancelFunc = function()
    helper:show()
    if g_client and g_client.setInputLockWidget then
      g_client.setInputLockWidget(nil)
    end
    if window then
      window:destroy()
      window = nil
    end
	end

	window.contentPanel.buttonOk.onClick = function() okFunc(true) end
	window.contentPanel.buttonApply.onClick = function() okFunc(false) end
	window.contentPanel.buttonClose.onClick = cancelFunc
	window.contentPanel.onEnter = function() okFunc(true) end
	window.onEscape = cancelFunc
end

function assignRune(button, groupName, groups, tableToAssign)
  if g_mouse and g_mouse.updateGrabber then
    g_mouse.updateGrabber(mouseGrabberWidget, 'target')
  end
  mouseGrabberWidget:grabMouse()
  hide()
  g_mouse.pushCursor('target')
  mouseGrabberWidget.onMouseRelease = function(self, mousePosition, mouseButton)
      onAssignRune(self, mousePosition, mouseButton, button)
  end
end

function onAssignRune(self, mousePosition, mouseButton, button)
  if g_mouse and g_mouse.updateGrabber then
    g_mouse.updateGrabber(mouseGrabberWidget, 'target')
  end
  mouseGrabberWidget:ungrabMouse()
  helper:show()
  g_mouse.popCursor('target')
  mouseGrabberWidget.onMouseRelease = nil

  local rootWidget = g_ui.getRootWidget()
  if not rootWidget then
    return true
  end

  local clickedWidget = rootWidget:recursiveGetChildByPos(mousePosition, false)
  if not clickedWidget then
    return true
  end

  local runeId = 0
  if clickedWidget:getClassName() == 'UIItem' and not clickedWidget:isVirtual() then
    local item = clickedWidget:getItem()
    if item then
      runeId = item:getId()
    end
  elseif clickedWidget:getClassName() == 'UIGameMap' then
    local tile = clickedWidget:getTile(mousePosition)
    if tile then
      local topUseThing = tile:getTopUseThing()
      if topUseThing then
        runeId = topUseThing:getId()
      end
    end
  end

  local rune = Spells.getRuneSpellByItem(runeId)
  if rune and rune.group == 1 then
    if rune.vocations and not table.contains(rune.vocations, translateVocation(player:getVocation())) then
      modules.game_textmessage.displayFailureMessage(tr('Your vocation can not use this rune.'))
      return true
    end
    updateRuneButton(button, runeId, rune)
  else
    modules.game_textmessage.displayFailureMessage(tr('Invalid rune!'))
  end
end

function updateRuneButton(button, runeId, rune)
  button:setImageSource('/images/ui/item')

  if not button:getChildById('runeItem') then
    local itemWidget = g_ui.createWidget('RuneItem', button)
    itemWidget:setId('runeItem')
  end

  local itemWidget = button:getChildById('runeItem')
  itemWidget:setItemId(runeId)

  button:setTooltip(string.format(rune.name .. " %s", rune.area and "(Area Target)" or "(Single Target)"))

  local profile = getShooterProfile()
  local buttonId = button:getId()
  local slotID = tonumber(buttonId:match("%d+"))
  local creaturesMin = runePanel:recursiveGetChildById("countMinCreature" .. slotID)
  local forceCast = runePanel:recursiveGetChildById("conditionSetting" .. slotID)

  profile.runes[slotID + 1].id = runeId
  profile.runes[slotID + 1].creatures = profile.runes[slotID + 1].creatures

  local runeSpell = Spells.getRuneSpellByItem(runeId)
  if runeSpell and not runeSpell.area then
    creaturesMin:setCurrentOption("1+")
    creaturesMin:disable()
    forceCast:setChecked(profile.runes[slotID + 1].forceCast)
    forceCast:setVisible(true)
    profile.runes[slotID + 1].creatures = 1
    return
  end
  profile.runes[slotID + 1].forceCast = false
  forceCast:setChecked(false)
  forceCast:setVisible(false)
  creaturesMin:enable()
end

function getPotionInfoById(itemId)
  for _, potion in pairs(potionWhitelist) do
      if itemId == potion.id then
          return true, potion.name
      end
  end
  return false, "Unknown Potion"
end

function isHealthPotion(potionId)
  for _, potion in ipairs(potionWhitelist) do
    if potion.id == potionId and potion.type == "health" then
      return true
    end
  end
  return false
end

function isManaPotion(potionId)
  for _, potion in ipairs(potionWhitelist) do
    if potion.id == potionId and potion.type == "mana" then
      return true
    end
  end
  return false
end

function usePotion(potionId)
  local player = g_game.getLocalPlayer()
  if not player then
    return
  end

  local cooldown = getSpellCooldown(potionConfig.id)
  if cooldown > g_clock.millis() then
    return true
  end

  if multiUseExDelay > g_clock.millis() then
    return true
  end

  helperConfig.magicShooterOnHold = true

  local currentPlayer = getPlayer()
  if not currentPlayer then
    return
  end
  local potionCount = currentPlayer:getInventoryCount(potionId)
  if potionCount > 0 then
    g_game.doThing(false)
    g_game.useInventoryItemWith(potionId, player, 0, true)
    g_game.doThing(true)
    spellsCooldown[potionConfig.id] = g_clock.millis() + potionConfig.exhaustion
  end

  helperConfig.magicShooterOnHold = false
end

function assignPotionEvent(button)
  if g_mouse and g_mouse.updateGrabber then
    if g_mouse and g_mouse.updateGrabber then
    g_mouse.updateGrabber(mouseGrabberWidget, 'target')
  end
  end
  mouseGrabberWidget:grabMouse()
  hide()
  g_mouse.pushCursor('target')
  mouseGrabberWidget.onMouseRelease = function(self, mousePosition, mouseButton)
      onAssignPotion(self, mousePosition, mouseButton, button)
  end
end

function onAssignPotion(self, mousePosition, mouseButton, button)
  if g_mouse and g_mouse.updateGrabber then
    if g_mouse and g_mouse.updateGrabber then
    g_mouse.updateGrabber(mouseGrabberWidget, 'target')
  end
  end
  mouseGrabberWidget:ungrabMouse()
  helper:show()
  g_mouse.popCursor('target')
  mouseGrabberWidget.onMouseRelease = nil

  local rootWidget = g_ui.getRootWidget()
  if not rootWidget then
    return true
  end

  local clickedWidget = rootWidget:recursiveGetChildByPos(mousePosition, false)
  if not clickedWidget then
    return true
  end

  local potionId = 0
  if clickedWidget:getClassName() == 'UIItem' and not clickedWidget:isVirtual() then
    local item = clickedWidget:getItem()
    if item then
      potionId = item:getId()
    end
  elseif clickedWidget:getClassName() == 'UIGameMap' then
    local tile = clickedWidget:getTile(mousePosition)
    if tile then
      local topUseThing = tile:getTopUseThing()
      if topUseThing then
        potionId = topUseThing:getId()
      end
    end
  end

  local isPotion, potionName = getPotionInfoById(potionId)
  if isPotion then
    updatePotionButton(button, potionId, potionName)
  else
    modules.game_textmessage.displayFailureMessage(tr('Invalid potion!'))
  end
end

function updatePotionButton(button, potionId, potionName)
  button:setImageSource('/images/ui/item')

  if not button:getChildById('potionItem') then
    local itemWidget = g_ui.createWidget('PotionItem', button)
    itemWidget:setId('potionItem')
  end

  local itemWidget = button:getChildById('potionItem')
  itemWidget:setItemId(potionId)
  itemWidget:setTooltip(potionName)

  local buttonId = button:getId()
  local slotID = tonumber(buttonId:match("%d+"))
  helperConfig.potions[slotID + 1].id = potionId
  helperConfig.potions[slotID + 1].percent = helperConfig.potions[slotID + 1].percent

  if potionId == 7642 or potionId == 23374 then
    helperConfig.potions[slotID + 1].priority = 1
    local priorityButton = healingPanel:recursiveGetChildById("priority" .. slotID)
    priorityButton:setImageSource("/images/skin/show-gui-help-red")
    priorityButton:setTooltip("This potion is healing health...")
    priorityButton:setActionId(1)
  end
end

function updateButton(button)
  local profile = getShooterProfile()
  local index = tonumber(button:getId():match("%d+"))
  button.onMousePress = function(self, mousePos, mouseButton)
    if mouseButton == MouseRightButton then
      local menu = g_ui.createWidget('PopupMenu')
      menu:setGameMenu(true)
      local buttonId = button:getId()
      if buttonId:find("runeShooterButton") then
        if profile.runes[index + 1].id > 0 then
          menu:addOption(tr('Edit Rune'), function() assignRune(button) end)
          menu:addOption(tr('Remove'), function() removeAction("rune", button) end)
        else
          menu:addOption(tr('Assign Rune'), function() assignRune(button) end)
        end
      elseif buttonId:find("attackSpellButton") then
        if profile.spells[index + 1].id > 0 then
          menu:addOption(tr('Edit Spell'), function() assignSpell(button, "Aggressive", {1, 4, 8}, profile.spells) end)
          menu:addOption(tr('Remove'), function() removeAction("shooter", button) end)
        else
          menu:addOption(tr('Assign Spell'), function() assignSpell(button, "Aggressive", {1, 4, 8}, profile.spells) end)
        end
      elseif buttonId:find("spellButton") then
        if helperConfig.spells[index + 1].id > 0 then
          menu:addOption(tr('Edit Spell'), function() assignSpell(button, "Healing", {2}, helperConfig.spells) end)
          menu:addOption(tr('Remove'), function() removeAction("spell", button) end)
        else
          menu:addOption(tr('Assign Spell'), function() assignSpell(button, "Healing", {2}, helperConfig.spells) end)
        end
      elseif buttonId:find("potionButton") then
        if helperConfig.potions[index + 1].id > 0 then
          menu:addOption(tr('Edit Potion'), function() assignPotionEvent(button) end)
          menu:addOption(tr('Remove'), function() removeAction("potion", button) end)
        else
          menu:addOption(tr('Assign Potion'), function() assignPotionEvent(button) end)
        end
      elseif buttonId:find("spellTrainingButton") then
        if helperConfig.training[index + 1].id > 0 then
          menu:addOption(tr('Edit Training Spell'), function() assignTrainingSpell(button) end)
          menu:addOption(tr('Remove'), function() removeAction("training", button) end)
        else
          menu:addOption(tr('Assign Training Spell'), function() assignTrainingSpell(button) end)
        end
      elseif buttonId:find("hasteButton") then
         if helperConfig.haste[index + 1].id > 0 then
          menu:addOption(tr('Edit Haste Spell'), function() assignTrainingSpell(button, true) end)
          menu:addOption(tr('Remove'), function() removeAction("haste", button) end)
        else
          menu:addOption(tr('Assign Haste Spell'), function() assignTrainingSpell(button, true) end)
        end


      elseif buttonId:find("autoTrainingItem") then
        if not button.potionItem or button.potionItem:getItemId() == 0 then
          menu:addOption(tr('Select exercise weapon'), function() assignExerciseEvent(button) end)
        else
          menu:addOption(tr('Remove'), function() removeAction("exercise", button) end)
        end
      end

      menu:display(mousePos)
      return true
    end
    return false
  end
end

function onPartyDataClear()
  if not friendListWidget or not granListWidget then
    return
  end

  friendListWidget:destroyChildren()
  granListWidget:destroyChildren()
  resetPartyPanel()
end

function onPartyDataUpdate(members)
  if table.empty(members) or not friendListWidget or not granListWidget then
    return
  end

  if (#members - 1) ~= friendListWidget:getChildCount() then
    friendListWidget:destroyChildren()
    granListWidget:destroyChildren()
    resetPartyPanel()

    for _, member in pairs(members) do
      local creature = g_map.getCreatureById(member.id)
      if creature and not creature:isLocalPlayer() and creature:isPlayer() and creature:isPartyMember() then
        local widget_1 = g_ui.createWidget("PlayerName", friendListWidget)
        local widget_2 = g_ui.createWidget("PlayerName", granListWidget)
        widget_1:setText(member.name)
        widget_2:setText(member.name)
        widget_1.creature = creature
        widget_2.creature = creature
      end
    end
  end
end

function resetPartyPanel()
  local sioPanel = healingPanel:recursiveGetChildById('friendHealingPanel')
  local granSioPanel = healingPanel:recursiveGetChildById('granSioPanel')

  local player = g_game.getLocalPlayer()
  if not player or not player:isPartyMember() then
    friendListWidget:destroyChildren()
    granListWidget:destroyChildren()
    for i = 0, 1 do
      sioPanel:recursiveGetChildById("healPercent" .. i):setEnabled(false)
      granSioPanel:recursiveGetChildById("healPercent" .. i):setEnabled(false)

      sioPanel:recursiveGetChildById("enableSio" .. i):setEnabled(false)
      granSioPanel:recursiveGetChildById("enableSio" .. i):setChecked(false)

      sioPanel:recursiveGetChildById("friendButton" .. i):setCreature(nil)
      granSioPanel:recursiveGetChildById("friendButton" .. i):setCreature(nil)

      sioPanel:recursiveGetChildById("friendButton" .. i):setImageSource("/images/store/bazaar-add-item")
      granSioPanel:recursiveGetChildById("friendButton" .. i):setImageSource("/images/store/bazaar-add-item")

      helperConfig.friendhealing[i + 1].name = ""
      helperConfig.friendhealing[i + 1].percent = 0
      helperConfig.friendhealing[i + 1].enabled = false

      helperConfig.gransiohealing[i + 1].name = ""
      helperConfig.gransiohealing[i + 1].percent = 0
      helperConfig.gransiohealing[i + 1].enabled = false
    end
    return
  end

  if not sioPanel:recursiveGetChildById("healPercent0"):isEnabled() then
    for i = 0, 1 do
      sioPanel:recursiveGetChildById("healPercent" .. i):setEnabled(true)
      sioPanel:recursiveGetChildById("enableSio" .. i):setEnabled(true)
      sioPanel:recursiveGetChildById("friendButton" .. i):setEnabled(true)
    end
  end

  if not granSioPanel:recursiveGetChildById("healPercent0"):isEnabled() then
    for i = 0, 1 do
      granSioPanel:recursiveGetChildById("healPercent" .. i):setEnabled(true)
      granSioPanel:recursiveGetChildById("enableSio" .. i):setEnabled(true)
      granSioPanel:recursiveGetChildById("friendButton" .. i):setEnabled(true)
    end
  end
end

function onAddPartyMember(self)
  local slotIndex = tonumber(self:getId():match("%d+"))
  local panel = healingPanel:recursiveGetChildById('secondPanel')
  local selectedWidget = friendListWidget:getFocusedChild()
  if not selectedWidget then
    return true
  end

  local sioPanel = healingPanel:recursiveGetChildById('friendHealingPanel')
  local enabled = sioPanel:recursiveGetChildById("enableSio" .. slotIndex) and sioPanel:recursiveGetChildById("enableSio" .. slotIndex):isChecked()
  local percent = panel:recursiveGetChildById("healPercent" .. slotIndex):getCurrentOption().text
  if self:getImageSource() == "/images/store/clean-button" then
    helperConfig.friendhealing[slotIndex + 1].name = ""
    helperConfig.friendhealing[slotIndex + 1].percent = 0
    helperConfig.friendhealing[slotIndex + 1].enabled = false
    self:setCreature(nil)
    self:setImageSource("/images/store/bazaar-add-item")
    manageSioSettings(false, slotIndex)
  else
    if (selectedWidget:getText() == helperConfig.friendhealing[1].name) or (selectedWidget:getText() == helperConfig.friendhealing[2].name) then
      return true
    end
    helperConfig.friendhealing[slotIndex + 1].name = selectedWidget:getText()
    helperConfig.friendhealing[slotIndex + 1].percent = tonumber(percent:match("%d+"))
    helperConfig.friendhealing[slotIndex + 1].enabled = enabled
    self:setCreature(selectedWidget.creature)
    self:setImageSource("/images/store/clean-button")
    manageSioSettings(true, slotIndex)
  end
end

function onAddPartyGranSioMember(self)
  local slotIndex = tonumber(self:getId():match("%d+"))
  local panel = healingPanel:recursiveGetChildById('secondPanel2')
  local selectedWidget = granListWidget:getFocusedChild()
  if not selectedWidget then
    return true
  end

  local sioPanel = healingPanel:recursiveGetChildById('granSioPanel')
  local enabled = sioPanel:recursiveGetChildById("enableSio" .. slotIndex) and sioPanel:recursiveGetChildById("enableSio" .. slotIndex):isChecked()
  local percent = panel:recursiveGetChildById("healPercent" .. slotIndex):getCurrentOption().text
  if self:getImageSource() == "/images/store/clean-button" then
    helperConfig.gransiohealing[slotIndex + 1].name = ""
    helperConfig.gransiohealing[slotIndex + 1].percent = 0
    helperConfig.gransiohealing[slotIndex + 1].enabled = false
    self:setCreature(nil)
    self:setImageSource("/images/store/bazaar-add-item")
    manageGranSioSettings(false, slotIndex)
  else
    if (selectedWidget:getText() == helperConfig.gransiohealing[1].name) or (selectedWidget:getText() == helperConfig.gransiohealing[2].name) then
      return true
    end
    helperConfig.gransiohealing[slotIndex + 1].name = selectedWidget:getText()
    helperConfig.gransiohealing[slotIndex + 1].percent = tonumber(percent:match("%d+"))
    helperConfig.gransiohealing[slotIndex + 1].enabled = enabled
    self:setCreature(selectedWidget.creature)
    self:setImageSource("/images/store/clean-button")
    manageGranSioSettings(true, slotIndex)
  end
end

function manageSioSettings(activate, index)
  local sioPanel = healingPanel:recursiveGetChildById('friendHealingPanel')
  sioPanel:recursiveGetChildById("healPercent" .. index):setEnabled(activate)
  sioPanel:recursiveGetChildById("enableSio" .. index):setEnabled(activate)
  if not activate then
    sioPanel:recursiveGetChildById("enableSio" .. index):setChecked(false)
  end
end

function manageGranSioSettings(activate, index)
  local granSioPanel = healingPanel:recursiveGetChildById('granSioPanel')
  granSioPanel:recursiveGetChildById("healPercent" .. index):setEnabled(activate)
  granSioPanel:recursiveGetChildById("enableSio" .. index):setEnabled(activate)
  if not activate then
    granSioPanel:recursiveGetChildById("enableSio" .. index):setChecked(false)
  end
end

function onEnableSio(button, checked)
  local slotIndex = tonumber(button:getId():match("%d+"))
  helperConfig.friendhealing[slotIndex + 1].enabled = checked
end

function onEnableGranSio(button, checked)
  local slotIndex = tonumber(button:getId():match("%d+"))
  helperConfig.gransiohealing[slotIndex + 1].enabled = checked
end

function onEnableTraining(buttonId, checked)
  if helperConfig.haste[1].enabled then
    toolsPanel:recursiveGetChildById("enableHaste0"):setChecked(false)
  end

  local slotIndex = tonumber(buttonId:match("%d+"))
  helperConfig.training[slotIndex + 1].enabled = checked
end

-- Bot functions
function updateHealingPercent(buttonId, newPercent)
  local buttonIndex = string.match(buttonId, "%d+")
  if not buttonIndex then
    return
  end

  buttonIndex = tonumber(buttonIndex)
  local config = helperConfig.spells[buttonIndex + 1]
  if string.find(buttonId, "add") then
    if config.percent + 1 > 99 then
      healingPanel:recursiveGetChildById("addPercentButton" .. buttonIndex):setEnabled(false)
      return
    end

    healingPanel:recursiveGetChildById("rmvPercentButton" .. buttonIndex):setEnabled(true)
    config.percent = config.percent + 1
    local label = healingPanel:recursiveGetChildById("spellPercentLabel" .. buttonIndex)
    label:setText(config.percent .. "%")
  elseif string.find(buttonId, "rmv") then
    if config.percent - 1 < 1 then
      healingPanel:recursiveGetChildById("rmvPercentButton" .. buttonIndex):setEnabled(false)
      return
    end

    healingPanel:recursiveGetChildById("addPercentButton" .. buttonIndex):setEnabled(true)
    config.percent = config.percent - 1
    local label = healingPanel:recursiveGetChildById("spellPercentLabel" .. buttonIndex)
    label:setText(config.percent .. "%")
  end

  cachedSpells = table.copy(helperConfig.spells)
  table.sort(cachedSpells, function(a, b) return a.percent < b.percent end)
end

function updateMagicShooterPercent(buttonId, newPercent)
  local buttonIndex = string.match(buttonId, "%d+")
  if not buttonIndex then
    return
  end

  local profile = getShooterProfile()

  buttonIndex = tonumber(buttonIndex)
  local config = profile.spells[buttonIndex + 1]
  local label = shooterPanel:recursiveGetChildById("spellPercentLabel" .. buttonIndex)

  if string.find(buttonId, "add") then
    if config.percent >= 99 then
      shooterPanel:recursiveGetChildById("addPercentButton" .. buttonIndex):setEnabled(false)
      return
    end

    config.percent = config.percent + 1
    label:setText(config.percent .. "%")

    if config.percent >= 99 then
      shooterPanel:recursiveGetChildById("addPercentButton" .. buttonIndex):setEnabled(false)
    end

    shooterPanel:recursiveGetChildById("rmvPercentButton" .. buttonIndex):setEnabled(true)

  elseif string.find(buttonId, "rmv") then
    if config.percent <= 1 then
      shooterPanel:recursiveGetChildById("rmvPercentButton" .. buttonIndex):setEnabled(false)
      return
    end

    config.percent = config.percent - 1
    label:setText(config.percent .. "%")

    if config.percent <= 1 then
      shooterPanel:recursiveGetChildById("rmvPercentButton" .. buttonIndex):setEnabled(false)
    end

    shooterPanel:recursiveGetChildById("addPercentButton" .. buttonIndex):setEnabled(true)
  end
end


function updateRuneShooterCreatures(name, index, creatures)
  local profile = getShooterProfile()
  profile.runes[index + 1].creatures = tonumber(creatures)
end

function updateRuneShooterPriority(index, priority)
  local profile = getShooterProfile()
  profile.runes[index + 1].priority = tonumber(priority)
end

function updatePotionPercent(buttonId, newPercent)
  local buttonIndex = string.match(buttonId, "%d+")
  if not buttonIndex then
    return
  end

  buttonIndex = tonumber(buttonIndex)
  local config = helperConfig.potions[buttonIndex + 1]
  if string.find(buttonId, "add") then
    if config.percent + 1 > 99 then
      healingPanel:recursiveGetChildById("addPotionPercentButton" .. buttonIndex):setEnabled(false)
      return
    end

    healingPanel:recursiveGetChildById("rmvPotionPercentButton" .. buttonIndex):setEnabled(true)
    config.percent = config.percent + 1
    local label = healingPanel:recursiveGetChildById("potionPercentLabel" .. buttonIndex)
    label:setText(config.percent .. "%")
  elseif string.find(buttonId, "rmv") then
    if config.percent - 1 < 1 then
      healingPanel:recursiveGetChildById("rmvPotionPercentButton" .. buttonIndex):setEnabled(false)
      return
    end

    healingPanel:recursiveGetChildById("addPotionPercentButton" .. buttonIndex):setEnabled(true)
    config.percent = config.percent - 1
    local label = healingPanel:recursiveGetChildById("potionPercentLabel" .. buttonIndex)
    label:setText(config.percent .. "%")
  end
end

function updateFriendHealingPercent(index, newPercent)
  helperConfig.friendhealing[index + 1].percent = tonumber(newPercent)
end

function updateGranSioPercent(index, newPercent)
  helperConfig.gransiohealing[index + 1].percent = tonumber(newPercent)
end

function castHealingSpell(spellId)
  safeLog("debug", string.format("Helper: castHealingSpell - Attempting to cast spell ID %d", spellId))

  -- Try to get spell by ID first (spell.id), then by clientId
  local spell = getSpellDataById(spellId)

  -- If not found by ID, try by clientId
  if not spell then
    safeLog("debug", string.format("Helper: castHealingSpell - Spell not found by ID %d, trying clientId", spellId))
    spell = getSpellByClientId(tonumber(spellId))
  end

  if not spell then
    safeLog("debug", string.format("Helper: castHealingSpell - ERRO: Spell ID %d not found in spell database!", spellId))
    safeLog("debug", string.format("Helper: castHealingSpell - Checking SpellInfo.Default availability: %s", tostring(SpellInfo and SpellInfo.Default)))
    if SpellInfo and SpellInfo.Default then
      safeLog("debug", string.format("Helper: castHealingSpell - SpellInfo.Default has %d spells", table.size(SpellInfo.Default)))
    end
    return false
  end
  
  safeLog("debug", string.format("Helper: castHealingSpell - Found spell: id=%s, words=%s", tostring(spell.id), tostring(spell.words)))
  
  -- Check if spell has words (required for casting)
  if not spell.words or spell.words == "" then
    safeLog("debug", string.format("Helper: castHealingSpell - Spell ID %d has no words", spellId))
    return false
  end

  if (isSpellOnCooldown(spell)) then
    safeLog("debug", string.format("Helper: castHealingSpell - Spell ID %d is on cooldown", spellId))
    return false
  end

  if spell.soul and spell.soul > 0 then
    local currentPlayer = getPlayer()
    if not currentPlayer then
      safeLog("debug", "Helper: castHealingSpell - No player found for soul check")
      return false
    end
    local playerSoul = currentPlayer:getSoul()
    if playerSoul < spell.soul then
      safeLog("debug", string.format("Helper: castHealingSpell - Not enough soul: %d < %d", playerSoul, spell.soul))
      return false
    end

    if spell.source and not hasItemInBackpack(spell.source) then
      safeLog("debug", string.format("Helper: castHealingSpell - Missing source item: %d", spell.source))
      return false
    end
  end

  -- Execute the spell
  safeLog("debug", string.format("Helper: castHealingSpell - EXECUTANDO magia ID %d with words: '%s'", spellId, spell.words))
  g_game.doThing(false)
  g_game.talk(spell.words, true)
  g_game.doThing(true)
  safeLog("debug", string.format("Helper: castHealingSpell - MAGIA EXECUTADA com sucesso: ID %d, words: '%s'", spellId, spell.words))
  return true
end

local checkHealthHealingCallCount = 0

function checkHealthHealing()
  -- Log apenas a cada 5 chamadas para reduzir spam
  checkHealthHealingCallCount = checkHealthHealingCallCount + 1

  if checkHealthHealingCallCount % 5 == 0 then  -- Mais frequente
    safeLog("debug", string.format("Helper: checkHealthHealing - Function called (count: %d, status: %s)", checkHealthHealingCallCount, tostring(hotkeyHelperStatus)))
    -- Mostrar configurações dos spells
    safeLog("debug", "Helper: checkHealthHealing - Current spell configs:")
    for i, spell in ipairs(helperConfig.spells) do
      safeLog("debug", string.format("  Slot %d: id=%s, percent=%s", i, tostring(spell.id), tostring(spell.percent)))
    end
  end

  if not hotkeyHelperStatus then
    if checkHealthHealingCallCount % 10 == 0 then
      safeLog("debug", "Helper: checkHealthHealing - hotkeyHelperStatus is false - HABILITE O HELPER COM A TECLA PAUSE BREAK!")
    end
    return false
  end

  -- Verificar se helperConfig.spells existe
  if not helperConfig or not helperConfig.spells then
    if checkHealthHealingCallCount % 10 == 0 then
      safeLog("debug", "Helper: checkHealthHealing - ERRO: helperConfig.spells não existe!")
    end
    return false
  end

  local currentPlayer = getPlayer()
  if not currentPlayer then
    if checkHealthHealingCallCount % 10 == 0 then
      safeLog("debug", "Helper: checkHealthHealing - ERRO: getPlayer() retornou nil!")
      safeLog("debug", string.format("Helper: checkHealthHealing - g_game.getLocalPlayer(): %s", tostring(g_game and g_game.getLocalPlayer())))
      safeLog("debug", string.format("Helper: checkHealthHealing - g_game existe: %s", tostring(g_game ~= nil)))
    end
    return false
  end

  -- Verificar se o player tem os métodos necessários
  if not currentPlayer.getHealth or not currentPlayer.getMaxHealth then
    if checkHealthHealingCallCount % 10 == 0 then
      safeLog("debug", "Helper: checkHealthHealing - ERRO: Player não tem métodos getHealth/getMaxHealth!")
      safeLog("debug", string.format("Helper: checkHealthHealing - Player type: %s", type(currentPlayer)))
      safeLog("debug", string.format("Helper: checkHealthHealing - Player methods: %s", table.concat(table.keys(currentPlayer), ", ")))
    end
    return false
  end

  -- Tentar obter vida com tratamento de erro
  local health, maxHealth
  local success, err = pcall(function()
    health = currentPlayer:getHealth()
    maxHealth = currentPlayer:getMaxHealth()
  end)

  if not success then
    if checkHealthHealingCallCount % 10 == 0 then
      safeLog("debug", string.format("Helper: checkHealthHealing - ERRO ao obter vida: %s", err))
      safeLog("debug", string.format("Helper: checkHealthHealing - Player válido: %s", tostring(currentPlayer ~= nil)))
    end
    return false
  end

  -- Verificar valores obtidos
  if not health or not maxHealth then
    if checkHealthHealingCallCount % 10 == 0 then
      safeLog("debug", string.format("Helper: checkHealthHealing - Vida ou maxHealth nil: health=%s, maxHealth=%s", tostring(health), tostring(maxHealth)))
    end
    return false
  end

  if maxHealth == 0 then
    if checkHealthHealingCallCount % 10 == 0 then
      safeLog("debug", "Helper: checkHealthHealing - maxHealth é 0 - personagem pode estar morto ou não carregado")
    end
    return false
  end
  -- Calcular porcentagem com verificações
  if type(health) ~= "number" or type(maxHealth) ~= "number" then
    if checkHealthHealingCallCount % 10 == 0 then
      safeLog("debug", string.format("Helper: checkHealthHealing - ERRO: Valores não são números - health type: %s (%s), maxHealth type: %s (%s)",
        type(health), tostring(health), type(maxHealth), tostring(maxHealth)))
    end
    return false
  end

  if health < 0 or maxHealth < 0 then
    if checkHealthHealingCallCount % 10 == 0 then
      safeLog("debug", string.format("Helper: checkHealthHealing - ERRO: Valores negativos - health: %s, maxHealth: %s", tostring(health), tostring(maxHealth)))
    end
    return false
  end

  local healthPercent = (health / maxHealth) * 100
  safeLog("debug", string.format("Helper: checkHealthHealing - Health: %d/%d (%.2f%%)", health, maxHealth, healthPercent))

  -- Verificar se há algum spell ou poção válido configurado
  local hasValidSpell = false
  for _, spell in ipairs(helperConfig.spells) do
    if spell.id and spell.id > 0 and spell.percent and spell.percent > 0 then
      hasValidSpell = true
      break
    end
  end

  local hasValidPotion = false
  for _, potion in ipairs(helperConfig.potions) do
    if potion.id and potion.id > 0 and potion.percent and potion.percent > 0 then
      hasValidPotion = true
      break
    end
  end

  if not hasValidSpell and not hasValidPotion then
    if checkHealthHealingCallCount % 20 == 0 then
      safeLog("debug", "Helper: checkHealthHealing - NENHUMA MAGIA OU POCAO VALIDA CONFIGURADA! Configure pelo menos uma magia ou poção de cura.")
      for i, spell in ipairs(helperConfig.spells) do
        safeLog("debug", string.format("  Spell %d: id=%s, percent=%s", i, tostring(spell.id), tostring(spell.percent)))
      end
      for i, potion in ipairs(helperConfig.potions) do
        safeLog("debug", string.format("  Potion %d: id=%s, percent=%s, priority=%s", i, tostring(potion.id), tostring(potion.percent), tostring(potion.priority)))
      end
    end
    return false
  end

  -- Debug: mostrar configuração dos spells
  if checkHealthHealingCallCount % 50 == 0 then
    safeLog("debug", "Helper: checkHealthHealing - Spell configurations:")
    for i, spell in ipairs(helperConfig.spells) do
      safeLog("debug", string.format("  Spell %d: id=%s, percent=%s", i, tostring(spell.id), tostring(spell.percent)))
    end
  end

  local prioritizedPotions = {}
  for _, potion in pairs(helperConfig.potions) do
    if potion.id and potion.id > 0 and potion.percent and potion.percent > 0 then
      table.insert(prioritizedPotions, potion)
    end
  end
  table.sort(prioritizedPotions, function(a, b)
    if a.percent == b.percent then
      return a.priority < b.priority
    else
      return a.percent < b.percent
    end
  end)

  safeLog("debug", string.format("Helper: checkHealthHealing - Found %d prioritized potions", #prioritizedPotions))
  
  for _, potion in ipairs(prioritizedPotions) do
    if hasItemInBackpack(potion.id) and isHealthPotion(potion.id) and healthPercent <= potion.percent then
      safeLog("debug", string.format("Helper: checkHealthHealing - POCAO ENCONTRADA! Tentando usar poção ID %d (vida %.2f%% <= %.2f%%)", potion.id, healthPercent, potion.percent))
      local result = usePotion(potion.id)
      safeLog("debug", string.format("Helper: checkHealthHealing - Resultado uso da poção ID %d: %s", potion.id, tostring(result)))
      break -- Use only one potion at a time
    else
      -- Debug por que não usou a poção
      if not hasItemInBackpack(potion.id) then
        safeLog("debug", string.format("Helper: checkHealthHealing - Poção ID %d não encontrada no inventário", potion.id))
      elseif not isHealthPotion(potion.id) then
        safeLog("debug", string.format("Helper: checkHealthHealing - Poção ID %d não é poção de vida", potion.id))
      elseif healthPercent > potion.percent then
        safeLog("debug", string.format("Helper: checkHealthHealing - Vida %.2f%% está acima da configuração %.2f%%", healthPercent, potion.percent))
      end
    end
  end

  local prioritizedSpells = {}
  for _, spell in pairs(helperConfig.spells) do
    if spell.id and spell.id > 0 and spell.percent and spell.percent > 0 then
      table.insert(prioritizedSpells, spell)
      safeLog("debug", string.format("Helper: checkHealthHealing - Added spell ID %d with percent %.2f%%", spell.id, spell.percent))
    else
      safeLog("debug", string.format("Helper: checkHealthHealing - Skipped spell: id=%s, percent=%s", tostring(spell.id), tostring(spell.percent)))
    end
  end

  table.sort(prioritizedSpells, function(a, b)
    if a.percent == b.percent then
      return a.id < b.id
    else
      return a.percent < b.percent
    end
  end)

  safeLog("debug", string.format("Helper: checkHealthHealing - Found %d prioritized spells", #prioritizedSpells))
  
  for _, spell in ipairs(prioritizedSpells) do
    if ignoredSpellsIds[spell.id] then
      safeLog("debug", string.format("Helper: checkHealthHealing - Spell ID %d is ignored", spell.id))
      goto skipSpell
    end

    safeLog("debug", string.format("Helper: checkHealthHealing - Checking spell ID %d, percent: %.2f%%, healthPercent: %.2f%%", spell.id, spell.percent or 0, healthPercent))

    -- Only cast if health is at or below the configured percentage
    -- The spells are sorted by percent (lowest first), so we cast the first one that matches
    local spellPercentNum = tonumber(spell.percent)
    if spell.id and spell.id > 0 and spellPercentNum and spellPercentNum > 0 and healthPercent <= spellPercentNum then
          safeLog("debug", string.format("Helper: checkHealthHealing - CONDITION MET: spell.id=%s > 0, spell.percent=%s (type: %s), healthPercent=%.2f <= spellPercentNum=%.2f", tostring(spell.id), tostring(spell.percent), type(spell.percent), healthPercent, spellPercentNum))
      safeLog("debug", string.format("Helper: checkHealthHealing - MAGIA ENCONTRADA! Tentando executar spell ID %d (vida %.2f%% <= %.2f%%)", spell.id, healthPercent, spellPercentNum))
      if castHealingSpell(spell.id) then
        safeLog("debug", string.format("Helper: checkHealthHealing - MAGIA EXECUTADA COM SUCESSO: ID %d", spell.id))
        -- Spell was cast successfully, break to avoid casting multiple spells
        break
      else
        safeLog("debug", string.format("Helper: checkHealthHealing - Failed to cast spell ID %d", spell.id))
      end
    else
      if not spell.id or spell.id == 0 then
        safeLog("debug", string.format("Helper: checkHealthHealing - Spell has invalid ID: %s", tostring(spell.id)))
      elseif not spell.percent or spell.percent == 0 then
        safeLog("debug", string.format("Helper: checkHealthHealing - Spell ID %d has invalid percent: %s", spell.id, tostring(spell.percent)))
      elseif healthPercent > spell.percent then
        safeLog("debug", string.format("Helper: checkHealthHealing - Health %.2f%% is above spell percent %.2f%% - WAITING FOR HEALTH TO DROP", healthPercent, spell.percent))
      else
        safeLog("debug", string.format("Helper: checkHealthHealing - Unknown condition failure for spell ID %d", spell.id))
      end
    end

    ::skipSpell::
  end
end

eventTable.checkHealthHealing.action = checkHealthHealing
--safeLog("info", "Helper: checkHealthHealing action assigned to eventTable")

function hasItemInBackpack(potionId)
  local currentPlayer = getPlayer()
  return currentPlayer and type(currentPlayer) == "userdata" and currentPlayer:getInventoryCount(potionId, 0) > 0
end

function checkManaHealing(mana, maxMana)
  local manaPercent = (mana / maxMana) * 100

  for i, potion in ipairs(helperConfig.potions) do
    if isManaPotion(potion.id) then
      helperConfig.potions[i].percent = tonumber(potion.percent) or 0
    end
  end

  local healthPotionPriority = false
  for _, potion in ipairs(helperConfig.potions) do
    local healthPercent = (player:getHealth() / player:getMaxHealth()) * 100
    if hasItemInBackpack(potion.id) and isHealthPotion(potion.id) and healthPercent <= potion.percent then
      healthPotionPriority = true
    end
  end

  if healthPotionPriority then
    return
  end

  local prioritizedManaPotions = {}
  for _, potion in ipairs(helperConfig.potions) do
    if isManaPotion(potion.id) or potion.priority == 2 then
      table.insert(prioritizedManaPotions, potion)
    end
  end
  table.sort(prioritizedManaPotions, function(a, b)
    return a.percent < b.percent
  end)

  for _, potion in ipairs(prioritizedManaPotions) do
    if hasItemInBackpack(potion.id) and manaPercent <= potion.percent then
      usePotion(potion.id)
      return
    end
  end
end

function useAutoSio(target)
  local spellId = 84
  local spell = getSpellByClientId(tonumber(spellId))
  if not spell or spell.id == 0 then
    return false
  end

  if not checkHealthPriority() then
    return
  end

  if (isSpellOnCooldown(spell)) then
    return false
  end

  g_game.doThing(false)
  g_game.talk(string.format("%s \"%s\"", spell.words, target:getName()), true)
  g_game.doThing(true)
end

function useAutoGranSio(target)
  local spellId = 242
  local spell = getSpellByClientId(spellId)
  if not spell or spell.id == 0 then
    return false
  end

  if not checkHealthPriority() then
    return
  end

  if (isSpellOnCooldown(spell)) then
    return false
  end

  g_game.doThing(false)
  g_game.talk(string.format("%s \"%s\"", spell.words, target:getName()), true)
  g_game.doThing(true)
end

function useAutoTioSio(target)
  local spellId = 297
  local spell = getSpellByClientId(spellId)
  if not spell or spell.id == 0 then
    return false
  end

  if not checkHealthPriority() then
    return
  end

  if (isSpellOnCooldown(spell)) then
    return false
  end

  g_game.doThing(false)
  g_game.talk(string.format("%s \"%s\"", spell.words, target:getName()), true)
  g_game.doThing(true)
end

function useAutoUH(target)
  local runeId = 3160
  local rune = Spells.getRuneSpellByItem(runeId)
  if not rune then
    return false
  end

  if not checkHealthPriority() then
    return
  end

  helperConfig.magicShooterOnHold = true

  if hasItemInBackpack(runeId) then
    g_game.doThing(false)
    g_game.useInventoryItemWith(runeId, target, 0, true)
    g_game.doThing(true)
  end

  helperConfig.magicShooterOnHold = false
end

-- toolMenu
function updateTrainingPercent(buttonId, newPercent)
  local buttonIndex = string.match(buttonId, "%d+")
  buttonIndex = tonumber(buttonIndex)
  local trainingConfig = helperConfig.training[buttonIndex + 1]
  if trainingConfig and trainingConfig.percent then
    trainingConfig.percent = tonumber(newPercent)
  end
end

function checkTrainingSpell(mana, maxMana)
  local trainingSpell = helperConfig.training[1]
  if not trainingSpell or not trainingSpell.enabled then
    return false
  end

  local manaPercent = (mana / maxMana) * 100
  if manaPercent < tonumber(trainingSpell.percent) then
    return false
  end

  castHealingSpell(trainingSpell.id)
end

function toggleAutoEat(checked)
  helperConfig.autoEatFood = checked
end

function toggleAutoHaste(checked)
  if helperConfig.training[1].enabled then
    toolsPanel:recursiveGetChildById("enableTraining0"):setChecked(false)
  end

  helperConfig.haste[1].enabled = checked
end

function toggleAutoHastePz(checked)
  helperConfig.haste[1].safecast = checked
end

function toogleChangeGold(checked)
  helperConfig.autoChangeGold = checked
end

function autoEatFood()
  if not g_game.isOnline() or not helperConfig.autoEatFood then
    return
  end

  local cooldown = getSpellCooldown(foodConfig.id)
  if cooldown >= g_clock.millis() then
    return true
  end

  local currentPlayer = getPlayer()
  if not currentPlayer then
    return
  end

  for _, id in pairs(infiniteFoodIds) do
    if currentPlayer:getInventoryCount(id) > 0 then
      g_game.doThing(false)
      g_game.useInventoryItem(id)
      g_game.doThing(true)
      spellsCooldown[foodConfig.id] = g_clock.millis() + foodConfig.exhaustion
      return
    end
  end

  for _, id in pairs(foodIds) do
    if currentPlayer:getInventoryCount(id) > 0 then
      g_game.doThing(false)
      g_game.useInventoryItem(id)
      g_game.doThing(true)
      spellsCooldown[foodConfig.id] = g_clock.millis() + foodConfig.exhaustion
      break
    end
  end
end

function autoChangeGold()
  if not g_game.isOnline() or not helperConfig.autoChangeGold then
    return
  end
  local currentPlayer = getPlayer()
  if not currentPlayer then
    return
  end

  local goldCoinId = 3031  -- Gold Coin
  local platinumCoinId = 3035  -- Platinum Coin
  local crystalCoinId = 3043  -- Crystal Coin
  
  local goldCount = currentPlayer:getInventoryCount(goldCoinId)
  local platinumCount = currentPlayer:getInventoryCount(platinumCoinId)
  
  -- Tentar encontrar os itens nos containers abertos
  local goldItem = g_game.findItemInContainers(goldCoinId)
  local platinumItem = g_game.findItemInContainers(platinumCoinId)
  local crystalItem = g_game.findItemInContainers(crystalCoinId)
  
  -- Se tiver 100+ platinum coins e crystal coin, converte platinum -> crystal
  if platinumCount >= 100 then
    g_game.doThing(false)
    g_game.useWith(platinumItem, platinumItem)
    g_game.doThing(true)
    return
  end
  
  -- Se tiver 100+ gold coins e platinum coin, converte gold -> platinum
  if goldCount >= 100  then
    g_game.doThing(false)
    g_game.useWith(goldItem, goldItem)
    g_game.doThing(true)
    return
  end
end

function checkMana()
  if not g_game.isOnline() or not hotkeyHelperStatus then return end
  local currentPlayer = getPlayer()
  if not currentPlayer then
    return
  end

  local currentPlayer = getPlayer()
  if not currentPlayer then
    return
  end
  local mana = currentPlayer:getMana()
  local maxMana = currentPlayer:getMaxMana()
  checkManaHealing(mana, maxMana)
  checkTrainingSpell(mana, maxMana)
end

eventTable.checkMana.action = checkMana

function routineChecks()
  if not hotkeyHelperStatus then return end
  local currentPlayer = getPlayer()
  if currentPlayer then
    if currentPlayer:getRegenerationTime() <= 500 then
      autoEatFood()
    end

    autoChangeGold()
  end
end

eventTable.routineChecks.action = routineChecks

function updateMagicShooterPriority(index, priority)
  local profile = getShooterProfile()
  profile.spells[index + 1].priority = tonumber(priority)
end

function updateMagicShooterCreatures(name, index, creatures)
  local profile = getShooterProfile()
  profile.spells[index + 1].creatures = tonumber(creatures)
end

function toggleSelfCast(index, checked)
  local profile = getShooterProfile()
  profile.spells[index + 1].selfCast = checked
end

function toggleForceCast(index, checked)
  local profile = getShooterProfile()
  profile.spells[index + 1].forceCast = checked
end

function toggleForceRuneCast(index, checked)
  local profile = getShooterProfile()
  profile.runes[index + 1].forceCast = checked
end

function isMagicShooterActive()
  return helperConfig.magicShooterEnabled
end

function toggleMagicShooter(widget, message)
  local shooterTracker = helperTracker:recursiveGetChildById("shooterStatus")
  if not widget then
    widget = shooterPanel:recursiveGetChildById("enableMagicShooter")
    widget:setChecked(not widget:isChecked())
  end

  helperConfig.magicShooterEnabled = widget:isChecked()
  modules.game_textmessage.displayGameMessage(message and message or string.format("RTCaster is %s.", (helperConfig.magicShooterEnabled and "enabled" or "disabled")))
  shooterTracker:setText(helperConfig.magicShooterEnabled and "Active" or "Inactive")
  shooterTracker:setColor(helperConfig.magicShooterEnabled and TextColors.green or TextColors.red)
end

function isAutoTargetActive()
  return helperConfig.autoTargetEnabled
end

function toggleAutoTarget(widget)
  local targetTracker = helperTracker:recursiveGetChildById("targetStatus")
  if not widget then
    widget = shooterPanel:recursiveGetChildById("enableAutoTarget")
    widget:setChecked(not widget:isChecked())
  end
  helperConfig.autoTargetEnabled = widget:isChecked()
  if not helperConfig.autoTargetEnabled and helperConfig.currentLockedTargetId > 0 then
    helperConfig.currentLockedTargetId = 0
    g_game.cancelAttack()
  end
  modules.game_textmessage.displayGameMessage(string.format("Auto Target is %s.", (helperConfig.autoTargetEnabled and "enabled" or "disabled")))
  targetTracker:setText(helperConfig.autoTargetEnabled and "Active" or "Inactive")
  targetTracker:setColor(helperConfig.autoTargetEnabled and TextColors.green or TextColors.red)
end

function toggleShooterPreset(widget, hideMessage)
  local option = ""
  if widget then
    option = widget:getCurrentOption().text
    local profile = helperConfig.shooterProfiles[option]
    if profile then
      loadShooterProfileByName(option)
    end
  elseif not widget then
    widget = presetsPanel:recursiveGetChildById("presets")
    local profiles = {}
    for name, config in pairs(helperConfig.shooterProfiles) do
      table.insert(profiles, name)
    end
    local amount = #profiles
    if amount == 0 then
      return
    end
    local i = 1
    for j, name in ipairs(profiles) do
      if name == helperConfig.selectedShooterProfile then
        i = j
        break
      end
    end
    local nextIndex = i % amount + 1
    option = profiles[nextIndex]
    if not option then
      option = profiles[1]
    end
    widget:setCurrentOption(option, true)
    loadShooterProfileByName(option)
  end
  if not hideMessage then
    modules.game_textmessage.displayGameMessage(string.format("RTCaster profile switched to %s.", option))
  end
end

function removeProfile()
  if not presetsPanel then return end
  
  local confirmWindow = nil
  local presets = presetsPanel:recursiveGetChildById('presets')

  local cancel = function()
    if confirmWindow then
      confirmWindow:destroy()
    end
  end

  local confirm = function()
    if confirmWindow then
      confirmWindow:destroy()
    end
    if getShooterProfileCount() <= 1 then
      modules.game_textmessage.displayGameMessage(string.format("You can't delete your only preset."))
      return
    end
    local currentProfileName = helperConfig.selectedShooterProfile
    toggleShooterPreset(nil, true)
    helperConfig.shooterProfiles[currentProfileName] = nil
    presets:removeOption(currentProfileName)
    modules.game_textmessage.displayGameMessage(string.format("Preset %s deleted.", currentProfileName))
  end

  confirmWindow = displayGeneralBox('Delete Preset', string.format("Are you sure you want to delete preset %s?", helperConfig.selectedShooterProfile),
		{ { text=tr('Yes'), callback = confirm }, { text=tr('No'), callback = cancel }
	}, yesFunction, noFunction)
end

function updateAutoTargetMode(mode)
  local modeId = autoTargetModes[mode]
  if not modeId then
    return
  end
  helperConfig.autoTargetMode = modeId
  local profile = getShooterProfile()
  if profile then
    profile.autoTargetMode = modeId
  end
end

local function printArea(area)
  for _, row in ipairs(area) do
    local line = ""
    for _, value in ipairs(row) do
      line = line .. tostring(value) .. " "
    end
    print(line)
  end
  print("\n")
end

local function rotateArea(area, direction)
  if not area or type(area) ~= "table" or #area == 0 or not area[1] or type(area[1]) ~= "table" then
    return area
  end

  local rotatedArea = {}
  local rows = #area
  local cols = #area[1]

  if direction == Directions.North then
      rotatedArea = area
  elseif direction == Directions.South then
      for y = 1, rows do
          rotatedArea[y] = {}
          for x = 1, cols do
              rotatedArea[y][x] = area[rows - y + 1][cols - x + 1]
          end
      end
  elseif direction == Directions.East then
      for x = 1, cols do
          rotatedArea[x] = {}
          for y = 1, rows do
              rotatedArea[x][y] = area[rows - y + 1][x]
          end
      end
  elseif direction == Directions.West then
      for x = 1, cols do
          rotatedArea[x] = {}
          for y = 1, rows do
              rotatedArea[x][y] = area[y][cols - x + 1]
          end
      end
  end

  return rotatedArea
end

local function findPlayerPosition(area)
  for y, row in ipairs(area) do
      for x, value in ipairs(row) do
          if value == 3 or value == 2 then
              return x, y
          end
      end
  end
  return nil, nil
end

function getRelativePosition(targetPos)
  local player = g_game.getLocalPlayer()
  if not player then return targetPos end
  local playerPos = player:getPosition()

  local relativePos = {x = targetPos.x, y = targetPos.y, z = targetPos.z}
	if playerPos.x < targetPos.x and playerPos.y < targetPos.y then
    relativePos.x = relativePos.x - 1;
    relativePos.y = relativePos.y - 1;
	elseif (playerPos.x < targetPos.x and playerPos.y > targetPos.y) or playerPos.x < targetPos.x then
    relativePos.x = relativePos.x - 1;
	elseif (playerPos.x > targetPos.x and playerPos.y < targetPos.y) or playerPos.y < targetPos.y then
    relativePos.y = relativePos.y - 1;
  end
  return relativePos
end

local function countAttackableCreatures(casterPos, direction, area, creatureList, ranged)
  if direction == Directions.SouthEast or direction == Directions.NorthEast then
    direction = Directions.East
  elseif direction == Directions.SouthWest or direction == Directions.NorthWest then
    direction = Directions.West
  end
  local area = rotateArea(area, direction)
  local creatures = 0
  local playerX, playerY = findPlayerPosition(area)
  if not playerX or not playerY then
      return 0
  end
  local countedCreatures = {}
  for yOffset, row in ipairs(area) do
      for xOffset, value in ipairs(row) do
          if value == 1 or (ranged and (value == 3 or value == 2)) then
              local position = {
                  x = casterPos.x + (xOffset - playerX),
                  y = casterPos.y + (yOffset - playerY),
                  z = casterPos.z
              }
              for _, creatureData in ipairs(creatureList) do
                  local creaturePos = creatureData.position
                  if creaturePos and positionCompare(creaturePos, position) and (g_map.isSightClear(casterPos, creaturePos)) then
                      local creature = creatureData.creature
                      local creatureId = creature and creature.getId and creature:getId() or tostring(creaturePos.x) .. "," .. tostring(creaturePos.y) .. "," .. tostring(creaturePos.z)
                      if not countedCreatures[creatureId] then
                          countedCreatures[creatureId] = true
                          creatures = creatures + 1
                          break
                      end
                  end
              end
          end
      end
  end
  return creatures
end

local function sortMagicShooterByPriority(list)
  table.sort(list, function(a, b)
    if a.config.priority and b.config.priority then
      return a.config.priority < b.config.priority
    else
      return false
    end
  end)

  local player = g_game.getLocalPlayer()
  if not player then return list end

  local vocation = player:getVocation()
  -- Apenas vocações Monk (5 = Monk, 15 = Exalted Monk - client ID) têm harmony
  if vocation == 5 or vocation == 15 then
    if player.getHarmony and type(player.getHarmony) == "function" then
      local harmonyCount = player:getHarmony()
      if harmonyCount and harmonyCount >= 5 then
        local spenderIndex = nil
        for i, item in ipairs(list) do
          if item.spell and item.spell.spender then
            spenderIndex = i
            break
          end
        end

        if spenderIndex then
          local spenderSpell = table.remove(list, spenderIndex)
          table.insert(list, 1, spenderSpell)
        end
      end
    end
  end
  return list
end

local function findBestTarget(position, direction, area, creatureList, minCreatures)

  local bestTarget = nil
  local maxCreaturesHit = 0

  for _, creatureInfo in pairs(creatureList) do
    if isWithinReach(position, creatureInfo.position) and g_map.isSightClear(position, creatureInfo.position) then
      local creaturesHit = countAttackableCreatures(creatureInfo.position, direction, area, creatureList, true)
      if creaturesHit >= minCreatures then
        if creaturesHit > maxCreaturesHit then
          maxCreaturesHit = creaturesHit
          bestTarget = creatureInfo.creature
        end
      end
    end
  end

  return bestTarget, maxCreaturesHit
end

function isSpellOnCooldown(spell)
  if getSpellCooldown(spell.id) >= g_clock.millis() then
    return true
  end

  if type(spell.group) == "table" then
    for group, _ in pairs(spell.group) do
      if getGroupSpellCooldown(group) >= g_clock.millis() then
        return true
      end
    end
  else
    if getGroupSpellCooldown(spell.group) >= g_clock.millis() then
      return true
    end
  end

  return false
end

function checkMagicShooter()
  if not hotkeyHelperStatus then return end
  if not helperConfig.magicShooterEnabled then return end

  local profile = getShooterProfile()
  local myCharacter = g_game.getLocalPlayer()
  if not myCharacter then return end

  -- Verificar se estamos em zona de proteção
  if myCharacter:isInProtectionZone() then
    local caster = enableButtons:recursiveGetChildById("enableMagicShooter")
    if caster then
      caster:setChecked(false)
      toggleMagicShooter(caster, "Entering in a Protection Zone!\nRTCaster disabled.")
      return
    end
  end

  -- Verificação de AFK removida pois getActionTimer não existe

  local following = g_game.getFollowingCreature()
  if following then
    local widget = enableButtons:recursiveGetChildById("enableMagicShooter")
    if widget then
      widget:setChecked(false)
      toggleMagicShooter(widget, "Follow detected!\nRTCaster disabled.")
      return
    end
  end

  local position, direction = myCharacter:getPosition(), myCharacter:getDirection()
  local creatureList = {}
  local creaturesAround = 0
  for i, creature in pairs(spectators) do
    if creature:getPosition().z == position.z and getDistanceBetween(position, creature:getPosition()) <= 6 then
      creaturesAround = creaturesAround + 1
    end
    table.insert(creatureList, {position = creature:getPosition(), creature = creature})
  end

  local unifiedList = {}

  for i, shooter in ipairs(profile.spells) do
    local spell = shooter.id ~= 0 and getSpellDataById(shooter.id) or nil
    if spell then
      table.insert(unifiedList, {type = "spell", spell = spell, config = shooter})
    end
  end

  for i, runeConfig in ipairs(profile.runes) do
    local runeSpell = Spells.getRuneSpellByItem(runeConfig.id)
    if runeSpell then
      table.insert(unifiedList, {type = "rune", rune = runeSpell, config = runeConfig})
    end
  end

  unifiedList = sortMagicShooterByPriority(unifiedList)

  local currentPlayer = getPlayer()
  if not currentPlayer then
    return
  end
  local percentageMana = (currentPlayer:getMana() / currentPlayer:getMaxMana()) * 100
  local harmonyCount = 0
  local vocation = currentPlayer:getVocation()
  -- Apenas vocações Monk (5 = Monk, 15 = Exalted Monk - client ID) têm harmony
  if (vocation == 5 or vocation == 15) and currentPlayer.getHarmony and type(currentPlayer.getHarmony) == "function" then
    harmonyCount = currentPlayer:getHarmony() or 0
  end

  for _, entry in ipairs(unifiedList) do
    if autoTargetOnHold then
      goto continue
    end

    local target = g_game.getAttackingCreature()
    local positionTarget = target and target:getPosition() or {x = 0xFFFF, y = 0xFFFF, z = 0xFF}

    if entry.type == "spell" then
      local castOnFoot = false
      local spell = entry.spell
      local config = entry.config
      local reachableCreatures = 0
      local targetable = (spell.range and spell.range > 0) or table.contains(bothCastTypeSpells, spell.id)

      if player:getMana() < spell.mana then
        goto continue
      elseif targetable and not target and not config.selfCast then
        goto continue
      elseif not table.contains(spell.vocations, translateVocation(myCharacter:getVocation())) then
        goto continue
      elseif not playerHasSpell(myCharacter, spell.id) then
        goto continue
      elseif spell.spender and harmonyCount < 5 then
        goto continue
      end

      if config and percentageMana >= config.percent then
        if spell.area then
          if not target then
            goto continue
          end
          if not positionTarget or positionTarget.z ~= position.z or not target:canBeSeen() then
            goto continue
          end
          local range = spell.range or 3

          if target and target.getCollisionSquare then
            local collisionSquare = target:getCollisionSquare()
            if collisionSquare and collisionSquare > 1 then
              positionTarget = getRelativePosition(positionTarget)
            end
          end

          if target and range >= getDistanceBetween(position, positionTarget) then
            reachableCreatures = countAttackableCreatures(positionTarget, 1, spell.area, creatureList, true)
          end
        elseif targetable and not config.selfCast and target then
          if not positionTarget or positionTarget.z ~= position.z or not target:canBeSeen() then
            goto continue
          end
          local range = spell.range or 3

          if target and target.getCollisionSquare then
            local collisionSquare = target:getCollisionSquare()
            if collisionSquare and collisionSquare > 1 then
              positionTarget = getRelativePosition(positionTarget)
            end
          end

          if target and range >= getDistanceBetween(position, positionTarget) then
            reachableCreatures = 1
          end
        elseif not targetable then
          reachableCreatures = 1
        end

        if reachableCreatures >= config.creatures then

          if not table.contains(bothCastTypeSpells, spell.id) and not config.forceCast and (targetable and creaturesAround > 1) then
            goto continue
          end

          if (isSpellOnCooldown(spell)) then
            goto continue
          end

          if target and not spell.area and not config.selfCast then
            local targetDirection = getDirectionTo(position, positionTarget)
            if targetDirection then
              g_game.turn(targetDirection)
            end
          end

          g_game.doThing(false) 
          g_game.talk(spell.words, true, castOnFoot)
          g_game.doThing(true)

          -- --- precooldown
          onSpellCooldown(spell.id, 500)
          for group,_ in pairs(spell.group) do
            onSpellGroupCooldown(group, 500)
          end
          return
        end
      end

    elseif entry.type == "rune" then
      if helperConfig.magicShooterOnHold then
        goto continue
      end

      local runeSpell = entry.rune
      local config = entry.config
      local runeCount = myCharacter:getInventoryCount(config.id)
      if runeCount > 0 then
        local bestTarget = nil
        local maxCreaturesHit = 0
        if runeSpell.area then
          bestTarget, maxCreaturesHit = findBestTarget(position, direction, runeSpell.area, creatureList, config.creatures)
        elseif not runeSpell.area then
          bestTarget = target and (isWithinReach(position, positionTarget) and g_map.isSightClear(position, positionTarget)) and target or nil
        end
        if bestTarget then
          if not config.forceCast and (not runeSpell.area and creaturesAround > 1) then
            goto continue
          end

          if isSpellOnCooldown(runeSpell) then
            goto continue
          end

          g_game.doThing(false)
          g_game.useInventoryItemWith(config.id, bestTarget, 0, true)
          g_game.doThing(true)
          -- precooldown
          onSpellGroupCooldown(runeSpell.group, 500)
          return
        end
      end
    end
    ::continue::
  end
end

eventTable.checkMagicShooter.action = checkMagicShooter

function checkAutoTarget()
  if not hotkeyHelperStatus then return end
  if not helperConfig.autoTargetEnabled then return end
  if autoTargetOnHold then return end

  local myCharacter = g_game.getLocalPlayer()
  if not myCharacter then return end

  -- Verificar se estamos em zona de proteção
  if myCharacter:isInProtectionZone() then
    local autoTarget = enableButtons:recursiveGetChildById("enableAutoTarget")
    if autoTarget then
      autoTarget:setChecked(false)
      toggleAutoTarget(autoTarget)
      return
    end
  end

  -- Verificação de AFK removida pois getActionTimer não existe

  local position = myCharacter:getPosition()

  local currentLockedTarget = helperConfig.currentLockedTargetId ~= 0 and g_map.getCreatureById(helperConfig.currentLockedTargetId) or nil
  if currentLockedTarget and not currentLockedTarget:isDead() and isWithinReach(position, currentLockedTarget:getPosition()) then
    return
  end

  local closestTarget = {id = nil, distance = 99}
  local farthestTarget = {id = nil, distance = -1}
  local lowestHealthTarget = {id = nil, health = 100}
  local highestHealthTarget = {id = nil, health = -1}
  local bestTarget = {id = nil, creatures = 0}
  local closestLowestHealthTarget = {id = nil, distance = 99, health = 100}
  local closestHighestHealthTarget = {id = nil, distance = 99, health = -1}
  local farthestLowestHealthTarget = {id = nil, distance = -1, health = 100}
  local farthestHighestHealthTarget = {id = nil, distance = -1, health = -1}

  local area = {
    {0, 0, 1, 0, 0},
    {0, 1, 1, 1, 0},
    {1, 1, 2, 1, 1},
    {0, 1, 1, 1, 0},
    {0, 0, 1, 0, 0}
  }
  if translateVocation(myCharacter:getVocation()) == 7 then
    area = {
      {0, 1, 0},
      {1, 2, 1},
      {0, 1, 0}
    }
  end

  local creatureList = {}
  for i, creature in pairs(spectators) do
    table.insert(creatureList, {position = creature:getPosition(), creature = creature})
  end

  local monsters = {}
  local maxCreaturesHit = 0

  for i, creatureData in pairs(creatureList) do
    if not isWithinReach(position, creatureData.position) or not g_map.isSightClear(position, creatureData.position) then
      goto continue
    end
    local health = creatureData.creature:getHealthPercent()
    if lowestHealthTarget.id == nil then -- just to make sure it will target someone at 100% health
      lowestHealthTarget = {id = creatureData.creature:getId(), health = health}
    end
    if health < lowestHealthTarget.health then
      lowestHealthTarget = {id = creatureData.creature:getId(), health = health}
    end
    if health > highestHealthTarget.health then
      highestHealthTarget = {id = creatureData.creature:getId(), health = health}
    end
    local creatureDistance = getDistanceBetween(position, creatureData.position)
    if creatureDistance < closestTarget.distance then
      closestTarget = {id = creatureData.creature:getId(), distance = creatureDistance}
    end
    if creatureDistance > farthestTarget.distance then
      farthestTarget = {id = creatureData.creature:getId(), distance = creatureDistance}
    end
    if (creatureDistance < closestLowestHealthTarget.distance) or
       (creatureDistance == closestLowestHealthTarget.distance and health < closestLowestHealthTarget.health) then
      closestLowestHealthTarget = {id = creatureData.creature:getId(), distance = creatureDistance, health = health}
    end
    if (creatureDistance < closestHighestHealthTarget.distance) or
       (creatureDistance == closestHighestHealthTarget.distance and health > closestHighestHealthTarget.health) then
      closestHighestHealthTarget = {id = creatureData.creature:getId(), distance = creatureDistance, health = health}
    end
    if (creatureDistance > farthestLowestHealthTarget.distance) or
       (creatureDistance == farthestLowestHealthTarget.distance and health < farthestLowestHealthTarget.health) then
      farthestLowestHealthTarget = {id = creatureData.creature:getId(), distance = creatureDistance, health = health}
    end
    if (creatureDistance > farthestHighestHealthTarget.distance) or
       (creatureDistance == farthestHighestHealthTarget.distance and health > farthestHighestHealthTarget.health) then
      farthestHighestHealthTarget = {id = creatureData.creature:getId(), distance = creatureDistance, health = health}
    end
    local creaturesHit = countAttackableCreatures(creatureData.position, 1, area, creatureList, true)
    if creaturesHit > maxCreaturesHit then
        maxCreaturesHit = creaturesHit
        bestTarget.id = creatureData.creature:getId()
        bestTarget.creatures = creaturesHit
    end
    table.insert(monsters, creatureData.creature)
    ::continue::
  end


  local currentTarget = g_game.getAttackingCreature()
  local target = nil
  if helperConfig.autoTargetMode == autoTargetModes["A"] then
    target = g_map.getCreatureById(closestTarget.id)
  elseif helperConfig.autoTargetMode == autoTargetModes["B"] then
    target = g_map.getCreatureById(farthestTarget.id)
  elseif helperConfig.autoTargetMode == autoTargetModes["C"] then
    target = g_map.getCreatureById(lowestHealthTarget.id)
  elseif helperConfig.autoTargetMode == autoTargetModes["D"] then
    target = g_map.getCreatureById(highestHealthTarget.id)
  elseif helperConfig.autoTargetMode == autoTargetModes["E"] and bestTarget.id ~= nil then
    target = g_map.getCreatureById(bestTarget.id)
  elseif helperConfig.autoTargetMode == autoTargetModes["F"] then
    target = g_map.getCreatureById(closestLowestHealthTarget.id)
  elseif helperConfig.autoTargetMode == autoTargetModes["G"] then
    target = g_map.getCreatureById(closestHighestHealthTarget.id)
  elseif helperConfig.autoTargetMode == autoTargetModes["H"] then
    target = g_map.getCreatureById(farthestLowestHealthTarget.id)
  elseif helperConfig.autoTargetMode == autoTargetModes["I"] then
    target = g_map.getCreatureById(farthestHighestHealthTarget.id)
  end

  if target and not (currentTarget and currentTarget:getId() == target:getId()) then
    g_game.doThing(false)
    g_game.attack(target)
    g_game.doThing(true)
  end
end


eventTable.checkAutoTarget.action = checkAutoTarget

function checkFriendHealing()
  if not hotkeyHelperStatus then return end
  local localPlayer = g_game.getLocalPlayer()
  if localPlayer and localPlayer:isPartyMember() then
    onFriendHealing(localPlayer)
  end
end

eventTable.checkFriendHealing.action = checkFriendHealing

local lastHaste = 0

function checkAutoHaste()
  if not hotkeyHelperStatus then return end

  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer or helperConfig.haste[1].id == 0 then
    return true
  end

  if not helperConfig.haste[1].enabled then
    return true
  end

  if not helperConfig.haste[1].safecast and localPlayer:isInProtectionZone() then
    return true
  end

  local spellId = helperConfig.haste[1].id
  local spell = getSpellDataById(spellId)
  if not spell or not spell.words then
    return
  end

  -- Verificar se já está com haste ativa
  if localPlayer and localPlayer.getStates then
    local states = localPlayer:getStates()
    if states and bit.band(states, PlayerStates.Haste) ~= 0 then
      return
    end
  end

  if not checkHealthPriority() then
    return
  end

  local currentMillis = g_clock.millis()
  local cooldown = getSpellCooldown(spellId)
  
  if currentMillis < cooldown then
    return
  end

  g_game.doThing(false)
  g_game.talk(spell.words, true)
  g_game.doThing(true)

  lastHaste = currentMillis
end

eventTable.checkAutoHaste.action = checkAutoHaste

function checkHealthPriority()
  if not hotkeyHelperStatus then return end
  for _, spell in ipairs(helperConfig.spells) do
    local healthPercent = (player:getHealth() / player:getMaxHealth()) * 100
    if spell.id ~= 0 and healthPercent <= tonumber(spell.percent) then
      return false
    end
  end
  return true
end

function toggleReconnect(checked)
  local currentCharacterName = g_game.getCharacterName()
  helperConfig.autoReconnect = checked
  if saveAutoReconnect then
    saveAutoReconnect(currentCharacterName, checked)
  else
    -- Fallback if saveAutoReconnect is not available
    safeLog("warning", "Helper: saveAutoReconnect function not available")
  end
end

function onFriendHealing(localPlayer)
  if not hotkeyHelperStatus then return end

  local primaryHealing = helperConfig.friendhealing[1]
  local secondaryHealing = helperConfig.friendhealing[2]
  local gransioHealing1 = helperConfig.gransiohealing[1]
  local gransioHealing2 = helperConfig.gransiohealing[2]

  local position = localPlayer:getPosition()
  local partyMembers = modules.game_party_list.getUpcomingPartyMembers()

  table.sort(partyMembers, function(a, b)
    if a:getName() == primaryHealing.name then
      return true
    elseif b:getName() == primaryHealing.name then
      return false
    else
      return a:getName() < b:getName()
    end
  end)

  for _, member in ipairs(partyMembers) do
    if not member:isPlayer() then
      goto continue
    end

    local memberHealth = member:getHealthPercent()
    local isInSight = g_map.isSightClear(position, member:getPosition()) and isWithinReach(position, member:getPosition())

    if not isInSight then
      goto continue
    end

    if gransioHealing1.enabled and member:getName() == gransioHealing1.name and memberHealth <= gransioHealing1.percent then
      useAutoGranSio(member)
    end

    if gransioHealing2.enabled and member:getName() == gransioHealing2.name and memberHealth <= gransioHealing2.percent then
      useAutoGranSio(member)
    end

    if primaryHealing.enabled then
      if member:getName() == primaryHealing.name and memberHealth <= primaryHealing.percent and member:isPartyMember() then
        if translateVocation(localPlayer:getVocation()) == 5 then
          useAutoUH(member)
        elseif translateVocation(localPlayer:getVocation()) == 9 then
          useAutoTioSio(member)
        else
          useAutoSio(member)
        end
      end
    end

    if secondaryHealing.enabled then
      if member:getName() == secondaryHealing.name and memberHealth <= secondaryHealing.percent and member:isPartyMember() then
        if translateVocation(localPlayer:getVocation()) == 5 then
          useAutoUH(member)
        elseif translateVocation(localPlayer:getVocation()) == 9 then
          useAutoTioSio(member)
        else
          useAutoSio(member)
        end
      end
    end

    :: continue ::
  end
end


function reset()
  for i = 0, 2 do
    removeAction("spell", healingPanel:recursiveGetChildById("spellButton" .. i))
    removeAction("potion", healingPanel:recursiveGetChildById("potionButton" .. i))
    removeAction("shooter", shooterPanel:recursiveGetChildById("attackSpellButton" .. i))
    if i < 2 then
      removeAction("rune", runePanel:recursiveGetChildById("runeShooterButton" .. i))
    end
  end

  removeAction("training", toolsPanel:recursiveGetChildById("spellTrainingButton0"))
  removeAction("haste", toolsPanel:recursiveGetChildById("hasteButton0"))
end

function removeAction(type, button, keepInfo)
  local slotIndex = tonumber(button:getId():match("%d+"))
  if type == "spell" then
    helperConfig.spells[slotIndex + 1].id = 0
    helperConfig.spells[slotIndex + 1].percent = 80
    local button = healingPanel:recursiveGetChildById("spellButton" .. slotIndex)
    local percent = healingPanel:recursiveGetChildById("spellPercentLabel" .. slotIndex)
    button:setImageSource("/images/game/actionbar/actionbarslot")
    button:setImageClip("0 0 34 34")
    button:setBorderWidth(0)
    button:setTooltip("")
    percent:setText("80%")
  elseif type == "shooter" then
    if not keepInfo then
      local profile = getShooterProfile()
      profile.spells[slotIndex + 1].id = 0
      profile.spells[slotIndex + 1].percent = 80
      profile.spells[slotIndex + 1].creatures = 1
      profile.spells[slotIndex + 1].forceCast = false
      profile.spells[slotIndex + 1].selfCast = false
    end
    local button = shooterPanel:recursiveGetChildById("attackSpellButton" .. slotIndex)
    button:setImageSource("/images/game/actionbar/actionbarslot")
    button:setImageClip("0 0 34 34")
    button:setBorderWidth(0)
    button:setTooltip("")
    local percent = shooterPanel:recursiveGetChildById("spellPercentLabel" .. slotIndex)
    shooterPanel:recursiveGetChildById("rmvPercentButton" .. slotIndex):setEnabled(true)
    shooterPanel:recursiveGetChildById("addPercentButton" .. slotIndex):setEnabled(true)
    percent:setText("80%")
    local forceCast = shooterPanel:recursiveGetChildById("conditionSetting" .. slotIndex)
    forceCast:setChecked(false)
    forceCast:setVisible(false)
    local creaturesMin = shooterPanel:recursiveGetChildById("countMinCreature" .. slotIndex)
    creaturesMin:setCurrentOption("1+")
    creaturesMin:enable()
    local selfCast = shooterPanel:recursiveGetChildById("selfCast" .. slotIndex)
    if selfCast then
      selfCast:destroy()
    end
  elseif type == "potion" then
    if not helperConfig.potions[slotIndex + 1] then
      helperConfig.potions[slotIndex + 1] = {}
    end

    if helperConfig.potions[slotIndex + 1].id == 7642 or helperConfig.potions[slotIndex + 1].id == 23374 then
      helperConfig.potions[slotIndex + 1].priority = 0
      local priorityButton = healingPanel:recursiveGetChildById("priority" .. slotIndex)
      priorityButton:setImageSource("/images/skin/show-gui-help-grey")
      priorityButton:setTooltip("Uses a healing or mana potion when your health or\nmana reaches the defined percentage.\nPaladins can click on this button to change the potion priority:\n  - Icon: Blue (Mana Priority)\n  - Icon: Red  (Health Priority)")
    end

    helperConfig.potions[slotIndex + 1].id = 0
    helperConfig.potions[slotIndex + 1].percent = 50
    local button = healingPanel:recursiveGetChildById("potionButton" .. slotIndex)
    button:setImageSource("/images/game/actionbar/actionbarslot")
    local percent = healingPanel:recursiveGetChildById("potionPercentLabel" .. slotIndex)
    if button.potionItem then
      button.potionItem:destroy()
    end
    percent:setText("50%")
  elseif type == "rune" then
    if not keepInfo then
      local profile = getShooterProfile()
      if not profile.runes[slotIndex + 1] then
        profile.runes[slotIndex + 1] = {}
      end

      profile.runes[slotIndex + 1].id = 0
      profile.runes[slotIndex + 1].creatures = 1
      profile.runes[slotIndex + 1].forceCast = false
    end
    local button = runePanel:recursiveGetChildById("runeShooterButton" .. slotIndex)
    button:setImageSource("/images/game/actionbar/actionbarslot")
    local creaturesMin = runePanel:recursiveGetChildById("countMinCreature" .. slotIndex)
    creaturesMin:setCurrentOption("1+")
    creaturesMin:enable()
    local forceCast = runePanel:recursiveGetChildById("conditionSetting" .. slotIndex)
    forceCast:setVisible(false)
    forceCast:setChecked(false)
    if button.runeItem then
      button.runeItem:destroy()
    end

  elseif type == "training" then
    helperConfig.training[slotIndex + 1].id = 0
    helperConfig.training[slotIndex + 1].percent = 0
    helperConfig.training[slotIndex + 1].enabled = false
    local button = toolsPanel:recursiveGetChildById("spellTrainingButton" .. slotIndex)
    local percentOption = toolsPanel:recursiveGetChildById("spellTrainingPercent" .. slotIndex)
    button:setImageSource("/images/game/actionbar/actionbarslot")
    button:setImageClip("0 0 34 34")
    button:setBorderWidth(0)
    button:setTooltip("")
    percentOption:setCurrentOption("100%")
    toolsPanel:recursiveGetChildById("enableTraining" .. slotIndex):setChecked(false)
  elseif type == "haste" then
    helperConfig.haste[slotIndex + 1].id = 0
    helperConfig.haste[slotIndex + 1].enabled = false
    helperConfig.haste[slotIndex + 1].safecast = false
    local button = toolsPanel:recursiveGetChildById("hasteButton" .. slotIndex)
    button:setImageSource("/images/game/actionbar/actionbarslot")
    button:setImageClip("0 0 34 34")
    button:setBorderWidth(0)
    button:setTooltip("")
    toolsPanel:recursiveGetChildById("enableHaste" .. slotIndex):setChecked(false)
    toolsPanel:recursiveGetChildById("castOnPz"):setChecked(false)
  elseif type == "exercise" then
    local box = toolsPanel:recursiveGetChildById("autoTrainingItem")
    box:setImageSource("/images/game/actionbar/actionbarslot")
    if button.potionItem then
      button.potionItem:destroy()
    end
  end
end

function loadProfileOptions()
  if not presetsPanel then return end
  
  local profile = helperConfig.selectedShooterProfile
  local presets = presetsPanel:recursiveGetChildById('presets')
  if presets then
    if presets.getOptionsCount and presets:getOptionsCount() > 0 then
      return
    end

    local profileNames = {}

    for profileName, _ in pairs(helperConfig.shooterProfiles) do
      table.insert(profileNames, profileName)
    end

    table.sort(profileNames)

    for _, profileName in ipairs(profileNames) do
      presets:addOption(profileName)
    end

    presets:setCurrentOption(profile)
    presets:updateCurrentOption(profile)
  end
end


function loadShooterProfileByName(profileName)
  helperConfig.selectedShooterProfile = profileName
  local profile = getShooterProfile()
  if not profile then
    return
  end

  local currentPresetLabel = helperTracker:recursiveGetChildById("currentPresetName")
  if currentPresetLabel then
    currentPresetLabel:setText(profileName)
  end

  if profile.autoTargetMode then
    helperConfig.autoTargetMode = profile.autoTargetMode
    local autoTargetMode = enableButtons:recursiveGetChildById("autoTargetMode")
    if autoTargetMode then
      for k, v in pairs(autoTargetModes) do
        if v == profile.autoTargetMode then
          autoTargetMode:setCurrentOption(k)
          break
        end
      end
    end
  end

  for k, v in pairs(profile.spells) do
    if v.id <= 0 then
      removeAction("shooter", shooterPanel:recursiveGetChildById("attackSpellButton" .. k - 1))
    else
      local button = shooterPanel:recursiveGetChildById("attackSpellButton" .. k - 1)
      local minCreatures = shooterPanel:recursiveGetChildById("countMinCreature" .. k - 1)
      local priority = shooterPanel:recursiveGetChildById("priority" .. k - 1)
      local forceCast = shooterPanel:recursiveGetChildById("conditionSetting" .. k - 1)
      local selfCast = shooterPanel:recursiveGetChildById("selfCast" .. k - 1)
      forceCast:setChecked(v.forceCast)
      priority:setCurrentOption(numberToOrdinal(v.priority))
      minCreatures:setCurrentOption(tostring(v.creatures) .. "+")
      local spell = getSpellDataById(v.id)
      if spell then
        local spellId = getSpellIdFromIcon(spell.icon)
        local source = SpelllistSettings['Default'].iconFile
        local clip = getSpellImageClip(spellId, 'Default')
        button:setImageSource(source)
        button:setImageClip(clip)
        button:setBorderColorTop("#1b1b1b")
        button:setBorderColorLeft("#1b1b1b")
        button:setBorderColorRight("#757575")
        button:setBorderColorBottom("#757575")
        button:setBorderWidth(1)
        local spellName = spell.name or (spell.words and spell.words:match("^%S+") or "Unknown")
        if Spells and Spells.getSpellNameByWords then
          local success, name = pcall(function() return Spells.getSpellNameByWords(spell.words) end)
          if success and name then
            spellName = name
          end
        end
        button:setTooltip("Spell: " .. spellName .. "\nWords: " .. (spell.words or ""))
        if table.contains(bothCastTypeSpells, spell.id) then
          if not selfCast then
            selfCast = g_ui.createWidget('CheckBox', minCreatures:getParent())
            if selfCast then
              local style = {
                ["width"] = 12,
                ["anchors.top"] = "countMinCreature" .. k - 1 .. ".top",
                ["anchors.left"] = "countMinCreature" .. k - 1 .. ".right",
                ["margin-top"] = 6,
                ["margin-left"] = 5
              }
              selfCast:mergeStyle(style)
              selfCast:setId('selfCast' .. k - 1)
              selfCast:setTooltip('Cast on yourself')
              selfCast:setVisible(true)
              selfCast:setChecked(v.selfCast)
              selfCast.onCheckChange = function() toggleSelfCast(selfCast:getId():match("%d+"), selfCast:isChecked()) end
            end
          end
        end
        if minCreatures and (spell.range > 0 or not spell.area) and not table.contains(bothCastTypeSpells, spell.id) then
          minCreatures:setCurrentOption("1+")
          minCreatures:disable()
          v.creatures = 1
          forceCast:setVisible(true)
        else
          minCreatures:setEnabled(true)
          minCreatures:setCurrentOption(tostring(v.creatures) .. "+")
          forceCast:setVisible(false)
          forceCast:setChecked(false)
        end
      end
      local percentOption = shooterPanel:recursiveGetChildById("spellPercentLabel" .. k - 1)
      percentOption:setText(tostring(v.percent) .. "%")
      if v.percent <= 1 then
        shooterPanel:recursiveGetChildById("rmvPercentButton" .. k - 1):setEnabled(false)
      elseif v.percent >= 99 then
        shooterPanel:recursiveGetChildById("addPercentButton" .. k - 1):setEnabled(false)
      end
    end
  end
  for k, v in pairs(profile.runes) do
    if v.id <= 0 then
      removeAction("rune", runePanel:recursiveGetChildById("runeShooterButton" .. k - 1))
    else
      local button = runePanel:recursiveGetChildById("runeShooterButton" .. k - 1)
      if button.runeItem then
        button.runeItem:destroy()
      end
      local itemWidget = g_ui.createWidget('RuneItem', button)
      itemWidget:setItemId(v.id)
      itemWidget:setId('runeItem')
      local creaturesMin = runePanel:recursiveGetChildById("countMinCreature" .. k - 1)
      creaturesMin:setCurrentOption(tostring(v.creatures) .. "+")
      local forceCast = runePanel:recursiveGetChildById("conditionSetting" .. k - 1)
      forceCast:setVisible(false)
      forceCast:setChecked(v.forceCast)
      local rune = Spells.getRuneSpellByItem(v.id)
      if rune then
        if not rune.area then
          creaturesMin:disable()
          forceCast:setVisible(true)
        else
          creaturesMin:setEnabled(true)
          creaturesMin:setCurrentOption(tostring(v.creatures) .. "+")
          forceCast:setVisible(false)
          forceCast:setChecked(false)
        end
        button:setTooltip(string.format(rune.name .. " %s", rune.area and "(Area Damage)" or "(Single Damage)"))
      end
      local priorityOption = runePanel:recursiveGetChildById("runePriority" .. k - 1)
      priorityOption:setCurrentOption(numberToOrdinal(v.priority))
    end
  end
end

function onLoadHelperData()
  for k, v in pairs(helperConfig.spells) do
    if v.id ~= 0 then
      local button = healingPanel:recursiveGetChildById("spellButton" .. k - 1)
      if not button then
        goto continue
      end
      local spell = getSpellDataById(v.id)
      if spell then
        -- Try to get icon ID from spell.icon or use clientId as fallback
        local spellId = 0
        if spell.icon and spell.icon ~= "" then
          spellId = getSpellIdFromIcon(spell.icon)
        end
        -- If icon ID is 0, try using clientId
        if spellId == 0 and spell.clientId then
          spellId = spell.clientId
        end
        -- If still 0, try using spell.id
        if spellId == 0 and spell.id then
          spellId = spell.id
        end
        
        local source = (SpelllistSettings and SpelllistSettings['Default'] and SpelllistSettings['Default'].iconFile) or "/images/game/spells/spell-icons-32x32"
        local clip = getSpellImageClip(spellId, 'Default')
        button:setImageSource(source)
        button:setImageClip(clip)
        button:setBorderColorTop("#1b1b1b")
        button:setBorderColorLeft("#1b1b1b")
        button:setBorderColorRight("#757575")
        button:setBorderColorBottom("#757575")
        button:setBorderWidth(1)
        local spellName = spell.name or (spell.words and spell.words:match("^%S+") or "Unknown")
        if Spells and Spells.getSpellNameByWords then
          local success, name = pcall(function() return Spells.getSpellNameByWords(spell.words) end)
          if success and name then
            spellName = name
          end
        end
        button:setTooltip("Spell: " .. spellName .. "\nWords: " .. (spell.words or ""))
      end
      ::continue::
    end
    local percentOption = healingPanel:recursiveGetChildById("spellPercentLabel" .. k - 1)
    percentOption:setText(tostring(v.percent) .. "%")
  end

  for k, v in pairs(helperConfig.potions) do
    if v.id ~= 0 then
      local button = healingPanel:recursiveGetChildById("potionButton" .. k - 1)
      local itemWidget = g_ui.createWidget('PotionItem', button)
      itemWidget:setItemId(v.id)
      itemWidget:setId('potionItem')
      if v.id == 7642 or v.id == 23374 then
        local priorityButton = healingPanel:recursiveGetChildById("priority" .. k - 1)
        if v.priority == 1 then
          priorityButton:setImageSource("/images/skin/show-gui-help-red")
          priorityButton:setTooltip("This potion is healing health...")
          priorityButton:setActionId(1)
          helperConfig.potions[k].priority = 1
        else
          priorityButton:setImageSource("/images/skin/show-gui-help-blue")
          priorityButton:setTooltip("This potion is healing mana...")
          priorityButton:setActionId(2)
          helperConfig.potions[k].priority = 2
        end
      end
    end

    local percentOption = healingPanel:recursiveGetChildById("potionPercentLabel" .. k - 1)
    percentOption:setText(tostring(v.percent) .. "%")
  end

  for k, v in pairs(helperConfig.training) do
    if v.id ~= 0 then
      local button = toolsPanel:recursiveGetChildById("spellTrainingButton" .. k - 1)
      local spell = getSpellDataById(v.id)
      if spell then
        local spellId = getSpellIdFromIcon(spell.icon)
        local source = SpelllistSettings['Default'].iconFile
        local clip = getSpellImageClip(spellId, 'Default')
        button:setImageSource(source)
        button:setImageClip(clip)
        button:setBorderColorTop("#1b1b1b")
        button:setBorderColorLeft("#1b1b1b")
        button:setBorderColorRight("#757575")
        button:setBorderColorBottom("#757575")
        button:setBorderWidth(1)
        local spellName = spell.name or (spell.words and spell.words:match("^%S+") or "Unknown")
        if Spells and Spells.getSpellNameByWords then
          local success, name = pcall(function() return Spells.getSpellNameByWords(spell.words) end)
          if success and name then
            spellName = name
          end
        end
        button:setTooltip("Spell: " .. spellName .. "\nWords: " .. (spell.words or ""))
      end
      local percentOption = toolsPanel:recursiveGetChildById("spellTrainingPercent" .. k - 1)
      percentOption:setCurrentOption(tostring(v.percent) .. "%")
      toolsPanel:recursiveGetChildById("enableTraining" .. k - 1):setChecked(v.enabled)
    end
  end

  for k, v in pairs(helperConfig.haste) do
    if v.id ~= 0 then
      local button = toolsPanel:recursiveGetChildById("hasteButton" .. k - 1)
      local spell = getSpellDataById(v.id)
      if spell then
        -- Try to get icon ID from spell.icon or use clientId as fallback
        local spellId = 0
        if spell.icon and spell.icon ~= "" then
          spellId = getSpellIdFromIcon(spell.icon)
        end
        -- If icon ID is 0, try using clientId
        if spellId == 0 and spell.clientId then
          spellId = spell.clientId
        end
        -- If still 0, try using spell.id
        if spellId == 0 and spell.id then
          spellId = spell.id
        end
        
        local source = (SpelllistSettings and SpelllistSettings['Default'] and SpelllistSettings['Default'].iconFile) or "/images/game/spells/spell-icons-32x32"
        local clip = getSpellImageClip(spellId, 'Default')
        button:setImageSource(source)
        button:setImageClip(clip)
        button:setBorderColorTop("#1b1b1b")
        button:setBorderColorLeft("#1b1b1b")
        button:setBorderColorRight("#757575")
        button:setBorderColorBottom("#757575")
        button:setBorderWidth(1)
        local spellName = spell.name or (spell.words and spell.words:match("^%S+") or "Unknown")
        if Spells and Spells.getSpellNameByWords then
          local success, name = pcall(function() return Spells.getSpellNameByWords(spell.words) end)
          if success and name then
            spellName = name
          end
        end
        button:setTooltip("Spell: " .. spellName .. "\nWords: " .. (spell.words or ""))
      end
      toolsPanel:recursiveGetChildById("enableHaste" .. k - 1):setChecked(v.enabled)
      toolsPanel:recursiveGetChildById("castOnPz"):setChecked(v.safecast)
    end
  end
  loadShooterProfileByName(helperConfig.selectedShooterProfile)
  toolsPanel:recursiveGetChildById("eatFood"):setChecked(helperConfig.autoEatFood)
  toolsPanel:recursiveGetChildById("reconnect"):setChecked(helperConfig.autoReconnect)
  toolsPanel:recursiveGetChildById("changeGold"):setChecked(helperConfig.autoChangeGold)
  enableButtons:recursiveGetChildById("enableMagicShooter"):setChecked(helperConfig.magicShooterEnabled)
  enableButtons:recursiveGetChildById("enableAutoTarget"):setChecked(helperConfig.autoTargetEnabled)
  local autoTargetMode = enableButtons:recursiveGetChildById("autoTargetMode")
  for k, v in pairs(autoTargetModes) do
    if v == helperConfig.autoTargetMode then
      autoTargetMode:setCurrentOption(k)
      break
    end
  end
end

function saveSettings()
  local player = g_game.getLocalPlayer()
  if not player then
    return
  end

  local currentLoadedPlayer = LoadedPlayer or player
  if currentLoadedPlayer.isLoaded and not currentLoadedPlayer:isLoaded() then return end

  local playerId = currentLoadedPlayer.getId and currentLoadedPlayer:getId() or player:getId()
  local folder = "/characterdata/".. playerId .."/helper.json"
	local status, result = pcall(function() return json.encode(helperConfig, 2) end)
	if not status then
		return onError("Error while saving helper profile settings. Data won't be saved. Details: " .. result)
	end

	if result:len() > 100 * 1024 * 1024 then
	  return onError("Something went wrong, file is above 100MB, won't be saved")
	end

	g_resources.writeFileContents(folder, result)
end

function loadSettings()
  local currentLoadedPlayer = LoadedPlayer or g_game.getLocalPlayer()
  if not currentLoadedPlayer then
    return
  end
  local playerId = 0
  local success, id = pcall(function() return currentLoadedPlayer:getId() end)
  if success then
    playerId = id
  end
  local folder = "/characterdata/".. playerId .."/helper.json"

  helperConfig = {
    spells = {
      { id = 0, percent = 80 },
      { id = 0, percent = 80 },
      { id = 0, percent = 80 }
    },
    potions = {
      { id = 0, percent = 50, priority = 0 },
      { id = 0, percent = 50, priority = 0},
      { id = 0, percent = 50, priority = 0 }
    },
    training = {
      {id = 0, percent = 0, enabled = false }
    },
    haste = {
      {id = 0, enabled = false, safecast = false }
    },
    friendhealing = {
      {name = "", percent = 0, enabled = false },
      {name = "", percent = 0, enabled = false }
    },
    gransiohealing = {
      {name = "", percent = 0, enabled = false },
      {name = "", percent = 0, enabled = false }
    },

    shooterProfiles = {
      ["Default"] = deepCopy(defaultShooterProfile)
    }, selectedShooterProfile = "Default",

    autoEatFood = false,
    autoReconnect = false,
    autoChangeGold = false,
    magicShooterEnabled = false,
    magicShooterOnHold = false,
    autoTargetEnabled = false,
    autoTargetMode = autoTargetModes["F"],
    currentLockedTargetId = 0
  }

  if g_resources.fileExists(folder) then
		local status, result = pcall(function()
			return json.decode(g_resources.readFileContents(folder))
		end)

		if not status then
			return false
		end

		helperConfig = result

    -- hot-fix para caso ja tenha carregado vazio
    if not result.spells then
      helperConfig.spells = {
        { id = 0, percent = 80 },
        { id = 0, percent = 80 },
        { id = 0, percent = 80 }
      }
    end
    if #helperConfig.spells < 3 then
      table.insert(helperConfig.spells, { id = 0, percent = 0 })
    end
    for _, k in pairs(helperConfig.spells) do
      if k.percent == 0 then
        k.percent = 80
      end
    end
    if not result.potions then
      helperConfig.potions = {
        { id = 0, percent = 50, priority = 0 },
        { id = 0, percent = 50, priority = 0 },
        { id = 0, percent = 50, priority = 0 }
      }
    end
    for _, k in pairs(helperConfig.potions) do
      if k.percent == 0 then
        k.percent = 50
      end

      if not k.priority then
        k.priority = 0
      end
    end
    if not result.training then
      helperConfig.training = {
        {id = 0, percent = 0, enabled = false }
      }
    end
    if not result.haste then
      helperConfig.haste = {
        {id = 0, enabled = false, safecast = false }
      }
    end
    if not result.friendhealing then
      helperConfig.friendhealing = {
        {name = "", percent = 0, enabled = false },
        {name = "", percent = 0, enabled = false }
      }
    end
    if not result.gransiohealing then
      helperConfig.gransiohealing = {
        {name = "", percent = 0, enabled = false },
        {name = "", percent = 0, enabled = false }
      }
    end
    if not result.shooterProfiles then
      result.selectedShooterProfile = "Default"
      result.shooterProfiles = {
        ["Default"] = defaultShooterProfile
      }
    end

    for profileName, profile in pairs(helperConfig.shooterProfiles) do
      if not profile.autoTargetMode then
        profile.autoTargetMode = autoTargetModes['F']
      end
    end

    if not result.autoEatFood then
      helperConfig.autoEatFood = false
    end
    if not result.autoReconnect then
      helperConfig.autoReconnect = false
    end
    if not result.autoChangeGold then
      helperConfig.autoChangeGold = false
    end
    if not result.magicShooterEnabled then
      helperConfig.magicShooterEnabled = false
    end
    if not result.magicShooterOnHold then
      helperConfig.magicShooterOnHold = false
    end
    if not result.autoTargetEnabled then
      helperConfig.autoTargetEnabled = false
    end
    if not result.autoTargetMode then
      helperConfig.autoTargetMode = autoTargetModes["F"]
    end
    if not result.currentLockedTargetId then
      helperConfig.currentLockedTargetId = 0
    end
		return true
	end
end

function checkExerciseEvent()
  local checkBox = toolsPanel:recursiveGetChildById("autoTrainingCheck")
  if not checkBox:isChecked() then
    return
  end

  local itemBox = toolsPanel:recursiveGetChildById("autoTrainingItem").potionItem
  if not itemBox or itemBox:getItemId() == 0 then
    return checkBox:setChecked(false)
  end

  local itemId = itemBox:getItemId()
  if itemId == 0 then
    return checkBox:setChecked(false)
  end

  local currentPlayer = getPlayer()
  if not currentPlayer then
    return checkBox:setChecked(false)
  end
  if currentPlayer:getInventoryCount(itemId, 0) == 0 then
    return checkBox:setChecked(false)
  end

  local dummy = getExerciseDummy()
  if not dummy then
    modules.game_textmessage.displayGameMessage("No exercise dummy found.")
    checkBox:setChecked(false)
    return
  end

  g_game.doThing(false)
  g_game.useInventoryItemWith(itemId, dummy)
  g_game.doThing(true)
end

function getExerciseDummy()
  local currentPlayer = getPlayer()
  if not currentPlayer then
    return nil
  end
  local playerPos = currentPlayer:getPosition()
  local itemList = {}
  for _, id in pairs(exerciseDummies) do
    local items = g_map.findItemsById(id, 5)
    if items then
      for pos, ptr in pairs(items) do
        if pos.z == playerPos.z then
          itemList[#itemList + 1] = {position = pos, item = ptr}
        end
      end
    end
  end

  table.sort(itemList, function(a, b)
    return getDistanceBetween(playerPos, a.position) < getDistanceBetween(playerPos, b.position)
  end)

  for _, data in pairs(itemList) do
    if g_map.isSightClear(data.position, playerPos) then
      return data.item
    end
  end
  return nil
end

eventTable.checkExerciseEvent.action = checkExerciseEvent

function assignExerciseEvent(button)
  if g_mouse and g_mouse.updateGrabber then
    g_mouse.updateGrabber(mouseGrabberWidget, 'target')
  end
  mouseGrabberWidget:grabMouse()
  hide()
  g_mouse.pushCursor('target')
  mouseGrabberWidget.onMouseRelease = function(self, mousePosition, mouseButton)
      onAssignExercise(self, mousePosition, mouseButton, button)
  end
end

function onAssignExercise(self, mousePosition, mouseButton, button)
  if g_mouse and g_mouse.updateGrabber then
    g_mouse.updateGrabber(mouseGrabberWidget, 'target')
  end
  mouseGrabberWidget:ungrabMouse()
  g_mouse.popCursor('target')
  mouseGrabberWidget.onMouseRelease = nil
  helper:show()

  local rootWidget = g_ui.getRootWidget()
  if not rootWidget then
    return true
  end

  local clickedWidget = rootWidget:recursiveGetChildByPos(mousePosition, false)
  if not clickedWidget then
    return true
  end

  local exerciseId = 0
  if clickedWidget:getClassName() == 'UIItem' and not clickedWidget:isVirtual() then
    local item = clickedWidget:getItem()
    if item then
      exerciseId = item:getId()
    end
  end

  if table.find(exercises, exerciseId) then
    button:setImageSource('/images/ui/item')
    if not button:getChildById('potionItem') then
      local itemWidget = g_ui.createWidget('PotionItem', button)
      if itemWidget then
          itemWidget:setId('potionItem')
      end
    end
    local itemWidget = button:getChildById('potionItem')
    if itemWidget then
      itemWidget:setItemId(exerciseId)
    end
  else
    modules.game_textmessage.displayFailureMessage(tr('Invalid exercise!'))
  end
end

function onCheckPotionPriority(button)
  local index = tonumber(button:getId():match("%d+"))
  if helperConfig.potions[index + 1].priority == 0 then
    return true
  end

  if button:getActionId() == 1 then
    button:setActionId(2)
    button:setImageSource("/images/skin/show-gui-help-blue")
    button:setTooltip("This potion is healing mana...")
    helperConfig.potions[index + 1].priority = 2
  else
    button:setActionId(1)
    button:setImageSource("/images/skin/show-gui-help-red")
    button:setTooltip("This potion is healing health...")
    helperConfig.potions[index + 1].priority = 1
  end
end

_G.forceInitializeHelper = function()
  print("=== FORÇANDO INICIALIZAÇÃO DO HELPER ===")

  -- 1. Definir player se não estiver definido
  if not player then
    print("Definindo variável player...")
    player = g_game.getLocalPlayer()
    print("Player definido: " .. tostring(player ~= nil))
  end

  -- 2. Chamar online() se cycleEvent não estiver registrado
  if not helperEvents or not helperEvents.helperCycleEvent then
    print("Chamando função online()...")
    online()
  else
    print("CycleEvent já registrado")
  end

  -- 3. Verificar status final
  print("Status final:")
  print("  Player definido: " .. tostring(player ~= nil))
  print("  CycleEvent ativo: " .. tostring(helperEvents and helperEvents.helperCycleEvent ~= nil))
  print("  Helper status: " .. tostring(hotkeyHelperStatus))

  print("=== INICIALIZAÇÃO CONCLUÍDA ===")
end

_G.forceRegisterCycleEvent = function()
  print("Forçando registro do cycleEvent...")

  if cycleEvent then
    print("cycleEvent encontrado, registrando...")
    helperEvents.helperCycleEvent = cycleEvent(helperCycleEvent, helperEvents.helperCycleTimer)
    print("CycleEvent registrado: " .. tostring(helperEvents.helperCycleEvent ~= nil))
  elseif _G.cycleEvent then
    print("Encontrado _G.cycleEvent")
    helperEvents.helperCycleEvent = _G.cycleEvent(helperCycleEvent, helperEvents.helperCycleTimer)
    print("CycleEvent registrado via _G: " .. tostring(helperEvents.helperCycleEvent ~= nil))
  else
    print("ERRO: cycleEvent não encontrado!")

    -- Listar funções relacionadas a cycle/timing
    print("Funções relacionadas encontradas:")
    for k, v in pairs(_G) do
      if type(v) == "function" and (string.find(k, "cycle") or string.find(k, "timer") or string.find(k, "event")) then
        print("  " .. k)
      end
    end
  end
end

_G.testHealingSystem = function()
  print("=== TESTE DO SISTEMA DE CURA ===")

  -- Status básico
  print("Helper status: " .. tostring(hotkeyHelperStatus or false))
  print("Player definido: " .. tostring(player ~= nil))
  print("CycleEvent registrado: " .. tostring(helperEvents and helperEvents.helperCycleEvent ~= nil))

  -- Testar player
  local currentPlayer = getPlayer()
  if currentPlayer and currentPlayer.getHealth and currentPlayer.getMaxHealth then
    local success, err = pcall(function()
      local health = currentPlayer:getHealth()
      local maxHealth = currentPlayer:getMaxHealth()
      local healthPercent = (health / maxHealth) * 100
      print(string.format("Player health: %d/%d (%.2f%%)", health, maxHealth, healthPercent))
    end)
    if not success then
      print("ERRO ao obter vida: " .. err)
    end
  else
    print("Player não encontrado ou sem métodos!")
  end

  -- Mostrar configurações
  print("Spell configurations:")
  if helperConfig and helperConfig.spells then
    for i, spell in ipairs(helperConfig.spells) do
      print(string.format("  Slot %d: id=%s, percent=%s", i, tostring(spell.id), tostring(spell.percent)))
    end
  else
    print("ERRO: helperConfig.spells não existe!")
  end

  print("Potion configurations:")
  if helperConfig and helperConfig.potions then
    for i, potion in ipairs(helperConfig.potions) do
      print(string.format("  Slot %d: id=%s, percent=%s, priority=%s", i, tostring(potion.id), tostring(potion.percent), tostring(potion.priority)))
    end
  else
    print("ERRO: helperConfig.potions não existe!")
  end

  -- Inicialização forçada se necessário
  if (not player or not helperEvents or not helperEvents.helperCycleEvent) then
    print("Executando inicialização forçada...")
    forceInitializeHelper()
  end

  print("=== FIM DO TESTE ===")
end

function botStatus()
  local helperStatus = helper.contentPanel:recursiveGetChildById("helperStatus")
  local helperStatusLabel = helper.contentPanel:recursiveGetChildById("helperStatusLabel")
  local helperTrackerStatus = helperTracker:recursiveGetChildById("helperStatus")

  hotkeyHelperStatus = not hotkeyHelperStatus
  --safeLog("info", string.format("Helper: hotkeyHelperStatus toggled to: %s", tostring(hotkeyHelperStatus)))

  if hotkeyHelperStatus then
    helperStatus:setImageSource("/images/store/icon-yes")
    helperStatusLabel:setText("Enabled")
    helperTrackerStatus:setText("Active")
    helperTrackerStatus:setColor(TextColors.green)
    helperStatus:setTooltip(" - Helper Status: Enabled\n\nYou can Enable or Disable the helper using\nthe default hotkey (Pause Break).\n\nAlso you can change the hotkey on settings.")
    modules.game_textmessage.displayFailureMessage(tr('Helper Status: Enabled'))
  else
    helperStatus:setImageSource("/images/store/icon-no")
    helperTrackerStatus:setText("Inactive")
    helperStatusLabel:setText("Disabled")
    helperTrackerStatus:setColor(TextColors.red)
    helperStatus:setTooltip(" - Helper Status: Disabled\n\nYou can Enable or Disable the helper using\nthe default hotkey (Pause Break).\n\nAlso you can change the hotkey on settings.")
    modules.game_textmessage.displayFailureMessage(tr('Helper Status: Disabled'))
  end

  if not helperTracker.clickHandlersSetup then
    if helperTrackerStatus then
      helperTrackerStatus.onClick = function()
        botStatus()
      end
      helperTrackerStatus:setTooltip("Click to toggle Helper status")
    end

    local shooterStatusWidget = helperTracker:recursiveGetChildById("shooterStatus")
    if shooterStatusWidget then
      shooterStatusWidget.onClick = function()
        local widget = shooterPanel:recursiveGetChildById("enableMagicShooter")
        if widget then
          widget:setChecked(not widget:isChecked())
          toggleMagicShooter(widget)
        end
      end
      shooterStatusWidget:setTooltip("Click to toggle RTCaster")
    end

    local targetStatusWidget = helperTracker:recursiveGetChildById("targetStatus")
    if targetStatusWidget then
      targetStatusWidget.onClick = function()
        local widget = shooterPanel:recursiveGetChildById("enableAutoTarget")
        if widget then
          widget:setChecked(not widget:isChecked())
          toggleAutoTarget(widget)
        end
      end
      targetStatusWidget:setTooltip("Click to toggle Auto Target")
    end

    local currentPresetWidget = helperTracker:recursiveGetChildById("currentPresetName")
    if currentPresetWidget then
      currentPresetWidget.onClick = function()
        toggleShooterPreset()
      end
      currentPresetWidget:setTooltip("Click to cycle through shooter presets")
    end

    helperTracker.clickHandlersSetup = true
  end

  local shooterTracker = helperTracker:recursiveGetChildById("shooterStatus")
  if shooterTracker then
    shooterTracker:setText(helperConfig.magicShooterEnabled and "Active" or "Inactive")
    shooterTracker:setColor(helperConfig.magicShooterEnabled and TextColors.green or TextColors.red)
  end

  local targetTracker = helperTracker:recursiveGetChildById("targetStatus")
  if targetTracker then
    targetTracker:setText(helperConfig.autoTargetEnabled and "Active" or "Inactive")
    targetTracker:setColor(helperConfig.autoTargetEnabled and TextColors.green or TextColors.red)
  end

  local currentPresetLabel = helperTracker:recursiveGetChildById("currentPresetName")
  if currentPresetLabel then
    currentPresetLabel:setText(helperConfig.selectedShooterProfile)
    currentPresetLabel:setTooltip("Click to cycle through shooter presets")
  end
end

function toggleNextWindow()
  local widgetList = {
    "healingMenu",
    "toolsMenu",
    "shooterMenu"
  }

  local selectedIndex = nil
  for i, widget in ipairs(widgetList) do
    if widget == menuId then
      selectedIndex = i
      break
    end
  end

  if not selectedIndex then
    selectedIndex = 1
  end

  local nextWidgetId = (selectedIndex == #widgetList and 1 or selectedIndex + 1)
  menuId = widgetList[nextWidgetId]
  loadMenu(menuId)
end

function manageHotkeys(typo)
  hide()
  local rootWidget = g_ui.getRootWidget()
  if not rootWidget then
    safeLog("error", "Helper: manageHotkeys - No root widget available")
    return
  end
  
  -- Try to create ActionAssignWindow, fallback to UIWindow if not available
  local assignWindow = g_ui.createWidget('ActionAssignWindow', rootWidget)
  if not assignWindow then
    assignWindow = g_ui.createWidget('UIWindow', rootWidget)
    if assignWindow then
      assignWindow:setId('ActionAssignWindow')
      -- Set basic window properties
      assignWindow:setSize({300, 200})
      assignWindow:center()
    end
  end
  
  if not assignWindow then
    safeLog("error", "Helper: manageHotkeys - Failed to create ActionAssignWindow")
    return
  end
  
  assignWindow:setText("Enable/Disable State")
  assignWindow:grabKeyboard()

  local currentHotkey = ""
  local chatMode = Options.isChatOnEnabled
  local currentBind = KeyBind:getKeyBind("Helper", typo)
  if currentBind then
    currentHotkey = currentBind:getFirstKey()
  end

  assignWindow.display:setText(currentHotkey)
  assignWindow.desc:setText("Assign or edit a hotkey to manage Target/Shooter state.")
  assignWindow:setHeight(190)
  if g_client and g_client.setInputLockWidget then
    g_client.setInputLockWidget(assignWindow)
  end

  assignWindow.onKeyDown = function(assignWindow, keyCode, keyboardModifiers, keyText)
    local keyCombo = determineKeyComboDesc(keyCode, keyboardModifiers, keyText)
    local resetCombo = {"Shift", "Ctrl", "Alt"}
    if table.contains(resetCombo, keyCombo) then
      assignWindow.display:setText('')
      assignWindow.warning:setVisible(false)
      assignWindow.buttonOk:setEnabled(true)
      return true
    end

    assignWindow.display:setText(keyCombo)
    assignWindow.warning:setVisible(false)
    assignWindow.buttonOk:setEnabled(true)
    if KeyBinds:hotkeyIsUsed(keyCombo) or modules.game_actionbar.isHotkeyUsed(keyCombo, false) or modules.game_actionbar.isHotkeyUsed(keyCombo, true) then
      assignWindow.warning:setVisible(true)
      assignWindow.warning:setText("This hotkey is already in use and will be overwritten.")
    end

    if table.contains(blockedKeys, keyCombo) then
      assignWindow.warning:setVisible(true)
      assignWindow.warning:setText("This hotkey is already in use and cannot be overwritten.")
      assignWindow.buttonOk:setEnabled(false)
    end
    return true
  end

  assignWindow.buttonOk.onClick = function()
    local text = tostring(assignWindow.display:getText())
    if #text == 0 then
      if currentBind then
        Options.removeActionHotkey(chatMode and "chatOn" or "chatOff", currentBind.jsonName, false)
        KeyBinds:setupAndReset(Options.currentHotkeySetName, chatMode and "chatOn" or "chatOff")
      end
      if g_client and g_client.setInputLockWidget then
      g_client.setInputLockWidget(nil)
    end
      assignWindow:destroy()
      return true
    end

    if KeyBinds:hotkeyIsUsed(text) and text ~= '' then
      local key = KeyBind:getKeyBindByHotkey(text)
      if key then
        g_keyboard.unbindKeyDown(text, nil)
        Options.removeActionHotkey(chatMode and "chatOn" or "chatOff", key.jsonName)
      end
    end

    if modules.game_actionbar.isHotkeyUsedByChat(text, chatMode and "chatOn" or "chatOff") then
      local usedButton = modules.game_actionbar.getUsedHotkeyButton(text)
      if usedButton then
        Options.removeHotkey(usedButton:getId())
        local rootPanel = (m_interface and m_interface.getRootPanel and m_interface.getRootPanel()) or g_ui.getRootWidget()
        g_keyboard.unbindKeyPress(text, nil, rootPanel)
        g_keyboard.unbindKeyDown(text, nil, rootPanel)
        usedButton.cache.hotkey = nil
        modules.game_actionbar.updateButton(usedButton)
      end
    end

    m_settings.CustomHotkeys.checkAndRemoveUsedHotkey(text, chatMode)
    if currentBind then
      Options.updateGeneralHotkey(chatMode and "chatOn" or "chatOff", currentBind.jsonName, text)
      KeyBinds:setupAndReset(Options.currentHotkeySetName, chatMode and "chatOn" or "chatOff")
      currentBind:setFirstKey(text)
      currentBind.firstKey = text
    end

    assignWindow:destroy()
    if g_client and g_client.setInputLockWidget then
      g_client.setInputLockWidget(nil)
    end
  end

  assignWindow.buttonClear.onClick = function()
    if currentBind then
      Options.removeActionHotkey(chatMode and "chatOn" or "chatOff", currentBind.jsonName, false)
      KeyBinds:setupAndReset(Options.currentHotkeySetName, chatMode and "chatOn" or "chatOff")
    end

    assignWindow:destroy()
    if g_client and g_client.setInputLockWidget then
      g_client.setInputLockWidget(nil)
    end
  end

  assignWindow.onDestroy = function(widget) helper:show(true) end
end

function onDropSpell(widget, spellWords)
  local spellData = Spells.getSpellDataByWords(spellWords)
  if not spellData then
    return
  end

  local isHealingPanel = string.match(widget:getId(), "^spellButton%d*")
  local isTrainingPanel = string.match(widget:getId(), "^spellTrainingButton")
  local isHastePanel = string.match(widget:getId(), "^hasteButton")
  local isAttackPanel = string.match(widget:getId(), "^attackSpellButton%d*")
  local profile = getShooterProfile()

  if isHealingPanel then
    onSetupDropSpell(widget, spellData, {2}, helperConfig.spells)
  elseif isTrainingPanel or isHastePanel then
    onSetupDropSupport(widget, spellData, isHastePanel)
  elseif isAttackPanel then
    onSetupDropSpell(widget, spellData, {1, 4, 8}, profile.spells)
  end
end

function onSetupDropSpell(button, spellData, groups, tableToAssign)
  local groupIds = Spells.getGroupIds(spellData)
  local function containsAnyGroup(groups, targetGroups)
      for _, group in ipairs(targetGroups) do
          if table.contains(groups, group) then
              return true
          end
      end
      return false
  end

  local spellId = getSpellIdFromIcon(spellData.icon)
  local playerVocation = translateVocation(player:getVocation())
  local profile = getShooterProfile()

  if containsAnyGroup(groupIds, groups) and table.contains(spellData.vocations, playerVocation) and not ignoredSpellsIds[spellId] then
    local source = SpelllistSettings['Default'].iconFile
    local clip = getSpellImageClip(spellId, 'Default')
    local spell = getSpellByClientId(tonumber(spellId))

    button:setImageSource(source)
    button:setImageClip(clip)
    button:setBorderColorTop("#1b1b1b")
    button:setBorderColorLeft("#1b1b1b")
    button:setBorderColorRight("#757575")
    button:setBorderColorBottom("#757575")
    button:setBorderWidth(1)
    button:setTooltip("Spell: " .. spellData.name .. "\nWords: " .. spellData.words)

    local slotID = tonumber(button:getId():match("%d+"))
    if button:getId():find("attackSpellButton") then
      profile.spells[slotID + 1].id = tonumber(spellData.id)
    else
      tableToAssign[slotID + 1].id = tonumber(spellData.id)
    end

    if button:getId():find("attackSpellButton") then
      local creaturesMin = shooterPanel:recursiveGetChildById("countMinCreature" .. slotID)
      local forceCast = shooterPanel:recursiveGetChildById("conditionSetting" .. slotID)
      local selfCast = shooterPanel:recursiveGetChildById("selfCast" .. slotID)
      if table.contains(bothCastTypeSpells, spell.id) then -- divine grenade self cast
        if not selfCast then
          selfCast = g_ui.createWidget('CheckBox', creaturesMin:getParent())
          local style = {
            ["width"] = 12,
            ["anchors.top"] = "countMinCreature" .. slotID .. ".top",
            ["anchors.left"] = "countMinCreature" .. slotID .. ".right",
            ["margin-top"] = 6,
            ["margin-left"] = 5
          }
          selfCast:mergeStyle(style)
          selfCast:setId('selfCast' .. slotID)
          selfCast:setTooltip('Cast on yourself')
          selfCast:setVisible(true)
          selfCast.onCheckChange = function() toggleSelfCast(selfCast:getId():match("%d+"), selfCast:isChecked()) end
        end
      end

      if selfCast and not table.contains(bothCastTypeSpells, spell.id) then
        profile.spells[slotID + 1].selfCast = false
        selfCast:destroy()
      end

      if (spell.range > 0 or not spell.area) and not table.contains(bothCastTypeSpells, spell.id) then
        if not profile.spells[slotID + 1].creatures or profile.spells[slotID + 1].creatures < 1 then
          profile.spells[slotID + 1].creatures = 1
        end
        creaturesMin:setCurrentOption(tostring(profile.spells[slotID + 1].creatures) .. "+")
        creaturesMin:disable()
        if forceCast then
          forceCast:setChecked(profile.spells[slotID + 1].forceCast)
          forceCast:setVisible(true)
        end
      else
        creaturesMin:enable()
        if forceCast then
          forceCast:setChecked(false)
          forceCast:setVisible(false)
          profile.spells[slotID + 1].forceCast = false
        end
      end
    end
  end
end

function onSetupDropSupport(widget, spellData, hasteSpell)
  local playerVocation = translateVocation(player:getVocation())
  if hasteSpell and not table.contains(hasteWhiteList[playerVocation], spellData.id) then
    return
  end

  if not hasteSpell and not (table.contains(Spells.getGroupIds(spellData), 3) or table.contains(Spells.getGroupIds(spellData), 2)) then
    return
  end

  if not hasteSpell and table.contains(hasteWhiteList[playerVocation], spellData.id) then
    return
  end

  local spellId = getSpellIdFromIcon(spellData.icon)
  if table.contains(spellData.vocations, playerVocation) and not ignoredTrainingSpells[spellData.id] then
    local source = SpelllistSettings['Default'].iconFile
    local clip = getSpellImageClip(spellId, 'Default')

    widget:setImageSource(source)
    widget:setImageClip(clip)
    widget:setBorderColorTop("#1b1b1b")
    widget:setBorderColorLeft("#1b1b1b")
    widget:setBorderColorRight("#757575")
    widget:setBorderColorBottom("#757575")
    widget:setBorderWidth(1)
    widget:setTooltip("Spell: " .. spellData.name .. "\nWords: " .. spellData.words)

    local slotID = tonumber(widget:getId():match("%d+"))
    if hasteSpell then
      helperConfig.haste[1].id = tonumber(spellData.id)
    else
      helperConfig.training[1].id = tonumber(spellData.id)
      if helperConfig.training[1].percent == 0 then
        helperConfig.training[1].percent = 100
        updateTrainingPercent('spellTrainingButton0', helperConfig.training[1].percent)
      end
    end
  end
end

function onSearchTextChange(text)
  local spellList = window:recursiveGetChildById('spellList')
  for _, child in pairs(spellList:getChildren()) do
      local name = child:getText():lower()
      if name:find(text:lower()) or text == '' or #text < 3 then
          child:setVisible(true)
      else
          child:setVisible(false)
      end
  end
end

function onClearSearchText()
  local search = window:recursiveGetChildById('searchText')
  search:setText('')
end

function toggleHelperTracker()
	if not helperTracker then
		return
	end
	if helperTracker:isVisible() then
		helperTracker:close()
		helperTracker:setParent(nil)
	else
		helperTracker:open()
		-- Try to add to interface panels if available
		if m_interface and m_interface.addToPanels then
			if m_interface.addToPanels(helperTracker) then
				helperTracker:getParent():moveChildToIndex(helperTracker, #helperTracker:getParent():getChildren())
			end
		else
			-- Fallback: add to root widget if not already parented
			if not helperTracker:getParent() then
				g_ui.getRootWidget():addChild(helperTracker)
			end
		end
	end
end

function showTerms()
  if helperConfig.terms then
    show()
  else
    createHelperRules()
    helperRules:show()
    helperRules:focus()
  end
end

function closeTerms()
  helperRules:hide()
end

function createHelperRules()
  local rulesTextList = helperRules:recursiveGetChildById('rules')
  if rulesTextList then
    rulesTextList:destroyChildren()

    local longText = "\n           Extended Terms of Conditions for Helper Services\n\n" ..
                      " These Terms of Service establish the conditions under which D FATO GAMES LTDA provides 'Helper' and 'Additional Services' for the online RPG game 'RubinOT.' This document complements the 'RubinOT Service Agreement,' which all users must accept when creating an account.\n\n" ..

                      "2 - Cheating\n\n" ..
                      "2.H - Automations in RTC.\n If the player is using the RTC client and the RTCaster function to attack monsters and/or cast spells is active, they will undergo a standard check by our team. If the player absence is confirmed, a ban will be applied to the player and their account."

    local label = g_ui.createWidget('UILabel', rulesTextList)
    label:setText(longText)
    label:setColor(TextColors.white)
    label:setFont('$var-cip-font')
    label:setTextWrap(true)
    label:setTextAutoResize(true)
    label:setMarginRight(10)
    label:setMarginLeft(10)
    label:setBackgroundColor('#414141')
  end
end

function onHelperTermCondition(widgetId, value)
  helperRules:recursiveGetChildById('next'):setEnabled(value)
end

function onHelperTermConditionNext()
  helperRules:hide()
  show()
  helperConfig.terms = true
end

function hasAcceptedTerms()
  return helperConfig.terms
end

function move(panel, height, index, minimized, locked)
  helperTracker:setParent(panel)
  helperTracker:open()
  helperTracker:setHeight(height)

  if minimized then
    helperTracker:minimize()
  end
  if locked then
    helperTracker:lock(true)
  end
  modules.game_sidebuttons.setButtonVisible("helperDialog", true)
  return helperTracker
end

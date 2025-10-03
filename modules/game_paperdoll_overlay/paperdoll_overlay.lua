local SLOT_DIR = {
  [InventorySlotHead]   = "head",
  [InventorySlotNeck]   = "neck",
  [InventorySlotBack]   = "back",
  [InventorySlotBody]   = "body",
  [InventorySlotRight]  = "right",
  [InventorySlotLeft]   = "left",
  [InventorySlotLeg]    = "legs",
  [InventorySlotFeet]   = "feet",
  [InventorySlotFinger] = "finger",
  [InventorySlotAmmo]   = "ammo",
  [InventorySlotPurse]  = "purse",
}

local SLOT_BASE = {
  [InventorySlotHead]   = 10000,
  [InventorySlotNeck]   = 20000,
  [InventorySlotBack]   = 30000,
  [InventorySlotBody]   = 40000,
  [InventorySlotRight]  = 50000,
  [InventorySlotLeft]   = 60000,
  [InventorySlotLeg]    = 70000,
  [InventorySlotFeet]   = 80000,
  [InventorySlotFinger] = 90000,
  [InventorySlotAmmo]   = 100000,
  [InventorySlotPurse]  = 110000,
}

local DIR_INDEX = { [North] = 0, [East] = 1, [South] = 2, [West] = 3 }
local INDEX_TO_DIR = { North, East, South, West }

local function applyDefaultOffsets(eff)
  eff:setDirOffset(North, 0, -6, true)
  eff:setDirOffset(East,  6, -4, true)
  eff:setDirOffset(South, 0,  8, true)
  eff:setDirOffset(West, -6, -4, true)
end

local state = { current = {}, activeEffect = {} }

local function makeEffectId(slot, itemId, dirIdx)
  return SLOT_BASE[slot] + (itemId % 10000) + (dirIdx or 0)
end

local function findDirectionalPNGs(slot, itemId)
  local dirName = SLOT_DIR[slot]
  if not dirName then return {} end
  local base = string.format("/images/paperdll/%s/%d_", dirName, itemId)
  local map = {}
  for i = 0, 3 do
    local path = base .. i .. ".png"
    if g_resources.fileExists(path) then map[i] = path end
  end
  return map
end

local function ensureEffects(slot, itemId, dirPaths)
  for i = 0, 3 do
    local path = dirPaths[i]
    if path then
      local effId = makeEffectId(slot, itemId, i)
      if not g_attachedEffects.getById(effId) then
        g_attachedEffects.registerByImage(effId, "paperdll", path, true)
        local eff = g_attachedEffects.getById(effId)
        if eff then
          eff:setOnTop(true)
          applyDefaultOffsets(eff)
        end
      end
    end
  end
end

local function switchDirEffect(player, slot, itemId, dirIdx, dirPaths)
  local wantedEffId = makeEffectId(slot, itemId, dirIdx)
  if not dirPaths[dirIdx] then
    if dirPaths[2] then
      wantedEffId = makeEffectId(slot, itemId, 2)
    else
      for i = 0, 3 do if dirPaths[i] then wantedEffId = makeEffectId(slot, itemId, i); break end end
    end
  end
  local active = state.activeEffect[slot]
  if active and active ~= wantedEffId then
    player:detachEffectById(active)
    state.activeEffect[slot] = nil
  end
  if not player:getAttachedEffectById(wantedEffId) then
    local eff = g_attachedEffects.getById(wantedEffId)
    if eff then
      player:attachEffect(eff)
      state.activeEffect[slot] = wantedEffId
    end
  else
    state.activeEffect[slot] = wantedEffId
  end
end

local function updateSlotOverlay(player, slot, item)
  if not item then
    if state.activeEffect[slot] then
      player:detachEffectById(state.activeEffect[slot])
      state.activeEffect[slot] = nil
    end
    state.current[slot] = nil
    return
  end

  local itemId = item:getId()
  state.current[slot] = itemId

  local dirPaths = findDirectionalPNGs(slot, itemId)
  if next(dirPaths) == nil then return end
  ensureEffects(slot, itemId, dirPaths)

  local dir = player.getDirection and player:getDirection() or South
  local dirIdx = DIR_INDEX[dir] or 2
  switchDirEffect(player, slot, itemId, dirIdx, dirPaths)
end

local controller = Controller:new()
local lastDirIdx = nil
local cycleName = "paperdoll_dir"
local invisByCreature = {}

local function isInvisible(outfit)
  -- Protocol sets invisible as: lookType=0 and lookTypeEx=0 -> auxType=13 (effect id)
  return outfit and outfit.type == 0 and outfit.auxType == 13
end

local function detachAllOverlays(player)
  for _, effId in pairs(state.activeEffect) do
    if effId and player:getAttachedEffectById(effId) then
      player:detachEffectById(effId)
    end
  end
  state.activeEffect = {}
end

function init() end

function controller:onGameStart()
  self:registerEvents(LocalPlayer, {
    onInventoryChange = function(player, slot, item, oldItem)
      updateSlotOverlay(player, slot, item)
    end
    ,
    onOutfitChange = function(creature, outfit)
      -- LocalPlayer-only overlay management; other creatures handled by server effects
      local lp = g_game.getLocalPlayer()
      if not lp or creature ~= lp then return end
      local inv = isInvisible(outfit)
      local cid = creature:getId()
      if inv and not invisByCreature[cid] then
        detachAllOverlays(creature)
        invisByCreature[cid] = true
        return
      end
      if not inv and invisByCreature[cid] then
        for s = InventorySlotFirst, InventorySlotLast do
          updateSlotOverlay(creature, s, creature:getInventoryItem(s))
        end
        invisByCreature[cid] = false
      end
    end
  }):execute()

  local p = g_game.getLocalPlayer()
  if p then
    for s = InventorySlotFirst, InventorySlotLast do
      updateSlotOverlay(p, s, p:getInventoryItem(s))
    end
    self:cycleEvent(function()
      if not g_game.isOnline() then return end
      local dir = p.getDirection and p:getDirection() or South
      local dirIdx = DIR_INDEX[dir] or 2
      if dirIdx ~= lastDirIdx then
        for s, itemId in pairs(state.current) do
          local dirPaths = findDirectionalPNGs(s, itemId)
          if next(dirPaths) ~= nil then
            switchDirEffect(p, s, itemId, dirIdx, dirPaths)
          end
        end
        lastDirIdx = dirIdx
      end
      -- Inventory sync: ensure overlays attach/detach even if onInventoryChange isn't fired
      for s = InventorySlotFirst, InventorySlotLast do
        local it = p:getInventoryItem(s)
        local curr = state.current[s]
        local currId = curr
        local itId = it and it:getId() or nil
        if itId ~= currId then
          updateSlotOverlay(p, s, it)
        end
      end
    end, 200, cycleName)
  end
end

function controller:onGameEnd()
  local p = g_game.getLocalPlayer()
  if p then
    for s, effId in pairs(state.activeEffect) do
      if effId then p:detachEffectById(effId) end
    end
  end
  state.activeEffect = {}
  state.current = {}
end

function terminate() end

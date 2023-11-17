-- Author: Vithrax
-- contains mostly basic function shortcuts and code shorteners

-- initial global variables declaration
vBot = {} -- global namespace for bot variables
vBot.BotServerMembers = {}
vBot.standTime = now
vBot.isUsingPotion = false
vBot.isUsing = false
vBot.customCooldowns = {}

function logInfo(text)
    local timestamp = os.date("%H:%M:%S")
    text = tostring(text)
    local start = timestamp.." [vBot]: "

    return modules.client_terminal.addLine(start..text, "orange") 
end

-- scripts / functions
onPlayerPositionChange(function(x,y)
    vBot.standTime = now
end)

function standTime()
    return now - vBot.standTime
end

function relogOnCharacter(charName)
    local characters = g_ui.getRootWidget().charactersWindow.characters
    for index, child in ipairs(characters:getChildren()) do
        local name = child:getChildren()[1]:getText()
    
        if name:lower():find(charName:lower()) then
            child:focus()
            schedule(100, modules.client_entergame.CharacterList.doLogin)
        end
    end
end

function castSpell(text)
    if canCast(text) then
        say(text)
    end
end

local dmgTable = {}
local lastDmgMessage = now
onTextMessage(function(mode, text)
    if not text:lower():find("you lose") or not text:lower():find("due to") then
        return
    end
    local dmg = string.match(text, "%d+")
    if #dmgTable > 0 then
        for k, v in ipairs(dmgTable) do
            if now - v.t > 3000 then table.remove(dmgTable, k) end
        end
    end
    lastDmgMessage = now
    table.insert(dmgTable, {d = dmg, t = now})
    schedule(3050, function()
        if now - lastDmgMessage > 3000 then dmgTable = {} end
    end)
end)

-- based on data collected by callback calculates per second damage
-- returns number
function burstDamageValue()
    local d = 0
    local time = 0
    if #dmgTable > 1 then
        for i, v in ipairs(dmgTable) do
            if i == 1 then time = v.t end
            d = d + v.d
        end
    end
    return math.ceil(d / ((now - time) / 1000))
end

-- simplified function from modules
-- displays string as white colour message
function whiteInfoMessage(text)
    return modules.game_textmessage.displayGameMessage(text)
end

function statusMessage(text, logInConsole)
    return not logInConsole and modules.game_textmessage.displayFailureMessage(text) or modules.game_textmessage.displayStatusMessage(text)
end

-- same as above but red message
function broadcastMessage(text)
    return modules.game_textmessage.displayBroadcastMessage(text)
end

-- almost every talk action inside cavebot has to be done by using schedule
-- therefore this is simplified function that doesn't require to build a body for schedule function
function scheduleNpcSay(text, delay)
    if not text or not delay then return false end

    return schedule(delay, function() NPC.say(text) end)
end

-- returns first number in string, already formatted as number
-- returns number or nil
function getFirstNumberInText(text)
    local n = nil
    if string.match(text, "%d+") then n = tonumber(string.match(text, "%d+")) end
    return n
end

-- function to search if item of given ID can be found on certain tile
-- first argument is always ID 
-- the rest of aguments can be:
-- - tile
-- - position
-- - or x,y,z coordinates as p1, p2 and p3
-- returns boolean
function isOnTile(id, p1, p2, p3)
    if not id then return end
    local tile
    if type(p1) == "table" then
        tile = g_map.getTile(p1)
    elseif type(p1) ~= "number" then
        tile = p1
    else
        local p = getPos(p1, p2, p3)
        tile = g_map.getTile(p)
    end
    if not tile then return end

    local item = false
    if #tile:getItems() ~= 0 then
        for i, v in ipairs(tile:getItems()) do
            if v:getId() == id then item = true end
        end
    else
        return false
    end

    return item
end

-- position is a special table, impossible to compare with normal one
-- this is translator from x,y,z to proper position value
-- returns position table
function getPos(x, y, z)
    if not x or not y or not z then return nil end
    local pos = pos()
    pos.x = x
    pos.y = y
    pos.z = z

    return pos
end

-- opens purse... that's it
function openPurse()
    return g_game.use(g_game.getLocalPlayer():getInventoryItem(
                          InventorySlotPurse))
end

-- check's whether container is full
-- c has to be container object
-- returns boolean
function containerIsFull(c)
    if not c then return false end

    if c:getCapacity() > #c:getItems() then
        return false
    else
        return true
    end

end

function dropItem(idOrObject)
    if type(idOrObject) == "number" then
        idOrObject = findItem(idOrObject)
    end

    g_game.move(idOrObject, pos(), idOrObject:getCount())
end

-- not perfect function to return whether character has utito tempo buff
-- known to be bugged if received debuff (ie. roshamuul)
-- TODO: simply a better version
-- returns boolean
function isBuffed()
    local var = false
    if not hasPartyBuff() then return var end

    local skillId = 0
    for i = 1, 4 do
        if player:getSkillBaseLevel(i) > player:getSkillBaseLevel(skillId) then
            skillId = i
        end
    end

    local premium = (player:getSkillLevel(skillId) - player:getSkillBaseLevel(skillId))
    local base = player:getSkillBaseLevel(skillId)
    if (premium / 100) * 305 > base then
        var = true
    end
    return var
end

-- if using index as table element, this can be used to properly assign new idex to all values
-- table needs to contain "index" as value
-- if no index in tables, it will create one
function reindexTable(t)
    if not t or type(t) ~= "table" then return end

    local i = 0
    for _, e in pairs(t) do
        i = i + 1
        e.index = i
    end
end

-- supports only new tibia, ver 10+
-- returns how many kills left to get next skull - can be red skull, can be black skull!
-- reutrns number
function killsToRs()
    return math.min(g_game.getUnjustifiedPoints().killsDayRemaining,
                    g_game.getUnjustifiedPoints().killsWeekRemaining,
                    g_game.getUnjustifiedPoints().killsMonthRemaining)
end

-- calculates exhaust for potions based on "Aaaah..." message
-- changes state of vBot variable, can be used in other scripts
-- already used in pushmax, healbot, etc

onTalk(function(name, level, mode, text, channelId, pos)
    if name ~= player:getName() then return end
    if mode ~= 34 then return end

    if text == "Aaaah..." then
        vBot.isUsingPotion = true
        schedule(950, function() vBot.isUsingPotion = false end)
    end
end)

-- [[ canCast and cast functions ]] --
-- callback connected to cast and canCast function
-- detects if a given spell was in fact casted based on player's text messages 
-- Cast text and message text must match
-- checks only spells inserted in SpellCastTable by function cast
SpellCastTable = {}
onTalk(function(name, level, mode, text, channelId, pos)
    if name ~= player:getName() then return end
    text = text:lower()

    if SpellCastTable[text] then SpellCastTable[text].t = now end
end)

-- if delay is nil or delay is lower than 100 then this function will act as a normal say function
-- checks or adds a spell to SpellCastTable and updates cast time if exist
function cast(text, delay)
    text = text:lower()
    if type(text) ~= "string" then return end
    if not delay or delay < 100 then
        return say(text) -- if not added delay or delay is really low then just treat it like casual say
    end
    if not SpellCastTable[text] or SpellCastTable[text].d ~= delay then
        SpellCastTable[text] = {t = now - delay, d = delay}
        return say(text)
    end
    local lastCast = SpellCastTable[text].t
    local spellDelay = SpellCastTable[text].d
    if now - lastCast > spellDelay then return say(text) end
end

-- canCast is a base for AttackBot and HealBot
-- checks if spell is ready to be casted again
-- ignoreRL - if true, aparat from cooldown will also check conditions inside gamelib SpellInfo table
-- ignoreCd - it true, will ignore cooldown
-- returns boolean
local Spells = modules.gamelib.SpellInfo['Default']
function canCast(spell, ignoreRL, ignoreCd)
    if type(spell) ~= "string" then return end
    spell = spell:lower()
    if SpellCastTable[spell] then
        if now - SpellCastTable[spell].t > SpellCastTable[spell].d or ignoreCd then
            return true
        else
            return false
        end
    end
    if getSpellData(spell) then
        if (ignoreCd or not getSpellCoolDown(spell)) and
            (ignoreRL or level() >= getSpellData(spell).level and mana() >=
                getSpellData(spell).mana) then
            return true
        else
            return false
        end
    end
    -- if no data nor spell table then return true
    return true
end

local lastPhrase = ""
onTalk(function(name, level, mode, text, channelId, pos)
    if name == player:getName() then
        lastPhrase = text:lower()
    end
end)

if onSpellCooldown and onGroupSpellCooldown then
    onSpellCooldown(function(iconId, duration)
        schedule(1, function()
            if not vBot.customCooldowns[lastPhrase] then
                vBot.customCooldowns[lastPhrase] = {id = iconId}
            end
        end)
    end)

    onGroupSpellCooldown(function(iconId, duration)
        schedule(2, function()
            if vBot.customCooldowns[lastPhrase] then
                vBot.customCooldowns[lastPhrase] = {id = vBot.customCooldowns[lastPhrase].id, group = {[iconId] = duration}}
            end
        end)
    end)
else
    warn("Outdated OTClient! update to newest version to take benefits from all scripts!")
end

-- exctracts data about spell from gamelib SpellInfo table
-- returns table
-- ie:['Spell Name'] = {id, words, exhaustion, premium, type, icon, mana, level, soul, group, vocations}
-- cooldown detection module
function getSpellData(spell)
    if not spell then return false end
    spell = spell:lower()
    local t = nil
    local c = nil
    for k, v in pairs(Spells) do
        if v.words == spell then
            t = k
            break
        end
    end
    if not t then
        for k, v in pairs(vBot.customCooldowns) do
            if k == spell then
                c = {id = v.id, mana = 1, level = 1, group = v.group}
                break
            end
        end
    end
    if t then
        return Spells[t]
    elseif c then
        return c
    else
        return false
    end
end

-- based on info extracted by getSpellData checks if spell is on cooldown
-- returns boolean
function getSpellCoolDown(text)
    if not text then return nil end
    text = text:lower()
    local data = getSpellData(text)
    if not data then return false end
    local icon = modules.game_cooldown.isCooldownIconActive(data.id)
    local group = false
    for groupId, duration in pairs(data.group) do
        if modules.game_cooldown.isGroupCooldownIconActive(groupId) then
            group = true
            break
        end
    end
    if icon or group then
        return true
    else
        return false
    end
end

-- global var to indicate that player is trying to do something
-- prevents action blocking by scripts
-- below callbacks are triggers to changing the var state
local isUsingTime = now
macro(100, function()
    vBot.isUsing = now < isUsingTime and true or false
end)
onUse(function(pos, itemId, stackPos, subType)
    if pos.x > 65000 then return end
    if getDistanceBetween(player:getPosition(), pos) > 1 then return end
    local tile = g_map.getTile(pos)
    if not tile then return end

    local topThing = tile:getTopUseThing()
    if topThing:isContainer() then return end

    isUsingTime = now + 1000
end)
onUseWith(function(pos, itemId, target, subType)
    if pos.x < 65000 then isUsingTime = now + 1000 end
end)

-- returns first word in string 
function string.starts(String, Start)
    return string.sub(String, 1, string.len(Start)) == Start
end

-- global tables for cached players to prevent unnecesary resource consumption
-- probably still can be improved, TODO in future
-- c can be creature or string
-- if exected then adds name or name and creature to tables
-- returns boolean
CachedFriends = {}
CachedEnemies = {}
function isFriend(c)
    local name = c
    if type(c) ~= "string" then
        if c == player then return true end
        name = c:getName()
    end

    if CachedFriends[c] then return true end
    if CachedEnemies[c] then return false end

    if table.find(storage.playerList.friendList, name) then
        CachedFriends[c] = true
        return true
    elseif vBot.BotServerMembers[name] ~= nil then
        CachedFriends[c] = true
        return true
    elseif storage.playerList.groupMembers then
        local p = c
        if type(c) == "string" then p = getCreatureByName(c, true) end
        if not p then return false end
        if p:isLocalPlayer() then return true end
        if p:isPlayer() then
            if p:isPartyMember() then
                CachedFriends[c] = true
                CachedFriends[p] = true
                return true
            end
        end
    else
        return false
    end
end

-- similar to isFriend but lighter version
-- accepts only name string
-- returns boolean
function isEnemy(c)
    local name = c
    local p
    if type(c) ~= "string" then
        if c == player then return false end
        name = c:getName()
        p = c
    end
    if not name then return false end
    if not p then
        p = getCreatureByName(name, true)
    end
    if not p then return end
    if p:isLocalPlayer() then return end

    if p:isPlayer() and table.find(storage.playerList.enemyList, name) or
        (storage.playerList.marks and not isFriend(name)) or p:getEmblem() == 2 then
        return true
    else
        return false
    end
end

function getPlayerDistribution()
    local friends = {}
    local neutrals = {}
    local enemies = {}
    for i, spec in ipairs(getSpectators()) do
        if spec:isPlayer() and not spec:isLocalPlayer() then
            if isFriend(spec) then
                table.insert(friends, spec)
            elseif isEnemy(spec) then
                table.insert(enemies, spec)
            else
                table.insert(neutrals, spec)
            end
        end
    end

    return friends, neutrals, enemies
end

function getFriends()
    local friends, neutrals, enemies = getPlayerDistribution()

    return friends
end

function getNeutrals()
    local friends, neutrals, enemies = getPlayerDistribution()

    return neutrals
end

function getEnemies()
    local friends, neutrals, enemies = getPlayerDistribution()

    return enemies
end

-- based on first word in string detects if text is a offensive spell
-- returns boolean
function isAttSpell(expr)
    if string.starts(expr, "exori") or string.starts(expr, "exevo") then
        return true
    else
        return false
    end
end

-- returns dressed-up item id based on not dressed id
-- returns number
function getActiveItemId(id)
    if not id then return false end

    if id == 3049 then
        return 3086
    elseif id == 3050 then
        return 3087
    elseif id == 3051 then
        return 3088
    elseif id == 3052 then
        return 3089
    elseif id == 3053 then
        return 3090
    elseif id == 3091 then
        return 3094
    elseif id == 3092 then
        return 3095
    elseif id == 3093 then
        return 3096
    elseif id == 3097 then
        return 3099
    elseif id == 3098 then
        return 3100
    elseif id == 16114 then
        return 16264
    elseif id == 23531 then
        return 23532
    elseif id == 23533 then
        return 23534
    elseif id == 23544 then
        return 23528
    elseif id == 23529 then
        return 23530
    elseif id == 30343 then -- Sleep Shawl
        return 30342
    elseif id == 30344 then -- Enchanted Pendulet
        return 30345
    elseif id == 30403 then -- Enchanted Theurgic Amulet
        return 30402
    elseif id == 31621 then -- Blister Ring
        return 31616
    elseif id == 32621 then -- Ring of Souls
        return 32635
    else
        return id
    end
end

-- returns not dressed item id based on dressed-up id
-- returns number
function getInactiveItemId(id)
    if not id then return false end

    if id == 3086 then
        return 3049
    elseif id == 3087 then
        return 3050
    elseif id == 3088 then
        return 3051
    elseif id == 3089 then
        return 3052
    elseif id == 3090 then
        return 3053
    elseif id == 3094 then
        return 3091
    elseif id == 3095 then
        return 3092
    elseif id == 3096 then
        return 3093
    elseif id == 3099 then
        return 3097
    elseif id == 3100 then
        return 3098
    elseif id == 16264 then
        return 16114
    elseif id == 23532 then
        return 23531
    elseif id == 23534 then
        return 23533
    elseif id == 23530 then
        return 23529
    elseif id == 30342 then -- Sleep Shawl
        return 30343
    elseif id == 30345 then -- Enchanted Pendulet
        return 30344
    elseif id == 30402 then -- Enchanted Theurgic Amulet
        return 30403
    elseif id == 31616 then -- Blister Ring
        return 31621
    elseif id == 32635 then -- Ring of Souls
        return 32621
    else
        return id
    end
end

-- returns amount of monsters within the range of position
-- does not include summons (new tibia)
-- returns number
function getMonstersInRange(pos, range)
    if not pos or not range then return false end
    local monsters = 0
    for i, spec in pairs(getSpectators()) do
        if spec:isMonster() and
            (g_game.getClientVersion() < 960 or spec:getType() < 3) and
            getDistanceBetween(pos, spec:getPosition()) < range then
            monsters = monsters + 1
        end
    end
    return monsters
end

-- shortcut in calculating distance from local player position
-- needs only one argument
-- returns number
function distanceFromPlayer(coords)
    if not coords then return false end
    return getDistanceBetween(pos(), coords)
end

-- returns amount of monsters within the range of local player position
-- does not include summons (new tibia)
-- can also check multiple floors
-- returns number
function getMonsters(range, multifloor)
    if not range then range = 10 end
    local mobs = 0;
    for _, spec in pairs(getSpectators(multifloor)) do
        mobs = (g_game.getClientVersion() < 960 or spec:getType() < 3) and
                   spec:isMonster() and distanceFromPlayer(spec:getPosition()) <=
                   range and mobs + 1 or mobs;
    end
    return mobs;
end

-- returns amount of players within the range of local player position
-- does not include party members
-- can also check multiple floors
-- returns number
function getPlayers(range, multifloor)
    if not range then range = 10 end
    local specs = 0;
    for _, spec in pairs(getSpectators(multifloor)) do
        if not spec:isLocalPlayer() and spec:isPlayer() and distanceFromPlayer(spec:getPosition()) <= range and not ((spec:getShield() ~= 1 and spec:isPartyMember()) or spec:getEmblem() == 1) then
            specs = specs + 1
        end
    end
    return specs;
end

-- this is multifloor function
-- checks if player added in "Anti RS list" in player list is within the given range
-- returns boolean
function isBlackListedPlayerInRange(range)
    if #storage.playerList.blackList == 0 then return end
    if not range then range = 10 end
    local found = false
    for _, spec in pairs(getSpectators(true)) do
        local specPos = spec:getPosition()
        local pPos = player:getPosition()
        if spec:isPlayer() then
            if math.abs(specPos.z - pPos.z) <= 2 then
                if specPos.z ~= pPos.z then specPos.z = pPos.z end
                if distanceFromPlayer(specPos) < range then
                    if table.find(storage.playerList.blackList, spec:getName()) then
                        found = true
                    end
                end
            end
        end
    end
    return found
end

-- checks if there is non-friend player withing the range
-- padding is only for multifloor
-- returns boolean
function isSafe(range, multifloor, padding)
    local onSame = 0
    local onAnother = 0
    if not multifloor and padding then
        multifloor = false
        padding = false
    end

    for _, spec in pairs(getSpectators(multifloor)) do
        if spec:isPlayer() and not spec:isLocalPlayer() and
            not isFriend(spec:getName()) then
            if spec:getPosition().z == posz() and
                distanceFromPlayer(spec:getPosition()) <= range then
                onSame = onSame + 1
            end
            if multifloor and padding and spec:getPosition().z ~= posz() and
                distanceFromPlayer(spec:getPosition()) <= (range + padding) then
                onAnother = onAnother + 1
            end
        end
    end

    if onSame + onAnother > 0 then
        return false
    else
        return true
    end
end

-- returns amount of players within the range of local player position
-- can also check multiple floors
-- returns number
function getAllPlayers(range, multifloor)
    if not range then range = 10 end
    local specs = 0;
    for _, spec in pairs(getSpectators(multifloor)) do
        specs = not spec:isLocalPlayer() and spec:isPlayer() and
                    distanceFromPlayer(spec:getPosition()) <= range and specs +
                    1 or specs;
    end
    return specs;
end

-- returns amount of NPC's within the range of local player position
-- can also check multiple floors
-- returns number
function getNpcs(range, multifloor)
    if not range then range = 10 end
    local npcs = 0;
    for _, spec in pairs(getSpectators(multifloor)) do
        npcs =
            spec:isNpc() and distanceFromPlayer(spec:getPosition()) <= range and
                npcs + 1 or npcs;
    end
    return npcs;
end

-- main function for calculatin item amount in all visible containers
-- also considers equipped items
-- returns number
function itemAmount(id)
    return player:getItemsCount(id)
end

-- self explanatory
-- a is item to use on 
-- b is item to use a on
function useOnInvertoryItem(a, b)
    local item = findItem(b)
    if not item then return end

    return useWith(a, item)
end

-- pos can be tile or position
-- returns table of tiles surrounding given POS/tile
function getNearTiles(pos)
    if type(pos) ~= "table" then pos = pos:getPosition() end

    local tiles = {}
    local dirs = {
        {-1, 1}, {0, 1}, {1, 1}, {-1, 0}, {1, 0}, {-1, -1}, {0, -1}, {1, -1}
    }
    for i = 1, #dirs do
        local tile = g_map.getTile({
            x = pos.x - dirs[i][1],
            y = pos.y - dirs[i][2],
            z = pos.z
        })
        if tile then table.insert(tiles, tile) end
    end

    return tiles
end

-- self explanatory
-- use along with delay, it will only call action
function useGroundItem(id)
    if not id then return false end

    local dest = nil
    for i, tile in ipairs(g_map.getTiles(posz())) do
        for j, item in ipairs(tile:getItems()) do
            if item:getId() == id then
                dest = item
                break
            end
        end
    end

    if dest then
        return use(dest)
    else
        return false
    end
end

-- self explanatory
-- use along with delay, it will only call action
function reachGroundItem(id)
    if not id then return false end

    local dest = nil
    for i, tile in ipairs(g_map.getTiles(posz())) do
        for j, item in ipairs(tile:getItems()) do
            local iPos = item:getPosition()
            local iId = item:getId()
            if iId == id then
                if findPath(pos(), iPos, 20,
                            {ignoreNonPathable = true, precision = 1}) then
                    dest = item
                    break
                end
            end
        end
    end

    if dest then
        return autoWalk(iPos, 20, {ignoreNonPathable = true, precision = 1})
    else
        return false
    end
end

-- self explanatory
-- returns object
function findItemOnGround(id)
    for i, tile in ipairs(g_map.getTiles(posz())) do
        for j, item in ipairs(tile:getItems()) do
            if item:getId() == id then return item end
        end
    end
end

-- self explanatory
-- use along with delay, it will only call action
function useOnGroundItem(a, b)
    if not b then return false end
    local item = findItem(a)
    if not item then return false end

    local dest = nil
    for i, tile in ipairs(g_map.getTiles(posz())) do
        for j, item in ipairs(tile:getItems()) do
            if item:getId() == id then
                dest = item
                break
            end
        end
    end

    if dest then
        return useWith(item, dest)
    else
        return false
    end
end

-- returns target creature
function target()
    if not g_game.isAttacking() then
        return
    else
        return g_game.getAttackingCreature()
    end
end

-- returns target creature
function getTarget() return target() end

-- dist is boolean
-- returns target position/distance from player
function targetPos(dist)
    if not g_game.isAttacking() then return end
    if dist then
        return distanceFromPlayer(target():getPosition())
    else
        return target():getPosition()
    end
end

-- for gunzodus/ezodus only
-- it will reopen loot bag, necessary for depositer
function reopenPurse()
    for i, c in pairs(getContainers()) do
        if c:getName():lower() == "loot bag" or c:getName():lower() ==
            "store inbox" then g_game.close(c) end
    end
    schedule(100, function()
        g_game.use(g_game.getLocalPlayer():getInventoryItem(InventorySlotPurse))
    end)
    schedule(1400, function()
        for i, c in pairs(getContainers()) do
            if c:getName():lower() == "store inbox" then
                for _, i in pairs(c:getItems()) do
                    if i:getId() == 23721 then
                        g_game.open(i, c)
                    end
                end
            end
        end
    end)
    return CaveBot.delay(1500)
end

-- getSpectator patterns
-- param1 - pos/creature
-- param2 - pattern
-- param3 - type of return
-- 1 - everyone, 2 - monsters, 3 - players
-- returns number
function getCreaturesInArea(param1, param2, param3)
    local specs = 0
    local monsters = 0
    local players = 0
    for i, spec in pairs(getSpectators(param1, param2)) do
        if spec ~= player then
            specs = specs + 1
            if spec:isMonster() and
                (g_game.getClientVersion() < 960 or spec:getType() < 3) then
                monsters = monsters + 1
            elseif spec:isPlayer() and not isFriend(spec:getName()) then
                players = players + 1
            end
        end
    end

    if param3 == 1 then
        return specs
    elseif param3 == 2 then
        return monsters
    else
        return players
    end
end

-- can be improved
-- TODO in future
-- uses getCreaturesInArea, specType
-- returns number
function getBestTileByPatern(pattern, specType, maxDist, safe)
    if not pattern or not specType then return end
    if not maxDist then maxDist = 4 end

    local bestTile = nil
    local best = nil
    for _, tile in pairs(g_map.getTiles(posz())) do
        if distanceFromPlayer(tile:getPosition()) <= maxDist then
            local minimapColor = g_map.getMinimapColor(tile:getPosition())
            local stairs = (minimapColor >= 210 and minimapColor <= 213)
            if tile:canShoot() and tile:isWalkable() then
                if getCreaturesInArea(tile:getPosition(), pattern, specType) > 0 then
                    if (not safe or
                        getCreaturesInArea(tile:getPosition(), pattern, 3) == 0) then
                        local candidate =
                            {
                                pos = tile,
                                count = getCreaturesInArea(tile:getPosition(),
                                                           pattern, specType)
                            }
                        if not best or best.count <= candidate.count then
                            best = candidate
                        end
                    end
                end
            end
        end
    end

    bestTile = best

    if bestTile then
        return bestTile
    else
        return false
    end
end

-- returns container object based on name
function getContainerByName(name, notFull)
    if type(name) ~= "string" then return nil end

    local d = nil
    for i, c in pairs(getContainers()) do
        if c:getName():lower() == name:lower() and (not notFull or not containerIsFull(c)) then
            d = c
            break
        end
    end
    return d
end

-- returns container object based on container ID
function getContainerByItem(id, notFull)
    if type(id) ~= "number" then return nil end

    local d = nil
    for i, c in pairs(getContainers()) do
        if c:getContainerItem():getId() == id and (not notFull or not containerIsFull(c)) then
            d = c
            break
        end
    end
    return d
end

-- [[ ready to use getSpectators patterns ]] --
LargeUeArea = [[
    0000001000000
    0000011100000
    0000111110000
    0001111111000
    0011111111100
    0111111111110
    1111111111111
    0111111111110
    0011111111100
    0001111111000
    0000111110000
    0000011100000
    0000001000000
]]

NormalUeAreaMs = [[
    00000100000
    00011111000
    00111111100
    01111111110
    01111111110
    11111111111
    01111111110
    01111111110
    00111111100
    00001110000
    00000100000
]]

NormalUeAreaEd = [[
    00000100000
    00001110000
    00011111000
    00111111100
    01111111110
    11111111111
    01111111110
    00111111100
    00011111000
    00001110000
    00000100000
]]

smallUeArea = [[
    0011100
    0111110
    1111111
    1111111
    1111111
    0111110
    0011100
]]

largeRuneArea = [[
    0011100
    0111110
    1111111
    1111111
    1111111
    0111110
    0011100
]]

adjacentArea = [[
    111
    101
    111
]]

longBeamArea = [[
    0000000N0000000
    0000000N0000000
    0000000N0000000
    0000000N0000000
    0000000N0000000
    0000000N0000000
    0000000N0000000
    WWWWWWW0EEEEEEE
    0000000S0000000
    0000000S0000000
    0000000S0000000
    0000000S0000000
    0000000S0000000
    0000000S0000000
    0000000S0000000
]]

shortBeamArea = [[
    00000100000
    00000100000
    00000100000
    00000100000
    00000100000
    EEEEE0WWWWW
    00000S00000
    00000S00000
    00000S00000
    00000S00000
    00000S00000
]]

newWaveArea = [[
    000NNNNN000
    000NNNNN000
    0000NNN0000
    WW00NNN00EE
    WWWW0N0EEEE
    WWWWW0EEEEE
    WWWW0S0EEEE
    WW00SSS00EE
    0000SSS0000
    000SSSSS000
    000SSSSS000
]]

bigWaveArea = [[
    0000NNN0000
    0000NNN0000
    0000NNN0000
    00000N00000
    WWW00N00EEE
    WWWWW0EEEEE
    WWW00S00EEE
    00000S00000
    0000SSS0000
    0000SSS0000
    0000SSS0000
]]

smallWaveArea = [[
    00NNN00
    00NNN00
    WW0N0EE
    WWW0EEE
    WW0S0EE
    00SSS00
    00SSS00
]]

diamondArrowArea = [[
    01110
    11111
    11111
    11111
    01110
]]

----------------------------------------------------------------
---------------------To-do----------------------------------
----------------------------------------------------------------
-- Multi Channels
-- 8-D
-- randomPitch, randomVolume
-- move options/sounds to here
-- cache
-- ambienceObjectStream with onAddThing and onPositionChange ?
-- uiSound with onTalk ? UIWidget-onClick ?
----------------------------------------------------------------
---------------------Variables----------------------------------
----------------------------------------------------------------
local debugMode = false

function toggleDebugMode()
    -- modules.game_sound.toggleDebugMode()
    debugMode = not debugMode
    if debugMode then
        print("Debug mode enabled")
    else
        print("Debug mode disabled")
    end
end

local function createEffectAtPosition(pos, effectId)
    local effect = Effect.create()
    effect:setId(effectId)
    g_map.addThing(effect, pos)
end

local function createMissileBetweenPositions(fromPos, toPos, missileId)
    local missile = Missile.create()
    missile:setId(missileId)
    missile:setPath(fromPos, toPos)
    g_map.addThing(missile, fromPos)
end

local function debugTablePrint(title, data)
    local function createSeparator(length)
        return string.rep("=", length)
    end

    local function createRow(cells, separator)
        local row = ""
        for i, cell in ipairs(cells) do
            row = row .. tostring(cell)
            if i < #cells then
                row = row .. (separator or "    ")
            end
        end
        return row
    end

    local title_fill = createSeparator(title:len())
    local header_str = '\n' .. createSeparator(title:len() + 8) .. '\n'
    header_str = header_str .. '=== ' .. title .. ' ===\n'
    header_str = header_str .. createSeparator(title:len() + 8) .. '\n'

    local output = {}
    table.insert(output, "Missile created from")
    table.insert(output, createSeparator(80))

    -- Positions
    table.insert(output, "Positions")
    table.insert(output, createRow(
        {"Position Sonido", "x= " .. data.soundPos.x, "y= " .. data.soundPos.y, "z= " .. data.soundPos.z}))
    table.insert(output, createRow(
        {"Posicion del player", "x= " .. data.playerPos.x, "y= " .. data.playerPos.y, "z= " .. data.playerPos.z}))
    
        table.insert(output, createRow({"distanceCalculate", data.distanceCalculate}))
        table.insert(output, createRow({"gainCalculate", data.gainCalculate}))
        table.insert(output, createSeparator(80))

    -- Sound Info
    table.insert(output, "Info del sonido")
    table.insert(output, createRow({"g_sounds.soundIds(soundID)", data.soundEffectType}))
    table.insert(output, createRow({"g_sounds.getSoundEffectType(soundID)", data.getSoundEffectType}))
    table.insert(output, createRow({"channelId", data.channelId}))

    local footer_str = '\n' .. createSeparator(title:len() + 8) .. '\n'
    if data.color == "#FFFF00" then
        pwarning(header_str .. table.concat(output, "\n") .. footer_str)
    else
        perror(header_str .. table.concat(output, "\n") .. footer_str)

    end
    -- parseColoredText(header_str .. table.concat(output, "\n") .. footer_str)
end

----------------------------------------------------------------
---------------------Variables----------------------------------
----------------------------------------------------------------

local soundType = {
    NUMERIC_SOUND_TYPE_UNKNOWN = 0,
    NUMERIC_SOUND_TYPE_SPELL_ATTACK = 1,
    NUMERIC_SOUND_TYPE_SPELL_HEALING = 2,
    NUMERIC_SOUND_TYPE_SPELL_SUPPORT = 3,
    NUMERIC_SOUND_TYPE_WEAPON_ATTACK = 4,
    NUMERIC_SOUND_TYPE_CREATURE_NOISE = 5,
    NUMERIC_SOUND_TYPE_CREATURE_DEATH = 6,
    NUMERIC_SOUND_TYPE_CREATURE_ATTACK = 7,
    NUMERIC_SOUND_TYPE_AMBIENCE_STREAM = 8,
    NUMERIC_SOUND_TYPE_FOOD_AND_DRINK = 9,
    NUMERIC_SOUND_TYPE_ITEM_MOVEMENT = 10,
    NUMERIC_SOUND_TYPE_EVENT = 11,
    NUMERIC_SOUND_TYPE_UI = 12,
    NUMERIC_SOUND_TYPE_WHISPER_WITHOUT_OPEN_CHAT = 13,
    NUMERIC_SOUND_TYPE_CHAT_MESSAGE = 14,
    NUMERIC_SOUND_TYPE_PARTY = 15,
    NUMERIC_SOUND_TYPE_VIP_LIST = 16,
    NUMERIC_SOUND_TYPE_RAID_ANNOUNCEMENT = 17,
    NUMERIC_SOUND_TYPE_SERVER_MESSAGE = 18,
    NUMERIC_SOUND_TYPE_SPELL_GENERIC = 19
}

local MusicType = {
    MUSIC_TYPE_UNKNOWN = 0,
    MUSIC_TYPE_MUSIC = 1,
    MUSIC_TYPE_MUSIC_IMMEDIATE = 2,
    MUSIC_TYPE_MUSIC_TITLE = 3
}

local soundSource = {
    GLOBAL = 0,
    OWN = 1,
    OTHERS = 2,
    CREATURES = 3
}

----------------------------------------------------------------
---------------------getConfig----------------------------------
----------------------------------------------------------------
-- LuaFormatter off
local function getSoundConfig()
    return {
        panelSound = {
            masterVolume = modules.client_options.getOption('soundMaster'),
            musicVolume = modules.client_options.getOption('soundMusic'),
            anthem = modules.client_options.getOption('soundAnthem'),
            ambienceVolume = modules.client_options.getOption('soundAmbience'),
            items = modules.client_options.getOption('soundItems'),
            foodAndBeverages = modules.client_options.getOption('soundFoodAndBeverages'),
            moveItem = modules.client_options.getOption('soundMoveItem'),
            eventVolume = modules.client_options.getOption('soundEventVolume')
        },
        battleSound = {
            [soundSource.GLOBAL] = {
                volume = modules.client_options.getOption('battleSoundOwnBattle'),
                subChannels = {
                }
            },
            [soundSource.OWN] = {
                volume = modules.client_options.getOption('battleSoundOwnBattle'),
                subChannels = {
                    [-1] = modules.client_options.getOption('battleSoundOwnBattlesubChannelsSpells'), -- UI disable?
                    [soundType.NUMERIC_SOUND_TYPE_SPELL_ATTACK] = modules.client_options.getOption('battleSoundOwnBattleSubChannelsAttack'),
                    [soundType.NUMERIC_SOUND_TYPE_SPELL_HEALING] = modules.client_options.getOption('battleSoundOwnBattleSoundSubChannelsHealing'),
                    [soundType.NUMERIC_SOUND_TYPE_SPELL_SUPPORT] = modules.client_options.getOption('battleSoundOwnBattleSoundSubChannelsSupport'),
                    [soundType.NUMERIC_SOUND_TYPE_WEAPON_ATTACK] = modules.client_options.getOption('battleSoundOwnBattleSoundSubChannelsWeapons')
                }
            },
            [soundSource.OTHERS] = { 
                volume = modules.client_options.getOption('battleSoundOtherPlayers'),
                subChannels = {
                    [-1] = modules.client_options.getOption('battleSoundOtherPlayersSubChannelsSpells'), -- UI disable?
                    [soundType.NUMERIC_SOUND_TYPE_SPELL_ATTACK] = modules.client_options.getOption('battleSoundOtherPlayersSubChannelsAttack'),
                    [soundType.NUMERIC_SOUND_TYPE_SPELL_HEALING] = modules.client_options.getOption('battleSoundOtherPlayersSubChannelsHealing'),
                    [soundType.NUMERIC_SOUND_TYPE_SPELL_SUPPORT] = modules.client_options.getOption('battleSoundOtherPlayersSubChannelsSupport'),
                    [soundType.NUMERIC_SOUND_TYPE_WEAPON_ATTACK] = modules.client_options.getOption('battleSoundOtherPlayersSubChannelsWeapons'),
                    [soundType.NUMERIC_SOUND_TYPE_CREATURE_NOISE]  = modules.client_options.getOption('battleSoundCreatureSubChannelsNoises'),

                }
            },
            [soundSource.CREATURES] = { 
                volume = modules.client_options.getOption('battleSoundCreature'),
                subChannels = {
                    [soundType.NUMERIC_SOUND_TYPE_CREATURE_NOISE]  = modules.client_options.getOption('battleSoundCreatureSubChannelsNoises'),
                    [soundType.NUMERIC_SOUND_TYPE_CREATURE_DEATH]  = modules.client_options.getOption('battleSoundCreatureSubChannelsNoisesDeath'),
                    [soundType.NUMERIC_SOUND_TYPE_CREATURE_ATTACK] = modules.client_options.getOption('battleSoundCreatureSubChannelsAttacksAndSpells'),
                    [soundType.NUMERIC_SOUND_TYPE_SPELL_ATTACK] = modules.client_options.getOption('battleSoundCreatureSubChannelsAttacksAndSpells'),
                    [soundType.NUMERIC_SOUND_TYPE_WEAPON_ATTACK] = modules.client_options.getOption('battleSoundCreatureSubChannelsAttacksAndSpells')
                }
            }
        },
        uiSound = {
            volume = modules.client_options.getOption('soundUI'),
            subChannels = {
                interactions = modules.client_options.getOption('soundUIsubChannelsInteractions'),
                joinLeaveParty = modules.client_options.getOption('soundUIsubChannelsJoinLeaveParty'),
                vipLoginLogout = modules.client_options.getOption('soundUIsubChannelsVipLoginLogout')
            }
        },
        notifications = {
            subChannels = {
                party = modules.client_options.getOption('soundNotificationsubChannelsParty'),
                guild = modules.client_options.getOption('soundNotificationsubChannelsGuild'),
                localChat = modules.client_options.getOption('soundNotificationsubChannelsLocalChat'),
                privateMessages = modules.client_options.getOption('soundNotificationsubChannelsPrivateMessages'),
                npc = modules.client_options.getOption('soundNotificationsubChannelsNPC'),
                global = modules.client_options.getOption('soundNotificationsubChannelsGlobal'),
                teamFinder = modules.client_options.getOption('soundNotificationsubChannelsTeamFinder'),
                raidAnnouncements = modules.client_options.getOption('soundNotificationsubChannelsRaidAnnuncements'),
                systemAnnouncements = modules.client_options.getOption('soundNotificationsubChannelsSystemAnnouncements')
            }
        }
    }
end
-- LuaFormatter on
----------------------------------------------------------------
---------------------Play--------------------------------------
----------------------------------------------------------------

local function playSoundBasedOnPosition(soundID, pos, max, channel)

    if type(soundID) == "number" then
        soundID = g_sounds.getAudioFileNameById(soundID)
    end
    local playerPos = g_game.getLocalPlayer():getPosition()
    local distance = math.sqrt((pos.x - playerPos.x) ^ 2 + (pos.y - playerPos.y) ^ 2)

    local soundChannel = g_sounds.getChannel(channel)
    if not soundChannel then
        return
    end

    local maxDistance = max or 8 -- extendedview ?
    local gain = math.max(0.1, 1 - (distance / maxDistance))

    local stereoBalance = (pos.x - playerPos.x) / maxDistance

    local active_source = soundChannel:play("/sounds/" .. g_game.getProtocolVersion() .. "/" .. soundID, 0, gain, 1.0)
    if active_source then
        active_source:setPosition({
            x = stereoBalance,
            y = 0
        })
    end
    if debugMode then
        createEffectAtPosition(pos, 4)
        createMissileBetweenPositions(pos, playerPos, 6)
    end
end

----------------------------------------------------------------
---------------------Protocol-----------------------------------
----------------------------------------------------------------

local lastPlayedSounds = {}
local function cleanOldEntries()
    -- TODO improve
    local currentTime = g_clock.millis() / 1000
    for soundID, timestamp in pairs(lastPlayedSounds) do
        if currentTime - timestamp > 10 then 
            lastPlayedSounds[soundID] = nil
        end
    end
end

local function handleSoundPlayback(soundSource2, soundID, pos, channel, debugColor)
    cleanOldEntries()
    local currentTime = g_clock.millis() / 1000
    local cooldownTime = 1 -- in seconds
    if lastPlayedSounds[soundID] and (currentTime - lastPlayedSounds[soundID] < cooldownTime) then
        return
    end

    lastPlayedSounds[soundID] = currentTime

    local soundConfig = getSoundConfig()
    local sourceConfig = soundConfig.battleSound[soundSource2]
    if not sourceConfig or not sourceConfig.volume or sourceConfig.volume == 1 then
        return
    end
    if soundSource2 >= 1 then
        local soundType = g_sounds.getSoundEffectType(soundID)
        local subChannelConfig = sourceConfig.subChannels[soundType]
        if not subChannelConfig then
            return
        end
    end
    local soundIds = g_sounds.getRandomSoundIds(soundID)
    if type(soundIds) == "table" and #soundIds > 0 then
        soundIds = soundIds[math.random(1, #soundIds)]
        playSoundBasedOnPosition(soundIds, pos, 8, channel)
    elseif type(soundIds) == "number" then
        playSoundBasedOnPosition(soundIds, pos, 8, channel)
    end
    if debugMode then
        local playerPos = g_game.getLocalPlayer():getPosition()
        local distance = math.sqrt((pos.x - playerPos.x) ^ 2 + (pos.y - playerPos.y) ^ 2)
        local debugData = {
            color = debugColor,
            soundPos = pos,
            playerPos = playerPos,
            distanceCalculate = distance,
            gainCalculate = math.max(0, 1 - (distance / 8)),
            soundIds = soundIds,
            getSoundEffectType = g_sounds.getSoundEffectType(soundID),
            channelId = channel
        }
        debugTablePrint("Debug Sound Playback", debugData)
    end
end

local function soundMain(soundSource2, soundID, pos)
    handleSoundPlayback(soundSource2, soundID, pos, SoundChannels.Effect, "#FFFF00")
end

local function soundSecondary(SoundENUM, soundSource2, soundID, pos)
    print("what is 'SoundENUM' : ?" .. SoundENUM)
    handleSoundPlayback(soundSource2, soundID, pos, SoundChannels.secundaryChannel, "#FF00003")
end

----------------------------------------------------------------
---------------------Terminal-----------------------------------
----------------------------------------------------------------
local function clearAudios(gameEnd)
    if gameEnd then
        for channelName, channelId in pairs(SoundChannels) do
            if channelId ~= SoundChannels.Music then
                g_sounds.getChannel(channelId):stop()
            end
        end
    else
        g_sounds.stopAll()
    end
end

----------------------------------------------------------------
---------------------Controller-----------------------------------
----------------------------------------------------------------
local function testSound(bool)
    if bool then
        connect(g_sounds, {
            soundMain = soundMain,
            soundSecondary = soundSecondary
        })
    else
        disconnect(g_sounds, {
            soundMain = soundMain,
            soundSecondary = soundSecondary
        })
    end
end

controllerSound = Controller:new()
function controllerSound:onInit()
    if not g_sounds then
        return
    end
    if g_modules.isAutoReloadEnabled() then
        -- registerEvents()
    end
    controllerSound:registerEvents(g_sounds, {
        testSound = testSound
    })

end

function controllerSound:onGameStart()
end

function controllerSound:onGameEnd()
    if not g_sounds then
        return
    end
    clearAudios(true)
end

function controllerSound:onTerminate()
    if g_modules.isAutoReloadEnabled() then
        if not g_sounds then
            return
        end
        clearAudios(false)
        -- unregisterEvents()
    end
end

----------------------------------------------------------------
---------------------Bibliografia-----------------------------------
----------------------------------------------------------------
--[[     
  ---* FRAMEWORK_SOUND
---@class g_sounds
g_sounds = {}

---@param fileName string
function g_sounds.preload(fileName) end

---@param fileName string
---@param fadeTime? number 0.0
---@param gain? number 0.0
---@param pitch? number 0.0
---@return SoundSource
function g_sounds.play(fileName, fadeTime, gain, pitch) end

---@param channelId integer
---@return SoundChannel
function g_sounds.getChannel(channelId) end

function g_sounds.stopAll() end

function g_sounds.enableAudio() end

function g_sounds.disableAudio() end

---@return boolean
function g_sounds.isAudioEnabled() end

---@param pos Point | string
function g_sounds.setPosition(pos) end

---@return SoundSource
function g_sounds.createSoundEffect() end

---@return boolean
function g_sounds.isEaxEnabled() end

---@param file string
---@return boolean
function g_sounds.loadClientFiles(directory) end

---@param audioFileId string
---@return string
function g_sounds.getAudioFileNameById(audioFileId) end

--------------------------------
--------- SoundSource ----------
--------------------------------

---* FRAMEWORK_SOUND
---@class SoundSource
SoundSource = {}

---@return SoundSource
function SoundSource.create(fileName) end

---@param name string
function SoundSource:setName(name) end

function SoundSource:play() end

function SoundSource:stop() end

---@return boolean
function SoundSource:isPlaying() end

---@param gain number
function SoundSource:setGain(gain) end

---@param pos Point | string
function SoundSource:setPosition(pos) end

---@param velocity Point | string
function SoundSource:setVelocity(velocity) end

---@param state number
---@param fadeTime number
function SoundSource:setFading(state, fadeTime) end

---@param looping boolean
function SoundSource:setLooping(looping) end

---@param relative boolean
function SoundSource:setRelative(relative) end

---@param distance number
function SoundSource:setReferenceDistance(distance) end

---@param soundEffect SoundEffect
function SoundSource:setEffect(soundEffect) end

function SoundSource:removeEffect() end

--------------------------------
------ CombinedSoundSource -----
--------------------------------

---* FRAMEWORK_SOUND
---@class CombinedSoundSource : SoundSource
CombinedSoundSource = {}

--------------------------------
------ StreamSoundSource -------
--------------------------------

---* FRAMEWORK_SOUND
---@class StreamSoundSource : SoundSource
StreamSoundSource = {}

--------------------------------
--------- SoundEffect ----------
--------------------------------

---* FRAMEWORK_SOUND
---@class SoundEffect
SoundEffect = {}

---@param presetName string
function SoundEffect:setPreset(presetName) end

--------------------------------
--------- SoundChannel ---------
--------------------------------

---* FRAMEWORK_SOUND
---@class SoundChannel
SoundChannel = {}

---@param fileName string
---@param fadeTime? number 0.0
---@param gain? number 1.0
---@param pitch? number 1.0
---@return SoundSource
function SoundChannel:play(fileName, fadeTime, gain, pitch) end

---@param fadeTime? number 0.0
function SoundChannel:stop(fadeTime) end

---@param fileName string
---@param fadeTime? number 0.0
---@param gain? number 1.0
---@param pitch? number 1.0
function SoundChannel:enqueue(fileName, fadeTime, gain, pitch) end

function SoundChannel:enable() end

function SoundChannel:disable() end

---@param gain number
function SoundChannel:setGain(gain) end

---@return number
function SoundChannel:getGain() end

---@param enabled boolean
function SoundChannel:setEnabled(enabled) end

---@return boolean
function SoundChannel:isEnabled() end

---@return integer
function SoundChannel:getId() end
local availablePresets = {
    "none",
    "generic",
    "paddedCell",
    "room",
    "bathroom",
    "stoneroom",
    "sewerPipe",
    "underWater",
    "dizzy",
    "psychotic",
    "none",
    "generic",
    "paddedcell",
    "room",
    "bathroom",
    "livingroom",
    "stoneroom",
    "auditorium",
    "concerthall",
    "cave",
    "arena",
    "hangar",
    "carpetedhallway",
    "hallway",
    "stonecorridor",
    "alley",
    "forest",
    "city",
    "mountains",
    "quarry",
    "plain",
    "parkinglot",
    "sewerpipe",
    "underwater",
    "drugged",
    "dizzy",
    "psychotic",
    "castleSmallroom",
    "castleShortpassage",
    "castleMediumroom",
    "castleLargeroom",
    "castleLongpassage",
    "castleHall",
    "castleCupboard",
    "castleCourtyard",
    "castleAlcove",
    "factorySmallroom",
    "factoryShortpassage",
    "factoryMediumroom",
    "factoryLargeroom",
    "factoryLongpassage",
    "factoryHall",
    "factoryCupboard",
    "factoryCourtyard",
    "factoryAlcove",
    "icepalaceSmallroom",
    "icepalaceShortpassage",
    "icepalaceMediumroom",
    "icepalaceLargeroom",
    "icepalaceLongpassage",
    "icepalaceHall",
    "icepalaceCupboard",
    "icepalaceCourtyard",
    "icepalaceAlcove",
    "spacestationSmallroom",
    "spacestationShortpassage",
    "spacestationMediumroom",
    "spacestationLargeroom",
    "spacestationLongpassage",
    "spacestationHall",
    "spacestationCupboard",
    "spacestationAlcove",
    "woodenSmallroom",
    "woodenShortpassage",
    "woodenMediumroom",
    "woodenLargeroom",
    "woodenLongpassage",
    "woodenHall",
    "woodenCupboard",
    "woodenCourtyard",
    "woodenAlcove",
    "sportEmptystadium",
    "sportSquashcourt",
    "sportSmallswimmingpool",
    "sportLargeswimmingpool",
    "sportGymnasium",
    "sportFullstadium",
    "sportStadiumtannoy",
    "prefabWorkshop",
    "prefabSchoolroom",
    "prefabPractiseroom",
    "prefabOuthouse",
    "prefabCaravan",
    "domeTomb",
    "pipeSmall",
    "domeSaintpauls",
    "pipeLongthin",
    "pipeLarge",
    "pipeResonant",
    "outdoorsBackyard",
    "outdoorsRollingplains",
    "outdoorsDeepcanyon",
    "outdoorsCreek",
    "outdoorsValley",
    "moodHeaven",
    "moodHell",
    "moodMemory",
    "drivingCommentator",
    "drivingPitgarage",
    "drivingIncarRacer",
    "drivingIncarSports",
    "drivingIncarLuxury",
    "drivingFullgrandstand",
    "drivingEmptygrandstand",
    "drivingTunnel",
    "cityStreets",
    "citySubway",
    "cityMuseum",
    "cityLibrary",
    "cityUnderpass",
    "cityAbandoned",
    "dustyroom",
    "chapel",
    "smallwaterroom",
}

    ]]

local function testThings(tile, thing)
    print(1)
    if not thing:isItem() then
        return
    end
    print(2)
    --[[             
        {
            "id": 13,
            "countedAppearanceTypes": [
              1922,
            ],
            "soundEffects": [
              {
                "count": 1,
                "loopingSoundId": 631
              }
            ],
            "maxSoundDistance": 3
        }
           ]]
    if thing:getId() == 1922 then
        print(3)
        local ogg = g_sounds.getAudioFileNameById(631)
        playSoundBasedOnPosition(ogg, thing:getPosition(), 3)
    end

end

local function onPositionChange(newPos, oldPos)

end

local function test()
    connect(Tile, {
        onAddThing = testThings
    })
    connect(LocalPlayer, {
        onPositionChange = onPositionChange
    })
end
local function test2()
    disconnect(Tile, {
        onAddThing = testThings
    })
    disconnect(LocalPlayer, {
        onPositionChange = onPositionChange
    })
end

/*
 * Copyright (c) 2010-2025 OTClient <https://github.com/edubart/otclient>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#pragma once

#include "global.h"

namespace Proto
{
    enum LoginServerOpts
    {
        LoginServerError = 10,
        LoginServerMotd = 20,
        LoginServerUpdateNeeded = 30,
        LoginServerCharacterList = 100
    };

    enum ItemOpcode
    {
        StaticText = 96,
        UnknownCreature = 97,
        OutdatedCreature = 98,
        Creature = 99
    };

    enum GameServerOpcodes : uint8_t
    {
        GameServerLoginOrPendingState = 10, // 0x0A
        GameServerGMActions = 11, // 0x0B
        GameServerEnterGame = 15, // 0x0F
        GameServerUpdateNeeded = 17, // 0x11
        GameServerLoginError = 20, // 0x14
        GameServerLoginAdvice = 21, // 0x15
        GameServerLoginWait = 22, // 0x16
        GameServerLoginSuccess = 23, // 0x17
        GameServerSessionEnd = 24, // 0x18
        GameServerStoreButtonIndicators = 25, // 0x19
        GameServerBugReport = 26, // 0x1A
        GameServerPingBack = 29, // 0x1D
        GameServerPing = 30, // 0x1E
        GameServerChallenge = 31, // 0x1F
        GameServerDeath = 40, // 0x28
        GameServerSupplyStash = 41, // 0x29
        GameServerSpecialContainer = 42, // 0x2A
        GameServerPartyAnalyzer = 43, // 0x2B

        // all in game opcodes must be greater than 50
        GameServerFirstGameOpcode = 50, // 0x32

        // otclient ONLY
        GameServerExtendedOpcode = 50, // 0x32

        // NOTE: add any custom opcodes in this range
        // 51 - 99
        GameServerChangeMapAwareRange = 51, // 0x33
        GameServerAttchedEffect = 52, // 0x34
        GameServerDetachEffect = 53, // 0x35
        GameServerCreatureShader = 54, // 0x36
        GameServerMapShader = 55, // 0x37
        GameServerCreatureTyping = 56, // 0x38
        GameServerFeatures = 67, // 0x43
        GameServerFloorDescription = 75, // 0x4B

        // original tibia ONLY
        GameServerImbuementDurations = 93, // 0x5D
        GameServerPassiveCooldown = 94, // 0x5E
        GameServerBosstiaryData = 97, // 0x61
        GameServerBosstiarySlots = 98, // 0x62
        GameServerSendClientCheck = 99, // 0x63
        GameServerFullMap = 100, // 0x64
        GameServerMapTopRow = 101, // 0x65
        GameServerMapRightRow = 102, // 0x66
        GameServerMapBottomRow = 103, // 0x67
        GameServerMapLeftRow = 104, // 0x68
        GameServerUpdateTile = 105, // 0x69
        GameServerCreateOnMap = 106, // 0x6A
        GameServerChangeOnMap = 107, // 0x6B
        GameServerDeleteOnMap = 108, // 0x6C
        GameServerMoveCreature = 109, // 0x6D
        GameServerOpenContainer = 110, // 0x6E
        GameServerCloseContainer = 111, // 0x6F
        GameServerCreateContainer = 112, // 0x70
        GameServerChangeInContainer = 113, // 0x71
        GameServerDeleteInContainer = 114, // 0x72
        GameServerBosstiaryInfo = 115, // 0x73
        GameServerTakeScreenshot = 117, // 0x75
        GameServerCyclopediaItemDetail = 118, // 0x76
        GameServerSetInventory = 120, // 0x78
        GameServerDeleteInventory = 121, // 0x79
        GameServerOpenNpcTrade = 122, // 0x7A
        GameServerPlayerGoods = 123, // 0x7B
        GameServerCloseNpcTrade = 124, // 0x7C
        GameServerOwnTrade = 125, // 0x7D
        GameServerCounterTrade = 126, // 0x7E
        GameServerCloseTrade = 127, // 0x7F
        GameServerAmbient = 130, // 0x82
        GameServerGraphicalEffect = 131, // 0x83
        GameServerTextEffect = 132, // 0x84
        GameServerMissleEffect = 133, // Anthem on 13.x
        GameServerItemClasses = 134, // 0x86
        GameServerTrappers = 135, // 0x87
        GameServerCloseForgeWindow = 137, // 0x89
        GameServerCreatureData = 139, // 0x8B
        GameServerCreatureHealth = 140, // 0x8C
        GameServerCreatureLight = 141, // 0x8D
        GameServerCreatureOutfit = 142, // 0x8E
        GameServerCreatureSpeed = 143, // 0x8F
        GameServerCreatureSkull = 144, // 0x90
        GameServerCreatureParty = 145, // 0x91
        GameServerCreatureUnpass = 146, // 0x92
        GameServerCreatureMarks = 147, // 0x93
        GameServerPlayerHelpers = 148, // 0x94
        GameServerCreatureType = 149, // 0x95
        GameServerEditText = 150, // 0x96
        GameServerEditList = 151, // 0x97
        GameServerSendGameNews = 152, // 0x98
        GameServerSendBlessDialog = 155, // 0x9B
        GameServerBlessings = 156, // 0x9C
        GameServerPreset = 157, // 0x9D
        GameServerPremiumTrigger = 158, // 0x9E
        GameServerPlayerDataBasic = 159, // 0x9F
        GameServerPlayerData = 160, // 0xA0
        GameServerPlayerSkills = 161, // 0xA1
        GameServerPlayerState = 162, // 0xA2
        GameServerClearTarget = 163, // 0xA3
        GameServerSpellDelay = 164, // 0xA4
        GameServerSpellGroupDelay = 165, // 0xA5
        GameServerMultiUseDelay = 166, // 0xA6
        GameServerPlayerModes = 167, // 0xA7
        GameServerSetStoreDeepLink = 168, // 0xA8
        GameServerSendRestingAreaState = 169, // 0xA9
        GameServerTalk = 170, // 0xAA
        GameServerChannels = 171, // 0xAB
        GameServerOpenChannel = 172, // 0xAC
        GameServerOpenPrivateChannel = 173, // 0xAD
        GameServerRuleViolationChannel = 174, // 0xAE
        GameServerRuleViolationRemove = 175, // 0xAF
        GameServerRuleViolationCancel = 176, // 0xB0
        GameServerRuleViolationLock = 177, // 0xB1
        GameServerOpenOwnChannel = 178, // 0xB2
        GameServerCloseChannel = 179, // 0xB3
        GameServerTextMessage = 180, // 0xB4
        GameServerCancelWalk = 181, // 0xB5
        GameServerWalkWait = 182, // 0xB6
        GameServerUnjustifiedStats = 183, // 0xB7
        GameServerPvpSituations = 184, // 0xB8
        GameServerBestiaryRefreshTracker = 185, // 0xB9
        GameServerTaskHuntingBasicData = 186, // 0xBA
        GameServerTaskHuntingData = 187, // 0xBB
        GameServerBosstiaryCooldownTimer = 189, // 0xBD
        GameServerFloorChangeUp = 190, // 0xBE
        GameServerFloorChangeDown = 191, // 0xBF
        GameServerLootContainers = 192, // 0xC0
        GameServerMonkData = 193, // 0xC1
        GameServerCyclopediaHouseAuctionMessage = 195, // 0xC3
        GameServerCyclopediaHousesInfo = 198, // 0xC6
        GameServerCyclopediaHouseList = 199, // 0xC7
        GameServerChooseOutfit = 200, // 0xC8
        GameServerSendUpdateImpactTracker = 204, // 0xCC
        GameServerSendItemsPrice = 205, // 0xCD
        GameServerSendUpdateSupplyTracker = 206, // 0xCE
        GameServerSendUpdateLootTracker = 207, // 0xCF
        GameServerQuestTracker = 208, // 0xD0
        GameServerKillTracker = 209, // 0xD1
        GameServerVipAdd = 210, // 0xD2
        GameServerVipState = 211, // 0xD3
        GameServerVipLogout = 212, // 0xD4
        GameServerBestiaryRaces = 213, // 0xD5
        GameServerBestiaryOverview = 214, // 0xD6
        GameServerBestiaryMonsterData = 215, // 0xD7
        GameServerBestiaryCharmsData = 216, // 0xD8
        GameServerBestiaryEntryChanged = 217, // 0xD9
        GameServerCyclopediaCharacterInfoData = 218, // 0xDA
        GameServerTutorialHint = 220, // 0xDC
        GameServerAutomapFlag = 221, // 0xDD
        GameServerSendDailyRewardCollectionState = 222, // 0xDE
        GameServerCoinBalance = 223, // 0xDF
        GameServerStoreError = 224, // 0xE0
        GameServerRequestPurchaseData = 225, // 0xE1
        GameServerSendOpenRewardWall = 226, // 0xE2
        GameServerSendDailyReward = 228, // 0xE4
        GameServerSendRewardHistory = 229, // 0xE5
        GameServerSendPreyFreeRerolls = 230, // 0xE6
        GameServerSendPreyTimeLeft = 231, // 0xE7
        GameServerSendPreyData = 232, // 0xE8
        GameServerSendPreyRerollPrice = 233, // 0xE9
        GameServerSendShowDescription = 234, // 0xEA
        GameServerSendImbuementWindow = 235, // 0xEB
        GameServerSendCloseImbuementWindow = 236, // 0xEC
        GameServerSendError = 237, // 0xED
        GameServerResourceBalance = 238, // 0xEE
        GameServerWorldTime = 239, // 0xEF
        GameServerQuestLog = 240, // 0xF0
        GameServerQuestLine = 241, // 0xF1
        GameServerCoinBalanceUpdating = 242, // 0xF2
        GameServerChannelEvent = 243, // 0xF3
        GameServerItemInfo = 244, // 0xF4
        GameServerPlayerInventory = 245, // 0xF5
        GameServerMarketEnter = 246, // 0xF6
        GameServerMarketLeave = 247, // 0xF7
        GameServerMarketDetail = 248, // 0xF8
        GameServerMarketBrowse = 249, // 0xF9
        GameServerModalDialog = 250, // 0xFA
        GameServerStore = 251, // 0xFB
        GameServerStoreOffers = 252, // 0xFC
        GameServerStoreTransactionHistory = 253, // 0xFD
        GameServerStoreCompletePurchase = 254 // 0xFE
    };

    enum ClientOpcodes : uint8_t
    {
        ClientEnterAccount = 1,
        ClientPendingGame = 10,
        ClientEnterGame = 15,
        ClientLeaveGame = 20,
        ClientPing = 29,
        ClientPingBack = 30,
        ClientUseStash = 40,
        ClientBestiaryTrackerStatus = 42,
        ClientPartyAnalyzerAction = 43,

        // all in game opcodes must be equal or greater than 50
        ClientFirstGameOpcode = 50,

        // otclient ONLY
        ClientExtendedOpcode = 50,
        ClientChangeMapAwareRange = 51,

        // NOTE: add any custom opcodes in this range
        // 51 - 99

        // original tibia ONLY
        ClientImbuementDurations = 96,
        ClientAutoWalk = 100,
        ClientWalkNorth = 101,
        ClientWalkEast = 102,
        ClientWalkSouth = 103,
        ClientWalkWest = 104,
        ClientStop = 105,
        ClientWalkNorthEast = 106,
        ClientWalkSouthEast = 107,
        ClientWalkSouthWest = 108,
        ClientWalkNorthWest = 109,
        ClientTurnNorth = 111,
        ClientTurnEast = 112,
        ClientTurnSouth = 113,
        ClientTurnWest = 114,
        ClientGmTeleport = 115,
        ClientEquipItem = 119,
        ClientMove = 120,
        ClientInspectNpcTrade = 121,
        ClientBuyItem = 122,
        ClientSellItem = 123,
        ClientCloseNpcTrade = 124,
        ClientRequestTrade = 125,
        ClientInspectTrade = 126,
        ClientAcceptTrade = 127,
        ClientRejectTrade = 128,
        ClientUseItem = 130,
        ClientUseItemWith = 131,
        ClientUseOnCreature = 132,
        ClientRotateItem = 133,
        ClientCloseContainer = 135,
        ClientUpContainer = 136,
        ClientEditText = 137,
        ClientEditList = 138,
        ClientOnWrapItem = 139,
        ClientLook = 140,
        ClientLookCreature = 141,
        ClientSendQuickLoot = 143,
        ClientLootContainer = 144,
        ClientQuickLootBlackWhitelist = 145,
        ClientTalk = 150,
        ClientRequestChannels = 151,
        ClientJoinChannel = 152,
        ClientLeaveChannel = 153,
        ClientOpenPrivateChannel = 154,
        ClientOpenRuleViolation = 155,
        ClientCloseRuleViolation = 156,
        ClientCancelRuleViolation = 157,
        ClientCloseNpcChannel = 158,
        ClientChangeFightModes = 160,
        ClientAttack = 161,
        ClientFollow = 162,
        ClientInviteToParty = 163,
        ClientJoinParty = 164,
        ClientRevokeInvitation = 165,
        ClientPassLeadership = 166,
        ClientLeaveParty = 167,
        ClientShareExperience = 168,
        ClientDisbandParty = 169,
        ClientOpenOwnChannel = 170,
        ClientInviteToOwnChannel = 171,
        ClientExcludeFromOwnChannel = 172,
        ClientCyclopediaHouseAuction = 173,
        ClientBosstiaryRequestInfo = 174,
        ClientBosstiaryRequestSlotInfo = 175,
        ClientBosstiaryRequestSlotAction = 176,
        ClientRequestHighscore = 177,
        ClientCancelAttackAndFollow = 190,
        ClientForgeEnter = 191,
        ClientForgeBrowseHistory = 192,
        ClientUpdateTile = 201,
        ClientRefreshContainer = 202,
        ClientBrowseField = 203,
        ClientSeekInContainer = 204,
        ClientInspectionObject = 205,
        ClientRequestBless = 207,
        ClientRequestTrackerQuestLog = 208,
        ClientRequestOutfit = 210,
        ClientChangeOutfit = 211,
        ClientMount = 212,
        ClientApplyImbuement = 213,
        ClientClearImbuement = 214,
        ClientCloseImbuingWindow = 215,
        ClientOpenRewardWall = 216,
        ClientOpenRewardHistory = 217,
        sendGetRewardDaily = 218,
        ClientAddVip = 220,
        ClientRemoveVip = 221,
        ClientEditVip = 222,
        ClientEditVipGroups = 223,
        ClientBestiaryRequest = 225,
        ClientBestiaryRequestOverview = 226,
        ClientBestiaryRequestSearch = 227,
        ClientCyclopediaSendBuyCharmRune = 228,
        ClientCyclopediaRequestCharacterInfo = 229,
        ClientBugReport = 230,
        ClientRuleViolation = 231,
        ClientDebugReport = 232,
        ClientPreyAction = 235,
        ClientPreyRequest = 237,
        ClientTransferCoins = 239,
        ClientRequestQuestLog = 240,
        ClientRequestQuestLine = 241,
        ClientNewRuleViolation = 242,
        ClientRequestItemInfo = 243,
        ClientMarketLeave = 244,
        ClientMarketBrowse = 245,
        ClientMarketCreate = 246,
        ClientMarketCancel = 247,
        ClientMarketAccept = 248,
        ClientAnswerModalDialog = 249,
        ClientOpenStore = 250,
        ClientRequestStoreOffers = 251,
        ClientBuyStoreOffer = 252,
        ClientOpenTransactionHistory = 253,
        ClientRequestTransactionHistory = 254
    };

    enum CreatureType
    {
        CreatureTypePlayer = 0,
        CreatureTypeMonster,
        CreatureTypeNpc,
        CreatureTypeSummonOwn,
        CreatureTypeSummonOther,
        CreatureTypeHidden,
        CreatureTypeUnknown = 0xFF
    };

    enum CreaturesIdRange
    {
        PlayerStartId = 0x10000000,
        PlayerEndId = 0x40000000,
        MonsterStartId = 0x40000000,
        MonsterEndId = 0x80000000,
        NpcStartId = 0x80000000,
        NpcEndId = 0xffffffff
    };

    void buildMessageModesMap(int version);
    Otc::MessageMode translateMessageModeFromServer(uint8_t mode);
    uint8_t translateMessageModeToServer(Otc::MessageMode mode);
}

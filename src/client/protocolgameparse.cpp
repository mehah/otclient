/*
* Copyright (c) 2010-2022 OTClient <https://github.com/edubart/otclient>
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

#include "protocolgame.h"

#include "effect.h"
#include "framework/net/inputmessage.h"

#include <framework/core/eventdispatcher.h>
#include "item.h"
#include "localplayer.h"
#include "luavaluecasts_client.h"
#include "map.h"
#include "missile.h"
#include "statictext.h"
#include "thingtypemanager.h"
#include "attachedeffectmanager.h"
#include "tile.h"
#include "time.h"

void ProtocolGame::parseMessage(const InputMessagePtr& msg)
{
    int opcode = -1;
    int prevOpcode = -1;

    try {
        while (!msg->eof()) {
            opcode = msg->getU8();

            // must be > so extended will be enabled before GameStart.
            if (!g_game.getFeature(Otc::GameLoginPending)) {
                if (!m_gameInitialized && opcode > Proto::GameServerFirstGameOpcode) {
                    g_game.processGameStart();
                    m_gameInitialized = true;
                }
            }

            // try to parse in lua first
            const int readPos = msg->getReadPos();
            if (callLuaField<bool>("onOpcode", opcode, msg))
                continue;
            msg->setReadPos(readPos);
            // restore read pos

            switch (opcode) {
                case Proto::GameServerLoginOrPendingState: // 10
                    if (g_game.getFeature(Otc::GameLoginPending))
                        parsePendingGame(msg);
                    else
                        parseLogin(msg);
                    break;
                case Proto::GameServerGMActions: // 11
                    parseGMActions(msg);
                    break;
                case Proto::GameServerEnterGame: // 15
                    parseEnterGame(msg);
                    break;
                case Proto::GameServerUpdateNeeded: // 17
                    parseUpdateNeeded(msg);
                    break;
                case Proto::GameServerLoginError: // 20
                    parseLoginError(msg);
                    break;
                case Proto::GameServerLoginAdvice: // 21
                    parseLoginAdvice(msg);
                    break;
                case Proto::GameServerLoginWait: // 22
                    parseLoginWait(msg);
                    break;
                case Proto::GameServerLoginSuccess: // 23
                    parseLogin(msg);
                    break;
                case Proto::GameServerSessionEnd: // 24
                    parseSessionEnd(msg);
                    break;
                case Proto::GameServerStoreButtonIndicators: // 25
                    parseStoreButtonIndicators(msg);
                    break;
                case Proto::GameServerBugReport: // 26
                    parseBugReport(msg);
                    break;
                case Proto::GameServerPingBack: // 29
                case Proto::GameServerPing: // 30
                    if (((opcode == Proto::GameServerPing) && (g_game.getFeature(Otc::GameClientPing))) ||
                        ((opcode == Proto::GameServerPingBack) && !g_game.getFeature(Otc::GameClientPing)))
                        parsePingBack(msg);
                    else
                        parsePing(msg);
                    break;
                case Proto::GameServerChallenge: // 31
                    parseChallenge(msg);
                    break;
                case Proto::GameServerDeath: // 40
                    parseDeath(msg);
                    break;
                case Proto::GameServerSupplyStash: // 41
                    parseSupplyStash(msg);
                    break;
                case Proto::GameServerSpecialContainer: // 42
                    parseSpecialContainer(msg);
                    break;
                case Proto::GameServerPartyAnalyzer: // 43
                    parsePartyAnalyzer(msg);
                    break;
                case Proto::GameServerExtendedOpcode: // 50 - otclient only
                    parseExtendedOpcode(msg);
                    break;
                case Proto::GameServerChangeMapAwareRange: // 51
                    parseChangeMapAwareRange(msg);
                    break;
                case Proto::GameServerAttchedEffect: // 52
                    parseAttachedEffect(msg);
                    break;
                case Proto::GameServerDetachEffect: // 53
                    parseDetachEffect(msg);
                    break;
                case Proto::GameServerCreatureShader: // 54
                    parseCreatureShader(msg);
                    break;
                case Proto::GameServerMapShader: // 55
                    parseMapShader(msg);
                    break;
                case Proto::GameServerCreatureTyping: // 56
                    parseCreatureTyping(msg);
                    break;
                case Proto::GameServerFloorDescription: // 75
                    parseFloorDescription(msg);
                    break;
                case Proto::GameServerImbuementDurations: // 93
                    parseImbuementDurations(msg);
                    break;
                case Proto::GameServerPassiveCooldown: // 94
                    parsePassiveCooldown(msg);
                    break;
                case Proto::GameServerBosstiaryData: // 97
                    parseBosstiaryData(msg);
                    break;
                case Proto::GameServerBosstiarySlots: // 98
                    parseBosstiarySlots(msg);
                    break;
                case Proto::GameServerSendClientCheck: // 99
                    parseClientCheck(msg);
                    break;
                case Proto::GameServerFullMap: // 100
                    parseMapDescription(msg);
                    break;
                case Proto::GameServerMapTopRow: // 101
                    parseMapMoveNorth(msg);
                    break;
                case Proto::GameServerMapRightRow: // 102
                    parseMapMoveEast(msg);
                    break;
                case Proto::GameServerMapBottomRow: // 103
                    parseMapMoveSouth(msg);
                    break;
                case Proto::GameServerMapLeftRow: // 104
                    parseMapMoveWest(msg);
                    break;
                case Proto::GameServerUpdateTile: // 105
                    parseUpdateTile(msg);
                    break;
                case Proto::GameServerCreateOnMap: // 106
                    parseTileAddThing(msg);
                    break;
                case Proto::GameServerChangeOnMap: // 107
                    parseTileTransformThing(msg);
                    break;
                case Proto::GameServerDeleteOnMap: // 108
                    parseTileRemoveThing(msg);
                    break;
                case Proto::GameServerMoveCreature: // 109
                    parseCreatureMove(msg);
                    break;
                case Proto::GameServerOpenContainer: // 110
                    parseOpenContainer(msg);
                    break;
                case Proto::GameServerCloseContainer: // 111
                    parseCloseContainer(msg);
                    break;
                case Proto::GameServerCreateContainer: // 112
                    parseContainerAddItem(msg);
                    break;
                case Proto::GameServerChangeInContainer: // 113
                    parseContainerUpdateItem(msg);
                    break;
                case Proto::GameServerDeleteInContainer: // 114
                    parseContainerRemoveItem(msg);
                    break;
                case Proto::GameServerTakeScreenshot: // 117
                    parseTakeScreenshot(msg);
                    break;
                case Proto::GameServerSetInventory: // 120
                    parseAddInventoryItem(msg);
                    break;
                case Proto::GameServerDeleteInventory: // 121
                    parseRemoveInventoryItem(msg);
                    break;
                case Proto::GameServerOpenNpcTrade: // 122
                    parseOpenNpcTrade(msg);
                    break;
                case Proto::GameServerPlayerGoods: // 123
                    parsePlayerGoods(msg);
                    break;
                case Proto::GameServerCloseNpcTrade: // 124
                    parseCloseNpcTrade(msg);
                    break;
                case Proto::GameServerOwnTrade: // 125
                    parseOwnTrade(msg);
                    break;
                case Proto::GameServerCounterTrade: // 126
                    parseCounterTrade(msg);
                    break;
                case Proto::GameServerCloseTrade: // 127
                    parseCloseTrade(msg);
                    break;
                case Proto::GameServerAmbient: // 130
                    parseWorldLight(msg);
                    break;
                case Proto::GameServerGraphicalEffect: // 131
                    parseMagicEffect(msg);
                    break;
                case Proto::GameServerTextEffect: // 132
                    parseAnimatedText(msg);
                    break;
                case Proto::GameServerMissleEffect: // 133
                    if (g_game.getFeature(Otc::GameAnthem)) {
                        parseAnthem(msg);
                    } else {
                        parseDistanceMissile(msg);
                    }
                    break;
                case Proto::GameServerItemClasses: // 134
                    if (g_game.getClientVersion() >= 1281)
                        parseItemClasses(msg);
                    else
                        parseCreatureMark(msg);
                    break;
                case Proto::GameServerTrappers: // 135
                    parseTrappers(msg);
                    break;
                case Proto::GameServerCreatureData: // 139
                    parseCreatureData(msg);
                    break;
                case Proto::GameServerCreatureHealth: // 140
                    parseCreatureHealth(msg);
                    break;
                case Proto::GameServerCreatureLight: // 141
                    parseCreatureLight(msg);
                    break;
                case Proto::GameServerCreatureOutfit: // 142
                    parseCreatureOutfit(msg);
                    break;
                case Proto::GameServerCreatureSpeed: // 143
                    parseCreatureSpeed(msg);
                    break;
                case Proto::GameServerCreatureSkull: // 144
                    parseCreatureSkulls(msg);
                    break;
                case Proto::GameServerCreatureParty: // 145
                    parseCreatureShields(msg);
                    break;
                case Proto::GameServerCreatureUnpass: // 146
                    parseCreatureUnpass(msg);
                    break;
                case Proto::GameServerCreatureMarks: // 147
                    parseCreaturesMark(msg);
                    break;
                case Proto::GameServerPlayerHelpers: // 148
                    parsePlayerHelpers(msg);
                    break;
                case Proto::GameServerCreatureType: // 149
                    parseCreatureType(msg);
                    break;
                case Proto::GameServerEditText: // 150
                    parseEditText(msg);
                    break;
                case Proto::GameServerEditList: // 151
                    parseEditList(msg);
                    break;
                case Proto::GameServerSendGameNews: // 152
                    parseGameNews(msg);
                    break;
                case Proto::GameServerSendBlessDialog: // 155
                    parseBlessDialog(msg);
                    break;
                case Proto::GameServerBlessings: // 156
                    parseBlessings(msg);
                    break;
                case Proto::GameServerPreset: // 157
                    parsePreset(msg);
                    break;
                case Proto::GameServerPremiumTrigger: // 158
                    parsePremiumTrigger(msg);
                    break;
                case Proto::GameServerPlayerDataBasic: // 159
                    parsePlayerInfo(msg);
                    break;
                case Proto::GameServerPlayerData: // 160
                    parsePlayerStats(msg);
                    break;
                case Proto::GameServerPlayerSkills: // 161
                    parsePlayerSkills(msg);
                    break;
                case Proto::GameServerPlayerState: // 162
                    parsePlayerState(msg);
                    break;
                case Proto::GameServerClearTarget: // 163
                    parsePlayerCancelAttack(msg);
                    break;
                case Proto::GameServerSpellDelay: // 164
                    parseSpellCooldown(msg);
                    break;
                case Proto::GameServerSpellGroupDelay: // 165
                    parseSpellGroupCooldown(msg);
                    break;
                case Proto::GameServerMultiUseDelay: // 166
                    parseMultiUseCooldown(msg);
                    break;
				case Proto::GameServerPlayerModes: // 167
                    parsePlayerModes(msg);
                    break;
                case Proto::GameServerSetStoreDeepLink: // 168
                    parseSetStoreDeepLink(msg);
                    break;
                case Proto::GameServerSendRestingAreaState: // 169
                    parseRestingAreaState(msg);
                    break;
                case Proto::GameServerTalk: // 170
                    parseTalk(msg);
                    break;
                case Proto::GameServerChannels: // 171
                    parseChannelList(msg);
                    break;
                case Proto::GameServerOpenChannel: // 172
                    parseOpenChannel(msg);
                    break;
                case Proto::GameServerOpenPrivateChannel: // 173
                    parseOpenPrivateChannel(msg);
                    break;
                case Proto::GameServerRuleViolationChannel: // 174
                    parseRuleViolationChannel(msg);
                    break;
                case Proto::GameServerRuleViolationRemove: // 175
                    if (g_game.getClientVersion() >= 1200)
                        parseExperienceTracker(msg);
                    else
                        parseRuleViolationRemove(msg);
                    break;
                case Proto::GameServerRuleViolationCancel: // 176
                    parseRuleViolationCancel(msg);
                    break;
                case Proto::GameServerRuleViolationLock: // 177
                    if (g_game.getClientVersion() >= 1310)
                        parseHighscores(msg);
                    else
                        parseRuleViolationLock(msg);
                    break;
                case Proto::GameServerOpenOwnChannel: // 178
                    parseOpenOwnPrivateChannel(msg);
                    break;
                case Proto::GameServerCloseChannel: // 179
                    parseCloseChannel(msg);
                    break;
                case Proto::GameServerTextMessage: // 180
                    parseTextMessage(msg);
                    break;
                case Proto::GameServerCancelWalk: // 181
                    parseCancelWalk(msg);
                    break;
                case Proto::GameServerWalkWait: // 182
                    parseWalkWait(msg);
                    break;
                case Proto::GameServerUnjustifiedStats: // 183
                    parseUnjustifiedStats(msg);
                    break;
                case Proto::GameServerPvpSituations: // 184
                    parsePvpSituations(msg);
                    break;
                case Proto::GameServerRefreshBestiaryTracker: // 185
                    parseBestiaryTracker(msg);
                    break;
                case Proto::GameServerTaskHuntingBasicData: // 186
                    parseTaskHuntingBasicData(msg);
                    break;
                case Proto::GameServerTaskHuntingData: // 187
                    parseTaskHuntingData(msg);
                    break;
                case Proto::GameServerBosstiaryCooldownTimer: // 189
                    parseBosstiaryCooldownTimer(msg);
                    break;
                case Proto::GameServerFloorChangeUp: // 190
                    parseFloorChangeUp(msg);
                    break;
                case Proto::GameServerFloorChangeDown: // 191
                    parseFloorChangeDown(msg);
                    break;
                case Proto::GameServerLootContainers: // 192
                    parseLootContainers(msg);
                    break;
                case Proto::GameServerChooseOutfit: // 200
                    parseOpenOutfitWindow(msg);
                    break;
                case Proto::GameServerSendUpdateImpactTracker: // 204
                    parseUpdateImpactTracker(msg);
                    break;
                case Proto::GameServerSendItemsPrice: // 205
                    parseItemsPrice(msg);
                    break;
                case Proto::GameServerSendUpdateSupplyTracker: // 206
                    parseUpdateSupplyTracker(msg);
                    break;




                case Proto::GameServerKillTracker:
                    parseKillTracker(msg);
                    break;
                case Proto::GameServerVipAdd:
                    parseVipAdd(msg);
                    break;
                case Proto::GameServerVipState:
                    parseVipState(msg);
                    break;
                case Proto::GameServerVipLogout:
                    parseVipLogout(msg);
                    break;
                case Proto::GameServerTutorialHint:
                    parseTutorialHint(msg);
                    break;
                case Proto::GameServerAutomapFlag:
                    parseAutomapFlag(msg);
                    break;
                case Proto::GameServerQuestLog:
                    parseQuestLog(msg);
                    break;
                case Proto::GameServerQuestLine:
                    parseQuestLine(msg);
                    break;
                    // PROTOCOL>=910
                case Proto::GameServerChannelEvent:
                    parseChannelEvent(msg);
                    break;
                case Proto::GameServerItemInfo:
                    parseItemInfo(msg);
                    break;
                case Proto::GameServerPlayerInventory:
                    parsePlayerInventory(msg);
                    break;
                    // PROTOCOL>=970
                case Proto::GameServerModalDialog:
                    parseModalDialog(msg);
                    break;
                    // PROTOCOL>=1080
                case Proto::GameServerCoinBalanceUpdating:
                    parseCoinBalanceUpdating(msg);
                    break;
                case Proto::GameServerCoinBalance:
                    parseCoinBalance(msg);
                    break;
                case Proto::GameServerRequestPurchaseData:
                    parseRequestPurchaseData(msg);
                    break;
                case Proto::GameServerResourceBalance: // 1281
                    parseResourceBalance(msg);
                    break;
                case Proto::GameServerWorldTime:
                    parseWorldTime(msg);
                    break;
                case Proto::GameServerStoreCompletePurchase:
                    parseCompleteStorePurchase(msg);
                    break;
                case Proto::GameServerStoreOffers:
                    parseStoreOffers(msg);
                    break;
                case Proto::GameServerStoreTransactionHistory:
                    parseStoreTransactionHistory(msg);
                    break;
                case Proto::GameServerStoreError:
                    parseStoreError(msg);
                    break;
                case Proto::GameServerStore:
                    parseStore(msg);
                    break;
                    // 12x
                case Proto::GameServerSendShowDescription:
                    parseShowDescription(msg);
                    break;
                case Proto::GameServerSendUpdateLootTracker:
                    parseUpdateLootTracker(msg);
                    break;
                case Proto::GameServerSendBestiaryEntryChanged:
                    parseBestiaryEntryChanged(msg);
                    break;
                case Proto::GameServerSendDailyRewardCollectionState:
                    parseDailyRewardCollectionState(msg);
                    break;
                case Proto::GameServerSendOpenRewardWall:
                    parseOpenRewardWall(msg);
                    break;
                case Proto::GameServerSendDailyReward:
                    parseDailyReward(msg);
                    break;
                case Proto::GameServerSendRewardHistory:
                    parseRewardHistory(msg);
                    break;

                case Proto::GameServerSendPreyFreeRerolls: // || Proto::GameServerSendBosstiaryEntryChanged
                    if (g_game.getFeature(Otc::GameBosstiary))
                        parseBosstiaryEntryChanged(msg);
                    else parsePreyFreeRerolls(msg);
                    break;

                case Proto::GameServerSendPreyTimeLeft:
                    parsePreyTimeLeft(msg);
                    break;
                case Proto::GameServerSendPreyData:
                    parsePreyData(msg);
                    break;
                case Proto::GameServerSendPreyRerollPrice:
                    parsePreyRerollPrice(msg);
                    break;
                case Proto::GameServerSendImbuementWindow:
                    parseImbuementWindow(msg);
                    break;
                case Proto::GameServerSendCloseImbuementWindow:
                    parseCloseImbuementWindow(msg);
                    break;
                case Proto::GameServerSendError:
                    parseError(msg);
                    break;
                case Proto::GameServerMarketEnter:
                    if (g_game.getClientVersion() >= 1281)
                        parseMarketEnter(msg);
                    else
                        parseMarketEnterOld(msg);
                    break;
                case Proto::GameServerMarketDetail:
                    parseMarketDetail(msg);
                    break;
                case Proto::GameServerMarketBrowse:
                    parseMarketBrowse(msg);
                    break;
                default:
                    throw Exception("unhandled opcode %d", opcode);
                    break;
            }
            prevOpcode = opcode;
        }
    } catch (const stdext::exception& e) {
        g_logger.error(stdext::format("ProtocolGame parse message exception (%d bytes, %d unread, last opcode is 0x%02x (%d), prev opcode is 0x%02x (%d)): %s"
                       "\nPacket has been saved to packet.log, you can use it to find what was wrong. (Protocol: %i)",
                       msg->getMessageSize(), msg->getUnreadSize(), opcode, opcode, prevOpcode, prevOpcode, e.what(), g_game.getProtocolVersion()));

        std::ofstream packet("packet.log", std::ifstream::app);
        if (!packet.is_open())
            return;
        packet << stdext::format("ProtocolGame parse message exception (%d bytes, %d unread, last opcode is 0x%02x (%d), prev opcode is 0x%02x (%d), proto: %i): %s\n",
                                 msg->getMessageSize(), msg->getUnreadSize(), opcode, opcode, prevOpcode, prevOpcode, g_game.getProtocolVersion(), e.what());
    }
}

void ProtocolGame::parsePendingGame(const InputMessagePtr&)
{
    //set player to pending game state
    g_game.processPendingGame();
}

void ProtocolGame::parseLogin(const InputMessagePtr& msg) const
{
    const uint32_t playerId = msg->getU32();
    const uint16_t serverBeat = msg->getU16();

    if (g_game.getFeature(Otc::GameNewSpeedLaw)) {
        Creature::speedA = msg->getDouble();
        Creature::speedB = msg->getDouble();
        Creature::speedC = msg->getDouble();
    }

    bool canReportBugs = false;
    if (!g_game.getFeature(Otc::GameDynamicBugReporter)) {
        canReportBugs = msg->getU8() > 0;
    }

    if (g_game.getClientVersion() >= 1054)
        msg->getU8(); // can change pvp frame option

    if (g_game.getClientVersion() >= 1058) {
        const uint8_t expertModeEnabled = msg->getU8();
        g_game.setExpertPvpMode(expertModeEnabled);
    }

    if (g_game.getFeature(Otc::GameIngameStore)) {
        // URL to ingame store images
        msg->getString();

        // premium coin package size
        // e.g you can only buy packs of 25, 50, 75, .. coins in the market
        msg->getU16();
    }

    if (g_game.getClientVersion() >= 1281) {
        msg->getU8(); // exiva button enabled (bool)
        if (g_game.getFeature(Otc::GameTournamentPackets)) {
            msg->getU8(); // Tournament button (bool)
        }
    }

    m_localPlayer->setId(playerId);
    g_game.setServerBeat(serverBeat);
    g_game.setCanReportBugs(canReportBugs);

    g_game.processLogin();
}

void ProtocolGame::parseGMActions(const InputMessagePtr& msg)
{
    std::vector<uint8_t > actions;

    uint8_t numViolationReasons;

    if (g_game.getClientVersion() >= 850)
        numViolationReasons = 20;
    else if (g_game.getClientVersion() >= 840)
        numViolationReasons = 23;
    else
        numViolationReasons = 32;

	for (auto i = 0; i < numViolationReasons; ++i)
        actions.push_back(msg->getU8());

    g_game.processGMActions(actions);
}

void ProtocolGame::parseEnterGame(const InputMessagePtr&)
{
    //set player to entered game state
    g_game.processEnterGame();

    if (!m_gameInitialized) {
        g_game.processGameStart();
        m_gameInitialized = true;
    }
}

void ProtocolGame::parseUpdateNeeded(const InputMessagePtr& msg)
{
    const auto& signature = msg->getString();
    g_game.processUpdateNeeded(signature);
}

void ProtocolGame::parseLoginError(const InputMessagePtr& msg)
{
    const auto& error = msg->getString();
    g_game.processLoginError(error);
}

void ProtocolGame::parseLoginAdvice(const InputMessagePtr& msg)
{
    const auto& message = msg->getString();
    g_game.processLoginAdvice(message);
}

void ProtocolGame::parseLoginWait(const InputMessagePtr& msg)
{
    const auto& message = msg->getString();
    const uint8_t time = msg->getU8();

    g_game.processLoginWait(message, time);
}

void ProtocolGame::parseSessionEnd(const InputMessagePtr& msg)
{
    const uint8_t reason = msg->getU8();
    g_game.processSessionEnd(reason);
}

void ProtocolGame::parseStoreButtonIndicators(const InputMessagePtr& msg)
{
    msg->getU8(); // (bool) IsSaleBannerVisible
    msg->getU8(); // (bool) IsNewBannerVisible
}

void ProtocolGame::parseBugReport(const InputMessagePtr& msg)
{
    const bool canReportBugs = msg->getU8() > 0;
    g_game.setCanReportBugs(canReportBugs);
}

void ProtocolGame::parsePing(const InputMessagePtr&) { g_game.processPing(); }
void ProtocolGame::parsePingBack(const InputMessagePtr&) { g_game.processPingBack(); }

void ProtocolGame::parseChallenge(const InputMessagePtr& msg)
{
    const uint32_t timestamp = msg->getU32();
    const uint8_t random = msg->getU8();

    sendLoginPacket(timestamp, random);
}

void ProtocolGame::parseDeath(const InputMessagePtr& msg)
{
    uint8_t penality = 100;
    uint8_t deathType = Otc::DeathRegular;

    if (g_game.getFeature(Otc::GameDeathType))
        deathType = msg->getU8();

    if (g_game.getFeature(Otc::GamePenalityOnDeath) && deathType == Otc::DeathRegular)
        penality = msg->getU8();

    if (g_game.getClientVersion() >= 1281)
        msg->getU8(); // (bool) can use death redemption

    g_game.processDeath(deathType, penality);
}

void ProtocolGame::parseSupplyStash(const InputMessagePtr& msg)
{
    std::vector<std::vector<uint32_t>> stashItems;

    const uint16_t size = msg->getU16();
    for (auto i = 0; i < size; ++i) {
        uint16_t itemId = msg->getU16();
        uint32_t amount = msg->getU32();
        stashItems.push_back({ itemId, amount });
    }

    msg->getU16(); // free slots

    g_lua.callGlobalField("g_game", "onSupplyStashEnter", stashItems); // g_game.processSupplyStashEnter(stashItems); // ????
}

void ProtocolGame::parseSpecialContainer(const InputMessagePtr& msg)
{
    msg->getU8(); // (bool) IsSupplyStashAvailable
    if (g_game.getProtocolVersion() >= 1220) {
        msg->getU8(); // (bool) IsMarketAvailable
    }
}

void ProtocolGame::parsePartyAnalyzer(const InputMessagePtr& msg)
{
    msg->getU32(); // session minutes
    msg->getU32(); // leader ID
    msg->getU8(); // price type

    const uint8_t partyMembersSize = msg->getU8();
    for (auto i = 0; i < partyMembersSize; ++i) {
        msg->getU32(); // party member id
        msg->getU8(); // highlight
        msg->getU64(); // loot
        msg->getU64(); // supply
        msg->getU64(); // damage
        msg->getU64(); // healing
    }

    const bool hasNamesBool = msg->getU8();
    if (hasNamesBool) {
        const uint8_t membersNameSize = msg->getU8();
        for (auto i = 0; i < membersNameSize; ++i) {
            msg->getU32(); // party member id
            msg->getString(); // party member name
        }
    }
}

void ProtocolGame::parseExtendedOpcode(const InputMessagePtr& msg)
{
    const uint8_t opcode = msg->getU8();
    const auto& buffer = msg->getString();

    if (opcode == 0)
        m_enableSendExtendedOpcode = true;
    else if (opcode == 2)
        parsePingBack(msg);
    else
        callLuaField("onExtendedOpcode", opcode, buffer); // ????????????
}

void ProtocolGame::parseChangeMapAwareRange(const InputMessagePtr& msg)
{
    const uint8_t xRange = msg->getU8();
    const uint8_t yRange = msg->getU8();

    g_map.setAwareRange({
        .left = static_cast<uint8_t>(xRange / 2 - (xRange + 1) % 2),
        .top = static_cast<uint8_t>(yRange / 2 - (yRange + 1) % 2),
        .right = static_cast<uint8_t>(xRange / 2),
        .bottom = static_cast<uint8_t>(yRange / 2)
                        });

    g_lua.callGlobalField("g_game", "onMapChangeAwareRange", xRange, yRange); // ????????????
}

void ProtocolGame::parseAttachedEffect(const InputMessagePtr& msg)
{
    const uint32_t creatureId = msg->getU32();
    const uint16_t attachedEffectId = msg->getU16();

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError(stdext::format("ProtocolGame::parseAttachedEffect: could not get creature with id %d", creatureId));
        return;
    }

    const auto& effect = g_attachedEffects.getById(attachedEffectId);
    if (!effect)
        return;

    creature->attachEffect(effect->clone());
}

void ProtocolGame::parseDetachEffect(const InputMessagePtr& msg)
{
    const uint32_t creatureId = msg->getU32();
    const uint16_t attachedEffectId = msg->getU16();

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError(stdext::format("ProtocolGame::parseDetachEffect: could not get creature with id %d", creatureId));
        return;
    }

    creature->detachEffectById(attachedEffectId);
}

void ProtocolGame::parseCreatureShader(const InputMessagePtr& msg)
{
    const uint32_t creatureId = msg->getU32();
    const auto& shaderName = msg->getString();

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError(stdext::format("ProtocolGame::parseCreatureShader: could not get creature with id %d", creatureId));
        return;
    }

    creature->setShader(shaderName);
}

void ProtocolGame::parseMapShader(const InputMessagePtr& msg)
{
    const auto& shaderName = msg->getString();

    const auto& mapView = g_map.getMapView(0);
    if (mapView)
        mapView->setShader(shaderName, 0.f, 0.f);
}

void ProtocolGame::parseCreatureTyping(const InputMessagePtr& msg)
{
    const uint32_t creatureId = msg->getU32();
    const bool typing = msg->getU8();

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError(stdext::format("ProtocolGame::parseCreatureTyping: could not get creature with id %d", creatureId));
        return;
    }

    creature->setTyping(typing);
}

void ProtocolGame::parseFloorDescription(const InputMessagePtr& msg)
{
    const auto& pos = getPosition(msg);
    const uint8_t floor = msg->getU8();

    if (pos.z == floor) {
        const auto& oldPos = m_localPlayer->getPosition();
        if (!m_mapKnown)
            m_localPlayer->setPosition(pos);

        g_map.setCentralPosition(pos);

        if (!m_mapKnown) {
            g_dispatcher.addEvent([] { g_lua.callGlobalField("g_game", "onMapKnown"); }); // ??????
            m_mapKnown = true;
        }

        g_dispatcher.addEvent([] { g_lua.callGlobalField("g_game", "onMapDescription"); }); // ??????
        g_lua.callGlobalField("g_game", "onTeleport", m_localPlayer, pos, oldPos); // ????????
    }

    const auto& range = g_map.getAwareRange();
    setFloorDescription(msg, pos.x - range.left, pos.y - range.top, floor, range.horizontal(), range.vertical(), pos.z - floor, 0);
}

void ProtocolGame::parseImbuementDurations(const InputMessagePtr& msg)
{
    std::vector<ImbuementTrackerItem> items;

    const uint8_t itemListSize = msg->getU8(); // amount of items to display
    for (auto itemIndex = 0; itemIndex < itemListSize; ++itemIndex) {
        ImbuementTrackerItem item(msg->getU8());
        item.item = getItem(msg);

        std::map<uint8_t, ImbuementSlot> slots;
        const uint8_t slotsCount = msg->getU8(); // total amount of imbuing slots on item
        for (auto slotIndex = 0; slotIndex < slotsCount; ++slotIndex) {
            const bool slotImbued = msg->getU8(); // 0 - empty, 1 - imbued
            ImbuementSlot slot(slotIndex);
            if (slotImbued) {
                slot.name = msg->getString();
                slot.iconId = msg->getU16();
                slot.duration = msg->getU32();
                slot.state = msg->getU8(); // 0 - paused, 1 - decaying
            }
            slots.emplace(slotIndex, slot);
        }

        item.slots = slots;
        items.emplace_back(item);
    }

    g_lua.callGlobalField("g_game", "onUpdateImbuementTracker", items); // ????????
}

void ProtocolGame::parsePassiveCooldown(const InputMessagePtr& msg)
{
    msg->getU8(); // passive id

    const uint8_t unknownType = msg->getU8();
    if (unknownType == 0) {
        msg->getU32(); // timestamp (partial)
        msg->getU32(); // timestamp (total)
        msg->getU8(); // (bool) timer is running?
    } else if (unknownType == 1)
        msg->getU8(); // unknown
        msg->getU8(); // unknown
    }
}

void ProtocolGame::parseBosstiaryData(const InputMessagePtr& msg)
{
    msg->getU16(); // Number of kills to achieve 'Bane Prowess'
    msg->getU16(); // Number of kills to achieve 'Bane expertise'
    msg->getU16(); // Number of kills to achieve 'Base Mastery'

    msg->getU16(); // Number of kills to achieve 'Archfoe Prowess'
    msg->getU16(); // Number of kills to achieve 'Archfoe Expertise'
    msg->getU16(); // Number of kills to achieve 'Archfoe Mastery'

    msg->getU16(); // Number of kills to achieve 'Nemesis Prowess'
    msg->getU16(); // Number of kills to achieve 'Nemesis Expertise'
    msg->getU16(); // Number of kills to achieve 'Nemesis Mastery'

    msg->getU16(); // Points will receive when reach 'Bane Prowess'
    msg->getU16(); // Points will receive when reach 'Bane Expertise'
    msg->getU16(); // Points will receive when reach 'Base Mastery'

    msg->getU16(); // Points will receive when reach 'Archfoe Prowess'
    msg->getU16(); // Points will receive when reach 'Archfoe Expertise'
    msg->getU16(); // Points will receive when reach 'Archfoe Mastery'

    msg->getU16(); // Points will receive when reach 'Nemesis Prowess'
    msg->getU16(); // Points will receive when reach 'Nemesis Expertise'
    msg->getU16(); // Points will receive when reach 'Nemesis Mastery'
}

void ProtocolGame::parseBosstiarySlots(const InputMessagePtr& msg)
{
    const auto& getBosstiarySlot = [&]() {
        msg->getU8(); // Boss Race
        msg->getU32(); // Kill Count
        msg->getU16(); // Loot Bonus
        msg->getU8(); // Kill Bonus
        msg->getU8(); // Boss Race
        msg->getU32(); // Remove Price
        msg->getU8(); // Inactive? (Only true if equal to Boosted Boss)
    };

    msg->getU32(); // Player Points
    msg->getU32(); // Total Points next bonus
    msg->getU16(); // Current Bonus
    msg->getU16(); // Next Bonus

    const bool isSlotOneUnlocked = msg->getU8();
    const uint32_t bossIdSlotOne = msg->getU32();
    if (isSlotOneUnlocked && bossIdSlotOne > 0) {
        getBosstiarySlot();
    }

    const bool isSlotTwoUnlocked = msg->getU8();
    const uint32_t bossIdSlotTwo = msg->getU32();
    if (isSlotTwoUnlocked && bossIdSlotTwo > 0) {
        getBosstiarySlot();
    }

    const bool isTodaySlotUnlocked = msg->getU8();
    const uint32_t boostedBossId = msg->getU32();
    if (isTodaySlotUnlocked && boostedBossId > 0) {
        getBosstiarySlot();
    }

    const bool bossesUnlocked = msg->getU8();
    if (bossesUnlocked) {
        const uint16_t bossesUnlockedSize = msg->getU16();
        for (auto i = 0; i < bossesUnlockedSize; ++i) {
            msg->getU32(); // bossId
            msg->getU8(); // bossRace
        }
    }
}

void ProtocolGame::parseClientCheck(const InputMessagePtr& msg)
{
    const uint32_t size = msg->getU32();
    for (auto i = 0; i < size; ++i) {
        msg->getU8(); // unknown
    }
}

void ProtocolGame::parseMapDescription(const InputMessagePtr& msg)
{
    const auto& pos = getPosition(msg);

    if (!m_mapKnown)
        m_localPlayer->setPosition(pos);

    g_map.setCentralPosition(pos);

    const auto& range = g_map.getAwareRange();
    setMapDescription(msg, pos.x - range.left, pos.y - range.top, pos.z, range.horizontal(), range.vertical());

    if (!m_mapKnown) {
        g_dispatcher.addEvent([] { g_lua.callGlobalField("g_game", "onMapKnown"); }); // ?????????????????
        m_mapKnown = true;
    }

    g_dispatcher.addEvent([] { g_lua.callGlobalField("g_game", "onMapDescription"); }); // ?????????????????
}

void ProtocolGame::parseMapMoveNorth(const InputMessagePtr& msg)
{
    auto pos = g_game.getFeature(Otc::GameMapMovePosition) ? getPosition(msg) : g_map.getCentralPosition();
    --pos.y;

    const auto& range = g_map.getAwareRange();
    setMapDescription(msg, pos.x - range.left, pos.y - range.top, pos.z, range.horizontal(), 1);
    g_map.setCentralPosition(pos);
}

void ProtocolGame::parseMapMoveEast(const InputMessagePtr& msg)
{
    auto pos = g_game.getFeature(Otc::GameMapMovePosition) ? getPosition(msg) : g_map.getCentralPosition();
    ++pos.x;

    const auto& range = g_map.getAwareRange();
    setMapDescription(msg, pos.x + range.right, pos.y - range.top, pos.z, 1, range.vertical());
    g_map.setCentralPosition(pos);
}

void ProtocolGame::parseMapMoveSouth(const InputMessagePtr& msg)
{
    auto pos = g_game.getFeature(Otc::GameMapMovePosition) ? getPosition(msg) : g_map.getCentralPosition();
    ++pos.y;

    const auto& range = g_map.getAwareRange();
    setMapDescription(msg, pos.x - range.left, pos.y + range.bottom, pos.z, range.horizontal(), 1);
    g_map.setCentralPosition(pos);
}

void ProtocolGame::parseMapMoveWest(const InputMessagePtr& msg)
{
    auto pos = g_game.getFeature(Otc::GameMapMovePosition) ? getPosition(msg) : g_map.getCentralPosition();
    --pos.x;

    const auto& range = g_map.getAwareRange();
    setMapDescription(msg, pos.x - range.left, pos.y - range.top, pos.z, 1, range.vertical());
    g_map.setCentralPosition(pos);
}

void ProtocolGame::parseUpdateTile(const InputMessagePtr& msg)
{
    const auto& tilePos = getPosition(msg);
    setTileDescription(msg, tilePos);
}

void ProtocolGame::parseTileAddThing(const InputMessagePtr& msg)
{
    const auto& pos = getPosition(msg);
	const uint8_t stackPos = g_game.getClientVersion() >= 841 ? msg->getU8() : -1;
    const auto& thing = getThing(msg);

    g_map.addThing(thing, pos, stackPos);
}

void ProtocolGame::parseTileTransformThing(const InputMessagePtr& msg)
{
    const auto& thing = getMappedThing(msg);
    const auto& newThing = getThing(msg);

    if (!thing) {
        g_logger.traceError("ProtocolGame::parseTileTransformThing: no thing");
        return;
    }

    const auto& pos = thing->getPosition();
    const uint8_t stackPos = thing->getStackPos();

    if (!g_map.removeThing(thing)) {
        g_logger.traceError("ProtocolGame::parseTileTransformThing: unable to remove thing");
        return;
    }

    g_map.addThing(newThing, pos, stackPos);
}

void ProtocolGame::parseTileRemoveThing(const InputMessagePtr& msg) const
{
    const auto& thing = getMappedThing(msg);
    if (!thing) {
        g_logger.traceError("ProtocolGame::parseTileRemoveThing: no thing");
        return;
    }

    if (!g_map.removeThing(thing))
        g_logger.traceError("ProtocolGame::parseTileRemoveThing: unable to remove thing");
}

void ProtocolGame::parseCreatureMove(const InputMessagePtr& msg)
{
    const auto& thing = getMappedThing(msg);
    const auto& newPos = getPosition(msg);

    if (!thing || !thing->isCreature()) {
        g_logger.traceError("ProtocolGame::parseCreatureMove: no creature found to move");
        return;
    }

    if (!g_map.removeThing(thing)) {
        g_logger.traceError("ProtocolGame::parseCreatureMove: unable to remove creature");
        return;
    }

    const auto& creature = thing->static_self_cast<Creature>();
    creature->allowAppearWalk();

    g_map.addThing(thing, newPos, -1);
}

void ProtocolGame::parseOpenContainer(const InputMessagePtr& msg)
{
    const uint8_t containerId = msg->getU8();
    const auto& containerItem = getItem(msg);
    const auto& name = msg->getString();
    const uint8_t capacity = msg->getU8();
    const bool hasParent = msg->getU8() != 0;

    bool isUnlocked = true;
    bool hasPages = false;
    uint16_t containerSize = 0;
    uint16_t firstIndex = 0;

    if (g_game.getClientVersion() >= 1281) {
        msg->getU8(); // (bool) show search icon
    }

    if (g_game.getFeature(Otc::GameContainerPagination)) {
        isUnlocked = msg->getU8() != 0; // drag and drop
        hasPages = msg->getU8() != 0; // pagination
        containerSize = msg->getU16(); // container size
        firstIndex = msg->getU16(); // first index
    }

    const uint8_t itemCount = msg->getU8();

    std::vector<ItemPtr> items(itemCount);
    for (auto i = 0; i < itemCount; i++) {
        items[i] = getItem(msg);

    if (g_game.getFeature(Otc::GameContainerFilter)) {
        // Check if container is store inbox id
        if (containerItem->getId() == 23396) {
            msg->getU8(); // category
            const uint8_t categoriesSize = msg->getU8();
            for (auto i = 0; i < categoriesSize; ++i) {
                msg->getU8(); // id
                msg->getString(); // name
            }
        } else {
            // Parse store inbox category empty
            msg->getU8(); // category
            msg->getU8(); // categories size
        }
    }

    g_game.processOpenContainer(containerId, containerItem, name, capacity, hasParent, items, isUnlocked, hasPages, containerSize, firstIndex);
}

void ProtocolGame::parseCloseContainer(const InputMessagePtr& msg)
{
    const uint8_t containerId = msg->getU8();
    g_game.processCloseContainer(containerId);
}

void ProtocolGame::parseContainerAddItem(const InputMessagePtr& msg)
{
    const uint8_t containerId = msg->getU8();
	const uint16_t slot = g_game.getFeature(Otc::GameContainerPagination) ? msg->getU16() : 0;
    const auto& item = getItem(msg);

    g_game.processContainerAddItem(containerId, item, slot);
}

void ProtocolGame::parseContainerUpdateItem(const InputMessagePtr& msg)
{
    const uint8_t containerId = msg->getU8();
	const uint16_t slot = g_game.getFeature(Otc::GameContainerPagination) ? msg->getU16() : msg->getU8();
    const auto& item = getItem(msg);

    g_game.processContainerUpdateItem(containerId, slot, item);
}

void ProtocolGame::parseContainerRemoveItem(const InputMessagePtr& msg)
{
    const uint8_t containerId = msg->getU8();
    uint16_t slot;

    ItemPtr lastItem;
    if (g_game.getFeature(Otc::GameContainerPagination)) {
        slot = msg->getU16();

        const uint16_t itemId = msg->getU16();
        if (itemId != 0)
            lastItem = getItem(msg, itemId);
    } else {
        slot = msg->getU8();
    }

    g_game.processContainerRemoveItem(containerId, slot, lastItem);
}

void ProtocolGame::parseTakeScreenshot(const InputMessagePtr& msg)
{
    const uint8_t screenshotType = msg->getU8();
    m_localPlayer->takeScreenshot(screenshotType);
}

void ProtocolGame::parseAddInventoryItem(const InputMessagePtr& msg)
{
    const uint8_t slot = msg->getU8();
    const auto& item = getItem(msg);

    g_game.processInventoryChange(slot, item);
}

void ProtocolGame::parseRemoveInventoryItem(const InputMessagePtr& msg)
{
    const uint8_t slot = msg->getU8();

    g_game.processInventoryChange(slot, ItemPtr());
}

void ProtocolGame::parseOpenNpcTrade(const InputMessagePtr& msg)
{
    std::vector<std::tuple<ItemPtr, std::string, int, int, int>> items;

    if (g_game.getFeature(Otc::GameNameOnNpcTrade))
        msg->getString(); // npcName

    if (g_game.getClientVersion() >= 1281) {
        msg->getU16(); // currency
        msg->getString(); // currency name
    }

    const uint16_t listCount = g_game.getClientVersion() >= 900 ? msg->getU16() : msg->getU8();
    for (auto i = 0; i < listCount; ++i) {
        const uint16_t itemId = msg->getU16();
        const uint8_t itemCount = msg->getU8();

        const auto& item = Item::create(itemId);
        item->setCountOrSubType(itemCount);

        const auto& itemName = msg->getString();
        uint32_t itemWeight = msg->getU32();
        uint32_t itemBuyPrice = msg->getU32();
        uint32_t itemSellPrice = msg->getU32();

        items.emplace_back(item, itemName, itemWeight, itemBuyPrice, itemSellPrice);
    }

    g_game.processOpenNpcTrade(items);
}

void ProtocolGame::parsePlayerGoods(const InputMessagePtr& msg) const
{
    std::vector<std::tuple<ItemPtr, int>> goods;

    // 12.x NOTE: this u64 is parsed only, because TFS stil sends it, we use resource balance in this protocol
    uint64_t money = 0;
    if (g_game.getClientVersion() >= 1281) {
        money = m_localPlayer->getResourceBalance(Otc::RESOURCE_BANK_BALANCE) + m_localPlayer->getResourceBalance(Otc::RESOURCE_GOLD_EQUIPPED);
    } else {
        money = g_game.getClientVersion() >= 973 ? msg->getU64() : msg->getU32();
    }

    const uint8_t size = msg->getU8();
    for (auto i = 0; i < size; ++i) {
        const uint16_t itemId = msg->getU16();
        const uint16_t itemAmount = g_game.getFeature(Otc::GameDoubleShopSellAmount) ? msg->getU16() : msg->getU8();

        goods.emplace_back(Item::create(itemId), itemAmount);
    }

    g_game.processPlayerGoods(money, goods);
}

void ProtocolGame::parseCloseNpcTrade(const InputMessagePtr&) { g_game.processCloseNpcTrade(); }

void ProtocolGame::parseOwnTrade(const InputMessagePtr& msg)
{
    const auto& name = g_game.formatCreatureName(msg->getString());
    const uint8_t count = msg->getU8();

    std::vector<ItemPtr> items(count);
    for (auto i = 0; i < count; i++) {
        items[i] = getItem(msg);

    g_game.processOwnTrade(name, items);
}

void ProtocolGame::parseCounterTrade(const InputMessagePtr& msg)
{
    const auto& name = g_game.formatCreatureName(msg->getString());
    const uint8_t count = msg->getU8();

    std::vector<ItemPtr> items(count);
    for (auto i = 0; i < count; i++) {
        items[i] = getItem(msg);

    g_game.processCounterTrade(name, items);
}

void ProtocolGame::parseCloseTrade(const InputMessagePtr&) { g_game.processCloseTrade(); }

void ProtocolGame::parseWorldLight(const InputMessagePtr& msg)
{
    const auto& oldLight = g_map.getLight();

    const auto intensity = msg->getU8();
    const auto color = msg->getU8();

    g_map.setLight({ intensity , color });

    if (oldLight.color != color || oldLight.intensity != intensity)
        g_lua.callGlobalField("g_game", "onWorldLightChange", g_map.getLight(), oldLight); // ?????
}

void ProtocolGame::parseMagicEffect(const InputMessagePtr& msg)
{
    const auto& pos = getPosition(msg);
    if (g_game.getProtocolVersion() >= 1203) {
        uint8_t effectType = msg->getU8();
        while (effectType != Otc::MAGIC_EFFECTS_END_LOOP) {
            switch (effectType) {
                case Otc::MAGIC_EFFECTS_DELAY:
                case Otc::MAGIC_EFFECTS_DELTA: {
                    msg->getU8(); // ?
                    break;
                }

                case Otc::MAGIC_EFFECTS_CREATE_DISTANCEEFFECT:
                case Otc::MAGIC_EFFECTS_CREATE_DISTANCEEFFECT_REVERSED: {
                    const uint16_t shotId = g_game.getFeature(Otc::GameEffectU16) ? msg->getU16() : msg->getU8();
                    const int8_t offsetX = static_cast<int8_t>(msg->getU8());
                    const int8_t offsetY = static_cast<int8_t>(msg->getU8());
                    if (!g_things.isValidDatId(shotId, ThingCategoryMissile)) {
                        g_logger.traceError(stdext::format("invalid missile id %d", shotId));
                        return;
                    }

                    const auto& missile = std::make_shared<Missile>();
                    missile->setId(shotId);

                    if (effectType == Otc::MAGIC_EFFECTS_CREATE_DISTANCEEFFECT)
                        missile->setPath(pos, Position(pos.x + offsetX, pos.y + offsetY, pos.z));
                    else
                        missile->setPath(Position(pos.x + offsetX, pos.y + offsetY, pos.z), pos);

                    g_map.addThing(missile, pos);
                    break;
                }

                case Otc::MAGIC_EFFECTS_CREATE_EFFECT: {
                    const uint16_t effectId = g_game.getFeature(Otc::GameEffectU16) ? msg->getU16() : msg->getU8();
                    if (!g_things.isValidDatId(effectId, ThingCategoryEffect)) {
                        g_logger.traceError(stdext::format("invalid effect id %d", effectId));
                        continue;
                    }

                    const auto& effect = std::make_shared<Effect>();
                    effect->setId(effectId);
                    g_map.addThing(effect, pos);
                    break;
                }

                case Otc::MAGIC_EFFECTS_CREATE_SOUND_MAIN_EFFECT: {
                    msg->getU8(); // Source
                    msg->getU16(); // Sound ID
                    break;
                }

                case Otc::MAGIC_EFFECTS_CREATE_SOUND_SECONDARY_EFFECT: {
                    msg->getU8(); // ENUM
                    msg->getU8(); // Source
                    msg->getU16(); // Sound ID
                    break;
                }
                default:
                    break;
            }

            effectType = msg->getU8();
        }

        return;
    }

    uint16_t effectId = g_game.getFeature(Otc::GameMagicEffectU16) ? msg->getU16() : msg->getU8();

    if (g_game.getClientVersion() <= 750)
        effectId += 1; //hack to fix effects in earlier clients

    if (!g_things.isValidDatId(effectId, ThingCategoryEffect)) {
        g_logger.traceError(stdext::format("invalid effect id %d", effectId));
        return;
    }

    const auto& effect = std::make_shared<Effect>();
    effect->setId(effectId);

    g_map.addThing(effect, pos);
}

void ProtocolGame::parseAnimatedText(const InputMessagePtr& msg)
{
    const auto& position = getPosition(msg);
    const uint8_t color = msg->getU8();
    const auto& text = msg->getString();

    g_map.addAnimatedText(std::make_shared<AnimatedText>(text, color), position);
}

void ProtocolGame::parseAnthem(const InputMessagePtr& msg)
{
    const uint8_t type = msg->getU8();
    if (type <= 2) {
        msg->getU16(); // Anthem id
    }
}

void ProtocolGame::parseDistanceMissile(const InputMessagePtr& msg)
{
    const auto& fromPos = getPosition(msg);
    const auto& toPos = getPosition(msg);

    const uint16_t shotId = g_game.getFeature(Otc::GameDistanceEffectU16) ? msg->getU16() : msg->getU8();
    if (!g_things.isValidDatId(shotId, ThingCategoryMissile)) {
        g_logger.traceError(stdext::format("invalid missile id %d", shotId));
        return;
    }

    const auto& missile = std::make_shared<Missile>();
    missile->setId(shotId);
    missile->setPath(fromPos, toPos);

    g_map.addThing(missile, fromPos);
}

void ProtocolGame::parseItemClasses(const InputMessagePtr& msg)
{
    const uint8_t classSize = msg->getU8();
    for (auto i = 0; i < classSize; ++i) {
        msg->getU8(); // class id

        // tiers
        const uint8_t tiersSize = msg->getU8();
        for (auto j = 0; j < tiersSize; ++j) {
            msg->getU8(); // tier id
            msg->getU64(); // upgrade cost
        }
    }

    if (g_game.getFeature(Otc::GameDynamicForgeVariables)) {
        const uint8_t grades = msg->getU8();
        for (auto i = 0; i < grades; ++i) {
            msg->getU8(); // Tier
            msg->getU8(); // Exalted cores
        }

        if (g_game.getFeature(Otc::GameForgeConvergence)) {
            // Convergence fusion prices per tier
            const uint8_t totalConvergenceFusion = msg->getU8(); // total size count
            for (auto i = 0; i < totalConvergenceFusion; ++i) {
                msg->getU8(); // tier id
                msg->getU64(); // upgrade cost
            }

            // Convergence transfer prices per tier
            const uint8_t totalConvergenceTransfer = msg->getU8(); // total size count
            for (auto i = 0; i < totalConvergenceTransfer; ++i) {
                msg->getU8(); // tier id
                msg->getU64(); // upgrade cost
            }
        }

        msg->getU8(); // Dust Percent
        msg->getU8(); // Dust To Sleaver
        msg->getU8(); // Sliver To Core
        msg->getU8(); // Dust Percent Upgrade
        if (g_game.getClientVersion() >= 1316) {
            msg->getU16(); // Max Dust
            msg->getU16(); // Max Dust Cap
        } else {
            msg->getU8(); // Max Dust
            msg->getU8(); // Max Dust Cap
        }
        msg->getU8(); // Dust Normal Fusion
        if (g_game.getFeature(Otc::GameForgeConvergence)) {
            msg->getU8(); // Dust Convergence Fusion
        }
        msg->getU8(); // Dust Normal Transfer
        if (g_game.getFeature(Otc::GameForgeConvergence)) {
            msg->getU8(); // Dust Convergence Transfer
        }
        msg->getU8(); // Chance Base
        msg->getU8(); // Chance Improved
        msg->getU8(); // Reduce Tier Loss
    } else {
        uint8_t totalForgeValues = 11;
        if (g_game.getClientVersion() >= 1316) {
            totalForgeValues = 13;
        }

        if (g_game.getFeature(Otc::GameForgeConvergence)) {
            totalForgeValues = totalForgeValues + 2;
        }

        for (auto i = 0; i < totalForgeValues; ++i) {
            msg->getU8(); // Forge values
        }
    }
}

void ProtocolGame::parseCreatureMark(const InputMessagePtr& msg)
{
    const uint32_t creatureId = msg->getU32();
    const uint8_t color = msg->getU8();

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError(stdext::format("ProtocolGame::parseCreatureMark: could not get creature with id %d", creatureId));
        return;
    }

    creature->addTimedSquare(color);
}

void ProtocolGame::parseTrappers(const InputMessagePtr& msg)
{
    const uint8_t numTrappers = msg->getU8();

    if (numTrappers > 8)
        g_logger.traceError("ProtocolGame::parseTrappers: too many trappers");

    for (auto i = 0; i < numTrappers; ++i) {
        const uint32_t creatureId = msg->getU32();
        const auto& creature = g_map.getCreatureById(creatureId);
        if (!creature) {
            g_logger.traceError(stdext::format("ProtocolGame::parseTrappers: could not get creature with id %d", creatureId));
            continue;
        }

        //TODO: set creature as trapper
    }
}

void ProtocolGame::addCreatureIcon(const InputMessagePtr& msg, const CreaturePtr& creature)
{
    const uint8_t sizeIcons = msg->getU8();
    for (auto i = 0; i < sizeIcons; ++i) {
        msg->getU8(); // icon.serialize()
        msg->getU8(); // icon.category
        msg->getU16(); // icon.count
    }

    // TODO: implement creature icons usage
}

void ProtocolGame::parseCreatureData(const InputMessagePtr& msg)
{
    const uint32_t creatureId = msg->getU32();
    const uint8_t type = msg->getU8();

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError(stdext::format("ProtocolGame::parseCreatureData: could not get creature with id %d", creatureId));
    }

    switch (type) {
        case 0: // creature update
            getCreature(msg);
            break;
        case 11: // creature mana percent
        case 12: // creature show status
        case 13: // player vocation
            msg->getU8();
            break;
        case 14: // creature icons
            addCreatureIcon(msg, creature);
            break;
    }
}

void ProtocolGame::parseCreatureHealth(const InputMessagePtr& msg)
{
    const uint32_t creatureId = msg->getU32();
    const uint8_t healthPercent = msg->getU8();

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError(stdext::format("ProtocolGame::parseCreatureHealth: could not get creature with id %d", creatureId));
        return;
    }

    creature->setHealthPercent(healthPercent);
}

void ProtocolGame::parseCreatureLight(const InputMessagePtr& msg)
{
    const uint32_t creatureId = msg->getU32();

    Light light;
    light.intensity = msg->getU8();
    light.color = msg->getU8();

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError(stdext::format("ProtocolGame::parseCreatureLight: could not get creature with id %d", creatureId));
        return;
    }

    creature->setLight(light);
}

void ProtocolGame::parseCreatureOutfit(const InputMessagePtr& msg) const
{
    const uint32_t creatureId = msg->getU32();
    const Outfit outfit = getOutfit(msg);

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError(stdext::format("ProtocolGame::parseCreatureOutfit: could not get creature with id %d", creatureId));
        return;
    }

    creature->setOutfit(outfit);
}

void ProtocolGame::parseCreatureSpeed(const InputMessagePtr& msg)
{
    const uint32_t creatureId = msg->getU32();
    const uint16_t baseSpeed = g_game.getClientVersion() >= 1059 ? msg->getU16() : 0;
    const uint16_t speed = msg->getU16();

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError(stdext::format("ProtocolGame::parseCreatureSpeed: could not get creature with id %d", creatureId));
        return;
    }

    creature->setSpeed(speed);
    if (baseSpeed != 0)
        creature->setBaseSpeed(baseSpeed);
}

void ProtocolGame::parseCreatureSkulls(const InputMessagePtr& msg)
{
    const uint32_t creatureId = msg->getU32();
    const uint8_t skull = msg->getU8();

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError(stdext::format("ProtocolGame::parseCreatureSkulls: could not get creature with id %d", creatureId));
        return;
    }

    creature->setSkull(skull);
}

void ProtocolGame::parseCreatureShields(const InputMessagePtr& msg)
{
    const uint32_t creatureId = msg->getU32();
    const uint8_t shield = msg->getU8();

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError(stdext::format("ProtocolGame::parseCreatureShields: could not get creature with id %d", creatureId));
        return;
    }

    creature->setShield(shield);
}

void ProtocolGame::parseCreatureUnpass(const InputMessagePtr& msg)
{
    const uint32_t creatureId = msg->getU32();
    const bool unpass = msg->getU8();

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError(stdext::format("ProtocolGame::parseCreatureUnpass: could not get creature with id %d", creatureId));
        return;
    }

    creature->setPassable(!unpass);
}

void ProtocolGame::parseCreaturesMark(const InputMessagePtr& msg)
{
    const uint8_t len = g_game.getClientVersion() >= 1035 ? 1 : msg->getU8();
    for (auto i = 0; i < len; ++i) {
        const uint32_t creatureId = msg->getU32();
        const bool isPermanent = msg->getU8() != 1;
        const uint8_t markType = msg->getU8();

        const auto& creature = g_map.getCreatureById(creatureId);
        if (!creature) {
            g_logger.traceError(stdext::format("ProtocolGame::parseTrappers: could not get creature with id %d", creatureId));
            continue;
        }

        if (isPermanent) {
            if (markType == 0xff)
                creature->hideStaticSquare();
            else
                creature->showStaticSquare(Color::from8bit(markType));
        } else
            creature->addTimedSquare(markType);
    }
}

void ProtocolGame::parsePlayerHelpers(const InputMessagePtr& msg) const
{
    const uint32_t creatureId = msg->getU32();
    const uint16_t helpers = msg->getU16();

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError(stdext::format("ProtocolGame::parsePlayerHelpers: could not get creature with id %d", creatureId));
        return;
    }

    g_game.processPlayerHelpers(helpers);
}

void ProtocolGame::parseCreatureType(const InputMessagePtr& msg)
{
    const uint32_t creatureId = msg->getU32();
    const uint8_t type = msg->getU8();

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError(stdext::format("ProtocolGame::parseCreatureType: could not get creature with id %d", creatureId));
        return;
    }

    creature->setType(type);
}

void ProtocolGame::parseEditText(const InputMessagePtr& msg)
{
    const uint32_t id = msg->getU32();

    uint32_t itemId;
    if (g_game.getClientVersion() >= 1010 || g_game.getFeature(Otc::GameItemShader)) {
        // TODO: processEditText with ItemPtr as parameter
        const auto& item = getItem(msg);
        itemId = item->getId();
    } else
        itemId = msg->getU16();

    const uint16_t maxLength = msg->getU16();

    const auto& text = msg->getString();
    const auto& writer = msg->getString();

    if (g_game.getClientVersion() >= 1281) {
        msg->getU8(); // suffix
    }

    std::string date;
    if (g_game.getFeature(Otc::GameWritableDate))
        date = msg->getString();

    g_game.processEditText(id, itemId, maxLength, text, writer, date);
}

void ProtocolGame::parseEditList(const InputMessagePtr& msg)
{
    const uint8_t doorId = msg->getU8();
    const uint32_t id = msg->getU32();
    const auto& text = msg->getString();

    g_game.processEditList(id, doorId, text);
}

void ProtocolGame::parseGameNews(const InputMessagePtr& msg)
{
    msg->getU32(); // category id
    msg->getU8(); // page number

    // TODO: implement game news usage
}

void ProtocolGame::parseBlessDialog(const InputMessagePtr& msg)
{
    // parse bless amount
    const uint8_t totalBless = msg->getU8();

    // parse each bless
    for (auto i = 0; i < totalBless; ++i) {
        msg->getU16(); // bless bit wise
        msg->getU8(); // player bless count
        msg->getU8(); // store?
    }

    // parse general info
    msg->getU8(); // premium
    msg->getU8(); // promotion
    msg->getU8(); // pvp min xp loss
    msg->getU8(); // pvp max xp loss
    msg->getU8(); // pve exp loss
    msg->getU8(); // equip pvp loss
    msg->getU8(); // equip pve loss
    msg->getU8(); // skull
    msg->getU8(); // aol

    // parse log
    const uint8_t logCount = msg->getU8();
    for (auto i = 0; i < logCount; ++i) {
        msg->getU32(); // timestamp
        msg->getU8(); // color message (0 = white loss, 1 = red)
        msg->getString(); // history message
    }

    // TODO: implement bless dialog usage
}

void ProtocolGame::parseBlessings(const InputMessagePtr& msg) const
{
    const uint16_t blessings = msg->getU16();

    if (g_game.getClientVersion() >= 1200) {
        msg->getU8(); // Blessing count
    }

    m_localPlayer->setBlessings(blessings);
}

void ProtocolGame::parsePreset(const InputMessagePtr& msg)
{
    msg->getU32(); // preset
}

void ProtocolGame::parsePremiumTrigger(const InputMessagePtr& msg)
{
    const uint8_t triggerCount = msg->getU8();

    std::vector<int> triggers;

    for (auto i = 0; i < triggerCount; ++i) {
        triggers.push_back(msg->getU8());
    }

    if (g_game.getClientVersion() <= 1096) {
        msg->getU8(); // == 1; // something
    }
}

void ProtocolGame::parsePlayerInfo(const InputMessagePtr& msg) const
{
    const bool premium = msg->getU8(); // premium

    if (g_game.getFeature(Otc::GamePremiumExpiration)) {
        msg->getU32(); // premium expiration used for premium advertisement
    }

    const uint8_t vocation = msg->getU8(); // vocation

    if (g_game.getClientVersion() >= 1281) {
        msg->getU8(); // prey enabled
    }

    std::vector<uint16_t> spells;

    const uint16_t spellCount = msg->getU16();
    for (auto i = 0; i < spellCount; ++i) {
        if (g_game.getFeature(Otc::GameUshortSpell)) {
            spells.push_back(msg->getU16()); // spell id
        } else {
            spells.push_back(static_cast<uint16_t>(msg->getU8())); // spell id
        }
    }

    if (g_game.getClientVersion() >= 1281) {
        msg->getU8(); // is magic shield active (bool)
    }

    m_localPlayer->setPremium(premium);
    m_localPlayer->setVocation(vocation);
    m_localPlayer->setSpells(spells);
}

void ProtocolGame::parsePlayerStats(const InputMessagePtr& msg) const
{
    const uint32_t health = g_game.getFeature(Otc::GameDoubleHealth) ? msg->getU32() : msg->getU16();
    const uint32_t maxHealth = g_game.getFeature(Otc::GameDoubleHealth) ? msg->getU32() : msg->getU16();
	const uint32_t freeCapacity = g_game.getFeature(Otc::GameDoubleFreeCapacity) ? msg->getU32() / 100.f : msg->getU16() / 100.f;

    uint32_t totalCapacity = 0;
    if (g_game.getClientVersion() < 1281 && g_game.getFeature(Otc::GameTotalCapacity)) {
        totalCapacity = msg->getU32() / 100.f;
    }

	const uint64_t experience = g_game.getFeature(Otc::GameDoubleExperience) ? msg->getU64() : msg->getU32();
	const uint16_t level = g_game.getFeature(Otc::GameLevelU16) ? msg->getU16() : msg->getU8();
    const uint8_t levelPercent = msg->getU8();

    if (g_game.getFeature(Otc::GameExperienceBonus)) {
        if (g_game.getClientVersion() <= 1096) {
            msg->getDouble(); // experienceBonus
        } else {
            msg->getU16(); // baseXpGain
            if (g_game.getClientVersion() < 1281) {
                msg->getU16(); // voucherAddend
            }
            msg->getU16(); // grindingAddend
            msg->getU16(); // storeBoostAddend
            msg->getU16(); // huntingBoostFactor
        }
    }

    const uint32_t mana = g_game.getFeature(Otc::GameDoubleHealth) ? msg->getU32() : msg->getU16();
    const uint32_t maxMana = g_game.getFeature(Otc::GameDoubleHealth) ? msg->getU32() : msg->getU16();

    if (g_game.getClientVersion() < 1281) {
        const uint8_t magicLevel = msg->getU8();
        const uint8_t baseMagicLevel = g_game.getFeature(Otc::GameSkillsBase) ? msg->getU8() : magicLevel;
        const uint8_t magicLevelPercent = msg->getU8();

        m_localPlayer->setMagicLevel(magicLevel, magicLevelPercent);
        m_localPlayer->setBaseMagicLevel(baseMagicLevel);
    }

    const uint8_t soul = g_game.getFeature(Otc::GameSoul) ? msg->getU8() : 0;
    const uint16_t stamina = g_game.getFeature(Otc::GamePlayerStamina) ? msg->getU16() : 0;
    const uint16_t baseSpeed = g_game.getFeature(Otc::GameSkillsBase) ? msg->getU16() : 0;
    const uint16_t regeneration = g_game.getFeature(Otc::GamePlayerRegenerationTime) ? msg->getU16() : 0;
    const uint16_t training = g_game.getFeature(Otc::GameOfflineTrainingTime) ? msg->getU16() : 0;

    if (g_game.getClientVersion() >= 1097) {
        msg->getU16(); // xp boost time (seconds)
        msg->getU8(); // enables exp boost in the store
    }

    if (g_game.getClientVersion() >= 1281) {
        if (g_game.getFeature(Otc::GameDoubleHealth)) {
            msg->getU32(); // remaining mana shield
            msg->getU32(); // total mana shield
        } else {
            msg->getU16(); // remaining mana shield
            msg->getU16(); // total mana shield
        }
    }

    m_localPlayer->setHealth(health, maxHealth);
    m_localPlayer->setFreeCapacity(freeCapacity);
    m_localPlayer->setTotalCapacity(totalCapacity);
    m_localPlayer->setExperience(experience);
    m_localPlayer->setLevel(level, levelPercent);
    m_localPlayer->setMana(mana, maxMana);
    m_localPlayer->setStamina(stamina);
    m_localPlayer->setSoul(soul);
    m_localPlayer->setBaseSpeed(baseSpeed);
    m_localPlayer->setRegenerationTime(regeneration);
    m_localPlayer->setOfflineTrainingTime(training);
}

void ProtocolGame::parsePlayerSkills(const InputMessagePtr& msg) const
{
    if (g_game.getClientVersion() >= 1281) {
        // magic level
        const uint16_t magicLevel = msg->getU16();
        const uint16_t baseMagicLevel = msg->getU16();
        msg->getU16(); // base + loyalty bonus(?)
        const uint8_t percent = msg->getU16() / 100;

        m_localPlayer->setMagicLevel(magicLevel, percent);
        m_localPlayer->setBaseMagicLevel(baseMagicLevel);
    }

    for (int_fast32_t skill = Otc::Fist; skill <= Otc::Fishing; ++skill) {
        const uint16_t level = g_game.getFeature(Otc::GameDoubleSkills) ? msg->getU16() : msg->getU8();

        uint16_t baseLevel;
        if (g_game.getFeature(Otc::GameSkillsBase))
            if (g_game.getFeature(Otc::GameBaseSkillU16))
                baseLevel = msg->getU16();
            else
                baseLevel = msg->getU8();
        else
            baseLevel = level;

        uint16_t levelPercent = 0;

        if (g_game.getClientVersion() >= 1281) {
            msg->getU16(); // base + loyalty bonus(?)
            levelPercent = msg->getU16() / 100;
        } else {
            levelPercent = msg->getU8();
        }

        m_localPlayer->setSkill(static_cast<Otc::Skill>(skill), level, levelPercent);
        m_localPlayer->setBaseSkill(static_cast<Otc::Skill>(skill), baseLevel);
    }

    if (g_game.getFeature(Otc::GameAdditionalSkills)) {
        // Critical, Life Leech, Mana Leech
        for (int_fast32_t skill = Otc::CriticalChance; skill <= Otc::ManaLeechAmount; ++skill) {
            if (!g_game.getFeature(Otc::GameLeechAmount)) {
                if (skill == Otc::LifeLeechAmount || skill == Otc::ManaLeechAmount) {
                    continue;
                }
            }

            const uint16_t level = msg->getU16();
            const uint16_t baseLevel = msg->getU16();
            m_localPlayer->setSkill(static_cast<Otc::Skill>(skill), level, 0);
            m_localPlayer->setBaseSkill(static_cast<Otc::Skill>(skill), baseLevel);
        }
    }

    if (g_game.getFeature(Otc::GameConcotions)) {
        msg->getU8();
    }

    if (g_game.getClientVersion() >= 1281) {
        // forge skill stats
        const uint8_t lastSkill = g_game.getClientVersion() >= 1332 ? Otc::LastSkill : Otc::Momentum + 1;
        for (int_fast32_t skill = Otc::Fatal; skill < lastSkill; ++skill) {
            const uint16_t level = msg->getU16();
            const uint16_t baseLevel = msg->getU16();
            m_localPlayer->setSkill(static_cast<Otc::Skill>(skill), level, 0);
            m_localPlayer->setBaseSkill(static_cast<Otc::Skill>(skill), baseLevel);
        }

        // bonus cap
        const uint32_t capacity = msg->getU32(); // base + bonus capacity
        msg->getU32(); // base capacity

        m_localPlayer->setTotalCapacity(capacity);
    }
}

void ProtocolGame::parsePlayerState(const InputMessagePtr& msg) const
{
    uint32_t states;

    if (g_game.getClientVersion() >= 1281) {
        states = msg->getU32();
        if (g_game.getFeature(Otc::GamePlayerStateCounter)) {
            msg->getU8(); // icons counter
        }
    } else {
        states = g_game.getFeature(Otc::GamePlayerStateU16) ? msg->getU16() : msg->getU8();
    }

    m_localPlayer->setStates(states);
}

void ProtocolGame::parsePlayerCancelAttack(const InputMessagePtr& msg)
{
    const uint32_t seq = g_game.getFeature(Otc::GameAttackSeq) ? msg->getU32() : 0;
    g_game.processAttackCancel(seq);
}

void ProtocolGame::parseSpellCooldown(const InputMessagePtr& msg)
{
    const uint16_t spellId = g_game.getFeature(Otc::GameUshortSpell) ? msg->getU16() : msg->getU8();
    const uint32_t delay = msg->getU32();

    g_lua.callGlobalField("g_game", "onSpellCooldown", spellId, delay); // ?????
}

void ProtocolGame::parseSpellGroupCooldown(const InputMessagePtr& msg)
{
    const uint8_t groupId = msg->getU8();
    const uint32_t delay = msg->getU32();

    g_lua.callGlobalField("g_game", "onSpellGroupCooldown", groupId, delay); // ????
}

void ProtocolGame::parseMultiUseCooldown(const InputMessagePtr& msg)
{
    const uint32_t delay = msg->getU32();
    g_lua.callGlobalField("g_game", "onMultiUseCooldown", delay); // ????
}

void ProtocolGame::parsePlayerModes(const InputMessagePtr& msg)
{
    const uint8_t fightMode = msg->getU8();
    const uint8_t chaseMode = msg->getU8();
    const bool safeMode = msg->getU8();
    const uint8_t pvpMode = g_game.getFeature(Otc::GamePVPMode) ? msg->getU8() : 0;

    g_game.processPlayerModes(static_cast<Otc::FightModes>(fightMode), static_cast<Otc::ChaseModes>(chaseMode), safeMode, static_cast<Otc::PVPModes>(pvpMode));
}

void ProtocolGame::parseSetStoreDeepLink(const InputMessagePtr& msg)
{
    msg->getU8(); // currentlyFeaturedServiceType
}

void ProtocolGame::parseRestingAreaState(const InputMessagePtr& msg)
{
    msg->getU8(); // zone
    msg->getU8(); // state
    msg->getString(); // message

    // TODO: implement resting area state usage
}

void ProtocolGame::parseTalk(const InputMessagePtr& msg)
{
    if (g_game.getFeature(Otc::GameMessageStatements)) {
        msg->getU32(); // channel statement guid
    }

    const auto& name = g_game.formatCreatureName(msg->getString());

    if (g_game.getClientVersion() >= 1281) {
        msg->getU8(); // suffix
    }

    const uint16_t level = g_game.getFeature(Otc::GameMessageLevel) ? msg->getU16() : 0;

    const Otc::MessageMode mode = Proto::translateMessageModeFromServer(msg->getU8());
    uint16_t channelId = 0;
    Position pos;

    switch (mode) {
        case Otc::MessagePotion:
        case Otc::MessageSay:
        case Otc::MessageWhisper:
        case Otc::MessageYell:
        case Otc::MessageMonsterSay:
        case Otc::MessageMonsterYell:
        case Otc::MessageNpcTo:
        case Otc::MessageBarkLow:
        case Otc::MessageBarkLoud:
        case Otc::MessageSpell:
        case Otc::MessageNpcFromStartBlock:
            pos = getPosition(msg);
            break;
        case Otc::MessageChannel:
        case Otc::MessageChannelManagement:
        case Otc::MessageChannelHighlight:
        case Otc::MessageGamemasterChannel:
            channelId = msg->getU16();
            break;
        case Otc::MessageNpcFrom:
        case Otc::MessagePrivateTo:
        case Otc::MessagePrivateFrom:
        case Otc::MessageGamemasterBroadcast:
        case Otc::MessageGamemasterPrivateFrom:
        case Otc::MessageRVRAnswer:
        case Otc::MessageRVRContinue:
            break;
        case Otc::MessageRVRChannel:
            msg->getU32();
            break;
        default:
            throw Exception("ProtocolGame::parseTalk: unknown message mode %d", mode);
            break;
    }

    const auto& text = msg->getString();

    g_game.processTalk(name, level, mode, text, channelId, pos);
}

void ProtocolGame::parseChannelList(const InputMessagePtr& msg)
{
    std::vector<std::tuple<int, std::string> > channelList;

    const uint8_t count = msg->getU8();
    for (auto i = 0; i < count; ++i) {
        const uint16_t channelId = msg->getU16();
        const auto& channelName = msg->getString();
        channelList.emplace_back(channelId, channelName);
    }

    g_game.processChannelList(channelList);
}

void ProtocolGame::parseOpenChannel(const InputMessagePtr& msg)
{
    const uint16_t channelId = msg->getU16();
    const auto& channelName = msg->getString();

    if (g_game.getFeature(Otc::GameChannelPlayerList)) {
        const uint16_t joinedPlayers = msg->getU16();
        for (auto i = 0; i < joinedPlayers; ++i)  {
            g_game.formatCreatureName(msg->getString()); // player name
        }

        const uint16_t invitedPlayers = msg->getU16();
        for (auto i = 0; i < invitedPlayers; ++i)  {
            g_game.formatCreatureName(msg->getString()); // player name
        }
    }

    g_game.processOpenChannel(channelId, channelName);
}

void ProtocolGame::parseOpenPrivateChannel(const InputMessagePtr& msg)
{
    const auto& name = g_game.formatCreatureName(msg->getString());
    g_game.processOpenPrivateChannel(name);
}

void ProtocolGame::parseRuleViolationChannel(const InputMessagePtr& msg)
{
    const uint16_t channelId = msg->getU16();
    g_game.processRuleViolationChannel(channelId);
}

void ProtocolGame::parseExperienceTracker(const InputMessagePtr& msg)
{
    msg->get64(); // raw exp
    msg->get64(); // final exp
}

void ProtocolGame::parseRuleViolationRemove(const InputMessagePtr& msg)
{
    const auto& name = msg->getString();
    g_game.processRuleViolationRemove(name);
}

void ProtocolGame::parseRuleViolationCancel(const InputMessagePtr& msg)
{
    const auto& name = msg->getString();
    g_game.processRuleViolationCancel(name);
}

void ProtocolGame::parseHighscores(const InputMessagePtr& msg)
{
    const bool isEmpty = msg->getU8() == 1;
    if (isEmpty) {
        return;
    }

    msg->getU8(); // skip (0x01)
    const auto& serverName = msg->getString();
    const auto& world = msg->getString();
    const uint8_t worldType = msg->getU8();
    const uint8_t battlEye = msg->getU8();
    const uint8_t sizeVocation = msg->getU8();

    msg->getU32(); // skip 0xFFFFFFFF
    msg->getString(); // skip "All vocations"

    std::vector<std::tuple<uint32_t, std::string>> vocations;

    for (uint8_t i = 0; i < sizeVocation - 1; ++i) {
        const uint32_t vocationID = msg->getU32();
        const auto& vocationName = msg->getString();
        vocations.emplace_back(vocationID, vocationName);
    }

    msg->getU32(); // skip params.vocation

	const uint8_t sizeCategories = msg->getU8();
    std::vector<std::tuple<uint8_t, std::string>> categories;
    categories.reserve(sizeCategories);

    for (uint8_t i = 0; i < sizeCategories; ++i) {
        const uint8_t id = msg->getU8();
        const auto& categoryName = msg->getString();
        categories.emplace_back(id, categoryName);
    }

    msg->getU8();  // skip params.category
    const uint16_t page = msg->getU16();
    const uint16_t totalPages = msg->getU16();

	const uint8_t sizeEntries = msg->getU8();
    std::vector<std::tuple<uint32_t, std::string, std::string, uint8_t, std::string, uint16_t, uint8_t, uint64_t>> highscores;
    highscores.reserve(sizeEntries);

    for (uint8_t i = 0; i < sizeEntries; ++i) {
        const uint32_t rank = msg->getU32();
        const auto& name = msg->getString();
        const auto& title = msg->getString();
        const uint8_t vocation = msg->getU8();
        const auto& world = msg->getString();
        const uint16_t level = msg->getU16();
        const uint8_t isPlayer = msg->getU8();
        const uint64_t points = msg->getU64();
        highscores.emplace_back(rank, name, title, vocation, world, level, isPlayer, points);
    }

    msg->getU8(); // skip (0xFF) unknown
    msg->getU8(); // skip display loyalty title column
    msg->getU8(); // skip HIGHSCORES_CATEGORIES[params.category].type or 0x00
    const uint32_t entriesTs = msg->getU32(); // last update

    g_game.processHighscore(serverName, world, worldType, battlEye, vocations, categories, page, totalPages, highscores, entriesTs);
}

void ProtocolGame::parseRuleViolationLock(const InputMessagePtr&) { g_game.processRuleViolationLock(); }

void ProtocolGame::parseOpenOwnPrivateChannel(const InputMessagePtr& msg)
{
    const uint16_t channelId = msg->getU16();
    const auto& channelName = msg->getString();

    g_game.processOpenOwnPrivateChannel(channelId, channelName);
}

void ProtocolGame::parseCloseChannel(const InputMessagePtr& msg)
{
    const uint16_t channelId = msg->getU16();
    g_game.processCloseChannel(channelId);
}

void ProtocolGame::parseTextMessage(const InputMessagePtr& msg)
{
    const uint8_t code = msg->getU8();
    const Otc::MessageMode mode = Proto::translateMessageModeFromServer(code);
    std::string text;

    g_logger.debug(stdext::format("[ProtocolGame::parseTextMessage] code: %d, mode: %d", code, mode));

    switch (mode) {
        case Otc::MessageChannelManagement:
            msg->getU16(); // channelId
            text = msg->getString();
            break;
        case Otc::MessageGuild:
        case Otc::MessagePartyManagement:
        case Otc::MessageParty:
        {
            msg->getU16(); // channelId
            text = msg->getString();
            break;
        }
        case Otc::MessageDamageDealed:
        case Otc::MessageDamageReceived:
        case Otc::MessageDamageOthers:
        {
            const auto& pos = getPosition(msg);
            std::array<uint32_t, 2> value;
            std::array<uint8_t, 2> color;

            // physical damage
            value[0] = msg->getU32();
            color[0] = msg->getU8();

            // magic damage
            value[1] = msg->getU32();
            color[1] = msg->getU8();
            text = msg->getString();

            for (auto j = 0; j < 2; j++) {
                if (value[j] == 0) {
                    continue;
                }

                g_map.addAnimatedText(std::make_shared<AnimatedText>(std::to_string(value[j]), color[j]), pos);
            }
            break;
        }
        case Otc::MessageHeal:
        case Otc::MessageMana:
        case Otc::MessageHealOthers:
        {
            const auto& pos = getPosition(msg);
            const uint32_t value = msg->getU32();
            const uint8_t color = msg->getU8();
            text = msg->getString();

            g_map.addAnimatedText(std::make_shared<AnimatedText>(std::to_string(value), color), pos);
            break;
        }
        case Otc::MessageExp:
        case Otc::MessageExpOthers:
        {
            const auto& pos = getPosition(msg);
            const uint64_t value = g_game.getClientVersion() >= 1332 ? msg->getU64() : msg->getU32();
            const uint8_t color = msg->getU8();
            text = msg->getString();

            g_map.addAnimatedText(std::make_shared<AnimatedText>(std::to_string(value), color), pos);
            break;
        }
        case Otc::MessageInvalid:
            throw Exception("ProtocolGame::parseTextMessage: unknown message mode %d", mode);
            break;
        default:
            break;
    }

    if (text.empty()) {
        text = msg->getString();
    }

    g_game.processTextMessage(mode, text);
}

void ProtocolGame::parseCancelWalk(const InputMessagePtr& msg)
{
    const auto direction = static_cast<Otc::Direction>(msg->getU8());
    g_game.processWalkCancel(direction);
}

void ProtocolGame::parseWalkWait(const InputMessagePtr& msg) const
{
    const uint16_t millis = msg->getU16();
    m_localPlayer->lockWalk(millis);
}

void ProtocolGame::parseUnjustifiedStats(const InputMessagePtr& msg)
{
    const uint8_t killsDay = msg->getU8();
    const uint8_t killsDayRemaining = msg->getU8();
    const uint8_t killsWeek = msg->getU8();
    const uint8_t killsWeekRemaining = msg->getU8();
    const uint8_t killsMonth = msg->getU8();
    const uint8_t killsMonthRemaining = msg->getU8();
    const uint8_t skullTime = msg->getU8();

    g_game.setUnjustifiedPoints({ killsDay, killsDayRemaining, killsWeek, killsWeekRemaining, killsMonth, killsMonthRemaining, skullTime });
}

void ProtocolGame::parseBestiaryTracker(const InputMessagePtr& msg)
{
    if (g_game.getFeature(Otc::GameBosstiaryTracker)) {
        msg->getU8(); // is bestiary boolean
    }

    const uint8_t size = msg->getU8();
    for (auto i = 0; i < size; ++i) {
        msg->getU16(); // RaceID
        msg->getU32(); // Kill count
        msg->getU16(); // First unlock
        msg->getU16(); // Second unlock
        msg->getU16(); // Last unlock
        msg->getU8(); // Status
    }
}

void ProtocolGame::parseTaskHuntingBasicData(const InputMessagePtr& msg)
{
    const uint16_t preys = msg->getU16();
    for (auto i = 0; i < preys; ++i) {
        msg->getU16(); // RaceID
        msg->getU8(); // Difficult
    }

    const uint8_t options = msg->getU8();
    for (auto i = 0; i < options; ++i) {
        msg->getU8(); // Difficult
        msg->getU8(); // Stars
        msg->getU16(); // First kill
        msg->getU16(); // First reward
        msg->getU16(); // Second kill
        msg->getU16(); // Second reward
    }
}

void ProtocolGame::parseTaskHuntingData(const InputMessagePtr& msg)
{
    msg->getU8(); // slot
    const auto state = static_cast<Otc::PreyTaskstate_t>(msg->getU8()); // slot state

    switch (state) {
        case Otc::PREY_TASK_STATE_LOCKED:
        {
            msg->getU8(); // task slot unlocked
            break;
        }
        case Otc::PREY_TASK_STATE_INACTIVE:
            break;
        case Otc::PREY_TASK_STATE_SELECTION:
        {
            const uint16_t creatures = msg->getU16();
            for (auto i = 0; i < creatures; ++i) {
                msg->getU16(); // RaceID
                msg->getU8(); // Is unlocked
            }
            break;
        }
        case Otc::PREY_TASK_STATE_LIST_SELECTION:
        {
            const uint16_t creatures = msg->getU16();
            for (auto i = 0; i < creatures; ++i) {
                msg->getU16(); // RaceID
                msg->getU8(); // Is unlocked
            }
            break;
        }
        case Otc::PREY_TASK_STATE_ACTIVE:
        {
            msg->getU16(); // RaceID
            msg->getU8(); // Upgraded
            msg->getU16(); // Required kills
            msg->getU16(); // Current kills
            msg->getU8(); // Stars
            break;
        }
        case Otc::PREY_TASK_STATE_COMPLETED:
        {
            msg->getU16(); // RaceID
            msg->getU8(); // Upgraded
            msg->getU16(); // Required kills
            msg->getU16(); // Current kills
            break;
        }
    }

    msg->getU32(); // next free roll
}

void ProtocolGame::parseBosstiaryCooldownTimer(const InputMessagePtr& msg)
{
    const uint16_t bossesOnTrackerSize = msg->getU16();
    for (auto i = 0; i < bossesOnTrackerSize; ++i) {
        msg->getU32(); // bossRaceId
        msg->getU64(); // Boss cooldown in seconds
    }
}

void ProtocolGame::parseFloorChangeUp(const InputMessagePtr& msg)
{
    const AwareRange& range = g_map.getAwareRange();

    auto pos = g_game.getFeature(Otc::GameMapMovePosition) ? getPosition(msg) : g_map.getCentralPosition();
    --pos.z;

    int skip = 0;
    if (pos.z == g_gameConfig.getMapSeaFloor()) {
        for (auto i = g_gameConfig.getMapSeaFloor() - g_gameConfig.getMapAwareUndergroundFloorRange(); i >= 0; --i) {
            skip = setFloorDescription(msg, pos.x - range.left, pos.y - range.top, i, range.horizontal(), range.vertical(), 8 - i, skip);
        }
    } else if (pos.z > g_gameConfig.getMapSeaFloor()) {
        setFloorDescription(msg, pos.x - range.left, pos.y - range.top, pos.z - g_gameConfig.getMapAwareUndergroundFloorRange(), range.horizontal(), range.vertical(), 3, skip);
    }

    ++pos.x;
    ++pos.y;
    g_map.setCentralPosition(pos);
}

void ProtocolGame::parseFloorChangeDown(const InputMessagePtr& msg)
{
    const AwareRange& range = g_map.getAwareRange();

    auto pos = g_game.getFeature(Otc::GameMapMovePosition) ? getPosition(msg) : g_map.getCentralPosition();
    ++pos.z;

    int skip = 0;
    if (pos.z == g_gameConfig.getMapUndergroundFloorRange()) {
        int j;
        int i;
        for (i = pos.z, j = -1; i <= pos.z + g_gameConfig.getMapAwareUndergroundFloorRange(); ++i, --j) {
            skip = setFloorDescription(msg, pos.x - range.left, pos.y - range.top, i, range.horizontal(), range.vertical(), j, skip);
        }
    } else if (pos.z > g_gameConfig.getMapUndergroundFloorRange() && pos.z < g_gameConfig.getMapMaxZ() - 1) {
        setFloorDescription(msg, pos.x - range.left, pos.y - range.top, pos.z + g_gameConfig.getMapAwareUndergroundFloorRange(), range.horizontal(), range.vertical(), -3, skip);
    }

    --pos.x;
    --pos.y;
    g_map.setCentralPosition(pos);
}

void ProtocolGame::parseLootContainers(const InputMessagePtr& msg)
{
    msg->getU8(); // quickLootFallbackToMainContainer ? 1 : 0

    const uint8_t containers = msg->getU8();
    for (auto i = 0; i < containers; ++i) {
        msg->getU8(); // category type
        msg->getU16(); // loot container id
        if (g_game.getClientVersion() >= 1332) {
            msg->getU16(); // obtainer container id
        }
    }
}

void ProtocolGame::parseOpenOutfitWindow(const InputMessagePtr& msg) const
{
    const Outfit currentOutfit = getOutfit(msg);

    // mount color bytes are required here regardless of having one
    if (g_game.getClientVersion() >= 1281) {
        if (currentOutfit.getMount() == 0) {
            msg->getU8(); //head
            msg->getU8(); //body
            msg->getU8(); //legs
            msg->getU8(); //feet
        }

        msg->getU16(); // current familiar looktype
    }

    std::vector<std::tuple<int, std::string, int>> outfitList;

    if (g_game.getFeature(Otc::GameNewOutfitProtocol)) {
        const uint16_t outfitCount = g_game.getClientVersion() >= 1281 ? msg->getU16() : msg->getU8();
        for (auto i = 0; i < outfitCount; ++i) {
            uint16_t outfitId = msg->getU16();
            const auto& outfitName = msg->getString();
            uint8_t outfitAddons = msg->getU8();

            if (g_game.getClientVersion() >= 1281) {
                const uint8_t outfitMode = msg->getU8(); // mode: 0x00 - available, 0x01 store (requires U32 store offerId), 0x02 golden outfit tooltip (hardcoded)
                if (outfitMode == 1) {
                    msg->getU32();
                }
            }

            outfitList.emplace_back(outfitId, outfitName, outfitAddons);
        }
    } else {
        uint16_t outfitStart;
        uint16_t outfitEnd;
        if (g_game.getFeature(Otc::GameLooktypeU16)) {
            outfitStart = msg->getU16();
            outfitEnd = msg->getU16();
        } else {
            outfitStart = msg->getU8();
            outfitEnd = msg->getU8();
        }

        for (auto i = outfitStart; i <= outfitEnd; ++i) {
            outfitList.emplace_back(i, "", 0);
        }
    }

    std::vector<std::tuple<int, std::string> > mountList;

    if (g_game.getFeature(Otc::GamePlayerMounts)) {
        const uint16_t mountCount = g_game.getClientVersion() >= 1281 ? msg->getU16() : msg->getU8();
        for (auto i = 0; i < mountCount; ++i) {
            const uint16_t mountId = msg->getU16(); // mount type
            const auto& mountName = msg->getString(); // mount name

            if (g_game.getClientVersion() >= 1281) {
                const uint8_t mountMode = msg->getU8(); // mode: 0x00 - available, 0x01 store (requires U32 store offerId)
                if (mountMode == 1) {
                    msg->getU32();
                }
            }

            mountList.emplace_back(mountId, mountName);
        }
    }

    if (g_game.getClientVersion() >= 1281) {
        const uint16_t familiarCount = msg->getU16();
        for (auto i = 0; i < familiarCount; ++i) {
            msg->getU16(); // familiar lookType
            msg->getString(); // familiar name
            const uint8_t familiarMode = msg->getU8(); // 0x00 // mode: 0x00 - available, 0x01 store (requires U32 store offerId)
            if (familiarMode == 1) {
                msg->getU32();
            }
        }

        msg->getU8(); // Try outfit mode (?)
        msg->getU8(); // (bool) mounted
        msg->getU8(); // (bool) randomize mount
    }

    std::vector<std::tuple<int, std::string> > wingList;
    std::vector<std::tuple<int, std::string> > auraList;
    std::vector<std::tuple<int, std::string> > effectList;
    std::vector<std::tuple<int, std::string> > shaderList;

    if (g_game.getFeature(Otc::GameWingsAurasEffectsShader)) {
        const uint8_t wingCount = msg->getU8();
        for (auto i = 0; i < wingCount; ++i) {
            const uint16_t wingId = msg->getU16();
            const auto& wingName = msg->getString();
            wingList.emplace_back(wingId, wingName);
        }

        const uint8_t auraCount = msg->getU8();
        for (auto i = 0; i < auraCount; ++i) {
            const uint16_t auraId = msg->getU16();
            const auto& auraName = msg->getString();
            auraList.emplace_back(auraId, auraName);
        }

        const uint8_t effectCount = msg->getU8();
        for (auto i = 0; i < effectCount; ++i) {
            const uint16_t effectId = msg->getU16();
            const auto& effectName = msg->getString();
            effectList.emplace_back(effectId, effectName);
        }

        const uint8_t shaderCount = msg->getU8();
        for (auto i = 0; i < shaderCount; ++i) {
            const uint16_t shaderId = msg->getU16();
            const auto& shaderName = msg->getString();
            shaderList.emplace_back(shaderId, shaderName);
        }
   }

    g_game.processOpenOutfitWindow(currentOutfit, outfitList, mountList, wingList, auraList, effectList, shaderList);
}

void ProtocolGame::parseUpdateImpactTracker(const InputMessagePtr& msg)
{
    const uint8_t type = msg->getU8();
    msg->getU32(); // amount
    if (type == 1) {
        msg->getU8(); // Element
    } else if (type == 2) {
        msg->getU8(); // Element
        msg->getString(); // Name
    }

    // TODO: implement impact tracker usage
}


















void ProtocolGame::parseRequestPurchaseData(const InputMessagePtr& msg)
{
    msg->getU32(); // transactionId
    msg->getU8(); // productType
}

void ProtocolGame::parseResourceBalance(const InputMessagePtr& msg) const
{
    const auto type = static_cast<Otc::ResourceTypes_t>(msg->getU8());
    const uint64_t value = msg->getU64();
    m_localPlayer->setResourceBalance(type, value);
}

void ProtocolGame::parseWorldTime(const InputMessagePtr& msg)
{
    const auto hour = msg->getU8();
    const auto min = msg->getU8();
    g_lua.callGlobalField("g_game", "onChangeWorldTime", hour, min);
}

void ProtocolGame::parseStore(const InputMessagePtr& msg) const
{
    parseCoinBalance(msg);

    const uint8_t categories = msg->getU16();
    for (auto i = -1; ++i < categories;) {
        msg->getString(); // category
        msg->getString(); // description

        if (g_game.getFeature(Otc::GameIngameStoreHighlights))
            msg->getU8(); // highlightState

        std::vector<std::string> icons;
        const uint8_t iconCount = msg->getU8();
        for (auto j = -1; ++j < iconCount; ) {
            icons.push_back(msg->getString());
        }

        // If this is a valid category name then
        // the category we just parsed is a child of that
        msg->getString();
    }
}

void ProtocolGame::parseCoinBalance(const InputMessagePtr& msg) const
{
    const bool update = msg->getU8() == 1;
    if (update) {
        // amount of coins that can be used to buy prodcuts
        // in the ingame store
        const uint32_t coins = msg->getU32(); // coins
        m_localPlayer->setResourceBalance(Otc::RESOURE_COIN_NORMAL, coins);

        // amount of coins that can be sold in market
        // or be transfered to another player
        const uint32_t transferrableCoins = msg->getU32(); // transferableCoins
        m_localPlayer->setResourceBalance(Otc::RESOURE_COIN_TRANSFERRABLE, transferrableCoins);

        if (g_game.getClientVersion() >= 1281) {
            const uint32_t auctionCoins = msg->getU32();
            m_localPlayer->setResourceBalance(Otc::RESOURE_COIN_AUCTION, auctionCoins);
            if (g_game.getFeature(Otc::GameTournamentPackets)) {
                const uint32_t tournamentCoins = msg->getU32();
                m_localPlayer->setResourceBalance(Otc::RESOURE_COIN_TOURNAMENT, tournamentCoins);
            }
        }
    }
}

void ProtocolGame::parseCoinBalanceUpdating(const InputMessagePtr& msg)
{
    // coin balance can be updating and might not be accurate
    msg->getU8(); // == 1; // isUpdating
}

void ProtocolGame::parseCompleteStorePurchase(const InputMessagePtr& msg) const
{
    // not used
    msg->getU8();

    const auto& message = msg->getString();
    const uint32_t coins = msg->getU32();
    const uint32_t transferableCoins = msg->getU32();

    g_logger.info(stdext::format("Purchase Complete: %s\nAvailable coins: %d (transferable: %d)", message, coins, transferableCoins));
}

void ProtocolGame::parseStoreTransactionHistory(const InputMessagePtr& msg) const
{
    if (g_game.getClientVersion() <= 1096) {
        msg->getU16(); // currentPage
        msg->getU8(); // hasNextPage (bool)
    } else {
        msg->getU32(); // currentPage
        msg->getU32(); // pageCount
    }

    const uint8_t entries = msg->getU8();
    for (auto i = -1; ++i < entries;) {
        uint16_t time = msg->getU16();
        uint8_t productType = msg->getU8();
        uint32_t coinChange = msg->getU32();
        const auto& productName = msg->getString();
        g_logger.error(stdext::format("Time %i, type %i, change %i, product name %s", time, productType, coinChange, productName));
    }
}

void ProtocolGame::parseStoreOffers(const InputMessagePtr& msg)
{
    msg->getString(); // categoryName

    const uint16_t offers = msg->getU16();
    for (auto i = -1; ++i < offers;) {
        msg->getU32(); // offerId
        msg->getString(); // offerName
        msg->getString(); // offerDescription

        msg->getU32(); // price
        const uint8_t highlightState = msg->getU8();
        if (highlightState == 2 && g_game.getFeature(Otc::GameIngameStoreHighlights) && g_game.getClientVersion() >= 1097) {
            msg->getU32(); // saleValidUntilTimestamp
            msg->getU32(); // basePrice
        }

        const uint8_t disabledState = msg->getU8();
        if (g_game.getFeature(Otc::GameIngameStoreHighlights) && disabledState == 1) {
            msg->getString(); // disabledReason
        }

        std::vector<std::string> icons;
        const uint8_t iconCount = msg->getU8();
        for (auto j = -1; ++j < iconCount;) {
            icons.emplace_back(msg->getString());
        }

        const uint16_t subOffers = msg->getU16();
        for (auto j = -1; ++j < subOffers;) {
            msg->getString(); // name
            msg->getString(); // description

            const uint8_t subIcons = msg->getU8();
            for (auto k = -1; ++k < subIcons;) {
                msg->getString(); // icon
            }
            msg->getString(); // serviceType
        }
    }
}

void ProtocolGame::parseStoreError(const InputMessagePtr& msg) const
{
    const uint8_t errorType = msg->getU8();
    const auto& message = msg->getString();
    g_logger.error(stdext::format("Store Error: %s [%i]", message, errorType));
}

void ProtocolGame::parsePvpSituations(const InputMessagePtr& msg)
{
    const uint8_t openPvpSituations = msg->getU8();

    g_game.setOpenPvpSituations(openPvpSituations);
}

void ProtocolGame::parseKillTracker(const InputMessagePtr& msg)
{
    msg->getString(); // monster name
    getOutfit(msg, false);

    // corpse items
    const uint8_t size = msg->getU8();
    for (auto i = 0; i < size; ++i) {
        getItem(msg);
    }
}

void ProtocolGame::parseVipAdd(const InputMessagePtr& msg)
{
    uint32_t iconId = 0;
    std::string desc;
    bool notifyLogin = false;

    const uint32_t id = msg->getU32();
    const auto& name = g_game.formatCreatureName(msg->getString());
    if (g_game.getFeature(Otc::GameAdditionalVipInfo)) {
        desc = msg->getString();
        iconId = msg->getU32();
        notifyLogin = msg->getU8();
    }
    const uint32_t status = msg->getU8();

    if (g_game.getFeature(Otc::GameVipGroups)) {
        const uint8_t size = msg->getU8();
        for (auto i = 0; i < size; ++i) {
            msg->getU8(); // Group ID
        }
    }

    g_game.processVipAdd(id, name, status, desc, iconId, notifyLogin);
}

void ProtocolGame::parseVipState(const InputMessagePtr& msg)
{
    const uint32_t id = msg->getU32();
    if (g_game.getFeature(Otc::GameLoginPending)) {
        const uint32_t status = msg->getU8();
        g_game.processVipStateChange(id, status);
    } else {
        g_game.processVipStateChange(id, 1);
    }
}

void ProtocolGame::parseVipLogout(const InputMessagePtr& msg)
{
    // On QT client this operation is being processed on the 'parseVipState', now this opcode if for groups
    if (g_game.getFeature(Otc::GameVipGroups)) {
        const uint8_t size = msg->getU8();
        for (auto i = 0; i < size; ++i) {
            msg->getU8(); // Group ID
            msg->getString(); // Group name
            msg->getU8(); // Can edit group? (bool)
        }
        msg->getU8(); // Groups amount left
    } else {
        const uint32_t id = msg->getU32();
        g_game.processVipStateChange(id, 0);
    }
}

void ProtocolGame::parseTutorialHint(const InputMessagePtr& msg)
{
    const uint8_t id = msg->getU8();
    g_game.processTutorialHint(id);
}

void ProtocolGame::parseAutomapFlag(const InputMessagePtr& msg)
{
    const auto& pos = getPosition(msg);
    const uint8_t icon = msg->getU8();
    const auto& description = msg->getString();

    bool remove = false;
    if (g_game.getFeature(Otc::GameMinimapRemove))
        remove = msg->getU8() != 0;

    if (!remove)
        g_game.processAddAutomapFlag(pos, icon, description);
    else
        g_game.processRemoveAutomapFlag(pos, icon, description);
}

void ProtocolGame::parseQuestLog(const InputMessagePtr& msg)
{
    std::vector<std::tuple<int, std::string, bool> > questList;
    const uint16_t questsCount = msg->getU16();
    for (auto i = 0; i < questsCount; ++i) {
        uint16_t id = msg->getU16();
        const auto& questName = msg->getString();
        bool questCompleted = msg->getU8();
        questList.emplace_back(id, questName, questCompleted);
    }

    g_game.processQuestLog(questList);
}

void ProtocolGame::parseQuestLine(const InputMessagePtr& msg)
{
    std::vector<std::tuple<std::string, std::string>> questMissions;
    const uint16_t questId = msg->getU16();
    const uint8_t missionCount = msg->getU8();
    for (auto i = 0; i < missionCount; ++i) {
        const auto& missionName = msg->getString();
        const auto& missionDescrition = msg->getString();
        questMissions.emplace_back(missionName, missionDescrition);
    }

    g_game.processQuestLine(questId, questMissions);
}

void ProtocolGame::parseChannelEvent(const InputMessagePtr& msg)
{
    const uint16_t channelId = msg->getU16();
    const auto& channelName = msg->getString();
    const uint8_t channelType = msg->getU8();

    g_lua.callGlobalField("g_game", "onChannelEvent", channelId, channelName, channelType);
}

void ProtocolGame::parseItemInfo(const InputMessagePtr& msg) const
{
    std::vector<std::tuple<ItemPtr, std::string>> list;
    const uint8_t size = msg->getU8();
    for (auto i = 0; i < size; ++i) {
        const auto& item = std::make_shared<Item>();
        item->setId(msg->getU16());
        item->setCountOrSubType(g_game.getFeature(Otc::GameCountU16) ? msg->getU16() : msg->getU8());

        const auto& desc = msg->getString();
        list.emplace_back(item, desc);
    }

    g_lua.callGlobalField("g_game", "onItemInfo", list);
}

void ProtocolGame::parsePlayerInventory(const InputMessagePtr& msg)
{
    const uint16_t size = msg->getU16();
    for (auto i = 0; i < size; ++i) {
        msg->getU16(); // id
        msg->getU8(); // subtype
        msg->getU16(); // count
    }
}

void ProtocolGame::parseModalDialog(const InputMessagePtr& msg)
{
    const uint32_t windowId = msg->getU32();
    const auto& title = msg->getString();
    const auto& message = msg->getString();

    const uint8_t sizeButtons = msg->getU8();
    std::vector<std::tuple<int, std::string> > buttonList;
    for (auto i = 0; i < sizeButtons; ++i) {
        const auto& value = msg->getString();
        uint8_t buttonId = msg->getU8();
        buttonList.emplace_back(buttonId, value);
    }

    const uint8_t sizeChoices = msg->getU8();
    std::vector<std::tuple<int, std::string> > choiceList;
    for (auto i = 0; i < sizeChoices; ++i) {
        const auto& value = msg->getString();
        uint8_t choideId = msg->getU8();
        choiceList.emplace_back(choideId, value);
    }

    uint8_t enterButton;
    uint8_t escapeButton;
    if (g_game.getClientVersion() > 970) {
        escapeButton = msg->getU8();
        enterButton = msg->getU8();
    } else {
        enterButton = msg->getU8();
        escapeButton = msg->getU8();
    }

    const bool priority = msg->getU8() == 0x01;

    g_game.processModalDialog(windowId, title, message, buttonList, enterButton, escapeButton, choiceList, priority);
}

void ProtocolGame::setMapDescription(const InputMessagePtr& msg, int x, int y, int z, int width, int height)
{
    int startz;
    int endz;
    int zstep;

    if (z > g_gameConfig.getMapSeaFloor()) {
        startz = z - g_gameConfig.getMapAwareUndergroundFloorRange();
        endz = std::min<int>(z + g_gameConfig.getMapAwareUndergroundFloorRange(), g_gameConfig.getMapMaxZ());
        zstep = 1;
    } else {
        startz = g_gameConfig.getMapSeaFloor();
        endz = 0;
        zstep = -1;
    }

    int skip = 0;
    for (auto nz = startz; nz != endz + zstep; nz += zstep)
        skip = setFloorDescription(msg, x, y, nz, width, height, z - nz, skip);
}

int ProtocolGame::setFloorDescription(const InputMessagePtr& msg, int x, int y, int z, int width, int height, int offset, int skip)
{
    for (auto nx = 0; nx < width; ++nx) {
        for (auto ny = 0; ny < height; ++ny) {
            const Position tilePos(x + nx + offset, y + ny + offset, z);
            if (skip == 0)
                skip = setTileDescription(msg, tilePos);
            else {
                g_map.cleanTile(tilePos);
                --skip;
            }
        }
    }
    return skip;
}

int ProtocolGame::setTileDescription(const InputMessagePtr& msg, Position position)
{
    g_map.cleanTile(position);

    bool gotEffect = false;
    for (auto stackPos = 0; stackPos < 256; ++stackPos) {
        if (msg->peekU16() >= 0xff00)
            return msg->getU16() & 0xff;

        if (g_game.getFeature(Otc::GameEnvironmentEffect) && !gotEffect) {
            msg->getU16(); // environment effect
            gotEffect = true;
            continue;
        }

        if (stackPos > g_gameConfig.getTileMaxThings())
            g_logger.traceError(stdext::format("too many things, pos=%s, stackpos=%d", stdext::to_string(position), stackPos));

        const auto& thing = getThing(msg);
        g_map.addThing(thing, position, stackPos);
    }

    return 0;
}

Outfit ProtocolGame::getOutfit(const InputMessagePtr& msg, bool parseMount/* = true*/) const
{
    Outfit outfit;

    uint16_t lookType;
    if (g_game.getFeature(Otc::GameLooktypeU16))
        lookType = msg->getU16();
    else
        lookType = msg->getU8();

    if (lookType != 0) {
        outfit.setCategory(ThingCategoryCreature);
        const uint8_t head = msg->getU8();
        const uint8_t body = msg->getU8();
        const uint8_t legs = msg->getU8();
        const uint8_t feet = msg->getU8();
        const uint8_t addons = g_game.getFeature(Otc::GamePlayerAddons) ? msg->getU8() : 0;

        if (!g_things.isValidDatId(lookType, ThingCategoryCreature)) {
            g_logger.traceError(stdext::format("invalid outfit looktype %d", lookType));
            lookType = 0;
        }

        outfit.setId(lookType);
        outfit.setHead(head);
        outfit.setBody(body);
        outfit.setLegs(legs);
        outfit.setFeet(feet);
        outfit.setAddons(addons);
    } else {
        uint16_t lookTypeEx = msg->getU16();
        if (lookTypeEx == 0) {
            outfit.setCategory(ThingCategoryEffect);
            outfit.setAuxId(13); // invisible effect id
        } else {
            if (!g_things.isValidDatId(lookTypeEx, ThingCategoryItem)) {
                g_logger.traceError(stdext::format("invalid outfit looktypeex %d", lookTypeEx));
                lookTypeEx = 0;
            }
            outfit.setCategory(ThingCategoryItem);
            outfit.setAuxId(lookTypeEx);
        }
    }

    if (g_game.getFeature(Otc::GamePlayerMounts) && parseMount) {
        const uint16_t mount = msg->getU16();
        if (g_game.getClientVersion() >= 1281 && mount != 0) {
            msg->getU8(); //head
            msg->getU8(); //body
            msg->getU8(); //legs
            msg->getU8(); //feet
        }
        outfit.setMount(mount);
    }

    if (g_game.getFeature(Otc::GameWingsAurasEffectsShader)) {
        const uint16_t wings = msg->getU16();
        outfit.setWing(wings);

        const uint16_t auras = msg->getU16();
        outfit.setAura(auras);

        const uint16_t effects = msg->getU16();
        outfit.setEffect(effects);

        outfit.setShader(msg->getString());
    }

    return outfit;
}

ThingPtr ProtocolGame::getThing(const InputMessagePtr& msg)
{
    const uint16_t id = msg->getU16();
    if (id == 0)
        throw Exception("invalid thing id");

    if (id == Proto::UnknownCreature || id == Proto::OutdatedCreature || id == Proto::Creature)
        return getCreature(msg, id);

    return getItem(msg, id); // item
}

ThingPtr ProtocolGame::getMappedThing(const InputMessagePtr& msg) const
{
    const uint16_t x = msg->getU16();
    if (x != 0xffff) {
        const uint16_t y = msg->getU16();
        const uint8_t z = msg->getU8();

        const uint8_t stackpos = msg->getU8();
        assert(stackpos != UINT8_MAX);

        const Position& pos{ x, y, z };
        if (const auto& thing = g_map.getThing(pos, stackpos))
            return thing;

        g_logger.traceError(stdext::format("no thing at pos:%s, stackpos:%d", stdext::to_string(pos), stackpos));
    } else {
        const uint32_t creatureId = msg->getU32();
        if (const auto& thing = g_map.getCreatureById(creatureId))
            return thing;

        g_logger.traceError(stdext::format("ProtocolGame::getMappedThing: no creature with id %u", creatureId));
    }

    return nullptr;
}

CreaturePtr ProtocolGame::getCreature(const InputMessagePtr& msg, int type) const
{
    if (type == 0)
        type = msg->getU16();

    CreaturePtr creature;
    const bool known = type != Proto::UnknownCreature;
    if (type == Proto::OutdatedCreature || type == Proto::UnknownCreature) {
        if (known) {
            const uint32_t creatureId = msg->getU32();
            creature = g_map.getCreatureById(creatureId);
            if (!creature)
                g_logger.traceError("ProtocolGame::getCreature: server said that a creature is known, but it's not");
        } else {
            const uint32_t removeId = msg->getU32();
            const uint32_t id = msg->getU32();

            if (id == removeId) {
                creature = g_map.getCreatureById(id);
            } else {
                g_map.removeCreatureById(removeId);
            }

            uint8_t creatureType;
            if (g_game.getClientVersion() >= 910)
                creatureType = msg->getU8();
            else if (id >= Proto::PlayerStartId && id < Proto::PlayerEndId)
                creatureType = Proto::CreatureTypePlayer;
            else if (id >= Proto::MonsterStartId && id < Proto::MonsterEndId)
                creatureType = Proto::CreatureTypeMonster;
            else
                creatureType = Proto::CreatureTypeNpc;

            uint32_t masterId = 0;
            if (g_game.getClientVersion() >= 1281 && creatureType == Proto::CreatureTypeSummonOwn) {
                masterId = msg->getU32();
                if (m_localPlayer->getId() != masterId)
                    creatureType = Proto::CreatureTypeSummonOther;
            }

            const auto& name = g_game.formatCreatureName(msg->getString());

            if (!creature) {
                if ((id == m_localPlayer->getId()) ||
                    // fixes a bug server side bug where GameInit is not sent and local player id is unknown
                    (creatureType == Proto::CreatureTypePlayer && !m_localPlayer->getId() && name == m_localPlayer->getName())) {
                    creature = m_localPlayer;
                } else {
                    switch (creatureType) {
                        case Proto::CreatureTypePlayer:
                            creature = std::make_shared<Player>();
                            break;

                        case Proto::CreatureTypeNpc:
                            creature = std::make_shared<Npc>();
                            break;

                        case Proto::CreatureTypeHidden:
                        case Proto::CreatureTypeMonster:
                        case Proto::CreatureTypeSummonOwn:
                        case Proto::CreatureTypeSummonOther:
                            creature = std::make_shared<Monster>();
                            break;

                        default:
                            g_logger.traceError("creature type is invalid");
                    }

                    if (creature)
                        creature->onCreate();
                }
            }

            if (creature) {
                creature->setId(id);
                creature->setName(name);
                creature->setMasterId(masterId);

                g_map.addCreature(creature);
            }
        }

        const uint8_t healthPercent = msg->getU8();
        const auto direction = static_cast<Otc::Direction>(msg->getU8());
        const Outfit& outfit = getOutfit(msg);

        Light light;
        light.intensity = msg->getU8();
        light.color = msg->getU8();

        const uint16_t speed = msg->getU16();

        if (g_game.getClientVersion() >= 1281) {
            const uint8_t iconDebuff = msg->getU8(); // creature debuffs
            if (iconDebuff != 0) {
                msg->getU8(); // Icon
                msg->getU8(); // Update (?)
                msg->getU16(); // Counter text
            }
        }

        const uint8_t skull = msg->getU8();
        const uint8_t shield = msg->getU8();

        // emblem is sent only when the creature is not known
        uint8_t emblem = 0;
        uint8_t creatureType = 0;
        uint8_t icon = 0;
        bool unpass = true;

        if (g_game.getFeature(Otc::GameCreatureEmblems) && !known)
            emblem = msg->getU8();

        if (g_game.getFeature(Otc::GameThingMarks)) {
            creatureType = msg->getU8();
        }

        uint32_t masterId = 0;
        if (g_game.getClientVersion() >= 1281) {
            if (creatureType == Proto::CreatureTypeSummonOwn) {
                masterId = msg->getU32();
                if (m_localPlayer->getId() != masterId)
                    creatureType = Proto::CreatureTypeSummonOther;
            } else if (creatureType == Proto::CreatureTypePlayer) {
                msg->getU8(); // voc id
            }
        }

        if (g_game.getFeature(Otc::GameCreatureIcons)) {
            icon = msg->getU8();
        }

        if (g_game.getFeature(Otc::GameThingMarks)) {
            const uint8_t mark = msg->getU8(); // mark

            if (g_game.getClientVersion() < 1281) {
                msg->getU16(); // helpers
            }

            if (creature) {
                if (mark == 0xff)
                    creature->hideStaticSquare();
                else
                    creature->showStaticSquare(Color::from8bit(mark));
            }
        }

        if (g_game.getClientVersion() >= 1281) {
            msg->getU8(); // inspection type
        }

        if (g_game.getClientVersion() >= 854)
            unpass = msg->getU8();

        std::string shader;
        if (g_game.getFeature(Otc::GameCreatureShader)) {
            shader = msg->getString();
        }

        std::vector<uint16_t> attachedEffectList;
        if (g_game.getFeature(Otc::GameCreatureAttachedEffect)) {
            const uint8_t listSize = msg->getU8();
            for (auto i = -1; ++i < listSize;)
                attachedEffectList.push_back(msg->getU16());
        }

        if (creature) {
            creature->setHealthPercent(healthPercent);
            creature->turn(direction);
            creature->setOutfit(outfit);
            creature->setSpeed(speed);
            creature->setSkull(skull);
            creature->setShield(shield);
            creature->setPassable(!unpass);
            creature->setLight(light);
            creature->setMasterId(masterId);
            creature->setShader(shader);
            creature->clearTemporaryAttachedEffects();
            for (const auto effectId : attachedEffectList) {
                const auto& effect = g_attachedEffects.getById(effectId);
                if (effect) {
                    const auto& clonedEffect = effect->clone();
                    clonedEffect->setPermanent(false);
                    creature->attachEffect(clonedEffect);
                }
            }

            if (emblem > 0)
                creature->setEmblem(emblem);

            if (creatureType > 0)
                creature->setType(creatureType);

            if (icon > 0)
                creature->setIcon(icon);

            if (creature == m_localPlayer && !m_localPlayer->isKnown())
                m_localPlayer->setKnown(true);
        }
    } else if (type == Proto::Creature) {
        // this is send creature turn
        const uint32_t creatureId = msg->getU32();
        creature = g_map.getCreatureById(creatureId);
        if (!creature)
            g_logger.traceError("ProtocolGame::getCreature: invalid creature");

        const auto direction = static_cast<Otc::Direction>(msg->getU8());
        if (creature)
            creature->turn(direction);

        if (g_game.getClientVersion() >= 953) {
            const bool unpass = msg->getU8();

            if (creature)
                creature->setPassable(!unpass);
        }
    } else throw Exception("invalid creature opcode");

    return creature;
}

ItemPtr ProtocolGame::getItem(const InputMessagePtr& msg, int id)
{
    if (id == 0)
        id = msg->getU16();

    const auto& item = Item::create(id);
    if (item->getId() == 0)
        throw Exception("unable to create item with invalid id %d", id);

    if (g_game.getClientVersion() < 1281 && g_game.getFeature(Otc::GameThingMarks)) {
        msg->getU8(); // mark
    }

    if (item->isStackable() || item->isFluidContainer() || item->isSplash() || item->isChargeable()) {
        item->setCountOrSubType(g_game.getFeature(Otc::GameCountU16) ? msg->getU16() : msg->getU8());
    }

    if (g_game.getFeature(Otc::GameItemAnimationPhase)) {
        if (item->getAnimationPhases() > 1) {
            // 0x00 => automatic phase
            // 0xFE => random phase
            // 0xFF => async phase
            msg->getU8();
            //item->setPhase(msg->getU8());
        }
    }

    if (item->isContainer()) {
        if (g_game.getFeature(Otc::GameContainerTypes)) {
            const uint8_t containerType = msg->getU8(); // container type
            switch (containerType) {
                case 2: // Content Counter
                    msg->getU32(); // ammo total
                    break;
                case 4: // Loot Highlight
                    break;
                case 9: // Manager
                    msg->getU32(); // loot flags
                    if (g_game.getClientVersion() >= 1332) {
                        msg->getU32(); // obtain flags
                    }
                    break;
                case 11: // Quiver Loot
                    msg->getU32(); // loot flags
                    msg->getU32(); // ammo total
                    if (g_game.getClientVersion() >= 1332) {
                        msg->getU32(); // obtain flags
                    }
                    break;
                default:
                    break;
            }
        } else {
            if (g_game.getFeature(Otc::GameThingQuickLoot)) {
                const bool hasQuickLootFlags = msg->getU8() != 0;
                if (hasQuickLootFlags) {
                    msg->getU32(); // quick loot flags
                }
            }

            if (g_game.getFeature(Otc::GameThingQuiver)) {
                const uint8_t hasQuiverAmmoCount = msg->getU8();
                if (hasQuiverAmmoCount) {
                    msg->getU32(); // ammo total
                }
            }
        }
    }

    if (g_game.getFeature(Otc::GameThingPodium)) {
        if (item->isPodium()) {
            const uint16_t looktype = msg->getU16();
            if (looktype != 0) {
                msg->getU8(); // lookHead
                msg->getU8(); // lookBody
                msg->getU8(); // lookLegs
                msg->getU8(); // lookFeet
                msg->getU8(); // lookAddons
            } else if (g_game.getFeature(Otc::GameThingPodiumItemType)) {
                msg->getU16(); // LookTypeEx
            }

            const uint16_t lookmount = msg->getU16();
            if (lookmount != 0) {
                msg->getU8(); // lookHead
                msg->getU8(); // lookBody
                msg->getU8(); // lookLegs
                msg->getU8(); // lookFeet
            }

            msg->getU8(); // direction
            msg->getU8(); // visible (bool)
        }
    }

    if (g_game.getFeature(Otc::GameThingUpgradeClassification)) {
        if (item->getClassification() != 0) {
            msg->getU8(); // Item tier
        }
    }

    if (g_game.getFeature(Otc::GameThingClock)) {
        if (item->hasClockExpire() || item->hasExpire() || item->hasExpireStop()) {
            msg->getU32(); // Item duration (UI)
            msg->getU8(); // Is brand-new
        }
    }

    if (g_game.getFeature(Otc::GameThingCounter)) {
        if (item->hasWearOut()) {
            msg->getU32(); // Item charge (UI)
            msg->getU8(); // Is brand-new
        }
    }

    if (g_game.getFeature(Otc::GameWrapKit)) {
        if (item->isDecoKit()) {
            msg->getU16();
        }
    }

    if (g_game.getFeature(Otc::GameItemShader)) {
        item->setShader(msg->getString());
    }

    if (g_game.getFeature(Otc::GameItemTooltipV8)) {
        item->setTooltip(msg->getString());
    }

    return item;
}

Position ProtocolGame::getPosition(const InputMessagePtr& msg)
{
    const uint16_t x = msg->getU16();
    const uint16_t y = msg->getU16();
    const uint8_t z = msg->getU8();

    return { x, y, z };
}

// 12x
void ProtocolGame::parseShowDescription(const InputMessagePtr& msg)
{
    msg->getU32(); // offerId
    msg->getString();  // offer description
}

void ProtocolGame::parseItemsPrice(const InputMessagePtr& msg)
{
    const uint16_t priceCount = msg->getU16(); // count

    for (auto i = 0; i < priceCount; ++i) {
        const uint16_t itemId = msg->getU16(); // item client id
        if (g_game.getClientVersion() >= 1281) {
            const auto& item = Item::create(itemId);

            // note: vanilla client allows made-up client ids
            // their classification is assumed as 0
            if (item->getId() != 0 && item->getClassification() > 0) {
                msg->getU8();
            }
            msg->getU64(); // price
        } else {
            msg->getU32(); // price
        }
    }

    // TODO: implement items price usage
}

void ProtocolGame::parseUpdateSupplyTracker(const InputMessagePtr& msg)
{
    msg->getU16(); // item client ID

    // TODO: implement supply tracker usage
}

void ProtocolGame::parseUpdateLootTracker(const InputMessagePtr& msg)
{
    getItem(msg); // item
    msg->getString(); // item name

    // TODO: implement loot tracker usage
}

void ProtocolGame::parseBestiaryEntryChanged(const InputMessagePtr& msg)
{
    msg->getU16(); // monster ID

    // TODO: implement bestiary entry changed usage
}

void ProtocolGame::parseDailyRewardCollectionState(const InputMessagePtr& msg)
{
    msg->getU8(); // state

    // TODO: implement daily reward collection state usage
}

void ProtocolGame::parseOpenRewardWall(const InputMessagePtr& msg)
{
    msg->getU8(); // bonus shrine (1) or instant bonus (0)
    msg->getU32(); // next reward time
    msg->getU8(); // day streak day

    if (const uint8_t wasDailyRewardTaken = msg->getU8(); wasDailyRewardTaken != 0) {// taken (player already took reward?)
        msg->getString(); // error message
        const uint8_t token = msg->getU8();
        if (token != 0) {
            msg->getU16(); // Tokens
        }
    } else {
        msg->getU8(); // Unknown
        msg->getU32(); // time left to pickup reward without loosing streak
        msg->getU16(); // Tokens
    }

    msg->getU16(); // day streak level
    // TODO: implement open reward wall usage
}

namespace {
    void parseRewardDay(const InputMessagePtr& msg)
    {
        const uint8_t redeemMode = msg->getU8(); // reward type
        if (redeemMode == 1) {
            // select x items from the list
            msg->getU8(); // items to select

            const uint8_t itemListSize = msg->getU8();
            for (auto listIndex = 0; listIndex < itemListSize; ++listIndex) {
                msg->getU16(); // Item ID
                msg->getString(); // Item name
                msg->getU32(); // Item weight
            }
        } else if (redeemMode == 2) {
            // no choice, click to redeem all

            const uint8_t itemListSize = msg->getU8();
            for (auto listIndex = 0; listIndex < itemListSize; ++listIndex) {
                const uint8_t bundleType = msg->getU8(); // type of reward
                switch (bundleType) {
                    case 1: {
                        // Items
                        msg->getU16(); // Item ID
                        msg->getString(); // Item name
                        msg->getU8(); // Item Count
                        break;
                    }
                    case 2: {
                        // Prey Wildcards
                        msg->getU8(); // Prey Wildcards Count
                        break;
                    }
                    case 3: {
                        // XP Boost
                        msg->getU16(); // XP Boost Minutes
                        break;
                    }
                    default:
                        // Invalid type
                        break;
                }
            }
        }
    }
}
void ProtocolGame::parseDailyReward(const InputMessagePtr& msg)
{
    const uint8_t days = msg->getU8(); // Reward count (7 days)
    for (auto day = 1; day <= days; ++day) {
        parseRewardDay(msg); // Free account
        parseRewardDay(msg); // Premium account
    }

    const uint8_t bonus = msg->getU8();
    for (auto i = 0; i < bonus; ++i) {
        msg->getString(); // Bonus name
        msg->getU8(); // Bonus ID
    }

    msg->getU8(); // max unlockable "dragons" for free accounts
    // TODO: implement daily reward usage
}

void ProtocolGame::parseRewardHistory(const InputMessagePtr& msg)
{
    const uint8_t historyCount = msg->getU8(); // history count

    for (auto i = 0; i < historyCount; ++i) {
        msg->getU32(); // timestamp
        msg->getU8(); // is Premium
        msg->getString(); // description
        msg->getU16(); // daystreak
    }

    // TODO: implement reward history usage
}

void ProtocolGame::parsePreyFreeRerolls(const InputMessagePtr& msg)
{
    const uint8_t slot = msg->getU8();
    const uint16_t timeLeft = msg->getU16();

    g_lua.callGlobalField("g_game", "onPreyFreeRerolls", slot, timeLeft);
}

void ProtocolGame::parsePreyTimeLeft(const InputMessagePtr& msg)
{
    const uint8_t slot = msg->getU8();
    const uint16_t timeLeft = msg->getU16();

    g_lua.callGlobalField("g_game", "onPreyTimeLeft", slot, timeLeft);
}

PreyMonster ProtocolGame::getPreyMonster(const InputMessagePtr& msg) const
{
    const auto& name = msg->getString();
    const auto& outfit = getOutfit(msg, false);
    return { name , outfit };
}

std::vector<PreyMonster> ProtocolGame::getPreyMonsters(const InputMessagePtr& msg)
{
    std::vector<PreyMonster> monsters;
    const uint8_t monstersSize = msg->getU8(); // monster list size
    for (auto i = 0; i < monstersSize; ++i)
        monsters.emplace_back(getPreyMonster(msg));

    return monsters;
}

void ProtocolGame::parsePreyData(const InputMessagePtr& msg)
{
    const uint8_t slot = msg->getU8(); // slot
    const auto state = static_cast<Otc::PreyState_t>(msg->getU8()); // slot state

    uint32_t nextFreeReroll = 0; // next free roll
    uint8_t wildcards = 0; // wildcards

    switch (state) {
        case Otc::PREY_STATE_LOCKED:
        {
            const Otc::PreyUnlockState_t unlockState = static_cast<Otc::PreyUnlockState_t>(msg->getU8()); // prey slot unlocked
            if (g_game.getClientVersion() > 1149) { // correct unconfirmed version
                nextFreeReroll = msg->getU32();
                wildcards = msg->getU8();
            } else {
                nextFreeReroll = msg->getU16();
            }
            return g_lua.callGlobalField("g_game", "onPreyLocked", slot, unlockState, nextFreeReroll, wildcards);
        }
        case Otc::PREY_STATE_INACTIVE:
        {
            if (g_game.getClientVersion() > 1149) { // correct unconfirmed version
                nextFreeReroll = msg->getU32();
                wildcards = msg->getU8();
            } else {
                nextFreeReroll = msg->getU16();
            }
            return g_lua.callGlobalField("g_game", "onPreyInactive", slot, nextFreeReroll, wildcards);
        }
        case Otc::PREY_STATE_ACTIVE:
        {
            PreyMonster monster = getPreyMonster(msg);
            const uint8_t bonusType = msg->getU8(); // bonus type
            const uint16_t bonusValue = msg->getU16(); // bonus value
            const uint8_t bonusGrade = msg->getU8(); // bonus grade
            const uint16_t timeLeft = msg->getU16(); // time left
            if (g_game.getClientVersion() > 1149) { // correct unconfirmed version
                nextFreeReroll = msg->getU32();
                wildcards = msg->getU8();
            } else {
                nextFreeReroll = msg->getU16();
            }
            return g_lua.callGlobalField("g_game", "onPreyActive", slot, monster.name, monster.outfit, bonusType, bonusValue, bonusGrade, timeLeft, nextFreeReroll, wildcards);
        }
        case Otc::PREY_STATE_SELECTION:
        {
            std::vector<PreyMonster> monsters = getPreyMonsters(msg);
            std::vector<std::string> names;
            std::vector<Outfit> outfits;
            for (const auto& monster : monsters) {
                names.push_back(monster.name);
                outfits.push_back(monster.outfit);
            }

            if (g_game.getClientVersion() > 1149) { // correct unconfirmed version
                nextFreeReroll = msg->getU32();
                wildcards = msg->getU8();
            } else {
                nextFreeReroll = msg->getU16();
            }
            return g_lua.callGlobalField("g_game", "onPreySelection", slot, names, outfits, nextFreeReroll, wildcards);
        }
        case Otc::PREY_STATE_SELECTION_CHANGE_MONSTER:
        {
            const uint8_t bonusType = msg->getU8(); // bonus type
            const uint16_t bonusValue = msg->getU16(); // bonus value
            const uint8_t bonusGrade = msg->getU8(); // bonus grade
            std::vector<PreyMonster> monsters = getPreyMonsters(msg);
            std::vector<std::string> names;
            std::vector<Outfit> outfits;
            for (const auto& monster : monsters) {
                names.push_back(monster.name);
                outfits.push_back(monster.outfit);
            }

            if (g_game.getClientVersion() > 1149) { // correct unconfirmed version
                nextFreeReroll = msg->getU32();
                wildcards = msg->getU8();
            } else {
                nextFreeReroll = msg->getU16();
            }
            return g_lua.callGlobalField("g_game", "onPreySelectionChangeMonster", slot, names, outfits, bonusType, bonusValue, bonusGrade, nextFreeReroll, wildcards);
        }
        case Otc::PREY_STATE_LIST_SELECTION:
        {
            std::vector<uint16_t> races;
            const uint16_t creatures = msg->getU16();
            for (auto i = 0; i < creatures; ++i) {
                races.push_back(msg->getU16()); // RaceID
            }

            if (g_game.getClientVersion() > 1149) { // correct unconfirmed version
                nextFreeReroll = msg->getU32();
                wildcards = msg->getU8();
            } else {
                nextFreeReroll = msg->getU16();
            }
            return g_lua.callGlobalField("g_game", "onPreyListSelection", slot, races, nextFreeReroll, wildcards);
        }
        case Otc::PREY_STATE_WILDCARD_SELECTION:
        {
            msg->getU8(); // bonus type
            msg->getU16(); // bonus value
            msg->getU8(); // bonus grade

            std::vector<uint16_t> races;
            const uint16_t creatures = msg->getU16();
            for (auto i = 0; i < creatures; ++i) {
                races.push_back(msg->getU16()); // RaceID
            }

            if (g_game.getClientVersion() > 1149) { // correct unconfirmed version
                nextFreeReroll = msg->getU32();
                wildcards = msg->getU8();
            } else {
                nextFreeReroll = msg->getU16();
            }
            return g_lua.callGlobalField("g_game", "onPreyWildcardSelection", slot, races, nextFreeReroll, wildcards);
        }
    }
}

void ProtocolGame::parsePreyRerollPrice(const InputMessagePtr& msg)
{
    const uint32_t price = msg->getU32(); // prey reroll price
    uint8_t wildcard = 0; // prey bonus reroll price
    uint8_t directly = 0; // prey selection list price

    if (g_game.getProtocolVersion() >= 1230) {
        wildcard = msg->getU8();
        directly = msg->getU8();
        msg->getU32(); // task hunting reroll price
        msg->getU32(); // task hunting reroll price
        msg->getU8(); // task hunting selection list price
        msg->getU8(); // task hunting bonus reroll price
    }

    g_lua.callGlobalField("g_game", "onPreyRerollPrice", price, wildcard, directly);
}

Imbuement ProtocolGame::getImbuementInfo(const InputMessagePtr& msg)
{
    Imbuement imbuement;
    imbuement.id = msg->getU32(); // imbuid
    imbuement.name = msg->getString(); // name
    imbuement.description = msg->getString(); // description
    imbuement.group = msg->getString(); // subgroup

    imbuement.imageId = msg->getU16(); // iconId
    imbuement.duration = msg->getU32(); // duration

    imbuement.premiumOnly = msg->getU8(); // is premium

    const uint8_t itemsSize = msg->getU8(); // items size
    for (auto i = 0; i < itemsSize; ++i) {
        const uint16_t id = msg->getU16(); // item client ID
        const auto& description = msg->getString(); // item name
        const uint16_t count = msg->getU16(); // count
        const ItemPtr& item = Item::create(id);
        item->setCount(count);
        imbuement.sources.emplace_back(item, description);
    }

    imbuement.cost = msg->getU32(); // base price
    imbuement.successRate = msg->getU8(); // base percent
    imbuement.protectionCost = msg->getU32(); // base protection
    return imbuement;
}

void ProtocolGame::parseImbuementWindow(const InputMessagePtr& msg)
{
    const uint16_t itemId = msg->getU16(); // item client ID
    const ItemPtr& item = Item::create(itemId);
    if (item->getId() == 0)
        throw Exception("unable to create item with invalid id %d", itemId);

    if (item->getClassification() > 0) {
        msg->getU8();  // upgradeClass
    }

    const uint8_t slot = msg->getU8(); // slot id
    std::unordered_map<int, std::tuple<Imbuement, int, int>> activeSlots;
    for (auto j = 0; j < slot; j++) {
        const uint8_t firstByte = msg->getU8();
        if (firstByte == 0x01) {
            Imbuement imbuement = getImbuementInfo(msg);
            const uint32_t duration = msg->getU32(); // duration
            const uint32_t removalCost = msg->getU32(); // removecost
            activeSlots[j] = std::make_tuple(imbuement, duration, removalCost);
        }
    }

    const uint16_t imbSize = msg->getU16(); // imbuement size
    std::vector<Imbuement> imbuements;
    for (auto i = 0; i < imbSize; ++i) {
        imbuements.push_back(getImbuementInfo(msg));
    }

    const uint32_t neededItemsSize = msg->getU32(); // needed items size
    std::vector<ItemPtr> needItems;
    for (uint32_t i = 0; i < neededItemsSize; ++i) {
        const uint16_t needItemId = msg->getU16();
        const uint16_t count = msg->getU16();
        const auto& needItem = Item::create(needItemId);
        needItem->setCount(count);
        needItems.push_back(needItem);
    }

    g_lua.callGlobalField("g_game", "onImbuementWindow", itemId, slot, activeSlots, imbuements, needItems);
}

void ProtocolGame::parseCloseImbuementWindow(const InputMessagePtr& /*msg*/)
{
    g_lua.callGlobalField("g_game", "onCloseImbuementWindow");
}

void ProtocolGame::parseError(const InputMessagePtr& msg)
{
    msg->getU8(); // error code
    msg->getString(); // error

    // TODO: implement error usage
}

void ProtocolGame::parseMarketEnter(const InputMessagePtr& msg)
{
    const uint8_t offers = msg->getU8();
    std::vector<std::vector<uint16_t>> depotItems;
    const uint16_t itemsSent = msg->getU16();
    for (auto i = 0; i < itemsSent; ++i) {
        const uint16_t itemId = msg->getU16();
        const ItemPtr& item = Item::create(itemId);
        const uint16_t classification = item->getClassification();

        uint8_t itemClass = 0;
        if (classification > 0) {
            itemClass = msg->getU8();
        }

        const uint16_t count = msg->getU16();
        depotItems.push_back({ itemId, count, itemClass });
    }

    g_lua.callGlobalField("g_game", "onMarketEnter", depotItems, offers, -1, -1);
}

void ProtocolGame::parseMarketEnterOld(const InputMessagePtr& msg)
{
    const uint64_t balance = g_game.getClientVersion() >= 981 ? msg->getU64() : msg->getU32();
    const uint8_t vocation = g_game.getClientVersion() < 950 ? msg->getU8() : g_game.getLocalPlayer()->getVocation();

    const uint8_t offers = msg->getU8();
    const uint16_t itemsSent = msg->getU16();

    std::unordered_map<uint16_t, uint16_t> depotItems;
    for (auto i = 0; i < itemsSent; ++i) {
        const uint16_t itemId = msg->getU16();
        const uint16_t count = msg->getU16();
        depotItems.emplace(itemId, count);
    }

    g_lua.callGlobalField("g_game", "onMarketEnter", depotItems, offers, balance, vocation);
}

void ProtocolGame::parseMarketDetail(const InputMessagePtr& msg)
{
    const uint16_t itemId = msg->getU16();
    if (g_game.getClientVersion() >= 1281) {
        const ItemPtr& item = Item::create(itemId);
        if (item && item->getClassification() > 0) {
            msg->getU8();  // ?
        }
    }

    std::unordered_map<int, std::string> descriptions;
    Otc::MarketItemDescription lastAttribute = Otc::ITEM_DESC_WEIGHT;
    if (g_game.getClientVersion() >= 1200)
        lastAttribute = Otc::ITEM_DESC_IMBUINGSLOTS;
    if (g_game.getClientVersion() >= 1270)
        lastAttribute = Otc::ITEM_DESC_UPGRADECLASS;
    if (g_game.getClientVersion() >= 1282)
        lastAttribute = Otc::ITEM_DESC_LAST;

    for (int_fast32_t i = Otc::ITEM_DESC_FIRST; i <= lastAttribute; i++) {
        if (i == Otc::ITEM_DESC_AUGMENT && !g_game.getFeature(Otc::GameItemAugment)) {
            continue;
        }

        if (msg->peekU16() != 0x00) {
            const auto& sentString = msg->getString();
            descriptions.try_emplace(i, sentString);
        } else {
            msg->getU16();
        }
    }

    const uint32_t timeThing = (time(nullptr) / 1000) * 86400;

    std::vector<std::vector<uint64_t>> purchaseStats;
    uint8_t count = msg->getU8();
    for (auto i = -1; ++i < count;) {
        uint32_t transactions = msg->getU32();
        uint64_t totalPrice = 0;
        uint64_t highestPrice = 0;
        uint64_t lowestPrice = 0;
        if (g_game.getClientVersion() >= 1281) {
            totalPrice = msg->getU64();
            highestPrice = msg->getU64();
            lowestPrice = msg->getU64();
        } else {
            totalPrice = msg->getU32();
            highestPrice = msg->getU32();
            lowestPrice = msg->getU32();
        }

        const uint32_t tmp = timeThing - 86400;
        purchaseStats.push_back({ tmp, Otc::MARKETACTION_BUY, transactions, totalPrice, highestPrice, lowestPrice });
    }

    std::vector<std::vector<uint64_t>> saleStats;

    count = msg->getU8();
    for (auto i = -1; ++i < count;) {
        uint32_t transactions = msg->getU32();
        uint64_t totalPrice = 0;
        uint64_t highestPrice = 0;
        uint64_t lowestPrice = 0;
        if (g_game.getClientVersion() >= 1281) {
            totalPrice = msg->getU64();
            highestPrice = msg->getU64();
            lowestPrice = msg->getU64();
        } else {
            totalPrice = msg->getU32();
            highestPrice = msg->getU32();
            lowestPrice = msg->getU32();
        }

        const uint32_t tmp = timeThing - 86400;
        saleStats.push_back({ tmp, Otc::MARKETACTION_SELL, transactions, totalPrice, highestPrice, lowestPrice });
    }

    g_lua.callGlobalField("g_game", "onMarketDetail", itemId, descriptions, purchaseStats, saleStats);
}

MarketOffer ProtocolGame::readMarketOffer(const InputMessagePtr& msg, uint8_t action, uint16_t var)
{
    const uint32_t timestamp = msg->getU32();
    const uint16_t counter = msg->getU16();
    uint16_t itemId = 0;
    if (var == Otc::OLD_MARKETREQUEST_MY_OFFERS || var == Otc::MARKETREQUEST_OWN_OFFERS || var == Otc::OLD_MARKETREQUEST_MY_HISTORY || var == Otc::MARKETREQUEST_OWN_HISTORY) {
        itemId = msg->getU16();
        if (g_game.getClientVersion() >= 1281) {
            const ItemPtr& item = Item::create(itemId);
            if (item && item->getClassification() > 0) {
                msg->getU8();
            }
        }
    } else {
        itemId = var;
    }

    const uint16_t amount = msg->getU16();
    const uint64_t price = g_game.getClientVersion() >= 1281 ? msg->getU64() : msg->getU32();

    std::string playerName;
    uint8_t state = Otc::OFFER_STATE_ACTIVE;
    if (var == Otc::OLD_MARKETREQUEST_MY_HISTORY || var == Otc::MARKETREQUEST_OWN_HISTORY) {
        state = msg->getU8();
    } else if (var == Otc::OLD_MARKETREQUEST_MY_OFFERS || var == Otc::MARKETREQUEST_OWN_OFFERS) {} else {
        playerName = msg->getString();
    }

    g_lua.callGlobalField("g_game", "onMarketReadOffer", action, amount, counter, itemId, playerName, price, state, timestamp, var);
    return { timestamp, counter, action, itemId, amount, price, playerName, state, var };
}

void ProtocolGame::parseMarketBrowse(const InputMessagePtr& msg)
{
    uint16_t var = 0;
    if (g_game.getClientVersion() >= 1281) {
        var = msg->getU8();
        if (var == 3) {
            var = msg->getU16();
            const ItemPtr& item = Item::create(var);
            if (item && item->getClassification() > 0) {
                msg->getU8();
            }
        }
    } else {
        var = msg->getU16();
    }

    std::vector<MarketOffer> offers;
    const uint32_t buyOfferCount = msg->getU32();
    for (uint32_t i = 0; i < buyOfferCount; ++i) {
        offers.push_back(readMarketOffer(msg, Otc::MARKETACTION_BUY, var));
    }

    const uint32_t sellOfferCount = msg->getU32();
    for (uint32_t i = 0; i < sellOfferCount; ++i) {
        offers.push_back(readMarketOffer(msg, Otc::MARKETACTION_SELL, var));
    }
    std::vector<std::vector<uint64_t>> intOffers;
    std::vector<std::string> nameOffers;

    for (const auto& offer : offers) {
        std::vector<uint64_t> intOffer = { offer.action, offer.amount, offer.counter, offer.itemId, offer.price, offer.state, offer.timestamp, offer.var };
        const auto& playerName = offer.playerName;
        intOffers.push_back(intOffer);
        nameOffers.push_back(playerName);
    }

    g_lua.callGlobalField("g_game", "onMarketBrowse", intOffers, nameOffers);
}

void ProtocolGame::parseBosstiaryEntryChanged(const InputMessagePtr& msg)
{
    msg->getU32(); // bossId
}

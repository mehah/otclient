/*
* Copyright (c) 2010-2024 OTClient <https://github.com/edubart/otclient>
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

#include "attachedeffectmanager.h"
#include "item.h"
#include "localplayer.h"
#include "luavaluecasts_client.h"
#include "map.h"
#include "missile.h"
#include "thingtypemanager.h"
#include "tile.h"
#include <ctime>
#include <framework/core/eventdispatcher.h>

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
            if (callLuaField<bool>("onOpcode", opcode, msg)) {
                continue;
            }
            msg->setReadPos(readPos);
            // restore read pos

            switch (opcode) {
                case Proto::GameServerLoginOrPendingState:
                    if (g_game.getFeature(Otc::GameLoginPending)) {
                        parsePendingGame(msg);
                    } else {
                        parseLogin(msg);
                    }
                    break;
                case Proto::GameServerGMActions:
                    parseGMActions(msg);
                    break;
                case Proto::GameServerEnterGame:
                    parseEnterGame(msg);
                    break;
                case Proto::GameServerUpdateNeeded:
                    parseUpdateNeeded(msg);
                    break;
                case Proto::GameServerLoginError:
                    parseLoginError(msg);
                    break;
                case Proto::GameServerLoginAdvice:
                    parseLoginAdvice(msg);
                    break;
                case Proto::GameServerLoginWait:
                    parseLoginWait(msg);
                    break;
                case Proto::GameServerLoginSuccess:
                    parseLogin(msg);
                    break;
                case Proto::GameServerSessionEnd:
                    parseSessionEnd(msg);
                    break;
                case Proto::GameServerStoreButtonIndicators:
                    parseStoreButtonIndicators(msg);
                    break;
                case Proto::GameServerBugReport:
                    parseBugReport(msg);
                    break;
                case Proto::GameServerPingBack:
                case Proto::GameServerPing:
                    if (((opcode == Proto::GameServerPing) && (g_game.getFeature(Otc::GameClientPing))) ||
                        ((opcode == Proto::GameServerPingBack) && !g_game.getFeature(Otc::GameClientPing))) {
                        parsePingBack(msg);
                    } else {
                        parsePing(msg);
                    }
                    break;
                case Proto::GameServerChallenge:
                    parseLoginChallenge(msg);
                    break;
                case Proto::GameServerDeath:
                    parseDeath(msg);
                    break;
                case Proto::GameServerSupplyStash:
                    parseSupplyStash(msg);
                    break;
                case Proto::GameServerSpecialContainer:
                    parseSpecialContainer(msg);
                    break;
                case Proto::GameServerPartyAnalyzer:
                    parsePartyAnalyzer(msg);
                    break;
                case Proto::GameServerExtendedOpcode: // otclient only
                    parseExtendedOpcode(msg);
                    break;
                case Proto::GameServerChangeMapAwareRange:
                    parseChangeMapAwareRange(msg);
                    break;
                case Proto::GameServerAttchedEffect:
                    parseAttachedEffect(msg);
                    break;
                case Proto::GameServerDetachEffect:
                    parseDetachEffect(msg);
                    break;
                case Proto::GameServerCreatureShader:
                    parseCreatureShader(msg);
                    break;
                case Proto::GameServerMapShader:
                    parseMapShader(msg);
                    break;
                case Proto::GameServerCreatureTyping:
                    parseCreatureTyping(msg);
                    break;
                case Proto::GameServerFeatures:
                    parseFeatures(msg);
                    break;
                case Proto::GameServerFloorDescription:
                    parseFloorDescription(msg);
                    break;
                case Proto::GameServerImbuementDurations:
                    parseImbuementDurations(msg);
                    break;
                case Proto::GameServerPassiveCooldown:
                    parsePassiveCooldown(msg);
                    break;
                case Proto::GameServerBosstiaryData:
                    parseBosstiaryData(msg);
                    break;
                case Proto::GameServerBosstiarySlots:
                    parseBosstiarySlots(msg);
                    break;
                case Proto::GameServerSendClientCheck:
                    parseClientCheck(msg);
                    break;
                case Proto::GameServerFullMap:
                    parseMapDescription(msg);
                    break;
                case Proto::GameServerMapTopRow:
                    parseMapMoveNorth(msg);
                    break;
                case Proto::GameServerMapRightRow:
                    parseMapMoveEast(msg);
                    break;
                case Proto::GameServerMapBottomRow:
                    parseMapMoveSouth(msg);
                    break;
                case Proto::GameServerMapLeftRow:
                    parseMapMoveWest(msg);
                    break;
                case Proto::GameServerUpdateTile:
                    parseUpdateTile(msg);
                    break;
                case Proto::GameServerCreateOnMap:
                    parseTileAddThing(msg);
                    break;
                case Proto::GameServerChangeOnMap:
                    parseTileTransformThing(msg);
                    break;
                case Proto::GameServerDeleteOnMap:
                    parseTileRemoveThing(msg);
                    break;
                case Proto::GameServerMoveCreature:
                    parseCreatureMove(msg);
                    break;
                case Proto::GameServerOpenContainer:
                    parseOpenContainer(msg);
                    break;
                case Proto::GameServerCloseContainer:
                    parseCloseContainer(msg);
                    break;
                case Proto::GameServerCreateContainer:
                    parseContainerAddItem(msg);
                    break;
                case Proto::GameServerChangeInContainer:
                    parseContainerUpdateItem(msg);
                    break;
                case Proto::GameServerDeleteInContainer:
                    parseContainerRemoveItem(msg);
                    break;
                case Proto::GameServerBosstiaryInfo:
                    parseBosstiaryInfo(msg);
                    break;
                case Proto::GameServerTakeScreenshot:
                    parseTakeScreenshot(msg);
                    break;
                case Proto::GameServerCyclopediaItemDetail:
                    parseCyclopediaItemDetail(msg);
                    break;
                case Proto::GameServerSetInventory:
                    parseAddInventoryItem(msg);
                    break;
                case Proto::GameServerDeleteInventory:
                    parseRemoveInventoryItem(msg);
                    break;
                case Proto::GameServerOpenNpcTrade:
                    parseOpenNpcTrade(msg);
                    break;
                case Proto::GameServerPlayerGoods:
                    parsePlayerGoods(msg);
                    break;
                case Proto::GameServerCloseNpcTrade:
                    parseCloseNpcTrade(msg);
                    break;
                case Proto::GameServerOwnTrade:
                    parseOwnTrade(msg);
                    break;
                case Proto::GameServerCounterTrade:
                    parseCounterTrade(msg);
                    break;
                case Proto::GameServerCloseTrade:
                    parseCloseTrade(msg);
                    break;
                case Proto::GameServerAmbient:
                    parseWorldLight(msg);
                    break;
                case Proto::GameServerGraphicalEffect:
                    parseMagicEffect(msg);
                    break;
                case Proto::GameServerTextEffect:
                    if (g_game.getClientVersion() >= 1320) {
                        parseRemoveMagicEffect(msg);
                    } else {
                        parseAnimatedText(msg);
                    }
                    break;
                case Proto::GameServerMissleEffect:
                    if (g_game.getFeature(Otc::GameAnthem)) {
                        parseAnthem(msg);
                    } else {
                        parseDistanceMissile(msg);
                    }
                    break;
                case Proto::GameServerItemClasses:
                    if (g_game.getClientVersion() >= 1281) {
                        parseItemClasses(msg);
                    } else {
                        parseCreatureMark(msg);
                    }
                    break;
                case Proto::GameServerTrappers:
                    parseTrappers(msg);
                    break;
                case Proto::GameServerCloseForgeWindow:
                    parseCloseForgeWindow(msg);
                    break;
                case Proto::GameServerCreatureData:
                    parseCreatureData(msg);
                    break;
                case Proto::GameServerCreatureHealth:
                    parseCreatureHealth(msg);
                    break;
                case Proto::GameServerCreatureLight:
                    parseCreatureLight(msg);
                    break;
                case Proto::GameServerCreatureOutfit:
                    parseCreatureOutfit(msg);
                    break;
                case Proto::GameServerCreatureSpeed:
                    parseCreatureSpeed(msg);
                    break;
                case Proto::GameServerCreatureSkull:
                    parseCreatureSkulls(msg);
                    break;
                case Proto::GameServerCreatureParty:
                    parseCreatureShields(msg);
                    break;
                case Proto::GameServerCreatureUnpass:
                    parseCreatureUnpass(msg);
                    break;
                case Proto::GameServerCreatureMarks:
                    parseCreaturesMark(msg);
                    break;
                case Proto::GameServerPlayerHelpers:
                    parsePlayerHelpers(msg);
                    break;
                case Proto::GameServerCreatureType:
                    parseCreatureType(msg);
                    break;
                case Proto::GameServerEditText:
                    parseEditText(msg);
                    break;
                case Proto::GameServerEditList:
                    parseEditList(msg);
                    break;
                case Proto::GameServerSendGameNews:
                    parseGameNews(msg);
                    break;
                case Proto::GameServerSendBlessDialog:
                    parseBlessDialog(msg);
                    break;
                case Proto::GameServerBlessings:
                    parseBlessings(msg);
                    break;
                case Proto::GameServerPreset:
                    parsePreset(msg);
                    break;
                case Proto::GameServerPremiumTrigger:
                    parsePremiumTrigger(msg);
                    break;
                case Proto::GameServerPlayerDataBasic:
                    parsePlayerInfo(msg);
                    break;
                case Proto::GameServerPlayerData:
                    parsePlayerStats(msg);
                    break;
                case Proto::GameServerPlayerSkills:
                    parsePlayerSkills(msg);
                    break;
                case Proto::GameServerPlayerState:
                    parsePlayerState(msg);
                    break;
                case Proto::GameServerClearTarget:
                    parsePlayerCancelAttack(msg);
                    break;
                case Proto::GameServerSpellDelay:
                    parseSpellCooldown(msg);
                    break;
                case Proto::GameServerSpellGroupDelay:
                    parseSpellGroupCooldown(msg);
                    break;
                case Proto::GameServerMultiUseDelay:
                    parseMultiUseCooldown(msg);
                    break;
                case Proto::GameServerPlayerModes:
                    parsePlayerModes(msg);
                    break;
                case Proto::GameServerSetStoreDeepLink:
                    parseSetStoreDeepLink(msg);
                    break;
                case Proto::GameServerSendRestingAreaState:
                    parseRestingAreaState(msg);
                    break;
                case Proto::GameServerTalk:
                    parseTalk(msg);
                    break;
                case Proto::GameServerChannels:
                    parseChannelList(msg);
                    break;
                case Proto::GameServerOpenChannel:
                    parseOpenChannel(msg);
                    break;
                case Proto::GameServerOpenPrivateChannel:
                    parseOpenPrivateChannel(msg);
                    break;
                case Proto::GameServerRuleViolationChannel:
                    parseRuleViolationChannel(msg);
                    break;
                case Proto::GameServerRuleViolationRemove:
                    if (g_game.getClientVersion() >= 1200) {
                        parseExperienceTracker(msg);
                    } else {
                        parseRuleViolationRemove(msg);
                    }
                    break;
                case Proto::GameServerRuleViolationCancel:
                    parseRuleViolationCancel(msg);
                    break;
                case Proto::GameServerRuleViolationLock:
                    if (g_game.getClientVersion() >= 1310) {
                        parseHighscores(msg);
                    } else {
                        parseRuleViolationLock(msg);
                    }
                    break;
                case Proto::GameServerOpenOwnChannel:
                    parseOpenOwnPrivateChannel(msg);
                    break;
                case Proto::GameServerCloseChannel:
                    parseCloseChannel(msg);
                    break;
                case Proto::GameServerTextMessage:
                    parseTextMessage(msg);
                    break;
                case Proto::GameServerCancelWalk:
                    parseCancelWalk(msg);
                    break;
                case Proto::GameServerWalkWait:
                    parseWalkWait(msg);
                    break;
                case Proto::GameServerUnjustifiedStats:
                    parseUnjustifiedStats(msg);
                    break;
                case Proto::GameServerPvpSituations:
                    parsePvpSituations(msg);
                    break;
                case Proto::GameServerBestiaryRefreshTracker:
                    parseBestiaryTracker(msg);
                    break;
                case Proto::GameServerTaskHuntingBasicData:
                    parseTaskHuntingBasicData(msg);
                    break;
                case Proto::GameServerTaskHuntingData:
                    parseTaskHuntingData(msg);
                    break;
                case Proto::GameServerBosstiaryCooldownTimer:
                    parseBosstiaryCooldownTimer(msg);
                    break;
                case Proto::GameServerFloorChangeUp:
                    parseFloorChangeUp(msg);
                    break;
                case Proto::GameServerFloorChangeDown:
                    parseFloorChangeDown(msg);
                    break;
                case Proto::GameServerLootContainers:
                    parseLootContainers(msg);
                    break;
                case Proto::GameServerCyclopediaHouseAuctionMessage:
                    parseCyclopediaHouseAuctionMessage(msg);
                    break;
                case Proto::GameServerCyclopediaHousesInfo:
                    parseCyclopediaHousesInfo(msg);
                    break;
                case Proto::GameServerCyclopediaHouseList:
                    parseCyclopediaHouseList(msg);
                    break;
                case Proto::GameServerChooseOutfit:
                    parseOpenOutfitWindow(msg);
                    break;
                case Proto::GameServerSendUpdateImpactTracker:
                    parseUpdateImpactTracker(msg);
                    break;
                case Proto::GameServerSendItemsPrice:
                    parseItemsPrice(msg);
                    break;
                case Proto::GameServerSendUpdateSupplyTracker:
                    parseUpdateSupplyTracker(msg);
                    break;
                case Proto::GameServerSendUpdateLootTracker:
                    parseUpdateLootTracker(msg);
                    break;
                case Proto::GameServerQuestTracker:
                    parseQuestTracker(msg);
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
                case Proto::GameServerBestiaryRaces:
                    parseBestiaryRaces(msg);
                    break;
                case Proto::GameServerBestiaryOverview:
                    parseBestiaryOverview(msg);
                    break;
                case Proto::GameServerBestiaryMonsterData:
                    parseBestiaryMonsterData(msg);
                    break;
                case Proto::GameServerBestiaryCharmsData:
                    parseBestiaryCharmsData(msg);
                    break;
                case Proto::GameServerBestiaryEntryChanged:
                    parseBestiaryEntryChanged(msg);
                    break;
                case Proto::GameServerCyclopediaCharacterInfoData:
                    parseCyclopediaCharacterInfo(msg);
                    break;
                case Proto::GameServerTutorialHint:
                    parseTutorialHint(msg);
                    break;
                case Proto::GameServerAutomapFlag:
                    parseAutomapFlag(msg);
                    break;
                case Proto::GameServerSendDailyRewardCollectionState:
                    parseDailyRewardCollectionState(msg);
                    break;
                case Proto::GameServerCoinBalance:
                    parseCoinBalance(msg);
                    break;
                case Proto::GameServerStoreError:
                    parseStoreError(msg);
                    break;
                case Proto::GameServerRequestPurchaseData:
                    parseRequestPurchaseData(msg);
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
                    if (g_game.getFeature(Otc::GameBosstiary)) {
                        parseBosstiaryEntryChanged(msg);
                    } else {
                        parsePreyFreeRerolls(msg);
                    }
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
                case Proto::GameServerSendShowDescription:
                    parseShowDescription(msg);
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
                case Proto::GameServerResourceBalance:
                    parseResourceBalance(msg);
                    break;
                case Proto::GameServerWorldTime:
                    parseWorldTime(msg);
                    break;
                case Proto::GameServerQuestLog:
                    parseQuestLog(msg);
                    break;
                case Proto::GameServerQuestLine:
                    parseQuestLine(msg);
                    break;
                case Proto::GameServerCoinBalanceUpdating:
                    parseCoinBalanceUpdating(msg);
                    break;
                case Proto::GameServerChannelEvent:
                    parseChannelEvent(msg);
                    break;
                case Proto::GameServerItemInfo:
                    parseItemInfo(msg);
                    break;
                case Proto::GameServerPlayerInventory:
                    parsePlayerInventory(msg);
                    break;
                case Proto::GameServerMarketEnter:
                    if (g_game.getClientVersion() >= 1281) {
                        parseMarketEnter(msg);
                    } else {
                        parseMarketEnterOld(msg);
                    }
                    break;
                case Proto::GameServerMarketDetail:
                    parseMarketDetail(msg);
                    break;
                case Proto::GameServerMarketBrowse:
                    parseMarketBrowse(msg);
                    break;
                case Proto::GameServerModalDialog:
                    parseModalDialog(msg);
                    break;
                case Proto::GameServerStore:
                    parseStore(msg);
                    break;
                case Proto::GameServerStoreOffers:
                    parseStoreOffers(msg);
                    break;
                case Proto::GameServerStoreTransactionHistory:
                    parseStoreTransactionHistory(msg);
                    break;
                case Proto::GameServerStoreCompletePurchase:
                    parseCompleteStorePurchase(msg);
                    break;
                default:
                    throw Exception("unhandled opcode {}", opcode);
            }
            prevOpcode = opcode;
        }
    } catch (const stdext::exception& e) {
        g_logger.error(
            "ProtocolGame parse message exception ({} bytes, {} unread, last opcode is 0x{:02X} ({}), prev opcode is 0x{:02X} ({})): {}\n"
            "Packet has been saved to packet.log, you can use it to find what was wrong. (Protocol: {})",
            msg->getMessageSize(),
            msg->getUnreadSize(),
            opcode, opcode,
            prevOpcode, prevOpcode,
            e.what(),
            g_game.getProtocolVersion()
        );

        std::ofstream packet("packet.log", std::ios::app);
        if (!packet.is_open()) {
            return;
        }

        packet << fmt::format(
            "ProtocolGame parse message exception ({} bytes, {} unread, last opcode is 0x{:02X} ({}), prev opcode is 0x{:02X} ({}), proto: {}): {}\n",
            msg->getMessageSize(),
            msg->getUnreadSize(),
            opcode,
            opcode,
            prevOpcode,
            prevOpcode,
            g_game.getProtocolVersion(),
            e.what()
        );
    }
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

    if (g_game.getClientVersion() >= 1054) {
        msg->getU8(); // can change pvp frame option
    }

    if (g_game.getClientVersion() >= 1058) {
        const uint8_t expertModeEnabled = msg->getU8();
        g_game.setExpertPvpMode(expertModeEnabled);
    }

    if (g_game.getFeature(Otc::GameIngameStore)) {
        // URL to ingame store images
        std::string url = msg->getString();

        // premium coin package size
        // e.g you can only buy packs of 25, 50, 75, .. coins in the market
        const uint16_t coinsPacketSize = msg->getU16();
        g_lua.callGlobalField("g_game", "onStoreInit", url, coinsPacketSize);
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

void ProtocolGame::parseBugReport(const InputMessagePtr& msg)
{
    const bool canReportBugs = msg->getU8() > 0;
    g_game.setCanReportBugs(canReportBugs);
}

void ProtocolGame::parsePendingGame(const InputMessagePtr&)
{
    //set player to pending game state
    g_game.processPendingGame();
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

void ProtocolGame::parseStoreButtonIndicators(const InputMessagePtr& msg)
{
    msg->getU8(); // (bool) IsSaleBannerVisible
    msg->getU8(); // (bool) IsNewBannerVisible
}

void ProtocolGame::parseSetStoreDeepLink(const InputMessagePtr& msg)
{
    msg->getU8(); // currentlyFeaturedServiceType
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

void ProtocolGame::parseRequestPurchaseData(const InputMessagePtr& msg)
{
    msg->getU32(); // transactionId
    msg->getU8(); // productType
}

void ProtocolGame::parseResourceBalance(const InputMessagePtr& msg) const
{
    using enum Otc::ResourceTypes_t;
    const auto type = static_cast<Otc::ResourceTypes_t>(msg->getU8());
    if (type >= RESOURCE_CHARM && type <= RESOURCE_MAX_MINOR_CHARM) {
        const uint32_t value = msg->getU32();
        m_localPlayer->setResourceBalance(type, value);
    } else {
        const uint64_t value = msg->getU64();
        m_localPlayer->setResourceBalance(type, value);
    }
}

void ProtocolGame::parseWorldTime(const InputMessagePtr& msg)
{
    const uint8_t hour = msg->getU8();
    const uint8_t min = msg->getU8();
    g_lua.callGlobalField("g_game", "onChangeWorldTime", hour, min);
}

void ProtocolGame::parseStore(const InputMessagePtr& msg) const
{
    if (g_game.getClientVersion() <= 1100) {
        parseCoinBalance(msg);
    }

    const uint16_t categoryCount = msg->getU16();
    std::vector<StoreCategory> categories;

    for (auto i = 0; i < categoryCount; ++i) {
        StoreCategory category;
        category.name = msg->getString();

        if (g_game.getClientVersion() < 1291) {
            msg->getString();
        }

        if (g_game.getFeature(Otc::GameIngameStoreHighlights)) {
            category.state = msg->getU8();
        } else {
            category.state = 0;
        }

        const uint8_t iconCount = msg->getU8();
        for (auto j = 0; j < iconCount; ++j) {
            category.icons.push_back(msg->getString());
        }

        category.parent = msg->getString();
        categories.push_back(category);
    }

    if (g_game.getClientVersion() >= 1332) {
        msg->getU8();
        msg->getU8();
    }

    std::vector<StoreCategory> organizedCategories;

    for (const auto& category : categories) {
        if (category.parent.empty()) {
            StoreCategory mainCategory = category;
            mainCategory.subCategories.clear();

            for (const auto& subCategory : categories) {
                if (subCategory.parent == category.name) {
                    mainCategory.subCategories.push_back(subCategory);
                }
            }

            organizedCategories.push_back(mainCategory);

            for (const auto& subCategory : mainCategory.subCategories) {
                organizedCategories.push_back(subCategory);
            }
        }
    }

    g_lua.callGlobalField("g_game", "onParseStoreGetCategories", organizedCategories);
}

void ProtocolGame::parseCoinBalance(const InputMessagePtr& msg) const
{
    const bool update = static_cast<bool>(msg->getU8());
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
    if (g_game.getClientVersion() >= 1291) {
        const uint8_t action = msg->getU8();
        if (action == 0) {
            return;
        }

        msg->getU8();
        msg->getU8();
        const uint32_t getTibiaCoins = msg->getU32();
        const uint32_t getTransferableCoins = msg->getU32();
        if (g_game.getClientVersion() >= 1281) {
            msg->getU32(); // Reserved Auction Coins
        }
        if (g_game.getFeature(Otc::GameTournamentPackets)) {
            msg->getU32();
        }
        g_lua.callGlobalField("g_game", "onParseStoreGetCoin", getTibiaCoins, getTransferableCoins);
    } else {
        // coin balance can be updating and might not be accurate
        msg->getU8(); // == 1; // isUpdating
    }
}

void ProtocolGame::parseCompleteStorePurchase(const InputMessagePtr& msg) const
{
    if (g_game.getClientVersion() >= 1291) {
        msg->getU8();
        const auto& purchaseStatus = msg->getString();
        g_lua.callGlobalField("g_game", "onParseStoreGetPurchaseStatus", purchaseStatus);
    } else {
        msg->getU8(); // not used

        const auto& message = msg->getString();
        const uint32_t coins = msg->getU32();
        const uint32_t transferableCoins = msg->getU32();
        g_lua.callGlobalField("g_game", "onParseStoreGetCoin", coins, transferableCoins);
        g_lua.callGlobalField("g_game", "onParseStoreGetPurchaseStatus", message);
    }
}

void ProtocolGame::parseStoreTransactionHistory(const InputMessagePtr& msg) const
{
    uint32_t currentPage;
    uint32_t pageCount;
    if (g_game.getClientVersion() <= 1096) {
        msg->getU16(); // currentPage
        msg->getU8(); // hasNextPage (bool)
    } else {
        currentPage = msg->getU32();
        pageCount = msg->getU32();
    }

    const uint8_t entries = msg->getU8();
    std::vector<std::tuple<uint32_t, uint8_t, int32_t, uint8_t, std::string>> historyData;
    for (auto i = 0; i < entries; ++i) {
        if (g_game.getClientVersion() >= 1291) {
            msg->getU32(); // transactionId
            const uint32_t time = msg->getU32();
            const uint8_t mode = msg->getU8(); //0 = normal, 1 = gift, 2 = refund
            const uint32_t rawAmount = msg->getU32();
            int32_t amount;
            if (rawAmount > INT32_MAX) {
                amount = -static_cast<int32_t>(UINT32_MAX - rawAmount + 1);
            } else {
                amount = static_cast<int32_t>(rawAmount);
            }
            const uint8_t coinType = msg->getU8(); // 0 = transferable tibia coin, 1 = normal tibia coin
            const auto& productName = msg->getString();
            msg->getU8(); //details
            historyData.emplace_back(time, mode, amount, coinType, productName);
        } else {
            const uint32_t time = msg->getU32();
            const uint8_t productType = msg->getU8();
            const uint32_t coinChange = msg->getU32();
            const auto& productName = msg->getString();
            historyData.emplace_back(time, productType, coinChange, 1, productName);
        }
    }

    g_lua.callGlobalField("g_game", "onParseStoreGetHistory", currentPage, pageCount, historyData);
}

void ProtocolGame::parseStoreOffers(const InputMessagePtr& msg)
{
	if (g_game.getClientVersion() >= 1291) {
		StoreData storeData;
		storeData.categoryName = msg->getString();
		storeData.redirectId = msg->getU32();

		msg->getU8(); //  -- sort by 0 - most popular, 1 - alphabetically, 2 - newest
		const uint8_t dropMenuShowAll = msg->getU8();
		for (auto i = 0; i < dropMenuShowAll; ++i) {
            const auto& menu = msg->getString();
            storeData.menuFilter.push_back(menu);
		}
  
        uint16_t stringLength = msg->getU16(); 
        msg->skipBytes(stringLength); // tfs send string , canary send u16

        if (g_game.getClientVersion() >= 1310) {
            const uint16_t disableReasonsSize = msg->getU16();

            for (auto i = 0; i < disableReasonsSize; ++i) {
                const auto& reason = msg->getString();
                storeData.disableReasons.push_back(reason);
            }
        }

		const uint16_t offersCount = msg->getU16();
		if (storeData.categoryName == "Home") {
			for (auto i = 0; i < offersCount; ++i) {
				HomeOffer offer;
				offer.name = msg->getString();
				offer.unknownByte = msg->getU8();
				offer.id = msg->getU32();
				offer.unknownU16 = msg->getU16();
				offer.price = msg->getU32();
				offer.coinType = msg->getU8();

				const uint8_t hasDisabledReason = msg->getU8();
				if (hasDisabledReason == 1) {
					msg->skipBytes(1);
                    if (g_game.getClientVersion() >= 1300) {
                        offer.disabledReasonIndex = msg->getU16();
                    } else{
                        msg->getString();
                    }
				}

				offer.unknownByte2 = msg->getU8();
				offer.type = msg->getU8();

				if (offer.type == Otc::GameStoreInfoType_t::SHOW_NONE) {
					offer.icon = msg->getString();
				} else if (offer.type == Otc::GameStoreInfoType_t::SHOW_MOUNT) {
					offer.mountClientId = msg->getU16();
				} else if (offer.type == Otc::GameStoreInfoType_t::SHOW_ITEM) {
					offer.itemType = msg->getU16();
				} else if (offer.type == Otc::GameStoreInfoType_t::SHOW_OUTFIT) {
					offer.sexId = msg->getU16();
					offer.outfit.lookHead = msg->getU8();
					offer.outfit.lookBody = msg->getU8();
					offer.outfit.lookLegs = msg->getU8();
					offer.outfit.lookFeet = msg->getU8();
				}

				offer.tryOnType = msg->getU8();
				offer.collection = msg->getU16();
				offer.popularityScore = msg->getU16();
				offer.stateNewUntil = msg->getU32();
				offer.userConfiguration = msg->getU8();
				offer.productsCapacity = msg->getU16();

				storeData.homeOffers.push_back(offer);
			}

			const uint8_t bannerCount = msg->getU8();

			for (auto i = 0; i < bannerCount; ++i) {
				Banner banner;
				banner.image = msg->getString();
				banner.bannerType = msg->getU8();
				banner.offerId = msg->getU32();
				banner.unknownByte1 = msg->getU8();
				banner.unknownByte2 = msg->getU8();
				storeData.banners.push_back(banner);
			}

			storeData.bannerDelay = msg->getU8();

			g_lua.callGlobalField("g_game", "onParseStoreCreateHome", storeData);
			return;
		}

		for (auto i = 0; i < offersCount; ++i) {
			StoreOffer offer;
			offer.name = msg->getString();

			const uint8_t subOffersCount = msg->getU8();
			for (auto j = 0; j < subOffersCount; ++j) {
				SubOffer subOffer{};
				subOffer.id = msg->getU32();
				subOffer.count = msg->getU16();
				subOffer.price = msg->getU32();
				subOffer.coinType = msg->getU8();
				subOffer.disabled = msg->getU8() == 1;
				if (subOffer.disabled) {
					const uint8_t reason = msg->getU8();
					for (auto k = 0; k < reason; ++k) {
                        if (g_game.getClientVersion() >= 1300) {
                            subOffer.reasonIdDisable = msg->getU16();
                        } else {
                            msg->getString();
                        }
					}
				}
				subOffer.state = msg->getU8();

				if (subOffer.state == Otc::GameStoreInfoStatesType_t::STATE_SALE) {
					subOffer.validUntil = msg->getU32();
					subOffer.basePrice = msg->getU32();
				}
				offer.subOffers.push_back(subOffer);
			}

			offer.type = msg->getU8();
			if (offer.type == Otc::GameStoreInfoType_t::SHOW_NONE) {
				offer.icon = msg->getString();
			} else if (offer.type == Otc::GameStoreInfoType_t::SHOW_MOUNT) {
				offer.mountId = msg->getU16();
			} else if (offer.type == Otc::GameStoreInfoType_t::SHOW_ITEM) {
				offer.itemId = msg->getU16();
			} else if (offer.type == Otc::GameStoreInfoType_t::SHOW_OUTFIT) {
				offer.outfitId = msg->getU16();
				offer.outfitHead = msg->getU8();
				offer.outfitBody = msg->getU8();
				offer.outfitLegs = msg->getU8();
				offer.outfitFeet = msg->getU8();
			} else if (offer.type == Otc::GameStoreInfoType_t::SHOW_HIRELING) {
				offer.sex = msg->getU8();
				offer.maleOutfitId = msg->getU16();
				offer.femaleOutfitId = msg->getU16();
				offer.outfitHead = msg->getU8();
				offer.outfitBody = msg->getU8();
				offer.outfitLegs = msg->getU8();
				offer.outfitFeet = msg->getU8();
			}

			offer.tryOnType = msg->getU8();

			if (g_game.getClientVersion() <= 1310) {
				auto test = msg->getString();
			} else {
				offer.collection = msg->getU16();
			}

			offer.popularityScore = msg->getU16();
			offer.stateNewUntil = msg->getU32();
			offer.configurable = msg->getU8() == 1;
			offer.productsCapacity = msg->getU16();
            for (auto j = 0; j < offer.productsCapacity; ++j) {
                msg->getString();
                msg->getU8(); // info in description?
                msg->getU16();
            }
			storeData.storeOffers.push_back(offer);
		}

		if (storeData.categoryName == "Search") {
			storeData.tooManyResults = msg->getU8() == 1;
		}

		g_lua.callGlobalField("g_game", "onParseStoreCreateProducts", storeData);
	} else {
		StoreData storeData;
		storeData.categoryName = msg->getString(); // categoryName

		const uint16_t offersCount = msg->getU16();
		for (auto i = 0; i < offersCount; ++i) {
			StoreOffer offer;
			offer.id = msg->getU32(); // offerId
			offer.name = msg->getString(); // offerName
			offer.description = msg->getString(); // offerDescription
			offer.price = msg->getU32(); // price

			const uint8_t highlightState = msg->getU8();
			if (highlightState == 2 && g_game.getFeature(Otc::GameIngameStoreHighlights) && g_game.getClientVersion() >= 1097) {
				offer.state = Otc::GameStoreInfoStatesType_t::STATE_SALE;
				offer.stateNewUntil = msg->getU32(); // saleValidUntilTimestamp
				offer.basePrice = msg->getU32(); // basePrice
			} else {
				offer.state = highlightState;
			}

            offer.disabled = msg->getU8() == 1;
            if (g_game.getFeature(Otc::GameIngameStoreHighlights) && offer.disabled) {
                offer.reasonIdDisable = msg->getString(); // disabledReason
            }

			const uint8_t iconCount = msg->getU8();
			for (auto j = 0; j < iconCount; ++j) {
				offer.icon = msg->getString(); // icon
			}

			const uint16_t subOffersCount = msg->getU16();

			for (auto j = 0; j < subOffersCount; ++j) {
				SubOffer subOffer;
				subOffer.name = msg->getString(); // name
				subOffer.description = msg->getString(); // description

				const uint8_t subIconsCount = msg->getU8();
				for (auto k = 0; k < subIconsCount; ++k) {
					subOffer.icons.push_back(msg->getString()); // icon
				}
				subOffer.parent = msg->getString(); // serviceType
				offer.subOffers.push_back(subOffer);
			}

			storeData.storeOffers.push_back(offer);
		}

		g_lua.callGlobalField("g_game", "onParseStoreCreateProducts", storeData);
	}
}

void ProtocolGame::parseStoreError(const InputMessagePtr& msg) const
{
    const uint8_t errorType = msg->getU8();
    const auto& message = msg->getString();

    g_lua.callGlobalField("g_game", "onParseStoreError", message, errorType);
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

    g_game.setUnjustifiedPoints({ .killsDay = killsDay, .killsDayRemaining = killsDayRemaining, .killsWeek = killsWeek, .killsWeekRemaining =
        killsWeekRemaining,
        .killsMonth = killsMonth, .killsMonthRemaining = killsMonthRemaining, .skullTime = skullTime
    });
}

void ProtocolGame::parsePvpSituations(const InputMessagePtr& msg)
{
    const uint8_t openPvpSituations = msg->getU8();
    g_game.setOpenPvpSituations(openPvpSituations);
}

void ProtocolGame::parsePlayerHelpers(const InputMessagePtr& msg) const
{
    const uint32_t creatureId = msg->getU32();
    const uint16_t helpers = msg->getU16();

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError("ProtocolGame::parsePlayerHelpers: could not get creature with id {}", creatureId);
        return;
    }

    g_game.processPlayerHelpers(helpers);
}

void ProtocolGame::parseGMActions(const InputMessagePtr& msg)
{
    uint8_t numViolationReasons;
    if (g_game.getClientVersion() >= 850) {
        numViolationReasons = 20;
    } else if (g_game.getClientVersion() >= 840) {
        numViolationReasons = 23;
    } else {
        numViolationReasons = 32;
    }

    std::vector<uint8_t> actions;

    for (auto i = 0; i < numViolationReasons; ++i) {
        actions.push_back(msg->getU8());
    }

    g_game.processGMActions(actions);
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

void ProtocolGame::parsePing(const InputMessagePtr&) { g_game.processPing(); }
void ProtocolGame::parsePingBack(const InputMessagePtr&) { g_game.processPingBack(); }

void ProtocolGame::parseLoginChallenge(const InputMessagePtr& msg)
{
    const uint32_t timestamp = msg->getU32();
    const uint8_t random = msg->getU8();

    if (g_game.getClientVersion() >= 1405) {
        msg->skipBytes(1);
    }

    sendLoginPacket(timestamp, random);
}

void ProtocolGame::parseDeath(const InputMessagePtr& msg)
{
    uint8_t penality = 100;
    uint8_t deathType = Otc::DeathRegular;

    if (g_game.getFeature(Otc::GameDeathType)) {
        deathType = msg->getU8();
    }

    if (g_game.getFeature(Otc::GamePenalityOnDeath) && deathType == Otc::DeathRegular) {
        penality = msg->getU8();
    }

    if (g_game.getClientVersion() >= 1281) {
        msg->getU8(); // (bool) can use death redemption
    }

    g_game.processDeath(deathType, penality);
}

void ProtocolGame::parseFloorDescription(const InputMessagePtr& msg)
{
    const auto& pos = getPosition(msg);
    const uint8_t floor = msg->getU8();

    if (pos.z == floor) {
        const auto& oldPos = m_localPlayer->getPosition();
        if (!m_mapKnown) {
            m_localPlayer->setPosition(pos);
        }

        g_map.setCentralPosition(pos);

        if (!m_mapKnown) {
            g_dispatcher.addEvent([] { g_lua.callGlobalField("g_game", "onMapKnown"); });
            m_mapKnown = true;
        }

        g_dispatcher.addEvent([] { g_lua.callGlobalField("g_game", "onMapDescription"); });
        g_lua.callGlobalField("g_game", "onTeleport", m_localPlayer, pos, oldPos);
    }

    const auto& range = g_map.getAwareRange();
    setFloorDescription(msg, pos.x - range.left, pos.y - range.top, floor, range.horizontal(), range.vertical(), pos.z - floor, 0);

    g_game.updateMapLatency();
}

void ProtocolGame::parseMapDescription(const InputMessagePtr& msg)
{
    const auto& pos = getPosition(msg);
    const auto& oldPos = m_localPlayer->getPosition();

    if (!m_mapKnown) {
        m_localPlayer->setPosition(pos);
    }

    g_map.setCentralPosition(pos);

    const auto& range = g_map.getAwareRange();
    setMapDescription(msg, pos.x - range.left, pos.y - range.top, pos.z, range.horizontal(), range.vertical());

    if (!m_mapKnown) {
        g_dispatcher.addEvent([] { g_lua.callGlobalField("g_game", "onMapKnown"); });
        m_mapKnown = true;
    }

    g_dispatcher.addEvent([] { g_lua.callGlobalField("g_game", "onMapDescription"); });
    g_lua.callGlobalField("g_game", "onTeleport", m_localPlayer, pos, oldPos);
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
    const int stackPos = g_game.getClientVersion() >= 841 ? msg->getU8() : -1;
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

    const auto& pos = thing->getServerPosition();
    const int stackPos = thing->getStackPos();

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
    const bool hasParent = static_cast<bool>(msg->getU8());

    bool isUnlocked = true;
    bool hasPages = false;
    uint16_t containerSize = 0;
    uint16_t firstIndex = 0;

    if (g_game.getClientVersion() >= 1281) {
        msg->getU8(); // (bool) show search icon
    }

    if (g_game.getFeature(Otc::GameContainerPagination)) {
        isUnlocked = static_cast<bool>(msg->getU8()); // drag and drop
        hasPages = static_cast<bool>(msg->getU8()); // pagination
        containerSize = msg->getU16(); // container size
        firstIndex = msg->getU16(); // first index
    }

    const uint8_t itemCount = msg->getU8();
    std::vector<ItemPtr> items;
    items.reserve(itemCount);

    for (auto i = 0; i < itemCount; i++) {
        items.push_back(getItem(msg));
    }

    if (g_game.getFeature(Otc::GameContainerFilter)) {
        msg->getU8(); // category
        const uint8_t categoriesSize = msg->getU8();
        for (auto i = 0; i < categoriesSize; ++i) {
            msg->getU8(); // id
            msg->getString(); // name
        }
    }

    if (g_game.getClientVersion() >= 1340) {
        msg->getU8(); // isMoveable
        msg->getU8(); // isHolding
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
        if (itemId != 0) {
            lastItem = getItem(msg, itemId);
        }
    } else {
        slot = msg->getU8();
    }

    g_game.processContainerRemoveItem(containerId, slot, lastItem);
}

void ProtocolGame::parseBosstiaryInfo(const InputMessagePtr& msg)
{
    const uint16_t bosstiaryRaceLast = msg->getU16();
    std::vector<BosstiaryData> bossData;

    for (auto i = 0; i < bosstiaryRaceLast; ++i) {
        BosstiaryData boss;
        boss.raceId = msg->getU32();
        boss.category = msg->getU8();
        boss.kills = msg->getU32();
        msg->getU8();
        boss.isTrackerActived = msg->getU8();
        bossData.emplace_back(boss);
    }

    g_game.processBosstiaryInfo(bossData);
}

void ProtocolGame::parseCyclopediaItemDetail(const InputMessagePtr& msg)
{
    msg->getU8(); // 0x00
    msg->getU8(); // bool is cyclopedia
    msg->getU32(); // creature ID (version 13.00)
    msg->getU8(); // 0x01

    msg->getString(); // item name
    const auto& item = getItem(msg);

    msg->getU8(); // 0x00

    const uint8_t descriptionsSize = msg->getU8();
    std::vector<std::tuple<std::string, std::string>> descriptions;
    descriptions.reserve(descriptionsSize);

    for (auto i = 0; i < descriptionsSize; ++i) {
        const auto& firstDescription = msg->getString();
        const auto& secondDescription = msg->getString();
        descriptions.emplace_back(firstDescription, secondDescription);
    }

    g_game.processItemDetail(item->getId(), descriptions);
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
    if (g_game.getFeature(Otc::GameNameOnNpcTrade)) {
        msg->getString(); // npcName
    }

    if (g_game.getClientVersion() >= 1281) {
        msg->getU16(); // currency
        msg->getString(); // currency name
    }

    const uint16_t listCount = g_game.getClientVersion() >= 900 ? msg->getU16() : msg->getU8();
    std::vector<std::tuple<ItemPtr, std::string, uint32_t, uint32_t, uint32_t>> items;

    for (auto i = 0; i < listCount; ++i) {
        const uint16_t itemId = msg->getU16();
        const uint8_t itemCount = msg->getU8();

        const auto item = Item::create(itemId);
        item->setCountOrSubType(itemCount);

        const auto& itemName = msg->getString();
        const uint32_t itemWeight = msg->getU32();
        const uint32_t itemBuyPrice = msg->getU32();
        const uint32_t itemSellPrice = msg->getU32();

        items.emplace_back(item, itemName, itemWeight, itemBuyPrice, itemSellPrice);
    }

    g_game.processOpenNpcTrade(items);
}

void ProtocolGame::parsePlayerGoods(const InputMessagePtr& msg) const
{
    // 12.x NOTE: this u64 is parsed only, because TFS stil sends it, we use resource balance in this protocol
    uint64_t money = 0;
    if (g_game.getClientVersion() >= 1281) {
        money = m_localPlayer->getResourceBalance(Otc::RESOURCE_BANK_BALANCE) + m_localPlayer->getResourceBalance(Otc::RESOURCE_GOLD_EQUIPPED);
    } else {
        money = g_game.getClientVersion() >= 973 ? msg->getU64() : msg->getU32();
    }

    const uint8_t itemsListSize = g_game.getClientVersion() >= 1334 ? msg->getU16() : msg->getU8();
    std::vector<std::tuple<ItemPtr, uint16_t>> goods;

    for (auto i = 0; i < itemsListSize; ++i) {
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
    std::vector<ItemPtr> items;
    items.reserve(count);

    for (auto i = 0; i < count; i++) {
        items.push_back(getItem(msg));
    }

    g_game.processOwnTrade(name, items);
}

void ProtocolGame::parseCounterTrade(const InputMessagePtr& msg)
{
    const auto& name = g_game.formatCreatureName(msg->getString());

    const uint8_t count = msg->getU8();
    std::vector<ItemPtr> items;
    items.reserve(count);

    for (auto i = 0; i < count; i++) {
        items.push_back(getItem(msg));
    }

    g_game.processCounterTrade(name, items);
}

void ProtocolGame::parseCloseTrade(const InputMessagePtr&) { g_game.processCloseTrade(); }

void ProtocolGame::parseWorldLight(const InputMessagePtr& msg)
{
    const auto& oldLight = g_map.getLight();

    const auto intensity = msg->getU8();
    const auto color = msg->getU8();

    g_map.setLight({ intensity , color });

    if (oldLight.color != color || oldLight.intensity != intensity) {
        g_lua.callGlobalField("g_game", "onWorldLightChange", g_map.getLight(), oldLight);
    }
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
                    const auto offsetX = static_cast<int8_t>(msg->getU8());
                    const auto offsetY = static_cast<int8_t>(msg->getU8());
                    if (!g_things.isValidDatId(shotId, ThingCategoryMissile)) {
                        g_logger.traceError("invalid missile id {}", shotId);
                        return;
                    }

                    const auto& missile = std::make_shared<Missile>();
                    missile->setId(shotId);

                    if (effectType == Otc::MAGIC_EFFECTS_CREATE_DISTANCEEFFECT) {
                        missile->setPath(pos, Position(pos.x + offsetX, pos.y + offsetY, pos.z));
                    } else {
                        missile->setPath(Position(pos.x + offsetX, pos.y + offsetY, pos.z), pos);
                    }

                    g_map.addThing(missile, pos);
                    break;
                }

                case Otc::MAGIC_EFFECTS_CREATE_EFFECT: {
                    const uint16_t effectId = g_game.getFeature(Otc::GameEffectU16) ? msg->getU16() : msg->getU8();
                    if (!g_things.isValidDatId(effectId, ThingCategoryEffect)) {
                        g_logger.traceError("invalid effect id {}", effectId);
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

    if (g_game.getClientVersion() <= 750) {
        effectId += 1; //hack to fix effects in earlier clients
    }

    if (!g_things.isValidDatId(effectId, ThingCategoryEffect)) {
        g_logger.traceError("invalid effect id {}", effectId);
        return;
    }

    const auto& effect = std::make_shared<Effect>();
    effect->setId(effectId);

    g_map.addThing(effect, pos);
}

void ProtocolGame::parseRemoveMagicEffect(const InputMessagePtr& msg)
{
    getPosition(msg);
    uint16_t effectId = g_game.getFeature(Otc::GameEffectU16) ? msg->getU16() : msg->getU8();
    if (!g_things.isValidDatId(effectId, ThingCategoryEffect)) {
        g_logger.warning("[ProtocolGame::parseRemoveMagicEffect] - Invalid effectId type {}", effectId);
        return;
    }
    // TO-DO
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
        g_logger.traceError("invalid missile id {}", shotId);
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
        g_logger.traceError("ProtocolGame::parseCreatureMark: could not get creature with id {}", creatureId);
        return;
    }

    creature->addTimedSquare(color);
}

void ProtocolGame::parseTrappers(const InputMessagePtr& msg)
{
    const uint8_t numTrappers = msg->getU8();

    if (numTrappers > 8) {
        g_logger.traceError("ProtocolGame::parseTrappers: too many trappers");
    }

    for (auto i = 0; i < numTrappers; ++i) {
        const uint32_t creatureId = msg->getU32();
        const auto& creature = g_map.getCreatureById(creatureId);
        if (!creature) {
            g_logger.traceError("ProtocolGame::parseTrappers: could not get creature with id {}", creatureId);
        }

        //TODO: set creature as trapper
    }
}

void ProtocolGame::addCreatureIcon(const InputMessagePtr& msg) const
{
    const uint8_t sizeIcons = msg->getU8();
    for (auto i = 0; i < sizeIcons; ++i) {
        msg->getU8(); // icon.serialize()
        msg->getU8(); // icon.category
        msg->getU16(); // icon.count
    }

    // TODO: implement creature icons usage
}

void ProtocolGame::parseCloseForgeWindow(const InputMessagePtr& /*msg*/)
{
    g_lua.callGlobalField("g_game", "onCloseForgeCloseWindows");
}

void ProtocolGame::parseCreatureData(const InputMessagePtr& msg)
{
    const uint32_t creatureId = msg->getU32();
    const uint8_t type = msg->getU8();

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError("ProtocolGame::parseCreatureData: could not get creature with id {}", creatureId);
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
            addCreatureIcon(msg);
            break;
    }
}

void ProtocolGame::parseCreatureHealth(const InputMessagePtr& msg)
{
    const uint32_t creatureId = msg->getU32();
    const uint8_t healthPercent = msg->getU8();

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError("ProtocolGame::parseCreatureHealth: could not get creature with id {}", creatureId);
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
        g_logger.traceError("ProtocolGame::parseCreatureLight: could not get creature with id {}", creatureId);
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
        g_logger.traceError("ProtocolGame::parseCreatureOutfit: could not get creature with id {}", creatureId);
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
        g_logger.traceError("ProtocolGame::parseCreatureSpeed: could not get creature with id {}", creatureId);
        return;
    }

    creature->setSpeed(speed);
    if (baseSpeed != 0) {
        creature->setBaseSpeed(baseSpeed);
    }
}

void ProtocolGame::parseCreatureSkulls(const InputMessagePtr& msg)
{
    const uint32_t creatureId = msg->getU32();
    const uint8_t skull = msg->getU8();

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError("ProtocolGame::parseCreatureSkulls: could not get creature with id {}", creatureId);
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
        g_logger.traceError("ProtocolGame::parseCreatureShields: could not get creature with id {}", creatureId);
        return;
    }

    creature->setShield(shield);
}

void ProtocolGame::parseCreatureUnpass(const InputMessagePtr& msg)
{
    const uint32_t creatureId = msg->getU32();
    const bool unpass = static_cast<bool>(msg->getU8());

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError("ProtocolGame::parseCreatureUnpass: could not get creature with id {}", creatureId);
        return;
    }

    creature->setPassable(!unpass);
}

void ProtocolGame::parseEditText(const InputMessagePtr& msg)
{
    const uint32_t id = msg->getU32();

    uint32_t itemId;
    if (g_game.getClientVersion() >= 1010 || g_game.getFeature(Otc::GameItemShader)) {
        // TODO: processEditText with ItemPtr as parameter
        const auto& item = getItem(msg);
        itemId = item->getId();
    } else {
        itemId = msg->getU16();
    }

    const uint16_t maxLength = msg->getU16();

    const auto& text = msg->getString();
    const auto& writer = msg->getString();

    if (g_game.getClientVersion() >= 1281) {
        msg->getU8(); // suffix
    }

    std::string date;
    if (g_game.getFeature(Otc::GameWritableDate)) {
        date = msg->getString();
    }

    g_game.processEditText(id, itemId, maxLength, text, writer, date);
}

void ProtocolGame::parseEditList(const InputMessagePtr& msg)
{
    const uint8_t doorId = msg->getU8();
    const uint32_t id = msg->getU32();
    const auto& text = msg->getString();

    g_game.processEditList(id, doorId, text);
}

void ProtocolGame::parsePremiumTrigger(const InputMessagePtr& msg)
{
    const uint8_t triggerCount = msg->getU8();
    std::vector<uint8_t> triggers;

    for (auto i = 0; i < triggerCount; ++i) {
        triggers.push_back(msg->getU8());
    }

    if (g_game.getClientVersion() <= 1096) {
        msg->getU8(); // == 1; // something
    }
}

void ProtocolGame::parsePlayerInfo(const InputMessagePtr& msg) const
{
    const bool premium = static_cast<bool>(msg->getU8()); // premium

    if (g_game.getFeature(Otc::GamePremiumExpiration)) {
        msg->getU32(); // premium expiration used for premium advertisement
    }

    const uint8_t vocation = msg->getU8(); // vocation

    if (g_game.getFeature(Otc::GamePrey)) {
        msg->getU8(); // (bool) prey enabled
    }

    const uint16_t spellCount = msg->getU16();
    std::vector<uint16_t> spells;

    for (auto i = 0; i < spellCount; ++i) {
        if (g_game.getFeature(Otc::GameUshortSpell)) {
            spells.push_back(msg->getU16()); // spell id
        } else {
            spells.push_back(msg->getU8()); // spell id
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
    const int version = g_game.getClientVersion();

    if (version >= 1281) {
        // magic level
        const uint16_t magicLevel = msg->getU16();
        const uint16_t baseMagicLevel = msg->getU16();
        msg->getU16(); // loyalty bonus
        const uint8_t percent = msg->getU16() / 100;

        m_localPlayer->setMagicLevel(magicLevel, percent);
        m_localPlayer->setBaseMagicLevel(baseMagicLevel);
    }

    for (int_fast32_t skill = Otc::Fist; skill <= Otc::Fishing; ++skill) {
        const uint16_t level = g_game.getFeature(Otc::GameDoubleSkills) ? msg->getU16() : msg->getU8();

        uint16_t baseLevel;
        if (g_game.getFeature(Otc::GameSkillsBase)) {
            baseLevel = g_game.getFeature(Otc::GameBaseSkillU16) ? msg->getU16() : msg->getU8();
        } else {
            baseLevel = level;
        }

        uint16_t levelPercent = 0;
        if (version >= 1281) {
            msg->getU16(); // loyalty
            levelPercent = msg->getU16() / 100;
        } else {
            levelPercent = msg->getU8();
        }

        m_localPlayer->setSkill(static_cast<Otc::Skill>(skill), level, levelPercent);
        m_localPlayer->setBaseSkill(static_cast<Otc::Skill>(skill), baseLevel);
    }

    if (g_game.getFeature(Otc::GameAdditionalSkills) && version < 1412) {
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

    if (version >= 1281 && version < 1412) {
        // forge skill stats (pre-14.12)
        const uint8_t lastSkill = version >= 1332 ? Otc::LastSkill : Otc::Momentum + 1;
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

    } else if (version >= 1412) {
        const uint32_t capacity = msg->getU32();
        msg->getU32(); // base capacity
        m_localPlayer->setTotalCapacity(capacity);

        msg->getU16(); // flat healing/damage bonus

        msg->getU16(); // attack total
        msg->getU8(); // element
        msg->getDouble(); // element ratio
        msg->getU8(); // element type

        // Imbuement values
        msg->getDouble(); // Life Leech
        msg->getDouble(); // Mana Leech
        msg->getDouble(); // Crit Chance
        msg->getDouble(); // Crit Extra Damage
        msg->getDouble(); // Onslaught

        msg->getU16(); // Defense
        msg->getU16(); // Armor
        msg->getDouble(); // Mitigation
        msg->getDouble(); // Dodge
        msg->getU16(); // Reflection

        const uint8_t absorbCount = msg->getU8();
        for (uint8_t i = 0; i < absorbCount; ++i) {
            msg->getU8(); // combat type
            msg->getDouble(); // value
        }

        msg->getDouble(); // Momentum
        msg->getDouble(); // Transcendence
        msg->getDouble(); // Amplification
    }
}

void ProtocolGame::parsePlayerState(const InputMessagePtr& msg) const
{
    uint64_t states;
    if (g_game.getClientVersion() >= 1281) {
        if (g_game.getClientVersion() >= 1405) {
            states = msg->getU64();
            
        } else {
            states = msg->getU32();
        }
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

void ProtocolGame::parsePlayerModes(const InputMessagePtr& msg)
{
    const auto fightMode = static_cast<Otc::FightModes>(msg->getU8());
    const auto chaseMode = static_cast<Otc::ChaseModes>(msg->getU8());
    const bool safeMode = static_cast<bool>(msg->getU8());
    const auto pvpMode = static_cast<Otc::PVPModes>(g_game.getFeature(Otc::GamePVPMode) ? msg->getU8() : 0);

    g_game.processPlayerModes(fightMode, chaseMode, safeMode, pvpMode);
}

void ProtocolGame::parseSpellCooldown(const InputMessagePtr& msg)
{
    const uint16_t spellId = g_game.getFeature(Otc::GameUshortSpell) ? msg->getU16() : msg->getU8();
    const uint32_t delay = msg->getU32();

    g_lua.callGlobalField("g_game", "onSpellCooldown", spellId, delay);
}

void ProtocolGame::parseSpellGroupCooldown(const InputMessagePtr& msg)
{
    const uint8_t groupId = msg->getU8();
    const uint32_t delay = msg->getU32();

    g_lua.callGlobalField("g_game", "onSpellGroupCooldown", groupId, delay);
}

void ProtocolGame::parseMultiUseCooldown(const InputMessagePtr& msg)
{
    const uint32_t delay = msg->getU32();
    g_lua.callGlobalField("g_game", "onMultiUseCooldown", delay);
}

void ProtocolGame::parseTalk(const InputMessagePtr& msg)
{
    uint32_t statement = 0;
    if (g_game.getFeature(Otc::GameMessageStatements)) {
        statement = msg->getU32(); // channel statement guid
    }

    const auto& name = g_game.formatCreatureName(msg->getString());

    if (statement > 0 && g_game.getClientVersion() >= 1281) {
        msg->getU8(); // suffix
    }

    const uint16_t level = g_game.getFeature(Otc::GameMessageLevel) ? msg->getU16() : 0;

    auto messageByte = msg->getU8();
    const Otc::MessageMode mode = Proto::translateMessageModeFromServer(messageByte);
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
            throw Exception("ProtocolGame::parseTalk: unknown message mode {}", messageByte);
    }

    const auto& text = msg->getString();

    g_game.processTalk(name, level, mode, text, channelId, pos);
}

void ProtocolGame::parseChannelList(const InputMessagePtr& msg)
{
    const uint8_t channelListSize = msg->getU8();
    std::vector<std::tuple<uint16_t, std::string>> channelList;

    for (auto i = 0; i < channelListSize; ++i) {
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
        for (auto i = 0; i < joinedPlayers; ++i) {
            g_game.formatCreatureName(msg->getString()); // player name
        }

        const uint16_t invitedPlayers = msg->getU16();
        for (auto i = 0; i < invitedPlayers; ++i) {
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

void ProtocolGame::parseRuleViolationChannel(const InputMessagePtr& msg)
{
    const uint16_t channelId = msg->getU16();
    Game::processRuleViolationChannel(channelId);
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

void ProtocolGame::parseRuleViolationLock(const InputMessagePtr&) { g_game.processRuleViolationLock(); }

void ProtocolGame::parseTextMessage(const InputMessagePtr& msg)
{
    const uint8_t code = msg->getU8();
    const Otc::MessageMode mode = Proto::translateMessageModeFromServer(code);
    std::string text;

    g_logger.debug("[ProtocolGame::parseTextMessage] code: {}, mode: {}", code, code);

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
            std::array<uint32_t, 2> value{};
            std::array<uint8_t, 2> color{};

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
            throw Exception("ProtocolGame::parseTextMessage: unknown message mode {}", code);
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

    auto newPos = pos;
    ++newPos.x;
    ++newPos.y;
    g_map.setCentralPosition(newPos);

    g_lua.callGlobalField("g_game", "onTeleport", m_localPlayer, newPos, pos);
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

    auto newPos = pos;
    --newPos.x;
    --newPos.y;
    g_map.setCentralPosition(newPos);

    g_lua.callGlobalField("g_game", "onTeleport", m_localPlayer, newPos, pos);
}

void ProtocolGame::parseOpenOutfitWindow(const InputMessagePtr& msg) const
{
    const auto& currentOutfit = getOutfit(msg);

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

    std::vector<std::tuple<uint16_t, std::string, uint8_t, uint8_t>> outfitList;

    if (g_game.getFeature(Otc::GameNewOutfitProtocol)) {
        const uint16_t outfitCount = g_game.getClientVersion() >= 1281 ? msg->getU16() : msg->getU8();
        for (auto i = 0; i < outfitCount; ++i) {
            const uint16_t outfitId = msg->getU16();
            const auto& outfitName = msg->getString();
            const uint8_t outfitAddons = msg->getU8();
            uint8_t outfitMode = 0;
            if (g_game.getClientVersion() >= 1281) {
                outfitMode = msg->getU8(); // mode: 0x00 - available, 0x01 store (requires U32 store offerId), 0x02 golden outfit tooltip (hardcoded)
                if (outfitMode == 1) {
                    msg->getU32();
                }
            }

            outfitList.emplace_back(outfitId, outfitName, outfitAddons, outfitMode);
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
            outfitList.emplace_back(i, "", 0, 0);
        }
    }

    std::vector<std::tuple<uint16_t, std::string, uint8_t>> mountList;

    if (g_game.getFeature(Otc::GamePlayerMounts)) {
        const uint16_t mountCount = g_game.getClientVersion() >= 1281 ? msg->getU16() : msg->getU8();
        for (auto i = 0; i < mountCount; ++i) {
            const uint16_t mountId = msg->getU16(); // mount type
            const auto& mountName = msg->getString(); // mount name
            uint8_t mountMode = 0;
            if (g_game.getClientVersion() >= 1281) {
                mountMode = msg->getU8(); // mode: 0x00 - available, 0x01 store (requires U32 store offerId)
                if (mountMode == 1) {
                    msg->getU32();
                }
            }

            mountList.emplace_back(mountId, mountName, mountMode);
        }
    }

    std::vector<std::tuple<uint16_t, std::string> > familiarList;
    if (g_game.getFeature(Otc::GamePlayerFamiliars)) {
        const uint16_t familiarCount = msg->getU16();
        for (auto i = 0; i < familiarCount; ++i) {
            const uint16_t familiarLookType = msg->getU16(); // familiar lookType
            const auto& familiarName = msg->getString(); // familiar name
            const uint8_t familiarMode = msg->getU8(); // 0x00 // mode: 0x00 - available, 0x01 store (requires U32 store offerId)
            if (familiarMode == 1) {
                msg->getU32();
            }
            familiarList.emplace_back(familiarLookType, familiarName);
        }
    }

    if (g_game.getClientVersion() >= 1281) {
        msg->getU8(); // Try outfit mode (?)
        msg->getU8(); // (bool) mounted
        msg->getU8(); // (bool) randomize mount
    }

    std::vector<std::tuple<uint16_t, std::string>> wingList;
    std::vector<std::tuple<uint16_t, std::string>> auraList;
    std::vector<std::tuple<uint16_t, std::string>> effectList;
    std::vector<std::tuple<uint16_t, std::string>> shaderList;

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

    g_game.processOpenOutfitWindow(currentOutfit, outfitList, mountList, familiarList, wingList, auraList, effectList, shaderList);
}

void ProtocolGame::parseQuestTracker(const InputMessagePtr& msg)
{
    const uint8_t messageType = msg->getU8();
    switch (messageType) {
        case 1: {
            const uint8_t remainingQuests = msg->getU8();
            const uint8_t missionCount = msg->getU8();
            std::vector<std::tuple<uint16_t, std::string, uint8_t, std::string, std::string>> missions;
            for (uint8_t i = 0; i < missionCount; ++i) {
                const uint16_t missionId = msg->getU16();
                const std::string& questName = msg->getString();
                uint8_t questIsCompleted = 0;
                if (g_game.getClientVersion() >= 1410) {
                    questIsCompleted = msg->getU8();
                }
                const std::string& missionName = msg->getString();
                const std::string& missionDesc = msg->getString();
                missions.emplace_back(missionId, questName, questIsCompleted, missionName, missionDesc);
            }
            return g_lua.callGlobalField("g_game", "onQuestTracker", remainingQuests, missions);
        }
        case 0: {
            const uint16_t missionId = msg->getU16();
            const std::string& missionName = msg->getString();
            uint8_t questIsCompleted = 0;
            if (g_game.getClientVersion() >= 1410) {
                questIsCompleted = msg->getU8();
            }
            const std::string& missionDesc = msg->getString();
            return g_lua.callGlobalField("g_game", "onUpdateQuestTracker", missionId, missionName, questIsCompleted, missionDesc);
        }
    }
}

void ProtocolGame::parseKillTracker(const InputMessagePtr& msg)
{
    msg->getString(); // monster name
    getOutfit(msg, false);

    const uint8_t corpseItemsSize = msg->getU8();
    for (auto i = 0; i < corpseItemsSize; ++i) {
        getItem(msg);
    }
}

void ProtocolGame::parseVipAdd(const InputMessagePtr& msg)
{
    uint32_t iconId = 0;
    std::string desc;
    bool notifyLogin = false;
    std::vector<uint8_t> groupIDs;

    const uint32_t id = msg->getU32();
    const auto& name = g_game.formatCreatureName(msg->getString());
    if (g_game.getFeature(Otc::GameAdditionalVipInfo)) {
        desc = msg->getString();
        iconId = msg->getU32();
        notifyLogin = static_cast<bool>(msg->getU8());
    }

    const uint32_t status = msg->getU8();
    if (g_game.getFeature(Otc::GameVipGroups)) {
        const uint8_t vipGroupSize = msg->getU8();
        groupIDs.reserve(vipGroupSize);
        for (auto i = 0; i < vipGroupSize; ++i) {
            const uint8_t groupID = msg->getU8();
            groupIDs.push_back(groupID);
        }
    }

    g_game.processVipAdd(id, name, status, desc, iconId, notifyLogin, groupIDs);
}

void ProtocolGame::parseVipState(const InputMessagePtr& msg)
{
    const uint32_t id = msg->getU32();
    const uint32_t status = g_game.getFeature(Otc::GameLoginPending) ? msg->getU8() : 1;

    g_game.processVipStateChange(id, status);
}

void ProtocolGame::parseVipLogout(const InputMessagePtr& msg)
{
    // On QT client this operation is being processed on the 'parseVipState', now this opcode if for groups
    if (g_game.getFeature(Otc::GameVipGroups)) {
        const uint8_t vipGroupSize = msg->getU8();
        std::vector<std::tuple<uint8_t, std::string, bool>> vipGroups;
        for (auto i = 0; i < vipGroupSize; ++i) {
            const uint8_t groupId = msg->getU8();
            const auto& groupName = msg->getString();
            const bool canEditGroup = static_cast<bool>(msg->getU8());
            vipGroups.emplace_back(groupId, groupName, canEditGroup);
        }
        const uint8_t groupsAmountLeft = msg->getU8();
        g_game.processVipGroupChange(vipGroups, groupsAmountLeft);
    } else {
        const uint32_t id = msg->getU32();
        g_game.processVipStateChange(id, 0);
    }
}

void ProtocolGame::parseBestiaryRaces(const InputMessagePtr& msg)
{
    std::vector<CyclopediaBestiaryRace> bestiaryData;

    const uint16_t bestiaryRaceLast = msg->getU16();
    for (auto i = 0; i < bestiaryRaceLast; ++i) {
        CyclopediaBestiaryRace race;
        race.race = i;
        race.bestClass = msg->getString();
        race.count = msg->getU16();
        race.unlockedCount = msg->getU16();
        bestiaryData.emplace_back(race);
    }

    g_game.processParseBestiaryRaces(bestiaryData);
}

void ProtocolGame::parseBestiaryOverview(const InputMessagePtr& msg)
{
    const auto& raceName = msg->getString();

    const uint16_t raceSize = msg->getU16();
    std::vector<BestiaryOverviewMonsters> data;

    for (auto i = 0; i < raceSize; ++i) {
        const uint16_t raceId = msg->getU16();
        const uint8_t progress = msg->getU8();
        uint8_t occurrence = 0;
        uint16_t creatureAnimusMasteryBonus = 0;
        if (progress > 0) {
            occurrence = msg->getU8();
        }
        if (g_game.getClientVersion() >= 1340) {
            creatureAnimusMasteryBonus = msg->getU16(); // Creature Animous Bonus
        }
        BestiaryOverviewMonsters monster;
        monster.id = raceId;
        monster.currentLevel = progress;
        monster.occurrence = occurrence;
        monster.creatureAnimusMasteryBonus = creatureAnimusMasteryBonus;
        data.emplace_back(monster);
    }

    uint16_t animusMasteryPoints = 0;
    if (g_game.getClientVersion() >= 1340) {
        animusMasteryPoints = msg->getU16(); // Animus Mastery Points
    }

    g_game.processParseBestiaryOverview(raceName, data, animusMasteryPoints);
}

void ProtocolGame::parseBestiaryMonsterData(const InputMessagePtr& msg)
{
    BestiaryMonsterData data;
    data.id = msg->getU16();
    data.bestClass = msg->getString();
    data.currentLevel = msg->getU8();

    auto version = g_game.getClientVersion();
    if (version >= 1340) {
        data.AnimusMasteryBonus = msg->getU16(); // Animus Mastery Bonus
        data.AnimusMasteryPoints = msg->getU16(); // Animus Mastery Points
    } else {
        data.AnimusMasteryBonus = 0;
        data.AnimusMasteryPoints = 0;
    }

    data.killCounter = msg->getU32();
    data.thirdDifficulty = msg->getU16();
    data.secondUnlock = msg->getU16();
    data.lastProgressKillCount = msg->getU16();
    data.difficulty = msg->getU8();
    data.ocorrence = msg->getU8();

    const uint8_t lootCount = msg->getU8();
    for (auto i = 0; i < lootCount; ++i) {
        LootItem lootItem;
        lootItem.itemId = msg->getU16();
        lootItem.diffculty = msg->getU8();
        lootItem.specialEvent = msg->getU8();

        const bool shouldAddItem = lootItem.itemId != 0;
        if (shouldAddItem) {
            lootItem.name = msg->getString();
            lootItem.amount = msg->getU8();
        }
        data.loot.emplace_back(lootItem);
    }

    if (data.currentLevel > 1) {
        data.charmValue = msg->getU16();
        data.attackMode = msg->getU8();
        msg->getU8();
        data.maxHealth = msg->getU32();
        data.experience = msg->getU32();
        data.speed = msg->getU16();
        data.armor = msg->getU16();
        data.mitigation = msg->getDouble();
    }

    if (data.currentLevel > 2) {
        const uint8_t elementsCount = msg->getU8();
        for (auto i = 0; i < elementsCount; ++i) {
            const uint8_t elementId = msg->getU8();
            const uint16_t elementValue = msg->getU16();
            data.combat[elementId] = elementValue;
        }

        msg->getU16();
        data.location = msg->getString();
    }

    if (data.currentLevel > 3 && version < 1412) {
        const bool hasCharm = static_cast<bool>(msg->getU8());
        if (hasCharm) {
            msg->getU8();
            msg->getU32();
        } else {
            msg->getU8();
        }
    }

    g_game.processUpdateBestiaryMonsterData(data);
}

void ProtocolGame::parseBestiaryCharmsData(const InputMessagePtr& msg)
{
    BestiaryCharmsData charmData;
    auto version = g_game.getClientVersion();
    if (version >= 1405) {
        charmData.points = msg->getU64();

    } else {
        charmData.points = msg->getU32();
    }

    if (version >= 1412) {
        const uint8_t charmsAmount = msg->getU8();
        for (uint8_t i = 0; i < charmsAmount; ++i) {
            CharmData charm;
            charm.id = msg->getU8();
            const uint8_t tier = msg->getU8();

            charm.unlockPrice = 0; // not sent anymore
            charm.unlocked = tier > 0;
            charm.asignedStatus = false;
            charm.raceId = 0;
            charm.removeRuneCost = 0;

            if (tier > 0) {
                const bool assigned = msg->getU8() == 1;
                if (assigned) {
                    charm.asignedStatus = true;
                    charm.raceId = msg->getU16();
                    charm.removeRuneCost = msg->getU32();
                }
            } else {
                msg->getU8(); // still reserved
            }

            // name and description are no longer sent
            charm.name = fmt::format("Charm {}", charm.id);
            charm.description = fmt::format("Tier {} charm", tier);

            charmData.charms.emplace_back(charm);
        }

        // available charm slots (uint8)
        msg->getU8();

        // finished monsters list (uint16 count + list of uint32 ids)
        const uint16_t finishedMonstersSize = msg->getU16();
        for (uint16_t i = 0; i < finishedMonstersSize; ++i) {
            const auto raceId = static_cast<uint16_t>(msg->getU32());
            charmData.finishedMonsters.emplace_back(raceId);
        }
    } else {
        const uint8_t charmsAmount = msg->getU8();
        for (auto i = 0; i < charmsAmount; ++i) {
            CharmData charm;
            charm.id = msg->getU8();
            charm.name = msg->getString();
            charm.description = msg->getString();
            msg->getU8();
            charm.unlockPrice = msg->getU16();
            charm.unlocked = msg->getU8() == 1;
            charm.asignedStatus = false;
            charm.raceId = 0;
            charm.removeRuneCost = 0;

            if (charm.unlocked) {
                const bool asigned = static_cast<bool>(msg->getU8());
                if (asigned) {
                    charm.asignedStatus = asigned;
                    charm.raceId = msg->getU16();
                    charm.removeRuneCost = msg->getU32();
                }
            } else {
                msg->getU8();
            }

            charmData.charms.emplace_back(charm);
        }

        msg->getU8();

        const uint16_t finishedMonstersSize = msg->getU16();
        for (auto i = 0; i < finishedMonstersSize; ++i) {
            const uint16_t raceId = msg->getU16();
            charmData.finishedMonsters.emplace_back(raceId);
        }
    }

    g_game.processUpdateBestiaryCharmsData(charmData);
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

    const bool remove = g_game.getFeature(Otc::GameMinimapRemove) ? static_cast<bool>(msg->getU8()) : false;
    if (!remove) {
        g_game.processAddAutomapFlag(pos, icon, description);
    } else {
        g_game.processRemoveAutomapFlag(pos, icon, description);
    }
}

void ProtocolGame::parseQuestLog(const InputMessagePtr& msg)
{
    const uint16_t questsCount = msg->getU16();
    std::vector<std::tuple<uint16_t, std::string, bool>> questList;

    for (auto i = 0; i < questsCount; ++i) {
        const uint16_t id = msg->getU16();
        const auto& questName = msg->getString();
        const bool questCompleted = static_cast<bool>(msg->getU8());
        questList.emplace_back(id, questName, questCompleted);
    }

    g_game.processQuestLog(questList);
}

void ProtocolGame::parseQuestLine(const InputMessagePtr& msg)
{
    const uint16_t questId = msg->getU16();

    const uint8_t missionCount = msg->getU8();
    std::vector<std::tuple<std::string, std::string, uint16_t>> questMissions;

    for (auto i = 0; i < missionCount; ++i) {
        auto missionId = 0;
        if (g_game.getClientVersion() >= 1200) {
            missionId = msg->getU16();
        }
        const auto& missionName = msg->getString();
        const auto& missionDescrition = msg->getString();
        questMissions.emplace_back(missionName, missionDescrition, missionId);
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
    const uint8_t listCount = msg->getU8();
    std::vector<std::tuple<ItemPtr, std::string>> itemList;

    for (auto i = 0; i < listCount; ++i) {
        const auto& item = std::make_shared<Item>();
        item->setId(msg->getU16());
        item->setCountOrSubType(g_game.getFeature(Otc::GameCountU16) ? msg->getU16() : msg->getU8());
        const auto& desc = msg->getString();
        itemList.emplace_back(item, desc);
    }

    g_lua.callGlobalField("g_game", "onItemInfo", itemList);
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

    const uint8_t buttonsCount = msg->getU8();
    std::vector<std::tuple<uint8_t, std::string>> buttonList;

    for (auto i = 0; i < buttonsCount; ++i) {
        const auto& value = msg->getString();
        const uint8_t buttonId = msg->getU8();
        buttonList.emplace_back(buttonId, value);
    }

    const uint8_t choicesCount = msg->getU8();
    std::vector<std::tuple<uint8_t, std::string>> choiceList;

    for (auto i = 0; i < choicesCount; ++i) {
        const auto& value = msg->getString();
        const uint8_t choideId = msg->getU8();
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

    const bool priority = static_cast<bool>(msg->getU8());

    g_game.processModalDialog(windowId, title, message, buttonList, enterButton, escapeButton, choiceList, priority);
}

void ProtocolGame::parseExtendedOpcode(const InputMessagePtr& msg)
{
    const uint8_t opcode = msg->getU8();
    const auto& buffer = msg->getString();

    if (opcode == 0) {
        m_enableSendExtendedOpcode = true;
    } else if (opcode == 2) {
        parsePingBack(msg);
    } else {
        callLuaField("onExtendedOpcode", opcode, buffer);
    }
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

    g_lua.callGlobalField("g_game", "onMapChangeAwareRange", xRange, yRange);
}

void ProtocolGame::parseCreaturesMark(const InputMessagePtr& msg)
{
    const uint32_t creatureId = msg->getU32();
    const bool isPermanent = g_game.getClientVersion() >= 1076 ? msg->getU8() == 0 : false;
    const uint8_t markType = msg->getU8();

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError("ProtocolGame::parseTrappers: could not get creature with id {}", creatureId);
        return;
    }

    if (isPermanent) {
        if (markType == 0xff) {
            creature->hideStaticSquare();
        } else {
            creature->showStaticSquare(Color::from8bit(markType != 0 ? markType : 1));
        }
    } else {
        creature->addTimedSquare(markType);
    }
}

void ProtocolGame::parseCreatureType(const InputMessagePtr& msg)
{
    const uint32_t creatureId = msg->getU32();
    const uint8_t type = msg->getU8();

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError("ProtocolGame::parseCreatureType: could not get creature with id {}", creatureId);
        return;
    }

    creature->setType(type);
}

void ProtocolGame::setMapDescription(const InputMessagePtr& msg, const int x, const int y, const int z, const int width, const int height)
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
    for (auto nz = startz; nz != endz + zstep; nz += zstep) {
        skip = setFloorDescription(msg, x, y, nz, width, height, z - nz, skip);
    }

    g_game.updateMapLatency();
}

int ProtocolGame::setFloorDescription(const InputMessagePtr& msg, const int x, const int y, const int z, const int width, const int height, const int offset, int skip)
{
    for (auto nx = 0; nx < width; ++nx) {
        for (auto ny = 0; ny < height; ++ny) {
            const Position tilePos(x + nx + offset, y + ny + offset, z);
            if (skip == 0) {
                skip = setTileDescription(msg, tilePos);
            } else {
                g_map.cleanTile(tilePos);
                --skip;
            }
        }
    }
    return skip;
}

int ProtocolGame::setTileDescription(const InputMessagePtr& msg, const Position position)
{
    g_map.cleanTile(position);

    bool gotEffect = false;
    for (auto stackPos = 0; stackPos < 256; ++stackPos) {
        if (msg->peekU16() >= 0xff00) {
            return msg->getU16() & 0xff;
        }

        if (g_game.getFeature(Otc::GameEnvironmentEffect) && !gotEffect) {
            msg->getU16(); // environment effect
            gotEffect = true;
            continue;
        }

        if (stackPos > g_gameConfig.getTileMaxThings()) {
            g_logger.traceError("ProtocolGame::setTileDescription: too many things, pos={}, stackpos={}", position, stackPos);
        }

        const auto& thing = getThing(msg);
        if (thing->isLocalPlayer()) {
            thing->static_self_cast<LocalPlayer>()->resetPreWalk();
        }

        g_map.addThing(thing, position, stackPos);
    }

    return 0;
}

Outfit ProtocolGame::getOutfit(const InputMessagePtr& msg, const bool parseMount/* = true*/) const
{
    Outfit outfit;

    uint16_t lookType = g_game.getFeature(Otc::GameLooktypeU16) ? msg->getU16() : msg->getU8();

    if (lookType != 0) {
        outfit.setCategory(ThingCategoryCreature);
        const uint8_t head = msg->getU8();
        const uint8_t body = msg->getU8();
        const uint8_t legs = msg->getU8();
        const uint8_t feet = msg->getU8();
        const uint8_t addons = g_game.getFeature(Otc::GamePlayerAddons) ? msg->getU8() : 0;

        if (!g_things.isValidDatId(lookType, ThingCategoryCreature)) {
            g_logger.traceError("invalid outfit looktype {}", lookType);
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
                g_logger.traceError("invalid outfit looktypeex {}", lookTypeEx);
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

    if (g_game.getFeature(Otc::GameWingsAurasEffectsShader) && parseMount) {
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
    if (id == 0) {
        throw Exception("ProtocolGame::getThing: invalid thing id");
    }

    if (id == Proto::UnknownCreature || id == Proto::OutdatedCreature || id == Proto::Creature) {
        return getCreature(msg, id);
    }

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
        if (const auto& thing = g_map.getThing(pos, stackpos)) {
            return thing;
        }

        g_logger.traceError("no thing at pos:{}, stackpos:{}", pos, stackpos);
    } else {
        const uint32_t creatureId = msg->getU32();
        if (const auto& thing = g_map.getCreatureById(creatureId)) {
            return thing;
        }

        g_logger.traceError("ProtocolGame::getMappedThing: no creature with id {}", creatureId);
    }

    return nullptr;
}

CreaturePtr ProtocolGame::getCreature(const InputMessagePtr& msg, int type) const
{
    if (type == 0) {
        type = msg->getU16();
    }

    CreaturePtr creature;
    const bool known = type != Proto::UnknownCreature;
    if (type == Proto::OutdatedCreature || type == Proto::UnknownCreature) {
        if (known) {
            const uint32_t creatureId = msg->getU32();
            creature = g_map.getCreatureById(creatureId);
            if (!creature) {
                g_logger.traceError("ProtocolGame::getCreature: server said that a creature is known, but it's not");
            }
        } else {
            const uint32_t removeId = msg->getU32();
            const uint32_t id = msg->getU32();

            if (id == removeId) {
                creature = g_map.getCreatureById(id);
            } else {
                g_map.removeCreatureById(removeId);
            }

            uint8_t creatureType;
            if (g_game.getClientVersion() >= 910) {
                creatureType = msg->getU8();
            } else {
                if (id >= Proto::PlayerStartId && id < Proto::PlayerEndId)
                    creatureType = Proto::CreatureTypePlayer;
                else if (id >= Proto::MonsterStartId && id < Proto::MonsterEndId)
                    creatureType = Proto::CreatureTypeMonster;
                else
                    creatureType = Proto::CreatureTypeNpc;
            }

            uint32_t masterId = 0;
            if (g_game.getClientVersion() >= 1281 && creatureType == Proto::CreatureTypeSummonOwn) {
                masterId = msg->getU32();
                if (m_localPlayer->getId() != masterId) {
                    creatureType = Proto::CreatureTypeSummonOther;
                }
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
                            g_logger.traceError("ProtocolGame::getCreature: creature type is invalid");
                    }

                    if (creature) {
                        creature->onCreate();
                    }
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
        const auto& outfit = getOutfit(msg);

        Light light;
        light.intensity = msg->getU8();
        light.color = msg->getU8();

        const uint16_t speed = msg->getU16();

        if (g_game.getClientVersion() >= 1281) {
            addCreatureIcon(msg);
        }

        const uint8_t skull = msg->getU8();
        const uint8_t shield = msg->getU8();

        // emblem is sent only when the creature is not known
        uint8_t emblem = 0;
        uint8_t creatureType = 0;
        uint8_t icon = 0;
        bool unpass = true;

        if (g_game.getFeature(Otc::GameCreatureEmblems) && !known) {
            emblem = msg->getU8();
        }

        if (g_game.getFeature(Otc::GameThingMarks)) {
            creatureType = msg->getU8();
        }

        uint32_t masterId = 0;
        if (g_game.getClientVersion() >= 1281) {
            if (creatureType == Proto::CreatureTypeSummonOwn) {
                masterId = msg->getU32();
                if (m_localPlayer->getId() != masterId) {
                    creatureType = Proto::CreatureTypeSummonOther;
                }
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
                if (mark == 0xff) {
                    creature->hideStaticSquare();
                } else {
                    creature->showStaticSquare(Color::from8bit(mark));
                }
            }
        }

        if (g_game.getClientVersion() >= 1281) {
            msg->getU8(); // inspection type
        }

        if (g_game.getClientVersion() >= 854) {
            unpass = static_cast<bool>(msg->getU8());
        }

        std::string shader;
        if (g_game.getFeature(Otc::GameCreatureShader)) {
            shader = msg->getString();
        }

        std::vector<uint16_t> attachedEffectList;
        if (g_game.getFeature(Otc::GameCreatureAttachedEffect)) {
            const uint8_t listSize = msg->getU8();
            for (auto i = -1; ++i < listSize;) {
                attachedEffectList.push_back(msg->getU16());
            }
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
            std::unordered_set<uint16_t> currentAttachedEffectIds;
            for (const auto& attachedEffect : creature->getAttachedEffects()) {
                currentAttachedEffectIds.insert(attachedEffect->getId());
            }

            for (const auto effectId : attachedEffectList) {
                const auto& effect = g_attachedEffects.getById(effectId);
                if (effect && currentAttachedEffectIds.find(effectId) == currentAttachedEffectIds.end()) {
                    const auto& clonedEffect = effect->clone();
                    clonedEffect->setPermanent(false);
                    creature->attachEffect(clonedEffect);
                }
            }

            if (emblem > 0) {
                creature->setEmblem(emblem);
            }

            if (creatureType > 0) {
                creature->setType(creatureType);
            }

            if (icon > 0) {
                creature->setIcon(icon);
            }

            if (creature == m_localPlayer && !m_localPlayer->isKnown()) {
                m_localPlayer->setKnown(true);
            }
        }
    } else if (type == Proto::Creature) {
        // this is send creature turn
        const uint32_t creatureId = msg->getU32();
        creature = g_map.getCreatureById(creatureId);
        if (!creature) {
            g_logger.traceError("ProtocolGame::getCreature: invalid creature");
        }

        const auto direction = static_cast<Otc::Direction>(msg->getU8());
        if (creature) {
            creature->turn(direction);
        }

        if (g_game.getClientVersion() >= 953) {
            const bool unpass = static_cast<bool>(msg->getU8());

            if (creature) {
                creature->setPassable(!unpass);
            }
        }
    } else {
        throw Exception("ProtocolGame::getCreature: invalid creature opcode");
    }

    return creature;
}

ItemPtr ProtocolGame::getItem(const InputMessagePtr& msg, int id)
{
    if (id == 0) {
        id = msg->getU16();
    }

    const auto& item = Item::create(id);

    if (!item) {
        throw Exception("ProtocolGame::getItem: unable to create item with invalid id {}", id);
    }

    if (item->getId() == 0) {
        throw Exception("ProtocolGame::getItem: unable to create item with invalid id {}", id);
    }

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
                case 1: // Loot Container
                    msg->getU32(); // loot category flags
                    break;
                case 2: // Content Counter
                    msg->getU32(); // ammo total
                    break;
                case 3: // Manager Unknown
                    msg->getU32(); // loot flags
                    msg->getU32(); // obtain flags
                    break;
                case 4: // Loot Highlight
                    break;
                case 8: // Obtain
                    msg->getU32(); // obtain flags
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
                const bool hasQuickLootFlags = static_cast<bool>(msg->getU8());
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
        if (item->getClassification()) {
            item->setTier(msg->getU8());
        }
    }

    if (g_game.getFeature(Otc::GameThingClock)) {
        if (item->hasClockExpire() || item->hasExpire() || item->hasExpireStop()) {
            if (item->getId() != 23398) {
                item->setDurationTime(msg->getU32());
                msg->getU8(); // Is brand-new
            }
        }
    }

    if (g_game.getFeature(Otc::GameThingCounter)) {
        if (item->hasWearOut()) {
            item->setCharges(msg->getU32());
            msg->getU8(); // Is brand-new
        }
    }

    if (g_game.getFeature(Otc::GameWrapKit)) {
        if (item->isDecoKit() || item->getId() == 23398) {
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

void ProtocolGame::parseShowDescription(const InputMessagePtr& msg)
{
    const uint32_t offerId = msg->getU32();
    const auto& offerdescription = msg->getString();

    g_lua.callGlobalField("g_game", "onParseStoreOfferDescriptions", offerId, offerdescription);
}

void ProtocolGame::parseBestiaryTracker(const InputMessagePtr& msg)
{
    const uint8_t trackerType = msg->getU8(); // 0x00 para bestiary, 0x01 para boss

    const uint8_t size = msg->getU8();
    std::vector<std::tuple<uint16_t, uint32_t, uint16_t, uint16_t, uint16_t, uint8_t>> trackerData;

    for (auto i = 0; i < size; ++i) {
        const uint16_t raceID = msg->getU16();
        const uint32_t killCount = msg->getU32();
        const uint16_t firstUnlock = msg->getU16();
        const uint16_t secondUnlock = msg->getU16();
        const uint16_t lastUnlock = msg->getU16();
        const uint8_t status = msg->getU8();
        trackerData.emplace_back(raceID, killCount, firstUnlock, secondUnlock, lastUnlock, status);
    }

    g_lua.callGlobalField("g_game", "onParseCyclopediaTracker", trackerType, trackerData);
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

void ProtocolGame::parseExperienceTracker(const InputMessagePtr& msg)
{
    msg->get64(); // raw exp
    msg->get64(); // final exp
}

void ProtocolGame::parseLootContainers(const InputMessagePtr& msg)
{
    const bool quickLootFallbackToMainContainer = static_cast<bool>(msg->getU8());

    const uint8_t containersCount = msg->getU8();
    std::vector<std::tuple<uint8_t, uint16_t, uint16_t>> lootList;

    for (auto i = 0; i < containersCount; ++i) {
        const uint8_t categoryType = msg->getU8();
        const uint16_t lootContainerId = msg->getU16();
        uint16_t obtainerContainerId = 0;
        if (g_game.getClientVersion() >= 1332) {
            obtainerContainerId = msg->getU16();
        }

        lootList.emplace_back(categoryType, lootContainerId, obtainerContainerId);
    }

    g_lua.callGlobalField("g_game", "onQuickLootContainers", quickLootFallbackToMainContainer, lootList);
}

void ProtocolGame::parseCyclopediaHouseAuctionMessage(const InputMessagePtr& msg)
{
    msg->getU32(); // houseId
    const uint8_t typeValue = msg->getU8();
    if (typeValue == 1) {
        msg->getU8(); // 0x00
    }
    msg->getU8(); // index
    // TO-DO Lua - Otui
}

void ProtocolGame::parseCyclopediaHousesInfo(const InputMessagePtr& msg)
{
    msg->getU32(); // houseClientId
    msg->getU8(); // 0x00

    msg->getU8(); // accountHouseCount

    msg->getU8(); // 0x00

    msg->getU8(); // 3
    msg->getU8(); // 3

    msg->getU8(); // 0x01

    msg->getU8(); // 0x01
    msg->getU32(); // houseClientId

    const uint16_t housesList = msg->getU16(); // g_game().map.houses.getHouses()
    for (auto i = 0; i < housesList; ++i) {
        msg->getU32(); // getClientId
    }
    // TO-DO Lua // Otui
}

void ProtocolGame::parseCyclopediaHouseList(const InputMessagePtr& msg)
{
    const uint16_t housesCount = msg->getU16(); // housesCount
    for (auto i = 0; i < housesCount; ++i) {
        msg->getU32(); // clientId
        msg->getU8(); // 0x00 = Renovation, 0x01 = Available

        const auto type = static_cast<Otc::CyclopediaHouseState_t>(msg->getU8());
        switch (type) {
            case Otc::CYCLOPEDIA_HOUSE_STATE_AVAILABLE: {
                std::string bidderName = msg->getString();
                const auto isBidder = static_cast<bool>(msg->getU8());
                msg->getU8(); // disableIndex

                if (!bidderName.empty()) {
                    msg->getU32(); // bidEndDate
                    msg->getU64(); // highestBid
                    if (isBidder) {
                        msg->getU64(); // bidHolderLimit
                    }
                }
                break;
            }
            case Otc::CYCLOPEDIA_HOUSE_STATE_RENTED: {
                msg->getString(); // ownerName
                msg->getU32(); // paidUntil

                const auto isRented = static_cast<bool>(msg->getU8());
                if (isRented) {
                    msg->getU8(); // unknown
                    msg->getU8(); // unknown
                }
                break;
            }
            case Otc::CYCLOPEDIA_HOUSE_STATE_TRANSFER: {
                msg->getString(); // ownerName
                msg->getU32(); // paidUntil
                const auto isOwner = static_cast<bool>(msg->getU8());
                if (isOwner) {
                    msg->getU8(); // unknown
                    msg->getU8(); // unknown
                }
                msg->getU32(); // bidEndDate
                msg->getString(); // bidderName
                msg->getU8(); // unknown
                msg->getU64(); // internalBid

                const auto isNewOwner = static_cast<bool>(msg->getU8());
                if (isNewOwner) {
                    msg->getU8(); // acceptTransferError
                    msg->getU8(); // rejectTransferError
                }

                if (isOwner) {
                    msg->getU8(); // cancelTransferError
                }
                break;
            }
            case Otc::CYCLOPEDIA_HOUSE_STATE_MOVEOUT: {
                msg->getString(); // ownerName
                msg->getU32(); // paidUntil

                const auto isOwner = static_cast<bool>(msg->getU8());
                if (isOwner) {
                    msg->getU8(); // unknown
                    msg->getU8(); // unknown
                    msg->getU32(); // bidEndDate
                    msg->getU8(); // unknown
                } else {
                    msg->getU32(); // bidEndDate
                }

                break;
            }
        }
    }
    // TO-DO Lua - Otui
}

void ProtocolGame::parseSupplyStash(const InputMessagePtr& msg)
{
    const uint16_t itemsCount = msg->getU16();
    std::vector<std::vector<uint32_t>> stashItems;

    for (auto i = 0; i < itemsCount; ++i) {
        uint16_t itemId = msg->getU16();
        uint32_t amount = msg->getU32();
        stashItems.push_back({ itemId, amount });
    }

    auto version = g_game.getProtocolVersion();
    if (version < 1412) {
        msg->getU16(); // free slots
    }

    g_lua.callGlobalField("g_game", "onSupplyStashEnter", stashItems);
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

    const bool hasNamesBool = static_cast<bool>(msg->getU8());
    if (hasNamesBool) {
        const uint8_t membersNameSize = msg->getU8();
        for (auto i = 0; i < membersNameSize; ++i) {
            msg->getU32(); // party member id
            msg->getString(); // party member name
        }
    }
}

void ProtocolGame::parseImbuementDurations(const InputMessagePtr& msg)
{
    const uint8_t itemListCount = msg->getU8(); // amount of items to display
    std::vector<ImbuementTrackerItem> itemList;

    for (auto i = 0; i < itemListCount; ++i) {
        ImbuementTrackerItem item(msg->getU8());
        item.item = getItem(msg);

        std::map<uint8_t, ImbuementSlot> slots;

        const uint8_t slotsCount = msg->getU8(); // total amount of imbuing slots on item
        for (auto slotIndex = 0; slotIndex < slotsCount; ++slotIndex) {
            const bool slotImbued = static_cast<bool>(msg->getU8()); // 0 - empty, 1 - imbued
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
        itemList.emplace_back(item);
    }

    g_lua.callGlobalField("g_game", "onUpdateImbuementTracker", itemList);
}

void ProtocolGame::parsePassiveCooldown(const InputMessagePtr& msg)
{
    msg->getU8(); // passive id

    const uint8_t unknownType = msg->getU8();
    if (unknownType == 0) {
        msg->getU32(); // timestamp (partial)
        msg->getU32(); // timestamp (total)
        msg->getU8(); // (bool) timer is running?
    } else if (unknownType == 1) {
        msg->getU8(); // unknown
        msg->getU8(); // unknown
    }
}

void ProtocolGame::parseClientCheck(const InputMessagePtr& msg)
{
    const uint32_t size = msg->getU32();
    for (uint32_t i = 0; i < size; ++i) {
        msg->getU8(); // unknown
    }
}

void ProtocolGame::parseGameNews(const InputMessagePtr& msg)
{
    msg->getU32(); // category id
    msg->getU8(); // page number

    // TODO: implement game news usage
}

void ProtocolGame::parseBlessDialog(const InputMessagePtr& msg)
{
    BlessDialogData data;

    data.totalBless = msg->getU8();
    for (auto i = 0; i < data.totalBless; ++i) {
        BlessData bless{};
        bless.blessBitwise = msg->getU16();
        bless.playerBlessCount = msg->getU8();
        bless.store = msg->getU8();
        data.blesses.emplace_back(bless);
    }

    data.premium = msg->getU8();
    data.promotion = msg->getU8();
    data.pvpMinXpLoss = msg->getU8();
    data.pvpMaxXpLoss = msg->getU8();
    data.pveExpLoss = msg->getU8();
    data.equipPvpLoss = msg->getU8();
    data.equipPveLoss = msg->getU8();
    data.skull = msg->getU8();
    data.aol = msg->getU8();

    const uint8_t logCount = msg->getU8();
    for (auto i = 0; i < logCount; ++i) {
        LogData log;
        log.timestamp = msg->getU32();
        log.colorMessage = msg->getU8();
        log.historyMessage = msg->getString();
        data.logs.emplace_back(log);
    }

    g_lua.callGlobalField("g_game", "onUpdateBlessDialog", data);
}

void ProtocolGame::parseRestingAreaState(const InputMessagePtr& msg)
{
    const uint8_t zone = msg->getU8();
    const uint8_t state = msg->getU8();
    const auto& message = msg->getString();

    g_lua.callGlobalField("g_game", "onRestingAreaState", zone, state, message);
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

void ProtocolGame::parseItemsPrice(const InputMessagePtr& msg)
{
    const uint16_t priceCount = msg->getU16(); // count

    for (auto i = 0; i < priceCount; ++i) {
        const uint16_t itemId = msg->getU16(); // item client id
        if (g_game.getClientVersion() >= 1281) {
            const auto& item = Item::create(itemId);

            // note: vanilla client allows made-up client ids
            // their classification is assumed as 0
            if (item && item->getId() != 0 && item->getClassification() > 0) {
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

void ProtocolGame::parseCyclopediaCharacterInfo(const InputMessagePtr& msg)
{
    const auto type = static_cast<Otc::CyclopediaCharacterInfoType_t>(msg->getU8());

    // 0: Send no error
    // 1: No data available at the moment.
    // 2: You are not allowed to see this character's data.
    // 3: You are not allowed to inspect this character.
    const uint8_t errorCode = msg->getU8();
    if (errorCode > 0) {
        return;
    }

    switch (type) {
        case Otc::CYCLOPEDIA_CHARACTERINFO_BASEINFORMATION:
        {
            msg->getString(); // player name
            msg->getString(); // player vocation name
            msg->getU16(); // player level
            getOutfit(msg, false);
            msg->getU8(); // ???
            if (g_game.getFeature(Otc::GameTournamentPackets)) {
                msg->getU8(); // ???
            }
            msg->getString(); // current title name
            break;
        }
        case Otc::CYCLOPEDIA_CHARACTERINFO_GENERALSTATS:
        {
            CyclopediaCharacterGeneralStats stats;
            stats.experience = msg->getU64();
            stats.level = msg->getU16();
            stats.levelPercent = msg->getU8();
            stats.baseExpGain = msg->getU16();
            if (g_game.getFeature(Otc::GameTournamentPackets)) {
                msg->getU32(); // tournament exp(deprecated)
            }
            stats.lowLevelExpBonus = msg->getU16();
            stats.XpBoostPercent = msg->getU16();
            stats.staminaExpBonus = msg->getU16();
            stats.XpBoostBonusRemainingTime = msg->getU16();
            stats.canBuyXpBoost = msg->getU8();
            stats.health = msg->getU32();
            stats.maxHealth = msg->getU32();
            stats.mana = msg->getU32();
            stats.maxMana = msg->getU32();
            stats.soul = msg->getU8();
            stats.staminaMinutes = msg->getU16();
            stats.regenerationCondition = msg->getU16();
            stats.offlineTrainingTime = msg->getU16();
            stats.speed = msg->getU16();
            stats.baseSpeed = msg->getU16();
            stats.capacity = msg->getU32();
            stats.baseCapacity = msg->getU32();
            stats.freeCapacity = msg->getU32();
            msg->getU8();
            msg->getU8();
            stats.magicLevel = msg->getU16();
            stats.baseMagicLevel = msg->getU16();
            stats.loyaltyMagicLevel = msg->getU16();
            stats.magicLevelPercent = msg->getU16();

            std::vector<std::vector<uint16_t>> skills;

            for (int_fast32_t skill = Otc::Fist; skill <= Otc::Fishing; ++skill) {
                msg->getU8(); // Hardcoded Skill Ids
                const uint16_t skillLevel = msg->getU16();
                const uint16_t baseSkill = msg->getU16();
                msg->getU16(); // base + loyalty bonus(?)
                const uint16_t skillPercent = msg->getU16() / 100;
                skills.push_back({ skillLevel, baseSkill, skillPercent });
            }

            const uint8_t combatCount = msg->getU8();
            std::vector<std::tuple<uint8_t, uint16_t>> combats;

            for (auto i = 0; i < combatCount; ++i) {
                const uint8_t element = msg->getU8();
                const uint16_t specializedMagicLevel = msg->getU16();
                combats.emplace_back(element, specializedMagicLevel);
            }

            g_game.processCyclopediaCharacterGeneralStats(stats, skills, combats);
            break;
        }
        case Otc::CYCLOPEDIA_CHARACTERINFO_COMBATSTATS:
        {
            std::vector<std::vector<uint16_t>> additionalSkillsArray;

            if (g_game.getFeature(Otc::GameAdditionalSkills)) {
                // Critical, Life Leech, Mana Leech
                for (uint16_t skill = Otc::CriticalChance; skill <= Otc::ManaLeechAmount; ++skill) {
                    if (!g_game.getFeature(Otc::GameLeechAmount)) {
                        if (skill == Otc::LifeLeechAmount || skill == Otc::ManaLeechAmount) {
                            continue;
                        }
                    }

                    const uint16_t skillLevel = msg->getU16();
                    msg->getU16();
                    additionalSkillsArray.push_back({ skill, skillLevel });
                }
            }

            std::vector<std::vector<uint16_t>> forgeSkillsArray;

            if (g_game.getClientVersion() >= 1281) {
                // forge skill stats
                const uint8_t lastSkill = g_game.getClientVersion() >= 1332 ? Otc::LastSkill : Otc::Momentum + 1;
                for (uint16_t skill = Otc::Fatal; skill < lastSkill; ++skill) {
                    const uint16_t skillLevel = msg->getU16();
                    msg->getU16();
                    forgeSkillsArray.push_back({ skill, skillLevel });
                }
            }

            msg->getU16(); // Cleave Percent
            msg->getU16(); // Magic Shield Capacity Flat
            msg->getU16(); // Magic Shield Capacity Percent

            std::vector<uint16_t> perfectShotDamageRangesArray;

            for (auto i = 1; i <= 5; i++) {
                const uint16_t perfectShotDamageRange = msg->getU16();
                perfectShotDamageRangesArray.emplace_back(perfectShotDamageRange);
            }

            msg->getU16(); // Damage reflection

            CyclopediaCharacterCombatStats data;
            data.haveBlessings = msg->getU8();
            msg->getU8(); // total blessings

            data.weaponMaxHitChance = msg->getU16();
            data.weaponElement = msg->getU8();
            data.weaponElementDamage = msg->getU8();
            data.weaponElementType = msg->getU8();
            data.armor = msg->getU16();
            data.defense = msg->getU16();
            const double mitigation = msg->getDouble();

            const uint8_t combatCount = msg->getU8();
            std::vector<std::tuple<uint8_t, uint16_t>> combatsArray;

            for (auto i = 0; i < combatCount; ++i) {
                const uint8_t element = msg->getU8();
                const uint16_t clientModifier = msg->getU16();
                combatsArray.emplace_back(element, clientModifier);
            }

            const uint8_t concoctionsCount = msg->getU8();
            std::vector<std::tuple<uint16_t, uint16_t>> concoctionsArray;

            for (auto i = 0; i < concoctionsCount; ++i) {
                const uint16_t concoctionFirst = msg->getU16();
                const uint16_t concoctionSecond = msg->getU16();
                concoctionsArray.emplace_back(concoctionFirst, concoctionSecond);
            }

            g_game.processCyclopediaCharacterCombatStats(data, mitigation, additionalSkillsArray, forgeSkillsArray, perfectShotDamageRangesArray, combatsArray, concoctionsArray);
            break;
        }
        case Otc::CYCLOPEDIA_CHARACTERINFO_RECENTDEATHS:
        {
            CyclopediaCharacterRecentDeaths data;
            msg->getU16();
            msg->getU16();

            const uint16_t entriesCount = msg->getU16();
            for (auto i = 0; i < entriesCount; ++i) {
                RecentDeathEntry entry;
                entry.timestamp = msg->getU32();
                entry.cause = msg->getString();
                data.entries.emplace_back(entry);
            }

            g_game.processCyclopediaCharacterRecentDeaths(data);
            break;
        }
        case Otc::CYCLOPEDIA_CHARACTERINFO_RECENTPVPKILLS:
        {
            CyclopediaCharacterRecentPvPKills data;
            msg->getU16();
            msg->getU16();

            const uint16_t entriesCount = msg->getU16();
            for (auto i = 0; i < entriesCount; ++i) {
                RecentPvPKillEntry entry;
                entry.timestamp = msg->getU32();
                entry.description = msg->getString();
                entry.status = msg->getU8();
                data.entries.emplace_back(entry);
            }

            g_game.processCyclopediaCharacterRecentPvpKills(data);
            break;
        }
        case Otc::CYCLOPEDIA_CHARACTERINFO_ACHIEVEMENTS:
        {
            break;
        }
        case Otc::CYCLOPEDIA_CHARACTERINFO_ITEMSUMMARY:
        {
            CyclopediaCharacterItemSummary data;

            const uint16_t inventoryItemsCount = msg->getU16();
            for (auto i = 0; i < inventoryItemsCount; ++i) {
                ItemSummary item;
                const uint16_t itemId = msg->getU16();
                const auto& itemCreated = Item::create(itemId);
                const uint16_t classification = itemCreated->getClassification();

                uint8_t itemTier = 0;
                if (classification > 0) {
                    itemTier = msg->getU8();
                }

                item.itemId = itemId;
                item.tier = itemTier;
                item.amount = msg->getU32();
                data.inventory.emplace_back(item);
            }

            const uint16_t storeItemsCount = msg->getU16();
            for (auto i = 0; i < storeItemsCount; ++i) {
                ItemSummary item;
                const uint16_t itemId = msg->getU16();
                const auto& itemCreated = Item::create(itemId);
                const uint16_t classification = itemCreated->getClassification();

                uint8_t itemTier = 0;
                if (classification > 0) {
                    itemTier = msg->getU8();
                }

                item.itemId = itemId;
                item.tier = itemTier;
                item.amount = msg->getU32();
                data.store.emplace_back(item);
            }

            const uint16_t stashItemsCount = msg->getU16();
            for (auto i = 0; i < stashItemsCount; ++i) {
                ItemSummary item;
                const uint16_t itemId = msg->getU16();
                const auto& thing = g_things.getThingType(itemId, ThingCategoryItem);
                if (!thing) {
                    continue;
                }
                const uint16_t classification = thing->getClassification();
                uint8_t itemTier = 0;
                if (classification > 0) {
                    itemTier = msg->getU8();
                }

                item.itemId = itemId;
                item.tier = itemTier;
                item.amount = msg->getU32();
                data.stash.emplace_back(item);
            }

            const uint16_t depotItemsCount = msg->getU16();
            for (auto i = 0; i < depotItemsCount; ++i) {
                ItemSummary item;
                const uint16_t itemId = msg->getU16();
                const auto& itemCreated = Item::create(itemId);
                const uint16_t classification = itemCreated->getClassification();

                uint8_t itemTier = 0;
                if (classification > 0) {
                    itemTier = msg->getU8();
                }

                item.itemId = itemId;
                item.tier = itemTier;
                item.amount = msg->getU32();
                data.depot.emplace_back(item);
            }

            const uint16_t inboxItemsCount = msg->getU16();
            for (auto i = 0; i < inboxItemsCount; ++i) {
                ItemSummary item;
                const uint16_t itemId = msg->getU16();
                const auto& itemCreated = Item::create(itemId);
                const uint16_t classification = itemCreated->getClassification();

                uint8_t itemTier = 0;
                if (classification > 0) {
                    itemTier = msg->getU8();
                }

                item.itemId = itemId;
                item.tier = itemTier;
                item.amount = msg->getU32();
                data.inbox.emplace_back(item);
            }

            g_game.processCyclopediaCharacterItemSummary(data);
            break;
        }
        case Otc::CYCLOPEDIA_CHARACTERINFO_OUTFITSMOUNTS:
        {
            const uint16_t outfitsSize = msg->getU16();
            std::vector<CharacterInfoOutfits> outfits;

            for (auto i = 0; i < outfitsSize; ++i) {
                CharacterInfoOutfits outfit;
                outfit.lookType = msg->getU16();
                outfit.name = msg->getString();
                outfit.addons = msg->getU8();
                outfit.type = msg->getU8(); // store / quest / none
                outfit.isCurrent = msg->getU32(); // 1000 = true / 0 = false
                outfits.emplace_back(outfit);
            }

            OutfitColorStruct currentOutfit;
            if (outfitsSize > 0) {
                currentOutfit.lookHead = msg->getU8();
                currentOutfit.lookBody = msg->getU8();
                currentOutfit.lookLegs = msg->getU8();
                currentOutfit.lookFeet = msg->getU8();
            }

            const uint16_t mountsSize = msg->getU16();
            std::vector<CharacterInfoMounts> mounts;

            for (auto i = 0; i < mountsSize; ++i) {
                CharacterInfoMounts mount;
                mount.mountId = msg->getU16();
                mount.name = msg->getString();
                mount.type = msg->getU8(); // store / quest / none
                mount.isCurrent = msg->getU32(); // 1000 = true / 0 = false
                mounts.emplace_back(mount);
            }

            if (mountsSize > 0) {
                currentOutfit.lookMountHead = msg->getU8();
                currentOutfit.lookMountBody = msg->getU8();
                currentOutfit.lookMountLegs = msg->getU8();
                currentOutfit.lookMountFeet = msg->getU8();
            }

            const uint16_t familiarsSize = msg->getU16();
            std::vector<CharacterInfoFamiliar> familiars;

            for (auto i = 0; i < familiarsSize; ++i) {
                CharacterInfoFamiliar familiar;
                familiar.lookType = msg->getU16();
                familiar.name = msg->getString();
                familiar.type = msg->getU8(); // quest / none
                familiar.isCurrent = msg->getU32(); // 1000 = true / 0 = false
                familiars.emplace_back(familiar);
            }

            g_game.processCyclopediaCharacterAppearances(currentOutfit, outfits, mounts, familiars);
            break;
        }
        case Otc::CYCLOPEDIA_CHARACTERINFO_STORESUMMARY:
        {
            const uint32_t xpBoostTime = msg->getU32();
            const uint32_t dailyRewardXpBoostTime = msg->getU32();

            std::vector<std::tuple<std::string, uint8_t>> blessings;
            const uint8_t blessingCount = msg->getU8();

            for (auto i = 0; i < blessingCount; ++i) {
                const auto& blessingName = msg->getString();
                const uint8_t blessingObtained = msg->getU8();
                blessings.emplace_back(blessingName, blessingObtained);
            }

            const uint8_t preySlotsUnlocked = msg->getU8();
            const uint8_t preyWildcards = msg->getU8();
            const uint8_t instantRewards = msg->getU8();
            const bool hasCharmExpansion = static_cast<bool>(msg->getU8());
            const uint8_t hirelingsObtained = msg->getU8();

            std::vector<uint16_t> hirelingSkills;
            const uint8_t hirelingSkillsCount = msg->getU8();

            for (auto i = 0; i < hirelingSkillsCount; ++i) {
                const uint8_t skill = msg->getU8();
                hirelingSkills.emplace_back(static_cast<uint16_t>(skill + 1000));
            }

            msg->getU8();

            std::vector<std::tuple<uint16_t, std::string, uint8_t>> houseItems;
            const uint16_t houseItemsCount = msg->getU16();

            for (auto i = 0; i < houseItemsCount; ++i) {
                const uint16_t itemId = msg->getU16();
                const auto& itemName = msg->getString();
                const uint8_t count = msg->getU8();
                houseItems.emplace_back(itemId, itemName, count);
            }
            g_lua.callGlobalField("g_game", "onParseCyclopediaStoreSummary", xpBoostTime, dailyRewardXpBoostTime, blessings, preySlotsUnlocked, preyWildcards, instantRewards, hasCharmExpansion, hirelingsObtained, hirelingSkills, houseItems);
            break;
        }
        case Otc::CYCLOPEDIA_CHARACTERINFO_INSPECTION:
        {
            break;
        }
        case Otc::CYCLOPEDIA_CHARACTERINFO_BADGES:
        {
            const uint8_t showAccountInformation = msg->getU8();
            const uint8_t playerOnline = msg->getU8();
            const uint8_t playerPremium = msg->getU8();
            const auto& loyaltyTitle = msg->getString();

            const uint8_t badgesSize = msg->getU8();
            std::vector<std::tuple<uint32_t, std::string>> badgesVector;

            for (auto i = 0; i < badgesSize; ++i) {
                const uint32_t badgeId = msg->getU32();
                const auto& badgeName = msg->getString();
                badgesVector.emplace_back(badgeId, badgeName);
            }

            g_game.processCyclopediaCharacterGeneralStatsBadge(showAccountInformation, playerOnline, playerPremium, loyaltyTitle, badgesVector);
            break;
        }
        case Otc::CYCLOPEDIA_CHARACTERINFO_TITLES:
        {
            msg->getU8(); // current title
            const uint8_t titlesSize = msg->getU8();
            for (auto i = 0; i < titlesSize; ++i) {
                msg->getString(); // title name
                msg->getString(); // title description
                msg->getU8(); // bool title permanent
                msg->getU8(); // bool title unlocked
            }
            break;
        }
    }
}

void ProtocolGame::parseDailyRewardCollectionState(const InputMessagePtr& msg)
{
    const uint8_t state = msg->getU8();
    g_lua.callGlobalField("g_game", "onDailyRewardCollectionState", state);
}

void ProtocolGame::parseOpenRewardWall(const InputMessagePtr& msg)
{
    const uint8_t bonusShrine = msg->getU8(); // bonus shrine (1) or instant bonus (0)
    const uint32_t nextRewardTime = msg->getU32(); // next reward time
    const uint8_t dayStreakDay = msg->getU8(); // day streak day

    const uint8_t wasDailyRewardTaken = msg->getU8();
    uint16_t tokens = 0;
    std::string errorMessage = "";
    uint32_t timeLeft = 0;

    if (wasDailyRewardTaken != 0) {// taken (player already took reward?)
        errorMessage = msg->getString(); // error message
        const uint8_t token = msg->getU8();
        if (token != 0) {
            tokens = msg->getU16(); // Tokens
        }
    } else {
        msg->getU8(); // Unknown
        timeLeft = msg->getU32(); // time left to pickup reward without loosing streak
        tokens = msg->getU16(); // Tokens
    }

    const uint16_t dayStreakLevel = msg->getU16(); // day streak level

    g_lua.callGlobalField("g_game", "onOpenRewardWall", bonusShrine, nextRewardTime, dayStreakDay,
                          wasDailyRewardTaken, errorMessage, tokens, timeLeft, dayStreakLevel);
}

namespace {
    DailyRewardDay parseRewardDay(const InputMessagePtr& msg)
    {
        DailyRewardDay day;
        day.redeemMode = msg->getU8(); // reward type
        day.itemsToSelect = 0; // reward type
        if (day.redeemMode == 1) {
            // select x items from the list
            day.itemsToSelect = msg->getU8(); // reward type
            const uint8_t itemListSize = msg->getU8();
            for (auto listIndex = 0; listIndex < itemListSize; ++listIndex) {
                DailyRewardItem item;
                item.itemId = msg->getU16(); // Item ID
                item.name = msg->getString(); // Item name
                item.weight = msg->getU32(); // Item weight
                day.selectableItems.emplace_back(item);
            }
        } else if (day.redeemMode == 2) {
            // no choice, click to redeem all
            const uint8_t itemListSize = msg->getU8();
            for (auto listIndex = 0; listIndex < itemListSize; ++listIndex) {
                const uint8_t bundleType = msg->getU8(); // type of reward
                DailyRewardBundle bundle;
                bundle.bundleType = bundleType;

                switch (bundleType) {
                    case 1: {
                        // Items
                        bundle.itemId = msg->getU16(); // Item ID
                        bundle.name = msg->getString(); // Item name
                        bundle.count = msg->getU8(); // Item Count
                        break;
                    }
                    case 2: {
                        // Prey Wildcards
                        bundle.itemId = 0;
                        bundle.name = "Prey Wildcards";
                        bundle.count = msg->getU8(); // Prey Wildcards Count
                        break;
                    }
                    case 3: {
                        // XP Boost
                        bundle.itemId = msg->getU16(); // XP Boost Minutes
                        bundle.name = "XP Boost";
                        bundle.count = 0;
                        break;
                    }
                    default:
                        // Invalid type
                        break;
                }
                day.bundleItems.emplace_back(bundle);
            }
        }

        return day;
    }
}

void ProtocolGame::parseDailyReward(const InputMessagePtr& msg)
{
    DailyRewardData data;
    data.days = msg->getU8(); // Reward count (7 days)

    for (auto i = 1; i <= data.days; ++i) {
        data.freeRewards.push_back(parseRewardDay(msg)); // Free account
        data.premiumRewards.push_back(parseRewardDay(msg)); // Premium account
    }

    const uint8_t bonusCount = msg->getU8();
    for (auto i = 0; i < bonusCount; ++i) {
        DailyRewardBonus bonus;
        bonus.name = msg->getString(); // Bonus name
        bonus.id = msg->getU8(); // Bonus ID
        data.bonuses.push_back(bonus);
    }

    data.maxUnlockableDragons = msg->getU8(); // max unlockable "dragons" for free accounts

    g_lua.callGlobalField("g_game", "onDailyReward", data);
}

void ProtocolGame::parseRewardHistory(const InputMessagePtr& msg)
{
    const uint8_t historyCount = msg->getU8();
    std::vector<std::tuple<uint32_t, bool, std::string, uint16_t>> rewardHistory;
    for (auto i = 0; i < historyCount; ++i) {
        const uint32_t timestamp = msg->getU32();
        const bool isPremium = static_cast<bool>(msg->getU8());
        const auto& description = msg->getString();
        const uint32_t daystreak = msg->getU16();
        rewardHistory.emplace_back(timestamp, isPremium, description, daystreak);
    }

    g_lua.callGlobalField("g_game", "onRewardHistory", rewardHistory);
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
    return { .name = name, .outfit = outfit };
}

std::vector<PreyMonster> ProtocolGame::getPreyMonsters(const InputMessagePtr& msg)
{
    const uint8_t monsterListCount = msg->getU8();
    std::vector<PreyMonster> monsterList;

    for (auto i = 0; i < monsterListCount; ++i) {
        const auto& monster = getPreyMonster(msg);
        monsterList.emplace_back(monster);
    }

    return monsterList;
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
            const auto unlockState = static_cast<Otc::PreyUnlockState_t>(msg->getU8()); // prey slot unlocked
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
            const auto& monster = getPreyMonster(msg);
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
            const auto& monsters = getPreyMonsters(msg);
            std::vector<std::string> monsterNames;
            std::vector<Outfit> monsterLooktypes;

            for (const auto& monster : monsters) {
                monsterNames.push_back(monster.name);
                monsterLooktypes.push_back(monster.outfit);
            }

            if (g_game.getClientVersion() > 1149) { // correct unconfirmed version
                nextFreeReroll = msg->getU32();
                wildcards = msg->getU8();
            } else {
                nextFreeReroll = msg->getU16();
            }
            return g_lua.callGlobalField("g_game", "onPreySelection", slot, monsterNames, monsterLooktypes, nextFreeReroll, wildcards);
        }
        case Otc::PREY_STATE_SELECTION_CHANGE_MONSTER:
        {
            const uint8_t bonusType = msg->getU8(); // bonus type
            const uint16_t bonusValue = msg->getU16(); // bonus value
            const uint8_t bonusGrade = msg->getU8(); // bonus grade

            const auto& monsters = getPreyMonsters(msg);
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
            const uint16_t raceListCount = msg->getU16();
            std::vector<uint16_t> raceList;

            for (auto i = 0; i < raceListCount; ++i) {
                raceList.push_back(msg->getU16()); // RaceID
            }

            if (g_game.getClientVersion() > 1149) { // correct unconfirmed version
                nextFreeReroll = msg->getU32();
                wildcards = msg->getU8();
            } else {
                nextFreeReroll = msg->getU16();
            }
            return g_lua.callGlobalField("g_game", "onPreyListSelection", slot, raceList, nextFreeReroll, wildcards);
        }
        case Otc::PREY_STATE_WILDCARD_SELECTION:
        {
            msg->getU8(); // bonus type
            msg->getU16(); // bonus value
            msg->getU8(); // bonus grade

            const uint16_t raceListCount = msg->getU16();
            std::vector<uint16_t> raceList;

            for (auto i = 0; i < raceListCount; ++i) {
                raceList.push_back(msg->getU16()); // RaceID
            }

            if (g_game.getClientVersion() > 1149) { // correct unconfirmed version
                nextFreeReroll = msg->getU32();
                wildcards = msg->getU8();
            } else {
                nextFreeReroll = msg->getU16();
            }
            return g_lua.callGlobalField("g_game", "onPreyWildcardSelection", slot, raceList, nextFreeReroll, wildcards);
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
        const auto& item = Item::create(id);
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
    const auto& item = Item::create(itemId);

    if (!item) {
        throw Exception("ProtocolGame::parseImbuementWindow: unable to create item with invalid id {}", itemId);
    }

    if (item->getId() == 0) {
        throw Exception("ProtocolGame::parseImbuementWindow: unable to create item with invalid id {}", itemId);
    }

    if (item->getClassification() > 0) {
        msg->getU8(); // upgradeClass
    }

    const uint8_t slot = msg->getU8();
    std::unordered_map<int, std::tuple<Imbuement, uint32_t, uint32_t>> activeSlots;

    for (auto i = 0; i < slot; i++) {
        const uint8_t firstByte = msg->getU8();
        if (firstByte == 0x01) {
            Imbuement imbuement = getImbuementInfo(msg);
            const uint32_t duration = msg->getU32();
            const uint32_t removalCost = msg->getU32();
            activeSlots[i] = std::make_tuple(imbuement, duration, removalCost);
        }
    }

    const uint16_t imbuementsSize = msg->getU16();
    std::vector<Imbuement> imbuements;

    for (auto i = 0; i < imbuementsSize; ++i) {
        imbuements.push_back(getImbuementInfo(msg));
    }

    const uint32_t neededItemsListCount = msg->getU32();
    std::vector<ItemPtr> neededItemsList;
    neededItemsList.reserve(neededItemsListCount);

    for (uint32_t i = 0; i < neededItemsListCount; ++i) {
        const uint16_t needItemId = msg->getU16();
        const uint16_t count = msg->getU16();
        const auto& needItem = Item::create(needItemId);
        needItem->setCount(count);
        neededItemsList.push_back(needItem);
    }

    g_lua.callGlobalField("g_game", "onImbuementWindow", itemId, slot, activeSlots, imbuements, neededItemsList);
}

void ProtocolGame::parseCloseImbuementWindow(const InputMessagePtr& /*msg*/)
{
    g_lua.callGlobalField("g_game", "onCloseImbuementWindow");
}

void ProtocolGame::parseError(const InputMessagePtr& msg)
{
    const uint8_t code = msg->getU8();
    const auto& error = msg->getString();
    g_lua.callGlobalField("g_game", "onServerError", code, error);
}

void ProtocolGame::parseMarketEnter(const InputMessagePtr& msg)
{
    const uint8_t offers = msg->getU8();

    const uint16_t itemsSentCount = msg->getU16();
    std::vector<std::vector<uint16_t>> depotItems;

    for (auto i = 0; i < itemsSentCount; ++i) {
        const uint16_t itemId = msg->getU16();
        const auto& item = Item::create(itemId);

        uint8_t itemClass = 0;
        if (item && item->getClassification() > 0) {
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

    std::vector<std::vector<uint16_t>> depotItems;
    for (auto i = 0; i < itemsSent; ++i) {
        const uint16_t itemId = msg->getU16();
        const uint16_t count = msg->getU16();
        depotItems.push_back({ itemId, count });
    }

    g_lua.callGlobalField("g_game", "onMarketEnter", depotItems, offers, balance, vocation);
}

void ProtocolGame::parseMarketDetail(const InputMessagePtr& msg)
{
    const uint16_t itemId = msg->getU16();
    if (g_game.getClientVersion() >= 1281) {
        const auto& item = Item::create(itemId);
        if (item && item->getClassification() > 0) {
            msg->getU8(); // ?
        }
    }

    std::unordered_map<int, std::string> descriptions;

    Otc::MarketItemDescription lastAttribute = Otc::ITEM_DESC_WEIGHT;
    if (g_game.getClientVersion() >= 1100) {
        lastAttribute = Otc::ITEM_DESC_IMBUINGSLOTS;
    }

    if (g_game.getClientVersion() >= 1270) {
        lastAttribute = Otc::ITEM_DESC_UPGRADECLASS;
    }

    if (g_game.getClientVersion() >= 1282) {
        lastAttribute = Otc::ITEM_DESC_LAST;
    }

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

    const uint8_t purchaseStatsListCount = msg->getU8();
    std::vector<std::vector<uint64_t>> purchaseStatsList;

    for (auto i = 0; i < purchaseStatsListCount; ++i) {
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
        purchaseStatsList.push_back({ tmp, Otc::MARKETACTION_BUY, transactions, totalPrice, highestPrice, lowestPrice });
    }

    const uint8_t saleStatsListCount = msg->getU8();
    std::vector<std::vector<uint64_t>> saleStatsList;

    for (auto i = 0; i < saleStatsListCount; ++i) {
        const uint32_t transactions = msg->getU32();
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
        saleStatsList.push_back({ tmp, Otc::MARKETACTION_SELL, transactions, totalPrice, highestPrice, lowestPrice });
    }

    g_lua.callGlobalField("g_game", "onMarketDetail", itemId, descriptions, purchaseStatsList, saleStatsList);
}

MarketOffer ProtocolGame::readMarketOffer(const InputMessagePtr& msg, const uint8_t action, const uint16_t var)
{
    const uint32_t timestamp = msg->getU32();
    const uint16_t counter = msg->getU16();
    uint16_t itemId = 0;
    if (var == Otc::OLD_MARKETREQUEST_MY_OFFERS || var == Otc::MARKETREQUEST_OWN_OFFERS || var == Otc::OLD_MARKETREQUEST_MY_HISTORY || var == Otc::MARKETREQUEST_OWN_HISTORY) {
        itemId = msg->getU16();
        if (g_game.getClientVersion() >= 1281) {
            const auto& item = Item::create(itemId);
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
    return { .timestamp = timestamp, .counter = counter, .action = action, .itemId = itemId, .amount = amount, .price = price,
        .playerName = playerName, .state = state, .var = var
    };
}

void ProtocolGame::parseMarketBrowse(const InputMessagePtr& msg)
{
    uint16_t var = 0;
    if (g_game.getClientVersion() >= 1281) {
        var = msg->getU8();
        if (var == 3) {
            var = msg->getU16();
            const auto& item = Item::create(var);
            if (item && item->getClassification() > 0) {
                msg->getU8();
            }
        }
    } else {
        var = msg->getU16();
    }

    const uint32_t buyOfferCount = msg->getU32();

    std::vector<MarketOffer> offers;

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
    BosstiarySlotsData data;

    auto getBosstiarySlot = [&msg]() -> BosstiarySlot {
        BosstiarySlot slot;
        slot.bossRace = msg->getU8();
        slot.killCount = msg->getU32();
        slot.lootBonus = msg->getU16();
        slot.killBonus = msg->getU8();
        slot.bossRaceRepeat = msg->getU8();
        slot.removePrice = msg->getU32();
        slot.inactive = msg->getU8();
        return slot;
    };

    data.playerPoints = msg->getU32();
    data.totalPointsNextBonus = msg->getU32();
    data.currentBonus = msg->getU16();
    data.nextBonus = msg->getU16();

    data.isSlotOneUnlocked = msg->getU8();
    data.bossIdSlotOne = msg->getU32();
    if (data.isSlotOneUnlocked && data.bossIdSlotOne != 0) {
        data.slotOneData = getBosstiarySlot();
    }

    data.isSlotTwoUnlocked = msg->getU8();
    data.bossIdSlotTwo = msg->getU32();
    if (data.isSlotTwoUnlocked && data.bossIdSlotTwo != 0) {
        data.slotTwoData = getBosstiarySlot();
    }

    data.isTodaySlotUnlocked = msg->getU8();
    data.boostedBossId = msg->getU32();
    if (data.isTodaySlotUnlocked && data.boostedBossId != 0) {
        data.todaySlotData = getBosstiarySlot();
    }

    data.bossesUnlocked = msg->getU8();
    if (data.bossesUnlocked) {
        const uint16_t bossesUnlockedSize = msg->getU16();
        for (auto i = 0; i < bossesUnlockedSize; ++i) {
            BossUnlocked boss;
            boss.bossId = msg->getU32();
            boss.bossRace = msg->getU8();
            data.bossesUnlockedData.emplace_back(boss);
        }
    }

    g_game.processBosstiarySlots(data);
}

void ProtocolGame::parseBosstiaryCooldownTimer(const InputMessagePtr& msg)
{
    const uint16_t bossesOnTrackerSize = msg->getU16();
    for (auto i = 0; i < bossesOnTrackerSize; ++i) {
        msg->getU32(); // bossRaceId
        msg->getU64(); // Boss cooldown in seconds
    }
}

void ProtocolGame::parseBosstiaryEntryChanged(const InputMessagePtr& msg)
{
    msg->getU32(); // bossId
}

void ProtocolGame::parseTakeScreenshot(const InputMessagePtr& msg)
{
    const uint8_t screenshotType = msg->getU8();
    m_localPlayer->takeScreenshot(screenshotType);
}

void ProtocolGame::parseAttachedEffect(const InputMessagePtr& msg)
{
    const uint32_t creatureId = msg->getU32();
    const uint16_t attachedEffectId = msg->getU16();

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError("ProtocolGame::parseAttachedEffect: could not get creature with id {}", creatureId);
        return;
    }

    const auto& effect = g_attachedEffects.getById(attachedEffectId);
    if (!effect) {
        return;
    }

    creature->attachEffect(effect->clone());
}

void ProtocolGame::parseDetachEffect(const InputMessagePtr& msg)
{
    const uint32_t creatureId = msg->getU32();
    const uint16_t attachedEffectId = msg->getU16();

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError("ProtocolGame::parseDetachEffect: could not get creature with id {}", creatureId);
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
        g_logger.traceError("ProtocolGame::parseCreatureShader: could not get creature with id {}", creatureId);
        return;
    }

    creature->setShader(shaderName);
}

void ProtocolGame::parseMapShader(const InputMessagePtr& msg)
{
    const auto& shaderName = msg->getString();

    const auto& mapView = g_map.getMapView(0);
    if (mapView) {
        mapView->setShader(shaderName, 0.f, 0.f);
    }
}

void ProtocolGame::parseCreatureTyping(const InputMessagePtr& msg)
{
    const uint32_t creatureId = msg->getU32();
    const bool typing = static_cast<bool>(msg->getU8());

    const auto& creature = g_map.getCreatureById(creatureId);
    if (!creature) {
        g_logger.traceError("ProtocolGame::parseCreatureTyping: could not get creature with id {}", creatureId);
        return;
    }

    creature->setTyping(typing);
}

void ProtocolGame::parseFeatures(const InputMessagePtr& msg)
{
    const uint16_t features = msg->getU16();
    for (auto i = 0; i < features; ++i) {
        const auto feature = static_cast<Otc::GameFeature>(msg->getU8());
        const auto enabled = static_cast<bool>(msg->getU8());
        if (enabled) {
            g_game.enableFeature(feature);
        } else {
            g_game.disableFeature(feature);
        }
    }
}

void ProtocolGame::parseHighscores(const InputMessagePtr& msg)
{
    const bool isEmpty = static_cast<bool>(msg->getU8());
    if (isEmpty) {
        return;
    }

    msg->getU8(); // skip (0x01)
    const auto& serverName = msg->getString();
    const auto& world = msg->getString();
    const uint8_t worldType = msg->getU8();
    const uint8_t battlEye = msg->getU8();

    const uint8_t sizeVocation = msg->getU8();
    std::vector<std::tuple<uint32_t, std::string>> vocations;

    msg->getU32(); // skip 0xFFFFFFFF
    msg->getString(); // skip "All vocations"

    for (auto i = 0; i < sizeVocation - 1; ++i) {
        const uint32_t vocationID = msg->getU32();
        const auto& vocationName = msg->getString();
        vocations.emplace_back(vocationID, vocationName);
    }

    msg->getU32(); // skip params.vocation

    const uint8_t sizeCategories = msg->getU8();
    std::vector<std::tuple<uint8_t, std::string>> categories;

    for (auto i = 0; i < sizeCategories; ++i) {
        const uint8_t id = msg->getU8();
        const auto& categoryName = msg->getString();
        categories.emplace_back(id, categoryName);
    }

    msg->getU8(); // skip params.category
    const uint16_t page = msg->getU16();
    const uint16_t totalPages = msg->getU16();

    const uint8_t sizeEntries = msg->getU8();
    std::vector<std::tuple<uint32_t, std::string, std::string, uint8_t, std::string, uint16_t, uint8_t, uint64_t>> highscores;

    for (auto i = 0; i < sizeEntries; ++i) {
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
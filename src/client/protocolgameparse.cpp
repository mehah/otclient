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
#include "luavaluecasts.h"
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
                case Proto::GameServerLoginOrPendingState:
                    if (g_game.getFeature(Otc::GameLoginPending))
                        parsePendingGame(msg);
                    else
                        parseLogin(msg);
                    break;
                case Proto::GameServerGMActions:
                    parseGMActions(msg);
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
                case Proto::GameServerSessionEnd:
                    parseSessionEnd(msg);
                    break;
                case Proto::GameServerPing:
                case Proto::GameServerPingBack:
                    if (((opcode == Proto::GameServerPing) && (g_game.getFeature(Otc::GameClientPing))) ||
                        ((opcode == Proto::GameServerPingBack) && !g_game.getFeature(Otc::GameClientPing)))
                        parsePingBack(msg);
                    else
                        parsePing(msg);
                    break;
                case Proto::GameServerChallenge:
                    parseChallenge(msg);
                    break;
                case Proto::GameServerDeath:
                    parseDeath(msg);
                    break;
                case Proto::GameServerFloorDescription:
                    parseFloorDescription(msg);
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
                    parseAnimatedText(msg);
                    break;
                case Proto::GameServerMissleEffect:
                    if (g_game.getFeature(Otc::GameAnthem)) {
                        parseAnthem(msg);
                    } else {
                        parseDistanceMissile(msg);
                    }
                    break;
                case Proto::GameServerItemClasses:
                    if (g_game.getClientVersion() >= 1281)
                        parseItemClasses(msg);
                    else
                        parseCreatureMark(msg);
                    break;
                case Proto::GameServerTrappers:
                    parseTrappers(msg);
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
                case Proto::GameServerEditText:
                    parseEditText(msg);
                    break;
                case Proto::GameServerEditList:
                    parseEditList(msg);
                    break;
                    // PROTOCOL>=1038
                case Proto::GameServerPremiumTrigger:
                    parsePremiumTrigger(msg);
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
                case Proto::GameServerPlayerModes:
                    parsePlayerModes(msg);
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
                    if (g_game.getClientVersion() >= 1200)
                        parseExperienceTracker(msg);
                    else
                        parseRuleViolationRemove(msg);
                    break;
                case Proto::GameServerRuleViolationCancel:
                    parseRuleViolationCancel(msg);
                    break;
                case Proto::GameServerRuleViolationLock:
                    parseRuleViolationLock(msg);
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
                case Proto::GameServerFloorChangeUp:
                    parseFloorChangeUp(msg);
                    break;
                case Proto::GameServerFloorChangeDown:
                    parseFloorChangeDown(msg);
                    break;
                case Proto::GameServerChooseOutfit:
                    parseOpenOutfitWindow(msg);
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
                    // PROTOCOL>=870
                case Proto::GameServerSpellDelay:
                    parseSpellCooldown(msg);
                    break;
                case Proto::GameServerSpellGroupDelay:
                    parseSpellGroupCooldown(msg);
                    break;
                case Proto::GameServerMultiUseDelay:
                    parseMultiUseCooldown(msg);
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
                    // PROTOCOL>=950
                case Proto::GameServerPlayerDataBasic:
                    parsePlayerInfo(msg);
                    break;
                    // PROTOCOL>=970
                case Proto::GameServerModalDialog:
                    parseModalDialog(msg);
                    break;
                    // PROTOCOL>=980
                case Proto::GameServerLoginSuccess:
                    parseLogin(msg);
                    break;
                case Proto::GameServerEnterGame:
                    parseEnterGame(msg);
                    break;
                case Proto::GameServerPlayerHelpers:
                    parsePlayerHelpers(msg);
                    break;
                    // PROTOCOL>=1000
                case Proto::GameServerCreatureMarks:
                    parseCreaturesMark(msg);
                    break;
                case Proto::GameServerCreatureType:
                    parseCreatureType(msg);
                    break;
                    // PROTOCOL>=1055
                case Proto::GameServerBlessings:
                    parseBlessings(msg);
                    break;
                case Proto::GameServerUnjustifiedStats:
                    parseUnjustifiedStats(msg);
                    break;
                case Proto::GameServerPvpSituations:
                    parsePvpSituations(msg);
                    break;
                case Proto::GameServerPreset:
                    parsePreset(msg);
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
                    // PROTOCOL>=1097
                case Proto::GameServerStoreButtonIndicators:
                    parseStoreButtonIndicators(msg);
                    break;
                case Proto::GameServerSetStoreDeepLink:
                    parseSetStoreDeepLink(msg);
                    break;
                    // otclient ONLY
                case Proto::GameServerExtendedOpcode:
                    parseExtendedOpcode(msg);
                    break;
                case Proto::GameServerChangeMapAwareRange:
                    parseChangeMapAwareRange(msg);
                    break;
                    // 12x
                case Proto::GameServerLootContainers:
                    parseLootContainers(msg);
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
                case Proto::GameServerRefreshBestiaryTracker:
                    parseBestiaryTracker(msg);
                    break;
                case Proto::GameServerTaskHuntingBasicData:
                    parseTaskHuntingBasicData(msg);
                    break;
                case Proto::GameServerTaskHuntingData:
                    parseTaskHuntingData(msg);
                    break;
                case Proto::GameServerSendShowDescription:
                    parseShowDescription(msg);
                    break;
                case Proto::GameServerPassiveCooldown:
                    parsePassiveCooldown(msg);
                    break;
                case Proto::GameServerSendClientCheck:
                    parseClientCheck(msg);
                    break;
                case Proto::GameServerSendGameNews:
                    parseGameNews(msg);
                    break;
                case Proto::GameServerSendBlessDialog:
                    parseBlessDialog(msg);
                    break;
                case Proto::GameServerSendRestingAreaState:
                    parseRestingAreaState(msg);
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

                    // 13xx
                case Proto::GameServerBosstiaryData:
                    parseBosstiaryData(msg);
                    break;
                case Proto::GameServerBosstiarySlots:
                    parseBosstiarySlots(msg);
                    break;
                case Proto::GameServerBosstiaryCooldownTimer:
                    parseBosstiaryCooldownTimer(msg);
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

                default:
                    throw Exception("unhandled opcode %d", opcode);
                    break;
            }
            prevOpcode = opcode;
        }
    } catch (const stdext::exception& e) {
        g_logger.error(stdext::format("ProtocolGame parse message exception (%d bytes unread, last opcode is %d, prev opcode is %d): %s",
                       msg->getUnreadSize(), opcode, prevOpcode, e.what()));
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

    const bool canReportBugs = msg->getU8();

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

    Game::processLogin();
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
    msg->getU8(); // unknown
    msg->getU8(); // unknown
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
    const auto type = static_cast<Otc::ResourceTypes_t>(msg->getU8());
    const uint64_t value = msg->getU64();
    m_localPlayer->setResourceBalance(type, value);
}

void ProtocolGame::parseWorldTime(const InputMessagePtr& msg)
{
    msg->getU8(); // hour
    msg->getU8(); // min
}

void ProtocolGame::parseStore(const InputMessagePtr& msg) const
{
    parseCoinBalance(msg);

    const uint8_t categories = msg->getU16();
    for (int_fast32_t i = -1; ++i < categories;) {
        msg->getString(); // category
        msg->getString(); // description

        if (g_game.getFeature(Otc::GameIngameStoreHighlights))
            msg->getU8(); // highlightState

        std::vector<std::string> icons;
        const uint8_t iconCount = msg->getU8();
        for (int_fast32_t j = -1; ++j < iconCount; ) {
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
    for (int_fast32_t i = -1; ++i < entries;) {
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
    for (int_fast32_t i = -1; ++i < offers;) {
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
        for (int_fast32_t j = -1; ++j < iconCount;) {
            icons.emplace_back(msg->getString());
        }

        const uint16_t subOffers = msg->getU16();
        for (int_fast32_t j = -1; ++j < subOffers;) {
            msg->getString(); // name
            msg->getString(); // description

            const uint8_t subIcons = msg->getU8();
            for (int_fast32_t k = -1; ++k < subIcons;) {
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

void ProtocolGame::parsePvpSituations(const InputMessagePtr& msg)
{
    const uint8_t openPvpSituations = msg->getU8();

    g_game.setOpenPvpSituations(openPvpSituations);
}

void ProtocolGame::parsePlayerHelpers(const InputMessagePtr& msg) const
{
    const uint32_t id = msg->getU32();
    const uint16_t helpers = msg->getU16();

    if (g_map.getCreatureById(id))
        Game::processPlayerHelpers(helpers);
    else
        g_logger.traceError(stdext::format("could not get creature with id %d", id));
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

    for (int_fast32_t i = -1; ++i < numViolationReasons;)
        actions.push_back(msg->getU8());

    g_game.processGMActions(actions);
}

void ProtocolGame::parseUpdateNeeded(const InputMessagePtr& msg)
{
    const auto& signature = msg->getString();
    Game::processUpdateNeeded(signature);
}

void ProtocolGame::parseLoginError(const InputMessagePtr& msg)
{
    const auto& error = msg->getString();
    Game::processLoginError(error);
}

void ProtocolGame::parseLoginAdvice(const InputMessagePtr& msg)
{
    const auto& message = msg->getString();
    Game::processLoginAdvice(message);
}

void ProtocolGame::parseLoginWait(const InputMessagePtr& msg)
{
    const auto& message = msg->getString();
    const uint8_t time = msg->getU8();

    Game::processLoginWait(message, time);
}

void ProtocolGame::parseSessionEnd(const InputMessagePtr& msg)
{
    const uint8_t reason = msg->getU8();
    Game::processSessionEnd(reason);
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

    if (g_game.getClientVersion() >= 1281) {
        msg->getU8(); // can use death redemption (bool)
    }

    g_game.processDeath(deathType, penality);
}

void ProtocolGame::parseFloorDescription(const InputMessagePtr& msg)
{
    const auto& pos = getPosition(msg);
    const auto& oldPos = m_localPlayer->getPosition();
    const uint8_t floor = msg->getU8();

    if (pos.z == floor) {
        if (!m_mapKnown)
            m_localPlayer->setPosition(pos);
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
        g_dispatcher.addEvent([] { g_lua.callGlobalField("g_game", "onMapKnown"); });
        m_mapKnown = true;
    }

    g_dispatcher.addEvent([] { g_lua.callGlobalField("g_game", "onMapDescription"); });
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
    int stackPos = -1;

    if (g_game.getClientVersion() >= 841)
        stackPos = msg->getU8();

    const auto& thing = getThing(msg);
    g_map.addThing(thing, pos, stackPos);
}

void ProtocolGame::parseTileTransformThing(const InputMessagePtr& msg)
{
    const auto& thing = getMappedThing(msg);
    const auto& newThing = getThing(msg);

    if (!thing) {
        g_logger.traceError("no thing");
        return;
    }

    const auto& pos = thing->getPosition();
    const int stackpos = thing->getStackPos();

    if (!g_map.removeThing(thing)) {
        g_logger.traceError("unable to remove thing");
        return;
    }

    g_map.addThing(newThing, pos, stackpos);
}

void ProtocolGame::parseTileRemoveThing(const InputMessagePtr& msg) const
{
    const auto& thing = getMappedThing(msg);
    if (!thing) {
        g_logger.traceError("no thing");
        return;
    }

    if (!g_map.removeThing(thing))
        g_logger.traceError("unable to remove thing");
}

void ProtocolGame::parseCreatureMove(const InputMessagePtr& msg)
{
    const auto& thing = getMappedThing(msg);
    const auto& newPos = getPosition(msg);

    if (!thing || !thing->isCreature()) {
        g_logger.traceError("no creature found to move");
        return;
    }

    if (!g_map.removeThing(thing)) {
        g_logger.traceError("unable to remove creature");
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
        msg->getU8(); // show search icon (boolean)
    }

    if (g_game.getFeature(Otc::GameContainerPagination)) {
        isUnlocked = msg->getU8() != 0; // drag and drop
        hasPages = msg->getU8() != 0; // pagination
        containerSize = msg->getU16(); // container size
        firstIndex = msg->getU16(); // first index
    }

    const uint8_t itemCount = msg->getU8();

    std::vector<ItemPtr> items(itemCount);
    for (int_fast32_t i = -1; ++i < itemCount;)
        items[i] = getItem(msg);

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
    uint16_t slot = 0;
    if (g_game.getFeature(Otc::GameContainerPagination)) {
        slot = msg->getU16(); // slot
    }
    const auto& item = getItem(msg);
    g_game.processContainerAddItem(containerId, item, slot);
}

void ProtocolGame::parseContainerUpdateItem(const InputMessagePtr& msg)
{
    const uint8_t containerId = msg->getU8();
    uint16_t slot;
    if (g_game.getFeature(Otc::GameContainerPagination)) {
        slot = msg->getU16();
    } else {
        slot = msg->getU8();
    }
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

    uint16_t listCount;

    if (g_game.getClientVersion() >= 900)
        listCount = msg->getU16();
    else
        listCount = msg->getU8();

    for (int_fast32_t i = -1; ++i < listCount;) {
        const uint16_t itemId = msg->getU16();
        const uint8_t count = msg->getU8();

        const auto& item = Item::create(itemId);
        item->setCountOrSubType(count);

        const auto& name = msg->getString();
        uint32_t weight = msg->getU32();
        uint32_t buyPrice = msg->getU32();
        uint32_t sellPrice = msg->getU32();
        items.emplace_back(item, name, weight, buyPrice, sellPrice);
    }

    Game::processOpenNpcTrade(items);
}

void ProtocolGame::parsePlayerGoods(const InputMessagePtr& msg) const
{
    std::vector<std::tuple<ItemPtr, int>> goods;

    // 12.x NOTE: this u64 is parsed only, because TFS stil sends it, we use resource balance in this protocol
    uint64_t money = 0;
    if (g_game.getClientVersion() >= 973)
        money = msg->getU64();
    else
        money = msg->getU32();

    if (g_game.getClientVersion() >= 1281) {
        money = m_localPlayer->getResourceBalance(Otc::RESOURCE_BANK_BALANCE) + m_localPlayer->getResourceBalance(Otc::RESOURCE_GOLD_EQUIPPED);
    }

    const uint8_t size = msg->getU8();
    for (int_fast32_t i = -1; ++i < size;) {
        const uint16_t itemId = msg->getU16();

        uint16_t amount;
        if (g_game.getFeature(Otc::GameDoubleShopSellAmount))
            amount = msg->getU16();
        else
            amount = msg->getU8();

        goods.emplace_back(Item::create(itemId), amount);
    }

    Game::processPlayerGoods(money, goods);
}

void ProtocolGame::parseCloseNpcTrade(const InputMessagePtr&) { Game::processCloseNpcTrade(); }

void ProtocolGame::parseOwnTrade(const InputMessagePtr& msg)
{
    const auto& name = g_game.formatCreatureName(msg->getString());
    const uint8_t count = msg->getU8();

    std::vector<ItemPtr> items(count);
    for (int_fast32_t i = -1; ++i < count;)
        items[i] = getItem(msg);

    Game::processOwnTrade(name, items);
}

void ProtocolGame::parseCounterTrade(const InputMessagePtr& msg)
{
    const auto& name = g_game.formatCreatureName(msg->getString());
    const uint8_t count = msg->getU8();

    std::vector<ItemPtr> items(count);
    for (int_fast32_t i = -1; ++i < count; )
        items[i] = getItem(msg);

    Game::processCounterTrade(name, items);
}

void ProtocolGame::parseCloseTrade(const InputMessagePtr&) { Game::processCloseTrade(); }

void ProtocolGame::parseWorldLight(const InputMessagePtr& msg)
{
    uint8_t intensity = msg->getU8();
    uint8_t color = msg->getU8();

    g_map.setLight({ intensity , color });
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
                    const uint8_t shotId = msg->getU8();
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
                    const uint8_t effectId = msg->getU8();
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

    uint16_t effectId;
    if (g_game.getFeature(Otc::GameMagicEffectU16))
        effectId = msg->getU16();
    else
        effectId = msg->getU8();

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
    uint8_t type = msg->getU8();
    if (type >= 0 && type <= 2) {
        msg->getU16(); // Anthem id
    }
}

void ProtocolGame::parseDistanceMissile(const InputMessagePtr& msg)
{
    const auto& fromPos = getPosition(msg);
    const auto& toPos = getPosition(msg);

    uint16_t shotId;
    if (g_game.getFeature(Otc::GameDistanceEffectU16))
        shotId = msg->getU16();
    else
        shotId = msg->getU8();

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
    for (uint8_t i = 0; i < classSize; i++) {
        msg->getU8(); // class id

        // tiers
        const uint8_t tiersSize = msg->getU8();
        for (uint8_t j = 0; j < tiersSize; j++) {
            msg->getU8(); // tier id
            msg->getU64(); // upgrade cost
        }
    }

    if (g_game.getFeature(Otc::GameDynamicForgeVariables)) {
        const uint8_t grades = msg->getU8();
        for (int i = 0; i < grades; i++) {
            msg->getU8(); // Tier
            msg->getU8(); // Exalted cores
        }

        msg->getU8(); // Dust Percent
        msg->getU8(); // Dust To Sleaver
        msg->getU8(); // Sliver To Core
        msg->getU8(); // Dust Percent Upgrade
        msg->getU16(); // Max Dust
        msg->getU16(); // Max Dust Cap
        msg->getU8(); // Dust Fusion
        msg->getU8(); // Dust Transfer
        msg->getU8(); // Chance Base
        msg->getU8(); // Chance Improved
        msg->getU8(); // Reduce Tier Loss
    } else {
        for (uint8_t i = 1; i <= 11; i++) {
            msg->getU8(); // Forge values
        }
    }
}

void ProtocolGame::parseCreatureMark(const InputMessagePtr& msg)
{
    const uint32_t id = msg->getU32();
    const uint8_t color = msg->getU8();

    const CreaturePtr creature = g_map.getCreatureById(id);
    if (creature)
        creature->addTimedSquare(color);
    else
        g_logger.traceError("could not get creature");
}

void ProtocolGame::parseTrappers(const InputMessagePtr& msg)
{
    const uint8_t numTrappers = msg->getU8();

    if (numTrappers > 8)
        g_logger.traceError("too many trappers");

    for (int_fast32_t i = 0; i < numTrappers; ++i) {
        const uint32_t id = msg->getU32();
        if (const auto& creature = g_map.getCreatureById(id)) {
            //TODO: set creature as trapper
        } else
            g_logger.traceError("could not get creature");
    }
}

void ProtocolGame::parseCreatureHealth(const InputMessagePtr& msg)
{
    const uint32_t id = msg->getU32();
    const uint8_t healthPercent = msg->getU8();

    const auto& creature = g_map.getCreatureById(id);
    if (creature) creature->setHealthPercent(healthPercent);
}

void ProtocolGame::parseCreatureLight(const InputMessagePtr& msg)
{
    const uint32_t id = msg->getU32();

    Light light;
    light.intensity = msg->getU8();
    light.color = msg->getU8();

    const auto& creature = g_map.getCreatureById(id);
    if (!creature) {
        g_logger.traceError("could not get creature");
        return;
    }

    creature->setLight(light);
}

void ProtocolGame::parseCreatureOutfit(const InputMessagePtr& msg) const
{
    const uint32_t id = msg->getU32();
    const Outfit outfit = getOutfit(msg);

    const auto& creature = g_map.getCreatureById(id);
    if (!creature) {
        g_logger.traceError("could not get creature");
        return;
    }

    creature->setOutfit(outfit);
}

void ProtocolGame::parseCreatureSpeed(const InputMessagePtr& msg)
{
    const uint32_t id = msg->getU32();

    uint16_t baseSpeed = 0;
    if (g_game.getClientVersion() >= 1059)
        baseSpeed = msg->getU16();

    const uint16_t speed = msg->getU16();

    const auto& creature = g_map.getCreatureById(id);
    if (!creature) return;

    creature->setSpeed(speed);
    if (baseSpeed != 0)
        creature->setBaseSpeed(baseSpeed);
}

void ProtocolGame::parseCreatureSkulls(const InputMessagePtr& msg)
{
    const uint32_t id = msg->getU32();
    const uint8_t skull = msg->getU8();

    const auto& creature = g_map.getCreatureById(id);
    if (!creature) {
        g_logger.traceError("could not get creature");
        return;
    }

    creature->setSkull(skull);
}

void ProtocolGame::parseCreatureShields(const InputMessagePtr& msg)
{
    const uint32_t id = msg->getU32();
    const uint8_t shield = msg->getU8();

    const auto& creature = g_map.getCreatureById(id);
    if (!creature) {
        g_logger.traceError("could not get creature");
        return;
    }

    creature->setShield(shield);
}

void ProtocolGame::parseCreatureUnpass(const InputMessagePtr& msg)
{
    const uint32_t id = msg->getU32();
    const bool unpass = msg->getU8();

    const auto& creature = g_map.getCreatureById(id);
    if (!creature) {
        g_logger.traceError("could not get creature");
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

    Game::processEditText(id, itemId, maxLength, text, writer, date);
}

void ProtocolGame::parseEditList(const InputMessagePtr& msg)
{
    const uint8_t doorId = msg->getU8();
    const uint32_t id = msg->getU32();
    const auto& text = msg->getString();

    Game::processEditList(id, doorId, text);
}

void ProtocolGame::parsePremiumTrigger(const InputMessagePtr& msg)
{
    const uint8_t triggerCount = msg->getU8();
    std::vector<int> triggers;

    for (int_fast32_t i = 0; i < triggerCount; ++i) {
        triggers.push_back(msg->getU8());
    }

    if (g_game.getClientVersion() <= 1096) {
        msg->getU8(); // == 1; // something
    }
}

void ProtocolGame::parsePlayerInfo(const InputMessagePtr& msg) const
{
    const bool premium = msg->getU8(); // premium
    if (g_game.getFeature(Otc::GamePremiumExpiration))
        msg->getU32(); // premium expiration used for premium advertisement
    const uint8_t vocation = msg->getU8(); // vocation

    if (g_game.getClientVersion() >= 1281) {
        msg->getU8(); // prey enabled
    }

    const uint16_t spellCount = msg->getU16();
    std::vector<uint16_t> spells;
    for (int_fast32_t i = 0; i < spellCount; ++i) {
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
    uint32_t health;
    uint32_t maxHealth;

    if (g_game.getFeature(Otc::GameDoubleHealth)) {
        health = msg->getU32();
        maxHealth = msg->getU32();
    } else {
        health = msg->getU16();
        maxHealth = msg->getU16();
    }

    uint32_t freeCapacity = 0;
    uint32_t totalCapacity = 0;

    if (g_game.getFeature(Otc::GameDoubleFreeCapacity))
        freeCapacity = msg->getU32() / 100.f;
    else
        freeCapacity = msg->getU16() / 100.f;

    if (g_game.getClientVersion() < 1281) {
        if (g_game.getFeature(Otc::GameTotalCapacity))
            totalCapacity = msg->getU32() / 100.f;
    }

    uint64_t experience;
    if (g_game.getFeature(Otc::GameDoubleExperience))
        experience = msg->getU64();
    else
        experience = msg->getU32();

    uint16_t level;
    if (g_game.getFeature(Otc::GameLevelU16))
        level = msg->getU16();
    else
        level = msg->getU8();

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

    uint32_t mana;
    uint32_t maxMana;

    if (g_game.getFeature(Otc::GameDoubleHealth)) {
        mana = msg->getU32();
        maxMana = msg->getU32();
    } else {
        mana = msg->getU16();
        maxMana = msg->getU16();
    }

    if (g_game.getClientVersion() < 1281) {
        const uint8_t magicLevel = msg->getU8();

        uint8_t baseMagicLevel = 0;
        if (g_game.getFeature(Otc::GameSkillsBase))
            baseMagicLevel = msg->getU8();
        else
            baseMagicLevel = magicLevel;

        const uint8_t magicLevelPercent = msg->getU8();

        m_localPlayer->setMagicLevel(magicLevel, magicLevelPercent);
        m_localPlayer->setBaseMagicLevel(baseMagicLevel);
    }

    uint8_t soul = 0;
    if (g_game.getFeature(Otc::GameSoul))
        soul = msg->getU8();

    uint16_t stamina = 0;
    if (g_game.getFeature(Otc::GamePlayerStamina))
        stamina = msg->getU16();

    uint16_t baseSpeed = 0;
    if (g_game.getFeature(Otc::GameSkillsBase))
        baseSpeed = msg->getU16();

    uint16_t regeneration = 0;
    if (g_game.getFeature(Otc::GamePlayerRegenerationTime))
        regeneration = msg->getU16();

    uint16_t training = 0;
    if (g_game.getFeature(Otc::GameOfflineTrainingTime)) {
        training = msg->getU16();
    }

    if (g_game.getClientVersion() >= 1097) {
        msg->getU16(); // xp boost time (seconds)
        msg->getU8(); // enables exp boost in the store
    }

    if (g_game.getClientVersion() >= 1281) {
        if (g_game.getFeature(Otc::GameDoubleHealth)) {
            msg->getU32();  // remaining mana shield
            msg->getU32();  // total mana shield
        } else {
            msg->getU16();  // remaining mana shield
            msg->getU16();  // total mana shield
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
        uint16_t level;

        if (g_game.getFeature(Otc::GameDoubleSkills))
            level = msg->getU16();
        else
            level = msg->getU8();

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

    if (g_game.getFeature(Otc::GameConcotions)) {
        msg->getU8();
    }

    if (g_game.getFeature(Otc::GameAdditionalSkills)) {
        // Critical, Life Leech, Mana Leech, Dodge, Fatal, Momentum have no level percent, nor loyalty bonus

        const uint8_t lastSkill = g_game.getClientVersion() >= 1281 ? Otc::LastSkill : Otc::ManaLeechAmount + 1;
        for (int_fast32_t skill = Otc::CriticalChance; skill < lastSkill; ++skill) {
            const uint16_t level = msg->getU16();
            const uint16_t baseLevel = msg->getU16();
            m_localPlayer->setSkill(static_cast<Otc::Skill>(skill), level, 0);
            m_localPlayer->setBaseSkill(static_cast<Otc::Skill>(skill), baseLevel);
        }
    }

    if (g_game.getClientVersion() >= 1281) {
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
    } else {
        if (g_game.getFeature(Otc::GamePlayerStateU16))
            states = msg->getU16();
        else
            states = msg->getU8();
    }

    m_localPlayer->setStates(states);
}

void ProtocolGame::parsePlayerCancelAttack(const InputMessagePtr& msg)
{
    uint32_t seq = 0;
    if (g_game.getFeature(Otc::GameAttackSeq))
        seq = msg->getU32();

    g_game.processAttackCancel(seq);
}

void ProtocolGame::parsePlayerModes(const InputMessagePtr& msg)
{
    const uint8_t fightMode = msg->getU8();
    const uint8_t chaseMode = msg->getU8();
    const bool safeMode = msg->getU8();

    uint8_t pvpMode = 0;
    if (g_game.getFeature(Otc::GamePVPMode))
        pvpMode = msg->getU8();

    g_game.processPlayerModes(static_cast<Otc::FightModes>(fightMode), static_cast<Otc::ChaseModes>(chaseMode), safeMode, static_cast<Otc::PVPModes>(pvpMode));
}

void ProtocolGame::parseSpellCooldown(const InputMessagePtr& msg)
{
    uint16_t spellId = msg->getU8();
    if (g_game.getFeature(Otc::GameUshortSpell)) {
        spellId = msg->getU16();
    } else {
        spellId = msg->getU8();
    }
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
    if (g_game.getFeature(Otc::GameMessageStatements))
        msg->getU32(); // channel statement guid

    const auto& name = g_game.formatCreatureName(msg->getString());

    if (g_game.getClientVersion() >= 1281) {
        msg->getU8(); // suffix
    }

    uint16_t level = 0;
    if (g_game.getFeature(Otc::GameMessageLevel))
        level = msg->getU16();

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
            throw Exception("unknown message mode %d", mode);
            break;
    }

    const auto& text = msg->getString();

    Game::processTalk(name, level, mode, text, channelId, pos);
}

void ProtocolGame::parseChannelList(const InputMessagePtr& msg)
{
    const uint8_t count = msg->getU8();
    std::vector<std::tuple<int, std::string> > channelList;
    for (int_fast32_t i = 0; i < count; ++i) {
        const uint16_t id = msg->getU16();
        const auto& name = msg->getString();
        channelList.emplace_back(id, name);
    }

    Game::processChannelList(channelList);
}

void ProtocolGame::parseOpenChannel(const InputMessagePtr& msg)
{
    const uint16_t channelId = msg->getU16();
    const auto& name = msg->getString();

    if (g_game.getFeature(Otc::GameChannelPlayerList)) {
        const uint16_t joinedPlayers = msg->getU16();
        for (int_fast32_t i = 0; i < joinedPlayers; ++i)
            g_game.formatCreatureName(msg->getString()); // player name
        const uint16_t invitedPlayers = msg->getU16();
        for (int_fast32_t i = 0; i < invitedPlayers; ++i)
            g_game.formatCreatureName(msg->getString()); // player name
    }

    Game::processOpenChannel(channelId, name);
}

void ProtocolGame::parseOpenPrivateChannel(const InputMessagePtr& msg)
{
    const auto& name = g_game.formatCreatureName(msg->getString());
    Game::processOpenPrivateChannel(name);
}

void ProtocolGame::parseOpenOwnPrivateChannel(const InputMessagePtr& msg)
{
    const uint16_t channelId = msg->getU16();
    const auto& name = g_game.formatCreatureName(msg->getString());

    Game::processOpenOwnPrivateChannel(channelId, name);
}

void ProtocolGame::parseCloseChannel(const InputMessagePtr& msg)
{
    const uint16_t channelId = msg->getU16();
    Game::processCloseChannel(channelId);
}

void ProtocolGame::parseRuleViolationChannel(const InputMessagePtr& msg)
{
    const int channelId = msg->getU16();
    Game::processRuleViolationChannel(channelId);
}

void ProtocolGame::parseRuleViolationRemove(const InputMessagePtr& msg)
{
    const auto& name = msg->getString();
    Game::processRuleViolationRemove(name);
}

void ProtocolGame::parseRuleViolationCancel(const InputMessagePtr& msg)
{
    const auto& name = msg->getString();
    Game::processRuleViolationCancel(name);
}

void ProtocolGame::parseRuleViolationLock(const InputMessagePtr&) { Game::processRuleViolationLock(); }

void ProtocolGame::parseTextMessage(const InputMessagePtr& msg)
{
    const uint8_t code = msg->getU8();
    const Otc::MessageMode mode = Proto::translateMessageModeFromServer(code);
    std::string text;

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
            std::array<uint32_t, 2> color;

            // physical damage
            value[0] = msg->getU32();
            color[0] = msg->getU8();

            // magic damage
            value[1] = msg->getU32();
            color[1] = msg->getU8();
            text = msg->getString();

            for (int_fast32_t i = 0; i < 2; ++i) {
                if (value[i] == 0)
                    continue;

                g_map.addAnimatedText(std::make_shared<AnimatedText>(std::to_string(value[i]), color[i]), pos);
            }
            break;
        }
        case Otc::MessageHeal:
        case Otc::MessageMana:
        case Otc::MessageExp:
        case Otc::MessageHealOthers:
        case Otc::MessageExpOthers:
        {
            const auto& pos = getPosition(msg);
            const uint32_t value = msg->getU32();
            const uint8_t color = msg->getU8();
            text = msg->getString();

            g_map.addAnimatedText(std::make_shared<AnimatedText>(std::to_string(value), color), pos);
            break;
        }
        case Otc::MessageInvalid:
            throw Exception("unknown message mode %d", mode);
            break;
        default:
            text = msg->getString();
            break;
    }

    Game::processTextMessage(mode, text);
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
    if (pos.z == g_gameConfig.getMapSeaFloor())
        for (int_fast32_t i = g_gameConfig.getMapSeaFloor() - g_gameConfig.getMapAwareUndergroundFloorRange(); i >= 0; --i)
            skip = setFloorDescription(msg, pos.x - range.left, pos.y - range.top, i, range.horizontal(), range.vertical(), 8 - i, skip);
    else if (pos.z > g_gameConfig.getMapSeaFloor())
        setFloorDescription(msg, pos.x - range.left, pos.y - range.top, pos.z - g_gameConfig.getMapAwareUndergroundFloorRange(), range.horizontal(), range.vertical(), 3, skip);

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
        for (i = pos.z, j = -1; i <= pos.z + g_gameConfig.getMapAwareUndergroundFloorRange(); ++i, --j)
            skip = setFloorDescription(msg, pos.x - range.left, pos.y - range.top, i, range.horizontal(), range.vertical(), j, skip);
    } else if (pos.z > g_gameConfig.getMapUndergroundFloorRange() && pos.z < g_gameConfig.getMapMaxZ() - 1)
        setFloorDescription(msg, pos.x - range.left, pos.y - range.top, pos.z + g_gameConfig.getMapAwareUndergroundFloorRange(), range.horizontal(), range.vertical(), -3, skip);

    --pos.x;
    --pos.y;
    g_map.setCentralPosition(pos);
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
        for (int_fast32_t i = 0; i < outfitCount; ++i) {
            uint16_t outfitId = msg->getU16();
            const auto& outfitName = msg->getString();
            uint8_t outfitAddons = msg->getU8();

            if (g_game.getClientVersion() >= 1281) {
                msg->getU8(); // mode: 0x00 - available, 0x01 store (requires U32 store offerId), 0x02 golden outfit tooltip (hardcoded)
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

        for (int_fast32_t i = outfitStart; i <= outfitEnd; ++i)
            outfitList.emplace_back(i, "", 0);
    }

    std::vector<std::tuple<int, std::string> > mountList;
    if (g_game.getFeature(Otc::GamePlayerMounts)) {
        const uint16_t mountCount = g_game.getClientVersion() >= 1281 ? msg->getU16() : msg->getU8();
        for (int_fast32_t i = 0; i < mountCount; ++i) {
            const uint16_t mountId = msg->getU16(); // mount type
            const auto& mountName = msg->getString(); // mount name

            if (g_game.getClientVersion() >= 1281) {
                msg->getU8(); // mode: 0x00 - available, 0x01 store (requires U32 store offerId)
            }

            mountList.emplace_back(mountId, mountName);
        }
    }

    if (g_game.getClientVersion() >= 1281) {
        msg->getU16(); // familiars.size()
        // size > 0
        // U16 looktype
        // String name
        // 0x00 // mode: 0x00 - available, 0x01 store (requires U32 store offerId)

        msg->getU8(); //Try outfit mode (?)
        msg->getU8(); // mounted
        msg->getU8(); // randomize mount (bool)
    }

    g_game.processOpenOutfitWindow(currentOutfit, outfitList, mountList);
}

void ProtocolGame::parseKillTracker(const InputMessagePtr& msg)
{
    msg->getString(); // monster name
    getOutfit(msg, false);

    // corpse items
    const uint8_t size = msg->getU8();
    for (int_fast32_t i = 0; i < size; i++) {
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
        uint8_t size = msg->getU8();
        for (int i = 0; size; i++) {
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
        uint8_t size = msg->getU8();
        for (int i = 0; size; i++) {
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
    Game::processTutorialHint(id);
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
        Game::processAddAutomapFlag(pos, icon, description);
    else
        Game::processRemoveAutomapFlag(pos, icon, description);
}

void ProtocolGame::parseQuestLog(const InputMessagePtr& msg)
{
    std::vector<std::tuple<int, std::string, bool> > questList;
    const uint16_t questsCount = msg->getU16();
    for (int_fast32_t i = 0; i < questsCount; ++i) {
        uint16_t id = msg->getU16();
        const auto& name = msg->getString();
        bool completed = msg->getU8();
        questList.emplace_back(id, name, completed);
    }

    Game::processQuestLog(questList);
}

void ProtocolGame::parseQuestLine(const InputMessagePtr& msg)
{
    std::vector<std::tuple<std::string, std::string>> questMissions;
    const uint16_t questId = msg->getU16();
    const uint8_t missionCount = msg->getU8();
    for (int_fast32_t i = 0; i < missionCount; ++i) {
        const auto& missionName = msg->getString();
        const auto& missionDescrition = msg->getString();
        questMissions.emplace_back(missionName, missionDescrition);
    }

    Game::processQuestLine(questId, questMissions);
}

void ProtocolGame::parseChannelEvent(const InputMessagePtr& msg)
{
    const uint16_t channelId = msg->getU16();
    const auto& name = g_game.formatCreatureName(msg->getString());
    const uint8_t type = msg->getU8();

    g_lua.callGlobalField("g_game", "onChannelEvent", channelId, name, type);
}

void ProtocolGame::parseItemInfo(const InputMessagePtr& msg) const
{
    std::vector<std::tuple<ItemPtr, std::string>> list;
    const uint8_t size = msg->getU8();
    for (int_fast32_t i = 0; i < size; ++i) {
        const auto& item = std::make_shared<Item>();
        item->setId(msg->getU16());
        item->setCountOrSubType(msg->getU8());

        const auto& desc = msg->getString();
        list.emplace_back(item, desc);
    }

    g_lua.callGlobalField("g_game", "onItemInfo", list);
}

void ProtocolGame::parsePlayerInventory(const InputMessagePtr& msg)
{
    const uint16_t size = msg->getU16();
    for (int_fast32_t i = 0; i < size; ++i) {
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
    for (int_fast32_t i = 0; i < sizeButtons; ++i) {
        const auto& value = msg->getString();
        uint8_t buttonId = msg->getU8();
        buttonList.emplace_back(buttonId, value);
    }

    const uint8_t sizeChoices = msg->getU8();
    std::vector<std::tuple<int, std::string> > choiceList;
    for (int_fast32_t i = 0; i < sizeChoices; ++i) {
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

    Game::processModalDialog(windowId, title, message, buttonList, enterButton, escapeButton, choiceList, priority);
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
        callLuaField("onExtendedOpcode", opcode, buffer);
}

void ProtocolGame::parseChangeMapAwareRange(const InputMessagePtr& msg)
{
    const uint8_t xrange = msg->getU8();
    const uint8_t yrange = msg->getU8();

    g_map.setAwareRange({
        .left = static_cast<uint8_t>(xrange / 2 - (xrange + 1) % 2),
        .top = static_cast<uint8_t>(yrange / 2 - (yrange + 1) % 2),
        .right = static_cast<uint8_t>(xrange / 2),
        .bottom = static_cast<uint8_t>(yrange / 2)
                        });

    g_lua.callGlobalField("g_game", "onMapChangeAwareRange", xrange, yrange);
}

void ProtocolGame::parseCreaturesMark(const InputMessagePtr& msg)
{
    uint8_t len;
    if (g_game.getClientVersion() >= 1035) {
        len = 1;
    } else {
        len = msg->getU8();
    }

    for (int_fast32_t i = 0; i < len; ++i) {
        const uint32_t id = msg->getU32();
        const bool isPermanent = msg->getU8() != 1;
        const uint8_t markType = msg->getU8();

        if (const auto& creature = g_map.getCreatureById(id)) {
            if (isPermanent) {
                if (markType == 0xff)
                    creature->hideStaticSquare();
                else
                    creature->showStaticSquare(Color::from8bit(markType));
            } else
                creature->addTimedSquare(markType);
        } else
            g_logger.traceError("could not get creature");
    }
}

void ProtocolGame::parseCreatureType(const InputMessagePtr& msg)
{
    const uint32_t id = msg->getU32();
    const uint8_t type = msg->getU8();

    const auto& creature = g_map.getCreatureById(id);
    if (creature)
        creature->setType(type);
    else
        g_logger.traceError("could not get creature");
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
    for (int_fast32_t nz = startz; nz != endz + zstep; nz += zstep)
        skip = setFloorDescription(msg, x, y, nz, width, height, z - nz, skip);
}

int ProtocolGame::setFloorDescription(const InputMessagePtr& msg, int x, int y, int z, int width, int height, int offset, int skip)
{
    for (int_fast32_t nx = 0; nx < width; ++nx) {
        for (int_fast32_t ny = 0; ny < height; ++ny) {
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
    for (int_fast32_t stackPos = 0; stackPos < 256; ++stackPos) {
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
        const uint32_t id = msg->getU32();
        if (const auto& thing = g_map.getCreatureById(id))
            return thing;

        g_logger.traceError(stdext::format("no creature with id %u", id));
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
            const uint32_t id = msg->getU32();
            creature = g_map.getCreatureById(id);
            if (!creature)
                g_logger.traceError("server said that a creature is known, but it's not");
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
                } else switch (creatureType) {
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
            uint8_t listSize = msg->getU8();
            for (int_fast8_t i = -1; ++i < listSize;)
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
            creature->clearAttachedEffects();
            for (const auto effectId : attachedEffectList) {
                const auto& effect = g_attachedEffects.getById(effectId);
                if (effect)
                    creature->attachEffect(effect->clone());
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
        const uint32_t id = msg->getU32();
        creature = g_map.getCreatureById(id);

        if (!creature)
            g_logger.traceError("invalid creature");

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
        item->setCountOrSubType(msg->getU8());
    }

    if (item->isContainer()) {
        if (g_game.getFeature(Otc::GameThingQuickLoot)) {
            const bool hasQuickLootFlags = msg->getU8() != 0;
            if (hasQuickLootFlags) {
                msg->getU32(); // quick loot flags
            }
        }

        if (g_game.getFeature(Otc::GameThingQuiver)) {
            const uint8_t hasQuiverAmmoCount = msg->getU8();
            if (hasQuiverAmmoCount) {
                msg->getU32(); // ammoTotal
            }
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

    if (g_game.getFeature(Otc::GameItemAnimationPhase)) {
        if (item->getAnimationPhases() > 1) {
            // 0x00 => automatic phase
            // 0xFE => random phase
            // 0xFF => async phase
            msg->getU8();
            //item->setPhase(msg->getU8());
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

    if (g_game.getFeature(Otc::GameItemShader)) {
        item->setShader(msg->getString());
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

void ProtocolGame::parseBestiaryTracker(const InputMessagePtr& msg)
{
    const uint8_t size = msg->getU8();
    for (uint8_t i = 0; i < size; i++) {
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
    for (uint16_t i = 0; i < preys; i++) {
        msg->getU16(); // RaceID
        msg->getU8(); // Difficult
    }

    const uint8_t options = msg->getU8();
    for (uint8_t j = 0; j < options; j++) {
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
            for (uint16_t i = 0; i < creatures; i++) {
                msg->getU16(); // RaceID
                msg->getU8(); // Is unlocked
            }
        }
        break;
        case Otc::PREY_TASK_STATE_LIST_SELECTION:
        {
            const uint16_t creatures = msg->getU16();
            for (uint16_t i = 0; i < creatures; i++) {
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
    msg->get64(); // Raw exp
    msg->get64(); // Final exp
}

void ProtocolGame::parseLootContainers(const InputMessagePtr& msg)
{
    msg->getU8(); // quickLootFallbackToMainContainer ? 1 : 0
    const uint8_t containers = msg->getU8();
    for (int_fast32_t i = 0; i < containers; ++i) {
        msg->getU8(); // id?
        msg->getU16();
    }
}

void ProtocolGame::parseSupplyStash(const InputMessagePtr& msg)
{
    const uint16_t size = msg->getU16();
    for (int_fast32_t i = 0; i < size; ++i) {
        msg->getU16(); // item id
        msg->getU32(); // unknown
    }
    msg->getU16(); // available slots?
}

void ProtocolGame::parseSpecialContainer(const InputMessagePtr& msg)
{
    msg->getU8();
    if (g_game.getProtocolVersion() >= 1220) {
        msg->getU8();
    }
}

void ProtocolGame::parsePartyAnalyzer(const InputMessagePtr& msg)
{
    msg->getU32(); // Timestamp
    msg->getU32(); // LeaderID
    msg->getU8(); // Price type
    const uint8_t size = msg->getU8();
    for (uint8_t i = 0; i < size; i++) {
        msg->getU32(); // MemberID
        msg->getU8(); // Highlight
        msg->getU64(); // Loot
        msg->getU64(); // Supply
        msg->getU64(); // Damage
        msg->getU64(); // Healing
    }

    uint8_t names = msg->getU8();
    if (names != 0) {
        names = msg->getU8();
        for (uint8_t i = 0; i < names; i++) {
            msg->getU32(); // MemberID
            msg->getString(); // Member name
        }
    }
}

void ProtocolGame::parsePassiveCooldown(const InputMessagePtr& msg)
{
    msg->getU8(); // Passive id
    msg->getU8(); // ENUM
    msg->getU32(); // Timestamp (partial)
    msg->getU32(); // Timestamp (total)
    msg->getU8(); // Timer is running? (bool)
}

void ProtocolGame::parseClientCheck(const InputMessagePtr& msg)
{
    msg->getU32(); // 1
    msg->getU8(); // 1
}

void ProtocolGame::parseGameNews(const InputMessagePtr& msg)
{
    msg->getU32(); // 1
    msg->getU8(); // 1

    // TODO: implement game news usage
}

void ProtocolGame::parseBlessDialog(const InputMessagePtr& msg)
{
    // parse bless amount
    const uint8_t totalBless = msg->getU8(); // total bless

    // parse each bless
    for (int_fast32_t i = 0; i < totalBless; i++) {
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
    const uint8_t logCount = msg->getU8(); // log count
    for (int_fast32_t i = 0; i < logCount; i++) {
        msg->getU32(); // timestamp
        msg->getU8(); // color message (0 = white loss, 1 = red)
        msg->getString(); // history message
    }

    // TODO: implement bless dialog usage
}

void ProtocolGame::parseRestingAreaState(const InputMessagePtr& msg)
{
    msg->getU8(); // zone
    msg->getU8(); // state
    msg->getString(); // message

    // TODO: implement resting area state usage
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

    for (int_fast32_t i = 0; i < priceCount; i++) {
        const uint16_t itemId = msg->getU16(); // item client id
        if (g_game.getClientVersion() >= 1281) {
            const auto& item = Item::create(itemId);
            if (item->getId() == 0)
                throw Exception("unable to create item with invalid id %d", itemId);

            if (item->getClassification() > 0) {
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

void ProtocolGame::parseDailyReward(const InputMessagePtr& msg)
{
    const uint8_t days = msg->getU8(); // Reward count (7 days)
    for (uint8_t day = 1; day <= days; day++) {
        // Free account
        msg->getU8(); // type
        msg->getU8(); // Items to pick
        uint8_t size = msg->getU8();
        if (day == 1 || day == 2 || day == 4 || day == 6) {
            for (uint8_t i = 0; i < size; i++) {
                msg->getU16(); // Item ID
                msg->getString(); // Item name
                msg->getU32(); // Item weight
            }
        } else {
            msg->getU16(); // Amount
        }

        // Premium account
        msg->getU8(); // type
        msg->getU8(); // Items to pick
        size = msg->getU8();
        if (day == 1 || day == 2 || day == 4 || day == 6) {
            for (uint8_t i = 0; i < size; i++) {
                msg->getU16(); // Item ID
                msg->getString(); // Item name
                msg->getU32(); // Item weight
            }
        } else {
            msg->getU16(); // Amount
        }
    }

    const uint8_t bonus = msg->getU8();
    for (uint8_t i = 0; i < bonus; i++) {
        msg->getString(); // Bonus name
        msg->getU8(); // Bonus ID
    }

    msg->getU8(); // Unknown
    // TODO: implement daily reward usage
}

void ProtocolGame::parseRewardHistory(const InputMessagePtr& msg)
{
    const uint8_t historyCount = msg->getU8(); // history count

    for (int_fast32_t i = 0; i < historyCount; i++) {
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
    for (uint8_t i = 0; i < monstersSize; i++)
        monsters.emplace_back(getPreyMonster(msg));

    return monsters;
}

void ProtocolGame::parsePreyData(const InputMessagePtr& msg)
{
    const uint8_t slot = msg->getU8(); // slot
    const auto state = static_cast<Otc::PreyState_t>(msg->getU8()); // slot state

    switch (state) {
        case Otc::PREY_STATE_LOCKED:
        {
            const Otc::PreyUnlockState_t unlockState = static_cast<Otc::PreyUnlockState_t>(msg->getU8()); // prey slot unlocked
            const uint32_t nextFreeReroll = msg->getU32(); // next free roll
            const uint8_t wildcards = msg->getU8(); // wildcards
            return g_lua.callGlobalField("g_game", "onPreyLocked", slot, unlockState, nextFreeReroll, wildcards);
        }
        case Otc::PREY_STATE_INACTIVE:
        {
            const uint32_t nextFreeReroll = msg->getU32(); // next free roll
            const uint8_t wildcards = msg->getU8(); // wildcards
            return g_lua.callGlobalField("g_game", "onPreyInactive", slot, nextFreeReroll, wildcards);
        }
        case Otc::PREY_STATE_ACTIVE:
        {
            PreyMonster monster = getPreyMonster(msg);
            const uint8_t bonusType = msg->getU8(); // bonus type
            const uint16_t bonusValue = msg->getU16(); // bonus value
            const uint8_t bonusGrade = msg->getU8(); // bonus grade
            const uint16_t timeLeft = msg->getU16(); // time left
            const uint32_t nextFreeReroll = msg->getU32(); // next free roll
            const uint8_t wildcards = msg->getU8(); // wildcards
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
            const uint32_t nextFreeReroll = msg->getU32(); // next free roll
            const uint8_t wildcards = msg->getU8(); // wildcards
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
            const uint32_t nextFreeReroll = msg->getU32(); // next free roll
            const uint8_t wildcards = msg->getU8(); // wildcards
            return g_lua.callGlobalField("g_game", "onPreySelectionChangeMonster", slot, names, outfits, bonusType, bonusValue, bonusGrade, nextFreeReroll, wildcards);
        }
        case Otc::PREY_STATE_LIST_SELECTION:
        {
            std::vector<uint16_t> races;
            const uint16_t creatures = msg->getU16();
            for (uint16_t i = 0; i < creatures; i++) {
                races.push_back(msg->getU16()); // RaceID
            }
            const uint32_t nextFreeReroll = msg->getU32(); // next free roll
            const uint8_t wildcards = msg->getU8(); // wildcards
            return g_lua.callGlobalField("g_game", "onPreyListSelection", slot, races, nextFreeReroll, wildcards);
        }
        case Otc::PREY_STATE_WILDCARD_SELECTION:
        {
            msg->getU8(); // bonus type
            msg->getU16(); // bonus value
            msg->getU8(); // bonus grade

            std::vector<uint16_t> races;
            const uint16_t creatures = msg->getU16();
            for (uint16_t i = 0; i < creatures; i++) {
                races.push_back(msg->getU16()); // RaceID
            }
            const uint32_t nextFreeReroll = msg->getU32(); // next free roll
            const uint8_t wildcards = msg->getU8(); // wildcards
            return g_lua.callGlobalField("g_game", "onPreyWildcardSelection", slot, races, nextFreeReroll, wildcards);
        }
    }
}

void ProtocolGame::parsePreyRerollPrice(const InputMessagePtr& msg)
{
    const uint32_t price = msg->getU32(); //reroll price
    const uint8_t wildcard = msg->getU8(); // wildcard
    const uint8_t directly = msg->getU8(); // selectCreatureDirectly price (5 in tibia)
    if (g_game.getProtocolVersion() >= 1230) { // prey task
        msg->getU32();
        msg->getU32();
        msg->getU8();
        msg->getU8();
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
    for (uint8_t i = 0; i < itemsSize; i++) {
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
    stdext::map<int, std::tuple<Imbuement, int, int>> activeSlots;
    for (uint8_t i = 0; i < slot; i++) {
        const uint8_t firstByte = msg->getU8();
        if (firstByte == 0x01) {
            Imbuement imbuement = getImbuementInfo(msg);
            const uint32_t duration = msg->getU32(); // duration
            const uint32_t removalCost = msg->getU32(); // removecost
            activeSlots[i] = std::make_tuple(imbuement, duration, removalCost);
        }
    }

    const uint16_t imbSize = msg->getU16(); // imbuement size
    std::vector<Imbuement> imbuements;
    for (uint16_t i = 0; i < imbSize; i++) {
        imbuements.push_back(getImbuementInfo(msg));
    }

    const uint32_t neededItemsSize = msg->getU32(); // needed items size
    std::vector<ItemPtr> needItems;
    for (uint32_t i = 0; i < neededItemsSize; i++) {
        const uint16_t needItemId = msg->getU16();
        const uint16_t count = msg->getU16();
        const ItemPtr& item = Item::create(needItemId);
        item->setCount(count);
        needItems.push_back(item);
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
    if (const uint16_t depotLocker = msg->peekU16(); depotLocker == 0x00) {
        return;
    }

    std::vector<std::vector<uint16_t>> depotItems;
    const uint16_t itemsSent = msg->getU16();
    for (int_fast32_t i = 0; i < itemsSent; i++) {
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

    stdext::map<uint16_t, uint16_t> depotItems;
    for (int_fast32_t i = 0; i < itemsSent; i++) {
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

    stdext::map<int, std::string> descriptions;
    Otc::MarketItemDescription lastAttribute = Otc::ITEM_DESC_WEIGHT;
    if (g_game.getClientVersion() >= 1200)
        lastAttribute = Otc::ITEM_DESC_IMBUINGSLOTS;
    if (g_game.getClientVersion() >= 1270)
        lastAttribute = Otc::ITEM_DESC_UPGRADECLASS;
    if (g_game.getClientVersion() >= 1282)
        lastAttribute = Otc::ITEM_DESC_LAST;

    for (int_fast32_t i = Otc::ITEM_DESC_FIRST; i <= lastAttribute; i++) {
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
    for (int_fast32_t i = -1; ++i < count;) {
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
    for (int_fast32_t i = -1; ++i < count;) {
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
    for (uint32_t i = 0; i < buyOfferCount; i++) {
        offers.push_back(readMarketOffer(msg, Otc::MARKETACTION_BUY, var));
    }

    const uint32_t sellOfferCount = msg->getU32();
    for (uint32_t i = 0; i < sellOfferCount; i++) {
        offers.push_back(readMarketOffer(msg, Otc::MARKETACTION_SELL, var));
    }
    std::vector<std::vector<uint64_t>> intOffers;
    std::vector<std::string> nameOffers;

    for (const auto& offer : offers) {
        std::vector<uint64_t> intOffer = { offer.action, offer.amount, offer.counter, offer.itemId, offer.price, offer.state, offer.timestamp, offer.var };
        std::string playerName = offer.playerName;
        intOffers.push_back(intOffer);
        nameOffers.push_back(playerName);
    }

    g_lua.callGlobalField("g_game", "onMarketBrowse", intOffers, nameOffers);
}

// 13x
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

void ProtocolGame::parseBosstiarySlots(const InputMessagePtr& msg) {
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
    if (isSlotOneUnlocked && bossIdSlotOne != 0) {
        getBosstiarySlot();
    }

    const bool isSlotTwoUnlocked = msg->getU8();
    const uint32_t bossIdSlotTwo = msg->getU32();
    if (isSlotTwoUnlocked && bossIdSlotTwo != 0) {
        getBosstiarySlot();
    }

    const bool isTodaySlotUnlocked = msg->getU8();
    const uint32_t boostedBossId = msg->getU32();
    if (isTodaySlotUnlocked && boostedBossId != 0) {
        getBosstiarySlot();
    }

    const bool bossesUnlocked = msg->getU8();
    if (bossesUnlocked) {
        const uint16_t bossesUnlockedSize = msg->getU16();

        for (uint_fast16_t i = 0; i < bossesUnlockedSize; ++i) {
            msg->getU32(); // bossId
            msg->getU8(); // bossRace
        }
    }
}

void ProtocolGame::parseBosstiaryCooldownTimer(const InputMessagePtr& msg) {
    const uint16_t bossesOnTrackerSize = msg->getU16();
    for (uint_fast16_t i = 0; i < bossesOnTrackerSize; ++i) {
        msg->getU32(); // bossRaceId
        msg->getU64(); // Boss cooldown in seconds
    }
}

void ProtocolGame::parseBosstiaryEntryChanged(const InputMessagePtr& msg) {
    msg->getU32(); // bossId
}

void ProtocolGame::parseAttachedEffect(const InputMessagePtr& msg) {
    const uint32_t id = msg->getU32();
    const uint16_t attachedEffectId = msg->getU16();

    const auto& creature = g_map.getCreatureById(id);
    if (!creature) {
        g_logger.traceError(stdext::format("could not get creature with id %d", id));
        return;
    }

    const auto& effect = g_attachedEffects.getById(attachedEffectId);
    if (!effect)
        return;

    creature->attachEffect(effect->clone());
}

void ProtocolGame::parseDetachEffect(const InputMessagePtr& msg) {
    const uint32_t id = msg->getU32();
    const uint16_t attachedEffectId = msg->getU16();

    const auto& creature = g_map.getCreatureById(id);
    if (!creature) {
        g_logger.traceError(stdext::format("could not get creature with id %d", id));
        return;
    }

    creature->detachEffectById(attachedEffectId);
}

void ProtocolGame::parseCreatureShader(const InputMessagePtr& msg) {
    const uint32_t id = msg->getU32();
    const auto& shaderName = msg->getString();

    const auto& creature = g_map.getCreatureById(id);
    if (!creature) {
        g_logger.traceError(stdext::format("could not get creature with id %d", id));
        return;
    }

    creature->setShader(shaderName);
}

void ProtocolGame::parseMapShader(const InputMessagePtr& msg) {
    const auto& shaderName = msg->getString();

    const auto& mapView = g_map.getMapView(0);
    if (mapView)
        mapView->setShader(shaderName, 0.f, 0.f);
}
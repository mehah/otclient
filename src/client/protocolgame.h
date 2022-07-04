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

#pragma once

#include "creature.h"
#include "declarations.h"
#include "protocolcodes.h"
#include <framework/net/protocol.h>

class ProtocolGame : public Protocol
{
public:
    void login(const std::string_view accountName, const std::string_view accountPassword, const std::string_view host, uint16_t port, const std::string_view characterName, const std::string_view authenticatorToken, const std::string_view sessionKey);
    void send(const OutputMessagePtr& outputMessage) override;

    void sendExtendedOpcode(uint8_t opcode, const std::string_view buffer);
    void sendLoginPacket(uint32_t challengeTimestamp, uint8_t challengeRandom);
    void sendEnterGame();
    void sendLogout();
    void sendPing();
    void sendPingBack();
    void sendAutoWalk(const std::vector<Otc::Direction>& path);
    void sendWalkNorth();
    void sendWalkEast();
    void sendWalkSouth();
    void sendWalkWest();
    void sendStop();
    void sendWalkNorthEast();
    void sendWalkSouthEast();
    void sendWalkSouthWest();
    void sendWalkNorthWest();
    void sendTurnNorth();
    void sendTurnEast();
    void sendTurnSouth();
    void sendTurnWest();
    void sendEquipItem(int itemId, int countOrSubType);
    void sendMove(const Position& fromPos, int thingId, int stackpos, const Position& toPos, int count);
    void sendInspectNpcTrade(int itemId, int count);
    void sendBuyItem(int itemId, int subType, int amount, bool ignoreCapacity, bool buyWithBackpack);
    void sendSellItem(int itemId, int subType, int amount, bool ignoreEquipped);
    void sendCloseNpcTrade();
    void sendRequestTrade(const Position& pos, int thingId, int stackpos, uint32_t creatureId);
    void sendInspectTrade(bool counterOffer, int index);
    void sendAcceptTrade();
    void sendRejectTrade();
    void sendUseItem(const Position& position, int itemId, int stackpos, int index);
    void sendUseItemWith(const Position& fromPos, int itemId, int fromStackPos, const Position& toPos, int toThingId, int toStackPos);
    void sendUseOnCreature(const Position& pos, int thingId, int stackpos, uint32_t creatureId);
    void sendRotateItem(const Position& pos, int thingId, int stackpos);
    void sendCloseContainer(int containerId);
    void sendUpContainer(int containerId);
    void sendEditText(uint32_t id, const std::string_view text);
    void sendEditList(uint32_t id, int doorId, const std::string_view text);
    void sendLook(const Position& position, int thingId, int stackpos);
    void sendLookCreature(uint32_t creatureId);
    void sendTalk(Otc::MessageMode mode, int channelId, const std::string_view receiver, const std::string_view message);
    void sendRequestChannels();
    void sendJoinChannel(int channelId);
    void sendLeaveChannel(int channelId);
    void sendOpenPrivateChannel(const std::string_view receiver);
    void sendOpenRuleViolation(const std::string_view reporter);
    void sendCloseRuleViolation(const std::string_view reporter);
    void sendCancelRuleViolation();
    void sendCloseNpcChannel();
    void sendChangeFightModes(Otc::FightModes fightMode, Otc::ChaseModes chaseMode, bool safeFight, Otc::PVPModes pvpMode);
    void sendAttack(uint32_t creatureId, uint32_t seq);
    void sendFollow(uint32_t creatureId, uint32_t seq);
    void sendInviteToParty(uint32_t creatureId);
    void sendJoinParty(uint32_t creatureId);
    void sendRevokeInvitation(uint32_t creatureId);
    void sendPassLeadership(uint32_t creatureId);
    void sendLeaveParty();
    void sendShareExperience(bool active);
    void sendOpenOwnChannel();
    void sendInviteToOwnChannel(const std::string_view name);
    void sendExcludeFromOwnChannel(const std::string_view name);
    void sendCancelAttackAndFollow();
    void sendRefreshContainer(int containerId);
    void sendRequestOutfit();
    void sendChangeOutfit(const Outfit& outfit);
    void sendMountStatus(bool mount);
    void sendAddVip(const std::string_view name);
    void sendRemoveVip(uint32_t playerId);
    void sendEditVip(uint32_t playerId, const std::string_view description, int iconId, bool notifyLogin);
    void sendBugReport(const std::string_view comment);
    void sendRuleViolation(const std::string_view target, int reason, int action, const std::string_view comment, const std::string_view statement, int statementId, bool ipBanishment);
    void sendDebugReport(const std::string_view a, const std::string_view b, const std::string_view c, const std::string_view d);
    void sendRequestQuestLog();
    void sendRequestQuestLine(int questId);
    void sendNewNewRuleViolation(int reason, int action, const std::string_view characterName, const std::string_view comment, const std::string_view translation);
    void sendRequestItemInfo(int itemId, int subType, int index);
    void sendAnswerModalDialog(uint32_t dialog, int button, int choice);
    void sendBrowseField(const Position& position);
    void sendSeekInContainer(int cid, int index);
    void sendBuyStoreOffer(int offerId, int productType, const std::string_view name);
    void sendRequestTransactionHistory(int page, int entriesPerPage);
    void sendRequestStoreOffers(const std::string_view categoryName, int serviceType);
    void sendOpenStore(int serviceType, const std::string_view category);
    void sendTransferCoins(const std::string_view recipient, int amount);
    void sendOpenTransactionHistory(int entriesPerPage);

    // otclient only
    void sendChangeMapAwareRange(int xrange, int yrange);

protected:
    void onConnect() override;
    void onRecv(const InputMessagePtr& inputMessage) override;
    void onError(const std::error_code& error) override;

    friend class Game;

public:
    void addPosition(const OutputMessagePtr& msg, const Position& position);

private:
    void parseStoreButtonIndicators(const InputMessagePtr& msg);
    void parseSetStoreDeepLink(const InputMessagePtr& msg);
    void parseStore(const InputMessagePtr& msg);
    void parseStoreError(const InputMessagePtr& msg);
    void parseStoreTransactionHistory(const InputMessagePtr& msg);
    void parseStoreOffers(const InputMessagePtr& msg);
    void parseCompleteStorePurchase(const InputMessagePtr& msg);
    void parseRequestPurchaseData(const InputMessagePtr& msg);
    void parseResourceBalance(const InputMessagePtr& msg);
    void parseWorldTime(const InputMessagePtr& msg);
    void parseCoinBalance(const InputMessagePtr& msg);
    void parseCoinBalanceUpdating(const InputMessagePtr& msg);
    void parseBlessings(const InputMessagePtr& msg);
    void parseUnjustifiedStats(const InputMessagePtr& msg);
    void parsePvpSituations(const InputMessagePtr& msg);
    void parsePreset(const InputMessagePtr& msg);
    void parseCreatureType(const InputMessagePtr& msg);
    void parsePlayerHelpers(const InputMessagePtr& msg);
    void parseMessage(const InputMessagePtr& msg);
    void parsePendingGame(const InputMessagePtr& msg);
    void parseEnterGame(const InputMessagePtr& msg);
    void parseLogin(const InputMessagePtr& msg);
    void parseGMActions(const InputMessagePtr& msg);
    void parseUpdateNeeded(const InputMessagePtr& msg);
    void parseLoginError(const InputMessagePtr& msg);
    void parseLoginAdvice(const InputMessagePtr& msg);
    void parseLoginWait(const InputMessagePtr& msg);
    void parseSessionEnd(const InputMessagePtr& msg);
    void parsePing(const InputMessagePtr& msg);
    void parsePingBack(const InputMessagePtr& msg);
    void parseChallenge(const InputMessagePtr& msg);
    void parseDeath(const InputMessagePtr& msg);
    void parseFloorDescription(const InputMessagePtr& msg);
    void parseMapDescription(const InputMessagePtr& msg);
    void parseMapMoveNorth(const InputMessagePtr& msg);
    void parseMapMoveEast(const InputMessagePtr& msg);
    void parseMapMoveSouth(const InputMessagePtr& msg);
    void parseMapMoveWest(const InputMessagePtr& msg);
    void parseUpdateTile(const InputMessagePtr& msg);
    void parseTileAddThing(const InputMessagePtr& msg);
    void parseTileTransformThing(const InputMessagePtr& msg);
    void parseTileRemoveThing(const InputMessagePtr& msg);
    void parseCreatureMove(const InputMessagePtr& msg);
    void parseOpenContainer(const InputMessagePtr& msg);
    void parseCloseContainer(const InputMessagePtr& msg);
    void parseContainerAddItem(const InputMessagePtr& msg);
    void parseContainerUpdateItem(const InputMessagePtr& msg);
    void parseContainerRemoveItem(const InputMessagePtr& msg);
    void parseAddInventoryItem(const InputMessagePtr& msg);
    void parseRemoveInventoryItem(const InputMessagePtr& msg);
    void parseOpenNpcTrade(const InputMessagePtr& msg);
    void parsePlayerGoods(const InputMessagePtr& msg);
    void parseCloseNpcTrade(const InputMessagePtr&);
    void parseWorldLight(const InputMessagePtr& msg);
    void parseMagicEffect(const InputMessagePtr& msg);
    void parseAnimatedText(const InputMessagePtr& msg);
    void parseDistanceMissile(const InputMessagePtr& msg);
    void parseItemClasses(const InputMessagePtr& msg);
    void parseCreatureMark(const InputMessagePtr& msg);
    void parseTrappers(const InputMessagePtr& msg);
    void parseCreatureHealth(const InputMessagePtr& msg);
    void parseCreatureLight(const InputMessagePtr& msg);
    void parseCreatureOutfit(const InputMessagePtr& msg);
    void parseCreatureSpeed(const InputMessagePtr& msg);
    void parseCreatureSkulls(const InputMessagePtr& msg);
    void parseCreatureShields(const InputMessagePtr& msg);
    void parseCreatureUnpass(const InputMessagePtr& msg);
    void parseEditText(const InputMessagePtr& msg);
    void parseEditList(const InputMessagePtr& msg);
    void parsePremiumTrigger(const InputMessagePtr& msg);
    void parsePlayerInfo(const InputMessagePtr& msg);
    void parsePlayerStats(const InputMessagePtr& msg);
    void parsePlayerSkills(const InputMessagePtr& msg);
    void parsePlayerState(const InputMessagePtr& msg);
    void parsePlayerCancelAttack(const InputMessagePtr& msg);
    void parsePlayerModes(const InputMessagePtr& msg);
    void parseSpellCooldown(const InputMessagePtr& msg);
    void parseSpellGroupCooldown(const InputMessagePtr& msg);
    void parseMultiUseCooldown(const InputMessagePtr& msg);
    void parseTalk(const InputMessagePtr& msg);
    void parseChannelList(const InputMessagePtr& msg);
    void parseOpenChannel(const InputMessagePtr& msg);
    void parseOpenPrivateChannel(const InputMessagePtr& msg);
    void parseOpenOwnPrivateChannel(const InputMessagePtr& msg);
    void parseCloseChannel(const InputMessagePtr& msg);
    void parseRuleViolationChannel(const InputMessagePtr& msg);
    void parseRuleViolationRemove(const InputMessagePtr& msg);
    void parseRuleViolationCancel(const InputMessagePtr& msg);
    void parseRuleViolationLock(const InputMessagePtr& msg);
    void parseOwnTrade(const InputMessagePtr& msg);
    void parseCounterTrade(const InputMessagePtr& msg);
    void parseCloseTrade(const InputMessagePtr&);
    void parseTextMessage(const InputMessagePtr& msg);
    void parseCancelWalk(const InputMessagePtr& msg);
    void parseWalkWait(const InputMessagePtr& msg);
    void parseFloorChangeUp(const InputMessagePtr& msg);
    void parseFloorChangeDown(const InputMessagePtr& msg);
    void parseKillTracker(const InputMessagePtr& msg);
    void parseOpenOutfitWindow(const InputMessagePtr& msg);
    void parseVipAdd(const InputMessagePtr& msg);
    void parseVipState(const InputMessagePtr& msg);
    void parseVipLogout(const InputMessagePtr& msg);
    void parseTutorialHint(const InputMessagePtr& msg);
    void parseAutomapFlag(const InputMessagePtr& msg);
    void parseQuestLog(const InputMessagePtr& msg);
    void parseQuestLine(const InputMessagePtr& msg);
    void parseChannelEvent(const InputMessagePtr& msg);
    void parseItemInfo(const InputMessagePtr& msg);
    void parsePlayerInventory(const InputMessagePtr& msg);
    void parseModalDialog(const InputMessagePtr& msg);
    void parseExtendedOpcode(const InputMessagePtr& msg);
    void parseChangeMapAwareRange(const InputMessagePtr& msg);
    void parseCreaturesMark(const InputMessagePtr& msg);
    // 12x
    void parseShowDescription(const InputMessagePtr& msg);
    void parseBestiaryTracker(const InputMessagePtr& msg);
    void parseTaskHuntingBasicData(const InputMessagePtr& msg);
    void parseTaskHuntingData(const InputMessagePtr& msg);
    void parseExperienceTracker(const InputMessagePtr& msg);
    void parseLootContainers(const InputMessagePtr& msg);
    void parseSupplyStash(const InputMessagePtr& msg);
    void parseSpecialContainer(const InputMessagePtr& msg);
    void parsePartyAnalyzer(const InputMessagePtr& msg);
    void parseClientCheck(const InputMessagePtr& msg);
    void parseGameNews(const InputMessagePtr& msg);
    void parseBlessDialog(const InputMessagePtr& msg);
    void parseRestingAreaState(const InputMessagePtr& msg);
    void parseUpdateImpactTracker(const InputMessagePtr& msg);
    void parseItemsPrice(const InputMessagePtr& msg);
    void parseUpdateSupplyTracker(const InputMessagePtr& msg);
    void parseUpdateLootTracker(const InputMessagePtr& msg);
    void parseBestiaryEntryChanged(const InputMessagePtr& msg);
    void parseDailyRewardCollectionState(const InputMessagePtr& msg);
    void parseOpenRewardWall(const InputMessagePtr& msg);
    void parseDailyReward(const InputMessagePtr& msg);
    void parseRewardHistory(const InputMessagePtr& msg);
    void parsePreyTimeLeft(const InputMessagePtr& msg);
    void getPreyMonster(const InputMessagePtr& msg);
    void getPreyMonsters(const InputMessagePtr& msg);
    void parsePreyData(const InputMessagePtr& msg);
    void parsePreyRerollPrice(const InputMessagePtr& msg);
    void getImbuementInfo(const InputMessagePtr& msg);
    void parseImbuementWindow(const InputMessagePtr& msg);
    void parseCloseImbuementWindow(const InputMessagePtr& msg);
    void parseError(const InputMessagePtr& msg);

public:
    void setMapDescription(const InputMessagePtr& msg, int x, int y, int z, int width, int height);
    int setFloorDescription(const InputMessagePtr& msg, int x, int y, int z, int width, int height, int offset, int skip);
    int setTileDescription(const InputMessagePtr& msg, Position position);

    Outfit getOutfit(const InputMessagePtr& msg, bool parseMount = true);
    ThingPtr getThing(const InputMessagePtr& msg);
    ThingPtr getMappedThing(const InputMessagePtr& msg);
    CreaturePtr getCreature(const InputMessagePtr& msg, int type = 0);
    StaticTextPtr getStaticText(const InputMessagePtr& msg, int type = 0);
    ItemPtr getItem(const InputMessagePtr& msg, int id = 0);
    Position getPosition(const InputMessagePtr& msg);

private:
    bool m_enableSendExtendedOpcode{ false },
        m_gameInitialized{ false },
        m_mapKnown{ false },
        m_firstRecv{ true };

    std::string m_accountName;
    std::string m_accountPassword;
    std::string m_authenticatorToken;
    std::string m_sessionKey;
    std::string m_characterName;
    LocalPlayerPtr m_localPlayer;
};

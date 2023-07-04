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

#include <framework/core/application.h>
#include <framework/platform/platform.h>
#include <framework/util/crypt.h>
#include "game.h"
#include "protocolgame.h"
#include "framework/net/outputmessage.h"

void ProtocolGame::send(const OutputMessagePtr& outputMessage)
{
    // avoid usage of automated sends (bot modules)
    if (!g_game.checkBotProtection())
        return;
    Protocol::send(outputMessage);
}

void ProtocolGame::sendExtendedOpcode(uint8_t opcode, const std::string& buffer)
{
    if (m_enableSendExtendedOpcode) {
        const auto& msg = std::make_shared<OutputMessage>();
        msg->addU8(Proto::ClientExtendedOpcode);
        msg->addU8(opcode);
        msg->addString(buffer);
        send(msg);
    } else {
        g_logger.error(stdext::format("Unable to send extended opcode %d, extended opcodes are not enabled", opcode));
    }
}

void ProtocolGame::sendLoginPacket(uint32_t challengeTimestamp, uint8_t challengeRandom)
{
    const auto& msg = std::make_shared<OutputMessage>();

    msg->addU8(Proto::ClientPendingGame);
    msg->addU16(g_game.getOs());
    msg->addU16(g_game.getProtocolVersion());

    if (g_game.getFeature(Otc::GameClientVersion))
        msg->addU32(g_game.getClientVersion());

    if (g_game.getClientVersion() >= 1281) {
        msg->addString(std::to_string(g_game.getClientVersion()));
    }

    if (g_game.getFeature(Otc::GameContentRevision))
        msg->addU16(g_things.getContentRevision());

    if (g_game.getFeature(Otc::GamePreviewState))
        msg->addU8(0);

    const int offset = msg->getMessageSize();

    if (g_game.getFeature(Otc::GameLoginPacketEncryption)) {
        // first RSA byte must be 0
        msg->addU8(0);
        // xtea key
        generateXteaKey();
        msg->addU32(m_xteaKey[0]);
        msg->addU32(m_xteaKey[1]);
        msg->addU32(m_xteaKey[2]);
        msg->addU32(m_xteaKey[3]);
    }

    msg->addU8(0); // is gm set?

    if (g_game.getFeature(Otc::GameSessionKey)) {
        msg->addString(m_sessionKey);
        msg->addString(m_characterName);
    } else {
        if (g_game.getFeature(Otc::GameAccountNames))
            msg->addString(m_accountName);
        else
            msg->addU32(stdext::from_string<uint32_t >(m_accountName));

        msg->addString(m_characterName);
        msg->addString(m_accountPassword);

        if (g_game.getFeature(Otc::GameAuthenticator))
            msg->addString(m_authenticatorToken);
    }

    if (g_game.getFeature(Otc::GameChallengeOnLogin)) {
        msg->addU32(challengeTimestamp);
        msg->addU8(challengeRandom);
    }

    const auto& extended = callLuaField<std::string>("getLoginExtendedData");
    if (!extended.empty())
        msg->addString(extended);

    // complete the bytes for rsa encryption with zeros
    const int paddingBytes = g_crypt.rsaGetSize() - (msg->getMessageSize() - offset);
    assert(paddingBytes >= 0);
    msg->addPaddingBytes(paddingBytes);

    // encrypt with RSA
    if (g_game.getFeature(Otc::GameLoginPacketEncryption))
        msg->encryptRsa();

    if (g_game.getFeature(Otc::GameProtocolChecksum))
        enableChecksum();

    send(msg);

    if (g_game.getFeature(Otc::GameLoginPacketEncryption))
        enableXteaEncryption();

    if (g_game.getFeature(Otc::GameSequencedPackets))
        enabledSequencedPackets();
}

void ProtocolGame::sendEnterGame()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientEnterGame);
    send(msg);
}

void ProtocolGame::sendLogout()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientLeaveGame);
    send(msg);
}

void ProtocolGame::sendPing()
{
    if (g_game.getFeature(Otc::GameExtendedClientPing))
        sendExtendedOpcode(2, "");
    else {
        const auto& msg = std::make_shared<OutputMessage>();
        msg->addU8(Proto::ClientPing);
        Protocol::send(msg);
    }
}

void ProtocolGame::sendPingBack()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientPingBack);
    send(msg);
}

void ProtocolGame::sendAutoWalk(const std::vector<Otc::Direction>& path)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientAutoWalk);
    msg->addU8(path.size());
    for (const Otc::Direction dir : path) {
        uint8_t byte;
        switch (dir) {
            case Otc::East:
                byte = 1;
                break;
            case Otc::NorthEast:
                byte = 2;
                break;
            case Otc::North:
                byte = 3;
                break;
            case Otc::NorthWest:
                byte = 4;
                break;
            case Otc::West:
                byte = 5;
                break;
            case Otc::SouthWest:
                byte = 6;
                break;
            case Otc::South:
                byte = 7;
                break;
            case Otc::SouthEast:
                byte = 8;
                break;
            default:
                byte = 0;
                break;
        }
        msg->addU8(byte);
    }
    send(msg);
}

void ProtocolGame::sendWalkNorth()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientWalkNorth);
    send(msg);
}

void ProtocolGame::sendWalkEast()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientWalkEast);
    send(msg);
}

void ProtocolGame::sendWalkSouth()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientWalkSouth);
    send(msg);
}

void ProtocolGame::sendWalkWest()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientWalkWest);
    send(msg);
}

void ProtocolGame::sendStop()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientStop);
    send(msg);
}

void ProtocolGame::sendWalkNorthEast()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientWalkNorthEast);
    send(msg);
}

void ProtocolGame::sendWalkSouthEast()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientWalkSouthEast);
    send(msg);
}

void ProtocolGame::sendWalkSouthWest()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientWalkSouthWest);
    send(msg);
}

void ProtocolGame::sendWalkNorthWest()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientWalkNorthWest);
    send(msg);
}

void ProtocolGame::sendTurnNorth()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientTurnNorth);
    send(msg);
}

void ProtocolGame::sendTurnEast()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientTurnEast);
    send(msg);
}

void ProtocolGame::sendTurnSouth()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientTurnSouth);
    send(msg);
}

void ProtocolGame::sendTurnWest()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientTurnWest);
    send(msg);
}

void ProtocolGame::sendEquipItem(int itemId, int countOrSubType)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientEquipItem);
    msg->addU16(itemId);
    msg->addU8(countOrSubType);
    send(msg);
}

void ProtocolGame::sendMove(const Position& fromPos, int thingId, int stackpos, const Position& toPos, int count)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientMove);
    addPosition(msg, fromPos);
    msg->addU16(thingId);
    msg->addU8(stackpos);
    addPosition(msg, toPos);
    msg->addU8(count);
    send(msg);
}

void ProtocolGame::sendInspectNpcTrade(int itemId, int count)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientInspectNpcTrade);
    msg->addU16(itemId);
    msg->addU8(count);
    send(msg);
}

void ProtocolGame::sendBuyItem(int itemId, int subType, int amount, bool ignoreCapacity, bool buyWithBackpack)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientBuyItem);
    msg->addU16(itemId);
    msg->addU8(subType);
    if (g_game.getFeature(Otc::GameDoubleShopSellAmount))
        msg->addU16(amount);
    else
        msg->addU8(amount);
    msg->addU8(ignoreCapacity ? 0x01 : 0x00);
    msg->addU8(buyWithBackpack ? 0x01 : 0x00);
    send(msg);
}

void ProtocolGame::sendSellItem(int itemId, int subType, int amount, bool ignoreEquipped)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientSellItem);
    msg->addU16(itemId);
    msg->addU8(subType);
    if (g_game.getFeature(Otc::GameDoubleShopSellAmount))
        msg->addU16(amount);
    else
        msg->addU8(amount);
    msg->addU8(ignoreEquipped ? 0x01 : 0x00);
    send(msg);
}

void ProtocolGame::sendCloseNpcTrade()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientCloseNpcTrade);
    send(msg);
}

void ProtocolGame::sendRequestTrade(const Position& pos, int thingId, int stackpos, uint32_t creatureId)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientRequestTrade);
    addPosition(msg, pos);
    msg->addU16(thingId);
    msg->addU8(stackpos);
    msg->addU32(creatureId);
    send(msg);
}

void ProtocolGame::sendInspectTrade(bool counterOffer, int index)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientInspectTrade);
    msg->addU8(counterOffer ? 0x01 : 0x00);
    msg->addU8(index);
    send(msg);
}

void ProtocolGame::sendAcceptTrade()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientAcceptTrade);
    send(msg);
}

void ProtocolGame::sendRejectTrade()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientRejectTrade);
    send(msg);
}

void ProtocolGame::sendUseItem(const Position& position, int itemId, int stackpos, int index)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientUseItem);
    addPosition(msg, position);
    msg->addU16(itemId);
    msg->addU8(stackpos);
    msg->addU8(index);
    send(msg);
}

void ProtocolGame::sendUseItemWith(const Position& fromPos, int itemId, int fromStackPos, const Position& toPos, int toThingId, int toStackPos)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientUseItemWith);
    addPosition(msg, fromPos);
    msg->addU16(itemId);
    msg->addU8(fromStackPos);
    addPosition(msg, toPos);
    msg->addU16(toThingId);
    msg->addU8(toStackPos);
    send(msg);
}

void ProtocolGame::sendUseOnCreature(const Position& pos, int thingId, int stackpos, uint32_t creatureId)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientUseOnCreature);
    addPosition(msg, pos);
    msg->addU16(thingId);
    msg->addU8(stackpos);
    msg->addU32(creatureId);
    send(msg);
}

void ProtocolGame::sendRotateItem(const Position& pos, int thingId, int stackpos)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientRotateItem);
    addPosition(msg, pos);
    msg->addU16(thingId);
    msg->addU8(stackpos);
    send(msg);
}

void ProtocolGame::sendOnWrapItem(const Position& pos, int thingId, int stackpos)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientOnWrapItem);
    addPosition(msg, pos);
    msg->addU16(thingId);
    msg->addU8(stackpos);
    send(msg);
}

void ProtocolGame::sendCloseContainer(int containerId)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientCloseContainer);
    msg->addU8(containerId);
    send(msg);
}

void ProtocolGame::sendUpContainer(int containerId)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientUpContainer);
    msg->addU8(containerId);
    send(msg);
}

void ProtocolGame::sendEditText(uint32_t id, const std::string_view text)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientEditText);
    msg->addU32(id);
    msg->addString(text);
    send(msg);
}

void ProtocolGame::sendEditList(uint32_t id, int doorId, const std::string_view text)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientEditList);
    msg->addU8(doorId);
    msg->addU32(id);
    msg->addString(text);
    send(msg);
}

void ProtocolGame::sendLook(const Position& position, int thingId, int stackpos)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientLook);
    addPosition(msg, position);
    msg->addU16(thingId);
    msg->addU8(stackpos);
    send(msg);
}

void ProtocolGame::sendLookCreature(uint32_t creatureId)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientLookCreature);
    msg->addU32(creatureId);
    send(msg);
}

void ProtocolGame::sendTalk(Otc::MessageMode mode, int channelId, const std::string_view receiver, const std::string_view message)
{
    if (message.empty())
        return;

    if (message.length() > UINT8_MAX) {
        g_logger.traceError("message too large");
        return;
    }

    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientTalk);
    msg->addU8(Proto::translateMessageModeToServer(mode));

    switch (mode) {
        case Otc::MessagePrivateTo:
        case Otc::MessageGamemasterPrivateTo:
        case Otc::MessageRVRAnswer:
            msg->addString(receiver);
            break;
        case Otc::MessageChannel:
        case Otc::MessageChannelHighlight:
        case Otc::MessageChannelManagement:
        case Otc::MessageGamemasterChannel:
            msg->addU16(channelId);
            break;
        default:
            break;
    }

    msg->addString(message);
    send(msg);
}

void ProtocolGame::sendRequestChannels()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientRequestChannels);
    send(msg);
}

void ProtocolGame::sendJoinChannel(int channelId)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientJoinChannel);
    msg->addU16(channelId);
    send(msg);
}

void ProtocolGame::sendLeaveChannel(int channelId)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientLeaveChannel);
    msg->addU16(channelId);
    send(msg);
}

void ProtocolGame::sendOpenPrivateChannel(const std::string_view receiver)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientOpenPrivateChannel);
    msg->addString(receiver);
    send(msg);
}

void ProtocolGame::sendOpenRuleViolation(const std::string_view reporter)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientOpenRuleViolation);
    msg->addString(reporter);
    send(msg);
}

void ProtocolGame::sendCloseRuleViolation(const std::string_view reporter)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientCloseRuleViolation);
    msg->addString(reporter);
    send(msg);
}

void ProtocolGame::sendCancelRuleViolation()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientCancelRuleViolation);
    send(msg);
}

void ProtocolGame::sendCloseNpcChannel()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientCloseNpcChannel);
    send(msg);
}

void ProtocolGame::sendChangeFightModes(Otc::FightModes fightMode, Otc::ChaseModes chaseMode, bool safeFight, Otc::PVPModes pvpMode)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientChangeFightModes);
    msg->addU8(fightMode);
    msg->addU8(chaseMode);
    msg->addU8(safeFight ? 0x01 : 0x00);
    if (g_game.getFeature(Otc::GamePVPMode))
        msg->addU8(pvpMode);
    send(msg);
}

void ProtocolGame::sendAttack(uint32_t creatureId, uint32_t seq)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientAttack);
    msg->addU32(creatureId);
    if (g_game.getFeature(Otc::GameAttackSeq))
        msg->addU32(seq);
    send(msg);
}

void ProtocolGame::sendFollow(uint32_t creatureId, uint32_t seq)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientFollow);
    msg->addU32(creatureId);
    if (g_game.getFeature(Otc::GameAttackSeq))
        msg->addU32(seq);
    send(msg);
}

void ProtocolGame::sendInviteToParty(uint32_t creatureId)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientInviteToParty);
    msg->addU32(creatureId);
    send(msg);
}

void ProtocolGame::sendJoinParty(uint32_t creatureId)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientJoinParty);
    msg->addU32(creatureId);
    send(msg);
}

void ProtocolGame::sendRevokeInvitation(uint32_t creatureId)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientRevokeInvitation);
    msg->addU32(creatureId);
    send(msg);
}

void ProtocolGame::sendPassLeadership(uint32_t creatureId)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientPassLeadership);
    msg->addU32(creatureId);
    send(msg);
}

void ProtocolGame::sendLeaveParty()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientLeaveParty);
    send(msg);
}

void ProtocolGame::sendShareExperience(bool active)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientShareExperience);
    msg->addU8(active ? 0x01 : 0x00);
    if (g_game.getClientVersion() < 910)
        msg->addU8(0);
    send(msg);
}

void ProtocolGame::sendOpenOwnChannel()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientOpenOwnChannel);
    send(msg);
}

void ProtocolGame::sendInviteToOwnChannel(const std::string_view name)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientInviteToOwnChannel);
    msg->addString(name);
    send(msg);
}

void ProtocolGame::sendExcludeFromOwnChannel(const std::string_view name)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientExcludeFromOwnChannel);
    msg->addString(name);
    send(msg);
}

void ProtocolGame::sendCancelAttackAndFollow()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientCancelAttackAndFollow);
    send(msg);
}

void ProtocolGame::sendRefreshContainer(int containerId)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientRefreshContainer);
    msg->addU8(containerId);
    send(msg);
}

void ProtocolGame::sendRequestOutfit()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientRequestOutfit);
    send(msg);
}

void ProtocolGame::sendChangeOutfit(const Outfit& outfit)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientChangeOutfit);

    if (g_game.getClientVersion() >= 1281) {
        msg->addU8(0x00); // normal outfit window
    }

    if (g_game.getFeature(Otc::GameLooktypeU16))
        msg->addU16(outfit.getId());
    else
        msg->addU8(outfit.getId());

    msg->addU8(outfit.getHead());
    msg->addU8(outfit.getBody());
    msg->addU8(outfit.getLegs());
    msg->addU8(outfit.getFeet());

    if (g_game.getFeature(Otc::GamePlayerAddons))
        msg->addU8(outfit.getAddons());

    if (g_game.getFeature(Otc::GamePlayerMounts)) {
        msg->addU16(outfit.getMount());
        if (g_game.getClientVersion() >= 1281) {
            msg->addU8(0x00);
            msg->addU8(0x00);
            msg->addU8(0x00);
            msg->addU8(0x00);
        }
    }

    if (g_game.getClientVersion() >= 1281) {
        msg->addU16(0x00); //familiars
        msg->addU8(0x00); //randomizeMount
    }

    send(msg);
}

void ProtocolGame::sendMountStatus(bool mount)
{
    if (g_game.getFeature(Otc::GamePlayerMounts)) {
        const auto& msg = std::make_shared<OutputMessage>();
        msg->addU8(Proto::ClientMount);
        msg->addU8(mount);
        send(msg);
    } else {
        g_logger.error("ProtocolGame::sendMountStatus does not support the current protocol.");
    }
}

void ProtocolGame::sendAddVip(const std::string_view name)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientAddVip);
    msg->addString(name);
    send(msg);
}

void ProtocolGame::sendRemoveVip(uint32_t playerId)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientRemoveVip);
    msg->addU32(playerId);
    send(msg);
}

void ProtocolGame::sendEditVip(uint32_t playerId, const std::string_view description, int iconId, bool notifyLogin)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientEditVip);
    msg->addU32(playerId);
    msg->addString(description);
    msg->addU32(iconId);
    msg->addU8(notifyLogin);
    send(msg);
}

void ProtocolGame::sendBugReport(const std::string_view comment)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientBugReport);
    if (g_game.getProtocolVersion() > 1000) {
        msg->addU8(3); // category
    }
    msg->addString(comment);
    send(msg);
}

void ProtocolGame::sendRuleViolation(const std::string_view target, int reason, int action, const std::string_view comment, const std::string_view statement, int statementId, bool ipBanishment)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientRuleViolation);
    msg->addString(target);
    msg->addU8(reason);
    msg->addU8(action);
    msg->addString(comment);
    msg->addString(statement);
    msg->addU16(statementId);
    msg->addU8(ipBanishment);
    send(msg);
}

void ProtocolGame::sendDebugReport(const std::string_view a, const std::string_view b, const std::string_view c, const std::string_view d)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientDebugReport);
    msg->addString(a);
    msg->addString(b);
    msg->addString(c);
    msg->addString(d);
    send(msg);
}

void ProtocolGame::sendRequestQuestLog()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientRequestQuestLog);
    send(msg);
}

void ProtocolGame::sendRequestQuestLine(int questId)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientRequestQuestLine);
    msg->addU16(questId);
    send(msg);
}

void ProtocolGame::sendNewNewRuleViolation(int reason, int action, const std::string_view characterName, const std::string_view comment, const std::string_view translation)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientNewRuleViolation);
    msg->addU8(reason);
    msg->addU8(action);
    msg->addString(characterName);
    msg->addString(comment);
    msg->addString(translation);
    send(msg);
}

void ProtocolGame::sendRequestItemInfo(int itemId, int subType, int index)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientRequestItemInfo);
    msg->addU8(subType);
    msg->addU16(itemId);
    msg->addU8(index);
    send(msg);
}

void ProtocolGame::sendAnswerModalDialog(uint32_t dialog, int button, int choice)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientAnswerModalDialog);
    msg->addU32(dialog);
    msg->addU8(button);
    msg->addU8(choice);
    send(msg);
}

void ProtocolGame::sendBrowseField(const Position& position)
{
    if (!g_game.getFeature(Otc::GameBrowseField))
        return;

    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientBrowseField);
    addPosition(msg, position);
    send(msg);
}

void ProtocolGame::sendSeekInContainer(int cid, int index)
{
    if (!g_game.getFeature(Otc::GameContainerPagination))
        return;

    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientSeekInContainer);
    msg->addU8(cid);
    msg->addU16(index);
    send(msg);
}

void ProtocolGame::sendBuyStoreOffer(int offerId, int productType, const std::string_view name)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientBuyStoreOffer);
    msg->addU32(offerId);
    msg->addU8(productType);

    if (productType == Otc::ProductTypeNameChange)
        msg->addString(name);

    send(msg);
}

void ProtocolGame::sendRequestTransactionHistory(int page, int entriesPerPage)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientRequestTransactionHistory);
    if (g_game.getClientVersion() <= 1096) {
        msg->addU16(page);
        msg->addU32(entriesPerPage);
    } else {
        msg->addU32(page);
        msg->addU8(entriesPerPage);
    }

    send(msg);
}

void ProtocolGame::sendRequestStoreOffers(const std::string_view categoryName, int serviceType)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientRequestStoreOffers);

    if (g_game.getFeature(Otc::GameIngameStoreServiceType)) {
        msg->addU8(serviceType);
    }
    msg->addString(categoryName);

    send(msg);
}

void ProtocolGame::sendOpenStore(int serviceType, const std::string_view category)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientOpenStore);

    if (g_game.getFeature(Otc::GameIngameStoreServiceType)) {
        msg->addU8(serviceType);
        msg->addString(category);
    }

    send(msg);
}

void ProtocolGame::sendTransferCoins(const std::string_view recipient, int amount)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientTransferCoins);
    msg->addString(recipient);
    msg->addU16(amount);
    send(msg);
}

void ProtocolGame::sendOpenTransactionHistory(int entriesPerPage)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientOpenTransactionHistory);
    msg->addU8(entriesPerPage);

    send(msg);
}

void ProtocolGame::sendChangeMapAwareRange(int xrange, int yrange)
{
    if (!g_game.getFeature(Otc::GameChangeMapAwareRange))
        return;

    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientChangeMapAwareRange);
    msg->addU8(xrange);
    msg->addU8(yrange);
    send(msg);
}

void ProtocolGame::addPosition(const OutputMessagePtr& msg, const Position& position)
{
    msg->addU16(position.x);
    msg->addU16(position.y);
    msg->addU8(position.z);
}

void ProtocolGame::sendMarketLeave()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientMarketLeave);
    send(msg);
}

void ProtocolGame::sendMarketBrowse(uint8_t browseId, uint16_t browseType)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientMarketBrowse);
    if (g_game.getClientVersion() >= 1251) {
        msg->addU8(browseId);
        if (browseType > 0) {
            msg->addU16(browseType);
        }
    } else {
        msg->addU16(browseType);
    }
    send(msg);
}

void ProtocolGame::sendMarketCreateOffer(uint8_t type, uint16_t itemId, uint8_t itemTier, uint16_t amount, uint64_t price, uint8_t anonymous)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientMarketCreate);
    msg->addU8(type);
    msg->addU16(itemId);
    if (const auto& item = Item::create(itemId)) {
        if (item->getClassification() > 0) {
            msg->addU8(itemTier);
        }
    }
    msg->addU16(amount);
    msg->addU64(price);
    msg->addU8(anonymous);
    send(msg);
}

void ProtocolGame::sendMarketCancelOffer(uint32_t timestamp, uint16_t counter)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientMarketCancel);
    msg->addU32(timestamp);
    msg->addU16(counter);
    send(msg);
}

void ProtocolGame::sendMarketAcceptOffer(uint32_t timestamp, uint16_t counter, uint16_t amount)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientMarketAccept);
    msg->addU32(timestamp);
    msg->addU16(counter);
    msg->addU16(amount);
    send(msg);
}

void ProtocolGame::sendPreyAction(uint8_t slot, uint8_t actionType, uint16_t index)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientPreyAction);
    msg->addU8(slot);
    msg->addU8(actionType);
    if (actionType == 2 || actionType == 5) {
        msg->addU8(index);
    } else if (actionType == 4) {
        msg->addU16(index); // raceid
        send(msg);
    }
}

void ProtocolGame::sendPreyRequest()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientPreyRequest);
    send(msg);
}

void ProtocolGame::sendApplyImbuement(uint8_t slot, uint32_t imbuementId, bool protectionCharm)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientApplyImbuement);
    msg->addU8(slot);
    msg->addU32(imbuementId);
    msg->addU8(protectionCharm ? 1 : 0);
    send(msg);
}

void ProtocolGame::sendClearImbuement(uint8_t slot)
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientClearImbuement);
    msg->addU8(slot);
    send(msg);
}

void ProtocolGame::sendCloseImbuingWindow()
{
    const auto& msg = std::make_shared<OutputMessage>();
    msg->addU8(Proto::ClientCloseImbuingWindow);
    send(msg);
}
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

#include "game.h"
#include <framework/core/application.h>
#include <framework/core/eventdispatcher.h>
#include "container.h"
#include "creature.h"
#include "localplayer.h"
#include "luavaluecasts_client.h"
#include "map.h"
#include "protocolcodes.h"
#include "protocolgame.h"

#include "tile.h"
#include "framework/core/graphicalapplication.h"

Game g_game;

void Game::init()
{
    resetGameStates();
}

void Game::terminate()
{
    resetGameStates();
    m_protocolGame = nullptr;
}

void Game::resetGameStates()
{
    m_online = false;
    enableBotCall();
    m_dead = false;
    m_serverBeat = 50;
    m_seq = 0;
    m_ping = -1;
    setCanReportBugs(false);
    m_fightMode = Otc::FightBalanced;
    m_chaseMode = Otc::DontChase;
    m_pvpMode = Otc::WhiteDove;
    m_safeFight = true;
    m_followingCreature = nullptr;
    m_attackingCreature = nullptr;
    m_localPlayer = nullptr;
    m_pingSent = 0;
    m_pingReceived = 0;
    m_unjustifiedPoints = UnjustifiedPoints();
    m_nextScheduledDir = Otc::InvalidDirection;

    for (const auto& it : m_containers) {
        const auto& container = it.second;
        if (container)
            container->onClose();
    }

    if (m_pingEvent) {
        m_pingEvent->cancel();
        m_pingEvent = nullptr;
    }

    if (m_walkEvent) {
        m_walkEvent->cancel();
        m_walkEvent = nullptr;
    }

    if (m_checkConnectionEvent) {
        m_checkConnectionEvent->cancel();
        m_checkConnectionEvent = nullptr;
    }

    m_containers.clear();
    m_vips.clear();
    m_gmActions.clear();
    g_map.resetAwareRange();
}

void Game::processConnectionError(const std::error_code& ec)
{
    // connection errors only have meaning if we still have a protocol
    if (m_protocolGame) {
        // eof = end of file, a clean disconnect
        if (ec != asio::error::eof)
            g_lua.callGlobalField("g_game", "onConnectionError", ec.message(), ec.value());

        processDisconnect();
    }
}

void Game::processDisconnect()
{
    if (isOnline())
        processGameEnd();

    if (m_protocolGame) {
        m_protocolGame->disconnect();
        m_protocolGame = nullptr;
    }
}

void Game::processUpdateNeeded(const std::string_view signature)
{
    g_lua.callGlobalField("g_game", "onUpdateNeeded", signature);
}

void Game::processLoginError(const std::string_view error)
{
    g_lua.callGlobalField("g_game", "onLoginError", error);
}

void Game::processLoginAdvice(const std::string_view message)
{
    g_lua.callGlobalField("g_game", "onLoginAdvice", message);
}

void Game::processLoginWait(const std::string_view message, const uint8_t time)
{
    g_lua.callGlobalField("g_game", "onLoginWait", message, time);
}

void Game::processSessionEnd(const uint8_t reason)
{
    g_lua.callGlobalField("g_game", "onSessionEnd", reason);
}

void Game::processLogin()
{
    g_lua.callGlobalField("g_game", "onLogin");
}

void Game::processPendingGame()
{
    m_localPlayer->setPendingGame(true);
    g_lua.callGlobalField("g_game", "onPendingGame");
    m_protocolGame->sendEnterGame();
}

void Game::processEnterGame()
{
    g_dispatcher.addEvent([localPlayer = m_localPlayer] {
        localPlayer->setPendingGame(false);
    });
    g_lua.callGlobalField("g_game", "onEnterGame");
}

void Game::processGameStart()
{
    m_online = true;
    g_app.resetTargetFps();

    // synchronize fight modes with the server
    m_protocolGame->sendChangeFightModes(m_fightMode, m_chaseMode, m_safeFight, m_pvpMode);

    // NOTE: the entire map description and local player information is not known yet (bot call is allowed here)
    enableBotCall();
    g_lua.callGlobalField("g_game", "onGameStart");
    disableBotCall();

    if (g_game.getFeature(Otc::GameClientPing) || g_game.getFeature(Otc::GameExtendedClientPing)) {
        m_pingEvent = g_dispatcher.scheduleEvent([] { g_game.ping(); }, m_pingDelay);
    }

    m_checkConnectionEvent = g_dispatcher.cycleEvent([this] {
        if (!g_game.isConnectionOk() && !m_connectionFailWarned) {
            g_lua.callGlobalField("g_game", "onConnectionFailing", true);
            m_connectionFailWarned = true;
        } else if (g_game.isConnectionOk() && m_connectionFailWarned) {
            g_lua.callGlobalField("g_game", "onConnectionFailing", false);
            m_connectionFailWarned = false;
        }
    }, 1000);
}

void Game::processGameEnd()
{
    // FPS fixed at 60 for when UI is rendering alone.
    g_app.setTargetFps(60u);

    m_online = false;
    g_lua.callGlobalField("g_game", "onGameEnd");

    if (m_connectionFailWarned) {
        g_lua.callGlobalField("g_game", "onConnectionFailing", false);
        m_connectionFailWarned = false;
    }

    // reset game state
    resetGameStates();

    m_worldName = "";
    m_characterName = "";

    // clean map creatures
    g_map.cleanDynamicThings();
}

void Game::processDeath(const uint8_t deathType, const uint8_t penality)
{
    m_dead = true;
    m_localPlayer->stopWalk();

    g_lua.callGlobalField("g_game", "onDeath", deathType, penality);
}

void Game::processGMActions(const std::vector<uint8_t>& actions)
{
    m_gmActions = actions;
    g_lua.callGlobalField("g_game", "onGMActions", actions);
}

void Game::processPlayerHelpers(const uint16_t helpers)
{
    g_lua.callGlobalField("g_game", "onPlayerHelpersUpdate", helpers);
}

void Game::processPlayerModes(const Otc::FightModes fightMode, const Otc::ChaseModes chaseMode, const bool safeMode, const Otc::PVPModes pvpMode)
{
    m_fightMode = fightMode;
    m_chaseMode = chaseMode;
    m_safeFight = safeMode;
    m_pvpMode = pvpMode;

    g_lua.callGlobalField("g_game", "onFightModeChange", fightMode);
    g_lua.callGlobalField("g_game", "onChaseModeChange", chaseMode);
    g_lua.callGlobalField("g_game", "onSafeFightChange", safeMode);
    g_lua.callGlobalField("g_game", "onPVPModeChange", pvpMode);
}

void Game::processPing()
{
    g_lua.callGlobalField("g_game", "onPing");
    enableBotCall();
    m_protocolGame->sendPingBack();
    disableBotCall();
}

void Game::processPingBack()
{
    ++m_pingReceived;

    if (m_pingReceived == m_pingSent) {
        const ticks_t oldPing = m_ping;

        m_ping = m_pingTimer.elapsed_millis();

        if (oldPing != m_ping)
            g_lua.callGlobalField("g_game", "onPingBack", m_ping);
    } else
        g_logger.error("got an invalid ping from server");

    m_pingEvent = g_dispatcher.scheduleEvent([] { g_game.ping(); }, m_pingDelay);
}

void Game::processTextMessage(const Otc::MessageMode mode, const std::string_view text)
{
    g_lua.callGlobalField("g_game", "onTextMessage", mode, text);
}

void Game::processTalk(const std::string_view name, const uint16_t level, const Otc::MessageMode mode, const std::string_view text, const uint16_t channelId, const Position& pos)
{
    g_lua.callGlobalField("g_game", "onTalk", name, level, mode, text, channelId, pos);
}

void Game::processOpenContainer(const uint8_t containerId, const ItemPtr& containerItem, const std::string_view name, const uint8_t capacity, const bool hasParent, const std::vector<ItemPtr>& items, const bool isUnlocked, const bool hasPages, const uint16_t containerSize, const uint16_t firstIndex)
{
    const auto& container(ContainerPtr(new Container(containerId, capacity, name, containerItem, hasParent, isUnlocked, hasPages, containerSize, firstIndex)));
    const auto previousContainer = getContainer(containerId);

    m_containers[containerId] = container;
    container->onAddItems(items);

    // we might want to close a container here
    enableBotCall();
    container->onOpen(previousContainer);
    disableBotCall();

    if (previousContainer)
        previousContainer->onClose();
}

void Game::processCloseContainer(const uint8_t containerId)
{
    if (const auto& container = getContainer(containerId)) {
        m_containers[containerId] = nullptr;
        container->onClose();
    }
}

void Game::processContainerAddItem(const uint8_t containerId, const ItemPtr& item, const uint16_t slot)
{
    if (const auto& container = getContainer(containerId))
        container->onAddItem(item, slot);
}

void Game::processContainerUpdateItem(const uint8_t containerId, const uint16_t slot, const ItemPtr& item)
{
    if (const auto& container = getContainer(containerId))
        container->onUpdateItem(slot, item);
}

void Game::processContainerRemoveItem(const uint8_t containerId, const uint16_t slot, const ItemPtr& lastItem)
{
    if (const auto& container = getContainer(containerId))
        container->onRemoveItem(slot, lastItem);
}

void Game::processInventoryChange(const uint8_t slot, const ItemPtr& item)
{
    if (item)
        item->setPosition(Position(UINT16_MAX, slot, 0));

    m_localPlayer->setInventoryItem(static_cast<Otc::InventorySlot>(slot), item);
}

void Game::processChannelList(const std::vector<std::tuple<uint16_t, std::string>>& channelList)
{
    g_lua.callGlobalField("g_game", "onChannelList", channelList);
}

void Game::processOpenChannel(const uint16_t channelId, const std::string_view name)
{
    g_lua.callGlobalField("g_game", "onOpenChannel", channelId, name);
}

void Game::processOpenPrivateChannel(const std::string_view name)
{
    g_lua.callGlobalField("g_game", "onOpenPrivateChannel", name);
}

void Game::processOpenOwnPrivateChannel(const uint16_t channelId, const std::string_view name)
{
    g_lua.callGlobalField("g_game", "onOpenOwnPrivateChannel", channelId, name);
}

void Game::processCloseChannel(const uint16_t channelId)
{
    g_lua.callGlobalField("g_game", "onCloseChannel", channelId);
}

void Game::processRuleViolationChannel(const uint16_t channelId)
{
    g_lua.callGlobalField("g_game", "onRuleViolationChannel", channelId);
}

void Game::processRuleViolationRemove(const std::string_view name)
{
    g_lua.callGlobalField("g_game", "onRuleViolationRemove", name);
}

void Game::processRuleViolationCancel(const std::string_view name)
{
    g_lua.callGlobalField("g_game", "onRuleViolationCancel", name);
}

void Game::processRuleViolationLock()
{
    g_lua.callGlobalField("g_game", "onRuleViolationLock");
}

void Game::processVipAdd(const uint32_t id, const std::string_view name, const uint32_t status, const std::string_view description, const uint32_t iconId, const bool notifyLogin)
{
    m_vips[id] = Vip(name, status, description, iconId, notifyLogin);
    g_lua.callGlobalField("g_game", "onAddVip", id, name, status, description, iconId, notifyLogin);
}

void Game::processVipStateChange(const uint32_t id, const uint32_t status)
{
    std::get<1>(m_vips[id]) = status;
    g_lua.callGlobalField("g_game", "onVipStateChange", id, status);
}

void Game::processTutorialHint(const uint8_t id)
{
    g_lua.callGlobalField("g_game", "onTutorialHint", id);
}

void Game::processAddAutomapFlag(const Position& pos, const uint8_t icon, const std::string_view message)
{
    g_lua.callGlobalField("g_game", "onAddAutomapFlag", pos, icon, message);
}

void Game::processRemoveAutomapFlag(const Position& pos, const uint8_t icon, const std::string_view message)
{
    g_lua.callGlobalField("g_game", "onRemoveAutomapFlag", pos, icon, message);
}

void Game::processOpenOutfitWindow(const Outfit& currentOutfit, const std::vector<std::tuple<uint16_t, std::string, uint8_t>>& outfitList,
                                   const std::vector<std::tuple<uint16_t, std::string>>& mountList,
                                   const std::vector<std::tuple<uint16_t, std::string>>& wingsList,
                                   const std::vector<std::tuple<uint16_t, std::string>>& aurasList,
                                   const std::vector<std::tuple<uint16_t, std::string>>& effectList,
                                   const std::vector<std::tuple<uint16_t, std::string>>& shaderList)
{
    // create virtual creature outfit
    const auto& virtualOutfitCreature = std::make_shared<Creature>();
    virtualOutfitCreature->setDirection(Otc::South);
    virtualOutfitCreature->setOutfit(currentOutfit);
    for (const auto& effect : m_localPlayer->getAttachedEffects())
        virtualOutfitCreature->attachEffect(effect->clone());

    // creature virtual mount outfit
    CreaturePtr virtualMountCreature;
    if (getFeature(Otc::GamePlayerMounts)) {
        Outfit mountOutfit;
        mountOutfit.setId(currentOutfit.getMount());
        mountOutfit.setCategory(ThingCategoryCreature);

        virtualMountCreature = std::make_shared<Creature>();
        virtualMountCreature->setDirection(Otc::South);
        virtualMountCreature->setOutfit(mountOutfit);
    }

    g_lua.callGlobalField("g_game", "onOpenOutfitWindow", virtualOutfitCreature, outfitList, virtualMountCreature, mountList, wingsList, aurasList, effectList, shaderList);
}

void Game::processOpenNpcTrade(const std::vector<std::tuple<ItemPtr, std::string, uint32_t, uint32_t, uint32_t>>& items)
{
    g_lua.callGlobalField("g_game", "onOpenNpcTrade", items);
}

void Game::processPlayerGoods(const uint64_t money, const std::vector<std::tuple<ItemPtr, uint16_t>>& goods)
{
    g_lua.callGlobalField("g_game", "onPlayerGoods", money, goods);
}

void Game::processCloseNpcTrade()
{
    g_lua.callGlobalField("g_game", "onCloseNpcTrade");
}

void Game::processOwnTrade(const std::string_view name, const std::vector<ItemPtr>& items)
{
    g_lua.callGlobalField("g_game", "onOwnTrade", name, items);
}

void Game::processCounterTrade(const std::string_view name, const std::vector<ItemPtr>& items)
{
    g_lua.callGlobalField("g_game", "onCounterTrade", name, items);
}

void Game::processCloseTrade()
{
    g_lua.callGlobalField("g_game", "onCloseTrade");
}

void Game::processEditText(const uint32_t id, const uint32_t itemId, const uint16_t maxLength, const std::string_view text, const std::string_view writer, const std::string_view date)
{
    g_lua.callGlobalField("g_game", "onEditText", id, itemId, maxLength, text, writer, date);
}

void Game::processEditList(const uint32_t id, const uint8_t doorId, const std::string_view text)
{
    g_lua.callGlobalField("g_game", "onEditList", id, doorId, text);
}

void Game::processQuestLog(const std::vector<std::tuple<uint16_t, std::string, bool>>& questList)
{
    g_lua.callGlobalField("g_game", "onQuestLog", questList);
}

void Game::processQuestLine(const uint16_t questId, const std::vector<std::tuple<std::string, std::string>>& questMissions)
{
    g_lua.callGlobalField("g_game", "onQuestLine", questId, questMissions);
}

void Game::processModalDialog(const uint32_t id, const std::string_view title, const std::string_view message, const std::vector<std::tuple<uint8_t, std::string>>
                                & buttonList, const uint8_t enterButton, const uint8_t escapeButton, const std::vector<std::tuple<uint8_t, std::string>>
                                & choiceList, const bool priority)
{
    g_lua.callGlobalField("g_game", "onModalDialog", id, title, message, buttonList, enterButton, escapeButton, choiceList, priority);
}

void Game::processAttackCancel(const uint32_t seq)
{
    if (isAttacking() && (seq == 0 || m_seq == seq))
        cancelAttack();
}

void Game::processWalkCancel(const Otc::Direction direction)
{
    m_localPlayer->cancelWalk(direction);
}

void Game::loginWorld(const std::string_view account, const std::string_view password, const std::string_view worldName, const std::string_view worldHost, int worldPort, const std::string_view characterName, const std::string_view authenticatorToken, const std::string_view sessionKey)
{
    if (m_protocolGame || isOnline())
        throw Exception("Unable to login into a world while already online or logging.");

    if (m_protocolVersion == 0)
        throw Exception("Must set a valid game protocol version before logging.");

    // reset the new game state
    resetGameStates();

    m_localPlayer = std::make_shared<LocalPlayer>();
    m_localPlayer->onCreate();
    m_localPlayer->setName(characterName);

    m_protocolGame = std::make_shared<ProtocolGame>();
    m_protocolGame->login(account, password, worldHost, static_cast<uint16_t>(worldPort), characterName, authenticatorToken, sessionKey);
    m_characterName = characterName;
    m_worldName = worldName;
}

void Game::cancelLogin()
{
    enableBotCall();
    // send logout even if the game has not started yet, to make sure that the player doesn't stay logged there
    if (m_protocolGame)
        m_protocolGame->sendLogout();

    processDisconnect();
    disableBotCall();
}

void Game::forceLogout()
{
    if (!isOnline())
        return;

    m_protocolGame->sendLogout();
    processDisconnect();
}

void Game::safeLogout()
{
    if (!isOnline())
        return;

    m_protocolGame->sendLogout();
}

bool Game::walk(const Otc::Direction direction, const bool isKeyDown /*= false*/)
{
    if (!canPerformGameAction())
        return false;

    // must cancel auto walking, and wait next try
    if (m_localPlayer->isAutoWalking()) {
        m_protocolGame->sendStop();
        m_localPlayer->autoWalk(m_localPlayer->getPosition().translatedToDirection(direction));
        return false;
    }

    // check we can walk and add new walk event if false
    if (!m_localPlayer->canWalk()) {
        if (m_nextScheduledDir != direction) {
            const float ticks = std::clamp<float>(m_localPlayer->getStepTicksLeft(), 1, 2000);
            if (isKeyDown || (m_scheduleLastWalk && ticks < std::min<int>(m_localPlayer->getStepDuration() / 3, 250))) {
                // must add a new walk event
                if (m_walkEvent) {
                    m_walkEvent->cancel();
                    m_walkEvent = nullptr;
                }

                m_walkEvent = g_dispatcher.scheduleEvent([this, direction] { walk(direction); }, ticks);
                m_nextScheduledDir = direction;
            }
        }
        return false;
    }

    m_nextScheduledDir = Otc::InvalidDirection;

    // if it's going to walk, but there is another scheduled event, cancel it
    if (m_walkEvent && !m_walkEvent->isExecuted()) {
        m_walkEvent->cancel();
        m_walkEvent = nullptr;
    }

    const auto& toPos = m_localPlayer->getPosition().translatedToDirection(direction);

    // only do prewalks to walkable tiles (like grounds and not walls)
    const auto& toTile = g_map.getTile(toPos);
    if (toTile && toTile->isWalkable()) {
        m_localPlayer->preWalk(direction);
    } else {
        // check if can walk to a lower floor
        const auto& canChangeFloorDown = [&]() -> bool {
            Position pos = toPos;
            if (!pos.down())
                return false;

            const auto& toTile = g_map.getTile(pos);
            return toTile && toTile->hasElevation(3);
        };

        // check if can walk to a higher floor
        const auto& canChangeFloorUp = [&]() -> bool {
            const auto& fromTile = m_localPlayer->getTile();
            if (!fromTile || !fromTile->hasElevation(3))
                return false;

            Position pos = toPos;
            if (!pos.up())
                return false;

            const auto& toTile = g_map.getTile(pos);
            return toTile && toTile->isWalkable();
        };

        if (!(canChangeFloorDown() || canChangeFloorUp() || !toTile || toTile->isEmpty()))
            return false;

        m_localPlayer->lockWalk();
    }

    // must cancel follow before any new walk
    if (isFollowing())
        cancelFollow();

    g_lua.callGlobalField("g_game", "onWalk", direction);

    forceWalk(direction);

    m_lastWalkDir = direction;

    return true;
}

void Game::autoWalk(const std::vector<Otc::Direction>& dirs, const Position& startPos)
{
    if (!canPerformGameAction())
        return;

    if (dirs.size() == 0)
        return;

    // protocol limits walk path
    if (dirs.size() > 127) {
        g_logger.error("Auto walk path too great");
        return;
    }

    // must cancel follow before any new walk
    if (isFollowing()) {
        cancelFollow();
    }

    const Otc::Direction direction = *dirs.begin();

    if (const auto& toTile = g_map.getTile(startPos.translatedToDirection(direction))) {
        if (startPos == m_localPlayer->m_lastPrewalkDestination && toTile->isWalkable() && m_localPlayer->canWalk(true)) {
            m_localPlayer->preWalk(direction);
        }
    }

    g_lua.callGlobalField("g_game", "onAutoWalk", dirs);

    m_protocolGame->sendAutoWalk(dirs);
}

void Game::forceWalk(const Otc::Direction direction)
{
    if (!canPerformGameAction())
        return;

    switch (direction) {
        case Otc::North:
            m_protocolGame->sendWalkNorth();
            break;
        case Otc::East:
            m_protocolGame->sendWalkEast();
            break;
        case Otc::South:
            m_protocolGame->sendWalkSouth();
            break;
        case Otc::West:
            m_protocolGame->sendWalkWest();
            break;
        case Otc::NorthEast:
            m_protocolGame->sendWalkNorthEast();
            break;
        case Otc::SouthEast:
            m_protocolGame->sendWalkSouthEast();
            break;
        case Otc::SouthWest:
            m_protocolGame->sendWalkSouthWest();
            break;
        case Otc::NorthWest:
            m_protocolGame->sendWalkNorthWest();
            break;
        default:
            break;
    }

    g_lua.callGlobalField("g_game", "onForceWalk", direction);
}

void Game::turn(const Otc::Direction direction)
{
    if (!canPerformGameAction())
        return;

    switch (direction) {
        case Otc::North:
            m_protocolGame->sendTurnNorth();
            break;
        case Otc::East:
            m_protocolGame->sendTurnEast();
            break;
        case Otc::South:
            m_protocolGame->sendTurnSouth();
            break;
        case Otc::West:
            m_protocolGame->sendTurnWest();
            break;
        default:
            break;
    }
}

void Game::stop()
{
    if (!canPerformGameAction())
        return;

    if (isFollowing())
        cancelFollow();

    m_protocolGame->sendStop();
}

void Game::look(const ThingPtr& thing, const bool isBattleList)
{
    if (!canPerformGameAction() || !thing)
        return;

    if (thing->isCreature() && isBattleList && m_protocolVersion >= 961)
        m_protocolGame->sendLookCreature(thing->getId());
    else {
        const int thingId = thing->isCreature() ? static_cast<int>(Proto::Creature) : thing->getId();
        m_protocolGame->sendLook(thing->getPosition(), thingId, thing->getStackPos());
    }
}

void Game::move(const ThingPtr& thing, const Position& toPos, int count)
{
    if (count <= 0)
        count = 1;

    if (!canPerformGameAction() || !thing || thing->getPosition() == toPos)
        return;

    const auto thingId = thing->isCreature() ? static_cast<int>(Proto::Creature) : thing->getId();
    m_protocolGame->sendMove(thing->getPosition(), thingId, thing->getStackPos(), toPos, count);
}

void Game::moveToParentContainer(const ThingPtr& thing, const int count)
{
    if (!canPerformGameAction() || !thing || count <= 0)
        return;

    const auto& position = thing->getPosition();
    move(thing, Position(position.x, position.y, 254), count);
}

void Game::rotate(const ThingPtr& thing)
{
    if (!canPerformGameAction() || !thing)
        return;

    m_protocolGame->sendRotateItem(thing->getPosition(), thing->getId(), thing->getStackPos());
}

void Game::wrap(const ThingPtr& thing)
{
    if (!canPerformGameAction() || !thing)
        return;

    m_protocolGame->sendOnWrapItem(thing->getPosition(), thing->getId(), thing->getStackPos());
}

void Game::use(const ThingPtr& thing)
{
    if (!canPerformGameAction() || !thing)
        return;

    Position pos = thing->getPosition();
    if (!pos.isValid()) // virtual item
        pos = Position(0xFFFF, 0, 0); // inventory item

    // some items, e.g. parcel, are not set as containers but they are.
    // always try to use these items in free container slots.
    m_protocolGame->sendUseItem(pos, thing->getId(), thing->getStackPos(), findEmptyContainerId());

    g_lua.callGlobalField("g_game", "onUse", pos, thing->getId(), thing->getStackPos(), 0);
}

void Game::useInventoryItem(const uint16_t itemId)
{
    if (!canPerformGameAction() || !g_things.isValidDatId(itemId, ThingCategoryItem))
        return;

    const auto& pos = Position(0xFFFF, 0, 0); // means that is a item in inventory
    m_protocolGame->sendUseItem(pos, itemId, 0, 0);

    g_lua.callGlobalField("g_game", "onUse", pos, itemId, 0, 0);
}

void Game::useWith(const ItemPtr& item, const ThingPtr& toThing)
{
    if (!canPerformGameAction() || !item || !toThing)
        return;

    Position pos = item->getPosition();
    if (!pos.isValid()) // virtual item
        pos = Position(0xFFFF, 0, 0); // means that is an item in inventory

    if (toThing->isCreature())
        m_protocolGame->sendUseOnCreature(pos, item->getId(), item->getStackPos(), toThing->getId());
    else
        m_protocolGame->sendUseItemWith(pos, item->getId(), item->getStackPos(), toThing->getPosition(), toThing->getId(), toThing->getStackPos());

    g_lua.callGlobalField("g_game", "onUseWith", pos, item->getId(), toThing, item->getStackPos());
}

void Game::useInventoryItemWith(const uint16_t itemId, const ThingPtr& toThing)
{
    if (!canPerformGameAction() || !toThing)
        return;

    const auto& pos = Position(0xFFFF, 0, 0); // means that is a item in inventory
    if (toThing->isCreature())
        m_protocolGame->sendUseOnCreature(pos, itemId, 0, toThing->getId());
    else
        m_protocolGame->sendUseItemWith(pos, itemId, 0, toThing->getPosition(), toThing->getId(), toThing->getStackPos());

    g_lua.callGlobalField("g_game", "onUseWith", pos, itemId, toThing, 0);
}

ItemPtr Game::findItemInContainers(const uint32_t itemId, const int subType)
{
    for (const auto& it : m_containers) {
        if (const auto& container = it.second) {
            if (const auto& item = container->findItemById(itemId, subType)) {
                return item;
            }
        }
    }

    return nullptr;
}

int Game::open(const ItemPtr& item, const ContainerPtr& previousContainer)
{
    if (!canPerformGameAction() || !item)
        return -1;

    const int id = previousContainer ? previousContainer->getId() : findEmptyContainerId();
    m_protocolGame->sendUseItem(item->getPosition(), item->getId(), item->getStackPos(), id);

    return id;
}

void Game::openParent(const ContainerPtr& container)
{
    if (!canPerformGameAction() || !container)
        return;

    m_protocolGame->sendUpContainer(container->getId());
}

void Game::close(const ContainerPtr& container)
{
    if (!canPerformGameAction() || !container)
        return;

    m_protocolGame->sendCloseContainer(container->getId());
}

void Game::refreshContainer(const ContainerPtr& container)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendRefreshContainer(container->getId());
}

void Game::attack(CreaturePtr creature)
{
    if (!canPerformGameAction() || creature == m_localPlayer)
        return;

    // cancel when attacking again
    if (creature && creature == m_attackingCreature)
        creature = nullptr;

    if (creature && isFollowing())
        cancelFollow();

    setAttackingCreature(creature);
    m_localPlayer->stopAutoWalk();

    if (m_protocolVersion >= 963) {
        if (creature)
            m_seq = creature->getId();
    } else
        ++m_seq;

    m_protocolGame->sendAttack(creature ? creature->getId() : 0, m_seq);
}

void Game::follow(CreaturePtr creature)
{
    if (!canPerformGameAction() || creature == m_localPlayer)
        return;

    // cancel when following again
    if (creature && creature == m_followingCreature)
        creature = nullptr;

    if (creature && isAttacking())
        cancelAttack();

    setFollowingCreature(creature);
    m_localPlayer->stopAutoWalk();

    if (m_protocolVersion >= 963) {
        if (creature)
            m_seq = creature->getId();
    } else
        ++m_seq;

    m_protocolGame->sendFollow(creature ? creature->getId() : 0, m_seq);
}

void Game::cancelAttackAndFollow()
{
    if (!canPerformGameAction())
        return;

    if (isFollowing())
        setFollowingCreature(nullptr);

    if (isAttacking())
        setAttackingCreature(nullptr);

    if (m_walkEvent) {
        m_walkEvent->cancel();
        m_walkEvent = nullptr;
    }

    m_nextScheduledDir = Otc::InvalidDirection;

    m_localPlayer->stopAutoWalk();

    m_protocolGame->sendCancelAttackAndFollow();

    g_lua.callGlobalField("g_game", "onCancelAttackAndFollow");
}

void Game::talk(const std::string_view message)
{
    if (!canPerformGameAction() || message.empty())
        return;

    talkChannel(Otc::MessageSay, 0, message);
}

void Game::talkChannel(const Otc::MessageMode mode, const uint16_t channelId, const std::string_view message)
{
    if (!canPerformGameAction() || message.empty())
        return;

    m_protocolGame->sendTalk(mode, channelId, "", message);
}

void Game::talkPrivate(const Otc::MessageMode mode, const std::string_view receiver, const std::string_view message)
{
    if (!canPerformGameAction() || receiver.empty() || message.empty())
        return;

    m_protocolGame->sendTalk(mode, 0, receiver, message);
}

void Game::openPrivateChannel(const std::string_view receiver)
{
    if (!canPerformGameAction() || receiver.empty())
        return;

    m_protocolGame->sendOpenPrivateChannel(receiver);
}

void Game::requestChannels()
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendRequestChannels();
}

void Game::joinChannel(const uint16_t channelId)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendJoinChannel(channelId);
}

void Game::leaveChannel(const uint16_t channelId)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendLeaveChannel(channelId);
}

void Game::closeNpcChannel()
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendCloseNpcChannel();
}

void Game::openOwnChannel()
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendOpenOwnChannel();
}

void Game::inviteToOwnChannel(const std::string_view name)
{
    if (!canPerformGameAction() || name.empty())
        return;

    m_protocolGame->sendInviteToOwnChannel(name);
}

void Game::excludeFromOwnChannel(const std::string_view name)
{
    if (!canPerformGameAction() || name.empty())
        return;

    m_protocolGame->sendExcludeFromOwnChannel(name);
}

void Game::partyInvite(const uint32_t creatureId)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendInviteToParty(creatureId);
}

void Game::partyJoin(const uint32_t creatureId)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendJoinParty(creatureId);
}

void Game::partyRevokeInvitation(const uint32_t creatureId)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendRevokeInvitation(creatureId);
}

void Game::partyPassLeadership(const uint32_t creatureId)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendPassLeadership(creatureId);
}

void Game::partyLeave()
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendLeaveParty();
}

void Game::partyShareExperience(const bool active)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendShareExperience(active);
}

void Game::requestOutfit()
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendRequestOutfit();
}

void Game::changeOutfit(const Outfit& outfit)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendChangeOutfit(outfit);
}

void Game::sendTyping(const bool typing)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendTyping(typing);
}

void Game::addVip(const std::string_view name)
{
    if (!canPerformGameAction() || name.empty())
        return;

    m_protocolGame->sendAddVip(name);
}

void Game::removeVip(const uint32_t playerId)
{
    if (!canPerformGameAction())
        return;

    const auto it = m_vips.find(playerId);
    if (it == m_vips.end())
        return;

    m_vips.erase(it);
    m_protocolGame->sendRemoveVip(playerId);
}

void Game::editVip(const uint32_t playerId, const std::string_view description, const uint32_t iconId, const bool notifyLogin)
{
    if (!canPerformGameAction())
        return;

    const auto it = m_vips.find(playerId);
    if (it == m_vips.end())
        return;

    std::get<2>(m_vips[playerId]) = description;
    std::get<3>(m_vips[playerId]) = iconId;
    std::get<4>(m_vips[playerId]) = notifyLogin;

    if (getFeature(Otc::GameAdditionalVipInfo))
        m_protocolGame->sendEditVip(playerId, description, iconId, notifyLogin);
}

void Game::setChaseMode(const Otc::ChaseModes chaseMode)
{
    if (!canPerformGameAction())
        return;

    if (m_chaseMode == chaseMode)
        return;

    m_chaseMode = chaseMode;
    m_protocolGame->sendChangeFightModes(m_fightMode, m_chaseMode, m_safeFight, m_pvpMode);
    g_lua.callGlobalField("g_game", "onChaseModeChange", chaseMode);
}

void Game::setFightMode(const Otc::FightModes fightMode)
{
    if (!canPerformGameAction())
        return;

    if (m_fightMode == fightMode)
        return;

    m_fightMode = fightMode;
    m_protocolGame->sendChangeFightModes(m_fightMode, m_chaseMode, m_safeFight, m_pvpMode);
    g_lua.callGlobalField("g_game", "onFightModeChange", fightMode);
}

void Game::setSafeFight(const bool on)
{
    if (!canPerformGameAction())
        return;

    if (m_safeFight == on)
        return;

    m_safeFight = on;
    m_protocolGame->sendChangeFightModes(m_fightMode, m_chaseMode, m_safeFight, m_pvpMode);
    g_lua.callGlobalField("g_game", "onSafeFightChange", on);
}

void Game::setPVPMode(const Otc::PVPModes pvpMode)
{
    if (!canPerformGameAction())
        return;

    if (!getFeature(Otc::GamePVPMode))
        return;

    if (m_pvpMode == pvpMode)
        return;

    m_pvpMode = pvpMode;
    m_protocolGame->sendChangeFightModes(m_fightMode, m_chaseMode, m_safeFight, m_pvpMode);
    g_lua.callGlobalField("g_game", "onPVPModeChange", pvpMode);
}

void Game::setUnjustifiedPoints(const UnjustifiedPoints unjustifiedPoints)
{
    if (!canPerformGameAction())
        return;

    if (!getFeature(Otc::GameUnjustifiedPoints))
        return;

    if (m_unjustifiedPoints == unjustifiedPoints)
        return;

    m_unjustifiedPoints = unjustifiedPoints;
    g_lua.callGlobalField("g_game", "onUnjustifiedPointsChange", unjustifiedPoints);
}

void Game::setOpenPvpSituations(const uint8_t openPvpSituations)
{
    if (!canPerformGameAction())
        return;

    if (m_openPvpSituations == openPvpSituations)
        return;

    m_openPvpSituations = openPvpSituations;
    g_lua.callGlobalField("g_game", "onOpenPvpSituationsChange", openPvpSituations);
}

void Game::inspectNpcTrade(const ItemPtr& item)
{
    if (!canPerformGameAction() || !item)
        return;

    m_protocolGame->sendInspectNpcTrade(item->getId(), item->getCount());
}

void Game::buyItem(const ItemPtr& item, const uint16_t amount, const bool ignoreCapacity, const bool buyWithBackpack)
{
    if (!canPerformGameAction() || !item)
        return;

    m_protocolGame->sendBuyItem(item->getId(), item->getCountOrSubType(), amount, ignoreCapacity, buyWithBackpack);
}

void Game::sellItem(const ItemPtr& item, const uint16_t amount, const bool ignoreEquipped)
{
    if (!canPerformGameAction() || !item)
        return;

    m_protocolGame->sendSellItem(item->getId(), item->getSubType(), amount, ignoreEquipped);
}

void Game::closeNpcTrade()
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendCloseNpcTrade();
}

void Game::requestTrade(const ItemPtr& item, const CreaturePtr& creature)
{
    if (!canPerformGameAction() || !item || !creature)
        return;

    m_protocolGame->sendRequestTrade(item->getPosition(), item->getId(), item->getStackPos(), creature->getId());
}

void Game::inspectTrade(const bool counterOffer, const uint8_t index)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendInspectTrade(counterOffer, index);
}

void Game::acceptTrade()
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendAcceptTrade();
}

void Game::rejectTrade()
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendRejectTrade();
}

void Game::editText(const uint32_t id, const std::string_view text)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendEditText(id, text);
}

void Game::editList(const uint32_t id, const uint8_t doorId, const std::string_view text)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendEditList(id, doorId, text);
}

void Game::openRuleViolation(const std::string_view reporter)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendOpenRuleViolation(reporter);
}

void Game::closeRuleViolation(const std::string_view reporter)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendCloseRuleViolation(reporter);
}

void Game::cancelRuleViolation()
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendCancelRuleViolation();
}

void Game::reportBug(const std::string_view comment)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendBugReport(comment);
}

void Game::reportRuleViolation(const std::string_view target, const uint8_t reason, const uint8_t action, const std::string_view comment, const std::string_view statement, const uint16_t statementId, const bool ipBanishment)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendRuleViolation(target, reason, action, comment, statement, statementId, ipBanishment);
}

void Game::debugReport(const std::string_view a, const std::string_view b, const std::string_view c, const std::string_view d)
{
    m_protocolGame->sendDebugReport(a, b, c, d);
}

void Game::requestQuestLog()
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendRequestQuestLog();
}

void Game::requestQuestLine(const uint16_t questId)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendRequestQuestLine(questId);
}

void Game::equipItem(const ItemPtr& item)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendEquipItem(item->getId(), item->getCountOrSubType());
}

void Game::mount(const bool mount)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendMountStatus(mount);
}

void Game::requestItemInfo(const ItemPtr& item, const uint8_t index)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendRequestItemInfo(item->getId(), item->getSubType(), index);
}

void Game::answerModalDialog(const uint32_t dialog, const uint8_t button, const uint8_t choice)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendAnswerModalDialog(dialog, button, choice);
}

void Game::browseField(const Position& position)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendBrowseField(position);
}

void Game::seekInContainer(const uint8_t containerId, const uint16_t index)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendSeekInContainer(containerId, index);
}

void Game::buyStoreOffer(const uint32_t offerId, const uint8_t productType, const std::string_view name)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendBuyStoreOffer(offerId, productType, name);
}

void Game::requestTransactionHistory(const uint32_t page, const uint32_t entriesPerPage)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendRequestTransactionHistory(page, entriesPerPage);
}

void Game::requestStoreOffers(const std::string_view categoryName, const uint8_t serviceType)
{
    enableBotCall();
    m_protocolGame->sendRequestStoreOffers(categoryName, serviceType);
    m_denyBotCall = true;
}

void Game::openStore(const uint8_t serviceType, const std::string_view category)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendOpenStore(serviceType, category);
}

void Game::transferCoins(const std::string_view recipient, const uint16_t amount)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendTransferCoins(recipient, amount);
}

void Game::openTransactionHistory(const uint8_t entriesPerPage)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendOpenTransactionHistory(entriesPerPage);
}

void Game::ping()
{
    if (!m_protocolGame || !m_protocolGame->isConnected())
        return;

    if (m_pingReceived != m_pingSent)
        return;

    enableBotCall();
    m_protocolGame->sendPing();
    disableBotCall();
    ++m_pingSent;
    m_pingTimer.restart();
}

void Game::changeMapAwareRange(const uint8_t xrange, const uint8_t yrange)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendChangeMapAwareRange(xrange, yrange);
}

bool Game::checkBotProtection() const
{
#ifdef BOT_PROTECTION
    // accepts calls comming from a stacktrace containing only C++ functions,
    // if the stacktrace contains a lua function, then only accept if the engine is processing an input event
    if (m_denyBotCall && g_lua.isInCppCallback() && !g_app.isOnInputEvent()) {
        g_logger.error(g_lua.traceback("caught a lua call to a bot protected game function, the call was cancelled"));
        return false;
    }
#endif
    return true;
}

bool Game::canPerformGameAction() const
{
    // we can only perform game actions if we meet these conditions:
    // - the game is online
    // - the local player exists
    // - the local player is not dead
    // - we have a game protocol
    // - the game protocol is connected
    // - its not a bot action
    return m_online && m_localPlayer && !m_dead && m_protocolGame && m_protocolGame->isConnected() && checkBotProtection();
}

void Game::setProtocolVersion(const uint16_t version)
{
    if (m_protocolVersion == version)
        return;

    if (isOnline())
        throw Exception("Unable to change protocol version while online");

    if (version != 0 && (version < 740 || version > g_gameConfig.getLastSupportedVersion()))
        throw Exception("Protocol version %d not supported", version);

    m_protocolVersion = version;

    Proto::buildMessageModesMap(version);

    g_lua.callGlobalField("g_game", "onProtocolVersionChange", version);
}

void Game::setClientVersion(const uint16_t version)
{
    if (m_clientVersion == version)
        return;

    if (isOnline())
        throw Exception("Unable to change client version while online");

    if (version != 0 && (version < 740 || version > g_gameConfig.getLastSupportedVersion()))
        throw Exception("Client version %d not supported", version);

    m_features.reset();

    m_clientVersion = version;

    g_lua.callGlobalField("g_game", "onClientVersionChange", version);
}

void Game::setAttackingCreature(const CreaturePtr& creature)
{
    if (creature == m_attackingCreature)
        return;

    const CreaturePtr oldCreature = m_attackingCreature;
    m_attackingCreature = creature;

    g_lua.callGlobalField("g_game", "onAttackingCreatureChange", creature, oldCreature);
}

void Game::setFollowingCreature(const CreaturePtr& creature)
{
    if (creature == m_followingCreature)
        return;

    const CreaturePtr oldCreature = m_followingCreature;
    m_followingCreature = creature;

    g_lua.callGlobalField("g_game", "onFollowingCreatureChange", creature, oldCreature);
}

std::string Game::formatCreatureName(const std::string_view name)
{
    std::string formatedName{ name };
    if (getFeature(Otc::GameFormatCreatureName) && name.length() > 0) {
        bool upnext = true;
        for (char& i : formatedName) {
            const char ch = i;
            if (upnext) {
                i = std::toupper(ch);
                upnext = false;
            }
            if (ch == ' ')
                upnext = true;
        }
    }

    return formatedName;
}

int Game::findEmptyContainerId()
{
    int id = -1;
    while (m_containers[++id] != nullptr);
    return id;
}

Otc::OperatingSystem_t Game::getOs()
{
    if (m_clientCustomOs > Otc::CLIENTOS_NONE)
        return m_clientCustomOs;

    if (g_app.getOs() == "windows")
        return Otc::CLIENTOS_OTCLIENT_WINDOWS;

    if (g_app.getOs() == "mac")
        return Otc::CLIENTOS_OTCLIENT_MAC;

    return Otc::CLIENTOS_OTCLIENT_LINUX;
}

void Game::leaveMarket()
{
    enableBotCall();
    m_protocolGame->sendMarketLeave();
    disableBotCall();

    g_lua.callGlobalField("g_game", "onMarketLeave");
}

void Game::browseMarket(const uint8_t browseId, const uint8_t browseType)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendMarketBrowse(browseId, browseType);
}

void Game::createMarketOffer(const uint8_t type, const uint16_t itemId, const uint8_t itemTier, const uint16_t amount, const uint64_t price, const uint8_t anonymous)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendMarketCreateOffer(type, itemId, itemTier, amount, price, anonymous);
}

void Game::cancelMarketOffer(const uint32_t timestamp, const uint16_t counter)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendMarketCancelOffer(timestamp, counter);
}

void Game::acceptMarketOffer(const uint32_t timestamp, const uint16_t counter, const uint16_t amount)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendMarketAcceptOffer(timestamp, counter, amount);
}

void Game::preyAction(const uint8_t slot, const uint8_t actionType, const uint16_t index)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendPreyAction(slot, actionType, index);
}

void Game::preyRequest()
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendPreyRequest();
}

void Game::applyImbuement(const uint8_t slot, const uint32_t imbuementId, const bool protectionCharm)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendApplyImbuement(slot, imbuementId, protectionCharm);
}

void Game::clearImbuement(const uint8_t slot)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendClearImbuement(slot);
}

void Game::closeImbuingWindow()
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendCloseImbuingWindow();
}

void Game::imbuementDurations(const bool isOpen)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendImbuementDurations(isOpen);
}

void Game::stashWithdraw(const uint16_t itemId, const uint32_t count, const uint8_t stackpos)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendStashWithdraw(itemId, count, stackpos);
}

void Game::requestHighscore(const uint8_t action, const uint8_t category, const uint32_t vocation, const std::string_view world, const uint8_t worldType, const uint8_t battlEye, const uint16_t page, const uint8_t totalPages)
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendHighscoreInfo(action, category, vocation, world, worldType, battlEye, page, totalPages);
}

void Game::processHighscore(const std::string_view serverName, const std::string_view world, const uint8_t worldType, const uint8_t battlEye,
                            const std::vector<std::tuple<uint32_t, std::string>>& vocations,
                            const std::vector<std::tuple<uint8_t, std::string>>& categories,
                            const uint16_t page, const uint16_t totalPages,
                            const std::vector<std::tuple<uint32_t, std::string, std::string, uint8_t, std::string, uint16_t, uint8_t, uint64_t>>& highscores, const uint32_t entriesTs)
{
    g_lua.callGlobalField("g_game", "onProcessHighscores", serverName, world, worldType, battlEye, vocations, categories, page, totalPages, highscores, entriesTs);
}

void Game::requestBless()
{
    if (!canPerformGameAction())
        return;

    m_protocolGame->sendRequestBless();
}

void Game::requestQuickLootBlackWhiteList(const uint8_t filter, const uint16_t size, const std::vector<uint16_t>& listedItems)
{
    enableBotCall();
    m_protocolGame->requestQuickLootBlackWhiteList(filter, size, listedItems);
    disableBotCall();
}

void Game::openContainerQuickLoot(const uint8_t action, const uint8_t category, const Position& pos, const uint16_t itemId, const uint8_t stackpos, const bool useMainAsFallback)
{
    enableBotCall();
    m_protocolGame->openContainerQuickLoot(action, category, pos, itemId, stackpos, useMainAsFallback);
    disableBotCall();
}
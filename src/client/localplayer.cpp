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

#include "localplayer.h"
#include "game.h"
#include "map.h"
#include "tile.h"
#include <framework/core/eventdispatcher.h>

void LocalPlayer::lockWalk(const uint16_t millis)
{
    m_walkLockExpiration = std::max<ticks_t>(m_walkLockExpiration, g_clock.millis() + millis);
}

bool LocalPlayer::canWalk(const Otc::Direction dir, const bool ignoreLock)
{
    // paralyzed
    if (isDead())
        return false;

    // cannot walk while locked
    if (isWalkLocked() && !ignoreLock)
        return false;

    return m_walkTimer.ticksElapsed() >= getStepDuration() && (dir == m_direction || !m_walking);
}

void LocalPlayer::walk(const Position& oldPos, const Position& newPos)
{
    m_autoWalkRetries = 0;

    if (m_preWalking) {
        m_preWalking = false;
        if (newPos == m_lastPrewalkDestination) {
            updateWalk();
            return;
        }
    }

    Creature::walk(oldPos, newPos);
}

void LocalPlayer::preWalk(const Otc::Direction direction)
{
    // avoid reanimating prewalks
    if (m_preWalking)
        return;

    m_preWalking = true;

    // start walking to direction
    m_lastPrewalkDestination = m_position.translatedToDirection(direction);
    Creature::walk(m_position, m_lastPrewalkDestination);
}

bool LocalPlayer::retryAutoWalk()
{
    if (m_autoWalkDestination.isValid()) {
        g_game.stop();

        if (m_autoWalkRetries <= 3) {
            if (m_autoWalkContinueEvent)
                m_autoWalkContinueEvent->cancel();

            m_autoWalkContinueEvent = g_dispatcher.scheduleEvent(
                [capture0 = asLocalPlayer(), autoWalkDest = m_autoWalkDestination] { capture0->autoWalk(autoWalkDest, true); }, 200
            );

            m_autoWalkRetries += 1;

            return true;
        }

        m_autoWalkDestination = {};
    }

    return false;
}

void LocalPlayer::cancelWalk(const Otc::Direction direction)
{
    // only cancel client side walks
    if (m_walking && m_preWalking)
        stopWalk();

    g_map.notificateCameraMove(m_walkOffset);

    lockWalk();
    if (retryAutoWalk()) return;

    // turn to the cancel direction
    if (direction != Otc::InvalidDirection)
        setDirection(direction);

    callLuaField("onCancelWalk", direction);
}

bool LocalPlayer::autoWalk(const Position& destination, const bool retry)
{
    // reset state
    m_autoWalkDestination = {};
    m_lastAutoWalkPosition = {};
    if (m_autoWalkContinueEvent)
        m_autoWalkContinueEvent->cancel();
    m_autoWalkContinueEvent = nullptr;

    if (!retry)
        m_autoWalkRetries = 0;

    if (destination == m_position)
        return true;

    m_autoWalkDestination = destination;
    auto self(asLocalPlayer());
    g_map.findPathAsync(m_position, destination, [self](const auto& result) {
        if (self->m_autoWalkDestination != result->destination)
            return;

        if (result->status != Otc::PathFindResultOk) {
            if (self->m_autoWalkRetries > 0 && self->m_autoWalkRetries <= 3) { // try again in 300, 700, 1200 ms if canceled by server
                self->m_autoWalkContinueEvent = g_dispatcher.scheduleEvent([self, capture0 = result->destination] { self->autoWalk(capture0, true); }, 200 + self->m_autoWalkRetries * 100);
                return;
            }
            self->m_autoWalkDestination = {};
            self->callLuaField("onAutoWalkFail", result->status);
            return;
        }

        if (result->path.size() > 127)
            result->path.resize(127);

        if (result->path.empty()) {
            self->m_autoWalkDestination = {};
            self->callLuaField("onAutoWalkFail", result->status);
            return;
        }

        if (self->m_autoWalkDestination != result->destination) {
            self->m_lastAutoWalkPosition = result->destination;
        }

        g_game.autoWalk(result->path, result->start);
    });

    if (!retry)
        lockWalk();

    return true;
}

void LocalPlayer::stopAutoWalk()
{
    m_autoWalkDestination = {};
    m_lastAutoWalkPosition = {};
    m_knownCompletePath = false;

    if (m_autoWalkContinueEvent)
        m_autoWalkContinueEvent->cancel();
}

void LocalPlayer::stopWalk()
{
    Creature::stopWalk(); // will call terminateWalk

    m_lastPrewalkDestination = {};
}

void LocalPlayer::updateWalkOffset(const uint8_t totalPixelsWalked)
{
    if (!m_preWalking) {
        Creature::updateWalkOffset(totalPixelsWalked);
        return;
    }

    // pre walks offsets are calculated in the oposite direction
    m_walkOffset = {};
    if (m_direction == Otc::North || m_direction == Otc::NorthEast || m_direction == Otc::NorthWest)
        m_walkOffset.y = -totalPixelsWalked;
    else if (m_direction == Otc::South || m_direction == Otc::SouthEast || m_direction == Otc::SouthWest)
        m_walkOffset.y = totalPixelsWalked;

    if (m_direction == Otc::East || m_direction == Otc::NorthEast || m_direction == Otc::SouthEast)
        m_walkOffset.x = totalPixelsWalked;
    else if (m_direction == Otc::West || m_direction == Otc::NorthWest || m_direction == Otc::SouthWest)
        m_walkOffset.x = -totalPixelsWalked;
}

void LocalPlayer::terminateWalk()
{
    Creature::terminateWalk();
    m_preWalking = false;
}

void LocalPlayer::onPositionChange(const Position& newPos, const Position& oldPos)
{
    Creature::onPositionChange(newPos, oldPos);

    if (newPos == m_autoWalkDestination)
        stopAutoWalk();
    else if (m_autoWalkDestination.isValid() && newPos == m_lastAutoWalkPosition)
        autoWalk(m_autoWalkDestination);
}

void LocalPlayer::setStates(const uint32_t states)
{
    if (m_states == states)
        return;

    const uint32_t oldStates = m_states;
    m_states = states;

    if (isParalyzed())
        m_walkTimer.update(-getStepDuration());

    callLuaField("onStatesChange", states, oldStates);
}

void LocalPlayer::setSkill(const Otc::Skill skillId, const uint16_t level, const uint16_t levelPercent)
{
    if (skillId >= Otc::LastSkill) {
        g_logger.traceError("invalid skill");
        return;
    }

    auto& skill = m_skills[skillId];

    const uint16_t oldLevel = skill.level;
    const uint16_t oldLevelPercent = skill.levelPercent;

    if (level == oldLevel && levelPercent == oldLevelPercent)
        return;

    skill.level = level;
    skill.levelPercent = levelPercent;

    callLuaField("onSkillChange", skillId, level, levelPercent, oldLevel, oldLevelPercent);
}

void LocalPlayer::setBaseSkill(const Otc::Skill skill, const uint16_t baseLevel)
{
    if (skill >= Otc::LastSkill) {
        g_logger.traceError("invalid skill");
        return;
    }

    const uint16_t oldBaseLevel = m_skills[skill].baseLevel;
    if (baseLevel == oldBaseLevel)
        return;

    m_skills[skill].baseLevel = baseLevel;

    callLuaField("onBaseSkillChange", skill, baseLevel, oldBaseLevel);
}

void LocalPlayer::setHealth(const uint32_t health, const uint32_t maxHealth)
{
    if (m_health != health || m_maxHealth != maxHealth) {
        const uint32_t oldHealth = m_health;
        const uint32_t oldMaxHealth = m_maxHealth;
        m_health = health;
        m_maxHealth = maxHealth;

        callLuaField("onHealthChange", health, maxHealth, oldHealth, oldMaxHealth);

        if (isDead()) {
            if (isPreWalking())
                stopWalk();
            lockWalk();
        }
    }
}

void LocalPlayer::setFreeCapacity(const uint32_t freeCapacity)
{
    if (m_freeCapacity == freeCapacity)
        return;

    const uint32_t oldFreeCapacity = m_freeCapacity;
    m_freeCapacity = freeCapacity;

    callLuaField("onFreeCapacityChange", freeCapacity, oldFreeCapacity);
}

void LocalPlayer::setTotalCapacity(const uint32_t totalCapacity)
{
    if (m_totalCapacity == totalCapacity)
        return;

    const uint32_t oldTotalCapacity = m_totalCapacity;
    m_totalCapacity = totalCapacity;

    callLuaField("onTotalCapacityChange", totalCapacity, oldTotalCapacity);
}

void LocalPlayer::setExperience(const uint64_t experience)
{
    if (m_experience == experience)
        return;

    const uint64_t oldExperience = m_experience;
    m_experience = experience;

    callLuaField("onExperienceChange", experience, oldExperience);
}

void LocalPlayer::setLevel(const uint16_t level, const uint8_t levelPercent)
{
    if (m_level == level && m_levelPercent == levelPercent)
        return;

    const uint16_t oldLevel = m_level;
    const uint8_t oldLevelPercent = m_levelPercent;

    m_level = level;
    m_levelPercent = levelPercent;

    callLuaField("onLevelChange", level, levelPercent, oldLevel, oldLevelPercent);
}

void LocalPlayer::setMana(const uint32_t mana, const uint32_t maxMana)
{
    if (m_mana == mana && m_maxMana == maxMana)
        return;

    const uint32_t oldMana = m_mana;
    const uint32_t oldMaxMana = m_maxMana;
    m_mana = mana;
    m_maxMana = maxMana;

    callLuaField("onManaChange", mana, maxMana, oldMana, oldMaxMana);
}

void LocalPlayer::setMagicLevel(const uint16_t magicLevel, const uint16_t magicLevelPercent)
{
    if (m_magicLevel == magicLevel && m_magicLevelPercent == magicLevelPercent)
        return;

    const uint16_t oldMagicLevel = m_magicLevel;
    const uint16_t oldMagicLevelPercent = m_magicLevelPercent;

    m_magicLevel = magicLevel;
    m_magicLevelPercent = magicLevelPercent;

    callLuaField("onMagicLevelChange", magicLevel, magicLevelPercent, oldMagicLevel, oldMagicLevelPercent);
}

void LocalPlayer::setBaseMagicLevel(const uint16_t baseMagicLevel)
{
    if (m_baseMagicLevel == baseMagicLevel)
        return;

    const uint16_t oldBaseMagicLevel = m_baseMagicLevel;
    m_baseMagicLevel = baseMagicLevel;

    callLuaField("onBaseMagicLevelChange", baseMagicLevel, oldBaseMagicLevel);
}

void LocalPlayer::setSoul(const uint8_t soul)
{
    if (m_soul == soul)
        return;

    const uint8_t oldSoul = m_soul;
    m_soul = soul;

    callLuaField("onSoulChange", soul, oldSoul);
}

void LocalPlayer::setStamina(const uint16_t stamina)
{
    if (m_stamina == stamina)
        return;

    const uint16_t oldStamina = m_stamina;
    m_stamina = stamina;

    callLuaField("onStaminaChange", stamina, oldStamina);
}

void LocalPlayer::setInventoryItem(const Otc::InventorySlot inventory, const ItemPtr& item)
{
    if (inventory >= Otc::LastInventorySlot) {
        g_logger.traceError("invalid slot");
        return;
    }

    if (m_inventoryItems[inventory] == item)
        return;

    const auto& oldItem = m_inventoryItems[inventory];
    m_inventoryItems[inventory] = item;

    callLuaField("onInventoryChange", inventory, item, oldItem);
}

void LocalPlayer::setVocation(const uint8_t vocation)
{
    if (m_vocation == vocation)
        return;

    const uint8_t oldVocation = m_vocation;
    m_vocation = vocation;

    callLuaField("onVocationChange", vocation, oldVocation);
}

void LocalPlayer::setPremium(const bool premium)
{
    if (m_premium == premium)
        return;

    m_premium = premium;

    callLuaField("onPremiumChange", premium);
}

void LocalPlayer::setRegenerationTime(const uint16_t regenerationTime)
{
    if (m_regenerationTime == regenerationTime)
        return;

    const uint16_t oldRegenerationTime = m_regenerationTime;
    m_regenerationTime = regenerationTime;

    callLuaField("onRegenerationChange", regenerationTime, oldRegenerationTime);
}

void LocalPlayer::setOfflineTrainingTime(const uint16_t offlineTrainingTime)
{
    if (m_offlineTrainingTime == offlineTrainingTime)
        return;

    const uint16_t oldOfflineTrainingTime = m_offlineTrainingTime;
    m_offlineTrainingTime = offlineTrainingTime;

    callLuaField("onOfflineTrainingChange", offlineTrainingTime, oldOfflineTrainingTime);
}

void LocalPlayer::setSpells(const std::vector<uint16_t>& spells)
{
    if (m_spells == spells)
        return;

    const std::vector<uint16_t> oldSpells = m_spells;
    m_spells = spells;

    callLuaField("onSpellsChange", spells, oldSpells);
}

void LocalPlayer::setBlessings(const uint16_t blessings)
{
    if (blessings == m_blessings)
        return;

    const uint16_t oldBlessings = m_blessings;
    m_blessings = blessings;

    callLuaField("onBlessingsChange", blessings, oldBlessings);
}

void LocalPlayer::takeScreenshot(const uint8_t type)
{
    g_lua.callGlobalField("LocalPlayer", "onTakeScreenshot", type);
}

void LocalPlayer::setResourceBalance(const Otc::ResourceTypes_t type, const uint64_t value)
{
    const uint64_t oldBalance = getResourceBalance(type);
    if (value == oldBalance)
        return;

    m_resourcesBalance[type] = value;
    g_lua.callGlobalField("g_game", "onResourcesBalanceChange", value, oldBalance, type);
}

bool LocalPlayer::hasSight(const Position& pos)
{
    return m_position.isInRange(pos, g_map.getAwareRange().left - 1, g_map.getAwareRange().top - 1);
}
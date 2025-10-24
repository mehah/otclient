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

#include "outfit.h"
#include "position.h"

struct AwareRange
{
    uint8_t left{ 0 };
    uint8_t top{ 0 };
    uint8_t right{ 0 };
    uint8_t bottom{ 0 };

    uint8_t horizontal() const { return left + right + 1; }
    uint8_t vertical() const { return top + bottom + 1; }

    Size dimension() const { return { left * 2 + 1 , top * 2 + 1 }; }

    bool operator==(const AwareRange& other) const
    { return left == other.left && top == other.top && right == other.right && bottom == other.bottom; }
};

struct MapPosInfo
{
    Rect rect;
    Rect srcRect;
    Point drawOffset;
    float horizontalStretchFactor;
    float verticalStretchFactor;
    float scaleFactor;

    bool isInRange(const Position& pos, const bool ignoreZ = false) const
    {
        return camera.isInRange(pos, awareRange.left - 1, awareRange.right - 2, awareRange.top - 1, awareRange.bottom - 2, ignoreZ);
    }

    bool isInRangeEx(const Position& pos, const bool ignoreZ = false)  const
    {
        return camera.isInRange(pos, awareRange.left, awareRange.right, awareRange.top, awareRange.bottom, ignoreZ);
    }

private:
    Position camera;
    AwareRange awareRange;

    friend class MapView;
};

struct RaceType
{
    uint32_t raceId;
    std::string name;
    Outfit outfit;
    bool boss;
};

struct PreyMonster
{
    std::string name;
    Outfit outfit;
};

struct Imbuement
{
    uint32_t id;
    std::string name;
    std::string description;
    std::string group;
    uint16_t imageId;
    uint32_t duration;
    bool premiumOnly;
    std::vector<std::pair<ItemPtr, std::string>> sources;
    uint32_t cost;
    uint8_t successRate;
    uint32_t protectionCost;
};

struct ImbuementSlot
{
    ImbuementSlot(const uint8_t id) : id(id) {}

    uint8_t id;
    std::string name;
    uint16_t iconId = 0;
    uint32_t duration = 0;
    bool state = false; // paused, running
};

struct ImbuementTrackerItem
{
    ImbuementTrackerItem() : slot(0) {}
    ImbuementTrackerItem(const uint8_t slot) : slot(slot) {}

    uint8_t slot;
    uint8_t totalSlots = 0;
    ItemPtr item;
    std::map<uint8_t, ImbuementSlot> slots;
};

struct MarketData
{
    std::string name;
    ITEM_CATEGORY category;
    uint16_t requiredLevel;
    uint16_t restrictVocation;
    uint16_t showAs;
    uint16_t tradeAs;
};

struct NPCData
{
    std::string name;
    std::string location;
    uint32_t salePrice;
    uint32_t buyPrice;
    uint32_t currencyObjectTypeId;
    std::string currencyQuestFlagDisplayName;
};

struct MarketOffer
{
    uint32_t timestamp = 0;
    uint16_t counter = 0;
    uint8_t action = 0;
    uint16_t itemId = 0;
    uint16_t amount = 0;
    uint64_t price = 0;
    std::string playerName;
    uint8_t state = 0;
    uint16_t var = 0;
    uint8_t itemTier = 0;
};

struct Light
{
    Light() = default;
    Light(const uint8_t intensity, const uint8_t color) : intensity(intensity), color(color) {}
    uint8_t intensity = 0;
    uint8_t color = 215;
};

struct BossCooldownData
{
    uint32_t bossRaceId;
    uint64_t cooldownTime;

    BossCooldownData(uint32_t raceId, uint64_t cooldown)
        : bossRaceId(raceId), cooldownTime(cooldown) {}
};

struct PartyMemberData
{
    uint32_t memberID;
    uint8_t highlight;
    uint64_t loot;
    uint64_t supply;
    uint64_t damage;
    uint64_t healing;

    PartyMemberData(uint32_t id, uint8_t highlightValue, uint64_t lootValue, uint64_t supplyValue, uint64_t damageValue, uint64_t healingValue)
        : memberID(id), highlight(highlightValue), loot(lootValue), supply(supplyValue), damage(damageValue), healing(healingValue) {}
};

struct PartyMemberName
{
    uint32_t memberID;
    std::string memberName;

    PartyMemberName(uint32_t id, const std::string& name)
        : memberID(id), memberName(name) {}
};

struct UnjustifiedPoints
{
    bool operator==(const UnjustifiedPoints& other) const
    {
        return killsDay == other.killsDay &&
            killsDayRemaining == other.killsDayRemaining &&
            killsWeek == other.killsWeek &&
            killsWeekRemaining == other.killsWeekRemaining &&
            killsMonth == other.killsMonth &&
            killsMonthRemaining == other.killsMonthRemaining &&
            skullTime == other.skullTime;
    }
    uint8_t killsDay;
    uint8_t killsDayRemaining;
    uint8_t killsWeek;
    uint8_t killsWeekRemaining;
    uint8_t killsMonth;
    uint8_t killsMonthRemaining;
    uint8_t skullTime;
};

struct BlessData
{
    uint16_t blessBitwise;
    uint8_t playerBlessCount;
    uint8_t store;
};

struct LogData
{
    uint32_t timestamp;
    uint8_t colorMessage;
    std::string historyMessage;
};

struct BlessDialogData
{
    uint8_t totalBless;
    std::vector<BlessData> blesses;
    uint8_t premium;
    uint8_t promotion;
    uint8_t pvpMinXpLoss;
    uint8_t pvpMaxXpLoss;
    uint8_t pveExpLoss;
    uint8_t equipPvpLoss;
    uint8_t equipPveLoss;
    uint8_t skull;
    uint8_t aol;
    std::vector<LogData> logs;
};

using Vip = std::tuple<std::string, uint32_t, std::string, int, bool, std::vector<uint8_t>>;

struct StoreCategory
{
    std::string name;
    std::vector<StoreCategory> subCategories;
    uint8_t state;
    std::vector<std::string> icons;
    std::string parent;
};

struct SubOffer
{
    uint32_t id;
    uint16_t count;
    uint32_t price;
    uint8_t coinType;
    bool disabled;
    uint16_t disabledReason;
    uint16_t reasonIdDisable;
    uint8_t state;
    uint32_t validUntil;
    uint32_t basePrice;
    std::string name;         // oldProtocol
    std::string description;  // oldProtocol
    std::vector<std::string> icons; // oldProtocol
    std::string parent;       // oldProtocol
};

struct StoreOffer
{
    std::string name;
    std::vector<SubOffer> subOffers;
    uint32_t id;
    std::string description;
    uint32_t price; // oldProtocol
    uint8_t state; // oldProtocol
    uint32_t basePrice; // oldProtocol
    bool disabled; // oldProtocol
    std::string reasonIdDisable; // oldProtocol
    uint8_t type;
    std::string icon;
    uint16_t mountId;
    uint16_t itemId;
    uint16_t outfitId;
    uint8_t outfitHead, outfitBody, outfitLegs, outfitFeet;
    uint8_t sex;
    uint16_t maleOutfitId, femaleOutfitId;
    uint8_t tryOnType;
    uint16_t collection;
    uint16_t popularityScore;
    uint32_t stateNewUntil;
    bool configurable;
    uint16_t productsCapacity;
};

struct HomeOffer
{
    std::string name;
    uint8_t unknownByte;
    uint32_t id;
    uint16_t unknownU16;
    uint32_t price;
    uint8_t coinType;
    uint16_t disabledReasonIndex;
    uint8_t unknownByte2;
    uint8_t type;
    std::string icon;
    uint16_t mountClientId;
    uint16_t itemType;
    uint16_t sexId;
    struct { uint8_t lookHead, lookBody, lookLegs, lookFeet; } outfit;
    uint8_t tryOnType;
    uint16_t collection;
    uint16_t popularityScore;
    uint32_t stateNewUntil;
    uint8_t userConfiguration;
    uint16_t productsCapacity;
};

struct Banner
{
    std::string image;
    uint8_t bannerType;
    uint32_t offerId;
    uint8_t unknownByte1, unknownByte2;
};

struct StoreData
{
    std::string categoryName;
    uint32_t redirectId;
    std::vector<std::string> disableReasons;
    std::vector<HomeOffer> homeOffers;
    std::vector<StoreOffer> storeOffers;
    std::vector<Banner> banners;
    uint8_t bannerDelay;
    bool tooManyResults;
    std::vector<std::string> menuFilter;
};

struct CyclopediaCharacterGeneralStats
{
    uint64_t experience;
    uint16_t level;
    uint8_t levelPercent;
    uint16_t baseExpGain;
    uint16_t lowLevelExpBonus;
    uint16_t XpBoostPercent;
    uint16_t staminaExpBonus;
    uint16_t XpBoostBonusRemainingTime;
    uint8_t canBuyXpBoost;
    uint32_t health;
    uint32_t maxHealth;
    uint32_t mana;
    uint32_t maxMana;
    uint8_t soul;
    uint16_t staminaMinutes;
    uint16_t regenerationCondition;
    uint16_t offlineTrainingTime;
    uint16_t speed;
    uint16_t baseSpeed;
    uint32_t capacity;
    uint32_t baseCapacity;
    uint32_t freeCapacity;
    uint16_t magicLevel;
    uint16_t baseMagicLevel;
    uint16_t loyaltyMagicLevel;
    uint16_t magicLevelPercent;
};

struct CyclopediaCharacterCombatStats
{
    uint8_t weaponElement;
    uint16_t weaponMaxHitChance;
    uint8_t weaponElementDamage;
    uint8_t weaponElementType;
    uint16_t defense;
    uint16_t armor;
    uint8_t haveBlessings;
};

struct CyclopediaBestiaryRace
{
    uint8_t race;
    std::string bestClass;
    uint16_t count;
    uint16_t unlockedCount;
};

struct CharmData
{
    uint8_t id;
    std::string name;
    std::string description;
    uint16_t unlockPrice;
    bool unlocked;
    bool asignedStatus;
    uint16_t raceId;
    uint32_t removeRuneCost;
    uint8_t availableCharmSlots;
    uint8_t tier;
};

struct BestiaryCharmsData
{
    uint64_t resetAllCharmsCost;
    uint8_t availableCharmSlots;

    uint32_t points;
    std::vector<CharmData> charms;
    std::vector<uint16_t> finishedMonsters;
};

struct BestiaryOverviewMonsters
{
    uint16_t id;
    uint8_t currentLevel;
    uint8_t occurrence;
    uint16_t creatureAnimusMasteryBonus;
};

struct LootItem
{
    uint16_t itemId;
    uint8_t diffculty;
    uint8_t specialEvent;
    std::string name;
    uint8_t amount;
};

struct BestiaryMonsterData
{
    uint16_t id;
    std::string bestClass;
    uint8_t currentLevel;
    uint16_t AnimusMasteryBonus;
    uint16_t AnimusMasteryPoints;
    uint32_t killCounter;
    uint16_t thirdDifficulty;
    uint16_t secondUnlock;
    uint16_t lastProgressKillCount;
    uint8_t difficulty;
    uint8_t ocorrence;
    std::vector<LootItem> loot;
    uint16_t charmValue;
    uint8_t attackMode;
    uint32_t maxHealth;
    uint32_t experience;
    uint16_t speed;
    uint16_t armor;
    double mitigation;
    std::map<uint8_t, uint16_t> combat;
    std::string location;
};

struct BosstiaryData
{
    uint32_t raceId;
    uint8_t category;
    uint32_t kills;
    uint8_t isTrackerActived;
};

struct BosstiarySlot
{
    uint8_t bossRace;
    uint32_t killCount;
    uint16_t lootBonus;
    uint8_t killBonus;
    uint8_t bossRaceRepeat;
    uint32_t removePrice;
    uint8_t inactive;
};

struct BossUnlocked
{
    uint32_t bossId;
    uint8_t bossRace;
};

struct BosstiarySlotsData
{
    uint32_t playerPoints;
    uint32_t totalPointsNextBonus;
    uint16_t currentBonus;
    uint16_t nextBonus;
    bool isSlotOneUnlocked;
    uint32_t bossIdSlotOne;
    std::optional<BosstiarySlot> slotOneData;
    bool isSlotTwoUnlocked;
    uint32_t bossIdSlotTwo;
    std::optional<BosstiarySlot> slotTwoData;
    bool isTodaySlotUnlocked;
    uint32_t boostedBossId;
    std::optional<BosstiarySlot> todaySlotData;
    bool bossesUnlocked;
    std::vector<BossUnlocked> bossesUnlockedData;
};

struct ItemSummary
{
    uint16_t itemId;
    uint8_t tier;
    uint32_t amount;
};

struct CyclopediaCharacterItemSummary
{
    std::vector<ItemSummary> inventory;
    std::vector<ItemSummary> store;
    std::vector<ItemSummary> stash;
    std::vector<ItemSummary> depot;
    std::vector<ItemSummary> inbox;
};

struct RecentPvPKillEntry
{
    uint32_t timestamp;
    std::string description;
    uint8_t status;
};

struct CyclopediaCharacterRecentPvPKills
{
    std::vector<RecentPvPKillEntry> entries;
};

struct RecentDeathEntry
{
    uint32_t timestamp;
    std::string cause;
};

struct CyclopediaCharacterRecentDeaths
{
    std::vector<RecentDeathEntry> entries;
};

struct OutfitColorStruct
{
    uint8_t lookHead;
    uint8_t lookBody;
    uint8_t lookLegs;
    uint8_t lookFeet;
    uint8_t lookMountHead;
    uint8_t lookMountBody;
    uint8_t lookMountLegs;
    uint8_t lookMountFeet;
};

struct CharacterInfoOutfits
{
    uint16_t lookType;
    std::string name;
    uint8_t addons;
    uint8_t type;
    uint32_t isCurrent;
};

struct CharacterInfoMounts
{
    uint16_t mountId;
    std::string name;
    uint8_t type;
    uint32_t isCurrent;
};

struct CharacterInfoFamiliar
{
    uint16_t lookType;
    std::string name;
    uint8_t type;
    uint32_t isCurrent;
};

struct DailyRewardItem
{
    uint16_t itemId;
    std::string name;
    uint32_t weight;
};

struct DailyRewardBundle
{
    uint8_t bundleType;
    uint16_t itemId;
    std::string name;
    uint8_t count;
};

struct DailyRewardDay
{
    uint8_t redeemMode;
    uint8_t itemsToSelect;
    std::vector<DailyRewardItem> selectableItems;
    std::vector<DailyRewardBundle> bundleItems;
};

struct DailyRewardBonus
{
    std::string name;
    uint8_t id;
};

struct DailyRewardData
{
    uint8_t days;
    std::vector<DailyRewardDay> freeRewards;
    std::vector<DailyRewardDay> premiumRewards;
    std::vector<DailyRewardBonus> bonuses;
    uint8_t maxUnlockableDragons;
};

struct CyclopediaCharacterOffenceStats
{
    double critChance;
    double critDamage;
    double critDamageBase;
    double critDamageImbuement;
    double critDamageWheel;

    double lifeLeech;
    double lifeLeechBase;
    double lifeLeechImbuement;
    double lifeLeechWheel;

    double manaLeech;
    double manaLeechBase;
    double manaLeechImbuement;
    double manaLeechWheel;

    double onslaught;
    double onslaughtBase;
    double onslaughtBonus;

    double cleavePercent;

    std::vector<uint16_t> perfectShotDamage;

    uint16_t flatDamage;
    uint16_t flatDamageBase;

    uint16_t weaponAttack;
    uint16_t weaponFlatModifier;
    uint16_t weaponDamage;
    uint8_t weaponSkillType;
    uint16_t weaponSkillLevel;
    uint16_t weaponSkillModifier;
    uint8_t weaponElement;
    double weaponElementDamage;
    uint8_t weaponElementType;
    std::vector<double> weaponAccuracy;
};

struct CyclopediaCharacterDefenceStats
{
    double dodgeTotal;
    double dodgeBase;
    double dodgeBonus;
    double dodgeWheel;

    uint32_t magicShieldCapacity;
    uint16_t magicShieldCapacityFlat;
    double magicShieldCapacityPercent;

    uint16_t reflectPhysical;
    uint16_t armor;

    uint16_t defense;
    uint16_t defenseEquipment;
    uint8_t defenseSkillType;
    uint16_t shieldingSkill;
    uint16_t defenseWheel;

    double mitigation;
    double mitigationBase;
    double mitigationEquipment;
    double mitigationShield;
    double mitigationWheel;
    double mitigationCombatTactics;

    struct ElementalResistance
    {
        uint8_t element;
        double value;
    };

    std::vector<ElementalResistance> resistances;
};

struct CyclopediaCharacterMiscStats
{
    double momentumTotal;
    double momentumBase;
    double momentumBonus;
    double momentumWheel;

    double dodgeTotal;
    double dodgeBase;
    double dodgeBonus;
    double dodgeWheel;

    double damageReflectionTotal;
    double damageReflectionBase;
    double damageReflectionBonus;

    uint8_t haveBlesses;
    uint8_t totalBlesses;

    struct Concoction
    {
        uint16_t id;
        uint32_t duration;
    };

    std::vector<Concoction> concoctions;
};

struct ForgeItemInfo
{
    uint16_t id{ 0 };
    uint8_t tier{ 0 };
    uint16_t count{ 0 };
};

struct ForgeTransferData
{
    std::vector<ForgeItemInfo> donors;
    std::vector<ForgeItemInfo> receivers;
};

struct ForgeOpenData
{
    std::vector<ForgeItemInfo> fusionItems;
    std::vector<std::vector<ForgeItemInfo>> convergenceFusion;
    std::vector<ForgeTransferData> transfers;
    std::vector<ForgeTransferData> convergenceTransfers;
    uint16_t dustLevel{ 0 };
};
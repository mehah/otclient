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

#include "luavaluecasts_client.h"
#include <framework/luaengine/luainterface.h>

int push_luavalue(const Outfit& outfit)
{
    g_lua.createTable(0, 8);
    g_lua.pushInteger(outfit.getId());
    g_lua.setField("type");
    g_lua.pushInteger(outfit.getAuxId());
    g_lua.setField("auxType");
    if (g_game.getFeature(Otc::GamePlayerAddons)) {
        g_lua.pushInteger(outfit.getAddons());
        g_lua.setField("addons");
    }
    g_lua.pushInteger(outfit.getHead());
    g_lua.setField("head");
    g_lua.pushInteger(outfit.getBody());
    g_lua.setField("body");
    g_lua.pushInteger(outfit.getLegs());
    g_lua.setField("legs");
    g_lua.pushInteger(outfit.getFeet());
    g_lua.setField("feet");
    if (g_game.getFeature(Otc::GamePlayerMounts)) {
        g_lua.pushInteger(outfit.getMount());
        g_lua.setField("mount");
    }
    return 1;
}

bool luavalue_cast(int index, Outfit& outfit)
{
    if (!g_lua.isTable(index))
        return false;

    g_lua.getField("type", index);
    outfit.setId(g_lua.popInteger());
    g_lua.getField("auxType", index);
    outfit.setAuxId(g_lua.popInteger());
    if (g_game.getFeature(Otc::GamePlayerAddons)) {
        g_lua.getField("addons", index);
        outfit.setAddons(g_lua.popInteger());
    }
    g_lua.getField("head", index);
    outfit.setHead(g_lua.popInteger());
    g_lua.getField("body", index);
    outfit.setBody(g_lua.popInteger());
    g_lua.getField("legs", index);
    outfit.setLegs(g_lua.popInteger());
    g_lua.getField("feet", index);
    outfit.setFeet(g_lua.popInteger());
    if (g_game.getFeature(Otc::GamePlayerMounts)) {
        g_lua.getField("mount", index);
        outfit.setMount(g_lua.popInteger());
    }
    if (g_game.getFeature(Otc::GameWingsAurasEffectsShader)) {
        g_lua.getField("wings", index);
        outfit.setWing(g_lua.popInteger());
        g_lua.getField("effects", index);
        outfit.setEffect(g_lua.popInteger());
        g_lua.getField("auras", index);
        outfit.setAura(g_lua.popInteger());
        g_lua.getField("shaders", index);
        outfit.setShader(g_lua.popString());
    }

    return true;
}

int push_luavalue(const Position& pos)
{
    if (pos.isValid()) {
        g_lua.createTable(0, 3);
        g_lua.pushInteger(pos.x);
        g_lua.setField("x");
        g_lua.pushInteger(pos.y);
        g_lua.setField("y");
        g_lua.pushInteger(pos.z);
        g_lua.setField("z");
    } else
        g_lua.pushNil();

    return 1;
}

bool luavalue_cast(int index, Position& pos)
{
    if (!g_lua.isTable(index))
        return false;

    g_lua.getField("x", index);
    pos.x = g_lua.popInteger();
    g_lua.getField("y", index);
    pos.y = g_lua.popInteger();
    g_lua.getField("z", index);
    pos.z = g_lua.popInteger();

    return true;
}

int push_luavalue(const MarketData& data)
{
    g_lua.createTable(0, 6);
    g_lua.pushInteger(data.category);
    g_lua.setField("category");
    g_lua.pushString(data.name);
    g_lua.setField("name");
    g_lua.pushInteger(data.requiredLevel);
    g_lua.setField("requiredLevel");
    g_lua.pushInteger(data.restrictVocation);
    g_lua.setField("restrictVocation");
    g_lua.pushInteger(data.showAs);
    g_lua.setField("showAs");
    g_lua.pushInteger(data.tradeAs);
    g_lua.setField("tradeAs");

    return 1;
}

bool luavalue_cast(int index, MarketData& data)
{
    if (!g_lua.isTable(index))
        return false;

    g_lua.getField("category", index);
    data.category = static_cast<ITEM_CATEGORY>(g_lua.popInteger());
    g_lua.getField("name", index);
    data.name = g_lua.popString();
    g_lua.getField("requiredLevel", index);
    data.requiredLevel = g_lua.popInteger();
    g_lua.getField("restrictVocation", index);
    data.restrictVocation = g_lua.popInteger();
    g_lua.getField("showAs", index);
    data.showAs = g_lua.popInteger();
    g_lua.getField("tradeAs", index);
    data.tradeAs = g_lua.popInteger();

    return true;
}

int push_luavalue(const Light& light)
{
    g_lua.createTable(0, 2);
    g_lua.pushInteger(light.color);
    g_lua.setField("color");
    g_lua.pushInteger(light.intensity);
    g_lua.setField("intensity");

    return 1;
}

bool luavalue_cast(int index, Light& light)
{
    if (!g_lua.isTable(index))
        return false;

    g_lua.getField("color", index);
    light.color = g_lua.popInteger();
    g_lua.getField("intensity", index);
    light.intensity = g_lua.popInteger();

    return true;
}

int push_luavalue(const UnjustifiedPoints& unjustifiedPoints)
{
    g_lua.createTable(0, 7);
    g_lua.pushInteger(unjustifiedPoints.killsDay);
    g_lua.setField("killsDay");
    g_lua.pushInteger(unjustifiedPoints.killsDayRemaining);
    g_lua.setField("killsDayRemaining");
    g_lua.pushInteger(unjustifiedPoints.killsWeek);
    g_lua.setField("killsWeek");
    g_lua.pushInteger(unjustifiedPoints.killsWeekRemaining);
    g_lua.setField("killsWeekRemaining");
    g_lua.pushInteger(unjustifiedPoints.killsMonth);
    g_lua.setField("killsMonth");
    g_lua.pushInteger(unjustifiedPoints.killsMonthRemaining);
    g_lua.setField("killsMonthRemaining");
    g_lua.pushInteger(unjustifiedPoints.skullTime);
    g_lua.setField("skullTime");

    return 1;
}

int push_luavalue(const Imbuement& i)
{
    g_lua.createTable(0, 11);
    g_lua.pushInteger(i.id);
    g_lua.setField("id");
    g_lua.pushString(i.name);
    g_lua.setField("name");
    g_lua.pushString(i.description);
    g_lua.setField("description");
    g_lua.pushString(i.group);
    g_lua.setField("group");
    g_lua.pushInteger(i.imageId);
    g_lua.setField("imageId");
    g_lua.pushInteger(i.duration);
    g_lua.setField("duration");
    g_lua.pushBoolean(i.premiumOnly);
    g_lua.setField("premiumOnly");
    g_lua.createTable(i.sources.size(), 0);
    for (size_t j = 0; j < i.sources.size(); ++j) {
        g_lua.createTable(0, 2);
        g_lua.pushObject(i.sources[j].first);
        g_lua.setField("item");
        g_lua.pushString(i.sources[j].second);
        g_lua.setField("description");
        g_lua.rawSeti(j + 1);
    }
    g_lua.setField("sources");
    g_lua.pushInteger(i.cost);
    g_lua.setField("cost");
    g_lua.pushInteger(i.successRate);
    g_lua.setField("successRate");
    g_lua.pushInteger(i.protectionCost);
    g_lua.setField("protectionCost");
    return 1;
}

int push_luavalue(const ImbuementTrackerItem& i)
{
    g_lua.createTable(0, 3);
    g_lua.pushInteger(i.slot);
    g_lua.setField("slot");
    g_lua.pushObject(i.item);
    g_lua.setField("item");
    g_lua.createTable(i.slots.size(), 0);
    for (auto& [id, slot] : i.slots) {
        g_lua.createTable(0, 5);
        g_lua.pushInteger(id);
        g_lua.setField("id");
        g_lua.pushString(slot.name);
        g_lua.setField("name");
        g_lua.pushInteger(slot.iconId);
        g_lua.setField("iconId");
        g_lua.pushInteger(slot.duration);
        g_lua.setField("duration");
        g_lua.pushBoolean(slot.state);
        g_lua.setField("state");
        g_lua.rawSeti(id + 1);
    }
    g_lua.setField("slots");
    return 1;
}

bool luavalue_cast(int index, UnjustifiedPoints& unjustifiedPoints)
{
    if (!g_lua.isTable(index))
        return false;

    g_lua.getField("killsDay", index);
    unjustifiedPoints.killsDay = g_lua.popInteger();
    g_lua.getField("killsDayRemaining", index);
    unjustifiedPoints.killsDayRemaining = g_lua.popInteger();
    g_lua.getField("killsWeek", index);
    unjustifiedPoints.killsWeek = g_lua.popInteger();
    g_lua.getField("killsWeekRemaining", index);
    unjustifiedPoints.killsWeekRemaining = g_lua.popInteger();
    g_lua.getField("killsMonth", index);
    unjustifiedPoints.killsMonth = g_lua.popInteger();
    g_lua.getField("killsMonthRemaining", index);
    unjustifiedPoints.killsMonthRemaining = g_lua.popInteger();
    g_lua.getField("skullTime", index);
    unjustifiedPoints.skullTime = g_lua.popInteger();
    return true;
}

int push_luavalue(const BlessData& bless) {
    g_lua.createTable(0, 3);
    g_lua.pushInteger(bless.blessBitwise);
    g_lua.setField("blessBitwise");
    g_lua.pushInteger(bless.playerBlessCount);
    g_lua.setField("playerBlessCount");
    g_lua.pushInteger(bless.store);
    g_lua.setField("store");
    return 1;
}

int push_luavalue(const LogData& log) {
    g_lua.createTable(0, 3);
    g_lua.pushInteger(log.timestamp);
    g_lua.setField("timestamp");
    g_lua.pushInteger(log.colorMessage);
    g_lua.setField("colorMessage");
    g_lua.pushString(log.historyMessage);
    g_lua.setField("historyMessage");
    return 1;
}

int push_luavalue(const BlessDialogData& data) {
    g_lua.createTable(0, 11);
    g_lua.pushInteger(data.totalBless);
    g_lua.setField("totalBless");

    g_lua.createTable(data.blesses.size(), 0);
    for (size_t i = 0; i < data.blesses.size(); ++i) {
        push_luavalue(data.blesses[i]);
        g_lua.rawSeti(i + 1);
    }
    g_lua.setField("blesses");

    g_lua.pushInteger(data.premium);
    g_lua.setField("premium");
    g_lua.pushInteger(data.promotion);
    g_lua.setField("promotion");
    g_lua.pushInteger(data.pvpMinXpLoss);
    g_lua.setField("pvpMinXpLoss");
    g_lua.pushInteger(data.pvpMaxXpLoss);
    g_lua.setField("pvpMaxXpLoss");
    g_lua.pushInteger(data.pveExpLoss);
    g_lua.setField("pveExpLoss");
    g_lua.pushInteger(data.equipPvpLoss);
    g_lua.setField("equipPvpLoss");
    g_lua.pushInteger(data.equipPveLoss);
    g_lua.setField("equipPveLoss");
    g_lua.pushInteger(data.skull);
    g_lua.setField("skull");
    g_lua.pushInteger(data.aol);
    g_lua.setField("aol");

    g_lua.createTable(data.logs.size(), 0);
    for (size_t i = 0; i < data.logs.size(); ++i) {
        push_luavalue(data.logs[i]);
        g_lua.rawSeti(i + 1);
    }
    g_lua.setField("logs");
    
    return 1;
}

int push_luavalue(const StoreCategory& category) {
    g_lua.createTable(0, 5);
    g_lua.pushString(category.name);
    g_lua.setField("name");

    if (!category.parent.empty()) {
        g_lua.pushString(category.parent);
        g_lua.setField("parent");
    }

    g_lua.pushInteger(category.state);
    g_lua.setField("state");

    g_lua.createTable(0, category.icons.size());
    for (size_t i = 0; i < category.icons.size(); ++i) {
        g_lua.pushString(category.icons[i]);
        g_lua.rawSeti(i + 1);
    }
    g_lua.setField("icons");

    if (category.parent.empty()) {
        g_lua.createTable(0, category.subCategories.size());
        for (size_t i = 0; i < category.subCategories.size(); ++i) {
            push_luavalue(category.subCategories[i]);
            g_lua.rawSeti(i + 1);
        }
        g_lua.setField("subCategories");
    } else {
        g_lua.createTable(0, 0);
        g_lua.setField("subCategories");
    }

    return 1;
}

int push_luavalue(const SubOffer& subOffer) {
    g_lua.createTable(0, 9);
    g_lua.pushInteger(subOffer.id);
    g_lua.setField("id");
    g_lua.pushInteger(subOffer.count);
    g_lua.setField("count");
    g_lua.pushInteger(subOffer.price);
    g_lua.setField("price");
    g_lua.pushInteger(subOffer.coinType);
    g_lua.setField("coinType");
    g_lua.pushBoolean(subOffer.disabled);
    g_lua.setField("disabled");
    if (subOffer.disabled) {
        g_lua.pushInteger(subOffer.disabledReason);
        g_lua.setField("disabledReason");
    }
    g_lua.pushInteger(subOffer.state);
    g_lua.setField("state");
    if (subOffer.state == Otc::GameStoreInfoStatesType_t::STATE_SALE) {
        g_lua.pushInteger(subOffer.validUntil);
        g_lua.setField("validUntil");
        g_lua.pushInteger(subOffer.basePrice);
        g_lua.setField("basePrice");
    }
    return 1;
}

int push_luavalue(const StoreOffer& offer) {
    g_lua.createTable(0, 14);
    g_lua.pushString(offer.name);
    g_lua.setField("name");

    g_lua.createTable(0, offer.subOffers.size());
    for (size_t i = 0; i < offer.subOffers.size(); ++i) {
        push_luavalue(offer.subOffers[i]);
        g_lua.rawSeti(i + 1);
    }
    g_lua.setField("subOffers");

    g_lua.pushInteger(offer.ofertaid);
    g_lua.setField("ofertaid");
    g_lua.pushString(offer.description);
    g_lua.setField("description");
    g_lua.pushInteger(offer.type);
    g_lua.setField("type");

    if (offer.type == Otc::GameStoreInfoType_t::SHOW_NONE) {
        g_lua.pushString(offer.icon);
        g_lua.setField("icon");
    } else if (offer.type == Otc::GameStoreInfoType_t::SHOW_MOUNT) {
        g_lua.pushInteger(offer.mountId);
        g_lua.setField("mountId");
    } else if (offer.type == Otc::GameStoreInfoType_t::SHOW_ITEM) {
        g_lua.pushInteger(offer.itemId);
        g_lua.setField("itemId");
    } else if (offer.type == Otc::GameStoreInfoType_t::SHOW_OUTFIT) {
        g_lua.pushInteger(offer.outfitId);
        g_lua.setField("outfitId");
        g_lua.pushInteger(offer.outfitHead);
        g_lua.setField("outfitHead");
        g_lua.pushInteger(offer.outfitBody);
        g_lua.setField("outfitBody");
        g_lua.pushInteger(offer.outfitLegs);
        g_lua.setField("outfitLegs");
        g_lua.pushInteger(offer.outfitFeet);
        g_lua.setField("outfitFeet");
    } else if (offer.type == Otc::GameStoreInfoType_t::SHOW_HIRELING) {
        g_lua.pushInteger(offer.sex);
        g_lua.setField("sex");
        g_lua.pushInteger(offer.maleOutfitId);
        g_lua.setField("maleOutfitId");
        g_lua.pushInteger(offer.femaleOutfitId);
        g_lua.setField("femaleOutfitId");
        g_lua.pushInteger(offer.outfitHead);
        g_lua.setField("outfitHead");
        g_lua.pushInteger(offer.outfitBody);
        g_lua.setField("outfitBody");
        g_lua.pushInteger(offer.outfitLegs);
        g_lua.setField("outfitLegs");
        g_lua.pushInteger(offer.outfitFeet);
        g_lua.setField("outfitFeet");
    }

    g_lua.pushInteger(offer.tryOnType);
    g_lua.setField("tryOnType");
    g_lua.pushInteger(offer.collection);
    g_lua.setField("collection");
    g_lua.pushInteger(offer.popularityScore);
    g_lua.setField("popularityScore");
    g_lua.pushInteger(offer.stateNewUntil);
    g_lua.setField("stateNewUntil");
    g_lua.pushBoolean(offer.configurable);
    g_lua.setField("configurable");
    g_lua.pushInteger(offer.productsCapacity);
    g_lua.setField("productsCapacity");

    return 1;
}

int push_luavalue(const HomeOffer& homeOffer) {
    g_lua.createTable(0, 16);
    g_lua.pushString(homeOffer.name);
    g_lua.setField("name");
    g_lua.pushInteger(homeOffer.unknownByte);
    g_lua.setField("unknownByte");
    g_lua.pushInteger(homeOffer.id);
    g_lua.setField("id");
    g_lua.pushInteger(homeOffer.unknownU16);
    g_lua.setField("unknownU16");
    g_lua.pushInteger(homeOffer.price);
    g_lua.setField("price");
    g_lua.pushInteger(homeOffer.coinType);
    g_lua.setField("coinType");
    g_lua.pushInteger(homeOffer.disabledReasonIndex);
    g_lua.setField("disabledReasonIndex");
    g_lua.pushInteger(homeOffer.unknownByte2);
    g_lua.setField("unknownByte2");
    g_lua.pushInteger(homeOffer.type);
    g_lua.setField("type");

    if (homeOffer.type == Otc::GameStoreInfoType_t::SHOW_NONE) {
        g_lua.pushString(homeOffer.icon);
        g_lua.setField("icon");
    } else if (homeOffer.type == Otc::GameStoreInfoType_t::SHOW_MOUNT) {
        g_lua.pushInteger(homeOffer.mountClientId);
        g_lua.setField("mountClientId");
    } else if (homeOffer.type == Otc::GameStoreInfoType_t::SHOW_ITEM) {
        g_lua.pushInteger(homeOffer.itemType);
        g_lua.setField("itemType");
    } else if (homeOffer.type == Otc::GameStoreInfoType_t::SHOW_OUTFIT) {
        g_lua.pushInteger(homeOffer.sexId);
        g_lua.setField("sexId");
        g_lua.createTable(0, 4);
        g_lua.pushInteger(homeOffer.outfit.lookHead);
        g_lua.setField("lookHead");
        g_lua.pushInteger(homeOffer.outfit.lookBody);
        g_lua.setField("lookBody");
        g_lua.pushInteger(homeOffer.outfit.lookLegs);
        g_lua.setField("lookLegs");
        g_lua.pushInteger(homeOffer.outfit.lookFeet);
        g_lua.setField("lookFeet");
        g_lua.setField("outfit");
    }

    g_lua.pushInteger(homeOffer.tryOnType);
    g_lua.setField("tryOnType");
    g_lua.pushInteger(homeOffer.collection);
    g_lua.setField("collection");
    g_lua.pushInteger(homeOffer.popularityScore);
    g_lua.setField("popularityScore");
    g_lua.pushInteger(homeOffer.stateNewUntil);
    g_lua.setField("stateNewUntil");
    g_lua.pushInteger(homeOffer.userConfiguration);
    g_lua.setField("userConfiguration");
    g_lua.pushInteger(homeOffer.productsCapacity);
    g_lua.setField("productsCapacity");

    return 1;
}

int push_luavalue(const Banner& banner) {
    g_lua.createTable(0, 5);
    g_lua.pushString(banner.image);
    g_lua.setField("image");
    g_lua.pushInteger(banner.bannerType);
    g_lua.setField("bannerType");
    g_lua.pushInteger(banner.offerId);
    g_lua.setField("offerId");
    g_lua.pushInteger(banner.unknownByte1);
    g_lua.setField("unknownByte1");
    g_lua.pushInteger(banner.unknownByte2);
    g_lua.setField("unknownByte2");
    return 1;
}

int push_luavalue(const StoreData& storeData) {
    g_lua.createTable(0, 7);
    g_lua.pushString(storeData.categoryName);
    g_lua.setField("categoryName");
    g_lua.pushInteger(storeData.redirectId);
    g_lua.setField("redirectId");

    g_lua.createTable(0, storeData.disableReasons.size());
    for (size_t i = 0; i < storeData.disableReasons.size(); ++i) {
        g_lua.pushString(storeData.disableReasons[i]);
        g_lua.rawSeti(i + 1);
    }
    g_lua.setField("disableReasons");

    if (storeData.categoryName == "Home") {
        g_lua.createTable(0, storeData.homeOffers.size());
        for (size_t i = 0; i < storeData.homeOffers.size(); ++i) {
            push_luavalue(storeData.homeOffers[i]);
            g_lua.rawSeti(i + 1);
        }
    } else {
        g_lua.createTable(0, storeData.storeOffers.size());
        for (size_t i = 0; i < storeData.storeOffers.size(); ++i) {
            push_luavalue(storeData.storeOffers[i]);
            g_lua.rawSeti(i + 1);
        }
    }
    g_lua.setField("offers");

    if (storeData.categoryName == "Home") {
        g_lua.createTable(0, storeData.banners.size());
        for (size_t i = 0; i < storeData.banners.size(); ++i) {
            push_luavalue(storeData.banners[i]);
            g_lua.rawSeti(i + 1);
        }
        g_lua.setField("banners");

        g_lua.pushInteger(storeData.bannerDelay);
        g_lua.setField("bannerDelay");
    }

    if (storeData.categoryName == "Search") {
        g_lua.pushBoolean(storeData.tooManyResults);
        g_lua.setField("tooManyResults");
    }

    return 1;
}

// cyclopedia
int push_luavalue(const CyclopediaBestiaryRace& race) {
    g_lua.createTable(0, 4);
    g_lua.pushInteger(race.race);
    g_lua.setField("race");
    g_lua.pushString(race.bestClass);
    g_lua.setField("bestClass");
    g_lua.pushInteger(race.count);
    g_lua.setField("count");
    g_lua.pushInteger(race.unlockedCount);
    g_lua.setField("unlockedCount");
    return 1;
}

int push_luavalue(const LootItem& lootItem) {
    g_lua.createTable(0, 5);
    g_lua.pushInteger(lootItem.itemId);
    g_lua.setField("itemId");
    g_lua.pushInteger(lootItem.diffculty);
    g_lua.setField("diffculty");
    g_lua.pushInteger(lootItem.specialEvent);
    g_lua.setField("specialEvent");
    g_lua.pushString(lootItem.name);
    g_lua.setField("name");
    g_lua.pushInteger(lootItem.amount);
    g_lua.setField("amount");
    return 1;
}

int push_luavalue(const BestiaryMonsterData& data) {
    g_lua.createTable(0, 16);
    g_lua.pushInteger(data.id);
    g_lua.setField("id");
    g_lua.pushString(data.bestClass);
    g_lua.setField("class");
    g_lua.pushInteger(data.currentLevel);
    g_lua.setField("currentLevel");
    g_lua.pushInteger(data.AnimusMasteryPoints);
    g_lua.setField("AnimusMasteryPoints");
    g_lua.pushInteger(data.AnimusMasteryBonus);
    g_lua.setField("AnimusMasteryBonus");
    g_lua.pushInteger(data.killCounter);
    g_lua.setField("killCounter");
    g_lua.pushInteger(data.thirdDifficulty);
    g_lua.setField("thirdDifficulty");
    g_lua.pushInteger(data.secondUnlock);
    g_lua.setField("secondUnlock");
    g_lua.pushInteger(data.lastProgressKillCount);
    g_lua.setField("lastProgressKillCount");
    g_lua.pushInteger(data.difficulty);
    g_lua.setField("difficulty");
    g_lua.pushInteger(data.ocorrence);
    g_lua.setField("ocorrence");

    g_lua.createTable(data.loot.size(), 0);
    for (size_t i = 0; i < data.loot.size(); ++i) {
        push_luavalue(data.loot[i]);
        g_lua.rawSeti(i + 1);
    }
    g_lua.setField("loot");

    if (data.currentLevel > 1) {
        g_lua.pushInteger(data.charmValue);
        g_lua.setField("charmValue");
        g_lua.pushInteger(data.attackMode);
        g_lua.setField("attackMode");
        g_lua.pushInteger(data.maxHealth);
        g_lua.setField("maxHealth");
        g_lua.pushInteger(data.experience);
        g_lua.setField("experience");
        g_lua.pushInteger(data.speed);
        g_lua.setField("speed");
        g_lua.pushInteger(data.armor);
        g_lua.setField("armor");
        g_lua.pushNumber(data.mitigation);
        g_lua.setField("mitigation");
    }

    if (data.currentLevel > 2) {
        g_lua.createTable(data.combat.size(), 0);
        for (const auto& [elementId, elementValue] : data.combat) {
            g_lua.pushInteger(elementValue);
            g_lua.rawSeti(elementId + 1);
        }
        g_lua.setField("combat");
        g_lua.pushString(data.location);
        g_lua.setField("location");
    }

    return 1;
}       

int push_luavalue(const CharmData& charm) {
    g_lua.createTable(0, 7);
    g_lua.pushInteger(charm.id);
    g_lua.setField("id");
    g_lua.pushString(charm.name);
    g_lua.setField("name");
    g_lua.pushString(charm.description);
    g_lua.setField("description");
    g_lua.pushInteger(charm.unlockPrice);
    g_lua.setField("unlockPrice");
    g_lua.pushBoolean(charm.unlocked);
    g_lua.setField("unlocked");
    g_lua.pushBoolean(charm.asignedStatus);
    g_lua.setField("asignedStatus");
    g_lua.pushInteger(charm.raceId);
    g_lua.setField("raceId");
    g_lua.pushInteger(charm.removeRuneCost);
    g_lua.setField("removeRuneCost");
    return 1;
}

int push_luavalue(const BestiaryCharmsData& charmData) {
    g_lua.createTable(0, 3);
    g_lua.pushInteger(charmData.points);
    g_lua.setField("points");

    g_lua.createTable(charmData.charms.size(), 0);
    for (size_t i = 0; i < charmData.charms.size(); ++i) {
        push_luavalue(charmData.charms[i]);
        g_lua.rawSeti(i + 1);
    }
    g_lua.setField("charms");

    g_lua.createTable(charmData.finishedMonsters.size(), 0);
    for (size_t i = 0; i < charmData.finishedMonsters.size(); ++i) {
        g_lua.pushInteger(charmData.finishedMonsters[i]);
        g_lua.rawSeti(i + 1);
    }
    g_lua.setField("finishedMonsters");
    return 1;
}

int push_luavalue(const BestiaryOverviewMonsters& monster) {
    g_lua.createTable(0, 3);
    g_lua.pushInteger(monster.id);
    g_lua.setField("id");
    g_lua.pushInteger(monster.currentLevel);
    g_lua.setField("currentLevel");
    g_lua.pushInteger(monster.occurrence);
    g_lua.setField("occurrence");
    g_lua.pushInteger(monster.creatureAnimusMasteryBonus);
    g_lua.setField("creatureAnimusMasteryBonus");
    return 1;
}

int push_luavalue(const CyclopediaCharacterGeneralStats& stats) {
    g_lua.createTable(0, 26);
    g_lua.pushInteger(stats.experience);
    g_lua.setField("xperiencee");
    g_lua.pushInteger(stats.level);
    g_lua.setField("level");
    g_lua.pushInteger(stats.levelPercent);
    g_lua.setField("levelPercent");
    g_lua.pushInteger(stats.baseExpGain);
    g_lua.setField("baseExpGain");
    g_lua.pushInteger(stats.lowLevelExpBonus);
    g_lua.setField("lowLevelExpBonus");
    g_lua.pushInteger(stats.XpBoostPercent);
    g_lua.setField("XpBoostPercent");
    g_lua.pushInteger(stats.staminaExpBonus);
    g_lua.setField("staminaExpBonus");
    g_lua.pushInteger(stats.XpBoostBonusRemainingTime);
    g_lua.setField("XpBoostBonusRemainingTime");
    g_lua.pushInteger(stats.canBuyXpBoost);
    g_lua.setField("canBuyXpBoost");
    g_lua.pushInteger(stats.health);
    g_lua.setField("health");
    g_lua.pushInteger(stats.maxHealth);
    g_lua.setField("maxHealth");
    g_lua.pushInteger(stats.mana);
    g_lua.setField("mana");
    g_lua.pushInteger(stats.maxMana);
    g_lua.setField("maxMana");
    g_lua.pushInteger(stats.soul);
    g_lua.setField("soul");
    g_lua.pushInteger(stats.staminaMinutes);
    g_lua.setField("staminaMinutes");
    g_lua.pushInteger(stats.regenerationCondition);
    g_lua.setField("regenerationCondition");
    g_lua.pushInteger(stats.offlineTrainingTime);
    g_lua.setField("offlineTrainingTime");
    g_lua.pushInteger(stats.speed);
    g_lua.setField("speed");
    g_lua.pushInteger(stats.baseSpeed);
    g_lua.setField("baseSpeed");
    g_lua.pushInteger(stats.capacity);
    g_lua.setField("capacity");
    g_lua.pushInteger(stats.baseCapacity);
    g_lua.setField("baseCapacity");
    g_lua.pushInteger(stats.freeCapacity);
    g_lua.setField("freeCapacity");
    g_lua.pushInteger(stats.magicLevel);
    g_lua.setField("magicLevel");
    g_lua.pushInteger(stats.baseMagicLevel);
    g_lua.setField("baseMagicLevel");
    g_lua.pushInteger(stats.loyaltyMagicLevel);
    g_lua.setField("loyaltyMagicLevel");
    g_lua.pushInteger(stats.magicLevelPercent);
    g_lua.setField("magicLevelPercent");

    return 1;
}

int push_luavalue(const CyclopediaCharacterCombatStats& data) {
    g_lua.createTable(0, 7);
    g_lua.pushInteger(data.weaponElement);
    g_lua.setField("weaponElement");
    g_lua.pushInteger(data.weaponMaxHitChance);
    g_lua.setField("weaponMaxHitChance");
    g_lua.pushInteger(data.weaponElementDamage);
    g_lua.setField("weaponElementDamage");
    g_lua.pushInteger(data.weaponElementType);
    g_lua.setField("weaponElementType");
    g_lua.pushInteger(data.defense);
    g_lua.setField("defense");
    g_lua.pushInteger(data.armor);
    g_lua.setField("armor");
    g_lua.pushInteger(data.haveBlessings);
    g_lua.setField("haveBlessings");
    return 1;
}

int push_luavalue(const BosstiaryData& boss) {
    g_lua.createTable(0, 4);
    g_lua.pushInteger(boss.raceId);
    g_lua.setField("raceId");
    g_lua.pushInteger(boss.category);
    g_lua.setField("category");
    g_lua.pushInteger(boss.kills);
    g_lua.setField("kills");
    g_lua.pushInteger(boss.isTrackerActived);
    g_lua.setField("isTrackerActived");
    return 1;
}

int push_luavalue(const BosstiarySlot& slot) {
    g_lua.createTable(0, 7);
    g_lua.pushInteger(slot.bossRace);
    g_lua.setField("bossRace");
    g_lua.pushInteger(slot.killCount);
    g_lua.setField("killCount");
    g_lua.pushInteger(slot.lootBonus);
    g_lua.setField("lootBonus");
    g_lua.pushInteger(slot.killBonus);
    g_lua.setField("killBonus");
    g_lua.pushInteger(slot.bossRaceRepeat);
    g_lua.setField("bossRaceRepeat");
    g_lua.pushInteger(slot.removePrice);
    g_lua.setField("removePrice");
    g_lua.pushInteger(slot.inactive);
    g_lua.setField("inactive");
    return 1;
}

int push_luavalue(const BossUnlocked& boss) {
    g_lua.createTable(0, 2);
    g_lua.pushInteger(boss.bossId);
    g_lua.setField("bossId");
    g_lua.pushInteger(boss.bossRace);
    g_lua.setField("bossRace");
    return 1;
}

int push_luavalue(const BosstiarySlotsData& data) {
    g_lua.createTable(0, 13);
    g_lua.pushInteger(data.playerPoints);
    g_lua.setField("playerPoints");
    g_lua.pushInteger(data.totalPointsNextBonus);
    g_lua.setField("totalPointsNextBonus");
    g_lua.pushInteger(data.currentBonus);
    g_lua.setField("currentBonus");
    g_lua.pushInteger(data.nextBonus);
    g_lua.setField("nextBonus");

    g_lua.pushBoolean(data.isSlotOneUnlocked);
    g_lua.setField("isSlotOneUnlocked");
    g_lua.pushInteger(data.bossIdSlotOne);
    g_lua.setField("bossIdSlotOne");
    if (data.slotOneData) {
        push_luavalue(*data.slotOneData);
        g_lua.setField("slotOneData");
    }

    g_lua.pushBoolean(data.isSlotTwoUnlocked);
    g_lua.setField("isSlotTwoUnlocked");
    g_lua.pushInteger(data.bossIdSlotTwo);
    g_lua.setField("bossIdSlotTwo");
    if (data.slotTwoData) {
        push_luavalue(*data.slotTwoData);
        g_lua.setField("slotTwoData");
    }

    g_lua.pushBoolean(data.isTodaySlotUnlocked);
    g_lua.setField("isTodaySlotUnlocked");
    g_lua.pushInteger(data.boostedBossId);
    g_lua.setField("boostedBossId");
    if (data.todaySlotData) {
        push_luavalue(*data.todaySlotData);
        g_lua.setField("todaySlotData");
    }

    g_lua.pushBoolean(data.bossesUnlocked);
    g_lua.setField("bossesUnlocked");

    g_lua.createTable(data.bossesUnlockedData.size(), 0);
    for (size_t i = 0; i < data.bossesUnlockedData.size(); ++i) {
        push_luavalue(data.bossesUnlockedData[i]);
        g_lua.rawSeti(i + 1);
    }
    g_lua.setField("bossesUnlockedData");
        return 1;
}

int push_luavalue(const ItemSummary& item) {
    g_lua.createTable(0, 2);
    g_lua.pushInteger(item.itemId);
    g_lua.setField("itemId");
    g_lua.pushInteger(item.amount);
    g_lua.setField("amount");
    return 1;
}

int push_luavalue(const CyclopediaCharacterItemSummary& data) {
    g_lua.createTable(0, 5);

    g_lua.createTable(data.inventory.size(), 0);
    for (size_t i = 0; i < data.inventory.size(); ++i) {
        push_luavalue(data.inventory[i]);
        g_lua.rawSeti(i + 1);
    }
    g_lua.setField("inventory");

    g_lua.createTable(data.store.size(), 0);
    for (size_t i = 0; i < data.store.size(); ++i) {
        push_luavalue(data.store[i]);
        g_lua.rawSeti(i + 1);
    }
    g_lua.setField("store");

    g_lua.createTable(data.stash.size(), 0);
    for (size_t i = 0; i < data.stash.size(); ++i) {
        push_luavalue(data.stash[i]);
        g_lua.rawSeti(i + 1);
    }
    g_lua.setField("stash");

    g_lua.createTable(data.depot.size(), 0);
    for (size_t i = 0; i < data.depot.size(); ++i) {
        push_luavalue(data.depot[i]);
        g_lua.rawSeti(i + 1);
    }
    g_lua.setField("depot");

    g_lua.createTable(data.inbox.size(), 0);
    for (size_t i = 0; i < data.inbox.size(); ++i) {
        push_luavalue(data.inbox[i]);
        g_lua.rawSeti(i + 1);
    }
    g_lua.setField("inbox");

    return 1;
}

int push_luavalue(const RecentPvPKillEntry& entry) {
    g_lua.createTable(0, 3);
    g_lua.pushInteger(entry.timestamp);
    g_lua.setField("timestamp");
    g_lua.pushString(entry.description);
    g_lua.setField("description");
    g_lua.pushInteger(entry.status);
    g_lua.setField("status");
    return 1;
}

int push_luavalue(const CyclopediaCharacterRecentPvPKills& data) {
    g_lua.createTable(data.entries.size(), 0);
    for (size_t i = 0; i < data.entries.size(); ++i) {
        push_luavalue(data.entries[i]);
        g_lua.rawSeti(i + 1);
    }
    return 1;
}

int push_luavalue(const RecentDeathEntry& entry) {
    g_lua.createTable(0, 2);
    g_lua.pushInteger(entry.timestamp);
    g_lua.setField("timestamp");
    g_lua.pushString(entry.cause);
    g_lua.setField("cause");
    return 1;
}

int push_luavalue(const CyclopediaCharacterRecentDeaths& data) {
    g_lua.createTable(data.entries.size(), 0);
    for (size_t i = 0; i < data.entries.size(); ++i) {
        push_luavalue(data.entries[i]);
        g_lua.rawSeti(i + 1);
    }
    return 1;
}

int push_luavalue(const OutfitColorStruct& currentOutfit) {
    g_lua.createTable(0, 8);
    g_lua.pushInteger(currentOutfit.lookHead);
    g_lua.setField("lookHead");
    g_lua.pushInteger(currentOutfit.lookBody);
    g_lua.setField("lookBody");
    g_lua.pushInteger(currentOutfit.lookLegs);
    g_lua.setField("lookLegs");
    g_lua.pushInteger(currentOutfit.lookFeet);
    g_lua.setField("lookFeet");
    g_lua.pushInteger(currentOutfit.lookMountHead);
    g_lua.setField("lookMountHead");
    g_lua.pushInteger(currentOutfit.lookMountBody);
    g_lua.setField("lookMountBody");
    g_lua.pushInteger(currentOutfit.lookMountLegs);
    g_lua.setField("lookMountLegs");
    g_lua.pushInteger(currentOutfit.lookMountFeet);
    g_lua.setField("lookMountFeet");
    return 1;
}

int push_luavalue(const CharacterInfoOutfits& outfit) {
    g_lua.createTable(0, 5);
    g_lua.pushInteger(outfit.lookType);
    g_lua.setField("lookType");
    g_lua.pushString(outfit.name);
    g_lua.setField("name");
    g_lua.pushInteger(outfit.addons);
    g_lua.setField("addons");
    g_lua.pushInteger(outfit.type);
    g_lua.setField("type");
    g_lua.pushInteger(outfit.isCurrent);
    g_lua.setField("isCurrent");
    return 1;
}

int push_luavalue(const CharacterInfoMounts& mount) {
    g_lua.createTable(0, 4);
    g_lua.pushInteger(mount.mountId);
    g_lua.setField("mountId");
    g_lua.pushString(mount.name);
    g_lua.setField("name");
    g_lua.pushInteger(mount.type);
    g_lua.setField("type");
    g_lua.pushInteger(mount.isCurrent);
    g_lua.setField("isCurrent");
    return 1;
}

int push_luavalue(const CharacterInfoFamiliar& familiar) {
    g_lua.createTable(0, 4);
    g_lua.pushInteger(familiar.lookType);
    g_lua.setField("lookType");
    g_lua.pushString(familiar.name);
    g_lua.setField("name");
    g_lua.pushInteger(familiar.type);
    g_lua.setField("type");
    g_lua.pushInteger(familiar.isCurrent);
    g_lua.setField("isCurrent");
    return 1;
}

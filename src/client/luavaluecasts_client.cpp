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

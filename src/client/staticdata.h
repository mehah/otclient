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

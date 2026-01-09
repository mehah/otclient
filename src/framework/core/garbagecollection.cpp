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

#include "garbagecollection.h"

#include "client/const.h"
#include "client/thingtypemanager.h"
#include "framework/graphics/declarations.h"
#include "framework/graphics/texture.h"
#include "framework/graphics/texturemanager.h"
#include "framework/graphics/animatedtexture.h"
#include "framework/luaengine/luainterface.h"

constexpr uint32_t LUA_TIME = 15 * 60 * 1000; // 15min
constexpr uint32_t TEXTURE_TIME = 30 * 60 * 1000; // 30min
constexpr uint32_t THINGTYPE_TIME = 2 * 1000; // 2seg

Timer lua_timer, texture_timer, drawpool_timer, thingtype_timer;

void GarbageCollection::poll() {
    if (canCheck(thingtype_timer, THINGTYPE_TIME))
        thingType();

    if (canCheck(texture_timer, TEXTURE_TIME))
        texture();

    if (canCheck(lua_timer, LUA_TIME))
        lua();
}

void GarbageCollection::lua() {
    g_lua.collectGarbage();
}

void GarbageCollection::texture() {
    static constexpr uint32_t IDLE_TIME = 25 * 60 * 1000; // 25min

    std::erase_if(g_textures.m_textures, [](const auto& item) {
        const auto& [key, tex] = item;
        return tex.use_count() == 1 && tex->m_lastTimeUsage.ticksElapsed() > IDLE_TIME;
    });

    std::erase_if(g_textures.m_animatedTextures, [](const TexturePtr& tex) {
        return tex.use_count() == 1 && tex->m_lastTimeUsage.ticksElapsed() > IDLE_TIME;
    });
}

void GarbageCollection::thingType() {
    static constexpr uint16_t AMOUNT_PER_CHECK = 500; // maximum number of objects to be checked.

    static uint8_t category{ 0 };

    static size_t thingId = 0;
    static size_t resourceId = 0;
    size_t scanned = 0;

    while (scanned < AMOUNT_PER_CHECK) {
        // no more resources to scan
        // wrap around and finish
        if (resourceId >= g_things.getResourcesCount()) {
            resourceId = 0;
            category = ThingCategoryItem;
            thingId = 0;
            break;
        }

        // get resource by id
        auto res = g_things.getResourceById(resourceId);
        if (!res) {
            // no resource found
            // move to the next resource
            ++resourceId;
            category = ThingCategoryItem;
            thingId = 0;
            continue;
        }

        // this is unlikely to happen
        // but it stops sonar from flagging this function as a "blocker"
        if (category >= res->m_thingTypes->size()) {
            throw std::out_of_range("GarbageCollection: resource category is out of range");
            break;
        }

        auto& things = res->m_thingTypes[category];
        if (things.empty()) {
            ++category;
            thingId = 0;
            if (category == ThingLastCategory) {
                category = ThingCategoryItem;
                ++resourceId;
            }
            continue;
        }

        processThingsInCategory(things, thingId, scanned, AMOUNT_PER_CHECK);

        if (thingId == things.size() - 1) {
            thingId = 0;
            ++category;
            if (category == ThingLastCategory) {
                category = ThingCategoryItem;
                ++resourceId;
            }
        }
    }
}

void GarbageCollection::processThingsInCategory(ThingTypeList& things, size_t& thingId, size_t& scanned, size_t maxAmount) {
    static constexpr uint16_t IDLE_TIME = 60 * 1000; // Maximum time it can be idle, default 60 seconds.

    const size_t limit = std::min(thingId + (maxAmount - scanned), things.size() - 1);
    for (; thingId < limit; ++thingId, ++scanned) {
        const auto& thing = things[thingId];
        if (!thing) continue;

        if (thing->hasTexture() && thing->getLastTimeUsage().ticksElapsed() > IDLE_TIME)
            thing->unload();
    }
}

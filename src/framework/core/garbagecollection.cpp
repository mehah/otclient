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

#include "garbagecollection.h"
#include <client/thingtypemanager.h>
#include <framework/luaengine/luainterface.h>
#include <framework/graphics/texturemanager.h>
#include <framework/graphics/animatedtexture.h>
#include <framework/graphics/drawpoolmanager.h>
#include <framework/core/asyncdispatcher.h>
#include <framework/core/eventdispatcher.h>

constexpr uint32_t LUA_TIME = 15 * 60 * 1000; // 15min
constexpr uint32_t TEXTURE_TIME = 30 * 60 * 1000; // 30min
constexpr uint32_t DRAWPOOL_TIME = 30 * 60 * 1000; // 30min
constexpr uint32_t THINGTYPE_TIME = 2 * 1000; // 2seg

Timer lua_timer, texture_timer, drawpool_timer, thingtype_timer;

void GarbageCollection::poll() {
    if (canCheck(lua_timer, LUA_TIME))
        g_lua.collectGarbage();

    if (canCheck(thingtype_timer, THINGTYPE_TIME))
        g_asyncDispatcher.detach_task([] { thingType(); });

    if (canCheck(texture_timer, TEXTURE_TIME))
        g_asyncDispatcher.detach_task([] { texture(); });

    if (canCheck(drawpool_timer, DRAWPOOL_TIME))
        g_mainDispatcher.addEvent([] { drawpoll(); });
}

void GarbageCollection::drawpoll() {
    for (int8_t i = -1; ++i < static_cast<uint8_t>(DrawPoolType::LAST);) {
        g_drawPool.get(static_cast<DrawPoolType>(i))->resetBuffer();
    }
}

void GarbageCollection::texture() {
    static constexpr uint32_t IDLE_TIME = 25 * 60 * 1000; // 25min

    std::vector<std::string> textureRemove;
    std::vector<AnimatedTexturePtr> animatedTextureRemove;

    {
        std::shared_lock l(g_textures.m_mutex);
        for (const auto& [fileName, tex] : g_textures.m_textures) {
            if (tex->m_lastTimeUsage.ticksElapsed() > IDLE_TIME) {
                textureRemove.emplace_back(fileName);
            }
        }

        for (const auto& tex : g_textures.m_animatedTextures) {
            if (tex->m_lastTimeUsage.ticksElapsed() > IDLE_TIME) {
                animatedTextureRemove.emplace_back(tex);
            }
        }
    }

    if (!textureRemove.empty() || !animatedTextureRemove.empty()) {
        std::unique_lock l(g_textures.m_mutex);
        for (const auto& path : textureRemove)
            g_textures.m_textures.erase(path);

        for (const auto& text : animatedTextureRemove)
            std::erase(g_textures.m_animatedTextures, text);
    }
}

void GarbageCollection::thingType() {
    static constexpr uint16_t
        IDLE_TIME = 60 * 1000, // Maximum time it can be idle, default 60 seconds.
        AMOUNT_PER_CHECK = 500; // maximum number of objects to be checked.

    static uint8_t category{ ThingLastCategory };
    static size_t index = 0;

    if (category == ThingLastCategory)
        category = ThingCategoryItem;

    const auto& thingTypes = g_things.m_thingTypes[category];
    const size_t limit = std::min<size_t>(index + AMOUNT_PER_CHECK, thingTypes.size());

    std::vector<ThingTypePtr> thingsUnload;

    while (index < limit) {
        auto& thing = thingTypes[index];
        if (thing->hasTexture() && thing->getLastTimeUsage().ticksElapsed() > IDLE_TIME) {
            thingsUnload.emplace_back(thing);
        }
        ++index;
    }

    if (limit == thingTypes.size()) {
        index = 0;
        ++category;
    }

    if (!thingsUnload.empty()) {
        g_dispatcher.addEvent([thingsUnload = std::move(thingsUnload)] {
            for (auto& thingType : thingsUnload)
                thingType->unload();
        });
    }
}
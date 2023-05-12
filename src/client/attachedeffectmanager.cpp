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

#include "attachedeffectmanager.h"
#include "attachedeffect.h"
#include "thingtypemanager.h"
#include "spritemanager.h"
#include <framework/graphics/texturemanager.h>
#include <framework/graphics/animatedtexture.h>

AttachedEffectManager g_attachedEffects;

AttachedEffectPtr AttachedEffectManager::getById(uint16_t id) {
    const auto it = m_effects.find(id);
    if (it == m_effects.end()) {
        g_logger.error(stdext::format("AttachedEffectManager::getById(%d): not found.", id));
        return nullptr;
    }

    const auto& obj = (*it).second;
    if (obj->m_thingId > 0 && obj->m_thingType == nullptr) {
        if (!g_things.isValidDatId(obj->m_thingId, obj->m_thingCategory)) {
            g_logger.error(stdext::format("AttachedEffectManager::getById(%d): invalid thing with id %d.", id, obj->m_thingId));
            return nullptr;
        }

        obj->m_thingType = g_things.getThingType(obj->m_thingId, obj->m_thingCategory).get();
    }

    return obj;
}

AttachedEffectPtr AttachedEffectManager::registerByThing(uint16_t id, const std::string_view name, uint16_t thingId, ThingCategory category) {
    const auto it = m_effects.find(id);
    if (it != m_effects.end()) {
        g_logger.error(stdext::format("AttachedEffectManager::registerByThing(%d, %s): has already been registered.", id, name));
        return nullptr;
    }

    const auto& obj = std::make_shared<AttachedEffect>();
    obj->m_id = id;
    obj->m_thingId = thingId;
    obj->m_thingCategory = category;

    obj->m_name = { name.data() };

    m_effects.emplace(id, obj);
    return obj;
}

AttachedEffectPtr AttachedEffectManager::registerByImage(uint16_t id, const std::string_view name, const std::string_view path, bool smooth) {
    const auto it = m_effects.find(id);
    if (it != m_effects.end()) {
        g_logger.error(stdext::format("AttachedEffectManager::registerByImage(%d, %s): has already been registered.", id, name));
        return nullptr;
    }

    const auto& texture = g_textures.getTexture(path.data(), smooth);
    if (!texture)
        return nullptr;

    if (!texture->isAnimatedTexture()) {
        g_logger.error(stdext::format("AttachedEffectManager::registerByImage(%d, %s): only animated texture is allowed.", id, name));
        return nullptr;
    }

    const auto& animatedTexture = std::static_pointer_cast<AnimatedTexture>(texture);
    animatedTexture->setOnMap(true);
    animatedTexture->restart();

    const auto& obj = std::make_shared<AttachedEffect>();
    obj->m_id = id;
    obj->m_texture = animatedTexture;
    obj->m_name = { name.data() };

    m_effects.emplace(id, obj);
    return obj;
}
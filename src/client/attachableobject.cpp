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

#include "attachableobject.h"

#include <framework/core/eventdispatcher.h>

void AttachableObject::attachEffect(const AttachedEffectPtr& obj) {
    if (!obj)
        return;

    onStartAttachEffect(obj);

    if (obj->isHidedOwner())
        ++m_ownerHidden;

    if (obj->getDuration() > 0) {
        g_dispatcher.scheduleEvent([self = std::static_pointer_cast<AttachableObject>(shared_from_this()), effectId = obj->getId()]() {
            self->detachEffectById(effectId);
        }, obj->getDuration());
    }

    m_attachedEffects.emplace_back(obj);
    g_dispatcher.addEvent([effect = obj, self = std::static_pointer_cast<AttachableObject>(shared_from_this())] {
        self->onDispatcherAttachEffect(effect);
        effect->callLuaField("onAttach", self->attachedObjectToLuaObject());
    });
}

bool AttachableObject::detachEffectById(uint16_t id) {
    const auto it = std::find_if(m_attachedEffects.begin(), m_attachedEffects.end(),
                                 [id](const AttachedEffectPtr& obj) { return obj->getId() == id; });

    if (it == m_attachedEffects.end())
        return false;

    onDetachEffect(*it);
    m_attachedEffects.erase(it);

    return true;
}

void AttachableObject::onDetachEffect(const AttachedEffectPtr& effect) {
    if (effect->isHidedOwner())
        --m_ownerHidden;

    onStartDetachEffect(effect);

    effect->callLuaField("onDetach", attachedObjectToLuaObject());
}

void AttachableObject::clearAttachedEffects() {
    for (const auto& e : m_attachedEffects)
        onDetachEffect(e);
    m_attachedEffects.clear();
}

AttachedEffectPtr AttachableObject::getAttachedEffectById(uint16_t id) {
    const auto it = std::find_if(m_attachedEffects.begin(), m_attachedEffects.end(),
                                 [id](const AttachedEffectPtr& obj) { return obj->getId() == id; });

    if (it == m_attachedEffects.end())
        return nullptr;

    return *it;
}

void AttachableObject::drawAttachedEffect(const Point& dest, LightView* lightView, bool isOnTop)
{
    for (const auto& effect : m_attachedEffects) {
        effect->draw(dest, isOnTop, lightView);
        if (effect->getLoop() == 0) {
            g_dispatcher.addEvent([self = std::static_pointer_cast<AttachableObject>(shared_from_this()), effectId = effect->getId()]() {
                self->detachEffectById(effectId);
            });
        }
    }
}

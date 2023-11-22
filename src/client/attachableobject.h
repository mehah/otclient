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

#pragma once
#include "attachedeffect.h"
#include <framework/luaengine/luaobject.h>

class AttachableObject : public LuaObject
{
public:
    AttachableObject() = default;
    virtual ~AttachableObject() = default;
    
    void attachEffect(const AttachedEffectPtr& obj);
    void clearAttachedEffects();
    bool detachEffectById(uint16_t id);
    AttachedEffectPtr getAttachedEffectById(uint16_t id);

    virtual LuaObjectPtr attachedObjectToLuaObject() = 0;
    virtual void onStartAttachEffect(const AttachedEffectPtr& effect) { };
    virtual void onDispatcherAttachEffect(const AttachedEffectPtr& effect) { };
    virtual void onStartDetachEffect(const AttachedEffectPtr& effect) { };

    bool isOwnerHidden() { return m_ownerHidden > 0; }

    const std::vector<AttachedEffectPtr>& getAttachedEffects() { return m_attachedEffects; };

    void attachParticleEffect(const std::string& name);
    void clearAttachedParticlesEffect();
    bool detachParticleEffectByName(const std::string& name);

protected:
    void drawAttachedEffect(const Point& dest, LightView* lightView, bool isOnTop);
    void onDetachEffect(const AttachedEffectPtr& effect);
    void drawAttachedParticlesEffect(const Point& dest);

    std::vector<AttachedEffectPtr> m_attachedEffects;
    std::vector<ParticleEffectPtr> m_attachedParticles;
    uint8_t m_ownerHidden{ 0 };
};

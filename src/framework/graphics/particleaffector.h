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

#include "declarations.h"
#include <framework/otml/otml.h>

class ParticleAffector
{
public:
    virtual ~ParticleAffector() {} // fix clang warning

    void update(float elapsedTime);
    virtual void load(const OTMLNodePtr& node);
    virtual void updateParticle(const ParticlePtr&, float) const = 0;

    bool hasFinished() const { return m_finished; }

protected:
    bool m_finished{ false };
    bool m_active{ false };
    float m_delay{ 0 };
    float m_duration{ 0 };
    float m_elapsedTime{ 0 };
};

class GravityAffector : public ParticleAffector
{
public:
    void load(const OTMLNodePtr& node) override;
    void updateParticle(const ParticlePtr& particle, float elapsedTime) const override;

private:
    float m_angle{ 0 };
    float m_gravity{ 0 };
};

class AttractionAffector : public ParticleAffector
{
public:
    void load(const OTMLNodePtr& node) override;
    void updateParticle(const ParticlePtr& particle, float elapsedTime) const override;

private:
    Point m_position;
    float m_acceleration{ .0f };
    float m_reduction{ .0f };
    bool m_repelish{ false };
};

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

#include "particleemitter.h"
#include "particle.h"
#include "particlemanager.h"
#include "particlesystem.h"

void ParticleEmitter::load(const OTMLNodePtr& node)
{
    for (const auto& childNode : node->children()) {
        // self related
        if (childNode->tag() == "position")
            m_position = childNode->value<Point>();
        else if (childNode->tag() == "duration")
            m_duration = childNode->value<float>();
        else if (childNode->tag() == "delay")
            m_delay = childNode->value<float>();
        else if (childNode->tag() == "burst-rate")
            m_burstRate = childNode->value<float>();
        else if (childNode->tag() == "burst-count")
            m_burstCount = childNode->value<int>();
        else if (childNode->tag() == "particle-type")
            m_particleType = g_particles.getParticleType(childNode->value());
    }

    if (!m_particleType)
        throw Exception("emitter didn't provide a valid particle type");
}

void ParticleEmitter::update(float elapsedTime, const ParticleSystemPtr& system)
{
    m_elapsedTime += elapsedTime;

    // check if finished
    if (m_duration > 0 && m_elapsedTime >= m_duration + m_delay) {
        m_finished = true;
        return;
    }

    if (!m_active && m_elapsedTime > m_delay)
        m_active = true;

    if (!m_active)
        return;

    const int nextBurst = std::floor((m_elapsedTime - m_delay) * m_burstRate) + 1;
    const auto* type = m_particleType.get();
    for (int b = m_currentBurst; b < nextBurst; ++b) {
        // every burst created at same position.
        const float pRadius = stdext::random_range(type->pMinPositionRadius, type->pMaxPositionRadius);
        const float pAngle = stdext::random_range(type->pMinPositionAngle, type->pMaxPositionAngle);

        Point pPosition = m_position + Point(pRadius * std::cos(pAngle), pRadius * std::sin(pAngle));

        for (int p = 0; p < m_burstCount; ++p) {
            const float pDuration = stdext::random_range(type->pMinDuration, type->pMaxDuration);

            // particles initial velocity
            const float pVelocityAbs = stdext::random_range(type->pMinVelocity, type->pMaxVelocity);
            const float pVelocityAngle = stdext::random_range(type->pMinVelocityAngle, type->pMaxVelocityAngle);
            const PointF pVelocity(pVelocityAbs * std::cos(pVelocityAngle), pVelocityAbs * std::sin(pVelocityAngle));

            // particles initial acceleration
            const float pAccelerationAbs = stdext::random_range(type->pMinAcceleration, type->pMaxAcceleration);
            const float pAccelerationAngle = stdext::random_range(type->pMinAccelerationAngle, type->pMaxAccelerationAngle);
            const PointF pAcceleration(pAccelerationAbs * std::cos(pAccelerationAngle), pAccelerationAbs * std::sin(pAccelerationAngle));

            system->addParticle(std::make_shared<Particle>(pPosition, type->pStartSize, type->pFinalSize,
                                pVelocity, pAcceleration,
                                pDuration, type->pIgnorePhysicsAfter,
                                type->pColors, type->pColorsStops,
                                type->pCompositionMode, type->pTexture));
        }
    }

    m_currentBurst = nextBurst;
}
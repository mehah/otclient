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

#include "particlesystem.h"
#include <framework/core/clock.h>
#include <framework/core/graphicalapplication.h>
#include "particle.h"
#include "particleaffector.h"

ParticleSystem::ParticleSystem() :m_lastUpdateTime(g_clock.seconds()) {}

void ParticleSystem::load(const OTMLNodePtr& node)
{
    for (const auto& childNode : node->children()) {
        if (childNode->tag() == "Emitter") {
            const auto& emitter = std::make_shared<ParticleEmitter>();
            emitter->load(childNode);
            m_emitters.emplace_back(emitter);
        } else if (childNode->tag().find("Affector") != std::string::npos) {
            ParticleAffectorPtr affector;

            if (childNode->tag() == "GravityAffector")
                affector = std::make_shared<GravityAffector>();
            else if (childNode->tag() == "AttractionAffector")
                affector = std::make_shared<AttractionAffector>();

            if (affector) {
                affector->load(childNode);
                m_affectors.emplace_back(affector);
            }
        }
    }
}

void ParticleSystem::addParticle(const ParticlePtr& particle) { m_particles.emplace_back(particle); }

void ParticleSystem::render() const
{
    for (const auto& particle : m_particles)
        particle->render();
}

void ParticleSystem::update()
{
    static constexpr float delay = 0.0166; // 60 updates/s

    // check time
    const float elapsedTime = g_clock.seconds() - m_lastUpdateTime;
    if (elapsedTime < delay)
        return;

    // check if finished
    if (m_particles.empty() && m_emitters.empty()) {
        m_finished = true;
        return;
    }

    m_lastUpdateTime = g_clock.seconds() - std::fmod(elapsedTime, delay);

    const auto& self = shared_from_this();
    for (int i = 0; i < std::floor(elapsedTime / delay); ++i) {
        // update emitters
        for (auto it = m_emitters.begin(); it != m_emitters.end();) {
            const ParticleEmitterPtr& emitter = *it;
            if (emitter->hasFinished()) {
                it = m_emitters.erase(it);
            } else {
                emitter->update(delay, self);
                ++it;
            }
        }

        // update affectors
        for (auto it = m_affectors.begin(); it != m_affectors.end();) {
            const ParticleAffectorPtr& affector = *it;
            if (affector->hasFinished()) {
                it = m_affectors.erase(it);
            } else {
                affector->update(delay);
                ++it;
            }
        }

        // update particles
        for (auto it = m_particles.begin(); it != m_particles.end();) {
            const ParticlePtr& particle = *it;
            if (particle->hasFinished()) {
                it = m_particles.erase(it);
            } else {
                // pass particles through affectors
                for (const auto& particleAffector : m_affectors)
                    particleAffector->updateParticle(particle, delay);

                particle->update(delay);
                ++it;
            }
        }
    }

    g_app.repaint();
}
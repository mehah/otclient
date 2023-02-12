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

#include "drawpoolmanager.h"
#include "declarations.h"
#include "painter.h"
#include <framework/graphics/framebuffermanager.h>

thread_local static uint8_t CURRENT_POOL;

DrawPoolManager g_drawPool;

void DrawPoolManager::init()
{
    // Create Pools
    for (int8_t i = -1; ++i <= static_cast<uint8_t>(DrawPoolType::UNKNOW);) {
        m_pools[i] = DrawPool::create(static_cast<DrawPoolType>(i));
    }
}

void DrawPoolManager::terminate() const
{
    // Destroy Pools
    for (int_fast8_t i = -1; ++i <= static_cast<uint8_t>(DrawPoolType::UNKNOW);) {
        delete m_pools[i];
    }
}

DrawPool* DrawPoolManager::getCurrentPool() const { return m_pools[CURRENT_POOL]; }
void DrawPoolManager::select(DrawPoolType type) { CURRENT_POOL = static_cast<uint8_t>(type); }

void DrawPoolManager::draw()
{
    if (m_size != g_graphics.getViewportSize()) {
        m_size = g_graphics.getViewportSize();
        m_transformMatrix = g_painter->getTransformMatrix(m_size);
    }

    auto& mapMutex = get<DrawPool>(DrawPoolType::MAP)->getMutex();

    // Pre Draw
    for (auto* pool : m_pools) {
        if (!pool->isEnabled()) continue;

        // Light and Creature Info, are in the same thread as the MAP
        auto& mutex = pool->getType() == DrawPoolType::CREATURE_INFORMATION ||
            pool->getType() == DrawPoolType::LIGHT ? mapMutex : pool->getMutex();

        std::scoped_lock l(mutex);

        if (pool->hasFrameBuffer()) {
            const auto* pf = pool->toPoolFramed();
            if (!pf->m_framebuffer->canDraw())
                continue;

            if (pool->canRepaint(true)) {
                pf->m_framebuffer->bind();
                for (int_fast8_t z = -1; ++z <= pool->m_currentFloor;) {
                    for (const auto& order : pool->m_objects[z])
                        for (const auto& obj : order)
                            drawObject(obj);
                }

                pf->m_framebuffer->release();
            }

            g_painter->resetState();
            g_painter->setResolution(m_size, m_transformMatrix);

            if (pf->m_beforeDraw) pf->m_beforeDraw();
            pf->m_framebuffer->draw();
            if (pf->m_afterDraw) pf->m_afterDraw();
        } else for (const auto& obj : pool->m_objects[0][DrawOrder::FIRST]) {
            drawObject(obj);
        }
    }
}

void DrawPoolManager::drawObject(const DrawPool::DrawObject& obj)
{
    if (obj.action) {
        obj.action();
        return;
    }

    auto& coords = !obj.coords ? m_coordsBuffer : *obj.coords;
    if (!obj.coords) {
        coords.clear();
        for (const auto& method : obj.methods)
            DrawPool::addCoords(&coords, method, obj.drawMode);
    }

    obj.state.execute();
    g_painter->drawCoords(coords, obj.drawMode);
}

void DrawPoolManager::addTexturedCoordsBuffer(const TexturePtr& texture, const CoordsBufferPtr& coords, const Color& color) const
{
    DrawPool::DrawMethod method;
    getCurrentPool()->add(color, texture, method, DrawMode::TRIANGLE_STRIP, DEFAULT_DRAW_CONDUCTOR, coords);
}

void DrawPoolManager::addTexturedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color, const DrawConductor& condutor) const
{
    if (dest.isEmpty() || src.isEmpty())
        return;

    DrawPool::DrawMethod method{
        .type = DrawPool::DrawMethodType::RECT,
        .dest = dest, .src = src
    };

    getCurrentPool()->add(color, texture, method, DrawMode::TRIANGLE_STRIP, condutor);
}

void DrawPoolManager::addUpsideDownTexturedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color) const
{
    if (dest.isEmpty() || src.isEmpty())
        return;

    DrawPool::DrawMethod method{ DrawPool::DrawMethodType::UPSIDEDOWN_RECT, dest, src };

    getCurrentPool()->add(color, texture, method, DrawMode::TRIANGLE_STRIP);
}

void DrawPoolManager::addTexturedRepeatedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color) const
{
    if (dest.isEmpty() || src.isEmpty())
        return;

    DrawPool::DrawMethod method{ DrawPool::DrawMethodType::REPEATED_RECT, dest, src };

    getCurrentPool()->add(color, texture, method);
}

void DrawPoolManager::addFilledRect(const Rect& dest, const Color& color, const DrawConductor& condutor) const
{
    if (dest.isEmpty())
        return;

    DrawPool::DrawMethod method{ DrawPool::DrawMethodType::RECT, dest };

    getCurrentPool()->add(color, nullptr, method, DrawMode::TRIANGLES, condutor);
}

void DrawPoolManager::addFilledTriangle(const Point& a, const Point& b, const Point& c, const Color& color) const
{
    if (a == b || a == c || b == c)
        return;

    DrawPool::DrawMethod method{ .type = DrawPool::DrawMethodType::TRIANGLE, .a = a, .b = b, .c = c };

    getCurrentPool()->add(color, nullptr, method);
}

void DrawPoolManager::addBoundingRect(const Rect& dest, const Color& color, uint16_t innerLineWidth) const
{
    if (dest.isEmpty() || innerLineWidth == 0)
        return;

    DrawPool::DrawMethod method{
        .type = DrawPool::DrawMethodType::BOUNDING_RECT,
        .dest = dest,
        .intValue = innerLineWidth
    };

    getCurrentPool()->add(color, nullptr, method);
}

void DrawPoolManager::addAction(const std::function<void()>& action) const
{
    getCurrentPool()->m_objects[0][DrawOrder::FIRST].emplace_back(action);
}

void DrawPoolManager::bindFrameBuffer(const Size& size) const
{
    getCurrentPool()->m_oldState = std::move(getCurrentPool()->m_state);
    getCurrentPool()->m_state = {};

    g_drawPool.addAction([size, drawState = getCurrentPool()->m_state] {
        drawState.execute();
        const auto& frame = g_framebuffers.getTemporaryFrameBuffer();
        frame->resize(size);
        frame->bind();
    });
}
void DrawPoolManager::releaseFrameBuffer(const Rect& dest) const
{
    getCurrentPool()->m_state = std::move(getCurrentPool()->m_oldState);
    g_drawPool.addAction([dest, drawState = getCurrentPool()->m_state] {
        const auto& frame = g_framebuffers.getTemporaryFrameBuffer();
        frame->release();
        drawState.execute();
        frame->draw(dest);
    });
}

void DrawPoolManager::use(const DrawPoolType type, const Rect& dest, const Rect& src, const Color& colorClear)
{
    select(type);

    auto* currentPoll = getCurrentPool();

    currentPoll->setEnable(true);
    currentPoll->resetState();

    if (currentPoll->hasFrameBuffer()) {
        currentPoll->toPoolFramed()
            ->m_framebuffer->prepare(dest, src, colorClear);

        // when the selected pool is MAP, reset the creature information state.
        if (type == DrawPoolType::MAP) {
            get<DrawPool>(DrawPoolType::CREATURE_INFORMATION)->resetState();
        }
    }
}

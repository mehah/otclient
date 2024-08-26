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
#include "drawpool.h"
#include "declarations.h"

thread_local static uint8_t CURRENT_POOL = static_cast<uint8_t>(DrawPoolType::LAST);

void resetSelectedPool() {
    CURRENT_POOL = static_cast<uint8_t>(DrawPoolType::LAST);
}

DrawPoolManager g_drawPool;

void DrawPoolManager::init(uint16_t spriteSize)
{
    if (spriteSize != 0)
        m_spriteSize = spriteSize;

    // Create Pools
    for (int8_t i = -1; ++i < static_cast<uint8_t>(DrawPoolType::LAST);) {
        m_pools[i] = DrawPool::create(static_cast<DrawPoolType>(i));
    }
}

void DrawPoolManager::terminate() const
{
    // Destroy Pools
    for (int_fast8_t i = -1; ++i < static_cast<uint8_t>(DrawPoolType::LAST);) {
        delete m_pools[i];
    }
}

DrawPool* DrawPoolManager::getCurrentPool() const { return m_pools[CURRENT_POOL]; }
void DrawPoolManager::select(DrawPoolType type) { CURRENT_POOL = static_cast<uint8_t>(type); }
bool DrawPoolManager::isPreDrawing() const { return CURRENT_POOL != static_cast<uint8_t>(DrawPoolType::LAST); }

void DrawPoolManager::draw()
{
    if (m_size != g_graphics.getViewportSize()) {
        m_size = g_graphics.getViewportSize();
        m_transformMatrix = g_painter->getTransformMatrix(m_size);
        g_painter->setResolution(m_size, m_transformMatrix);
    }

    for (int8_t i = -1; ++i < static_cast<uint8_t>(DrawPoolType::LAST);) {
        drawPool(static_cast<DrawPoolType>(i));
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

void DrawPoolManager::addTexturedCoordsBuffer(const TexturePtr& texture, const CoordsBufferPtr& coords, const Color& color, const DrawConductor& condutor) const
{
    getCurrentPool()->add(color, texture, DrawPool::DrawMethod{}, DrawMode::TRIANGLE_STRIP, condutor, coords);
}

void DrawPoolManager::addTexturedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color, const DrawConductor& condutor) const
{
    if (dest.isEmpty() || src.isEmpty()) {
        getCurrentPool()->resetOnlyOnceParameters();
        return;
    }

    getCurrentPool()->add(color, texture, DrawPool::DrawMethod{
        .type = DrawPool::DrawMethodType::RECT,
        .dest = dest, .src = src
    }, DrawMode::TRIANGLE_STRIP, condutor);
}

void DrawPoolManager::addUpsideDownTexturedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color, const DrawConductor& condutor) const
{
    if (dest.isEmpty() || src.isEmpty()) {
        getCurrentPool()->resetOnlyOnceParameters();
        return;
    }

    getCurrentPool()->add(color, texture, DrawPool::DrawMethod{ DrawPool::DrawMethodType::UPSIDEDOWN_RECT, dest, src }, DrawMode::TRIANGLE_STRIP, condutor);
}

void DrawPoolManager::addTexturedRepeatedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color, const DrawConductor& condutor) const
{
    if (dest.isEmpty() || src.isEmpty()) {
        getCurrentPool()->resetOnlyOnceParameters();
        return;
    }

    getCurrentPool()->add(color, texture, DrawPool::DrawMethod{ DrawPool::DrawMethodType::REPEATED_RECT, dest, src }, DrawMode::TRIANGLES, condutor);
}

void DrawPoolManager::addFilledRect(const Rect& dest, const Color& color, const DrawConductor& condutor) const
{
    if (dest.isEmpty()) {
        getCurrentPool()->resetOnlyOnceParameters();
        return;
    }

    getCurrentPool()->add(color, nullptr, DrawPool::DrawMethod{ DrawPool::DrawMethodType::RECT, dest }, DrawMode::TRIANGLES, condutor);
}

void DrawPoolManager::addFilledTriangle(const Point& a, const Point& b, const Point& c, const Color& color, const DrawConductor& condutor) const
{
    if (a == b || a == c || b == c) {
        getCurrentPool()->resetOnlyOnceParameters();
        return;
    }

    getCurrentPool()->add(color, nullptr, DrawPool::DrawMethod{
            .type = DrawPool::DrawMethodType::TRIANGLE,
            .a = a,
            .b = b,
            .c = c
     }, DrawMode::TRIANGLES, condutor);
}

void DrawPoolManager::addBoundingRect(const Rect& dest, const Color& color, uint16_t innerLineWidth, const DrawConductor& condutor) const
{
    if (dest.isEmpty() || innerLineWidth == 0) {
        getCurrentPool()->resetOnlyOnceParameters();
        return;
    }

    getCurrentPool()->add(color, nullptr, DrawPool::DrawMethod{
        .type = DrawPool::DrawMethodType::BOUNDING_RECT,
        .dest = dest,
        .intValue = innerLineWidth
    }, DrawMode::TRIANGLES, condutor);
}

void DrawPoolManager::preDraw(const DrawPoolType type, const std::function<void()>& f, const Rect& dest, const Rect& src, const Color& colorClear, const bool alwaysDraw)
{
    select(type);
    const auto pool = getCurrentPool();

    if (pool->m_repaint.load()) {
        resetSelectedPool();
        return;
    }

    pool->resetState();

    if (f) f();

    std::scoped_lock l(pool->m_mutexDraw);

    if (pool->hasFrameBuffer())
        pool->m_framebuffer->prepare(dest, src, colorClear);

    pool->release(pool->m_repaint = alwaysDraw || pool->canRepaint());

    if (pool->m_repaint) {
        pool->m_refreshTimer.restart();
    }

    resetSelectedPool();
}

void DrawPoolManager::drawPool(const DrawPoolType type) {
    const auto pool = get(type);

    if (!pool->isEnabled())
        return;

    std::scoped_lock l(pool->m_mutexDraw);
    if (pool->hasFrameBuffer()) {
        if (pool->m_repaint) {
            pool->m_repaint.store(false);
            pool->m_framebuffer->bind();
            for (const auto& obj : pool->m_objectsDraw)
                drawObject(obj);
            pool->m_framebuffer->release();
        }

        // Let's clean this up so that the cleaning is not done in another thread,
        // and thus the CPU consumption will be partitioned.
        pool->m_objectsDraw.clear();

        g_painter->resetState();

        if (pool->m_beforeDraw) pool->m_beforeDraw();
        pool->m_framebuffer->draw();
        if (pool->m_afterDraw) pool->m_afterDraw();
    } else {
        pool->m_repaint.store(false);
        for (const auto& obj : pool->m_objectsDraw) {
            drawObject(obj);
        }
    }
}
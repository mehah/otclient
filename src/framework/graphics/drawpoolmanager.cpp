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

#include "drawpoolmanager.h"
#include "declarations.h"
#include "drawpool.h"
#include "graphics.h"
#include "textureatlas.h"

thread_local static uint8_t CURRENT_POOL = static_cast<uint8_t>(DrawPoolType::LAST);

void resetSelectedPool() {
    CURRENT_POOL = static_cast<uint8_t>(DrawPoolType::LAST);
}

DrawPoolManager g_drawPool;

void DrawPoolManager::init(const uint16_t spriteSize)
{
    if (spriteSize != 0)
        m_spriteSize = spriteSize;

    auto atlasMap = std::make_shared<TextureAtlas>(Fw::TextureAtlasType::MAP);
    auto atlasForeground = std::make_shared<TextureAtlas>(Fw::TextureAtlasType::FOREGROUND, 4096, 4096);

    // Create Pools
    for (int8_t i = -1; ++i < static_cast<uint8_t>(DrawPoolType::LAST);) {
        auto pool = m_pools[i] = DrawPool::create(static_cast<DrawPoolType>(i));

        switch (static_cast<DrawPoolType>(i)) {
            case DrawPoolType::MAP:
                pool->m_atlas = atlasMap;
                break;

            case DrawPoolType::FOREGROUND:
            case DrawPoolType::FOREGROUND_MAP:
            case DrawPoolType::CREATURE_INFORMATION:
                pool->m_atlas = atlasForeground;
                break;
        }
    }
}

void DrawPoolManager::terminate() const
{
    // Destroy Pools
    for (int_fast8_t i = -1; ++i < static_cast<uint8_t>(DrawPoolType::LAST);) {
        delete m_pools[i];
    }
}

DrawPoolType DrawPoolManager::getCurrentType() const { return static_cast<DrawPoolType>(CURRENT_POOL); }
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

void DrawPoolManager::drawObject(DrawPool* pool, const DrawPool::DrawObject& obj)
{
    if (obj.action) {
        obj.action();
    } else {
        obj.state.execute(pool);
        g_painter->drawCoords(*obj.coords, DrawMode::TRIANGLES);
    }
}

void DrawPoolManager::addTexturedCoordsBuffer(const TexturePtr& texture, const CoordsBufferPtr& coords, const Color& color, const DrawConductor& condutor) const
{
    getCurrentPool()->add(color, texture, DrawPool::DrawMethod{}, condutor, coords);
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
    }, condutor);
}

void DrawPoolManager::addUpsideDownTexturedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color, const DrawConductor& condutor) const
{
    if (dest.isEmpty() || src.isEmpty()) {
        getCurrentPool()->resetOnlyOnceParameters();
        return;
    }

    getCurrentPool()->add(color, texture, DrawPool::DrawMethod{ .type = DrawPool::DrawMethodType::UPSIDEDOWN_RECT, .dest =
                              dest,
                              .src = src
                          }, condutor);
}

void DrawPoolManager::addTexturedRepeatedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color, const DrawConductor& condutor) const
{
    if (dest.isEmpty() || src.isEmpty()) {
        getCurrentPool()->resetOnlyOnceParameters();
        return;
    }

    getCurrentPool()->add(color, texture, DrawPool::DrawMethod{ .type = DrawPool::DrawMethodType::REPEATED_RECT, .dest =
                              dest,
                              .src = src
                          }, condutor);
}

void DrawPoolManager::addFilledRect(const Rect& dest, const Color& color, const DrawConductor& condutor) const
{
    if (dest.isEmpty()) {
        getCurrentPool()->resetOnlyOnceParameters();
        return;
    }

    getCurrentPool()->add(color, nullptr, DrawPool::DrawMethod{ .type = DrawPool::DrawMethodType::RECT, .dest = dest }, condutor);
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
     }, condutor);
}

void DrawPoolManager::addBoundingRect(const Rect& dest, const Color& color, const uint16_t innerLineWidth, const DrawConductor& condutor) const
{
    if (dest.isEmpty() || innerLineWidth == 0) {
        getCurrentPool()->resetOnlyOnceParameters();
        return;
    }

    getCurrentPool()->add(color, nullptr, DrawPool::DrawMethod{
        .type = DrawPool::DrawMethodType::BOUNDING_RECT,
        .dest = dest,
        .intValue = innerLineWidth
    }, condutor);
}

void DrawPoolManager::preDraw(const DrawPoolType type, const std::function<void()>& f, const std::function<void()>& beforeRelease, const Rect& dest, const Rect& src, const Color& colorClear, const bool alwaysDraw)
{
    select(type);
    const auto pool = getCurrentPool();

    if (pool->isDrawState(DrawPoolState::READY) || pool->isDrawState(DrawPoolState::DRAWING)) {
        resetSelectedPool();
        return;
    }

    pool->resetState();

    if (f) f();

    if (beforeRelease)
        beforeRelease();

    if (alwaysDraw)
        pool->repaint();

    if (pool->hasFrameBuffer()) {
        addAction([pool, dest, src, colorClear] {
            pool->m_framebuffer->prepare(dest, src, colorClear);
        });
    }

    pool->release();

    resetSelectedPool();
}

void DrawPoolManager::drawObjects(DrawPool* pool) {
    const auto hasFramebuffer = pool->hasFrameBuffer();

    if (!pool->isDrawState(DrawPoolState::READY) && hasFramebuffer)
        return;

    pool->waitWhileStateIs(DrawPoolState::PREPARING);
    pool->setDrawState(DrawPoolState::DRAWING);

    if (hasFramebuffer)
        pool->m_framebuffer->bind();

    for (const auto& obj : pool->m_objectsDraw) {
        drawObject(pool, obj);
    }

    if (hasFramebuffer) {
        pool->m_framebuffer->release();

        // Let's clean this up so that the cleaning is not done in another thread,
        // and thus the CPU consumption will be partitioned.
        pool->m_objectsDraw.clear();
    }

    if (pool->m_atlas)
        pool->m_atlas->flush();

    pool->setDrawState(DrawPoolState::RENDERED);
}

void DrawPoolManager::drawPool(const DrawPoolType type) {
    const auto pool = get(type);

    if (!pool->isEnabled())
        return;

    drawObjects(pool);

    if (pool->hasFrameBuffer()) {
        g_painter->resetState();

        if (pool->m_beforeDraw) pool->m_beforeDraw();
        pool->m_framebuffer->draw();
        if (pool->m_afterDraw) pool->m_afterDraw();
    }
}

void DrawPoolManager::removeTextureFromAtlas(uint32_t id) {
    for (auto pool : m_pools) {
        if (pool->m_atlas)
            pool->m_atlas->removeTexture(id);
    }
}
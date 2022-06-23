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

#include "drawpool.h"
#include "declarations.h"
#include "painter.h"
#include <utility>

DrawPool g_drawPool;

void DrawPool::init()
{
    // Create Pools
    for (int8_t i = -1; ++i <= static_cast<uint8_t>(PoolType::UNKNOW);) {
        m_pools[i] = Pool::create(static_cast<PoolType>(i));
    }
}

void DrawPool::terminate()
{
    // Destroy Pools
    m_currentPool = nullptr;
    for (int_fast8_t i = -1; ++i <= static_cast<uint8_t>(PoolType::UNKNOW);) {
        delete m_pools[i];
    }
}

void DrawPool::draw()
{
    if (m_size != g_painter->getResolution()) {
        m_size = g_painter->getResolution();
        m_transformMatrix = g_painter->getTransformMatrix(m_size);
    }

    // Pre Draw
    for (const auto& pool : m_pools) {
        if (!pool->isEnabled() || !pool->hasFrameBuffer()) continue;

        const auto& pf = pool->toPoolFramed();
        if (pool->hasModification(true) && !pool->m_objects.empty()) {
            pf->m_framebuffer->bind();
            for (auto& obj : pool->m_objects)
                drawObject(obj);
            pf->m_framebuffer->release();
        }
    }

    g_painter->setResolution(m_size, m_transformMatrix);

    // Draw
    for (const auto& pool : m_pools) {
        if (!pool->isEnabled()) continue;

        if (pool->hasFrameBuffer()) {
            const auto* const pf = pool->toPoolFramed();

            if (pf->m_beforeDraw) pf->m_beforeDraw();
            pf->m_framebuffer->draw();
            if (pf->m_afterDraw) pf->m_afterDraw();
        } else for (auto& obj : pool->m_objects) {
            drawObject(obj);
        }

        pool->m_objects.clear();
    }
}

void DrawPool::drawObject(const Pool::DrawObject& obj)
{
    if (obj.action) {
        obj.action();
        return;
    }

    const bool useGlobalCoord = !obj.buffer;
    auto& buffer = useGlobalCoord ? m_coordsBuffer : *obj.buffer->m_coords;

    if (useGlobalCoord) {
        if (obj.drawMethods->empty()) return;
        for (const auto& method : *obj.drawMethods) {
            m_currentPool->addCoords(method, buffer, obj.drawMode);
        }
    }

    { // Set DrawState
        const auto& state = obj.state;

        if (state->texture) {
            state->texture->create();
            g_painter->setTexture(state->texture.get());
        }

        g_painter->setColor(state->color);
        g_painter->setOpacity(state->opacity);
        g_painter->setCompositionMode(state->compositionMode);
        g_painter->setBlendEquation(state->blendEquation);
        g_painter->setClipRect(state->clipRect);
        g_painter->setShaderProgram(state->shaderProgram);
        g_painter->setTransformMatrix(state->transformMatrix);
        if (state->action) state->action();
    }

    g_painter->drawCoords(buffer, obj.drawMode);

    if (useGlobalCoord)
        m_coordsBuffer.clear();
}

void DrawPool::addTexturedCoordsBuffer(const TexturePtr& texture, const CoordsBufferPtr& coords, const Color& color)
{
    m_currentPool->add(color, texture, {}, DrawMode::TRIANGLE_STRIP, nullptr, coords);
}

void DrawPool::addTexturedRect(const Rect& dest, const TexturePtr& texture, const Color& color)
{
    addTexturedRect(dest, texture, Rect(Point(), texture->getSize()), color);
}

void DrawPool::addTexturedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color, const Point& originalDest, DrawBufferPtr buffer)
{
    if (dest.isEmpty() || src.isEmpty())
        return;

    const Pool::DrawMethod method{
        .type = Pool::DrawMethodType::RECT,
        .rects = std::make_pair(dest, src),
        .dest = originalDest.isNull() ? std::optional<Point>{} : originalDest
    };

    m_currentPool->add(color, texture, method, DrawMode::TRIANGLE_STRIP, buffer);
}

void DrawPool::addUpsideDownTexturedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color)
{
    if (dest.isEmpty() || src.isEmpty())
        return;

    const Pool::DrawMethod method{ Pool::DrawMethodType::UPSIDEDOWN_RECT, std::make_pair(dest, src) };

    m_currentPool->add(color, texture, method, DrawMode::TRIANGLE_STRIP);
}

void DrawPool::addTexturedRepeatedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color)
{
    if (dest.isEmpty() || src.isEmpty())
        return;

    const Pool::DrawMethod method{ Pool::DrawMethodType::REPEATED_RECT, std::make_pair(dest, src) };

    m_currentPool->add(color, texture, method);
}

void DrawPool::addFilledRect(const Rect& dest, const Color& color)
{
    if (dest.isEmpty())
        return;

    const Pool::DrawMethod method{ Pool::DrawMethodType::RECT, std::make_pair(dest, Rect()) };

    m_currentPool->add(color, nullptr, method);
}

void DrawPool::addFilledTriangle(const Point& a, const Point& b, const Point& c, const Color& color)
{
    if (a == b || a == c || b == c)
        return;

    const Pool::DrawMethod method{ .type = Pool::DrawMethodType::TRIANGLE, .points = std::make_tuple(a, b, c) };

    m_currentPool->add(color, nullptr, method);
}

void DrawPool::addBoundingRect(const Rect& dest, const Color& color, int innerLineWidth)
{
    if (dest.isEmpty() || innerLineWidth == 0)
        return;

    const Pool::DrawMethod method{
        .type = Pool::DrawMethodType::BOUNDING_RECT,
        .rects = std::make_pair(dest, Rect()),
        .intValue = static_cast<uint16_t>(innerLineWidth)
    };

    m_currentPool->add(color, nullptr, method);
}

void DrawPool::addAction(std::function<void()> action)
{
    m_currentPool->m_objects.emplace_back(action);
}

void DrawPool::use(const PoolType type) { use(type, {}, {}); }
void DrawPool::use(const PoolType type, const Rect& dest, const Rect& src, const Color& colorClear)
{
    m_currentPool = get<Pool>(type);
    m_currentPool->resetState();

    if (m_currentPool->hasFrameBuffer()) {
        m_currentPool->toPoolFramed()
            ->m_framebuffer->prepare(dest, src, colorClear);
    }
}

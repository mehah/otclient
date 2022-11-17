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
#include <utility>

DrawPoolManager g_drawPool;

void DrawPoolManager::init()
{
    // Create Pools
    for (int8_t i = -1; ++i <= static_cast<uint8_t>(DrawPoolType::UNKNOW);) {
        m_pools[i] = DrawPool::create(static_cast<DrawPoolType>(i));
    }
}

void DrawPoolManager::terminate()
{
    // Destroy Pools
    m_currentPool = nullptr;
    for (int_fast8_t i = -1; ++i <= static_cast<uint8_t>(DrawPoolType::UNKNOW);) {
        delete m_pools[i];
    }
}

void DrawPoolManager::draw()
{
    if (m_size != g_painter->getResolution()) {
        m_size = g_painter->getResolution();
        m_transformMatrix = g_painter->getTransformMatrix(m_size);
    }

    // Pre Draw
    for (const auto& pool : m_pools) {
        if (!pool->isEnabled() || !pool->hasFrameBuffer()) continue;

        const auto& pf = pool->toPoolFramed();

        if (pool->canRepaint(true)) {
            pf->m_framebuffer->bind();
            for (int_fast8_t z = -1; ++z <= pool->m_currentFloor;) {
                for (const auto& order : pool->m_objects[z])
                    for (const auto& obj : order)
                        drawObject(obj);
            }

            pf->m_framebuffer->release();
        }
    }

    g_app.updateCPUInterval();

    g_painter->setResolution(m_size, m_transformMatrix);

    // Draw
    for (const auto& pool : m_pools) {
        if (!pool->isEnabled()) continue;

        if (pool->hasFrameBuffer()) {
            // Reset before events as there may be paint controls such as shaders.
            g_painter->resetState();

            const auto* const pf = pool->toPoolFramed();
            {
                if (pf->m_beforeDraw) pf->m_beforeDraw();
                pf->m_framebuffer->draw();
                if (pf->m_afterDraw) pf->m_afterDraw();
            }
        } else for (const auto& obj : pool->m_objects[0][static_cast<int>(DrawPool::DrawOrder::FIRST)]) {
            drawObject(obj);
        }

        pool->clear();
    }
}

void DrawPoolManager::drawObject(const DrawPool::DrawObject& obj)
{
    if (obj.action) {
        obj.action();
        return;
    }

    const bool useGlobalCoord = !obj.buffer;
    auto& buffer = useGlobalCoord ? m_coordsBuffer : *obj.buffer->m_coords;

    if (useGlobalCoord) {
        m_coordsBuffer.clear();

        if (!obj.methods.has_value()) {
            m_currentPool->addCoords(*obj.method, buffer, obj.drawMode);
        } else for (const auto& method : *obj.methods) {
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
}

void DrawPoolManager::addTexturedCoordsBuffer(const TexturePtr& texture, const CoordsBufferPtr& coords, const Color& color)
{
    m_currentPool->add(color, texture, {}, DrawMode::TRIANGLE_STRIP, nullptr, coords);
}

void DrawPoolManager::addTexturedRect(const Rect& dest, const TexturePtr& texture, const Color& color)
{
    addTexturedRect(dest, texture, Rect(Point(), texture->getSize()), color);
}

void DrawPoolManager::addTexturedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color, const Point& originalDest, const DrawBufferPtr& buffer)
{
    if (dest.isEmpty() || src.isEmpty())
        return;

    const DrawPool::DrawMethod method{
        .type = DrawPool::DrawMethodType::RECT,
        .rects = std::make_pair(dest, src),
        .dest = originalDest.isNull() ? std::optional<Point>{} : originalDest
    };

    if (buffer)
        buffer->validate(originalDest);

    m_currentPool->add(color, texture, method, DrawMode::TRIANGLE_STRIP, buffer);
}

void DrawPoolManager::addUpsideDownTexturedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color)
{
    if (dest.isEmpty() || src.isEmpty())
        return;

    const DrawPool::DrawMethod method{ DrawPool::DrawMethodType::UPSIDEDOWN_RECT, std::make_pair(dest, src) };

    m_currentPool->add(color, texture, method, DrawMode::TRIANGLE_STRIP);
}

void DrawPoolManager::addTexturedRepeatedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color)
{
    if (dest.isEmpty() || src.isEmpty())
        return;

    const DrawPool::DrawMethod method{ DrawPool::DrawMethodType::REPEATED_RECT, std::make_pair(dest, src) };

    m_currentPool->add(color, texture, method);
}

void DrawPoolManager::addFilledRect(const Rect& dest, const Color& color, const DrawBufferPtr& buffer)
{
    if (dest.isEmpty())
        return;

    const DrawPool::DrawMethod method{ DrawPool::DrawMethodType::RECT, std::make_pair(dest, Rect()) };

    m_currentPool->add(color, nullptr, method, DrawMode::TRIANGLES, buffer);
}

void DrawPoolManager::addFilledTriangle(const Point& a, const Point& b, const Point& c, const Color& color)
{
    if (a == b || a == c || b == c)
        return;

    const DrawPool::DrawMethod method{ .type = DrawPool::DrawMethodType::TRIANGLE, .points = std::make_tuple(a, b, c) };

    m_currentPool->add(color, nullptr, method);
}

void DrawPoolManager::addBoundingRect(const Rect& dest, const Color& color, int innerLineWidth)
{
    if (dest.isEmpty() || innerLineWidth == 0)
        return;

    const DrawPool::DrawMethod method{
        .type = DrawPool::DrawMethodType::BOUNDING_RECT,
        .rects = std::make_pair(dest, Rect()),
        .intValue = static_cast<uint16_t>(innerLineWidth)
    };

    m_currentPool->add(color, nullptr, method);
}

void DrawPoolManager::addAction(std::function<void()> action)
{
    m_currentPool->m_objects[0][static_cast<uint8_t>(DrawPool::DrawOrder::FIRST)].emplace_back(action);
}

void DrawPoolManager::use(const DrawPoolType type) { use(type, {}, {}); }
void DrawPoolManager::use(const DrawPoolType type, const Rect& dest, const Rect& src, const Color& colorClear)
{
    m_currentPool = get<DrawPool>(type);
    m_currentPool->resetState();

    if (m_currentPool->hasFrameBuffer()) {
        m_currentPool->toPoolFramed()
            ->m_framebuffer->prepare(dest, src, colorClear);
    }

    // when the selected pool is MAP, reset the creature information state.
    if (type == DrawPoolType::MAP) {
        get<DrawPool>(DrawPoolType::CREATURE_INFORMATION)->resetState();
    }
}

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
#include <framework/graphics/framebuffermanager.h>

#include "painter.h"
#include <utility>

DrawPool g_drawPool;

void DrawPool::init() { createPools(); }

void DrawPool::terminate()
{
    m_currentPool = nullptr;
    for (int8 i = -1; ++i <= static_cast<uint8_t>(PoolType::UNKNOW);) {
        delete m_pools[i];
    }
}

void DrawPool::add(const Painter::PainterState& state, const Pool::DrawMethod& method, const Painter::DrawMode drawMode)
{
    updateHash(state, method);

    auto& list = m_currentPool->m_objects;

    if (m_currentPool->m_forceGrouping) {
        const auto itFind = std::find_if(list.begin() + m_currentPool->m_indexToStartSearching, list.end(), [&state]
        (const Pool::DrawObject& action) { return action.state == state; });

        if (itFind != list.end()) {
            (*itFind).drawMethods.push_back(method);
        } else {
            list.push_back(Pool::DrawObject{ state, Painter::DrawMode::Triangles, {method} });
        }

        return;
    }

    if (!list.empty()) {
        auto& prevObj = list.back();

        const bool sameState = prevObj.state == state;
        if (!method.dest.isNull()) {
            // Look for identical or opaque textures that are greater than or
            // equal to the size of the previous texture, if so, remove it from the list so they don't get drawn.
            for (auto itm = prevObj.drawMethods.begin(); itm != prevObj.drawMethods.end(); ++itm) {
                auto& prevMtd = *itm;
                if (prevMtd.dest == method.dest &&
                   ((sameState && prevMtd.rects.second == method.rects.second) || (state.texture->isOpaque() && prevObj.state.texture->canSuperimposed()))) {
                    prevObj.drawMethods.erase(itm);
                    break;
                }
            }
        }

        if (sameState) {
            prevObj.drawMode = Painter::DrawMode::Triangles;
            prevObj.drawMethods.push_back(method);
            return;
        }
    }

    list.push_back(Pool::DrawObject{ state, drawMode, {method} });
}

void DrawPool::draw()
{
    // Pre Draw
    for (const auto& pool : m_pools) {
        if (!pool->isEnabled() || !pool->hasFrameBuffer()) continue;

        const auto& pf = pool->toPoolFramed();
        if (pool->hasModification(true) && !pool->m_objects.empty()) {
            pf->m_framebuffer->bind(pf->m_dest, pf->m_src);
            for (auto& obj : pool->m_objects)
                drawObject(pool, obj);
            pf->m_framebuffer->release();
        }
    }

    // Draw
    for (const auto& pool : m_pools) {
        if (!pool->isEnabled()) continue;
        if (pool->hasFrameBuffer()) {
            const auto* const pf = pool->toPoolFramed();

            if (pf->m_beforeDraw) pf->m_beforeDraw();
            pf->m_framebuffer->draw();
            if (pf->m_afterDraw) pf->m_afterDraw();
        } else {
            if (pool->m_objects.empty())
                pool->m_cachedObjects.clear();
            else if (pool->hasModification(true))
                pool->m_cachedObjects = pool->m_objects;

            for (auto& obj : pool->m_cachedObjects) {
                drawObject(pool, obj);
            }
        }

        pool->m_objects.clear();
    }
}

void DrawPool::drawObject(const Pool* pool, Pool::DrawObject& obj)
{
    if (obj.action) {
        obj.action();
        return;
    }

    if (obj.drawMethods.empty()) return;

    g_painter->executeState(obj.state);

    if (obj.state.texture) {
        obj.state.texture->create();
        g_painter->setTexture(obj.state.texture.get());
    }

    if (!pool->hasFrameBuffer() && obj.coordsBuffer == nullptr) {
        obj.coordsBuffer = std::make_shared<CoordsBuffer>();
    }

    const bool isGlobalCoord = obj.coordsBuffer == nullptr;
    auto& buffer = isGlobalCoord ? m_coordsBuffer : *obj.coordsBuffer;

    if (buffer.getVertexCount() == 0) {
        for (const auto& method : obj.drawMethods) {
            if (method.type == Pool::DrawMethodType::BOUNDING_RECT) {
                buffer.addBoudingRect(method.rects.first, method.intValue);
            } else if (method.type == Pool::DrawMethodType::RECT) {
                if (obj.drawMode == Painter::DrawMode::Triangles)
                    buffer.addRect(method.rects.first, method.rects.second);
                else
                    buffer.addQuad(method.rects.first, method.rects.second);
            } else if (method.type == Pool::DrawMethodType::TRIANGLE) {
                buffer.addTriangle(std::get<0>(method.points), std::get<1>(method.points), std::get<2>(method.points));
            } else if (method.type == Pool::DrawMethodType::UPSIDEDOWN_RECT) {
                if (obj.drawMode == Painter::DrawMode::Triangles)
                    buffer.addUpsideDownRect(method.rects.first, method.rects.second);
                else
                    buffer.addUpsideDownQuad(method.rects.first, method.rects.second);
            } else if (method.type == Pool::DrawMethodType::REPEATED_RECT) {
                buffer.addRepeatedRects(method.rects.first, method.rects.second);
            }
        }
    }

    g_painter->drawCoords(buffer, obj.drawMode);

    if (isGlobalCoord)
        m_coordsBuffer.clear();
}

void DrawPool::addTexturedRect(const Rect& dest, const TexturePtr& texture, const Color color)
{
    addTexturedRect(dest, texture, Rect(Point(), texture->getSize()), color);
}

void DrawPool::addTexturedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color color, const Point& originalDest)
{
    if (dest.isEmpty() || src.isEmpty())
        return;

    const Pool::DrawMethod method{
        .type = Pool::DrawMethodType::RECT,
        .rects = std::make_pair(dest, src),
        .dest = originalDest
    };

    add(generateState(color, texture), method, Painter::DrawMode::TriangleStrip);
}

void DrawPool::addUpsideDownTexturedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color color)
{
    if (dest.isEmpty() || src.isEmpty())
        return;

    const Pool::DrawMethod method{ Pool::DrawMethodType::UPSIDEDOWN_RECT, std::make_pair(dest, src) };

    add(generateState(color, texture), method, Painter::DrawMode::TriangleStrip);
}

void DrawPool::addTexturedRepeatedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color color)
{
    if (dest.isEmpty() || src.isEmpty())
        return;

    const Pool::DrawMethod method{ Pool::DrawMethodType::REPEATED_RECT,std::make_pair(dest, src) };

    add(generateState(color, texture), method);
}

void DrawPool::addFilledRect(const Rect& dest, const Color color)
{
    if (dest.isEmpty())
        return;

    const Pool::DrawMethod method{ Pool::DrawMethodType::RECT,std::make_pair(dest, Rect()) };

    add(generateState(color), method);
}

void DrawPool::addFilledTriangle(const Point& a, const Point& b, const Point& c, const Color color)
{
    if (a == b || a == c || b == c)
        return;

    const Pool::DrawMethod method{ .type = Pool::DrawMethodType::TRIANGLE, .points = std::make_tuple(a, b, c) };

    add(generateState(color), method);
}

void DrawPool::addBoundingRect(const Rect& dest, const Color color, int innerLineWidth)
{
    if (dest.isEmpty() || innerLineWidth == 0)
        return;

    const Pool::DrawMethod method{
        .type = Pool::DrawMethodType::BOUNDING_RECT,
        .rects = std::make_pair(dest, Rect()),
        .intValue = static_cast<uint16>(innerLineWidth)
    };

    add(generateState(color), method);
}

void DrawPool::addAction(std::function<void()> action)
{
    m_currentPool->m_objects.push_back(Pool::DrawObject{ .action = std::move(action) });
}

Painter::PainterState DrawPool::generateState(const Color& color, const TexturePtr& texture)
{
    return Painter::PainterState{
       g_painter->getResolution() , g_painter->getTransformMatrix(), g_painter->getProjectionMatrix(), g_painter->getTextureMatrix(),
        color, m_currentPool->m_state.opacity, m_currentPool->m_state.compositionMode, m_currentPool->m_state.blendEquation, m_currentPool->m_state.clipRect,
        texture, m_currentPool->m_state.shaderProgram, m_currentPool->m_state.alphaWriting
    };
}

void DrawPool::createPools()
{
    for (int8 i = -1; ++i <= static_cast<uint8_t>(PoolType::UNKNOW);) {
        const auto type = static_cast<PoolType>(i);
        Pool* pool;
        if (type == PoolType::MAP || type == PoolType::LIGHT || type == PoolType::FOREGROUND) {
            const auto& frameBuffer = g_framebuffers.createFrameBuffer(true);

            if (type == PoolType::MAP) frameBuffer->disableBlend();
            else if (type == PoolType::LIGHT) frameBuffer->setCompositionMode(Painter::CompositionMode_Light);

            pool = new PoolFramed{ frameBuffer };
        } else {
            pool = new Pool;
            pool->m_forceGrouping = true; // CREATURE_INFORMATION & TEXT
        }

        pool->m_type = type;
        m_pools[i] = pool;
    }
}

void DrawPool::use(const PoolType type)
{
    m_currentPool = get<Pool>(type);
    m_currentPool->resetState();
}

void DrawPool::use(const PoolType type, const Rect& dest, const Rect& src, const Color colorClear)
{
    use(type);
    if (!m_currentPool->hasFrameBuffer())
        return;

    const auto& pool = poolFramed();

    pool->m_dest = dest;
    pool->m_src = src;
    pool->m_state.alphaWriting = false;
    pool->m_framebuffer->m_colorClear = colorClear;
}

void DrawPool::updateHash(const Painter::PainterState& state, const Pool::DrawMethod& method)
{
    size_t hash = 0;

    if (state.texture) {
        // TODO: use uniqueID id when applying multithreading, not forgetting that in the APNG texture, the id changes every frame.
        stdext::hash_combine(hash, state.texture->getId() || state.texture->getUniqueId());
    }

    if (state.opacity < 1.f)
        stdext::hash_combine(hash, state.opacity);

    if (state.color != Color::white)
        stdext::hash_combine(hash, state.color.rgba());

    if (state.compositionMode != Painter::CompositionMode_Normal)
        stdext::hash_combine(hash, state.compositionMode);

    if (state.shaderProgram)
        m_currentPool->m_autoUpdate = true;

    if (state.clipRect.isValid()) stdext::hash_combine(hash, state.clipRect.hash());
    if (method.rects.first.isValid()) stdext::hash_combine(hash, method.rects.first.hash());
    if (method.rects.second.isValid()) stdext::hash_combine(hash, method.rects.second.hash());

    const auto& a = std::get<0>(method.points),
        b = std::get<1>(method.points),
        c = std::get<2>(method.points);

    if (!a.isNull()) stdext::hash_combine(hash, a.hash());
    if (!b.isNull()) stdext::hash_combine(hash, b.hash());
    if (!c.isNull()) stdext::hash_combine(hash, c.hash());

    if (method.intValue) stdext::hash_combine(hash, method.intValue);

    stdext::hash_combine(m_currentPool->m_status.second, hash);
}

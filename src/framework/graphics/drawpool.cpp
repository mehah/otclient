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
    for (int_fast8_t i = -1; ++i <= static_cast<uint8_t>(PoolType::UNKNOW);) {
        delete m_pools[i];
    }
}

void DrawPool::add(const Color& color, const TexturePtr& texture, const Pool::DrawMethod& method, const DrawMode drawMode, std::shared_ptr<Pool::DrawBuffer> drawQueue)
{
    const auto& state = Painter::PainterState{
       g_painter->getTransformMatrixRef(), color, m_currentPool->m_state.opacity,
       m_currentPool->m_state.compositionMode, m_currentPool->m_state.blendEquation,
       m_currentPool->m_state.clipRect, texture, m_currentPool->m_state.shaderProgram
    };

    size_t stateHash = 0, methodHash = 0;
    updateHash(state, method, stateHash, methodHash);

    auto& list = m_currentPool->m_objects;

    if (m_currentPool->m_forceGrouping || drawQueue) {
        auto& pointer = m_currentPool->m_drawObjectPointer;
        if (auto it = pointer.find(stateHash); it != pointer.end()) {
            auto& draw = list[it->second];
            if (!draw.queue->isValid())
                return;

            auto& hashList = draw.queue->hashs;
            if (++draw.queue->i == hashList.size()) {
                hashList.push_back(methodHash);
                addCoords(method, *draw.queue->coords, DrawMode::TRIANGLES);
            } else if (hashList[draw.queue->i] != methodHash) {
                draw.queue->invalidate();
            }

            return;
        }

        pointer[stateHash] = list.size();

        if (!drawQueue) {
            auto& bufferCache = m_currentPool->m_bufferCache;
            if (auto it = bufferCache.find(stateHash); it == bufferCache.end()) {
                bufferCache[stateHash] = drawQueue = std::make_shared<Pool::DrawBuffer>();
            } else {
                drawQueue = it->second;
            }
        }

        if (drawQueue->hashs.empty()) {
            if (drawQueue->coords)
                drawQueue->coords->clear();
            else
                drawQueue->coords = std::make_shared<CoordsBuffer>();

            drawQueue->hashs.push_back(methodHash);
            addCoords(method, *drawQueue->coords, DrawMode::TRIANGLES);
        }
        drawQueue->i = 0;

        list.push_back({ state, DrawMode::TRIANGLES, {}, drawQueue });

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
            prevObj.drawMode = DrawMode::TRIANGLES;
            prevObj.drawMethods.push_back(method);
            return;
        }
    }

    list.push_back({ state, drawMode, {method} });
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
                drawObject(obj);
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
            for (auto& obj : pool->m_objects) {
                drawObject(obj);
            }
        }

        pool->m_objects.clear();
    }
}

void DrawPool::drawObject(Pool::DrawObject& obj)
{
    if (obj.action) {
        obj.action();
        return;
    }

    const bool useGlobalCoord = !obj.queue;
    auto& buffer = useGlobalCoord ? m_coordsBuffer : *obj.queue->coords;

    if (useGlobalCoord) {
        if (obj.drawMethods.empty()) return;
        for (const auto& method : obj.drawMethods) {
            addCoords(method, buffer, obj.drawMode);
        }
    }

    if (obj.state.texture) {
        obj.state.texture->create();
        g_painter->setTexture(obj.state.texture.get());
    }
    g_painter->executeState(obj.state);
    g_painter->drawCoords(buffer, obj.drawMode);

    if (useGlobalCoord)
        m_coordsBuffer.clear();
}

void DrawPool::addCoords(const Pool::DrawMethod& method, CoordsBuffer& buffer, DrawMode drawMode)
{
    if (method.type == Pool::DrawMethodType::BOUNDING_RECT) {
        buffer.addBoudingRect(method.rects.first, method.intValue);
    } else if (method.type == Pool::DrawMethodType::RECT) {
        if (drawMode == DrawMode::TRIANGLES)
            buffer.addRect(method.rects.first, method.rects.second);
        else
            buffer.addQuad(method.rects.first, method.rects.second);
    } else if (method.type == Pool::DrawMethodType::TRIANGLE) {
        buffer.addTriangle(std::get<0>(method.points), std::get<1>(method.points), std::get<2>(method.points));
    } else if (method.type == Pool::DrawMethodType::UPSIDEDOWN_RECT) {
        if (drawMode == DrawMode::TRIANGLES)
            buffer.addUpsideDownRect(method.rects.first, method.rects.second);
        else
            buffer.addUpsideDownQuad(method.rects.first, method.rects.second);
    } else if (method.type == Pool::DrawMethodType::REPEATED_RECT) {
        buffer.addRepeatedRects(method.rects.first, method.rects.second);
    }
}

void DrawPool::addTexturedRect(const Rect& dest, const TexturePtr& texture, const Color& color)
{
    addTexturedRect(dest, texture, Rect(Point(), texture->getSize()), color);
}

void DrawPool::addTexturedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color, const Point& originalDest, std::shared_ptr<Pool::DrawBuffer> drawQueue)
{
    if (dest.isEmpty() || src.isEmpty())
        return;

    const Pool::DrawMethod method{
        .type = Pool::DrawMethodType::RECT,
        .rects = std::make_pair(dest, src),
        .dest = originalDest
    };

    add(color, texture, method, DrawMode::TRIANGLE_STRIP, drawQueue);
}

void DrawPool::addUpsideDownTexturedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color)
{
    if (dest.isEmpty() || src.isEmpty())
        return;

    const Pool::DrawMethod method{ Pool::DrawMethodType::UPSIDEDOWN_RECT, std::make_pair(dest, src) };

    add(color, texture, method, DrawMode::TRIANGLE_STRIP);
}

void DrawPool::addTexturedRepeatedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color)
{
    if (dest.isEmpty() || src.isEmpty())
        return;

    const Pool::DrawMethod method{ Pool::DrawMethodType::REPEATED_RECT,std::make_pair(dest, src) };

    add(color, texture, method);
}

void DrawPool::addFilledRect(const Rect& dest, const Color& color)
{
    if (dest.isEmpty())
        return;

    const Pool::DrawMethod method{ Pool::DrawMethodType::RECT,std::make_pair(dest, Rect()) };

    add(color, nullptr, method);
}

void DrawPool::addFilledTriangle(const Point& a, const Point& b, const Point& c, const Color& color)
{
    if (a == b || a == c || b == c)
        return;

    const Pool::DrawMethod method{ .type = Pool::DrawMethodType::TRIANGLE, .points = std::make_tuple(a, b, c) };

    add(color, nullptr, method);
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

    add(color, nullptr, method);
}

void DrawPool::addAction(std::function<void()> action)
{
    m_currentPool->m_objects.push_back(Pool::DrawObject{ .state = NULL_STATE,.action = std::move(action) });
}

void DrawPool::createPools()
{
    for (int8_t i = -1; ++i <= static_cast<uint8_t>(PoolType::UNKNOW);) {
        const auto type = static_cast<PoolType>(i);
        Pool* pool;
        if (type == PoolType::MAP || type == PoolType::LIGHT || type == PoolType::FOREGROUND) {
            const auto& frameBuffer = g_framebuffers.createFrameBuffer(true);

            pool = new PoolFramed{ frameBuffer };

            if (type == PoolType::MAP) frameBuffer->disableBlend();
            else if (type == PoolType::LIGHT) {
                pool->m_forceGrouping = true;
                frameBuffer->setCompositionMode(CompositionMode::LIGHT);
            }
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

void DrawPool::use(const PoolType type, const Rect& dest, const Rect& src, const Color& colorClear)
{
    use(type);
    if (!m_currentPool->hasFrameBuffer())
        return;

    const auto& pool = poolFramed();

    pool->m_dest = dest;
    pool->m_src = src;
    pool->m_framebuffer->m_colorClear = colorClear;
}

void DrawPool::updateHash(const Painter::PainterState& state, const Pool::DrawMethod& method,
                            size_t& stateHash, size_t& methodhash)
{
    { // State Hash
        if (state.blendEquation != BlendEquation::ADD)
            stdext::hash_combine(stateHash, state.blendEquation);

        if (state.clipRect.isValid()) stdext::hash_union(stateHash, state.clipRect.hash());
        if (state.color != Color::white)
            stdext::hash_combine(stateHash, state.color.rgba());

        if (state.compositionMode != CompositionMode::NORMAL)
            stdext::hash_combine(stateHash, state.compositionMode);

        if (state.opacity < 1.f)
            stdext::hash_combine(stateHash, state.opacity);

        if (state.shaderProgram) {
            m_currentPool->m_autoUpdate = true;
            stdext::hash_combine(stateHash, state.shaderProgram->getProgramId());
        }

        if (state.texture) {
            // TODO: use uniqueID id when applying multithreading, not forgetting that in the APNG texture, the id changes every frame.
            stdext::hash_combine(stateHash, !state.texture->isEmpty() ? state.texture->getId() : state.texture->getUniqueId());
        }

        if (state.transformMatrix != DEFAULT_MATRIX_3)
            stdext::hash_union(stateHash, state.transformMatrix.hash());

        stdext::hash_union(m_currentPool->m_status.second, stateHash);
    }

    { // Method Hash
        if (method.rects.first.isValid()) stdext::hash_union(methodhash, method.rects.first.hash());
        if (method.rects.second.isValid()) stdext::hash_union(methodhash, method.rects.second.hash());

        const auto& a = std::get<0>(method.points),
            b = std::get<1>(method.points),
            c = std::get<2>(method.points);

        if (!a.isNull()) stdext::hash_union(methodhash, a.hash());
        if (!b.isNull()) stdext::hash_union(methodhash, b.hash());
        if (!c.isNull()) stdext::hash_union(methodhash, c.hash());

        if (method.intValue) stdext::hash_combine(methodhash, method.intValue);

        stdext::hash_union(m_currentPool->m_status.second, methodhash);
    }
}

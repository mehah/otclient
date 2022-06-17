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

#include "pool.h"
#include <framework/graphics/framebuffermanager.h>

Pool* Pool::create(const PoolType type)
{
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
    return pool;
}

void Pool::add(const Color& color, const TexturePtr& texture, const DrawMethod& method, const DrawMode drawMode, std::shared_ptr<DrawBuffer> drawBuffer)
{
    const auto& state = Painter::PainterState{
       g_painter->getTransformMatrixRef(), color, m_state.opacity,
       m_state.compositionMode, m_state.blendEquation,
       m_state.clipRect, texture, m_state.shaderProgram
    };

    size_t stateHash = 0, methodHash = 0;
    updateHash(state, method, stateHash, methodHash);

    auto& list = m_objects;

    if (m_forceGrouping || drawBuffer) {
        auto& pointer = m_drawObjectPointer;
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

        if (!drawBuffer) {
            drawBuffer = std::make_shared<DrawBuffer>();
        }

        if (drawBuffer->hashs.empty()) {
            if (drawBuffer->coords)
                drawBuffer->coords->clear();
            else
                drawBuffer->coords = std::make_shared<CoordsBuffer>();

            drawBuffer->hashs.push_back(methodHash);
            addCoords(method, *drawBuffer->coords, DrawMode::TRIANGLES);
        }
        drawBuffer->i = 0;

        list.push_back({ state, DrawMode::TRIANGLES, {}, drawBuffer });

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

void Pool::addCoords(const DrawMethod& method, CoordsBuffer& buffer, DrawMode drawMode)
{
    if (method.type == DrawMethodType::BOUNDING_RECT) {
        buffer.addBoudingRect(method.rects.first, method.intValue);
    } else if (method.type == DrawMethodType::RECT) {
        if (drawMode == DrawMode::TRIANGLES)
            buffer.addRect(method.rects.first, method.rects.second);
        else
            buffer.addQuad(method.rects.first, method.rects.second);
    } else if (method.type == DrawMethodType::TRIANGLE) {
        buffer.addTriangle(std::get<0>(method.points), std::get<1>(method.points), std::get<2>(method.points));
    } else if (method.type == DrawMethodType::UPSIDEDOWN_RECT) {
        if (drawMode == DrawMode::TRIANGLES)
            buffer.addUpsideDownRect(method.rects.first, method.rects.second);
        else
            buffer.addUpsideDownQuad(method.rects.first, method.rects.second);
    } else if (method.type == DrawMethodType::REPEATED_RECT) {
        buffer.addRepeatedRects(method.rects.first, method.rects.second);
    }
}

void Pool::updateHash(const Painter::PainterState& state, const DrawMethod& method,
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
            m_autoUpdate = true;
            stdext::hash_combine(stateHash, state.shaderProgram->getProgramId());
        }

        if (state.texture) {
            // TODO: use uniqueID id when applying multithreading, not forgetting that in the APNG texture, the id changes every frame.
            stdext::hash_combine(stateHash, !state.texture->isEmpty() ? state.texture->getId() : state.texture->getUniqueId());
        }

        if (state.transformMatrix != DEFAULT_MATRIX_3)
            stdext::hash_union(stateHash, state.transformMatrix.hash());

        stdext::hash_union(m_status.second, stateHash);
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

        stdext::hash_union(m_status.second, methodhash);
    }
}

void Pool::setCompositionMode(const CompositionMode mode, const int pos)
{
    if (pos == -1) {
        m_state.compositionMode = mode;
        return;
    }

    m_objects[pos - 1].state.compositionMode = mode;
    stdext::hash_combine(m_status.second, mode);
}

void Pool::setBlendEquation(BlendEquation equation, const int pos)
{
    if (pos == -1) {
        m_state.blendEquation = equation;
        return;
    }

    m_objects[pos - 1].state.blendEquation = equation;
    stdext::hash_combine(m_status.second, equation);
}

void Pool::setClipRect(const Rect& clipRect, const int pos)
{
    if (pos == -1) {
        m_state.clipRect = clipRect;
        return;
    }

    m_objects[pos - 1].state.clipRect = clipRect;
    stdext::hash_combine(m_status.second, clipRect.hash());
}

void Pool::setOpacity(const float opacity, const int pos)
{
    if (pos == -1) {
        m_state.opacity = opacity;
        return;
    }

    m_objects[pos - 1].state.opacity = opacity;
    stdext::hash_combine(m_status.second, opacity);
}

void Pool::setShaderProgram(const PainterShaderProgramPtr& shaderProgram, const int pos, const std::function<void()>& action)
{
    const auto& shader = shaderProgram ? shaderProgram.get() : nullptr;

    if (pos == -1) {
        m_state.shaderProgram = shader;
        m_state.action = action;
        return;
    }

    if (shader) {
        m_autoUpdate = true;
    }

    auto& o = m_objects[pos - 1];
    o.state.shaderProgram = shader;
    o.state.action = action;
}

void Pool::resetState()
{
    resetOpacity();
    resetClipRect();
    resetShaderProgram();
    resetBlendEquation();
    resetCompositionMode();

    m_autoUpdate = false;
    m_status.second = 0;
    m_drawObjectPointer.clear();
}

bool Pool::hasModification(const bool autoUpdateStatus)
{
    const bool hasModification = m_status.first != m_status.second || (m_autoUpdate && m_refreshTime.ticksElapsed() > 50);

    if (hasModification && autoUpdateStatus)
        updateStatus();

    return hasModification;
}

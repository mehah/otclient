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
            pool->m_alwaysGroupDrawings = true;
            frameBuffer->setCompositionMode(CompositionMode::LIGHT);
        }
    } else {
        pool = new Pool;
        pool->m_alwaysGroupDrawings = true; // CREATURE_INFORMATION & TEXT
    }

    pool->m_type = type;
    return pool;
}

void Pool::add(const Color& color, const TexturePtr& texture, const DrawMethod& method, const DrawMode drawMode, const DrawBufferPtr& drawBuffer, const CoordsBufferPtr& coordsBuffer)
{
    const auto& state = PoolState{
       g_painter->m_transformMatrix, color, m_state.opacity,
       m_state.compositionMode, m_state.blendEquation,
       m_state.clipRect, texture, m_state.shaderProgram
    };

    m_empty = false;

    size_t stateHash = 0, methodHash = 0;
    updateHash(state, method, stateHash, methodHash);

    if (m_alwaysGroupDrawings || drawBuffer && drawBuffer->m_agroup) {
        if (auto it = m_objectsByhash.find(stateHash); it != m_objectsByhash.end()) {
            const auto& buffer = it->second.buffer;

            if (!buffer->isTemporary()) {
                if (!buffer->isValid())
                    return;

                auto& hashList = buffer->m_hashs;

                // condition to check if the buffer has been reset, if so, add the vertex again.
                if (++buffer->m_i == hashList.size()) {
                    hashList.push_back(methodHash);
                } else {
                    // checks if the vertex to be added is in the same position,
                    // otherwise the buffer will be invalidated to recreate the cache.
                    if (hashList[buffer->m_i] != methodHash)
                        buffer->invalidate();
                    return;
                }
            }

            if (coordsBuffer)
                buffer->getCoords()->append(coordsBuffer.get());
            else
                addCoords(method, *buffer->m_coords.get(), DrawMode::TRIANGLES);

            return;
        }

        bool addCoord = false;

        const DrawBufferPtr& buffer = drawBuffer ? drawBuffer : std::make_shared<DrawBuffer>(Pool::DrawOrder::FIRST);
        if (drawBuffer) {
            if (!drawBuffer->isValid()) {
                drawBuffer->getCoords()->clear();
                drawBuffer->m_hashs.clear();
                drawBuffer->m_hashs.push_back(methodHash);
                addCoord = true;
            }
            drawBuffer->m_i = 0; // reset identifier to say it is valid.
        } else {
            buffer->m_i = -2; // identifier to say it is a temporary buffer.
            addCoord = true;
        }

        if (addCoord) {
            auto* coords = buffer->getCoords();
            if (coordsBuffer)
                coords->append(coordsBuffer.get());
            else
                addCoords(method, *coords, DrawMode::TRIANGLES);
        }

        m_objectsByhash.emplace(stateHash,
              m_objects[m_currentFloor][m_currentOrder = static_cast<uint8_t>(buffer->m_order)]
                       .emplace_back(state, buffer));

        return;
    }

    m_currentOrder = static_cast<uint8_t>(drawBuffer ? drawBuffer->m_order : Pool::DrawOrder::THIRD);

    auto& list = m_objects[m_currentFloor][m_currentOrder];

    if (!list.empty()) {
        auto& prevObj = list.back();

        const bool sameState = prevObj.state == state;
        if (method.dest.has_value() && prevObj.methods.has_value()) {
            // Look for identical or opaque textures that are greater than or
            // equal to the size of the previous texture, if so, remove it from the list so they don't get drawn.
            auto& drawMethods = *prevObj.methods;
            for (auto itm = drawMethods.begin(); itm != drawMethods.end(); ++itm) {
                auto& prevMtd = *itm;
                if (prevMtd.dest == method.dest &&
                   ((sameState && prevMtd.rects->second == method.rects->second) || (state.texture->isOpaque() && prevObj.state->texture->canSuperimposed()))) {
                    drawMethods.erase(itm);
                    break;
                }
            }
        }

        if (sameState) {
            if (prevObj.buffer) {
                if (coordsBuffer)
                    prevObj.buffer->getCoords()->append(coordsBuffer.get());
                else
                    addCoords(method, *prevObj.buffer->getCoords(), DrawMode::TRIANGLES);
            } else
                prevObj.addMethod(method);
            return;
        }
    }

    if (coordsBuffer) {
        const DrawBufferPtr& buffer = std::make_shared<DrawBuffer>(Pool::DrawOrder::FIRST);
        buffer->getCoords()->append(coordsBuffer.get());
        list.emplace_back(state, buffer);
    } else
        list.emplace_back(drawMode, state, method);
}

void Pool::addCoords(const DrawMethod& method, CoordsBuffer& buffer, DrawMode drawMode)
{
    if (method.type == DrawMethodType::BOUNDING_RECT) {
        buffer.addBoudingRect(method.rects->first, method.intValue);
    } else if (method.type == DrawMethodType::RECT) {
        if (drawMode == DrawMode::TRIANGLES)
            buffer.addRect(method.rects->first, method.rects->second);
        else
            buffer.addQuad(method.rects->first, method.rects->second);
    } else if (method.type == DrawMethodType::TRIANGLE) {
        const auto& points = *method.points;
        buffer.addTriangle(std::get<0>(points), std::get<1>(points), std::get<2>(points));
    } else if (method.type == DrawMethodType::UPSIDEDOWN_RECT) {
        if (drawMode == DrawMode::TRIANGLES)
            buffer.addUpsideDownRect(method.rects->first, method.rects->second);
        else
            buffer.addUpsideDownQuad(method.rects->first, method.rects->second);
    } else if (method.type == DrawMethodType::REPEATED_RECT) {
        buffer.addRepeatedRects(method.rects->first, method.rects->second);
    }
}

void Pool::updateHash(const PoolState& state, const DrawMethod& method,
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

        if (state.transformMatrix != DEFAULT_MATRIX3)
            stdext::hash_union(stateHash, state.transformMatrix.hash());

        stdext::hash_union(m_status.second, stateHash);
    }

    { // Method Hash
        if (method.rects.has_value()) {
            if (method.rects->first.isValid()) stdext::hash_union(methodhash, method.rects->first.hash());
            if (method.rects->second.isValid()) stdext::hash_union(methodhash, method.rects->second.hash());
        }

        if (method.points.has_value()) {
            const auto& points = *method.points;
            const auto& a = std::get<0>(points),
                b = std::get<1>(points),
                c = std::get<2>(points);

            if (!a.isNull()) stdext::hash_union(methodhash, a.hash());
            if (!b.isNull()) stdext::hash_union(methodhash, b.hash());
            if (!c.isNull()) stdext::hash_union(methodhash, c.hash());
        }

        if (method.intValue) stdext::hash_combine(methodhash, method.intValue);

        stdext::hash_union(m_status.second, methodhash);
    }
}

void Pool::setCompositionMode(const CompositionMode mode, bool onLastDrawing)
{
    if (!onLastDrawing) {
        m_state.compositionMode = mode;
        return;
    }

    getLastDrawObject().state->compositionMode = mode;
    stdext::hash_combine(m_status.second, mode);
}

void Pool::setBlendEquation(BlendEquation equation, bool onLastDrawing)
{
    if (!onLastDrawing) {
        m_state.blendEquation = equation;
        return;
    }

    getLastDrawObject().state->blendEquation = equation;
    stdext::hash_combine(m_status.second, equation);
}

void Pool::setClipRect(const Rect& clipRect, bool onLastDrawing)
{
    if (!onLastDrawing) {
        m_state.clipRect = clipRect;
        return;
    }

    getLastDrawObject().state->clipRect = clipRect;
    stdext::hash_union(m_status.second, clipRect.hash());
}

void Pool::setOpacity(const float opacity, bool onLastDrawing)
{
    if (!onLastDrawing) {
        m_state.opacity = opacity;
        return;
    }

    getLastDrawObject().state->opacity = opacity;
    stdext::hash_combine(m_status.second, opacity);
}

void Pool::setShaderProgram(const PainterShaderProgramPtr& shaderProgram, bool onLastDrawing, const std::function<void()>& action)
{
    const auto& shader = shaderProgram ? shaderProgram.get() : nullptr;

    if (!onLastDrawing) {
        m_state.shaderProgram = shader;
        m_state.action = action;
        return;
    }

    if (shader) {
        m_autoUpdate = true;
    }

    auto& o = getLastDrawObject();
    o.state->shaderProgram = shader;
    o.state->action = action;
}

void Pool::resetState()
{
    clear();
    resetOpacity();
    resetClipRect();
    resetShaderProgram();
    resetBlendEquation();
    resetCompositionMode();

    m_status.second = 0;

    m_empty = true;
    m_autoUpdate = false;
}

bool Pool::hasModification(const bool autoUpdateStatus)
{
    const bool hasModification = m_status.first != m_status.second || (m_autoUpdate && m_refreshTime.ticksElapsed() > 50);

    if (hasModification && autoUpdateStatus)
        updateStatus();

    return hasModification;
}

void Pool::clear()
{
    // clean only processed floors
    for (int_fast8_t z = -1; ++z <= m_currentFloor;) {
        for (auto& order : m_objects[z])
            order.clear();
    }
    m_objectsByhash.clear();
    m_currentFloor = 0;
}

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
#include "framebuffermanager.h"

static constexpr int REFRESH_TIME = 1000 / 20; // 20 FPS (50ms)

DrawPool* DrawPool::create(const DrawPoolType type)
{
    DrawPool* pool;
    if (type == DrawPoolType::MAP || type == DrawPoolType::LIGHT || type == DrawPoolType::FOREGROUND) {
        const auto& frameBuffer = g_framebuffers.createFrameBuffer(true);

        pool = new DrawPoolFramed{ frameBuffer };

        if (type == DrawPoolType::MAP) frameBuffer->disableBlend();
        else if (type == DrawPoolType::LIGHT) {
            pool->m_alwaysGroupDrawings = true;
            frameBuffer->setCompositionMode(CompositionMode::LIGHT);
        }
    } else {
        pool = new DrawPool;
        pool->m_alwaysGroupDrawings = true; // CREATURE_INFORMATION & TEXT
    }

    pool->m_type = type;
    return pool;
}

void DrawPool::add(const Color& color, const TexturePtr& texture, const DrawMethod& method, const DrawMode drawMode, const DrawBufferPtr& drawBuffer, const CoordsBufferPtr& coordsBuffer)
{
    const auto& state = PoolState{
       m_state.transformMatrix, color, m_state.opacity,
       m_state.compositionMode, m_state.blendEquation,
       m_state.clipRect, texture, m_state.shaderProgram,
       m_state.action
    };

    if (m_onlyOnceStateFlag > 0) { // Only Once State
        if (m_onlyOnceStateFlag & STATE_OPACITY)
            resetOpacity();

        if (m_onlyOnceStateFlag & STATE_BLEND_EQUATION)
            resetBlendEquation();

        if (m_onlyOnceStateFlag & STATE_CLIP_RECT)
            resetClipRect();

        if (m_onlyOnceStateFlag & STATE_COMPOSITE_MODE)
            resetCompositionMode();

        if (m_onlyOnceStateFlag & STATE_SHADER_PROGRAM)
            resetShaderProgram();

        m_onlyOnceStateFlag = 0;
    }

    size_t stateHash = 0;
    size_t methodHash = 0;
    updateHash(state, method, stateHash, methodHash);

    if (m_type != DrawPoolType::FOREGROUND && (m_alwaysGroupDrawings || (drawBuffer && drawBuffer->m_agroup))) {
        if (auto it = m_objectsByhash.find(stateHash); it != m_objectsByhash.end()) {
            const auto& buffer = it->second.buffer;

            if (!buffer->isTemporary() && buffer->isValid()) {
                auto& hashList = buffer->m_hashs;
                if (++buffer->m_i != hashList.size()) {
                    // checks if the vertex to be added is in the same position,
                    // otherwise the buffer will be invalidated to recreate the cache.
                    if (hashList[buffer->m_i] != methodHash)
                        buffer->invalidate();
                    else return;
                }
                hashList.push_back(methodHash);
            }

            if (coordsBuffer)
                buffer->getCoords()->append(coordsBuffer.get());
            else
                addCoords(method, *buffer->m_coords.get(), DrawMode::TRIANGLES);

            return;
        }

        const DrawOrder order = m_type == DrawPoolType::MAP ? DrawPool::DrawOrder::THIRD : DrawPool::DrawOrder::FIRST;
        const DrawBufferPtr& buffer = drawBuffer ? drawBuffer : DrawBuffer::createTemporaryBuffer(order);

        bool addCoord = buffer->isTemporary();
        if (!addCoord) { // is not temp buffer
            if (buffer->m_stateHash != stateHash || !buffer->isValid()) {
                buffer->getCoords()->clear();
                buffer->m_stateHash = stateHash;
                buffer->m_hashs.clear();
                buffer->m_hashs.push_back(methodHash);
                addCoord = true;
            }
            buffer->m_i = 0; // reset identifier to say it is valid.
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

    m_currentOrder = static_cast<uint8_t>(m_type == DrawPoolType::FOREGROUND ? DrawPool::DrawOrder::FIRST :
                                          drawBuffer ? drawBuffer->m_order : DrawPool::DrawOrder::THIRD);

    auto& list = m_objects[m_currentFloor][m_currentOrder];

    if (!list.empty()) {
        auto& prevObj = list.back();

        const bool sameState = prevObj.state == state;
        if (!method.dest.isNull() && !prevObj.methods.empty()) {
            // Look for identical or opaque textures that are greater than or
            // equal to the size of the previous texture, if so, remove it from the list so they don't get drawn.
            auto& drawMethods = prevObj.methods;
            for (auto itm = drawMethods.begin(); itm != drawMethods.end(); ++itm) {
                auto& prevMtd = *itm;
                if (prevMtd.dest == method.dest &&
                    ((sameState && prevMtd.rects.second == method.rects.second) || (state.texture->isOpaque() && prevObj.state.texture->canSuperimposed()))) {
                    drawMethods.erase(itm);
                    break;
                }
            }
        }

        if (sameState) {
            if (!prevObj.buffer) {
                prevObj.addMethod(method);
                return;
            }

            if (prevObj.buffer->isTemporary()) {
                if (coordsBuffer) {
                    prevObj.buffer->getCoords()->append(coordsBuffer.get());
                } else {
                    addCoords(method, *prevObj.buffer->getCoords(), DrawMode::TRIANGLES);
                }
            }
        }
    }

    if (coordsBuffer) {
        const DrawBufferPtr& buffer = DrawBuffer::createTemporaryBuffer(DrawPool::DrawOrder::FIRST);
        buffer->getCoords()->append(coordsBuffer.get());
        list.emplace_back(state, buffer);
    } else
        list.emplace_back(drawMode, state, method);
}

void DrawPool::addCoords(const DrawMethod& method, CoordsBuffer& buffer, DrawMode drawMode)
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

void DrawPool::updateHash(const PoolState& state, const DrawMethod& method, size_t& stateHash, size_t& methodhash)
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
            m_refreshTimeMS = REFRESH_TIME;
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
        if (method.rects.first.isValid()) stdext::hash_union(methodhash, method.rects.first.hash());
        if (method.rects.second.isValid()) stdext::hash_union(methodhash, method.rects.second.hash());

        if (method.type == DrawPool::DrawMethodType::TRIANGLE) {
            const auto& a = std::get<0>(method.points);
            const auto& b = std::get<1>(method.points);
            const auto& c = std::get<2>(method.points);

            if (!a.isNull()) stdext::hash_union(methodhash, a.hash());
            if (!b.isNull()) stdext::hash_union(methodhash, b.hash());
            if (!c.isNull()) stdext::hash_union(methodhash, c.hash());
        }

        if (method.intValue) stdext::hash_combine(methodhash, method.intValue);

        stdext::hash_union(m_status.second, methodhash);
    }
}

void DrawPool::setCompositionMode(const CompositionMode mode, bool onlyOnce)
{
    m_state.compositionMode = mode;
    if (onlyOnce) m_onlyOnceStateFlag |= STATE_COMPOSITE_MODE;
}

void DrawPool::setBlendEquation(BlendEquation equation, bool onlyOnce)
{
    m_state.blendEquation = equation;
    if (onlyOnce) m_onlyOnceStateFlag |= STATE_BLEND_EQUATION;
}

void DrawPool::setClipRect(const Rect& clipRect, bool onlyOnce)
{
    m_state.clipRect = clipRect;
    if (onlyOnce) m_onlyOnceStateFlag |= STATE_CLIP_RECT;
}

void DrawPool::setOpacity(const float opacity, bool onlyOnce)
{
    m_state.opacity = opacity;
    if (onlyOnce) m_onlyOnceStateFlag |= STATE_OPACITY;
}

void DrawPool::setShaderProgram(const PainterShaderProgramPtr& shaderProgram, bool onlyOnce, const std::function<void()>& action)
{
    m_state.shaderProgram = shaderProgram ? shaderProgram.get() : nullptr;
    m_state.action = action;

    if (m_state.shaderProgram) {
        m_refreshTimeMS = REFRESH_TIME;
    }

    if (onlyOnce) m_onlyOnceStateFlag |= STATE_SHADER_PROGRAM;
}

void DrawPool::resetState()
{
    clear();
    resetOpacity();
    resetClipRect();
    resetShaderProgram();
    resetBlendEquation();
    resetCompositionMode();
    resetTransformMatrix();

    m_status.second = 0;
    if (!m_autoUpdate)
        m_refreshTimeMS = 0;
}

bool DrawPool::canRepaint(const bool autoUpdateStatus)
{
    const bool canRepaint = m_status.first != m_status.second || (m_refreshTimeMS > 0 && m_refreshTimer.ticksElapsed() > m_refreshTimeMS);

    if (canRepaint && autoUpdateStatus) {
        m_refreshTimer.restart();
        m_status.first = m_status.second;
    }

    return canRepaint;
}

void DrawPool::clear()
{
    for (auto& objs : m_objects) {
        for (auto& order : objs)
            order.clear();
    }

    m_objectsByhash.clear();
    m_currentFloor = 0;
}

void DrawPool::scale(float x, float y)
{
    const Matrix3 scaleMatrix = {
              x,   0.0f,  0.0f,
            0.0f,     y,  0.0f,
            0.0f,  0.0f,  1.0f
    };

    m_state.transformMatrix = m_state.transformMatrix * scaleMatrix.transposed();
}

void DrawPool::translate(float x, float y)
{
    const Matrix3 translateMatrix = {
            1.0f,  0.0f,     x,
            0.0f,  1.0f,     y,
            0.0f,  0.0f,  1.0f
    };

    m_state.transformMatrix = m_state.transformMatrix * translateMatrix.transposed();
}

void DrawPool::rotate(float angle)
{
    const Matrix3 rotationMatrix = {
            std::cos(angle), -std::sin(angle),  0.0f,
            std::sin(angle),  std::cos(angle),  0.0f,
                                 0.0f,             0.0f,  1.0f
    };

    m_state.transformMatrix = m_state.transformMatrix * rotationMatrix.transposed();
}

void DrawPool::rotate(float x, float y, float angle)
{
    translate(-x, -y);
    rotate(angle);
    translate(x, y);
}

void DrawPool::pushTransformMatrix()
{
    m_transformMatrixStack.push_back(m_state.transformMatrix);
    assert(m_transformMatrixStack.size() < 100);
}

void DrawPool::popTransformMatrix()
{
    assert(!m_transformMatrixStack.empty());
    m_state.transformMatrix = m_transformMatrixStack.back();
    m_transformMatrixStack.pop_back();
}

void DrawPool::optimize(int size) {
    if (m_type != DrawPoolType::MAP)
        return;

    m_alwaysGroupDrawings = size > 115; // Max optimization
}

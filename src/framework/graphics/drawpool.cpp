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

static constexpr uint16_t SHADER_REFRESH_DELAY = 1000 / 20; // 20 FPS (50ms)

DrawPool* DrawPool::create(const DrawPoolType type)
{
    DrawPool* pool;
    if (type == DrawPoolType::MAP || type == DrawPoolType::LIGHT || type == DrawPoolType::FOREGROUND) {
        pool = new DrawPoolFramed;

        const auto& frameBuffer = pool->toPoolFramed()->m_framebuffer;
        if (type == DrawPoolType::MAP) {
            frameBuffer->setUseAlphaWriting(false);
            frameBuffer->disableBlend();
        } else if (type == DrawPoolType::FOREGROUND) {
            pool->m_refreshDelay = 100; // 10 FPS (1000 / 10)
        } else if (type == DrawPoolType::LIGHT) {
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

void DrawPool::add(const Color& color, const TexturePtr& texture, DrawMethod& method, const DrawMode drawMode, const DrawBufferPtr& drawBuffer, const CoordsBufferPtr& coordsBuffer)
{
    auto state = PoolState{
       m_state.transformMatrix, m_state.opacity,
       m_state.compositionMode, m_state.blendEquation,
       m_state.clipRect, m_state.shaderProgram,
       m_state.action, color, texture
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

    size_t methodHash = updateHash(state, method);

    const DrawOrder drawOrder = m_type == DrawPoolType::MAP ? DrawPool::DrawOrder::THIRD : DrawPool::DrawOrder::FIRST;

    if (m_type != DrawPoolType::FOREGROUND && (m_alwaysGroupDrawings || (drawBuffer && drawBuffer->m_agroup))) {
        if (auto it = m_objectsByhash.find(state.hash); it != m_objectsByhash.end()) {
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
                addCoords(method, buffer->m_coords.get(), DrawMode::TRIANGLES);

            return;
        }

        const auto& buffer = drawBuffer ? drawBuffer : DrawBuffer::createTemporaryBuffer(drawOrder);

        bool addCoord = buffer->isTemporary();
        if (!addCoord) { // is not temp buffer
            if (buffer->m_stateHash != state.hash || !buffer->isValid()) {
                buffer->getCoords()->clear();
                buffer->m_stateHash = state.hash;
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
                addCoords(method, coords, DrawMode::TRIANGLES);
        }

        m_currentOrder = static_cast<uint8_t>(buffer->m_order);
        m_objectsByhash.emplace(state.hash, m_objects[m_currentFloor][m_currentOrder].emplace_back(state, buffer));

        return;
    }

    m_currentOrder = static_cast<uint8_t>(drawBuffer ? drawBuffer->m_order : drawOrder);
    auto& list = m_objects[m_currentFloor][m_currentOrder];

    if (!list.empty()) {
        auto& prevObj = list.back();

        if (prevObj.state == state) {
            if (!prevObj.buffer) {
                prevObj.addMethod(method);
                return;
            }

            if (prevObj.buffer->isTemporary()) {
                if (coordsBuffer) {
                    prevObj.buffer->getCoords()->append(coordsBuffer.get());
                } else {
                    addCoords(method, prevObj.buffer->getCoords(), DrawMode::TRIANGLES);
                }
            }
        }
    }

    if (coordsBuffer) {
        const auto& buffer = DrawBuffer::createTemporaryBuffer(DrawPool::DrawOrder::FIRST);
        buffer->getCoords()->append(coordsBuffer.get());
        list.emplace_back(state, buffer);
    } else
        list.emplace_back(drawMode, state, method);
}

void DrawPool::addCoords(const DrawMethod& method, CoordsBuffer* buffer, DrawMode drawMode)
{
    if (method.type == DrawMethodType::BOUNDING_RECT) {
        buffer->addBoudingRect(method.dest, method.intValue);
    } else if (method.type == DrawMethodType::RECT) {
        if (drawMode == DrawMode::TRIANGLES)
            buffer->addRect(method.dest, method.src);
        else
            buffer->addQuad(method.dest, method.src);
    } else if (method.type == DrawMethodType::TRIANGLE) {
        buffer->addTriangle(method.a, method.b, method.c);
    } else if (method.type == DrawMethodType::UPSIDEDOWN_RECT) {
        if (drawMode == DrawMode::TRIANGLES)
            buffer->addUpsideDownRect(method.dest, method.src);
        else
            buffer->addUpsideDownQuad(method.dest, method.src);
    } else if (method.type == DrawMethodType::REPEATED_RECT) {
        buffer->addRepeatedRects(method.dest, method.src);
    }
}

size_t DrawPool::updateHash(PoolState& state, const DrawMethod& method)
{
    { // State Hash
        if (state.blendEquation != BlendEquation::ADD)
            stdext::hash_combine(state.hash, state.blendEquation);

        if (state.clipRect.isValid())
            stdext::hash_union(state.hash, state.clipRect.hash());

        if (state.compositionMode != CompositionMode::NORMAL)
            stdext::hash_combine(state.hash, state.compositionMode);

        if (state.opacity < 1.f)
            stdext::hash_combine(state.hash, state.opacity);

        if (state.shaderProgram)
            stdext::hash_combine(state.hash, state.shaderProgram->getProgramId());

        if (state.transformMatrix != DEFAULT_MATRIX3)
            stdext::hash_union(state.hash, state.transformMatrix.hash());

        if (state.color != Color::white)
            stdext::hash_combine(state.hash, state.color.rgba());

        if (state.texture)
            stdext::hash_union(state.hash, state.texture->hash());

        stdext::hash_union(m_status.second, state.hash);
    }

    size_t methodhash = 0;
    { // Method Hash
        if (method.type == DrawPool::DrawMethodType::TRIANGLE) {
            if (!method.a.isNull()) stdext::hash_union(methodhash, method.a.hash());
            if (!method.b.isNull()) stdext::hash_union(methodhash, method.b.hash());
            if (!method.c.isNull()) stdext::hash_union(methodhash, method.c.hash());
        } else if (method.type == DrawPool::DrawMethodType::BOUNDING_RECT) {
            if (method.intValue) stdext::hash_combine(methodhash, method.intValue);
        } else {
            if (method.dest.isValid()) stdext::hash_union(methodhash, method.dest.hash());
            if (method.src.isValid()) stdext::hash_union(methodhash, method.src.hash());
        }

        stdext::hash_union(m_status.second, methodhash);
    }

    return methodhash;
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
    if (shaderProgram) {
        m_shaderRefreshDelay = SHADER_REFRESH_DELAY;
        m_state.shaderProgram = shaderProgram.get();
        m_state.action = action;
    } else {
        m_state.shaderProgram = nullptr;
        m_state.action = nullptr;
    }

    if (onlyOnce) m_onlyOnceStateFlag |= STATE_SHADER_PROGRAM;
}

void DrawPool::resetState()
{
    resetOpacity();
    resetClipRect();
    resetShaderProgram();
    resetBlendEquation();
    resetCompositionMode();
    resetTransformMatrix();

    for (auto& objs : m_objects) {
        for (auto& order : objs)
            order.clear();
    }

    m_objectsByhash.clear();
    m_currentFloor = 0;
    m_status.second = 0;
    m_shaderRefreshDelay = 0;
}

bool DrawPool::canRepaint(const bool autoUpdateStatus)
{
    uint16_t refreshDelay = m_refreshDelay;
    if (m_shaderRefreshDelay > 0 && (m_refreshDelay == 0 || m_shaderRefreshDelay < m_refreshDelay))
        refreshDelay = m_shaderRefreshDelay;

    const bool canRepaint = m_status.first != m_status.second || refreshDelay > 0 && m_refreshTimer.ticksElapsed() >= refreshDelay;

    if (canRepaint) {
        if (static_cast<bool>(m_refreshDelay) != autoUpdateStatus)
            m_refreshTimer.restart();

        if (autoUpdateStatus)
            m_status.first = m_status.second;
    }

    return canRepaint;
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

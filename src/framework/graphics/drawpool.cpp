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

DrawPool* DrawPool::create(const DrawPoolType type)
{
    DrawPool* pool = new DrawPool;
    if (type == DrawPoolType::MAP || type == DrawPoolType::FOREGROUND) {
        pool->setFramebuffer({});

        if (type == DrawPoolType::MAP) {
            pool->m_framebuffer->m_useAlphaWriting = false;
            pool->m_framebuffer->disableBlend();
        } else if (type == DrawPoolType::FOREGROUND) {
            pool->setFPS(FPS10);

            // creates a temporary framebuffer with smoothing.
            pool->m_temporaryFramebuffers.emplace_back(std::make_shared<FrameBuffer>());
        }
    } else {
        pool->m_alwaysGroupDrawings = true; // CREATURE_INFORMATION & TEXT

        if (type == DrawPoolType::FOREGROUND_MAP) {
            pool->setFPS(FPS60);
        }
    }

    pool->m_type = type;
    return pool;
}

void DrawPool::add(const Color& color, const TexturePtr& texture, DrawPool::DrawMethod&& method,
                   DrawMode drawMode, const DrawConductor& conductor, const CoordsBufferPtr& coordsBuffer)
{
    updateHash(method, texture, color);

    uint8_t order = conductor.order;
    if (m_type == DrawPoolType::FOREGROUND)
        order = DrawOrder::FIRST;
    else if (m_type == DrawPoolType::MAP && order == DrawOrder::FIRST && !conductor.agroup)
        order = DrawOrder::THIRD;

    if (m_alwaysGroupDrawings || conductor.agroup) {
        auto& coords = m_coords.try_emplace(m_state.hash, nullptr).first->second;
        if (!coords) {
            auto state = getState(texture, color);
            coords = m_objects[order].emplace_back(std::move(state)).coords.get();
        }

        if (coordsBuffer)
            coords->append(coordsBuffer.get());
        else
            addCoords(coords, method, DrawMode::TRIANGLES);
    } else {
        bool addNewObj = true;

        auto& list = m_objects[order];
        if (!list.empty()) {
            auto& prevObj = list.back();
            if (prevObj.state == m_state) {
                if (!prevObj.coords)
                    prevObj.addMethod(std::move(method));
                else if (coordsBuffer)
                    prevObj.coords->append(coordsBuffer.get());
                else
                    addCoords(prevObj.coords.get(), method, DrawMode::TRIANGLES);

                addNewObj = false;
            }
        }

        if (addNewObj) {
            auto state = getState(texture, color);
            if (coordsBuffer) {
                list.emplace_back(std::move(state)).coords->append(coordsBuffer.get());
            } else
                list.emplace_back(drawMode, std::move(state), std::move(method));
        }
    }

    resetOnlyOnceParameters();
}

void DrawPool::addCoords(CoordsBuffer* buffer, const DrawMethod& method, DrawMode drawMode)
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

void DrawPool::updateHash(const DrawPool::DrawMethod& method, const TexturePtr& texture, const Color& color) {
    { // State Hash
        m_state.hash = 0;

        if (m_bindedFramebuffers)
            stdext::hash_combine(m_state.hash, m_lastFramebufferId);

        if (m_state.blendEquation != BlendEquation::ADD)
            stdext::hash_combine(m_state.hash, m_state.blendEquation);

        if (m_state.compositionMode != CompositionMode::NORMAL)
            stdext::hash_combine(m_state.hash, m_state.compositionMode);

        if (m_state.opacity < 1.f)
            stdext::hash_combine(m_state.hash, m_state.opacity);

        if (m_state.clipRect.isValid())
            stdext::hash_union(m_state.hash, m_state.clipRect.hash());

        if (m_state.shaderProgram)
            stdext::hash_union(m_state.hash, m_state.shaderProgram->hash());

        if (m_state.transformMatrix != DEFAULT_MATRIX3)
            stdext::hash_union(m_state.hash, m_state.transformMatrix.hash());

        if (color != Color::white)
            stdext::hash_union(m_state.hash, color.hash());

        if (texture)
            stdext::hash_union(m_state.hash, texture->hash());
    }

    if (hasFrameBuffer()) { // Pool Hash
        if (m_state.hash)
            stdext::hash_union(m_status.second, m_state.hash);

        if (method.type == DrawPool::DrawMethodType::TRIANGLE) {
            if (!method.a.isNull()) stdext::hash_union(m_status.second, method.a.hash());
            if (!method.b.isNull()) stdext::hash_union(m_status.second, method.b.hash());
            if (!method.c.isNull()) stdext::hash_union(m_status.second, method.c.hash());
        } else if (method.type == DrawPool::DrawMethodType::BOUNDING_RECT) {
            if (method.intValue) stdext::hash_combine(m_status.second, method.intValue);
        } else {
            if (method.dest.isValid()) stdext::hash_union(m_status.second, method.dest.hash());
            if (method.src.isValid()) stdext::hash_union(m_status.second, method.src.hash());
        }
    }
}

DrawPool::PoolState DrawPool::getState(const TexturePtr& texture, const Color& color)
{
    return PoolState{
       std::move(m_state.transformMatrix), m_state.opacity,
       m_state.compositionMode, m_state.blendEquation,
       std::move(m_state.clipRect), m_state.shaderProgram,
       std::move(m_state.action), std::move(const_cast<Color&>(color)), texture, m_state.hash
    };
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
    if (g_painter->isReplaceColorShader(m_state.shaderProgram))
        return;

    if (shaderProgram) {
        if (!g_painter->isReplaceColorShader(shaderProgram.get()))
            m_shaderRefreshDelay = FPS20;

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
    for (auto& objs : m_objects)
        objs.clear();
    m_objectsFlushed.clear();
    m_coords.clear();
    m_parameters.clear();

    m_state = {};
    m_status.second = 0;
    m_lastFramebufferId = 0;
    m_shaderRefreshDelay = 0;
    m_scale = PlatformWindow::DEFAULT_DISPLAY_DENSITY;
}

bool DrawPool::canRepaint(const bool autoUpdateStatus)
{
    if (!hasFrameBuffer())
        return true;

    uint16_t refreshDelay = m_refreshDelay;
    if (m_shaderRefreshDelay > 0 && (m_refreshDelay == 0 || m_shaderRefreshDelay < m_refreshDelay))
        refreshDelay = m_shaderRefreshDelay;

    const bool canRepaint = (m_status.first != m_status.second) || (refreshDelay > 0 && m_refreshTimer.ticksElapsed() >= refreshDelay);

    if (canRepaint) {
        if (static_cast<bool>(m_refreshDelay) != autoUpdateStatus)
            m_refreshTimer.restart();

        if (autoUpdateStatus)
            m_status.first = m_status.second;
    }

    return canRepaint;
}

void DrawPool::scale(float factor)
{
    if (m_scale == factor)
        return;

    m_scale = factor;
    m_state.transformMatrix = DEFAULT_MATRIX3 * Matrix3{
      factor,   0.0f,  0.0f,
        0.0f, factor,  0.0f,
        0.0f,   0.0f,  1.0f
    }.transposed();
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
    m_transformMatrixStack.emplace_back(m_state.transformMatrix);
    assert(m_transformMatrixStack.size() < 100);
}

void DrawPool::popTransformMatrix()
{
    assert(!m_transformMatrixStack.empty());
    m_state.transformMatrix = m_transformMatrixStack.back();
    m_transformMatrixStack.pop_back();
}

void DrawPool::PoolState::execute() const {
    g_painter->setColor(color);
    g_painter->setOpacity(opacity);
    g_painter->setCompositionMode(compositionMode);
    g_painter->setBlendEquation(blendEquation);
    g_painter->setClipRect(clipRect);
    g_painter->setShaderProgram(shaderProgram);
    g_painter->setTransformMatrix(transformMatrix);
    if (action) action();
    if (texture)
        g_painter->setTexture(texture->create());
}

void DrawPool::setFramebuffer(const Size& size) {
    if (!m_framebuffer) {
        m_framebuffer = std::make_shared<FrameBuffer>();
        m_framebuffer->m_isScene = true;
    }

    if (size.isValid() && m_framebuffer->resize(size)) {
        m_framebuffer->prepare({}, {});
        repaint();
    }
}

void DrawPool::removeFramebuffer() {
    m_status.first = 0;
    m_framebuffer = nullptr;
}

void DrawPool::addAction(const std::function<void()>& action)
{
    const uint8_t order = m_type == DrawPoolType::MAP ? DrawOrder::THIRD : DrawOrder::FIRST;
    m_objects[order].emplace_back(action);
}

void DrawPool::bindFrameBuffer(const Size& size, const Color& color)
{
    ++m_bindedFramebuffers;
    ++m_lastFramebufferId;

    if (color != Color::white)
        m_state.color = color;

    m_oldState = std::move(m_state);
    m_state = {};
    addAction([this, size, frameIndex = m_bindedFramebuffers, drawState = m_state] {
        drawState.execute();
        const auto& frame = getTemporaryFrameBuffer(frameIndex);
        frame->resize(size);
        frame->bind();
    });
}
void DrawPool::releaseFrameBuffer(const Rect& dest)
{
    m_state = std::move(m_oldState);
    m_oldState = {};
    addAction([this, dest, frameIndex = m_bindedFramebuffers, drawState = m_state] {
        const auto& frame = getTemporaryFrameBuffer(frameIndex);
        frame->release();
        drawState.execute();
        frame->draw(dest);
    });
    if (hasFrameBuffer() && !dest.isNull()) stdext::hash_union(m_status.second, dest.hash());
    --m_bindedFramebuffers;
}

const FrameBufferPtr& DrawPool::getTemporaryFrameBuffer(const uint8_t index) {
    if (index < m_temporaryFramebuffers.size()) {
        return m_temporaryFramebuffers[index];
    }

    const auto& tempfb = m_temporaryFramebuffers.emplace_back(std::make_shared<FrameBuffer>());
    tempfb->setSmooth(false);
    return tempfb;
}
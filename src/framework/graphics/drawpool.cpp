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

#include "drawpool.h"

DrawPool* DrawPool::create(const DrawPoolType type)
{
    auto pool = new DrawPool;
    if (type == DrawPoolType::MAP || type == DrawPoolType::FOREGROUND) {
        pool->setFramebuffer({});
        if (type == DrawPoolType::MAP) {
            pool->m_framebuffer->m_useAlphaWriting = false;
            pool->m_framebuffer->disableBlend();
        }
        else if (type == DrawPoolType::FOREGROUND) {
            pool->setFPS(10);

            // creates a temporary framebuffer with smoothing.
            pool->m_temporaryFramebuffers.emplace_back(std::make_shared<FrameBuffer>());
        }
    }
    else if (type == DrawPoolType::LIGHT) {
        pool->m_hashCtrl = true;
    }
    else {
        pool->m_alwaysGroupDrawings = true; // CREATURE_INFORMATION & TEXT
        pool->setFPS(60);
    }

    pool->m_type = type;
    return pool;
}

void DrawPool::add(const Color& color, const TexturePtr& texture, DrawMethod&& method, const DrawConductor& conductor, const CoordsBufferPtr& coordsBuffer)
{
    if (!updateHash(method, texture, color, coordsBuffer != nullptr))
        return;

    bool agroup = m_alwaysGroupDrawings || conductor.agroup;

    uint8_t order = conductor.order;
    if (m_type == DrawPoolType::FOREGROUND) {
        order = FIRST;
        agroup = false;
    }
    else if (m_type == DrawPoolType::MAP && order == FIRST && !conductor.agroup)
        order = THIRD;

    if (agroup) {
        auto& coords = m_coords.try_emplace(getCurrentState().hash, nullptr).first->second;
        if (!coords) {
            auto state = getState(texture, color);
            coords = m_objects[order].emplace_back(std::move(state), getCoordsBuffer()).coords.get();
        }

        if (coordsBuffer)
            coords->append(coordsBuffer.get());
        else
            addCoords(coords, method);
    }
    else {
        bool addNewObj = true;

        auto& list = m_objects[order];
        if (!list.empty()) {
            auto& prevObj = list.back();
            if (prevObj.state == getCurrentState()) {
                if (coordsBuffer)
                    prevObj.coords->append(coordsBuffer.get());
                else
                    addCoords(prevObj.coords.get(), method);

                addNewObj = false;
            }
        }

        if (addNewObj) {
            auto state = getState(texture, color);
            auto& draw = list.emplace_back(std::move(state), getCoordsBuffer());

            if (coordsBuffer) {
                draw.coords->append(coordsBuffer.get());
            }
            else
                addCoords(draw.coords.get(), method);
        }
    }

    resetOnlyOnceParameters();
}

void DrawPool::addCoords(CoordsBuffer* buffer, const DrawMethod& method)
{
    if (method.type == DrawMethodType::BOUNDING_RECT) {
        buffer->addBoudingRect(method.dest, method.intValue);
    }
    else if (method.type == DrawMethodType::RECT) {
        buffer->addRect(method.dest, method.src);
    }
    else if (method.type == DrawMethodType::TRIANGLE) {
        buffer->addTriangle(method.a, method.b, method.c);
    }
    else if (method.type == DrawMethodType::UPSIDEDOWN_RECT) {
        buffer->addUpsideDownRect(method.dest, method.src);
    }
    else if (method.type == DrawMethodType::REPEATED_RECT) {
        buffer->addRepeatedRects(method.dest, method.src);
    }
}

bool DrawPool::updateHash(const DrawMethod& method, const TexturePtr& texture, const Color& color, const bool hasCoord) {
    auto& state = getCurrentState();
    state.hash = 0;

    { // State Hash
        if (m_bindedFramebuffers)
            stdext::hash_combine(state.hash, m_lastFramebufferId);

        if (state.blendEquation != BlendEquation::ADD)
            stdext::hash_combine(state.hash, state.blendEquation);

        if (state.compositionMode != CompositionMode::NORMAL)
            stdext::hash_combine(state.hash, state.compositionMode);

        if (state.opacity < 1.f)
            stdext::hash_combine(state.hash, state.opacity);

        if (state.clipRect.isValid())
            stdext::hash_union(state.hash, state.clipRect.hash());

        if (state.shaderProgram)
            stdext::hash_union(state.hash, state.shaderProgram->hash());

        if (state.transformMatrix != DEFAULT_MATRIX3)
            stdext::hash_union(state.hash, state.transformMatrix.hash());

        if (color != Color::white)
            stdext::hash_union(state.hash, color.hash());

        if (texture)
            stdext::hash_union(state.hash, texture->hash());
    }

    if (hasFrameBuffer()) { // Pool Hash
        size_t hash = state.hash;

        if (method.type == DrawMethodType::TRIANGLE) {
            if (!method.a.isNull()) stdext::hash_union(hash, method.a.hash());
            if (!method.b.isNull()) stdext::hash_union(hash, method.b.hash());
            if (!method.c.isNull()) stdext::hash_union(hash, method.c.hash());
        }
        else if (method.type == DrawMethodType::BOUNDING_RECT) {
            if (method.intValue) stdext::hash_combine(hash, method.intValue);
        }
        else {
            if (method.dest.isValid()) stdext::hash_union(hash, method.dest.hash());
            if (method.src.isValid()) stdext::hash_union(hash, method.src.hash());
        }

        // check to skip the next drawing that is the same as the previous one.
        if (!hasCoord && m_hashCtrl.isLast(hash))
            return false;

        m_hashCtrl.put(hash);
    }

    return true;
}

DrawPool::PoolState DrawPool::getState(const TexturePtr& texture, const Color& color)
{
    PoolState copy = getCurrentState();
    if (copy.color != color) copy.color = color;
    if (texture) {
        if (texture->isEmpty() || !texture->isCached()) {
            copy.texture = texture;
        }
        else {
            copy.textureId = texture->getId();
            copy.textureMatrixId = texture->getTransformMatrixId();
        }
    }

    return copy;
}

void DrawPool::setCompositionMode(const CompositionMode mode, const bool onlyOnce)
{
    getCurrentState().compositionMode = mode;
    if (onlyOnce) m_onlyOnceStateFlag |= STATE_COMPOSITE_MODE;
}

void DrawPool::setBlendEquation(const BlendEquation equation, const bool onlyOnce)
{
    getCurrentState().blendEquation = equation;
    if (onlyOnce) m_onlyOnceStateFlag |= STATE_BLEND_EQUATION;
}

void DrawPool::setClipRect(const Rect& clipRect, const bool onlyOnce)
{
    getCurrentState().clipRect = clipRect;
    if (onlyOnce) m_onlyOnceStateFlag |= STATE_CLIP_RECT;
}

void DrawPool::setOpacity(const float opacity, const bool onlyOnce)
{
    getCurrentState().opacity = opacity;
    if (onlyOnce) m_onlyOnceStateFlag |= STATE_OPACITY;
}

void DrawPool::setShaderProgram(const PainterShaderProgramPtr& shaderProgram, const bool onlyOnce, const std::function<void()>& action)
{
    if (g_painter->isReplaceColorShader(getCurrentState().shaderProgram))
        return;

    if (shaderProgram) {
        if (!g_painter->isReplaceColorShader(shaderProgram.get()))
            m_shaderRefreshDelay = FPS20;

        getCurrentState().shaderProgram = shaderProgram.get();
        getCurrentState().action = action;
    }
    else {
        getCurrentState().shaderProgram = nullptr;
        getCurrentState().action = nullptr;
    }

    if (onlyOnce) m_onlyOnceStateFlag |= STATE_SHADER_PROGRAM;
}

void DrawPool::resetState()
{
    for (auto& objs : m_objects)
        objs.clear();

    m_coords.clear();
    m_parameters.clear();
    m_objectsFlushed.clear();

    m_hashCtrl.reset();

    getCurrentState() = {};
    m_lastFramebufferId = 0;
    m_shaderRefreshDelay = 0;
    m_coordsCache[0].last = 0;
    m_scale = PlatformWindow::DEFAULT_DISPLAY_DENSITY;
}

bool DrawPool::canRepaint()
{
    if (m_repaint)
        return false;

    uint16_t refreshDelay = m_refreshDelay;
    if (m_shaderRefreshDelay > 0 && (m_refreshDelay == 0 || m_shaderRefreshDelay < m_refreshDelay))
        refreshDelay = m_shaderRefreshDelay;

    const bool canRepaint = m_hashCtrl.wasModified() || (refreshDelay > 0 && m_refreshTimer.ticksElapsed() >= refreshDelay);

    return canRepaint;
}

void DrawPool::scale(const float factor)
{
    if (m_scale == factor)
        return;

    m_scale = factor;
    getCurrentState().transformMatrix = DEFAULT_MATRIX3 * Matrix3{
      factor,   0.0f,  0.0f,
        0.0f, factor,  0.0f,
        0.0f,   0.0f,  1.0f
    }.transposed();
}

void DrawPool::translate(const float x, const float y)
{
    const Matrix3 translateMatrix = {
            1.0f,  0.0f,     x,
            0.0f,  1.0f,     y,
            0.0f,  0.0f,  1.0f
    };

    getCurrentState().transformMatrix = getCurrentState().transformMatrix * translateMatrix.transposed();
}

void DrawPool::rotate(const float angle)
{
    const Matrix3 rotationMatrix = {
            std::cos(angle), -std::sin(angle),  0.0f,
            std::sin(angle),  std::cos(angle),  0.0f,
                       0.0f,             0.0f,  1.0f
    };

    getCurrentState().transformMatrix = getCurrentState().transformMatrix * rotationMatrix.transposed();
}

void DrawPool::rotate(const float x, const float y, const float angle)
{
    translate(-x, -y);
    rotate(angle);
    translate(x, y);
}

void DrawPool::pushTransformMatrix()
{
    m_transformMatrixStack.emplace_back(getCurrentState().transformMatrix);
    assert(m_transformMatrixStack.size() < 100);
}

void DrawPool::popTransformMatrix()
{
    assert(!m_transformMatrixStack.empty());
    getCurrentState().transformMatrix = m_transformMatrixStack.back();
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
    if (texture) {
        texture->create();
        g_painter->setTexture(texture->getId(), texture->getTransformMatrixId());
    }
    else
        g_painter->setTexture(textureId, textureMatrixId);
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
    m_hashCtrl.reset();
    m_framebuffer = nullptr;
}

void DrawPool::addAction(const std::function<void()>& action)
{
    const uint8_t order = m_type == DrawPoolType::MAP ? THIRD : FIRST;
    m_objects[order].emplace_back(action);
}

void DrawPool::bindFrameBuffer(const Size& size, const Color& color)
{
    ++m_bindedFramebuffers;
    ++m_lastFramebufferId;

    if (color != Color::white)
        getCurrentState().color = color;

    nextStateAndReset();

    addAction([this, size, frameIndex = m_bindedFramebuffers] {
        static const PoolState state;

        state.execute();

        const auto& frame = getTemporaryFrameBuffer(frameIndex);
        frame->resize(size);
        frame->bind();
        });
}
void DrawPool::releaseFrameBuffer(const Rect& dest)
{
    backState();

    addAction([this, dest, frameIndex = m_bindedFramebuffers, drawState = getCurrentState()] {
        const auto& frame = getTemporaryFrameBuffer(frameIndex);
        frame->release();
        drawState.execute();
        frame->draw(dest);
        });

    if (hasFrameBuffer() && !dest.isNull()) m_hashCtrl.put(dest.hash());
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

std::shared_ptr<CoordsBuffer> DrawPool::getCoordsBuffer() {
    if (++m_coordsCache[0].last > m_coordsCache[0].coords.size()) {
        return  m_coordsCache[0].coords.emplace_back(std::make_shared<CoordsBuffer>());
    }

    const auto& coords = m_coordsCache[0].coords[m_coordsCache[0].last - 1];
    coords->clear();
    return coords;
}
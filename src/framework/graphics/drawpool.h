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

#pragma once

#include <framework/core/graphicalapplication.h>
#include <framework/graphics/declarations.h>
#include <framework/graphics/framebuffer.h>
#include <framework/graphics/graphics.h>
#include <framework/graphics/pool.h>

class DrawPool
{
public:
    template <class T>
    T* get(const PoolType type) { return static_cast<T*>(m_pools[static_cast<uint8_t>(type)]); }

    void use(PoolType type);
    void use(PoolType type, const Rect& dest, const Rect& src, const Color& colorClear = Color::alpha);

    void addTexturedRect(const Rect& dest, const TexturePtr& texture, const Color& color = Color::white);
    void addTexturedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color = Color::white, const Point& originalDest = {}, const DrawBufferPtr drawQueue = nullptr);
    void addUpsideDownTexturedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color = Color::white);
    void addTexturedRepeatedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color = Color::white);
    void addFilledRect(const Rect& dest, const Color& color = Color::white);
    void addFilledTriangle(const Point& a, const Point& b, const Point& c, const Color& color = Color::white);
    void addBoundingRect(const Rect& dest, const Color& color = Color::white, int innerLineWidth = 1);
    void addAction(std::function<void()> action);

    void setOpacity(const float opacity, const int pos = -1) { m_currentPool->setOpacity(opacity, pos); }
    void setClipRect(const Rect& clipRect, const int pos = -1) { m_currentPool->setClipRect(clipRect, pos); }
    void setBlendEquation(BlendEquation equation, const int pos = -1) { m_currentPool->setBlendEquation(equation, pos); }
    void setCompositionMode(const CompositionMode mode, const int pos = -1) { m_currentPool->setCompositionMode(mode, pos); }
    void setShaderProgram(const PainterShaderProgramPtr& shaderProgram, const int pos = -1, const std::function<void()>& action = nullptr) { m_currentPool->setShaderProgram(shaderProgram, pos, action); }

    float getOpacity(const int pos = -1) { return m_currentPool->getOpacity(pos); }
    Rect getClipRect(const int pos = -1) { return m_currentPool->getClipRect(pos); }

    void resetState() { m_currentPool->resetState(); }
    void resetOpacity() { m_currentPool->resetOpacity(); }
    void resetClipRect() { m_currentPool->resetClipRect(); }
    void resetShaderProgram() { m_currentPool->resetShaderProgram(); }
    void resetCompositionMode() { m_currentPool->resetCompositionMode(); }

    void flush() { if (m_currentPool) m_currentPool->flush(); }

    size_t size() { return m_currentPool->m_objects.size(); }

private:
    void draw();
    void init();
    void terminate();
    void drawObject(const Pool::DrawObject& obj);

    CoordsBuffer m_coordsBuffer;
    std::array<Pool*, static_cast<uint8_t>(PoolType::UNKNOW) + 1> m_pools{};

    Pool* m_currentPool{ nullptr };

    Size m_size;
    Matrix3 m_transformMatrix;

    friend class GraphicalApplication;
};

extern DrawPool g_drawPool;

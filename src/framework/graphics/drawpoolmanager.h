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
#include <framework/graphics/drawpool.h>

class DrawPoolManager
{
public:
    template <class T>
    T* get(const DrawPoolType type) { return static_cast<T*>(m_pools[static_cast<uint8_t>(type)]); }

    void optimize(int size);

    void select(DrawPoolType type) { m_currentPool = get<DrawPool>(type); }
    void use(DrawPoolType type);
    void use(DrawPoolType type, const Rect& dest, const Rect& src, const Color& colorClear = Color::alpha);

    void addTexturedRect(const Rect& dest, const TexturePtr& texture, const Color& color = Color::white);
    void addTexturedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color = Color::white, const Point& originalDest = {}, const DrawBufferPtr& buffer = nullptr);
    void addTexturedCoordsBuffer(const TexturePtr& texture, const CoordsBufferPtr& coords, const Color& color = Color::white);
    void addUpsideDownTexturedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color = Color::white);
    void addTexturedRepeatedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color = Color::white);
    void addFilledRect(const Rect& dest, const Color& color = Color::white, const DrawBufferPtr& buffer = nullptr);
    void addFilledTriangle(const Point& a, const Point& b, const Point& c, const Color& color = Color::white);
    void addBoundingRect(const Rect& dest, const Color& color = Color::white, int innerLineWidth = 1);
    void addAction(std::function<void()> action);

    void setOpacity(const float opacity, bool onLastDrawing = false) { m_currentPool->setOpacity(opacity, onLastDrawing); }
    void setClipRect(const Rect& clipRect, bool onLastDrawing = false) { m_currentPool->setClipRect(clipRect, onLastDrawing); }
    void setBlendEquation(BlendEquation equation, bool onLastDrawing = false) { m_currentPool->setBlendEquation(equation, onLastDrawing); }
    void setCompositionMode(const CompositionMode mode, bool onLastDrawing = false) { m_currentPool->setCompositionMode(mode, onLastDrawing); }
    void setShaderProgram(const PainterShaderProgramPtr& shaderProgram, bool onLastDrawing = false, const std::function<void()>& action = nullptr) { m_currentPool->setShaderProgram(shaderProgram, onLastDrawing, action); }

    float getOpacity(bool onLastDrawing = false) { return m_currentPool->getOpacity(onLastDrawing); }
    Rect getClipRect(bool onLastDrawing = false) { return m_currentPool->getClipRect(onLastDrawing); }

    void resetState() { m_currentPool->resetState(); }
    void resetOpacity() { m_currentPool->resetOpacity(); }
    void resetClipRect() { m_currentPool->resetClipRect(); }
    void resetShaderProgram() { m_currentPool->resetShaderProgram(); }
    void resetCompositionMode() { m_currentPool->resetCompositionMode(); }

    void flush() { if (m_currentPool) m_currentPool->flush(); }

    DrawPoolType getCurrentType() const { return m_currentPool->m_type; }

private:
    void draw();
    void init();
    void terminate();
    void drawObject(const DrawPool::DrawObject& obj);

    CoordsBuffer m_coordsBuffer;
    std::array<DrawPool*, static_cast<uint8_t>(DrawPoolType::UNKNOW) + 1> m_pools{};

    DrawPool* m_currentPool{ nullptr };

    Size m_size;
    Matrix3 m_transformMatrix;

    friend class GraphicalApplication;
};

extern DrawPoolManager g_drawPool;

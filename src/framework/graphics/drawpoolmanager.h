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

    void select(DrawPoolType type);
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

    void setOpacity(const float opacity, bool onlyOnce = false) { getCurrentPool()->setOpacity(opacity, onlyOnce); }
    void setClipRect(const Rect& clipRect, bool onlyOnce = false) { getCurrentPool()->setClipRect(clipRect, onlyOnce); }
    void setBlendEquation(BlendEquation equation, bool onlyOnce = false) { getCurrentPool()->setBlendEquation(equation, onlyOnce); }
    void setCompositionMode(const CompositionMode mode, bool onlyOnce = false) { getCurrentPool()->setCompositionMode(mode, onlyOnce); }
    void setShaderProgram(const PainterShaderProgramPtr& shaderProgram, bool onlyOnce = false, const std::function<void()>& action = nullptr) { getCurrentPool()->setShaderProgram(shaderProgram, onlyOnce, action); }

    float getOpacity() { return getCurrentPool()->getOpacity(); }
    Rect getClipRect() { return getCurrentPool()->getClipRect(); }

    void resetState() { getCurrentPool()->resetState(); }
    void resetOpacity() { getCurrentPool()->resetOpacity(); }
    void resetClipRect() { getCurrentPool()->resetClipRect(); }
    void resetShaderProgram() { getCurrentPool()->resetShaderProgram(); }
    void resetCompositionMode() { getCurrentPool()->resetCompositionMode(); }

    void pushTransformMatrix() { getCurrentPool()->pushTransformMatrix(); }
    void popTransformMatrix() { getCurrentPool()->popTransformMatrix(); }
    void scale(float x, float y) { getCurrentPool()->scale(x, y); }
    void scale(float factor) { getCurrentPool()->scale(factor); }
    void translate(float x, float y) { getCurrentPool()->translate(x, y); }
    void translate(const Point& p) { getCurrentPool()->translate(p); }
    void rotate(float angle) { getCurrentPool()->rotate(angle); }
    void rotate(float x, float y, float angle) { getCurrentPool()->rotate(x, y, angle); }
    void rotate(const Point& p, float angle) { getCurrentPool()->rotate(p, angle); }

    void setScaleFactor(float scale) { getCurrentPool()->setScaleFactor(scale); }
    inline float getScaleFactor() { return getCurrentPool()->getScaleFactor(); }

    void flush() { if (getCurrentPool()) getCurrentPool()->flush(); }

    DrawPoolType getCurrentType() { return getCurrentPool()->m_type; }

private:
    DrawPool* getCurrentPool();

    void draw();
    void init();
    void terminate();
    void drawObject(const DrawPool::DrawObject& obj);

    CoordsBuffer m_coordsBuffer;
    std::array<DrawPool*, static_cast<uint8_t>(DrawPoolType::UNKNOW) + 1> m_pools{};

    Size m_size;
    Matrix3 m_transformMatrix;

    friend class GraphicalApplication;
};

extern DrawPoolManager g_drawPool;

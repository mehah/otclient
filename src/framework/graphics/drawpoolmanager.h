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
#include <framework/graphics/drawpool.h>
#include <framework/graphics/framebuffer.h>
#include <framework/graphics/graphics.h>

class DrawPoolManager
{
public:
    DrawPool* get(const DrawPoolType type) const { return m_pools[static_cast<uint8_t>(type)]; }

    void select(DrawPoolType type);
    void use(const DrawPoolType type) { use(type, {}, {}); }
    void use(DrawPoolType type, const Rect& dest, const Rect& src, const Color& colorClear = Color::alpha);

    void addTexturedPoint(const TexturePtr& texture, const Point& point, const Color& color = Color::white) const
    { addTexturedRect(Rect(point, texture->getSize()), texture, color); }

    void addTexturedPos(const TexturePtr& texture, int x, int y, const Color& color = Color::white) const
    { addTexturedRect(Rect(x, y, texture->getSize()), texture, color); }

    void addTexturedRect(const Rect& dest, const TexturePtr& texture, const Color& color = Color::white) const
    { addTexturedRect(dest, texture, Rect(Point(), texture->getSize()), color); }

    void addTexturedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color = Color::white, const DrawConductor& condutor = DEFAULT_DRAW_CONDUCTOR) const;
    void addTexturedCoordsBuffer(const TexturePtr& texture, const CoordsBufferPtr& coords, const Color& color = Color::white) const;
    void addUpsideDownTexturedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color = Color::white) const;
    void addTexturedRepeatedRect(const Rect& dest, const TexturePtr& texture, const Rect& src, const Color& color = Color::white) const;
    void addFilledRect(const Rect& dest, const Color& color = Color::white, const DrawConductor& condutor = DEFAULT_DRAW_CONDUCTOR) const;
    void addFilledTriangle(const Point& a, const Point& b, const Point& c, const Color& color = Color::white) const;
    void addBoundingRect(const Rect& dest, const Color& color = Color::white, uint16_t innerLineWidth = 1) const;
    void addAction(const std::function<void()>& action) const;

    void bindFrameBuffer(const Size& size) const;
    void releaseFrameBuffer(const Rect& dest) const;

    void setOpacity(const float opacity, bool onlyOnce = false) const { getCurrentPool()->setOpacity(opacity, onlyOnce); }
    void setClipRect(const Rect& clipRect, bool onlyOnce = false) const { getCurrentPool()->setClipRect(clipRect, onlyOnce); }
    void setBlendEquation(BlendEquation equation, bool onlyOnce = false) const { getCurrentPool()->setBlendEquation(equation, onlyOnce); }
    void setCompositionMode(const CompositionMode mode, bool onlyOnce = false) const { getCurrentPool()->setCompositionMode(mode, onlyOnce); }

    void setShaderProgram(const PainterShaderProgramPtr& shaderProgram, const std::function<void()>& action) const { getCurrentPool()->setShaderProgram(shaderProgram, false, action); }
    void setShaderProgram(const PainterShaderProgramPtr& shaderProgram, bool onlyOnce = false, const std::function<void()>& action = nullptr) const { getCurrentPool()->setShaderProgram(shaderProgram, onlyOnce, action); }

    float getOpacity() const { return getCurrentPool()->getOpacity(); }
    Rect getClipRect() const { return getCurrentPool()->getClipRect(); }

    void resetState() const { getCurrentPool()->resetState(); }
    void resetOpacity() const { getCurrentPool()->resetOpacity(); }
    void resetClipRect() const { getCurrentPool()->resetClipRect(); }
    void resetShaderProgram() const { getCurrentPool()->resetShaderProgram(); }
    void resetCompositionMode() const { getCurrentPool()->resetCompositionMode(); }

    void pushTransformMatrix() const { getCurrentPool()->pushTransformMatrix(); }
    void popTransformMatrix() const { getCurrentPool()->popTransformMatrix(); }
    void scale(float factor) const { getCurrentPool()->scale(factor); }
    void translate(float x, float y) const { getCurrentPool()->translate(x, y); }
    void translate(const Point& p) const { getCurrentPool()->translate(p); }
    void rotate(float angle) const { getCurrentPool()->rotate(angle); }
    void rotate(float x, float y, float angle) const { getCurrentPool()->rotate(x, y, angle); }
    void rotate(const Point& p, float angle) const { getCurrentPool()->rotate(p, angle); }

    void setScaleFactor(float scale) const { getCurrentPool()->setScaleFactor(scale); }
    inline float getScaleFactor() const { return getCurrentPool()->getScaleFactor(); }
    inline bool isScaled() const { return getCurrentPool()->isScaled(); }
    inline uint16_t getScaledSpriteSize() const { return m_spriteSize * getScaleFactor(); }

    void flush() const { if (getCurrentPool()) getCurrentPool()->flush(); }

    DrawPoolType getCurrentType() const { return getCurrentPool()->m_type; }

private:
    DrawPool* getCurrentPool() const;

    void draw();
    void init(uint16_t spriteSize);
    void terminate() const;
    void drawObject(const DrawPool::DrawObject& obj);

    bool drawPool(const auto& pool);

    CoordsBuffer m_coordsBuffer;
    std::array<DrawPool*, static_cast<uint8_t>(DrawPoolType::UNKNOW) + 1> m_pools{};

    Size m_size;
    Matrix3 m_transformMatrix;

    uint16_t m_spriteSize{ 32 };

    friend class GraphicalApplication;
};

extern DrawPoolManager g_drawPool;

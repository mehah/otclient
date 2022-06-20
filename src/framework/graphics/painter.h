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

#include <framework/graphics/coordsbuffer.h>
#include <framework/graphics/declarations.h>
#include <framework/graphics/paintershaderprogram.h>

enum class BlendEquation
{
    ADD,
    MAX,
    MIN,
    SUBTRACT,
    REVER_SUBTRACT,
};

enum class CompositionMode
{
    NORMAL,
    MULTIPLY,
    ADD,
    REPLACE,
    DESTINATION_BLENDING,
    LIGHT
};

enum class DrawMode
{
    NONE = GL_NONE,
    TRIANGLES = GL_TRIANGLES,
    TRIANGLE_STRIP = GL_TRIANGLE_STRIP
};

class Painter
{
public:
    Painter();

    virtual ~Painter() = default;

    virtual void bind() {}
    virtual void unbind() {}

    virtual void clear(const Color& color) = 0;

    virtual void drawCoords(CoordsBuffer& coordsBuffer, DrawMode drawMode = DrawMode::TRIANGLES) = 0;

    virtual void setTexture(Texture* texture) = 0;
    virtual void setClipRect(const Rect& clipRect) = 0;
    virtual void setColor(const Color& color) { m_color = color; }
    virtual void setAlphaWriting(bool enable) = 0;
    virtual void setBlendEquation(BlendEquation blendEquation) = 0;
    virtual void setCompositionMode(CompositionMode compositionMode) = 0;
    virtual void setTransformMatrix(const Matrix3& transformMatrix) = 0;
    virtual void setShaderProgram(PainterShaderProgram* shaderProgram) { m_shaderProgram = shaderProgram; }

    void setShaderProgram(const PainterShaderProgramPtr& shaderProgram) { setShaderProgram(shaderProgram.get()); }

    virtual void scale(float x, float y) = 0;
    void scale(float factor) { scale(factor, factor); }
    virtual void translate(float x, float y) = 0;
    void translate(const Point& p) { translate(p.x, p.y); }
    virtual void rotate(float angle) = 0;
    virtual void rotate(float x, float y, float angle) = 0;
    void rotate(const Point& p, float angle) { rotate(p.x, p.y, angle); }

    virtual void setOpacity(float opacity) { m_opacity = opacity; }
    virtual void setResolution(const Size& resolution, const Matrix3& matrix = {}) { m_resolution = resolution; }

    virtual Matrix3 getTransformMatrix(const Size& size) = 0;
    virtual Matrix3 getTransformMatrix() = 0;
    virtual Matrix3 getProjectionMatrix() = 0;
    virtual Matrix3 getTextureMatrix() = 0;

    virtual void pushTransformMatrix() = 0;
    virtual void popTransformMatrix() = 0;

    virtual void resetState() = 0;
    virtual bool hasShaders() = 0;

    Color getColor() { return m_color; }
    float getOpacity() { return m_opacity; }
    Rect getClipRect() { return m_clipRect; }
    Size getResolution() { return m_resolution; }
    CompositionMode getCompositionMode() { return m_compositionMode; }

    void resetClipRect() { setClipRect({}); }
    void resetOpacity() { setOpacity(1.f); }
    void resetCompositionMode() { setCompositionMode(CompositionMode::NORMAL); }
    void resetColor() { setColor(Color::white); }
    void resetShaderProgram() { setShaderProgram(nullptr); }

protected:
    float m_opacity{ 1.f };

    PainterShaderProgram* m_shaderProgram{ nullptr };
    CompositionMode m_compositionMode{ CompositionMode::NORMAL };
    Color m_color{ Color::white };
    Size m_resolution;
    Rect m_clipRect;

    friend class DrawPool;
    friend class Pool;
};

extern Painter* g_painter;

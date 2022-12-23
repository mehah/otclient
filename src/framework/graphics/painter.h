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

    ~Painter() = default;

    void bind();
    void unbind();

    void clear(const Color& color);
    void clearRect(const Color& color, const Rect& rect);

    void drawCoords(CoordsBuffer& coordsBuffer, DrawMode drawMode = DrawMode::TRIANGLES);

    float getOpacity() { return m_opacity; }
    bool getAlphaWriting() { return m_alphaWriting; }

    Matrix3 getTextureMatrix() { return m_textureMatrix; }
    Matrix3 getTransformMatrix(const Size& size);
    Matrix3 getTransformMatrix() { return m_transformMatrix; }
    Matrix3 getProjectionMatrix() { return m_projectionMatrix; }

    Color getColor() { return m_color; }
    Rect getClipRect() { return m_clipRect; }
    Size getResolution() { return m_resolution; }
    BlendEquation getBlendEquation() { return m_blendEquation; }
    CompositionMode getCompositionMode() { return m_compositionMode; }
    PainterShaderProgram* getShaderProgram() { return m_shaderProgram; }

    void setColor(const Color& color) { m_color = color; }
    void setTexture(Texture* texture);
    void setOpacity(float opacity) { m_opacity = opacity; }
    void setClipRect(const Rect& clipRect);
    void setResolution(const Size& resolution, const Matrix3& matrix = {});
    void setDrawProgram(PainterShaderProgram* drawProgram) { m_drawProgram = drawProgram; }
    void setAlphaWriting(bool enable);
    void setBlendEquation(BlendEquation blendEquation);
    void setShaderProgram(PainterShaderProgram* shaderProgram) { m_shaderProgram = shaderProgram; }
    void setShaderProgram(const PainterShaderProgramPtr& shaderProgram) { setShaderProgram(shaderProgram.get()); }
    void setCompositionMode(CompositionMode compositionMode);

    void setTextureMatrix(const Matrix3& textureMatrix) { m_textureMatrix = textureMatrix; }
    void setTransformMatrix(const Matrix3& transformMatrix) { m_transformMatrix = transformMatrix; }
    void setProjectionMatrix(const Matrix3& projectionMatrix) { m_projectionMatrix = projectionMatrix; }

    void resetState();
    void resetBlendEquation() { setBlendEquation(BlendEquation::ADD); }
    void resetTexture() { setTexture(nullptr); }
    void resetAlphaWriting() { setAlphaWriting(false); }
    void resetClipRect() { setClipRect({}); }
    void resetOpacity() { setOpacity(1.f); }
    void resetCompositionMode() { setCompositionMode(CompositionMode::NORMAL); }
    void resetColor() { setColor(Color::white); }
    void resetShaderProgram() { setShaderProgram(nullptr); }
    void resetTransformMatrix() { setTransformMatrix(DEFAULT_MATRIX3); }

protected:
    void refreshState();
    void updateGlTexture();
    void updateGlCompositionMode();
    void updateGlBlendEquation();
    void updateGlClipRect();
    void updateGlAlphaWriting();
    void updateGlViewport();

    Matrix3 m_transformMatrix;
    Matrix3 m_projectionMatrix;
    Matrix3 m_textureMatrix;

    BlendEquation m_blendEquation{ BlendEquation::ADD };
    Texture* m_texture{ nullptr };
    bool m_alphaWriting{ false };
    uint32_t m_glTextureId{ 0 };

    float m_opacity{ 1.f };

    PainterShaderProgram* m_shaderProgram{ nullptr };
    CompositionMode m_compositionMode{ CompositionMode::NORMAL };
    Color m_color{ Color::white };
    Size m_resolution;
    Rect m_clipRect;

    friend class FrameBuffer;
    friend class DrawPoolManager;
    friend class DrawPool;

    PainterShaderProgram* m_drawProgram{ nullptr };
    PainterShaderProgramPtr m_drawTexturedProgram;
    PainterShaderProgramPtr m_drawSolidColorProgram;
};

extern Painter* g_painter;

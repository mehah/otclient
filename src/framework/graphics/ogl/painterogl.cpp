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

#include "painterogl.h"
#include <framework/graphics/graphics.h>
#include <framework/platform/platformwindow.h>

#include "framework/graphics/texture.h"

PainterOGL::PainterOGL()
{
    setResolution(g_window.getSize());
}

void PainterOGL::resetState()
{
    resetColor();
    resetOpacity();
    resetCompositionMode();
    resetBlendEquation();
    resetClipRect();
    resetShaderProgram();
    resetAlphaWriting();
    resetTransformMatrix();
}

void PainterOGL::refreshState()
{
    updateGlViewport();
    updateGlCompositionMode();
    updateGlBlendEquation();
    updateGlClipRect();
    updateGlTexture();
    updateGlAlphaWriting();
}

void PainterOGL::clear(const Color& color)
{
    glClearColor(color.rF(), color.gF(), color.bF(), color.aF());
    glClear(GL_COLOR_BUFFER_BIT);
}

void PainterOGL::clearRect(const Color& color, const Rect& rect)
{
    const Rect oldClipRect = m_clipRect;
    setClipRect(rect);
    glClearColor(color.rF(), color.gF(), color.bF(), color.aF());
    glClear(GL_COLOR_BUFFER_BIT);
    setClipRect(oldClipRect);
}

void PainterOGL::setCompositionMode(CompositionMode compositionMode)
{
    if (m_compositionMode == compositionMode)
        return;
    m_compositionMode = compositionMode;

    updateGlCompositionMode();
}

void PainterOGL::setBlendEquation(BlendEquation blendEquation)
{
    if (m_blendEquation == blendEquation)
        return;
    m_blendEquation = blendEquation;

    updateGlBlendEquation();
}

void PainterOGL::setClipRect(const Rect& clipRect)
{
    if (m_clipRect == clipRect)
        return;
    m_clipRect = clipRect;

    updateGlClipRect();
}

void PainterOGL::setTexture(Texture* texture)
{
    if (m_texture == texture)
        return;

    m_texture = texture;

    if (!m_texture) {
        m_glTextureId = 0;
        return;
    }

    setTextureMatrix(texture->getTransformMatrix());
    m_glTextureId = texture->getId();
    updateGlTexture();
}

void PainterOGL::setAlphaWriting(bool enable)
{
    if (m_alphaWriting == enable)
        return;

    m_alphaWriting = enable;
    updateGlAlphaWriting();
}

void PainterOGL::setResolution(const Size& resolution, const Matrix3& projectionMatrix)
{
    if (resolution == m_resolution)
        return;

    setProjectionMatrix(projectionMatrix == DEFAULT_MATRIX3 ? getTransformMatrix(resolution) : projectionMatrix);

    m_resolution = resolution;
    if (g_painter == this)
        updateGlViewport();
}

Matrix3 PainterOGL::getTransformMatrix(const Size& resolution)
{
    // The projection matrix converts from Painter's coordinate system to GL's coordinate system
    //    * GL's viewport is 2x2, Painter's is width x height
    //    * GL has +y -> -y going from bottom -> top, Painter is the other way round
    //    * GL has [0,0] in the center, Painter has it in the top-left
    //
    // This results in the Projection matrix below.
    //
    //                                    Projection Matrix
    //   Painter Coord     ------------------------------------------------        GL Coord
    //   -------------     | 2.0 / width  |      0.0      |      0.0      |     ---------------
    //   |  x  y  1  |  *  |     0.0      | -2.0 / height |      0.0      |  =  |  x'  y'  1  |
    //   -------------     |    -1.0      |      1.0      |      1.0      |     ---------------

    return { 2.0f / resolution.width(),  0.0f,                       0.0f,
                                  0.0f, -2.0f / resolution.height(), 0.0f,
                                 -1.0f,  1.0f,                       1.0f };
}

void PainterOGL::scale(float x, float y)
{
    const Matrix3 scaleMatrix = {
              x,   0.0f,  0.0f,
            0.0f,     y,  0.0f,
            0.0f,  0.0f,  1.0f
    };

    setTransformMatrix(m_transformMatrix * scaleMatrix.transposed());
}

void PainterOGL::translate(float x, float y)
{
    const Matrix3 translateMatrix = {
            1.0f,  0.0f,     x,
            0.0f,  1.0f,     y,
            0.0f,  0.0f,  1.0f
    };

    setTransformMatrix(m_transformMatrix * translateMatrix.transposed());
}

void PainterOGL::rotate(float angle)
{
    const Matrix3 rotationMatrix = {
            std::cos(angle), -std::sin(angle),  0.0f,
            std::sin(angle),  std::cos(angle),  0.0f,
                                 0.0f,             0.0f,  1.0f
    };

    setTransformMatrix(m_transformMatrix * rotationMatrix.transposed());
}

void PainterOGL::rotate(float x, float y, float angle)
{
    translate(-x, -y);
    rotate(angle);
    translate(x, y);
}

void PainterOGL::pushTransformMatrix()
{
    m_transformMatrixStack.push_back(m_transformMatrix);
    assert(m_transformMatrixStack.size() < 100);
}

void PainterOGL::popTransformMatrix()
{
    assert(!m_transformMatrixStack.empty());
    setTransformMatrix(m_transformMatrixStack.back());
    m_transformMatrixStack.pop_back();
}

void PainterOGL::updateGlTexture()
{
    if (m_glTextureId != 0)
        glBindTexture(GL_TEXTURE_2D, m_glTextureId);
}

void PainterOGL::updateGlCompositionMode()
{
    switch (m_compositionMode) {
        case CompositionMode::NORMAL:
            if (g_graphics.canUseBlendFuncSeparate())
                glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE);
            else
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            break;
        case CompositionMode::MULTIPLY:
            glBlendFunc(GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA);
            break;
        case CompositionMode::ADD:
            glBlendFunc(GL_ONE_MINUS_SRC_COLOR, GL_ONE_MINUS_SRC_COLOR);
            break;
        case CompositionMode::REPLACE:
            glBlendFunc(GL_ONE, GL_ZERO);
            break;
        case CompositionMode::DESTINATION_BLENDING:
            glBlendFunc(GL_ONE_MINUS_DST_ALPHA, GL_DST_ALPHA);
            break;
        case CompositionMode::LIGHT:
            glBlendFunc(GL_ZERO, GL_SRC_COLOR);
            break;
    }
}

void PainterOGL::updateGlBlendEquation()
{
    if (!g_graphics.canUseBlendEquation())
        return;
    if (m_blendEquation == BlendEquation::ADD)
        glBlendEquation(GL_FUNC_ADD);
    else if (m_blendEquation == BlendEquation::MAX)
        glBlendEquation(GL_MAX);
    else if (m_blendEquation == BlendEquation::MIN)
        glBlendEquation(GL_MIN);
    else if (m_blendEquation == BlendEquation::SUBTRACT)
        glBlendEquation(GL_FUNC_SUBTRACT);
    else if (m_blendEquation == BlendEquation::REVER_SUBTRACT)
        glBlendEquation(GL_FUNC_REVERSE_SUBTRACT);
}

void PainterOGL::updateGlClipRect()
{
    if (m_clipRect.isValid()) {
        glEnable(GL_SCISSOR_TEST);
        glScissor(m_clipRect.left(), m_resolution.height() - m_clipRect.bottom() - 1, m_clipRect.width(), m_clipRect.height());
    } else {
        glScissor(0, 0, m_resolution.width(), m_resolution.height());
        glDisable(GL_SCISSOR_TEST);
    }
}

void PainterOGL::updateGlAlphaWriting()
{
    glColorMask(1, 1, 1, m_alphaWriting);
}

void PainterOGL::updateGlViewport()
{
    glViewport(0, 0, m_resolution.width(), m_resolution.height());
}

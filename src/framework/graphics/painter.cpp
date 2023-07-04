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

#include "painter.h"

#include <framework/platform/platformwindow.h>
#include "framework/graphics/texture.h"

#include "shader/shadersources.h"

Painter* g_painter = nullptr;

/**
   * Painter using OpenGL 2.0 programmable rendering pipeline,
   * compatible with OpenGL ES 2.0. Only recent cards support
   * this painter engine.
   */
Painter::Painter()
{
    setResolution(g_window.getSize());

    m_drawTexturedProgram = std::make_shared<PainterShaderProgram>();
    assert(m_drawTexturedProgram);
    m_drawTexturedProgram->addShaderFromSourceCode(ShaderType::VERTEX, std::string{ glslMainWithTexCoordsVertexShader } + glslPositionOnlyVertexShader.data());
    m_drawTexturedProgram->addShaderFromSourceCode(ShaderType::FRAGMENT, std::string{ glslMainFragmentShader } + glslTextureSrcFragmentShader.data());
    m_drawTexturedProgram->link();

    m_drawSolidColorProgram = std::make_shared<PainterShaderProgram>();
    assert(m_drawSolidColorProgram);
    m_drawSolidColorProgram->addShaderFromSourceCode(ShaderType::VERTEX, std::string{ glslMainVertexShader } + glslPositionOnlyVertexShader.data());
    m_drawSolidColorProgram->addShaderFromSourceCode(ShaderType::FRAGMENT, std::string{ glslMainFragmentShader } + glslSolidColorFragmentShader.data());
    m_drawSolidColorProgram->link();

    m_drawReplaceColorProgram = std::make_shared<PainterShaderProgram>();
    assert(m_drawReplaceColorProgram);
    m_drawReplaceColorProgram->addShaderFromSourceCode(ShaderType::VERTEX, std::string{ glslMainWithTexCoordsVertexShader } + glslPositionOnlyVertexShader.data());
    m_drawReplaceColorProgram->addShaderFromSourceCode(ShaderType::FRAGMENT, std::string{ glslMainFragmentShader } + glslReplaceColorFragmentShader.data());
    m_drawReplaceColorProgram->link();

    PainterShaderProgram::release();

    refreshState();

    // vertex and texture coord attributes are always enabled
    // to avoid massive enable/disables, thus improving frame rate
    PainterShaderProgram::enableAttributeArray(PainterShaderProgram::VERTEX_ATTR);
    PainterShaderProgram::enableAttributeArray(PainterShaderProgram::TEXCOORD_ATTR);
}

void Painter::drawCoords(CoordsBuffer& coordsBuffer, DrawMode drawMode)
{
    const int vertexCount = coordsBuffer.getVertexCount();
    if (vertexCount == 0)
        return;

    const bool textured = coordsBuffer.getTextureCoordCount() > 0 && m_texture;

    // skip drawing of empty textures
    if (textured && m_texture->isEmpty())
        return;

    m_drawProgram = m_shaderProgram ? m_shaderProgram : textured ? m_drawTexturedProgram.get() : m_drawSolidColorProgram.get();

    // update shader with the current painter state
    m_drawProgram->bind();
    m_drawProgram->setTransformMatrix(m_transformMatrix);
    m_drawProgram->setProjectionMatrix(m_projectionMatrix);
    m_drawProgram->setOpacity(m_opacity);
    m_drawProgram->setColor(m_color);
    m_drawProgram->setResolution(m_resolution);
    m_drawProgram->updateTime();

    coordsBuffer.cache(); // Try to cache

    // only set texture coords arrays when needed
    {
        if (textured) {
            m_drawProgram->setTextureMatrix(m_textureMatrix);
            m_drawProgram->bindMultiTextures();

            const auto* hardwareBuffer = coordsBuffer.getHardwareTextureCoordCache();
            if (hardwareBuffer)
                hardwareBuffer->bind();

            m_drawProgram->setAttributeArray(PainterShaderProgram::TEXCOORD_ATTR, hardwareBuffer ? nullptr : coordsBuffer.getTextureCoordArray(), 2);
        } else
            PainterShaderProgram::disableAttributeArray(PainterShaderProgram::TEXCOORD_ATTR);
    }

    // set vertex array
    {
        const auto* hardwareBuffer = coordsBuffer.getHardwareVertexCache();
        if (hardwareBuffer)
            hardwareBuffer->bind();

        m_drawProgram->setAttributeArray(PainterShaderProgram::VERTEX_ATTR, hardwareBuffer ? nullptr : coordsBuffer.getVertexArray(), 2);
    }

    if (coordsBuffer.isCached())
        HardwareBuffer::unbind(HardwareBuffer::Type::VERTEX_BUFFER);

    // draw the element in coords buffers
    glDrawArrays(static_cast<GLenum>(drawMode), 0, vertexCount);

    if (!textured)
        PainterShaderProgram::enableAttributeArray(PainterShaderProgram::TEXCOORD_ATTR);
}

void Painter::resetState()
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

void Painter::refreshState() const {
    updateGlViewport();
    updateGlCompositionMode();
    updateGlBlendEquation();
    updateGlClipRect();
    updateGlTexture();
    updateGlAlphaWriting();
}

void Painter::clear(const Color& color)
{
    glClearColor(color.rF(), color.gF(), color.bF(), color.aF());
    glClear(GL_COLOR_BUFFER_BIT);
}

void Painter::clearRect(const Color& color, const Rect& rect)
{
    const auto& oldClipRect = m_clipRect;
    setClipRect(rect);
    glClearColor(color.rF(), color.gF(), color.bF(), color.aF());
    glClear(GL_COLOR_BUFFER_BIT);
    setClipRect(oldClipRect);
}

void Painter::setCompositionMode(CompositionMode compositionMode)
{
    if (m_compositionMode == compositionMode)
        return;

    m_compositionMode = compositionMode;
    updateGlCompositionMode();
}

void Painter::setBlendEquation(BlendEquation blendEquation)
{
    if (m_blendEquation == blendEquation)
        return;

    m_blendEquation = blendEquation;
    updateGlBlendEquation();
}

void Painter::setClipRect(const Rect& clipRect)
{
    if (m_clipRect == clipRect)
        return;

    m_clipRect = clipRect;
    updateGlClipRect();
}

void Painter::setTexture(Texture* texture)
{
    if (m_texture == texture)
        return;

    if (!(m_texture = texture)) {
        m_glTextureId = 0;
        return;
    }

    setTextureMatrix(texture->getTransformMatrix());
    m_glTextureId = texture->getId();
    updateGlTexture();
}

void Painter::setAlphaWriting(bool enable)
{
    if (m_alphaWriting == enable)
        return;

    m_alphaWriting = enable;
    updateGlAlphaWriting();
}

void Painter::setResolution(const Size& resolution, const Matrix3& projectionMatrix)
{
    if (resolution == m_resolution)
        return;

    setProjectionMatrix(projectionMatrix == DEFAULT_MATRIX3 ? getTransformMatrix(resolution) : projectionMatrix);

    m_resolution = resolution;
    updateGlViewport();
}

Matrix3 Painter::getTransformMatrix(const Size& resolution) const
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

void Painter::updateGlCompositionMode() const
{
    switch (m_compositionMode) {
        case CompositionMode::NORMAL:
            glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE);
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

void Painter::updateGlClipRect() const
{
    if (m_clipRect.isValid()) {
        glEnable(GL_SCISSOR_TEST);
        glScissor(m_clipRect.left(), m_resolution.height() - m_clipRect.bottom() - 1, m_clipRect.width(), m_clipRect.height());
    } else {
        glScissor(0, 0, m_resolution.width(), m_resolution.height());
        glDisable(GL_SCISSOR_TEST);
    }
}
void Painter::updateGlTexture() const { if (m_glTextureId != 0) glBindTexture(GL_TEXTURE_2D, m_glTextureId); }
void Painter::updateGlBlendEquation() const { glBlendEquation(static_cast<GLenum>(m_blendEquation)); }
void Painter::updateGlAlphaWriting() const { glColorMask(1, 1, 1, m_alphaWriting); }
void Painter::updateGlViewport() const { glViewport(0, 0, m_resolution.width(), m_resolution.height()); }
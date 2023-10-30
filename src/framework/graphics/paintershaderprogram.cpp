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

#include "paintershaderprogram.h"
#include <framework/core/clock.h>
#include <framework/platform/platformwindow.h>
#include "texture.h"
#include "texturemanager.h"

PainterShaderProgram::PainterShaderProgram() : ShaderProgram()
{
    m_startTime = g_clock.seconds();
    m_depth = 0;
    m_color = Color::white;
    m_time = 0;
}

void PainterShaderProgram::setupUniforms()
{
    bindUniformLocation(TRANSFORM_MATRIX_UNIFORM, "u_TransformMatrix");
    bindUniformLocation(PROJECTION_MATRIX_UNIFORM, "u_ProjectionMatrix");
    bindUniformLocation(TEXTURE_MATRIX_UNIFORM, "u_TextureMatrix");

    bindUniformLocation(COLOR_UNIFORM, "u_Color");
    bindUniformLocation(OPACITY_UNIFORM, "u_Opacity");
    bindUniformLocation(DEPTH_UNIFORM, "u_Depth");
    bindUniformLocation(TIME_UNIFORM, "u_Time");


    bindUniformLocation(TEX0_UNIFORM, "u_Tex0");
    bindUniformLocation(TEX1_UNIFORM, "u_Tex1");
    bindUniformLocation(TEX2_UNIFORM, "u_Tex2");
    bindUniformLocation(TEX3_UNIFORM, "u_Tex3");

    bindUniformLocation(ATLAS_TEX0_UNIFORM, "u_Atlas");
    bindUniformLocation(ATLAS_TEX1_UNIFORM, "u_Fonts");

    bindUniformLocation(RESOLUTION_UNIFORM, "u_Resolution");
    bindUniformLocation(OFFSET_UNIFORM, "u_Offset");
    bindUniformLocation(CENTER_UNIFORM, "u_Center");

    setUniformValue(TRANSFORM_MATRIX_UNIFORM, m_transformMatrix);
    setUniformValue(PROJECTION_MATRIX_UNIFORM, m_projectionMatrix);
    setUniformValue(TEXTURE_MATRIX_UNIFORM, m_textureMatrix);

    if (!m_useColorMatrix) {
        setUniformValue(COLOR_UNIFORM, m_color);
    }

    setUniformValue(OPACITY_UNIFORM, m_opacity);
    setUniformValue(TIME_UNIFORM, m_time);
    setUniformValue(DEPTH_UNIFORM, m_depth);

    setUniformValue(TEX0_UNIFORM, 0);
    setUniformValue(TEX1_UNIFORM, 1);
    setUniformValue(TEX2_UNIFORM, 2);
    setUniformValue(TEX3_UNIFORM, 3);

    setUniformValue(ATLAS_TEX0_UNIFORM, 6);
    setUniformValue(ATLAS_TEX1_UNIFORM, 7);

    setUniformValue(RESOLUTION_UNIFORM, static_cast<float>(m_resolution.width()), static_cast<float>(m_resolution.height()));
    setUniformValue(OFFSET_UNIFORM, static_cast<float>(m_offset.x), static_cast<float>(m_offset.y));
    setUniformValue(CENTER_UNIFORM, static_cast<float>(m_center.x), static_cast<float>(m_center.y));
}

bool PainterShaderProgram::link()
{
    m_startTime = g_clock.seconds();
    bindAttributeLocation(VERTEX_ATTR, "a_Vertex");
    bindAttributeLocation(TEXCOORD_ATTR, "a_TexCoord");
    bindAttributeLocation(DEPTH_ATTR, "a_Depth");
    bindAttributeLocation(COLOR_ATTR, "a_Color");
    bindAttributeLocation(DEPTH_TEXCOORD_ATTR, "a_DepthTexCoord");
    if (!ShaderProgram::link())
        return false;

    bind();
    setupUniforms();
    release();
    return true;
}

void PainterShaderProgram::setTransformMatrix(const Matrix3& transformMatrix)
{
    if (transformMatrix == m_transformMatrix)
        return;

    bind();
    setUniformValue(TRANSFORM_MATRIX_UNIFORM, transformMatrix);
    m_transformMatrix = transformMatrix;
}

void PainterShaderProgram::setProjectionMatrix(const Matrix3& projectionMatrix)
{
    if (projectionMatrix == m_projectionMatrix)
        return;

    bind();
    setUniformValue(PROJECTION_MATRIX_UNIFORM, projectionMatrix);
    m_projectionMatrix = projectionMatrix;
}

void PainterShaderProgram::setTextureMatrix(const Matrix3& textureMatrix)
{
    if (textureMatrix == m_textureMatrix)
        return;

    bind();
    setUniformValue(TEXTURE_MATRIX_UNIFORM, textureMatrix);
    m_textureMatrix = textureMatrix;
}

void PainterShaderProgram::setColor(const Color& color)
{
    if (color == m_color)
        return;

    bind();
    setUniformValue(COLOR_UNIFORM, color);
    m_color = color;
}

void PainterShaderProgram::setMatrixColor(const Matrix4& colors)
{
    bind();
    setUniformValue(COLOR_UNIFORM, colors);
}

#ifdef WITH_DEPTH_BUFFER
void PainterShaderProgram::setDepth(float depth)
{
    if (depth < 0.)
        depth = 0.;

    if (m_depth == depth)
        return;

    bind();
    setUniformValue(DEPTH_UNIFORM, depth);
    m_depth = depth;
}
#endif

void PainterShaderProgram::setOpacity(float opacity)
{
    if (m_opacity == opacity)
        return;

    bind();
    setUniformValue(OPACITY_UNIFORM, opacity);
    m_opacity = opacity;
}

void PainterShaderProgram::setResolution(const Size& resolution)
{
    if (m_resolution == resolution)
        return;

    bind();
    setUniformValue(RESOLUTION_UNIFORM, static_cast<float>(resolution.width()), static_cast<float>(resolution.height()));
    m_resolution = resolution;
}

void PainterShaderProgram::setOffset(const Point& offset)
{
    if (m_offset == offset)
        return;

    bind();
    m_offset = offset;
    setUniformValue(OFFSET_UNIFORM, (float)m_offset.x, (float)m_offset.y);
}

void PainterShaderProgram::setCenter(const Point& center)
{
    if (m_center == center)
        return;

    bind();
    m_center = center;
    setUniformValue(CENTER_UNIFORM, (float)m_center.x, (float)m_center.y);
}

void PainterShaderProgram::updateTime()
{
    const float time = g_clock.seconds() - m_startTime;
    if (m_time == time)
        return;

    bind();
    setUniformValue(TIME_UNIFORM, time);
    m_time = time;
}

void PainterShaderProgram::addMultiTexture(const std::string& file)
{
    if (m_multiTextures.size() > 3)
        g_logger.error("cannot add more multi textures to shader, the max is 3");

    const auto& texture = g_textures.getTexture(file);
    if (!texture)
        return;

    texture->create();
    texture->setSmooth(true);
    texture->setRepeat(true);

    m_multiTextures.emplace_back(texture);
}

void PainterShaderProgram::bindMultiTextures() const
{
    if (m_multiTextures.empty())
        return;

    uint_fast8_t i = 1;
    for (const auto& tex : m_multiTextures) {
        glActiveTexture(GL_TEXTURE0 + i++);
        glBindTexture(GL_TEXTURE_2D, tex->getId());
    }

    glActiveTexture(GL_TEXTURE0);
}

void PainterShaderProgram::clearMultiTextures()
{
    m_multiTextures.clear();
}
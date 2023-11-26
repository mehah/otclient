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

#include "framebuffer.h"
#include "graphics.h"
#include "texture.h"

#include <framework/core/application.h>
#include <framework/core/eventdispatcher.h>
#include <framework/graphics/drawpoolmanager.h>
#include <framework/platform/platformwindow.h>

uint32_t FrameBuffer::boundFbo = 0;

FrameBuffer::FrameBuffer()
{
    glGenFramebuffers(1, &m_fbo);
    if (!m_fbo)
        g_logger.fatal("Unable to create framebuffer object");
}

FrameBuffer::~FrameBuffer()
{
#ifndef NDEBUG
    assert(!g_app.isTerminated());
#endif
    if (g_graphics.ok() && m_fbo != 0)
        glDeleteFramebuffers(1, &m_fbo);
}

bool FrameBuffer::resize(const Size& size)
{
    assert(size.isValid());

    if (m_texture && m_texture->getSize() == size)
        return false;

    m_texture = std::make_shared<Texture>(size);
    m_texture->setSmooth(m_smooth);
    m_texture->setUpsideDown(true);
    m_textureMatrix = g_painter->getTransformMatrix(size);

    m_screenCoordsBuffer.clear();
    m_screenCoordsBuffer.addRect(Rect{ 0, 0, size });

    internalBind();
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, m_texture->getId(), 0);

    const GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE)
        g_logger.fatal("Unable to setup framebuffer object");

    internalRelease();

    return true;
}

void FrameBuffer::bind()
{
    internalBind();

    if (m_isScene) {
        g_painter->resetState();
    }

    m_oldSize = std::move(g_painter->getResolution());
    m_oldTextureMatrix = std::move(g_painter->getProjectionMatrix());

    g_painter->setResolution(getSize(), m_textureMatrix);
    g_painter->setAlphaWriting(m_useAlphaWriting);

    if (m_colorClear != Color::alpha) {
        g_painter->setTexture(nullptr);
        g_painter->setColor(m_colorClear);
        g_painter->drawCoords(m_screenCoordsBuffer, DrawMode::TRIANGLE_STRIP);
    } else {
        g_painter->clear(Color::alpha);
    }
}

void FrameBuffer::release() const
{
    internalRelease();
    g_painter->setResolution(m_oldSize, m_oldTextureMatrix);
}

void FrameBuffer::draw()
{
    if (m_disableBlend) glDisable(GL_BLEND);
    g_painter->setCompositionMode(m_compositeMode);
    g_painter->setTexture(m_texture.get());
    g_painter->drawCoords(m_coordsBuffer, DrawMode::TRIANGLE_STRIP);
    g_painter->resetCompositionMode();
    if (m_disableBlend) glEnable(GL_BLEND);
}

void FrameBuffer::internalBind()
{
    assert(boundFbo != m_fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, m_fbo);
    m_prevBoundFbo = boundFbo;
    boundFbo = m_fbo;
}

void FrameBuffer::internalRelease() const
{
    assert(boundFbo == m_fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, m_prevBoundFbo);
    boundFbo = m_prevBoundFbo;
}

void FrameBuffer::prepare(const Rect& dest, const Rect& src, const Color& colorClear)
{
    const auto& _dest = dest.isValid() ? dest : Rect(0, 0, getSize());
    const auto& _src = src.isValid() ? src : Rect(0, 0, getSize());

    if (m_colorClear != colorClear)
        m_colorClear = colorClear;

    if (_src != m_src || _dest != m_dest) {
        m_src = _src;
        m_dest = _dest;

        m_coordsBuffer.clear();
        m_coordsBuffer.addQuad(m_dest, m_src);
    }
}
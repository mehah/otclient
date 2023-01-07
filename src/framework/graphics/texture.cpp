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

#include "texture.h"
#include "framebuffer.h"
#include "graphics.h"
#include "image.h"

#include <framework/core/application.h>
#include <framework/core/eventdispatcher.h>
#include "framework/stdext/math.h"

 // UINT16_MAX = just to avoid conflicts with GL generated ID.
static std::atomic_uint32_t UID(UINT16_MAX);

Texture::Texture() : m_uniqueId(++UID) {}

Texture::Texture(const Size& size) : m_uniqueId(++UID)
{
    m_id = 0;
    m_time = 0;

    if (!setupSize(size))
        return;

    createTexture();
    bind();
    setupPixels(0, size, nullptr, 4);
    setupWrap();
    setupFilters();
}

Texture::Texture(const ImagePtr& image, bool buildMipmaps, bool compress, bool canSuperimposed, bool load) : m_uniqueId(++UID)
{
    m_id = 0;
    m_time = 0;
    m_canSuperimposed = canSuperimposed;
    m_compress = compress;
    m_buildMipmaps = buildMipmaps;
    if (load) {
        createTexture();
        uploadPixels(image, m_buildMipmaps, m_compress);
    } else {
        m_image = image;
        setupSize(image->getSize());
    }
}

Texture::~Texture()
{
#ifndef NDEBUG
    assert(!g_app.isTerminated());
#endif
    if (g_graphics.ok() && m_id != 0) {
        g_mainDispatcher.addEvent([id = m_id]() {
            glDeleteTextures(1, &id);
        });
    }
}

void Texture::create()
{
    if (m_image) {
        createTexture();
        uploadPixels(m_image, m_buildMipmaps, m_compress);
        m_image = nullptr;
    }
}

void Texture::uploadPixels(const ImagePtr& image, bool buildMipmaps, bool compress)
{
    if (!setupSize(image->getSize()))
        return;

    bind();

    if (buildMipmaps) {
        int level = 0;
        do {
            setupPixels(level++, image->getSize(), image->getPixelData(), image->getBpp(), compress);
        } while (image->nextMipmap());
        m_hasMipmaps = true;
    } else
        setupPixels(0, image->getSize(), image->getPixelData(), image->getBpp(), compress);

    setupWrap();
    setupFilters();

    m_opaque = !image->hasTransparentPixel();
}

void Texture::bind()
{
    // must reset painter texture state
    g_painter->setTexture(this);
    glBindTexture(GL_TEXTURE_2D, m_id);
}

void Texture::copyFromScreen(const Rect& screenRect)
{
    bind();
    glCopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, screenRect.x(), screenRect.y(), screenRect.width(), screenRect.height());
}

bool Texture::buildHardwareMipmaps()
{
    bind();

    if (!m_hasMipmaps) {
        m_hasMipmaps = true;
        setupFilters();
    }

    glGenerateMipmap(GL_TEXTURE_2D);
    return true;
}

void Texture::setSmooth(bool smooth)
{
    if (smooth == m_smooth)
        return;

    m_smooth = smooth;
    bind();
    setupFilters();
}

void Texture::setRepeat(bool repeat)
{
    if (m_repeat == repeat)
        return;

    m_repeat = repeat;
    bind();
    setupWrap();
}

void Texture::setUpsideDown(bool upsideDown)
{
    if (m_upsideDown == upsideDown)
        return;
    m_upsideDown = upsideDown;
    setupTranformMatrix();
}

void Texture::createTexture()
{
    if (g_graphics.ok() && m_id != 0)
        glDeleteTextures(1, &m_id);

    glGenTextures(1, &m_id);
    assert(m_id != 0);
}

bool Texture::setupSize(const Size& size)
{
    // checks texture max size
    if (std::max<int>(size.width(), size.height()) > g_graphics.getMaxTextureSize()) {
        g_logger.error(stdext::format("loading texture with size %dx%d failed, "
                       "the maximum size allowed by the graphics card is %dx%d,"
                       "to prevent crashes the texture will be displayed as a blank texture",
                       size.width(), size.height(), g_graphics.getMaxTextureSize(), g_graphics.getMaxTextureSize()));
        return false;
    }

    m_size = size;

    setupTranformMatrix();

    return true;
}

void Texture::setupWrap()
{
    const GLint texParam = m_repeat ? GL_REPEAT : GL_CLAMP_TO_EDGE;
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, texParam);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, texParam);
}

void Texture::setupFilters()
{
    int minFilter;
    int magFilter;
    if (m_smooth) {
        minFilter = m_hasMipmaps ? GL_LINEAR_MIPMAP_LINEAR : GL_LINEAR;
        magFilter = GL_LINEAR;
    } else {
        minFilter = m_hasMipmaps ? GL_NEAREST_MIPMAP_NEAREST : GL_NEAREST;
        magFilter = GL_NEAREST;
    }
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, minFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, magFilter);
}

void Texture::setupTranformMatrix()
{
    if (m_upsideDown) {
        m_transformMatrix = { 1.0f / m_size.width(), 0.0f,                                                    0.0f,
                              0.0f,                   -1.0f / m_size.height(),                                0.0f,
                              0.0f,                    m_size.height() / static_cast<float>(m_size.height()), 1.0f };
    } else {
        m_transformMatrix = { 1.0f / m_size.width(), 0.0f,                     0.0f,
                              0.0f,                    1.0f / m_size.height(), 0.0f,
                              0.0f,                    0.0f,                     1.0f };
    }
}

void Texture::setupPixels(int level, const Size& size, uint8_t* pixels, int channels, bool compress)
{
    GLenum format = 0;
    switch (channels) {
        case 4:
            format = GL_RGBA;
            break;
        case 3:
            format = GL_RGB;
            break;
        case 2:
            format = GL_LUMINANCE_ALPHA;
            break;
        case 1:
            format = GL_LUMINANCE;
            break;
    }

    GLenum internalFormat = GL_RGBA;

#ifdef OPENGL_ES
    //TODO
#else
    if (compress)
        internalFormat = GL_COMPRESSED_RGBA;
#endif

    glTexImage2D(GL_TEXTURE_2D, level, internalFormat, size.width(), size.height(), 0, format, GL_UNSIGNED_BYTE, pixels);
}

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

#include "declarations.h"
#include "painter.h"
#include "texture.h"

class FrameBuffer
{
public:
    FrameBuffer();
    ~FrameBuffer();

    void release() const;
    void bind();
    void draw();
    void draw(const Rect& dest) { prepare(dest, Rect(0, 0, getSize())); draw(); }

    void setSmooth(bool enabled) { m_smooth = enabled; m_texture = nullptr; }

    bool resize(const Size& size);
    bool isValid() const { return m_texture != nullptr; }
    bool canDraw() const { return m_coordsBuffer.getVertexCount() > 0; }
    TexturePtr getTexture() const { return m_texture; }
    Size getSize() const { return m_texture->getSize(); }

    void setCompositionMode(const CompositionMode mode) { m_compositeMode = mode; }
    void disableBlend() { m_disableBlend = true; }

protected:
    Color m_colorClear{ Color::alpha };

    friend class FrameBufferManager;
    friend class DrawPoolManager;
    friend class DrawPool;

private:
    static uint32_t boundFbo;

    void internalBind();
    void internalRelease() const;
    void prepare(const Rect& dest, const Rect& src, const Color& colorClear = Color::alpha);

    Size m_oldSize;

    Matrix3 m_textureMatrix, m_oldTextureMatrix;
    TexturePtr m_texture;

    uint32_t m_fbo{ 0 };
    uint32_t m_prevBoundFbo{ 0 };

    CompositionMode m_compositeMode{ CompositionMode::NORMAL };

    bool m_smooth{ true };
    bool m_useAlphaWriting{ true };
    bool m_disableBlend{ false };
    bool m_isScene{ false };

    Rect m_dest;
    Rect m_src;

    CoordsBuffer m_coordsBuffer;
    CoordsBuffer m_screenCoordsBuffer;
};

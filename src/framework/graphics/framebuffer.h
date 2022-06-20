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

class FrameBuffer : public stdext::shared_object
{
public:
    ~FrameBuffer() override;

    void release();
    void resize(const Size& size);
    void bind();
    void draw();

    void setSmooth(bool enabled) { m_smooth = enabled; m_texture = nullptr; }
    void setBackuping(bool enabled) { m_backuping = enabled; }

    TexturePtr getTexture() { return m_texture; }
    Size getSize();

    bool isBackuping() { return m_backuping; }
    bool isSmooth() { return m_smooth; }

    void setCompositionMode(const CompositionMode mode) { m_compositeMode = mode; }
    void disableBlend() { m_disableBlend = true; }

protected:
    FrameBuffer(bool useAlphaWriting);

    Color m_colorClear{ Color::alpha };

    friend class FrameBufferManager;
    friend class DrawPool;

private:
    void internalCreate();
    void internalBind();
    void internalRelease();
    void prepare(const Rect& dest, const Rect& src, const Color& colorClear = Color::alpha);

    static uint boundFbo;

    Matrix3 m_textureMatrix;
    TexturePtr m_texture, m_screenBackup;

    uint32_t m_fbo, m_prevBoundFbo;

    CompositionMode m_compositeMode{ CompositionMode::NORMAL };

    bool m_backuping{ true },
        m_smooth{ true },
        m_useAlphaWriting{ false },
        m_disableBlend{ false };

    Rect m_dest, m_src;
    CoordsBuffer m_coordsBuffer, m_screenCoordsBuffer;
};

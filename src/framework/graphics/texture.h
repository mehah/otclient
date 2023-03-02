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

class Texture
{
public:
    Texture();
    Texture(const Size& size);
    Texture(const ImagePtr& image, bool buildMipmaps = false, bool compress = false);
    virtual ~Texture();

    Texture* create();
    void uploadPixels(const ImagePtr& image, bool buildMipmaps = false, bool compress = false);
    void updateImage(const ImagePtr& image);
    void updatePixels(uint8_t* pixels, int level = 0, int channels = 4, bool compress = false);

    virtual void buildHardwareMipmaps();

    virtual void setSmooth(bool smooth);
    virtual void setRepeat(bool repeat);
    void setUpsideDown(bool upsideDown);
    void setTime(ticks_t time) { m_time = time; }

    const Size& getSize() const { return m_size; }
    const Matrix3& getTransformMatrix() const { return m_transformMatrix; }

    ticks_t getTime() const { return m_time; }
    uint32_t getId() const { return m_id; }
    uint32_t getUniqueId() const { return m_uniqueId; }
    size_t hash() const { return m_hash; }

    int getWidth() const { return m_size.width(); }
    int getHeight() const { return m_size.height(); }

    bool isEmpty() const { return m_id == 0; }
    bool hasRepeat() const { return getProp(Prop::repeat); }
    bool hasMipmaps() const { return getProp(Prop::hasMipMaps); }
    virtual bool isAnimatedTexture() const { return false; }
    bool setupSize(const Size& size);

protected:
    void bind();
    void setupWrap() const;
    void setupFilters() const;
    void createTexture();
    void setupTranformMatrix();
    void setupPixels(int level, const Size& size, uint8_t* pixels, int channels = 4, bool compress = false) const;
    void generateHash() { m_hash = stdext::hash_int(m_id > 0 ? m_id : m_uniqueId); }

    const uint32_t m_uniqueId;

    uint32_t m_id{ 0 };
    ticks_t m_time{ 0 };
    size_t m_hash{ 0 };

    Size m_size;

    Matrix3 m_transformMatrix = DEFAULT_MATRIX3;

    ImagePtr m_image;

    enum Prop : uint16_t
    {
        hasMipMaps = 1 << 0,
        smooth = 1 << 1,
        upsideDown = 1 << 2,
        repeat = 1 << 3,
        compress = 1 << 4,
        buildMipmaps = 1 << 5
    };

    uint16_t m_props{ 0 };
    void setProp(Prop prop, bool v) { if (v) m_props |= prop; else m_props &= ~prop; }
    bool getProp(Prop prop) const { return m_props & prop; };

    static const Matrix3 toMatrix(const Size& size) {
        return { 1.0f / size.width(), 0.0f, 0.0f,
            0.0f, 1.0f / size.height(), 0.0f,
            0.0f, 0.0f, 1.0f };
    }
};

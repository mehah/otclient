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

#include <framework/graphics/declarations.h>
#include <framework/graphics/framebuffer.h>
#include "declarations.h"
#include "thingtype.h"

class LightView : public LuaObject
{
public:
    LightView();

    void resize(const Size& size, uint16_t tileSize);
    void draw(const Rect& dest, const Rect& src);

    void addLightSource(const Point& pos, const Light& light);
    void resetShade(const Point& pos);
    void update() { m_hash = 0; m_updatingHash = 1; }

    void setGlobalLight(const Light& light)
    {
        m_globalLight = light;
        m_globalLightColor = Color::from8bit(m_globalLight.color, m_globalLight.intensity / static_cast<float>(UINT8_MAX));
        m_pool->repaint();
    }

    const Light& getGlobalLight() const { return m_globalLight; }
    bool isDark() const { return m_globalLight.intensity < 250; }

private:
    struct TileLight : public Light
    {
        Point pos;
        float brightness{ 1.f };

        TileLight(const Point& pos, uint8_t intensity, uint8_t color, float brightness) : Light(intensity, color), pos(pos), brightness(brightness) {}
    };

    void updateCoords(const Rect& dest, const Rect& src);
    bool updatePixels();

    uint16_t m_tileSize{ 0 };
    size_t m_hash{ 0 }, m_updatingHash{ 0 };

    Light m_globalLight;
    Color m_globalLightColor{ Color::white };

    DrawPool* m_pool{ nullptr };

    Size m_mapSize;
    Rect m_dest, m_src;

    CoordsBuffer m_coords;
    TexturePtr m_lightTexture;

    std::vector<TileLight> m_lights;
    std::vector<size_t> m_tiles;
    std::vector<uint8_t> m_pixels;
};

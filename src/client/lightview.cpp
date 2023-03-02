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

#include "lightview.h"
#include <framework/graphics/drawpoolmanager.h>
#include "map.h"
#include "mapview.h"
#include "spritemanager.h"

LightView::LightView() : m_pool(g_drawPool.get<DrawPool>(DrawPoolType::LIGHT)) {}

void LightView::resize(const Size& size, const uint8_t tileSize) {
    m_lightTexture = nullptr;
    m_mapSize = size;
    m_tiles.resize(size.area(), {});
    if (m_pixels.size() < 4u * m_mapSize.area())
        m_pixels.resize(m_mapSize.area() * 4);
}

void LightView::addLightSource(const Point& pos, const Light& light)
{
    if (!isDark()) return;

    if (!m_lights.empty()) {
        auto& prevLight = m_lights.back();
        if (prevLight.pos == pos && prevLight.color == light.color) {
            prevLight.intensity = std::max<uint8_t>(prevLight.intensity, light.intensity);
            return;
        }
    }
    m_lights.emplace_back(pos, light.intensity, light.color, g_drawPool.getOpacity());

    stdext::hash_union(m_updatingHash, pos.hash());
    stdext::hash_combine(m_updatingHash, light.intensity);
    stdext::hash_combine(m_updatingHash, light.color);
    stdext::hash_combine(m_updatingHash, g_drawPool.getOpacity());
}

void LightView::setFieldBrightness(const Point& pos, size_t start, float brightness)
{
    size_t index = (pos.y / g_drawPool.getScaledSpriteSize()) * m_mapSize.width() + (pos.x / g_drawPool.getScaledSpriteSize());
    if (index >= m_tiles.size()) return;

    auto& tile = m_tiles[index];

    tile.start = start;
    tile.brightness = brightness;
}

void LightView::draw(const Rect& dest, const Rect& src)
{
    // draw light, only if there is darkness
    m_pool->setEnable(isDark());
    if (!isDark() || !m_pool->isValid()) return;

    updateCoords(dest, src);
    g_drawPool.use(m_pool->getType());

    g_drawPool.addAction([&, updatePixel = updatePixels()] {
        if (!m_lightTexture) {
            m_lightTexture = std::make_shared<Texture>(m_mapSize);
            m_lightTexture->setSmooth(true);
        }

        if (updatePixel)
            m_lightTexture->updatePixels(m_pixels.data());

        g_painter->resetColor();
        g_painter->setCompositionMode(CompositionMode::MULTIPLY);
        g_painter->setTexture(m_lightTexture.get());
        g_painter->drawCoords(m_coords);
    });

    m_lights.clear();
}

void LightView::updateCoords(const Rect& dest, const Rect& src) {
    if (m_dest != dest || m_src != src) {
        m_dest = dest;
        m_src = src;

        Point offset = src.topLeft();
        Size size = src.size();

        m_coords.clear();
        m_coords.addRect(RectF(dest.left(), dest.top(), dest.width(), dest.height()),
                       RectF((float)offset.x / g_drawPool.getScaledSpriteSize(), (float)offset.y / g_drawPool.getScaledSpriteSize(),
                         (float)size.width() / g_drawPool.getScaledSpriteSize(), (float)size.height() / g_drawPool.getScaledSpriteSize()));
    }
}

bool LightView::updatePixels() {
    bool updatePixel = m_updatingHash != m_hash;
    if (updatePixel) {
        for (int x = 0; x < m_mapSize.width(); ++x) {
            for (int y = 0; y < m_mapSize.height(); ++y) {
                const Point pos(x * g_drawPool.getScaledSpriteSize() + g_drawPool.getScaledSpriteSize() / 2, y * g_drawPool.getScaledSpriteSize() + g_drawPool.getScaledSpriteSize() / 2);

                int index = (y * m_mapSize.width() + x);

                const auto& tile = m_tiles[index];

                int colorIndex = index * 4;
                m_pixels[colorIndex] = m_globalLightColor.r() * tile.brightness;
                m_pixels[colorIndex + 1] = m_globalLightColor.g() * tile.brightness;
                m_pixels[colorIndex + 2] = m_globalLightColor.b() * tile.brightness;
                m_pixels[colorIndex + 3] = 255; // alpha channel
                for (size_t i = tile.start; i < m_lights.size(); ++i) {
                    const auto& light = m_lights[i];
                    float distance = std::sqrt((pos.x - light.pos.x) * (pos.x - light.pos.x) +
                                               (pos.y - light.pos.y) * (pos.y - light.pos.y));
                    distance /= g_drawPool.getScaledSpriteSize();
                    float intensity = (-distance + (light.intensity * light.brightness)) * 0.2f;
                    if (intensity < 0.01f) continue;
                    if (intensity > 1.0f) intensity = 1.0f;
                    Color lightColor = Color::from8bit(light.color) * intensity;
                    m_pixels[colorIndex] = std::max<int>(m_pixels[colorIndex], lightColor.r());
                    m_pixels[colorIndex + 1] = std::max<int>(m_pixels[colorIndex + 1], lightColor.g());
                    m_pixels[colorIndex + 2] = std::max<int>(m_pixels[colorIndex + 2], lightColor.b());
                }
            }
        }

        m_hash = m_updatingHash;
        m_updatingHash = 0;
    }

    return updatePixel;
}

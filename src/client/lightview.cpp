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

void LightView::resize(const Size& size, const uint16_t tileSize) {
    m_lightTexture = nullptr;
    m_mapSize = size;
    m_tileSize = tileSize;
    m_tiles.resize(size.area());
    if (m_pixels.size() < 4u * m_mapSize.area())
        m_pixels.resize(m_mapSize.area() * 4);
}

void LightView::addLightSource(const Point& pos, const Light& light, float brightness)
{
    if (!isDark()) return;

    if (!m_lights.empty()) {
        auto& prevLight = m_lights.back();
        if (prevLight.pos == pos && prevLight.color == light.color) {
            prevLight.intensity = std::max<uint8_t>(prevLight.intensity, light.intensity);
            return;
        }
    }
    m_lights.emplace_back(pos, light.intensity, light.color, std::min<float>(brightness, g_drawPool.getOpacity()));

    stdext::hash_union(m_updatingHash, pos.hash());
    stdext::hash_combine(m_updatingHash, light.intensity);
    stdext::hash_combine(m_updatingHash, light.color);

    if (g_drawPool.getOpacity() < 1.f)
        stdext::hash_combine(m_updatingHash, g_drawPool.getOpacity());
}

void LightView::resetShade(const Point& pos)
{
    size_t index = (pos.y / m_tileSize) * m_mapSize.width() + (pos.x / m_tileSize);
    if (index >= m_tiles.size()) return;
    m_tiles[index] = m_lights.size();
}

void LightView::draw(const Rect& dest, const Rect& src)
{
    // draw light, only if there is darkness
    m_pool->setEnable(isDark());
    if (!isDark() || !m_pool->isValid()) return;

    g_drawPool.use(DrawPoolType::LIGHT);

    updateCoords(dest, src);
    updatePixels();

    g_drawPool.addAction([&] {
        if (!m_lightTexture) {
            m_lightTexture = std::make_shared<Texture>(m_mapSize);
            m_lightTexture->setSmooth(true);
        }

        m_lightTexture->updatePixels(m_pixels.data());

        g_painter->resetColor();
        g_painter->setTexture(m_lightTexture.get());
        g_painter->setCompositionMode(CompositionMode::MULTIPLY);
        g_painter->drawCoords(m_coords);
    });

    m_lights.clear();
    m_tiles.assign(m_mapSize.area(), {});
}

void LightView::updateCoords(const Rect& dest, const Rect& src) {
    if (m_dest == dest && m_src == src)
        return;

    const auto& offset = src.topLeft();
    const auto& size = src.size();

    m_dest = dest;
    m_src = src;

    m_coords.clear();
    m_coords.addRect(RectF(m_dest.left(), m_dest.top(), m_dest.width(), m_dest.height()),
               RectF(static_cast<float>(offset.x) / m_tileSize, static_cast<float>(offset.y) / m_tileSize,
                     static_cast<float>(size.width()) / m_tileSize, static_cast<float>(size.height()) / m_tileSize));
}

void LightView::updatePixels() {
    if (m_updatingHash == m_hash)
        return;

    for (int x = 0; x < m_mapSize.width(); ++x) {
        for (int y = 0; y < m_mapSize.height(); ++y) {
            const Point pos(x * m_tileSize + m_tileSize / 2, y * m_tileSize + m_tileSize / 2);
            const int index = (y * m_mapSize.width() + x);
            const int colorIndex = index * 4;

            m_pixels[colorIndex] = m_globalLightColor.r();
            m_pixels[colorIndex + 1] = m_globalLightColor.g();
            m_pixels[colorIndex + 2] = m_globalLightColor.b();
            m_pixels[colorIndex + 3] = 255; // alpha channel
            for (size_t i = m_tiles[index]; i < m_lights.size(); ++i) {
                const auto& light = m_lights[i];
                float distance = std::sqrt((pos.x - light.pos.x) * (pos.x - light.pos.x) +
                                           (pos.y - light.pos.y) * (pos.y - light.pos.y));
                distance /= m_tileSize;

                float intensity = (-distance + (light.intensity * light.brightness)) * .2f;
                if (intensity < .01f) continue;
                if (intensity > 1.f) intensity = 1.f;

                const auto& lightColor = Color::from8bit(light.color) * intensity;
                m_pixels[colorIndex] = std::max<int>(m_pixels[colorIndex], lightColor.r());
                m_pixels[colorIndex + 1] = std::max<int>(m_pixels[colorIndex + 1], lightColor.g());
                m_pixels[colorIndex + 2] = std::max<int>(m_pixels[colorIndex + 2], lightColor.b());
            }
        }
    }

    m_hash = m_updatingHash;
    m_updatingHash = 0;
}

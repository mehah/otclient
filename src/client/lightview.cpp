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
#include "map.h"
#include "mapview.h"
#include "spritemanager.h"

#include <framework/core/eventdispatcher.h>
#include <framework/core/asyncdispatcher.h>
#include <framework/graphics/drawpoolmanager.h>

LightView::LightView(const Size& size, const uint16_t tileSize) : m_pool(g_drawPool.get(DrawPoolType::LIGHT)) {
    g_mainDispatcher.addEvent([this, size] {
        m_texture = std::make_shared<Texture>(size);
        m_texture->setSmooth(true);
    });
}

void LightView::resize(const Size& size, const uint16_t tileSize) {
    if (!m_texture || m_mapSize == size && m_tileSize == tileSize)
        return;

    std::scoped_lock l(m_pool->getMutex(), m_pool->getMutexPreDraw());

    m_mapSize = size;
    m_tileSize = tileSize;

    for (auto& lightData : m_lightData) {
        lightData.tiles.resize(size.area());
        lightData.lights.clear();
    }

    m_pixels.resize(size.area() * 4);

    if (m_texture)
        m_texture->setupSize(m_mapSize);
}

void LightView::addLightSource(const Point& pos, const Light& light, float brightness)
{
    if (!isDark() || light.intensity == 0)
        return;

    auto& lightData = m_lightData[0];

    if (!lightData.lights.empty()) {
        auto& prevLight = lightData.lights.back();
        if (prevLight.pos == pos && prevLight.color == light.color) {
            prevLight.intensity = std::max<uint8_t>(prevLight.intensity, light.intensity);
            return;
        }
    }
    lightData.lights.emplace_back(pos, light.intensity, light.color, std::min<float>(brightness, g_drawPool.getOpacity()));

    stdext::hash_union(m_updatedHash, pos.hash());
    stdext::hash_combine(m_updatedHash, light.intensity);
    stdext::hash_combine(m_updatedHash, light.color);

    if (g_drawPool.getOpacity() < 1.f)
        stdext::hash_combine(m_updatedHash, g_drawPool.getOpacity());
}

void LightView::resetShade(const Point& pos)
{
    auto& lightData = m_lightData[0];

    size_t index = (pos.y / m_tileSize) * m_mapSize.width() + (pos.x / m_tileSize);
    if (index >= lightData.tiles.size()) return;
    lightData.tiles[index] = lightData.lights.size();
}

void LightView::draw(const Rect& dest, const Rect& src)
{
    if (m_updatedHash != m_hash) {
        m_hash = m_updatedHash;
        m_updatedHash = 0;

        std::scoped_lock l(m_pool->getMutexPreDraw());
        std::swap(m_lightData[0], m_lightData[1]);
        g_asyncDispatcher.dispatch([this] {
            updatePixels();
        });
    }

    g_drawPool.preDraw(DrawPoolType::LIGHT, [this, &dest, &src] {
        g_drawPool.addAction([=, this] {
            {
                std::scoped_lock l(m_pool->getMutexPreDraw());
                m_texture->updatePixels(m_pixels.data());
            }

            updateCoords(dest, src);
            g_painter->setCompositionMode(CompositionMode::MULTIPLY);
            g_painter->resetTransformMatrix();
            g_painter->resetColor();
            g_painter->setTexture(m_texture.get());
            g_painter->drawCoords(m_coords);
        });
    });

    auto& lightData = m_lightData[0];
    lightData.lights.clear();
    lightData.tiles.assign(m_mapSize.area(), {});
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
    std::scoped_lock l(m_pool->getMutexPreDraw());

    const auto& lightData = m_lightData[1];

    const size_t lightSize = lightData.lights.size();

    const int mapWidth = m_mapSize.width();
    const int mapHeight = m_mapSize.height();

    for (int x = -1; ++x < mapWidth;) {
        for (int y = -1; ++y < mapHeight;) {
            const Point pos(x * m_tileSize + m_tileSize / 2, y * m_tileSize + m_tileSize / 2);
            const int index = (y * mapWidth + x);
            const int colorIndex = index * 4;
            m_pixels[colorIndex] = m_globalLightColor.r();
            m_pixels[colorIndex + 1] = m_globalLightColor.g();
            m_pixels[colorIndex + 2] = m_globalLightColor.b();
            m_pixels[colorIndex + 3] = 255; // alpha channel
            for (size_t i = lightData.tiles[index]; i < lightSize; ++i) {
                const auto& light = lightData.lights[i];
                const float distance = (std::sqrt((pos.x - light.pos.x) * (pos.x - light.pos.x) +
                                        (pos.y - light.pos.y) * (pos.y - light.pos.y))) / m_tileSize;

                float intensity = (-distance + light.intensity) * 0.2f;
                if (intensity < 0.01f) continue;
                if (intensity > 1.0f) intensity = 1.0f;

                const auto& lightColor = Color::from8bit(light.color) * intensity;
                m_pixels[colorIndex] = std::max<int>(m_pixels[colorIndex], lightColor.r());
                m_pixels[colorIndex + 1] = std::max<int>(m_pixels[colorIndex + 1], lightColor.g());
                m_pixels[colorIndex + 2] = std::max<int>(m_pixels[colorIndex + 2], lightColor.b());
            }
        }
    }
}
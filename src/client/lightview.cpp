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
#include <framework/graphics/drawpoolmanager.h>

LightView::LightView(const Size& size, const uint16_t tileSize) : m_pool(g_drawPool.get(DrawPoolType::LIGHT)) {
    resize(size, tileSize);
    g_mainDispatcher.addEvent([&] {
        m_texture = std::make_shared<Texture>(m_lightData.mapSize);
        m_texture->setSmooth(true);
    });

    m_thread = std::thread([this]() {
        std::unique_lock lock(m_pool->getMutex());
        m_condition.wait(lock, [this]() -> bool {
            updatePixels();
            return m_texture == nullptr;
        });
    });
}

void LightView::resize(const Size& size, const uint16_t tileSize) {
    std::scoped_lock l(m_pool->getMutex());
    m_lightData.mapSize = size;
    m_lightData.tileSize = tileSize;
    m_lightData.tiles.resize(size.area());
    if (m_pixels.size() < 4u * m_lightData.mapSize.area())
        m_pixels.resize(m_lightData.mapSize.area() * 4);
    if (m_texture)
        m_texture->setupSize(m_lightData.mapSize);


    g_drawPool.use(DrawPoolType::LIGHT);
    g_drawPool.addAction([this] {
        {
            std::scoped_lock l(m_pool->getMutex());
            m_texture->updatePixels(m_pixels.data());
        }
        g_painter->resetColor();
        g_painter->resetTransformMatrix();
        g_painter->setTexture(m_texture.get());
        g_painter->setCompositionMode(CompositionMode::MULTIPLY);
        g_painter->drawCoords(m_coords);
    });
}

void LightView::addLightSource(const Point& pos, const Light& light, float brightness)
{
    if (light.intensity == 0)
        return;

    if (!m_lightData.lights.empty()) {
        auto& prevLight = m_lightData.lights.back();
        if (prevLight.pos == pos && prevLight.color == light.color) {
            prevLight.intensity = std::max<uint8_t>(prevLight.intensity, light.intensity);
            return;
        }
    }
    m_lightData.lights.emplace_back(pos, light.intensity, light.color, std::min<float>(brightness, g_drawPool.getOpacity()));

    stdext::hash_union(m_updatedHash, pos.hash());
    stdext::hash_combine(m_updatedHash, light.intensity);
    stdext::hash_combine(m_updatedHash, light.color);

    if (g_drawPool.getOpacity() < 1.f)
        stdext::hash_combine(m_updatedHash, g_drawPool.getOpacity());
}

void LightView::resetShade(const Point& pos)
{
    size_t index = (pos.y / m_lightData.tileSize) * m_lightData.mapSize.width() + (pos.x / m_lightData.tileSize);
    if (index >= m_lightData.tiles.size()) return;
    m_lightData.tiles[index] = m_lightData.lights.size();
}

void LightView::draw(const Rect& dest, const Rect& src)
{
    updateCoords(dest, src);

    if (m_updatedHash != m_hash) {
        m_hash = m_updatedHash;
        m_updatedHash = 0;

        {
            //std::scoped_lock l(m_mutex);
            m_threadLightData = m_lightData;
        }
        m_condition.notify_one();
    }

    m_lightData.lights.clear();
    m_lightData.tiles.assign(m_lightData.mapSize.area(), {});
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
               RectF(static_cast<float>(offset.x) / m_lightData.tileSize, static_cast<float>(offset.y) / m_lightData.tileSize,
                     static_cast<float>(size.width()) / m_lightData.tileSize, static_cast<float>(size.height()) / m_lightData.tileSize));
}

void LightView::updatePixels() {
    const size_t lightSize = m_threadLightData.lights.size();

    for (int x = 0; x < m_threadLightData.mapSize.width(); ++x) {
        for (int y = 0; y < m_threadLightData.mapSize.height(); ++y) {
            Point pos(x * m_threadLightData.tileSize + m_threadLightData.tileSize / 2, y * m_threadLightData.tileSize + m_threadLightData.tileSize / 2);
            int index = (y * m_threadLightData.mapSize.width() + x);
            int colorIndex = index * 4;
            m_pixels[colorIndex] = m_threadLightData.globalLightColor.r();
            m_pixels[colorIndex + 1] = m_threadLightData.globalLightColor.g();
            m_pixels[colorIndex + 2] = m_threadLightData.globalLightColor.b();
            m_pixels[colorIndex + 3] = 255; // alpha channel
            for (size_t i = m_threadLightData.tiles[index]; i < lightSize; ++i) {
                const auto& light = m_threadLightData.lights[i];
                float distance = std::sqrt((pos.x - light.pos.x) * (pos.x - light.pos.x) +
                                           (pos.y - light.pos.y) * (pos.y - light.pos.y));
                distance /= m_threadLightData.tileSize;
                float intensity = (-distance + light.intensity) * 0.2f;
                if (intensity < 0.01f) continue;
                if (intensity > 1.0f) intensity = 1.0f;
                Color lightColor = Color::from8bit(light.color) * intensity;
                m_pixels[colorIndex] = std::max<int>(m_pixels[colorIndex], lightColor.r());
                m_pixels[colorIndex + 1] = std::max<int>(m_pixels[colorIndex + 1], lightColor.g());
                m_pixels[colorIndex + 2] = std::max<int>(m_pixels[colorIndex + 2], lightColor.b());
            }
        }
    }
}
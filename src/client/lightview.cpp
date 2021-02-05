/*
 * Copyright (c) 2010-2020 OTClient <https://github.com/edubart/otclient>
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
#include <framework/graphics/framebuffer.h>
#include <framework/graphics/framebuffermanager.h>
#include <framework/graphics/image.h>
#include <framework/graphics/painter.h>
#include "mapview.h"
#include "map.h"

#define DEBUG_BUBBLE 0

LightView::LightView(const MapViewPtr& mapView)
{
    m_mapView = mapView;

    m_lightbuffer = g_framebuffers.createFrameBuffer();
    m_lightTexture = generateLightBubble();

    reset();
    resize();
}

const TexturePtr LightView::generateLightBubble()
{
    const uint8 intensityVariant = 0xff;
    const float centerFactor = .0f;

    const uint16 bubbleRadius = 256,
        centerRadius = bubbleRadius * centerFactor,
        bubbleDiameter = bubbleRadius * 2;

    ImagePtr lightImage = ImagePtr(new Image(Size(bubbleDiameter, bubbleDiameter)));

    for(int_fast16_t x = -1; ++x < bubbleDiameter;) {
        for(int_fast16_t y = -1; ++y < bubbleDiameter;) {
            const float radius = std::sqrt((bubbleRadius - x) * (bubbleRadius - x) + (bubbleRadius - y) * (bubbleRadius - y));
            float intensity = stdext::clamp<float>((bubbleRadius - radius) / static_cast<float>(bubbleRadius - centerRadius), .0f, 1.0f);

            // light intensity varies inversely with the square of the distance
            intensity = std::min<float>(intensity * intensity, 0.4);
            const uint8_t colorByte = intensity * intensityVariant;

            uint8_t pixel[4] = { colorByte, colorByte, colorByte, 0xff };
            lightImage->setPixel(x, y, pixel);
        }
    }

    TexturePtr tex = TexturePtr(new Texture(lightImage, true));
    tex->setSmooth(true);
    return tex;
}

void LightView::addLightSource(const Position& pos, const Point& center, float scaleFactor, const Light& light, const ThingPtr& thing)
{
    const uint8 intensity = std::min<uint8>(light.intensity, MAX_LIGHT_INTENSITY);

#if DEBUG_BUBBLE == 1
    const float extraRadius = 1;
#else
    const float extraRadius = intensity > 1 ? 1.8 + std::min<float>(intensity, MAX_LIGHT_INTENSITY) / 10 : 1.1;
#endif

    std::pair<Point, Point> extraOffset;
    bool isMoving = false;
    if(thing && thing->isCreature()) {
        const CreaturePtr& creature = thing->static_self_cast<Creature>();
        extraOffset.first = Point(16, 16) * scaleFactor;
        extraOffset.second = (creature->getWalkOffset() + Point(16, 16)) * scaleFactor;
        isMoving = extraOffset.first != extraOffset.second;
    }

    const uint16 radius = (Otc::TILE_PIXELS * scaleFactor) * extraRadius;
    const Position centralPos = pos.isValid() ? pos : m_mapView->getPosition(center, m_mapView->m_srcRect.size());
    const auto& dimension = getDimensionConfig(intensity);
    for(const auto& position : dimension.positions)
    {
        const auto& lightPos = centralPos.translated(position.x, position.y);
        auto& lightPoint = getLightPoint(lightPos);
        if(!lightPoint.isValid()) continue;

        LightSource& staticLight = lightPoint.staticLight;
        if(!isMoving && staticLight.hasLight()) {
            if(staticLight.color < light.color) {
                continue;
            }

            if(staticLight.color == light.color && staticLight.brightness > position.brightness) {
                staticLight.brightness = position.brightness;
                continue;
            }
        }

        LightSource lightSource;
        lightSource.pos = lightPos;
        lightSource.color = light.color;
        lightSource.radius = radius;
        lightSource.center = center + ((position.point * Otc::TILE_PIXELS) * scaleFactor);
        lightSource.centralPos = centralPos;
        lightSource.extraOffset = extraOffset;
        lightSource.brightness = position.brightness;

        if(isMoving) {
            lightPoint.dynamicLights.push_back(lightSource);
        } else {
            lightSource.center += extraOffset.first;
            staticLight = lightSource;
        }
    }
}

const DimensionConfig& LightView::getDimensionConfig(const uint8 intensity)
{
#if DEBUG_BUBBLE == 1
    const float startBrightness = 3;
#else
    const float startBrightness = intensity == 1 ? .15 : .35;
#endif

    auto& dimension = m_dimensionCache[intensity - 1];
    if(dimension.positions.empty()) {
        const uint8 size = std::max<int>(1, std::floor(static_cast<float>(intensity) / 1.1)),
            middle = (size / 2);
        const int8 start = size * -1;

        // TODO: REFATORATION REQUIRED
        // Ugly algorithm
        {
            auto pushLight = [&](const int8 x, const int8 y) -> void {
                const float brightness = startBrightness - ((std::max<float>(std::abs(x), std::abs(y)) * 1.5) / 50);
                dimension.positions.push_back(PositionLight(x, y, brightness));
            };

            uint8 i = 1;
            for(int_fast8_t x = start; x < 0; ++x) {
                for(int_fast8_t y = i * -1; y <= i; ++y) {
                    if(x == start || y == start || y == size) continue;
                    pushLight(x, y);
                }
                ++i;
            }

            i = 1;
            for(int_fast8_t x = size; x >= 0; --x) {
                for(int_fast8_t y = i * -1; y <= i; ++y) {
                    if(y >= size || y <= start || x == size) continue;
                    pushLight(x, y);
                }
                ++i;
            }
        }

        for(auto& pos : dimension.positions)
        {
            for(const auto& posAround : pos.getPositionsAround())
            {
                if(std::find(dimension.positions.begin(), dimension.positions.end(), posAround) == dimension.positions.end()) {
                    dimension.edges.push_back(pos);
                    pos.isEdge = true;
                    break;
                }
            }
        }
    }

    return dimension;
}

static LightPoint INVALID_LIGHT_POINT(true);
LightPoint& LightView::getLightPoint(const Position& pos)
{
    const auto& point = m_mapView->transformPositionTo2D(pos, m_mapView->getCameraPosition());
    size_t index = (m_mapView->m_drawDimension.width() * (point.y / Otc::TILE_PIXELS)) + (point.x / Otc::TILE_PIXELS);

    if(index >= m_lightMap.size()) return INVALID_LIGHT_POINT;

    return m_lightMap[index];
}

bool LightView::canDraw(const Position& pos, float& brightness)
{
    TilePtr tile = g_map.getTile(pos);
    if(!tile || tile->isCovered() || tile->isTopGround() && !tile->hasBottomToDraw() || !tile->hasGround()) {
        return false;
    }

    Position tilePos = pos;
    while(tilePos.coveredUp() && tilePos.z >= m_mapView->getCachedFirstVisibleFloor()) {
        tile = g_map.getTile(tilePos);
        if(tile) {
            if(tile->blockLight() || tile->isTopGround()) {
                return false;
            }

            brightness -= 0.05;
        }
    }

    return true;
}

void LightView::drawGlobalLight() const
{
    g_painter->setCompositionMode(Painter::CompositionMode_Replace);
    {
        Color color = Color::from8bit(m_globalLight.color);
        const float brightness = m_globalLight.intensity / static_cast<float>(MAX_AMBIENT_LIGHT_INTENSITY);
        color.setRed(color.rF() * brightness);
        color.setGreen(color.gF() * brightness);
        color.setBlue(color.bF() * brightness);
        g_painter->setColor(color);
    }
    g_painter->drawFilledRect(Rect(0, 0, m_lightbuffer->getSize()));
}

void LightView::drawLights()
{
    g_painter->setCompositionMode(Painter::CompositionMode_Add);
    for(LightPoint& adapter : m_lightMap) {
        if(adapter.hasDynamicLights()) {
            for(auto& light : adapter.dynamicLights) {
                g_painter->setBlendEquation(Painter::BlendEquation_Add);

                const bool canDrawLight = canDraw(light.pos, light.brightness);
                const auto originalOffset = light.center;

                light.center += light.extraOffset.second;
                drawLightSource(light);

                if(!canDrawLight) {
                    g_painter->setBlendEquation(Painter::BlendEquation_Rever_Subtract);
                    light.center = originalOffset + light.extraOffset.first;
                    drawLightSource(light);
                }
            }
            adapter.dynamicLights.clear();
        }

        if(adapter.hasStaticLight()) {
            auto& light = adapter.staticLight;
            if(!canDraw(light.pos, light.brightness)) continue;

            g_painter->setBlendEquation(Painter::BlendEquation_Add);
            drawLightSource(light);
            light.reset();
        }
    }
}

void LightView::drawLightSource(const LightSource& light)
{
    float brightness = light.brightness;
    if(!canDraw(light.pos, brightness)) return;

    Color color = Color::from8bit(light.color);
    color.setRed(color.rF() * brightness);
    color.setBlue(color.bF() * brightness);
    color.setGreen(color.gF() * brightness);

    const Rect dest = Rect(light.center - Point(light.radius, light.radius), Size(light.radius * 2, light.radius * 2));
    g_painter->setColor(color);
    g_painter->drawTexturedRect(dest, m_lightTexture);
}

void LightView::resize()
{
    m_lightbuffer->resize(m_mapView->m_frameCache.tile->getSize());
    m_lightMap.resize(m_mapView->m_drawDimension.area());
}

void LightView::draw(const Rect& dest, const Rect& src)
{
    // draw light, only if there is darkness
    if(!isDark() || m_lightbuffer->getTexture() == nullptr) return;

    g_painter->saveAndResetState();
    if(m_lightbuffer->canUpdate()) {
        m_lightbuffer->bind();

        drawGlobalLight();
        drawLights();

        m_lightbuffer->release();
    }
    g_painter->setCompositionMode(Painter::CompositionMode_Light);

    m_lightbuffer->draw(dest, src);
    g_painter->restoreSavedState();
}

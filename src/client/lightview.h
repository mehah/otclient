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

#ifndef LIGHTVIEW_H
#define LIGHTVIEW_H

#include <framework/graphics/framebuffer.h>
#include <framework/graphics/declarations.h>
#include <framework/graphics/painter.h>
#include "declarations.h"
#include "thingtype.h"

enum : uint8 {
    MAX_LIGHT_INTENSITY = 8,
    MAX_AMBIENT_LIGHT_INTENSITY = _UI8_MAX
};

struct PositionLight : Position {
    const float brightness;
    const Point point;
    bool isEdge = false;

    PositionLight(int8 x, int8 y, float brightness) :
        brightness(brightness), point(Point(x, y))
    {
        Position::x = x, Position::y = y, z = _UI8_MAX;
    }
};

struct DimensionConfig {
    std::vector<PositionLight>
        positions,
        edges;

    bool isEdge(const Position pos) const
    {
        return std::find(edges.begin(), edges.end(), pos) != edges.end();
    }
};

struct LightSource {
    int8_t radius;
    Point center;
    Position pos, centralPos;
    std::pair<Point, Point> extraOffset;
    Otc::Direction dir;
    bool isEdge;

    // Comparison Var
    uint8 color;
    float brightness;

    void reset()
    {
        radius = color = brightness = 0;
        pos = centralPos = Position();
        extraOffset = std::make_pair(center, center);
    }

    bool hasLight() const { return color > 0; }
    bool isValid() const { return radius > -1; }
    bool isMoving() const { return extraOffset.first != extraOffset.second; }
};

struct LightPoint {
    LightPoint(const bool valid = true) : isValid(valid), canMove(valid) {}

    bool isValid, canMove;
    std::vector<LightSource> lights;
    Point center;

    bool hasLight() const { return !lights.empty(); }
    void reset() { canMove = true; lights.clear(); center = Point(); }
};

class LightView : public LuaObject
{
public:
    LightView(const MapViewPtr& mapView);

    const Light& getGlobalLight() { return m_globalLight; }

    void resize();
    void reset() { m_lightMap.clear(); }
    void draw(const Rect& dest, const Rect& src);
    void addLightSource(const Position& pos, const Point& center, float scaleFactor, const Light& light, const ThingPtr& thing = nullptr);

    void setGlobalLight(const Light& light) { m_globalLight = light; }
    void schedulePainting(const uint16_t delay = FrameBuffer::MIN_TIME_UPDATE) const { if(isDark()) m_lightbuffer->schedulePainting(delay); }

    bool canUpdate() const { return isDark() && m_lightbuffer->canUpdate(); }
    bool isDark() const { return m_globalLight.intensity < 250; }

private:
    const DimensionConfig& getDimensionConfig(const uint8 intensity);
    const TexturePtr generateLightBubble();

    void drawLights();
    void drawGlobalLight() const;
    void drawLightSource(const LightSource& light);

    bool canDraw(const Position& pos, float& brightness);
    LightPoint& getLightPoint(const Position& pos);

    TexturePtr m_lightTexture;
    Light m_globalLight;

    FrameBufferPtr m_lightbuffer;
    MapViewPtr m_mapView;

    std::vector<LightPoint> m_lightMap;
    std::array<DimensionConfig, MAX_LIGHT_INTENSITY> m_dimensionCache;
};

#endif

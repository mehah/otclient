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

#include <framework/core/inputevent.h>
#include <framework/graphics/declarations.h>
#include <framework/graphics/paintershaderprogram.h>
#include <framework/luaengine/luaobject.h>
#include "lightview.h"

struct AwareRange
{
    uint8_t left{ 0 };
    uint8_t top{ 0 };
    uint8_t right{ 0 };
    uint8_t bottom{ 0 };

    uint8_t horizontal() const { return left + right + 1; }
    uint8_t vertical() const { return top + bottom + 1; }

    Size dimension() const { return { left * 2 + 1 , top * 2 + 1 }; }
};

struct MapPosInfo
{
    Rect rect;
    Rect srcRect;
    Point drawOffset;
    float horizontalStretchFactor;
    float verticalStretchFactor;

    bool isInRange(const Position& pos, bool ignoreZ = false) const
    {
        return camera.isInRange(pos, awareRange.left - 1, awareRange.right - 2, awareRange.top - 1, awareRange.bottom - 2, ignoreZ);
    }

    bool isInRangeEx(const Position& pos, bool ignoreZ = false)  const
    {
        return camera.isInRange(pos, awareRange.left, awareRange.right, awareRange.top, awareRange.bottom, ignoreZ);
    }

private:
    Position camera;
    AwareRange awareRange;

    friend class MapView;
};

// @bindclass
class MapView : public LuaObject
{
public:
    enum FloorViewMode
    {
        NORMAL,
        FADE,
        LOCKED,
        ALWAYS,
        ALWAYS_WITH_TRANSPARENCY
    };

    enum AntialiasingMode :uint8_t
    {
        ANTIALIASING_DISABLED,
        ANTIALIASING_ENABLED,
        ANTIALIASING_SMOOTH_RETRO
    };

    MapView();
    ~MapView() override;
    void draw();
    void drawText();

    // floor visibility related
    uint8_t getLockedFirstVisibleFloor() const { return m_lockedFirstVisibleFloor; }
    uint8_t getCachedFirstVisibleFloor() const { return m_cachedFirstVisibleFloor; }
    uint8_t getCachedLastVisibleFloor() const { return m_cachedLastVisibleFloor; }
    uint8_t getTileSize() const { return m_tileSize; }

    void lockFirstVisibleFloor(uint8_t firstVisibleFloor);
    void unlockFirstVisibleFloor();

    // map dimension related
    Size getVisibleDimension() { return m_visibleDimension; }
    void setVisibleDimension(const Size& visibleDimension);

    // view mode related
    FloorViewMode getFloorViewMode() const { return m_floorViewMode; }
    void setFloorViewMode(FloorViewMode viewMode);

    // camera related
    CreaturePtr getFollowingCreature() { return m_followingCreature; }
    void followCreature(const CreaturePtr& creature);
    bool isFollowingCreature() const { return m_followingCreature && m_follow; }

    Position getCameraPosition();
    void setCameraPosition(const Position& pos);

    void setMinimumAmbientLight(float intensity) { m_minimumAmbientLight = intensity; updateLight(); }
    float getMinimumAmbientLight() const { return m_minimumAmbientLight; }

    void setShadowFloorIntensity(float intensity) { m_shadowFloorIntensity = intensity; updateLight(); }
    float getShadowFloorIntensity() const { return m_shadowFloorIntensity; }

    void setDrawNames(bool enable) { m_drawNames = enable; }
    bool isDrawingNames() const { return m_drawNames; }

    void setDrawHealthBars(bool enable) { m_drawHealthBars = enable; }
    bool isDrawingHealthBars() const { return m_drawHealthBars; }

    void setDrawLights(bool enable);
    bool isDrawingLights() const { return m_drawingLight && m_lightView->isDark(); }

    void setLimitVisibleDimension(bool v) { m_limitVisibleDimension = v; }
    bool isLimitedVisibleDimension() const { return m_limitVisibleDimension; }

    void setDrawManaBar(bool enable) { m_drawManaBar = enable; }
    bool isDrawingManaBar() const { return m_drawManaBar; }

    void move(int32_t x, int32_t y);

    void setShader(const std::string_view name, float fadein, float fadeout);
    PainterShaderProgramPtr getShader() { return m_shader; }

    Position getPosition(const Point& point, const Size& mapSize);

    Position getPosition(const Point& mousePos);

    MapViewPtr asMapView() { return static_self_cast<MapView>(); }

    void resetLastCamera() { m_lastCameraPosition = {}; }

    std::vector<CreaturePtr> getSpectators(bool multiFloor = false);
    std::vector<CreaturePtr> getSightSpectators(bool multiFloor = false);

    bool isInRange(const Position& pos, bool ignoreZ = false)
    {
        return getCameraPosition().isInRange(pos, m_posInfo.awareRange.left - 1, m_posInfo.awareRange.right - 2, m_posInfo.awareRange.top - 1, m_posInfo.awareRange.bottom - 2, ignoreZ);
    }

    bool isInRangeEx(const Position& pos, bool ignoreZ = false)
    {
        return getCameraPosition().isInRange(pos, m_posInfo.awareRange.left, m_posInfo.awareRange.right, m_posInfo.awareRange.top, m_posInfo.awareRange.bottom, ignoreZ);
    }

    TilePtr getTopTile(Position tilePos) const;

    void setCrosshairTexture(const std::string& texturePath);
    void setAntiAliasingMode(AntialiasingMode mode);

    void onMouseMove(const Position& mousePos, bool isVirtualMove = false);
    void onKeyRelease(const InputEvent& inputEvent);

    void setLastMousePosition(const Position& mousePos) { m_mousePosition = mousePos; }
    const Position& getLastMousePosition() const { return m_mousePosition; }

    void setDrawHighlightTarget(const bool enable) { m_drawHighlightTarget = enable; }

    void setFloorFading(uint16_t value) { m_floorFading = value; }

    PainterShaderProgramPtr getNextShader() { return m_nextShader; }
    bool isSwitchingShader() { return !m_shaderSwitchDone; }

protected:
    void onGlobalLightChange(const Light& light);
    void onFloorChange(uint8_t floor, uint8_t previousFloor);
    void onTileUpdate(const Position& pos, const ThingPtr& thing, Otc::Operation operation);
    void onMapCenterChange(const Position& newPos, const Position& oldPos);
    void onCameraMove(const Point& offset);
    void onFadeInFinished();

    friend class Map;
    friend class UIMap;
    friend class Tile;
    friend class LightView;

private:
    enum class FadeType
    {
        NONE$, IN$, OUT$
    };

    struct MapObject
    {
        std::vector<TilePtr> shades;
        std::vector<TilePtr> tiles;
        void clear() { shades.clear(); tiles.clear(); }
    };

    struct FloorData
    {
        MapObject cachedVisibleTiles;
        stdext::timer fadingTimers;
    };

    struct Crosshair
    {
        bool positionChanged = false;
        Position position;
        TexturePtr texture;
    };

    void updateGeometry(const Size& visibleDimension);
    void updateVisibleTiles();
    void updateRect(const Rect& rect);
    void requestUpdateVisibleTiles() { m_updateVisibleTiles = true; }
    void requestUpdateMapPosInfo() { m_posInfo.rect = {}; }

    uint8_t calcFirstVisibleFloor(bool checkLimitsFloorsView) const;
    uint8_t calcLastVisibleFloor() const;

    void updateLight();
    void updateViewportDirectionCache();
    void drawFloor();

    void updateViewport(const Otc::Direction dir = Otc::InvalidDirection) { m_viewport = m_viewPortDirection[dir]; }

    bool canFloorFade() const { return m_floorViewMode == FADE && m_floorFading; }

    float getFadeLevel(uint8_t z) const
    {
        if (!canFloorFade()) return 1.f;

        float fading = std::clamp<float>(static_cast<float>(m_floors[z].fadingTimers.elapsed_millis()) / static_cast<float>(m_floorFading), 0.f, 1.f);
        if (z < m_cachedFirstVisibleFloor)
            fading = 1.0 - fading;
        return fading;
    }

    Rect calcFramebufferSource(const Size& destSize);

    Point transformPositionTo2D(const Position& position, const Position& relativePosition) const
    {
        return {
            (m_virtualCenterOffset.x + (position.x - relativePosition.x) - (relativePosition.z - position.z)) * m_tileSize,
                     (m_virtualCenterOffset.y + (position.y - relativePosition.y) - (relativePosition.z - position.z)) * m_tileSize
        };
    }

    int8_t m_lockedFirstVisibleFloor{ -1 };
    uint8_t m_cachedFirstVisibleFloor{ 0 };
    uint8_t m_cachedLastVisibleFloor{ 0 };
    uint8_t m_floorMin{ 0 };
    uint8_t m_floorMax{ 0 };

    uint16_t m_tileSize{ 0 };
    uint16_t m_floorFading = 500;

    float m_minimumAmbientLight{ 0 };
    float m_fadeInTime{ 0 };
    float m_fadeOutTime{ 0 };
    float m_shadowFloorIntensity{ 0 };

    Rect m_rectDimension;

    Size m_drawDimension;
    Size m_visibleDimension;

    Point m_virtualCenterOffset;
    Point m_moveOffset;

    Position m_customCameraPosition;
    Position m_lastCameraPosition;
    Position m_mousePosition;
    Position m_shaderPosition;

    std::array<AwareRange, Otc::InvalidDirection + 1> m_viewPortDirection;
    AwareRange m_viewport;

    bool m_limitVisibleDimension{ true };
    bool m_updateVisibleTiles{ true };
    bool m_resetCoveredCache{ true };
    bool m_shaderSwitchDone{ true };
    bool m_drawHealthBars{ true };
    bool m_drawManaBar{ true };
    bool m_drawNames{ true };
    bool m_smooth{ true };
    bool m_follow{ true };
    bool m_drawingLight{ true };

    bool m_fadeFinish{ false };
    bool m_autoViewMode{ false };
    bool m_drawViewportEdge{ false };
    bool m_forceDrawViewportEdge{ false };
    bool m_drawHighlightTarget{ false };
    bool m_shiftPressed{ false };

    FadeType m_fadeType{ FadeType::NONE$ };

    AntialiasingMode m_antiAliasingMode{ AntialiasingMode::ANTIALIASING_DISABLED };

    std::vector<FloorData> m_floors;

    PainterShaderProgramPtr m_shader;
    PainterShaderProgramPtr m_nextShader;
    LightViewPtr m_lightView;
    CreaturePtr m_followingCreature;

    MapPosInfo m_posInfo;
    FloorViewMode m_floorViewMode{ NORMAL };

    Timer m_fadeTimer;

    TilePtr m_lastHighlightTile;
    TexturePtr m_crosshairTexture;

    DrawConductor m_shadowConductor{ false, DrawOrder::FIFTH };
    DrawPool* m_pool;
};

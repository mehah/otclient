/*
 * Copyright (c) 2010-2025 OTClient <https://github.com/edubart/otclient>
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
#include "tile.h"
#include <framework/ui/uiwidget.h>

#include "mapview.h"

class UIMap final : public UIWidget
{
public:
    UIMap();
    ~UIMap() override;

    void drawSelf(DrawPoolType drawPane) override;
    void draw(DrawPoolType drawPane);

    void movePixels(const int x, const int y) { m_mapView->move(x, y); }
    void followCreature(const CreaturePtr& creature) { m_mapView->followCreature(creature); }
    void setCameraPosition(const Position& pos) { m_mapView->setCameraPosition(pos); }
    void setMaxZoomIn(const int maxZoomIn) { m_maxZoomIn = maxZoomIn; }
    void setMaxZoomOut(const int maxZoomOut) { m_maxZoomOut = maxZoomOut; }
    void lockVisibleFloor(const int floor) { m_mapView->lockFirstVisibleFloor(floor); }
    void unlockVisibleFloor() { m_mapView->unlockFirstVisibleFloor(); }
    void setVisibleDimension(const Size& visibleDimension);
    void setFloorViewMode(const MapView::FloorViewMode viewMode) { m_mapView->setFloorViewMode(viewMode); }
    void setDrawNames(const bool enable) { m_mapView->setDrawNames(enable); }
    void setDrawHealthBars(const bool enable) { m_mapView->setDrawHealthBars(enable); }
    void setDrawLights(const bool enable) { m_mapView->setDrawLights(enable); }
    void setLimitVisibleDimension(const bool enable) { m_mapView->setLimitVisibleDimension(enable); updateVisibleDimension(); }
    void setDrawManaBar(const bool enable) { m_mapView->setDrawManaBar(enable); }
    void setKeepAspectRatio(bool enable);
    void setShader(const std::string_view name, const float fadein, const float fadeout) { m_mapView->setShader(name, fadein, fadeout); }
    void setMinimumAmbientLight(const float intensity) { m_mapView->setMinimumAmbientLight(intensity); }
    void setLimitVisibleRange(const bool limitVisibleRange) { m_limitVisibleRange = limitVisibleRange; updateVisibleDimension(); }
    void setDrawViewportEdge(const bool force) { m_mapView->m_forceDrawViewportEdge = force; m_mapView->m_visibleDimension = {}; updateVisibleDimension(); }

    bool zoomIn();
    bool zoomOut();
    bool setZoom(int zoom);
    bool isDrawingNames() { return m_mapView->isDrawingNames(); }
    bool isDrawingHealthBars() { return m_mapView->isDrawingHealthBars(); }
    bool isDrawingLights() { return m_mapView->isDrawingLights(); }
    bool isLimitedVisibleDimension() { return m_mapView->isLimitedVisibleDimension(); }
    bool isDrawingManaBar() { return m_mapView->isDrawingManaBar(); }
    bool isKeepAspectRatioEnabled() { return m_keepAspectRatio; }
    bool isLimitVisibleRangeEnabled() { return m_limitVisibleRange; }
    bool isSwitchingShader() { return m_mapView->isSwitchingShader(); }

    void setShadowFloorIntensity(const float intensity) { m_mapView->setShadowFloorIntensity(intensity); }

    std::vector<CreaturePtr> getSpectators(const bool multiFloor = false) { return m_mapView->getSpectators(multiFloor); }
    std::vector<CreaturePtr> getSightSpectators(const bool multiFloor = false) { return m_mapView->getSightSpectators(multiFloor); }
    bool isInRange(const Position& pos) { return m_mapView->isInRange(pos); }

    PainterShaderProgramPtr getShader() { return m_mapView->getShader(); }
    PainterShaderProgramPtr getNextShader() { return m_mapView->getNextShader(); }
    MapView::FloorViewMode getFloorViewMode() { return m_mapView->getFloorViewMode(); }
    CreaturePtr getFollowingCreature() { return m_mapView->getFollowingCreature(); }
    Position getCameraPosition() { return m_mapView->getCameraPosition(); }
    Position getPosition(const Point& mousePos) { return m_mapView->getPosition(mousePos); }
    TilePtr getTile(const Point& mousePos) { return m_mapView->getTopTile(getPosition(mousePos)); }
    Size getVisibleDimension() { return m_mapView->getVisibleDimension(); }

    int getMaxZoomIn() { return m_maxZoomIn; }
    int getMaxZoomOut() { return m_maxZoomOut; }
    int getZoom() { return m_zoom; }

    float getMinimumAmbientLight() { return m_mapView->getMinimumAmbientLight(); }

    void setCrosshairTexture(const std::string& texturePath) { m_mapView->setCrosshairTexture(texturePath); }
    void setDrawHighlightTarget(const bool enable) { m_mapView->setDrawHighlightTarget(enable); }
    void setAntiAliasingMode(const MapView::AntialiasingMode mode) { m_mapView->setAntiAliasingMode(mode); }
    void setFloorFading(const uint16_t v) { m_mapView->setFloorFading(v); }
    MapViewPtr getMapView() const { return m_mapView; }
    void clearTiles() {
        m_mapView->m_foregroundTiles.clear();
    }

    void updateMapRect();

protected:
    void onStyleApply(std::string_view styleName, const OTMLNodePtr& styleNode) override;
    void onGeometryChange(const Rect& oldRect, const Rect& newRect) override;
    bool onMouseMove(const Point& mousePos, const Point& mouseMoved) override;
    bool onMousePress(const Point& mousePos, Fw::MouseButton button) override;
    bool onMouseRelease(const Point& mousePos, Fw::MouseButton button) override;
    bool onMouseWheel(const Point& mousePos, Fw::MouseWheelDirection direction) override;

private:
    void updateVisibleDimension();
    void updateMapSize();

    MapViewPtr m_mapView;
    Rect m_mapRect;
    Rect m_mapviewRect;

    float m_aspectRatio;

    bool m_keepAspectRatio;
    bool m_limitVisibleRange;

    uint16_t m_maxZoomIn;
    uint16_t m_maxZoomOut;
    uint16_t m_zoom;

    friend class Client;
};

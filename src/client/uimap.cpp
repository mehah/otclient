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

#include "uimap.h"
#include <framework/core/graphicalapplication.h>
#include <framework/graphics/drawpoolmanager.h>
#include <framework/graphics/graphics.h>
#include "game.h"
#include "map.h"
#include "mapview.h"

UIMap::UIMap()
{
    setProp(PropDraggable, true);
    m_keepAspectRatio = true;
    m_limitVisibleRange = false;
    m_maxZoomIn = 3;
    m_maxZoomOut = 513;
    m_mapView = std::make_shared<MapView>();
    m_zoom = m_mapView->getVisibleDimension().height();
    m_aspectRatio = m_mapView->getVisibleDimension().ratio();

    m_mapRect.resize(1, 1);
    g_map.addMapView(m_mapView);
}

UIMap::~UIMap()
{
    g_map.removeMapView(m_mapView);
}

void UIMap::drawSelf(DrawPoolType drawPane)
{
    UIWidget::drawSelf(drawPane);

    if (drawPane == DrawPoolType::FOREGROUND) {
        g_drawPool.addBoundingRect(m_mapRect.expanded(1), Color::black);
        g_drawPool.addAction([] {glDisable(GL_BLEND); });
        g_drawPool.addFilledRect(m_mapRect, Color::alpha);
        g_drawPool.addAction([] {glEnable(GL_BLEND); });
        return;
    }

    const auto& mapSize = g_app.isScaled() ? Rect(0, 0, g_graphics.getViewportSize()) : m_mapRect;
    m_mapView->updateRect(mapSize);

    if (drawPane == DrawPoolType::MAP) {
        m_mapView->draw();
    } else if (drawPane == DrawPoolType::TEXT) {
        m_mapView->drawText();
    }
}

void UIMap::movePixels(int x, int y)
{
    m_mapView->move(x, y);
}

bool UIMap::setZoom(int zoom)
{
    m_zoom = std::clamp<int>(zoom, m_maxZoomIn, m_maxZoomOut);
    updateVisibleDimension();
    return false;
}

bool UIMap::zoomIn()
{
    int delta = 2;
    if (m_zoom - delta < m_maxZoomIn)
        --delta;

    if (m_zoom - delta < m_maxZoomIn)
        return false;

    const auto oldZoom = m_zoom;

    m_zoom -= delta;
    updateVisibleDimension();

    callLuaField("onZoomChange", m_zoom, oldZoom);

    return true;
}

bool UIMap::zoomOut()
{
    int delta = 2;
    if (m_zoom + delta > m_maxZoomOut)
        --delta;

    if (m_zoom + delta > m_maxZoomOut)
        return false;

    const auto oldZoom = m_zoom;

    m_zoom += 2;
    updateVisibleDimension();

    callLuaField("onZoomChange", m_zoom, oldZoom);

    return true;
}

void UIMap::setVisibleDimension(const Size& visibleDimension)
{
    m_mapView->setVisibleDimension(visibleDimension);
    m_aspectRatio = visibleDimension.ratio();

    if (m_keepAspectRatio)
        updateMapSize();
}

void UIMap::setKeepAspectRatio(bool enable)
{
    m_keepAspectRatio = enable;
    if (enable)
        m_aspectRatio = getVisibleDimension().ratio();
    updateMapSize();
}

Position UIMap::getPosition(const Point& mousePos) {
    return m_mapView->getPosition(mousePos);
}

TilePtr UIMap::getTile(const Point& mousePos)
{
    const Position tilePos = getPosition(mousePos);
    if (!tilePos.isValid())
        return nullptr;

    return m_mapView->getTopTile(tilePos);
}

void UIMap::onStyleApply(const std::string_view styleName, const OTMLNodePtr& styleNode)
{
    UIWidget::onStyleApply(styleName, styleNode);
    for (const auto& node : styleNode->children()) {
        if (node->tag() == "draw-lights")
            setDrawLights(node->value<bool>());
    }
}

void UIMap::onGeometryChange(const Rect& oldRect, const Rect& newRect)
{
    UIWidget::onGeometryChange(oldRect, newRect);
    updateMapSize();
}

bool UIMap::onMouseMove(const Point& mousePos, const Point& mouseMoved)
{
    const Position& pos = getPosition(mousePos);
    if (!pos.isValid())
        return false;

    if (m_mapView->getLastMousePosition() != pos) {
        m_mapView->onMouseMove(pos);
        m_mapView->setLastMousePosition(pos);
    }

    return UIWidget::onMouseMove(mousePos, mouseMoved);
}

void UIMap::updateVisibleDimension()
{
    int dimensionHeight = m_zoom;

    float ratio = m_aspectRatio;
    if (!m_limitVisibleRange && !m_mapRect.isEmpty() && !m_keepAspectRatio)
        ratio = m_mapRect.size().ratio();

    if (dimensionHeight % 2 == 0)
        dimensionHeight += 1;
    int dimensionWidth = m_zoom * ratio;
    if (dimensionWidth % 2 == 0)
        dimensionWidth += 1;

    m_mapView->setVisibleDimension(Size(dimensionWidth, dimensionHeight));

    if (m_keepAspectRatio)
        updateMapSize();
}

void UIMap::updateMapSize()
{
    const auto& clippingRect = getPaddingRect();
    Size mapSize;
    if (m_keepAspectRatio) {
        const auto& mapRect = clippingRect.expanded(-1);
        mapSize = { static_cast<int>(m_aspectRatio * m_zoom), m_zoom };
        mapSize.scale(mapRect.size(), Fw::KeepAspectRatio);
    } else {
        mapSize = clippingRect.expanded(-1).size();
    }

    m_mapRect.resize(mapSize);
    m_mapRect.moveCenter(clippingRect.center());

    if (!m_keepAspectRatio)
        updateVisibleDimension();
}

/* vim: set ts=4 sw=4 et: */
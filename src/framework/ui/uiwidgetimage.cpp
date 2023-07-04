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

#include <framework/core/eventdispatcher.h>
#include <framework/graphics/painter.h>
#include <framework/graphics/animatedtexture.h>
#include <framework/graphics/texture.h>
#include <framework/graphics/texturemanager.h>
#include "uiwidget.h"
#include "framework/graphics/drawpoolmanager.h"

void UIWidget::initImage() {}

void UIWidget::parseImageStyle(const OTMLNodePtr& styleNode)
{
    for (const auto& node : styleNode->children()) {
        if (node->tag() == "image-source")
            setImageSource(stdext::resolve_path(node->value(), node->source()));
        else if (node->tag() == "image-offset-x")
            setImageOffsetX(node->value<int>());
        else if (node->tag() == "image-offset-y")
            setImageOffsetY(node->value<int>());
        else if (node->tag() == "image-offset")
            setImageOffset(node->value<Point>());
        else if (node->tag() == "image-width")
            setImageWidth(node->value<int>());
        else if (node->tag() == "image-height")
            setImageHeight(node->value<int>());
        else if (node->tag() == "image-size")
            setImageSize(node->value<Size>());
        else if (node->tag() == "image-rect")
            setImageRect(node->value<Rect>());
        else if (node->tag() == "image-clip")
            setImageClip(node->value<Rect>());
        else if (node->tag() == "image-fixed-ratio")
            setImageFixedRatio(node->value<bool>());
        else if (node->tag() == "image-repeated")
            setImageRepeated(node->value<bool>());
        else if (node->tag() == "image-smooth")
            setImageSmooth(node->value<bool>());
        else if (node->tag() == "image-color")
            setImageColor(node->value<Color>());
        else if (node->tag() == "image-border-top")
            setImageBorderTop(node->value<int>());
        else if (node->tag() == "image-border-right")
            setImageBorderRight(node->value<int>());
        else if (node->tag() == "image-border-bottom")
            setImageBorderBottom(node->value<int>());
        else if (node->tag() == "image-border-left")
            setImageBorderLeft(node->value<int>());
        else if (node->tag() == "image-border")
            setImageBorder(node->value<int>());
        else if (node->tag() == "image-auto-resize")
            setImageAutoResize(node->value<bool>());
        else if (node->tag() == "image-individual-animation")
            setImageIndividualAnimation(node->value<bool>());
    }
}

void UIWidget::drawImage(const Rect& screenCoords)
{
    if (!m_imageTexture || !screenCoords.isValid())
        return;

    // cache vertex buffers
    if (m_imageCachedScreenCoords != screenCoords) {
        m_imageCachedScreenCoords = screenCoords;
        m_imageCoordsCache.clear();

        Rect drawRect = screenCoords;
        drawRect.translate(m_imageRect.topLeft());
        if (m_imageRect.isValid())
            drawRect.resize(m_imageRect.size());

        auto clipRect = m_imageClipRect.isValid() ? m_imageClipRect : Rect(0, 0, m_imageTexture->getSize());

        if (hasProp(PropImageBordered)) {
            int top = m_imageBorder.top;
            int bottom = m_imageBorder.bottom;
            int left = m_imageBorder.left;
            int right = m_imageBorder.right;

            // calculates border coords
            Rect leftBorder(clipRect.left(), clipRect.top() + top, left, clipRect.height() - top - bottom);
            Rect rightBorder(clipRect.right() - right + 1, clipRect.top() + top, right, clipRect.height() - top - bottom);
            Rect topBorder(clipRect.left() + left, clipRect.top(), clipRect.width() - right - left, top);
            Rect bottomBorder(clipRect.left() + left, clipRect.bottom() - bottom + 1, clipRect.width() - right - left, bottom);
            Rect topLeftCorner(clipRect.left(), clipRect.top(), left, top);
            Rect topRightCorner(clipRect.right() - right + 1, clipRect.top(), right, top);
            Rect bottomLeftCorner(clipRect.left(), clipRect.bottom() - bottom + 1, left, bottom);
            Rect bottomRightCorner(clipRect.right() - right + 1, clipRect.bottom() - bottom + 1, right, bottom);
            Rect center(clipRect.left() + left, clipRect.top() + top, clipRect.width() - right - left, clipRect.height() - top - bottom);
            Size bordersSize(leftBorder.width() + rightBorder.width(), topBorder.height() + bottomBorder.height());
            Size centerSize = drawRect.size() - bordersSize;
            Rect rectCoords;

            // first the center
            if (centerSize.area() > 0) {
                rectCoords = Rect(drawRect.left() + leftBorder.width(), drawRect.top() + topBorder.height(), centerSize);
                m_imageCoordsCache.emplace_back(rectCoords, center);
            }
            // top left corner
            rectCoords = Rect(drawRect.topLeft(), topLeftCorner.size());
            m_imageCoordsCache.emplace_back(rectCoords, topLeftCorner);
            // top
            rectCoords = Rect(drawRect.left() + topLeftCorner.width(), drawRect.topLeft().y, centerSize.width(), topBorder.height());
            m_imageCoordsCache.emplace_back(rectCoords, topBorder);
            // top right corner
            rectCoords = Rect(drawRect.left() + topLeftCorner.width() + centerSize.width(), drawRect.top(), topRightCorner.size());
            m_imageCoordsCache.emplace_back(rectCoords, topRightCorner);
            // left
            rectCoords = Rect(drawRect.left(), drawRect.top() + topLeftCorner.height(), leftBorder.width(), centerSize.height());
            m_imageCoordsCache.emplace_back(rectCoords, leftBorder);
            // right
            rectCoords = Rect(drawRect.left() + leftBorder.width() + centerSize.width(), drawRect.top() + topRightCorner.height(), rightBorder.width(), centerSize.height());
            m_imageCoordsCache.emplace_back(rectCoords, rightBorder);
            // bottom left corner
            rectCoords = Rect(drawRect.left(), drawRect.top() + topLeftCorner.height() + centerSize.height(), bottomLeftCorner.size());
            m_imageCoordsCache.emplace_back(rectCoords, bottomLeftCorner);
            // bottom
            rectCoords = Rect(drawRect.left() + bottomLeftCorner.width(), drawRect.top() + topBorder.height() + centerSize.height(), centerSize.width(), bottomBorder.height());
            m_imageCoordsCache.emplace_back(rectCoords, bottomBorder);
            // bottom right corner
            rectCoords = Rect(drawRect.left() + bottomLeftCorner.width() + centerSize.width(), drawRect.top() + topRightCorner.height() + centerSize.height(), bottomRightCorner.size());
            m_imageCoordsCache.emplace_back(rectCoords, bottomRightCorner);
        } else {
            if (isImageFixedRatio()) {
                Size textureSize = m_imageTexture->getSize(),
                    textureClipSize = drawRect.size();

                textureClipSize.scale(textureSize, Fw::KeepAspectRatio);

                Point texCoordsOffset;
                if (textureSize.height() > textureClipSize.height())
                    texCoordsOffset.y = (textureSize.height() - textureClipSize.height()) / 2;
                else if (textureSize.width() > textureClipSize.width())
                    texCoordsOffset.x = (textureSize.width() - textureClipSize.width()) / 2;

                clipRect = Rect(texCoordsOffset, textureClipSize);
            }

            m_imageCoordsCache.emplace_back(drawRect, clipRect);
        }
    }

    // smooth is now enabled by default for all textures
    //m_imageTexture->setSmooth(m_imageSmooth);
    const bool useRepeated = hasProp(PropImageBordered) || hasProp(PropImageRepeated);

    const auto& texture = m_imageTexture->isAnimatedTexture() && isImageIndividualAnimation() ?
        std::static_pointer_cast<AnimatedTexture>(m_imageTexture)->get(m_currentFrame, m_imageAnimatorTimer) : m_imageTexture;

    for (const auto& [dest, src] : m_imageCoordsCache) {
        if (useRepeated)
            g_drawPool.addTexturedRepeatedRect(dest, texture, src, m_imageColor);
        else
            g_drawPool.addTexturedRect(dest, texture, src, m_imageColor);
    }
}

void UIWidget::setImageSource(const std::string_view source)
{
    updateImageCache();

    if (source.empty()) {
        m_imageTexture = nullptr;
        m_imageSource = {};
        return;
    }

    m_imageTexture = g_textures.getTexture(m_imageSource = source, isImageSmooth());
    if (!m_imageTexture)
        return;

    if (m_imageTexture->isAnimatedTexture()) {
        if (isImageIndividualAnimation()) {
            m_imageAnimatorTimer.restart();
            m_currentFrame = 0;
        } else
            std::static_pointer_cast<AnimatedTexture>(m_imageTexture)->restart();
    }

    if (!m_rect.isValid() || hasProp(PropImageAutoResize)) {
        const auto& imageSize = m_imageTexture->getSize();

        Size size = getSize();
        if (size.width() <= 0 || hasProp(PropImageAutoResize))
            size.setWidth(imageSize.width());

        if (size.height() <= 0 || hasProp(PropImageAutoResize))
            size.setHeight(imageSize.height());

        setSize(size);
    }
}
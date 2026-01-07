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

#include "uisprite.h"
#include <client/thingtypemanager.h>
#include "framework/graphics/drawpoolmanager.h"
#include "framework/otml/otmlnode.h"

void UISprite::drawSelf(const DrawPoolType drawPane)
{
    if (drawPane != DrawPoolType::FOREGROUND)
        return;

    // draw style components in order
    if (m_backgroundColor.aF() > Fw::MIN_ALPHA) {
        Rect backgroundDestRect = m_rect;
        backgroundDestRect.expand(-m_borderWidth.top, -m_borderWidth.right, -m_borderWidth.bottom, -m_borderWidth.left);
        drawBackground(m_rect);
    }

    drawImage(m_rect);

    if (m_spriteVisible && m_sprite) {
        g_drawPool.addTexturedRect(getPaddingRect(), m_sprite, m_spriteColor);
    }

    drawBorder(m_rect);
    drawIcon(m_rect);
    drawText(m_rect);
}

void UISprite::setSpriteId(const int id, const uint16_t resourceId)
{
    if (!g_things.isSprLoaded(resourceId))
        return;

    m_spriteId = id;
    if (id == 0) {
        m_sprite = nullptr;
        return;
    }

    m_sprite = nullptr;
    bool isLoading = false;
    if (const auto& image = g_things.getSpriteImage(id, resourceId, isLoading)) {
        m_sprite = std::make_shared<Texture>(image);
        m_sprite->allowAtlasCache();
    }
}

void UISprite::onStyleApply(const std::string_view styleName, const OTMLNodePtr& styleNode)
{
    UIWidget::onStyleApply(styleName, styleNode);

    uint16_t spriteId = 0;
    uint16_t spriteResourceId = 0;

    for (const auto& node : styleNode->children()) {
        const std::string tag = node->tag();
        if (tag == "sprite-id")
            spriteId = node->value<int>();
        else if (tag == "sprite-resource-id")
            spriteResourceId = node->value<int>();
        else if (tag == "sprite-visible")
            setSpriteVisible(node->value<bool>());
        else if (tag == "sprite-color")
            setSpriteColor(node->value<Color>());
    }

    setSpriteId(spriteId, spriteResourceId);
}

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

#include "bitmapfont.h"
#include "graphics.h"
#include "image.h"
#include "texturemanager.h"
#include "textureatlas.h"

#include <framework/otml/otml.h>

#include "drawpoolmanager.h"

static thread_local std::vector<Point> s_glyphsPositions(1);
static thread_local std::vector<int>   s_lineWidths(1);

void BitmapFont::load(const OTMLNodePtr& fontNode)
{
    const auto& textureNode = fontNode->at("texture");
    const auto& textureFile = stdext::resolve_path(textureNode->value(), textureNode->source());
    const auto& glyphSize = fontNode->valueAt<Size>("glyph-size");
    const int spaceWidth = fontNode->valueAt("space-width", glyphSize.width());

    m_glyphHeight = fontNode->valueAt<int>("height");
    m_yOffset = fontNode->valueAt("y-offset", 0);
    m_firstGlyph = fontNode->valueAt("first-glyph", 32);
    m_glyphSpacing = fontNode->valueAt("spacing", Size(0));

    m_texture = g_textures.getTexture(textureFile, false);
    if (!m_texture)
        return;
    m_texture->create();

    const Size textureSize = m_texture->getSize();

    if (const auto& node = fontNode->get("fixed-glyph-width")) {
        for (int glyph = m_firstGlyph; glyph < 256; ++glyph)
            m_glyphsSize[glyph] = Size(node->value<int>(), m_glyphHeight);
    } else {
        calculateGlyphsWidthsAutomatically(Image::load(textureFile), glyphSize);
    }

    m_glyphsSize[32].setWidth(spaceWidth);
    m_glyphsSize[160].setWidth(spaceWidth);
    m_glyphsSize[127].setWidth(1);
    m_glyphsSize[static_cast<uint8_t>('\n')] = { 1, m_glyphHeight };

    const int numHorizontalGlyphs = textureSize.width() / glyphSize.width();
    for (int glyph = m_firstGlyph; glyph < 256; ++glyph) {
        m_glyphsTextureCoords[glyph].setRect(((glyph - m_firstGlyph) % numHorizontalGlyphs) * glyphSize.width(),
                                             ((glyph - m_firstGlyph) / numHorizontalGlyphs) * glyphSize.height(),
                                             m_glyphsSize[glyph].width(),
                                             m_glyphHeight);
    }
}

void BitmapFont::drawText(const std::string_view text, const Point& startPos, const Color& color)
{
    const Size boxSize = g_painter->getResolution() - startPos.toSize();
    const Rect screenCoords(startPos, boxSize);
    drawText(text, screenCoords, color, Fw::AlignTopLeft);
}

void BitmapFont::drawText(const std::string_view text, const Rect& screenCoords, const Color& color, const Fw::AlignmentFlag align)
{
    Size textBoxSize;
    calculateGlyphsPositions(text, align, s_glyphsPositions, &textBoxSize);

    auto pairs = getDrawTextCoords(text, textBoxSize, align, screenCoords, s_glyphsPositions);
    for (const auto& p : pairs) {
        g_drawPool.addTexturedRect(p.first, m_texture, p.second, color);
    }
}

inline bool BitmapFont::clipAndTranslateGlyph(Rect& glyphScreenCoords, Rect& glyphTextureCoords, const Rect& screenCoords) const noexcept
{
    if (glyphScreenCoords.bottom() < 0 || glyphScreenCoords.right() < 0)
        return false;

    if (glyphScreenCoords.top() < 0) {
        glyphTextureCoords.setTop(glyphTextureCoords.top() - glyphScreenCoords.top());
        glyphScreenCoords.setTop(0);
    }
    if (glyphScreenCoords.left() < 0) {
        glyphTextureCoords.setLeft(glyphTextureCoords.left() - glyphScreenCoords.left());
        glyphScreenCoords.setLeft(0);
    }

    glyphScreenCoords.translate(screenCoords.topLeft());

    if (!screenCoords.intersects(glyphScreenCoords))
        return false;

    if (glyphScreenCoords.bottom() > screenCoords.bottom()) {
        glyphTextureCoords.setBottom(glyphTextureCoords.bottom() + (screenCoords.bottom() - glyphScreenCoords.bottom()));
        glyphScreenCoords.setBottom(screenCoords.bottom());
    }
    if (glyphScreenCoords.right() > screenCoords.right()) {
        glyphTextureCoords.setRight(glyphTextureCoords.right() + (screenCoords.right() - glyphScreenCoords.right()));
        glyphScreenCoords.setRight(screenCoords.right());
    }

    return true;
}

std::vector<std::pair<Rect, Rect>> BitmapFont::getDrawTextCoords(const std::string_view text,
                                                                 const Size& textBoxSize,
                                                                 const Fw::AlignmentFlag align,
                                                                 const Rect& screenCoords,
                                                                 const std::vector<Point>& glyphsPositions) const noexcept
{
    std::vector<std::pair<Rect, Rect>> list;
    if (!screenCoords.isValid() || !m_texture)
        return list;

    const int textLength = static_cast<int>(text.length());
    list.reserve(textLength);

    int dx = 0;
    int dy = 0;

    if (align & Fw::AlignBottom) {
        dy = screenCoords.height() - textBoxSize.height();
    } else if (align & Fw::AlignVerticalCenter) {
        dy = (screenCoords.height() - textBoxSize.height()) / 2;
    }

    if (align & Fw::AlignRight) {
        dx = screenCoords.width() - textBoxSize.width();
    } else if (align & Fw::AlignHorizontalCenter) {
        dx = (screenCoords.width() - textBoxSize.width()) / 2;
    }

    const AtlasRegion* region = m_texture->getAtlasRegion();

    for (int i = 0; i < textLength; ++i) {
        const int glyph = static_cast<uint8_t>(text[i]);
        if (glyph < 32) continue;

        Rect glyphScreenCoords(glyphsPositions[i] + Point(dx, dy), m_glyphsSize[glyph]);
        Rect glyphTextureCoords = m_glyphsTextureCoords[glyph];

        if (!clipAndTranslateGlyph(glyphScreenCoords, glyphTextureCoords, screenCoords))
            continue;

        if (region)
            glyphTextureCoords.translate(region->x, region->y);

        list.emplace_back(glyphScreenCoords, glyphTextureCoords);
    }

    return list;
}

void BitmapFont::fillTextCoords(const CoordsBufferPtr& coords, const std::string_view text,
                                const Size& textBoxSize, const Fw::AlignmentFlag align, const Rect& screenCoords,
                                const std::vector<Point>& glyphsPositions) const noexcept
{
    coords->clear();
    if (!screenCoords.isValid() || !m_texture)
        return;

    const int textLength = static_cast<int>(text.length());

    int dx = 0;
    int dy = 0;

    if (align & Fw::AlignBottom) {
        dy = screenCoords.height() - textBoxSize.height();
    } else if (align & Fw::AlignVerticalCenter) {
        dy = (screenCoords.height() - textBoxSize.height()) / 2;
    }

    if (align & Fw::AlignRight) {
        dx = screenCoords.width() - textBoxSize.width();
    } else if (align & Fw::AlignHorizontalCenter) {
        dx = (screenCoords.width() - textBoxSize.width()) / 2;
    }

    const AtlasRegion* region = m_texture->getAtlasRegion();

    for (int i = 0; i < textLength; ++i) {
        const int glyph = static_cast<uint8_t>(text[i]);
        if (glyph < 32) continue;

        Rect glyphScreenCoords(glyphsPositions[i] + Point(dx, dy), m_glyphsSize[glyph]);
        Rect glyphTextureCoords = m_glyphsTextureCoords[glyph];

        if (!clipAndTranslateGlyph(glyphScreenCoords, glyphTextureCoords, screenCoords))
            continue;

        if (region)
            glyphTextureCoords.translate(region->x, region->y);

        coords->addRect(glyphScreenCoords, glyphTextureCoords);
    }
}

void BitmapFont::fillTextColorCoords(std::vector<std::pair<Color, CoordsBufferPtr>>& colorCoords, const std::string_view text,
                                     const std::vector<std::pair<int, Color>> textColors,
                                     const Size& textBoxSize, const Fw::AlignmentFlag align,
                                     const Rect& screenCoords, const std::vector<Point>& glyphsPositions) const noexcept
{
    colorCoords.clear();
    if (!screenCoords.isValid() || !m_texture)
        return;

    const int textLength = static_cast<int>(text.length());
    const int textColorsSize = static_cast<int>(textColors.size());

    std::unordered_map<uint32_t, CoordsBufferPtr> colorCoordsMap;
    uint32_t curColorRgba = 0;
    int32_t nextColorIndex = 0;
    int32_t colorIndex = -1;
    CoordsBufferPtr coords;

    for (int i = 0; i < textLength; ++i) {
        if (i >= nextColorIndex) {
            colorIndex = colorIndex + 1;
            if (colorIndex < textColorsSize) {
                curColorRgba = textColors[colorIndex].second.rgba();
            }
            if (colorIndex + 1 < textColorsSize) {
                nextColorIndex = textColors[colorIndex + 1].first;
            } else {
                nextColorIndex = textLength;
            }

            auto it = colorCoordsMap.find(curColorRgba);
            if (it == colorCoordsMap.end()) {
                coords = std::make_shared<CoordsBuffer>();
                colorCoordsMap.emplace(curColorRgba, coords);
            } else {
                coords = it->second;
            }
        }

        const int glyph = static_cast<uint8_t>(text[i]);
        if (glyph < 32) continue;

        Rect glyphScreenCoords(glyphsPositions[i], m_glyphsSize[glyph]);
        Rect glyphTextureCoords = m_glyphsTextureCoords[glyph];

        int dx = 0, dy = 0;
        if (align & Fw::AlignBottom) {
            dy = screenCoords.height() - textBoxSize.height();
        } else if (align & Fw::AlignVerticalCenter) {
            dy = (screenCoords.height() - textBoxSize.height()) / 2;
        }
        if (align & Fw::AlignRight) {
            dx = screenCoords.width() - textBoxSize.width();
        } else if (align & Fw::AlignHorizontalCenter) {
            dx = (screenCoords.width() - textBoxSize.width()) / 2;
        }

        glyphScreenCoords.translate(dx, dy);

        if (!clipAndTranslateGlyph(glyphScreenCoords, glyphTextureCoords, screenCoords))
            continue;

        if (const AtlasRegion* region = m_texture->getAtlasRegion())
            glyphTextureCoords.translate(region->x, region->y);

        coords->addRect(glyphScreenCoords, glyphTextureCoords);
    }

    colorCoords.reserve(colorCoordsMap.size());
    for (auto& kv : colorCoordsMap) {
        colorCoords.emplace_back(Color(kv.first), kv.second);
    }
}

void BitmapFont::calculateGlyphsPositions(std::string_view text,
                                          Fw::AlignmentFlag align,
                                          std::vector<Point>& glyphsPositions,
                                          Size* textBoxSize) const noexcept
{
    const int textLength = static_cast<int>(text.size());
    int maxLineWidth = 0;
    int lines = 0;

    if (textBoxSize && textLength == 0) {
        textBoxSize->resize(0, m_glyphHeight);
        return;
    }

    if (std::cmp_less(glyphsPositions.size(), textLength))
        glyphsPositions.resize(textLength);
    if (std::cmp_less(glyphsPositions.capacity(), textLength))
        glyphsPositions.reserve(std::max(1024, textLength));

    const unsigned char* p = reinterpret_cast<const unsigned char*>(text.data());
    const Size* __restrict widths = m_glyphsSize;

    const bool needLines =
        (align & Fw::AlignRight) || (align & Fw::AlignHorizontalCenter) || (textBoxSize != nullptr);

    if (needLines) {
        if (s_lineWidths.empty()) s_lineWidths.resize(1);
        s_lineWidths[0] = 0;

        for (int i = 0; i < textLength; ++i) {
            const unsigned char g = p[i];
            if (g == static_cast<unsigned char>('\n')) {
                ++lines;
                if (lines + 1 > static_cast<int>(s_lineWidths.size()))
                    s_lineWidths.resize(lines + 1);
                s_lineWidths[lines] = 0;
                continue;
            }
            if (g >= 32) {
                s_lineWidths[lines] += widths[g].width();
                if (i + 1 != textLength && p[i + 1] != static_cast<unsigned char>('\n'))
                    s_lineWidths[lines] += m_glyphSpacing.width();
                if (s_lineWidths[lines] > maxLineWidth)
                    maxLineWidth = s_lineWidths[lines];
            }
        }
    }

    Point vpos(0, m_yOffset);
    lines = 0;

    for (int i = 0; i < textLength; ++i) {
        const unsigned char g = p[i];

        if (g == static_cast<unsigned char>('\n') || i == 0) {
            if (g == static_cast<unsigned char>('\n')) {
                vpos.y += m_glyphHeight + m_glyphSpacing.height();
                ++lines;
            }
            if (align & Fw::AlignRight) {
                vpos.x = (maxLineWidth - (needLines ? s_lineWidths[lines] : 0));
            } else if (align & Fw::AlignHorizontalCenter) {
                vpos.x = (maxLineWidth - (needLines ? s_lineWidths[lines] : 0)) / 2;
            } else {
                vpos.x = 0;
            }
        }

        if (g >= 32 && g != static_cast<unsigned char>('\n')) {
            glyphsPositions[i] = vpos;
            vpos.x += widths[g].width() + m_glyphSpacing.width();
        }
    }

    if (textBoxSize) {
        textBoxSize->setWidth(maxLineWidth);
        textBoxSize->setHeight(vpos.y + m_glyphHeight);
    }
}

Size BitmapFont::calculateTextRectSize(const std::string_view text)
{
    Size size;
    calculateGlyphsPositions(text, Fw::AlignTopLeft, s_glyphsPositions, &size);
    return size;
}

void BitmapFont::calculateGlyphsWidthsAutomatically(const ImagePtr& image, const Size& glyphSize)
{
    if (!image)
        return;

    const auto& imageSize = image->getSize();
    const auto& texturePixels = image->getPixels();
    const int numHorizontalGlyphs = imageSize.width() / glyphSize.width();

    for (int glyph = m_firstGlyph; glyph < 256; ++glyph) {
        Rect glyphCoords(((glyph - m_firstGlyph) % numHorizontalGlyphs) * glyphSize.width(),
                         ((glyph - m_firstGlyph) / numHorizontalGlyphs) * glyphSize.height(),
                         glyphSize.width(),
                         m_glyphHeight);

        int width = glyphSize.width();
        for (int x = glyphCoords.left(); x <= glyphCoords.right(); ++x) {
            bool anyFilled = false;
            const int base = x * 4;
            for (int y = glyphCoords.top(); y <= glyphCoords.bottom(); ++y) {
                if (texturePixels[(y * imageSize.width() * 4) + base + 3] != 0) {
                    anyFilled = true;
                    break;
                }
            }
            if (anyFilled)
                width = x - glyphCoords.left() + 1;
        }
        m_glyphsSize[glyph].resize(width, m_glyphHeight);
    }
}

std::string BitmapFont::wrapText(const std::string_view text, const int maxWidth, std::vector<std::pair<int, Color>>* colors) noexcept
{
    if (text.empty() || maxWidth <= 0) return "";

    const int spacing = m_glyphSpacing.width();
    const int spaceW = m_glyphsSize[static_cast<uint8_t>(' ')].width();
    const int hyphW = m_glyphsSize[static_cast<uint8_t>('-')].width();

    std::string out;
    out.reserve(text.size() + text.size() / 8);

    int lineW = 0;
    bool pendingSpace = false;

    auto emit_space_if_fits = [&](std::string& dst) -> bool {
        if (!pendingSpace) return true;
        const int need = (lineW > 0 ? spacing : 0) + spaceW;
        if (lineW + need > maxWidth) return false;
        if (lineW > 0) lineW += spacing;
        dst.push_back(' ');
        lineW += spaceW;
        pendingSpace = false;
        return true;
    };

    auto emit_hyphen_break = [&](std::string& dst) {
        const int pos = static_cast<int>(dst.size());
        dst.push_back('-');
        dst.push_back('\n');
        if (colors) updateColors(colors, pos, 2);
        lineW = 0;
        pendingSpace = false;
    };

    size_t i = 0, n = text.size();
    while (i < n) {
        const unsigned char c = static_cast<unsigned char>(text[i]);

        if (c == '\n') {
            out.push_back('\n');
            lineW = 0;
            pendingSpace = false;
            ++i;
            continue;
        }
        if (isSpace(c)) {
            pendingSpace = true;
            ++i;
            continue;
        }

        const size_t wordStart = i;
        int wordW = 0;
        int glyphs = 0;
        while (i < n) {
            const unsigned char ch = static_cast<unsigned char>(text[i]);
            if (ch == '\n' || isSpace(ch)) break;
            if (ch >= 32) {
                if (glyphs > 0) wordW += spacing;
                wordW += m_glyphsSize[ch].width();
                ++glyphs;
            }
            ++i;
        }
        const size_t wordEnd = i;

        int addW = wordW;
        if (pendingSpace && lineW > 0) addW += spacing + spaceW;
        if (lineW + addW <= maxWidth) {
            if (!emit_space_if_fits(out)) {
                out.push_back('\n');
                lineW = 0;
                pendingSpace = false;
            }
            (void)emit_space_if_fits(out);
            if (glyphs > 0) {
                out.append(text.data() + wordStart, wordEnd - wordStart);
                lineW += wordW;
            }
            continue;
        }

        size_t segStart = wordStart;
        if (pendingSpace && lineW == 0) pendingSpace = false;

        while (segStart < wordEnd) {
            if (pendingSpace) {
                const int need = (lineW > 0 ? spacing : 0) + spaceW;
                if (lineW + need > maxWidth) {
                    out.push_back('\n');
                    lineW = 0;
                } else {
                    if (lineW > 0) lineW += spacing;
                    out.push_back(' ');
                    lineW += spaceW;
                    pendingSpace = false;
                }
            }

            size_t k = segStart;
            int segW = 0;
            int segGlyphs = 0;

            while (k < wordEnd) {
                const unsigned char ch2 = static_cast<unsigned char>(text[k]);
                if (ch2 < 32) { ++k; continue; }
                const int gw = m_glyphsSize[ch2].width();
                const int next = segW + (segGlyphs > 0 ? spacing + gw : gw);
                const bool needHyphen = (k + 1 < wordEnd);
                const int tail = needHyphen ? (segGlyphs > 0 ? spacing : 0) + hyphW : 0;
                if (lineW + next + tail <= maxWidth) {
                    segW = next;
                    ++segGlyphs;
                    ++k;
                } else {
                    break;
                }
            }

            if (segGlyphs == 0) {
                const unsigned char ch3 = static_cast<unsigned char>(text[segStart]);
                size_t one = segStart + 1;
                while (one <= wordEnd && static_cast<unsigned char>(text[one - 1]) < 32) ++one;
                out.append(text.data() + segStart, one - segStart);
                emit_hyphen_break(out);
                segStart = one;
                continue;
            }

            const size_t segEnd = k;
            out.append(text.data() + segStart, segEnd - segStart);
            lineW += segW;

            if (segEnd < wordEnd) {
                emit_hyphen_break(out);
                segStart = segEnd;
            } else {
                segStart = wordEnd;
            }
        }
    }

    return out;
}

void BitmapFont::updateColors(std::vector<std::pair<int, Color>>* colors, const int pos, const int newTextLen) noexcept
{
    if (!colors) return;
    for (auto& it : *colors) {
        if (it.first > pos) {
            it.first += newTextLen;
        }
    }
}

const AtlasRegion* BitmapFont::getAtlasRegion() const noexcept {
    return m_texture ? m_texture->getAtlasRegion() : nullptr;
}
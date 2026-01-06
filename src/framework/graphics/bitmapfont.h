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

#include "bitmapfontwrapoptions.h"
#include "declarations.h"
#include <framework/otml/declarations.h>

class BitmapFont
{
public:
    BitmapFont(const std::string_view name) : m_name(name) {}

    void load(const OTMLNodePtr& fontNode);

    void drawText(std::string_view text, const Point& startPos, const Color& color = Color::white);
    void drawText(std::string_view text, const Rect& screenCoords, const Color& color = Color::white, Fw::AlignmentFlag align = Fw::AlignTopLeft);

    std::vector<std::pair<Rect, Rect>> getDrawTextCoords(std::string_view text,
                                                         const Size& textBoxSize,
                                                         Fw::AlignmentFlag align,
                                                         const Rect& screenCoords,
                                                         const std::vector<Point>& glyphsPositions) const noexcept;

    void fillTextCoords(const CoordsBufferPtr& coords, std::string_view text,
                        const Size& textBoxSize, Fw::AlignmentFlag align,
                        const Rect& screenCoords, const std::vector<Point>& glyphsPositions) const noexcept;

    void fillTextColorCoords(std::vector<std::pair<Color, CoordsBufferPtr>>& colorCoords, std::string_view text,
                             std::vector<std::pair<int, Color>> textColors,
                             const Size& textBoxSize, Fw::AlignmentFlag align,
                             const Rect& screenCoords, const std::vector<Point>& glyphsPositions) const noexcept;

    void calculateGlyphsPositions(std::string_view text,
                                  Fw::AlignmentFlag align,
                                  std::vector<Point>& glyphsPositions,
                                  Size* textBoxSize = nullptr) const noexcept;

    Size calculateTextRectSize(std::string_view text);

    std::string wrapText(std::string_view text,
                     int maxWidth,
                     std::vector<std::pair<int, Color>>* colors = nullptr) {
        WrapOptions opt;
        return wrapText(text, maxWidth, opt, colors);
    }

    std::string wrapText(std::string_view text,
                     int maxWidth,
                     const WrapOptions& options,
                     std::vector<std::pair<int, Color>>* colors = nullptr);

    inline const std::string& getName() const noexcept { return m_name; }
    inline int getGlyphHeight() const noexcept { return m_glyphHeight; }
    inline const Rect* getGlyphsTextureCoords() noexcept { return m_glyphsTextureCoords; }
    inline const Size* getGlyphsSize() noexcept { return m_glyphsSize; }
    inline const TexturePtr& getTexture() const noexcept { return m_texture; }
    inline int getYOffset() const noexcept { return m_yOffset; }
    inline Size getGlyphSpacing() const noexcept { return m_glyphSpacing; }
    const AtlasRegion* getAtlasRegion() const noexcept;

private:
    void calculateGlyphsWidthsAutomatically(const ImagePtr& image, const Size& glyphSize);
    void updateColors(std::vector<std::pair<int, Color>>* colors, int pos, int newTextLen) noexcept;

    static inline bool isSpace(unsigned char c) noexcept {
        return c == ' ' || c == '\t' || c == '\r' || c == '\n' || c == '\v' || c == '\f';
    }

    inline bool clipAndTranslateGlyph(Rect& glyphScreenCoords, Rect& glyphTextureCoords, const Rect& screenCoords) const noexcept;

    std::string m_name;
    int m_glyphHeight{ 0 };
    int m_firstGlyph{ 0 };
    int m_yOffset{ 0 };
    Size m_glyphSpacing;
    TexturePtr m_texture;
    Rect m_glyphsTextureCoords[256];
    Size m_glyphsSize[256];
};

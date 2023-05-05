#ifndef TEXTRENDER_H
#define TEXTRENDER_H

#include <map>
#include <mutex>
#include "bitmapfont.h"
#include "coordsbuffer.h"
#include <framework/core/clock.h>

struct TextRenderCache {
    BitmapFontPtr font;
    std::string text;
    Size size;
    Fw::AlignmentFlag align;
    TexturePtr texture;
    CoordsBuffer coords;
    ticks_t lastUse;
};

class TextRender
{
    static const int INDEXES = 10;
public:
    void init();
    void terminate();
    void poll();
    uint64_t addText(BitmapFontPtr font, const std::string& text, const Size& size, Fw::AlignmentFlag align = Fw::AlignTopLeft);
    void drawText(const Rect& rect, const std::string& text, BitmapFontPtr font, const Color& color = Color::white, Fw::AlignmentFlag align = Fw::AlignTopLeft, bool shadow = false);
    void drawText(const Point& pos, uint64_t hash, const Color& color, bool shadow = false);
    void drawColoredText(const Point& pos, uint64_t hash, const std::vector<std::pair<int, Color>>& colors, bool shadow = false);

private:
    std::map<uint64_t, std::shared_ptr<TextRenderCache>> m_cache[INDEXES];
    std::mutex m_mutex[INDEXES];
};

extern TextRender g_text;

#endif

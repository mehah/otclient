#include "painter.h"
#include "textrender.h"
#include <framework/core/logger.h>
#include <framework/core/eventdispatcher.h>

TextRender g_text;

void TextRender::init()
{

}

void TextRender::terminate()
{
    for (auto& cache : m_cache) {
        cache.clear();
    }
}

void TextRender::poll()
{
    static int iteration = 0;
    int index = (iteration++) % INDEXES;
    std::lock_guard<std::mutex> lock(m_mutex[index]);
    auto& cache = m_cache[index];
    if (cache.size() < 100)
        return;

    ticks_t dropPoint = g_clock.millis();
    if (cache.size() > 500)
        dropPoint -= 10;
    else if (cache.size() > 250)
        dropPoint -= 100;
    else
        dropPoint -= 1000;

    for (auto it = cache.begin(); it != cache.end(); ) {
        if (it->second->lastUse < dropPoint) {
            it = cache.erase(it);
            continue;
        }
        ++it;
    }
}

uint64_t TextRender::addText(BitmapFontPtr font, const std::string& text, const Size& size, Fw::AlignmentFlag align)
{
    if (!font || text.empty() || !size.isValid()) 
        return 0;
    uint64_t hash = 1125899906842597ULL;
    for (size_t i = 0; i < text.length(); ++i) {
        hash = hash * 31 + text[i];
    }
    hash = hash * 31 + size.width();
    hash = hash * 31 + size.height();
    hash = hash * 31 + (uint64_t)align;
    hash = hash * 31 + (uint64_t)font->getId();

    int index = hash % INDEXES;
    m_mutex[index].lock();
    auto it = m_cache[index].find(hash);
    if (it == m_cache[index].end()) {
        m_cache[index][hash] = std::shared_ptr<TextRenderCache>(new TextRenderCache{ font, text, size, align, font->getTexture(), CoordsBuffer(), g_clock.millis() });
    }
    m_mutex[index].unlock();
    return hash;
}

void TextRender::drawText(const Rect& rect, const std::string& text, BitmapFontPtr font, const Color& color, Fw::AlignmentFlag align, bool shadow)
{
    VALIDATE_GRAPHICS_THREAD();
    uint64_t hash = addText(font, text, rect.size(), align);
    drawText(rect.topLeft(), hash, color, shadow);
}

void TextRender::drawText(const Point& pos, uint64_t hash, const Color& color, bool shadow)
{
    VALIDATE_GRAPHICS_THREAD();
    int index = hash % INDEXES;
    m_mutex[index].lock();
    auto _it = m_cache[index].find(hash);
    if (_it == m_cache[index].end()) {
        m_mutex[index].unlock();
        return;
    }
    auto it = _it->second;
    it->lastUse = g_clock.millis();
    m_mutex[index].unlock();
    if (it->font) { // calculate text coords
        it->font->calculateDrawTextCoords(it->coords, it->text, Rect(0, 0, it->size), it->align);
        it->coords.cache();
        it->text.clear();
        it->font.reset();
    }

    if (shadow) {
        auto shadowPos = Point(pos);
        shadowPos.x += 1;
        shadowPos.y += 1;
        g_painter->drawText(shadowPos, it->coords, Color::black, it->texture);
    }

    g_painter->drawText(pos, it->coords, color, it->texture);
}

void TextRender::drawColoredText(const Point& pos, uint64_t hash, const std::vector<std::pair<int, Color>>& colors, bool shadow)
{
    VALIDATE_GRAPHICS_THREAD();
    if (colors.empty())
        return drawText(pos, hash, Color::white);
    int index = hash % INDEXES;
    m_mutex[index].lock();
    auto _it = m_cache[index].find(hash);
    if (_it == m_cache[index].end()) {
        m_mutex[index].unlock();
        return;
    }
    auto it = _it->second;
    it->lastUse = g_clock.millis();
    m_mutex[index].unlock();
    if (it->font) { // calculate text coords
        it->font->calculateDrawTextCoords(it->coords, it->text, Rect(0, 0, it->size), it->align);
        it->coords.cache();
        it->text.clear();
        it->font.reset();
    }
    g_painter->drawText(pos, it->coords, colors, it->texture);
}


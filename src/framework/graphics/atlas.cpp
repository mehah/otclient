#include "atlas.h"
#include "framebuffermanager.h"
#include "painter.h"
#include "graphics.h"
#include <framework/core/clock.h>
#include <framework/platform/platform.h>

Atlas g_atlas;

void Atlas::init()
{
    // If you don't care about players with old computers (~5% of players) you can change 4096 to 6144 or8192
    m_size = std::min<size_t>(4096, g_graphics.getMaxTextureSize());
    g_logger.info(stdext::format("[Atlas] Texture size is: %ix%i (max: %ix%i)", m_size, m_size, g_graphics.getMaxTextureSize(), g_graphics.getMaxTextureSize()));

    for(size_t i = 0; i < 2; ++i) {
        m_atlas[i] = g_framebuffers.createFrameBuffer();
        if (i == 0) {
            m_atlas[i]->resize(Size(m_size, m_size));
        } else { // text atlas
            m_atlas[i]->setSmooth(false);
#ifdef BIG_FONTS
            m_atlas[i]->resize(Size(m_size, m_size));
#else
            m_atlas[i]->resize(Size(2048, 2048));
#endif
        }

        glActiveTexture(GL_TEXTURE6 + i);
        glBindTexture(GL_TEXTURE_2D, m_atlas[i]->getTexture()->getId());
        glActiveTexture(GL_TEXTURE0);
    }
    reset();
    resetAtlas(1);
}

void Atlas::reset()
{
    m_doReset = false;
    resetAtlas(0);
    m_cache.clear();
}

void Atlas::reload()
{
    reset();
    resetAtlas(1);
}

void Atlas::resetAtlas(int location) {
    if (!m_atlas[location])
        return;
    for (auto& location : m_locations[location])
        location.clear();

    size_t size = m_atlas[location]->getSize().width();
    for (size_t i = 0; i < size; i += 2048) {
        m_locations[location][6].push_back(Point(i, i));
        for (size_t x = 0; x < i; x += 2048) {
            m_locations[location][6].push_back(Point(i, x));
            m_locations[location][6].push_back(Point(x, i));
        }
    }

    m_atlas[location]->bind();
    g_painter->clear(Color::alpha);
    m_atlas[location]->release();
}


void Atlas::terminate() {
    for(auto& it : m_atlas)
        it = nullptr;
}

Point Atlas::cache(uint64_t hash, const Size& size, bool& draw)
{
    if (m_doReset) {
        reset();
    }
    auto it = m_cache.find(hash);
    if (it != m_cache.end()) {
        return it->second;
    }

    int index = calculateIndex(size);
    if (index < 0 || index > 4 || (index == 4 && m_size == 2048)) { // too big to be cached, max 512x512
        draw = false;
        return Point(-1, -1);
    }

    if (m_locations[0][index].empty() && !findSpace(0, index)) {
        draw = false;
        m_doReset = true;
        return Point(-1, -1);
    }

    Point location = m_locations[0][index].front();
    m_locations[0][index].pop_front();
    m_cache.emplace(hash, location);
    draw = true;
    return location;
}

void Atlas::bind()
{
    m_atlas[0]->bind();
    g_painter->setCompositionMode(Painter::CompositionMode_Replace);
}

void Atlas::release()
{
    m_atlas[0]->release();
}

Point Atlas::cacheFont(const TexturePtr& fontTexture)
{
    fontTexture->update();
    int index = calculateIndex(fontTexture->getSize());
    if (index < 0) {
        g_logger.fatal("[Atlas] Too big font texture. Max is 2048x2048");
    }
    if (m_locations[1][index].empty() && !findSpace(1, index)) {
        g_logger.fatal("[Atlas] Out of space for new fonts, compile with BIG_FONTS or DONT_CACHE_FONTS definition");
    }
    Point location = m_locations[1][index].front();
    m_locations[1][index].pop_front();
    m_atlas[1]->bind();
    g_painter->setCompositionMode(Painter::CompositionMode_Replace);
    g_painter->drawTexturedRect(Rect(location, fontTexture->getSize()), fontTexture);
    m_atlas[1]->release();
    return location;
}

int Atlas::calculateIndex(const Size& size)
{
    int s = std::max<int>(size.width(), size.height());
    if (s <= 64)
        return s <= 32 ? 0 : 1;
    if (s <= 256)
        return s <= 128 ? 2 : 3;
    if (s <= 1024)
        return s <= 512 ? 4 : 5;
    return s <= 2048 ? 6 : -1;
}

bool Atlas::findSpace(int location, int index) {
    static const size_t sizes[7] = { 32, 64, 128, 256, 512, 1024, 2048 };
    if (location >= 2 || index >= 6) {
        return false;
    }
    if (m_locations[location][index + 1].size() == 0 && !findSpace(location, index + 1)) {
        return false;
    }
    auto pos = m_locations[location][index + 1].front();
    m_locations[location][index + 1].pop_front();
    m_locations[location][index].push_back(pos);
    m_locations[location][index].push_back(Point(pos.x, pos.y + sizes[index]));
    m_locations[location][index].push_back(Point(pos.x + sizes[index], pos.y));
    m_locations[location][index].push_back(Point(pos.x + sizes[index], pos.y + sizes[index]));
    return true;
}

std::string Atlas::getStats() {
    std::stringstream ss;
    for (int l = 0; l < 2; ++l) {
        for (auto& it : m_locations[l]) {
            ss << it.size() << " ";
        }
        ss << "| ";
    }
    ss << "(" << m_size << "|" << g_graphics.getMaxTextureSize() << ")";
    return ss.str();
}
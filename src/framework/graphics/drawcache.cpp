#include "drawcache.h"

DrawCache g_drawCache;

void DrawCache::draw()
{
    release();
    if (m_size == 0) return;
    g_painter->drawCache(m_destCoord, m_srcCoord, m_color, m_size);
    m_size = 0;
}

void DrawCache::bind()
{
    if (m_bound) return;
    g_atlas.bind();
    m_bound = true;
}

void DrawCache::release()
{
    if (!m_bound) return;
    g_atlas.release();
    m_bound = false;
}

void DrawCache::addRect(const Rect& dest, const Color& color)
{
    static Rect emptyRect(Point(-10, -10), Point(-10, -10));
    addRectRaw(m_destCoord.data() + (m_size * 2), dest);
    addRectRaw(m_srcCoord.data() + (m_size * 2), emptyRect);
    addColorRaw(color, 6);
    m_size += 6;
}

void DrawCache::addTexturedRect(const Rect& dest, const Rect& src, const Color& color)
{
    addRectRaw(m_destCoord.data() + (m_size * 2), dest);
    addRectRaw(m_srcCoord.data() + (m_size * 2), src);
    addColorRaw(color, 6);
    m_size += 6;
}

void DrawCache::addCoords(CoordsBuffer& coords, const Color& color)
{
    int size = coords.getVertexCount();
    memcpy(m_destCoord.data() + m_size * 2, coords.getVertexArray(), size * 2 * sizeof(float));
    for (int start = m_size * 2, end = (m_size + size) * 2; start < end; ++start)
        m_srcCoord[start] = -10;
    addColorRaw(color, size);
    m_size += size;
}

void DrawCache::addTexturedCoords(CoordsBuffer& coords, const Point& offset, const Color& color)
{
    int size = coords.getVertexCount();
    float* src = coords.getTextureCoordArray();
    memcpy(m_destCoord.data() + m_size * 2, coords.getVertexArray(), size * 2 * sizeof(float));
    for (int i = m_size * 2, j = 0, end = (m_size + size) * 2; i < end; ) {
        m_srcCoord[i++] = src[j++] + offset.x;
        m_srcCoord[i++] = src[j++] + offset.y;
    }
    addColorRaw(color, size);
    m_size += size;
}
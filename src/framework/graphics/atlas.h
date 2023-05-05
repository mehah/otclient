#ifndef ATLAS_H
#define ATLAS_H

#include "drawqueue.h"
#include "framebuffer.h"
#include <map>
#include <vector>

class Atlas {
public:
    void init();
    void terminate();
    void reload();

    Point cache(uint64_t hash, const Size& size, bool& draw);
    Point cacheFont(const TexturePtr& fontTexture);

    TexturePtr get(int location) { return m_atlas[location]->getTexture(); }
    void bind();
    void release();

    std::string getStats(); // not thread safe!

private:
    void reset();
    void resetAtlas(int location);
    bool findSpace(int location, int index);
    inline int calculateIndex(const Size& size);

    FrameBufferPtr m_atlas[2];
    std::map<uint64_t, Point> m_cache;
    std::list<Point> m_locations[2][7];
    size_t m_size;
    bool m_doReset = false;
};

extern Atlas g_atlas;

#endif
#pragma once

#include "texture.h"
#include <framework/util/rect.h>

class TextureAtlas
{
public:
    explicit TextureAtlas(const Size& size = {2048, 2048});

    bool addTexture(const TexturePtr& texture, Rect& atlasRect);

    TexturePtr getAtlasTexture() const { return m_texture; }

private:
    TexturePtr m_texture;
    Size m_size;
    Point m_nextPos{0,0};
    int m_rowHeight{0};
};


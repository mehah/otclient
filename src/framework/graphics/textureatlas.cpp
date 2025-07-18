#include "textureatlas.h"
#include "graphics.h"

TextureAtlas::TextureAtlas(const Size& size) : m_size(size)
{
    m_texture = std::make_shared<Texture>(size);
    m_texture->setSmooth(true);
}

bool TextureAtlas::addTexture(const TexturePtr& texture, Rect& atlasRect)
{
    if (!texture || !texture->m_image)
        return false;

    const Size& size = texture->m_image->getSize();

    if (size.width() > m_size.width() || size.height() > m_size.height())
        return false;

    if (m_nextPos.x + size.width() > m_size.width()) {
        m_nextPos.x = 0;
        m_nextPos.y += m_rowHeight;
        m_rowHeight = 0;
    }

    if (m_nextPos.y + size.height() > m_size.height())
        return false;

    atlasRect = Rect(m_nextPos, size);
    m_nextPos.x += size.width();
    m_rowHeight = std::max(m_rowHeight, size.height());

    m_texture->bind();
    glTexSubImage2D(GL_TEXTURE_2D, 0, atlasRect.x(), atlasRect.y(), size.width(), size.height(), GL_RGBA, GL_UNSIGNED_BYTE, texture->m_image->getPixelData());

    texture->m_inAtlas = true;
    texture->m_atlasRect = atlasRect;

    return true;
}


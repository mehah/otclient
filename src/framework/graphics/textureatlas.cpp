#include "textureatlas.h"
#include "texturemanager.h"

TextureAtlas::TextureAtlas(int width, int height, int layers) : atlasWidth(width), atlasHeight(height), maxLayers(layers) {
    if (width <= 0 || height <= 0 || layers <= 0) {
        throw std::invalid_argument("Invalid atlas dimensions or layer count.");
    }
    createNewLayer();
}

void TextureAtlas::addTexture(const TexturePtr& texture) {
    const auto textureID = texture->getId();
    const auto width = texture->getWidth();
    const auto height = texture->getHeight();
    const auto inactivityThreshold = 3600;

    if (width <= 0 || height <= 0 || width > atlasWidth || height > atlasHeight) {
        throw std::invalid_argument("Texture dimensions are invalid or exceed atlas dimensions.");
    }

    auto now = std::chrono::steady_clock::now();
    removeExpiredInactiveTextures(inactivityThreshold);

    auto sizeKey = std::make_pair(width, height);
    if (inactiveTextures.contains(sizeKey)) {
        auto& texList = inactiveTextures[sizeKey];
        if (!texList.empty()) {
            TextureInfo tex = texList.back();
            texList.pop_back();

            glBindTexture(GL_TEXTURE_2D, m_atlas[tex.layer]->getId());
            glCopyImageSubData(texture->getId(), GL_TEXTURE_2D, 0, 0, 0, 0,
                               m_atlas[tex.layer]->getId(), GL_TEXTURE_2D, 0, tex.x, tex.y, 0,
                               width, height, 1);

            tex.textureID = texture->getId();
            tex.lastUsed = now;
            tex.active = true;
            tex.width = width;
            tex.height = height;
            return;
        }
    }

    auto bestRegionOpt = findBestRegion(width, height);
    if (!bestRegionOpt.has_value()) {
        if (static_cast<int>(m_atlas.size()) >= maxLayers) {
            throw std::runtime_error("Unable to allocate texture: No space and maximum layers reached.");
        }
        createNewLayer();
        return addTexture(texture);
    }

    FreeRegion region = bestRegionOpt.value();
    splitRegion(region, width, height);

    glBindTexture(GL_TEXTURE_2D, m_atlas[region.layer]->getId());
    glCopyImageSubData(textureID, GL_TEXTURE_2D, 0, 0, 0, 0,
                       m_atlas[region.layer]->getId(), GL_TEXTURE_2D, 0, region.x, region.y, 0,
                       width, height, 1);

    m_texturesCached.emplace(textureID, TextureInfo{
        .textureID = textureID,
        .x = region.x,
        .y = region.y,
        .layer = region.layer,
        .width = width,
        .height = height,
        .lastUsed = now,
        .active = true
    });
}

TextureInfo TextureAtlas::getTextureInfo(uint32_t id) {
    auto it = m_texturesCached.find(id);
    if (it == m_texturesCached.end()) {
        return {};
    }

    return it->second;
}

void TextureAtlas::createNewLayer() {
    if (static_cast<int>(m_atlas.size()) >= maxLayers) {
        throw std::runtime_error("Atlas has reached the maximum number of layers.");
    }

    auto texture = std::make_shared<Texture>(Size{ atlasWidth, atlasHeight });
    texture->setCached(true);
    texture->setSmooth(false);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, atlasWidth, atlasHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);

    m_atlas.push_back(texture);
    FreeRegion newRegion = { 0, 0, atlasWidth, atlasHeight, static_cast<int>(m_atlas.size()) - 1 };
    freeRegions.insert(newRegion);
    freeRegionsBySize[atlasWidth * atlasHeight].insert(newRegion);
}
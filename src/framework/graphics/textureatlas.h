#pragma once
#include <GL/glew.h>
#include <unordered_map>
#include <vector>
#include <chrono>
#include <set>
#include <optional>
#include <functional>
#include <stdexcept>
#include <iostream>
#include <map>
#include <algorithm>
#include "declarations.h"

struct TextureInfo
{
    GLuint textureID;
    int x, y, layer;
    int width, height;
    bool active = false;
};

struct FreeRegion
{
    int x, y, width, height, layer;

    bool operator<(const FreeRegion& other) const {
        if (layer != other.layer) return layer < other.layer;
        if (width * height != other.width * other.height)
            return (width * height) < (other.width * other.height);
        return (y != other.y) ? (y < other.y) : (x < other.x);
    }

    bool canFit(int texWidth, int texHeight) const {
        return width >= texWidth && height >= texHeight;
    }
};

struct PairHash
{
    template <typename T1, typename T2>
    std::size_t operator()(const std::pair<T1, T2>& pair) const {
        std::hash<T1> hash1;
        std::hash<T2> hash2;
        return hash1(pair.first) ^ (hash2(pair.second) << 1);
    }
};

class TextureAtlas
{
private:
    std::vector<TexturePtr> m_layers;
    int m_atlasWidth, m_atlasHeight, m_maxLayers;

    std::unordered_map<std::pair<int, int>, std::vector<TextureInfo>, PairHash> m_inactiveTextures;
    std::set<FreeRegion> m_freeRegions;
    std::map<int, std::set<FreeRegion>> m_freeRegionsBySize;

    uint16_t m_transformMatrixId{ 0 };
    phmap::parallel_flat_hash_map<uint32_t, TextureInfo> m_texturesCached;

    void createNewLayer();

    std::optional<FreeRegion> findBestRegion(int width, int height) {
        auto sizeIt = m_freeRegionsBySize.lower_bound(width * height);
        while (sizeIt != m_freeRegionsBySize.end()) {
            for (const auto& region : sizeIt->second) {
                if (region.canFit(width, height)) {
                    return region;
                }
            }
            ++sizeIt;
        }
        return std::nullopt;
    }

    void splitRegion(const FreeRegion& region, int width, int height) {
        m_freeRegions.erase(region);
        m_freeRegionsBySize[region.width * region.height].erase(region);

        if (region.width > width) {
            FreeRegion right = { region.x + width, region.y, region.width - width, height, region.layer };
            if (right.width > 0 && right.height > 0) {
                m_freeRegions.insert(right);
                m_freeRegionsBySize[right.width * right.height].insert(right);
            }
        }

        if (region.height > height) {
            FreeRegion bottom = { region.x, region.y + height, width, region.height - height, region.layer };
            if (bottom.width > 0 && bottom.height > 0) {
                m_freeRegions.insert(bottom);
                m_freeRegionsBySize[bottom.width * bottom.height].insert(bottom);
            }
        }

        if (region.width > width && region.height > height) {
            FreeRegion corner = { region.x + width, region.y + height, region.width - width, region.height - height, region.layer };
            if (corner.width > 0 && corner.height > 0) {
                m_freeRegions.insert(corner);
                m_freeRegionsBySize[corner.width * corner.height].insert(corner);
            }
        }
    }

public:
    TextureAtlas(int width, int height, int layers);

    void addTexture(const TexturePtr& texture);
    void removeTexture(uint32_t id);

    const auto& getAtlas(int layer) const {
        if (layer < 0 || layer >= static_cast<int>(m_layers.size())) {
            throw std::out_of_range("Invalid layer index.");
        }
        return m_layers[layer];
    }

    auto getTransformMatrixId() const { return m_transformMatrixId; }
    auto getWidth() const { return m_atlasWidth; }
    auto getHeight() const { return m_atlasHeight; }

    int getLayerCount() const {
        return static_cast<int>(m_layers.size());
    }

    TextureInfo getTextureInfo(uint32_t id);
};

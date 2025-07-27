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

#include "thing.h"
#include "game.h"
#include "map.h"

#include <framework/graphics/shadermanager.h>

void Thing::setPosition(const Position& position, uint8_t /*stackPos*/, bool /*hasElevation*/)
{
    if (m_position == position)
        return;

    const Position oldPos = m_position;
    m_position = position;
    onPositionChange(position, oldPos);
}

int Thing::getStackPriority()
{
    // Bug fix for old versions
    if (g_game.getClientVersion() <= 800 && isSplash())
        return GROUND;

    if (isGround())
        return GROUND;

    if (isGroundBorder())
        return GROUND_BORDER;

    if (isOnBottom())
        return ON_BOTTOM;

    if (isOnTop())
        return ON_TOP;

    if (isCreature())
        return CREATURE;

    // common items
    return COMMON_ITEMS;
}

const TilePtr& Thing::getTile()
{
    return g_map.getTile(m_position);
}

ContainerPtr Thing::getParentContainer()
{
    if (m_position.x == 0xffff && m_position.y & 0x40) {
        const int containerId = m_position.y ^ 0x40;
        return g_game.getContainer(containerId);
    }

    return nullptr;
}

int Thing::getStackPos()
{
    if (m_position.x == UINT16_MAX && isItem()) // is inside a container
        return m_position.z;

    if (m_stackPos >= 0)
        return m_stackPos;

    g_logger.traceError("got a thing with invalid stackpos");
    return -1;
}

PainterShaderProgramPtr Thing::getShader() const {
    return g_shaders.getShaderById(m_shaderId);
}

void Thing::setShader(const std::string_view name) {
    m_shaderId = 0;
    if (name.empty())
        return;

    if (const auto& shader = g_shaders.getShader(name))
        m_shaderId = shader->getId();
}
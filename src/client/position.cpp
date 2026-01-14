/*
 * Copyright (c) 2010-2026 OTClient <https://github.com/edubart/otclient>
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

#include "gameconfig.h"
#include "position.h"
#include "map.h"

void Position::offsetByDelta(const Position& origin, const uint8_t delta)
{
    // this is for MAGIC_EFFECT_DELTA, for packed area effects

    // horizontal viewport size (tiles)
    const uint8_t tileCount = g_map.getAwareRange().horizontal();
    for (uint8_t i = 1; i <= delta; ++i) {
        x++;
        if ((x - origin.x) == tileCount) { // wrap row
            y++;
            x = origin.x;
        } else {
            x += delta; // continue within the same row
        }
    }
}

bool Position::isMapPosition() const { return ((x >= 0) && (y >= 0) && (x < UINT16_MAX) && (y < UINT16_MAX) && (z <= g_gameConfig.getMapMaxZ())); }

bool Position::up(const int8_t n)
{
    const int8_t nz = z - n;
    if (nz >= 0 && nz <= g_gameConfig.getMapMaxZ()) {
        z = nz;
        return true;
    }
    return false;
}

bool Position::down(const int8_t n)
{
    const int8_t nz = z + n;
    if (nz >= 0 && nz <= g_gameConfig.getMapMaxZ()) {
        z = nz;
        return true;
    }

    return false;
}

bool Position::coveredUp(const int8_t n)
{
    const int32_t nx = x + n, ny = y + n;
    const int8_t nz = z - n;
    if (nx >= 0 && nx <= UINT16_MAX && ny >= 0 && ny <= UINT16_MAX && nz >= 0 && nz <= g_gameConfig.getMapMaxZ()) {
        x = nx; y = ny; z = nz;
        return true;
    }

    return false;
}

bool Position::coveredDown(const int8_t n)
{
    const int32_t nx = x - n, ny = y - n;
    const int8_t nz = z + n;
    if (nx >= 0 && nx <= UINT16_MAX && ny >= 0 && ny <= UINT16_MAX && nz >= 0 && nz <= g_gameConfig.getMapMaxZ()) {
        x = nx; y = ny; z = nz;
        return true;
    }

    return false;
}
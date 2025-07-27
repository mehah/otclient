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

#pragma once

#include "creature.h"
#include "declarations.h"
#include <framework/ui/uiwidget.h>

class UICreature final : public UIWidget
{
public:
    void drawSelf(DrawPoolType drawPane) override;

    void setCreature(const CreaturePtr& creature) { m_creature = creature; }
    void setOutfit(const Outfit& outfit);

    CreaturePtr getCreature() { return m_creature; }
    uint8_t getCreatureSize() { return m_creatureSize; }
    void setCreatureSize(const uint8_t size) { m_creatureSize = size; }

    void setCenter(const bool v) { m_center = v; }
    bool isCentered() { return m_center; }

    /*
    // @ note:
    this did not work:
    UIcreature:getCreature():getDirection()
    UIcreature:getDirection()
    in game_outfit
    function updatePreview()
        local direction = previewCreature:getDirection()

    plan b:
    */
    Otc::Direction getDirection() {
        if (m_creature != nullptr) {
            return m_creature->getDirection();
        }
        return Otc::InvalidDirection;
    }
    // @
protected:
    void onStyleApply(std::string_view styleName, const OTMLNodePtr& styleNode) override;
    Outfit getOutfit() { if (!m_creature) setOutfit({}); return m_creature->getOutfit(); }
    CreaturePtr m_creature;
    uint8_t m_creatureSize{ 0 };
    bool m_center{ false };
};

/*
 * Copyright (c) 2010-2022 OTClient <https://github.com/edubart/otclient>
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

#include "uicreature.h"

void UICreature::drawSelf(DrawPoolType drawPane)
{
    if (drawPane != DrawPoolType::FOREGROUND)
        return;

    UIWidget::drawSelf(drawPane);

    if (m_creature) {
        m_creature->drawOutfit(getPaddingRect(), m_creatureSize, m_imageColor);
    }
}

void UICreature::setOutfit(const Outfit& outfit)
{
    if (!m_creature)
        m_creature = std::make_shared<Creature>();
    m_creature->setDirection(Otc::South);
    m_creature->setOutfit(outfit);
}

void UICreature::onStyleApply(const std::string_view styleName, const OTMLNodePtr& styleNode)
{
    UIWidget::onStyleApply(styleName, styleNode);

    for (const auto& node : styleNode->children()) {
        if (node->tag() == "creature-size") {
            m_creatureSize = node->value<int>();
        } else if (node->tag() == "outfit-id") {
            auto outfit = getOutfit();
            outfit.setCategory(ThingCategoryCreature);
            outfit.setId(node->value<int>());
            setOutfit(outfit);
        } else if (node->tag() == "outfit-head") {
            getOutfit().setHead(node->value<int>());
        } else if (node->tag() == "outfit-body") {
            getOutfit().setBody(node->value<int>());
        } else if (node->tag() == "outfit-legs") {
            getOutfit().setLegs(node->value<int>());
        } else if (node->tag() == "outfit-feet") {
            getOutfit().setFeet(node->value<int>());
        }
    }
}
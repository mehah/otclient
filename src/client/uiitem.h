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

#pragma once

#include <framework/ui/uiwidget.h>
#include "declarations.h"
#include "item.h"

class UIItem : public UIWidget
{
public:
    UIItem();
    void drawSelf(DrawPoolType drawPane) override;

    void setItemId(int id);
    void setItemCount(int count) { if (m_item) m_item->setCount(count); }
    void setItemSubType(int subType) { if (m_item) m_item->setSubType(subType); }
    void setItemVisible(bool visible) { m_itemVisible = visible; }
    void setItem(const ItemPtr& item) { m_item = item; }
    void setVirtual(bool virt) { m_virtual = virt; }
    void clearItem() { setItemId(0); }

    int getItemId() { return m_item ? m_item->getId() : 0; }
    int getItemCount() { return m_item ? m_item->getCount() : 0; }
    int getItemSubType() { return m_item ? m_item->getSubType() : 0; }
    ItemPtr getItem() { return m_item; }
    bool isVirtual() { return m_virtual; }
    bool isItemVisible() { return m_itemVisible; }

protected:
    void onStyleApply(const std::string_view styleName, const OTMLNodePtr& styleNode) override;

    ItemPtr m_item;
    bool m_virtual{ false };
    bool m_showId{ false };
    bool m_itemVisible{ true };
    bool m_alwaysShowCount{ false };
};

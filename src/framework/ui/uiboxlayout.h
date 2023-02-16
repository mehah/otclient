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

#include "uilayout.h"

 // @bindclass
class UIBoxLayout : public UILayout
{
public:
    UIBoxLayout(UIWidgetPtr parentWidget);

    void applyStyle(const OTMLNodePtr& styleNode) override;
    void addWidget(const UIWidgetPtr& /*widget*/) override { update(); }
    void removeWidget(const UIWidgetPtr& /*widget*/) override { update(); }

    void setSpacing(uint8_t spacing) { m_spacing = spacing; update(); }
    void setFitChildren(bool fitParent) { m_fitChildren = fitParent; update(); }

    bool isUIBoxLayout() override { return true; }

protected:
    bool m_fitChildren{ false };
    uint8_t m_spacing{ 0 };
};

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

#include "declarations.h"
#include <framework/ui/uiwidget.h>

class UIGraph : public UIWidget {
public:
    UIGraph();

    void drawSelf(DrawPoolType drawPane);

    void clear();
    void addValue(int value, bool ignoreSmallValues = false);
    void setLineWidth(int width)
    {
        m_width = width;
    }
    void setCapacity(int capacity)
    {
        m_capacity = capacity;
    }
    void setTitle(const std::string& title)
    {
        m_title = title;
    }
    void setShowLabels(bool value)
    {
        m_showLabes = value;
    }

protected:
    void onStyleApply(const std::string& styleName, const OTMLNodePtr& styleNode);

private:
    std::string m_title;
    size_t m_capacity = 100;
    size_t m_ignores = 0;
    int m_width = 1;
    bool m_showLabes = true;
    std::deque<int> m_values;
};

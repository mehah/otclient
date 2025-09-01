#pragma once

#include "declarations.h"
#include <framework/ui/declarations.h>

class HtmlManager
{
public:
    UIWidgetPtr createWidgetFromHTML(const std::string& htmlPath, const UIWidgetPtr& parent);
    void setGlobalStyle(const std::string& style);
};

extern HtmlManager g_html;

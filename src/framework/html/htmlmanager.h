#pragma once

#include "declarations.h"
#include <framework/ui/declarations.h>

class HtmlManager
{
public:
    UIWidgetPtr load(const std::string& htmlPath, UIWidgetPtr parent);
    void setGlobalStyle(const std::string& style);
};

extern HtmlManager g_html;

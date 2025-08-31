#pragma once

#include "declarations.h"
#include <framework/ui/declarations.h>

class HtmlManager
{
public:
    UIWidgetPtr createWidgetFromHTML(const std::string& html, const UIWidgetPtr& parent);
};

extern HtmlManager g_html;

#pragma once

#include "declarations.h"
#include <framework/ui/declarations.h>

class HtmlManager
{
public:
    uint32_t load(const std::string& htmlPath, UIWidgetPtr parent);
    void destroy(uint32_t id);
    void setGlobalStyle(const std::string& style);

private:
    stdext::map<uint32_t, HtmlNodePtr> m_nodes;
};

extern HtmlManager g_html;

#pragma once

#include "declarations.h"
#include "htmlnode.h"
#include <string>
std::shared_ptr<HtmlNode> parseHtml(const std::string& html);
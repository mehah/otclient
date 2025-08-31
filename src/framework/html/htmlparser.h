#pragma once

#include "htmlnode.h"
#include <string>
#include <memory>

std::shared_ptr<HtmlNode> parseHtml(const std::string& html);

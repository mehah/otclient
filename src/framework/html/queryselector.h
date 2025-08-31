#pragma once
#include "declarations.h"
#include "htmlnode.h"
#include <string>
#include <vector>

std::vector<std::shared_ptr<HtmlNode>> querySelectorAll(std::shared_ptr<HtmlNode> root, const std::string& selector);
std::shared_ptr<HtmlNode> querySelector(std::shared_ptr<HtmlNode> root, const std::string& selector);

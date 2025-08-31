#pragma once
#include <string>
#include <vector>
#include <unordered_map>
#include <memory>

class HtmlNode
{
public:
    std::string tag;
    std::unordered_map<std::string, std::string> attributes;
    std::vector<std::shared_ptr<HtmlNode>> children;
    std::string text;

    std::weak_ptr<HtmlNode> parent;

    std::string getAttr(const std::string& name) const;
    size_t indexInParent() const;
    bool isOnlyChild() const;
    bool isLastChild() const;
    bool isEmpty() const;

    std::vector<std::shared_ptr<HtmlNode>> querySelectorAll(const std::string& selector);
    std::shared_ptr<HtmlNode> querySelector(const std::string& selector);
};
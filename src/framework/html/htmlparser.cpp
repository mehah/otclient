#include "htmlparser.h"
#include <regex>
#include <stack>
#include <sstream>

std::unordered_map<std::string, std::string> parseAttributes(const std::string& tagContent) {
    std::unordered_map<std::string, std::string> attrs;
    std::string_view content(tagContent);

    size_t pos = 0;
    while (pos < content.size()) {
        while (pos < content.size() && std::isspace(content[pos])) ++pos;

        size_t keyStart = pos;
        while (pos < content.size() && (std::isalnum(content[pos]) || content[pos] == '-' || content[pos] == ':'))
            ++pos;
        if (keyStart == pos) break;

        std::string_view key = content.substr(keyStart, pos - keyStart);

        while (pos < content.size() && (std::isspace(content[pos]) || content[pos] == '=')) ++pos;
        if (pos >= content.size() || content[pos] != '\"') continue;

        ++pos;

        size_t valueStart = pos;
        while (pos < content.size() && content[pos] != '\"') ++pos;
        std::string_view value = content.substr(valueStart, pos - valueStart);

        if (pos < content.size()) ++pos;

        attrs[std::string(key)] = std::string(value);
    }

    return attrs;
}

std::string extractTagName(const std::string& tagContent) {
    size_t space = tagContent.find(' ');
    return space == std::string::npos ? tagContent : tagContent.substr(0, space);
}

std::shared_ptr<HtmlNode> parseHtml(const std::string& html) {
    std::stack<std::shared_ptr<HtmlNode>> stack;
    auto root = std::make_shared<HtmlNode>();
    root->tag = "root";
    stack.push(root);

    std::regex tagRegex(R"(<([^>]+)>)");
    std::sregex_iterator it(html.begin(), html.end(), tagRegex), end;
    size_t lastPos = 0;

    for (; it != end; ++it) {
        size_t pos = it->position();
        std::string textContent = html.substr(lastPos, pos - lastPos);
        stdext::trim(textContent);

        if (!textContent.empty()) {
            auto node = std::make_shared<HtmlNode>();
            node->tag = "text";
            node->text = textContent;
            node->parent = stack.top();
            stack.top()->children.push_back(node);
        }

        std::string tag = (*it)[1];
        if (tag[0] == '/') {
            stack.pop();
        } else {
            bool selfClosing = tag.back() == '/';
            if (selfClosing) tag.pop_back();
            stdext::trim(tag);

            auto node = std::make_shared<HtmlNode>();
            node->tag = extractTagName(tag);
            node->attributes = parseAttributes(tag);
            node->parent = stack.top();
            stack.top()->children.push_back(node);

            if (!selfClosing)
                stack.push(node);
        }
        lastPos = pos + it->length();
    }

    return root;
}
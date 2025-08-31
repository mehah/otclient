#pragma once
#include "declarations.h"

#include <string>
#include <vector>
#include <unordered_map>
#include <memory>

namespace css {
    struct Declaration
    {
        std::string property;   // lowercased
        std::string value;      // raw value
        bool important{ false };
    };

    struct Rule
    {
        std::vector<std::string> selectors;
        std::vector<Declaration> decls;
        int order{ 0 }; // source order
    };

    struct StyleSheet
    {
        std::vector<Rule> rules;
    };

    using StyleMap = std::unordered_map<std::string, std::string>;

    struct CascadeOptions
    {
        bool parse_inline_style{ true };
        bool media_always_true{ true };
    };

    // --- Parsing API ---
    StyleSheet parse(const std::string& cssText);
    std::vector<Declaration> parseDeclarationList(const std::string& block);

    // --- Cascade helpers ---
    void applyStyleSheet(const std::shared_ptr<HtmlNode>& root,
                         const StyleSheet& sheet,
                         std::unordered_map<const HtmlNode*, StyleMap>& out,
                         const CascadeOptions& opts = {});

    StyleMap computeStyleFor(const std::shared_ptr<HtmlNode>& root,
                             const std::shared_ptr<HtmlNode>& element,
                             const StyleSheet& sheet,
                             const CascadeOptions& opts = {});
} // namespace css

#include "htmlparser.h"
#include <stack>
#include <string_view>
#include <unordered_set>
#include <cctype>

static inline bool is_space(unsigned char c){ return c==' '||c=='\n'||c=='\t'||c=='\r'||c=='\f'; }
static inline bool is_name_char(unsigned char c){ return std::isalnum(c) || c=='-' || c==':' || c=='_'; }

static const std::unordered_set<std::string> kVoid = {
    "area","base","br","col","embed","hr","img","input","link","meta","source","track","wbr"
};

static void skip_ws(const std::string& s, size_t& i){
    while (i < s.size() && is_space((unsigned char)s[i])) ++i;
}

static std::string read_until(const std::string& s, size_t& i, char end){
    size_t start = i;
    while (i < s.size() && s[i] != end) ++i;
    return s.substr(start, i - start);
}

static void parseAttributes(std::unordered_map<std::string, std::string>& out,
                            std::vector<std::string>& classList,
                            const std::string& s, size_t& i)
{
    out.reserve(8);
    while (i < s.size()) {
        skip_ws(s, i);
        if (i >= s.size() || s[i] == '>' || (s[i] == '/' && i+1 < s.size() && s[i+1] == '>')) break;

        size_t keyStart = i;
        while (i < s.size() && is_name_char((unsigned char)s[i])) ++i;
        if (i == keyStart) { ++i; continue; }
        std::string key = s.substr(keyStart, i - keyStart);
        ascii_tolower_inplace(key);

        skip_ws(s, i);
        std::string value;
        if (i < s.size() && s[i] == '=') {
            ++i; skip_ws(s, i);
            if (i < s.size() && (s[i] == '"' || s[i] == '\'')) {
                char q = s[i++];
                value = read_until(s, i, q);
                if (i < s.size() && s[i] == q) ++i;
            } else {
                size_t vstart = i;
                while (i < s.size() && !is_space((unsigned char)s[i]) && s[i] != '>' && s[i] != '/') ++i;
                value = s.substr(vstart, i - vstart);
            }
        } else {
            value = "";
        }
        out[key] = value;

        if (key == "class" && !value.empty()) {
            size_t j = 0;
            while (j < value.size()) {
                while (j < value.size() && is_space((unsigned char)value[j])) ++j;
                size_t start = j;
                while (j < value.size() && !is_space((unsigned char)value[j])) ++j;
                if (start < j) classList.emplace_back(value.substr(start, j - start));
            }
        }
    }
}

std::shared_ptr<HtmlNode> parseHtml(const std::string& html) {
    auto root = std::make_shared<HtmlNode>();
    root->type = NodeType::Element;
    root->tag  = "root";

    std::stack<std::shared_ptr<HtmlNode>> st;
    st.push(root);

    const std::string& s = html;
    size_t i = 0, N = s.size();

    auto push_node = [&](std::shared_ptr<HtmlNode> node){
        node->parent = st.top();
        st.top()->children.push_back(node);
    };

    while (i < N) {
        if (s[i] == '<') {
            if (i + 3 < N && s.compare(i, 4, "<!--") == 0) {
                i += 4;
                size_t end = s.find("-->", i);
                auto node = std::make_shared<HtmlNode>();
                node->type = NodeType::Comment;
                node->text = (end == std::string::npos) ? s.substr(i) : s.substr(i, end - i);
                push_node(node);
                i = (end == std::string::npos) ? N : end + 3;
                continue;
            }
            if (i + 2 < N && s.compare(i, 2, "<!") == 0) {
                size_t gt = s.find('>', i+2);
                auto node = std::make_shared<HtmlNode>();
                node->type = NodeType::Doctype;
                node->text = (gt == std::string::npos) ? s.substr(i+2) : s.substr(i+2, gt - (i+2));
                push_node(node);
                i = (gt == std::string::npos) ? N : gt + 1;
                continue;
            }
            if (i + 1 < N && s[i+1] == '/') {
                i += 2;
                size_t start = i;
                while (i < N && is_name_char((unsigned char)s[i])) ++i;
                std::string tag = s.substr(start, i - start);
                ascii_tolower_inplace(tag);
                while (i < N && s[i] != '>') ++i;
                if (i < N) ++i;
                while (st.size() > 1) {
                    auto top = st.top();
                    if (top->type == NodeType::Element && top->tag == tag) { st.pop(); break; }
                    st.pop();
                }
                continue;
            }
            size_t lt = i; ++i;
            size_t nameStart = i;
            while (i < N && is_name_char((unsigned char)s[i])) ++i;
            std::string tag = s.substr(nameStart, i - nameStart);
            ascii_tolower_inplace(tag);

            auto node = std::make_shared<HtmlNode>();
            node->type = NodeType::Element;
            node->tag  = tag;

            skip_ws(s, i);
            parseAttributes(node->attributes, node->classList, s, i);

            bool isRaw = (tag == "script" || tag == "style");

            bool selfClosing = false;
            if (i < N && s[i] == '/') { selfClosing = true; ++i; }
            if (i < N && s[i] == '>') ++i;

            push_node(node);

            
            root->tagIndex[tag].push_back(node);
            auto idv = node->getAttr("id");
            if (!idv.empty()) root->idIndex[idv] = node;
            if (!node->classList.empty()) {
                for (const auto& cls : node->classList) root->classIndex[cls].push_back(node);
            }

            bool isVoid = kVoid.count(tag) > 0;
            if (!selfClosing && !isVoid) {
                if (isRaw) {
                    size_t closePos = std::string::npos;
                    std::string endTag = "</" + tag + ">";
                    closePos = s.find(endTag, i);
                    auto tnode = std::make_shared<HtmlNode>();
                    tnode->type = NodeType::Text;
                    if (closePos == std::string::npos) {
                        tnode->text = s.substr(i);
                        push_node(tnode);
                        i = N;
                    } else {
                        tnode->text = s.substr(i, closePos - i);
                        push_node(tnode);
                        i = closePos + endTag.size();
                    }
                } else {
                    st.push(node);
                }
            }
        } else {
            size_t start = i;
            size_t lt = s.find('<', i);
            if (lt == std::string::npos) lt = N;
            std::string txt = s.substr(start, lt - start);
            if (!txt.empty()) {
                auto t = std::make_shared<HtmlNode>();
                t->type = NodeType::Text;
                t->text = txt;
                push_node(t);
            }
            i = lt;
        }
    }

    while (st.size() > 1) st.pop();
    return root;
}

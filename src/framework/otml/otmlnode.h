/*
 * Copyright (c) 2010-2022 OTClient <https://github.com/edubart/otclient>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#pragma once

#include "declarations.h"

class OTMLNode : public std::enable_shared_from_this<OTMLNode>
{
public:
    virtual ~OTMLNode() {} // fix clang warning

    static OTMLNodePtr create(const std::string_view tag = "", bool unique = false);
    static OTMLNodePtr create(const std::string_view tag, const std::string_view value);

    std::string tag() { return m_tag; }
    int size() const { return m_children.size(); }
    std::string source() { return m_source; }
    std::string rawValue() { return m_value; }

    bool isUnique() const { return m_unique; }
    bool isNull() const { return m_null; }

    bool hasTag() const { return !m_tag.empty(); }
    bool hasValue() const { return !m_value.empty(); }
    bool hasChildren() const;
    bool hasChildAt(const std::string_view childTag) const { return !!get(childTag); }
    bool hasChildAtIndex(int childIndex) { return !!getIndex(childIndex); }

    void setTag(const std::string_view tag) { m_tag = tag; }
    void setValue(const std::string_view value) { m_value = value; }
    void setNull(bool null) { m_null = null; }
    void setUnique(bool unique) { m_unique = unique; }
    void setSource(const std::string_view source) { m_source = source; }

    OTMLNodePtr get(const std::string_view childTag) const;
    OTMLNodePtr getIndex(int childIndex);

    OTMLNodePtr at(const std::string_view childTag);
    OTMLNodePtr atIndex(int childIndex);

    void addChild(const OTMLNodePtr& newChild);
    bool removeChild(const OTMLNodePtr& oldChild);
    bool replaceChild(const OTMLNodePtr& oldChild, const OTMLNodePtr& newChild);
    void copy(const OTMLNodePtr& node);
    void merge(const OTMLNodePtr& node);
    void clear();

    OTMLNodeList children() const;
    OTMLNodePtr clone() const;

    template<typename T = std::string>
    T value();
    template<typename T = std::string>
    T valueAt(const std::string_view childTag);
    template<typename T = std::string>
    T valueAtIndex(int childIndex);
    template<typename T = std::string>
    T valueAt(const std::string_view childTag, const T& def);
    template<typename T = std::string>
    T valueAtIndex(int childIndex, const T& def);

    template<typename T>
    void write(const T& v);
    template<typename T>
    void writeAt(const std::string_view childTag, const T& v);
    template<typename T>
    void writeIn(const T& v);

    virtual std::string emit();

    OTMLNodePtr asOTMLNode() { return this->shared_from_this(); }

protected:
    OTMLNodeList m_children;
    std::string m_tag;
    std::string m_value;
    std::string m_source;
    bool m_unique{ false };
    bool m_null{ false };
};

#include "otmlexception.h"

template<>
inline std::string OTMLNode::value<std::string>()
{
    std::string value = m_value;
    if (value.starts_with("\"") && value.ends_with("\"")) {
        value = value.substr(1, value.length() - 2);
        stdext::replace_all(value, "\\\\", "\\");
        stdext::replace_all(value, "\\\"", "\"");
        stdext::replace_all(value, "\\t", "\t");
        stdext::replace_all(value, "\\n", "\n");
        stdext::replace_all(value, "\\'", "\'");
    }
    return value;
}

template<typename T>
T OTMLNode::value()
{
    T ret;
    if (!stdext::cast(m_value, ret))
        throw OTMLException(asOTMLNode(), stdext::format("failed to cast node value '%s' to type '%s'", m_value, stdext::demangle_type<T>()));
    return ret;
}

template<typename T>
T OTMLNode::valueAt(const std::string_view childTag)
{
    const OTMLNodePtr node = at(childTag);
    return node->value<T>();
}

template<typename T>
T OTMLNode::valueAtIndex(int childIndex)
{
    const OTMLNodePtr node = atIndex(childIndex);
    return node->value<T>();
}

template<typename T>
T OTMLNode::valueAt(const std::string_view childTag, const T& def)
{
    if (const auto& node = get(childTag))
        if (!node->isNull())
            return node->value<T>();
    return def;
}

template<typename T>
T OTMLNode::valueAtIndex(int childIndex, const T& def)
{
    if (const auto& node = getIndex(childIndex))
        return node->value<T>();
    return def;
}

template<typename T>
void OTMLNode::write(const T& v)
{
    m_value = stdext::safe_cast<std::string>(v);
}

template<typename T>
void OTMLNode::writeAt(const std::string_view childTag, const T& v)
{
    const auto& child = create(childTag);
    child->setUnique(true);
    child->write<T>(v);
    addChild(child);
}

template<typename T>
void OTMLNode::writeIn(const T& v)
{
    const auto& child = create();
    child->write<T>(v);
    addChild(child);
}

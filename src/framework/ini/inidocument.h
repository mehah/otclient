/*
 * Copyright (c) 2010-2025 OTClient <https://github.com/edubart/otclient>
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
#include <framework/stdext/types.h>

/**
 * INISection represents a section in an INI file.
 * Example:
 *   [section_name]
 *   key1 = value1
 *   key2 = value2
 */
class INISection
{
public:
    INISection(const std::string& name) : m_name(name) {}
    
    // Getters
    std::string getName() const { return m_name; }
    
    // Value access
    bool hasKey(const std::string& key) const;
    std::string get(const std::string& key, const std::string& defaultValue = "") const;
    int getInt(const std::string& key, int defaultValue = 0) const;
    double getDouble(const std::string& key, double defaultValue = 0.0) const;
    bool getBool(const std::string& key, bool defaultValue = false) const;
    
    // Value modification
    void set(const std::string& key, const std::string& value);
    void setInt(const std::string& key, int value);
    void setDouble(const std::string& key, double value);
    void setBool(const std::string& key, bool value);
    void remove(const std::string& key);
    
    // Iteration
    std::vector<std::string> getKeys() const;
    const std::map<std::string, std::string>& getAll() const { return m_values; }
    
private:
    std::string m_name;
    std::map<std::string, std::string> m_values;
};

/**
 * INIDocument represents an INI file with multiple sections.
 * Global usage similar to OTMLDocument.
 * 
 * Example usage:
 *   auto doc = INIDocument::parse("/data/config.ini");
 *   auto section = doc->getSection("game");
 *   int spriteSize = section->getInt("sprite-size", 32);
 */
class INIDocument
{
public:
    /// Create a new empty INI document
    static INIDocumentPtr create();
    
    /// Parse INI from a file path (uses ResourceManager)
    static INIDocumentPtr parse(const std::string& fileName);
    
    /// Parse INI from a string content
    static INIDocumentPtr parseString(const std::string& content, const std::string& source = "");
    
    // Section access
    bool hasSection(const std::string& name) const;
    INISectionPtr getSection(const std::string& name) const;
    INISectionPtr getOrCreateSection(const std::string& name);
    void removeSection(const std::string& name);
    
    // Get all sections
    std::vector<std::string> getSectionNames() const;
    const std::map<std::string, INISectionPtr>& getSections() const { return m_sections; }
    
    // Direct value access (shorthand for section->get)
    std::string get(const std::string& section, const std::string& key, const std::string& defaultValue = "") const;
    int getInt(const std::string& section, const std::string& key, int defaultValue = 0) const;
    double getDouble(const std::string& section, const std::string& key, double defaultValue = 0.0) const;
    bool getBool(const std::string& section, const std::string& key, bool defaultValue = false) const;
    
    // Direct value modification
    void set(const std::string& section, const std::string& key, const std::string& value);
    void setInt(const std::string& section, const std::string& key, int value);
    void setDouble(const std::string& section, const std::string& key, double value);
    void setBool(const std::string& section, const std::string& key, bool value);
    
    /// Emit the INI document as a string
    std::string emit() const;
    
    /// Save this document to a file
    bool save(const std::string& fileName) const;
    
    // Source file info
    std::string getSource() const { return m_source; }
    
private:
    INIDocument() = default;
    void parseContent(const std::string& content);
    
    std::map<std::string, INISectionPtr> m_sections;
    std::string m_source;
};

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

#include "inidocument.h"
#include <framework/core/resourcemanager.h>
#include <framework/core/filestream.h>
#include <sstream>
#include <algorithm>

// ============================================================================
// INISection Implementation
// ============================================================================

bool INISection::hasKey(const std::string& key) const
{
    return m_values.find(key) != m_values.end();
}

std::string INISection::get(const std::string& key, const std::string& defaultValue) const
{
    auto it = m_values.find(key);
    if (it != m_values.end())
        return it->second;
    return defaultValue;
}

int INISection::getInt(const std::string& key, int defaultValue) const
{
    auto it = m_values.find(key);
    if (it != m_values.end()) {
        try {
            return std::stoi(it->second);
        } catch (...) {
            return defaultValue;
        }
    }
    return defaultValue;
}

double INISection::getDouble(const std::string& key, double defaultValue) const
{
    auto it = m_values.find(key);
    if (it != m_values.end()) {
        try {
            return std::stod(it->second);
        } catch (...) {
            return defaultValue;
        }
    }
    return defaultValue;
}

bool INISection::getBool(const std::string& key, bool defaultValue) const
{
    auto it = m_values.find(key);
    if (it != m_values.end()) {
        std::string value = it->second;
        std::transform(value.begin(), value.end(), value.begin(), ::tolower);
        if (value == "true" || value == "yes" || value == "1" || value == "on")
            return true;
        if (value == "false" || value == "no" || value == "0" || value == "off")
            return false;
    }
    return defaultValue;
}

void INISection::set(const std::string& key, const std::string& value)
{
    m_values[key] = value;
}

void INISection::setInt(const std::string& key, int value)
{
    m_values[key] = std::to_string(value);
}

void INISection::setDouble(const std::string& key, double value)
{
    m_values[key] = std::to_string(value);
}

void INISection::setBool(const std::string& key, bool value)
{
    m_values[key] = value ? "true" : "false";
}

void INISection::remove(const std::string& key)
{
    m_values.erase(key);
}

std::vector<std::string> INISection::getKeys() const
{
    std::vector<std::string> keys;
    keys.reserve(m_values.size());
    for (const auto& pair : m_values)
        keys.push_back(pair.first);
    return keys;
}

// ============================================================================
// INIDocument Implementation
// ============================================================================

INIDocumentPtr INIDocument::create()
{
    return INIDocumentPtr(new INIDocument());
}

INIDocumentPtr INIDocument::parse(const std::string& fileName)
{
    // Use ResourceManager to find the file
    std::string filePath = fileName;
    if (filePath.find(".ini") == std::string::npos)
        filePath = g_resources.guessFilePath(fileName, "ini");
    
    // Read file contents
    std::string content = g_resources.readFileContents(filePath);
    if (content.empty()) {
        throw std::runtime_error("Failed to read INI file or file is empty: " + filePath);
    }
    
    auto doc = create();
    doc->m_source = filePath;
    doc->parseContent(content);
    return doc;
}

INIDocumentPtr INIDocument::parseString(const std::string& content, const std::string& source)
{
    auto doc = create();
    doc->m_source = source;
    doc->parseContent(content);
    return doc;
}

void INIDocument::parseContent(const std::string& content)
{
    std::istringstream stream(content);
    std::string line;
    INISectionPtr currentSection;
    
    while (std::getline(stream, line)) {
        // Trim whitespace
        size_t start = line.find_first_not_of(" \t\r\n");
        size_t end = line.find_last_not_of(" \t\r\n");
        
        if (start == std::string::npos) {
            continue; // Empty line
        }
        
        line = line.substr(start, end - start + 1);
        
        // Skip comments
        if (line[0] == ';' || line[0] == '#') {
            continue;
        }
        
        // Check for section header
        if (line[0] == '[' && line.back() == ']' && line.length() > 2) {
            std::string sectionName = line.substr(1, line.length() - 2);
            currentSection = std::make_shared<INISection>(sectionName);
            m_sections[sectionName] = currentSection;
            continue;
        }
        
        // Parse key=value
        size_t equalPos = line.find('=');
        if (equalPos != std::string::npos && currentSection) {
            std::string key = line.substr(0, equalPos);
            std::string value = line.substr(equalPos + 1);
            
            // Trim key
            size_t keyStart = key.find_first_not_of(" \t");
            size_t keyEnd = key.find_last_not_of(" \t");
            if (keyStart != std::string::npos && keyEnd != std::string::npos)
                key = key.substr(keyStart, keyEnd - keyStart + 1);
            
            // Trim value
            size_t valueStart = value.find_first_not_of(" \t");
            size_t valueEnd = value.find_last_not_of(" \t");
            if (valueStart != std::string::npos && valueEnd != std::string::npos)
                value = value.substr(valueStart, valueEnd - valueStart + 1);
            else
                value = "";
            
            currentSection->set(key, value);
        }
    }
}

bool INIDocument::hasSection(const std::string& name) const
{
    return m_sections.find(name) != m_sections.end();
}

INISectionPtr INIDocument::getSection(const std::string& name) const
{
    auto it = m_sections.find(name);
    if (it != m_sections.end())
        return it->second;
    return nullptr;
}

INISectionPtr INIDocument::getOrCreateSection(const std::string& name)
{
    auto it = m_sections.find(name);
    if (it != m_sections.end())
        return it->second;
    
    auto section = std::make_shared<INISection>(name);
    m_sections[name] = section;
    return section;
}

void INIDocument::removeSection(const std::string& name)
{
    m_sections.erase(name);
}

std::vector<std::string> INIDocument::getSectionNames() const
{
    std::vector<std::string> names;
    names.reserve(m_sections.size());
    for (const auto& pair : m_sections)
        names.push_back(pair.first);
    return names;
}

// Direct value access shortcuts
std::string INIDocument::get(const std::string& section, const std::string& key, const std::string& defaultValue) const
{
    auto sec = getSection(section);
    if (sec)
        return sec->get(key, defaultValue);
    return defaultValue;
}

int INIDocument::getInt(const std::string& section, const std::string& key, int defaultValue) const
{
    auto sec = getSection(section);
    if (sec)
        return sec->getInt(key, defaultValue);
    return defaultValue;
}

double INIDocument::getDouble(const std::string& section, const std::string& key, double defaultValue) const
{
    auto sec = getSection(section);
    if (sec)
        return sec->getDouble(key, defaultValue);
    return defaultValue;
}

bool INIDocument::getBool(const std::string& section, const std::string& key, bool defaultValue) const
{
    auto sec = getSection(section);
    if (sec)
        return sec->getBool(key, defaultValue);
    return defaultValue;
}

void INIDocument::set(const std::string& section, const std::string& key, const std::string& value)
{
    getOrCreateSection(section)->set(key, value);
}

void INIDocument::setInt(const std::string& section, const std::string& key, int value)
{
    getOrCreateSection(section)->setInt(key, value);
}

void INIDocument::setDouble(const std::string& section, const std::string& key, double value)
{
    getOrCreateSection(section)->setDouble(key, value);
}

void INIDocument::setBool(const std::string& section, const std::string& key, bool value)
{
    getOrCreateSection(section)->setBool(key, value);
}

std::string INIDocument::emit() const
{
    std::ostringstream output;
    
    for (const auto& [sectionName, section] : m_sections) {
        output << "[" << sectionName << "]\n";
        
        for (const auto& [key, value] : section->getAll()) {
            output << key << " = " << value << "\n";
        }
        
        output << "\n";
    }
    
    return output.str();
}

bool INIDocument::save(const std::string& fileName) const
{
    try {
        auto file = g_resources.createFile(fileName);
        if (!file)
            return false;
        
        std::string content = emit();
        file->write(content.c_str(), content.size());
        file->close();
        return true;
    } catch (...) {
        return false;
    }
}

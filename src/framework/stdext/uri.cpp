#include <locale>
#include <regex>

#include "uri.h"

ParsedURI parseURI(const std::string& url)
{
    const auto& value_default = [](const std::string& value, std::string&& deflt) -> std::string {
        return (value.empty() ? deflt : value);
    };

    const auto& value_to_lower = [](std::string data) -> std::string {
        for (char& c : data)
            c = tolower(c);
        return data;
    };

    // Note: only "http", "https", "ws", and "wss" protocols are supported
    static const std::regex PARSE_URL{ R"((([httpsw]{2,5})://)?([^/ :]+)(:(\d+))?(/(.+)?))",
                                       std::regex_constants::ECMAScript | std::regex_constants::icase };
    ParsedURI result;
    std::smatch match;
    if (std::regex_match(url, match, PARSE_URL) && match.size() == 8) {
        result.protocol = value_default(value_to_lower(std::string(match[2])), "http");
        result.domain = match[3];
        const bool is_sequre_protocol = (result.protocol == "https" || result.protocol == "wss");
        result.port = value_default(match[5], (is_sequre_protocol) ? "443" : "80");
        result.query = value_default(match[6], "/");
    }
    return result;
}
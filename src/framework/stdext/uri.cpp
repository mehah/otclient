#include <boost/algorithm/string.hpp>
#include <regex>

#include "uri.h"

ParsedURI parseURI(const std::string& url)
{
    ParsedURI result;
    auto value_or = [](const std::string& value, std::string&& deflt) -> std::string {
        return (value.empty() ? deflt : value);
    };
    // Note: only "http", "https", "ws", and "wss" protocols are supported
    static const std::regex PARSE_URL{ R"((([httpsw]{2,5})://)?([^/ :]+)(:(\d+))?(/(.+)?))",
                                       std::regex_constants::ECMAScript | std::regex_constants::icase };
    std::smatch match;
    if (std::regex_match(url, match, PARSE_URL) && match.size() == 8) {
        result.protocol = value_or(boost::algorithm::to_lower_copy(std::string(match[2])), "http");
        result.domain = match[3];
        const bool is_sequre_protocol = (result.protocol == "https" || result.protocol == "wss");
        result.port = value_or(match[5], (is_sequre_protocol) ? "443" : "80");
        result.query = value_or(match[6], "/");
    }
    return result;
}
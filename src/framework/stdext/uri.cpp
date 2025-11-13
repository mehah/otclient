#include "uri.h"

ParsedURI parseURI(const std::string& url) {
    // Regular expression pattern to match URL components
    static const std::regex PARSE_URL{
        R"((([httpsw]{2,5})://)?([^/ :]+)(:(\d+))?(/(.+)?))",
        std::regex_constants::ECMAScript | std::regex_constants::icase };

    ParsedURI result;
    std::smatch match;

    // Check if the URL matches the pattern and has the correct number of components
    if (std::regex_match(url, match, PARSE_URL) && match.size() == 8) {
        // Set protocol with default value "http" if not provided
        result.protocol = (match[2].str().empty()) ? "http" : match[2].str();

        // Set domain
        result.domain = match[3].str();

        // Check if protocol is "https" or "wss" to determine default port
        const bool isHttps = (result.protocol == "https" || result.protocol == "wss");
        result.port = (match[5].str().empty()) ? (isHttps) ? "443" : "80" : match[5].str();

        // Set query with default value "/"
        result.query = (match[6].str().empty()) ? "/" : match[6].str();
    }

    return result;
}
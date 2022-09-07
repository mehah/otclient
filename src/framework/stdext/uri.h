#include <string>

struct ParsedURI {
  std::string protocol;
  std::string domain;  // only domain must be present
  std::string port;
  std::string query;   // everything after '?', possibly nothing
};

ParsedURI parseURI(const std::string& url);
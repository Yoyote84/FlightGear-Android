#include <string>
#include <vector>
#include <cstring>
#include <cctype>

namespace simgear::strutils {

bool starts_with(const std::string& s, const std::string& prefix)
{
    return s.compare(0, prefix.size(), prefix) == 0;
}

std::vector<std::string> split(const std::string& str, const char* sep, int maxsplit)
{
    std::vector<std::string> result;
    if (!sep) {
        std::size_t i = 0;
        while (i < str.size()) {
            while (i < str.size() && std::isspace(static_cast<unsigned char>(str[i]))) ++i;
            if (i >= str.size()) break;
            std::size_t j = i;
            while (i < str.size() && !std::isspace(static_cast<unsigned char>(str[i]))) ++i;
            result.push_back(str.substr(j, i - j));
            if (maxsplit > 0 && static_cast<int>(result.size()) >= maxsplit) {
                while (i < str.size() && std::isspace(static_cast<unsigned char>(str[i]))) ++i;
                if (i < str.size()) result.push_back(str.substr(i));
                break;
            }
        }
        return result;
    }

    const std::size_t n = std::strlen(sep);
    if (n == 0) return result;
    std::size_t start = 0;
    int count = 0;
    for (std::size_t i = 0; i + n <= str.size();) {
        if (str.compare(i, n, sep) == 0) {
            result.push_back(str.substr(start, i - start));
            i += n;
            start = i;
            ++count;
            if (maxsplit > 0 && count >= maxsplit) break;
        } else {
            ++i;
        }
    }
    result.push_back(str.substr(start));
    return result;
}

} // namespace simgear::strutils

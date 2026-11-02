#include <string>
#include <vector>
#include <cstring>
#include <cctype>
#include <cstdlib>
namespace simgear::strutils {
bool starts_with(const std::string& s,const std::string& p){return s.compare(0,p.size(),p)==0;}
std::vector<std::string> split(const std::string& str,const char* sep,int maxsplit){std::vector<std::string> r;if(!sep){std::size_t i=0;while(i<str.size()){while(i<str.size()&&std::isspace((unsigned char)str[i]))++i;if(i>=str.size())break;std::size_t j=i;while(i<str.size()&&!std::isspace((unsigned char)str[i]))++i;r.push_back(str.substr(j,i-j));if(maxsplit>0&&(int)r.size()>=maxsplit){while(i<str.size()&&std::isspace((unsigned char)str[i]))++i;if(i<str.size())r.push_back(str.substr(i));break;}}return r;}std::size_t n=std::strlen(sep);if(!n)return r;std::size_t start=0;int count=0;for(std::size_t i=0;i+n<=str.size();){if(str.compare(i,n,sep)==0){r.push_back(str.substr(start,i-start));i+=n;start=i;++count;if(maxsplit>0&&count>=maxsplit)break;}else ++i;}r.push_back(str.substr(start));return r;}
int to_int(const std::string& s,int base){return (int)std::strtol(s.c_str(),nullptr,base);}
std::string lowercase(const std::string& s){std::string r=s;for(char& c:r)c=(char)std::tolower((unsigned char)c);return r;}
}

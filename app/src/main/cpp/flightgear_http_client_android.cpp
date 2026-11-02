#include <Network/HTTPClient.hxx>
FGHTTPClient::FGHTTPClient():_inited(false){} FGHTTPClient::~FGHTTPClient()=default;
void FGHTTPClient::init(){_inited=true;} void FGHTTPClient::postinit(){} void FGHTTPClient::shutdown(){_http.reset();_inited=false;} void FGHTTPClient::update(double){if(_http)_http->update();}
FGHTTPClient* FGHTTPClient::getOrCreate(){return nullptr;}
void FGHTTPClient::makeRequest(const simgear::HTTP::Request_ptr& r){if(_http)_http->makeRequest(r);else if(r)r->setFailure(-1,"HTTP client unavailable on Android");}
bool FGHTTPClient::isDefaultCatalogInstalled()const{return false;} simgear::pkg::CatalogRef FGHTTPClient::addDefaultCatalog(){return {};}
std::string FGHTTPClient::getDefaultCatalogId()const{return {};} std::string FGHTTPClient::getDefaultCatalogUrl()const{return {};} std::string FGHTTPClient::getDefaultCatalogFallbackUrl()const{return {};} 

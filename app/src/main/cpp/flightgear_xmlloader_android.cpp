#include <Airports/xmlloader.hxx>
#include <simgear/misc/sg_path.hxx>
XMLLoader::XMLLoader()=default; XMLLoader::~XMLLoader()=default;
bool XMLLoader::findAirportData(const std::string&,const std::string&,SGPath& p){p=SGPath();return false;}

#include <Aircraft/replay.hxx>
struct FGReplayInternal {};
FGReplay::FGReplay():m_internal(new FGReplayInternal){}
FGReplay::~FGReplay()=default;
void FGReplay::bind(){} void FGReplay::init(){} void FGReplay::reinit(){} void FGReplay::unbind(){} void FGReplay::update(double){}
bool FGReplay::start(bool){return false;} bool FGReplay::saveTape(const SGPropertyNode*){return false;} bool FGReplay::loadTape(const SGPropertyNode*){return false;}
int FGReplay::loadContinuousHeader(const std::string&,std::istream*,SGPropertyNode*){return -1;}
bool FGReplay::loadTape(const SGPath&,bool,bool,double,SGPropertyNode&,simgear::HTTP::FileRequestRef){return false;}
std::string FGReplay::makeTapePath(const std::string& p){return p;} void FGReplay::resetStatisticsProperties(){}

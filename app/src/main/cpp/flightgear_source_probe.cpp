// Compile-time integration probe for the real FlightGear source tree.
// This first gate verifies that Android's C++ compiler can see the fetched
// upstream SimGear headers before we enable the full desktop CMake graph.
#include <simgear/version.h>

extern "C" const char* fg_android_source_probe() {
    return "FlightGear/SimGear Android source tree visible";
}

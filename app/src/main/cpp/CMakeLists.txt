cmake_minimum_required(VERSION 3.22.1)
project(flightgear_android LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(FLIGHTGEAR_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../../../third_party/flightgear")
set(SIMGEAR_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../../../third_party/simgear")
set(FGOSG_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../../../third_party/openscenegraph")

add_library(flightgear_android SHARED
    native_bridge.cpp
    android_egl_surface.cpp
)

# Gate 1: prove that the real upstream source trees are visible to Android C++.
add_library(flightgear_source_probe OBJECT
    flightgear_source_probe.cpp
)

target_include_directories(flightgear_source_probe PRIVATE
    "${FLIGHTGEAR_ROOT}/src"
    "${SIMGEAR_ROOT}"
    "${SIMGEAR_ROOT}/simgear"
    "${FGOSG_ROOT}/include"
)

target_compile_definitions(flightgear_source_probe PRIVATE
    FG_ANDROID=1
    ANDROID=1
    SIMGEAR_USE_OPENGL=1
)

# Gate 2: compile an actual upstream FlightGear translation unit.  We keep it
# as an OBJECT target for now so the Android app remains linkable while this
# first real source file exposes desktop-only dependencies one at a time.
add_library(flightgear_main_probe OBJECT
    "${FLIGHTGEAR_ROOT}/src/Main/main.cxx"
)

target_include_directories(flightgear_main_probe PRIVATE
    "${FLIGHTGEAR_ROOT}/src"
    "${SIMGEAR_ROOT}"
    "${SIMGEAR_ROOT}/simgear"
    "${FGOSG_ROOT}/include"
)

target_compile_definitions(flightgear_main_probe PRIVATE
    FG_ANDROID=1
    ANDROID=1
    SIMGEAR_USE_OPENGL=1
)

target_compile_definitions(flightgear_android PRIVATE
    FG_ANDROID=1
    ANDROID=1
    SIMGEAR_USE_OPENGL=1
)

target_include_directories(flightgear_android PRIVATE
    "${FLIGHTGEAR_ROOT}/src"
    "${SIMGEAR_ROOT}"
    "${SIMGEAR_ROOT}/simgear"
    "${FGOSG_ROOT}/include"
)

target_link_libraries(flightgear_android
    android
    log
    EGL
    GLESv3
)

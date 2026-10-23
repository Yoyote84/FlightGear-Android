cmake_minimum_required(VERSION 3.22.1)
project(flightgear_android LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Android-native build of the real FlightGear source tree.
# The source fetch is kept separate so CI and local builds remain reproducible.
set(FLIGHTGEAR_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../../../third_party/flightgear")
set(SIMGEAR_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../../../third_party/simgear")
set(FGOSG_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../../../third_party/openscenegraph")

add_library(flightgear_android SHARED
    native_bridge.cpp
    android_egl_surface.cpp
)

target_compile_definitions(flightgear_android PRIVATE
    FG_ANDROID=1
    ANDROID=1
)

target_link_libraries(flightgear_android
    android
    log
    EGL
    GLESv3
)

# Keep the original source trees visible to the Android build as we progressively
# enable FlightGear/SimGear/FG OSG targets and replace desktop-only platform code.
target_include_directories(flightgear_android PRIVATE
    "${FLIGHTGEAR_ROOT}/src"
    "${SIMGEAR_ROOT}/simgear"
    "${FGOSG_ROOT}/include"
)

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

add_library(flightgear_source_probe OBJECT flightgear_source_probe.cpp)
target_include_directories(flightgear_source_probe PRIVATE
    "${FLIGHTGEAR_ROOT}/src" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear" "${FGOSG_ROOT}/include")
target_compile_definitions(flightgear_source_probe PRIVATE FG_ANDROID=1 ANDROID=1 SIMGEAR_USE_OPENGL=1)

add_library(flightgear_main_probe OBJECT "${FLIGHTGEAR_ROOT}/src/Main/main.cxx")
add_library(flightgear_bootstrap_probe OBJECT "${FLIGHTGEAR_ROOT}/src/Main/bootstrap.cxx")
foreach(probe flightgear_main_probe flightgear_bootstrap_probe)
    target_include_directories(${probe} PRIVATE
        "${FLIGHTGEAR_ROOT}/src" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear" "${FGOSG_ROOT}/include")
    target_compile_definitions(${probe} PRIVATE FG_ANDROID=1 ANDROID=1 SIMGEAR_USE_OPENGL=1)
endforeach()

# Gate 3: compile the upstream Main implementation as OBJECTs.
include("${CMAKE_CURRENT_LIST_DIR}/flightgear_main_sources.cmake")
add_library(flightgear_main_objects OBJECT ${FLIGHTGEAR_MAIN_SOURCES})
target_include_directories(flightgear_main_objects PRIVATE
    "${FLIGHTGEAR_ROOT}/src" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear" "${FGOSG_ROOT}/include")
target_compile_definitions(flightgear_main_objects PRIVATE FG_ANDROID=1 ANDROID=1 SIMGEAR_USE_OPENGL=1)

# Gate 4: compile a real SimGear translation unit for Android ARM64.
# Keep this target separate while the dependency graph is brought over in
# small, verifiable groups.
add_library(simgear_atomic_objects OBJECT
    "${SIMGEAR_ROOT}/simgear/structure/SGAtomic.cxx"
)
target_include_directories(simgear_atomic_objects PRIVATE
    "${SIMGEAR_ROOT}"
    "${SIMGEAR_ROOT}/simgear"
)
target_compile_definitions(simgear_atomic_objects PRIVATE
    ANDROID=1
    SGATOMIC_USE_LIBRARY_FUNCTIONS=1
    GCC_ATOMIC_BUILTINS_FOUND=1
)

# Gate 5: compile a real SimGear structure translation unit. SGReferenced and
# SGSharedPtr are header/template implementations in current SimGear and do
# not have standalone .cxx files. SGSourceLocation is a concrete source file,
# but it is intentionally left out here until the generated SimGear
# configuration header is provided by the native SimGear CMake setup.
# This keeps the gate grounded in files that actually exist and avoids
# introducing a hand-written replacement for upstream configuration.

# The final FlightGear/SimGear/FGOSG link will be enabled after the upstream
# SimGear configuration and dependency graph are brought into this build.
target_compile_definitions(flightgear_android PRIVATE FG_ANDROID=1 ANDROID=1 SIMGEAR_USE_OPENGL=1)
target_include_directories(flightgear_android PRIVATE
    "${FLIGHTGEAR_ROOT}/src" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear" "${FGOSG_ROOT}/include")
target_link_libraries(flightgear_android android log EGL GLESv3)

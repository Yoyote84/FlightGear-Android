cmake_minimum_required(VERSION 3.22.1)
project(flightgear_android LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(FLIGHTGEAR_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../../../third_party/flightgear")
set(SIMGEAR_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../../../third_party/simgear")
set(FGOSG_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../../../third_party/openscenegraph")
set(FLIGHTGEAR_CJSON_ROOT "${FLIGHTGEAR_ROOT}/3rdparty/cjson")

file(READ "${FLIGHTGEAR_ROOT}/flightgear-version" FLIGHTGEAR_VERSION)
string(STRIP "${FLIGHTGEAR_VERSION}" FLIGHTGEAR_VERSION)
string(REGEX MATCH "([0-9]+)\\.([0-9]+)\\.([0-9]+)" FLIGHTGEAR_VERSION_MATCH "${FLIGHTGEAR_VERSION}")
set(FLIGHTGEAR_MAJOR_VERSION "${CMAKE_MATCH_1}")
set(FLIGHTGEAR_MINOR_VERSION "${CMAKE_MATCH_2}")
set(FLIGHTGEAR_PATCH_VERSION "${CMAKE_MATCH_3}")
set(FG_DATA_DIR "${CMAKE_CURRENT_BINARY_DIR}/flightgear-data")
set(FG_BUILD_TYPE "Dev")
set(WEB_BROWSER "")
set(FG_HAVE_HLA 0)
set(FG_HAVE_DDS 0)
set(FG_HAVE_GPERFTOOLS 0)
set(FG_TEST_SUITE_DATA "")
set(sentry_api_key "")
set(ENABLE_YASIM 1)
set(ENABLE_JSBSIM 1)
set(ENABLE_PLIB_JOYSTICK 0)
set(ENABLE_SWIFT 0)
set(HAVE_SENTRY 0)

set(FLIGHTGEAR_GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/flightgear")
file(MAKE_DIRECTORY "${FLIGHTGEAR_GENERATED_DIR}")
configure_file("${FLIGHTGEAR_ROOT}/src/Include/config_cmake.h.in" "${FLIGHTGEAR_GENERATED_DIR}/config.h")

# FlightGear's normal build generates this header from Git metadata at build
# time. The Android build does not enter the upstream GenerateBuildInfo target,
# so generate the same public header directly in the native build tree.
execute_process(
    COMMAND git -C "${FLIGHTGEAR_ROOT}" rev-parse HEAD
    OUTPUT_VARIABLE FLIGHTGEAR_REVISION
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
)
if(NOT FLIGHTGEAR_REVISION)
    set(FLIGHTGEAR_REVISION "unknown")
endif()
string(TIMESTAMP FLIGHTGEAR_BUILD_DATE "%Y-%m-%d %H:%M:%S UTC" UTC)
configure_file(
    "${CMAKE_CURRENT_LIST_DIR}/flightgearBuildId.h.in"
    "${FLIGHTGEAR_GENERATED_DIR}/flightgearBuildId.h"
    @ONLY
)

# Reproduce the public generated headers from the upstream OSG build.
set(OSG_GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/osg_generated")
file(MAKE_DIRECTORY "${OSG_GENERATED_DIR}/osg")
file(MAKE_DIRECTORY "${OSG_GENERATED_DIR}/OpenThreads")
set(OSG_GL1_AVAILABLE 0)
set(OSG_GL2_AVAILABLE 0)
set(OSG_GL3_AVAILABLE 0)
set(OSG_GLES1_AVAILABLE 0)
set(OSG_GLES2_AVAILABLE 0)
set(OSG_GLES3_AVAILABLE 1)
set(OSG_GL1_FEATURES 0)
set(OSG_GL2_FEATURES 0)
set(OSG_GL3_FEATURES 0)
set(OSG_GLES1_FEATURES 0)
set(OSG_GLES2_FEATURES 0)
set(OSG_GLES3_FEATURES 1)
set(OSG_GL_DISPLAYLISTS_AVAILABLE 0)
set(OSG_GL_MATRICES_AVAILABLE 0)
set(OSG_GL_VERTEX_FUNCS_AVAILABLE 0)
set(OSG_GL_VERTEX_ARRAY_FUNCS_AVAILABLE 0)
set(OSG_GL_FIXED_FUNCTION_AVAILABLE 0)
set(OSG_CPP_EXCEPTIONS_AVAILABLE 0)
set(OSG_GL_CONTEXT_VERSION "3.0")
# Match the FlightGear OSG fork's CMake defaults for Android.
set(OSG_WINDOWING_SYSTEM "None")
set(OSG_WINDOWING_SYSTEM_NONE 1)
set(OSG_USE_REF_PTR_IMPLICIT_OUTPUT_CONVERSION 1)
set(OPENSCENEGRAPH_MAJOR_VERSION 3)
set(OPENSCENEGRAPH_MINOR_VERSION 6)
set(OPENSCENEGRAPH_PATCH_VERSION 5)
set(OPENSCENEGRAPH_SOVERSION 162)
set(OPENSCENEGRAPH_FG_MAJOR_VERSION 2024)
set(OPENSCENEGRAPH_FG_MINOR_VERSION 2)
set(OPENSCENEGRAPH_FG_PATCH_VERSION 0)
set(OPENGL_HEADER1 "#include <GLES3/gl3.h>")
set(OPENGL_HEADER2 "#include <GLES3/gl31.h>")
set(GL_HEADER_HAS_GLINT64 1)
set(GL_HEADER_HAS_GLUINT64 1)
configure_file("${FGOSG_ROOT}/src/osg/Config.in" "${OSG_GENERATED_DIR}/osg/Config")
configure_file("${FGOSG_ROOT}/src/osg/GL.in" "${OSG_GENERATED_DIR}/osg/GL")
configure_file("${FGOSG_ROOT}/src/osg/Version.in" "${OSG_GENERATED_DIR}/osg/Version")
configure_file("${FGOSG_ROOT}/src/OpenThreads/common/Config.in" "${OSG_GENERATED_DIR}/OpenThreads/Config")

# SimGear requires <simgear/simgear_config.h>, matching its normal install layout.
set(SIMGEAR_GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/simgear")
set(SIMGEAR_GENERATED_PARENT "${CMAKE_CURRENT_BINARY_DIR}")
file(MAKE_DIRECTORY "${SIMGEAR_GENERATED_DIR}")
configure_file("${CMAKE_CURRENT_LIST_DIR}/simgear_android_config.h.in" "${SIMGEAR_GENERATED_DIR}/simgear_config.h" @ONLY)
# Generate simgear/version.h from the upstream template, matching the normal
# SimGear build where CMake configure_file produces ${PROJECT_BINARY_DIR}/simgear/version.h.
# The template is at ${CMAKE_CURRENT_LIST_DIR}/../../../../third_party/simgear/simgear/version.h.in
configure_file("${CMAKE_CURRENT_LIST_DIR}/../../../../third_party/simgear/simgear/version.h.in" "${SIMGEAR_GENERATED_DIR}/version.h" @ONLY)

# Stage the host's header-only Boost tree under a non-system include root.
# CMake omits /usr/include from cross-compiler command lines as an implicit
# system path, but the Android NDK sysroot does not contain the host Boost tree.
set(BOOST_SOURCE_DIR "/usr/include/boost")
set(BOOST_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/boost_include")
if(NOT IS_DIRECTORY "${BOOST_SOURCE_DIR}")
    message(FATAL_ERROR "Boost headers not found at ${BOOST_SOURCE_DIR}; install libboost-dev before configuring.")
endif()
file(MAKE_DIRECTORY "${BOOST_INCLUDE_DIR}")
if(NOT EXISTS "${BOOST_INCLUDE_DIR}/boost")
    file(CREATE_LINK "${BOOST_SOURCE_DIR}" "${BOOST_INCLUDE_DIR}/boost" SYMBOLIC)
endif()
if(NOT EXISTS "${BOOST_INCLUDE_DIR}/boost/call_traits.hpp")
    message(FATAL_ERROR "Boost header staging failed: ${BOOST_INCLUDE_DIR}/boost/call_traits.hpp is missing.")
endif()

add_library(flightgear_android SHARED
    native_bridge.cpp
    android_egl_surface.cpp
)

# FlightGear's Main sources include cJSON.h and require cJSON symbols at link time.
add_library(flightgear_cjson OBJECT "${FLIGHTGEAR_CJSON_ROOT}/cJSON.c")
target_include_directories(flightgear_cjson PRIVATE "${FLIGHTGEAR_CJSON_ROOT}")

add_library(flightgear_source_probe OBJECT flightgear_source_probe.cpp)
target_include_directories(flightgear_source_probe PRIVATE
    "${FLIGHTGEAR_GENERATED_DIR}"
    "${OSG_GENERATED_DIR}"
    "${SIMGEAR_GENERATED_PARENT}"
    "${BOOST_INCLUDE_DIR}"
    "${FLIGHTGEAR_ROOT}/src" "${FLIGHTGEAR_CJSON_ROOT}" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear" "${FGOSG_ROOT}/include")
target_compile_definitions(flightgear_source_probe PRIVATE FG_ANDROID=1 ANDROID=1 SIMGEAR_USE_OPENGL=1)

add_library(flightgear_main_probe OBJECT "${FLIGHTGEAR_ROOT}/src/Main/main.cxx")
add_library(flightgear_bootstrap_probe OBJECT "${FLIGHTGEAR_ROOT}/src/Main/bootstrap.cxx")
foreach(probe flightgear_main_probe flightgear_bootstrap_probe)
    target_include_directories(${probe} PRIVATE
        "${FLIGHTGEAR_GENERATED_DIR}"
        "${OSG_GENERATED_DIR}"
        "${SIMGEAR_GENERATED_PARENT}"
        "${BOOST_INCLUDE_DIR}"
        "${FLIGHTGEAR_ROOT}/src" "${FLIGHTGEAR_CJSON_ROOT}" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear" "${FGOSG_ROOT}/include")
    target_compile_definitions(${probe} PRIVATE FG_ANDROID=1 ANDROID=1 SIMGEAR_USE_OPENGL=1)
endforeach()

include("${CMAKE_CURRENT_LIST_DIR}/flightgear_main_sources.cmake")
add_library(flightgear_main_objects OBJECT ${FLIGHTGEAR_MAIN_SOURCES})
target_include_directories(flightgear_main_objects PRIVATE
    "${FLIGHTGEAR_GENERATED_DIR}"
    "${OSG_GENERATED_DIR}"
    "${SIMGEAR_GENERATED_PARENT}"
    "${BOOST_INCLUDE_DIR}"
    "${FLIGHTGEAR_ROOT}/src" "${FLIGHTGEAR_CJSON_ROOT}" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear" "${FGOSG_ROOT}/include")
target_compile_definitions(flightgear_main_objects PRIVATE FG_ANDROID=1 ANDROID=1 SIMGEAR_USE_OPENGL=1)

add_library(simgear_atomic_objects OBJECT
    "${SIMGEAR_ROOT}/simgear/structure/SGAtomic.cxx"
)
target_include_directories(simgear_atomic_objects PRIVATE
    "${SIMGEAR_GENERATED_PARENT}"
    "${SIMGEAR_ROOT}"
    "${SIMGEAR_ROOT}/simgear"
)
target_compile_definitions(simgear_atomic_objects PRIVATE
    ANDROID=1
    SGATOMIC_USE_LIBRARY_FUNCTIONS=1
    GCC_ATOMIC_BUILTINS_FOUND=1
)

# Gate 7: compile the complete upstream SimGear structure component as
# independent OBJECTs. This follows SimGear's own structure/CMakeLists.txt
# source list instead of inventing replacement implementations.
set(SIMGEAR_GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/simgear")
file(MAKE_DIRECTORY "${SIMGEAR_GENERATED_DIR}")
set(SIMGEAR_STRUCTURE_SOURCES
    SGAtomic.cxx
    SGBinding.cxx
    SGExpression.cxx
    SGSmplhist.cxx
    SGSmplstat.cxx
    SGPerfMon.cxx
    SGSourceLocation.cxx
    StringTable.cxx
    commands.cxx
    event_mgr.cxx
    exception.cxx
    subsystem_mgr.cxx
    StateMachine.cxx
)
set(SIMGEAR_STRUCTURE_ABS_SOURCES)
foreach(source IN LISTS SIMGEAR_STRUCTURE_SOURCES)
    list(APPEND SIMGEAR_STRUCTURE_ABS_SOURCES "${SIMGEAR_ROOT}/simgear/structure/${source}")
endforeach()

add_library(simgear_structure_objects OBJECT ${SIMGEAR_STRUCTURE_ABS_SOURCES})
target_include_directories(simgear_structure_objects PRIVATE
    "${SIMGEAR_GENERATED_DIR}"
    "${SIMGEAR_ROOT}"
    "${SIMGEAR_ROOT}/simgear"
)
target_compile_definitions(simgear_structure_objects PRIVATE
    ANDROID=1
    HAVE_CONFIG_H=1
    SGATOMIC_USE_LIBRARY_FUNCTIONS=1
    GCC_ATOMIC_BUILTINS_FOUND=1
)

target_compile_definitions(flightgear_android PRIVATE FG_ANDROID=1 ANDROID=1 SIMGEAR_USE_OPENGL=1)
target_include_directories(flightgear_android PRIVATE
    "${FLIGHTGEAR_GENERATED_DIR}"
    "${OSG_GENERATED_DIR}"
    "${SIMGEAR_GENERATED_PARENT}"
    "${BOOST_INCLUDE_DIR}"
    "${FLIGHTGEAR_ROOT}/src" "${FLIGHTGEAR_CJSON_ROOT}" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear" "${FGOSG_ROOT}/include")

target_link_libraries(flightgear_android PRIVATE
    flightgear_main_objects
    flightgear_cjson
    android log EGL GLESv3
)

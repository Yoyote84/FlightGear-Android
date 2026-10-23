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

# Gates 7-8: compile upstream SimGear components as independent OBJECTs.
# The source lists mirror SimGear's own component CMake files; no replacement
# implementations are introduced here.
set(SIMGEAR_GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/simgear")
file(MAKE_DIRECTORY "${SIMGEAR_GENERATED_DIR}")
configure_file(
    "${CMAKE_CURRENT_LIST_DIR}/simgear_android_config.h.in"
    "${SIMGEAR_GENERATED_DIR}/simgear_config.h"
    @ONLY
)

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

set(SIMGEAR_PROPS_SOURCES
    AtomicChangeListener.cxx
    condition.cxx
    easing_functions.cxx
    PropertyBasedElement.cxx
    PropertyBasedMgr.cxx
    PropertyInterpolationMgr.cxx
    PropertyInterpolator.cxx
    propertyObject.cxx
    props.cxx
    props_io.cxx
)

set(SIMGEAR_PROPS_ABS_SOURCES)
foreach(source IN LISTS SIMGEAR_PROPS_SOURCES)
    list(APPEND SIMGEAR_PROPS_ABS_SOURCES "${SIMGEAR_ROOT}/simgear/props/${source}")
endforeach()

add_library(simgear_props_objects OBJECT ${SIMGEAR_PROPS_ABS_SOURCES})
target_include_directories(simgear_props_objects PRIVATE
    "${SIMGEAR_GENERATED_DIR}"
    "${SIMGEAR_ROOT}"
    "${SIMGEAR_ROOT}/simgear"
)
target_compile_definitions(simgear_props_objects PRIVATE
    ANDROID=1
    HAVE_CONFIG_H=1
    SGATOMIC_USE_LIBRARY_FUNCTIONS=1
    GCC_ATOMIC_BUILTINS_FOUND=1
)

# Gate 9: compile the remaining upstream SimGear components in one parallel
# translation-unit pool. CMake/Ninja will schedule independent files in
# parallel and enforce only the dependency boundaries that actually exist.
set(SIMGEAR_COMPONENT_DIRS
    bucket
    bvh
    canvas
    debug
    embedded_resources
    emesary
    environment
    ephemeris
    io
    magvar
    math
    misc
    nasal
    nasal/cppbind
    scene
    screen
    serial
    sound
    std
    threads
    timing
    xml
    package
)

set(SIMGEAR_REMAINING_SOURCES)
foreach(component IN LISTS SIMGEAR_COMPONENT_DIRS)
    file(GLOB_RECURSE component_sources CONFIGURE_DEPENDS
        "${SIMGEAR_ROOT}/simgear/${component}/*.c"
        "${SIMGEAR_ROOT}/simgear/${component}/*.cc"
        "${SIMGEAR_ROOT}/simgear/${component}/*.cpp"
        "${SIMGEAR_ROOT}/simgear/${component}/*.cxx"
    )
    list(APPEND SIMGEAR_REMAINING_SOURCES ${component_sources})
endforeach()

list(SORT SIMGEAR_REMAINING_SOURCES)
list(LENGTH SIMGEAR_REMAINING_SOURCES SIMGEAR_REMAINING_COUNT)
message(STATUS "SimGear remaining native C/C++ sources: ${SIMGEAR_REMAINING_COUNT}")

add_library(simgear_remaining_objects OBJECT ${SIMGEAR_REMAINING_SOURCES})
target_include_directories(simgear_remaining_objects PRIVATE
    "${SIMGEAR_GENERATED_DIR}"
    "${SIMGEAR_ROOT}"
    "${SIMGEAR_ROOT}/simgear"
    "${FGOSG_ROOT}/include"
)
target_compile_definitions(simgear_remaining_objects PRIVATE
    ANDROID=1
    HAVE_CONFIG_H=1
    SGATOMIC_USE_LIBRARY_FUNCTIONS=1
    GCC_ATOMIC_BUILTINS_FOUND=1
    FG_ANDROID=1
    SIMGEAR_USE_OPENGL=1
)

target_compile_definitions(flightgear_android PRIVATE FG_ANDROID=1 ANDROID=1 SIMGEAR_USE_OPENGL=1)
target_include_directories(flightgear_android PRIVATE
    "${FLIGHTGEAR_ROOT}/src" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear" "${FGOSG_ROOT}/include")
target_link_libraries(flightgear_android android log EGL GLESv3)

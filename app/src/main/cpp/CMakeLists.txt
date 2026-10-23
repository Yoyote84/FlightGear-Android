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

include("${CMAKE_CURRENT_LIST_DIR}/flightgear_main_sources.cmake")
add_library(flightgear_main_objects OBJECT ${FLIGHTGEAR_MAIN_SOURCES})
target_include_directories(flightgear_main_objects PRIVATE
    "${FLIGHTGEAR_ROOT}/src" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear" "${FGOSG_ROOT}/include")
target_compile_definitions(flightgear_main_objects PRIVATE FG_ANDROID=1 ANDROID=1 SIMGEAR_USE_OPENGL=1)

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

set(SIMGEAR_GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/simgear")
file(MAKE_DIRECTORY "${SIMGEAR_GENERATED_DIR}")
configure_file(
    "${CMAKE_CURRENT_LIST_DIR}/simgear_android_config.h.in"
    "${SIMGEAR_GENERATED_DIR}/simgear_config.h"
    @ONLY
)

set(SIMGEAR_STRUCTURE_SOURCES
    SGAtomic.cxx SGBinding.cxx SGExpression.cxx SGSmplhist.cxx SGSmplstat.cxx
    SGPerfMon.cxx SGSourceLocation.cxx StringTable.cxx commands.cxx event_mgr.cxx
    exception.cxx subsystem_mgr.cxx StateMachine.cxx
)
set(SIMGEAR_STRUCTURE_ABS_SOURCES)
foreach(source IN LISTS SIMGEAR_STRUCTURE_SOURCES)
    list(APPEND SIMGEAR_STRUCTURE_ABS_SOURCES "${SIMGEAR_ROOT}/simgear/structure/${source}")
endforeach()
add_library(simgear_structure_objects OBJECT ${SIMGEAR_STRUCTURE_ABS_SOURCES})
target_include_directories(simgear_structure_objects PRIVATE "${SIMGEAR_GENERATED_DIR}" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear")
target_compile_definitions(simgear_structure_objects PRIVATE ANDROID=1 HAVE_CONFIG_H=1 SGATOMIC_USE_LIBRARY_FUNCTIONS=1 GCC_ATOMIC_BUILTINS_FOUND=1)

set(SIMGEAR_PROPS_SOURCES
    AtomicChangeListener.cxx condition.cxx easing_functions.cxx PropertyBasedElement.cxx
    PropertyBasedMgr.cxx PropertyInterpolationMgr.cxx PropertyInterpolator.cxx
    propertyObject.cxx props.cxx props_io.cxx
)
set(SIMGEAR_PROPS_ABS_SOURCES)
foreach(source IN LISTS SIMGEAR_PROPS_SOURCES)
    list(APPEND SIMGEAR_PROPS_ABS_SOURCES "${SIMGEAR_ROOT}/simgear/props/${source}")
endforeach()
add_library(simgear_props_objects OBJECT ${SIMGEAR_PROPS_ABS_SOURCES})
target_include_directories(simgear_props_objects PRIVATE "${SIMGEAR_GENERATED_DIR}" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear")
target_compile_definitions(simgear_props_objects PRIVATE ANDROID=1 HAVE_CONFIG_H=1 SGATOMIC_USE_LIBRARY_FUNCTIONS=1 GCC_ATOMIC_BUILTINS_FOUND=1)

set(SIMGEAR_COMPONENT_DIRS
    bucket bvh canvas debug embedded_resources emesary environment ephemeris io magvar
    math misc nasal nasal/cppbind scene screen serial sound std threads timing xml package
)
set(SIMGEAR_REMAINING_SOURCES)
foreach(component IN LISTS SIMGEAR_COMPONENT_DIRS)
    file(GLOB_RECURSE component_sources CONFIGURE_DEPENDS
        "${SIMGEAR_ROOT}/simgear/${component}/*.c"
        "${SIMGEAR_ROOT}/simgear/${component}/*.cc"
        "${SIMGEAR_ROOT}/simgear/${component}/*.cpp"
        "${SIMGEAR_ROOT}/simgear/${component}/*.cxx")
    list(APPEND SIMGEAR_REMAINING_SOURCES ${component_sources})
endforeach()
list(SORT SIMGEAR_REMAINING_SOURCES)
add_library(simgear_remaining_objects OBJECT ${SIMGEAR_REMAINING_SOURCES})
target_include_directories(simgear_remaining_objects PRIVATE "${SIMGEAR_GENERATED_DIR}" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear" "${FGOSG_ROOT}/include")
target_compile_definitions(simgear_remaining_objects PRIVATE ANDROID=1 HAVE_CONFIG_H=1 SGATOMIC_USE_LIBRARY_FUNCTIONS=1 GCC_ATOMIC_BUILTINS_FOUND=1 FG_ANDROID=1 SIMGEAR_USE_OPENGL=1)

set(SIMGEAR_CORE_COMPONENT_DIRS
    bucket debug embedded_resources emesary ephemeris io magvar math misc nasal nasal/cppbind
    serial std threads timing xml package
)
set(SIMGEAR_CORE_SOURCES)
foreach(component IN LISTS SIMGEAR_CORE_COMPONENT_DIRS)
    file(GLOB_RECURSE core_component_sources CONFIGURE_DEPENDS
        "${SIMGEAR_ROOT}/simgear/${component}/*.c"
        "${SIMGEAR_ROOT}/simgear/${component}/*.cc"
        "${SIMGEAR_ROOT}/simgear/${component}/*.cpp"
        "${SIMGEAR_ROOT}/simgear/${component}/*.cxx")
    list(APPEND SIMGEAR_CORE_SOURCES ${core_component_sources})
endforeach()
list(SORT SIMGEAR_CORE_SOURCES)
add_library(simgear_core_objects OBJECT ${SIMGEAR_CORE_SOURCES})
target_include_directories(simgear_core_objects PRIVATE "${SIMGEAR_GENERATED_DIR}" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear")
target_compile_definitions(simgear_core_objects PRIVATE ANDROID=1 HAVE_CONFIG_H=1 SGATOMIC_USE_LIBRARY_FUNCTIONS=1 GCC_ATOMIC_BUILTINS_FOUND=1 FG_ANDROID=1)
add_library(SimGearCore STATIC
    $<TARGET_OBJECTS:simgear_structure_objects>
    $<TARGET_OBJECTS:simgear_props_objects>
    $<TARGET_OBJECTS:simgear_core_objects>)
target_include_directories(SimGearCore PUBLIC "${SIMGEAR_GENERATED_DIR}" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear")
target_compile_definitions(SimGearCore PUBLIC ANDROID=1 HAVE_CONFIG_H=1 SGATOMIC_USE_LIBRARY_FUNCTIONS=1 GCC_ATOMIC_BUILTINS_FOUND=1 FG_ANDROID=1)
target_link_libraries(SimGearCore PUBLIC android log)

set(SIMGEAR_SCENE_COMPONENT_DIRS
    bvh canvas scene/material scene/model scene/sky scene/tgdb scene/util scene/tsync scene/viewer screen
)
set(SIMGEAR_SCENE_SOURCES)
foreach(component IN LISTS SIMGEAR_SCENE_COMPONENT_DIRS)
    file(GLOB_RECURSE scene_component_sources CONFIGURE_DEPENDS
        "${SIMGEAR_ROOT}/simgear/${component}/*.c"
        "${SIMGEAR_ROOT}/simgear/${component}/*.cc"
        "${SIMGEAR_ROOT}/simgear/${component}/*.cpp"
        "${SIMGEAR_ROOT}/simgear/${component}/*.cxx")
    list(APPEND SIMGEAR_SCENE_SOURCES ${scene_component_sources})
endforeach()
foreach(component IN ITEMS canvas/ShaderVG/src canvas/elements canvas/events canvas/layout)
    file(GLOB_RECURSE canvas_component_sources CONFIGURE_DEPENDS
        "${SIMGEAR_ROOT}/simgear/${component}/*.c"
        "${SIMGEAR_ROOT}/simgear/${component}/*.cc"
        "${SIMGEAR_ROOT}/simgear/${component}/*.cpp"
        "${SIMGEAR_ROOT}/simgear/${component}/*.cxx")
    list(APPEND SIMGEAR_SCENE_SOURCES ${canvas_component_sources})
endforeach()
list(REMOVE_DUPLICATES SIMGEAR_SCENE_SOURCES)
list(SORT SIMGEAR_SCENE_SOURCES)
add_library(simgear_scene_objects OBJECT ${SIMGEAR_SCENE_SOURCES})
target_include_directories(simgear_scene_objects PRIVATE "${SIMGEAR_GENERATED_DIR}" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear" "${FGOSG_ROOT}/include")
target_compile_definitions(simgear_scene_objects PRIVATE ANDROID=1 HAVE_CONFIG_H=1 SGATOMIC_USE_LIBRARY_FUNCTIONS=1 GCC_ATOMIC_BUILTINS_FOUND=1 FG_ANDROID=1 SIMGEAR_USE_OPENGL=1 SIMGEAR_HAVE_OPENGL=1 SIMGEAR_HAVE_OPENGL_ES=1)
add_library(SimGearScene STATIC $<TARGET_OBJECTS:simgear_scene_objects>)
target_include_directories(SimGearScene PUBLIC "${SIMGEAR_GENERATED_DIR}" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear" "${FGOSG_ROOT}/include")
target_compile_definitions(SimGearScene PUBLIC ANDROID=1 HAVE_CONFIG_H=1 FG_ANDROID=1 SIMGEAR_USE_OPENGL=1 SIMGEAR_HAVE_OPENGL=1 SIMGEAR_HAVE_OPENGL_ES=1)
target_link_libraries(SimGearScene PUBLIC SimGearCore android log)

set(FGOSG_INCLUDE_DIR "${FGOSG_ROOT}/include")

file(GLOB_RECURSE FGOSG_OPENTHREADS_SOURCES CONFIGURE_DEPENDS
    "${FGOSG_ROOT}/src/OpenThreads/*.c"
    "${FGOSG_ROOT}/src/OpenThreads/*.cc"
    "${FGOSG_ROOT}/src/OpenThreads/*.cpp"
    "${FGOSG_ROOT}/src/OpenThreads/*.cxx")
add_library(FGOpenThreads OBJECT ${FGOSG_OPENTHREADS_SOURCES})
target_include_directories(FGOpenThreads PRIVATE "${FGOSG_INCLUDE_DIR}" "${FGOSG_ROOT}/src")
target_compile_definitions(FGOpenThreads PRIVATE ANDROID=1 OSG_LIBRARY_STATIC=1)

file(GLOB_RECURSE FGOSG_OSG_SOURCES CONFIGURE_DEPENDS
    "${FGOSG_ROOT}/src/osg/*.cpp"
    "${FGOSG_ROOT}/src/osg/*.cxx")
add_library(FGOSGCore OBJECT ${FGOSG_OSG_SOURCES})
target_include_directories(FGOSGCore PRIVATE "${FGOSG_INCLUDE_DIR}" "${FGOSG_ROOT}/src")
target_compile_definitions(FGOSGCore PRIVATE
    ANDROID=1 OSG_LIBRARY_STATIC=1 OSG_GL1_AVAILABLE=0 OSG_GL2_AVAILABLE=1
    OSG_GL3_AVAILABLE=1 OSG_GLES1_AVAILABLE=1 OSG_GLES2_AVAILABLE=1
    OSG_WINDOWING_SYSTEM_NONE=1)
add_library(FGOpenSceneGraph STATIC
    $<TARGET_OBJECTS:FGOpenThreads>
    $<TARGET_OBJECTS:FGOSGCore>)
target_include_directories(FGOpenSceneGraph PUBLIC "${FGOSG_INCLUDE_DIR}" "${FGOSG_ROOT}/src")
target_compile_definitions(FGOpenSceneGraph PUBLIC ANDROID=1 OSG_LIBRARY_STATIC=1 OSG_WINDOWING_SYSTEM_NONE=1)
target_link_libraries(FGOpenSceneGraph PUBLIC android log EGL GLESv3)

# Gate 13: osgDB
file(GLOB_RECURSE FGOSG_OSGDB_SOURCES CONFIGURE_DEPENDS
    "${FGOSG_ROOT}/src/osgDB/*.cpp"
    "${FGOSG_ROOT}/src/osgDB/*.cxx")
add_library(FGOSGDB OBJECT ${FGOSG_OSGDB_SOURCES})
target_include_directories(FGOSGDB PRIVATE "${FGOSG_INCLUDE_DIR}" "${FGOSG_ROOT}/src" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear")
target_compile_definitions(FGOSGDB PRIVATE
    ANDROID=1 OSG_LIBRARY_STATIC=1 OSG_GL1_AVAILABLE=0 OSG_GL2_AVAILABLE=1
    OSG_GL3_AVAILABLE=1 OSG_GLES1_AVAILABLE=1 OSG_GLES2_AVAILABLE=1
    OSG_WINDOWING_SYSTEM_NONE=1)

# Gate 14: osgUtil. Keep it isolated so Android portability errors remain
# visible before we assemble the renderer stack.
file(GLOB_RECURSE FGOSG_OSGUTIL_SOURCES CONFIGURE_DEPENDS
    "${FGOSG_ROOT}/src/osgUtil/*.cpp"
    "${FGOSG_ROOT}/src/osgUtil/*.cxx")
add_library(FGOSGUtil OBJECT ${FGOSG_OSGUTIL_SOURCES})
target_include_directories(FGOSGUtil PRIVATE
    "${FGOSG_INCLUDE_DIR}" "${FGOSG_ROOT}/src" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear")
target_compile_definitions(FGOSGUtil PRIVATE
    ANDROID=1 OSG_LIBRARY_STATIC=1 OSG_GL1_AVAILABLE=0 OSG_GL2_AVAILABLE=1
    OSG_GL3_AVAILABLE=1 OSG_GLES1_AVAILABLE=1 OSG_GLES2_AVAILABLE=1
    OSG_WINDOWING_SYSTEM_NONE=1)

# Gate 15: osgGA. Input/event adapters are compiled independently first so
# Android portability errors stay isolated before linking the renderer stack.
file(GLOB_RECURSE FGOSG_OSGGA_SOURCES CONFIGURE_DEPENDS
    "${FGOSG_ROOT}/src/osgGA/*.cpp"
    "${FGOSG_ROOT}/src/osgGA/*.cxx")
add_library(FGOSGGA OBJECT ${FGOSG_OSGGA_SOURCES})
target_include_directories(FGOSGGA PRIVATE
    "${FGOSG_INCLUDE_DIR}" "${FGOSG_ROOT}/src" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear")
target_compile_definitions(FGOSGGA PRIVATE
    ANDROID=1 OSG_LIBRARY_STATIC=1 OSG_GL1_AVAILABLE=0 OSG_GL2_AVAILABLE=1
    OSG_GL3_AVAILABLE=1 OSG_GLES1_AVAILABLE=1 OSG_GLES2_AVAILABLE=1
    OSG_WINDOWING_SYSTEM_NONE=1)

# Gate 16: osgText. Text rendering is kept isolated before we bring osgViewer
# and the full viewer stack into the final link.
file(GLOB_RECURSE FGOSG_OSGTEXT_SOURCES CONFIGURE_DEPENDS
    "${FGOSG_ROOT}/src/osgText/*.cpp"
    "${FGOSG_ROOT}/src/osgText/*.cxx")
add_library(FGOSGText OBJECT ${FGOSG_OSGTEXT_SOURCES})
target_include_directories(FGOSGText PRIVATE
    "${FGOSG_INCLUDE_DIR}" "${FGOSG_ROOT}/src" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear")
target_compile_definitions(FGOSGText PRIVATE
    ANDROID=1 OSG_LIBRARY_STATIC=1 OSG_GL1_AVAILABLE=0 OSG_GL2_AVAILABLE=1
    OSG_GL3_AVAILABLE=1 OSG_GLES1_AVAILABLE=1 OSG_GLES2_AVAILABLE=1
    OSG_WINDOWING_SYSTEM_NONE=1)

target_compile_definitions(flightgear_android PRIVATE FG_ANDROID=1 ANDROID=1 SIMGEAR_USE_OPENGL=1)
target_include_directories(flightgear_android PRIVATE "${FLIGHTGEAR_ROOT}/src" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear" "${FGOSG_ROOT}/include")
target_link_libraries(flightgear_android android log EGL GLESv3)

# First native FlightGear Main source set for Android.
# Keep the upstream source files as OBJECTs while platform dependencies are
# adapted incrementally. This is intentionally separate from the final fgfs
# executable target.
set(FLIGHTGEAR_MAIN_SOURCES
    "${FLIGHTGEAR_ROOT}/src/Main/fg_commands.cxx"
    "${FLIGHTGEAR_ROOT}/src/Main/fg_init.cxx"
    "${FLIGHTGEAR_ROOT}/src/Main/fg_io.cxx"
    "${FLIGHTGEAR_ROOT}/src/Main/fg_os_common.cxx"
    "${FLIGHTGEAR_ROOT}/src/Main/fg_scene_commands.cxx"
    "${FLIGHTGEAR_ROOT}/src/Main/fg_props.cxx"
    "${FLIGHTGEAR_ROOT}/src/Main/FGInterpolator.cxx"
    "${FLIGHTGEAR_ROOT}/src/Main/globals.cxx"
    "${FLIGHTGEAR_ROOT}/src/Main/locale.cxx"
    "${FLIGHTGEAR_ROOT}/src/Main/logger.cxx"
    "${FLIGHTGEAR_ROOT}/src/Main/options.cxx"
    "${FLIGHTGEAR_ROOT}/src/Main/positioninit.cxx"
    "${FLIGHTGEAR_ROOT}/src/Main/subsystemFactory.cxx"
    "${FLIGHTGEAR_ROOT}/src/Main/util.cxx"
    "${FLIGHTGEAR_ROOT}/src/Main/XLIFFParser.cxx"
    "${FLIGHTGEAR_ROOT}/src/Main/ErrorReporter.cxx"
)

# Android-native OSG builds normally receive osg/Config and osg/GL from the
# upstream CMake configure step. This project compiles OSG sources directly,
# so reproduce those generated headers here instead of depending on a desktop
# OSG installation.
set(FGOSG_GENERATED_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/openscenegraph/include")
file(MAKE_DIRECTORY "${FGOSG_GENERATED_INCLUDE_DIR}/osg")

set(OSG_NOTIFY_DISABLED OFF)
set(OSG_USE_FLOAT_MATRIX OFF)
set(OSG_USE_FLOAT_PLANE OFF)
set(OSG_USE_FLOAT_BOUNDINGSPHERE OFF)
set(OSG_USE_FLOAT_BOUNDINGBOX OFF)
set(OSG_USE_FLOAT_QUAT OFF)
set(OSG_USE_REF_PTR_IMPLICIT_OUTPUT_CONVERSION ON)
set(OSG_USE_REF_PTR_SAFE_DEREFERENCE OFF)
set(OSG_USE_UTF8_FILENAME ON)
set(OSG_DISABLE_MSVC_WARNINGS OFF)
set(OSG_PROVIDE_READFILE ON)
set(OSG_USE_DEPRECATED_API ON)
set(OSG_ENVVAR_SUPPORTED ON)
set(OSG_WINDOWING_SYSTEM_CARBON OFF)
set(OSG_WINDOWING_SYSTEM_NONE ON)

set(OSG_GL1_AVAILABLE OFF)
set(OSG_GL2_AVAILABLE ON)
set(OSG_GL3_AVAILABLE ON)
set(OSG_GLES1_AVAILABLE ON)
set(OSG_GLES2_AVAILABLE ON)
set(OSG_GLES3_AVAILABLE OFF)
set(OSG_GL_LIBRARY_STATIC ON)
set(OSG_GL_DISPLAYLISTS_AVAILABLE OFF)
set(OSG_GL_MATRICES_AVAILABLE OFF)
set(OSG_GL_VERTEX_FUNCS_AVAILABLE OFF)
set(OSG_GL_VERTEX_ARRAY_FUNCS_AVAILABLE OFF)
set(OSG_GL_FIXED_FUNCTION_AVAILABLE OFF)
set(GL_HEADER_HAS_GLINT64 OFF)
set(GL_HEADER_HAS_GLUINT64 OFF)
set(OSG_GL1_FEATURES false)
set(OSG_GL2_FEATURES true)
set(OSG_GL3_FEATURES true)
set(OSG_GLES1_FEATURES true)
set(OSG_GLES2_FEATURES true)
set(OSG_GLES3_FEATURES false)
set(OSG_GL_CONTEXT_VERSION "")
set(OPENGL_HEADER1 "#include <GLES2/gl2.h>")
set(OPENGL_HEADER2 "")

configure_file(
    "${FGOSG_ROOT}/src/osg/Config.in"
    "${FGOSG_GENERATED_INCLUDE_DIR}/osg/Config"
    @ONLY
)
configure_file(
    "${FGOSG_ROOT}/src/osg/GL.in"
    "${FGOSG_GENERATED_INCLUDE_DIR}/osg/GL"
    @ONLY
)

include_directories(BEFORE "${FGOSG_GENERATED_INCLUDE_DIR}")

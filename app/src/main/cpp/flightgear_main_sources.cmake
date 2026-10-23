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

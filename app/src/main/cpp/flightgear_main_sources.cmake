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

    # SimGear core components required by the native FlightGear Main sources.
    # Keep the upstream implementations; compiling them into the same OBJECT
    # target avoids introducing another shared-library dependency at this gate.
    "${SIMGEAR_ROOT}/simgear/props/AtomicChangeListener.cxx"
    "${SIMGEAR_ROOT}/simgear/props/condition.cxx"
    "${SIMGEAR_ROOT}/simgear/props/easing_functions.cxx"
    "${SIMGEAR_ROOT}/simgear/props/PropertyBasedElement.cxx"
    "${SIMGEAR_ROOT}/simgear/props/PropertyBasedMgr.cxx"
    "${SIMGEAR_ROOT}/simgear/props/PropertyInterpolationMgr.cxx"
    "${SIMGEAR_ROOT}/simgear/props/PropertyInterpolator.cxx"
    "${SIMGEAR_ROOT}/simgear/props/propertyObject.cxx"
    "${SIMGEAR_ROOT}/simgear/props/props.cxx"
    "${SIMGEAR_ROOT}/simgear/props/props_io.cxx"
    "${SIMGEAR_ROOT}/simgear/math/interpolater.cxx"
    "${SIMGEAR_ROOT}/simgear/threads/SGThread.cxx"
    "${CMAKE_CURRENT_LIST_DIR}/simgear_strutils_android.cpp"

    "${SIMGEAR_ROOT}/simgear/debug/logstream.cxx"
    "${SIMGEAR_ROOT}/simgear/debug/BufferedLogCallback.cxx"
    "${SIMGEAR_ROOT}/simgear/debug/LogCallback.cxx"
    "${SIMGEAR_ROOT}/simgear/debug/LogEntry.cxx"
    "${SIMGEAR_ROOT}/simgear/debug/logdelta.cxx"
    "${SIMGEAR_ROOT}/simgear/debug/ErrorReportingCallback.cxx"
    "${SIMGEAR_ROOT}/simgear/debug/Reporting.cxx"

    "${SIMGEAR_ROOT}/simgear/timing/lowleveltime.cxx"
    "${SIMGEAR_ROOT}/simgear/timing/sg_time.cxx"
    "${SIMGEAR_ROOT}/simgear/timing/timestamp.cxx"
    "${SIMGEAR_ROOT}/simgear/timing/timezone.cxx"
    "${SIMGEAR_ROOT}/simgear/timing/zonedetect.c"

    # SimGear misc/IO implementations required by FlightGear Main.
    "${SIMGEAR_ROOT}/simgear/misc/sg_path.cxx"
    "${SIMGEAR_ROOT}/simgear/io/iostreams/sgstream.cxx"
    "${SIMGEAR_ROOT}/simgear/io/iostreams/gzfstream.cxx"
    "${SIMGEAR_ROOT}/simgear/io/iostreams/gzcontainerfile.cxx"
    "${SIMGEAR_ROOT}/simgear/io/iostreams/CharArrayStream.cxx"
    "${SIMGEAR_ROOT}/simgear/io/iostreams/zlibstream.cxx"

    # SimGear embedded-resource runtime.
    "${SIMGEAR_ROOT}/simgear/embedded_resources/EmbeddedResource.cxx"
    "${SIMGEAR_ROOT}/simgear/embedded_resources/EmbeddedResourceManager.cxx"
    "${SIMGEAR_ROOT}/simgear/embedded_resources/EmbeddedResourceProxy.cxx"

    # FlightGear Viewer and scripting implementations referenced by Main.
    "${FLIGHTGEAR_ROOT}/src/Viewer/renderer.cxx"
    "${FLIGHTGEAR_ROOT}/src/Viewer/view.cxx"
    "${FLIGHTGEAR_ROOT}/src/Viewer/viewmgr.cxx"
    "${FLIGHTGEAR_ROOT}/src/Scripting/NasalSys.cxx"
    "${FLIGHTGEAR_ROOT}/src/GUI/gui_funcs.cxx"

    # OSG core implementations needed by Group's transitive Node/Geometry/Notify
    # dependencies. Keep these as upstream sources until the full OSG library
    # target is integrated into the Android build graph.
    "${FGOSG_ROOT}/src/osg/Group.cpp"
    "${FGOSG_ROOT}/src/osg/Node.cpp"
    "${FGOSG_ROOT}/src/osg/Geometry.cpp"
    "${FGOSG_ROOT}/src/osg/Notify.cpp"
    "${FGOSG_ROOT}/src/osg/OccluderNode.cpp"
    "${FGOSG_ROOT}/src/osg/Referenced.cpp"
    "${FGOSG_ROOT}/src/osg/Object.cpp"
    "${FGOSG_ROOT}/src/osg/Drawable.cpp"
    "${FGOSG_ROOT}/src/osg/ApplicationUsage.cpp"
    "${FGOSG_ROOT}/src/osg/CopyOp.cpp"
    "${FGOSG_ROOT}/src/osg/StateAttribute.cpp"
    "${FGOSG_ROOT}/src/osg/StateSet.cpp"
    "${FGOSG_ROOT}/src/osg/VertexArrayState.cpp"
)

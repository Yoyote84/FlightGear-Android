from pathlib import Path

root = Path(__file__).resolve().parents[1]
p = root / "app/src/main/cpp/CMakeLists.txt"
s = p.read_text()

# Android/Bionic provides timegm(); SimGear's configure step is not run in this
# native build, so expose the capability explicitly.
anchor = "set(CMAKE_POSITION_INDEPENDENT_CODE ON)\n"
if "add_compile_definitions(HAVE_TIMEGM=1)" not in s:
    if anchor not in s:
        raise SystemExit("expected CMake position-independent anchor not found")
    s = s.replace(anchor, anchor + "add_compile_definitions(HAVE_TIMEGM=1)\n", 1)

needle = '"${FLIGHTGEAR_ROOT}/src" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear" "${FGOSG_ROOT}/include"'
replacement = '"${FLIGHTGEAR_ROOT}/src" "${FLIGHTGEAR_ROOT}/src/Include" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear" "${FGOSG_ROOT}/include"'
if replacement not in s:
    if needle not in s:
        raise SystemExit("expected CMake include path not found")
    s = s.replace(needle, replacement, 1)

# SimGear normally creates its bundled Expat target from 3rdparty/CMakeLists.
# Our Android build assembles SimGear sources directly, so reproduce the
# important parts here: generate the Expat config, add its C sources, and expose
# the bundled headers to easyxml.cxx.
expat_anchor = 'set(SIMGEAR_GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/simgear")\n'
expat_block = '''set(SIMGEAR_EXPAT_ROOT "${SIMGEAR_ROOT}/3rdparty/expat")
set(SIMGEAR_EXPAT_GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/simgear_expat")
file(MAKE_DIRECTORY "${SIMGEAR_EXPAT_GENERATED_DIR}")
set(XML_DEV_URANDOM 1)
configure_file(
    "${SIMGEAR_EXPAT_ROOT}/expat_config_cmake.in"
    "${SIMGEAR_EXPAT_GENERATED_DIR}/simgear_expat_config.h"
    @ONLY)
include_directories("${SIMGEAR_EXPAT_ROOT}" "${SIMGEAR_EXPAT_GENERATED_DIR}")

'''
if expat_block not in s:
    if expat_anchor not in s:
        raise SystemExit("expected SimGear generated-dir anchor not found")
    s = s.replace(expat_anchor, expat_anchor + expat_block, 1)

expat_source_anchor = 'foreach(component IN LISTS SIMGEAR_CORE_COMPONENT_DIRS)\n'
# Add the bundled Expat C implementation exactly once to SimGearCore.
if 'file(GLOB SIMGEAR_EXPAT_SOURCES' not in s:
    marker = 'list(SORT SIMGEAR_CORE_SOURCES)\n'
    insertion = '''file(GLOB SIMGEAR_EXPAT_SOURCES CONFIGURE_DEPENDS
    "${SIMGEAR_EXPAT_ROOT}/*.c")
list(APPEND SIMGEAR_CORE_SOURCES ${SIMGEAR_EXPAT_SOURCES})
'''
    if marker not in s:
        raise SystemExit("expected SimGear core sort anchor not found")
    s = s.replace(marker, insertion + marker, 1)

core_defs = 'ANDROID=1 HAVE_CONFIG_H=1 SGATOMIC_USE_LIBRARY_FUNCTIONS=1 GCC_ATOMIC_BUILTINS_FOUND=1 FG_ANDROID=1'
core_defs_replacement = core_defs + ' HAVE_SIMGEAR_EXPAT_CONFIG_H=1 XML_STATIC=1'
old_core = f'target_compile_definitions(simgear_core_objects PRIVATE {core_defs})'
new_core = f'target_compile_definitions(simgear_core_objects PRIVATE {core_defs_replacement})'
if old_core in s and new_core not in s:
    s = s.replace(old_core, new_core, 1)

# Keep the existing source exclusions; they are needed because the Android build
# intentionally assembles SimGearCore without the optional desktop utilities.
test_filter = 'list(FILTER {var} EXCLUDE REGEX "/([^/]*[Tt][Ee][Ss][Tt][^/]*)\\.(c|cc|cpp|cxx)$")'
filters = {}
for var in ("SIMGEAR_REMAINING_SOURCES", "SIMGEAR_CORE_SOURCES", "SIMGEAR_SCENE_SOURCES"):
    filters[f"list(SORT {var})\n"] = (
        f"list(SORT {var})\n"
        + test_filter.format(var=var) + "\n"
        + f'list(FILTER {var} EXCLUDE REGEX "/(DNSClient(_cares)?|text_DNS)\\.cxx$")\n'
        + f'list(FILTER {var} EXCLUDE REGEX "/(HTTPClient|HTTPFileRequest|HTTPRepository|HTTPRequest|HTTPMemoryRequest|http_repo_sync|httpget)\\.cxx$")\n'
        + f'list(FILTER {var} EXCLUDE REGEX "/SGDataDistributionService\\.cxx$")\n'
        + f'list(FILTER {var} EXCLUDE REGEX "/package/.*\\.(c|cc|cpp|cxx)$")\n'
        + f'list(FILTER {var} EXCLUDE REGEX "/scene/tsync/.*\\.(c|cc|cpp|cxx)$")\n'
        + f'list(FILTER {var} EXCLUDE REGEX "/CanvasImage\\.cxx$")\n'
        + f'list(FILTER {var} EXCLUDE REGEX "/untar\\.cxx$")\n'
        + f'list(FILTER {var} EXCLUDE REGEX "/sha1\\.c$")\n'
        + f'list(FILTER {var} EXCLUDE REGEX "/nasal-bin\\.c$")\n'
    )
for needle, replacement in filters.items():
    if replacement not in s:
        if needle not in s:
            raise SystemExit(f"expected CMake source-list anchor not found: {needle}")
        s = s.replace(needle, replacement, 1)

p.write_text(s)

glu = root / "third_party/openscenegraph/include/osg/GLU"
if glu.exists():
    g = glu.read_text()
    inc = "#include <osg/Config>\n"
    if inc not in g:
        marker = "#pragma once\n"
        if marker in g:
            g = g.replace(marker, marker + inc, 1)
        else:
            g = inc + g
        glu.write_text(g)

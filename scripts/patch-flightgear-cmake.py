from pathlib import Path

root = Path(__file__).resolve().parents[1]
p = root / "app/src/main/cpp/CMakeLists.txt"
s = p.read_text()
needle = '"${FLIGHTGEAR_ROOT}/src" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear" "${FGOSG_ROOT}/include"'
replacement = '"${FLIGHTGEAR_ROOT}/src" "${FLIGHTGEAR_ROOT}/src/Include" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear" "${FGOSG_ROOT}/include"'
if replacement not in s:
    if needle not in s:
        raise SystemExit("expected CMake include path not found")
    s = s.replace(needle, replacement, 1)

filters = {
    'list(SORT SIMGEAR_REMAINING_SOURCES)\n': 'list(SORT SIMGEAR_REMAINING_SOURCES)\nlist(FILTER SIMGEAR_REMAINING_SOURCES EXCLUDE REGEX "/(test[^/]*|[^/]*test)\\.(c|cc|cpp|cxx)$")\nlist(FILTER SIMGEAR_REMAINING_SOURCES EXCLUDE REGEX "/DNSClient\\.cxx$")\n',
    'list(SORT SIMGEAR_CORE_SOURCES)\n': 'list(SORT SIMGEAR_CORE_SOURCES)\nlist(FILTER SIMGEAR_CORE_SOURCES EXCLUDE REGEX "/(test[^/]*|[^/]*test)\\.(c|cc|cpp|cxx)$")\nlist(FILTER SIMGEAR_CORE_SOURCES EXCLUDE REGEX "/DNSClient\\.cxx$")\n',
    'list(SORT SIMGEAR_SCENE_SOURCES)\n': 'list(SORT SIMGEAR_SCENE_SOURCES)\nlist(FILTER SIMGEAR_SCENE_SOURCES EXCLUDE REGEX "/(test[^/]*|[^/]*test)\\.(c|cc|cpp|cxx)$")\nlist(FILTER SIMGEAR_SCENE_SOURCES EXCLUDE REGEX "/DNSClient\\.cxx$")\n',
}
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

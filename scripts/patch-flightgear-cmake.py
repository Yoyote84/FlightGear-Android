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

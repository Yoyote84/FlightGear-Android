from pathlib import Path

p = Path(__file__).resolve().parents[1] / "app/src/main/cpp/CMakeLists.txt"
s = p.read_text()
needle = '"${FLIGHTGEAR_ROOT}/src" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear" "${FGOSG_ROOT}/include"'
replacement = '"${FLIGHTGEAR_ROOT}/src" "${FLIGHTGEAR_ROOT}/src/Include" "${SIMGEAR_ROOT}" "${SIMGEAR_ROOT}/simgear" "${FGOSG_ROOT}/include"'
if replacement not in s:
    s = s.replace(needle, replacement)
p.write_text(s)

#!/usr/bin/env bash
set -euo pipefail

LIB_DIR="${1:?usage: test-16kb-page-size.sh <directory-containing-so-files>}"

if [[ ! -d "$LIB_DIR" ]]; then
  echo "Native library directory not found: $LIB_DIR" >&2
  exit 1
fi

python3 - "$LIB_DIR" <<'PY'
from pathlib import Path
import struct
import sys

directory = Path(sys.argv[1])
libraries = sorted(directory.glob("*.so"))
if not libraries:
    raise SystemExit(f"No shared libraries found in {directory}")

PAGE_SIZE = 16 * 1024
failed = []

for library in libraries:
    data = library.read_bytes()
    if len(data) < 64 or data[:4] != b"\x7fELF":
        failed.append((library.name, "not a valid ELF64 file"))
        continue
    if data[4] != 2 or data[5] != 1:
        failed.append((library.name, "expected a 64-bit little-endian ELF file"))
        continue

    phoff = struct.unpack_from("<Q", data, 32)[0]
    phentsize = struct.unpack_from("<H", data, 54)[0]
    phnum = struct.unpack_from("<H", data, 56)[0]
    if phentsize < 56 or phoff + phentsize * phnum > len(data):
        failed.append((library.name, "invalid ELF program-header table"))
        continue

    loads = []
    for index in range(phnum):
        offset = phoff + index * phentsize
        p_type = struct.unpack_from("<I", data, offset)[0]
        if p_type != 1:  # PT_LOAD
            continue
        p_offset = struct.unpack_from("<Q", data, offset + 8)[0]
        p_vaddr = struct.unpack_from("<Q", data, offset + 16)[0]
        p_align = struct.unpack_from("<Q", data, offset + 48)[0]
        loads.append((p_align, p_offset, p_vaddr))

    if not loads:
        failed.append((library.name, "no PT_LOAD segments"))
        continue

    for p_align, p_offset, p_vaddr in loads:
        if p_align < PAGE_SIZE or (p_offset % PAGE_SIZE) != (p_vaddr % PAGE_SIZE):
            failed.append((
                library.name,
                f"PT_LOAD not 16 KB aligned (align=0x{p_align:x}, "
                f"offset=0x{p_offset:x}, vaddr=0x{p_vaddr:x})",
            ))
            break
    else:
        print(f"16 KB ELF alignment verified: {library.name}")

if failed:
    for name, reason in failed:
        print(f"FAIL: {name}: {reason}", file=sys.stderr)
    raise SystemExit(1)
PY

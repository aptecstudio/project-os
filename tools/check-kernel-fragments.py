#!/usr/bin/env python3
"""Checks kernel configuration fragments against the Kconfig files of a Linux source tree.

Usage:
  tools/check-kernel-fragments.py <linux-source> <fragment.cfg> [...]

For each CONFIG_X=value line it checks that:
  - the symbol X exists in the Kconfig files of the given kernel version;
  - the value is allowed by the type: "m" only for tristate symbols, "y"/"n" for bool
    and tristate.
It does not check dependencies ("depends on"): the kernel build does that, reporting
the options that are required but not enabled.

A source tree with only the Kconfig files is enough, for example:
  git clone --depth=1 --filter=blob:none --no-checkout -b v6.18 \\
      https://github.com/torvalds/linux linux
  git -C linux sparse-checkout set --no-cone '/**/Kconfig*' '/Kconfig'
  git -C linux checkout v6.18
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

SYMBOL = re.compile(r"^\s*(?:menu)?config\s+([A-Za-z0-9_]+)\s*$")
TYPE = re.compile(r"^\s*(bool|tristate|def_bool|def_tristate|string|int|hex)\b")
ASSIGN = re.compile(r"^CONFIG_([A-Za-z0-9_]+)=(.*)$")
UNSET = re.compile(r"^#\s*CONFIG_([A-Za-z0-9_]+) is not set")


def load_kconfig(root: Path) -> dict[str, set[str]]:
    """Returns symbol -> set of the types it is declared with."""
    types: dict[str, set[str]] = {}
    for path in root.rglob("Kconfig*"):
        if not path.is_file():
            continue
        current = None
        for line in path.read_text(errors="replace").splitlines():
            m = SYMBOL.match(line)
            if m:
                current = m.group(1)
                types.setdefault(current, set())
                continue
            if current:
                t = TYPE.match(line)
                if t:
                    kind = t.group(1).replace("def_", "")
                    types[current].add(kind)
                    current = None
                elif line and not line[0].isspace():
                    current = None
    return types


def check(fragment: Path, types: dict[str, set[str]]) -> list[str]:
    errors = []
    for n, raw in enumerate(fragment.read_text().splitlines(), 1):
        line = raw.strip()
        m = ASSIGN.match(line) or UNSET.match(line)
        if not m:
            continue
        sym = m.group(1)
        value = m.group(2) if m.re is ASSIGN else "n"
        where = f"{fragment}:{n}: CONFIG_{sym}"
        if sym not in types:
            errors.append(f"{where}: symbol does not exist in this kernel version")
            continue
        kinds = types[sym]
        if value == "m" and "tristate" not in kinds:
            errors.append(f"{where}=m: the symbol is {'/'.join(sorted(kinds)) or '?'}, "
                          "it cannot be a module")
        elif value in ("y", "n") and kinds and not kinds & {"bool", "tristate"}:
            errors.append(f"{where}={value}: the symbol is {'/'.join(sorted(kinds))}")
    return errors


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    types = load_kconfig(Path(sys.argv[1]))
    errors = []
    count = 0
    for name in sys.argv[2:]:
        frag = Path(name)
        count += sum(1 for l in frag.read_text().splitlines() if l.startswith("CONFIG_"))
        errors += check(frag, types)
    for e in errors:
        print(e)
    print(f"{count} options checked, {len(errors)} errors")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())

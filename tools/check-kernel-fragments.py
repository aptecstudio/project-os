#!/usr/bin/env python3
r"""Check kernel configuration fragments against the Kconfig files of a Linux tree.

Usage:
  tools/check-kernel-fragments.py <linux-source> <fragment.cfg> [...]

For each CONFIG_X=value line it checks that:
  - the symbol X exists in the Kconfig files of the given kernel version;
  - the value is allowed by the type: "m" only for tristate symbols, "y"/"n" for bool
    and tristate.
It does not check dependencies ("depends on"): the kernel recipe does that at build
time (do_project_os_configcheck, D-041), comparing the fragments with the final
configuration.

A source tree with only the Kconfig files is enough, for example:
  git clone --depth=1 --filter=blob:none --no-checkout -b v6.18 \
      https://github.com/torvalds/linux linux
  git -C linux sparse-checkout set --no-cone '/**/Kconfig*' '/Kconfig'
  git -C linux checkout v6.18
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

SYMBOL_PATTERN = re.compile(r"^\s*(?:menu)?config\s+([A-Za-z0-9_]+)\s*$")
TYPE_PATTERN = re.compile(r"^\s*(bool|tristate|def_bool|def_tristate|string|int|hex)\b")
ASSIGNMENT_PATTERN = re.compile(r"^CONFIG_([A-Za-z0-9_]+)=(.*)$")
UNSET_PATTERN = re.compile(r"^#\s*CONFIG_([A-Za-z0-9_]+) is not set")


def load_kconfig(source_dir: Path) -> dict[str, set[str]]:
    """Return a map from each Kconfig symbol to the set of types it is declared with."""
    symbol_types: dict[str, set[str]] = {}
    for path in source_dir.rglob("Kconfig*"):
        if not path.is_file():
            continue
        current_symbol = None
        for line in path.read_text(errors="replace").splitlines():
            symbol_match = SYMBOL_PATTERN.match(line)
            if symbol_match:
                current_symbol = symbol_match.group(1)
                symbol_types.setdefault(current_symbol, set())
                continue
            if current_symbol:
                type_match = TYPE_PATTERN.match(line)
                if type_match:
                    kind = type_match.group(1).replace("def_", "")
                    symbol_types[current_symbol].add(kind)
                    current_symbol = None
                elif line and not line[0].isspace():
                    # A new top-level entry: the symbol had no type line
                    current_symbol = None
    return symbol_types


def check_fragment(fragment: Path, symbol_types: dict[str, set[str]]) -> list[str]:
    """Return the problems found in one fragment, one message per problem."""
    errors = []
    lines = fragment.read_text().splitlines()
    for line_number, raw_line in enumerate(lines, 1):
        line = raw_line.strip()
        match = ASSIGNMENT_PATTERN.match(line) or UNSET_PATTERN.match(line)
        if not match:
            continue
        symbol = match.group(1)
        value = match.group(2) if match.re is ASSIGNMENT_PATTERN else "n"
        location = f"{fragment}:{line_number}: CONFIG_{symbol}"

        if symbol not in symbol_types:
            errors.append(f"{location}: symbol does not exist in this kernel version")
            continue
        kinds = symbol_types[symbol]
        kinds_text = "/".join(sorted(kinds)) or "?"
        if value == "m" and "tristate" not in kinds:
            errors.append(
                f"{location}=m: the symbol is {kinds_text}, it cannot be a module"
            )
        elif value in ("y", "n") and kinds and not kinds & {"bool", "tristate"}:
            errors.append(f"{location}={value}: the symbol is {kinds_text}")
    return errors


def main() -> int:
    """Check the fragments given on the command line; return the exit status."""
    if len(sys.argv) < 3:
        print(__doc__)
        return 2

    symbol_types = load_kconfig(Path(sys.argv[1]))
    errors = []
    option_count = 0
    for name in sys.argv[2:]:
        fragment = Path(name)
        lines = fragment.read_text().splitlines()
        option_count += sum(1 for line in lines if line.startswith("CONFIG_"))
        errors += check_fragment(fragment, symbol_types)

    for error in errors:
        print(error)
    print(f"{option_count} options checked, {len(errors)} errors")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Verifica i frammenti di configurazione del kernel contro i Kconfig di un sorgente Linux.

Uso:
  tools/check-kernel-fragments.py <sorgenti-linux> <frammento.cfg> [...]

Per ogni riga CONFIG_X=valore controlla che:
  - il simbolo X esista nei Kconfig della versione del kernel indicata;
  - il valore sia ammesso dal tipo: "m" solo per i simboli tristate, "y"/"n" per bool
    e tristate.
Non verifica le dipendenze ("depends on"): quelle le controlla la build del kernel,
che segnala le opzioni richieste e non attivate.

Basta un sorgente con i soli file Kconfig, per esempio:
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
    """Restituisce simbolo -> insieme dei tipi con cui è dichiarato."""
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
            errors.append(f"{where}: simbolo inesistente in questa versione del kernel")
            continue
        kinds = types[sym]
        if value == "m" and "tristate" not in kinds:
            errors.append(f"{where}=m: il simbolo è {'/'.join(sorted(kinds)) or '?'}, "
                          "non può essere un modulo")
        elif value in ("y", "n") and kinds and not kinds & {"bool", "tristate"}:
            errors.append(f"{where}={value}: il simbolo è {'/'.join(sorted(kinds))}")
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
    print(f"{count} opzioni controllate, {len(errors)} errori")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())

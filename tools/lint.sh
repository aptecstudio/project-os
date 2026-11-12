#!/bin/sh
# Checks the code style of project-os (AGENTS.md §7) with the standard tool of each
# language. A change is complete only when this script passes.
#
# Usage: tools/lint.sh
#
# Tools (installed by tools/setup-host.sh, through pipx): ShellCheck (shellcheck-py),
# ruff, oelint-adv. Rust (cargo fmt, clippy) and JavaScript (ESLint, Prettier) are
# checked as soon as the repository has a Cargo.toml or a package.json.
set -eu

cd "$(dirname "$0")/.."

failed=0

# Runs one check, prints its name and remembers whether it failed
run_check() {
    name=$1
    shift
    printf '==> %s\n' "$name"
    if ! "$@"; then
        failed=1
    fi
}

require_tool() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "$1 not found: install it with tools/setup-host.sh" >&2
        exit 1
    fi
}

# Files tracked by git, so build output and downloaded sources are never checked
tracked_files() {
    git ls-files -- "$@"
}

# Shell scripts: the *.sh files and any tracked file whose first line runs sh
shell_scripts() {
    git ls-files | while read -r file; do
        case "$file" in
            *.sh) echo "$file" ;;
            *)
                if [ -f "$file" ] && head -n 1 "$file" | grep -q '^#!/bin/sh'; then
                    echo "$file"
                fi
                ;;
        esac
    done
}

require_tool shellcheck
require_tool ruff
require_tool oelint-adv

# shellcheck disable=SC2046  # file lists are split on purpose, names have no spaces
run_check "Shell (ShellCheck)" shellcheck $(shell_scripts)

# shellcheck disable=SC2046
run_check "Python (ruff check)" ruff check $(tracked_files '*.py')
# shellcheck disable=SC2046
run_check "Python (ruff format)" ruff format --check $(tracked_files '*.py')

# BitBake recipes (OpenEmbedded style guide). Rules left out, and why:
#   suggestedvar.SECTION, .BUGTRACKER, .CVE_PRODUCT, var.bbclassextend
#       meant for recipes of software published elsewhere; ours are system
#       components built only for the target
#   var.licenseremotefile
#       our own recipes have no upstream license file: their license is the
#       GPL-3.0 of the repository (LICENSE), referenced through COMMON_LICENSE_DIR
# shellcheck disable=SC2046
run_check "BitBake (oelint-adv)" oelint-adv --quiet \
    --constantmods=+tools/oelint-constants.json \
    --suppress oelint.var.suggestedvar.SECTION \
    --suppress oelint.var.suggestedvar.BUGTRACKER \
    --suppress oelint.var.suggestedvar.CVE_PRODUCT \
    --suppress oelint.var.bbclassextend \
    --suppress oelint.var.licenseremotefile \
    $(tracked_files 'layers/*.bb' 'layers/*.bbappend' 'layers/*.bbclass')

if [ -n "$(tracked_files 'Cargo.toml' '*/Cargo.toml')" ]; then
    require_tool cargo
    run_check "Rust (cargo fmt)" cargo fmt --all --check
    run_check "Rust (cargo clippy)" cargo clippy --all-targets -- -D warnings
fi

if [ -n "$(tracked_files 'package.json' '*/package.json')" ]; then
    require_tool npx
    run_check "JavaScript (ESLint)" npx --no-install eslint .
    run_check "JavaScript (Prettier)" npx --no-install prettier --check .
fi

if [ "$failed" -ne 0 ]; then
    echo "Style checks failed (AGENTS.md §7)." >&2
    exit 1
fi
echo "All style checks passed."

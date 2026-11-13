#!/bin/sh
# Builds project-os for desktop amd64, in development configuration.
#
# Usage: tools/build.sh [--low-resources] [image|update|shell]
#   image            (default) disk image, to be tested with tools/run-qemu.sh
#   update           signed RAUC update bundle (project-os-bundle)
#   shell            terminal with the bitbake environment, for manual commands
#   --low-resources  for PCs with little RAM or disk space, for example a laptop
#                    (kas/low-resources.yml): slower build, but it fits in about 8 GB
#                    of RAM and 45 GB of disk. Enough for Phase 1, not for WebKit.
#   --help           show this help
#
# Default mode: full performance, for the recommended build host (docs/development.md:
# at least 16 GB of RAM and 250 GB of disk). bitbake uses all cores and keeps the work
# files of the recipes, so later builds are faster.
# If the machine looks too small, the script warns and suggests --low-resources.
#
# Equivalent kas commands, without this script:
#   kas build kas/desktop-amd64.yml:kas/dev.yml
#   kas build kas/desktop-amd64.yml:kas/dev.yml:kas/low-resources.yml
#
# PROJECT_OS_LOW_RESOURCES=1 is the same as --low-resources (=0 or unset: default).
# The development configuration (kas/dev.yml) allows passwordless root login: never use
# it for images to be distributed (AGENTS.md §5.6).
set -eu

cd "$(dirname "$0")/.."

usage() {
    sed -n '4,11s/^# \{0,1\}//p' "$0"
}

low="${PROJECT_OS_LOW_RESOURCES:-0}"
target=image
for arg in "$@"; do
    case "$arg" in
        --low-resources) low=1 ;;
        --help|-h) usage; exit 0 ;;
        image|update|shell) target="$arg" ;;
        *)
            echo "Unknown option: $arg" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if ! command -v kas >/dev/null 2>&1; then
    echo "kas not found. Prepare the machine with tools/setup-host.sh" >&2
    echo "(then open a new terminal)." >&2
    exit 1
fi

: "${PROJECT_OS_KEYS:=$HOME/.config/project-os/keys}"
export PROJECT_OS_KEYS
if [ ! -f "$PROJECT_OS_KEYS/ca.cert.pem" ]; then
    echo "Keys not found in $PROJECT_OS_KEYS." >&2
    echo "Create them with tools/gen-dev-keys.sh (or tools/setup-host.sh)." >&2
    exit 1
fi

CONFIG="kas/desktop-amd64.yml:kas/dev.yml"

# Machine resources: total RAM and free space where the build goes
mem_gb=$(awk '/^MemTotal:/ { printf "%d", $2 / 1048576 + 0.5 }' /proc/meminfo)
free_gb=$(df -Pk . | awk 'NR == 2 { printf "%d", $4 / 1048576 }')
cores=$(nproc)

# Space is required only by the first build: later ones reuse build/ and sources/
first_build=0
[ -d build/tmp ] || first_build=1

warn=""
if [ "$low" = 1 ]; then
    CONFIG="$CONFIG:kas/low-resources.yml"
    echo "Low-resources mode (kas/low-resources.yml): slower build, less RAM and disk."
    if [ "$first_build" = 1 ] && [ "$free_gb" -lt 45 ]; then
        warn="Free space: $free_gb GB; even with --low-resources about 45 are needed."
    fi
else
    echo "Default mode: full performance ($cores cores, $mem_gb GB of RAM)."
    # 15 rather than 16: a 16 GB PC shows a bit less to the system
    if [ "$mem_gb" -lt 15 ]; then
        warn="RAM: $mem_gb GB, below the recommended 16 GB: the build may run out of memory."
    fi
    if [ "$first_build" = 1 ] && [ "$free_gb" -lt 100 ]; then
        warn="${warn:+$warn
}Free space: $free_gb GB; the first build takes about 100 (250 from Phase 2)."
    fi
    [ -n "$warn" ] && warn="$warn
On a PC with few resources use: tools/build.sh --low-resources"
fi

if [ -n "$warn" ]; then
    echo >&2
    echo "Warning:" >&2
    echo "$warn" | sed 's/^/  /' >&2
    echo >&2
    # From a terminal, ask for confirmation; from scripts (CI, automation), just warn
    if [ -t 0 ]; then
        printf "Continue anyway? [y/N] " >&2
        read -r answer
        case "$answer" in
            y|Y|yes|Yes|YES) ;;
            *) echo "Build cancelled." >&2; exit 1 ;;
        esac
    fi
fi

case "$target" in
    image)  exec kas build "$CONFIG" ;;
    update) exec kas build --target project-os-bundle "$CONFIG" ;;
    shell)  exec kas shell "$CONFIG" ;;
esac

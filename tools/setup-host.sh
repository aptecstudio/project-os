#!/bin/sh
# Prepares a machine to build and test project-os, with one command (D-028, D-057).
#
# Usage: tools/setup-host.sh [--yes] [--help]
#   --yes    answer "yes" to every question, for unattended setups (on Ubuntu this
#            includes allowing user namespaces for bitbake)
#   --help   show this help
#
# Tested systems: Ubuntu 24.04 and 26.04 LTS, Debian 13. Run it as a normal user: it
# uses sudo by itself for the system packages.
#
# Installs:
#   - the programs required by Yocto 6.0 "Wrynose" (apt);
#   - QEMU and the OVMF UEFI firmware, to test images in the emulator (apt);
#   - what branding/tools/render.py needs: rsvg-convert, Pillow, NumPy, Inter (apt);
#   - kas (build tool, D-024) and the code style tools of tools/lint.sh (ShellCheck,
#     ruff, oelint-adv), through pipx, in ~/.local/bin;
#   - the development keys to sign updates, in ~/.config/project-os/keys (outside the
#     repository, AGENTS.md §4).
# Then it checks that every tool works and that the repository sits on a file system
# where Yocto can build, and prints what is still missing.
# It can be run again at any time: what is already there is kept, pipx tools are
# upgraded.
set -eu

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
assume_yes=0

usage() {
    sed -n '4,7s/^# \{0,1\}//p' "$0"
}

for arg in "$@"; do
    case "$arg" in
        --yes|-y) assume_yes=1 ;;
        --help|-h) usage; exit 0 ;;
        *)
            echo "Unknown option: $arg" >&2
            usage >&2
            exit 2
            ;;
    esac
done

say() {
    printf '\n==> %s\n' "$*"
}

ask() {
    if [ "$assume_yes" -eq 1 ]; then
        printf '%s [y/N] yes (--yes)\n' "$1"
        return 0
    fi
    printf '%s [y/N] ' "$1"
    read -r answer
    case "$answer" in
        y|Y|yes|Yes|YES) return 0 ;;
        *) return 1 ;;
    esac
}

if [ "$(id -u)" -eq 0 ]; then
    echo "Run the script as a normal user (it uses sudo by itself when needed)." >&2
    echo "Bitbake refuses to run as root." >&2
    exit 1
fi

# shellcheck source=/dev/null
. /etc/os-release
case "${ID:-}:${VERSION_ID:-}" in
    ubuntu:24.04|ubuntu:26.04|debian:13) ;;
    *)
        echo "Warning: ${PRETTY_NAME:-this system} is not among the tested systems" \
            "(Ubuntu 24.04/26.04, Debian 13)."
        ask "Continue anyway?" || exit 1
        ;;
esac

if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is not installed. As root (su -), run:" >&2
    echo "  apt-get install sudo && usermod -aG sudo $USER" >&2
    echo "then log out, log back in and run this script again." >&2
    exit 1
fi

# Yocto needs a POSIX file system for build/ and sources/: owners, permissions, symbolic
# and hard links, case-sensitive names. NTFS, FAT and exFAT disks (often shared with
# Windows) and network shares do not offer them, and the build fails in odd ways.
# findmnt names the real type (ntfs-3g shows as "fuseblk"); stat only says "fuse"
repo_fs=$(findmnt -n -o FSTYPE -T "$repo_dir" 2>/dev/null ||
    stat -f -c %T "$repo_dir" 2>/dev/null || echo unknown)
fs_ok=1
case "$repo_fs" in
    fuse|fuseblk|ntfs|ntfs3|msdos|vfat|exfat|nfs|nfs4|cifs|smb2|smbfs|9p|v9fs) fs_ok=0 ;;
esac
if [ "$fs_ok" -eq 0 ]; then
    say "The repository is on an unsuitable file system ($repo_fs)"
    echo "  $repo_dir"
    echo "The setup goes on, but the build will not work from here. Afterwards, clone"
    echo "the project into a Linux file system (ext4, btrfs, xfs), for example:"
    echo "  git clone https://github.com/aptecstudio/project-os.git ~/project-os"
fi

say "sudo is needed to install the system packages"
sudo -v

say "Installing the system packages (apt)"
# Yocto 6.0 host requirements for Debian and Ubuntu (Yocto Project Reference Manual,
# "Required Packages for the Build Host"); lz4 is the current name of liblz4-tool.
yocto_packages="build-essential chrpath cpio debianutils diffstat file gawk gcc git
    iputils-ping libacl1 locales lz4 python3 python3-git python3-jinja2 python3-pexpect
    python3-pip python3-subunit socat texinfo unzip wget xz-utils zstd"
# pipx and venv: kas and the style tools; openssl: development keys; ca-certificates
# and curl: HTTPS downloads of the sources
tool_packages="pipx python3-venv openssl ca-certificates curl"
emulator_packages="qemu-system-x86 qemu-utils ovmf"
# branding/tools/render.py: rsvg-convert, Pillow, NumPy and the Inter font (preview)
branding_packages="librsvg2-bin python3-pil python3-numpy fonts-inter"
sudo apt-get update
# shellcheck disable=SC2086 # the package lists are meant to be split into words
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
    $yocto_packages $tool_packages $emulator_packages $branding_packages

say "Enabling the en_US.UTF-8 locale (bitbake requires it)"
if locale -a | grep -qi '^en_US\.utf-\?8$'; then
    echo "Already enabled."
else
    sudo sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
    sudo locale-gen
fi

say "Installing kas and the code style tools (pipx, AGENTS.md §7)"
pipx ensurepath >/dev/null
# Make the tools usable by the checks below, before the next login updates PATH
PATH="$HOME/.local/bin:$PATH"
export PATH
# ShellCheck comes from its official Python package (shellcheck-py): no root needed
for tool in kas ruff shellcheck-py oelint-adv; do
    if pipx list --short 2>/dev/null | grep -q "^$tool "; then
        pipx upgrade "$tool"
    else
        pipx install "$tool"
    fi
done

# Ubuntu 24.04 and later restrict unprivileged user namespaces with AppArmor; bitbake
# uses them to isolate compilation steps from the network.
userns_restriction=/proc/sys/kernel/apparmor_restrict_unprivileged_userns
if [ -r "$userns_restriction" ] && [ "$(cat "$userns_restriction")" = "1" ]; then
    say "User namespaces restricted by AppArmor"
    echo "Bitbake needs user namespaces to isolate compilation from the network."
    echo "I can allow them permanently on this machine"
    echo "(/etc/sysctl.d/60-project-os-bitbake.conf). It slightly reduces app isolation"
    echo "on the build host: fine on a dedicated VM, less so on an everyday PC."
    if ask "Allow user namespaces?"; then
        echo "kernel.apparmor_restrict_unprivileged_userns = 0" |
            sudo tee /etc/sysctl.d/60-project-os-bitbake.conf >/dev/null
        sudo sysctl --system >/dev/null
    else
        echo "Not changed: the build may stop with namespace errors."
    fi
fi

# A repository owned by another user (for example on a disk mounted by root) makes git
# refuse to work in it ("dubious ownership"); kas and bitbake call git there.
if ! git -C "$repo_dir" rev-parse --git-dir >/dev/null 2>&1; then
    say "git does not trust this repository (owned by another user)"
    echo "I can add it to the trusted directories of your git configuration"
    echo "(git config --global --add safe.directory $repo_dir)."
    if ask "Trust this repository?"; then
        git config --global --add safe.directory "$repo_dir"
    fi
fi

keys_dir="$HOME/.config/project-os/keys"
say "Development keys for updates"
if [ -f "$keys_dir/ca.cert.pem" ]; then
    echo "Already present in $keys_dir"
else
    "$repo_dir/tools/gen-dev-keys.sh" "$keys_dir"
fi

relogin=0
if [ -e /dev/kvm ]; then
    if [ ! -w /dev/kvm ]; then
        say "KVM acceleration"
        echo "Adding $USER to the kvm group (takes effect from the next login)."
        sudo usermod -aG kvm "$USER"
        relogin=1
    fi
else
    say "KVM acceleration not available"
    echo "QEMU will work, but much slower. In a VM, enable nested virtualization in the"
    echo "settings of the virtualization program; on a PC, enable virtualization"
    echo "(VT-x / AMD-V) in the firmware settings."
fi

say "Checking the installation"
missing=""

# Runs a check quietly: check <label> <command...>
check() {
    label=$1
    shift
    if "$@" >/dev/null 2>&1; then
        printf '  ok       %s\n' "$label"
    else
        printf '  MISSING  %s\n' "$label"
        missing="$missing
  - $label"
    fi
}

for command_name in gcc make gawk git chrpath diffstat socat makeinfo cpio lz4 zstd \
    python3 openssl kas ruff shellcheck oelint-adv qemu-system-x86_64 rsvg-convert; do
    check "$command_name" command -v "$command_name"
done
check "Python modules for bitbake and branding (git, jinja2, pexpect, PIL, numpy)" \
    python3 -c "import git, jinja2, pexpect, subunit, PIL, numpy"
check "en_US.UTF-8 locale" sh -c "locale -a | grep -qi '^en_US\.utf-\?8$'"
check "OVMF UEFI firmware" \
    sh -c "ls /usr/share/OVMF/OVMF_CODE*.fd || ls /usr/share/edk2/ovmf/OVMF_CODE.fd"
check "Inter font" test -f /usr/share/fonts/opentype/inter/Inter-Regular.otf
check "development keys" test -f "$keys_dir/ca.cert.pem"
check "git works in the repository" git -C "$repo_dir" rev-parse --git-dir

# Resources, compared with the two build modes of tools/build.sh (D-036)
mem_gb=$(awk '/^MemTotal:/ { printf "%d", $2 / 1048576 + 0.5 }' /proc/meminfo)
free_gb=$(df -Pk "$repo_dir" | awk 'NR == 2 { printf "%d", $4 / 1048576 }')
cores=$(nproc)
echo
echo "  This machine: $cores cores, $mem_gb GB of RAM, $free_gb GB free for the build."
build_command="tools/build.sh"
if [ "$mem_gb" -lt 15 ] || [ "$free_gb" -lt 100 ]; then
    build_command="tools/build.sh --low-resources"
    echo "  Below the recommended 16 GB of RAM or 100 GB free: use $build_command"
fi

if [ -n "$missing" ]; then
    say "Setup incomplete. Missing:$missing"
    echo "Copy the messages above when asking for help (docs/development.md, section 6)."
    exit 1
fi

say "Done. Next steps:"
if [ "$fs_ok" -eq 0 ]; then
    echo "  0. clone the project into a Linux file system (see the warning above) and"
    echo "     run the next commands from there"
fi
if [ "$relogin" -eq 1 ]; then
    echo "  1. log out and back in, for the kvm group (and kas in a new terminal)"
else
    echo "  1. open a new terminal, so that kas is in PATH"
fi
echo "  2. $build_command    first build: several hours"
echo "  3. tools/run-qemu.sh      boot the image in the emulator"

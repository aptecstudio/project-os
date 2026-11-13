#!/bin/sh
# Prepares the project-os build host (DA-11).
#
# Usage: tools/setup-host.sh
# Recommended system: Ubuntu Server 24.04 or 26.04 LTS (Debian 13 works too), in a VM
# or on a dedicated PC. Requirements: at least 16 GB of RAM, 250 GB of disk, many cores.
#
# Installs:
#   - the programs required by Yocto 6.0 "Wrynose";
#   - kas (build tool, D-024), through pipx;
#   - QEMU and the OVMF UEFI firmware, to test images in the emulator;
#   - the code style tools of tools/lint.sh (ShellCheck, ruff, oelint-adv), through pipx;
#   - the development keys to sign updates (outside the repository).
# Asks for confirmation before changing system settings.
set -eu

say() { printf '\n==> %s\n' "$*"; }
ask() {
    printf '%s [y/N] ' "$1"
    read -r answer
    case "$answer" in y|Y|yes|Yes|YES) return 0 ;; *) return 1 ;; esac
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
        echo "Warning: $PRETTY_NAME is not among the tested systems" \
            "(Ubuntu 24.04/26.04, Debian 13)."
        ask "Continue anyway?" || exit 1
        ;;
esac

say "Installing the programs required by Yocto, QEMU and OVMF"
sudo apt-get update
sudo apt-get install -y \
    build-essential chrpath cpio debianutils diffstat file gawk gcc git \
    iputils-ping libacl1 locales python3 python3-git python3-jinja2 \
    python3-pexpect python3-pip python3-subunit socat texinfo unzip wget xz-utils \
    zstd lz4 \
    pipx openssl \
    qemu-system-x86 qemu-utils ovmf

say "Enabling the en_US.UTF-8 locale (bitbake requires it)"
if ! locale -a | grep -qi '^en_US\.utf-\?8$'; then
    sudo sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
    sudo locale-gen
fi

say "Installing kas and the code style tools (AGENTS.md §7)"
pipx ensurepath >/dev/null
# ShellCheck comes from its official Python package (shellcheck-py): no root needed
for tool in kas ruff shellcheck-py oelint-adv; do
    if pipx list 2>/dev/null | grep -q "package $tool "; then
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
    echo "(/etc/sysctl.d/60-project-os-bitbake.conf). It slightly reduces app isolation on"
    echo "the build host: fine on a dedicated VM, less so on an everyday PC."
    if ask "Allow user namespaces?"; then
        echo "kernel.apparmor_restrict_unprivileged_userns = 0" |
            sudo tee /etc/sysctl.d/60-project-os-bitbake.conf >/dev/null
        sudo sysctl --system >/dev/null
    else
        echo "Not changed: the build may stop with namespace errors."
    fi
fi

KEYS="$HOME/.config/project-os/keys"
say "Development keys for updates"
if [ -f "$KEYS/ca.cert.pem" ]; then
    echo "Already present in $KEYS"
else
    "$(dirname "$0")/gen-dev-keys.sh" "$KEYS"
fi

if [ -e /dev/kvm ]; then
    if [ ! -w /dev/kvm ]; then
        say "KVM acceleration"
        echo "Adding $USER to the kvm group (takes effect from the next login)."
        sudo usermod -aG kvm "$USER"
    fi
else
    say "KVM acceleration not available"
    echo "QEMU will work, but much slower. In a VM, enable nested virtualization in the"
    echo "settings of the virtualization program."
fi

say "Done. Next steps:"
echo "  1. log out and back in (or open a new terminal), for kas and the kvm group"
echo "  2. tools/build.sh            first build: several hours"
echo "     (PC with less than 16 GB of RAM: tools/build.sh --low-resources)"
echo "  3. tools/run-qemu.sh         boot the image in the emulator"

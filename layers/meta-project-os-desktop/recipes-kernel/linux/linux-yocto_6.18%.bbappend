# linux-yocto 6.18 LTS kernel for the desktop amd64 machine (D-014).
# The OE-Core recipe declares only the QEMU machines as compatible: we add ours and
# start from the reference configuration for 64-bit PCs in yocto-kernel-cache.
COMPATIBLE_MACHINE:project-os-amd64 = "project-os-amd64"
KMACHINE:project-os-amd64 = "common-pc-64"
KBRANCH:project-os-amd64 = "v6.18/standard/base"

# Modern hardware (R-04, D-025). Each fragment is checked against the kernel Kconfig
# files with tools/check-kernel-fragments.py.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append:project-os-amd64 = " \
    file://storage.cfg \
    file://graphics.cfg \
    file://audio.cfg \
    file://bluetooth.cfg \
    file://wifi.cfg \
    file://ethernet.cfg \
    file://input-platform.cfg \
    file://ab-crypt.cfg \
"

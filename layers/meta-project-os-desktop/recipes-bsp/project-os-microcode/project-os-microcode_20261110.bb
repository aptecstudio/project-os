SUMMARY = "project-os desktop — early CPU microcode for Intel and AMD"
DESCRIPTION = "Builds microcode.cpio, the uncompressed archive that GRUB loads before \
the initramfs: the kernel finds kernel/x86/microcode/GenuineIntel.bin and \
AuthenticAMD.bin there and updates the processor microcode at the very start of the \
boot, before anything else runs (R-04, step 3b, D-043)."
HOMEPAGE = "https://github.com/intel/Intel-Linux-Processor-Microcode-Data-Files"
LICENSE = "Intel-Microcode-License & Firmware-amd-ucode"
LIC_FILES_CHKSUM = " \
    file://intel/license;md5=d8405101ec6e90c1d84b082b0c40c721 \
    file://linux-firmware-${LINUX_FIRMWARE_PV}/LICENSE.amd-ucode;md5=450f217aadc787514165e9568652d700 \
"
NO_GENERIC_LICENSE[Intel-Microcode-License] = "intel/license"
NO_GENERIC_LICENSE[Firmware-amd-ucode] = "linux-firmware-${LINUX_FIRMWARE_PV}/LICENSE.amd-ucode"

# Intel: official microcode release, pinned to the commit of its tag (PV is the
# release date). AMD: amd-ucode from the same linux-firmware release that
# OpenEmbedded-Core uses (same file and digest as its linux-firmware recipe); keep
# LINUX_FIRMWARE_PV in sync when OE-Core moves to a newer linux-firmware.
LINUX_FIRMWARE_PV = "20260410"
SRC_URI = " \
    git://github.com/intel/Intel-Linux-Processor-Microcode-Data-Files.git;protocol=https;nobranch=1;name=intel;destsuffix=intel \
    ${KERNELORG_MIRROR}/linux/kernel/firmware/linux-firmware-${LINUX_FIRMWARE_PV}.tar.xz;name=linux-firmware \
"
# Tag microcode-20261110
SRCREV_intel = "d71fe4e2f0f70a49ebbac7f2c7e915f181361974"
SRC_URI[linux-firmware.sha256sum] = "b7812ed6d59f6b09ecceddaa0be842a7e82a79cc0e46ca60478a4ebf02f1e178"

S = "${UNPACKDIR}"
B = "${WORKDIR}/build"

inherit deploy nopackages

INHIBIT_DEFAULT_DEPS = "1"
COMPATIBLE_HOST = "(i.86|x86_64).*-linux"
PACKAGE_ARCH = "${MACHINE_ARCH}"

do_configure[noexec] = "1"

do_compile() {
    rm -rf ${B}/root ${B}/microcode.cpio
    install -d ${B}/root/kernel/x86/microcode
    # Intel: all files of intel-ucode/. intel-ucode-with-caveats/ is left out: Intel
    # documents it as microcode that must not be loaded without extra precautions
    # (Broadwell-EP servers).
    cat ${S}/intel/intel-ucode/* > ${B}/root/kernel/x86/microcode/GenuineIntel.bin
    # AMD: the container files of every processor family
    cat ${S}/linux-firmware-${LINUX_FIRMWARE_PV}/amd-ucode/microcode_amd*.bin \
        > ${B}/root/kernel/x86/microcode/AuthenticAMD.bin
    # Reproducible archive: fixed times and owner, sorted entries. Paths must start
    # with "kernel/", without "./", for the kernel's early cpio parser.
    find ${B}/root -exec touch -h -d @${SOURCE_DATE_EPOCH} {} +
    cd ${B}/root
    find kernel | LC_ALL=C sort | cpio --quiet -o -H newc -R 0:0 --reproducible > ${B}/microcode.cpio
}

do_deploy() {
    install -d ${DEPLOYDIR}/project-os
    install -m 0644 ${B}/microcode.cpio ${DEPLOYDIR}/project-os/microcode.cpio
}
addtask deploy after do_compile before do_build

SUMMARY = "project-os desktop — initial state of the A/B boot slots"
DESCRIPTION = "Generates grubenv, the variable block that GRUB reads to choose the \
slot to boot and that RAUC updates on every installation (D-026). Factory state: \
slot A valid, slot B empty."
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-3.0-only;md5=c79ff39f19dfec6d293b95dea7b07891"

inherit deploy nopackages

INHIBIT_DEFAULT_DEPS = "1"
PACKAGE_ARCH = "${MACHINE_ARCH}"

# Variables read by project-os-grub.cfg and written by RAUC (bootloader=grub)
GRUBENV_VARS = "ORDER=A B;A_OK=1;A_TRY=0;B_OK=0;B_TRY=0"

do_compile() {
    # GRUB format: header, one variable per line, padding with '#' up to exactly
    # 1024 bytes (save_env never changes the file size)
    {
        echo "# GRUB Environment Block"
        echo "${GRUBENV_VARS}" | tr ';' '\n'
    } > grubenv.head
    size=$(wc -c < grubenv.head)
    if [ "$size" -gt 1024 ]; then
        bbfatal "grubenv exceeds 1024 bytes"
    fi
    cp grubenv.head grubenv
    head -c $(expr 1024 - $size) /dev/zero | tr '\0' '#' >> grubenv
}

do_deploy() {
    install -d ${DEPLOYDIR}/project-os
    install -m 0644 ${B}/grubenv ${DEPLOYDIR}/project-os/grubenv
}
addtask deploy after do_compile before do_build

SUMMARY = "project-os desktop — encrypted data partition and EFI partition"
DESCRIPTION = "Creation on first boot (systemd-repart), unlocking (crypttab) and \
mounting on /var of the encrypted data partition; checking and mounting on /efi of the \
EFI partition (D-026, D-038)."
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-3.0-only;md5=c79ff39f19dfec6d293b95dea7b07891"

inherit systemd allarch features_check

SRC_URI = " \
    file://50-data.conf \
    file://crypttab \
    file://var.mount \
    file://10-after-repart.conf \
    file://efi.mount \
"
S = "${UNPACKDIR}"

do_install() {
    install -d ${D}${nonarch_libdir}/repart.d
    install -m 0644 ${UNPACKDIR}/50-data.conf ${D}${nonarch_libdir}/repart.d/

    install -d ${D}${sysconfdir}
    install -m 0644 ${UNPACKDIR}/crypttab ${D}${sysconfdir}/crypttab

    install -d ${D}${systemd_system_unitdir}/systemd-cryptsetup@data.service.d
    install -m 0644 ${UNPACKDIR}/10-after-repart.conf \
        ${D}${systemd_system_unitdir}/systemd-cryptsetup@data.service.d/
    install -m 0644 ${UNPACKDIR}/var.mount ${D}${systemd_system_unitdir}/
    install -m 0644 ${UNPACKDIR}/efi.mount ${D}${systemd_system_unitdir}/

    # Mask OE's 00-create-volatile.conf (same name in /etc, pointing to /dev/null):
    # it links /var/log and /var/tmp into /var/volatile, a tmpfs layout meant for
    # systems without a data partition. Here they are real directories on /var,
    # created by systemd's own tmpfiles rules (D-038).
    install -d ${D}${sysconfdir}/tmpfiles.d
    ln -sf /dev/null ${D}${sysconfdir}/tmpfiles.d/00-create-volatile.conf
}

SYSTEMD_SERVICE:${PN} = "var.mount efi.mount"

FILES:${PN} += "${nonarch_libdir}/repart.d ${systemd_system_unitdir} ${sysconfdir}/tmpfiles.d"
# e2fsprogs-mke2fs: mkfs.ext4, which systemd-repart uses to format the data partition
# dosfstools: fsck.vfat, which systemd-fsck uses to check the EFI partition (efi.mount)
RDEPENDS:${PN} = "systemd cryptsetup e2fsprogs-mke2fs dosfstools"
REQUIRED_DISTRO_FEATURES = "systemd"

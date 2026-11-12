SUMMARY = "project-os desktop — partizione dati cifrata e partizione EFI"
DESCRIPTION = "Creazione al primo avvio (systemd-repart), sblocco (crypttab) e montaggio \
su /var della partizione dati cifrata; montaggio su /efi della partizione EFI (D-026)."
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
}

SYSTEMD_SERVICE:${PN} = "var.mount efi.mount"

FILES:${PN} += "${nonarch_libdir}/repart.d ${systemd_system_unitdir}"
# e2fsprogs-mke2fs: mkfs.ext4, con cui systemd-repart formatta la partizione dati
RDEPENDS:${PN} = "systemd cryptsetup e2fsprogs-mke2fs"
REQUIRED_DISTRO_FEATURES = "systemd"

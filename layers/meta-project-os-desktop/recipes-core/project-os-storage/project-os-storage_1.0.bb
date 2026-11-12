SUMMARY = "project-os desktop — data partition, persistent /etc, EFI partition"
DESCRIPTION = "Data partition: created on first boot (systemd-repart), unlocked \
               (crypttab) and mounted on /var by the initramfs, which also mounts the \
               persistent /etc overlay on it (package project-os-storage-initrd). In \
               the system: partition definition, /etc conflict report after updates, \
               checking and mounting of the EFI partition on /efi (D-026, D-038, \
               D-044)."
HOMEPAGE = "https://github.com/aptecstudio/project-os"
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-3.0-only;md5=c79ff39f19dfec6d293b95dea7b07891"

inherit systemd allarch features_check

SRC_URI = "\
    file://50-data.conf \
    file://efi.mount \
    file://etc-overlay-conflicts \
    file://initrd/crypttab \
    file://initrd/10-after-repart.conf \
    file://initrd/project-os-repart.service \
    file://initrd/sysroot-var.mount \
    file://initrd/project-os-etc-overlay.service \
"
S = "${UNPACKDIR}"

PACKAGES =+ "${PN}-initrd"

do_install() {
    # --- System (${PN}) ---
    # Definition of the data partition: read by the initramfs with --root=/sysroot
    install -d ${D}${nonarch_libdir}/repart.d
    install -m 0644 ${UNPACKDIR}/50-data.conf ${D}${nonarch_libdir}/repart.d/
    # The initramfs owns the data partition: systemd's own systemd-repart.service would
    # only run again on the booted system and change nothing
    install -d ${D}${sysconfdir}/systemd/system
    ln -sf /dev/null ${D}${sysconfdir}/systemd/system/systemd-repart.service
    # The image already has the right ld.so.cache for the libraries of its slot. With a
    # writable /etc, ldconfig.service would write a copy into the persistent overlay,
    # which could go stale after an update and hide the cache of the new system.
    ln -sf /dev/null ${D}${sysconfdir}/systemd/system/ldconfig.service

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/efi.mount ${D}${systemd_system_unitdir}/

    # Run by RAUC after installing an update (post-install handler, rauc-conf)
    install -d ${D}${nonarch_libdir}/project-os
    install -m 0755 ${UNPACKDIR}/etc-overlay-conflicts ${D}${nonarch_libdir}/project-os/

    # Mask OE's 00-create-volatile.conf (same name in /etc, pointing to /dev/null):
    # it links /var/log and /var/tmp into /var/volatile, a tmpfs layout meant for
    # systems without a data partition. Here they are real directories on /var,
    # created by systemd's own tmpfiles rules (D-038).
    install -d ${D}${sysconfdir}/tmpfiles.d
    ln -sf /dev/null ${D}${sysconfdir}/tmpfiles.d/00-create-volatile.conf

    # --- initramfs (${PN}-initrd) ---
    install -m 0644 ${UNPACKDIR}/initrd/crypttab ${D}${sysconfdir}/crypttab
    install -d ${D}${systemd_system_unitdir}/systemd-cryptsetup@data.service.d
    install -m 0644 ${UNPACKDIR}/initrd/10-after-repart.conf \
        ${D}${systemd_system_unitdir}/systemd-cryptsetup@data.service.d/
    for unit in project-os-repart.service sysroot-var.mount project-os-etc-overlay.service; do
        install -m 0644 ${UNPACKDIR}/initrd/$unit ${D}${systemd_system_unitdir}/
    done
    # Enabled in the initramfs (RequiredBy=initrd-fs.target)
    install -d ${D}${systemd_system_unitdir}/initrd-fs.target.requires
    for unit in sysroot-var.mount project-os-etc-overlay.service; do
        ln -sf ../$unit ${D}${systemd_system_unitdir}/initrd-fs.target.requires/$unit
    done
}

SYSTEMD_SERVICE:${PN} = "efi.mount"

FILES:${PN}-initrd += "\
    ${sysconfdir}/crypttab \
    ${systemd_system_unitdir}/systemd-cryptsetup@data.service.d \
    ${systemd_system_unitdir}/project-os-repart.service \
    ${systemd_system_unitdir}/sysroot-var.mount \
    ${systemd_system_unitdir}/project-os-etc-overlay.service \
    ${systemd_system_unitdir}/initrd-fs.target.requires \
"
FILES:${PN} += "\
    ${nonarch_libdir}/repart.d \
    ${nonarch_libdir}/project-os \
    ${systemd_system_unitdir} \
    ${sysconfdir}/tmpfiles.d \
    ${sysconfdir}/systemd/system \
"

# System:
#   cryptsetup   key management of the data partition (password and recovery key,
#                step 4d)
#   dosfstools   fsck.vfat, which systemd-fsck uses to check the EFI partition
#   busybox      sh, find, cmp, mount for etc-overlay-conflicts
RDEPENDS:${PN} = "busybox cryptsetup dosfstools systemd"
# initramfs:
#   e2fsprogs-mke2fs   mkfs.ext4, which systemd-repart uses to format the data partition
#   e2fsprogs-e2fsck   fsck of the data partition before mounting it
#   busybox            mkdir for the overlay directories, sh for the emergency shell
RDEPENDS:${PN}-initrd = "busybox e2fsprogs-e2fsck e2fsprogs-mke2fs systemd util-linux-mount"
REQUIRED_DISTRO_FEATURES = "systemd"

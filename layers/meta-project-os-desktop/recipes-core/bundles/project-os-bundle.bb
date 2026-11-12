SUMMARY = "project-os desktop — system update bundle"
DESCRIPTION = "Signed RAUC bundle with the system image: it is installed into the \
unused slot and becomes active on the next reboot (D-018, D-026)."
LICENSE = "GPL-3.0-only"

inherit bundle

RAUC_BUNDLE_COMPATIBLE = "project-os-amd64"
RAUC_BUNDLE_VERSION = "${DISTRO_VERSION}"
RAUC_BUNDLE_DESCRIPTION = "${DISTRO_NAME} ${DISTRO_VERSION}"
# verity format: the bundle is verified block by block while it is installed
RAUC_BUNDLE_FORMAT = "verity"
BUNDLE_ARGS += '--mksquashfs-args="-comp zstd"'

RAUC_BUNDLE_SLOTS = "rootfs"
RAUC_SLOT_rootfs = "project-os-image-base"
RAUC_SLOT_rootfs[fstype] = "ext4"

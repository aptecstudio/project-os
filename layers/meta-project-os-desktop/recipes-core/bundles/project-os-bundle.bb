# nooelint: oelint.file.underscores - like the RAUC bundle examples, no version in the
# file name (a bundle packs the system image, it has no version of its own)
SUMMARY = "project-os desktop — system update bundle"
DESCRIPTION = "Signed RAUC bundle with the system image: it is installed into the \
               unused slot and becomes active on the next reboot (D-018, D-026, \
               D-048)."
HOMEPAGE = "https://github.com/aptecstudio/project-os"
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-3.0-only;md5=c79ff39f19dfec6d293b95dea7b07891"

inherit bundle

RAUC_BUNDLE_COMPATIBLE = "project-os-amd64"
RAUC_BUNDLE_VERSION = "${DISTRO_VERSION}"
RAUC_BUNDLE_DESCRIPTION = "${DISTRO_NAME} ${DISTRO_VERSION}"
# verity format: the bundle is verified block by block while it is installed
RAUC_BUNDLE_FORMAT = "verity"
BUNDLE_ARGS += '--mksquashfs-args="-comp zstd"'

# System slot (D-047, D-048): the erofs image with its dm-verity hash tree, written as
# it is (raw) into the inactive slot, plus the slot's boot files (UKI, kernel,
# initramfs, command lines), which the hook copies to the EFI partition before RAUC
# marks the slot bootable
RAUC_BUNDLE_SLOTS = "rootfs"
RAUC_SLOT_rootfs = "project-os-image-base"
RAUC_SLOT_rootfs[fstype] = "erofs-lz4hc.verity"
RAUC_SLOT_rootfs[imagetype] = "raw"
RAUC_SLOT_rootfs[hooks] = "post-install"
RAUC_BUNDLE_EXTRA_FILES = "project-os-image-base-${MACHINE}.rootfs.slot-boot"

SRC_URI = "file://project-os-bundle-hook"
RAUC_BUNDLE_HOOKS[file] = "project-os-bundle-hook"

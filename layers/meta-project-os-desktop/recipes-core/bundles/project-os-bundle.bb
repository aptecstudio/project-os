SUMMARY = "project-os desktop — pacchetto di aggiornamento del sistema"
DESCRIPTION = "Bundle RAUC firmato con l'immagine di sistema: si installa nello slot non \
in uso e diventa attivo al riavvio successivo (D-018, D-026)."
LICENSE = "GPL-3.0-only"

inherit bundle

RAUC_BUNDLE_COMPATIBLE = "project-os-amd64"
RAUC_BUNDLE_VERSION = "${DISTRO_VERSION}"
RAUC_BUNDLE_DESCRIPTION = "${DISTRO_NAME} ${DISTRO_VERSION}"
# Formato verity: il bundle è verificato blocco per blocco mentre si installa
RAUC_BUNDLE_FORMAT = "verity"
BUNDLE_ARGS += '--mksquashfs-args="-comp zstd"'

RAUC_BUNDLE_SLOTS = "rootfs"
RAUC_SLOT_rootfs = "project-os-image-base"
RAUC_SLOT_rootfs[fstype] = "ext4"

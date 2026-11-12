SUMMARY = "project-os — immagine base"
DESCRIPTION = "Sistema minimo: kernel, glibc, systemd. Si avvia fino a un terminale \
testuale. Gli strati successivi (grafica, broker, shell) si aggiungono nelle fasi \
seguenti della roadmap."
LICENSE = "GPL-3.0-only"

inherit core-image

# Solo ciò che serve ad avviarsi (AGENTS.md §5.5), più ciò che la macchina dichiara
# per il proprio hardware (moduli del kernel, firmware: MACHINE_EXTRA_RRECOMMENDS).
# packagegroup-core-boot non li include da solo.
IMAGE_INSTALL = "packagegroup-core-boot ${MACHINE_EXTRA_RRECOMMENDS} ${CORE_IMAGE_EXTRA_INSTALL}"

# Kernel dentro lo slot di sistema: GRUB lo carica dallo slot scelto (D-026)
IMAGE_INSTALL += "kernel-image"

# Aggiornamenti A/B firmati (D-018, D-026)
IMAGE_INSTALL += "rauc"
# squashfs-tools non serve: i bundle si montano con il driver del kernel
BAD_RECOMMENDATIONS += "squashfs-tools"

# Sistema in sola lettura (D-018); i dati vivono sulla partizione cifrata montata su /var
IMAGE_FEATURES += "read-only-rootfs"

# Nessun gestore di pacchetti nell'immagine (D-018)
IMAGE_FEATURES:remove = "package-management"

# /home sta sulla partizione dati: nell'immagine diventa un collegamento a /var/home
ROOTFS_POSTPROCESS_COMMAND += "project_os_home_on_data"
project_os_home_on_data() {
    rm -rf ${IMAGE_ROOTFS}/home
    ln -s var/home ${IMAGE_ROOTFS}/home
    install -d ${IMAGE_ROOTFS}${nonarch_libdir}/tmpfiles.d
    echo "d /var/home 0755 root root -" > ${IMAGE_ROOTFS}${nonarch_libdir}/tmpfiles.d/project-os-home.conf
}

# Punto di montaggio della partizione EFI (fstab): con il sistema in sola lettura
# systemd non può crearlo all'avvio. Accesso solo root, come l'ESP montata (umask=0077).
ROOTFS_POSTPROCESS_COMMAND += "project_os_efi_mountpoint"
project_os_efi_mountpoint() {
    install -d -m 0700 ${IMAGE_ROOTFS}/efi
}

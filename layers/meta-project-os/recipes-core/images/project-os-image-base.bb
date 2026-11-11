SUMMARY = "project-os — immagine base"
DESCRIPTION = "Sistema minimo: kernel, glibc, systemd. Si avvia fino a un terminale \
testuale. Gli strati successivi (grafica, broker, shell) si aggiungono nelle fasi \
seguenti della roadmap."
LICENSE = "GPL-3.0-only"

inherit core-image

# Solo ciò che serve ad avviarsi (AGENTS.md §5.5)
IMAGE_INSTALL = "packagegroup-core-boot ${CORE_IMAGE_EXTRA_INSTALL}"

# Nessun gestore di pacchetti nell'immagine (D-018)
IMAGE_FEATURES:remove = "package-management"

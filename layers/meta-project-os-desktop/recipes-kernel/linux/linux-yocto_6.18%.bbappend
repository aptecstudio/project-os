# Kernel linux-yocto 6.18 LTS per la macchina desktop amd64 (D-014).
# La ricetta di OE-Core dichiara compatibili solo le macchine QEMU: aggiungiamo la
# nostra e partiamo dalla configurazione di riferimento per PC a 64 bit di
# yocto-kernel-cache.
COMPATIBLE_MACHINE:project-os-amd64 = "project-os-amd64"
KMACHINE:project-os-amd64 = "common-pc-64"
KBRANCH:project-os-amd64 = "v6.18/standard/base"

# Hardware moderno (R-04, D-025). Ogni frammento si verifica contro i Kconfig del
# kernel con tools/check-kernel-fragments.py.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append:project-os-amd64 = " \
    file://storage.cfg \
    file://graphics.cfg \
    file://audio.cfg \
    file://bluetooth.cfg \
    file://wifi.cfg \
    file://ethernet.cfg \
    file://input-platform.cfg \
    file://ab-crypt.cfg \
"

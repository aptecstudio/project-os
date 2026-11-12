SUMMARY = "project-os desktop — stato iniziale degli slot di avvio A/B"
DESCRIPTION = "Genera grubenv, il blocco di variabili che GRUB legge per scegliere lo \
slot da avviare e che RAUC aggiorna a ogni installazione (D-026). Stato di fabbrica: \
slot A valido, slot B vuoto."
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-3.0-only;md5=c79ff39f19dfec6d293b95dea7b07891"

inherit deploy nopackages

INHIBIT_DEFAULT_DEPS = "1"
PACKAGE_ARCH = "${MACHINE_ARCH}"

# Variabili lette da project-os-grub.cfg e scritte da RAUC (bootloader=grub)
GRUBENV_VARS = "ORDER=A B;A_OK=1;A_TRY=0;B_OK=0;B_TRY=0"

do_compile() {
    # Formato di GRUB: intestazione, una variabile per riga, riempimento con '#' fino a
    # 1024 byte esatti (save_env non cambia mai la dimensione del file)
    {
        echo "# GRUB Environment Block"
        echo "${GRUBENV_VARS}" | tr ';' '\n'
    } > grubenv.head
    size=$(wc -c < grubenv.head)
    if [ "$size" -gt 1024 ]; then
        bbfatal "grubenv supera 1024 byte"
    fi
    cp grubenv.head grubenv
    head -c $(expr 1024 - $size) /dev/zero | tr '\0' '#' >> grubenv
}

do_deploy() {
    install -d ${DEPLOYDIR}/project-os
    install -m 0644 ${B}/grubenv ${DEPLOYDIR}/project-os/grubenv
}
addtask deploy after do_compile before do_build

# Kernel linux-yocto 6.18 LTS per la macchina desktop amd64 (D-014).
# La ricetta di OE-Core dichiara compatibili solo le macchine QEMU: aggiungiamo la
# nostra e usiamo la configurazione di riferimento per PC a 64 bit di yocto-kernel-cache.
# La configurazione dell'hardware moderno (audio, Bluetooth, Wi-Fi, GPU) arriva al
# passo 3 della Fase 1, come frammenti in questo layer.
COMPATIBLE_MACHINE:project-os-amd64 = "project-os-amd64"
KMACHINE:project-os-amd64 = "common-pc-64"
KBRANCH:project-os-amd64 = "v6.18/standard/base"

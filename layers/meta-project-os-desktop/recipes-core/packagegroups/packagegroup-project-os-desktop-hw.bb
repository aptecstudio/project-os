SUMMARY = "project-os desktop — firmware dell'hardware moderno"
DESCRIPTION = "Firmware per schede grafiche, Wi-Fi, Bluetooth, rete e processori dei \
PC Intel/AMD (R-04, D-025). I driver sono nel kernel; qui ci sono solo i file che i \
driver caricano all'avvio dei dispositivi."
LICENSE = "GPL-3.0-only"

PACKAGE_ARCH = "${MACHINE_ARCH}"
inherit packagegroup

RDEPENDS:${PN} = " \
    ${GRAPHICS} \
    ${WIFI} \
    ${BLUETOOTH} \
    ${ETHERNET} \
    ${AUDIO} \
    ${CPU} \
"

# Grafica: Intel (i915, xe), AMD (amdgpu, radeon), NVIDIA (nouveau)
GRAPHICS = " \
    linux-firmware-i915 \
    linux-firmware-xe \
    linux-firmware-amdgpu \
    linux-firmware-amdgpu-misc \
    linux-firmware-radeon \
    linux-firmware-nvidia-gpu \
"

# Wi-Fi: Intel, Qualcomm Atheros, Realtek, MediaTek, Broadcom; database delle
# frequenze ammesse per paese (obbligatorio per cfg80211)
WIFI = " \
    linux-firmware-iwlwifi \
    linux-firmware-iwlwifi-misc \
    linux-firmware-ath9k \
    linux-firmware-ath10k \
    linux-firmware-ath11k \
    linux-firmware-ath12k \
    linux-firmware-rtl8821 \
    linux-firmware-rtl8822 \
    linux-firmware-rtl8851 \
    linux-firmware-rtl8852 \
    linux-firmware-rtl8922 \
    linux-firmware-mediatek \
    linux-firmware-bcm4350 \
    linux-firmware-bcm4356-pcie \
    wireless-regdb-static \
"

# Bluetooth: Intel, Qualcomm, Realtek (gli altri Realtek e MediaTek sono già nei
# pacchetti Wi-Fi qui sopra)
BLUETOOTH = " \
    linux-firmware-ibt \
    linux-firmware-ibt-misc \
    linux-firmware-qca \
    linux-firmware-rtl8761 \
"

# Rete cablata Realtek
ETHERNET = "linux-firmware-rtl-nic"

# Amplificatori audio Cirrus dei portatili. Firmware Intel SOF: ricetta da scrivere.
AUDIO = "linux-firmware-cirrus"

# Microcode AMD. Microcode Intel: ricetta da scrivere (non è in OpenEmbedded-Core).
CPU = "linux-firmware-microcode-amd"

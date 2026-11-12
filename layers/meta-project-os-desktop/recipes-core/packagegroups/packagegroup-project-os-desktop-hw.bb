SUMMARY = "project-os desktop — firmware for modern hardware"
DESCRIPTION = "Firmware for graphics cards, Wi-Fi, Bluetooth, network and processors \
of Intel/AMD PCs (R-04, D-025). The drivers are in the kernel; here are only the files \
the drivers load when the devices start."
LICENSE = "GPL-3.0-only"

PACKAGE_ARCH = "${MACHINE_ARCH}"
inherit packagegroup

RDEPENDS:${PN} = " \
    ${GRAPHICS} \
    ${WIFI} \
    ${BLUETOOTH} \
    ${ETHERNET} \
    ${AUDIO} \
"

# Graphics: Intel (i915, xe), AMD (amdgpu, radeon), NVIDIA (nouveau)
GRAPHICS = " \
    linux-firmware-i915 \
    linux-firmware-xe \
    linux-firmware-amdgpu \
    linux-firmware-amdgpu-misc \
    linux-firmware-radeon \
    linux-firmware-nvidia-gpu \
"

# Wi-Fi: Intel, Qualcomm Atheros, Realtek, MediaTek, Broadcom; database of the
# frequencies allowed per country (mandatory for cfg80211)
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

# Bluetooth: Intel, Qualcomm, Realtek (the other Realtek and MediaTek ones are already
# in the Wi-Fi packages above)
BLUETOOTH = " \
    linux-firmware-ibt \
    linux-firmware-ibt-misc \
    linux-firmware-qca \
    linux-firmware-rtl8761 \
"

# Realtek wired network
ETHERNET = "linux-firmware-rtl-nic"

# Cirrus audio amplifiers of laptops; Sound Open Firmware for the audio DSP of Intel
# laptops (sof-bin, D-039)
AUDIO = "linux-firmware-cirrus sof-bin"

# CPU microcode (Intel and AMD) is not installed here: it is loaded early from the
# microcode.cpio archive built by project-os-microcode (step 3b, D-043)

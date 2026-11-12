SUMMARY = "project-os — base image"
DESCRIPTION = "Minimal system: kernel, glibc, systemd. Boots to a text terminal. \
The next layers (graphics, broker, shell) are added in the following phases of the \
roadmap."
LICENSE = "GPL-3.0-only"

inherit core-image

# Only what is needed to boot (AGENTS.md §5.5), plus what the machine declares for its
# own hardware (kernel modules, firmware: MACHINE_EXTRA_RRECOMMENDS).
# packagegroup-core-boot does not include them by itself.
IMAGE_INSTALL = "packagegroup-core-boot ${MACHINE_EXTRA_RRECOMMENDS} ${CORE_IMAGE_EXTRA_INSTALL}"

# Kernel inside the system slot: GRUB loads it from the chosen slot (D-026)
IMAGE_INSTALL += "kernel-image"

# Signed A/B updates (D-018, D-026)
IMAGE_INSTALL += "rauc"
# squashfs-tools is not needed: bundles are mounted with the kernel driver
BAD_RECOMMENDATIONS += "squashfs-tools"

# Read-only system (D-018); data lives on the encrypted partition mounted on /var
IMAGE_FEATURES += "read-only-rootfs"

# No package manager in the image (D-018)
IMAGE_FEATURES:remove = "package-management"

# /home lives on the data partition: in the image it becomes a link to /var/home
ROOTFS_POSTPROCESS_COMMAND += "project_os_home_on_data"
project_os_home_on_data() {
    rm -rf ${IMAGE_ROOTFS}/home
    ln -s var/home ${IMAGE_ROOTFS}/home
    install -d ${IMAGE_ROOTFS}${nonarch_libdir}/tmpfiles.d
    echo "d /var/home 0755 root root -" > ${IMAGE_ROOTFS}${nonarch_libdir}/tmpfiles.d/project-os-home.conf
}

# Mount point of the EFI partition (efi.mount): on the read-only system systemd cannot
# create it at boot. Root-only access, like the mounted ESP (umask=0077).
ROOTFS_POSTPROCESS_COMMAND += "project_os_efi_mountpoint"
project_os_efi_mountpoint() {
    install -d -m 0700 ${IMAGE_ROOTFS}/efi
}

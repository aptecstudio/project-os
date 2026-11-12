SUMMARY = "project-os — initramfs"
DESCRIPTION = "systemd in initrd mode: finds the system slot given on the kernel \
command line, mounts it on /sysroot and switches to it. The base for the encrypted \
/etc overlay (step 4c.2) and dm-verity (step 4c.3) (D-042, D-043)."
LICENSE = "GPL-3.0-only"

# Only what systemd needs to find, check and mount the root file system (AGENTS.md
# §5.5): udev for /dev/disk/by-partlabel, fsck for ext4, mount, the os-release data
# that becomes /etc/initrd-release. No kernel modules: the boot drivers are built in.
PACKAGE_INSTALL = " \
    systemd \
    udev \
    systemd-udev-rules \
    util-linux-mount \
    util-linux-fsck \
    e2fsprogs-e2fsck \
    os-release \
"
# Nothing else from recommendations: the initramfs stays small
NO_RECOMMENDATIONS = "1"

IMAGE_FEATURES = ""
IMAGE_LINGUAS = ""
IMAGE_FSTYPES = "cpio.zst"
IMAGE_NAME_SUFFIX = ""
IMAGE_ROOTFS_SIZE = "8192"
IMAGE_ROOTFS_EXTRA_SPACE = "0"

inherit core-image

# systemd runs as /init and knows it is in an initramfs from /etc/initrd-release
ROOTFS_POSTPROCESS_COMMAND += "project_os_initrd_setup"
project_os_initrd_setup() {
    ln -sf ${nonarch_libdir}/systemd/systemd ${IMAGE_ROOTFS}/init
    cp ${IMAGE_ROOTFS}${nonarch_libdir}/os-release ${IMAGE_ROOTFS}${sysconfdir}/initrd-release
}

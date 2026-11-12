# No tmpfs on /var/volatile (D-026): /var is the persistent encrypted data partition,
# and logs and temporary files live there; the tmpfs was only used by volatile-binds.
do_install:append:project-os-amd64() {
    sed -i '/[[:space:]][/]var[/]volatile[[:space:]]/d' ${D}${sysconfdir}/fstab
}

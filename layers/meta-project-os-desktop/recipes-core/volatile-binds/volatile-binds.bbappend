# No volatile bind mounts (D-026): /var is the persistent encrypted data partition, so
# /var/lib, /var/cache and /var/spool must not be replaced by tmpfs copies, and /srv is
# not used. The package stays because systemd depends on it, but installs no units.
VOLATILE_BINDS = ""

# Without units, the unit directory stays empty and would fail the installed-vs-shipped
# QA check: remove the empty directories left under /usr/lib
do_install:append() {
    find ${D}${nonarch_libdir} -depth -type d -empty -delete
}

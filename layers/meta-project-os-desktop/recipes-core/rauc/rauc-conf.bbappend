# RAUC configuration for the desktop and certificate of the CA that verifies updates
# (D-026). The certificate is NOT in the repository: it is taken from the key directory
# given by PROJECT_OS_KEYS (see kas/base.yml and tools/gen-dev-keys.sh).
FILESEXTRAPATHS:prepend:project-os-amd64 := "${THISDIR}/files:${PROJECT_OS_KEYS}:"
RAUC_KEYRING_FILE:project-os-amd64 = "ca.cert.pem"

python do_fetch:prepend:project-os-amd64() {
    keys = d.getVar('PROJECT_OS_KEYS') or ''
    if not keys or not os.path.isfile(os.path.join(keys, 'ca.cert.pem')):
        bb.fatal("CA certificate not found. Set PROJECT_OS_KEYS to the key directory; "
                 "for development, create the keys with tools/gen-dev-keys.sh")
}

# No LUKS2 SSH token plugin: it keeps unlock keys on a remote SSH server, which we do
# not use; dropping it also removes libssh and libgcrypt from the image (R-02, §5.5)
PACKAGECONFIG:remove = "ssh-token"

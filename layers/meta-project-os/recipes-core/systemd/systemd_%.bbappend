# systemd features for the encrypted data partition (D-026):
#   repart       creates the data partition on first boot
#   cryptsetup   unlocks LUKS2 volumes (crypttab) and dm-verity (step 4c)
#   openssl      required by repart
PACKAGECONFIG:append:project-os = " repart cryptsetup openssl"

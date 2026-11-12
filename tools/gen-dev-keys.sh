#!/bin/sh
# Generates the DEVELOPMENT keys to sign and verify RAUC updates (D-026).
#
# Usage: tools/gen-dev-keys.sh [directory]
#        (default: ~/.config/project-os/keys)
# Then:  export PROJECT_OS_KEYS=<directory>
#
# The keys stay outside the repository (AGENTS.md §4) and must never be used for
# released images: those will have their own CA and signing keys, kept separately.
set -eu

DIR="${1:-$HOME/.config/project-os/keys}"
DAYS=3650

if [ -e "$DIR/ca.cert.pem" ]; then
    echo "Keys already exist in $DIR: not overwriting them." >&2
    exit 1
fi

mkdir -p "$DIR"
chmod 700 "$DIR"
cd "$DIR"

# Certificate authority: its certificate goes into the image and verifies the bundles
openssl req -x509 -newkey rsa:4096 -nodes -days "$DAYS" \
    -keyout ca.key.pem -out ca.cert.pem \
    -subj "/O=project-os/CN=project-os development CA"

# Bundle signing key, certified by the CA
openssl req -newkey rsa:4096 -nodes \
    -keyout signing.key.pem -out signing.csr.pem \
    -subj "/O=project-os/CN=project-os development signing"
printf 'basicConstraints=CA:FALSE\nkeyUsage=critical,digitalSignature\n' > signing.ext
openssl x509 -req -in signing.csr.pem -days "$DAYS" \
    -CA ca.cert.pem -CAkey ca.key.pem -CAcreateserial \
    -extfile signing.ext -out signing.cert.pem
rm -f signing.csr.pem signing.ext
chmod 600 ./*.key.pem

echo "Development keys created in $DIR"
echo "Before each build:  export PROJECT_OS_KEYS=$DIR"

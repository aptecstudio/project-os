#!/bin/sh
# Genera le chiavi di SVILUPPO per firmare e verificare gli aggiornamenti RAUC (D-026).
#
# Uso:  tools/gen-dev-keys.sh [cartella]
#       (predefinita: ~/.config/project-os/keys)
# Poi:  export PROJECT_OS_KEYS=<cartella>
#
# Le chiavi restano fuori dal repository (AGENTS.md §4) e non vanno mai usate per
# immagini rilasciate: quelle avranno una CA e chiavi di firma proprie, custodite a parte.
set -eu

DIR="${1:-$HOME/.config/project-os/keys}"
DAYS=3650

if [ -e "$DIR/ca.cert.pem" ]; then
    echo "Esistono già chiavi in $DIR: non le sovrascrivo." >&2
    exit 1
fi

mkdir -p "$DIR"
chmod 700 "$DIR"
cd "$DIR"

# Autorità di certificazione: il suo certificato va nell'immagine e verifica i bundle
openssl req -x509 -newkey rsa:4096 -nodes -days "$DAYS" \
    -keyout ca.key.pem -out ca.cert.pem \
    -subj "/O=project-os/CN=project-os development CA"

# Chiave di firma dei bundle, certificata dalla CA
openssl req -newkey rsa:4096 -nodes \
    -keyout signing.key.pem -out signing.csr.pem \
    -subj "/O=project-os/CN=project-os development signing"
printf 'basicConstraints=CA:FALSE\nkeyUsage=critical,digitalSignature\n' > signing.ext
openssl x509 -req -in signing.csr.pem -days "$DAYS" \
    -CA ca.cert.pem -CAkey ca.key.pem -CAcreateserial \
    -extfile signing.ext -out signing.cert.pem
rm -f signing.csr.pem signing.ext
chmod 600 ./*.key.pem

echo "Chiavi di sviluppo create in $DIR"
echo "Prima di ogni build:  export PROJECT_OS_KEYS=$DIR"

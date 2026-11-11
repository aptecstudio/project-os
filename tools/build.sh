#!/bin/sh
# Costruisce project-os per desktop amd64, in configurazione di sviluppo.
#
# Uso:  tools/build.sh [immagine|aggiornamento|shell]
#   immagine       (predefinito) immagine del disco, da provare con tools/run-qemu.sh
#   aggiornamento  pacchetto di aggiornamento RAUC firmato (project-os-bundle)
#   shell          terminale con l'ambiente bitbake, per comandi manuali
#
# La configurazione di sviluppo (kas/dev.yml) permette l'accesso root senza password:
# mai per immagini da distribuire (AGENTS.md §5.6).
set -eu

cd "$(dirname "$0")/.."

: "${PROJECT_OS_KEYS:=$HOME/.config/project-os/keys}"
export PROJECT_OS_KEYS
if [ ! -f "$PROJECT_OS_KEYS/ca.cert.pem" ]; then
    echo "Chiavi non trovate in $PROJECT_OS_KEYS." >&2
    echo "Creale con tools/gen-dev-keys.sh (o tools/setup-host.sh)." >&2
    exit 1
fi

CONFIG="kas/desktop-amd64.yml:kas/dev.yml"

case "${1:-immagine}" in
    immagine)      exec kas build "$CONFIG" ;;
    aggiornamento) exec kas build --target project-os-bundle "$CONFIG" ;;
    shell)         exec kas shell "$CONFIG" ;;
    *)
        echo "Uso: $0 [immagine|aggiornamento|shell]" >&2
        exit 2
        ;;
esac

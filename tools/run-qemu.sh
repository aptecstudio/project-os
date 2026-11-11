#!/bin/sh
# Avvia l'immagine desktop di project-os nell'emulatore QEMU, con firmware UEFI.
#
# Uso:  tools/run-qemu.sh [--reset] [--testo]
#   --reset   riparte da un disco nuovo, copiato dall'ultima build (perde i dati)
#   --testo   niente finestra grafica: tutto nel terminale (console seriale)
#
# Il disco dell'emulatore è una copia dell'immagine in build/qemu/disk.img, con 16 GB
# di spazio libero in più: al primo avvio systemd-repart ci crea la partizione dati.
# Per uscire in modalità --testo: Ctrl-a poi x.
#
# Avvio da BIOS: non ancora disponibile (ROADMAP, passo 4e).
set -eu

cd "$(dirname "$0")/.."

RESET=0
TEXT=0
for arg in "$@"; do
    case "$arg" in
        --reset) RESET=1 ;;
        --testo) TEXT=1 ;;
        *) echo "Opzione sconosciuta: $arg" >&2; exit 2 ;;
    esac
done

DEPLOY=build/tmp/deploy/images/project-os-amd64
IMAGE="$DEPLOY/project-os-image-base-project-os-amd64.rootfs.wic"
WORK=build/qemu
DISK="$WORK/disk.img"
VARS="$WORK/OVMF_VARS.fd"

if [ ! -f "$IMAGE" ]; then
    echo "Immagine non trovata: $IMAGE" >&2
    echo "Esegui prima tools/build.sh" >&2
    exit 1
fi

# Firmware UEFI OVMF: percorsi di Debian/Ubuntu e di Fedora
CODE=""
for c in /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd \
         /usr/share/edk2/ovmf/OVMF_CODE.fd; do
    [ -f "$c" ] && { CODE="$c"; break; }
done
if [ -z "$CODE" ]; then
    echo "Firmware OVMF non trovato: installa il pacchetto ovmf." >&2
    exit 1
fi
VARS_TEMPLATE="$(dirname "$CODE")/$(basename "$CODE" | sed 's/CODE/VARS/')"

mkdir -p "$WORK"
if [ "$RESET" -eq 1 ] || [ ! -f "$DISK" ]; then
    echo "Preparo un disco nuovo dall'ultima build..."
    cp --sparse=always "$IMAGE" "$DISK"
    truncate -s +16G "$DISK"
    cp "$VARS_TEMPLATE" "$VARS"
elif [ "$IMAGE" -nt "$DISK" ]; then
    echo "Nota: c'è una build più recente del disco in uso. Usa --reset per ripartire da quella."
fi

if [ -w /dev/kvm ]; then
    ACCEL=kvm
    CPU=host
else
    echo "KVM non disponibile: l'emulazione sarà lenta."
    ACCEL=tcg
    # Processore x86-64 di base, come il sistema (D-027)
    CPU=qemu64
fi

if [ "$TEXT" -eq 1 ]; then
    DISPLAY_ARGS="-nographic -serial mon:stdio"
else
    DISPLAY_ARGS="-vga std -serial mon:stdio"
fi

# shellcheck disable=SC2086
exec qemu-system-x86_64 \
    -machine q35,accel="$ACCEL" -cpu "$CPU" -smp 2 -m 2048 \
    -drive if=pflash,format=raw,readonly=on,file="$CODE" \
    -drive if=pflash,format=raw,file="$VARS" \
    -drive if=none,id=system,format=raw,file="$DISK" \
    -device nvme,serial=projectos0,drive=system \
    -nic user,model=e1000e \
    -device qemu-xhci -device usb-kbd -device usb-tablet \
    $DISPLAY_ARGS

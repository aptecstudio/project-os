#!/bin/sh
# Prepara la macchina di build di project-os (DA-11).
#
# Uso:  tools/setup-host.sh
# Sistema consigliato: Ubuntu Server 24.04 o 26.04 LTS (anche Debian 13), in una VM o
# su un PC dedicato. Requisiti: almeno 16 GB di RAM, 250 GB di disco, molti core.
#
# Installa:
#   - i programmi richiesti da Yocto 6.0 «Wrynose»;
#   - kas (strumento di build, D-024), tramite pipx;
#   - QEMU e il firmware UEFI OVMF, per provare le immagini nell'emulatore;
#   - le chiavi di sviluppo per firmare gli aggiornamenti (fuori dal repository).
# Chiede conferma prima di cambiare impostazioni di sistema.
set -eu

say() { printf '\n==> %s\n' "$*"; }
ask() {
    printf '%s [s/N] ' "$1"
    read -r answer
    case "$answer" in s|S|si|SI|sì|Sì) return 0 ;; *) return 1 ;; esac
}

if [ "$(id -u)" -eq 0 ]; then
    echo "Esegui lo script come utente normale (usa sudo da solo quando serve)." >&2
    echo "Bitbake si rifiuta di funzionare come root." >&2
    exit 1
fi

. /etc/os-release
case "${ID:-}:${VERSION_ID:-}" in
    ubuntu:24.04|ubuntu:26.04|debian:13) ;;
    *)
        echo "Attenzione: $PRETTY_NAME non è tra i sistemi provati (Ubuntu 24.04/26.04, Debian 13)."
        ask "Continuare lo stesso?" || exit 1
        ;;
esac

say "Installo i programmi richiesti da Yocto, QEMU e OVMF"
sudo apt-get update
sudo apt-get install -y \
    build-essential chrpath cpio debianutils diffstat file gawk gcc git \
    iputils-ping libacl1 liblz4-tool locales python3 python3-git python3-jinja2 \
    python3-pexpect python3-pip python3-subunit socat texinfo unzip wget xz-utils \
    zstd lz4 \
    pipx openssl \
    qemu-system-x86 qemu-utils ovmf

say "Attivo la lingua en_US.UTF-8 (bitbake la richiede)"
if ! locale -a | grep -qi '^en_US\.utf-\?8$'; then
    sudo sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
    sudo locale-gen
fi

say "Installo kas"
pipx ensurepath >/dev/null
if pipx list 2>/dev/null | grep -q 'package kas '; then
    pipx upgrade kas
else
    pipx install kas
fi

# Ubuntu 24.04 e successivi limitano i namespace utente non privilegiati con AppArmor;
# bitbake li usa per isolare dalla rete i passi di compilazione.
F=/proc/sys/kernel/apparmor_restrict_unprivileged_userns
if [ -r "$F" ] && [ "$(cat "$F")" = "1" ]; then
    say "Namespace utente limitati da AppArmor"
    echo "Bitbake ha bisogno dei namespace utente per isolare la compilazione dalla rete."
    echo "Posso consentirli in modo permanente su questa macchina"
    echo "(/etc/sysctl.d/60-project-os-bitbake.conf). Riduce un po' l'isolamento delle app"
    echo "sulla macchina di build: va bene su una VM dedicata, meno su un PC di uso quotidiano."
    if ask "Consentire i namespace utente?"; then
        echo "kernel.apparmor_restrict_unprivileged_userns = 0" |
            sudo tee /etc/sysctl.d/60-project-os-bitbake.conf >/dev/null
        sudo sysctl --system >/dev/null
    else
        echo "Non modificato: la build potrebbe fermarsi con errori sui namespace."
    fi
fi

KEYS="$HOME/.config/project-os/keys"
say "Chiavi di sviluppo per gli aggiornamenti"
if [ -f "$KEYS/ca.cert.pem" ]; then
    echo "Già presenti in $KEYS"
else
    "$(dirname "$0")/gen-dev-keys.sh" "$KEYS"
fi

if [ -e /dev/kvm ]; then
    if [ ! -w /dev/kvm ]; then
        say "Accelerazione KVM"
        echo "Aggiungo $USER al gruppo kvm (vale dal prossimo accesso)."
        sudo usermod -aG kvm "$USER"
    fi
else
    say "Accelerazione KVM non disponibile"
    echo "QEMU funzionerà, ma molto più lento. In una VM, attiva la virtualizzazione"
    echo "annidata nelle impostazioni del programma di virtualizzazione."
fi

say "Fatto. Prossimi passi:"
echo "  1. esci e rientra (o apri un nuovo terminale), per kas e il gruppo kvm"
echo "  2. tools/build.sh            prima build: diverse ore"
echo "  3. tools/run-qemu.sh         avvia l'immagine nell'emulatore"

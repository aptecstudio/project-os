#!/bin/sh
# Costruisce project-os per desktop amd64, in configurazione di sviluppo.
#
# Uso:  tools/build.sh [--poche-risorse] [immagine|aggiornamento|shell]
#   immagine         (predefinito) immagine del disco, da provare con tools/run-qemu.sh
#   aggiornamento    pacchetto di aggiornamento RAUC firmato (project-os-bundle)
#   shell            terminale con l'ambiente bitbake, per comandi manuali
#   --poche-risorse  per PC con poca RAM o poco disco, per esempio un portatile
#                    (kas/low-resources.yml): build più lenta, ma sta in circa 8 GB di
#                    RAM e 45 GB di disco. Basta per la Fase 1, non per WebKitGTK.
#   --help           mostra questo aiuto
#
# Modalità predefinita: piene prestazioni, per la macchina di build consigliata
# (docs/sviluppo.md: almeno 16 GB di RAM e 250 GB di disco). bitbake usa tutti i core e
# tiene i file di lavoro delle ricette, così le build successive sono più rapide.
# Se la macchina sembra troppo piccola, lo script avvisa e suggerisce --poche-risorse.
#
# Equivalenti con kas, senza questo script:
#   kas build kas/desktop-amd64.yml:kas/dev.yml
#   kas build kas/desktop-amd64.yml:kas/dev.yml:kas/low-resources.yml
#
# PROJECT_OS_LOW_RESOURCES=1 equivale a --poche-risorse (=0 o assente: predefinita).
# La configurazione di sviluppo (kas/dev.yml) permette l'accesso root senza password:
# mai per immagini da distribuire (AGENTS.md §5.6).
set -eu

cd "$(dirname "$0")/.."

usage() {
    sed -n '4,11s/^# \{0,1\}//p' "$0"
}

low="${PROJECT_OS_LOW_RESOURCES:-0}"
target=immagine
for arg in "$@"; do
    case "$arg" in
        --poche-risorse) low=1 ;;
        --help|-h) usage; exit 0 ;;
        immagine|aggiornamento|shell) target="$arg" ;;
        *)
            echo "Opzione sconosciuta: $arg" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if ! command -v kas >/dev/null 2>&1; then
    echo "kas non trovato. Prepara la macchina con tools/setup-host.sh" >&2
    echo "(poi apri un nuovo terminale)." >&2
    exit 1
fi

: "${PROJECT_OS_KEYS:=$HOME/.config/project-os/keys}"
export PROJECT_OS_KEYS
if [ ! -f "$PROJECT_OS_KEYS/ca.cert.pem" ]; then
    echo "Chiavi non trovate in $PROJECT_OS_KEYS." >&2
    echo "Creale con tools/gen-dev-keys.sh (o tools/setup-host.sh)." >&2
    exit 1
fi

CONFIG="kas/desktop-amd64.yml:kas/dev.yml"

# Risorse della macchina: RAM totale e spazio libero dove va la build
mem_gb=$(awk '/^MemTotal:/ { printf "%d", $2 / 1048576 + 0.5 }' /proc/meminfo)
free_gb=$(df -Pk . | awk 'NR == 2 { printf "%d", $4 / 1048576 }')
cores=$(nproc)

# Spazio richiesto solo alla prima build: le successive riusano build/ e sources/
first_build=0
[ -d build/tmp ] || first_build=1

warn=""
if [ "$low" = 1 ]; then
    CONFIG="$CONFIG:kas/low-resources.yml"
    echo "Modalità poche risorse (kas/low-resources.yml): build più lenta, meno RAM e disco."
    if [ "$first_build" = 1 ] && [ "$free_gb" -lt 45 ]; then
        warn="Spazio libero: $free_gb GB; anche con --poche-risorse ne servono circa 45."
    fi
else
    echo "Modalità predefinita: piene prestazioni ($cores core, $mem_gb GB di RAM)."
    # 15 e non 16: un PC da 16 GB ne mostra un po' meno al sistema
    if [ "$mem_gb" -lt 15 ]; then
        warn="RAM: $mem_gb GB, sotto i 16 GB consigliati: la build può esaurire la memoria."
    fi
    if [ "$first_build" = 1 ] && [ "$free_gb" -lt 100 ]; then
        warn="${warn:+$warn
}Spazio libero: $free_gb GB; la prima build ne occupa circa 100 (250 dalla Fase 2)."
    fi
    [ -n "$warn" ] && warn="$warn
Su un PC con poche risorse usa: tools/build.sh --poche-risorse"
fi

if [ -n "$warn" ]; then
    echo >&2
    echo "Attenzione:" >&2
    echo "$warn" | sed 's/^/  /' >&2
    echo >&2
    # Da terminale si chiede conferma; da script (CI, automazioni) si avvisa e basta
    if [ -t 0 ]; then
        printf "Continuare comunque? [s/N] " >&2
        read -r answer
        case "$answer" in
            s|S|si|sì|Si|Sì) ;;
            *) echo "Build annullata." >&2; exit 1 ;;
        esac
    fi
fi

case "$target" in
    immagine)      exec kas build "$CONFIG" ;;
    aggiornamento) exec kas build --target project-os-bundle "$CONFIG" ;;
    shell)         exec kas shell "$CONFIG" ;;
esac

# Lavorare su project-os dal proprio PC

Guida per scaricare il progetto, costruire l'immagine desktop e provarla nell'emulatore
QEMU. Stato: Fase 1 (sistema base), novembre 2026.

## 1. La macchina di build

La build compila da sorgenti l'intero sistema (kernel, librerie, systemd e il resto),
quindi serve una macchina robusta:

| | Minimo | Consigliato |
|---|---|---|
| Sistema | Ubuntu Server 24.04 LTS | Ubuntu Server 26.04 LTS |
| RAM | 16 GB | 32 GB |
| Disco libero | 250 GB | 400 GB su SSD |
| Processore | 4 core | 8 core o più |

Va bene una macchina virtuale (VirtualBox, VMware, GNOME Boxes, Hyper‑V) o un PC
dedicato. In una VM, attiva la **virtualizzazione annidata**: senza, l'emulatore
funziona ma è molto lento. Il desktop non serve, basta la versione Server; la finestra
dell'emulatore si può aprire anche da un Ubuntu Desktop.

Se il PC è già Linux (Ubuntu o Debian), si può lavorare direttamente lì.

**Portatile o PC con poche risorse** (circa 8 GB di RAM e 40-50 GB liberi): per
l'immagine della Fase 1 basta. Con meno di 16 GB di RAM `tools/build.sh` usa da solo
`kas/low-resources.yml`: meno compilazioni in parallelo e file di lavoro cancellati man
mano. La prima build diventa più lunga (anche una notte intera). Non basterà dalla
Fase 2, quando si compila WebKitGTK.

## 2. Scaricare il progetto e preparare la macchina

```sh
git clone https://github.com/aptecstudio/project-os.git
cd project-os
tools/setup-host.sh
```

`setup-host.sh` installa i programmi per Yocto, kas, QEMU e il firmware UEFI, e crea le
**chiavi di sviluppo** per firmare gli aggiornamenti in `~/.config/project-os/keys`
(fuori dal repository). Chiede conferma prima di cambiare impostazioni di sistema.

Alla fine esci e rientra (o apri un nuovo terminale).

## 3. Costruire l'immagine

```sh
tools/build.sh
```

La **prima build richiede diverse ore** (da 2 a 8 secondi la macchina) e scarica
alcuni GB di sorgenti in `build/` e `sources/`. Le build successive riusano il lavoro
già fatto e richiedono pochi minuti, se cambia poco.

Altri comandi:

| Comando | Cosa fa |
|---|---|
| `tools/build.sh aggiornamento` | pacchetto di aggiornamento firmato (RAUC) |
| `tools/build.sh shell` | terminale con i comandi di bitbake |

## 4. Provare l'immagine nell'emulatore

```sh
tools/run-qemu.sh            # finestra grafica, più la console nel terminale
tools/run-qemu.sh --testo    # tutto nel terminale; per uscire: Ctrl-a poi x
tools/run-qemu.sh --reset    # riparte da un disco nuovo, copiato dall'ultima build
```

Cosa aspettarsi oggi:

1. menu di avvio GRUB con la voce «project-os» (menu testuale: il tema grafico arriva
   al passo 5b);
2. avvio del kernel e di systemd;
3. al **primo avvio**, creazione della partizione dati cifrata nello spazio libero;
4. accesso testuale: utente `root`, senza password (solo nella configurazione di
   sviluppo); sulla console del terminale l'accesso è automatico.

Non c'è ancora interfaccia grafica: arriva con le Fasi 2 (WebKit e compositore) e 5
(shell).

## 5. Limiti attuali

- **I dati non sono protetti:** la partizione dati usa una chiave vuota finché non
  esisterà il setup (ROADMAP, passo 4d).
- **Avvio da BIOS** non ancora disponibile: solo UEFI (passo 4e).
- **Modifiche a `/etc`** (rete, utenti) non restano dopo il riavvio (passo 4c).
- **Emulatore Android / mobile:** non ancora, arriva con la Fase 7.

## 6. Se qualcosa va storto

- **Build ferma con un errore:** copia le ultime righe del terminale e, se indicato, il
  file di log citato nell'errore (in `build/tmp/work/...`). Sono utili anche il sistema
  della macchina di build e l'output di `git log -1`.
- **Errore sui namespace o su "unshare":** rilancia `tools/setup-host.sh` e accetta la
  modifica di AppArmor (vedi la spiegazione nello script).
- **Errore sulle chiavi:** controlla che esista `~/.config/project-os/keys/ca.cert.pem`,
  oppure creale con `tools/gen-dev-keys.sh`.
- **L'emulatore non si avvia o è lentissimo:** controlla che esista `/dev/kvm` e che il
  tuo utente sia nel gruppo `kvm` (`groups`).

## 7. Dove sono le cose

| Percorso | Contenuto |
|---|---|
| `AGENTS.md`, `MEMORY.md`, `ROADMAP.md` | regole, decisioni, stato del progetto |
| `kas/` | configurazione della build |
| `layers/` | ricette Yocto: distribuzione, immagine, macchina, kernel, avvio |
| `branding/` | logo segnaposto e tema del menu di avvio |
| `tools/` | script di questa guida e strumenti di verifica |
| `build/`, `sources/` | creati dalla build, non versionati |

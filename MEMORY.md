# MEMORY.md — Scelte, stile e convenzioni

Registro delle decisioni di progetto e del loro perché, dello stile grafico, della struttura
del codice e delle convenzioni sintattiche. Regole di aggiornamento in `AGENTS.md` §3.

**Stati di una decisione:** `requisito` (fissato dall'utente) · `confermata` (approvata) ·
`proposta` (in attesa di approvazione) · `superata` (sostituita, vedi voce indicata).

---

## 1. Requisiti di base

Fissati dall'utente il 2026-11-11.

| ID | Requisito |
|---|---|
| R-01 | Il sistema deriva da una versione **stabile** di Debian. |
| R-02 | Debian ridotta all'essenziale: nessun pacchetto superfluo, sistema pulito e leggero. |
| R-03 | **Wayland** per video e dispositivi di input. |
| R-04 | Mantenere il supporto all'hardware moderno principale (audio, Bluetooth, Wi‑Fi, GPU, ecc.) nel kernel e nei firmware. |
| R-05 | Architetture: **ARM mobile** (smartphone, tablet) e **desktop Intel/AMD**. |
| R-06 | Interfaccia grafica realizzata con la versione stabile di **WebKitGTK**. |
| R-07 | Ogni applicazione (incluse shell e pannelli) ha uno **script JavaScript principale** che può aprire finestre associate al proprio processo, in stile Electron ma basato su WebKitGTK. |
| R-08 | Rendering e animazioni gestiti interamente dal motore WebKit. |
| R-09 | Ogni applicazione è un processo che può avere sottoprocessi. |
| R-10 | Tutte le modali di sistema sono sostituite da modali HTML + JS + CSS predefinite. |
| R-11 | Ogni applicazione dichiara nel proprio `package.json` nome, metadati e API native richieste, anche come livello di sicurezza aggiuntivo. |
| R-12 | Ogni applicazione dispone di API di sistema di base: filesystem, dispositivi, finestre, servizi di sistema. |
| R-13 | Un'applicazione può richiedere l'accesso root dal `package.json` e/o tramite API dedicate. |
| R-14 | Il sistema deve essere **sicuro**. |
| R-15 | Branch principale del repository: `main`. |

---

## 2. Registro delle decisioni

### D-001 — Debian 13 «Trixie» come base · `proposta`
- **Cosa:** partire dalla stable corrente, Debian 13, sui rami `main`, `contrib`,
  `non-free-firmware`, più `trixie-security` e `trixie-updates`.
- **Perché:** è la stable supportata più a lungo (sicurezza fino al 2028, LTS oltre) e
  include WebKitGTK per GTK 4 (API `webkitgtk-6.0`), che riceve aggiornamenti di sicurezza.
- **Alternative scartate:** testing/unstable (contraddice R-01).

### D-002 — Costruire per aggiunta, non per sottrazione · `proposta`
- **Cosa:** generare il sistema con `mmdebstrap --variant=minbase` (o `debos` per le
  immagini) e aggiungere un elenco esplicito di pacchetti, invece di installare Debian
  completa e poi rimuovere.
- **Perché:** è riproducibile, ogni pacchetto ha una motivazione (AGENTS.md §5.5) e non
  restano dipendenze orfane. `--no-install-recommends` attivo per default.
- **Alternative scartate:** installazione standard + rimozione (fragile, lascia residui).

### D-003 — Kernel e firmware Debian completi · `proposta`
- **Cosa:** usare `linux-image-amd64` / `linux-image-arm64` con tutti i moduli, più
  `firmware-linux-free`, `firmware-misc-nonfree`, `firmware-sof-signed` (audio Intel),
  `firmware-iwlwifi`, `firmware-realtek`, `firmware-atheros`, `firmware-brcm80211`,
  `firmware-amd-graphics`, `intel-microcode`, `amd64-microcode`; stack audio
  PipeWire + WirePlumber; Bluetooth BlueZ.
- **Perché:** R-04. Ridurre i pacchetti utente non deve ridurre il supporto hardware; i
  moduli kernel non caricati non costano a runtime.
- **Da verificare:** elenco firmware definitivo per i dispositivi ARM scelti.

### D-004 — Due livelli di supporto ARM · `proposta`
- **Cosa:** ARM64 generico (UEFI/device tree, es. SBC, macchine virtuali) col kernel
  Debian; smartphone e tablet solo su un elenco di dispositivi supportati esplicitamente.
- **Perché:** la maggior parte degli smartphone non avvia un kernel Debian standard;
  servono kernel e firmware specifici per dispositivo (come fa postmarketOS/Mobian).
  Promettere «tutti gli ARM» non è realistico.

### D-005 — Sicurezza: broker dei permessi e sandbox per app · `proposta`
- **Cosa:**
  - un demone di sistema (*broker*) è l'unico a esporre API native; le app comunicano con
    esso tramite IPC autenticato (socket Unix, identità del processo verificata con
    `SO_PEERCRED`);
  - ogni app gira in una sandbox (`bubblewrap` + filtro `seccomp`), con filesystem,
    rete e dispositivi negati per default;
  - i permessi dichiarati in `package.json` sono un **tetto massimo**: il broker li
    concede solo dopo installazione/approvazione dell'utente;
  - il root (R-13) non concede mai una shell root all'app: il broker esegue operazioni
    privilegiate specifiche per suo conto, dopo conferma con modale di sistema, e le
    registra nel log di audit.
- **Perché:** R-13 e R-14 sono in tensione; un'app con root pieno annullerebbe ogni altra
  protezione. La mediazione mantiene la funzionalità con un rischio controllato.

### D-006 — Modali di sistema tramite portali · `proposta`
- **Cosa:** implementare un backend `xdg-desktop-portal` e un agente polkit propri che
  mostrano le richieste (selezione file, permessi, password, autenticazione) come modali
  HTML della shell.
- **Perché:** R-10. È il punto in cui GTK e i servizi di sistema chiedono già
  un'interazione; sostituirlo lì copre anche il software non scritto per project-os.

*Le decisioni su compositore/gestione finestre e runtime JavaScript sono aperte:
vedi `ROADMAP.md` → Decisioni aperte.*

---

## 3. Stile grafico

*Da definire nella Fase 4.* Annotare qui: palette, tipografia, spaziature, raggi,
ombre, durate e curve delle animazioni, icone, comportamento chiaro/scuro e adattivo
(desktop ↔ mobile).

---

## 4. Struttura del codice (proposta)

```
project-os/
├── AGENTS.md  MEMORY.md  ROADMAP.md
├── build/        # ricette dell'immagine (mmdebstrap/debos), elenchi pacchetti per arch
│   ├── packages/ # un file per gruppo, ogni pacchetto con commento sul perché
│   └── overlays/ # file di configurazione copiati nell'immagine
├── runtime/      # runtime delle app: avvio script principale, finestre WebKitGTK
├── broker/       # demone dei permessi e API native
├── portal/       # backend xdg-desktop-portal e agente polkit (modali HTML)
├── shell/        # shell di sistema: pannelli, launcher, notifiche, modali
├── apps/         # applicazioni di sistema (impostazioni, file, terminale…)
├── sdk/          # tipi e libreria JS delle API di sistema per le app
└── docs/         # specifiche (formato package.json, API, modello permessi)
```

---

## 5. Convenzioni sintattiche

*Da completare quando si scelgono linguaggi e strumenti.* Già fissate (AGENTS.md):
documentazione e commit in italiano, identificatori in inglese, Conventional Commits.

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
| ~~R-01~~ | ~~Il sistema deriva da una versione stabile di Debian.~~ *Superato da R-20.* |
| R-02 | Sistema ridotto all'essenziale: nessun pacchetto superfluo, pulito e leggero. *(Riformulato senza Debian dopo R-20.)* |
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
| R-16 | **Mobile:** installazione tramite la recovery del dispositivo; il setup prosegue al primo avvio con interfaccia HTML. |
| R-17 | **Desktop:** installazione con un'applicazione wizard in stile Windows/Debian, con rendering HTML come tutte le altre app. |
| R-18 | **Desktop:** menu di avvio con voci centrate e logo del sistema (inizialmente un logo generico), che consenta il dual boot con Windows o altri sistemi. |
| R-19 | Nessuna modalità live per ora. |

| R-20 | **Niente distribuzione di partenza:** si parte da Linux (kernel) e si costruisce sopra ogni pacchetto. |
| R-21 | **Un solo sistema, due basi:** con poche modifiche si ottengono la versione mobile su base Android (kernel e driver del produttore) e quella desktop; entrambe su Linux. |
| R-22 | Componenti nativi in **Rust**. |
| R-23 | Primo dispositivo mobile: **Google Pixel** dell'utente. Da non trascurare: vecchi modelli **Oppo** e **Samsung** in suo possesso. |
| R-24 | **Setup differenziato:** su desktop comprende formattazione del disco, layout tastiera e configurazione di base; su mobile chiede altri dati o parte da step successivi (il sistema è già installato dalla recovery). |

*R-16…R-19 aggiunti dall'utente il 2026-11-11. R-20…R-24 aggiunti lo stesso giorno: cambio
di approccio, da Debian a sistema costruito da zero.*

---

## 2. Registro delle decisioni

### D-001 — Debian 13 «Trixie» come base · `superata` da D-012 (R-20)
- **Cosa:** partire dalla stable corrente, Debian 13, sui rami `main`, `contrib`,
  `non-free-firmware`, più `trixie-security` e `trixie-updates`.
- **Perché:** è la stable supportata più a lungo (sicurezza fino al 2028, LTS oltre) e
  include WebKitGTK per GTK 4 (API `webkitgtk-6.0`), che riceve aggiornamenti di sicurezza.
- **Alternative scartate:** testing/unstable (contraddice R-01).

### D-002 — Costruire per aggiunta, non per sottrazione · `superata` da D-012 (il principio resta: ogni componente entra solo se motivato)
- **Cosa:** generare il sistema con `mmdebstrap --variant=minbase` (o `debos` per le
  immagini) e aggiungere un elenco esplicito di pacchetti, invece di installare Debian
  completa e poi rimuovere.
- **Perché:** è riproducibile, ogni pacchetto ha una motivazione (AGENTS.md §5.5) e non
  restano dipendenze orfane. `--no-install-recommends` attivo per default.
- **Alternative scartate:** installazione standard + rimozione (fragile, lascia residui).

### D-003 — Kernel e firmware Debian completi · `superata` da D-014 (resta valido l'obiettivo R-04)
- **Cosa:** usare `linux-image-amd64` / `linux-image-arm64` con tutti i moduli, più
  `firmware-linux-free`, `firmware-misc-nonfree`, `firmware-sof-signed` (audio Intel),
  `firmware-iwlwifi`, `firmware-realtek`, `firmware-atheros`, `firmware-brcm80211`,
  `firmware-amd-graphics`, `intel-microcode`, `amd64-microcode`; stack audio
  PipeWire + WirePlumber; Bluetooth BlueZ.
- **Perché:** R-04. Ridurre i pacchetti utente non deve ridurre il supporto hardware; i
  moduli kernel non caricati non costano a runtime.
- **Da verificare:** elenco firmware definitivo per i dispositivi ARM scelti.

### D-004 — Due livelli di supporto ARM · `superata` da D-014 (i vincoli sotto restano validi)
- **Cosa:** ARM64 generico (UEFI/device tree, es. SBC, macchine virtuali) col kernel
  Debian; smartphone e tablet solo su un elenco di modelli supportati esplicitamente.
- **Obiettivo dell'utente (2026-11-11):** gli smartphone più diffusi sul mercato —
  Google Pixel, Samsung, Xiaomi, Oppo.
- **Vincoli noti:**
  - la maggior parte di questi telefoni non avvia un kernel Debian standard: serve un
    kernel per dispositivo, oppure il kernel Android del produttore tramite
    Halium/libhybris (approccio di Droidian, anch'esso basato su Debian);
  - con Halium la GPU passa dai driver Android: WebKitGTK va verificato su quel percorso;
  - lo sblocco del bootloader varia: in genere possibile sui Pixel non vincolati
    all'operatore, limitato o assente su vari modelli Samsung, Xiaomi e Oppo.
- **Perché:** promettere «tutti gli ARM» non è realistico; si sceglie modello per modello.

### D-005 — Sicurezza: broker dei permessi e sandbox per app · `confermata` (2026-11-11)
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

### D-007 — Compositore Wayland proprio · `confermata` (2026-11-11)
- **Cosa:** compositore minimale scritto per project-os (base wlroots o Smithay, vedi
  DA-07). Ogni finestra di app è una superficie Wayland separata; la shell web disegna
  pannelli e decorazioni via *layer-shell* e decide disposizione e animazioni delle
  finestre tramite un protocollo privato compositore ↔ shell.
- **Perché:** R-08 e R-14: animazioni sotto il controllo della shell web e finestre
  isolate per processo.
- **Alternative scartate:** kiosk con WebView interne (isolamento debole), compositore
  esistente (poco controllo sulle animazioni).

### D-008 — Script principale eseguito su JavaScriptCore · `confermata` (2026-11-11)
- **Cosa:** lo script principale di ogni app gira in un contesto JavaScriptCore (il
  motore JS di WebKit, API GLib `libjavascriptcoregtk-6.0`) ospitato da un processo
  nativo di project-os, che espone solo le API di sistema concesse e crea le finestre
  WebKitGTK dell'app.
- **Perché:** stesso motore JS in script principale e finestre; nessuna API esposta per
  default (al contrario di Node.js o GJS, che danno accesso a file e processi), quindi il
  modello permessi parte da zero.
- **Conseguenza:** niente moduli Node/npm nativi; le librerie JS pure restano utilizzabili
  tramite bundling.
- **Alternative scartate:** GJS, Node.js.

### D-009 — Menu di avvio desktop: GRUB 2 con tema proprio · `proposta`
- **Cosa:** GRUB 2 (UEFI) con un tema project-os: menu centrato, logo in alto, sfondo e
  font propri. Rilevamento di Windows e altri sistemi con `os-prober` (da riattivare con
  `GRUB_DISABLE_OS_PROBER=false`).
- **Secure Boot (rivisto dopo R-20):** senza Debian non c'è più uno `shim` già firmato da
  Microsoft. Fase iniziale: chiavi project-os registrate dall'utente (MOK) durante
  l'installazione; ottenere uno shim firmato da Microsoft è un obiettivo a lungo termine.
- **Logo:** segnaposto generico in SVG, esportato in PNG per il tema, finché non si
  definisce il marchio.
- **Perché:** R-18. GRUB supporta temi grafici, multiboot e Secure Boot.
- **Alternative scartate:** systemd-boot (nessun tema grafico); rEFInd (da rivalutare se
  GRUB risulta scomodo da integrare senza Debian).

### D-010 — Supporto di installazione desktop · `proposta`
- **Cosa:** un'immagine USB di installazione che avvia solo il minimo indispensabile
  (kernel, compositore, runtime, broker) e apre direttamente il wizard di installazione;
  nessuna sessione utente né app.
- **Perché:** R-17 e R-19. Il wizard HTML ha bisogno del motore di rendering già in
  esecuzione, quindi l'ambiente di installazione deve avviarsi; resta però un ambiente
  chiuso dedicato all'installazione, non un sistema live usabile.
- **Il wizard gestisce:** lingua, tastiera, disco e partizioni (anche accanto a Windows
  esistente, senza toccarne l'avvio), cifratura del disco, utente, installazione di GRUB.

### D-011 — Installazione mobile da recovery · `proposta`
- **Cosa:** per ogni modello supportato, un pacchetto installabile dalla recovery
  (es. zip flashabile da recovery custom), più le immagini fastboot dove servono.
  Al primo avvio parte l'app di setup HTML (vedi D-017 per i passi).
- **Perché:** R-16. È il metodo standard sui telefoni Android con bootloader sbloccato.

### D-012 — Sistema costruito da sorgenti con Yocto/OpenEmbedded · `confermata` (2026-11-11)
- **Cosa:** ogni componente (toolchain, libc, librerie, WebKitGTK, kernel) è compilato da
  sorgenti con Yocto/OpenEmbedded, sul ramo LTS corrente. Il nostro codice sta in layer
  propri: `meta-project-os` (spazio utente comune, uguale per tutte le piattaforme),
  `meta-project-os-desktop` e `meta-project-os-mobile` (strato hardware, D-014), più un
  layer per ogni dispositivo mobile.
- **Alternative scartate:** Buildroot (fatica con WebKitGTK e con molti dispositivi),
  strumento proprio in Rust (tutto da scrivere e mantenere).
- **Perché:** R-20. Controllo completo su cosa entra nel sistema e build riproducibili.
- **Conseguenza importante:** la **sicurezza degli aggiornamenti** diventa responsabilità
  del progetto. Senza una distribuzione a monte, ogni falla nota (WebKit in particolare,
  che ne ha molte ogni anno) va seguita e corretta da noi. Serve un processo di
  monitoraggio delle vulnerabilità fin dalla Fase 2.

### D-018 — Sistema immutabile con aggiornamenti A/B · `confermata` (2026-11-11)
- **Cosa:** partizione di sistema in sola lettura, verificata con dm-verity e firmata;
  due slot (A/B): l'aggiornamento si scrive sullo slot inattivo e, se l'avvio fallisce,
  si torna automaticamente al precedente. Dati utente e app su partizione separata
  (cifrata). Le app si installano come pacchetti firmati (DA-05), fuori dall'immagine.
  Strumento candidato: RAUC (integrato in Yocto).
- **Perché:** R-14 (il sistema non è alterabile a runtime) e aggiornamenti atomici uguali
  su desktop e mobile, come Android e ChromeOS. Anche il «root» mediato (D-005) non può
  modificare la partizione di sistema.
- **Alternative scartate:** gestore di pacchetti tradizionale (meno sicuro e prevedibile).

### D-013 — Componenti nativi in Rust · `confermata` (2026-11-11)
- **Cosa:** compositore (su Smithay), host del runtime JavaScriptCore, broker, demoni di
  sistema e strumenti di build propri in Rust. Le librerie C esterne (WebKitGTK, GTK,
  Mesa) si usano tramite binding.
- **Perché:** R-22; sicurezza della memoria nei componenti più esposti (R-14).
- **Alternative scartate:** C con wlroots.

### D-014 — Spazio utente unico, strato hardware per piattaforma · `proposta`
- **Cosa:** tutto ciò che sta sopra il kernel (libc, compositore, runtime, shell, app) è
  identico su desktop e mobile. Cambia solo lo **strato hardware**:
  - **desktop (amd64):** kernel Linux mainline, Mesa per la GPU, firmware linux-firmware;
  - **mobile (arm64, base Android):** kernel e firmware del produttore del telefono,
    driver Android (GPU, modem, sensori, fotocamera) raggiunti tramite Halium/libhybris;
    dove un modello ha buon supporto mainline, si può usare quello.
- **Perché:** R-21. Le differenze restano confinate in una cartella per piattaforma e
  dispositivo; il resto si compila due volte (amd64, arm64) senza modifiche.
- **Vincoli:** libhybris richiede glibc (D-015); WebKitGTK deve funzionare con EGL via
  libhybris (da verificare presto, è il rischio tecnico principale lato mobile); lo
  sblocco del bootloader varia per modello (vedi D-004).

### D-015 — Libreria C: glibc · `proposta`
- **Perché:** necessaria per libhybris (driver Android, D-014) e la più collaudata con
  WebKitGTK e GTK.
- **Alternative scartate:** musl (incompatibile con libhybris, meno testata con WebKit).

### D-016 — Init: systemd · `proposta`
- **Cosa:** systemd come init, con udev, logind e journald.
- **Perché:** gestione di sessioni e dispositivi (logind/udev) serve al compositore;
  sandboxing dei servizi integrato; supporto Halium già esistente.
- **Alternative:** init leggeri (s6, dinit) o init proprio in Rust: meno dipendenze, ma
  udev/sessioni/seat da ricostruire.

### D-017 — Setup differenziato desktop / mobile · `proposta`
- **Cosa:** un'unica app di setup HTML con passi attivati in base alla piattaforma (R-24).
  - **Desktop (dall'immagine USB, D-010):** lingua → layout tastiera → fuso orario →
    rete (facoltativa) → disco: partizionamento/formattazione, anche accanto a
    Windows → cifratura disco → utente e password → riepilogo e installazione
    (con GRUB e rilevamento altri sistemi) → riavvio → primo avvio: preferenze.
  - **Mobile (primo avvio dopo la recovery):** lingua → rete Wi‑Fi/SIM (PIN) →
    fuso orario automatico → utente e codice di sblocco (PIN/password, eventuale
    impronta) → permessi di sistema (posizione, notifiche) → preferenze. Nessuno
    step di disco o tastiera fisica.
- **Perché:** su mobile il sistema è già scritto dalla recovery; su desktop il setup è
  anche l'installazione.

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
├── layers/       # layer Yocto (D-012)
│   ├── meta-project-os/          # spazio utente comune: ricette, immagini, tema GRUB
│   ├── meta-project-os-desktop/  # strato hardware amd64: kernel mainline, Mesa, firmware
│   ├── meta-project-os-mobile/   # strato hardware arm64 comune: Halium/libhybris
│   └── meta-device-<nome>/       # un layer per telefono: kernel, firmware, pacchetto
│                                 # recovery (pixel-…, samsung-…, oppo-…)
├── build/        # configurazione della build Yocto (versioni dei layer esterni, local.conf)
├── branding/     # logo (segnaposto) e risorse grafiche condivise
├── runtime/      # runtime delle app: avvio script principale, finestre WebKitGTK
├── broker/       # demone dei permessi e API native
├── portal/       # backend xdg-desktop-portal e agente polkit (modali HTML)
├── shell/        # shell di sistema: pannelli, launcher, notifiche, modali
├── apps/         # applicazioni di sistema (impostazioni, file, terminale,
│                 # installer desktop, setup al primo avvio…)
├── sdk/          # tipi e libreria JS delle API di sistema per le app
└── docs/         # specifiche (formato package.json, API, modello permessi)
```

---

## 5. Convenzioni sintattiche

*Da completare quando si scelgono linguaggi e strumenti.* Già fissate (AGENTS.md):
documentazione e commit in italiano, identificatori in inglese, Conventional Commits.

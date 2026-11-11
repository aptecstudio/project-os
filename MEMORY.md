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

| R-25 | **Retrocompatibilità a tutti i livelli e in tutti i contesti del progetto**: hardware, avvio, formati, API, dati, aggiornamenti. |
| R-26 | **Desktop:** avvio sia da UEFI sia da BIOS tradizionale, con la stessa immagine. |
| R-27 | **Cifratura senza TPM:** la partizione dati deve funzionare anche sui PC più datati senza chip TPM. |
| R-28 | **Processori desktop:** tutti i processori x86 a 64 bit (istruzioni x86-64 di base). |

*R-16…R-19 aggiunti dall'utente il 2026-11-11. R-20…R-24 aggiunti lo stesso giorno: cambio
di approccio, da Debian a sistema costruito da zero. R-25…R-28 aggiunti lo stesso giorno.*

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

### D-006 — Modali di sistema tramite portali · `confermata` (2026-11-11)
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

### D-009 — Menu di avvio desktop: GRUB 2 con tema proprio · `confermata` (2026-11-11)
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

### D-010 — Supporto di installazione desktop · `confermata` (2026-11-11)
- **Cosa:** un'immagine USB di installazione che avvia solo il minimo indispensabile
  (kernel, compositore, runtime, broker) e apre direttamente il wizard di installazione;
  nessuna sessione utente né app.
- **Perché:** R-17 e R-19. Il wizard HTML ha bisogno del motore di rendering già in
  esecuzione, quindi l'ambiente di installazione deve avviarsi; resta però un ambiente
  chiuso dedicato all'installazione, non un sistema live usabile.
- **Il wizard gestisce:** lingua, tastiera, disco e partizioni (anche accanto a Windows
  esistente, senza toccarne l'avvio), cifratura del disco, utente, installazione di GRUB.

### D-011 — Installazione mobile da recovery · `confermata` (2026-11-11)
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
  monitoraggio delle vulnerabilità fin dalla Fase 1. Per WebKitGTK vedi D-019.

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

### D-019 — Fork di WebKitGTK mantenuto dal progetto · `confermata` (2026-11-11)
- **Cosa (deciso dall'utente):** WebKitGTK si compila da un fork del progetto, su cui
  correggiamo noi le vulnerabilità.
- **Modalità (proposta):** fork *allineato*, non divergente:
  - il fork segue il ramo stabile ufficiale di WebKitGTK (`webkitglib/<versione>`) e
    riceve ogni rilascio di sicurezza ufficiale appena esce (avvisi WSA);
  - le nostre modifiche stanno in commit separati e documentati, riapplicati sopra ogni
    nuova versione stabile;
  - correzioni proprie: per vulnerabilità note senza correzione ufficiale, per
    l'irrobustimento (funzioni disattivate che non servono, opzioni di compilazione più
    restrittive) e per l'integrazione con il broker e il runtime JSC;
  - ogni correzione nostra, quando è di interesse generale, va proposta a monte.
- **Perché:** un fork che diverge perde le correzioni ufficiali, che sono la gran parte
  di quelle disponibili (WebKit è un progetto da milioni di righe con un team di
  sicurezza dedicato); allineato, aggiunge un livello nostro senza rinunciarvi.
- **In Yocto:** la ricetta `webkitgtk` di `meta-project-os` punta al fork e al tag
  rilasciato da noi.
- **Repository:** `aptecstudio/WebKit`, fork di `WebKit/WebKit` con tutti i rami.
  - `main`: copia dell'ufficiale, senza nostre modifiche;
  - `project-os/<versione>`: nostro ramo di lavoro, creato dal ramo stabile
    `webkitglib/<versione>`; a ogni nuova stabile si crea il ramo successivo e si
    riapplicano le nostre patch;
  - primo ramo: `project-os/2.54`, da `webkitglib/2.54` (commit `2b614de`, creato il
    2026-11-11; ultimo rilascio ufficiale a quella data: 2.54.2).

### D-024 — Configurazione della build Yocto · `confermata` (2026-11-11)
- **Versioni fissate:** Yocto 6.0 «Wrynose» (LTS), OpenEmbedded-Core `2285da0`, bitbake
  2.18 `6e260eb`. Si aggiornano solo con un commit dedicato.
- **Strumento:** [kas](https://kas.readthedocs.io): file YAML in `kas/` che descrivono
  repository, versioni, layer, macchina e distribuzione; la build si ricrea con un solo
  comando (`kas build kas/desktop-amd64.yml`). `kas/dev.yml` aggiunge le impostazioni di
  sviluppo (root senza password, prova in QEMU): **mai** per immagini rilasciate.
  Alternativa scartata: `bitbake-setup` (nuovo in Yocto 6.0, ancora poco documentato).
- **Sorgenti senza poky:** OpenEmbedded-Core e bitbake direttamente, con la nostra
  distribuzione `project-os` (`layers/meta-project-os/conf/distro/project-os.conf`).
- **Macchina `project-os-amd64`:** istruzioni x86-64-v2 (`corei7-64`), per funzionare
  sui PC dal 2008 in poi; x86-64-v3 scartato perché escluderebbe i PC precedenti al 2013
  circa. *Questa parte è superata da D-027 (x86-64 di base).* Kernel `linux-yocto` 6.18 LTS con la configurazione di riferimento per PC a
  64 bit (`common-pc-64`), avvio UEFI con GRUB.
- **Funzioni della distribuzione escluse** (motivi nel file della distribuzione): x11,
  pulseaudio, nfs, zeroconf, 3g, nfc, ptest, multiarch, debuginfod.
- **Verifica fatta:** bitbake legge configurazione, immagine e kernel senza errori né
  avvisi (controllo di sola lettura, nessuna compilazione). Da verificare alla prima
  build: download, compilazione, schema di partizioni `wic`, sintassi dei file kas.

### D-025 — Kernel e firmware per l'hardware desktop · `confermata` (2026-11-11)
- **Frammenti di configurazione** in
  `layers/meta-project-os-desktop/recipes-kernel/linux/files/`, uno per area: dischi e
  file system, grafica, audio, Bluetooth, Wi‑Fi, rete cablata, input e piattaforma.
  147 opzioni, tutte verificate contro i Kconfig di Linux 6.18.
- **Integrati (=y) solo i driver per l'avvio** (NVMe, SATA, ext4, FAT, framebuffer UEFI,
  tastiera, USB 3): non c'è initramfs, quindi il disco di sistema deve essere leggibile
  prima di caricare moduli. Tutto il resto è modulo, caricato solo se l'hardware c'è.
- **Grafica:** Intel (i915, xe), AMD (amdgpu, anche le prime GCN, e radeon), NVIDIA solo
  con il driver libero nouveau; driver per le macchine virtuali (QEMU, VirtualBox,
  VMware, Hyper‑V).
- **Firmware:** `packagegroup-project-os-desktop-hw`, 27 pacchetti di `linux-firmware`
  più il database delle frequenze Wi‑Fi; compressi con zstd.
- **Mancano, da scrivere come ricette proprie** (non sono in OpenEmbedded-Core):
  firmware audio Intel SOF (portatili Intel dalla 11ª generazione), microcode Intel.
  Il microcode va caricato all'avvio tramite initramfs per essere efficace: da decidere
  con lo schema di avvio (passo 4).
- **Strumento:** `tools/check-kernel-fragments.py` controlla che ogni opzione esista
  nella versione del kernel e che il valore sia ammesso dal tipo; ha già trovato un
  errore (`TG3` invece di `TIGON3`). Le dipendenze tra opzioni le verifica la build.
- **Verifiche fatte:** bitbake risolve il grafo delle dipendenze dell'immagine senza
  errori; firmware, regdb e frammenti entrano nella build. Da verificare alla prima
  build: compilazione del kernel e avvisi sulle dipendenze delle opzioni.
- **Correzione collegata:** l'immagine base ora include `MACHINE_EXTRA_RRECOMMENDS`;
  prima moduli e firmware della macchina sarebbero rimasti fuori.

### D-027 — Processori: x86-64 di base · `confermata` (2026-11-11)
- **Cosa:** `DEFAULTTUNE = "x86-64"`: tutti i processori a 64 bit (Athlon 64, Pentium 4
  a 64 bit, Core 2 e successivi). Supera la parte di D-024 su x86-64-v2.
- **Perché:** R-25, R-28. Costo accettato: prestazioni leggermente inferiori sui
  processori moderni.
- **Alternative scartate:** x86-64-v2 (esclude i PC prima del 2008 circa); 32 bit
  (WebKit su 32 bit è sempre meno supportato, costo troppo alto).

### D-026 — Partizioni A/B, avvio e partizione dati · `proposta` (in revisione sul ramo `build/ab-partitions`)
- **Schema del disco (GPT)**, in `files/wic/project-os-ab.wks`:
  | # | Nome | Dimensione | Contenuto |
  |---|---|---|---|
  | 1 | `bios_grub` | 1 MiB | GRUB per l'avvio da BIOS (passo 4e) |
  | 2 | `esp` | 512 MiB | partizione EFI: GRUB, menu, tema, stato degli slot (`grubenv`); montata su `/efi`, accesso solo root |
  | 3 | `root_a` | 4 GiB | sistema, copia A, sola lettura, kernel incluso |
  | 4 | `root_b` | 4 GiB | sistema, copia B, scritta dagli aggiornamenti |
  | 5 | `data` | resto | dati, creata al primo avvio, cifrata, montata su `/var` (`/home` → `/var/home`) |
- **Scelta dello slot:** GRUB (`files/wic/project-os-grub.cfg`) avvia il primo slot di
  `ORDER` valido e senza tentativi in sospeso, e segna il tentativo; `rauc-mark-good`
  lo conferma a sistema avviato. Se l'avvio fallisce, al riavvio passa all'altro slot.
  Nel menu lo slot attivo si chiama «project-os», l'altro «versione precedente».
- **Aggiornamenti:** RAUC (`recipes-core/rauc/files/system.conf`); bundle firmati in
  formato *verity*, compressi zstd (`project-os-bundle`). Il certificato della CA va
  nell'immagine; chiavi fuori dal repository (`PROJECT_OS_KEYS`, `tools/gen-dev-keys.sh`).
- **Partizione dati:** creata da `systemd-repart` sullo spazio libero, LUKS2. Sblocco
  con `crypttab`: funziona senza TPM (R-27). In questa fase la chiave è **vuota**
  (segnaposto, dati non protetti): il setup registrerà password e chiave di recupero,
  e il TPM come metodo in più dove c'è (passo 4d e Fase 8).
- **Kernel:** dm-crypt, dm-verity, AES-XTS, SHA-256, loop e squashfs zstd integrati
  (`ab-crypt.cfg`).
- **Decisioni collegate:** `systemd.gpt_auto=0` (le partizioni si montano solo come
  descritto, mai per tipo); `/home` sulla partizione dati.
- **Limiti noti, da risolvere nei sotto-passi:**
  - kernel letto da GRUB dentro lo slot senza verifica: con erofs + dm-verity e
    kernel unificato (UKI) firmato al passo 4c;
  - `/etc` in sola lettura: macchina, rete e utenti non persistono fino al passo 4c
    (sovrapposizione di `/etc` sulla partizione dati, dall'initramfs);
  - avvio da BIOS: OpenEmbedded non installa GRUB per BIOS nelle immagini; lo
    scriviamo al passo 4e;
  - pacchetti che mettono file in `/var` al momento della build: coperti dalla
    partizione dati montata sopra; da verificare alla prima build.
- **Verifiche fatte:** bitbake risolve tutte le dipendenze di immagine e bundle senza
  errori né avvisi; 159 opzioni del kernel verificate sul 6.18; lo script delle chiavi
  produce una catena di certificati valida. Da verificare alla prima build: sintassi di
  `grub.cfg`, moduli GRUB, creazione delle partizioni, avvio e aggiornamento A/B.

### D-013 — Componenti nativi in Rust · `confermata` (2026-11-11)
- **Cosa:** compositore (su Smithay), host del runtime JavaScriptCore, broker, demoni di
  sistema e strumenti di build propri in Rust. Le librerie C esterne (WebKitGTK, GTK,
  Mesa) si usano tramite binding.
- **Perché:** R-22; sicurezza della memoria nei componenti più esposti (R-14).
- **Alternative scartate:** C con wlroots.

### D-014 — Spazio utente unico, strato hardware per piattaforma · `confermata` (2026-11-11)
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

### D-015 — Libreria C: glibc · `confermata` (2026-11-11)
- **Perché:** necessaria per libhybris (driver Android, D-014) e la più collaudata con
  WebKitGTK e GTK.
- **Alternative scartate:** musl (incompatibile con libhybris, meno testata con WebKit).

### D-016 — Init: systemd · `confermata` (2026-11-11)
- **Cosa:** systemd come init, con udev, logind e journald.
- **Perché:** gestione di sessioni e dispositivi (logind/udev) serve al compositore;
  sandboxing dei servizi integrato; supporto Halium già esistente.
- **Alternative:** init leggeri (s6, dinit) o init proprio in Rust: meno dipendenze, ma
  udev/sessioni/seat da ricostruire.

### D-017 — Setup differenziato desktop / mobile · `confermata` (2026-11-11)
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

### D-020 — Licenza GPL-3.0 · `confermata` (2026-11-11)
- **Cosa:** il codice di project-os è rilasciato con licenza GNU GPL v3 (file `LICENSE`).
  Il fork di WebKit mantiene le licenze originali di WebKit (LGPL/BSD).
- **Perché:** scelta dell'utente; chi modifica e distribuisce il sistema deve pubblicarne
  il codice, evitando fork chiusi.

### D-021 — Fasi in sequenza, non in parallelo · `confermata` (2026-11-11)
- **Cosa:** si lavora su una fase alla volta, nell'ordine della roadmap.
- **Perché:** richiesta dell'utente.

### D-022 — Sviluppo dal basso verso l'alto · `confermata` (2026-11-11)
- **Cosa:** ordine delle fasi: sistema base (Yocto, kernel, avvio) → stack grafico →
  broker → runtime delle app → shell → app di sistema → mobile → installazione.
- **Perché:** scelta dell'utente: ogni livello si costruisce e si prova sul sistema reale
  sotto di esso.
- **Costo accettato:** il modello applicativo (la parte più nuova) si verifica più tardi;
  le build Yocto richiedono ore e una macchina di build robusta (DA-11).
- **Alternativa scartata:** partire dal prototipo del runtime su una distribuzione
  esistente.

### D-023 — Logo segnaposto e tema GRUB · `confermata` (2026-11-11)
- **Cosa:**
  - logo generico in `branding/logo/project-os-logo.svg`, **monocromo bianco** (anello e
    punto centrale) su fondo scuro, nello stile dell'avvio di elementary OS, come chiesto
    dall'utente; resta un **segnaposto**, il marchio definitivo è da decidere;
  - tema GRUB in `branding/grub-theme/`: logo e nome in alto, voci centrate larghe
    520 px, voce scelta evidenziata da un riquadro chiaro semitrasparente, conto alla
    rovescia e aiuto tasti in basso;
  - tutte le immagini si rigenerano con `branding/tools/render.py` (SVG → PNG con
    `rsvg-convert`, sfondo e riquadri con Pillow/NumPy); `branding/previews/` contiene
    un'anteprima approssimata, che non va nell'immagine.
- **Font:** Inter (licenza OFL‑1.1). I file `.pf2` per GRUB non stanno nel repository:
  la ricetta Yocto scaricherà Inter dal progetto ufficiale e li genererà con
  `grub-mkfont` (Regular 14 e 18, Medium 18, SemiBold 28).
- **Sfondo:** retinatura ordinata al posto del rumore, per evitare le bande di colore con
  un PNG leggero (224 KB contro 1,6 MB).
- **Testi del menu:** in italiano per ora; la localizzazione del menu di avvio è da
  decidere più avanti.
- **Perché:** R-18; il tema vive in `branding/` come sorgente unico, e la ricetta lo
  copierà nell'immagine.

---

## 3. Stile grafico

*Da definire nella Fase 5.* Annotare qui: palette, tipografia, spaziature, raggi,
ombre, durate e curve delle animazioni, icone, comportamento chiaro/scuro e adattivo
(desktop ↔ mobile).

**Punto di partenza (dal tema di avvio, D-023; provvisorio):**
- Fondo `#0B0D12`, alone `#2A2F6B`. Logo e marchio: **monocromo bianco** `#FFFFFF`.
- Testo principale `#F2F4F8`, secondario `#9AA3B2`, attenuato `#7D8597`, minimo `#596173`.
- Font: Inter. Raggio degli elementi selezionabili: 10 px.

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
├── kas/          # configurazione della build Yocto (D-024): versioni, layer, macchina
├── tools/        # strumenti di sviluppo (es. verifica dei frammenti del kernel)
├── build/        # uscite della build (non versionate)
├── sources/      # repository esterni scaricati da kas (non versionati)
├── branding/     # logo (segnaposto), tema GRUB, script di generazione, anteprime
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

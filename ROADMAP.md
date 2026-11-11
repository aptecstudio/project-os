# ROADMAP.md — Stato del progetto

Passi eseguiti e passi da eseguire, per avere uno stato globale e per fase.
Regole di aggiornamento in `AGENTS.md` §3.

**Stati di fase:** `proposta` → `approvata` → `in corso` → `completata` (oppure `sospesa`).
Si lavora solo su fasi `approvata` o `in corso`.

## Stato globale

Ordine **dal basso verso l'alto** (D-022): prima il sistema, poi ciò che ci gira sopra.
Le fasi si eseguono **una alla volta**, in ordine (D-021).

| Fase | Titolo | Stato |
|---|---|---|
| 0 | Fondamenta e decisioni | `in corso` |
| 1 | Sistema base: Yocto, kernel, avvio | `in corso` |
| 2 | Stack grafico: WebKitGTK dal fork e compositore | `proposta` |
| 3 | Broker, permessi e sandbox | `proposta` |
| 4 | Runtime delle app (script JS e finestre) | `proposta` |
| 5 | Shell, stile grafico e modali di sistema | `proposta` |
| 6 | Applicazioni di sistema | `proposta` |
| 7 | Mobile arm64 su base Android (Pixel, poi Oppo e Samsung) | `proposta` |
| 8 | Installazione, setup e aggiornamenti | `proposta` |
| 9 | Ecosistema: interoperabilità tra dispositivi | `proposta` |

**Prossimo passo:** l'utente prepara la macchina di build e prova l'immagine in QEMU
(`docs/sviluppo.md`) dal ramo `build/ab-partitions`; con l'esito si rivede il ramo e si
prosegue con 4c. Un passo alla volta, con conferma dell'utente.

---

## Decisioni aperte

Da risolvere con l'utente prima di avviare le fasi indicate. Una volta decise, si spostano
in `MEMORY.md` come voce `confermata`.

- [x] **DA-01 — Gestione finestre e compositore Wayland** → compositore proprio (D-007)
- [x] **DA-02 — Runtime dello script JavaScript principale** → JavaScriptCore (D-008)
- [ ] **DA-03 — Dispositivi mobili di riferimento** *(blocca Fase 7)*
  Primo: il Google Pixel dell'utente (modello esatto da indicare). Poi: i vecchi modelli
  Oppo e Samsung in suo possesso (modelli esatti da indicare). Per ognuno: bootloader
  sbloccabile? recovery custom disponibile?
- [x] **DA-04 — Modello dell'accesso root** → root mediato dal broker (D-005)
- [ ] **DA-05 — Formato di distribuzione delle app** *(blocca Fase 3)*
  Pacchetto proprio firmato (archivio con `package.json` + firma). L'opzione `.deb` è
  decaduta con R-20.
- [x] **DA-06a — Licenza** → GPL-3.0 (D-020)
- [ ] **DA-06b — Nome definitivo del sistema** *(non bloccante; per ora «project-os»)*
- [x] **DA-07 — Linguaggio dei componenti nativi** → Rust (D-013)
- [x] **DA-08 — Build system per il sistema da sorgenti** → Yocto/OpenEmbedded (D-012)
- [x] **DA-09 — Modello di aggiornamento del sistema** → immagine immutabile A/B (D-018)
- [x] **DA-10 — Aggiornare `AGENTS.md`** → autorizzato dall'utente il 2026-11-11, §1
  aggiornato (AGENTS.md v1.1)
- [ ] **DA-11 — Macchina di build** *(blocca le verifiche della Fase 1)*
  Yocto deve girare su una macchina dell'utente (VM o fisica): almeno 16 GB di RAM,
  250 GB di disco, molti core. Consigliato Ubuntu Server 24.04/26.04 LTS. Guida e script
  pronti (`docs/sviluppo.md`, `tools/setup-host.sh`); manca la macchina.
  *Soluzione provvisoria (D-034, proposta):* il portatile dell'utente, Debian 13
  (4 core, 7,4 GB di RAM, 42 GB liberi), con `kas/low-resources.yml`; basta per la
  Fase 1, non per WebKitGTK (Fase 2).
- [ ] **DA-12 — Ecosistema tra dispositivi** *(blocca la Fase 9; incide sulle Fasi 3, 4, 6)*
  Da decidere: (a) solo rete locale e Bluetooth, oppure anche un servizio di inoltro
  per i dispositivi lontani, e in quel caso ospitato da chi (dall'utente stesso, dal
  progetto); (b) scoperta in rete con mDNS (riattivando `zeroconf`) o con un annuncio
  proprio; (c) compatibilità con dispositivi che non usano project-os (es. protocollo
  KDE Connect per Android e Linux) oppure ecosistema riservato ai soli project-os;
  (d) ordine delle funzioni elencate in D-033.

---

## Fase 0 — Fondamenta e decisioni · `in corso`

- [x] Creare il repository `project-os` con branch principale `main`
- [x] Scrivere `AGENTS.md` (regole per agenti e persone)
- [x] Scrivere `MEMORY.md` (requisiti e decisioni)
- [x] Scrivere `ROADMAP.md`
- [x] Risolvere DA-01, DA-02, DA-04, DA-07
- [x] Ridisegnare l'approccio: da Debian a sistema da sorgenti (R-20…R-24)
- [x] Risolvere DA-08, DA-09, DA-10
- [x] Approvazione umana delle decisioni `proposta` in `MEMORY.md`
- [x] Licenza GPL-3.0, file `LICENSE`
- [x] Roadmap riordinata dal basso verso l'alto (D-022)
- [x] Avvio della Fase 1 approvato: si procede un passo alla volta, con conferma
      dell'utente a ogni passo
- [ ] Macchina di build pronta (DA-11)

## Fase 1 — Sistema base: Yocto, kernel, avvio · `in corso`

Obiettivo: un'immagine amd64 costruita da sorgenti che si avvia in QEMU/UEFI e su
hardware reale, con menu di avvio, partizioni A/B e supporto hardware completo.

**Primi passi (da approvare):**
- [x] 1. Configurare Yocto 6.0 «Wrynose» (LTS) con kas e creare i layer
      `meta-project-os` e `meta-project-os-desktop` (D-012, D-024); bitbake legge la
      configurazione senza errori. Da confermare alla prima build completa.
- [ ] 2. Immagine minima: kernel Linux 6.18 LTS, glibc, systemd; avvio in QEMU/UEFI
      fino a un terminale testuale (D-015, D-016)
  - [x] 2a. Ricetta dell'immagine, macchina e schema di partizioni scritti
  - [ ] 2b. Prima build e avvio in QEMU sulla macchina di build (DA-11)
- [x] 3. Configurazione del kernel per l'hardware moderno (audio, Bluetooth, Wi‑Fi,
      GPU Intel/AMD) e firmware da linux-firmware, ognuno con motivazione (R-04, D-025)
  - [ ] 3a. Ricetta firmware audio Intel SOF
  - [ ] 3b. Ricetta microcode Intel, caricamento anticipato del microcode (con il passo 4)
- [ ] 4. Schema partizioni A/B con dm-verity, partizione dati cifrata, RAUC (D-018, D-026)
  - [x] 4a. Schema del disco: ESP, slot A/B, spazio BIOS, partizione dati cifrata
        creata al primo avvio
  - [x] 4b. Scelta dello slot in GRUB e aggiornamenti RAUC firmati
  - [ ] 4c. Sistema erofs + dm-verity, initramfs systemd, kernel unificato (UKI) per
        slot, `/etc` persistente
  - [ ] 4d. Sblocco dei dati: password e chiave di recupero (senza TPM, R-27); TPM come
        metodo in più dove presente
  - [ ] 4e. Avvio da BIOS con GRUB nella stessa immagine (R-26)
- [ ] 5. Menu di avvio GRUB (D-009):
  - [x] 5a. Logo segnaposto e tema in `branding/`, con anteprima (D-023)
  - [ ] 5b. Ricetta Yocto: font `.pf2`, installazione del tema, `os-prober` per
        rilevare Windows e altri sistemi

**Passi successivi:**
- [x] Guida e script per la macchina di build e per l'emulatore (`docs/sviluppo.md`,
      `tools/setup-host.sh`, `tools/build.sh`, `tools/run-qemu.sh`, D-028)
- [ ] Prima build completa e avvio in QEMU sulla macchina dell'utente
  - [x] Prima build completa sul portatile (2026-11-11)
  - [ ] Avvio in QEMU con `tools/run-qemu.sh`
- [ ] Prova del dual boot in QEMU con Windows installato
- [ ] Servizi di base: rete, audio (PipeWire + WirePlumber), Bluetooth (BlueZ)
- [ ] Ogni componente con motivazione registrata (AGENTS.md §5.5)
- [ ] Processo di monitoraggio delle vulnerabilità dei componenti (D-012)
- [ ] Prova su hardware reale Intel e AMD (audio, Bluetooth, Wi‑Fi, GPU)
- [ ] Misura dimensione immagine e memoria a riposo; registrarle in `MEMORY.md`

## Fase 2 — Stack grafico: WebKitGTK dal fork e compositore · `proposta`

- [x] Fork `aptecstudio/WebKit` con ramo di lavoro `project-os/2.54` da
      `webkitglib/2.54` (D-019)
- [ ] Inventario delle vulnerabilità note sulla versione di partenza e verifica che
      siano tutte corrette nel fork
- [ ] Procedura documentata: integrazione di ogni rilascio di sicurezza ufficiale,
      riapplicazione delle nostre patch, nuovo tag del fork
- [ ] Irrobustimento: funzioni WebKit non necessarie disattivate, opzioni di
      compilazione restrittive
- [ ] Mesa e GTK 4 nell'immagine; ricetta WebKitGTK che compila dal fork
- [ ] Compositore Rust/Smithay minimo (D-007, D-013)
- [ ] Una finestra WebKitGTK a schermo nell'immagine, in QEMU e su hardware reale

## Fase 3 — Broker, permessi e sandbox · `proposta`

- [ ] Specifica del modello permessi (`docs/permissions.md`)
- [ ] Demone broker in Rust con IPC autenticato
- [ ] Sandbox per processo (namespace + seccomp), negazione per default
- [ ] API di base: filesystem, dispositivi, finestre, servizi di sistema (R-12)
- [ ] Richieste root mediate con conferma e log di audit (R-13)
- [ ] Formato pacchetto app firmato (DA-05)
- [ ] Test di sicurezza con client Rust: un processo non supera i permessi concessi
- [ ] Prevedere nel modello permessi le API dell'ecosistema (`devices.*`, D-033)

## Fase 4 — Runtime delle app · `proposta`

Obiettivo: il modello applicativo (R-07, R-09) sopra broker e compositore.

- [ ] Workspace Cargo con binding a WebKitGTK 6.0 e JavaScriptCore
- [ ] Specifica v0 del formato `package.json` (`docs/manifest.md`)
- [ ] Specifica delle API dell'oggetto `system` (`docs/api/`, D-029)
- [ ] Protocollo `app://` legato alla cartella dell'app, contesto WebKit separato per
      app, verifiche sui percorsi (D-031)
- [ ] `include()` e `includeAsync()`: ambito proprio, `exports`, cache, errore sui cicli
      con la catena (D-030); test dei casi limite (cicli sincroni e asincroni, errori a
      metà caricamento)
- [ ] Oggetto `system` esposto solo con gli spazi dichiarati e concessi (D-029)
- [ ] Host nativo che legge il manifest, crea un contesto JavaScriptCore isolato ed
      esegue lo script principale
- [ ] API `window`: apertura, chiusura e comunicazione con finestre WebKitGTK legate al
      processo; canale messaggi script principale ↔ finestre (stile Electron)
- [ ] Sottoprocessi dell'app con terminazione a cascata
- [ ] Collegamento delle API di sistema al broker, secondo i permessi del manifest
- [ ] App di esempio «hello» con due finestre

## Fase 5 — Shell, stile grafico e modali di sistema · `proposta`

- [ ] Definire lo stile grafico, ibrido Windows 11 / macOS Big Sur / MIUI (D-032), e
      registrarlo in `MEMORY.md` §3
- [ ] Shell: pannello, launcher, gestione finestre, notifiche
- [ ] Libreria di modali HTML predefinite (R-10)
- [ ] Backend `xdg-desktop-portal` e agente polkit con modali HTML
- [ ] Layout adattivo desktop ↔ mobile, input touch

## Fase 6 — Applicazioni di sistema · `proposta`

- [ ] Impostazioni (rete, Bluetooth, audio, schermo, permessi app)
- [ ] Gestore file
- [ ] Terminale
- [ ] Gestore applicazioni
- [ ] Pannello «Dispositivi» nelle Impostazioni: associazione, elenco, revoca (D-033)

## Fase 7 — Mobile arm64 su base Android · `proposta`

- [ ] **Verifica di fattibilità (da anticipare appena possibile):** WebKitGTK con EGL via
      libhybris sul Pixel dell'utente; è il rischio tecnico principale lato mobile (D-014)
- [ ] Stesso spazio utente compilato per arm64, senza modifiche
- [ ] Layer `meta-project-os-mobile`: Halium/libhybris
- [ ] Pixel: kernel e firmware del produttore, GPU, touch, audio, Wi‑Fi, Bluetooth
- [ ] Pixel: modem (chiamate, SMS, dati), sensori, fotocamera
- [ ] Pacchetto di installazione da recovery per il Pixel (D-011)
- [ ] Oppo e Samsung: valutazione modelli (bootloader, recovery), poi porting
- [ ] Gesti touch, tastiera a schermo, rotazione, gestione energetica

## Fase 8 — Installazione, setup e aggiornamenti · `proposta`

- [ ] Immagine USB di installazione desktop: avvio diretto nel wizard, nessuna modalità
      live (D-010, R-19)
- [ ] App di setup con passi per piattaforma (D-017):
  - [ ] desktop: lingua, tastiera, fuso orario, rete, partizionamento e formattazione
        (anche accanto a Windows), cifratura, utente, installazione con GRUB
  - [ ] mobile (primo avvio dopo la recovery): lingua, Wi‑Fi/SIM, fuso orario, utente e
        codice di sblocco, permessi, preferenze
- [ ] Secure Boot con chiavi project-os registrate dall'utente (D-009)
- [ ] Firma di pacchetti e immagini; chiavi fuori dal repository
- [ ] Aggiornamenti A/B firmati con ritorno automatico alla versione precedente (D-018),
      su desktop e mobile

## Fase 9 — Ecosistema: interoperabilità tra dispositivi · `proposta`

Obiettivo: i dispositivi project-os dello stesso utente, desktop e mobile, lavorano
insieme come un unico ecosistema (R-33, D-033). Richiede DA-12.

- [ ] Specifica del protocollo (`docs/continuity.md`): associazione, chiavi, canale
      cifrato end-to-end, scoperta, revoca, versioni
- [ ] Demone di continuità in Rust, integrato con il broker
- [ ] Associazione con codice QR o numerico; passo facoltativo nel setup (D-017)
- [ ] Invio di file e link tra dispositivi vicini
- [ ] Appunti condivisi
- [ ] Notifiche, chiamate e SMS del telefono sul desktop
- [ ] API di continuità delle app (*handoff*) nell'oggetto `system`, con permesso nel
      manifest
- [ ] Sincronizzazione di impostazioni, rubrica, calendario, password e reti Wi‑Fi
- [ ] Hotspot immediato e sblocco del desktop con il telefono
- [ ] Test di sicurezza: un dispositivo non associato o revocato non accede a nulla
- [ ] In seguito: tablet come secondo schermo, tastiera e mouse condivisi

---

## Registro avanzamento

| Data | Fase | Cosa |
|---|---|---|
| 2026-11-11 | 0 | Creati `AGENTS.md`, `MEMORY.md`, `ROADMAP.md` |
| 2026-11-11 | 0 | Decisi compositore proprio, runtime JavaScriptCore, root mediato; marche ARM indicate |
| 2026-11-11 | 0 | Aggiunti requisiti installazione (recovery mobile, wizard desktop), menu di avvio con dual boot, nessuna live (R-16…R-19); proposte D-009…D-011 |
| 2026-11-11 | 0 | Cambio di approccio: da Debian a sistema da sorgenti, spazio utente unico desktop/mobile su base Android, Rust, Pixel come primo dispositivo, setup differenziato (R-20…R-24, D-012…D-017) |
| 2026-11-11 | 0 | Decisi Yocto e aggiornamenti A/B immutabili (D-012, D-018); `AGENTS.md` §1 aggiornato con autorizzazione |
| 2026-11-11 | 0 | Deciso il fork di WebKitGTK mantenuto dal progetto (D-019) |
| 2026-11-11 | 2 | Creati il fork `aptecstudio/WebKit` e il ramo `project-os/2.54` (numerazione attuale: Fase 2) |
| 2026-11-11 | 0 | Approvate D-006, D-009…D-011, D-014…D-017; licenza GPL-3.0; fasi in sequenza |
| 2026-11-11 | 0 | Roadmap riordinata dal basso verso l'alto: sistema base → grafica → broker → runtime → shell → app → mobile → installazione (D-022) |
| 2026-11-11 | 1 | Logo segnaposto e tema GRUB con anteprima (D-023); logo reso monocromo bianco su richiesta; tema approvato e unito in `main` |
| 2026-11-11 | 0 | Nuovi requisiti: retrocompatibilità a tutti i livelli, avvio UEFI e BIOS, cifratura senza TPM, x86-64 di base (R-25…R-28, D-027) |
| 2026-11-11 | 1 | Partizioni A/B, scelta dello slot in GRUB, RAUC, partizione dati cifrata al primo avvio, sul ramo `build/ab-partitions` (D-026, passi 4a e 4b) |
| 2026-11-11 | 1 | Lavoro sospeso su richiesta dell'utente; preparati guida e script per costruire e provare l'immagine sul suo PC (D-028) |
| 2026-11-11 | 0 | Aggiunto `README.md` di presentazione, su richiesta dell'utente; variante scura del logo segnaposto per sfondi chiari |
| 2026-11-11 | 0 | Nuove specifiche: API nell'oggetto globale `system`, `include`/`includeAsync` con errore sui cicli, protocollo `app://` per la cartella isolata dell'app, design ibrido Windows 11 / Big Sur / MIUI (R-29…R-32, D-029…D-032) |
| 2026-11-11 | 1 | Portatile dell'utente come macchina di build provvisoria: `kas/low-resources.yml`, attivata da `tools/build.sh` sotto 16 GB di RAM (D-034) |
| 2026-11-11 | 1 | **Prima build completa riuscita** sul portatile (19:42 → 23:25, con tre correzioni: D-035, `features_check` in `project-os-storage`, schema del disco `.wks.in`); immagine `wic` da 695 MB reali; manca la prova in QEMU |
| 2026-11-11 | 1 | Prima build sul portatile fermata e rilanciata: kernel dal mirror HTTP di Yocto (il server git va a 17 KB/s), tolti QEMU/Mesa/LLVM costruiti da Yocto (D-035) |
| 2026-11-11 | 9 | Nuovo requisito: interoperabilità tra dispositivi project-os come un ecosistema (R-33); proposte la Fase 9 e D-033, aperta DA-12 |
| 2026-11-11 | 1 | Layer Yocto, distribuzione, macchina amd64, immagine base e configurazione kas, (D-024); controllo di lettura con bitbake superato; approvati kas e x86-64-v2, uniti in `main` |
| 2026-11-11 | 1 | Kernel e firmware per l'hardware desktop, (D-025): 147 opzioni verificate sul 6.18, 27 pacchetti firmware; approvato e unito in `main` |
| 2026-11-11 | 0 | `README.md` per chi vuole conoscere il progetto: cosa offrirà, dispositivi, stato, licenza; variante scura del logo per sfondi chiari |

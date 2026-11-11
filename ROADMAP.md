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

**Prossimo passo:** passo 3 della Fase 1, configurazione del kernel e firmware.
Un passo alla volta, con conferma dell'utente.

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
- [ ] **DA-11 — Macchina di build** *(blocca Fase 1)*
  Yocto deve girare su una macchina dell'utente (VM o fisica): almeno 16 GB di RAM,
  250 GB di disco, molti core. Sistema host da scegliere tra quelli supportati da Yocto.

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
- [ ] 3. Configurazione del kernel per l'hardware moderno (audio, Bluetooth, Wi‑Fi,
      GPU Intel/AMD) e firmware da linux-firmware, ognuno con motivazione (R-04)
- [ ] 4. Schema partizioni A/B con dm-verity, partizione dati cifrata, RAUC (D-018)
- [ ] 5. Menu di avvio GRUB (D-009):
  - [x] 5a. Logo segnaposto e tema in `branding/`, con anteprima (D-023)
  - [ ] 5b. Ricetta Yocto: font `.pf2`, installazione del tema, `os-prober` per
        rilevare Windows e altri sistemi

**Passi successivi:**
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

## Fase 4 — Runtime delle app · `proposta`

Obiettivo: il modello applicativo (R-07, R-09) sopra broker e compositore.

- [ ] Workspace Cargo con binding a WebKitGTK 6.0 e JavaScriptCore
- [ ] Specifica v0 del formato `package.json` (`docs/manifest.md`)
- [ ] Host nativo che legge il manifest, crea un contesto JavaScriptCore isolato ed
      esegue lo script principale
- [ ] API `window`: apertura, chiusura e comunicazione con finestre WebKitGTK legate al
      processo; canale messaggi script principale ↔ finestre (stile Electron)
- [ ] Sottoprocessi dell'app con terminazione a cascata
- [ ] Collegamento delle API di sistema al broker, secondo i permessi del manifest
- [ ] App di esempio «hello» con due finestre

## Fase 5 — Shell, stile grafico e modali di sistema · `proposta`

- [ ] Definire lo stile grafico e registrarlo in `MEMORY.md` §3
- [ ] Shell: pannello, launcher, gestione finestre, notifiche
- [ ] Libreria di modali HTML predefinite (R-10)
- [ ] Backend `xdg-desktop-portal` e agente polkit con modali HTML
- [ ] Layout adattivo desktop ↔ mobile, input touch

## Fase 6 — Applicazioni di sistema · `proposta`

- [ ] Impostazioni (rete, Bluetooth, audio, schermo, permessi app)
- [ ] Gestore file
- [ ] Terminale
- [ ] Gestore applicazioni

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
| 2026-11-11 | 1 | Layer Yocto, distribuzione, macchina amd64, immagine base e configurazione kas, (D-024); controllo di lettura con bitbake superato; approvati kas e x86-64-v2, uniti in `main` |

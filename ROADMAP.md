# ROADMAP.md — Stato del progetto

Passi eseguiti e passi da eseguire, per avere uno stato globale e per fase.
Regole di aggiornamento in `AGENTS.md` §3.

**Stati di fase:** `proposta` → `approvata` → `in corso` → `completata` (oppure `sospesa`).
Si lavora solo su fasi `approvata` o `in corso`.

## Stato globale

| Fase | Titolo | Stato |
|---|---|---|
| 0 | Fondamenta e decisioni | `in corso` |
| 1 | Prototipo del runtime app (su macchina di sviluppo) | `proposta` |
| 2 | Sistema base da sorgenti, desktop amd64 | `proposta` |
| 3 | Broker, permessi e sandbox | `proposta` |
| 4 | Shell, stile grafico e modali di sistema | `proposta` |
| 5 | Applicazioni di sistema | `proposta` |
| 6 | Mobile arm64 su base Android (Pixel, poi Oppo e Samsung) | `proposta` |
| 7 | Installazione, setup e aggiornamenti | `proposta` |

Le Fasi 1 e 2 possono procedere in parallelo: il runtime si sviluppa su qualsiasi Linux con
WebKitGTK, mentre si costruisce il sistema da sorgenti.

**Prossimo passo:** risolvere DA-08, DA-09 e DA-10; approvare le decisioni `proposta`
in `MEMORY.md`; approvare le Fasi 1 e 2.

---

## Decisioni aperte

Da risolvere con l'utente prima di avviare le fasi indicate. Una volta decise, si spostano
in `MEMORY.md` come voce `confermata`.

- [x] **DA-01 — Gestione finestre e compositore Wayland** → compositore proprio (D-007)
- [x] **DA-02 — Runtime dello script JavaScript principale** → JavaScriptCore (D-008)
- [ ] **DA-03 — Dispositivi mobili di riferimento** *(blocca Fase 6)*
  Primo: il Google Pixel dell'utente (modello esatto da indicare). Poi: i vecchi modelli
  Oppo e Samsung in suo possesso (modelli esatti da indicare). Per ognuno: bootloader
  sbloccabile? recovery custom disponibile?
- [x] **DA-04 — Modello dell'accesso root** → root mediato dal broker (D-005)
- [ ] **DA-05 — Formato di distribuzione delle app** *(blocca Fase 3)*
  Pacchetto proprio firmato (archivio con `package.json` + firma). L'opzione `.deb` è
  decaduta con R-20.
- [ ] **DA-06 — Nome del sistema e licenza del codice** *(blocca Fase 2)*
- [x] **DA-07 — Linguaggio dei componenti nativi** → Rust (D-013)
- [ ] **DA-08 — Build system per il sistema da sorgenti** *(blocca Fase 2)*
  - **Yocto/OpenEmbedded:** standard industriale per sistemi su misura, gestisce bene
    più architetture e dispositivi (layer per piattaforma), ricette WebKitGTK e strati
    Halium già esistenti nella comunità; curva di apprendimento ripida, build lunghe.
  - **Buildroot:** più semplice e veloce da imparare; meno adatto a uno stack grande
    come WebKitGTK e a più dispositivi, nessun gestore pacchetti.
  - **Strumento proprio in Rust (stile Linux From Scratch):** controllo totale, ma
    tutto da scrivere e mantenere, compresi gli aggiornamenti di sicurezza.
- [ ] **DA-09 — Modello di aggiornamento del sistema** *(blocca Fase 2, vincola Fase 7)*
  - **Immagine immutabile A/B:** sistema in sola lettura verificato (dm-verity), due
    slot, aggiornamento atomico con ritorno alla versione precedente se fallisce; come
    Android e ChromeOS. Le app si installano a parte (DA-05).
  - **Gestore di pacchetti tradizionale:** aggiornamento componente per componente,
    più flessibile ma meno sicuro e meno prevedibile.
- [ ] **DA-10 — Aggiornare `AGENTS.md`** *(richiede autorizzazione umana, AGENTS.md §2)*
  §1 descrive ancora project-os come «basato su una versione stabile di Debian».
  Modifica proposta: «costruito da sorgenti a partire dal kernel Linux, con uno spazio
  utente unico per desktop e mobile (su base Android)».

---

## Fase 0 — Fondamenta e decisioni · `in corso`

- [x] Creare il repository `project-os` con branch principale `main`
- [x] Scrivere `AGENTS.md` (regole per agenti e persone)
- [x] Scrivere `MEMORY.md` (requisiti e decisioni)
- [x] Scrivere `ROADMAP.md`
- [x] Risolvere DA-01, DA-02, DA-04, DA-07
- [x] Ridisegnare l'approccio: da Debian a sistema da sorgenti (R-20…R-24)
- [ ] Risolvere DA-08, DA-09, DA-10
- [ ] Approvazione umana delle decisioni `proposta` in `MEMORY.md`
- [ ] Approvazione delle Fasi 1 e 2

## Fase 1 — Prototipo del runtime app · `proposta`

Obiettivo: dimostrare il modello applicativo (R-07, R-09) su una macchina di sviluppo
Linux con WebKitGTK, indipendentemente dall'immagine.

- [ ] Progetto Rust (workspace Cargo) con binding a WebKitGTK 6.0 e JavaScriptCore
- [ ] Host nativo che crea un contesto JavaScriptCore ed esegue lo script principale
- [ ] Avviare un'app da `package.json`: lettura manifest, esecuzione dello script principale
- [ ] API `window`: apertura, chiusura e comunicazione con finestre WebKitGTK legate al processo
- [ ] Canale messaggi script principale ↔ finestre (stile IPC di Electron)
- [ ] Sottoprocessi dell'app con terminazione a cascata
- [ ] Specifica v0 del formato `package.json` (`docs/manifest.md`)
- [ ] App di esempio «hello» con due finestre

## Fase 2 — Sistema base da sorgenti, desktop amd64 · `proposta`

- [ ] Configurare il build system scelto in DA-08
- [ ] Toolchain e glibc (D-015)
- [ ] Kernel Linux mainline con supporto hardware moderno: audio, Bluetooth, Wi‑Fi,
      GPU (R-04); firmware da linux-firmware
- [ ] systemd, udev, logind (D-016); rete, audio (PipeWire + WirePlumber), BlueZ
- [ ] Mesa, GTK 4, WebKitGTK stabile compilati da sorgenti
- [ ] Ogni componente con motivazione registrata (AGENTS.md §5.5)
- [ ] Processo di monitoraggio delle vulnerabilità dei componenti (D-012)
- [ ] Compositore Rust/Smithay minimo che avvia una finestra WebKitGTK
- [ ] Logo segnaposto generico in `branding/` (SVG + PNG)
- [ ] Menu di avvio GRUB con tema project-os: voci centrate, logo (D-009)
- [ ] Dual boot: rilevamento di Windows e altri sistemi, prova in QEMU con Windows
- [ ] Avvio in QEMU/UEFI fino alla shell
- [ ] Prova su hardware reale Intel e AMD (audio, Bluetooth, Wi‑Fi, GPU)
- [ ] Misura dimensione immagine e memoria a riposo; registrarle in `MEMORY.md`

## Fase 3 — Broker, permessi e sandbox · `proposta`

- [ ] Specifica del modello permessi (`docs/permissions.md`)
- [ ] Demone broker in Rust con IPC autenticato
- [ ] Sandbox per app (namespace + seccomp), negazione per default
- [ ] API di base: filesystem, dispositivi, finestre, servizi di sistema (R-12)
- [ ] Richieste root mediate con conferma e log di audit (R-13)
- [ ] Formato pacchetto app firmato (DA-05)
- [ ] Test di sicurezza: un'app non può superare i permessi concessi

## Fase 4 — Shell, stile grafico e modali di sistema · `proposta`

- [ ] Definire lo stile grafico e registrarlo in `MEMORY.md` §3
- [ ] Shell: pannello, launcher, gestione finestre, notifiche
- [ ] Libreria di modali HTML predefinite (R-10)
- [ ] Backend `xdg-desktop-portal` e agente polkit con modali HTML
- [ ] Layout adattivo desktop ↔ mobile, input touch

## Fase 5 — Applicazioni di sistema · `proposta`

- [ ] Impostazioni (rete, Bluetooth, audio, schermo, permessi app)
- [ ] Gestore file
- [ ] Terminale
- [ ] Gestore applicazioni

## Fase 6 — Mobile arm64 su base Android · `proposta`

- [ ] **Verifica di fattibilità (da anticipare appena possibile):** WebKitGTK con EGL via
      libhybris sul Pixel dell'utente; è il rischio tecnico principale lato mobile (D-014)
- [ ] Stesso spazio utente compilato per arm64, senza modifiche
- [ ] Strato `platforms/mobile-arm64`: Halium/libhybris
- [ ] Pixel: kernel e firmware del produttore, GPU, touch, audio, Wi‑Fi, Bluetooth
- [ ] Pixel: modem (chiamate, SMS, dati), sensori, fotocamera
- [ ] Pacchetto di installazione da recovery per il Pixel (D-011)
- [ ] Oppo e Samsung: valutazione modelli (bootloader, recovery), poi porting
- [ ] Gesti touch, tastiera a schermo, rotazione, gestione energetica

## Fase 7 — Installazione, setup e aggiornamenti · `proposta`

- [ ] Immagine USB di installazione desktop: avvio diretto nel wizard, nessuna modalità
      live (D-010, R-19)
- [ ] App di setup con passi per piattaforma (D-017):
  - [ ] desktop: lingua, tastiera, fuso orario, rete, partizionamento e formattazione
        (anche accanto a Windows), cifratura, utente, installazione con GRUB
  - [ ] mobile (primo avvio dopo la recovery): lingua, Wi‑Fi/SIM, fuso orario, utente e
        codice di sblocco, permessi, preferenze
- [ ] Secure Boot con chiavi project-os registrate dall'utente (D-009)
- [ ] Firma di pacchetti e immagini; chiavi fuori dal repository
- [ ] Aggiornamenti di sistema secondo DA-09

---

## Registro avanzamento

| Data | Fase | Cosa |
|---|---|---|
| 2026-11-11 | 0 | Creati `AGENTS.md`, `MEMORY.md`, `ROADMAP.md` |
| 2026-11-11 | 0 | Decisi compositore proprio, runtime JavaScriptCore, root mediato; marche ARM indicate |
| 2026-11-11 | 0 | Aggiunti requisiti installazione (recovery mobile, wizard desktop), menu di avvio con dual boot, nessuna live (R-16…R-19); proposte D-009…D-011 |
| 2026-11-11 | 0 | Cambio di approccio: da Debian a sistema da sorgenti, spazio utente unico desktop/mobile su base Android, Rust, Pixel come primo dispositivo, setup differenziato (R-20…R-24, D-012…D-017) |

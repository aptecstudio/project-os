# ROADMAP.md — Stato del progetto

Passi eseguiti e passi da eseguire, per avere uno stato globale e per fase.
Regole di aggiornamento in `AGENTS.md` §3.

**Stati di fase:** `proposta` → `approvata` → `in corso` → `completata` (oppure `sospesa`).
Si lavora solo su fasi `approvata` o `in corso`.

## Stato globale

| Fase | Titolo | Stato |
|---|---|---|
| 0 | Fondamenta e decisioni | `in corso` |
| 1 | Prototipo del runtime app (su Debian esistente) | `proposta` |
| 2 | Immagine base minimale amd64 | `proposta` |
| 3 | Broker, permessi e sandbox | `proposta` |
| 4 | Shell, stile grafico e modali di sistema | `proposta` |
| 5 | Applicazioni di sistema | `proposta` |
| 6 | ARM64 e dispositivi mobili | `proposta` |
| 7 | Aggiornamenti, firma e installazione | `proposta` |

**Prossimo passo:** risolvere le decisioni aperte e approvare la Fase 1.

---

## Decisioni aperte

Da risolvere con l'utente prima di avviare le fasi indicate. Una volta decise, si spostano
in `MEMORY.md` come voce `confermata`.

- [ ] **DA-01 — Gestione finestre e compositore Wayland** *(blocca Fasi 1, 2, 4)*
  Serve un compositore che mostri le finestre delle app e la shell. Opzioni:
  - **A.** Compositore proprio minimale (wlroots o Smithay): ogni finestra di app è una
    superficie Wayland; la shell web (pannelli, dock) usa *layer-shell*; la logica di
    disposizione finestre è decisa dalla shell via IPC. Massima coerenza, più lavoro.
  - **B.** Compositore kiosk (`cage`) con un'unica finestra GTK della shell che ospita
    le WebView delle app al suo interno. Semplice, ma le app condividono un processo
    di composizione e l'isolamento è più debole.
  - **C.** Compositore esistente leggero (es. `labwc`) + shell web via layer-shell.
    Il più rapido per partire; meno controllo su animazioni di finestra (R-08).
- [ ] **DA-02 — Runtime dello script JavaScript principale** *(blocca Fase 1)*
  - **GJS:** JavaScript con binding GObject nativi, comanda GTK 4 e WebKitGTK
    direttamente; niente ecosistema npm completo.
  - **Node.js:** ecosistema npm e familiarità; serve un ponte nativo verso GTK/WebKitGTK.
  - **Runtime proprio** (es. processo C/Rust con motore JS integrato): massimo controllo
    sulle API esposte, più lavoro.
- [ ] **DA-03 — Dispositivi ARM di riferimento** *(blocca Fase 6)*
  Quali smartphone/tablet/SBC si vogliono supportare per primi.
- [ ] **DA-04 — Modello dell'accesso root** *(blocca Fase 3)*
  Confermare D-005 (root mediato dal broker, mai shell root all'app) o definire
  un'alternativa.
- [ ] **DA-05 — Formato di distribuzione delle app** *(blocca Fase 3)*
  Pacchetto proprio firmato (archivio con `package.json` + firma) oppure `.deb`.
- [ ] **DA-06 — Nome del sistema e licenza del codice** *(blocca Fase 2)*

---

## Fase 0 — Fondamenta e decisioni · `in corso`

- [x] Creare il repository `project-os` con branch principale `main`
- [x] Scrivere `AGENTS.md` (regole per agenti e persone)
- [x] Scrivere `MEMORY.md` (requisiti R-01…R-15, decisioni proposte D-001…D-006)
- [x] Scrivere `ROADMAP.md`
- [ ] Risolvere le decisioni aperte DA-01, DA-02, DA-04 (minimo per partire)
- [ ] Approvazione umana delle decisioni proposte in `MEMORY.md`
- [ ] Approvazione della Fase 1

## Fase 1 — Prototipo del runtime app · `proposta`

Obiettivo: dimostrare il modello applicativo (R-07, R-09) su una Debian 13 esistente,
prima di costruire l'immagine.

- [ ] Verificare il pacchetto WebKitGTK stabile disponibile in Trixie e la sua versione
- [ ] Avviare un'app da `package.json`: lettura manifest, esecuzione dello script principale
- [ ] API `window`: apertura, chiusura e comunicazione con finestre WebKitGTK legate al processo
- [ ] Canale messaggi script principale ↔ finestre (stile IPC di Electron)
- [ ] Sottoprocessi dell'app con terminazione a cascata
- [ ] Specifica v0 del formato `package.json` (`docs/manifest.md`)
- [ ] App di esempio «hello» con due finestre

## Fase 2 — Immagine base minimale amd64 · `proposta`

- [ ] Ricetta `mmdebstrap --variant=minbase` riproducibile in `build/`
- [ ] Elenchi pacchetti motivati (base, kernel e firmware, audio, Bluetooth, rete, grafica)
- [ ] Avvio in QEMU/UEFI fino al compositore Wayland
- [ ] Avvio automatico della shell (sessione utente, nessun display manager superfluo)
- [ ] Prova su hardware reale Intel e AMD (audio, Bluetooth, Wi‑Fi, GPU)
- [ ] Misura dimensione immagine e memoria a riposo; registrarle in `MEMORY.md`

## Fase 3 — Broker, permessi e sandbox · `proposta`

- [ ] Specifica del modello permessi (`docs/permissions.md`)
- [ ] Demone broker con IPC autenticato
- [ ] Sandbox per app (bubblewrap + seccomp), negazione per default
- [ ] API di base: filesystem, dispositivi, finestre, servizi di sistema (R-12)
- [ ] Richieste root mediate con conferma e log di audit (R-13)
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

## Fase 6 — ARM64 e dispositivi mobili · `proposta`

- [ ] Immagine arm64 generica (QEMU, SBC)
- [ ] Supporto ai dispositivi scelti in DA-03 (kernel, firmware, modem, sensori)
- [ ] Gesti touch, tastiera a schermo, rotazione, gestione energetica

## Fase 7 — Aggiornamenti, firma e installazione · `proposta`

- [ ] Firma di pacchetti e immagini; chiavi fuori dal repository
- [ ] Aggiornamenti di sistema sicuri (con eventuale rollback)
- [ ] Secure Boot su amd64
- [ ] Installer con interfaccia web

---

## Registro avanzamento

| Data | Fase | Cosa |
|---|---|---|
| 2026-11-11 | 0 | Creati `AGENTS.md`, `MEMORY.md`, `ROADMAP.md` |

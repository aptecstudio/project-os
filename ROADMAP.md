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

**Prossimo passo:** decidere DA-07, approvare le decisioni ancora `proposta` in
`MEMORY.md` e approvare la Fase 1.

---

## Decisioni aperte

Da risolvere con l'utente prima di avviare le fasi indicate. Una volta decise, si spostano
in `MEMORY.md` come voce `confermata`.

- [x] **DA-01 — Gestione finestre e compositore Wayland** → compositore proprio
  (`MEMORY.md` D-007)
- [x] **DA-02 — Runtime dello script JavaScript principale** → JavaScriptCore
  (`MEMORY.md` D-008)
- [ ] **DA-03 — Dispositivi ARM di riferimento** *(blocca Fase 6)*
  Marche indicate: Google Pixel, Samsung, Xiaomi, Oppo. Da scegliere: 1–2 modelli
  specifici per partire e percorso kernel (mainline o Halium/libhybris), vedi D-004.
- [x] **DA-04 — Modello dell'accesso root** → root mediato dal broker (`MEMORY.md` D-005)
- [ ] **DA-07 — Linguaggio dei componenti nativi** *(blocca Fasi 1, 2)*
  Compositore, host del runtime JSC e broker. Opzioni:
  - **Rust** (compositore su Smithay): sicurezza della memoria nei componenti più
    esposti, coerente con R-14.
  - **C** (compositore su wlroots): API native di wlroots e WebKitGTK senza binding,
    più esempi disponibili, rischio di errori di memoria.
- [ ] **DA-05 — Formato di distribuzione delle app** *(blocca Fase 3)*
  Pacchetto proprio firmato (archivio con `package.json` + firma) oppure `.deb`.
- [ ] **DA-06 — Nome del sistema e licenza del codice** *(blocca Fase 2)*

---

## Fase 0 — Fondamenta e decisioni · `in corso`

- [x] Creare il repository `project-os` con branch principale `main`
- [x] Scrivere `AGENTS.md` (regole per agenti e persone)
- [x] Scrivere `MEMORY.md` (requisiti R-01…R-15, decisioni proposte D-001…D-006)
- [x] Scrivere `ROADMAP.md`
- [x] Risolvere le decisioni aperte DA-01, DA-02, DA-04
- [ ] Risolvere DA-07 (linguaggio nativo)
- [ ] Approvazione umana delle decisioni proposte in `MEMORY.md`
- [ ] Approvazione della Fase 1

## Fase 1 — Prototipo del runtime app · `proposta`

Obiettivo: dimostrare il modello applicativo (R-07, R-09) su una Debian 13 esistente,
prima di costruire l'immagine.

- [ ] Verificare il pacchetto WebKitGTK stabile disponibile in Trixie e la sua versione
- [ ] Host nativo che crea un contesto JavaScriptCore ed esegue lo script principale
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
| 2026-11-11 | 0 | Decisi compositore proprio, runtime JavaScriptCore, root mediato; marche ARM indicate |

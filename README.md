<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="branding/logo/project-os-logo-256.png">
    <img src="branding/logo/project-os-logo-dark-256.png" alt="project-os" width="96">
  </picture>
</p>

<h1 align="center">project-os</h1>

<p align="center">
  Un sistema operativo costruito da zero sul kernel Linux, con un'interfaccia
  interamente web. Per desktop e smartphone.
</p>

<p align="center">
  <em>Progetto hobbistico in sviluppo: non è ancora utilizzabile.</em>
</p>

---

## L'idea

Tutto quello che si vede sullo schermo (pannelli, finestre, impostazioni, finestre di
sistema, persino l'installazione) è fatto con **HTML, CSS e JavaScript**, e disegnato
dal motore **WebKit**. Sotto c'è un sistema Linux essenziale, costruito pezzo per pezzo
dai sorgenti, senza partire da una distribuzione esistente.

Ogni applicazione è **uno script JavaScript principale** che apre le proprie finestre,
come in Electron, ma su WebKitGTK e con un modello di sicurezza molto più stretto.
L'app dichiara nel suo `package.json` di quali funzioni del sistema ha bisogno, e ottiene
solo quelle.

Lo stesso sistema gira su **PC Intel e AMD** e su **smartphone e tablet ARM**: cambia
solo lo strato che parla con l'hardware.

## Principi

- **Sicurezza prima di tutto.** Il progetto è disegnato così:
  - ogni app gira isolata e accede a file, dispositivi e servizi solo tramite un
    intermediario che verifica i permessi;
  - l'accesso root è sempre mediato, confermato dall'utente e registrato;
  - il sistema è in sola lettura e verificato;
  - gli aggiornamenti sono firmati e atomici, con ritorno automatico alla versione
    precedente se qualcosa va storto.
- **Retrocompatibilità a tutti i livelli.** L'obiettivo è che:
  - il sistema giri su ogni processore a 64 bit e si avvii sia da UEFI sia da BIOS;
  - la cifratura dei dati funzioni anche senza chip TPM.
- **Essenziale.** Ogni componente del sistema c'è per un motivo, scritto nero su bianco.

Molte di queste parti sono ancora in costruzione: lo stato preciso è in
[`ROADMAP.md`](ROADMAP.md).
- **Web fino in fondo.** Rendering e animazioni sono tutti del motore web, comprese le
  finestre di dialogo del sistema.

## Come è fatto

```
┌────────────────────────────────────────────────────────────┐
│  App e shell: HTML + CSS + JavaScript                      │
├────────────────────────────────────────────────────────────┤
│  Runtime delle app: script principale su JavaScriptCore,   │
│  finestre WebKitGTK (Rust)                                 │
├──────────────────────────────┬─────────────────────────────┤
│  Broker dei permessi e       │  Compositore Wayland        │
│  sandbox (Rust)              │  (Rust, Smithay)            │
├──────────────────────────────┴─────────────────────────────┤
│  Sistema base: systemd, glibc, PipeWire, BlueZ …           │
│  in sola lettura, due copie A/B, aggiornamenti RAUC        │
├──────────────────────────────┬─────────────────────────────┤
│  Desktop: kernel Linux 6.18, │  Mobile: kernel e driver    │
│  Mesa, firmware              │  Android (Halium/libhybris) │
└──────────────────────────────┴─────────────────────────────┘
```

| Componente | Scelta |
|---|---|
| Costruzione del sistema | Yocto Project 6.0 «Wrynose» (LTS), con kas |
| Kernel | Linux 6.18 LTS |
| Avvio | GRUB, con menu a tema e dual boot |
| Aggiornamenti | RAUC, due copie del sistema (A/B) |
| Motore web | WebKitGTK, da un [fork mantenuto dal progetto](https://github.com/aptecstudio/WebKit) |
| Linguaggio dei componenti nativi | Rust |
| Grafica e input | Wayland |

## A che punto siamo

Lo sviluppo procede dal basso verso l'alto, una fase alla volta.

| Fase | | Stato |
|---|---|---|
| 0 | Fondamenta e decisioni | ✅ quasi completata |
| 1 | Sistema base: build, kernel, avvio, partizioni A/B | 🔨 in corso |
| 2 | Stack grafico: WebKitGTK e compositore | ⏳ |
| 3 | Broker, permessi e sandbox | ⏳ |
| 4 | Runtime delle app | ⏳ |
| 5 | Shell, stile grafico e finestre di sistema | ⏳ |
| 6 | Applicazioni di sistema | ⏳ |
| 7 | Smartphone e tablet (Pixel, poi Oppo e Samsung) | ⏳ |
| 8 | Installazione, setup e aggiornamenti | ⏳ |
| 9 | Ecosistema: interoperabilità tra dispositivi | ⏳ |

Il dettaglio di ogni passo è in [`ROADMAP.md`](ROADMAP.md).

<p align="center">
  <img src="branding/previews/grub-menu.png" alt="Anteprima del menu di avvio" width="720">
  <br>
  <sub>Anteprima del menu di avvio, con il logo segnaposto.</sub>
</p>

## Provarlo

Oggi si costruisce l'immagine desktop e la si avvia nell'emulatore QEMU, fino a un
terminale testuale. Serve una macchina Linux robusta: la prima build richiede alcune ore.

```sh
git clone https://github.com/aptecstudio/project-os.git
cd project-os
tools/setup-host.sh   # prepara la macchina
tools/build.sh        # costruisce l'immagine
tools/run-qemu.sh     # la avvia nell'emulatore
```

Requisiti, limiti attuali e soluzione dei problemi: [`docs/sviluppo.md`](docs/sviluppo.md).

## Documenti del progetto

| Documento | Contenuto |
|---|---|
| [`AGENTS.md`](AGENTS.md) | Regole di lavoro per persone e agenti AI |
| [`MEMORY.md`](MEMORY.md) | Requisiti, decisioni prese e il loro perché |
| [`ROADMAP.md`](ROADMAP.md) | Passi fatti e da fare |
| [`docs/sviluppo.md`](docs/sviluppo.md) | Come costruire e provare il sistema |

## Licenza

Il codice di project-os è rilasciato con licenza [GNU GPL v3](LICENSE).
Il fork di WebKit mantiene le licenze originali di WebKit. Il font Inter, usato nel menu
di avvio, è distribuito con licenza SIL Open Font License 1.1.

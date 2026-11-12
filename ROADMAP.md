# ROADMAP.md — Project status

Steps done and steps to do, to give an overall and per-phase status.
Update rules in `AGENTS.md` §3.

**Phase states:** `proposed` → `approved` → `in progress` → `completed` (or `suspended`).
Work happens only on `approved` or `in progress` phases.

*Translated from Italian to English on 2026-11-12, at the user's request (D-037). The
content is unchanged; state names are translated (`proposta` → `proposed`, `approvata`
→ `approved`, `in corso` → `in progress`, `completata` → `completed`, `sospesa` →
`suspended`).*

## Overall status

Order **from the bottom up** (D-022): first the system, then what runs on top of it.
Phases are carried out **one at a time**, in order (D-021).

| Phase | Title | Status |
|---|---|---|
| 0 | Foundations and decisions | `in progress` |
| 1 | Base system: Yocto, kernel, boot | `in progress` |
| 2 | Graphics stack: WebKitGTK from the fork and compositor | `proposed` |
| 3 | Broker, permissions and sandbox | `proposed` |
| 4 | App runtime (JS scripts and windows) | `proposed` |
| 5 | Shell, visual style and system dialogs | `proposed` |
| 6 | System applications | `proposed` |
| 7 | Android-based arm64 mobile (Pixel, then Oppo and Samsung) | `proposed` |
| 8 | Installation, setup and updates | `proposed` |
| 9 | Ecosystem: interoperability between devices | `proposed` |

**Next step:** step 4c.4 (UKI per slot on the EFI partition) on the
`build/verified-boot` branch (step 4c.3 approved, D-047); then 4d,
4e, 5b, and the real hardware test session (step 6) with all the hardware checks
together. One step at a time, with the user's confirmation.

---

## Open decisions

To be settled with the user before starting the phases indicated. Once decided, they
move to `MEMORY.md` as a `confirmed` entry.

- [x] **DA-01 — Window management and Wayland compositor** → own compositor (D-007)
- [x] **DA-02 — Runtime of the main JavaScript script** → JavaScriptCore (D-008)
- [ ] **DA-03 — Reference mobile devices** *(blocks Phase 7)*
  First: the user's Google Pixel (exact model to be given). Then: the older Oppo and
  Samsung models the user owns (exact models to be given). For each one: unlockable
  bootloader? custom recovery available?
- [x] **DA-04 — Root access model** → root mediated by the broker (D-005)
- [ ] **DA-05 — App distribution format** *(blocks Phase 3)*
  Own signed package (archive with `package.json` + signature). The `.deb` option
  lapsed with R-20.
- [x] **DA-06a — License** → GPL-3.0 (D-020)
- [ ] **DA-06b — Final name of the system** *(not blocking; "project-os" for now)*
- [x] **DA-07 — Language of the native components** → Rust (D-013)
- [x] **DA-08 — Build system for the system built from source** → Yocto/OpenEmbedded (D-012)
- [x] **DA-09 — System update model** → immutable A/B image (D-018)
- [x] **DA-10 — Update `AGENTS.md`** → authorized by the user on 2026-11-11, §1 updated
  (AGENTS.md v1.1)
- [ ] **DA-11 — Build host** *(blocks the Phase 1 checks)*
  Yocto must run on a machine of the user's (VM or physical): at least 16 GB of RAM,
  250 GB of disk, many cores. Ubuntu Server 24.04/26.04 LTS recommended. Guide and
  scripts ready (`docs/development.md`, `tools/setup-host.sh`); the machine is missing.
  *Temporary solution (D-034, confirmed):* the user's laptop, Debian 13 (4 cores, 7.4 GB
  of RAM, 42 GB free), with `tools/build.sh --low-resources` (D-036); enough for Phase 1,
  not for WebKitGTK (Phase 2).
- [ ] **DA-12 — Ecosystem between devices** *(blocks Phase 9; affects Phases 3, 4, 6)*
  To decide: (a) local network and Bluetooth only, or also a relay service for distant
  devices, and in that case hosted by whom (the user themselves, the project);
  (b) network discovery with mDNS (re-enabling `zeroconf`) or with an own announcement;
  (c) compatibility with devices that do not run project-os (e.g. the KDE Connect
  protocol for Android and Linux) or an ecosystem reserved to project-os only;
  (d) order of the features listed in D-033.

---

## Phase 0 — Foundations and decisions · `in progress`

- [x] Create the `project-os` repository with main branch `main`
- [x] Write `AGENTS.md` (rules for agents and people)
- [x] Write `MEMORY.md` (requirements and decisions)
- [x] Write `ROADMAP.md`
- [x] Settle DA-01, DA-02, DA-04, DA-07
- [x] Redesign the approach: from Debian to a system built from source (R-20…R-24)
- [x] Settle DA-08, DA-09, DA-10
- [x] Human approval of the `proposed` decisions in `MEMORY.md`
- [x] GPL-3.0 license, `LICENSE` file
- [x] Roadmap reordered from the bottom up (D-022)
- [x] Start of Phase 1 approved: proceed one step at a time, with the user's
      confirmation at each step
- [x] Repository in English: code, documentation and commits (D-037)
- [x] Code style rule in `AGENTS.md` §7, checks in `tools/lint.sh`, existing code
      reviewed (D-046)
- [ ] Build host ready (DA-11)

## Phase 1 — Base system: Yocto, kernel, boot · `in progress`

Goal: an amd64 image built from source that boots in QEMU/UEFI and on real hardware,
with boot menu, A/B partitions and full hardware support.

**First steps (to be approved):**
- [x] 1. Configure Yocto 6.0 "Wrynose" (LTS) with kas and create the
      `meta-project-os` and `meta-project-os-desktop` layers (D-012, D-024); bitbake
      reads the configuration without errors. Confirmed by the first full build
      (2026-11-11).
- [x] 2. Minimal image: Linux 6.18 LTS kernel, glibc, systemd; boot in QEMU/UEFI up to a
      text terminal (D-015, D-016)
  - [x] 2a. Image recipe, machine and partition layout written
  - [x] 2b. First build and boot in QEMU on the build host (laptop, D-034)
- [x] 3. Kernel configuration for modern hardware (audio, Bluetooth, Wi‑Fi, Intel/AMD
      GPU) and firmware from linux-firmware, each with its reason (R-04, D-025)
  - [x] 3a. Intel SOF audio firmware recipe (`sof-bin` 2026.09.2, D-039); listening
        test in step 6
  - [x] 3b. Intel microcode recipe, early microcode loading (with step 4c.1, D-043);
        real check in step 6.17
- [ ] 4. A/B partition layout with dm-verity, encrypted data partition, RAUC (D-018, D-026)
  - [x] 4a. Disk layout: ESP, A/B slots, BIOS space, encrypted data partition created on
        first boot
  - [x] 4b. Slot selection in GRUB and signed RAUC updates
  - [ ] 4c. erofs + dm-verity system, systemd initramfs, unified kernel image (UKI) per
        slot, persistent `/etc` (plan in D-042)
    - [x] 4c.1 systemd initramfs with early Intel and AMD microcode (together with 3b,
          D-043)
    - [x] 4c.2 persistent `/etc`: overlay on the data partition, update conflicts
          reported (D-044)
    - [x] 4c.3 erofs system verified by dm-verity: root hash per slot on the EFI
          partition, written by the bundle hook; a corrupted block stops the boot
          (D-047)
    - [ ] 4c.4 UKI per slot on the EFI partition, plus separate kernel + initramfs for
          BIOS boot
  - [ ] 4d. Data unlocking: password and recovery key (without TPM, R-27); TPM as an
        extra method where present; limit the memory of the key derivation for old
        PCs with little RAM (D-044)
  - [ ] 4e. BIOS boot with GRUB in the same image (R-26)
- [ ] 5. GRUB boot menu (D-009):
  - [x] 5a. Placeholder logo and theme in `branding/`, with preview (D-023)
  - [ ] 5b. Yocto recipe: `.pf2` fonts, theme installation, `os-prober` to detect
        Windows and other systems
- [ ] 6. **Real hardware test session** (D-040): all the checks that QEMU cannot do,
      done together in one step on real PCs, after steps 3b–5b. Every step that leaves
      something to check on real hardware adds it to this list instead of keeping it
      open on its own.

      | # | Check | Hardware | From |
      |---|---|---|---|
      | 6.1 | UEFI boot from the PC's own firmware, GRUB menu and automatic slot choice | any UEFI PC | D-026 |
      | 6.2 | BIOS boot with the same image | PC with legacy BIOS (or CSM) | step 4e, R-26 |
      | 6.3 | Dual boot: Windows detected by `os-prober` and bootable from the menu | PC with Windows | step 5b, D-009 |
      | 6.4 | Encrypted data partition: creation, unlocking with password and recovery key, without TPM | PC without TPM | steps 4a, 4d, R-27 |
      | 6.5 | TPM as an extra unlock method | PC with TPM 2.0 | step 4d |
      | 6.6 | A/B update and automatic rollback, EFI partition check after a power cut | any PC | D-026, D-038 |
      | 6.7 | Graphics: Intel (i915/xe), AMD (amdgpu/radeon), NVIDIA (nouveau), screen from the first moment, laptop brightness | PCs with each GPU | D-025 |
      | 6.8 | Intel audio with SOF: speakers, headphones, microphones | Intel laptop, 11th generation or later | step 3a, D-039 |
      | 6.9 | AMD audio: does the laptop need SOF firmware (not available today)? | recent AMD laptop | D-039 |
      | 6.10 | HD Audio and HDMI/DisplayPort audio on desktops | desktop PC | D-025 |
      | 6.11 | Wi‑Fi (Intel, Realtek, MediaTek, Atheros, Broadcom) and regulatory database | PCs/adapters available | D-025 |
      | 6.12 | Bluetooth: pairing a keyboard/mouse and headphones | PCs/adapters available | D-025 |
      | 6.13 | Wired network (Intel, Realtek, USB adapters) | PCs/adapters available | D-025 |
      | 6.14 | Input: keyboard, I2C touchpad and touchscreen (DesignWare I2C, GPIO interrupts), laptop buttons, USB devices, USB 4/Thunderbolt | Intel and AMD laptops | D-025, D-041 |
      | 6.15 | Laptop platform: battery, AC adapter, buttons, fans, temperatures, CPU frequency | laptop | D-025 |
      | 6.16 | Disks: NVMe, SATA, USB sticks, SD card reader, NTFS and exFAT partitions | PCs available | D-025 |
      | 6.17 | Early microcode loading (Intel and AMD) | Intel and AMD PCs | step 3b |
      | 6.18 | Baseline x86-64: boot on an old 64-bit processor (before 2008) | old PC, if available | D-027, R-28 |
      | 6.19 | Measurements: image size, idle memory, boot time | every PC tested | D-034 |
      | 6.20 | Boot and display as a guest of VMware and Hyper‑V (Generation 2), and of VirtualBox | the three hypervisors | D-041 |

**Next steps:**
- [x] Guide and scripts for the build host and the emulator (`docs/development.md`,
      `tools/setup-host.sh`, `tools/build.sh`, `tools/run-qemu.sh`, D-028)
- [x] First full build and boot in QEMU on the user's machine
  - [x] First full build on the laptop (2026-11-11)
  - [x] Boot in QEMU with `tools/run-qemu.sh` (2026-11-12): login, encrypted data
        partition, slot A confirmed by RAUC, data persistent after reboot
- [x] Test in QEMU of an A/B update with a RAUC bundle and of the automatic rollback to
      the previous version (2026-11-12)
- [ ] Dual boot test in QEMU with Windows installed
- [ ] Basic services: network, audio (PipeWire + WirePlumber), Bluetooth (BlueZ)
- [x] Every component with its reason recorded (AGENTS.md §5.5): inventory of the
      current image and removal of the superfluous packages (2026-11-12, D-038); to be
      kept up to date at every new package
- [x] Check of the EFI partition at every boot (`fsck.vfat`, D-038)
- [x] The PC restarts by itself (`systemd.crash_action=reboot`) when a corrupted
      system block stops the boot, so the rollback needs no manual reset (the user's
      choice, D-047; tested in QEMU 2026-11-12)
- [ ] Understand the `dbus-daemon` "Failed to drop supplementary groups" message seen
      at every boot (D-038)
- [ ] Decide on swap (zram or swap file) with the memory budget; today only the
      tools are installed, as a systemd dependency (D-038)
- [ ] Vulnerability monitoring process for the components (D-012)
- [ ] Size budget: the NVIDIA firmware for nouveau (GSP) is 109 MB of the image, keep
      only the versions the kernel loads (D-041 review); the initramfs is 18.9 MB
      compressed because of systemd's hard dependencies (D-043)
- [ ] Measure image size and idle memory; record them in `MEMORY.md`
      *(QEMU: 610 MB, ~77 MB of RAM, D-038; on real hardware in step 6.19)*
- [x] Regenerate `branding/previews/grub-menu.png` with the English menu texts
      (2026-11-12, Inter 4.1 from the official release, D-046)

## Phase 2 — Graphics stack: WebKitGTK from the fork and compositor · `proposed`

- [x] Fork `aptecstudio/WebKit` with work branch `project-os/2.54` from
      `webkitglib/2.54` (D-019)
- [ ] Inventory of the known vulnerabilities of the starting version and check that
      they are all fixed in the fork
- [ ] Documented procedure: integration of each official security release, re-applying
      our patches, new tag of the fork
- [ ] Hardening: unneeded WebKit features disabled, restrictive build options
- [ ] Mesa and GTK 4 in the image; WebKitGTK recipe that builds from the fork
- [ ] Minimal Rust/Smithay compositor (D-007, D-013)
- [ ] A WebKitGTK window on screen in the image, in QEMU and on real hardware

## Phase 3 — Broker, permissions and sandbox · `proposed`

- [ ] Specification of the permission model (`docs/permissions.md`)
- [ ] Broker daemon in Rust with authenticated IPC
- [ ] Per-process sandbox (namespaces + seccomp), deny by default
- [ ] Basic APIs: filesystem, devices, windows, system services (R-12)
- [ ] Mediated root requests with confirmation and audit log (R-13)
- [ ] Signed app package format (DA-05)
- [ ] Security tests with a Rust client: a process does not exceed the granted
      permissions
- [ ] Plan the ecosystem APIs (`devices.*`, D-033) in the permission model

## Phase 4 — App runtime · `proposed`

Goal: the application model (R-07, R-09) on top of broker and compositor.

- [ ] Cargo workspace with bindings to WebKitGTK 6.0 and JavaScriptCore
- [ ] v0 specification of the `package.json` format (`docs/manifest.md`)
- [ ] Specification of the `system` object APIs (`docs/api/`, D-029), with the class and
      event model (R-35, D-045)
- [ ] System API developer guide (R-36): `docs/api/` indexed by namespace, one page per
      namespace (classes, methods, events, permission in `package.json`, errors,
      examples), written together with each API
- [ ] Specification of the `systemui` library (`docs/api/ui.md`, R-34, D-045): base
      component class, built-in components, custom components, events, ownership of
      the DOM tree and removal; `systemui` declaration in `package.json`
- [ ] `app://` protocol bound to the app folder, separate WebKit context per app, path
      checks (D-031)
- [ ] `include()` and `includeAsync()`: own scope, `exports`, cache, cycle error with
      the chain (D-030); tests of the edge cases (synchronous and asynchronous cycles,
      errors halfway through loading)
- [ ] `system` object exposed only with the declared and granted namespaces (D-029)
- [ ] Native host that reads the manifest, creates an isolated JavaScriptCore context
      and runs the main script
- [ ] `window` API: opening, closing and communication with WebKitGTK windows bound to
      the process; message channel main script ↔ windows (Electron style)
- [ ] App subprocesses with cascading termination
- [ ] Connection of the system APIs to the broker, according to the manifest
      permissions
- [ ] Sample "hello" app with two windows

## Phase 5 — Shell, visual style and system dialogs · `proposed`

- [ ] Define the visual style, a Windows 11 / macOS Big Sur / MIUI hybrid (D-032), and
      record it in `MEMORY.md` §3
- [ ] `systemui` library (R-34, D-045): wrapper that creates and owns the DOM elements,
      their tree and their removal; built-in components (buttons, headers, footers,
      text fields, lists…) with the system style; custom components; tests of the
      component lifecycle (no leaks, no orphan elements)
- [ ] `systemui` developer guide (R-36, D-045): a `docs/systemui/` folder of Markdown
      pages, indexed and organized by component (one page per component: purpose,
      constructor options, properties, methods, events, examples), plus getting
      started, custom components and lifecycle pages; written together with each
      component, not at the end
- [ ] Shell: panel, launcher, window management, notifications
- [ ] Library of predefined system dialogs (R-10), built with `systemui`
- [ ] `xdg-desktop-portal` backend and polkit agent with HTML dialogs
- [ ] Adaptive desktop ↔ mobile layout, touch input

## Phase 6 — System applications · `proposed`

All system apps are built with `systemui` (R-34), without HTML written by hand.

- [ ] Settings (network, Bluetooth, audio, display, app permissions)
- [ ] File manager
- [ ] Terminal
- [ ] App manager
- [ ] "Devices" panel in Settings: pairing, list, revocation (D-033)

## Phase 7 — Android-based arm64 mobile · `proposed`

- [ ] **Feasibility check (to be brought forward as soon as possible):** WebKitGTK with
      EGL through libhybris on the user's Pixel; it is the main technical risk on the
      mobile side (D-014)
- [ ] Same user space compiled for arm64, without changes
- [ ] `meta-project-os-mobile` layer: Halium/libhybris
- [ ] Pixel: vendor kernel and firmware, GPU, touch, audio, Wi‑Fi, Bluetooth
- [ ] Pixel: modem (calls, text messages, data), sensors, camera
- [ ] Recovery installation package for the Pixel (D-011)
- [ ] Oppo and Samsung: model assessment (bootloader, recovery), then porting
- [ ] Touch gestures, on-screen keyboard, rotation, power management

## Phase 8 — Installation, setup and updates · `proposed`

- [ ] Desktop USB installation image: boots straight into the wizard, no live mode
      (D-010, R-19)
- [ ] Setup app with per-platform steps (D-017):
  - [ ] desktop: language, keyboard, time zone, network, partitioning and formatting
        (next to Windows too), encryption, user, installation with GRUB
  - [ ] mobile (first boot after the recovery): language, Wi‑Fi/SIM, time zone, user
        and unlock code, permissions, preferences
- [ ] Secure Boot with project-os keys enrolled by the user (D-009)
- [ ] Signing of packages and images; keys outside the repository
- [ ] Signed A/B updates with automatic rollback to the previous version (D-018), on
      desktop and mobile

## Phase 9 — Ecosystem: interoperability between devices · `proposed`

Goal: the same user's project-os devices, desktop and mobile, work together as a single
ecosystem (R-33, D-033). Requires DA-12.

- [ ] Protocol specification (`docs/continuity.md`): pairing, keys, end-to-end
      encrypted channel, discovery, revocation, versions
- [ ] Continuity daemon in Rust, integrated with the broker
- [ ] Pairing with a QR or numeric code; optional step in the setup (D-017)
- [ ] Sending files and links between nearby devices
- [ ] Shared clipboard
- [ ] The phone's notifications, calls and text messages on the desktop
- [ ] App continuity API (*handoff*) in the `system` object, with a permission in the
      manifest
- [ ] Sync of settings, contacts, calendar, passwords and Wi‑Fi networks
- [ ] Instant hotspot and unlocking the desktop with the phone
- [ ] Security tests: an unpaired or revoked device accesses nothing
- [ ] Later: tablet as a second screen, shared keyboard and mouse

---

## Progress log

| Date | Phase | What |
|---|---|---|
| 2026-11-11 | 0 | Created `AGENTS.md`, `MEMORY.md`, `ROADMAP.md` |
| 2026-11-11 | 0 | Decided own compositor, JavaScriptCore runtime, mediated root; ARM brands given |
| 2026-11-11 | 0 | Added installation requirements (mobile recovery, desktop wizard), boot menu with dual boot, no live mode (R-16…R-19); proposed D-009…D-011 |
| 2026-11-11 | 0 | Change of approach: from Debian to a system built from source, single desktop/mobile user space on an Android base, Rust, Pixel as first device, differentiated setup (R-20…R-24, D-012…D-017) |
| 2026-11-11 | 0 | Decided Yocto and immutable A/B updates (D-012, D-018); `AGENTS.md` §1 updated with authorization |
| 2026-11-11 | 0 | Decided the WebKitGTK fork maintained by the project (D-019) |
| 2026-11-11 | 2 | Created the `aptecstudio/WebKit` fork and the `project-os/2.54` branch (current numbering: Phase 2) |
| 2026-11-11 | 0 | Approved D-006, D-009…D-011, D-014…D-017; GPL-3.0 license; phases in sequence |
| 2026-11-11 | 0 | Roadmap reordered from the bottom up: base system → graphics → broker → runtime → shell → apps → mobile → installation (D-022) |
| 2026-11-11 | 1 | Placeholder logo and GRUB theme with preview (D-023); logo made monochrome white on request; theme approved and merged into `main` |
| 2026-11-11 | 0 | New requirements: backward compatibility at every level, UEFI and BIOS boot, encryption without TPM, baseline x86-64 (R-25…R-28, D-027) |
| 2026-11-11 | 1 | A/B partitions, slot selection in GRUB, RAUC, encrypted data partition on first boot, on the `build/ab-partitions` branch (D-026, steps 4a and 4b) |
| 2026-11-11 | 1 | Work suspended at the user's request; prepared guide and scripts to build and test the image on their PC (D-028) |
| 2026-11-11 | 0 | Added the presentation `README.md`, at the user's request; dark variant of the placeholder logo for light backgrounds |
| 2026-11-11 | 0 | New specifications: APIs in the global `system` object, `include`/`includeAsync` with cycle error, `app://` protocol for the isolated app folder, Windows 11 / Big Sur / MIUI hybrid design (R-29…R-32, D-029…D-032) |
| 2026-11-11 | 1 | User's laptop as temporary build host: `kas/low-resources.yml`, enabled by `tools/build.sh` below 16 GB of RAM (D-034) |
| 2026-11-11 | 1 | **First full build succeeded** on the laptop (19:42 → 23:25, with three fixes: D-035, `features_check` in `project-os-storage`, `.wks.in` disk layout); `wic` image with 695 MB actually used; QEMU test missing |
| 2026-11-11 | 1 | First build on the laptop stopped and restarted: kernel from the Yocto HTTP mirror (the git server runs at 17 KB/s), removed QEMU/Mesa/LLVM built by Yocto (D-035) |
| 2026-11-11 | 9 | New requirement: interoperability between project-os devices as an ecosystem (R-33); proposed Phase 9 and D-033, opened DA-12 |
| 2026-11-11 | 1 | Yocto layers, distribution, amd64 machine, base image and kas configuration (D-024); bitbake read check passed; kas and x86-64-v2 approved, merged into `main` |
| 2026-11-11 | 1 | Kernel and firmware for desktop hardware (D-025): 147 options checked on 6.18, 27 firmware packages; approved and merged into `main` |
| 2026-11-11 | 0 | `README.md` for those who want to know the project: what it will offer, devices, status, license; dark variant of the logo for light backgrounds |
| 2026-11-12 | 1 | First test in QEMU: GRUB and kernel start; fixed missing `mkfs.ext4` for systemd-repart, ESP in fstab as `/dev/sda2` and missing `/efi` directory; `run-qemu.sh` opens the window from snap apps too. **Login reached**: encrypted data mounted and persistent, slot A confirmed by RAUC |
| 2026-11-12 | 1 | A/B test in QEMU: bundle installed, automatic boot of slot B and rollback to A after an interrupted boot; fixed `ext4` image for the bundle, `1`/`0` values in `grubenv`, mounting of `/efi` with `efi.mount` |
| 2026-11-12 | 1 | `tools/build.sh`: full-performance default mode, low resources on request; RAM and disk check with warnings; guide updated for those who reproduce the build without help (D-036) |
| 2026-11-12 | 0 | Repository in English: comments, options and messages of the scripts (`--low-resources`, `--text`, `image`/`update`/`shell`), recipes, GRUB menu, documentation, `MEMORY.md` and `ROADMAP.md`; `docs/sviluppo.md` → `docs/development.md`; `AGENTS.md` §6 rewritten as a fixed rule and the whole file translated, with authorization (v1.3, D-037) |
| 2026-11-12 | 1 | User's review: D-026, D-028, D-034, D-035, D-036 confirmed; `build/ab-partitions` merged into `main` |
| 2026-11-12 | 1 | Phase 1 cleanup (D-038): package inventory with reasons, removed syslog, udhcpc, Pine64 keymaps, libssh/libgcrypt and the volatile tmpfs layout; EFI partition checked at every boot; kernel configcheck clean; full QEMU test including A/B update and rollback |
| 2026-11-12 | 1 | D-038 approved by the user; `build/phase1-cleanup` merged into `main` |
| 2026-11-12 | 1 | Step 3a: `sof-bin` recipe for the Intel SOF audio firmware, compressed with zstd, without debug files and ARM topologies (D-039) |
| 2026-11-12 | 1 | Real hardware checks gathered in one test session, step 6, with the full list (D-040, at the user's request) |
| 2026-11-12 | 1 | Video drivers review: VMware/Hyper‑V drivers and the laptop I2C/GPIO drivers had been silently dropped by the kernel; fixed, and the build now checks every fragment option against the final configuration (D-041) |
| 2026-11-12 | 1 | D-039, D-040, D-041 approved, `build/sof-firmware` merged into `main`; plan of 3b + 4c approved with overlay `/etc` and UKI + separate kernel per slot (D-042) |
| 2026-11-12 | 1 | Steps 4c.1 and 3b: systemd initramfs and early Intel/AMD microcode loaded by GRUB; boot, A/B update and rollback tested in QEMU (D-043) |
| 2026-11-12 | 1 | Step 4c.2: data partition created, unlocked and mounted by the initramfs, persistent `/etc` overlay, update conflict report; tested in QEMU with reboot, A/B update, simulated conflict and rollback (D-044) |
| 2026-11-12 | 0 | QEMU test convention recorded in `MEMORY.md` §5: full A/B test for changes to the boot chain, boot test for changes inside the system |
| 2026-11-12 | 4–6 | New requirements: `systemui` library (`system.ui.*`, declared in `package.json`, classes and events, custom components, no HTML) and class/event model for all APIs (R-34, R-35, D-045); roadmap items in Phases 4, 5, 6 |
| 2026-11-12 | 0 | Code style rule written into `AGENTS.md` §7 at the user's request; `tools/lint.sh` with ShellCheck, ruff, oelint-adv; all existing code reviewed, bbappends limited to our distribution/machine (D-046) |
| 2026-11-12 | 5 | New requirement: `systemui` developer guide in `docs/systemui/`, indexed Markdown pages by component (R-36, D-045) |
| 2026-11-12 | 4 | Developer guide extended to all system APIs, `docs/api/` by namespace (R-36, the user's choice) |
| 2026-11-12 | 1 | Step 4c.3: erofs slots verified by dm-verity, root hash per slot on the EFI partition written by the bundle hook before activation; tested in QEMU with boot, A/B update, rollback and a corrupted block that stops the boot (D-047) |
| 2026-11-12 | 1 | D-047 approved; automatic restart when PID 1 cannot go on (`systemd.crash_action=reboot`), so a corrupted slot rolls back without a manual reset; `grub.cfg` tracked by the disk image build; tested in QEMU |

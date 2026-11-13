# ROADMAP.md — Project status

Steps done and steps to do, to give an overall and per-phase status.
Update rules in `AGENTS.md` §3: this file describes only the current state.

**Phase states:** `proposed` → `approved` → `in progress` → `completed` (or `suspended`).
Work happens only on `approved` or `in progress` phases.

## Overall status

Order **from the bottom up** (D-022): first the system, then what runs on top of it.
Phases are carried out **one at a time**, in order (D-021).

| Phase | Title | Status |
|---|---|---|
| 0 | Foundations and decisions | `in progress` |
| 1 | Base system: Yocto, kernel, boot | `in progress` |
| 2 | Graphics stack: EGL/GLES, Skia, compositor, WPE WebKit from the fork | `proposed` |
| 3 | Broker, permissions, sandbox and `.pak` packages | `proposed` |
| 4 | App runtime: Luau host, `systemui` framework, `app://` | `proposed` |
| 5 | Shell, visual style and system dialogs | `proposed` |
| 6 | System applications | `proposed` |
| 7 | Android-based arm64 mobile (Pixel, then Oppo and Samsung) | `proposed` |
| 8 | Installation, setup and updates | `proposed` |
| 9 | Ecosystem: interoperability between devices | `proposed` |

**Next step:** step 4d (data unlocking with password and recovery key) on the
`build/verified-boot` branch; then 4e, 5b, and the real hardware test session (step 6)
with all the hardware checks together. One step at a time, with the user's
confirmation. Awaiting approval: the `proposed` details of the new application model
(D-049, D-050, D-052, D-053).

---

## Open decisions

To be settled with the user before starting the phases indicated. Once decided, they
move to `MEMORY.md` as a `confirmed` entry and leave this list.

- [ ] **DA-03 — Reference mobile devices** *(blocks Phase 7)*
  First: the user's Google Pixel (exact model to be given). Then: the older Oppo and
  Samsung models the user owns (exact models to be given). For each one: unlockable
  bootloader? custom recovery available?
- [ ] **DA-05 — App package format** *(blocks Phase 3)*
  `.pak` (R-39) with a signature over the whole file, read in place: details proposed
  in D-052, to be approved.
- [ ] **DA-06b — Final name of the system** *(not blocking; "project-os" for now)*
- [ ] **DA-11 — Build host** *(blocks the Phase 1 checks)*
  Yocto must run on a machine of the user's (VM or physical): at least 16 GB of RAM,
  250 GB of disk, many cores. Ubuntu Server 24.04/26.04 LTS recommended. Guide and
  scripts ready (`docs/development.md`, `tools/setup-host.sh`); the machine is missing.
  *Temporary solution (D-034):* the user's laptop, Debian 13 (4 cores, 7.4 GB of RAM,
  42 GB free), with `tools/build.sh --low-resources` (D-036); enough for Phase 1, not
  for WPE WebKit and Skia (Phase 2).
- [ ] **DA-12 — Ecosystem between devices** *(blocks Phase 9; affects Phases 3, 4, 6)*
  To decide: (a) local network and Bluetooth only, or also a relay service for distant
  devices, and in that case hosted by whom (the user themselves, the project);
  (b) network discovery with mDNS (re-enabling `zeroconf`) or with an own announcement;
  (c) compatibility with devices that do not run project-os (e.g. the KDE Connect
  protocol for Android and Linux) or an ecosystem reserved to project-os only;
  (d) order of the features listed in D-033.

---

## Phase 0 — Foundations and decisions · `in progress`

- [x] Repository `project-os` with main branch `main`, GPL-3.0 license (D-020)
- [x] Governance documents: `AGENTS.md`, `MEMORY.md`, `ROADMAP.md`
- [x] Architecture decided and approved: system built from source with Yocto, Rust,
      own compositor, mediated root, immutable A/B updates (D-005…D-022)
- [x] Repository in English: code, documentation and commits (D-037)
- [x] Code style rule in `AGENTS.md` §7, checks in `tools/lint.sh`, existing code
      reviewed (D-046)
- [x] Native application model: Luau, own framework on EGL with Skia, WPE WebKit for
      web views, folder and `.pak` apps, XML layouts; shell, dialogs and setup native
      (R-37…R-41, D-049…D-054)
- [ ] Approval of the `proposed` details of D-049, D-050, D-052, D-053
- [ ] Build host ready (DA-11)

## Phase 1 — Base system: Yocto, kernel, boot · `in progress`

Goal: an amd64 image built from source that boots in QEMU/UEFI and on real hardware,
with boot menu, A/B partitions and full hardware support.

**Steps:**
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
  - [x] 4c. erofs + dm-verity system, systemd initramfs, unified kernel image (UKI) per
        slot, persistent `/etc` (plan in D-042)
    - [x] 4c.1 systemd initramfs with early Intel and AMD microcode (together with 3b,
          D-043)
    - [x] 4c.2 persistent `/etc`: overlay on the data partition, update conflicts
          reported (D-044)
    - [x] 4c.3 erofs system verified by dm-verity: root hash per slot on the EFI
          partition, written by the bundle hook; a corrupted block stops the boot
          (D-047)
    - [x] 4c.4 UKI per slot on the EFI partition (two profiles, @0 slot A and @1 slot
          B), plus separate kernel + initramfs for BIOS boot; lz4hc slots (D-048)
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
- [ ] Remove from the slot the unused `/boot/EFI/BOOT` files of the `grub-efi` package
      (D-048)
- [ ] Update GRUB and `grub.cfg` on the EFI partition with RAUC (today only the slots
      and their boot files are updated, D-048)
- [ ] Size budget: the NVIDIA firmware for nouveau (GSP) is 109 MB of the image, keep
      only the versions the kernel loads (D-041 review); the initramfs is 18.9 MB
      compressed because of systemd's hard dependencies (D-043)
- [ ] Measure image size and idle memory; record them in `MEMORY.md`
      *(QEMU: 610 MB, ~77 MB of RAM, D-038; on real hardware in step 6.19)*
- [x] Regenerate `branding/previews/grub-menu.png` with the English menu texts
      (2026-11-12, Inter 4.1 from the official release, D-046)

## Phase 2 — Graphics stack: EGL/GLES, Skia, compositor, WPE WebKit from the fork · `proposed`

- [x] Fork `aptecstudio/WebKit` with work branch `project-os/2.54` from
      `webkitglib/2.54` (D-019)
- [ ] Mesa (EGL, OpenGL ES 2/3) in the image, with a software renderer for machines
      without a usable GPU
- [ ] Minimal Rust/Smithay compositor (D-007, D-013)
- [ ] Skia recipe built from source (gn, ninja) and `skia-safe` bindings built against
      it, never prebuilt binaries (D-050)
- [ ] A Rust test client that draws with Skia on EGL into a Wayland surface, GPU and CPU
      paths, in QEMU and on real hardware
- [ ] WPE WebKit recipe that builds from the fork (`-DPORT=WPE`, D-051)
- [ ] Inventory of the known vulnerabilities of the starting version and check that
      they are all fixed in the fork
- [ ] Documented procedure: integration of each official security release, re-applying
      our patches, new tag of the fork
- [ ] Hardening: unneeded WebKit features disabled, restrictive build options
- [ ] A WPE web view drawn as a texture inside the Skia scene of the test client

## Phase 3 — Broker, permissions, sandbox and `.pak` packages · `proposed`

- [ ] Specification of the permission model (`docs/permissions.md`)
- [ ] Broker daemon in Rust with authenticated IPC
- [ ] Per-process sandbox (namespaces + seccomp), deny by default
- [ ] Basic APIs: filesystem, devices, windows, system services (R-12)
- [ ] Mediated root requests with confirmation and audit log (R-13)
- [ ] `.pak` format (DA-05, D-052): reader in place, entry name and size checks,
      signature over the whole file, developer mode for unsigned folders; tests with
      malformed archives (path traversal, duplicates, zip bombs, mismatched headers)
- [ ] Security tests with a Rust client: a process does not exceed the granted
      permissions
- [ ] Plan the ecosystem APIs (`devices.*`, D-033) in the permission model

## Phase 4 — App runtime: Luau host, `systemui` framework, `app://` · `proposed`

Goal: the application model (R-09, R-37…R-40) on top of broker and compositor.

- [ ] Cargo workspace with the Luau host (`mlua`), the framework (Skia, `taffy`,
      `accesskit`) and the WPE bindings
- [ ] Luau style tools (StyLua, selene, `luau-analyze`) installed by
      `tools/setup-host.sh`; `tools/lint.sh` already runs them on `*.lua`/`*.luau` files
- [ ] v0 specification of the `package.json` format (`docs/manifest.md`)
- [ ] Specification of the `system` object APIs (`docs/api/`, D-029), with the class and
      event model (R-35, D-045) and waiting calls on coroutines (D-053)
- [ ] System API developer guide (R-36): `docs/api/` indexed by namespace, one page per
      namespace (classes, methods, events, permission in `package.json`, errors,
      examples), written together with each API
- [ ] Specification of `systemui` (`docs/api/ui.md`, R-34, D-045): base component class,
      built-in components, custom components, events, component tree and removal, XML
      layout schema (R-40, D-053); `systemui` declaration in `package.json`
- [ ] Luau host: one sandboxed VM per app, only source code loaded, memory limit and
      interrupt, `class()`, coroutine scheduler (D-049, D-053)
- [ ] `app://` resolver bound to the app folder or `.pak`, path checks (D-031, D-052)
- [ ] `include()` and `includeAsync()`: own scope, exports, cache, cycle error with the
      chain (D-030); tests of the edge cases (synchronous and asynchronous cycles,
      errors halfway through loading)
- [ ] `system` object exposed only with the declared and granted namespaces (D-029)
- [ ] Framework core: windows on Wayland surfaces, layout, text, input, focus,
      animations, accessibility (D-050)
- [ ] XML layouts parsed and validated against the schema, `self:find("id")`, event
      binding to the controller class (D-053)
- [ ] `WebView` component on WPE with a declared message channel, never access to
      `system` (D-051)
- [ ] App subprocesses with cascading termination; background workers in separate VMs
- [ ] Connection of the system APIs to the broker, according to the manifest
      permissions
- [ ] Luau type definitions of `system` and `systemui` in `sdk/`, checked with
      `luau-analyze`
- [ ] Sample "hello" app with two windows, one layout in Lua and one in XML, as a folder
      and as a `.pak`

## Phase 5 — Shell, visual style and system dialogs · `proposed`

- [ ] Define the visual style, a Windows 11 / macOS Big Sur / MIUI hybrid (D-032), and
      record it in `MEMORY.md` §3
- [ ] `systemui` built-in components (buttons, headers, footers, text fields, lists…)
      with the system style; custom components; tests of the component lifecycle (no
      leaks, no orphan nodes) (R-34, D-045)
- [ ] `systemui` developer guide (R-36, D-045): a `docs/systemui/` folder of Markdown
      pages, indexed and organized by component (one page per component: purpose,
      properties, XML attributes, methods, events, examples), plus getting started,
      custom components and lifecycle pages; written together with each component, not
      at the end
- [ ] Shell as a native Lua app: panel, launcher, window management, notifications
      (D-054)
- [ ] Library of predefined system dialogs (R-10), built with `systemui`
- [ ] `xdg-desktop-portal` backend and polkit agent with native dialogs (D-006)
- [ ] Adaptive desktop ↔ mobile layout, touch input

## Phase 6 — System applications · `proposed`

All system apps are Lua apps built with `systemui` (R-34, R-37).

- [ ] Settings (network, Bluetooth, audio, display, app permissions)
- [ ] File manager
- [ ] Terminal
- [ ] App manager (`.pak` installation and removal)
- [ ] Web browser on WPE WebKit (R-41, D-051)
- [ ] "Devices" panel in Settings: pairing, list, revocation (D-033)

## Phase 7 — Android-based arm64 mobile · `proposed`

- [ ] **Feasibility check (to be brought forward as soon as possible):** the framework
      (Skia on EGL) and WPE WebKit through libhybris on the user's Pixel; it is the main
      technical risk on the mobile side (D-014). Fallback for web views: Igalia's WPE
      port for Android (D-051)
- [ ] Same user space compiled for arm64, without changes
- [ ] `meta-project-os-mobile` layer: Halium/libhybris
- [ ] Pixel: vendor kernel and firmware, GPU, touch, audio, Wi‑Fi, Bluetooth
- [ ] Pixel: modem (calls, text messages, data), sensors, camera
- [ ] Recovery installation package for the Pixel (D-011)
- [ ] Oppo and Samsung: model assessment (bootloader, recovery), then porting
- [ ] Touch gestures, on-screen keyboard, rotation, power management

## Phase 8 — Installation, setup and updates · `proposed`

- [ ] Desktop USB installation image: boots straight into the native wizard, no live
      mode, no web engine (D-010, R-19)
- [ ] Native setup app with per-platform steps (D-017, D-054):
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


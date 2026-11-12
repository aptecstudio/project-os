# MEMORY.md — Choices, style and conventions

Record of the project decisions and their reasons, of the visual style, of the code
structure and of the syntax conventions. Update rules in `AGENTS.md` §3.

**Decision states:** `requirement` (set by the user) · `confirmed` (approved) ·
`proposed` (awaiting approval) · `superseded` (replaced, see the entry indicated).

*Translated from Italian to English on 2026-11-12, at the user's request (D-037). The
content, including superseded choices, is unchanged; state names are translated
(`requisito` → `requirement`, `confermata` → `confirmed`, `proposta` → `proposed`,
`superata` → `superseded`).*

---

## 1. Basic requirements

Set by the user on 2026-11-11.

| ID | Requirement |
|---|---|
| ~~R-01~~ | ~~The system derives from a stable Debian release.~~ *Superseded by R-20.* |
| R-02 | System reduced to the essentials: no superfluous packages, clean and light. *(Reworded without Debian after R-20.)* |
| R-03 | **Wayland** for video and input devices. |
| R-04 | Keep support for the main modern hardware (audio, Bluetooth, Wi‑Fi, GPU, etc.) in the kernel and firmware. |
| R-05 | Architectures: **mobile ARM** (smartphones, tablets) and **Intel/AMD desktop**. |
| R-06 | Graphical interface made with the stable release of **WebKitGTK**. |
| R-07 | Each application (shell and panels included) has a **main JavaScript script** that can open windows bound to its own process, Electron style but based on WebKitGTK. |
| R-08 | Rendering and animations handled entirely by the WebKit engine. |
| R-09 | Each application is a process that can have subprocesses. |
| R-10 | All system dialogs are replaced by predefined HTML + JS + CSS dialogs. |
| R-11 | Each application declares in its `package.json` name, metadata and the native APIs it requires, also as an extra security layer. |
| R-12 | Each application has basic system APIs: filesystem, devices, windows, system services. |
| R-13 | An application can request root access from its `package.json` and/or through dedicated APIs. |
| R-14 | The system must be **secure**. |
| R-15 | Main branch of the repository: `main`. |
| R-16 | **Mobile:** installation through the device recovery; the setup continues on first boot with an HTML interface. |
| R-17 | **Desktop:** installation with a wizard application in Windows/Debian style, with HTML rendering like all the other apps. |
| R-18 | **Desktop:** boot menu with centered entries and the system logo (a generic logo at first), allowing dual boot with Windows or other systems. |
| R-19 | No live mode for now. |

| R-20 | **No starting distribution:** start from Linux (the kernel) and build every package on top. |
| R-21 | **One system, two bases:** with few changes, the Android-based mobile version (vendor kernel and drivers) and the desktop one; both on Linux. |
| R-22 | Native components in **Rust**. |
| R-23 | First mobile device: the user's **Google Pixel**. Not to be neglected: older **Oppo** and **Samsung** models the user owns. |
| R-24 | **Differentiated setup:** on desktop it includes disk formatting, keyboard layout and basic configuration; on mobile it asks for other data or starts from later steps (the system is already installed from the recovery). |

| R-25 | **Backward compatibility at every level and in every context of the project**: hardware, boot, formats, APIs, data, updates. |
| R-26 | **Desktop:** boot from both UEFI and legacy BIOS, with the same image. |
| R-27 | **Encryption without TPM:** the data partition must work on older PCs without a TPM chip too. |
| R-28 | **Desktop processors:** all 64-bit x86 processors (baseline x86-64 instructions). |
| R-29 | **App APIs as objects in the script context**, like the `chrome.*` APIs of extensions: apps reach them from a global object, without importing them. |
| R-30 | **Dynamic script loading with `include("url")`** and its counterpart **`includeAsync("url")`**, not with CommonJS or ES modules. Each included script has an `exports` object with the symbols it exposes to the includer; included scripts are cached; cyclic imports are prevented. |
| R-31 | **Isolated root folder for each app:** scripts, images and other resources are loaded only from there, with a dedicated protocol (`app://`), and only the app itself can access its own resources. External files only through the filesystem system APIs. |
| R-32 | **Design:** a hybrid of Windows 11, macOS Big Sur and Xiaomi MIUI. |
| R-33 | **Interoperability between devices:** the devices running project-os, desktop and mobile, cooperate as a single ecosystem, on the model of Apple's. |

*R-16…R-19 added by the user on 2026-11-11. R-20…R-24 added the same day: change of
approach, from Debian to a system built from scratch. R-25…R-28 added the same day.
R-29…R-32 added the same day (evening). R-33 added the same day, from the laptop.*

---

## 2. Decision log

### D-001 — Debian 13 "Trixie" as the base · `superseded` by D-012 (R-20)
- **What:** start from the current stable, Debian 13, on the `main`, `contrib`,
  `non-free-firmware` components, plus `trixie-security` and `trixie-updates`.
- **Why:** it is the stable release supported the longest (security until 2028, LTS
  beyond) and includes WebKitGTK for GTK 4 (`webkitgtk-6.0` API), which receives
  security updates.
- **Discarded alternatives:** testing/unstable (contradicts R-01).

### D-002 — Build by addition, not by subtraction · `superseded` by D-012 (the principle stays: every component enters only with a reason)
- **What:** generate the system with `mmdebstrap --variant=minbase` (or `debos` for the
  images) and add an explicit list of packages, instead of installing full Debian and
  then removing.
- **Why:** it is reproducible, each package has a reason (AGENTS.md §5.5) and no orphan
  dependencies remain. `--no-install-recommends` enabled by default.
- **Discarded alternatives:** standard installation + removal (fragile, leaves leftovers).

### D-003 — Full Debian kernel and firmware · `superseded` by D-014 (the R-04 goal remains valid)
- **What:** use `linux-image-amd64` / `linux-image-arm64` with all modules, plus
  `firmware-linux-free`, `firmware-misc-nonfree`, `firmware-sof-signed` (Intel audio),
  `firmware-iwlwifi`, `firmware-realtek`, `firmware-atheros`, `firmware-brcm80211`,
  `firmware-amd-graphics`, `intel-microcode`, `amd64-microcode`; PipeWire + WirePlumber
  audio stack; BlueZ Bluetooth.
- **Why:** R-04. Reducing the user packages must not reduce hardware support; kernel
  modules that are not loaded cost nothing at runtime.
- **To check:** final firmware list for the chosen ARM devices.

### D-004 — Two levels of ARM support · `superseded` by D-014 (the constraints below remain valid)
- **What:** generic ARM64 (UEFI/device tree, e.g. SBCs, virtual machines) with the
  Debian kernel; smartphones and tablets only on an explicitly supported model list.
- **User's goal (2026-11-11):** the most popular smartphones on the market — Google
  Pixel, Samsung, Xiaomi, Oppo.
- **Known constraints:**
  - most of these phones do not boot a standard Debian kernel: either a per-device
    kernel is needed, or the vendor's Android kernel through Halium/libhybris (the
    approach of Droidian, also Debian-based);
  - with Halium the GPU goes through the Android drivers: WebKitGTK has to be checked
    on that path;
  - bootloader unlocking varies: generally possible on Pixels not tied to a carrier,
    limited or absent on several Samsung, Xiaomi and Oppo models.
- **Why:** promising "all ARM devices" is not realistic; models are chosen one by one.

### D-005 — Security: permission broker and per-app sandbox · `confirmed` (2026-11-11)
- **What:**
  - a system daemon (*broker*) is the only one exposing native APIs; apps talk to it
    through authenticated IPC (Unix socket, process identity checked with
    `SO_PEERCRED`);
  - each app runs in a sandbox (`bubblewrap` + `seccomp` filter), with filesystem,
    network and devices denied by default;
  - the permissions declared in `package.json` are an **upper bound**: the broker
    grants them only after installation/approval by the user;
  - root (R-13) never gives the app a root shell: the broker performs specific
    privileged operations on its behalf, after confirmation with a system dialog, and
    records them in the audit log.
- **Why:** R-13 and R-14 are in tension; an app with full root would cancel every other
  protection. Mediation keeps the functionality with a controlled risk.

### D-006 — System dialogs through portals · `confirmed` (2026-11-11)
- **What:** implement our own `xdg-desktop-portal` backend and polkit agent that show
  the requests (file selection, permissions, password, authentication) as HTML dialogs
  of the shell.
- **Why:** R-10. It is the point where GTK and the system services already ask for an
  interaction; replacing it there also covers software not written for project-os.

### D-007 — Own Wayland compositor · `confirmed` (2026-11-11)
- **What:** a minimal compositor written for project-os (wlroots or Smithay based, see
  DA-07). Each app window is a separate Wayland surface; the web shell draws panels and
  decorations through *layer-shell* and decides window layout and animations through a
  private compositor ↔ shell protocol.
- **Why:** R-08 and R-14: animations under the control of the web shell and windows
  isolated per process.
- **Discarded alternatives:** kiosk with internal WebViews (weak isolation), existing
  compositor (little control over animations).

### D-008 — Main script run on JavaScriptCore · `confirmed` (2026-11-11)
- **What:** the main script of each app runs in a JavaScriptCore context (WebKit's JS
  engine, GLib API `libjavascriptcoregtk-6.0`) hosted by a native project-os process,
  which exposes only the granted system APIs and creates the app's WebKitGTK windows.
- **Why:** same JS engine in main script and windows; no API exposed by default (unlike
  Node.js or GJS, which give access to files and processes), so the permission model
  starts from zero.
- **Consequence:** no native Node/npm modules; pure JS libraries remain usable through
  bundling.
- **Discarded alternatives:** GJS, Node.js.

### D-009 — Desktop boot menu: GRUB 2 with own theme · `confirmed` (2026-11-11)
- **What:** GRUB 2 (UEFI) with a project-os theme: centered menu, logo at the top, own
  background and fonts. Detection of Windows and other systems with `os-prober` (to be
  re-enabled with `GRUB_DISABLE_OS_PROBER=false`).
- **Secure Boot (revised after R-20):** without Debian there is no longer a `shim`
  already signed by Microsoft. Initial phase: project-os keys enrolled by the user
  (MOK) during installation; getting a shim signed by Microsoft is a long-term goal.
- **Logo:** generic SVG placeholder, exported to PNG for the theme, until the brand is
  defined.
- **Why:** R-18. GRUB supports graphical themes, multiboot and Secure Boot.
- **Discarded alternatives:** systemd-boot (no graphical theme); rEFInd (to be
  re-evaluated if GRUB turns out awkward to integrate without Debian).

### D-010 — Desktop installation medium · `confirmed` (2026-11-11)
- **What:** a USB installation image that starts only the bare minimum (kernel,
  compositor, runtime, broker) and opens the installation wizard directly; no user
  session or apps.
- **Why:** R-17 and R-19. The HTML wizard needs the rendering engine already running,
  so the installation environment has to boot; it remains however a closed environment
  dedicated to installation, not a usable live system.
- **The wizard handles:** language, keyboard, disk and partitions (next to an existing
  Windows too, without touching its boot), disk encryption, user, GRUB installation.

### D-011 — Mobile installation from recovery · `confirmed` (2026-11-11)
- **What:** for each supported model, a package installable from the recovery (e.g. a
  zip flashable from a custom recovery), plus the fastboot images where needed. On
  first boot the HTML setup app starts (see D-017 for the steps).
- **Why:** R-16. It is the standard method on Android phones with an unlocked
  bootloader.

### D-012 — System built from source with Yocto/OpenEmbedded · `confirmed` (2026-11-11)
- **What:** every component (toolchain, libc, libraries, WebKitGTK, kernel) is compiled
  from source with Yocto/OpenEmbedded, on the current LTS branch. Our code lives in own
  layers: `meta-project-os` (common user space, the same on all platforms),
  `meta-project-os-desktop` and `meta-project-os-mobile` (hardware layer, D-014), plus
  one layer for each mobile device.
- **Discarded alternatives:** Buildroot (struggles with WebKitGTK and with many
  devices), own tool in Rust (all to be written and maintained).
- **Why:** R-20. Full control over what goes into the system and reproducible builds.
- **Important consequence:** **update security** becomes the project's responsibility.
  Without an upstream distribution, every known flaw (WebKit in particular, which has
  many every year) has to be tracked and fixed by us. A vulnerability monitoring
  process is needed from Phase 1. For WebKitGTK see D-019.

### D-018 — Immutable system with A/B updates · `confirmed` (2026-11-11)
- **What:** read-only system partition, verified with dm-verity and signed; two slots
  (A/B): the update is written to the inactive slot and, if the boot fails, the system
  automatically goes back to the previous one. User data and apps on a separate
  (encrypted) partition. Apps are installed as signed packages (DA-05), outside the
  image. Candidate tool: RAUC (integrated in Yocto).
- **Why:** R-14 (the system cannot be altered at runtime) and atomic updates, the same
  on desktop and mobile, like Android and ChromeOS. Even the mediated "root" (D-005)
  cannot modify the system partition.
- **Discarded alternatives:** traditional package manager (less secure and predictable).

### D-019 — WebKitGTK fork maintained by the project · `confirmed` (2026-11-11)
- **What (decided by the user):** WebKitGTK is compiled from a fork of the project, on
  which we fix vulnerabilities ourselves.
- **Approach (proposed):** an *aligned* fork, not a diverging one:
  - the fork follows the official stable WebKitGTK branch (`webkitglib/<version>`) and
    receives every official security release as soon as it comes out (WSA advisories);
  - our changes are in separate, documented commits, re-applied on top of each new
    stable version;
  - our own fixes: for known vulnerabilities without an official fix, for hardening
    (unneeded features disabled, more restrictive build options) and for the
    integration with the broker and the JSC runtime;
  - each fix of ours, when of general interest, is proposed upstream.
- **Why:** a diverging fork loses the official fixes, which are the vast majority of
  those available (WebKit is a project of millions of lines with a dedicated security
  team); an aligned one adds a layer of ours without giving them up.
- **In Yocto:** the `webkitgtk` recipe of `meta-project-os` points to the fork and to
  the tag released by us.
- **Repository:** `aptecstudio/WebKit`, fork of `WebKit/WebKit` with all branches.
  - `main`: copy of the official one, without our changes;
  - `project-os/<version>`: our work branch, created from the stable branch
    `webkitglib/<version>`; at each new stable release the next branch is created and
    our patches are re-applied;
  - first branch: `project-os/2.54`, from `webkitglib/2.54` (commit `2b614de`, created
    on 2026-11-11; latest official release at that date: 2.54.2).

### D-024 — Yocto build configuration · `confirmed` (2026-11-11)
- **Pinned versions:** Yocto 6.0 "Wrynose" (LTS), OpenEmbedded-Core `2285da0`, bitbake
  2.18 `6e260eb`. They are updated only with a dedicated commit.
- **Tool:** [kas](https://kas.readthedocs.io): YAML files in `kas/` that describe
  repositories, versions, layers, machine and distribution; the build is recreated with
  a single command (`kas build kas/desktop-amd64.yml`). `kas/dev.yml` adds the
  development settings (passwordless root, testing in QEMU): **never** for released
  images. Discarded alternative: `bitbake-setup` (new in Yocto 6.0, still poorly
  documented).
- **Sources without poky:** OpenEmbedded-Core and bitbake directly, with our
  `project-os` distribution (`layers/meta-project-os/conf/distro/project-os.conf`).
- **`project-os-amd64` machine:** x86-64-v2 instructions (`corei7-64`), to work on PCs
  from 2008 onwards; x86-64-v3 discarded because it would exclude PCs from before about
  2013. *This part is superseded by D-027 (baseline x86-64).* `linux-yocto` 6.18 LTS
  kernel with the reference configuration for 64-bit PCs (`common-pc-64`), UEFI boot
  with GRUB.
- **Excluded distribution features** (reasons in the distribution file): x11,
  pulseaudio, nfs, zeroconf, 3g, nfc, ptest, multiarch, debuginfod.
- **Check done:** bitbake reads configuration, image and kernel without errors or
  warnings (read-only check, no compilation). To check at the first build: download,
  compilation, `wic` partition layout, syntax of the kas files. *All confirmed by the
  first full build (2026-11-11) and the QEMU tests (2026-11-12, D-026).*

### D-025 — Kernel and firmware for desktop hardware · `confirmed` (2026-11-11)
- **Configuration fragments** in
  `layers/meta-project-os-desktop/recipes-kernel/linux/files/`, one per area: disks and
  file systems, graphics, audio, Bluetooth, Wi‑Fi, wired network, input and platform.
  147 options, all checked against the Kconfig files of Linux 6.18.
- **Built in (=y) only the boot drivers** (NVMe, SATA, ext4, FAT, UEFI framebuffer,
  keyboard, USB 3): there is no initramfs, so the system disk must be readable before
  loading modules. Everything else is a module, loaded only if the hardware is there.
- **Graphics:** Intel (i915, xe), AMD (amdgpu, the first GCN too, and radeon), NVIDIA
  only with the free nouveau driver; drivers for virtual machines (QEMU, VirtualBox,
  VMware, Hyper‑V).
- **Firmware:** `packagegroup-project-os-desktop-hw`, 27 `linux-firmware` packages plus
  the Wi‑Fi frequency database; compressed with zstd.
- **Missing, to be written as own recipes** (they are not in OpenEmbedded-Core): Intel
  SOF audio firmware (Intel laptops from the 11th generation), Intel microcode. The
  microcode has to be loaded at boot through an initramfs to be effective: to be
  decided with the boot layout (step 4).
- **Tool:** `tools/check-kernel-fragments.py` checks that each option exists in the
  kernel version and that the value is allowed by the type; it already found an error
  (`TG3` instead of `TIGON3`). The build checks the dependencies between options.
- **Checks done:** bitbake resolves the image dependency graph without errors;
  firmware, regdb and fragments enter the build. To check at the first build: kernel
  compilation and warnings about option dependencies. *First build (2026-11-11): the
  kernel compiles; `do_kernel_configcheck` reported only `MMC_SDHCI_ACPI` and
  `MMC_SDHCI_PLTFM`, set to `y` by yocto-kernel-cache but necessarily `m` with our
  `MMC=m`; now declared `=m` in `storage.cfg` (D-038).*
- **Related fix:** the base image now includes `MACHINE_EXTRA_RRECOMMENDS`; before,
  the machine's modules and firmware would have been left out.

### D-027 — Processors: baseline x86-64 · `confirmed` (2026-11-11)
- **What:** `DEFAULTTUNE = "x86-64"`: all 64-bit processors (Athlon 64, 64-bit Pentium
  4, Core 2 and later). Supersedes the x86-64-v2 part of D-024.
- **Why:** R-25, R-28. Accepted cost: slightly lower performance on modern processors.
- **Discarded alternatives:** x86-64-v2 (excludes PCs from before about 2008); 32-bit
  (WebKit on 32-bit is less and less supported, cost too high).

### D-026 — A/B partitions, boot and data partition · `confirmed` (2026-11-12, merged into `main`)
- **Disk layout (GPT)**, in `files/wic/project-os-ab.wks.in` (`.in` extension: bitbake
  substitutes variables such as `${EFI_PROVIDER}` in it):
  | # | Name | Size | Contents |
  |---|---|---|---|
  | 1 | `bios_grub` | 1 MiB | GRUB for BIOS boot (step 4e) |
  | 2 | `esp` | 512 MiB | EFI partition: GRUB, menu, theme, slot state (`grubenv`); mounted on `/efi`, root-only access |
  | 3 | `root_a` | 4 GiB | system, copy A, read-only, kernel included |
  | 4 | `root_b` | 4 GiB | system, copy B, written by updates |
  | 5 | `data` | rest | data, created on first boot, encrypted, mounted on `/var` (`/home` → `/var/home`) |
- **Slot selection:** GRUB (`files/wic/project-os-grub.cfg`) boots the first valid slot
  of `ORDER` without pending attempts, and records the attempt; `rauc-mark-good`
  confirms it once the system is up. If the boot fails, on reboot it switches to the
  other slot. In the menu the active slot is called "project-os", the other one
  "previous version" (Italian texts until D-037, now in English).
- **Updates:** RAUC (`recipes-core/rauc/files/system.conf`); bundles signed in *verity*
  format, zstd-compressed (`project-os-bundle`). The CA certificate goes into the
  image; keys outside the repository (`PROJECT_OS_KEYS`, `tools/gen-dev-keys.sh`).
- **Data partition:** created by `systemd-repart` on the free space, LUKS2. Unlocking
  with `crypttab`: works without TPM (R-27). In this phase the key is **empty**
  (placeholder, data not protected): the setup will enroll password and recovery key,
  and the TPM as an extra method where present (step 4d and Phase 8).
- **Kernel:** dm-crypt, dm-verity, AES-XTS, SHA-256, loop and zstd squashfs built in
  (`ab-crypt.cfg`).
- **Related decisions:** `systemd.gpt_auto=0` (partitions are mounted only as
  described, never by type); `/home` on the data partition.
- **Known limitations, to be solved in the sub-steps:**
  - kernel read by GRUB inside the slot without verification: with erofs + dm-verity
    and a signed unified kernel image (UKI) in step 4c;
  - read-only `/etc`: machine, network and users do not persist until step 4c (overlay
    of `/etc` on the data partition, from the initramfs);
  - BIOS boot: OpenEmbedded does not install GRUB for BIOS in images; we write it in
    step 4e;
  - packages that put files in `/var` at build time: covered by the data partition
    mounted on top; to check at the first build. *Checked (2026-11-12, D-038): the slot
    has only empty `/var/lib/{dbus,misc,systemd}` and base-files symlinks; on the data
    partition systemd recreates what is needed.*
- **Checks done:** bitbake resolves all image and bundle dependencies without errors or
  warnings; 159 kernel options checked on 6.18; the key script produces a valid
  certificate chain. To check at the first build: `grub.cfg` syntax, GRUB modules,
  partition creation, boot and A/B update.
- **First test in QEMU (2026-11-12):** GRUB starts, reads `grubenv`, chooses slot A and
  boots the kernel; systemd ends up in emergency mode because of two errors, fixed:
  - systemd-repart creates and encrypts the data partition but does not format it: the
    image lacked `mkfs.ext4`. Added `e2fsprogs-mke2fs` to the dependencies of
    `project-os-storage`;
  - wic wrote the ESP in fstab as `/dev/sda2`, which does not exist with NVMe or virtio
    disks. First attempt, `--use-uuid` (`UUID=` line): *superseded* the same day, see
    below (wic's fstab line does not reach updates);
  - then `/efi` did not mount: the directory did not exist and on the read-only system
    systemd cannot create it. The image creates it at build time
    (`project_os_efi_mountpoint`, permissions 0700).
- **Result after the fixes (2026-11-12, QEMU with KVM):** login reached; system
  `running`, no failed service; RAUC booted from A, slot A *good* (`rauc-mark-good`
  works), slot B *bad* because still empty; `/` ext4 read-only, `/efi` and `/var`
  (LUKS2, 15.6 GB) mounted. After a reboot the data in `/var/home` is still there and
  systemd-repart changes nothing.
- **A/B update test (2026-11-12, QEMU):** three errors found and fixed:
  - the bundle looked for the slot's `.ext4` image, which the build did not produce:
    the machine now generates `wic wic.bmap ext4`;
  - RAUC writes the values `1`/`0` in `grubenv`, while `grub.cfg` and the initial
    `grubenv` used `true`/`false`: after the first update (and already after
    `rauc-mark-good`) no slot was bootable and the menu stopped without a countdown.
    Now everything uses `1`/`0`, like RAUC's reference layout;
  - in slot B `/efi` did not mount: wic writes the fstab line only on the
    first-installation disk, not in the slot image. Now `efi.mount`
    (`project-os-storage`) mounts it by the GPT label `esp`, like the slots and the data
    partition; the mount point was removed from the `wks` layout. Discarded: adding the
    line to fstab in the recipe, because the FAT serial number changes at every build.
- **Result:** installation of the signed bundle from A (signature verified) → reboot →
  GRUB chooses B by itself → `rauc-mark-good` confirms it (`B_TRY=0`). Boot of B
  interrupted with a reset right after GRUB (`B_TRY=1` left set) → on reboot GRUB goes
  back to A by itself, which runs without errors. The automatic rollback to the
  previous version works.

### D-028 — Tools for the build host and the emulator · `confirmed` (2026-11-12, merged into `main`)
- **Guide:** `docs/development.md` (until D-037 `docs/sviluppo.md`), for the user who
  works from their own PC.
- **Scripts:** `tools/setup-host.sh` (programs for Yocto, kas through pipx, QEMU, OVMF,
  development keys; asks for confirmation before touching AppArmor), `tools/build.sh`
  (development build, update, bitbake shell), `tools/run-qemu.sh` (emulator).
- **Emulator:** QEMU `q35` with OVMF UEFI firmware; **NVMe** disk, because the driver
  is built into the kernel and there is no initramfs yet (a virtio disk would not be
  seen); copy of the image with 16 GB free for the data partition; KVM if available,
  otherwise the `qemu64` processor (baseline x86-64, D-027).
- **Recommended build host:** Ubuntu Server 24.04/26.04 LTS. On Ubuntu 24.04 and later
  bitbake needs user namespaces, restricted by AppArmor: the script explains the change
  and asks for confirmation.
- **Checks done:** script syntax; image path compared with bitbake. Run on the user's
  laptop on 2026-11-11 and 2026-11-12.
- **Fix (2026-11-12):** started from a snap app (VS Code installed as a snap), QEMU
  inherited the snap's GTK/GIO variables and did not open the window (`libpthread`
  error from `core20`). `tools/run-qemu.sh` removes them when `SNAP` is set. Checked
  also from a clean environment without snap variables: the window opens.

### D-033 — Ecosystem of project-os devices · `proposed` (2026-11-11)
- **What:** a system service in Rust (*continuity daemon*) that connects the devices of
  the same user. Planned features, in priority order (to be confirmed, DA-12):
  1. **pairing** of devices with a QR code or a numeric code; a key pair per device;
     list of trusted devices in Settings;
  2. **sending files and links** between nearby devices;
  3. **shared clipboard**;
  4. the phone's **notifications, calls and text messages** shown and handled on the
     desktop;
  5. **app continuity** (*handoff*): an app picks up on the desktop what was being done
     on the phone and vice versa, through an API of the `system` object (D-029);
  6. **sync** of settings, contacts, calendar, passwords and Wi‑Fi networks;
  7. **instant hotspot** from the phone and **unlocking** the desktop with the phone
     nearby;
  8. later: tablet as a second screen, shared keyboard and mouse.
- **Principles (from the security constraints, AGENTS.md §5):**
  - end-to-end encryption between devices, on a channel authenticated by the pairing
    keys (candidate protocol: Noise); no data in the clear outside the device;
  - **no mandatory cloud**: everything works on the local network and Bluetooth; a
    relay service for distant devices is optional (DA-12);
  - apps reach the ecosystem **only through the broker** and only with the permission
    declared in `package.json` (e.g. `devices.handoff`, `devices.share`);
  - every device can be revoked; revocation invalidates its keys on all the others;
  - protocol with a version number and negotiation, so that devices with different
    project-os versions keep talking to each other (backward compatibility, R-25).
- **Device discovery:** Bluetooth LE for proximity, then local network. Today the
  distribution excludes `zeroconf` (Avahi): to decide whether to re-enable mDNS only for
  this service or to use an own announcement (DA-12).
- **Why:** R-33. It makes sense only with working desktop and mobile, so the phase comes
  after Phase 7; the earlier phases must however plan for it: broker permissions
  (Phase 3), runtime APIs (Phase 4), "Devices" panel in Settings (Phase 6).
- **References to study:** KDE Connect / GSConnect (open protocol with similar
  features), Apple Continuity, Google Quick Share.

### D-034 — Laptop as temporary build host · `confirmed` (2026-11-12, merged into `main`)
- **What:** until the full build host exists (DA-11), Phase 1 can be built on the
  user's laptop: Debian 13, 4 cores, 7.4 GB of RAM, 42 GB free. `kas/low-resources.yml`
  sets 2 bitbake tasks and `make -j 3` (at most 6 compilations together, so RAM does
  not run out), `rm_work` (deletes the work files of each finished recipe) and a clean
  stop of the build below 5 GB free.
  ~~`tools/build.sh` adds it by itself below 16 GB of RAM
  (`PROJECT_OS_LOW_RESOURCES=1|0` to force or exclude it).~~ *Automatic choice
  superseded by D-036: the mode is now chosen with `--low-resources`.*
- **Why:** the Phase 1 image should fit in about 30-40 GB with `rm_work` (estimate, to
  be measured at the first build); the first build is long, later ones reuse the
  `sstate` cache.
- **Measured at the first build (2026-11-11):** about 3 hours and 45 minutes of actual
  build, `build/` 26 GB and `sources/` 0.4 GB; RAM never below 3 GB available; `wic`
  image of 8.6 GB nominal (4 GB slots A and B) and 695 MB actually used.
- **Measured in QEMU (2026-11-12):** system 612 MB used in the slot; idle memory in use
  about 70 MB out of 2 GB. Incremental build after a fix: 2-3 minutes.
- **Limitations:** not enough for WebKitGTK (Phase 2), which wants more than 2 GB of
  RAM per compilation process and much more disk. DA-11 stays open.
- **Discarded alternative:** a separate preparation script for the laptop:
  `tools/setup-host.sh` already covers Debian 13.

### D-035 — Downloads from the Yocto mirror, no QEMU built by Yocto · `confirmed` (2026-11-12, merged into `main`)
- **Problem (first build on the laptop, 2026-11-11):**
  - the `git.yoctoproject.org` git server serves clones at about 17 KB/s, even those
    reduced to the last commit: the `linux-yocto` kernel (several GB) would have taken
    days. The connection is not the cause: from kernel.org downloads run at 13 MB/s,
    from the Yocto HTTP mirror at about 3 MB/s;
  - the `qemuboot` class (included by the machine through `qemuboot-x86.inc` and by
    `kas/dev.yml`) and the `ovmf` recipe made bitbake build QEMU with graphics, hence
    Mesa, LLVM and Clang: hours of compilation and a risk of running out of RAM, for
    tools we do not use.
- **What:**
  - `kas/base.yml`: `PREMIRRORS` maps the `git.yoctoproject.org` repositories to the
    archives of the official mirror `downloads.yoctoproject.org/mirror/sources/`. The
    commit stays the one pinned in the recipe, verified by git; if the archive is older,
    bitbake fetches only the missing commits from the git server;
  - machine and `kas/dev.yml` without `qemuboot` and without `ovmf`: testing uses
    `tools/run-qemu.sh` with the QEMU and OVMF of the build host. The `QB_*` variables,
    which served only `runqemu`, are gone too.
- **Effect:** compilation tasks go from about 838 to 682; `qemu-native` (small, needed
  by the package installation scripts) and `qemuwrapper-cross` remain.
- **Discarded alternatives:** shallow clone (`BB_GIT_SHALLOW`), which stays slow on the
  same server; keeping `runqemu`, which is not needed because there is
  `tools/run-qemu.sh`.

### D-036 — Two build modes: full-performance default, low resources on request · `confirmed` (2026-11-12, merged into `main`)
- **What (user's request):** `tools/build.sh` builds by default at full performance
  (`kas/desktop-amd64.yml:kas/dev.yml`, bitbake settings: all cores, work files kept).
  The low-resources mode (`kas/low-resources.yml`, D-034) stays as a second choice and
  is enabled only explicitly with `tools/build.sh --low-resources` (named
  `--poche-risorse` until D-037) or `PROJECT_OS_LOW_RESOURCES=1` (compatible with the
  previous script, R-25).
- **Resource check:** the script measures RAM and free space. In default mode it warns
  below 15 GB of RAM (a 16 GB PC shows a bit less) and, at the first build, below
  100 GB free (estimate: without `rm_work`; to be measured on the build host); with
  `--low-resources`, below 45 GB free (about 27 GB measured, D-034). From a terminal it
  asks for confirmation, from scripts (CI) it warns and continues.
- **Why:** the repository is public and anyone must be able to reproduce the build
  without help: the recommended configuration is the default, the choices are explicit
  and documented (`docs/development.md` §3, with the equivalent kas commands), errors
  say what to do. A hidden automatic switch made the build less predictable and did not
  reflect the reference machine.
- **Discarded alternatives:** two separate scripts (duplicated checks and keys); a
  dedicated kas file for the default mode (not needed: they are bitbake's settings);
  stopping the build below the threshold (whoever knows what they are doing must be
  able to go on).
- **Checks done:** syntax; with a fake `kas`, all cases (help, unknown option, default,
  update, shell, `--low-resources`, variable, terminal confirmation answered yes and no,
  RAM and disk warnings at the first build); real incremental build in low-resources
  mode.

### D-037 — Repository in English · `requirement` (2026-11-12)
- **What (user's request):** everything in the repository is written in **English**:
  identifiers, comments, script options and messages, recipes, configurations, systemd
  units, GRUB menu and theme texts, documentation (`README.md`, `docs/`, `MEMORY.md`,
  `ROADMAP.md`) and commit messages. Italian only where it is needed for the user's
  language, that is in translation files (language packs) and in the locale lists of
  the distribution.
- **Changes made:**
  - script options: `--poche-risorse` → `--low-resources`, `--testo` → `--text`;
    `tools/build.sh` commands `immagine|aggiornamento|shell` → `image|update|shell`; no
    Italian aliases kept (decided by the user: the project has no releases yet);
  - GRUB menu: "project-os (previous version)", "project-os (copy A/B)", "UEFI Firmware
    Settings"; theme texts ("Booting automatically in %d seconds", key help);
  - `DISTRO_CODENAME` `fase1` → `phase1` (shown in `/etc/os-release`);
  - `docs/sviluppo.md` → `docs/development.md`;
  - `MEMORY.md` and `ROADMAP.md` translated with unchanged content;
  - `AGENTS.md` §6 rewritten as a fixed rule, with the user's explicit authorization
    (v1.2): repository in English, communication with the user (chat, questions and
    multiple-choice prompts) in Italian. Then the whole of `AGENTS.md` translated into
    English with the user's authorization (v1.3), content and meaning unchanged; the
    only adjustment is in §4, where "commit messages … in Italian" became "language: see
    §6", to avoid two opposite rules.
- **Not regenerated:** the OS images (they will be rebuilt in the next steps, as the
  user asked) and `branding/previews/grub-menu.png`, whose Italian texts are drawn in
  the image: `branding/tools/render.py` already has the English texts, the preview is
  regenerated when Pillow and `rsvg-convert` are available (ROADMAP, Phase 1).
- **Why:** the repository is public and must be readable and reproducible by anyone.
- **Supersedes:** the convention "documentation and commits in Italian" of §5 (until
  2026-11-12, from `AGENTS.md` §6 v1.1).

### D-038 — Phase 1 cleanup: package inventory, trimming, EFI partition check · `confirmed` (2026-11-12, merged into `main`)
- **Why:** AGENTS.md §5.5 requires a recorded reason for every package in the image;
  until now only kernel modules and firmware (D-025) had one. The review also closed
  the checks left open "for the first build" (D-024, D-025, D-026).
- **Removed** (each one checked with a build and a full QEMU test):
  - `busybox-syslog`: second system log next to systemd-journald
    (`VIRTUAL-RUNTIME_base-utils-syslog = ""` in the distribution);
  - `busybox-udhcpc`: second DHCP client, systemd-networkd already does DHCP
    (`BAD_RECOMMENDATIONS`);
  - `kbd-keymaps-pine`: keyboard layouts for Pine64 devices only (`BAD_RECOMMENDATIONS`);
  - `libssh`, `libgcrypt`, `libgpg-error`: pulled only by cryptsetup's LUKS2 SSH token
    plugin, which keeps unlock keys on a remote SSH server (`PACKAGECONFIG:remove =
    "ssh-token"`);
  - volatile bind mounts: `VOLATILE_BINDS = ""`. The `volatile-binds` package stays
    (systemd depends on it) but installs no units; before, its units for `/var/lib`,
    `/var/cache`, `/var/spool` were inactive only because `/var` was already writable,
    and `/srv` was bound to a tmpfs;
  - `/var/volatile` tmpfs line removed from fstab (`base-files` bbappend) and OE's
    `00-create-volatile.conf` masked (`/etc/tmpfiles.d/… → /dev/null`): it made
    `/var/tmp` a link into `/var/volatile` while `/var/log` was already a real
    directory. Now both are real directories on the data partition.
- **Added:** `dosfstools` (`fsck.vfat`): `efi.mount` requires
  `systemd-fsck@dev-disk-by\x2dpartlabel-esp.service`, so the EFI partition is checked
  and repaired at every boot before being mounted. GRUB writes `grubenv` there at every
  boot: a power loss can leave the FAT file system dirty (seen during the QEMU tests).
- **Kernel:** `CONFIG_MMC_SDHCI_ACPI=m` and `CONFIG_MMC_SDHCI_PLTFM=m` in `storage.cfg`;
  `do_kernel_configcheck` no longer reports anything.
- **Inventory of the image** (816 packages: 552 kernel modules and 121 firmware
  packages, reasons in D-025; the other 143 below, grouped by purpose; `-locale-it`
  packages are the Italian translations of each program, installed by
  `IMAGE_LINGUAS`):
  | Purpose | Packages | Reason |
  |---|---|---|
  | Kernel | `kernel`, `kernel-6.18.54-yocto-standard`, `kernel-image*`, `kernel-modules` (meta-package of the modules) | the Linux kernel, inside each slot (D-014, D-026) |
  | Hardware | `packagegroup-project-os-desktop-hw`, `wireless-regdb-static` | firmware group and Wi‑Fi regulatory database (D-025) |
  | Boot | `grub-efi`, `grub-common`, `grub-bootconf`, `grub-editenv`, `grub-locale-it` | GRUB boot menu (D-009); `grub-editenv` for RAUC (D-026) |
  | Init and devices | `systemd`, `systemd-conf`, `systemd-extra-utils`, `systemd-udev-rules`, `systemd-vconsole-setup`, `systemd-serialgetty`, `systemd-mime`, `udev`, `udev-hwdb`, `kmod`, `libkmod2`, `libsystemd0`, `libsystemd-shared`, `libudev1`, `libseccomp`, `libnss-myhostname2`, `libnss-resolve2`, `libnss-systemd2`, `volatile-binds` | systemd as init (D-016) and its direct dependencies; `systemd-serialgetty` for the serial console |
  | Network | `systemd-networkd`, `netbase` | network configuration (DHCP included); protocol and service tables |
  | IPC | `dbus-1`, `dbus-common`, `dbus-tools`, `libdbus-1-3`, `libexpat1` | D-Bus, needed by systemd and by RAUC's service |
  | Encryption and storage | `cryptsetup`, `systemd-crypt`, `libdevmapper`, `project-os-storage`, `e2fsprogs-mke2fs`, `e2fsprogs-e2fsck`, `libext2fs2`, `libe2p2`, `libcom-err2`, `dosfstools`, `util-linux-fsck`, `util-linux-mount`, `util-linux-umount`, `libmount1`, `libblkid1`, `libfdisk1`, `libsmartcols1`, `libuuid1` | LUKS2 data partition, repart, mounts and file system checks (D-026, D-038) |
  | Updates | `rauc`, `rauc-conf`, `rauc-service`, `rauc-mark-good`, `libglib-2.0-0`, `libjson-glib-1.0-0`, `libnl-3-200`, `libnl-genl-3-200`, `libcurl4`, `libnghttp2-14`, `libidn2-0`, `libunistring5`, `libffi8`, `libpcre2`, `shared-mime-info`, `shared-mime-info-data`, `libxml2` | signed A/B updates (D-018, D-026). `libcurl` (with `nghttp2`, `idn2`) and `libnl` come from RAUC's default `network` and `streaming` features: kept for installing updates directly over HTTPS (Phase 8); `shared-mime-info` and `libxml2` are required by GLib |
  | Crypto and certificates | `libssl3`, `libcrypto3`, `openssl`, `openssl-bin`, `openssl-conf`, `ca-certificates` | bundle signature checking (RAUC), HTTPS for updates; certificate authorities for HTTPS |
  | Login and accounts | `libpam`, `libpam-runtime`, `pam-plugin-*` (deny, env, faildelay, group, keyinit, limits, loginuid, mail, motd, namespace, nologin, permit, rootok, securetty, shells, umask, unix, warn), `shadow-base`, `shadow-securetty`, `util-linux-agetty`, `util-linux-sulogin`, `libcrypt2` | authentication (`pam` distribution feature, logind), text login, emergency shell |
  | Console | `kbd`, `kbd-keymaps`, `kbd-consolefonts`, `keymaps` | keyboard layouts and fonts of the text console |
  | Base system | `base-files`, `busybox`, `os-release`, `ldconfig`, `libc6`, `libgcc1`, `libstdc++6`, `libacl1`, `libattr1`, `libz1`, `libzstd1`, `liblzma5`, `libpopt0`, `libjson-c5`, `util-linux-flock`, `packagegroup-core-boot` | file system layout and basic tools (BusyBox, until our own shell exists), C/C++ runtime, compression libraries, dependencies of the packages above |
  | Swap tools | `util-linux-mkswap`, `util-linux-swapon`, `util-linux-swapoff`, `util-linux-swaponoff` | hard dependency of systemd; no swap is configured today (to be decided with the memory budget) |
  | Locales | `locale-base-it-it`, `locale-base-en-us`, `glibc-locale-it` | Italian and English for the users (§6 of AGENTS.md allows Italian here) |
- **Measured (QEMU, 2026-11-12):** system 610 MB in the slot (612 MB before), idle
  memory in use about 77 MB out of 2 GB.
- **Checks done:** three builds (low-resources mode), full QEMU test from a new disk:
  first boot (`running`, no failed units, EFI partition checked, data partition
  created), A/B update to B confirmed by `rauc-mark-good`, boot of B interrupted by a
  reset → automatic rollback to A, EFI partition clean after the reset.
- **Seen, not fixed (noted in ROADMAP):** `dbus-daemon: Failed to drop supplementary
  groups: Operation not permitted` at every boot, harmless so far; RAUC's "No bootable
  slot found" message during `rauc-mark-good`, expected (the slot is marked as tried
  until it is confirmed); the kernel warns that the GPT backup header is not at the end
  of the disk on the first boot in QEMU (the emulator disk is enlarged after the image
  is written).

### D-029 — System APIs in the global `system` object · `confirmed` (name and principle), details `proposed`
- **What (R-29):** in the context of the main script and of the app windows there is a
  global **`system`** object, with one sub-object per area, like `chrome.*` in
  extensions. Initial proposal of the namespaces:
  | Namespace | Contents |
  |---|---|
  | `system.runtime` | information about the app, messages between main script and windows |
  | `system.windows` | create, close, move the app's windows |
  | `system.process` | the app's subprocesses (R-09) |
  | `system.fs` | files outside the app folder, within the granted limits (R-31) |
  | `system.storage` | private, persistent app data |
  | `system.devices` | devices (camera, audio, USB, Bluetooth…) |
  | `system.services` | system services (network, notifications, power…) |
  | `system.dialogs` | system dialogs in HTML (R-10) |
  | `system.permissions` | granted permissions, requesting new permissions |
  | `system.root` | privileged operations mediated by the broker (R-13, D-005) |
- **Security rule:** a namespace exists in the `system` object only if the app declared
  it in `package.json` and the user granted it; otherwise it is `undefined`, like the
  `chrome.*` APIs not declared in the manifest (AGENTS.md §5.1).
- **Style (proposed):** asynchronous functions returning a `Promise`; events with
  `system.<namespace>.on<Event>.addListener()`, as in extensions; errors as exceptions
  with a code (`PermissionDenied`, `NotFound`…).
- **Why `system`:** the user's choice; independent of the final name of the system.
- **To be defined in Phase 4:** full list of functions, in `docs/api/`.

### D-030 — `include()` and `includeAsync()` · `confirmed` (principle), details `proposed`
- **What (R-30):**
  - `include(url)` loads and runs a script and **returns its `exports`**;
    `includeAsync(url)` does the same and returns a `Promise` of the `exports`;
  - the included script runs in its own scope (it does not pollute the includer's
    variables) and sees the variables `exports`, `include`, `includeAsync` and `system`;
  - **cache:** each script is run only once per context; later inclusions of the same
    address return the same `exports`;
  - **cycles:** if a script includes another one that is still loading along the same
    chain, the inclusion fails with an `IncludeCycleError` that shows the chain (e.g.
    `app://a.js → app://b.js → app://a.js`). This also applies to `includeAsync`: the
    chain of whoever requested the load is checked, so two asynchronous loads do not
    stay stuck waiting for each other (the user's choice: an error, not partial
    `exports` as in Node.js).
- **Allowed addresses (proposed):** only `app://`, i.e. the app folder (R-31); relative
  addresses are resolved against the including script. No scripts from the network:
  remote code must not be able to reach the native APIs (AGENTS.md §5.4).
- **Where (proposed):** in the main script (JavaScriptCore, D-008) and in the windows.
  In the main script a synchronous `include` is natural; in WebKit windows it has to be
  checked how to do it without blocking the interface (a technical point of Phase 4).

### D-031 — App folder and `app://` protocol · `confirmed` (principle), details `proposed`
- **What (R-31):** each app has an isolated root folder; its resources are reached with
  **`app://` followed by the path inside that folder**, for example `app://img/logo.png`
  or `app://lib/utils.js`.
- **Only the app accesses its own resources (the user's choice):** the same address in
  two apps points to two different folders; an app has no way to refer to another one's
  resources. Proposed implementation: each app has its own WebKit context (processes,
  network session, storage, cookies kept separate) and its own `app://` protocol
  handler, bound to its folder.
- **Security rules (proposed):**
  - normalized paths: no `..` or symbolic links that leave the folder;
  - app folder read-only (it is the installed package); the data the app writes lives
    elsewhere, through `system.storage` or `system.fs`;
  - no access to `file://`; external files only through `system.fs`, within the
    permission limits;
  - `app://` registered in WebKit as a secure context, so the web APIs that require it
    work.

### D-032 — Windows 11, macOS Big Sur, Xiaomi MIUI hybrid design · `confirmed` (requirement), details in Phase 5
- **What (R-32):** the visual style combines the three references; it is defined in
  Phase 5 and recorded in §3.
- **Inspiration, not copying:** visual language and behaviors are taken up, not icons,
  logos, wallpapers or other protected graphic elements of the three systems.

### D-013 — Native components in Rust · `confirmed` (2026-11-11)
- **What:** compositor (on Smithay), JavaScriptCore runtime host, broker, system daemons
  and own build tools in Rust. External C libraries (WebKitGTK, GTK, Mesa) are used
  through bindings.
- **Why:** R-22; memory safety in the most exposed components (R-14).
- **Discarded alternatives:** C with wlroots.

### D-014 — Single user space, per-platform hardware layer · `confirmed` (2026-11-11)
- **What:** everything above the kernel (libc, compositor, runtime, shell, apps) is
  identical on desktop and mobile. Only the **hardware layer** changes:
  - **desktop (amd64):** mainline Linux kernel, Mesa for the GPU, linux-firmware
    firmware;
  - **mobile (arm64, Android base):** the phone vendor's kernel and firmware, Android
    drivers (GPU, modem, sensors, camera) reached through Halium/libhybris; where a model
    has good mainline support, that can be used.
- **Why:** R-21. The differences stay confined in one folder per platform and device;
  the rest is compiled twice (amd64, arm64) without changes.
- **Constraints:** libhybris requires glibc (D-015); WebKitGTK must work with EGL
  through libhybris (to be checked early, it is the main technical risk on the mobile
  side); bootloader unlocking varies by model (see D-004).

### D-015 — C library: glibc · `confirmed` (2026-11-11)
- **Why:** needed for libhybris (Android drivers, D-014) and the best tested with
  WebKitGTK and GTK.
- **Discarded alternatives:** musl (incompatible with libhybris, less tested with WebKit).

### D-016 — Init: systemd · `confirmed` (2026-11-11)
- **What:** systemd as init, with udev, logind and journald.
- **Why:** session and device management (logind/udev) is needed by the compositor;
  built-in service sandboxing; existing Halium support.
- **Alternatives:** lightweight inits (s6, dinit) or an own init in Rust: fewer
  dependencies, but udev/sessions/seats to be rebuilt.

### D-017 — Differentiated desktop / mobile setup · `confirmed` (2026-11-11)
- **What:** a single HTML setup app with steps enabled according to the platform (R-24).
  - **Desktop (from the USB image, D-010):** language → keyboard layout → time zone →
    network (optional) → disk: partitioning/formatting, next to Windows too → disk
    encryption → user and password → summary and installation (with GRUB and
    detection of other systems) → reboot → first boot: preferences.
  - **Mobile (first boot after the recovery):** language → Wi‑Fi/SIM network (PIN) →
    automatic time zone → user and unlock code (PIN/password, fingerprint if any) →
    system permissions (location, notifications) → preferences. No disk or physical
    keyboard step.
- **Why:** on mobile the system is already written by the recovery; on desktop the
  setup is also the installation.

---

### D-020 — GPL-3.0 license · `confirmed` (2026-11-11)
- **What:** the project-os code is released under the GNU GPL v3 license (`LICENSE`
  file). The WebKit fork keeps WebKit's original licenses (LGPL/BSD).
- **Why:** the user's choice; whoever modifies and distributes the system must publish
  its code, avoiding closed forks.

### D-021 — Phases in sequence, not in parallel · `confirmed` (2026-11-11)
- **What:** work happens on one phase at a time, in roadmap order.
- **Why:** the user's request.

### D-022 — Bottom-up development · `confirmed` (2026-11-11)
- **What:** phase order: base system (Yocto, kernel, boot) → graphics stack → broker →
  app runtime → shell → system apps → mobile → installation.
- **Why:** the user's choice: each level is built and tested on the real system below
  it.
- **Accepted cost:** the application model (the newest part) is checked later; Yocto
  builds take hours and a robust build host (DA-11).
- **Discarded alternative:** starting from the runtime prototype on an existing
  distribution.

### D-023 — Placeholder logo and GRUB theme · `confirmed` (2026-11-11)
- **What:**
  - generic logo in `branding/logo/project-os-logo.svg`, **monochrome white** (ring and
    central dot) on a dark background, in the style of the elementary OS boot screen,
    as asked by the user; it stays a **placeholder**, the final brand is to be decided;
  - GRUB theme in `branding/grub-theme/`: logo and name at the top, centered entries
    520 px wide, selected entry highlighted by a light semi-transparent box, countdown
    and key help at the bottom;
  - all images are regenerated with `branding/tools/render.py` (SVG → PNG with
    `rsvg-convert`, background and boxes with Pillow/NumPy); `branding/previews/`
    holds an approximate preview, which does not go into the image.
- **Font:** Inter (OFL‑1.1 license). The `.pf2` files for GRUB are not in the
  repository: the Yocto recipe will download Inter from the official project and
  generate them with `grub-mkfont` (Regular 14 and 18, Medium 18, SemiBold 28).
- **Background:** ordered dithering instead of noise, to avoid color banding with a
  light PNG (224 KB against 1.6 MB).
- **Menu texts:** Italian for now; the localization of the boot menu is to be decided
  later. *(Texts in English since D-037; localization still to be decided.)*
- **Why:** R-18; the theme lives in `branding/` as the single source, and the recipe
  will copy it into the image.

---

## 3. Visual style

*To be defined in Phase 5.* Record here: palette, typography, spacing, radii, shadows,
animation durations and curves, icons, light/dark and adaptive behavior (desktop ↔
mobile).

**References (R-32, D-032):** a hybrid of Windows 11, macOS Big Sur and Xiaomi MIUI.
First reading of the traits to combine, to be confirmed in Phase 5:
- from **Windows 11**: translucent and blurred materials (Mica/Acrylic style), rounded
  corners, floating menus and panels, snappable window layouts;
- from **macOS Big Sur**: strong translucency ("vibrancy") of bars and sidebars, very
  rounded corners, soft icons and controls, fluid animations;
- from **MIUI**: on mobile, control center with large tiles, rounded cards, large and
  bold typography, gestures.

**Starting point (from the boot theme, D-023; provisional):**
- Background `#0B0D12`, glow `#2A2F6B`. Logo and brand: **monochrome white** `#FFFFFF`.
- Main text `#F2F4F8`, secondary `#9AA3B2`, dimmed `#7D8597`, minimal `#596173`.
- Font: Inter. Radius of selectable elements: 10 px.

---

## 4. Code structure (proposed)

```
project-os/
├── AGENTS.md  MEMORY.md  ROADMAP.md
├── README.md     # project presentation (requested by the user on 2026-11-11)
├── layers/       # Yocto layers (D-012)
│   ├── meta-project-os/          # common user space: recipes, images, GRUB theme
│   ├── meta-project-os-desktop/  # amd64 hardware layer: mainline kernel, Mesa, firmware
│   ├── meta-project-os-mobile/   # common arm64 hardware layer: Halium/libhybris
│   └── meta-device-<name>/       # one layer per phone: kernel, firmware, recovery
│                                 # package (pixel-…, samsung-…, oppo-…)
├── kas/          # Yocto build configuration (D-024): versions, layers, machine
├── tools/        # development tools (e.g. checking kernel fragments)
├── build/        # build output (not versioned)
├── sources/      # external repositories fetched by kas (not versioned)
├── branding/     # logo (placeholder), GRUB theme, generation script, previews
├── runtime/      # app runtime: main script startup, WebKitGTK windows
├── broker/       # permission daemon and native APIs
├── portal/       # xdg-desktop-portal backend and polkit agent (HTML dialogs)
├── shell/        # system shell: panels, launcher, notifications, dialogs
├── apps/         # system applications (settings, files, terminal,
│                 # desktop installer, first-boot setup…)
├── sdk/          # types and JS library of the system APIs (`system` object)
└── docs/         # specifications (package.json format, APIs, permission model)
```

---

## 5. Syntax conventions

*To be completed when languages and tools are chosen.* Already fixed (AGENTS.md §6,
D-037): **everything in English** — identifiers, comments, script options and messages,
documentation and commits; Italian only in translation files. Conventional Commits.
*(Until 2026-11-12: documentation and commits in Italian, identifiers in English —
superseded by D-037.)*

**Work branches (the user's preference, 2026-11-11):** work happens on **one branch at
a time**, the one open for review (today `build/ab-partitions`). New steps and updates
to `MEMORY.md` and `ROADMAP.md` go there as subsequent commits; no parallel branches
are opened. A new branch is opened only after the merge into `main`. Before starting,
`git fetch` and start again from the updated remote branch: work happens from several
devices.

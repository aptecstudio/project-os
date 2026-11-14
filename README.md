<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="branding/logo/project-os-logo-256.png">
    <img src="branding/logo/project-os-logo-dark-256.png" alt="project-os" width="96">
  </picture>
</p>

<h1 align="center">project-os</h1>

<p align="center">
  An operating system built from scratch on the Linux kernel, with a native interface
  and apps written in Lua. The same system for PCs and smartphones.
</p>

<p align="center">
  <strong>In development, not usable yet.</strong> There is no image to download and
  install today: this page describes where the project is going.
</p>

---

## What it is

project-os is an operating system for **Intel and AMD PCs** and for **smartphones and
tablets**. Everything you see on screen (panels, windows, settings, dialogs, even the
installer) is a native app written in **Lua**, on project-os's own graphics framework
drawn on the GPU through **EGL**; apps describe their screens in Lua or in XML. Web pages
are shown by the **WebKit** engine, only in web views and in the browser. Underneath
there is an essential Linux system, built piece by piece from source, without starting
from an existing distribution.

## What you will get

- **One interface, everywhere.** PC and phone run the same system and the same apps;
  only the way they adapt to the screen and to touch changes.
- **Your devices working together.** PCs and phones with project-os recognize each
  other and cooperate, as an ecosystem:
  - files and links sent from one device to another;
  - shared clipboard;
  - the phone's notifications, calls and text messages on the PC;
  - picking up on the PC what you were doing on the phone, and vice versa.

  All encrypted from one device to the other, with no mandatory cloud.
- **Apps that ask only for what they need.** Each app declares in advance what it wants
  to use (files, camera, network…) and gets only what you approve. Apps run isolated
  from one another; when one asks for administrator privileges, the system asks you
  with a clear dialog and logs it.
- **A system that does not break.** The system is read-only and verified at every boot.
  Updates are signed and installed onto a second copy: if something goes wrong, on
  reboot you are back to the previous version automatically. Your data lives on an
  encrypted partition.
- **On older PCs too.** The goal is to run on 64-bit PCs, older ones included, with UEFI
  or BIOS boot and encryption that does not require a TPM chip.
- **Next to Windows.** The boot menu detects Windows and the other systems already
  installed, so you can choose which one to start each time.

<p align="center">
  <img src="branding/previews/grub-menu.png" alt="Boot menu preview" width="720">
  <br>
  <sub>Boot menu preview, with the placeholder logo.</sub>
</p>

## What it will run on

| Device | How it is installed |
|---|---|
| 64-bit Intel/AMD desktop PCs and laptops | From the `.iso` image, on a USB stick or a DVD, with a guided setup: language, keyboard, disk (next to Windows too), encryption, user |
| Google Pixel (first supported phone) | By flashing the published package with `fastboot` (or from a custom recovery, where there is one); on first boot a guided setup asks for network, user and unlock code |
| Older Oppo and Samsung models | Later, model by model |

Phones need an unlockable bootloader: it depends on the model and sometimes on the
carrier.

## Where we are

Development goes from the bottom up, one phase at a time: first the base system, then
graphics, then apps.

| Phase | | Status |
|---|---|---|
| 0 | Foundations and decisions | almost complete |
| 1 | Base system: kernel, boot, partitions | in progress |
| 2 | Graphics: framework, compositor, WebKit | to do |
| 3 | App permissions and isolation | to do |
| 4 | App runtime | to do |
| 5 | Interface and visual style | to do |
| 6 | System apps: settings, files, terminal | to do |
| 7 | Smartphones and tablets | to do |
| 8 | Installation and updates | to do |
| 9 | Device ecosystem | to do |

The details of each step are in [`ROADMAP.md`](ROADMAP.md).

## Building it yourself

Today you can only build the base system from source and boot it in the QEMU emulator,
up to a text terminal, signed A/B updates included. The first build takes several
hours.

### What you need

| | Minimum | Recommended |
|---|---|---|
| System | Debian 13 or Ubuntu 24.04 LTS | Ubuntu 26.04 LTS |
| RAM | 8 GB (with `--low-resources`) | 16 GB or more |
| Free disk | 45 GB (with `--low-resources`) | 250 GB on SSD |
| Processor | 4 cores, 64-bit | 8 cores or more, with virtualization (KVM) enabled |

A user account with `sudo` rights is needed to install the packages. A virtual machine
works too: enable nested virtualization for the emulator.

**The project must be on a Linux file system** (ext4, btrfs, xfs), for example in your
home directory. A disk shared with Windows (NTFS, FAT, exFAT) or a network share does
not work: the build needs Linux owners, permissions and links.

### 1. Install the dependencies

One script installs everything, as a normal user (it asks for the `sudo` password):

```sh
git clone https://github.com/aptecstudio/project-os.git ~/project-os
cd ~/project-os
tools/setup-host.sh          # add --yes to answer "yes" to every question
```

It can be run again at any time. What it installs and sets up:

| What | Packages | Why |
|---|---|---|
| Yocto build tools | `build-essential chrpath cpio debianutils diffstat file gawk gcc git iputils-ping libacl1 locales lz4 python3 python3-git python3-jinja2 python3-pexpect python3-pip python3-subunit socat texinfo unzip wget xz-utils zstd` | compile the whole system from source |
| Emulator | `qemu-system-x86 qemu-utils ovmf` | boot the image with UEFI firmware |
| Helpers | `pipx python3-venv openssl ca-certificates curl` | install kas, create the signing keys, download sources |
| Branding | `librsvg2-bin python3-pil python3-numpy fonts-inter` | regenerate the logo and boot menu images |
| kas, style checks | `kas`, `ruff`, `shellcheck-py`, `oelint-adv` (through pipx, in `~/.local/bin`) | start the build; `tools/lint.sh` |
| Settings | `en_US.UTF-8` locale, `kvm` group, user namespaces on Ubuntu (asks first) | required by bitbake and the emulator |
| Development keys | `~/.config/project-os/keys`, outside the repository | sign the test updates |

At the end the script checks every tool and lists what is missing, if anything. Then
**open a new terminal** (log out and back in if it added you to the `kvm` group).

<details>
<summary>Installing by hand, without the script</summary>

```sh
sudo apt-get update
sudo apt-get install -y build-essential chrpath cpio debianutils diffstat file gawk \
    gcc git iputils-ping libacl1 locales lz4 python3 python3-git python3-jinja2 \
    python3-pexpect python3-pip python3-subunit socat texinfo unzip wget xz-utils zstd \
    pipx python3-venv openssl ca-certificates curl qemu-system-x86 qemu-utils ovmf \
    librsvg2-bin python3-pil python3-numpy fonts-inter
sudo sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen && sudo locale-gen
pipx ensurepath
pipx install kas && pipx install ruff && pipx install shellcheck-py \
    && pipx install oelint-adv
tools/gen-dev-keys.sh
sudo usermod -aG kvm "$USER"
```

On Ubuntu 24.04 and later, also allow user namespaces for bitbake (see the comments in
`tools/setup-host.sh`).

</details>

### 2. Build and run

```sh
tools/build.sh                  # builds the disk image (hours the first time)
tools/build.sh --low-resources  # the same, on a PC with less than 16 GB of RAM
tools/run-qemu.sh               # boots it in the emulator (--text: in the terminal)
tools/build.sh update           # signed A/B update bundle
tools/lint.sh                   # code style checks, before every commit
```

Downloads go into `sources/` and the build into `build/`; later builds reuse them and
take minutes. Log in as `root`, without password (development image only).

Modes, update tests, current limitations and troubleshooting:
[`docs/development.md`](docs/development.md).

## How it is made

| Component | Choice |
|---|---|
| System build | Yocto Project 6.0 (LTS), with kas |
| Kernel | Linux 6.18 LTS; on phones, the vendor's kernel and drivers |
| Boot | GRUB, with themed menu and dual boot |
| Updates | Two copies of the system (A/B), signed bundles |
| App language | Lua (Luau) |
| Graphics | own framework on EGL and OpenGL ES, drawn with Skia |
| Web engine | WPE WebKit, from a [fork maintained by the project](https://github.com/aptecstudio/WebKit) |
| Native components | Rust |
| Graphics and input | Wayland |

The choices and their reasons are in [`MEMORY.md`](MEMORY.md); the working rules for
contributors, people or AI agents, in [`AGENTS.md`](AGENTS.md).

## License

The project-os code is released under the [GNU GPL v3](LICENSE) license. The WebKit
fork keeps WebKit's original licenses. The Inter font, used in the boot menu, is
distributed under the SIL Open Font License 1.1.

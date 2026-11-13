# Working on project-os from your own PC

How to download the project, build the desktop image and test it in the QEMU emulator.
Status: Phase 1 (base system), November 2026.

## 1. The build host

The build compiles the whole system from source (kernel, libraries, systemd and the
rest), so it needs a capable machine:

| | Minimum | Recommended |
|---|---|---|
| System | Ubuntu Server 24.04 LTS | Ubuntu Server 26.04 LTS |
| RAM | 16 GB | 32 GB |
| Free disk | 250 GB | 400 GB on SSD |
| Processor | 4 cores | 8 cores or more |

A virtual machine (VirtualBox, VMware, GNOME Boxes, Hyper‑V) or a dedicated PC both
work. In a VM, enable **nested virtualization**: without it the emulator works but is
very slow. No desktop is needed, the Server edition is enough; the emulator window can
also be opened from Ubuntu Desktop.

If your PC already runs Linux (Ubuntu or Debian), you can work directly there.

**Laptop or PC with few resources** (about 8 GB of RAM, 4 cores and 45 GB free): enough
for the Phase 1 image, with the `--low-resources` mode (section 3). It will not be
enough from Phase 2 on, when WPE WebKit and Skia are compiled.

## 2. Download the project and prepare the machine

```sh
git clone https://github.com/aptecstudio/project-os.git
cd project-os
tools/setup-host.sh
```

`setup-host.sh` installs the programs for Yocto, kas, QEMU and the UEFI firmware, and
creates the **development keys** to sign updates in `~/.config/project-os/keys`
(outside the repository). It asks for confirmation before changing system settings.

When it finishes, log out and back in (or open a new terminal).

## 3. Build the image

There are two modes. Pick one based on your machine:

| | Default | Low resources |
|---|---|---|
| Command | `tools/build.sh` | `tools/build.sh --low-resources` |
| For | the recommended build host (section 1) | a laptop or a PC with less than 16 GB of RAM |
| Parallel compilations | all cores | at most 6 (2 recipes × 3 processes) |
| Recipe work files | kept: later builds are faster | deleted as it goes: less disk |
| Disk for the first build | about 100 GB (estimate) | about 30 GB (measured), 45 GB free recommended |
| First build | 1 to 3 hours (estimate, depends on the machine) | about 4 hours on 4 cores (measured), more on slow PCs |

If the machine looks too small for the default mode (less than 16 GB of RAM or little
free space), the script says so and asks for confirmation before starting. You can
always stop with Ctrl-C and start again with the other mode: the work already done is
not lost.

The first build downloads a few GB of sources into `sources/` and works in `build/`.
Later builds reuse the work already done and take a few minutes, if little changes.

Other commands (they also work with `--low-resources`):

| Command | What it does |
|---|---|
| `tools/build.sh update` | signed update bundle (RAUC) |
| `tools/build.sh shell` | terminal with the bitbake commands |
| `tools/build.sh --help` | script help |

**Without the scripts.** Everything the scripts do is described in the `kas/` files;
the build can also be started directly with [kas](https://kas.readthedocs.io):

```sh
export PROJECT_OS_KEYS=~/.config/project-os/keys
kas build kas/desktop-amd64.yml:kas/dev.yml                          # default
kas build kas/desktop-amd64.yml:kas/dev.yml:kas/low-resources.yml    # low resources
```

**Code style.** Before committing a change, run `tools/lint.sh`: it checks shell
scripts (ShellCheck), Python (ruff) and BitBake recipes (oelint-adv) with the
conventions of `AGENTS.md` §7, and later Rust, Luau and JavaScript too.

## 4. Test the image in the emulator

```sh
tools/run-qemu.sh            # graphical window, plus the console in the terminal
tools/run-qemu.sh --text     # everything in the terminal; to quit: Ctrl-a then x
tools/run-qemu.sh --reset    # start again from a new disk, copied from the latest build
```

What to expect today:

1. GRUB boot menu with the "project-os" entry, booted automatically after 5 seconds
   (text menu: the graphical theme comes in step 5b);
2. kernel and systemd start;
3. on **first boot**, the encrypted data partition is created in the free space;
4. text login: user `root`, no password (development configuration only); on the
   terminal console the login is automatic.

There is no graphical interface yet: it comes with Phases 2 (graphics framework and
compositor) and 5 (shell).

**Testing an update.** `tools/build.sh update` produces the signed bundle in
`build/tmp/deploy/images/project-os-amd64/`. Inside the emulator, download it (for
example from a local web server on the build host, which QEMU reaches at `10.0.2.2`)
and install it with `rauc install <file>.raucb`: on reboot the system starts from the
other copy, and goes back to the previous one by itself if the boot does not complete.

## 5. Current limitations

- **Data is not protected:** the data partition uses an empty key until the setup
  exists (ROADMAP, step 4d).
- **BIOS boot** not available yet: UEFI only (step 4e).
- **Changes to `/etc`** (network, users, host name) are kept on the encrypted data
  partition and survive reboots and updates; if an update changes a file you edited,
  your version is kept and the file is listed in `/var/lib/project-os/etc-conflicts`.
- **Android / mobile emulator:** not yet, it comes with Phase 7.

## 6. If something goes wrong

- **Build stopped because memory ran out** (processes killed by the system, messages
  like "Killed" or "out of memory"): run again with `tools/build.sh --low-resources`.
- **Build stopped with an error:** copy the last lines of the terminal and, if given,
  the log file named in the error (in `build/tmp/work/...`). The build host's system
  and the output of `git log -1` are useful too.
- **Error about namespaces or "unshare":** run `tools/setup-host.sh` again and accept
  the AppArmor change (see the explanation in the script).
- **Error about the keys:** check that `~/.config/project-os/keys/ca.cert.pem` exists,
  or create the keys with `tools/gen-dev-keys.sh`.
- **The emulator does not start or is extremely slow:** check that `/dev/kvm` exists and
  that your user is in the `kvm` group (`groups`).
- **The QEMU window does not open when started from VS Code or another snap app:**
  `tools/run-qemu.sh` already handles it; if you start `qemu-system-x86_64` by hand,
  launch it from a normal terminal.

## 7. Where things are

| Path | Contents |
|---|---|
| `AGENTS.md`, `MEMORY.md`, `ROADMAP.md` | rules, decisions, project status |
| `kas/` | build configuration |
| `layers/` | Yocto recipes: distribution, image, machine, kernel, boot |
| `branding/` | placeholder logo and boot menu theme |
| `tools/` | scripts from this guide and checking tools (`lint.sh` for the code style) |
| `ruff.toml`, `.shellcheckrc`, `tools/oelint-constants.json` | settings of the style checks |
| `build/`, `sources/` | created by the build, not versioned |

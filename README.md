# CloudDistro build guide

CloudDistro is an amd64 Debian 13 (trixie) WSL2 root filesystem for cloud and DevOps work. This repository builds a clean, reproducible, and signed `.tar.gz` and `.wsl` distribution using **Vagrant** and Debian's native **`debootstrap`** engine.

[![CI](https://github.com/AmulThantharate/cloud-distro/actions/workflows/release.yml/badge.svg)](https://github.com/AmulThantharate/cloud-distro/actions/workflows/release.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Assumptions.** Build inside the provided **Vagrant** Ubuntu 24.04 environment (VirtualBox, libvirt, or Hyper-V) or natively on Ubuntu 24.04. Docker is **not** required. Windows has current WSL (2.4.4+ recommended).

**WSL baseline.** Microsoft’s custom-distribution format requires WSL **2.4.4 or newer** for native `.wsl` sideloading. The supported primary installation command is `wsl --install --from-file clouddistro-<version>.wsl`; `wsl --import` remains the compatibility fallback.

## Build Methods Overview

See **[BUILD_METHODS.md](BUILD_METHODS.md)** for detailed instructions:
- **Vagrant (Recommended)**: Run `vagrant up` to provision a clean VM and build the custom WSL distro automatically into `./dist/`.
- **Native Host (`debootstrap`)**: Run `sudo ./build.sh` directly on any Ubuntu or Debian host machine.

## Contents

- [Build Guide (Vagrant & Debootstrap)](BUILD_METHODS.md)
- [Day 1 — Host and immutable base](docs/day-01/README.md)
- [Day 2 — Hardened Debian layer](docs/day-02/README.md)
- [Day 3 — systemd and first import](docs/day-03/README.md)
- [Day 4 — WSL and OOBE](docs/day-04/README.md)
- [Day 5 — Identity and shell](docs/day-05/README.md)
- [Day 6 — Verified DevOps CLIs](docs/day-06/README.md)
- [Day 7 — Containers and networking](docs/day-07/README.md)
- [Day 8 — Cloud CLIs and credentials](docs/day-08/README.md)
- [Day 9 — Security, scan and SBOM](docs/day-09/README.md)
- [Day 10 — Size and boot](docs/day-10/README.md)
- [Day 11 — Tests](docs/day-11/README.md)
- [Day 12 — Package and sign](docs/day-12/README.md)
- [Day 13 — Upgrade, rollback and backup](docs/day-13/README.md)
- [Day 14 — Release](docs/day-14/README.md)

## Repository tree

```text
cloud-distro/
├── BUILD_METHODS.md          # Guide: Vagrant & native debootstrap
├── Vagrantfile               # Isolated Ubuntu 24.04 VM builder environment
├── build.sh                  # Native debootstrap WSL builder script
├── .release/                 # committed tool locks and metadata
├── rootfs/etc/{wsl.conf,wsl-distribution.conf,os-release,issue,motd,godzilla.art}
├── rootfs/etc/default/useradd
├── rootfs/etc/profile.d/{00-first-run.sh,99-daily-banner.sh}
├── rootfs/etc/skel/.zshrc
├── rootfs/etc/zsh/zprofile
├── rootfs/usr/lib/wsl/{cloud-distro.ico,terminal-profile.json}
├── rootfs/usr/libexec/cloud-distro-oobe
├── rootfs/etc/sudoers.d/cloud-distro
├── docs/day-01..day-14/README.md
└── .github/workflows/release.yml
```

## Final release checklist

- `git diff --check` is clean; checksums and release metadata match upstream.
- Rootfs builds cleanly via `./build.sh` or `vagrant up`; no secrets or host artifacts leak into rootfs.
- Sudo policy parses with `visudo -cf /etc/sudoers.d/cloud-distro`.
- Imported WSL reports `running`, systemd starts, and user defaults to Zsh with passworded sudo.
- Archive, `.sha256`, and provenance match release tags.

## Known issues

WSL systemd requires a current Store WSL. DNS may be overwritten by WSL unless `generateResolvConf=false` is chosen deliberately. Never reuse a release signature after rebuilding an archive.

## License

MIT. Third-party tools retain their own licenses.

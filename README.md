# CloudDistro build guide

CloudDistro is an amd64 Debian 13 (trixie) WSL2 root filesystem for cloud and DevOps work. This repository keeps the fourteen-day implementation guide split by day so each reviewable milestone has its own README. It produces a digest-pinned, version-locked, scanned, SBOM-bearing and signed `.tar.gz` (optionally renamed `.wsl`), while retaining normal Debian `apt upgrade` maintenance.

[![CI](https://github.com/AmulThantharate/cloud-distro/actions/workflows/release.yml/badge.svg)](https://github.com/AmulThantharate/cloud-distro/actions/workflows/release.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Assumptions.** Build on Ubuntu 24.04 or WSL under `~/cloud-distro` (never `/mnt/c`), Docker Engine/Desktop is available, Windows has current WSL, and the builder is not root. Debian's official release page identifies Debian 13 **trixie** as stable (checked 2026-10-11). Docker digests change when tags are republished, so Day 1 resolves the amd64 digest from Docker Hub and commits the exact result before any build; no mutable tag is used by the Dockerfile build.

**WSL baseline.** Microsoft’s current custom-distribution format requires WSL **2.4.4 or newer**. The supported primary installation command is `wsl --install --from-file clouddistro-<version>.wsl`; `wsl --import` remains the compatibility fallback. Day 4 implements the Microsoft distribution configuration, and Day 14 covers publishing.

## Contents

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
├── Dockerfile
├── .dockerignore
├── .release/                 # committed immutable base/tool locks; no credentials
├── rootfs/etc/{wsl.conf,wsl-distribution.conf,os-release,issue,motd}
├── rootfs/usr/lib/wsl/{cloud-distro.ico,terminal-profile.json}
├── rootfs/usr/libexec/cloud-distro-oobe
├── rootfs/etc/sudoers.d/cloud-distro
├── docs/day-01..day-14/README.md
└── .github/workflows/release.yml
```

## Final release checklist

- `git diff --check` is clean; lock files contain immutable versions, URLs and SHA-256 values.
- Dockerfile is linted; build runs with `--platform linux/amd64`; no build secret/argument is copied to the image.
- `trivy image --exit-code 1 --severity HIGH,CRITICAL` passes and `sbom.spdx.json` exists.
- Imported WSL reports `running`, no failed units, and the non-root OOBE user has passworded sudo.
- Archive, `.sha256`, SBOM and provenance are signed; a second machine verifies before import.

## Known issues

WSL systemd requires a current Store WSL. DNS may be overwritten by WSL unless `generateResolvConf=false` is chosen deliberately. Docker Desktop integration is recommended; running dockerd inside a distro uses more disk/memory and needs a WSL kernel with cgroup v2. Never reuse a release signature after rebuilding an archive.

## License

MIT. Third-party tools retain their own licenses.

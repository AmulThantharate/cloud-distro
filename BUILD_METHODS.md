# Custom WSL Distribution Build Guide (Vagrant & Debootstrap)

This repository builds **CloudDistro**, an amd64 Debian 13 (trixie) WSL2 distribution, using **Vagrant** and Debian's official **`debootstrap`** engine.

No Docker daemon, Docker Desktop, or container runtime is required.

---

## Quick Start: Build with Vagrant (Recommended)

Vagrant provides an isolated, reproducible Ubuntu 24.04 virtual machine that automatically provisions build dependencies, bootstraps Debian 13, overlays the custom `rootfs`, and packages the output into `./dist/`.

### Prerequisites
- [Vagrant](https://developer.hashicorp.com/vagrant/install) (v2.3+)
- A virtualization provider: **VirtualBox**, **libvirt**, or **Hyper-V**

### 1. Start the VM and Build
Run the following from the repository root:
```bash
vagrant up
```
Vagrant boots the builder VM and automatically executes `./build.sh` via shell provisioning.

### 2. Retrieve Generated Artifacts
When the provisioning finishes, the build outputs are placed in `./dist/` on your host machine:
- `dist/clouddistro-v0.1.0.wsl` (WSL 2.4.4+ sideload package)
- `dist/clouddistro-v0.1.0.tar.gz` (Standard WSL import archive)
- `dist/clouddistro-v0.1.0.sha256` (SHA-256 integrity checksums)

### 3. Re-run or Rebuild on Demand
To run another build without recreating the VM:
```bash
vagrant provision
# or execute directly inside the VM:
vagrant ssh -c "sudo /vagrant/build.sh"
```
To destroy the builder VM when finished:
```bash
vagrant destroy -f
```

---

## Alternative: Build Directly on Linux (Without Vagrant)

If you are already running Ubuntu or Debian natively, you can invoke the builder script directly:

### 1. Make Scripts Executable
```bash
chmod +x build.sh rootfs/usr/libexec/cloud-distro-oobe
```

### 2. Run the Native Builder
```bash
sudo ./build.sh
```

The script will:
1. Install `debootstrap`, `debian-archive-keyring`, `tar`, and `gzip`.
2. Cryptographically bootstrap Debian 13 (Trixie) `minbase` from Debian's official archive.
3. Apply `rootfs/` configurations (`wsl.conf`, OOBE scripts, Godzilla daily login banner, Zsh defaults).
4. Chroot into the rootfs to install Zsh, systemd, and cloud packages.
5. Export `clouddistro-v0.1.0.tar.gz` and `clouddistro-v0.1.0.wsl` into `dist/`.

---

## Installing into Windows WSL

Once built, import into WSL from Windows PowerShell:

### Method A: WSL 2.4.4+ Native Sideload (with Interactive OOBE)
```powershell
wsl --install --from-file dist\clouddistro-v0.1.0.wsl --name CloudDistro
```
Upon first launch, CloudDistro runs the interactive user creation wizard (`cloud-distro-oobe`), creates your user with **Zsh as default shell**, sets up passworded `sudo`, and displays the daily login banner.

### Method B: Compatibility Import (`wsl --import`)
```powershell
New-Item -ItemType Directory -Force C:\WSL\CloudDistro | Out-Null
wsl --import CloudDistro C:\WSL\CloudDistro dist\clouddistro-v0.1.0.tar.gz --version 2
wsl -d CloudDistro
```
When imported directly, CloudDistro's `/etc/profile.d/00-first-run.sh` detects the missing user and launches the initial onboarding setup automatically.

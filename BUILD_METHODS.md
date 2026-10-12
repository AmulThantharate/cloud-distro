# Custom WSL Distribution Build Methods: With Docker vs. Without Docker

This document provides a side-by-side comparison and step-by-step instructions for building a custom WSL2 distribution **with Docker** and **without Docker**.

---

## Quick Comparison

| Feature | With Docker (Production) | With Docker (Quick Export) | Without Docker (`debootstrap`) | Without Docker (Alpine) |
|---|---|---|---|---|
| **Build Time** | 3–8 min | ~2 min | ~5 min | ~30 sec |
| **Prerequisites** | Docker Engine & Buildx | Docker Engine | `debootstrap`, `tar` | `curl`, `tar` |
| **Reproducibility** | Immutable digest-pinned | Medium | Depends on upstream repo | Pinned official tarball |
| **Security Gates** | Trivy scan + Syft SBOM | None | None | None |
| **User Setup** | Interactive OOBE (0 secrets) | Baked into container | Manual via `chroot` | Root default |
| **Use Case** | Production / Enterprise | Rapid prototyping | Containerless Linux hosts | Ultra-minimal lightweight |

---

## Method 1: With Docker

### Approach A: Production Build Pipeline (CloudDistro)
This is the main architecture used in this repository. It builds a reproducible, hardened Debian 13 WSL distribution with systemd, interactive OOBE, and proper WSL integration.

1. **Resolve immutable base digest:**
   ```bash
   export BASE_DIGEST="$(docker buildx imagetools inspect debian:trixie-slim --raw | jq -r '.manifests[] | select(.platform.os=="linux" and .platform.architecture=="amd64") | .digest')"
   printf 'BASE_IMAGE=debian:trixie-slim@%s\n' "$BASE_DIGEST" > .release/base.env
   ```

2. **Run the build script:**
   ```bash
   chmod +x build.sh rootfs/usr/libexec/cloud-distro-oobe
   ./build.sh
   ```

3. **Install in Windows WSL:**
   ```powershell
   # Sideload (WSL 2.4.4+)
   wsl --install --from-file dist\clouddistro-v0.1.0.wsl --name CloudDistro

   # Or standard import
   wsl --import CloudDistro C:\WSL\CloudDistro dist\clouddistro-v0.1.0.tar.gz --version 2
   ```

---

### Approach B: Quick Docker Export (Fast Prototyping)
When you need an ad-hoc custom distro immediately:

1. **Start any container:**
   ```bash
   docker run -d --name my-distro ubuntu:24.04 sleep infinity
   ```

2. **Customize inside container:**
   ```bash
   docker exec -it my-distro bash -c "apt-get update && apt-get install -y sudo git curl systemd && useradd -m -s /bin/bash devuser && echo 'devuser:password123' | chpasswd && usermod -aG sudo devuser"
   ```

3. **Export the container filesystem:**
   ```bash
   docker export my-distro | gzip > custom-wsl.tar.gz
   docker rm -f my-distro
   ```

4. **Import to WSL:**
   ```powershell
   wsl --import QuickUbuntu C:\WSL\QuickUbuntu custom-wsl.tar.gz --version 2
   wsl -d QuickUbuntu
   ```

---

## Method 2: Without Docker

### Approach A: Production-Grade Native Debian via `debootstrap` (Zero Docker)
This is the **official method** used by Debian and Canonical release teams to generate root filesystems for cloud and WSL images. It uses Debian's cryptographically verified package archive and integrates all WSL2 production features without needing Docker.

#### 1. Install prerequisites on your Linux build machine:
```bash
sudo apt-get update && sudo apt-get install -y debootstrap debian-archive-keyring tar gzip
```

#### 2. Bootstrap Debian 13 (Trixie) with cryptographic GPG signature verification:
```bash
sudo mkdir -p /tmp/clouddistro-rootfs
sudo debootstrap \
  --arch=amd64 \
  --variant=minbase \
  --keyring=/usr/share/keyrings/debian-archive-keyring.gpg \
  trixie /tmp/clouddistro-rootfs http://deb.debian.org/debian/
```

#### 3. Copy our production rootfs configurations into the bootstrapped filesystem:
```bash
sudo cp -r rootfs/* /tmp/clouddistro-rootfs/
```

#### 4. Configure and harden inside `chroot`:
```bash
sudo chroot /tmp/clouddistro-rootfs /bin/bash << 'EOF'
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Update apt and install essential WSL & DevOps packages
apt-get update
apt-get install -y --no-install-recommends \
    bash-completion ca-certificates curl dbus git iproute2 iputils-ping \
    jq locales make openssh-client pipx python3 python3-pip sudo \
    systemd systemd-sysv tmux tzdata unattended-upgrades unzip vim-tiny xz-utils

# Configure UTF-8 Locale
sed -i 's/^# *C.UTF-8 UTF-8/C.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
update-locale LANG=C.UTF-8 LC_ALL=C.UTF-8

# Mask problematic WSL services
systemctl mask getty@.service systemd-networkd-wait-online.service

# Truncate machine-id so each WSL clone gets a unique machine ID
truncate -s 0 /etc/machine-id
ln -sf /etc/machine-id /var/lib/dbus/machine-id

# Link WSL interoperability path translator
if [ ! -e /usr/bin/wslpath ]; then
    ln -s /init /usr/bin/wslpath
fi

# Set strict permissions on sudo and OOBE
chmod 0440 /etc/sudoers.d/cloud-distro
chmod 0644 /etc/wsl.conf /etc/wsl-distribution.conf /usr/lib/wsl/terminal-profile.json
chmod 0755 /usr/libexec/cloud-distro-oobe
visudo -cf /etc/sudoers.d/cloud-distro

# Clean up apt caches to minimize archive size
apt-get clean
rm -rf /var/lib/apt/lists/* /var/cache/apt/* /usr/share/doc/* /usr/share/man/* /tmp/*
exit
EOF
```

#### 5. Deterministically package into `.tar.gz` and `.wsl`:
```bash
mkdir -p dist
cd /tmp/clouddistro-rootfs
sudo tar --numeric-owner --exclude='proc/*' --exclude='sys/*' --exclude='dev/*' -czf "$OLDPWD/dist/clouddistro-v0.1.0.tar.gz" .
cd "$OLDPWD"
cp dist/clouddistro-v0.1.0.tar.gz dist/clouddistro-v0.1.0.wsl
(cd dist && sha256sum clouddistro-v0.1.0.tar.gz clouddistro-v0.1.0.wsl > clouddistro-v0.1.0.sha256)
```

#### 6. Clean up temporary build directory:
```bash
sudo rm -rf /tmp/clouddistro-rootfs
```

#### 7. Install into Windows WSL (Windows PowerShell):
```powershell
# WSL 2.4.4+ Native Sideload (with OOBE user creation):
wsl --install --from-file dist\clouddistro-v0.1.0.wsl --name CloudDistro

# Or standard import fallback:
New-Item -ItemType Directory -Force C:\WSL\CloudDistro | Out-Null
wsl --import CloudDistro C:\WSL\CloudDistro dist\clouddistro-v0.1.0.tar.gz --version 2
wsl -d CloudDistro
```

---

### Approach B: Minimal Alpine Linux Minirootfs
If you want an ultra-lightweight WSL instance (~15MB compressed):

1. **Download official Alpine minirootfs:**
   ```bash
   curl -LO https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/alpine-minirootfs-3.20.3-x86_64.tar.gz
   ```

2. **Directly import into WSL (No build step required):**
   ```powershell
   New-Item -ItemType Directory -Force C:\WSL\Alpine | Out-Null
   wsl --import Alpine C:\WSL\Alpine alpine-minirootfs-3.20.3-x86_64.tar.gz --version 2
   wsl -d Alpine
   ```

3. **Configure inside Alpine:**
   ```sh
   apk update && apk add bash sudo shadow
   adduser -D -u 1000 alpineuser
   echo "alpineuser:password" | chpasswd
   addgroup alpineuser wheel
   echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
   ```

---

## When to Choose Which Method

- **Use Docker (Production)**: When you are building a distributable, auditable, and security-scanned release for a team, organization, or public repository.
- **Use Docker (Quick Export)**: When you already have Docker installed and want to quickly test tools or configurations in WSL within minutes.
- **Use `debootstrap` (Without Docker)**: When you do not have Docker or permissions to run container engines on your Linux host.
- **Use Alpine (Without Docker)**: When you require maximum startup speed and minimal disk/memory footprint.

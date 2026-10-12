# CloudDistro: Debian 13 (Trixie) Custom WSL2 Distribution

CloudDistro is a reproducible, secure, amd64 **Debian 13 (trixie)** WSL2 root filesystem built for cloud and DevOps engineering.

This distribution is built **manually using Vagrant and native Debian `debootstrap`**. No Docker daemon, Dockerfiles, or opaque wrapper scripts are used. Every single command is documented below so you can execute and understand the complete process yourself.

[![CI](https://github.com/AmulThantharate/cloud-distro/actions/workflows/release.yml/badge.svg)](https://github.com/AmulThantharate/cloud-distro/actions/workflows/release.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Key Features

- **Pure Native Build (Zero Docker):** Bootstrapped with Debian's cryptographically verified package archive using `debootstrap`.
- **Isolated Build Environment:** Runs inside an Ubuntu 24.04 LTS VM using Vagrant to keep your personal host completely clean.
- **Default Zsh Shell:** Pre-configured with tab completion, persistent history, keybindings, and prompt styling via `/etc/skel/.zshrc`.
- **Godzilla Daily Login Art:** Interactive shell banner that prints the green ASCII monster once per calendar day upon login.
- **Native WSL2 OOBE:** Microsoft-compliant Out-Of-Box Experience wizard creating user UID 1000 with passworded `sudo`.
- **systemd Enabled:** Native WSL systemd integration with problematic daemons (`getty`, `wait-online`) masked.

---

## Repository Structure

```text
cloud-distro/
├── Vagrantfile               # Clean Ubuntu 24.04 LTS builder VM definition
├── rootfs/                   # Distribution overlay files:
│   ├── etc/
│   │   ├── wsl.conf                     # WSL systemd & interop settings
│   │   ├── wsl-distribution.conf        # OOBE entrypoint & terminal profile link
│   │   ├── os-release                   # CloudDistro identity
│   │   ├── issue & motd                 # Distribution pre/post login notices
│   │   ├── godzilla.art                 # Godzilla ASCII art asset
│   │   ├── default/useradd              # Sets default shell to /bin/zsh
│   │   ├── skel/.zshrc                  # Default user Zsh configuration
│   │   ├── zsh/zprofile                 # Sourced by zsh to load /etc/profile & profile.d
│   │   ├── profile.d/
│   │   │   ├── 00-first-run.sh          # Fallback onboarding for 'wsl --import'
│   │   │   └── 99-daily-banner.sh       # Daily Godzilla banner trigger
│   │   └── sudoers.d/cloud-distro       # Passworded sudo policy
│   ├── usr/lib/wsl/
│   │   ├── terminal-profile.json        # Windows Terminal color & profile config
│   │   └── cloud-distro.ico             # Distribution desktop icon
│   └── usr/libexec/
│       └── cloud-distro-oobe            # Interactive first-run user setup script
├── dist/                     # Generated build output directory
├── docs/day-01..day-14/      # Detailed 14-day implementation guides
└── .github/workflows/        # Automated CI workflow
```

---

## Complete Step-by-Step Build Guide

Run these commands in order.

### Step 1: Launch and Enter the Builder VM
From the repository root on your host machine (Windows or Linux):
```bash
# Start the clean Ubuntu 24.04 builder VM
vagrant up

# SSH into the builder VM
vagrant ssh
```

---

### Step 2: Install Build Tools Inside the VM
Inside the Vagrant VM, install `debootstrap`, the official Debian archive keyrings, and archiving tools:
```bash
sudo apt-get update
sudo apt-get install -y debootstrap debian-archive-keyring tar gzip
```

---

### Step 3: Debootstrap Debian 13 (Trixie)
Bootstrap a clean Debian 13 amd64 base system from Debian's official mirror:
```bash
# Create target build directory
sudo rm -rf /tmp/clouddistro-rootfs
sudo mkdir -p /tmp/clouddistro-rootfs

# Bootstrap Debian 13 minbase with cryptographic GPG signature verification
sudo debootstrap \
  --arch=amd64 \
  --variant=minbase \
  --keyring=/usr/share/keyrings/debian-archive-keyring.gpg \
  trixie \
  /tmp/clouddistro-rootfs \
  http://deb.debian.org/debian/
```

---

### Step 4: Overlay Custom Files and Set File Permissions
Copy the repository's configuration files into the bootstrapped filesystem:
```bash
# Navigate to the shared repository directory
cd /vagrant

# Overlay our custom rootfs files onto the bootstrapped system
sudo cp -r rootfs/* /tmp/clouddistro-rootfs/

# Set strict permissions required by sudo, WSL, and scripts
sudo chmod 0440 /tmp/clouddistro-rootfs/etc/sudoers.d/cloud-distro
sudo chmod 0644 /tmp/clouddistro-rootfs/etc/wsl.conf
sudo chmod 0644 /tmp/clouddistro-rootfs/etc/wsl-distribution.conf
sudo chmod 0644 /tmp/clouddistro-rootfs/etc/godzilla.art
sudo chmod 0644 /tmp/clouddistro-rootfs/etc/default/useradd
sudo chmod 0644 /tmp/clouddistro-rootfs/etc/skel/.zshrc
sudo chmod 0644 /tmp/clouddistro-rootfs/etc/zsh/zprofile
sudo chmod 0755 /tmp/clouddistro-rootfs/etc/profile.d/*.sh
sudo chmod 0755 /tmp/clouddistro-rootfs/usr/libexec/cloud-distro-oobe
```

---

### Step 5: Configure Packages & Environment Inside `chroot`
Chroot into the target filesystem to install required packages and configure system services:
```bash
sudo chroot /tmp/clouddistro-rootfs /bin/bash
```

*Now you are inside the chroot environment. Run the following commands:*

```bash
# 1. Non-interactive apt setup
export DEBIAN_FRONTEND=noninteractive
apt-get update

# 2. Install essential WSL, cloud, and DevOps packages (including zsh)
apt-get install -y --no-install-recommends \
    bash-completion \
    ca-certificates \
    curl \
    dbus \
    git \
    gpg \
    gzip \
    iproute2 \
    iputils-ping \
    jq \
    locales \
    make \
    openssh-client \
    pipx \
    python3 \
    python3-pip \
    sudo \
    systemd \
    systemd-sysv \
    tmux \
    tzdata \
    unattended-upgrades \
    unzip \
    vim-tiny \
    xz-utils \
    zsh

# 3. Configure UTF-8 Locale
sed -i 's/^# *C.UTF-8 UTF-8/C.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
update-locale LANG=C.UTF-8 LC_ALL=C.UTF-8

# 4. Mask problematic WSL services
systemctl mask getty@.service systemd-networkd-wait-online.service

# 5. Reset machine-id so each WSL clone generates a unique ID
truncate -s 0 /etc/machine-id
ln -sf /etc/machine-id /var/lib/dbus/machine-id

# 6. Create WSL path translation symlink
if [ ! -e /usr/bin/wslpath ]; then
    ln -s /init /usr/bin/wslpath
fi

# 7. Validate sudoers file syntax
visudo -cf /etc/sudoers.d/cloud-distro

# 8. Clean up apt cache to keep image size small
apt-get clean
rm -rf /var/lib/apt/lists/* /var/cache/apt/* /usr/share/doc/* /usr/share/man/* /tmp/*

# 9. Exit chroot back to the Vagrant VM
exit
```

---

### Step 6: Package the Distribution into `.tar.gz` and `.wsl`
Back in the Vagrant VM, create the distribution packages in `/vagrant/dist`:
```bash
# Create dist directory in the shared folder
mkdir -p /vagrant/dist

# Package the rootfs (preserving numeric owners and excluding virtual filesystems)
cd /tmp/clouddistro-rootfs
sudo tar --numeric-owner \
    --exclude='proc/*' \
    --exclude='sys/*' \
    --exclude='dev/*' \
    -czf /vagrant/dist/clouddistro-v0.1.0.tar.gz .

# Create the .wsl sideload package
cd /vagrant/dist
cp clouddistro-v0.1.0.tar.gz clouddistro-v0.1.0.wsl

# Generate SHA-256 integrity checksums
sha256sum clouddistro-v0.1.0.tar.gz clouddistro-v0.1.0.wsl > clouddistro-v0.1.0.sha256

# Verify the archive contains essential files
tar -tzf clouddistro-v0.1.0.tar.gz | grep -E '^etc/wsl.conf$'
tar -tzf clouddistro-v0.1.0.tar.gz | grep -E '^etc/godzilla.art$'

# Clean up temporary build rootfs
sudo rm -rf /tmp/clouddistro-rootfs

# Exit the Vagrant VM
exit
```

---

## Installing into Windows WSL

The output files are now directly on your host in `./dist/`.

Open **Windows PowerShell**:

### Method A: Native Sideload with OOBE (WSL 2.4.4+)
```powershell
wsl --install --from-file dist\clouddistro-v0.1.0.wsl --name CloudDistro
```
Upon opening, the OOBE prompts you for your username, sets your password, starts with **Zsh as default**, and displays the green Godzilla banner.

### Method B: Standard Import
```powershell
New-Item -ItemType Directory -Force C:\WSL\CloudDistro | Out-Null
wsl --import CloudDistro C:\WSL\CloudDistro dist\clouddistro-v0.1.0.tar.gz --version 2
wsl -d CloudDistro
```

---

## Managing the Vagrant VM

When you are done building:
```bash
# Halt the VM
vagrant halt

# Or destroy the VM to free disk space
vagrant destroy -f
```

---

## License

MIT. Third-party tools retain their own upstream licenses.

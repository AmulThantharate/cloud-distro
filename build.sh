#!/usr/bin/env bash
# CloudDistro Native WSL2 Distribution Builder (Vagrant / Debootstrap)
# Builds a Debian 13 (Trixie) WSL2 rootfs without Docker

set -euo pipefail

DIST_VERSION="${DIST_VERSION:-v0.1.0}"
TARGET_DIR="/tmp/clouddistro-rootfs"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="${SCRIPT_DIR}/dist"

echo "=========================================================="
echo " Building CloudDistro ${DIST_VERSION} WSL2 Distribution"
echo " Method: Native Debootstrap (Zero Docker)"
echo " Working directory: ${SCRIPT_DIR}"
echo "=========================================================="

# Check for root / sudo
if [ "$(id -u)" -ne 0 ]; then
    echo "==> Script requires root privileges. Elevating with sudo..."
    exec sudo DIST_VERSION="${DIST_VERSION}" "$0" "$@"
fi

# 1. Install Host Prerequisites
echo "==> [1/6] Installing build prerequisites..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq --no-install-recommends \
    debootstrap \
    debian-archive-keyring \
    tar \
    gzip \
    ca-certificates \
    curl \
    jq

# 2. Debootstrap Debian 13 (Trixie) minbase
echo "==> [2/6] Bootstrapping Debian 13 (trixie) amd64 rootfs..."
rm -rf "${TARGET_DIR}"
mkdir -p "${TARGET_DIR}"
debootstrap \
    --arch=amd64 \
    --variant=minbase \
    --keyring=/usr/share/keyrings/debian-archive-keyring.gpg \
    trixie \
    "${TARGET_DIR}" \
    http://deb.debian.org/debian/

# 3. Overlay repository rootfs
echo "==> [3/6] Applying CloudDistro rootfs overlays..."
if [ -d "${SCRIPT_DIR}/rootfs" ]; then
    cp -r "${SCRIPT_DIR}/rootfs"/* "${TARGET_DIR}/"
fi

# Ensure permissions
chmod 0440 "${TARGET_DIR}/etc/sudoers.d/cloud-distro" 2>/dev/null || true
chmod 0644 "${TARGET_DIR}/etc/wsl.conf" 2>/dev/null || true
chmod 0644 "${TARGET_DIR}/etc/wsl-distribution.conf" 2>/dev/null || true
chmod 0644 "${TARGET_DIR}/etc/godzilla.art" 2>/dev/null || true
chmod 0755 "${TARGET_DIR}/etc/profile.d/"*.sh 2>/dev/null || true
chmod 0755 "${TARGET_DIR}/usr/libexec/cloud-distro-oobe" 2>/dev/null || true

# 4. Configure system inside chroot
echo "==> [4/6] Configuring packages and services inside chroot..."
chroot "${TARGET_DIR}" /bin/bash << 'EOF'
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Update apt repositories
apt-get update

# Install essential WSL & Cloud packages
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

# Configure UTF-8 Locale
sed -i 's/^# *C.UTF-8 UTF-8/C.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
update-locale LANG=C.UTF-8 LC_ALL=C.UTF-8

# Mask problematic WSL units
systemctl mask getty@.service systemd-networkd-wait-online.service

# Unique machine ID setup
truncate -s 0 /etc/machine-id
ln -sf /etc/machine-id /var/lib/dbus/machine-id

# Link WSL interoperability path translator
if [ ! -e /usr/bin/wslpath ]; then
    ln -s /init /usr/bin/wslpath
fi

# Verify sudoers syntax
visudo -cf /etc/sudoers.d/cloud-distro

# Clean up apt caches to minimize archive size
apt-get clean
rm -rf /var/lib/apt/lists/* /var/cache/apt/* /usr/share/doc/* /usr/share/man/* /tmp/*
EOF

# 5. Deterministic packaging
echo "==> [5/6] Packaging into .tar.gz and .wsl..."
mkdir -p "${DIST_DIR}"
TAR_NAME="clouddistro-${DIST_VERSION}.tar.gz"
WSL_NAME="clouddistro-${DIST_VERSION}.wsl"

(
    cd "${TARGET_DIR}"
    tar --numeric-owner \
        --exclude='proc/*' \
        --exclude='sys/*' \
        --exclude='dev/*' \
        -czf "${DIST_DIR}/${TAR_NAME}" .
)

cp "${DIST_DIR}/${TAR_NAME}" "${DIST_DIR}/${WSL_NAME}"

(
    cd "${DIST_DIR}"
    sha256sum "${TAR_NAME}" "${WSL_NAME}" > "clouddistro-${DIST_VERSION}.sha256"
)

# 6. Cleanup temporary rootfs
echo "==> [6/6] Cleaning up build temporary files..."
rm -rf "${TARGET_DIR}"

echo "=========================================================="
echo " CloudDistro build complete!"
echo " Artifacts generated in: ${DIST_DIR}"
echo " - ${TAR_NAME}"
echo " - ${WSL_NAME}"
echo " - clouddistro-${DIST_VERSION}.sha256"
echo "=========================================================="

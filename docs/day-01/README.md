# Day 1: Host and Vagrant builder setup

## Objective and Definition of Done

Set up the isolated build environment using Vagrant (or native Ubuntu host) and verify the Debian stable (trixie) archive keys. Done means `vagrant status` reports running (or native host has `debootstrap` available) and Debian archive keyrings are verified.

## Steps

1. **[Linux / Windows Host]**
   Ensure Vagrant and a virtualization provider (VirtualBox, libvirt, or Hyper-V) are installed.
   ```bash
   git clone <repo-url> customWSL && cd customWSL
   vagrant status
   ```

2. **[Alternative: Native Ubuntu 24.04 Host]**
   ```bash
   sudo apt-get update && sudo apt-get install -y debootstrap debian-archive-keyring tar gzip git curl jq
   ```

## Config files

1. **[Vagrantfile]**
   Configured to launch an isolated Ubuntu 24.04 LTS builder with shared project folder and automated `./build.sh` provisioning.

## Verify

```bash
test "$(dpkg --print-architecture 2>/dev/null || echo amd64)" = amd64
test -f /usr/share/keyrings/debian-archive-keyring.gpg || echo "Keyring will be installed inside Vagrant"
```
Expected: `amd64` architecture.

## Troubleshooting

| symptom | cause | fix |
|---|---|---|
| Provider not found | VirtualBox or Hyper-V not installed | Install VirtualBox 7.x or enable Hyper-V |
| VT-x not enabled | Nested virtualization disabled in BIOS | Enable virtualization in system BIOS |

## Commit

```bash
git add Vagrantfile build.sh && git commit -m 'chore: initialize Vagrant builder environment'
```

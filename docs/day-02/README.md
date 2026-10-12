# Day 2: Hardened Debian layer via debootstrap

## Objective and Definition of Done

Bootstrap a clean Debian 13 (trixie) amd64 base system with UTF-8 locale, UTC timezone, and systemd, with zero retained apt caches. Done means `/var/lib/apt/lists` is clean and `locale -a` includes `C.UTF-8`.

## Steps

1. **[Vagrant / Native Host]**
   Bootstrap Debian 13 minbase with cryptographic GPG signature verification:
   ```bash
   sudo debootstrap \
       --arch=amd64 \
       --variant=minbase \
       --keyring=/usr/share/keyrings/debian-archive-keyring.gpg \
       trixie \
       /tmp/clouddistro-rootfs \
       http://deb.debian.org/debian/
   ```

2. Configure locale and mask problematic WSL services inside chroot:
   ```bash
   sudo chroot /tmp/clouddistro-rootfs /bin/bash -c "
       sed -i 's/^# *C.UTF-8 UTF-8/C.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
       update-locale LANG=C.UTF-8 LC_ALL=C.UTF-8
   "
   ```

## Verify

```bash
sudo chroot /tmp/clouddistro-rootfs locale -a | grep -Fx C.UTF-8
```
Expected: `C.UTF-8`.

## Troubleshooting

| symptom | cause | fix |
|---|---|---|
| apt signature error | stale clock/CA bundle | correct host time; verify `debian-archive-keyring` |
| debootstrap failed | network connectivity to mirror | check internet connection to deb.debian.org |

## Commit

```bash
git add build.sh && git commit -m 'build: add hardened Debian base via debootstrap'
```

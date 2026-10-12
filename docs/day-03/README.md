# Day 3: systemd and first import

## Objective and Definition of Done

Export a rootfs that starts systemd under WSL. Done means an imported test distro returns `running` and no failed units.

## Steps

1. **[Vagrant / Linux Host]**
   Build the distribution using Vagrant or `build.sh`:
   ```bash
   vagrant up
   # or on Linux host:
   sudo ./build.sh
   ```
   The tarball is written directly to `dist/clouddistro-v0.1.0.tar.gz`.

2. **[Windows PowerShell]**
   ```powershell
   wsl --shutdown
   New-Item -ItemType Directory -Force C:\WSL\CloudDistro-dev | Out-Null
   wsl --import CloudDistro-dev C:\WSL\CloudDistro-dev dist\clouddistro-v0.1.0.tar.gz --version 2
   wsl -d CloudDistro-dev -- systemctl is-system-running
   wsl -d CloudDistro-dev -- systemctl --failed
   ```

## Config files

Systemd packages, `/etc/machine-id` handling, and problematic unit masks (`getty@.service`, `systemd-networkd-wait-online.service`) are handled automatically in `build.sh`.

## Verify

Expected output: `running` (or `degraded` if offline), with `0 loaded units listed` failing.

## Troubleshooting

| symptom | cause | fix |
|---|---|---|
| `System has not been booted` | old WSL or absent `systemd=true` | `wsl --update`; ensure `/etc/wsl.conf` has `[boot] systemd=true` |
| machine-id collision | image carried a fixed ID | verify `build.sh` truncates `/etc/machine-id` |

## Commit

```bash
git add build.sh && git commit -m 'feat: enable systemd-ready rootfs export'
```

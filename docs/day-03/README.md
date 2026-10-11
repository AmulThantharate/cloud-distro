# Day 3: systemd and first import

## Objective and Definition of Done

Export a rootfs that starts systemd under WSL. Done means an imported test distro returns `running` and no failed unit.

## Steps

1. **[Docker Build]**
   ```bash
   source .release/base.env
   docker buildx build --platform linux/amd64 --load --build-arg BASE_IMAGE="$BASE_IMAGE" -t clouddistro:dev .
   cid="$(docker create clouddistro:dev)"; docker export "$cid" | gzip -n > dist/clouddistro-dev.tar.gz; docker rm "$cid"
   ```
2. **[Windows PowerShell]**
   ```powershell
   wsl --shutdown
   New-Item -ItemType Directory -Force C:\WSL\CloudDistro-dev | Out-Null
   wsl --import CloudDistro-dev C:\WSL\CloudDistro-dev $HOME\Downloads\clouddistro-dev.tar.gz --version 2
   wsl -d CloudDistro-dev -- systemctl is-system-running
   wsl -d CloudDistro-dev -- systemctl --failed
   ```

## Config files

Systemd packages, `/etc/machine-id` handling, and failing-unit masks are in the complete Dockerfile in Day 6.

## Verify

Expected output: `running`, then `0 loaded units listed`.

## Troubleshooting

| symptom | cause | fix |
|---|---|---|
| `System has not been booted` | old WSL or absent `systemd=true` | `wsl --update`; complete Day 4; `wsl --shutdown` |
| machine-id error | image carried a fixed ID | ensure Dockerfile truncates `/etc/machine-id` |

## Commit

```bash
git add . && git commit -m 'feat: enable systemd-ready rootfs export'
```

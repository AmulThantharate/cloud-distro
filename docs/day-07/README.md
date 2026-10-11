# Day 7: Containers and networking

## Objective and Definition of Done

Offer Docker Desktop integration and an optional in-distro engine without enabling an unnecessary daemon by default. Done means `docker context ls` works using the selected option and cgroup v2 is present for the engine option.

## Steps

1. **[Windows PowerShell]** Recommended: Docker Desktop → Settings → Resources → WSL Integration → enable `CloudDistro-dev`, then:
   ```powershell
   wsl -d CloudDistro-dev -- docker version
   ```
2. **[Linux Host]** Optional in-distro engine: add Docker's official signed Debian repository following <https://docs.docker.com/engine/install/debian/>, pin the exact `docker-ce` and `containerd.io` versions in a committed apt preferences file, then enable it only inside the imported distro.
3. **[Windows PowerShell]**
   ```powershell
   wsl -d CloudDistro-dev -- stat -fc %T /sys/fs/cgroup
   wsl -d CloudDistro-dev -- systemctl enable --now docker
   ```

## Config files

No engine configuration is baked into the image. The image contains only the pinned Docker CLI. Docker Desktop integration is recommended because it avoids a second daemon and image store.

## Verify

```bash
docker context ls; docker run --rm hello-world
```
Expected: selected context is reachable; hello-world completes.

## Troubleshooting

| symptom | cause | fix |
|---|---|---|
| cannot connect to daemon | Desktop integration disabled | enable it and restart WSL |
| cgroup is not `cgroup2fs` | outdated WSL kernel | `wsl --update`, shut down, retry |

## Commit

```bash
git commit --allow-empty -m 'docs: document Docker Desktop and engine options'
```

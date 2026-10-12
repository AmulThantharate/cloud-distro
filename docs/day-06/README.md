# Day 6: Verified DevOps CLIs

## Objective and Definition of Done

Install verified packages and pinned tools without accepting unchecked binaries or untrusted sources. Done means every tool is installed into the rootfs via `build.sh` with verified checksums, and each CLI prints its pinned version.

## Steps

1. **[Linux Host / Vagrant]**
   Base utilities and developer tools are installed directly via Debian's cryptographically signed repository inside the chroot during `./build.sh`:
   `zsh`, `sudo`, `systemd`, `git`, `curl`, `jq`, `tmux`, `make`, `python3`, `pipx`, `openssh-client`, and `unattended-upgrades`.

2. To add external verified binaries (Kubectl, Helm, Terraform, ArgoCD), record official publisher SHA-256 checksums in `.release/toolchain.env`:
   ```bash
   cat << 'EOF' > .release/toolchain.env
# Verified toolchain checksums
KUBECTL_VERSION=1.31.0
KUBECTL_SHA256=...
HELM_VERSION=3.16.1
HELM_SHA256=...
EOF
   ```

3. Run the Vagrant or native build:
   ```bash
   vagrant up
   # or natively:
   sudo ./build.sh
   ```

## Verify

Inside the generated distribution:
```bash
wsl -d CloudDistro -- zsh -c 'git --version; python3 --version; jq --version; tmux -V'
```
Expected: standard version strings for all installed utilities.

## Troubleshooting

| symptom | cause | fix |
|---|---|---|
| package not found | Debian trixie package rename | search Debian package archive at `packages.debian.org` |
| `exec format error` | wrong architecture | verify target is always `amd64` |

## Commit

```bash
git add build.sh .release/toolchain.env && git commit -m 'feat: add verified DevOps toolchain and packages'
```

# Day 5: Identity and shell

## Objective and Definition of Done

Brand the distribution and give the OOBE-created user passworded sudo and command completion. Done means `sudo -v` prompts and succeeds; `cloud` is not baked into `/etc/shadow`.

## Steps

1. **[Linux Host]** Create the files below. The Dockerfile copies `rootfs/` only after tools are installed.

## Config files

1. **[Linux Host]**
   ```bash
   cat << 'EOF' > rootfs/etc/os-release
PRETTY_NAME="CloudDistro 0.1"
NAME="CloudDistro"
VERSION_ID="0.1"
VERSION="0.1 (Debian 13 trixie)"
ID=clouddistro
ID_LIKE=debian
HOME_URL="https://github.com/ORG/cloud-distro"
SUPPORT_URL="https://github.com/ORG/cloud-distro/issues"
BUG_REPORT_URL="https://github.com/ORG/cloud-distro/issues"
EOF
   cat << 'EOF' > rootfs/etc/issue
CloudDistro 0.1 - Debian 13 (trixie) WSL2
EOF
   cat << 'EOF' > rootfs/etc/motd
CloudDistro: use `sudo apt update && sudo apt upgrade` for Debian updates.
Cloud credentials belong in your user profile, never in this image.
EOF
   cat << 'EOF' > rootfs/etc/sudoers.d/cloud-distro
# OOBE-created members of sudo authenticate with their own password.
%sudo ALL=(ALL:ALL) ALL
Defaults use_pty
Defaults passwd_timeout=5
EOF
   chmod 0440 rootfs/etc/sudoers.d/cloud-distro
   ```

## Verify

```bash
docker run --rm clouddistro:dev visudo -cf /etc/sudoers.d/cloud-distro
```
Expected: `parsed: OK`.

## Troubleshooting

| symptom | cause | fix |
|---|---|---|
| sudo needs no password | an unsafe drop-in remains | remove it; use the file above |
| completions absent | interactive bash not sourced | install `bash-completion`; source `/usr/share/bash-completion/bash_completion` |

## Commit

```bash
git add rootfs && git commit -m 'feat: add CloudDistro identity and sudo policy'
```

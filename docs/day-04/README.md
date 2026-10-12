# Day 4: WSL and OOBE

## Objective and Definition of Done

Enable systemd, safe interop and Microsoft-style first-run OOBE. Done means `wsl --version` is at least 2.4.4, a `.wsl` sideload invokes OOBE, the OOBE-created UID is 1000, no password hash ships in the image, and the Start-menu/Windows Terminal metadata exists.

This section follows Microsoft’s current [Build a Custom Linux Distribution for WSL](https://learn.microsoft.com/windows/wsl/build-custom-distro) guidance, which applies to WSL 2.4.4+.

## Steps

1. **[Windows PowerShell]** Verify the required Microsoft custom-distribution capability before packaging.
   ```powershell
   wsl --version
   ```
   Expected: a Store WSL version **2.4.4 or newer**. Update with `wsl --update` and then `wsl --shutdown` if necessary.
2. **[Linux Host]**
   ```bash
   install -d rootfs/etc rootfs/usr/lib/wsl rootfs/usr/libexec
   ```
3. **[Windows PowerShell]** Primary, Microsoft-supported sideload installation after packaging:
   ```powershell
   wsl --shutdown
   wsl --install --from-file $HOME\Downloads\clouddistro-v0.1.0.wsl --name CloudDistro
   ```
   Fallback for older WSL that cannot use `--from-file`:
   ```powershell
   New-Item -ItemType Directory -Force C:\WSL\CloudDistro | Out-Null
   wsl --import CloudDistro C:\WSL\CloudDistro $HOME\Downloads\clouddistro-v0.1.0.tar.gz --version 2
   wsl -d CloudDistro
   ```

## Config files

1. **[Linux Host]**
   ```bash
   cat << 'EOF' > rootfs/etc/wsl.conf
[boot]
systemd=true

[automount]
enabled=true
options="metadata,umask=022,fmask=111"
mountFsTab=false

[interop]
enabled=true
appendWindowsPath=true

[network]
generateHosts=true
generateResolvConf=true
EOF
   cat << 'EOF' > rootfs/etc/wsl-distribution.conf
[oobe]
command=/usr/libexec/cloud-distro-oobe
defaultUid=1000
defaultName=CloudDistro

[shortcut]
enabled=true
icon=/usr/lib/wsl/cloud-distro.ico

[windowsterminal]
enabled=true
profileTemplate=/usr/lib/wsl/terminal-profile.json
EOF
   cat << 'EOF' > rootfs/usr/lib/wsl/terminal-profile.json
{
  "profiles": [
    {
      "name": "CloudDistro",
      "commandline": "wsl.exe -d CloudDistro",
      "startingDirectory": "%USERPROFILE%",
      "fontFace": "Cascadia Mono",
      "colorScheme": "Campbell"
    }
  ]
}
EOF
   cat << 'EOF' > rootfs/usr/libexec/cloud-distro-oobe
#!/bin/bash
set -euo pipefail
while :; do
  read -r -p 'Create CloudDistro username: ' username
  [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]] || { echo 'Use lowercase letters, digits, _ or -; begin with a letter or _.'; continue; }
  getent passwd "$username" >/dev/null && { echo 'That username already exists.'; continue; }
  break
done
useradd --uid 1000 --create-home --shell /bin/zsh --groups sudo "$username"
passwd "$username"
install -d -m 0700 -o "$username" -g "$username" "/home/$username/.config"
EOF
   chmod 0644 rootfs/etc/wsl.conf rootfs/etc/wsl-distribution.conf rootfs/usr/lib/wsl/terminal-profile.json
   chmod 0755 rootfs/usr/libexec/cloud-distro-oobe
   ```
The OOBE command is the one required in-image executable exception to the no-build/test/package-script rule: Microsoft’s `oobe.command` explicitly requires an executable to create the user interactively. Do not use it to embed a password. Add a reviewed, valid `.ico` asset at `rootfs/usr/lib/wsl/cloud-distro.ico` (maximum 10 MB) before release; this binary asset cannot be represented meaningfully in this Markdown guide.

## Verify

```powershell
wsl -d CloudDistro -- id -u
wsl -d CloudDistro -- test -x /usr/libexec/cloud-distro-oobe
wsl -d CloudDistro -- test "$(readlink /usr/bin/wslpath)" = /init
wsl -d CloudDistro -- wslpath -w /tmp
wsl -d CloudDistro -- cmd.exe /c ver
```
Expected: `1000`, a `wslpath` Windows UNC path, and a Windows version string. `wslpath` is a WSL multi-call entrypoint and must be `/usr/bin/wslpath -> /init`; add that symlink in the Dockerfile if the base image does not contain it.

## Troubleshooting

| symptom | cause | fix |
|---|---|---|
| starts as root | OOBE did not run or returned nonzero | inspect the OOBE command, terminate the partially installed distro, and reinstall; do not set a root default |
| DNS stops working | custom resolver conflicts with WSL generation | retain `generateResolvConf=true`, or set false and manage `/etc/resolv.conf` deliberately |
| no shortcut/profile | older WSL or missing `.ico`/JSON | require 2.4.4+, check 0644 permissions and paths |

## Commit

```bash
git add rootfs/etc && git commit -m 'feat: configure WSL systemd and first-run user'
```

# Day 13: Upgrade, rollback and backup

## Objective and Definition of Done

Provide ordinary Debian patching and recoverable user-data workflows. Done means an engineer can back up, update, and revert a WSL instance.

## Steps

1. **[Windows PowerShell]** Back up before an update.
   ```powershell
   wsl --shutdown
   wsl --export CloudDistro-release $HOME\CloudDistro-release-backup.tar
   ```
2. **[Linux Host]** In the distro, use Debian’s normal update path:
   ```bash
   sudo apt update && sudo apt upgrade
   sudo apt autoremove --purge
   ```
3. **[Windows PowerShell]** Roll back by importing under a new name (do not destroy the failed instance first):
   ```powershell
   New-Item -ItemType Directory -Force C:\WSL\CloudDistro-rollback | Out-Null
   wsl --import CloudDistro-rollback C:\WSL\CloudDistro-rollback $HOME\CloudDistro-release-backup.tar --version 2
   ```

## Config files

Tool releases remain immutable in `/usr/local/bin`; update them by releasing a new signed CloudDistro image, not by replacing individual binaries outside the lock process.

There are two supported update planes: `apt upgrade` patches Debian packages in place; a base-image/toolchain update is a new, signed, versioned `.wsl` release. Export user data first, install the new release under a new name with `wsl --install --from-file`, migrate only reviewed user data, smoke-test it, then unregister the old distro only after the backup is verified.

## Verify

```bash
sudo apt-get -s upgrade
```
Expected: an ordinary package simulation with no third-party credentials required.

## Troubleshooting

| symptom | cause | fix |
|---|---|---|
| disk expands after export | WSL VHDX does not compact automatically | export/import to compact or use supported VHDX compaction procedure |
| rollback user missing | archive predates OOBE data | choose the right backup; retain regular exports |

## Commit

```bash
git commit --allow-empty -m 'docs: add update rollback and backup operations'
```

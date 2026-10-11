# Day 11: Tests

## Objective and Definition of Done

Add repeatable static archive checks and a manual WSL smoke test. Done means CI checks a generated tarball and the imported distro is `running` with zero failed units.

## Steps

1. **[Docker Build]**
   ```bash
   tar -tzf dist/clouddistro-dev.tar.gz | rg '^(etc/wsl.conf|etc/os-release|usr/local/bin/(kubectl|helm|terraform|argocd|trivy|docker|yq))$'
   ```
2. **[Windows PowerShell]**
   ```powershell
   wsl -d CloudDistro -- bash -lc 'id; systemctl is-system-running; test -z "$(systemctl --failed --no-legend)"; git --version; kubectl version --client; sudo -v; wslpath -w /tmp; cmd.exe /c ver'
   wsl -d CloudDistro -- bash -lc 'test -d /usr/lib/wsl/lib && ls /usr/lib/wsl/lib || true'
   wsl -d CloudDistro -- bash -lc 'command -v xeyes >/dev/null && xeyes || echo "WSLg test skipped: xeyes is not installed"'
   ```
   `xeyes` is an optional smoke test: install Debian package `x11-apps` only in a test build or run `gedit` if your selected image includes it. WSLg and GPU host integration are optional capabilities; a missing `/usr/lib/wsl/lib`, missing GUI client, headless Windows host, or no supported GPU must not block this headless DevOps distro release.

## Config files

The complete CI workflow is created on Day 14. It tests tar layout on GitHub-hosted Linux. The import/systemd test requires a maintained Windows WSL runner and remains an explicit release smoke test unless such a runner is provisioned.

## Verify

Expected: tar paths match, `running`, command versions print, `wslpath`/`cmd.exe` work, and sudo prompts for the OOBE password. If available, `/usr/lib/wsl/lib` lists WSL GPU/GUI libraries and `xeyes` opens on the Windows desktop.

## Troubleshooting

| symptom | cause | fix |
|---|---|---|
| workflow cannot execute systemd | hosted Linux job is not WSL | run the documented Windows smoke test or use a self-hosted Windows runner |
| archive misses a binary | tools stage/copy error | inspect Dockerfile build log and rebuild |
| WSLg/GPU check fails | unsupported host or optional packages absent | record it as optional; update WSL/GPU driver only if GUI/GPU work is required |

## Commit

```bash
git commit --allow-empty -m 'test: add rootfs smoke checklist'
```

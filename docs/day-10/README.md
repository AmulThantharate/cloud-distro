# Day 10: Size and boot

## Objective and Definition of Done

Keep runtime layers clean and quantify boot health. Done means no apt indexes/docs/man pages remain (if size policy permits) and boot reaches `running`.

## Steps

1. **[Docker Build]**
   ```bash
   docker image inspect clouddistro:dev --format '{{.Size}}'
   ```
2. **[Windows PowerShell]**
   ```powershell
   wsl -d CloudDistro-dev -- systemd-analyze
   wsl -d CloudDistro-dev -- systemd-analyze blame
   ```

## Config files

The Dockerfile uses a `tools` stage and copies only `/usr/local/bin`; apt lists/caches and optional docs/man pages are removed in the final image. Do not delete CA certificates, locales, or timezone data for a superficial size target.

## Verify

```bash
docker run --rm clouddistro:dev bash -c 'test -z "$(find /var/lib/apt/lists -type f -print -quit)"; systemctl is-enabled systemd-networkd-wait-online.service'
```
Expected: first check succeeds; final output `masked`.

## Troubleshooting

| symptom | cause | fix |
|---|---|---|
| slow boot | waiting unit enabled | inspect blame; keep the documented wait-online mask |
| certificates fail | over-aggressive pruning | restore `ca-certificates` |

## Commit

```bash
git commit --allow-empty -m 'perf: document image size and boot budget'
```

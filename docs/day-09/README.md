# Day 9: Security, scan and SBOM

## Objective and Definition of Done

Apply a small CIS-style baseline and produce failing vulnerability gates plus an SBOM. Done means Trivy exits zero only with no HIGH/CRITICAL findings under the agreed policy.

## Steps

1. **[Linux Host / Vagrant]**
   Scan the exported rootfs archive directly using Trivy and Syft:
   ```bash
   trivy rootfs --exit-code 1 --severity HIGH,CRITICAL dist/clouddistro-v0.1.0.tar.gz
   syft dist/clouddistro-v0.1.0.tar.gz -o spdx-json > dist/sbom.spdx.json
   ```
2. **[Hardening]** Keep only required packages, passworded sudo, `use_pty`, unattended security upgrades, no SSH daemon, and no setuid additions beyond Debian defaults.

## Config files

No secrets or scanner database is retained in the rootfs. Treat an exception as a time-bounded, reviewed vulnerability waiver outside the image.

## Verify

```bash
test -s dist/sbom.spdx.json && jq -e '.spdxVersion' dist/sbom.spdx.json
```
Expected: an SPDX version string.

## Troubleshooting

| symptom | cause | fix |
|---|---|---|
| scan suddenly fails | new CVE database | patch/rebuild; do not lower severity gate |
| SBOM empty | wrong image reference | use the locally loaded tag |

## Commit

```bash
git commit --allow-empty -m 'security: add scan gate and SBOM generation'
```

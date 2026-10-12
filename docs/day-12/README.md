# Day 12: Package and sign

## Objective and Definition of Done

Create a deterministic gzip archive, checksum, SBOM and signature. Done means a clean verifier validates all artifacts before import.

## Steps

1. **[Vagrant / Native Build]**
   ```bash
   VERSION="$(git describe --tags --always --dirty 2>/dev/null || echo v0.1.0)"
   DIST_VERSION="${VERSION}" sudo -E ./build.sh
   cosign sign-blob --yes --output-signature "dist/clouddistro-${VERSION}.tar.gz.sig" "dist/clouddistro-${VERSION}.tar.gz"
   ```
2. **[Windows PowerShell]**
   ```powershell
   wsl --import CloudDistro-release C:\WSL\CloudDistro-release $HOME\Downloads\clouddistro-v0.1.0.wsl --version 2
   ```
`.wsl` here is a compatible renamed tarball; use `.tar.gz` where a tool expects gzip explicitly.

## Config files

Cosign keyless signing uses the identity shown in its certificate. For offline releases, use GPG and publish the fingerprint through a separately authenticated channel.

## Verify

```bash
sha256sum -c dist/clouddistro-*.sha256
cosign verify-blob --signature dist/clouddistro-*.tar.gz.sig --certificate-identity-regexp 'https://github.com/ORG/cloud-distro/.*' --certificate-oidc-issuer https://token.actions.githubusercontent.com dist/clouddistro-*.tar.gz
```
Expected: all `OK` and cosign verification succeeds.

## Troubleshooting

| symptom | cause | fix |
|---|---|---|
| signature identity mismatch | wrong repository/tag workflow | verify expected identity, never bypass it |
| import fails | file copied incompletely | rerun SHA-256 verification before import |

## Commit

```bash
git commit --allow-empty -m 'release: package checksums SBOM and signatures'
```

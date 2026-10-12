# Day 14: Release

## Objective and Definition of Done

Publish signed rootfs assets from a protected `v*.*.*` tag. Done means the GitHub release contains `.tar.gz`, `.wsl`, checksums, SBOM and signature, and a fresh Windows machine verifies then imports it.

## Steps

1. **[Linux Host]** Replace the `ORG/cloud-distro` badge and signing identity in repository documentation with the actual GitHub owner/repository. Protect tags and require review of `.release/*.env` changes.
2. **[Linux Host]** Create the workflow below. It deliberately does not release if the version/checksum lock has an unresolved value.
3. **[Linux Host]**
   ```bash
   git add . && git commit -m 'ci: build scan sign and release CloudDistro'
   git tag -a v0.1.0 -m 'CloudDistro v0.1.0'
   git push origin main v0.1.0
   ```

## Config files

1. **[Linux Host]**
   ```bash
   cat << 'EOF' > .github/workflows/release.yml
name: build-test-release

on:
  pull_request:
  push:
    branches: [main]
    tags: ['v*.*.*']

permissions:
  contents: write
  id-token: write

jobs:
  build_package:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4

      - name: Build CloudDistro WSL2 rootfs via Native Debootstrap
        shell: bash
        run: |
          set -euo pipefail
          chmod +x build.sh rootfs/usr/libexec/cloud-distro-oobe
          DIST_VERSION="${GITHUB_REF_NAME:-v0.1.0}" sudo -E ./build.sh

      - name: Verify package contents
        shell: bash
        run: |
          DIST_VERSION="${GITHUB_REF_NAME:-v0.1.0}"
          tar -tzf "dist/clouddistro-${DIST_VERSION}.tar.gz" | grep -E '^etc/wsl.conf$'
          tar -tzf "dist/clouddistro-${DIST_VERSION}.tar.gz" | grep -E '^etc/godzilla.art$'
          tar -tzf "dist/clouddistro-${DIST_VERSION}.tar.gz" | grep -E '^usr/libexec/cloud-distro-oobe$'

      - uses: actions/upload-artifact@v4
        with:
          name: clouddistro-${{ github.ref_name }}
          path: dist/

  release:
    if: startsWith(github.ref, 'refs/tags/v')
    needs: build_test_scan_package
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: clouddistro-${{ github.ref_name }}
          path: dist
      - uses: sigstore/cosign-installer@v3
      - name: Keyless sign archive and checksums
        run: |
          cosign sign-blob --yes --output-signature dist/clouddistro-${GITHUB_REF_NAME}.tar.gz.sig dist/clouddistro-${GITHUB_REF_NAME}.tar.gz
          cosign sign-blob --yes --output-signature dist/clouddistro-${GITHUB_REF_NAME}.sha256.sig dist/clouddistro-${GITHUB_REF_NAME}.sha256
      - uses: softprops/action-gh-release@v2
        with:
          generate_release_notes: true
          files: dist/*
EOF
   ```

The action versions and container tags above are version pins, but tags can be retargeted. Before production, replace every third-party action/container reference with its upstream-published commit or manifest digest and commit that exact value; verify it at each publisher’s official release page. This requirement applies equally to `hadolint`, Trivy, and Syft.

## Verify

```bash
gh release view v0.1.0 --repo ORG/cloud-distro
```
Expected: archive, `.wsl`, `.sha256`, `sbom.spdx.json`, and two `.sig` files.

## Troubleshooting

| symptom | cause | fix |
|---|---|---|
| release job lacks OIDC token | permissions/enterprise policy | allow `id-token: write` for the repository |
| release assets absent | preceding artifact job failed | repair the failed gate; do not manually upload unsigned replacements |
| tag did not trigger | tag pattern mismatch | use exactly `vMAJOR.MINOR.PATCH` |

## Commit

```bash
git commit --allow-empty -m 'docs: publish release runbook and known limitations'
```

## Release checklist

- Confirm Debian stable and re-resolve the amd64 base digest; review the diff.
- Verify every lock version, checksum or signature at its official source.
- Run lint, build, tar inspection, Trivy and SBOM locally once.
- Validate the signed artifacts on a second machine before `wsl --import`.
- Perform the Day 11 Windows systemd smoke test for the tag.

## Publishing appendix

### GitHub release sideload

1. Publish the versioned `.wsl`, `.tar.gz`, `.sha256`, SBOM, and cosign signatures as immutable GitHub Release assets.
2. The user downloads all assets, checks `Get-FileHash` against the published SHA-256, verifies the cosign signature, then runs:
   ```powershell
   wsl --install --from-file $HOME\Downloads\clouddistro-v0.1.0.wsl --name CloudDistro
   ```
3. Document `wsl --import` from the `.tar.gz` only as the fallback path in Day 4. Never tell users to bypass signature/checksum verification.

### WinGet submission

WinGet distribution is a GitHub-manifest submission, not a Microsoft Store submission; the Microsoft Store is explicitly out of scope for CloudDistro. Follow the current [winget-pkgs manifest instructions](https://github.com/microsoft/winget-pkgs/blob/master/.github/instructions/manifests.instructions.md) and [validation guide](https://github.com/microsoft/winget-pkgs/blob/master/doc/ValidationFailureGuide.md).

1. Fork <https://github.com/microsoft/winget-pkgs>, create the required multi-file manifest beneath `manifests/c/CloudDistro/CloudDistro/<version>/`, and use a public, version-specific GitHub Release `.wsl` URL.
2. Set the installer URL and its exact SHA-256, generated from the downloaded release asset:
   ```powershell
   winget hash $HOME\Downloads\clouddistro-v0.1.0.wsl
   ```
   Use the current WinGet schema and installer type validated by `winget validate`; do not guess archive support or use a mutable “latest” URL.
3. Test locally with `winget install --manifest <manifest-path>`, then submit the pull request. The community repository verifies the artifact SHA-256, availability, and policy compliance.
4. If the current WinGet schema cannot install a `.wsl` directly, do not disguise it as another installer type. Keep GitHub-release sideload as the supported route until WinGet supports this artifact type or publish a reviewed native bootstrapper.

## Known issues

GitHub-hosted Linux runners cannot prove WSL systemd behavior. The workflow therefore has a static archive test; a Windows WSL smoke test is a release gate. OOBE depends on the WSL distribution configuration capability available in the target WSL version—verify it with the exact WSL package deployed by your organization before release.

## License

MIT; include a standard `LICENSE` file before publishing.

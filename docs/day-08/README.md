# Day 8: Cloud CLIs and credentials

## Objective and Definition of Done

Add AWS CLI v2 and Azure CLI as reviewed, version-locked artifacts, with no credentials in any layer. Done means both `--version` commands match the lock and `docker history` exposes no token/key.

## Steps

1. **[Linux Host]** Get AWS v2 from <https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>; verify its official signature or published checksum. For Azure use Microsoft’s signed Debian repository instructions at <https://learn.microsoft.com/cli/azure/install-azure-cli-linux>. Record exact package versions and repository signing-key fingerprint in `.release/cloud-cli.lock`; do not use `latest`.
2. **[Vagrant / Native Build]** Add the verified AWS installer and Azure signed repository installation directly to `build.sh` or rootfs. The Azure repository key must be installed as a dearmored keyring with `signed-by=`, and `apt-get install azure-cli=<reviewed-version>` followed by `apt-mark hold azure-cli`.
3. **[Windows PowerShell]** Authenticate only after import:
   ```powershell
   wsl -d CloudDistro-dev -- aws configure sso
   wsl -d CloudDistro-dev -- az login
   ```

## Config files

Do not add `~/.aws`, `~/.azure`, environment credentials, service principals, or build secrets to `rootfs/` or Git.

## Verify

```bash
aws --version; az version
```
Expected: pinned client versions and no credential-like history text.

## Troubleshooting

| symptom | cause | fix |
|---|---|---|
| `az login` browser cannot open | WSL interop disabled | enable interop or use `az login --use-device-code` |
| AWS credentials disappear | HOME changed or profile omitted | use the OOBE account and `aws configure sso` |

## Commit

```bash
git add .release && git commit -m 'feat: add pinned cloud CLIs without credentials'
```

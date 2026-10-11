# Day 1: Host and immutable base

## Objective and Definition of Done

Create a non-root repository and commit an amd64-only Debian stable digest lock. Done means `BASE_IMAGE` includes `@sha256:` and `docker buildx inspect` lists `linux/amd64`.

## Steps

1. **[Linux Host]**
   ```bash
   mkdir -p ~/cloud-distro/{docs,.release,rootfs/etc/sudoers.d,.github/workflows,dist} && cd ~/cloud-distro && git init
   sudo apt-get update && sudo apt-get install -y docker.io docker-buildx-plugin git curl jq gnupg
   sudo usermod -aG docker "$USER"
   ```
   Sign out/in before continuing.
2. **[Linux Host]** Verify Debian's release page and resolve the *platform-specific* Docker Hub digest, then write and inspect the immutable lock.
   ```bash
   test "$(dpkg --print-architecture)" = amd64
   export BASE_DIGEST="$(docker buildx imagetools inspect debian:trixie-slim --raw | jq -r '.manifests[] | select(.platform.os=="linux" and .platform.architecture=="amd64") | .digest')"
   test "$BASE_DIGEST" != null && printf 'BASE_IMAGE=debian:trixie-slim@%s\n' "$BASE_DIGEST" | tee .release/base.env
   cat .release/base.env
   docker buildx create --name clouddistro --use --bootstrap || docker buildx use clouddistro
   ```
   Verify the release at <https://www.debian.org/releases/> and tag/digest in Docker Hub's official Debian image page before committing.

## Config files

1. **[Linux Host]**
   ```bash
   cat << 'EOF' > .dockerignore
.git
.github
dist
.release/*.key
.release/*.pem
*.wsl
*.tar.gz
*.sig
*.sbom.json
EOF
   ```

## Verify

```bash
source .release/base.env; [[ "$BASE_IMAGE" =~ ^debian:trixie-slim@sha256:[0-9a-f]{64}$ ]] && docker buildx inspect --bootstrap
```
Expected: a 64-hex digest and `linux/amd64` in supported platforms.

## Troubleshooting

| symptom | cause | fix |
|---|---|---|
| permission denied on Docker socket | group not refreshed | sign out/in, then `id -nG` |
| digest is `null` | proxy/Hub response | authenticate with `docker login` and retry |

## Commit

```bash
git add . && git commit -m 'chore: initialize CloudDistro build and base lock'
```

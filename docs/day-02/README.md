# Day 2: Hardened Debian layer

## Objective and Definition of Done

Build a digest-pinned Debian system layer with locale, time zone, CA trust, and no retained apt indexes. Done means the image labels show the base digest and `/var/lib/apt/lists` is empty.

## Steps

1. **[Docker Build]** Create the final Dockerfile from Day 6 below, then build only the base target while using the immutable lock.
   ```bash
   source .release/base.env
   docker buildx build --platform linux/amd64 --load --build-arg BASE_IMAGE="$BASE_IMAGE" --target base -t clouddistro:base .
   docker run --rm clouddistro:base sh -c 'locale -a | grep -Fx C.UTF-8; test ! -e /var/lib/apt/lists/*'
   ```

## Config files

The complete `Dockerfile` is published in [Day 6](../day-06/README.md#complete-dockerfile), after all layers are introduced. It has no unpinned `FROM`.

## Verify

```bash
docker image inspect clouddistro:base --format '{{.Os}}/{{.Architecture}}'
```
Expected: `linux/amd64`.

## Troubleshooting

| symptom | cause | fix |
|---|---|---|
| apt signature error | stale clock/CA bundle | correct host time; rebuild |
| build pulls tag | missing build argument | source `.release/base.env` and pass `BASE_IMAGE` |

## Commit

```bash
git add Dockerfile .dockerignore && git commit -m 'build: add hardened Debian base'
```

# Day 6: Verified DevOps CLIs

## Objective and Definition of Done

Install pinned `git curl jq yq vim tmux make python3 pipx kubectl helm terraform argocd docker trivy` without accepting an unchecked binary. Done means every downloaded artifact has a recorded version, official URL and SHA-256 in the Git tag, and each CLI prints its pinned version.

## Steps

1. **[Linux Host]** Choose releases only from these official publishers and record the release asset SHA-256 before build: Kubernetes (<https://dl.k8s.io/release/>), Helm (<https://get.helm.sh/>), HashiCorp (<https://releases.hashicorp.com/terraform/>), Argo CD (<https://github.com/argoproj/argo-cd/releases>), Docker (<https://download.docker.com/linux/static/stable/x86_64/>), Trivy (<https://github.com/aquasecurity/trivy/releases>). `yq` is from <https://github.com/mikefarah/yq/releases>. Verify each release checksum/signature on that publisher page; do not copy a hash from a blog.
2. **[Linux Host]** Create an immutable tool lock from the selected official values. This example deliberately fails until you replace every `VERIFY_AT_OFFICIAL_SOURCE` value; that is safer than inventing a checksum. Do not build or commit a release with any such value.
   ```bash
   cat << 'EOF' > .release/toolchain.env
KUBECTL_VERSION=VERIFY_AT_OFFICIAL_SOURCE
KUBECTL_SHA256=VERIFY_AT_OFFICIAL_SOURCE
HELM_VERSION=VERIFY_AT_OFFICIAL_SOURCE
HELM_SHA256=VERIFY_AT_OFFICIAL_SOURCE
TERRAFORM_VERSION=VERIFY_AT_OFFICIAL_SOURCE
TERRAFORM_SHA256=VERIFY_AT_OFFICIAL_SOURCE
ARGOCD_VERSION=VERIFY_AT_OFFICIAL_SOURCE
ARGOCD_SHA256=VERIFY_AT_OFFICIAL_SOURCE
TRIVY_VERSION=VERIFY_AT_OFFICIAL_SOURCE
TRIVY_SHA256=VERIFY_AT_OFFICIAL_SOURCE
YQ_VERSION=VERIFY_AT_OFFICIAL_SOURCE
YQ_SHA256=VERIFY_AT_OFFICIAL_SOURCE
DOCKER_CLI_VERSION=VERIFY_AT_OFFICIAL_SOURCE
DOCKER_CLI_SHA256=VERIFY_AT_OFFICIAL_SOURCE
EOF
   grep -q VERIFY_AT_OFFICIAL_SOURCE .release/toolchain.env && echo 'populate and independently review this lock first'
   ```
3. **[Docker Build]** Once all lock values are reviewed, build with them as literal build arguments. A shell environment file is never copied into the image.
   ```bash
   source .release/base.env; source .release/toolchain.env
   ! grep -q VERIFY_AT_OFFICIAL_SOURCE .release/toolchain.env
   docker buildx build --platform linux/amd64 --load --build-arg BASE_IMAGE="$BASE_IMAGE" $(sed 's/^/--build-arg /' .release/toolchain.env) -t clouddistro:dev .
   ```

## Config files

### Complete Dockerfile

1. **[Linux Host]**
   ```bash
   cat << 'EOF' > Dockerfile
# syntax=docker/dockerfile:1.7
ARG BASE_IMAGE
FROM --platform=linux/amd64 ${BASE_IMAGE} AS base
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8 TZ=Etc/UTC
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash-completion ca-certificates curl dbus git iproute2 iputils-ping jq locales \
    make openssh-client python3 python3-pip pipx sudo systemd systemd-sysv tzdata \
    unattended-upgrades vim-tiny tmux xz-utils gzip gpg unzip zsh && \
    sed -i 's/^# *C.UTF-8 UTF-8/C.UTF-8 UTF-8/' /etc/locale.gen && locale-gen && \
    systemctl mask getty@.service systemd-networkd-wait-online.service && \
    truncate -s 0 /etc/machine-id && ln -sf /etc/machine-id /var/lib/dbus/machine-id && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/* /usr/share/doc/* /usr/share/man/*

FROM base AS tools
ARG KUBECTL_VERSION KUBECTL_SHA256 HELM_VERSION HELM_SHA256 TERRAFORM_VERSION TERRAFORM_SHA256
ARG ARGOCD_VERSION ARGOCD_SHA256 TRIVY_VERSION TRIVY_SHA256 YQ_VERSION YQ_SHA256 DOCKER_CLI_VERSION DOCKER_CLI_SHA256
RUN for x in "$KUBECTL_VERSION" "$KUBECTL_SHA256" "$HELM_VERSION" "$HELM_SHA256" "$TERRAFORM_VERSION" "$TERRAFORM_SHA256" "$ARGOCD_VERSION" "$ARGOCD_SHA256" "$TRIVY_VERSION" "$TRIVY_SHA256" "$YQ_VERSION" "$YQ_SHA256" "$DOCKER_CLI_VERSION" "$DOCKER_CLI_SHA256"; do [[ "$x" != VERIFY_AT_OFFICIAL_SOURCE && -n "$x" ]] || exit 64; done && \
    curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && echo "${KUBECTL_SHA256}  /tmp/kubectl" | sha256sum -c - && install -m 0755 /tmp/kubectl /usr/local/bin/kubectl && \
    curl -fsSLo /tmp/helm.tgz "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" && echo "${HELM_SHA256}  /tmp/helm.tgz" | sha256sum -c - && tar -C /tmp -xzf /tmp/helm.tgz && install -m 0755 /tmp/linux-amd64/helm /usr/local/bin/helm && \
    curl -fsSLo /tmp/terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && echo "${TERRAFORM_SHA256}  /tmp/terraform.zip" | sha256sum -c - && unzip -q /tmp/terraform.zip -d /usr/local/bin && \
    curl -fsSLo /tmp/argocd "https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-amd64" && echo "${ARGOCD_SHA256}  /tmp/argocd" | sha256sum -c - && install -m 0755 /tmp/argocd /usr/local/bin/argocd && \
    curl -fsSLo /tmp/trivy.tgz "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" && echo "${TRIVY_SHA256}  /tmp/trivy.tgz" | sha256sum -c - && tar -C /usr/local/bin -xzf /tmp/trivy.tgz trivy && \
    curl -fsSLo /tmp/yq "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64" && echo "${YQ_SHA256}  /tmp/yq" | sha256sum -c - && install -m 0755 /tmp/yq /usr/local/bin/yq && \
    curl -fsSLo /tmp/docker.tgz "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_CLI_VERSION}.tgz" && echo "${DOCKER_CLI_SHA256}  /tmp/docker.tgz" | sha256sum -c - && tar -C /tmp -xzf /tmp/docker.tgz && install -m 0755 /tmp/docker/docker /usr/local/bin/docker

FROM base
COPY --from=tools /usr/local/bin/ /usr/local/bin/
COPY rootfs/ /
RUN chmod 0440 /etc/sudoers.d/cloud-distro && visudo -cf /etc/sudoers.d/cloud-distro && \
    if [ ! -e /usr/bin/wslpath ]; then ln -s /init /usr/bin/wslpath; fi && \
    chmod 0644 /etc/wsl.conf /etc/wsl-distribution.conf /usr/lib/wsl/terminal-profile.json && chmod 0755 /usr/libexec/cloud-distro-oobe && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/cache/apt/*
CMD ["/sbin/init"]
EOF
   ```
## Verify

```bash
docker run --rm --entrypoint bash clouddistro:dev -c 'kubectl version --client; helm version; terraform version; argocd version --client; trivy --version; docker --version; yq --version'
```
Expected: every version matches `.release/toolchain.env`.

## Troubleshooting

| symptom | cause | fix |
|---|---|---|
| checksum mismatch | upstream asset/version mismatch | stop; reread official checksums; update both version and hash in a reviewed commit |
| `unzip: command not found` | missing base package | add `unzip`, rebuild |
| `exec format error` | wrong platform asset | retain `linux/amd64` and `--platform linux/amd64` |

## Commit

```bash
git add Dockerfile .release/toolchain.env && git commit -m 'feat: add verified DevOps toolchain'
```

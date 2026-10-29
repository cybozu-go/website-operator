ARG NODE_VERSION=24.22.2
ARG PNPM_VERSION=v11.28.9
ARG BASE_TAG=24.04

FROM scratch AS node-amd64
ARG NODE_VERSION
ADD --checksum=sha256:361718c444e49af2ca5a110c83ba6a8901143f23ab285ebbef0341f391f482a9 \
    https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz /node.tar.gz

FROM scratch AS node-arm64
ARG NODE_VERSION
ADD --checksum=sha256:95c264150aceb7f3437a29fd6984924f5f8d1511ea3cbd6c508b83f6c555dae2 \
    https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-arm64.tar.gz /node.tar.gz

FROM scratch AS pnpm-amd64
ARG PNPM_VERSION
ADD --checksum=sha256:44588952c6e0e2c25f5b3363c5736d7a176ce8dc6200ae8179bd688e60a212a7 \
    https://github.com/pnpm/pnpm/releases/download/${PNPM_VERSION}/pnpm-linux-x64.tar.gz /pnpm.tar.gz

FROM scratch AS pnpm-arm64
ARG PNPM_VERSION
ADD --checksum=sha256:2da5106f94a6b34b8ed59c8a9b8223c0f32621f4494b4d7644b672b8aac1ba4f \
    https://github.com/pnpm/pnpm/releases/download/${PNPM_VERSION}/pnpm-linux-arm64.tar.gz /pnpm.tar.gz

# Select the right download stage based on the target architecture
FROM node-${TARGETARCH} AS node-download
FROM pnpm-${TARGETARCH} AS pnpm-download

FROM ghcr.io/cybozu/ubuntu:${BASE_TAG} AS builder

LABEL org.opencontainers.image.source=https://github.com/cybozu-go/website-operator

USER root

RUN --mount=type=bind,from=node-download,source=/node.tar.gz,target=/tmp/node.tar.gz \
    mkdir -p /opt/node \
 && tar xf /tmp/node.tar.gz -C /opt/node --strip-components=1
ENV PATH="/opt/node/bin:${PATH}"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update \
 && apt-get install --no-install-recommends -y \
        # necessary for cloning repository
        git \
        openssh-client \
        # necessary for plantuml
        default-jre \
        graphviz \
        jq \
        # necessary for pnpm
        libatomic1 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME/bin:$PATH"

RUN --mount=type=bind,from=pnpm-download,source=/pnpm.tar.gz,target=/tmp/pnpm.tar.gz \
    mkdir -p /opt/pnpm \
 && tar xf /tmp/pnpm.tar.gz -C /opt/pnpm \
 && ln -sf /opt/pnpm/pnpm /usr/local/bin/pnpm \
 && mkdir -p "$PNPM_HOME" \
 && pnpm config set -g minimumReleaseAge 1440 \
 && chown -R 1000:1000 "$PNPM_HOME"

USER 1000:1000

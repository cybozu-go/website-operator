ARG NODE_VERSION=24.22.3
ARG PNPM_VERSION=v11.28.11
ARG BASE_TAG=24.04

FROM scratch AS node-amd64
ARG NODE_VERSION
ADD --checksum=sha256:061ec3e3062115705b56b51fa9cc330ab50d34b6969387d4e4b1a50c6809acc2 \
    https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz /node.tar.gz

FROM scratch AS node-arm64
ARG NODE_VERSION
ADD --checksum=sha256:261af2af250dfd7e9f25cf151d1b2713a0adf8f10a9ad116c4947f68627affe8 \
    https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-arm64.tar.gz /node.tar.gz

FROM scratch AS pnpm-amd64
ARG PNPM_VERSION
ADD --checksum=sha256:245b9ad9dd85b2ce876d62adf93fd2b227bd3c230deeb8a54b4d6a08f5a2d136 \
    https://github.com/pnpm/pnpm/releases/download/${PNPM_VERSION}/pnpm-linux-x64.tar.gz /pnpm.tar.gz

FROM scratch AS pnpm-arm64
ARG PNPM_VERSION
ADD --checksum=sha256:9c60e840e5e61f90a24adbe686a097237bcb31a68a5a78bf52cf904105fcc078 \
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

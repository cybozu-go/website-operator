ARG NODE_VERSION=24.16.0
ARG PNPM_VERSION=v10.34.1
ARG BASE_TAG=24.04

FROM scratch AS node-amd64
ARG NODE_VERSION
ADD --checksum=sha256:2faf6a387e9b62b888e21c54f01249fb27537ffecf1842f29f4c919d0a59a0ff \
    https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz /node.tar.gz

FROM scratch AS node-arm64
ARG NODE_VERSION
ADD --checksum=sha256:589f5b6dd4fcfee4dfda73013903c966abaa8abd93dbc9d436544e472b4f0e74 \
    https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-arm64.tar.gz /node.tar.gz

FROM scratch AS pnpm-amd64
ARG PNPM_VERSION
ADD --checksum=sha256:25dec6207e51ea4c8335dc1d8b203c9274f0bdcf630b998e0df46060dde65dba \
    https://github.com/pnpm/pnpm/releases/download/${PNPM_VERSION}/pnpm-linux-x64 /pnpm

FROM scratch AS pnpm-arm64
ARG PNPM_VERSION
ADD --checksum=sha256:a91a72e6ac0f30e5354af9a1c15eff1a9448b5471f572f3109863da928e5699f \
    https://github.com/pnpm/pnpm/releases/download/${PNPM_VERSION}/pnpm-linux-arm64 /pnpm

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
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN --mount=type=bind,from=pnpm-download,source=/pnpm,target=/tmp/pnpm \
    install -m 0755 /tmp/pnpm /usr/local/bin/pnpm \
 && pnpm config set -g minimumReleaseAge 1440

USER 1000:1000

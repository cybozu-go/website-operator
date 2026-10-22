ARG NODE_VERSION=24.22.1
ARG PNPM_VERSION=v11.25.0
ARG BASE_TAG=24.04

FROM scratch AS node-amd64
ARG NODE_VERSION
ADD --checksum=sha256:eb6728e77c576a35162c122c45ccadf224d89ff00abc8dae46cc2897c6002d7c \
    https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz /node.tar.gz

FROM scratch AS node-arm64
ARG NODE_VERSION
ADD --checksum=sha256:33c37be234ba8bee041961047b19160f4d7d0f164e8e246f78bdd10feff148b3 \
    https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-arm64.tar.gz /node.tar.gz

FROM scratch AS pnpm-amd64
ARG PNPM_VERSION
ADD --checksum=sha256:11caeed8b581d460638f836f10f6ead19cbf08d774a5b8e502628b20ebf3ac43 \
    https://github.com/pnpm/pnpm/releases/download/${PNPM_VERSION}/pnpm-linux-x64.tar.gz /pnpm.tar.gz

FROM scratch AS pnpm-arm64
ARG PNPM_VERSION
ADD --checksum=sha256:6d62b433b7a77b77e814dfaca8032bae57bb79c1a5ad50442e688c4f7fed3c8a \
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
 && pnpm config set -g minimumReleaseAge 1440 \
 && chown -R 1000:1000 "$PNPM_HOME"

USER 1000:1000

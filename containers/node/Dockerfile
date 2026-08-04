ARG NODE_VERSION=24.18.1
ARG PNPM_VERSION=v10.34.5
ARG BASE_TAG=24.04

FROM scratch AS node-amd64
ARG NODE_VERSION
ADD --checksum=sha256:9f5eb6ac21845a66c493c91a253b1da32fd684e89e9b7202d4936982336be4ca \
    https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz /node.tar.gz

FROM scratch AS node-arm64
ARG NODE_VERSION
ADD --checksum=sha256:df224555a083b918e46260cc969838501b9f9a87140c1195e5b9597b56d5dae2 \
    https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-arm64.tar.gz /node.tar.gz

FROM scratch AS pnpm-amd64
ARG PNPM_VERSION
ADD --checksum=sha256:69a535476f407fb0f64427913c2b592ca2ed6bf93f92e2cb82a32349e31f36eb \
    https://github.com/pnpm/pnpm/releases/download/${PNPM_VERSION}/pnpm-linux-x64 /pnpm

FROM scratch AS pnpm-arm64
ARG PNPM_VERSION
ADD --checksum=sha256:22391362c31edf522fd698d0b43d38fe9228e28d5b5e32124ffd0038fb60f9f0 \
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
        jq \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN --mount=type=bind,from=pnpm-download,source=/pnpm,target=/tmp/pnpm \
    install -m 0755 /tmp/pnpm /usr/local/bin/pnpm \
 && pnpm config set -g minimumReleaseAge 1440

USER 1000:1000

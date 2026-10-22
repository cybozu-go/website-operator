FROM ghcr.io/cybozu/ubuntu:24.04.20261021@sha256:7bc89f8e6e4dfe609ca671526e3bbee91753422b8a766d90cef4de8b7c73a3b9 AS base

LABEL org.opencontainers.image.source=https://github.com/cybozu-go/website-operator

FROM base as website-operator
ARG TARGETPLATFORM
COPY $TARGETPLATFORM/website-operator /
USER 1000:1000
ENTRYPOINT ["/website-operator"]

FROM base as repo-checker
RUN apt-get update \
    && apt-get install -y --no-install-recommends git openssh-client \
    && rm -rf /var/lib/apt/lists/*
ARG TARGETPLATFORM
COPY $TARGETPLATFORM/repo-checker /
USER 1000:1000
ENTRYPOINT ["/repo-checker"]

FROM base as ui
COPY ui/frontend/dist /dist
ARG TARGETPLATFORM
COPY $TARGETPLATFORM/website-operator-ui /
USER 1000:1000
ENTRYPOINT ["/website-operator-ui"]

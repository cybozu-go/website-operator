FROM ghcr.io/cybozu/ubuntu:24.04 AS base

LABEL org.opencontainers.image.source=https://github.com/cybozu-go/website-operator

FROM base AS website-operator
ARG TARGETPLATFORM
COPY $TARGETPLATFORM/website-operator /
USER 1000:1000
ENTRYPOINT ["/website-operator"]

FROM base AS repo-checker
ARG TARGETPLATFORM
RUN apt-get update \
    && apt-get install -y --no-install-recommends git openssh-client \
    && rm -rf /var/lib/apt/lists/*
COPY $TARGETPLATFORM/repo-checker /
USER 1000:1000
ENTRYPOINT ["/repo-checker"]

FROM base AS ui
ARG TARGETPLATFORM
COPY ui/frontend/dist /dist
COPY $TARGETPLATFORM/website-operator-ui /
USER 1000:1000
ENTRYPOINT ["/website-operator-ui"]

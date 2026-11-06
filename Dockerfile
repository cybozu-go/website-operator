FROM ghcr.io/cybozu/ubuntu:24.04.20261105@sha256:d17e041d23ea4238026cc4fa1418681fd81ea0060b8b7e3ca063627d72912a2b AS base

LABEL org.opencontainers.image.source=https://github.com/cybozu-go/website-operator

FROM base AS website-operator
ARG TARGETPLATFORM
COPY $TARGETPLATFORM/website-operator /
USER 1000:1000
ENTRYPOINT ["/website-operator"]

FROM base AS repo-checker
RUN apt-get update \
    && apt-get install -y --no-install-recommends git openssh-client \
    && rm -rf /var/lib/apt/lists/*
ARG TARGETPLATFORM
COPY $TARGETPLATFORM/repo-checker /
USER 1000:1000
ENTRYPOINT ["/repo-checker"]

FROM base AS ui
COPY ui/frontend/dist /dist
ARG TARGETPLATFORM
COPY $TARGETPLATFORM/website-operator-ui /
USER 1000:1000
ENTRYPOINT ["/website-operator-ui"]

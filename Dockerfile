FROM ghcr.io/cybozu/ubuntu:24.04.20260902@sha256:182a16198fafecbce2f813a07de269d28efb885aa4843e611ce44c25ce46cc2b AS base

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

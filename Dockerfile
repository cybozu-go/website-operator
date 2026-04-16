FROM ghcr.io/cybozu/ubuntu:24.04 as base

LABEL org.opencontainers.image.source=https://github.com/cybozu-go/website-operator

FROM base as website-operator
COPY website-operator /
USER 10000:10000
ENTRYPOINT ["/website-operator"]

FROM base as repo-checker
RUN apt-get update \
    && apt-get install -y --no-install-recommends git openssh-client \
    && rm -rf /var/lib/apt/lists/*
COPY repo-checker /
USER 10000:10000
ENTRYPOINT ["/repo-checker"]

FROM base as ui
COPY ui/frontend/dist /dist
COPY website-operator-ui /
USER 10000:10000
ENTRYPOINT ["/website-operator-ui"]

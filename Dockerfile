FROM ghcr.io/zoetrope/ubuntu:22.04@sha256:399e56354efe531e98f618966249767814d0d4ee6260bb4cf4086a0b45531979 as base

LABEL org.opencontainers.image.source=https://github.com/zoetrope/website-operator

FROM base as website-operator
COPY website-operator /
USER 10000:10000
ENTRYPOINT ["/website-operator"]

FROM base as repo-checker
COPY repo-checker /
USER 10000:10000
ENTRYPOINT ["/repo-checker"]

FROM base as ui
COPY ui/frontend/dist /dist
COPY website-operator-ui /
USER 10000:10000
ENTRYPOINT ["/website-operator-ui"]

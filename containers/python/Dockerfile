ARG BASE_TAG=24.04
FROM ghcr.io/cybozu/ubuntu:${BASE_TAG}

LABEL org.opencontainers.image.source=https://github.com/cybozu-go/website-operator

USER root

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
     python3.12 \
     python3-pip \
     python3-venv \
     git \
     openssh-client \
     jq \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER 1000:1000

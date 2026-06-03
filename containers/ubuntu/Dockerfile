ARG BASE_TAG=24.04
FROM ghcr.io/cybozu/ubuntu:${BASE_TAG}

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
     git \
     openssh-client \
     jq \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

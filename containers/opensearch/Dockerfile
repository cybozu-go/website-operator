FROM opensearchproject/opensearch:2.19.7@sha256:3bfa1ec74d56928c2e018033d45c460ce2c0ea65a5cedd577de3102326c31b89

LABEL org.opencontainers.image.source=https://github.com/cybozu-go/website-operator

RUN opensearch-plugin install --batch analysis-kuromoji \
    && opensearch-plugin install --batch analysis-icu

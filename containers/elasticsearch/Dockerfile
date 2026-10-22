FROM docker.elastic.co/elasticsearch/elasticsearch:8.19.23@sha256:4d0724bb8d78d7a2330693623e26ca4d621079d062ecc8a30b3e1fc180ec14c1

LABEL org.opencontainers.image.source=https://github.com/cybozu-go/website-operator

RUN elasticsearch-plugin install analysis-kuromoji \
    && elasticsearch-plugin install analysis-icu

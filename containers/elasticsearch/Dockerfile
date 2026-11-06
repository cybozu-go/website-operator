FROM docker.elastic.co/elasticsearch/elasticsearch:8.19.24@sha256:d6dfe6626d645cfec66e91009aca60c6c1bb6f94d34253528f24d8cea2f94ba6

LABEL org.opencontainers.image.source=https://github.com/cybozu-go/website-operator

RUN elasticsearch-plugin install analysis-kuromoji \
    && elasticsearch-plugin install analysis-icu

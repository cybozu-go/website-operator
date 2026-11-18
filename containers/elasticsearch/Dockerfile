FROM docker.elastic.co/elasticsearch/elasticsearch:8.19.24@sha256:d6dfe6626d645cfec66e91009aca60c6c1bb6f94d34253528f24d8cea2f94ba6

LABEL org.opencontainers.image.source=https://github.com/cybozu-go/website-operator

RUN elasticsearch-plugin install analysis-kuromoji \
    && elasticsearch-plugin install analysis-icu

# Mitigation for CVE-2026-114938 (Java4Shell): disable the AVX-512 Base64 intrinsics.
# Remove this once the bundled JDK includes the fix.
RUN echo "-XX:-UseBASE64Intrinsics" > /usr/share/elasticsearch/config/jvm.options.d/java4shell.options

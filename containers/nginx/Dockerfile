ARG BASE_TAG=24.04
FROM ghcr.io/cybozu/ubuntu:${BASE_TAG}

LABEL org.opencontainers.image.source=https://github.com/cybozu-go/website-operator

ARG NGINX_VERSION=1.30.4-1

COPY apt_pref /etc/apt/preferences.d/99nginx

RUN UBUNTU_CODENAME=$(. /etc/os-release && echo "$UBUNTU_CODENAME") \
 && curl -sS https://nginx.org/keys/nginx_signing.key \
   | tee /usr/share/keyrings/nginx-archive-keyring.asc >/dev/null \
 && echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.asc] https://nginx.org/packages/ubuntu ${UBUNTU_CODENAME} nginx" \
   | tee /etc/apt/sources.list.d/nginx.list \
 && apt-get update \
 && apt-get install --no-install-recommends -y \
      "nginx=${NGINX_VERSION}~${UBUNTU_CODENAME}" \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY --chown=www-data:www-data nginx.conf /etc/nginx/nginx.conf

RUN set -x \
 && mkdir -p /var/log/nginx \
 && mkdir -p /var/cache/nginx \
 && chown -R www-data:www-data /var/cache/nginx /var/log/nginx \
 && chmod 775 /var/cache/nginx /var/log/nginx \
 && touch /var/log/nginx/nginx.pid

EXPOSE 8080
USER www-data:www-data

CMD ["nginx", "-g", "daemon off;"]

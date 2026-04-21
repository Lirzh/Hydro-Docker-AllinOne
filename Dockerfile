FROM alpine:latest

USER root

RUN apk add --no-cache curl && \
    curl -fsSL --max-time 60 --retry 3 https://hydro.ac/setup.sh -o /tmp/hydro-setup.sh && \
    chmod +x /tmp/hydro-setup.sh && \
    set -ex && \
    LANG=zh /tmp/hydro-setup.sh --no-caddy && \
    rm -f /tmp/hydro-setup.sh

RUN pm2 ls

RUN yarn -v
RUN yarn config set registry https://registry.npmmirror.com

RUN sed -i 's#https\?://dl-cdn.alpinelinux.org/alpine#https://mirrors.tuna.tsinghua.edu.cn/alpine#g' /etc/apk/repositories && \
    apk update

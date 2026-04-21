FROM alpine:latest

USER root

RUN apk add --no-cache bash curl && \
    ln -sf /bin/bash /bin/sh && \
    set -ex && \
    LANG=zh . <(curl https://hydro.ac/setup.sh) --no-caddy

RUN pm2 ls

RUN yarn -v
RUN yarn config set registry https://registry.npmmirror.com

RUN sed -i 's#https\?://dl-cdn.alpinelinux.org/alpine#https://mirrors.tuna.tsinghua.edu.cn/alpine#g' /etc/apk/repositories && \
    apk update

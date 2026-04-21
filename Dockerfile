FROM debian:bookworm-slim

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl bash && \
    rm -rf /var/lib/apt/lists/* && \
    LANG=zh . <(curl https://hydro.ac/setup.sh) --no-caddy

RUN pm2 ls

RUN yarn -v
RUN yarn config set registry https://registry.npmmirror.com

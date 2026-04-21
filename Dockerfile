FROM alpine:latest

USER root

RUN LANG=zh . <(curl https://hydro.ac/setup.sh)

# RUN yarn config set registry https://registry.npmmirror.com
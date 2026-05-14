FROM node:22-alpine

ENV NODE_ENV=production
ENV DEBIAN_FRONTEND=noninteractive

# ==================== 核心：给 Alpine 安装 完整 glibc（复刻Nix运行原理） ====================
# 安装官方信任密钥 + glibc 仓库（Alpine 标准完整 glibc 源，社区公认稳定）
RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r1/glibc-2.35-r1.apk && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r1/glibc-bin-2.35-r1.apk && \
    apk add --no-cache --force-overwrite \
        glibc-2.35-r1.apk \
        glibc-bin-2.35-r1.apk && \
    rm -rf *.apk

# 配置 glibc 库路径（让系统优先使用完整glibc，而非musl）
ENV LD_LIBRARY_PATH=/usr/glibc-compat/lib:/usr/local/lib:/lib
ENV PATH=/usr/glibc-compat/bin:$PATH

# ==================== 安装基础依赖 ====================
RUN apk update && apk add --no-cache \
    curl \
    gnupg \
    ca-certificates \
    gcc \
    g++ \
    make \
    wget \
    build-base \
    zlib-dev \
    openssl-dev \
    libffi-dev \
    bzip2-dev \
    readline-dev \
    sqlite-dev \
    tk-dev \
    gawk \
    bash \
    openssl

# ==================== 安装 MongoDB 8.0（完整glibc加持，无任何符号报错） ====================
ENV MONGO_VERSION=8.0.0
RUN mkdir -p /opt/mongodb /data/db /var/log/mongodb && \
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then MONGO_ARCH="x86_64"; else MONGO_ARCH="aarch64"; fi && \
    wget -O /tmp/mongodb.tgz https://fastdl.mongodb.org/linux/mongodb-linux-${MONGO_ARCH}-ubuntu2204-${MONGO_VERSION} && \
    tar -zxvf /tmp/mongodb.tgz --strip 1 -C /opt/mongodb && \
    rm -f /tmp/mongodb.tgz && \
    ln -s /opt/mongodb/bin/mongod /usr/bin/mongod && \
    ln -s /opt/mongodb/bin/mongosh /usr/bin/mongosh && \
    chmod -R 777 /data/db /var/log/mongodb

# 验证：MongoDB 完美运行（无符号错误）
RUN gcc --version && g++ --version && mongod --version

# ==================== 后续配置（完全保留你的原有逻辑） ====================
RUN mkdir -p /root/.hydro && \
    mkdir -p /root/.pm2/logs && \
    mkdir -p /root/.pm2/pids

RUN echo '["@hydrooj/ui-default", "@hydrooj/hydrojudge", "@hydrooj/a11y"]' > /root/.hydro/addon.json

RUN MONGO_HOST="${MONGO_HOST:-localhost}" && \
    MONGO_PORT="${MONGO_PORT:-27017}" && \
    MONGO_NAME="${MONGO_NAME:-hydro}" && \
    MONGO_USER="${MONGO_USER:-}" && \
    MONGO_PASS="${MONGO_PASS:-$(openssl rand -base64 32)}" && \
    echo "{\"host\": \"${MONGO_HOST}\", \"port\": \"${MONGO_PORT}\", \"name\": \"${MONGO_NAME}\", \"username\": \"${MONGO_USER}\", \"password\": \"${MONGO_PASS}\"}" > /root/.hydro/config.json

# 安装 PM2 + HydroOJ
RUN yarn global add pm2 koa @types/markdown-it hydrooj @hydrooj/ui-default @hydrooj/hydrojudge @hydrooj/a11y

# 安装 go-judge 沙箱
RUN arch=$(uname -m) && \
    case "$arch" in \
      x86_64)  url="https://github.com/criyle/go-judge/releases/download/v1.12.0/go-judge_1.12.0_linux_amd64v3" ;; \
      aarch64) url="https://github.com/criyle/go-judge/releases/download/v1.12.0/go-judge_1.12.0_linux_arm64" ;; \
      *) echo "Unsupported architecture" && exit 1 ;; \
    esac && \
    wget $url -O /usr/bin/sandbox && chmod +x /usr/bin/sandbox

# 初始化 MongoDB + HydroOJ
RUN mongod --dbpath /data/db --fork --logpath /var/log/mongodb/mongod.log && \
    until mongosh --quiet --eval "db.adminCommand('ping')"; do sleep 1; done && \
    hydrooj cli system set server.host 0.0.0.0 && \
    mongod --dbpath /data/db --shutdown

# 启动配置
COPY ecosystem.config.js /etc/ecosystem.config.js
ENTRYPOINT ["bash", "-c", "pm2-runtime /etc/ecosystem.config.js"]

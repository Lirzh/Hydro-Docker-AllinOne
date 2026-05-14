FROM node:22-alpine

#  Alpine 环境无需 DEBIAN_FRONTEND，直接移除
ENV NODE_ENV=production

# 1. 安装 Alpine 基础依赖（替换 Debian 包为 Alpine 对应包 + MongoDB 必需 glibc 兼容库）
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
    libc6-compat

# 2. 手动安装 MongoDB 8.0（Alpine 无官方 APK 包，直接用官方二进制）
ENV MONGO_VERSION=8.0
RUN mkdir -p /opt/mongodb /data/db /var/log/mongodb && \
    # 自动识别 CPU 架构（amd64/arm64）
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then MONGO_ARCH="x86_64"; else MONGO_ARCH="aarch64"; fi && \
    # 下载 MongoDB 8.0 官方二进制包
    wget -O /tmp/mongodb.tgz https://fastdl.mongodb.org/linux/mongodb-linux-${MONGO_ARCH}-ubuntu2204-${MONGO_VERSION}.0.tgz && \
    tar -zxvf /tmp/mongodb.tgz --strip 1 -C /opt/mongodb && \
    rm -f /tmp/mongodb.tgz && \
    # 软链接到系统 PATH
    ln -s /opt/mongodb/bin/mongod /usr/bin/mongod && \
    ln -s /opt/mongodb/bin/mongosh /usr/bin/mongosh && \
    # 权限修复
    chmod -R 755 /data/db /var/log/mongodb

# 3. 验证工具链（保留原有验证逻辑）
RUN gcc --version && \
    g++ --version && \
    mongod --version

# 4. 创建必要目录（完全保留原有逻辑）
RUN mkdir -p /root/.hydro && \
    mkdir -p /root/.pm2/logs && \
    mkdir -p /root/.pm2/pids && \
    mkdir -p /data/db && \
    mkdir -p /var/log/mongodb

# 5. 初始化 HydroOJ 配置（完全保留原有逻辑）
RUN echo '["@hydrooj/ui-default", "@hydrooj/hydrojudge", "@hydrooj/a11y"]' > /root/.hydro/addon.json

RUN MONGO_HOST="${MONGO_HOST:-localhost}" && \
    MONGO_PORT="${MONGO_PORT:-27017}" && \
    MONGO_NAME="${MONGO_NAME:-hydro}" && \
    MONGO_USER="${MONGO_USER:-}" && \
    MONGO_PASS="${MONGO_PASS:-$(openssl rand -base64 32)}" && \
    echo "{\"host\": \"${MONGO_HOST}\", \"port\": \"${MONGO_PORT}\", \"name\": \"${MONGO_NAME}\", \"username\": \"${MONGO_USER}\", \"password\": \"${MONGO_PASS}\"}" > /root/.hydro/config.json

# 6. 安装 PM2 + HydroOJ 插件（保留原有逻辑）
RUN yarn global add pm2 koa @types/markdown-it hydrooj @hydrooj/ui-default @hydrooj/hydrojudge @hydrooj/a11y

# 7. 下载 go-judge 沙箱（替换 Alpine 架构识别方式）
RUN arch=$(uname -m) && \
    case "$arch" in \
      x86_64)  url="https://github.com/criyle/go-judge/releases/download/v1.12.0/go-judge_1.12.0_linux_amd64v3" ;; \
      aarch64) url="https://github.com/criyle/go-judge/releases/download/v1.12.0/go-judge_1.12.0_linux_arm64" ;; \
      *) echo "Unsupported architecture: $arch" && exit 1 ;; \
    esac && \
    wget "$url" -O /usr/bin/sandbox && \
    chmod +x /usr/bin/sandbox

# 8. 初始化 MongoDB + HydroOJ 系统配置（保留原有逻辑，适配 Alpine）
RUN mongod --dbpath /data/db --fork --logpath /var/log/mongodb/mongod.log && \
    until mongosh --quiet --eval "db.adminCommand('ping')" > /dev/null 2>&1; do sleep 1; done && \
    hydrooj cli system set server.host 0.0.0.0 && \
    mongod --dbpath /data/db --shutdown

# 9. 复制 PM2 配置
COPY ecosystem.config.js /etc/ecosystem.config.js

# 10. 启动命令（完全保留）
ENTRYPOINT ["bash", "-c", "pm2-runtime /etc/ecosystem.config.js"]

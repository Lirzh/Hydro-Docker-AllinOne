FROM node:22-alpine

ENV DEBIAN_FRONTEND=noninteractive

# 安装Alpine基础依赖
RUN apk add --no-cache \
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
    tk \
    bash \
    mongodb \
    mongodb-tools

# 创建必要目录
RUN mkdir -p /root/.hydro && \
    mkdir -p /root/.pm2/logs && \
    mkdir -p /root/.pm2/pids && \
    mkdir -p /data/db && \
    mkdir -p /var/log/mongodb

# 初始化 addon.json
RUN echo '["@hydrooj/ui-default", "@hydrooj/hydrojudge", "@hydrooj/a11y"]' > /root/.hydro/addon.json

# 初始化 config.json - 使用本地 MongoDB
RUN MONGO_HOST="${MONGO_HOST:-localhost}" && \
    MONGO_PORT="${MONGO_PORT:-27017}" && \
    MONGO_NAME="${MONGO_NAME:-hydro}" && \
    MONGO_USER="${MONGO_USER:-}" && \
    # 我也不知道下面这一行有什么实际区别，但总比留空好吧
    MONGO_PASS="${MONGO_PASS:-$(openssl rand -base64 32)}" && \
    echo "{\"host\": \"${MONGO_HOST}\", \"port\": \"${MONGO_PORT}\", \"name\": \"${MONGO_NAME}\", \"username\": \"${MONGO_USER}\", \"password\": \"${MONGO_PASS}\"}" > /root/.hydro/config.json

# 安装 pm2、hydrooj、ui-default 和 hydrojudge
RUN yarn global add pm2 koa @types/markdown-it hydrooj @hydrooj/ui-default @hydrooj/hydrojudge @hydrooj/a11y

# 下载 go-judge 沙箱 (Alpine兼容版本)
RUN arch=$(apk --print-arch) && \
    case "$arch" in \
      x86_64)  url="https://github.com/criyle/go-judge/releases/download/v1.12.0/go-judge_1.12.0_linux_amd64v3" ;; \
      aarch64)  url="https://github.com/criyle/go-judge/releases/download/v1.12.0/go-judge_1.12.0_linux_arm64" ;; \
      *) echo "Unsupported architecture: $arch" && exit 1 ;; \
    esac && \
    wget "$url" -O /usr/bin/sandbox && \
    chmod +x /usr/bin/sandbox

# 设置监听所有 ip 以适配 docker 环境
# 在Alpine中，MongoDB启动方式略有不同
RUN mongod --dbpath /data/db --fork --logpath /var/log/mongodb/mongod.log --bind_ip_all && \
    until mongosh --quiet --eval "db.adminCommand('ping')" > /dev/null 2>&1; do sleep 1; done && \
    hydrooj cli system set server.host 0.0.0.0 && \
    mongod --dbpath /data/db --shutdown

# 复制 PM2 ecosystem 配置文件
COPY ecosystem.config.js /etc/ecosystem.config.js

ENTRYPOINT ["bash", "-c", "pm2-runtime /etc/ecosystem.config.js"]
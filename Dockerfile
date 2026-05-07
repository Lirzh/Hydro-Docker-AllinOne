FROM node:22-trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

# 统一更新软件源并安装所有依赖
RUN apt-get -qq update && \
    apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    ca-certificates\
    gcc \
    g++ \
    make \
    wget \
    build-essential \
    zlib1g-dev \
    libssl-dev \
    libffi-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    tk-dev \
    gawk \
    bash \
    # openjdk-21-jdk-headless \
    # fpc \
    # fp-compiler \
    # rustc \
    # ghc \
    # cabal-install \
    # libjavascriptcoregtk-4.0-bin \
    # golang \
    # ruby \
    # mono-runtime \
    # mono-mcs \
    # kotlin \
    # php \
    # php-cli \
    # python3 \
    # pypy3 \
    && rm -rf /var/lib/apt/lists/*

# 更新 MongoDB 源
RUN curl -fsSL https://pgp.mongodb.com/server-8.0.asc | \
   gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
   --dearmor \
   && echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" | tee /etc/apt/sources.list.d/mongodb-org-8.0.list

# 安装 MongoDB
RUN apt-get -qq update && \
    apt-get install -y mongodb-org && \
    rm -rf /var/lib/apt/lists/*

# # 手动安装 Python2.7.18
# RUN cd /tmp && \
#     wget https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz && \
#     tar -xzf Python-2.7.18.tgz && \
#     cd Python-2.7.18 && \
#     ./configure --prefix=/usr/local --enable-unicode=ucs4 && \
#     make -j$(nproc) && \
#     make altinstall && \
#     ln -s /usr/local/bin/python2.7 /usr/bin/python2 && \
#     cd / && rm -rf /tmp/Python-2.7.18*

# # 设置 python 命令优先使用 python3
# RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 2 && \
#     update-alternatives --install /usr/bin/python python /usr/bin/python2 1

# 验证工具链
RUN gcc --version && \
    g++ --version && \
    # fpc -iV && \
    # javac -version && \
    # rustc --version && \
    # ghc --version && \
    # cabal --version && \
    # go version && \
    # ruby --version && \
    # mono --version && \
    # kotlinc -version && \
    # php --version && \
    # node --version && \
    # python2 --version && \
    # python3 --version && \
    # pypy3 --version && \
    mongod --version

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
RUN yarn global add pm2 hydrooj @hydrooj/ui-default @hydrooj/hydrojudge @hydrooj/a11y

# 下载 go-judge 沙箱
RUN arch=$(dpkg --print-architecture) && \
    case "$arch" in \
      amd64)  url="https://github.com/criyle/go-judge/releases/download/v1.12.0/go-judge_1.12.0_linux_amd64v3" ;; \
      arm64)  url="https://github.com/criyle/go-judge/releases/download/v1.12.0/go-judge_1.12.0_linux_arm64" ;; \
      *) echo "Unsupported architecture: $arch" && exit 1 ;; \
    esac && \
    wget "$url" -O /usr/bin/sandbox && \
    chmod +x /usr/bin/sandbox

# 设置监听所有 ip 以适配 docker 环境
RUN mongod --dbpath /data/db --fork --logpath /var/log/mongodb/mongod.log && \
    until mongosh --quiet --eval "db.adminCommand('ping')" > /dev/null 2>&1; do sleep 1; done && \
    hydrooj cli system set server.host 0.0.0.0 && \
    mongod --dbpath /data/db --shutdown

# 复制 PM2 ecosystem 配置文件
COPY ecosystem.config.js /etc/ecosystem.config.js

ENTRYPOINT ["bash", "-c", "pm2-runtime /etc/ecosystem.config.js"]
#!/bin/bash

ROOT=/root/.hydro

# 初始化 addon.json
if [ ! -f "$ROOT/addon.json" ]; then
    echo '["@hydrooj/ui-default"]' > "$ROOT/addon.json"
fi

# 初始化 config.json - 使用本地 MongoDB（如果有的话）或默认配置
if [ ! -f "$ROOT/config.json" ]; then
    # 如果环境变量中有 MongoDB 连接信息则使用，否则使用默认值
    MONGO_HOST="${MONGO_HOST:-localhost}"
    MONGO_PORT="${MONGO_PORT:-27017}"
    MONGO_NAME="${MONGO_NAME:-hydro}"
    MONGO_USER="${MONGO_USER:-}"
    MONGO_PASS="${MONGO_PASS:-}"
    echo "{\"host\": \"${MONGO_HOST}\", \"port\": \"${MONGO_PORT}\", \"name\": \"${MONGO_NAME}\", \"username\": \"${MONGO_USER}\", \"password\": \"${MONGO_PASS}\"}" > "$ROOT/config.json"
fi

# 初始化 judge.yaml - 修改 server_url 指向本地
if [ ! -f "$ROOT/judge.yaml" ]; then
    cp /root/judge.yaml "$ROOT/judge.yaml"
    # 将 server_url 改为 localhost，因为在同一容器内
    sed -i 's|server_url: http://oj-backend:8888/|server_url: http://localhost:8888/|g' "$ROOT/judge.yaml"
fi

# 首次运行初始化用户
if [ ! -f "$ROOT/first" ]; then
    echo "for marking use only!" > "$ROOT/first"
    hydrooj cli user create Hydro@hydro.local hydro hydro123
    hydrooj cli user setPassword 1 hydro123
    hydrooj cli user setJudge 1
    hydrooj cli system set server.host 0.0.0.0
fi

# 启动 sandbox
pm2 start sandbox --name sandbox

# 启动 hydrojudge
pm2 start hydrojudge --name hydrojudge

# 启动 hydrooj (backend)
pm2-runtime start hydrooj --name hydrooj

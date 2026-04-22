#!/bin/bash

ROOT=/root/.hydro

echo "========================================="
echo "Starting Hydro OJ All-in-One Container"
echo "========================================="

# 初始化 addon.json
if [ ! -f "$ROOT/addon.json" ]; then
    echo '["@hydrooj/ui-default"]' > "$ROOT/addon.json"
    echo "Created default addon.json"
fi

# 初始化 config.json - 使用本地 MongoDB
if [ ! -f "$ROOT/config.json" ]; then
    MONGO_HOST="${MONGO_HOST:-localhost}"
    MONGO_PORT="${MONGO_PORT:-27017}"
    MONGO_NAME="${MONGO_NAME:-hydro}"
    MONGO_USER="${MONGO_USER:-}"
    MONGO_PASS="${MONGO_PASS:-}"
    echo "{\"host\": \"${MONGO_HOST}\", \"port\": \"${MONGO_PORT}\", \"name\": \"${MONGO_NAME}\", \"username\": \"${MONGO_USER}\", \"password\": \"${MONGO_PASS}\"}" > "$ROOT/config.json"
    echo "Created default config.json with MongoDB connection: ${MONGO_HOST}:${MONGO_PORT}/${MONGO_NAME}"
fi

# 首次运行初始化用户
if [ ! -f "$ROOT/first" ]; then
    echo "[1/3] Initializing Hydro OJ first-time setup..."
    echo "for marking use only!" > "$ROOT/first"
    
    # 先启动 MongoDB 用于初始化
    echo "Starting MongoDB for initialization..."
    mongod --dbpath /data/db --logpath /var/log/mongodb/mongod.log --fork --bind_ip_all
    
    # 等待 MongoDB 完全启动
    echo "Waiting for MongoDB to be ready..."
    for i in {1..30}; do
        if mongosh --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
            echo "MongoDB is ready!"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "ERROR: MongoDB failed to start within 30 seconds!"
            exit 1
        fi
        sleep 1
    done
    
    # 执行初始化命令
    hydrooj cli user create Hydro@hydro.local hydro hydro123
    hydrooj cli user setPassword 1 hydro123
    hydrooj cli user setJudge 1
    hydrooj cli system set server.host 0.0.0.0
    echo "First-time initialization completed."
    
    # 停止临时 MongoDB,稍后用 pm2 重新启动
    echo "Stopping temporary MongoDB instance..."
    mongod --shutdown --dbpath /data/db
    sleep 2
else
    echo "[1/3] Skipping first-time initialization (already initialized)"
fi

# 使用 pm2-runtime 统一启动所有服务
echo "[2/3] Starting all services with PM2..."

# 创建 PM2 ecosystem 配置文件
cat > /tmp/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [
    {
      name: 'mongodb',
      script: 'mongod',
      args: '--dbpath /data/db --logpath /var/log/mongodb/mongod.log --bind_ip_all',
      autorestart: true,
      max_restarts: 10,
      min_uptime: '5s',
      restart_delay: 3000
    },
    {
      name: 'sandbox',
      script: 'sandbox',
      autorestart: true,
      max_restarts: 10,
      min_uptime: '5s',
      restart_delay: 3000
    },
    {
      name: 'hydrooj',
      script: 'hydrooj',
      autorestart: true,
      max_restarts: 10,
      min_uptime: '5s',
      restart_delay: 3000
    }
  ]
};
EOF

echo "[3/3] Launching services..."
pm2-runtime /tmp/ecosystem.config.js
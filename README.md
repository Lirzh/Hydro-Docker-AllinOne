# Hydro OJ Docker All-in-One

Hydro OJ 的 Docker 版本，采用真正的单容器架构（All-in-One），将 MongoDB、Hydro OJ Backend、Sandbox 和 Judge 全部集成在一个容器中运行.

## ✨ 特性

- 🎯 **真正的 All-in-One**: MongoDB + Hydro OJ + Sandbox + Judge 单容器运行
- 🔧 **统一进程管理**: 使用 PM2 统一管理所有服务，支持自动重启和日志收集
- 💾 **数据持久化**: 支持卷挂载，确保数据不丢失
- 🚀 **一键部署**: 简单的 Docker 命令即可启动完整系统

## 📋 前置要求

- Docker (推荐最新版本)
- 至少 2GB 可用内存
- 至少 8GB 可用磁盘空间

## 🚀 快速开始

### 1. 构建镜像

```bash
docker build -t hydro-allinone:latest .
```

### 2. 运行容器

**基础运行:**

```bash
docker run -d \
  --name hydro-oj \
  --privileged \
  -p 80:8888 \
  -v hydro-data:/root/.hydro \
  -v mongo-data:/data \
  hydro-allinone:latest
```

**参数说明:**
- `-p 80:8888`: 映射 Web 界面端口
- `-v hydro-data:/root/.hydro`: 持久化 Hydro OJ 配置、提交记录和 sandbox 挂载配置
- `-v mongo-data:/data/db`: 持久化 MongoDB 数据库文件

### 3. 访问系统

打开浏览器访问: `http://localhost:80`

### 查看服务状态

```bash
# 查看所有服务状态
docker exec hydro-oj pm2 list

# 查看特定服务日志
docker exec hydro-oj pm2 logs mongodb
docker exec hydro-oj pm2 logs hydro-sandbox
docker exec hydro-oj pm2 logs hydrooj

# 查看容器整体日志
docker logs hydro-oj
```

### 重启服务

```bash
# 重启单个服务
docker exec hydro-oj pm2 restart mongodb
docker exec hydro-oj pm2 restart hydro-sandbox
docker exec hydro-oj pm2 restart hydrooj

# 重启整个容器
docker restart hydro-oj
```

### 进入容器

```bash
docker exec -it hydro-oj /bin/bash
```

## 📊 架构说明

### 容器内服务组成

```
┌─────────────────────────────────────┐
│     Hydro OJ All-in-One Container   │
├─────────────────────────────────────┤
│                                     │
│         ┌────────────────┐          │
│         │   PM2 Runtime  │          │
│         │                │          │
│         │  ┌──────────┐  │          │
│         │  │ MongoDB  │  │          │
│         │  └──────────┘  │          │
│         │  ┌──────────┐  │          │
│         │  │ Sandbox  │  │          │
│         │  └──────────┘  │          │
│         │  ┌──────────┐  │          │
│         │  │ Hydro OJ │  │          │
│         │  └──────────┘  │          │
│         └────────────────┘          │
│                                     │
└─────────────────────────────────────┘
```

## 🔍 故障排查

### 容器无法启动

```bash
# 查看详细日志
docker logs hydro-oj

# 检查卷权限
docker volume inspect hydro-data
docker volume inspect mongo-data
```

### MongoDB 连接失败

```bash
# 检查 MongoDB 状态
docker exec hydro-oj pm2 status mongodb

# 查看 MongoDB 日志
docker exec hydro-oj pm2 logs mongodb

# 手动测试连接
docker exec hydro-oj mongosh --eval "db.adminCommand('ping')"
```

### Web 界面无法访问

```bash
# 检查 Hydro OJ 状态
docker exec hydro-oj pm2 status hydrooj

# 查看 Hydro OJ 日志
docker exec hydro-oj pm2 logs hydrooj

# 检查端口占用
netstat -tlnp | grep 8888
```

### 重置系统

如果需要完全重置系统（**警告: 会删除所有数据**）:

```
# 停止并删除容器
docker stop hydro-oj
docker rm hydro-oj

# 删除数据卷
docker volume rm hydro-data
docker volume rm mongo-data

# 重新启动
docker run -d \
  --name hydro-oj \
  --privileged \
  -p 80:8888 \
  -v hydro-data:/root/.hydro \
  -v mongo-data:/data \
  hydro-allinone:latest
```

## 📝 技术细节

### 基础镜像
- `node:22-trixie-slim` (基于 Debian Trixie)

### 安装的组件
- **MongoDB**: org (数据库，使用 bookworm 源兼容 trixie)
- **Node.js**: 22 (运行时)
- **PM2**: 进程管理器，统一管理所有服务
- **编程语言工具链**:
  - GCC/G++ (C/C++)
  - 其它自选
- **Sandbox**: go-judge 1.12.0 (代码执行沙箱)

### 配置文件位置
请参照 Hydro OJ 官方文档

## 🤝 贡献

欢迎提交 Issue 和 Pull Request!
# Hydro OJ Docker All-in-One

Hydro OJ 的 Docker 版本，采用真正的单容器架构（All-in-One），将 MongoDB、Hydro OJ Backend、Sandbox 和 Judge 全部集成在一个容器中运行.

## ✨ 特性

- 🎯 **真正的 All-in-One**: MongoDB + Hydro OJ + Sandbox + Judge 单容器运行
- 🔧 **统一进程管理**: 使用 PM2 统一管理所有服务，支持自动重启和日志收集
- 💾 **数据持久化**: 支持卷挂载，确保数据不丢失
- 🚀 **一键部署**: 简单的 Docker 命令即可启动完整系统

## 📋 前置要求

- Docker (推荐最新版本)
- 至少 4GB 可用内存
- 至少 10GB 可用磁盘空间

## 🚀 快速开始

### 1. 构建镜像

```bash
docker build -t hydro-allinone:latest .
```

### 2. 运行容器

```bash
docker run -d \
  --name hydro-oj \
  -p 8888:8888 \
  -v hydro-data:/root/.hydro \
  -v mongo-data:/data/db \
  ghcr.nju.edu.cn/lirzh/hydro-docker-allinone:latest
```

**参数说明:**
- `-p 8888:8888`: 映射 Web 界面端口
- `-v hydro-data:/root/.hydro`: 持久化 Hydro OJ 配置和提交记录
- `-v mongo-data:/data/db`: 持久化 MongoDB 数据库文件

### 3. 访问系统

打开浏览器访问: `http://localhost:8888`

**默认管理员账户:**
- 邮箱: `Hydro@hydro.local`
- 用户名: `hydro`
- 密码: `hydro123`

## 🔧 高级配置

### 环境变量

可以通过环境变量自定义配置:

```bash
docker run -d \
  --name hydro-oj \
  -p 8888:8888 \
  -e MONGO_HOST=localhost \
  -e MONGO_PORT=27017 \
  -e MONGO_NAME=hydro \
  -v hydro-data:/root/.hydro \
  -v mongo-data:/data/db \
  hydro-allinone:latest
```

**可用的环境变量:**
- `MONGO_HOST`: MongoDB 主机地址 (默认: localhost)
- `MONGO_PORT`: MongoDB 端口 (默认: 27017)
- `MONGO_NAME`: 数据库名称 (默认: hydro)
- `MONGO_USER`: MongoDB 用户名 (可选)
- `MONGO_PASS`: MongoDB 密码 (可选)

### 查看服务状态

```bash
# 查看所有服务状态
docker exec hydro-oj pm2 list

# 查看特定服务日志
docker exec hydro-oj pm2 logs mongodb
docker exec hydro-oj pm2 logs sandbox
docker exec hydro-oj pm2 logs hydrooj

# 查看容器整体日志
docker logs hydro-oj
```

### 重启服务

```bash
# 重启单个服务
docker exec hydro-oj pm2 restart mongodb
docker exec hydro-oj pm2 restart sandbox
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
│  ┌──────────┐  ┌────────────────┐  │
│  │ MongoDB  │  │   PM2 Runtime  │  │
│  │ (7.0)    │◄─┤                │  │
│  └──────────┘  │  ┌──────────┐  │  │
│                │  │ Sandbox  │  │  │
│                │  └──────────┘  │  │
│                │  ┌──────────┐  │  │
│                │  │ Hydro OJ │  │  │
│                │  └──────────┘  │  │
│                └────────────────┘  │
│                                     │
└─────────────────────────────────────┘
         ▲              ▲
         │              │
    Port 27017    Port 8888
    (内部)        (外部访问)
```

### 服务启动流程

1. **初始化阶段** (首次运行):
   - 启动临时 MongoDB
   - 创建管理员账户
   - 配置系统参数
   - 停止临时 MongoDB

2. **正常运行**:
   - PM2 启动 MongoDB
   - PM2 启动 Sandbox
   - PM2 启动 Hydro OJ Backend
   - 所有服务由 PM2 统一监控和自动重启

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

```bash
# 停止并删除容器
docker stop hydro-oj
docker rm hydro-oj

# 删除数据卷
docker volume rm hydro-data
docker volume rm mongo-data

# 重新启动
docker run -d \
  --name hydro-oj \
  -p 8888:8888 \
  -v hydro-data:/root/.hydro \
  -v mongo-data:/data/db \
  hydro-allinone:latest
```

## 📝 技术细节

### 基础镜像
- `node:22-trixie-slim` (Debian Trixie + Node.js 22)

### 安装的组件
- **MongoDB**: 7.0 (数据库)
- **Node.js**: 22 (运行时)
- **编程语言工具链**:
  - GCC/G++ (C/C++)
  - Python 2.7.18, Python 3, PyPy3
  - Java (OpenJDK 21)
  - Go
  - Rust
  - Haskell (GHC)
  - Pascal (FPC)
  - Ruby
  - PHP
  - Kotlin
  - Mono (C#)
  - JavaScript (Node.js)

### 进程管理
- **PM2**: 统一管理 MongoDB、Sandbox、Hydro OJ 三个服务
- **自动重启**: 服务崩溃时自动重启（最多 10 次）
- **日志收集**: 集中管理所有服务日志

## 🛡️ 安全注意事项

1. **修改默认密码**: 首次登录后立即修改管理员密码
2. **防火墙配置**: 确保只开放必要的端口
3. **HTTPS**: 生产环境建议配置反向代理和 HTTPS
4. **定期备份**: 定期备份数据卷

## 📄 许可证

本项目遵循 Hydro OJ 的开源许可证。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request!

## 📮 联系方式

- 项目主页: [Hydro OJ](https://hydro.ac)
- GitHub: [Hydro-OJ/hydro](https://github.com/Hydro-OJ/hydro)
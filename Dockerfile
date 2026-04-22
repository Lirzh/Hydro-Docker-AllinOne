FROM nixos/nix:latest

USER root

# 创建兼容的 os-release 文件
RUN echo -e '\
NAME=NixOS\n\
ID=nixos\n\
VERSION="24.11 (Tapir)"\n\
VERSION_ID=24.11\n\
PRETTY_NAME="NixOS 24.11 (Tapir)"\n\
BUILD_ID=24.11\n\
ANSI_COLOR="38;2;77;156;212"\n\
HOME_URL="https://nixos.org/"\n\
DOCUMENTATION_URL="https://nixos.org/learn.html"\n\
SUPPORT_URL="https://nixos.org/community.html"\n\
BUG_REPORT_URL="https://github.com/NixOS/nixpkgs/issues"\n\
LOGO=nixos' > /etc/os-release

# 创建标准 Linux 兼容目录并安装 bash
RUN mkdir -p /usr/local/bin /usr/local/lib /usr/local/etc && \
    apk add --no-cache bash

# 复制脚本文件到容器
COPY setup.sh /tmp/setup.sh
COPY nix.sh /tmp/nix.sh

# 使用 bash 显式执行脚本
RUN chmod +x /tmp/setup.sh /tmp/nix.sh && bash /tmp/setup.sh

# 容器启动时自动加载环境
CMD ["source", "/etc/profile", "&&", "pm2", "logs"]

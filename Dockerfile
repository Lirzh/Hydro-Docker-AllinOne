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

# 创建标准 Linux 兼容目录
RUN mkdir -p /usr/local/bin /usr/local/lib /usr/local/etc

# 安装 Hydro Nix 环境
RUN curl -fsSL --max-time 60 --retry 3 https://hydro.ac/nix.sh -o /tmp/hydro-nix.sh && \
    chmod +x /tmp/hydro-nix.sh && \
    bash /tmp/hydro-nix.sh && \
    rm -f /tmp/hydro-nix.sh

# 安装 Hydro 主程序（持久化 PATH 环境变量）
RUN curl -fsSL --max-time 60 --retry 3 https://hydro.ac/setup.sh -o /tmp/hydro-setup.sh && \
    chmod +x /tmp/hydro-setup.sh && \
    echo 'export PATH="/root/.nix-profile/bin:$PATH"' >> /etc/profile && \
    echo 'export PATH="/root/.nix-profile/bin:$PATH"' >> /root/.bashrc && \
    export PATH="/root/.nix-profile/bin:$PATH" && \
    LANG=zh bash /tmp/hydro-setup.sh --no-caddy && \
    rm -f /tmp/hydro-setup.sh

# 加载 Nix 环境后执行命令（必须在同一个 RUN 里）
RUN source /etc/profile && \
    pm2 ls && \
    yarn -v && \
    yarn config set registry https://registry.npmmirror.com

# 容器启动时自动加载环境
CMD ["source", "/etc/profile", "&&", "pm2", "logs"]

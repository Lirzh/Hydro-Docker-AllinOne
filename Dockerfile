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

# 安装 Hydro 主程序（显式加载 Nix 环境并设置完整 PATH）
RUN . /root/.nix-profile/etc/profile.d/nix.sh && \
    export PATH="/root/.nix-profile/bin:$PATH" && \
    export YARN_GLOBAL_BIN="$(yarn global bin)" && \
    export PATH="$YARN_GLOBAL_BIN:$PATH" && \
    curl -fsSL --max-time 60 --retry 3 https://hydro.ac/setup.sh -o /tmp/hydro-setup.sh && \
    chmod +x /tmp/hydro-setup.sh && \
    LANG=zh bash /tmp/hydro-setup.sh --no-caddy && \
    rm -f /tmp/hydro-setup.sh

# 持久化环境变量配置
RUN echo 'source /root/.nix-profile/etc/profile.d/nix.sh' >> /etc/profile && \
    echo 'export PATH="/root/.nix-profile/bin:$PATH"' >> /etc/profile && \
    echo 'export PATH="$(yarn global bin):$PATH"' >> /etc/profile && \
    echo 'source /root/.nix-profile/etc/profile.d/nix.sh' >> /root/.bashrc && \
    echo 'export PATH="/root/.nix-profile/bin:$PATH"' >> /root/.bashrc && \
    echo 'export PATH="$(yarn global bin):$PATH"' >> /root/.bashrc

# 验证安装
RUN . /root/.nix-profile/etc/profile.d/nix.sh && \
    export PATH="/root/.nix-profile/bin:$(yarn global bin):$PATH" && \
    pm2 ls && \
    yarn -v && \
    which hydrooj && \
    which hydrojudge

CMD ["pm2", "logs"]
